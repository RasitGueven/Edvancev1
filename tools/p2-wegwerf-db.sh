#!/usr/bin/env bash
# p2-wegwerf-db.sh — Wegwerf-DB für Paket P2 (Board nur mit Batus Liste, Sollzahlen je Knoten).
#
#   bash tools/p2-wegwerf-db.sh <fixture-ordner>          # Prod-Fixture, M1 zweimal, M2/M3, tools/p2-pruefung.sql
#   bash tools/p2-wegwerf-db.sh <fixture-ordner> --ci     # dazu Neuaufbau wie die CI (alle Migrationen + seed + pgTAP)
#
# Fixture und Cluster wie bei P1 (tools/p1-wegwerf-db.sh): read-only Abzug der Inhaltstabellen aus Prod (dbread,
# \copy … csv header, ohne generierte Spalten), je Tabelle <name>.csv, nicht eingecheckt. Eigener Cluster über
# P2_PORT (Standard 55480) und P2_SOCKET; PGDATABASE & Co. werden geleert; nie edvance_shadow, nie Produktion.
# pgTAP ohne Root: PGTAP_SQL zeigt auf pgtap--1.3.4.sql (apt-get download postgresql-18-pgtap, dpkg-deb -x).
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${P2_SOCKET:?P2_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${P2_PORT:-55480}" PGUSER=postgres
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"; shift || true
M1=20261014150100_p2_pilot_aus.sql
P2="$M1 20261014150200_p2_pruef_soll.sql 20261014150300_p2_pruef_board_soll.sql"
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung tasks task_solutions task_figures
      task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews pruef_einstellungen task_admin_protokoll'

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'p2_m[0-9]' <<<"$out" | sed "s#^#  [$2] #" || true
}
neu() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; psql -q -X "postgresql:///$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null; }

# ── 1. Basis ohne P2 + seed, Prod-Fixture, Ausgangsstand ────────────────────
DB=p2_test
neu "$DB"
for f in $(ls supabase/migrations/*.sql | sort); do
  case " $P2 " in *" $(basename "$f") "*) continue ;; esac
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
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/p2-vorher.sql

# ── 2. M1 zweimal (Idempotenz), M2 und M3, dann Abnahme ─────────────────────
for m in $P2 $M1; do spiele "supabase/migrations/$m" "$DB"; done
e3="{$(node -e "console.log(require('./docs/prefill/hinweise-e3-snapshot.json').aufgaben.map(a=>a.id).join(','))")}"
doku="{$(grep -oE '^\| `[0-9a-f-]{36}`' docs/themen/p2-pilot-entfernt.md | tr -d '|` ' | paste -sd,)}"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -v e3="$e3" -v doku="$doku" -f tools/p2-pruefung.sql

# ── 3. Optional: Neuaufbau wie die CI ───────────────────────────────────────
if [ "${1:-}" = "--ci" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  CI=p2_ci
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
