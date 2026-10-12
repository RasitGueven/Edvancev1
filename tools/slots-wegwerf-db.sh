#!/usr/bin/env bash
# slots-wegwerf-db.sh — frische Wegwerf-DB fuer Paket SL1 (Muster: tools/lena-board-wegwerf-db.sh).
#
#   bash tools/slots-wegwerf-db.sh <db>            # Basis + Slots-Migrationen + seed
#   bash tools/slots-wegwerf-db.sh <db> --tests    # dazu pgTAP laden und TESTS (Standard: supabase/tests/slots_*.test.sql)
#
# Eigener Cluster: Port 55450, Socket /tmp/claude-1000, Daten ~/wegwerf-db-sl1. PGDATABASE & Co. werden
# geleert, damit nichts still auf edvance_shadow oder Produktion zielt.
# Ablauf wie .github/workflows/schema.yml: supabase/test-grundlage.sql, jede Datei aus supabase/migrations
# in Versionsreihenfolge OHNE --single-transaction, dann supabase/seed.sql. "Basis" = alle Migrationen ausser
# denen dieses Pakets (Versionen 20261013100000–135959). Die Basis wird einmal als Vorlage slots_vorlage gebaut (neu, sobald sich
# die Liste aendert) und per createdb -T kopiert.
# pgTAP ohne Root: PGTAP_SQL zeigt auf pgtap--1.3.4.sql (apt-get download postgresql-18-pgtap, dpkg-deb -x).
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST=/tmp/claude-1000 PGPORT=55450 PGUSER=postgres
DB="${1:?Name der Wegwerf-DB fehlt}"; shift || true
case "$DB" in edvance_shadow|postgres|slots_vorlage) echo "$DB nicht verwenden"; exit 2 ;; esac
URL="postgresql:///$DB"
LAUF='/20261013(1[0-3])[0-9]{4}_[a-z0-9_]+\.sql$'
VORLAGE=slots_vorlage

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
}

basis=$(ls supabase/migrations/*.sql | sort | grep -Ev "$LAUF" || true)
kennung=$(echo "$basis" | md5sum | cut -c1-12)
if [ "$(psql -X -tA postgresql:///postgres -c "select shobj_description(oid, 'pg_database') from pg_database where datname = '$VORLAGE'" 2>/dev/null)" != "$kennung" ]; then
  dropdb --if-exists "$VORLAGE" 2>/dev/null; createdb "$VORLAGE"
  psql -q -X "postgresql:///$VORLAGE" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
  for f in $basis; do spiele "$f" "$VORLAGE"; done
  psql -q -X "postgresql:///$VORLAGE" -c "comment on database $VORLAGE is '$kennung'" >/dev/null
fi
dropdb --if-exists "$DB" 2>/dev/null
createdb -T "$VORLAGE" "$DB"
eigene=$(ls supabase/migrations/*.sql | sort | grep -E "$LAUF" || true)
for f in $eigene; do spiele "$f" "$DB"; done
spiele supabase/seed.sql "$DB"
echo "Basis: $(echo "$basis" | grep -c .) Migrationen (Vorlage $kennung); Slots: $(echo "$eigene" | grep -c .) Datei(en); seed ok"

if [ "${1:-}" = "--tests" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  psql -q -X "$URL" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" >/dev/null
  sed 's/@extschema@/extensions/g' "$PGTAP_SQL" | PGOPTIONS='-c search_path=extensions,public' psql -q -X "$URL" -v ON_ERROR_STOP=1 >/dev/null
  rot=0
  for t in ${TESTS:-$(ls supabase/tests/slots_*.test.sql 2>/dev/null | sort)}; do
    b=$(basename "$t" .test.sql)
    # \ir in den Tests loest relativ zur Datei auf: Kopie neben das Original legen.
    kopie="$(dirname "$t")/.lauf_$b.sql"
    sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' "$t" > "$kopie"
    if out=$(PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 "$URL" -f "$kopie" 2>&1) \
       && ! grep -qE '^not ok|^# Looks like' <<<"$out"; then
      echo "  ok     $b ($(grep -cE '^ok ' <<<"$out") Zusicherungen)"
    else
      echo "  ROT    $b"; grep -E '^not ok|^#|ERROR|FEHLER|psql:' <<<"$out" | head -25; rot=1
    fi
    [ -n "${ZEIGE:-}" ] && echo "$out"
    rm -f "$kopie"
  done
  exit $rot
fi
