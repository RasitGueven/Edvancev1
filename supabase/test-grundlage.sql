-- test-grundlage.sql
--
-- Bildet das nach, was eine Supabase-Instanz mitbringt und die Migrationen
-- voraussetzen: Rollen, Schemata, auth.users, auth.uid(). Ohne das scheitern
-- sie an Dingen, die mit dem eigenen Schema nichts zu tun haben.
--
-- Nur für Testdatenbanken. Nie gegen Produktion ausführen.
--
-- Genutzt von tools/neuaufbau-test.sh und .github/workflows/schema.yml

create schema if not exists extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto   with schema extensions;

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

-- instance_id/aud/role gehoeren zur echten auth.users und fehlten hier. Die
-- Invariantentests in supabase/tests/ schreiben sie mit
-- (`insert into auth.users (id, email, instance_id, aud, role)`) — gegen den
-- alten Stub scheiterte jeder von ihnen an einer fehlenden Spalte, statt an
-- dem, was er pruefen soll. Aufgefallen ist es erst, als die Tests in
-- .github/workflows/schema.yml aufgenommen wurden; vorher liefen sie nur
-- gegen `npx supabase test db`, wo die vollstaendige Tabelle existiert.
create table if not exists auth.users (
  id                 uuid primary key default gen_random_uuid(),
  email              text,
  instance_id        uuid,
  aud                text,
  role               text,
  raw_user_meta_data jsonb,
  created_at         timestamptz default now()
);

-- Supabase liefert die Claims als JSON in request.jwt.claims; einzelne
-- request.jwt.claim.<name> sind die aeltere Form. Beide muessen hier ankommen:
-- ein Stub, der nur eine davon liest, laesst Pruefskripte gruen leuchten, die
-- mit der anderen Form arbeiten — auth.uid() bleibt dann null, und
-- `if not lsa_may_act_for(...)` feuert bei null nicht.
-- Vorrang hat die Einzahlform (siehe supabase/checks/jwt_identitaet.PRUEFUNG.sql).

create or replace function auth.uid() returns uuid language sql stable as $$
  select coalesce(
           nullif(current_setting('request.jwt.claim.sub', true), ''),
           nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
         )::uuid
$$;

create or replace function auth.role() returns text language sql stable as $$
  select coalesce(
           nullif(current_setting('request.jwt.claim.role', true), ''),
           nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
           'anon'
         )
$$;

create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
$$;

create table if not exists storage.buckets (
  id         text primary key,
  name       text not null,
  owner      uuid,
  public     boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists storage.objects (
  id               uuid primary key default gen_random_uuid(),
  bucket_id        text references storage.buckets(id),
  name             text,
  owner            uuid,
  owner_id         text,
  path_tokens      text[],
  metadata         jsonb,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now(),
  last_accessed_at timestamptz default now()
);

create or replace function storage.foldername(name text) returns text[]
  language sql immutable as $fn$ select string_to_array(name, '/') $fn$;

create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key, name text, statements text[]
);

grant usage on schema public, extensions to anon, authenticated, service_role;
