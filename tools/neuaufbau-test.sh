#!/usr/bin/env bash
# neuaufbau-test.sh — spielt alle Migrationen in eine leere lokale Datenbank ein
# und vergleicht das Ergebnis mit Produktion.
#
# Braucht weder Supabase-CLI noch Docker — nur ein lokales Postgres.
#
#   sudo apt install -y postgresql postgresql-client
#   sudo service postgresql start
#   sudo -u postgres createuser -s "$USER"
#
#   bash tools/neuaufbau-test.sh
#
# Das ist der Beweis, dass das Repo Produktion nachbaut. Ohne ihn ist eine
# rekonstruierte Migration eine Vermutung.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

DB="${TESTDB:-edvance_neuaufbau}"
GEGEN_PROD=0; [[ "${1:-}" == "--gegen-prod" ]] && GEGEN_PROD=1
LOCAL="postgresql:///$DB"
[[ "$GEGEN_PROD" -eq 0 || -n "${DATABASE_URL:-}" ]] || { echo "DATABASE_URL nicht gesetzt (nur mit --gegen-prod noetig)."; exit 1; }

ok(){ echo "  ✓ $*"; }; bad(){ echo "  ✗ $*"; }; info(){ echo "  · $*"; }

command -v psql >/dev/null || { bad "psql fehlt"; exit 1; }
pg_isready -q || { bad "Lokales Postgres läuft nicht  →  sudo service postgresql start"; exit 1; }

echo
echo "══ Leere Datenbank"
dropdb --if-exists "$DB" 2>/dev/null
createdb "$DB" || { bad "createdb fehlgeschlagen — Rolle vorhanden? sudo -u postgres createuser -s $USER"; exit 1; }
ok "$DB angelegt"

# ── Supabase-Umfeld nachbilden ──────────────────────────────────────────────
# Die Migrationen setzen Rollen, Schemata und auth.users voraus, die in einer
# Supabase-Instanz vorhanden sind. Ohne diese Grundlage scheitern sie an
# Dingen, die nichts mit deinem Schema zu tun haben.
#
# Quelle ist supabase/test-grundlage.sql — dieselbe Datei, die schema-snapshot.sh
# und .github/workflows/schema.yml einspielen. Hier stand frueher eine zweite,
# eigene Kopie; sie ist beim auth.uid()-Fix auseinandergelaufen (siehe
# docs/jwt-identitaet-befund.md). Eine Grundlage, eine Datei.

echo
echo "══ Grundlage"
psql -q "$LOCAL" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql
[[ $? -eq 0 ]] && ok "Rollen, Schemata, auth.users, auth.uid()" || { bad "Grundlage fehlgeschlagen"; exit 1; }

# ── Migrationen einspielen ──────────────────────────────────────────────────
echo
echo "══ Migrationen"
n=0; fehler=0
for f in $(ls supabase/migrations/*.sql | sort); do
  base=$(basename "$f"); version="${base%%_*}"
  out=$(psql -q "$LOCAL" -v ON_ERROR_STOP=1 -f "$f" 2>&1)
  if [[ $? -ne 0 ]]; then
    bad "$base"
    echo "$out" | grep -E '^(psql:|ERROR|FEHLER|DETAIL|HINWEIS|CONTEXT)' | grep -v NOTICE | head -20 | sed 's/^/       /'
    fehler=$((fehler+1))
    [[ "$fehler" -ge 1 ]] && { echo; bad "Erster Fehler — abgebrochen, Folgefehler wären ohnehin unecht."; break; }
    continue
  fi
  psql -q "$LOCAL" -c "insert into supabase_migrations.schema_migrations (version, name)
                       values ('$version', '${base%.sql}') on conflict do nothing"
  n=$((n+1))
done
echo
info "$n eingespielt, $fehler gescheitert"
[[ "$fehler" -gt 0 ]] && { echo; bad "Erst die Fehler oben beheben."; exit 1; }

# ── Vergleich ───────────────────────────────────────────────────────────────
D="--schema-only --no-owner --no-acl --no-comments --schema public"
SIEB='^--|^$|^SET |^SELECT pg_catalog|restrict '

pg_dump "$LOCAL" $D 2>/dev/null | grep -vE "$SIEB" | sort > /tmp/neu.txt

if [[ "$GEGEN_PROD" -eq 0 ]]; then
  echo
  echo "══ Vergleich mit supabase/schema-erwartet.sql"
  [[ -f supabase/schema-erwartet.sql ]] || { bad "Datei fehlt — bash tools/schema-snapshot.sh"; exit 1; }
  grep -vE "$SIEB" supabase/schema-erwartet.sql | sort > /tmp/soll.txt
  if diff -q /tmp/soll.txt /tmp/neu.txt >/dev/null; then
    ok "Neuaufbau entspricht dem Schnappschuss."
    exit 0
  fi
  bad "Weicht vom Schnappschuss ab. Nach Schemaaenderungen: bash tools/schema-snapshot.sh"
  diff /tmp/soll.txt /tmp/neu.txt | head -30 | sed 's/^/      /'
  exit 1
fi

echo
echo "══ Vergleich mit Produktion"
if ! pg_dump "$DATABASE_URL" $D > /tmp/proddump 2>/tmp/dumperr; then
  bad "Prod nicht erreichbar:"; tail -3 /tmp/dumperr | sed 's/^/      /'; exit 1
fi
grep -vE "$SIEB" /tmp/proddump | sort > /tmp/prod.txt

echo "  neu:  $(wc -l < /tmp/neu.txt) Zeilen"
echo "  prod: $(wc -l < /tmp/prod.txt) Zeilen"
echo
if diff -q /tmp/neu.txt /tmp/prod.txt >/dev/null; then
  ok "Identisch. Das Repo baut Produktion nach."
  exit 0
fi
bad "$(comm -13 /tmp/neu.txt /tmp/prod.txt | wc -l) Zeile(n) nur in Prod, $(comm -23 /tmp/neu.txt /tmp/prod.txt | wc -l) nur im Neuaufbau"
echo
echo "  Nur in Prod (fehlt im Repo):"
comm -13 /tmp/neu.txt /tmp/prod.txt | head -25 | cut -c1-110 | sed 's/^/      /'
echo
echo "  Nur im Neuaufbau:"
comm -23 /tmp/neu.txt /tmp/prod.txt | head -15 | cut -c1-110 | sed 's/^/      /'
echo
info "vollständig:  diff /tmp/neu.txt /tmp/prod.txt"
exit 1
