-- ============================================================================
-- Session-Rahmen P1, Paket X0: Altlasten, LSA-Start, XP, Coach-Rechte,
-- Zugangscode, Einsatz/LSA-Pool, Testlauf (Migrationen 20261007100000 … 100800).
-- Eigene Fixtures (Quelle 'x0_test'), alles in einer Transaktion, am Ende rollback.
--
-- Lauf: npx supabase test db  (lokal: Wegwerf-DB aus allen Migrationen + pgTAP,
--       PGOPTIONS='-c search_path=public,extensions')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(79);

-- --- Konten ----------------------------------------------------------------
\set admin_uid   '0c000000-0000-4000-8000-00000000000a'
\set coach_uid   '0c000000-0000-4000-8000-00000000000c'
\set coach2_uid  '0c000000-0000-4000-8000-0000000000c2'
\set kind_uid    '0c000000-0000-4000-8000-00000000000d'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',  'x0-admin@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',  'x0-coach@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach2_uid', 'x0-coach2@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',   'x0-kind@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid',  'x0-admin@test.local',  'admin',   'X0 Admin'),
  (:'coach_uid',  'x0-coach@test.local',  'coach',   'X0 Coach'),
  (:'coach2_uid', 'x0-coach2@test.local', 'coach',   'X0 Coach ohne Platz'),
  (:'kind_uid',   'x0-kind@test.local',   'student', 'X0 Kind');

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
end $$;
-- Zahl der von einem UPDATE getroffenen Zeilen (RLS verweigert still).
create function pg_temp.zeilen(p_sql text) returns int language plpgsql as $$
declare n int;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n;
end $$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;
-- Zieht so lange, bis der Core nichts mehr liefert; protokolliert jede Ausgabe.
create function pg_temp.ziehe_alle(p_session uuid) returns uuid[] language plpgsql as $$
declare v uuid; a uuid[] := '{}'; i int := 0;
begin
  select coalesce(array_agg(task_id), '{}') into a from lsa_ausgegeben where session_id = p_session;
  loop
    i := i + 1;
    v := public.lsa_select_next_core(p_session, array['ready'], now());
    exit when v is null or v = any (a) or i > 20;
    insert into lsa_ausgegeben (session_id, task_id) values (p_session, v);
    a := a || v;
  end loop;
  return a;
end $$;
grant execute on all functions in schema pg_temp to authenticated;

-- --- Kinder ----------------------------------------------------------------
--   A  laufender Vertrag, Platz in einer Session des Coaches (spaeter Testkonto)
--   B  ruhende Akte (Vertrag seit 10 Tagen aus)
--   L  Lead ohne Vertrag (provisorisch)
--   C  echtes Kind ohne Vertrag (fuer Admin-Start und Nicht-Testkonto)
--   K  Kind mit eigenem Schuelerkonto (kind_uid)
select gen_random_uuid() as a, gen_random_uuid() as b, gen_random_uuid() as c,
       gen_random_uuid() as k, gen_random_uuid() as la, gen_random_uuid() as lb,
       gen_random_uuid() as ll, gen_random_uuid() as lt \gset
insert into leads (id, full_name, first_name, contact_email, status) values
  (:'la', 'X0 A', 'Anna', 'x0a@example.invalid', 'converted'),
  (:'lb', 'X0 B', 'Ben',  'x0b@example.invalid', 'converted'),
  (:'ll', 'X0 L', 'Lia',  'x0l@example.invalid', 'lsa_freigegeben');
insert into students (id, class_level) values (:'a', 9), (:'b', 9), (:'c', 9);
insert into students (id, class_level, profile_id) values (:'k', 9, :'kind_uid');
select set_config('edvance.allow_provisional', '1', true);
insert into students (class_level, is_provisional, lead_id) values (9, true, :'ll');
select id as l from students where lead_id = :'ll' \gset

insert into vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                       vertragsbeginn, vertrag_ende, abgeschlossen_am, zugangscode) values
  (:'la', 'abgeschlossen', 'aktiv', :'a', 57, 12, (date_trunc('month', current_date) - interval '2 months')::date,
   current_date + 200, current_date - 70, 'EDV-ABCD-EFG2'),
  (:'lb', 'abgeschlossen', 'aktiv', :'b', 57, 12, (date_trunc('month', current_date - 400))::date,
   current_date - 10, (date_trunc('month', current_date - 400))::date - 5, null);

