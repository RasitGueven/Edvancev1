#!/usr/bin/env bash
# ml2-wegwerf-db.sh — Wegwerf-DB für Paket ML2 (Musterlösungen Stufe 2, Klartext teilgekuerzt).
#
#   bash tools/ml2-wegwerf-db.sh <fixture-ordner>          # Prod-Fixture, Vorher-Prüfung, M1 zweimal, Nachher-Prüfung
#   bash tools/ml2-wegwerf-db.sh <fixture-ordner> --ci     # dazu Neuaufbau wie die CI (alle Migrationen + seed)
#
# Fixture wie bei P1/P2 (tools/p1-wegwerf-db.sh): read-only Abzug der Inhaltstabellen aus Prod, dazu
# fehlbild_familien und fehlbild_labels; je Tabelle <name>.csv, nicht eingecheckt. Eigener Cluster über
# ML2_PORT (Standard 55490) und ML2_SOCKET; PGDATABASE & Co. werden geleert; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${ML2_SOCKET:?ML2_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${ML2_PORT:-55490}" PGUSER=postgres
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"; shift || true
M1=20261016120100_ml2_musterloesungen_stufe2.sql
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung tasks task_solutions task_figures
      task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews pruef_einstellungen task_admin_protokoll
      fehlbild_familien fehlbild_labels'

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 ${3:-} -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'ml2_m[0-9]' <<<"$out" | sed "s#^#  [$2] #" || true
}
neu() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; psql -q -X "postgresql:///$1" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null; }

# ── 1. Basis ohne ML2 + seed, Prod-Fixture, Vorher ──────────────────────────
DB=ml2_test
neu "$DB"
for f in $(ls supabase/migrations/*.sql | sort); do
  [ "$(basename "$f")" = "$M1" ] && continue
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
echo "── VORHER"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/ml2-pruefung.sql
psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(s.task_id || coalesce(s.correct_answers::text,'') || coalesce(s.acceptance::text,'') || coalesce(s.hints::text,'') || t.status, '|' order by s.task_id)) from public.task_solutions s join public.tasks t on t.id = s.task_id" > "$FIX/.unberuehrt_vorher"

# ── 2. M1 zweimal (Idempotenz), dann Nachher ────────────────────────────────
spiele "supabase/migrations/$M1" "$DB" -1      # wie mig: eine Transaktion
spiele "supabase/migrations/$M1" "$DB" -1
echo "── NACHHER"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/ml2-pruefung.sql
nachher=$(psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(s.task_id || coalesce(s.correct_answers::text,'') || coalesce(s.acceptance::text,'') || coalesce(s.hints::text,'') || t.status, '|' order by s.task_id)) from public.task_solutions s join public.tasks t on t.id = s.task_id")
[ "$nachher" = "$(cat "$FIX/.unberuehrt_vorher")" ] && echo "Antworten, Akzeptanz, Hinweise, Status: unverändert" || { echo "ABWEICHUNG an Antworten/Akzeptanz/Hinweisen/Status"; exit 1; }

# ── 3. Optional: Neuaufbau wie die CI ───────────────────────────────────────
if [ "${1:-}" = "--ci" ]; then
  CI=ml2_ci
  neu "$CI"
  for f in $(ls supabase/migrations/*.sql | sort); do spiele "$f" "$CI"; done
  spiele supabase/seed.sql "$CI" >/dev/null
  echo "Neuaufbau: alle $(ls supabase/migrations/*.sql | wc -l) Migrationen + seed ohne Fehler"
fi
