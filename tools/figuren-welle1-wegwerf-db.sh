#!/usr/bin/env bash
# figuren-welle1-wegwerf-db.sh — Wegwerf-DB für Figuren Welle 1 (F2).
#
#   bash tools/figuren-welle1-wegwerf-db.sh            # Neuaufbau wie die CI: alle Migrationen + seed + pgTAP + Schema-Vergleich
#   bash tools/figuren-welle1-wegwerf-db.sh --abzug    # dazu supabase/schema-erwartet.sql aus dem Neuaufbau schreiben
#
# Eigener Cluster über FIG_SOCKET (Socket-Verzeichnis) und FIG_PORT (Standard 55511); PGDATABASE & Co. werden
# geleert; nie edvance_shadow, nie Produktion. pgTAP aus PGTAP_SQL (pgtap--1.3.4.sql, apt-get download).
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${FIG_SOCKET:?FIG_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${FIG_PORT:-55511}" PGUSER=postgres
: "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
CHECK_MIG=20261018170100_figuren_generatoren_welle1.sql

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
}
neu() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; psql -q -X "postgresql:///$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null; }

# ── 1. Neuaufbau wie die CI ─────────────────────────────────────────────────
CI=fig1_ci
neu "$CI"
for f in $(ls supabase/migrations/*.sql | sort); do spiele "$f" "$CI"; done
echo "Migrationen: $(ls supabase/migrations/*.sql | wc -l) eingespielt"

# ── 2. CHECK: die drei neuen Generatoren gehen, ein unbekannter nicht; zweiter Lauf ─
spiele "supabase/migrations/$CHECK_MIG" "$CI"
echo "  $(psql -X -tA "postgresql:///$CI" -c "select pg_get_constraintdef(oid) from pg_constraint where conname = 'task_figures_generator_check'")"
# Echte Zeilen: je Generator eine Figur an einer vorhandenen Aufgabe, dann ein unbekannter.
tid=$(psql -X -tA "postgresql:///$CI" -c "select id from public.tasks order by id limit 1")
for g in thales rechtecke rechteck; do
  psql -X -q "postgresql:///$CI" -v ON_ERROR_STOP=1 -c "begin; insert into public.task_figures (task_id, generator, params, alt_text)
    values ('$tid', '$g', '{}', 'Probe ohne Ziffern'); rollback;" >/dev/null && echo "  CHECK nimmt $g an"
done
if psql -X -q "postgresql:///$CI" -c "insert into public.task_figures (task_id, generator, params, alt_text)
     values ('$tid', 'phantasie', '{}', 'Probe')" >/dev/null 2>&1; then
  echo "FEHLER: CHECK nimmt einen unbekannten Generator an"; exit 1
else echo "  CHECK lehnt 'phantasie' ab"; fi

# ── 3. Schema-Vergleich wie die CI ──────────────────────────────────────────
ist=$(mktemp); soll=$(mktemp); trap 'rm -f "$ist" "$soll"' EXIT
pg_dump --schema-only --no-owner --no-acl --no-comments --schema public "postgresql:///$CI" > "$ist.roh"
if [ "${1:-}" = "--abzug" ]; then cp "$ist.roh" supabase/schema-erwartet.sql; echo "schema-erwartet.sql neu geschrieben"; fi
grep -vE '^--|^$|^SET |^SELECT pg_catalog|restrict ' "$ist.roh" | sort > "$ist"
grep -vE '^--|^$|^SET |^SELECT pg_catalog|restrict ' supabase/schema-erwartet.sql | sort > "$soll"
rm -f "$ist.roh"
if diff -q "$ist" "$soll" >/dev/null; then echo "Schema entspricht supabase/schema-erwartet.sql"
else echo "Schema weicht ab:"; diff "$soll" "$ist" | head -20 || true; fi

# ── 4. pgTAP wie die CI ─────────────────────────────────────────────────────
psql -q -X "postgresql:///$CI" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" >/dev/null
sed 's/@extschema@/extensions/g' "$PGTAP_SQL" | PGOPTIONS='-c search_path=extensions,public' psql -q -X "postgresql:///$CI" -v ON_ERROR_STOP=1 >/dev/null
spiele supabase/seed.sql "$CI"
liste=supabase/tests/bekannt-rot.txt; rot=0; n_ok=0; n_wartet=0
for f in $(ls supabase/tests/*.test.sql | sort); do
  b=$(basename "$f" .test.sql)
  kopie="$(dirname "$f")/.lauf_$b.sql"
  sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' "$f" > "$kopie"
  if out=$(PGOPTIONS='-c search_path=public,extensions -c jit=off' psql -X -q -t -A -v ON_ERROR_STOP=1 "postgresql:///$CI" -f "$kopie" 2>&1) \
     && ! grep -qE '^not ok|^# Looks like' <<<"$out"; then stand=gruen; else stand=rot; fi
  rm -f "$kopie"
  if grep -qE "^$b([[:space:]]|$)" "$liste"; then
    [ "$stand" = gruen ] && { echo "  WIEDER GRUEN $b (aus $liste nehmen)"; rot=1; } || n_wartet=$((n_wartet + 1))
    continue
  fi
  if [ "$stand" = gruen ]; then n_ok=$((n_ok + 1)); else echo "  ROT    $b"; grep -E '^not ok|^#|ERROR' <<<"$out" | head -8; rot=1; fi
done
echo "pgTAP: $n_ok ok, $n_wartet wartet (bekannt-rot), rot=$rot"
exit $rot