select gen_random_uuid() as platz_session, gen_random_uuid() as test_session \gset
insert into coaching_sessions (id, coach_id, scheduled_at, status) values
  (:'platz_session', :'coach_uid', now() - interval '2 hours', 'active');
insert into session_students (session_id, student_id, attendance) values (:'platz_session', :'a', 'present');

-- LSA-Daten je Kind (je eine Sitzung, eine Antwort, ein Urteil)
select id as irgendeine_aufgabe from tasks order by id limit 1 \gset
select skill_key as irgendein_skill from skills order by skill_key limit 1 \gset
create function pg_temp.lsa_daten(p_student uuid) returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into lsa_sessions (student_id, subject, grade, status, modus, completed_at)
  values (p_student, 'Mathematik', 9, 'completed', 'adaptiv', now()) returning id into v;
  insert into lsa_responses (session_id, task_id, response, correct)
  values (v, (select id from tasks order by id limit 1), '"1"', false);
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt)
  values (v, (select skill_key from skills order by skill_key limit 1), 'traegt', true);
  return v;
end $$;
select pg_temp.lsa_daten(:'a') as lsa_a, pg_temp.lsa_daten(:'b') as lsa_b, pg_temp.lsa_daten(:'l') as lsa_l \gset

-- --- Pool-Fixtures (Test 6/7): nur diese Aufgaben sind aktiv ----------------
update tasks set is_active = false where coalesce(source, '') <> 'x0_test';
select skill_key as pool_skill from skills
 where klasse_herkunft <= 9 and skill_key in (select skill_key from skill_thema)
 order by skill_key limit 1 \gset
select skill_key as test_skill from skills
 where klasse_herkunft <= 9 and skill_key in (select skill_key from skill_thema) and skill_key <> :'pool_skill'
 order by skill_key limit 1 \gset

-- Eigener Cluster: das Freigabe-Gate (pruef_ausschluss) verlangt einen.
insert into subjects (name) values ('X0-Mathematik') returning id as x0_fach \gset
insert into skill_clusters (subject_id, name, class_level_min, class_level_max)
values (:'x0_fach', 'X0 Cluster', 5, 13) returning id as x0_cluster \gset

create function pg_temp.aufgabe(p_ref text, p_skill text, p_status text, p_loesung boolean default true,
                                p_tutorial boolean default false, p_einsatz text[] default '{lsa,session}')
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, source, source_ref, status, is_tutorial, einsatz)
  values ('exercise', 'NUMERIC', 'X0 · ' || p_ref, 'Was ist 2 + 3?', 'I',
          (select id from skill_clusters where name = 'X0 Cluster'), 9, p_skill, 'x0_test', p_ref,
          p_status, p_tutorial, p_einsatz)
  returning id into v;
  if p_loesung then
    insert into task_solutions (task_id, correct_answers, acceptance, solution)
    values (v, '["5"]', '{"canonical": "5"}', '2 + 3 = 5');
  end if;
  return v;
end $$;

select pg_temp.aufgabe('ok',      :'pool_skill', 'ready')                          as t_ok,
       pg_temp.aufgabe('tutorial',:'pool_skill', 'ready', p_tutorial => true)      as t_tut,
       pg_temp.aufgabe('ohne',    :'pool_skill', 'ready', p_loesung => false)      as t_ohne,
       pg_temp.aufgabe('session', :'pool_skill', 'ready', p_einsatz => '{session}') as t_session,
       pg_temp.aufgabe('check',   :'pool_skill', 'ready', p_einsatz => '{check}')   as t_check,
       pg_temp.aufgabe('d-ok',    :'test_skill', 'draft')                          as d_ok,
       pg_temp.aufgabe('d-bad',   :'test_skill', 'review')                         as d_bad \gset
insert into task_pruef_ausschluss (task_id, grund) values (:'d_bad', 'x0: von Hand ausgeschlossen');

