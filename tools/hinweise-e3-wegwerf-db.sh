#!/usr/bin/env bash
# hinweise-e3-wegwerf-db.sh — Wegwerf-DB für Paket E3 (Muster: tools/slots-wegwerf-db.sh).
#
#   bash tools/hinweise-e3-wegwerf-db.sh <db>          # Basis + seed + Fixture, Abgleich vor/nach der E3-Migration
#   bash tools/hinweise-e3-wegwerf-db.sh <db> --tests  # dazu pgTAP und supabase/tests/session_e3_hinweise.test.sql
#
# Eigener Cluster: Port 55453, Socket /tmp/claude-1000, Daten ~/wegwerf-db-e3. PGDATABASE & Co. werden geleert,
# jeder psql-Aufruf nennt die DB ausdrücklich; nie edvance_shadow, nie Produktion.
# Ablauf wie .github/workflows/schema.yml: supabase/test-grundlage.sql, jede Migration außer E3 in
# Versionsreihenfolge (Vorlage e3_vorlage), dann supabase/seed.sql. Danach legt die Fixture die Aufgaben an, die nur
# in Prod stehen (Fundament, `node tools/hinweise-e3.mjs fixture`), sichert task_solutions und tasks, spielt die
# E3-Migration ein, gleicht ab (tools/hinweise-e3-abgleich.sql) und spielt sie ein zweites Mal ein.
# pgTAP ohne Root: PGTAP_SQL zeigt auf pgtap--1.3.4.sql (apt-get download postgresql-18-pgtap, dpkg-deb -x).
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST=/tmp/claude-1000 PGPORT=55453 PGUSER=postgres
DB="${1:?Name der Wegwerf-DB fehlt}"; shift || true
case "$DB" in edvance_shadow|postgres|e3_vorlage) echo "$DB nicht verwenden"; exit 2 ;; esac
URL="postgresql:///$DB"
E3='20261013175427_hinweise_e3_batu.sql'
VORLAGE=e3_vorlage

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
}

basis=$(ls supabase/migrations/*.sql | sort | grep -v "/$E3\$" || true)
kennung=$(echo "$basis" | md5sum | cut -c1-12)
if [ "$(psql -X -tA postgresql:///postgres -c "select shobj_description(oid, 'pg_database') from pg_database where datname = '$VORLAGE'" 2>/dev/null)" != "$kennung" ]; then
  dropdb --if-exists "$VORLAGE" 2>/dev/null; createdb "$VORLAGE"
  psql -q -X "postgresql:///$VORLAGE" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
  for f in $basis; do spiele "$f" "$VORLAGE"; done
  spiele supabase/seed.sql "$VORLAGE"
  psql -q -X "postgresql:///$VORLAGE" -c "comment on database $VORLAGE is '$kennung'" >/dev/null
fi
dropdb --if-exists "$DB" 2>/dev/null
createdb -T "$VORLAGE" "$DB"
echo "Basis: $(echo "$basis" | grep -c .) Migrationen + seed (Vorlage $kennung)"

fix=$(mktemp); trap 'rm -f "$fix"' EXIT
node tools/hinweise-e3.mjs fixture > "$fix"
spiele "$fix" "$DB"
psql -q -X "$URL" -v ON_ERROR_STOP=1 -c "create schema e3_vorher;
  create table e3_vorher.ts as select * from public.task_solutions;
  create table e3_vorher.tasks as select * from public.tasks;" >/dev/null
spiele "supabase/migrations/$E3" "$DB"
psql -q -X "$URL" -v ON_ERROR_STOP=1 -c "create table e3_vorher.ts_nach1 as select * from public.task_solutions;" >/dev/null
spiele "supabase/migrations/$E3" "$DB"
psql -X -tA "$URL" -v ON_ERROR_STOP=1 -f tools/hinweise-e3-abgleich.sql

if [ "${1:-}" = "--tests" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  psql -q -X "$URL" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" >/dev/null
  sed 's/@extschema@/extensions/g' "$PGTAP_SQL" | PGOPTIONS='-c search_path=extensions,public' psql -q -X "$URL" -v ON_ERROR_STOP=1 >/dev/null
  t=supabase/tests/session_e3_hinweise.test.sql
  kopie="$(dirname "$t")/.lauf_session_e3_hinweise.sql"
  sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' "$t" > "$kopie"
  rot=0
  out=$(PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 "$URL" -f "$kopie" 2>&1) || rot=1
  rm -f "$kopie"
  echo "$out"
  grep -qE '^not ok|^# Looks like' <<<"$out" && rot=1
  exit $rot
fi
