-- ============================================================================
-- W5-c: lead_thema_setzen — das aktuelle Thema eines Leads in einem Schritt.
--
-- Zusagen:
--   1) Nur Admin; eine fremde Rolle wird mit 42501 abgewiesen.
--   2) Setzen: das Thema steht als 'aktuell', quelle 'gespraech'.
--   3) Ersetzen: das alte 'aktuell' desselben Fachs faellt weg (geloescht, wie
--      bisher in der Oberflaeche); ein 'behandelt' wird auf 'aktuell' umgestellt.
--   4) Entfernen (null): 'aktuell' weg, 'behandelt' bleibt.
--   5) Atomar: scheitert das Schreiben, steht das alte Thema noch.
--   6) lead_mail_protokollieren: nur Admin, Urheber und Ort werden festgehalten,
--      ohne Ort kein Protokoll.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(14);

\set admin_uid 'dddddddd-0005-4000-8000-000000000001'
\set coach_uid 'dddddddd-0005-4000-8000-000000000002'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'w5c-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'w5c-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'w5c-admin@test.local', 'admin', 'W5c Admin'),
  (:'coach_uid', 'w5c-coach@test.local', 'coach', 'W5c Coach');

-- Eigene Themen, unabhaengig vom Katalog.
insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_w5c_a', 'mathematik', 8, 'erste', 'W5c A', 9001),
  ('zz_w5c_b', 'mathematik', 8, 'erste', 'W5c B', 9002),
  ('zz_w5c_c', 'mathematik', 8, 'erste', 'W5c C', 9003);

insert into leads (full_name, class_level, subjects, status)
values ('W5c Lead', 9, '{Mathematik}', 'contacted');
select (select id from leads where full_name = 'W5c Lead') as lead \gset

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- 1) Fremde Rolle
select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.lead_thema_setzen(%L, 'mathematik', 'zz_w5c_a')$f$, :'lead'),
  '42501', NULL, 'Coach darf kein Thema setzen');
select throws_ok(
  format($f$select public.lead_mail_protokollieren(%L, 'terminbestaetigung', 'x@test.local', 'Ort')$f$, :'lead'),
  '42501', NULL, 'Coach darf keinen Versand protokollieren');

select pg_temp.act_as(:'admin_uid');

-- 2) Setzen
select lives_ok(
  format($f$select public.lead_thema_setzen(%L, 'mathematik', 'zz_w5c_a')$f$, :'lead'),
  'Admin setzt ein Thema');
select results_eq(
  format($f$select thema_key, quelle from lead_themen where lead_id = %L and status = 'aktuell'$f$, :'lead'),
  $$values ('zz_w5c_a'::text, 'gespraech'::text)$$,
  'Setzen: Thema aktuell, Quelle Gespraech');

-- 3) Ersetzen, mit 'behandelt'-Zeile des neuen Themas
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
values (:'lead', 'mathematik', 'zz_w5c_b', 'behandelt', 'schulplan');
select public.lead_thema_setzen(:'lead', 'mathematik', 'zz_w5c_b');
select is(
  (select count(*)::int from lead_themen where lead_id = :'lead' and thema_key = 'zz_w5c_a'),
  0, 'Ersetzen: altes aktuell ist weg');
select results_eq(
  format($f$select thema_key, quelle from lead_themen where lead_id = %L and status = 'aktuell'$f$, :'lead'),
  $$values ('zz_w5c_b'::text, 'gespraech'::text)$$,
  'Ersetzen: behandelt wurde auf aktuell umgestellt');

-- 4) Entfernen
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
values (:'lead', 'mathematik', 'zz_w5c_c', 'behandelt', 'gespraech');
select public.lead_thema_setzen(:'lead', 'mathematik', null);
select is(
  (select count(*)::int from lead_themen where lead_id = :'lead' and status = 'aktuell'),
  0, 'Entfernen: kein aktuelles Thema mehr');
select is(
  (select count(*)::int from lead_themen where lead_id = :'lead' and status = 'behandelt'),
  1, 'Entfernen: behandelt bleibt');

-- 5) Atomar
select public.lead_thema_setzen(:'lead', 'mathematik', 'zz_w5c_a');
select throws_ok(
  format($f$select public.lead_thema_setzen(%L, 'mathematik', 'zz_w5c_gibt_es_nicht')$f$, :'lead'),
  '23503', NULL, 'Unbekanntes Thema wird abgewiesen');
select is(
  (select thema_key from lead_themen where lead_id = :'lead' and status = 'aktuell'),
  'zz_w5c_a', 'Nach dem Fehlschlag steht das alte Thema noch');

-- 6) Versandprotokoll
select lives_ok(
  format($f$select public.lead_mail_protokollieren(%L, 'terminbestaetigung', 'x@test.local', 'Musterweg 1, Köln', now(), null)$f$, :'lead'),
  'Admin protokolliert einen Versand');
select is(
  (select erfolgt_von from lead_mail_versand where lead_id = :'lead'),
  :'admin_uid'::uuid, 'Urheber ist der Admin');
select is(
  (select ort from lead_mail_versand where lead_id = :'lead'),
  'Musterweg 1, Köln', 'Ort steht im Protokoll');
select throws_ok(
  format($f$select public.lead_mail_protokollieren(%L, 'terminbestaetigung', 'x@test.local', '  ')$f$, :'lead'),
  '23514', NULL, 'Ohne Ort kein Protokoll');

select * from finish();
rollback;