-- ============================================================================
-- 1 · Schuelerkonto startet keine LSA; Coach nur ueber einen Platz
-- ============================================================================
select pg_temp.act_as(:'kind_uid');
select throws_ok(format('select public.lsa_start(%L, 9, %L)', :'k', 'Mathematik'), '42501', null,
  '1: Schuelerkonto, eigenes Kind → lsa_start 42501');
select throws_ok(format('select public.lsa_start(%L, 9, %L)', :'a', 'Mathematik'), '42501', null,
  '1: Schuelerkonto, fremdes Kind → lsa_start 42501');
select throws_ok(format('select public.lsa_start(%L, 9, %L, %L)', :'k', 'Mathematik', 'fest'), '42501', null,
  '1: Schuelerkonto, fester Modus → lsa_start 42501');
select throws_ok(format('select public.lead_lsa_freigeben(%L, 9, %L)', :'ll', 'Mathematik'), '42501', null,
  '1: Schuelerkonto → lead_lsa_freigeben 42501');
set local role authenticated;
select throws_ok(format($$insert into lsa_sessions (student_id, subject, grade, status) values (%L, 'Mathematik', 9, 'in_progress')$$, :'k'),
  '42501', null, '1: Schuelerkonto → direktes INSERT in lsa_sessions abgelehnt');
reset role;

select pg_temp.act_as(:'coach2_uid');
select throws_ok(format('select public.lsa_start(%L, 9, %L)', :'a', 'Mathematik'), '42501', null,
  '1: Coach ohne Platz des Kindes → lsa_start 42501');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format('select public.lsa_start(%L, 9, %L)', :'c', 'Mathematik'), '42501', null,
  '1: Coach, Kind ohne Platz bei ihm → lsa_start 42501');
select is(pg_temp.fehler(format('select public.lsa_start(%L, 9, %L)', :'a', 'Mathematik')), 'kein Fehler',
  '1: Coach mit Platz des Kindes → lsa_start erlaubt');
set local role authenticated;
select throws_ok(format($$insert into lsa_sessions (student_id, subject, grade, status) values (%L, 'Physik', 9, 'in_progress')$$, :'a'),
  '42501', null, '1: Coach → direktes INSERT in lsa_sessions abgelehnt');
reset role;
update lsa_sessions set status = 'aborted' where student_id = :'a' and status = 'in_progress';

-- ============================================================================
-- 2 · Schuelerkonto schreibt weder XP noch Altlast-Tabellen
-- ============================================================================
select pg_temp.act_as(:'kind_uid');
set local role authenticated;
select throws_ok(format('insert into xp_events (student_id, xp, reason) values (%L, 999, %L)', :'k', 'selbst'),
  '42501', null, '2: INSERT in xp_events abgelehnt');
select throws_ok(format('insert into student_progress (student_id, xp_total, level) values (%L, 999, 3)', :'k'),
  '42501', null, '2: INSERT in student_progress abgelehnt');
select throws_ok(format('update student_progress set xp_total = 999 where student_id = %L', :'k'),
  '42501', null, '2: UPDATE auf student_progress abgelehnt');
select throws_ok(format('insert into behavior_snapshots (user_id, task_id) values (%L, %L)', :'kind_uid', :'irgendeine_aufgabe'),
  '42501', null, '2: INSERT in behavior_snapshots abgelehnt');
select throws_ok(format('insert into student_task_progress (student_id, task_id) values (%L, %L)', :'k', :'irgendeine_aufgabe'),
  '42501', null, '2: INSERT in student_task_progress abgelehnt');
select throws_ok(format('select * from public.complete_task(%L)', :'irgendeine_aufgabe'),
  '42501', null, '2: complete_task (Web-TaskPlayer) → 42501');
select throws_ok(format('select public.xp_buchen(%L, 10, %L, %L)', :'k', 'selbst', 'x0:selbst'),
  '42501', null, '2: xp_buchen durch Schuelerkonto → 42501');
reset role;

