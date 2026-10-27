-- ============================================================================
-- Reihe 1 · D4b Session-Tablet liest den Themenbaum seines Kindes (ThemenbaumAusschnitt im Check-out von C).
--   1) Tablet mit aktiver Zuweisung: kompetenz_offen und home_uebung_kurz des zugewiesenen Kindes
--   2) nie ein anderes Kind; nach gelöster Zuweisung oder beendeter Session nichts mehr
--   3) melden darf das Tablet nie (home_uebung_melden bleibt beim Kind)
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set coach  'dddddddd-d4b0-4000-8000-000000000001'
\set tablet 'dddddddd-d4b0-4000-8000-000000000002'
\set k1     'dddddddd-d4b0-4000-8000-000000000003'
\set k2     'dddddddd-d4b0-4000-8000-000000000004'
insert into auth.users (id, email, instance_id, aud, role)
select u, 'd4b-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'coach'::uuid, 'coach'), (:'tablet', 'tablet'), (:'k1', 'k1'), (:'k2', 'k2')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'coach', 'd4b-coach@test.local', 'coach', 'ZZ Coach'), (:'tablet', 'd4b-tablet@test.local', 'student', 'ZZ Tablet'),
  (:'k1', 'd4b-k1@test.local', 'student', 'Batu Test'), (:'k2', 'd4b-k2@test.local', 'student', 'Mira Test');
insert into platz_devices (profile_id, label, tablet_nr) values (:'tablet', 'ZZ D4b Tablet', 5);
create or replace function pg_temp.kind(p_profil uuid) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Kind', 'ZZ', 'vertrag', 9) returning id into v_lead;
  insert into students (class_level, profile_id) values (9, p_profil) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname)
  select v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 30, 'vor_ort', v_st,
         date_trunc('month', current_date)::date, current_date + 300, date_trunc('month', current_date)::date + 13,
         t.id, 12, tl.einheiten, 'Mathematik', 9, 'ZZ', 'Kind'
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = 12 where t.name = 'Basic';
  return v_st;
end $$;
select pg_temp.kind(:'k1') as s1 \gset
select pg_temp.kind(:'k2') as s2 \gset
select set_config('edvance.session_rpc', '1', true);
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach', 'ZZ Raum', now() - interval '10 minutes', 'active', now() - interval '10 minutes') returning id as sess \gset
select set_config('edvance.session_rpc', '', true);
insert into session_students (session_id, student_id, attendance) values (:'sess', :'s1', 'present'), (:'sess', :'s2', 'present');
insert into session_tablets (session_id, student_id, tablet_nr, geraet_id, zugewiesen_von)
values (:'sess', :'s1', 5, :'tablet', :'coach') returning id as zuw \gset

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

select pg_temp.als(:'tablet');
set local role authenticated;
select ok((select count(*) from kompetenz_offen(:'s1')) > 0, '1 Tablet liest kompetenz_offen seines Kindes');
select lives_ok(format('select * from home_uebung_kurz(%L)', :'s1'), '1 Tablet liest home_uebung_kurz seines Kindes');
select throws_ok(format('select * from kompetenz_offen(%L)', :'s2'), '42501', null, '2 nie ein anderes Kind');
select throws_ok($$select home_uebung_melden('zz', 1, 60)$$, '42501', null, '3 das Tablet meldet keine Übung');
reset role;
update session_tablets set geloest_am = now() where id = :'zuw';
select pg_temp.als(:'tablet');
set local role authenticated;
select throws_ok(format('select * from kompetenz_offen(%L)', :'s1'), '42501', null, '2 nach gelöster Zuweisung nichts mehr');
reset role;

select * from finish();
rollback;
