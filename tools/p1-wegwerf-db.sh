#!/usr/bin/env bash
# p1-wegwerf-db.sh — Wegwerf-DB für Paket P1 (potenzen prüfbar, Batus Liste, A20-Rest).
#
#   bash tools/p1-wegwerf-db.sh <fixture-ordner>          # Prod-Fixture, M1–M3 zweimal, tools/p1-pruefung.sql
#   bash tools/p1-wegwerf-db.sh <fixture-ordner> --ci     # dazu Neuaufbau wie die CI (alle Migrationen + seed + pgTAP)
#
# Die Fixture ist ein read-only Abzug der Inhaltstabellen aus Prod (dbread, \copy … csv header, ohne generierte
# Spalten), je Tabelle <name>.csv. Sie wird nicht eingecheckt.
# Eigener Cluster: P1_PORT (Standard 55470) und P1_SOCKET; PGDATABASE & Co. werden geleert, jeder psql-Aufruf nennt
# die DB ausdrücklich; nie edvance_shadow, nie Produktion.
# pgTAP ohne Root: PGTAP_SQL zeigt auf pgtap--1.3.4.sql (apt-get download postgresql-18-pgtap, dpkg-deb -x).
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${P1_SOCKET:?P1_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${P1_PORT:-55470}" PGUSER=postgres
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"; shift || true
P1='20261014140100_p1_potenzen_pruefbar.sql 20261014140200_p1_batu_pilot.sql 20261014140300_p1_a20_rest_text.sql'
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung tasks task_solutions task_figures
      task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews pruef_einstellungen task_admin_protokoll'

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'p1_m[0-9]' <<<"$out" | sed "s#^#  [$2] #" || true
}
neu() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; psql -q -X "postgresql:///$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null; }

# ── 1. Basis ohne P1 + seed, Prod-Fixture, Ausgangsstand ────────────────────
DB=p1_test
neu "$DB"
for f in $(ls supabase/migrations/*.sql | sort); do
  case " $P1 " in *" $(basename "$f") "*) continue ;; esac
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
spiele tools/p1-vorher.sql "$DB"

# ── 2. M1–M3 zweimal (Idempotenz), dann Abnahme ─────────────────────────────
for runde in 1 2; do
  echo "Runde $runde:"
  for m in $P1; do spiele "supabase/migrations/$m" "$DB"; done
done
e3="{$(node -e "console.log(require('./docs/prefill/hinweise-e3-snapshot.json').aufgaben.map(a=>a.id).join(','))")}"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -v e3="$e3" -f tools/p1-pruefung.sql

# ── 3. Optional: Neuaufbau wie die CI ───────────────────────────────────────
if [ "${1:-}" = "--ci" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  CI=p1_ci
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