-- ============================================================================
-- 3 · xp_buchen als Systemaufruf bucht genau einmal
-- ============================================================================
select pg_temp.als_system();
select is(public.xp_buchen(:'a', 50, 'Test', 'x0:quest:1'), true,  '3: erster Aufruf bucht');
select is(public.xp_buchen(:'a', 50, 'Test', 'x0:quest:1'), false, '3: gleicher Schluessel bucht nicht noch einmal');
select is((select count(*)::int from xp_events where buchungs_schluessel = 'x0:quest:1'), 1, '3: genau eine Zeile');
select is((select xp_total from student_progress where student_id = :'a'), 50, '3: student_progress zaehlt 50 XP');
select is(public.xp_buchen(:'c', 50, 'Test', 'x0:quest:1'), true, '3: derselbe Schluessel bucht fuer ein anderes Kind');
select throws_ok(format('select public.xp_buchen(%L, 0, %L, %L)', :'a', 'Test', 'x0:null'), '22023', null,
  '3: Betrag 0 → 22023');
select pg_temp.act_as(:'admin_uid');
select is(public.xp_buchen(:'a', 10, 'Admin', 'x0:admin:1'), true, '3: Admin darf buchen');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format('select public.xp_buchen(%L, 10, %L, %L)', :'a', 'Coach', 'x0:coach:1'), '42501', null,
  '3: Coach bucht kein XP → 42501');

-- ============================================================================
-- 4 · Coach liest Akten-Daten nur bei laufendem Vertrag
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
set local role authenticated;
select is((select count(*)::int from lsa_sessions where id = :'lsa_a'), 1, '4: LSA des Kindes mit Vertrag sichtbar');
select is((select count(*)::int from lsa_sessions where id in (:'lsa_b', :'lsa_l')), 0, '4: LSA ruhend/Lead unsichtbar');
select is((select count(*)::int from lsa_responses where session_id = :'lsa_a'), 1, '4: Antworten mit Vertrag sichtbar');
select is((select count(*)::int from lsa_responses where session_id in (:'lsa_b', :'lsa_l')), 0, '4: Antworten ruhend/Lead unsichtbar');
select is((select count(*)::int from lsa_skill_urteil where session_id = :'lsa_a'), 1, '4: Urteile mit Vertrag sichtbar');
select is((select count(*)::int from lsa_skill_urteil where session_id in (:'lsa_b', :'lsa_l')), 0, '4: Urteile ruhend/Lead unsichtbar');
select is((select count(*)::int from lsa_ausgegeben where session_id in (:'lsa_b', :'lsa_l')), 0, '4: Ausgabe ruhend/Lead unsichtbar');
select is((select count(*)::int from xp_events where student_id = :'a'), 2, '4: XP mit Vertrag sichtbar');
select is(pg_temp.zeilen(format('update lsa_responses set correct = true where session_id = %L', :'lsa_a')), 0,
  '4: Coach schreibt keine Antworten (0 Zeilen)');
select is(pg_temp.zeilen(format('update lsa_sessions set grade = 5 where id = %L', :'lsa_a')), 0,
  '4: Coach schreibt keine LSA-Sitzung (0 Zeilen)');
reset role;
select pg_temp.als_system();
select public.xp_buchen(:'b', 10, 'Test', 'x0:b:1');
select pg_temp.act_as(:'coach_uid');
set local role authenticated;
select is((select count(*)::int from xp_events where student_id = :'b'), 0, '4: XP ruhend unsichtbar');
select is((select count(*)::int from student_progress where student_id = :'b'), 0, '4: Fortschritt ruhend unsichtbar');
reset role;
select pg_temp.act_as(:'coach_uid');
select is((select count(*)::int from public.lsa_fehlbild_report(:'lsa_b')), 0,
  '4: lsa_fehlbild_report ruhende Akte → leer');
select is((select count(*)::int from public.lsa_fehlbild_report(:'lsa_l')), 0,
  '4: lsa_fehlbild_report Lead ohne Vertrag → leer');
select is((select count(*)::int from public.lsa_fehlbild_report(:'lsa_a')), 1,
  '4: lsa_fehlbild_report mit Vertrag liefert den Befund');
select throws_ok(format('select public.lsa_uebernahme(%L, %L)', :'lsa_b', :'b'), '42501', null,
  '4: Coach schreibt keinen Lernpfad fuer eine ruhende Akte (lsa_uebernahme)');
select throws_ok(format('select public.lsa_confirm_focus(%L, %L::uuid[])', :'lsa_l', '{}'), '42501', null,
  '4: Coach schreibt keinen Lernpfad fuer einen Lead ohne Vertrag (lsa_confirm_focus)');

