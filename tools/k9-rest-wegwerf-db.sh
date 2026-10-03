#!/usr/bin/env bash
# k9-rest-wegwerf-db.sh — frische Wegwerf-DB aus den Migrationen des Repos (Lauf W4 K9-Rest).
#
#   bash tools/k9-rest-wegwerf-db.sh <db>                  # Basis + ALLE K9-Rest-Dateien, zweiter Lauf
#   bash tools/k9-rest-wegwerf-db.sh <db> <datei.sql> ...  # Basis + NUR diese K9-Rest-Dateien (zweimal)
#
# Muster der Vorlaeufe (K8-Rest: tools/k8-rest-wegwerf-db.sh): CI-Grundlage, dann jede Datei aus
# supabase/migrations in Versionsreihenfolge, OHNE --single-transaction (wie
# .github/workflows/schema.yml), dazu ein Admin-Profil fuer die Pruefskripte. "Basis" = alle
# Migrationen ausser denen dieses Laufs. Die Basis wird einmal als Vorlage k9rest_vorlage gebaut
# (neu, sobald sich die Liste der Basis-Dateien aendert) und per createdb -T kopiert.
# Idempotenz: die K9-Rest-Dateien laufen ein zweites Mal; jede Tabelle, die sie fuellen, muss
# danach dieselbe Zeilenzahl haben. Nur lokal (Unix-Socket); edvance_shadow wird nie angefasst.
set -euo pipefail
DB="${1:?Name der Wegwerf-DB fehlt}"; shift
case "$DB" in edvance_shadow|postgres|k9rest_vorlage) echo "$DB nicht verwenden"; exit 2 ;; esac
URL="postgresql:///$DB"
LAUF='_k9_(wurzel|potenz|quadrgl|quadrfkt|pythagoras|koerper|bedingt|aehnlich)\.sql$|_thema_einstieg_k9_rest\.sql$'
VORLAGE=k9rest_vorlage

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL' | head -8; exit 1
  fi
}
zaehle() {
  psql -X -tA "$URL" -c "select (select count(*) from skills)||' skills, '||(select count(*) from skill_kante)||' kanten, '||
    (select count(*) from fehlbild_labels)||' fehlbilder, '||(select count(*) from tasks)||' tasks, '||
    (select count(*) from task_solutions)||' loesungen, '||(select count(*) from task_figures)||' figuren, '||
    (select count(*) from thema_einstieg)||' einstiege'"
}

basis=$(ls supabase/migrations/*.sql | sort | grep -Ev "$LAUF" || true)
kennung=$(echo "$basis" | md5sum | cut -c1-12)
if [ "$(psql -X -tA postgresql:///postgres -c "select shobj_description(oid, 'pg_database') from pg_database where datname = '$VORLAGE'" 2>/dev/null)" != "$kennung" ]; then
  dropdb --if-exists "$VORLAGE" 2>/dev/null; createdb "$VORLAGE"
  psql -q -X "postgresql:///$VORLAGE" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
  for f in $basis; do spiele "$f" "$VORLAGE"; done
  psql -q -X "postgresql:///$VORLAGE" -v ON_ERROR_STOP=1 \
    -c "insert into auth.users (id, email) values (gen_random_uuid(), 'zz_admin@edvance.invalid')" \
    -c "insert into profiles (id, email, role, full_name) select id, email, 'admin', 'ZZ Admin' from auth.users where email='zz_admin@edvance.invalid'" \
    -c "comment on database $VORLAGE is '$kennung'" >/dev/null
fi
dropdb --if-exists "$DB" 2>/dev/null
createdb -T "$VORLAGE" "$DB"
if [ $# -gt 0 ]; then eigene=("$@"); else eigene=($(ls supabase/migrations/*.sql | sort | grep -E "$LAUF" || true)); fi
sortiert=$(printf '%s\n' "${eigene[@]}" | sort)
for f in $sortiert; do spiele "$f" "$DB"; done
erst=$(zaehle)
for f in $sortiert; do spiele "$f" "$DB"; done
zweit=$(zaehle)
echo "Basis: $(echo "$basis" | grep -c .) Migrationen (Vorlage $kennung); K9-Rest: $(echo "$sortiert" | grep -c .) Datei(en)"
echo "nach Lauf 1: $erst"
echo "nach Lauf 2: $zweit"
[ "$erst" = "$zweit" ] && echo "IDEMPOTENT: ok" || { echo "IDEMPOTENT: NEIN"; exit 1; }
