#!/usr/bin/env bash
# schema-snapshot.sh — erzeugt supabase/schema-erwartet.sql neu.
#
# Baut die Migrationen in eine leere lokale Datenbank ein und legt den
# Schema-Abzug als erwarteten Stand ab. Die Datei wird mitcommittet; damit
# wird jede Schemaänderung im PR-Diff sichtbar und ist prüfbar, statt in
# 200 Zeilen SQL verborgen zu bleiben.
#
# Nach jeder neuen Migration ausführen:
#     bash tools/schema-snapshot.sh
#
# Braucht ein lokales Postgres, keine Zugangsdaten zu Produktion.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

DB="${SNAPDB:-edvance_snapshot}"
ZIEL="supabase/schema-erwartet.sql"

command -v psql >/dev/null || { echo "psql fehlt."; exit 1; }
pg_isready -q || { echo "Lokales Postgres läuft nicht  →  sudo service postgresql start"; exit 1; }

echo "── Leere Datenbank"
dropdb --if-exists "$DB"
createdb "$DB"

echo "── Grundlage"
psql -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql

echo "── Migrationen"
n=0
for f in $(ls supabase/migrations/*.sql | sort); do
  if ! psql -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f "$f" >/dev/null 2>/tmp/snap_err; then
    echo "✗ $(basename "$f")"
    grep -vE '^(NOTICE|HINWEIS)' /tmp/snap_err | head -20
    echo
    echo "Schnappschuss nicht erzeugt — erst die Migration reparieren."
    exit 1
  fi
  n=$((n+1))
done
echo "   $n eingespielt"

echo "── Abzug"
{
  echo "-- schema-erwartet.sql"
  echo "-- Erzeugt von tools/schema-snapshot.sh am $(date -u +%F)."
  echo "-- Stand nach allen Migrationen in supabase/migrations/."
  echo "-- Nicht von Hand bearbeiten — nach Schemaänderungen neu erzeugen."
  echo
  pg_dump "postgresql:///$DB" --schema-only --no-owner --no-acl --no-comments --schema public
} > "$ZIEL"

dropdb "$DB"

echo
echo "✓ $ZIEL  ($(wc -l < "$ZIEL") Zeilen)"
git diff --stat -- "$ZIEL" 2>/dev/null || true
echo
echo "  Änderungen im Diff prüfen — dort steht, was deine Migration wirklich tut."
echo "  Dann:  git add $ZIEL"