-- ============================================================================
-- 5 · Zugangscode: nur Admin
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
set local role authenticated;
select is((select count(*)::int from vertraege where zugangscode is not null), 0, '5: Coach liest keinen Zugangscode');
select is((select count(*)::int from vertraege_aktuell where zugangscode is not null), 0, '5: Coach liest keinen Zugangscode (View)');
reset role;
select pg_temp.act_as(:'kind_uid');
set local role authenticated;
select is((select count(*)::int from vertraege where zugangscode is not null), 0, '5: Kind liest keinen Zugangscode');
select is((select count(*)::int from vertraege_aktuell where zugangscode is not null), 0, '5: Kind liest keinen Zugangscode (View)');
reset role;
select pg_temp.act_as(:'admin_uid');
set local role authenticated;
select is((select zugangscode from vertraege where student_id = :'a'), 'EDV-ABCD-EFG2', '5: Admin liest den Zugangscode');
reset role;
-- Waechter: der Schutz haengt an diesen beiden Tatsachen.
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename = 'vertraege'
            and cmd in ('SELECT', 'ALL') and qual not like '%''admin''%'), 0,
  '5: keine Nicht-Admin-Lese-Policy auf vertraege');
select ok((select 'security_invoker=true' = any (reloptions) from pg_class where oid = 'public.vertraege_aktuell'::regclass),
  '5: vertraege_aktuell bleibt security_invoker');

-- ============================================================================
-- 6 · LSA-Pool: kein Tutorial, keine ohne Loesung, keine ohne 'lsa'
-- ============================================================================
select is(public.lsa_im_pool(:'t_ok'), true, '6: ready, Loesung, lsa → im Pool');
select is(public.lsa_im_pool(:'t_tut'), false, '6: Tutorial → nicht im Pool');
select is(public.lsa_im_pool(:'t_ohne'), false, '6: ohne Loesung → nicht im Pool');
select is(public.lsa_im_pool(:'t_session'), false, '6: Einsatz nur session → nicht im Pool');
select is(public.lsa_im_pool(:'t_check'), false, '6: Einsatz nur check → nicht im Pool');
select throws_ok($$update tasks set einsatz = '{lsa,irgendwas}' where source = 'x0_test'$$, '23514', null,
  '6: Einsatz ausserhalb lsa/session/check/quest → CHECK');
select pg_temp.act_as(:'admin_uid');
select public.lsa_start(:'c', 9, 'Mathematik') ->> 'session_id' as lsa_c \gset
select ok(not (pg_temp.ziehe_alle(:'lsa_c') && array[:'t_tut', :'t_ohne', :'t_session', :'t_check', :'d_ok', :'d_bad']::uuid[]),
  '6: adaptive Auswahl zieht keine Aufgabe ausserhalb des Pools');
select ok(:'t_ok'::uuid = any (pg_temp.ziehe_alle(:'lsa_c')), '6: adaptive Auswahl zieht die Pool-Aufgabe');
select is(public.lsa_select_next(:'lsa_c', array['draft', 'review']), null::uuid,
  '6: Statusfilter des Aufrufers oeffnet den Pool nicht');

-- ============================================================================
-- 7 · Testlauf
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select throws_ok(format('select public.lsa_start(%L, 9, %L, p_testlauf => true)', :'b', 'Mathematik'), '22023', null,
  '7: Testlauf mit Nicht-Testkonto → abgelehnt');
select is(pg_temp.fehler(format($$select public.testkonto_setzen('lead', %L, true)$$, :'lb')), 'kein Fehler',
  '7: Admin setzt Testkonto an einem Lead ohne Kind');
select is(pg_temp.fehler(format($$select public.testkonto_setzen('student', %L, true)$$, :'a')), 'kein Fehler',
  '7: Admin setzt Testkonto');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format($$select public.testkonto_setzen('student', %L, true)$$, :'c'), '42501', null,
  '7: Coach setzt kein Testkonto');
select throws_ok(format('select public.lsa_start(%L, 9, %L, p_testlauf => true)', :'a', 'Mathematik'), '42501', null,
  '7: Coach startet keinen Testlauf');
