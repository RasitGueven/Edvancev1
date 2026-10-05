#!/usr/bin/env bash
# lena-board-wegwerf-db.sh — frische Wegwerf-DB fuer das Lena-Board (Muster: tools/k9-rest-wegwerf-db.sh).
#
#   bash tools/lena-board-wegwerf-db.sh <db>            # Basis + Lena-Board-Migrationen + seed
#   bash tools/lena-board-wegwerf-db.sh <db> --tests    # dazu pgTAP laden und supabase/tests/lena_board.test.sql
#
# Ablauf wie .github/workflows/schema.yml: supabase/test-grundlage.sql, jede Datei aus
# supabase/migrations in Versionsreihenfolge OHNE --single-transaction, dann supabase/seed.sql.
# "Basis" = alle Migrationen ausser denen dieses Laufs (_pruefung_*). Die Basis wird einmal als
# Vorlage lenaboard_vorlage gebaut (neu, sobald sich die Liste aendert) und per createdb -T kopiert.
# pgTAP ohne Root: PGTAP_SQL zeigt auf pgtap--1.3.4.sql (apt-get download postgresql-18-pgtap,
# dpkg-deb -x). Tests laufen mit PGOPTIONS='-c search_path=public,extensions' wie in CI.
# Nur lokal (Unix-Socket); edvance_shadow und Produktion werden nie angefasst.
set -euo pipefail
DB="${1:?Name der Wegwerf-DB fehlt}"; shift || true
case "$DB" in edvance_shadow|postgres|lenaboard_vorlage) echo "$DB nicht verwenden"; exit 2 ;; esac
URL="postgresql:///$DB"
LAUF='_pruefung_[a-z0-9_]+\.sql$'
VORLAGE=lenaboard_vorlage

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
echo "Basis: $(echo "$basis" | grep -c .) Migrationen (Vorlage $kennung); Lena-Board: $(echo "$eigene" | grep -c .) Datei(en); seed ok"

if [ "${1:-}" = "--tests" ]; then
  : "${PGTAP_SQL:?PGTAP_SQL zeigt nicht auf pgtap--1.3.4.sql}"
  psql -q -X "$URL" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" >/dev/null
  sed 's/@extschema@/extensions/g' "$PGTAP_SQL" | PGOPTIONS='-c search_path=extensions,public' psql -q -X "$URL" -v ON_ERROR_STOP=1 >/dev/null
  for t in ${TESTS:-supabase/tests/lena_board.test.sql}; do
    echo "== $t"
    sed 's/^create extension if not exists pgtap.*$/set search_path = public, extensions;/' "$t" \
      | PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 "$URL"
  done
fi
