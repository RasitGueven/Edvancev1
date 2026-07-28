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
LOCAL="postgresql:///$DB"
[[ -n "${DBURL:-}" ]] || { echo "DBURL nicht gesetzt."; exit 1; }

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

echo
echo "══ Grundlage"
psql -q "$LOCAL" -v ON_ERROR_STOP=1 <<'SQL'
create schema if not exists extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto with schema extensions;

do $$
declare r text;
begin
  foreach r in array array['anon','authenticated','service_role','authenticator',
                           'supabase_admin','supabase_auth_admin','supabase_storage_admin']
  loop
    if not exists (select 1 from pg_roles where rolname = r) then
      execute format('create role %I nologin noinherit', r);
    end if;
  end loop;
end $$;

create schema if not exists auth;
create schema if not exists storage;
create schema if not exists extensions;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  raw_user_meta_data jsonb,
  created_at timestamptz default now()
);

create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create or replace function auth.role() returns text language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon')
$$;

create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
$$;

create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key, name text, statements text[]
);

create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  owner uuid,
  public boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text,
  owner uuid,
  owner_id text,
  path_tokens text[],
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_accessed_at timestamptz default now()
);

create or replace function storage.foldername(name text) returns text[]
  language sql immutable as $fn$ select string_to_array(name, '/') $fn$;

grant usage on schema public, extensions to anon, authenticated, service_role;
SQL
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
echo
echo "══ Vergleich mit Produktion"
D="--schema-only --no-owner --no-acl --no-comments --schema public"
pg_dump "$LOCAL" $D 2>/dev/null | grep -vE '^--|^$|^SET |^SELECT pg_catalog|restrict ' | sort > /tmp/neu.txt
pg_dump "$DBURL" $D 2>/tmp/dumperr || { bad "Prod nicht erreichbar:"; tail -3 /tmp/dumperr; exit 1; } | grep -vE '^--|^$|^SET |^SELECT pg_catalog|restrict ' | sort > /tmp/prod.txt

echo "  neu:  $(wc -l < /tmp/neu.txt) Zeilen"
echo "  prod: $(wc -l < /tmp/prod.txt) Zeilen"
echo

if diff -q /tmp/neu.txt /tmp/prod.txt >/dev/null; then
  echo "  ════════════════════════════════════════"
  ok  "Identisch. Das Repo baut Produktion nach."
  echo "  ════════════════════════════════════════"
else
  a=$(comm -13 /tmp/neu.txt /tmp/prod.txt | wc -l)
  b=$(comm -23 /tmp/neu.txt /tmp/prod.txt | wc -l)
  bad "$a Zeile(n) nur in Prod, $b nur im Neuaufbau"
  echo
  echo "  Nur in Prod (fehlt im Repo — das ist der kritische Teil):"
  comm -13 /tmp/neu.txt /tmp/prod.txt | head -25 | cut -c1-110 | sed 's/^/      /'
  echo
  echo "  Nur im Neuaufbau (meist harmlos: Reihenfolge, Grundlage oben):"
  comm -23 /tmp/neu.txt /tmp/prod.txt | head -15 | cut -c1-110 | sed 's/^/      /'
  echo
  info "vollständig:  diff /tmp/neu.txt /tmp/prod.txt"
  echo
  exit 1
fi
echo
