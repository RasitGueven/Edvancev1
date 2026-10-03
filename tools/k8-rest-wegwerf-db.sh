#!/usr/bin/env bash
# k8-rest-wegwerf-db.sh — frische Wegwerf-DB aus den Migrationen des Repos (Lauf W4 K8-Rest).
#
#   bash tools/k8-rest-wegwerf-db.sh <db>                    # ALLE Migrationen, zweiter Lauf der K8-Rest-Dateien
#   bash tools/k8-rest-wegwerf-db.sh <db> <datei.sql> ...    # Basis + NUR diese K8-Rest-Dateien (zweimal)
#
# Muster aus den Vorlaeufen: CI-Grundlage, dann jede Datei aus supabase/migrations in
# Versionsreihenfolge, OHNE --single-transaction (wie .github/workflows/schema.yml), dazu
# ein Admin-Profil fuer die Pruefskripte. "Basis" = alle Migrationen ausser denen dieses
# Laufs (Muster unten); so stoeren sich parallele Themen nicht an halbfertigen Dateien.
# Idempotenz: die K8-Rest-Dateien laufen ein zweites Mal; jede Tabelle, die sie fuellen,
# muss danach dieselbe Zeilenzahl haben.
# Nur lokal (Unix-Socket); die alte Shadow-DB edvance_shadow wird nicht angefasst.
set -euo pipefail
DB="${1:?Name der Wegwerf-DB fehlt}"; shift
case "$DB" in edvance_shadow|postgres) echo "$DB nicht verwenden"; exit 2 ;; esac
URL="postgresql:///$DB"
LAUF='_k8_(lgs|stoch|flaeche|winkel)\.sql$|_thema_einstieg_k8_rest\.sql$'

spiele() {
  if ! out=$(psql -q "$URL" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT' | head -8; exit 1
  fi
}
zaehle() {
  psql -tA "$URL" -c "select (select count(*) from skills)||' skills, '||(select count(*) from skill_kante)||' kanten, '||
    (select count(*) from fehlbild_labels)||' fehlbilder, '||(select count(*) from tasks)||' tasks, '||
    (select count(*) from task_solutions)||' loesungen, '||(select count(*) from task_figures)||' figuren, '||
    (select count(*) from thema_einstieg)||' einstiege'"
}

dropdb --if-exists "$DB" 2>/dev/null
createdb "$DB"
psql -q "$URL" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
if [ $# -gt 0 ]; then
  eigene=("$@")
  basis=$(ls supabase/migrations/*.sql | sort | grep -Ev "$LAUF" || true)
else
  eigene=($(ls supabase/migrations/*.sql | sort | grep -E "$LAUF" || true))
  basis=$(ls supabase/migrations/*.sql | sort | grep -Ev "$LAUF" || true)
fi
n=0
for f in $basis; do spiele "$f"; n=$((n + 1)); done
psql -q "$URL" -v ON_ERROR_STOP=1 \
  -c "insert into auth.users (id, email) values (gen_random_uuid(), 'zz_admin@edvance.invalid')" \
  -c "insert into profiles (id, email, role, full_name) select id, email, 'admin', 'ZZ Admin' from auth.users where email='zz_admin@edvance.invalid'" >/dev/null
# Eigene Dateien in Versionsreihenfolge (Reihenfolge der Argumente zaehlt nicht).
sortiert=$(printf '%s\n' "${eigene[@]}" | sort)
for f in $sortiert; do spiele "$f"; done
erst=$(zaehle)
for f in $sortiert; do spiele "$f"; done
zweit=$(zaehle)
echo "Basis: $n Migrationen; K8-Rest: $(echo "$sortiert" | grep -c . ) Datei(en)"
echo "nach Lauf 1: $erst"
echo "nach Lauf 2: $zweit"
[ "$erst" = "$zweit" ] && echo "IDEMPOTENT: ok" || { echo "IDEMPOTENT: NEIN"; exit 1; }
