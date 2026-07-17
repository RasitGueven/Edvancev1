-- ============================================================================
-- A2 (S5): lead_delete — vollständige, nachweisbare Löschung. Nur Admin.
-- Verweigert bei status='converted' (Aufbewahrungspflicht). Nach der Löschung
-- kein verwaistes Datum auf den Lead.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(8);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
\set student_uid 'cccccccc-cccc-cccc-cccc-cccccccccccc'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'a2-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'a2-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'admin_uid',   'a2-admin@test.local',   'admin',   'A2 Admin'),
  (:'student_uid', 'a2-student@test.local', 'student', 'A2 Schueler');

-- Ein löschbarer Lead (status='new') mit zwei Einschätzungen …
insert into leads (full_name, class_level, subjects, status)
values ('A2 Loeschbar', 8, '{Mathematik}', 'new');
-- … und ein konvertierter Lead, der NICHT über diesen Weg fällt.
insert into leads (full_name, class_level, subjects, status)
values ('A2 Konvertiert', 8, '{Mathematik}', 'converted');

select (select id from leads where full_name = 'A2 Loeschbar')    as lead_del,
       (select id from leads where full_name = 'A2 Konvertiert')  as lead_conv
\gset

insert into lead_assessments (lead_id, source, note) values
  (:'lead_del', 'parent', 'E-Einschätzung'),
  (:'lead_del', 'child',  'K-Einschätzung');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- Nur Admin
-- ============================================================================
select pg_temp.act_as(:'student_uid');
select throws_ok(
  format($f$select public.lead_delete(%L)$f$, :'lead_del'),
  '42501', NULL,
  'Ein Nicht-Admin darf keinen Lead löschen'
);

-- ============================================================================
-- Verweigert bei converted
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.lead_delete(%L)$f$, :'lead_conv'),
  'P0001', NULL,
  'Ein konvertierter Lead wird nicht gelöscht (Aufbewahrungspflicht)'
);

select is(
  (select count(*) from leads where id = :'lead_conv'),
  1::bigint,
  'Der konvertierte Lead existiert nach dem verweigerten Löschen unverändert'
);

-- ============================================================================
-- Löschung des löschbaren Leads — vollständig und nachweisbar
-- ============================================================================
select lives_ok(
  format($f$select public.lead_delete(%L)$f$, :'lead_del'),
  'Admin löscht den löschbaren Lead'
);

select is(
  (select count(*) from leads where id = :'lead_del'),
  0::bigint,
  'Der Lead ist weg'
);

select is(
  (select count(*) from lead_assessments where lead_id = :'lead_del'),
  0::bigint,
  'Keine verwaiste Einschätzung auf den gelöschten Lead (FK on delete cascade greift)'
);

-- Der globale Nachweis: keine Einschätzung zeigt auf einen nicht mehr
-- existierenden Lead — auf keiner Tabelle bleibt ein Rest.
select is(
  (select count(*) from lead_assessments la
     where not exists (select 1 from leads l where l.id = la.lead_id)),
  0::bigint,
  'Nach der Löschung existiert kein verwaistes Datum, das auf den Lead verweist'
);

-- ============================================================================
-- Nicht existierender Lead
-- ============================================================================
select throws_ok(
  $f$select public.lead_delete('00000000-0000-0000-0000-000000000000'::uuid)$f$,
  'P0002', NULL,
  'lead_delete auf einen unbekannten Lead meldet sauber „nicht gefunden"'
);

select * from finish();
rollback;
