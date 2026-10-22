#!/usr/bin/env bash
# simulation.sh — alle Testkinder im CI-Neuaufbau, einmal ohne und einmal mit einer Migration (LSA-V2).
#
#   bash tools/lsa-testkinder/simulation.sh [<migration.sql>]
#
# Nur lokal: baut zwei Wegwerf-DBs im lokalen Postgres (wie tools/neuaufbau-test.sh: Grundlage, alle Migrationen
# außer der genannten, seed.sql), lädt die Fixture (neuaufbau-fixture.sql) und lässt erzeugen.sql laufen. „vorher“
# ohne die Migration, „nachher“ mit ihr. Danach je DB die Kennzahlen aus auswertung.sql. Für „vorher“ spielt das
# Skript erst NACH dem Lauf den Kopf der Migration bis zur ersten Fassung von lsa_select_next_core ein (nur die
# Hilfsfunktionen lsa_ausblick_knoten/lsa_ist_ausblick), damit die Auswertung dieselbe Definition benutzt.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
MIG="${1:-$(ls supabase/migrations/*_lsa_v2_ausblick.sql | tail -1)}"
# Nur das lokale Postgres (wie neuaufbau-test.sh); DATABASE_URL (Prod) wird nie benutzt.
case "${PGHOST:-}" in *supabase*) echo "Nur gegen ein lokales Postgres."; exit 1 ;; esac
unset DATABASE_URL
T=$(pwd)/tools/lsa-testkinder

baue() {  # $1 = DB, $2 = mit Migration (1/0)
  dropdb --if-exists "$1" >/dev/null 2>&1; createdb "$1"
  psql -q -d "$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
  for f in $(ls supabase/migrations/*.sql | sort); do
    [[ "$f" == "$MIG" && "$2" == 0 ]] && continue
    psql -q -d "$1" -v ON_ERROR_STOP=1 -f "$f" >/dev/null 2>&1 || { echo "Migration scheitert: $f"; exit 1; }
  done
  psql -q -d "$1" -v ON_ERROR_STOP=1 -f supabase/seed.sql >/dev/null 2>&1
}

lauf() {  # $1 = DB, $2 = Titel
  echo; echo "══ $2"
  psql -X -q -d "$1" -v ON_ERROR_STOP=1 -f tools/lsa-testkinder/neuaufbau-fixture.sql >/dev/null
  # erzeugen.sql und die Auswertung in einer Sitzung: lsat.sitzungen gilt nur dort.
  local skript; skript=$(mktemp)
  { echo '\o /dev/null'; echo "\\i $T/erzeugen.sql"; echo '\o'
    [[ -n "${3:-}" ]] && echo "\\i $3"
    echo "\\i $T/auswertung.sql"; } > "$skript"
  psql -X -q -d "$1" -v ON_ERROR_STOP=1 -1 -f "$skript" 2>&1 | grep -vE 'NOTICE|HINWEIS|^DETAIL|^CONTEXT' || true
  rm -f "$skript"
}

KOPF=$(mktemp); sed '/^CREATE OR REPLACE FUNCTION public.lsa_select_next_core/,$d' "$MIG" > "$KOPF"
baue lsav2_sim_vorher 0; baue lsav2_sim_nachher 1
lauf lsav2_sim_vorher "vorher (ohne $(basename "$MIG"))" "$KOPF"
lauf lsav2_sim_nachher "nachher (mit $(basename "$MIG"))"
rm -f "$KOPF"
