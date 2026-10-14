-- ============================================================================
-- Konto K1 (Migration 20261014121000_konto_k1): Stand der Mitarbeiterkonten,
-- Vorpruefung der Adresse und Protokoll der Auth-Mails.
--
--   A) mitarbeiter_konto_stand(): nur Admin. Coach, Schueler und ein Konto
--      ohne Profil bekommen 42501.
--   B) Der Stand stimmt: eingeladen (invited_at, nicht bestaetigt), aktiv
--      (bestaetigt), und nur Coaches/Admins stehen in der Liste.
--   C) konto_email_vorhanden() und auth_mail_protokollieren(): nur
--      service_role; das Protokoll lesen nur Admins.
--
-- Eigene Fixtures, alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: Wegwerf-DB aus allen Migrationen + seed.sql + pgTAP,
--       PGOPTIONS='-c search_path=public,extensions')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(20);

-- Die CI-Grundlage (supabase/test-grundlage.sql) bildet auth.users nur mit den
-- noetigsten Spalten nach. In Supabase gibt es diese drei; hier nachziehen.
alter table auth.users add column if not exists invited_at timestamptz;
alter table auth.users add column if not exists email_confirmed_at timestamptz;
alter table auth.users add column if not exists last_sign_in_at timestamptz;

\set admin_uid  '0c100000-0000-4000-8000-00000000000a'
\set coach_akt  '0c100000-0000-4000-8000-00000000000c'
\set coach_neu  '0c100000-0000-4000-8000-00000000000e'
\set kind_uid   '0c100000-0000-4000-8000-00000000000d'
\set ohne_uid   '0c100000-0000-4000-8000-0000000000ff'

insert into auth.users (id, email, instance_id, aud, role, invited_at, email_confirmed_at, last_sign_in_at) values
  (:'admin_uid', 'k1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     null, '2026-01-02T08:00:00Z', '2026-10-13T08:00:00Z'),
  (:'coach_akt', 'k1-coach-aktiv@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     '2026-10-01T09:00:00Z', '2026-10-02T10:00:00Z', '2026-10-02T10:00:05Z'),
  (:'coach_neu', 'k1-coach-neu@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     '2026-10-14T07:30:00Z', null, null),
  (:'kind_uid',  'k1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     null, '2026-09-01T00:00:00Z', null),
  (:'ohne_uid',  'k1-ohne@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     '2026-10-10T00:00:00Z', null, null);
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'k1-admin@test.local',        'admin',   'K1 Admin'),
  (:'coach_akt', 'k1-coach-aktiv@test.local',  'coach',   'K1 Coach Aktiv'),
  (:'coach_neu', 'k1-coach-neu@test.local',    'coach',   'K1 Coach Neu'),
  (:'kind_uid',  'k1-kind@test.local',         'student', 'K1 Kind');

-- SQLSTATE eines Aufrufs, "kein Fehler" wenn er durchlaeuft.
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;

create function pg_temp.als(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

grant execute on function pg_temp.fehler(text) to authenticated, service_role;

-- --- A) nur Admin ------------------------------------------------------------
set local role authenticated;

select pg_temp.als(:'coach_akt');
select is(pg_temp.fehler('select * from public.mitarbeiter_konto_stand()'), '42501', 'A1 Coach -> 42501');
select pg_temp.als(:'kind_uid');
select is(pg_temp.fehler('select * from public.mitarbeiter_konto_stand()'), '42501', 'A2 Schueler -> 42501');
select pg_temp.als(:'ohne_uid');
select ok(public.get_my_role() is null, 'A3 Fixture: angemeldet ohne Profil, get_my_role() ist NULL');
select is(pg_temp.fehler('select * from public.mitarbeiter_konto_stand()'), '42501', 'A4 ohne Profil -> 42501');

-- --- B) Admin bekommt den richtigen Stand -------------------------------------
select pg_temp.als(:'admin_uid');
select is(pg_temp.fehler('select * from public.mitarbeiter_konto_stand()'), 'kein Fehler', 'B1 Admin darf');

select is(
  (select count(*)::int from public.mitarbeiter_konto_stand() s
    where s.id in (:'admin_uid', :'coach_akt', :'coach_neu', :'kind_uid', :'ohne_uid')),
  3, 'B2 nur Coaches und Admins (kein Schueler, kein Konto ohne Profil)');

select is(
  (select row(s.eingeladen_at, s.bestaetigt_at, s.zuletzt_angemeldet_at)::text
     from public.mitarbeiter_konto_stand() s where s.id = :'coach_neu'),
  row('2026-10-14T07:30:00Z'::timestamptz, null::timestamptz, null::timestamptz)::text,
  'B3 eingeladener Coach: eingeladen, nicht bestaetigt');

select is(
  (select row(s.eingeladen_at, s.bestaetigt_at)::text
     from public.mitarbeiter_konto_stand() s where s.id = :'coach_akt'),
  row('2026-10-01T09:00:00Z'::timestamptz, '2026-10-02T10:00:00Z'::timestamptz)::text,
  'B4 aktiver Coach: bestaetigt seit der Annahme');

select is(
  (select s.eingeladen_at is null and s.bestaetigt_at is not null
     from public.mitarbeiter_konto_stand() s where s.id = :'admin_uid'),
  true, 'B5 Bestandskonto ohne Einladung: bestaetigt (Entscheidung 9)');

-- --- C) Vorpruefung und Protokoll: nur service_role --------------------------
select is(pg_temp.fehler($$select public.konto_email_vorhanden('x@y.z')$$), '42501',
  'C1 konto_email_vorhanden fuer authenticated gesperrt');
select is(pg_temp.fehler($$select public.auth_mail_protokollieren('invite', 'x@y.z')$$), '42501',
  'C2 auth_mail_protokollieren fuer authenticated gesperrt');
select is(pg_temp.fehler($$insert into public.auth_mail_versand (art, empfaenger) values ('invite', 'x@y.z')$$),
  '42501', 'C3 kein direktes Schreiben ins Protokoll');

reset role;
set local role anon;
select is(pg_temp.fehler('select * from public.mitarbeiter_konto_stand()'), '42501', 'C4 anon -> 42501');
reset role;

set local role service_role;
select is(public.konto_email_vorhanden('  K1-Coach-Neu@test.local '), true,
  'C5 vorhandene Adresse, Gross-/Kleinschreibung und Leerzeichen egal');
select is(public.konto_email_vorhanden('k1-gibt-es-nicht@test.local'), false, 'C6 freie Adresse');
select ok(public.auth_mail_protokollieren('recovery', 'k1-coach-aktiv@test.local', :'coach_akt', null) is not null,
  'C7 service_role protokolliert');
select ok(public.auth_mail_protokollieren('invite', 'k1-coach-neu@test.local', :'coach_neu', '  ') is not null,
  'C8 leerer Fehler wird zu null');
reset role;

set local role authenticated;
select pg_temp.als(:'coach_akt');
select is((select count(*)::int from public.auth_mail_versand where empfaenger like 'k1-%'), 0,
  'C9 Coach sieht das Protokoll nicht');
select pg_temp.als(:'admin_uid');
select is((select count(*)::int from public.auth_mail_versand where empfaenger like 'k1-%' and fehler is null), 2,
  'C10 Admin liest das Protokoll');
reset role;

select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'public' and table_name = 'auth_mail_versand'
      and column_name ~* '(token|link|url|hash)'),
  0, 'C11 das Protokoll hat keine Spalte fuer Token oder Link');

select * from finish();
rollback;