select is(public.lsa_im_pool(:'d_ok', true), true, '7: draft ohne pruef_ausschluss im Testlauf-Pool');
select is(public.lsa_im_pool(:'d_ok', false), false, '7: draft nie im normalen Pool');
select is(public.lsa_im_pool(:'d_bad', true), false, '7: Aufgabe mit pruef_ausschluss nie im Pool');
select pg_temp.act_as(:'admin_uid');
select public.lsa_start(:'a', 9, 'Mathematik', p_testlauf => true) ->> 'session_id' as lsa_test \gset
select is((select testlauf from lsa_sessions where id = :'lsa_test'), true, '7: Sitzung ist als Testlauf markiert');
select ok(:'d_ok'::uuid = any (pg_temp.ziehe_alle(:'lsa_test')), '7: Testlauf zieht die draft-Aufgabe');
select ok(not (:'d_bad'::uuid = any (pg_temp.ziehe_alle(:'lsa_test'))), '7: Testlauf zieht die ausgeschlossene nicht');
select throws_ok(format('update lsa_sessions set testlauf = false where id = %L', :'lsa_test'), '42501', null,
  '7: Testlauf-Kennzeichen ist nach dem Start fest');
select throws_ok(format('update lsa_sessions set student_id = %L where id = %L', :'b', :'lsa_test'), '42501', null,
  '7: das Kind eines Testlaufs ist fest');

-- ============================================================================
-- 8 · Testlauf erscheint in keiner Kennzahl, keinem Report, keiner Akte
-- ============================================================================
update lsa_sessions set status = 'completed', completed_at = now() where id = :'lsa_test';
select pg_temp.act_as(:'admin_uid');
insert into coaching_sessions (id, coach_id, scheduled_at, status, testlauf)
values (:'test_session', :'coach_uid', now() - interval '1 hour', 'done', true);
insert into session_students (session_id, student_id, attendance) values (:'test_session', :'a', 'present');
select is((select count(*)::int from public.akte_sessions(:'a') s where s.session_id = :'test_session'), 0,
  '8: Akte-Sessions ohne Test-Session');
select is((select count(*)::int from public.akte_sessions(:'a') s where s.session_id = :'platz_session'), 1,
  '8: echte Session steht in der Akte');
select is((select verbraucht from public.einheiten_stand(:'a')), 1, '8: Einheiten zaehlen die Test-Session nicht');
select is((select letzte_session from public.akte_basis() where student_id = :'a'),
  (select scheduled_at from coaching_sessions where id = :'platz_session'), '8: letzte Session ist keine Test-Session');
select throws_ok(format('select public.eltern_report_eintragen(%L, %L, p_lsa_session_id => %L)', :'a', 'lernstandsanalyse', :'lsa_test'),
  '22023', null, '8: aus einem Testlauf entsteht kein Eltern-Report');
select throws_ok(format('select public.lsa_uebernahme(%L, %L)', :'lsa_test', :'a'), '22023', null,
  '8: Testlauf geht nicht in den Lernpfad (lsa_uebernahme)');
select throws_ok(format('select public.lsa_confirm_focus(%L, %L::uuid[])', :'lsa_test', '{}'), '22023', null,
  '8: Testlauf geht nicht in den Lernpfad (lsa_confirm_focus)');

-- Lead-Trichter: Testlauf nur mit Test-Lead; ein Kind erbt ist_test vom Lead.
insert into leads (id, full_name, first_name, contact_email, status, ist_test)
values (:'lt', 'X0 Testlead', 'Tom', 'x0t@example.invalid', 'lsa_freigegeben', true);
insert into students (class_level, is_provisional, lead_id) values (9, true, :'lt');
select id as t_kind from students where lead_id = :'lt' \gset
select is((select ist_test from students where id = :'t_kind'), true, '8: Kind eines Test-Leads ist Testkonto');
update leads set consent_dsgvo_at = now() where id = :'ll';
select throws_ok(format('select public.lead_lsa_freigeben(%L, 9, %L, p_testlauf => true)', :'ll', 'Mathematik'), '22023', null,
  '8: Testlauf mit echtem Lead → abgelehnt');

select * from finish();
rollback;
