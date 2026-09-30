#!/usr/bin/env bash
# schema-snapshot.sh — erzeugt supabase/schema-erwartet.sql neu.
#
# Zieht einen rein LESENDEN Schema-Abzug (Schema public) aus der Ziel-DB
# ($DATABASE_URL, sonst aus .env). Keine lokale Datenbank mehr: der Abzug zeigt,
# was in Produktion wirklich steht. Die Datei wird mitcommittet; CI baut alle
# Migrationen in eine leere DB und vergleicht mit ihr — weicht Produktion von
# den Migrationen ab, faellt das dort auf.
#
# Nach jedem Einspielen einer Schemaaenderung ausfuehren:
#     bash tools/schema-snapshot.sh
#
# Sicherheitsnetz: Ziel-DB-Check (current_database() = postgres), keine lokale
# DB (localhost/127.0.0.1 wird abgelehnt), Sitzung read-only erzwungen.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ZIEL="supabase/schema-erwartet.sql"
ENVFILE="${ENVFILE:-.env}"

if [[ -z "${DATABASE_URL:-}" && -f "$ENVFILE" ]]; then
  DATABASE_URL="$(sed -n 's/^DATABASE_URL=//p' "$ENVFILE" | head -1)"
  # .env quotet den Wert in einfachen (oder doppelten) Anfuehrungszeichen.
  DATABASE_URL="${DATABASE_URL%\'}"; DATABASE_URL="${DATABASE_URL#\'}"
  DATABASE_URL="${DATABASE_URL%\"}"; DATABASE_URL="${DATABASE_URL#\"}"
fi
[[ -n "${DATABASE_URL:-}" ]] || { echo "DATABASE_URL fehlt (Umgebung oder \$ENVFILE)."; exit 1; }
case "$DATABASE_URL" in
  *localhost*|*127.0.0.1*) echo "Lokale DB abgelehnt — der Abzug kommt aus der Ziel-DB."; exit 1 ;;
esac

command -v pg_dump >/dev/null || { echo "pg_dump fehlt."; exit 1; }
export PGOPTIONS='-c default_transaction_read_only=on'

echo "── Ziel-DB-Check"
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres \
  || { echo "Ziel-DB ist nicht 'postgres' — Abbruch."; exit 1; }

echo "── Abzug (read-only)"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
{
  echo "-- schema-erwartet.sql"
  echo "-- Erzeugt von tools/schema-snapshot.sh (read-only Abzug der Ziel-DB, Schema public)."
  echo "-- Nicht von Hand bearbeiten — nach dem Einspielen einer Schemaaenderung neu erzeugen."
  echo
  # Rollenlisten in CREATE POLICY alphabetisch: Produktion gibt sie in OID-Reihenfolge
  # aus ("authenticated, anon"), der CI-Neuaufbau alphabetisch — inhaltlich gleich,
  # der zeilengenaue CI-Vergleich waere sonst rot.
  pg_dump "$DATABASE_URL" --schema-only --no-owner --no-acl --no-comments --schema public \
    | grep -vE "^\\\\(un)?restrict " \
    | perl -pe 's/^(CREATE POLICY .*? TO )([a-z_]+(?:, [a-z_]+)+)( )/$1.join(", ", sort split(", ", $2)).$3/e'
} > "$TMP"
mv "$TMP" "$ZIEL"
trap - EXIT

echo
echo "✓ $ZIEL  ($(wc -l < "$ZIEL") Zeilen)"
git diff --stat -- "$ZIEL" 2>/dev/null || true
echo
echo "  Diff pruefen: dort steht, was in Produktion wirklich angekommen ist."
echo "  Dann:  git add $ZIEL"
