#!/usr/bin/env bash
# hoch-wegwerf-db.sh — Wegwerf-DB für 20261016151208_hochzahlen_inhalt (Hochzeichen statt ^).
#
#   bash tools/hoch-wegwerf-db.sh <fixture-ordner>          # Prod-Fixture, Migration zweimal, Tabelle vorher/nachher, Abnahme
#   bash tools/hoch-wegwerf-db.sh <fixture-ordner> --ci     # dazu Neuaufbau wie die CI (alle Migrationen + seed + pgTAP)
#
# Fixture wie bei P2 (tools/p2-wegwerf-db.sh), zusätzlich fehlbild_labels, fehlbild_familien, pruef_soll, skill_clusters, process_competencies und microskills
# (Trigger task_solutions_pruef_version / FK-Pruefungen): read-only Abzug
# aus Prod (dbread, \copy … csv header, ohne generierte Spalten), nicht eingecheckt. Eigener Cluster über HOCH_PORT
# (Standard 55495) und HOCH_SOCKET; PGDATABASE & Co. werden geleert; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${HOCH_SOCKET:?HOCH_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${HOCH_PORT:-55495}" PGUSER=postgres
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"; shift || true
M=20261016151208_hochzahlen_inhalt.sql
KNOTEN='{potenzen}'
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung tasks task_solutions task_figures
      task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews pruef_einstellungen task_admin_protokoll
      fehlbild_familien fehlbild_labels pruef_soll skill_clusters process_competencies microskills'

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'hochzahlen|hoch-abnahme' <<<"$out" | sed "s#^.*NOTICE: *#  [$2] #" || true
}
neu() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; psql -q -X "postgresql:///$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null; }
tabelle() { psql -X -q "postgresql:///$1" -v ON_ERROR_STOP=1 -v knoten="$KNOTEN" -f tools/batu-inhalte-tabelle.sql; }

# ── 1. Basis ohne die Migration + seed, Prod-Fixture ───────────────────────
DB=hoch_test
neu "$DB"
for f in $(ls supabase/migrations/*.sql | sort); do
  [ "$(basename "$f")" = "$M" ] && continue
  spiele "$f" "$DB" >/dev/null
done
spiele supabase/seed.sql "$DB" >/dev/null
lade=$(mktemp); trap 'rm -f "$lade"' EXIT
{
  echo "set session_replication_role = replica;"
  echo "truncate $(echo $TABS | sed 's/\([a-z_]*\)/public.\1/g; s/ /, /g') cascade;"
  for t in $TABS; do
    echo "\\copy public.$t ($(head -1 "$FIX/$t.csv")) from '$FIX/$t.csv' csv header"
  done
} > "$lade"
spiele "$lade" "$DB"
echo "Fixture: $(psql -X -tA "postgresql:///$DB" -c 'select count(*) from public.tasks') Aufgaben"
# Prüf-Admin für pruef_board() (der Seed bringt keinen Prüfer mehr mit).
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 \
  -c "insert into auth.users (id, email) values ('2b000000-0000-4000-8000-0000000000ad', 'zz_admin@edvance.invalid')" \
  -c "insert into public.profiles (id, email, role, full_name) values ('2b000000-0000-4000-8000-0000000000ad', 'zz_admin@edvance.invalid', 'admin', 'ZZ Admin')" \
  -c "create schema vorher; create table vorher.sol as select * from public.task_solutions" \
  -c "create table vorher.tasks as select * from public.tasks" \
  -c "create table vorher.pruef as select * from public.task_pruefungen" \
  -c "create table vorher.befunde as select t.id, public.pruef_auffaelligkeiten(t, s.correct_answers, s.acceptance, s.solution) befunde
        from public.tasks t join public.task_solutions s on s.task_id = t.id where t.pruef_pilot and t.question like '%^%'"
echo "── vorher"; tabelle "$DB"

# ── 2. Migration zweimal (Idempotenz), Tabelle nachher, Abnahme ────────────
spiele "supabase/migrations/$M" "$DB"
spiele "supabase/migrations/$M" "$DB"
echo "── nachher"; tabelle "$DB"
spiele tools/hoch-abnahme.sql "$DB"

# ── 3. Optional: Neuaufbau wie die CI ───────────────────────────────────────
if [ "${1:-}" = "--ci" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  CI=hoch_ci
  neu "$CI"
  for f in $(ls supabase/migrations/*.sql | sort); do spiele "$f" "$CI"; done
  psql -q -X "postgresql:///$CI" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" >/dev/null
  sed 's/@extschema@/extensions/g' "$PGTAP_SQL" | PGOPTIONS='-c search_path=extensions,public' psql -q -X "postgresql:///$CI" -v ON_ERROR_STOP=1 >/dev/null
  spiele supabase/seed.sql "$CI" >/dev/null
  liste=supabase/tests/bekannt-rot.txt; rot=0
  for f in $(ls supabase/tests/*.test.sql | sort); do
    b=$(basename "$f" .test.sql)
    kopie="$(dirname "$f")/.lauf_$b.sql"
    sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' "$f" > "$kopie"
    if out=$(PGOPTIONS='-c search_path=public,extensions -c jit=off' psql -X -q -t -A -v ON_ERROR_STOP=1 "postgresql:///$CI" -f "$kopie" 2>&1) \
       && ! grep -qE '^not ok|^# Looks like' <<<"$out"; then stand=gruen; else stand=rot; fi
    rm -f "$kopie"
    if grep -qE "^$b([[:space:]]|$)" "$liste"; then
      [ "$stand" = gruen ] && { echo "  WIEDER GRUEN $b (aus $liste nehmen)"; rot=1; } || echo "  wartet $b"
      continue
    fi
    if [ "$stand" = gruen ]; then echo "  ok     $b"; else echo "  ROT    $b"; grep -E '^not ok|^#|ERROR' <<<"$out" | head -8; rot=1; fi
  done
  exit $rot
fi
