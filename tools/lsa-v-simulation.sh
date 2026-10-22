#!/usr/bin/env bash
# lsa-v-simulation.sh — Simulation LSA-V vorher/nachher als Markdown-Tabellen.
#
#   PGHOST=<socket> PGPORT=<port> bash tools/lsa-v-simulation.sh <db_vorher> <db_nachher> <ausgabe.md>
#
# <db_vorher>: Wegwerf-DB aus supabase/migrations OHNE 20261022065539 (Funktion aus dev), mit seed und pgTAP.
# <db_nachher>: dieselbe mit 20261022065539_lsa_v_vorschau.sql. Nie Produktion: Abbruch, wenn DATABASE_URL gesetzt ist.
# Läuft supabase/tests/lsa_v_simulation.test.sql in beiden (braucht supabase/tests/lsa_v_daten.sql, siehe
# tools/lsa-v-abzug.sh) und liest die diag-Zeilen SIM|… und DIREKT|….
set -euo pipefail
[ -z "${DATABASE_URL:-}" ] || { echo "DATABASE_URL ist gesetzt — dieses Skript läuft nur gegen Wegwerf-DBs"; exit 2; }
unset PGDATABASE PGSERVICE
vorher="${1:?db_vorher fehlt}"; nachher="${2:?db_nachher fehlt}"; out="${3:?ausgabe fehlt}"
cd "$(git rev-parse --show-toplevel)"
# LSA_V_DATEN: die Daten aus tools/lsa-v-abzug.sh (Standard: supabase/tests/lsa_v_daten.sql). Test und Daten
# laufen aus einem eigenen Ordner, damit \ir sie findet, ohne dass die Daten im Repo liegen muessen.
daten="${LSA_V_DATEN:-supabase/tests/lsa_v_daten.sql}"
[ -f "$daten" ] || { echo "$daten fehlt — erst tools/lsa-v-abzug.sh"; exit 2; }
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
cp "$daten" "$dir/lsa_v_daten.sql"
k="$dir/lauf.sql"
sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' \
  supabase/tests/lsa_v_simulation.test.sql > "$k"
lauf() { PGOPTIONS='-c search_path=public,extensions -c jit=off' psql -X -q -tA -v ON_ERROR_STOP=1 "postgresql:///$1" -f "$k"; }
lauf "$vorher" > "$out.vorher.txt"
lauf "$nachher" > "$out.nachher.txt"

tabelle() {  # <datei> <pool>
  echo "| Nr | Minute | Grund | Skill | Thema des Skills |"
  echo "|---:|---|---|---|---|"
  grep "^# SIM|$2|" "$1" | cut -d'|' -f3- | awk -F'|' '{printf "| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5}'
}
anteile() {  # <datei> <pool>
  grep "^# SIM|$2|" "$1" | cut -d'|' -f5 | sort | uniq -c | awk '
    { n[$2] = $1; s += $1 }
    END { th = n["Thema"] + n["Grundlage"];
          printf "%d Aufgaben · Themenraum %d (%.0f %%) · Vorschau %d (%.0f %%) · Rückblick %d (%.0f %%) · sonst %d (%.0f %%)\n",
                 s, th, 100*th/s, n["Vorschau"], 100*n["Vorschau"]/s, n["Rückblick"], 100*n["Rückblick"]/s,
                 n["sonst"], 100*n["sonst"]/s }'
}
direkt() { grep "^# DIREKT|$2|" "$1" | awk -F'|' '{print $3 " von " $4}'; }

{
  echo "# LSA-V Simulation vorher/nachher"
  echo
  echo "Erzeugt mit tools/lsa-v-simulation.sh am $(date -u +%Y-%m-%d). Grundlage und Annahmen: Kopf von"
  echo "supabase/tests/lsa_v_simulation.test.sql. Grund nach Zugehörigkeit des Skills, nicht nach der Phase."
  for pool in test echt; do
    case $pool in
      test) echo; echo "## Testpool (lsa_testinhalte = true, wie Testkonto B)" ;;
      echt) echo; echo "## Pool eines echten Kindes (nur status ready)" ;;
    esac
    for seite in vorher nachher; do
      f="$out.$seite.txt"
      echo; echo "### $seite"; echo
      echo "$(anteile "$f" "$pool") · Themenraum direkt geprüft: $(direkt "$f" "$pool")"
      echo; tabelle "$f" "$pool"
    done
  done
} > "$out"
grep -E '^not ok' "$out.nachher.txt" && { echo "nachher: Zusicherungen rot (siehe $out.nachher.txt)"; exit 1; }
rm -f "$out.vorher.txt" "$out.nachher.txt"
echo "$out geschrieben"
