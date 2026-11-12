-- ============================================================================
-- MSA-1 M1: Archiv für Aufgaben (20261112153053_msa1_archiv)
--
-- Zusagen:
--   1) Eine archivierte Aufgabe ist nicht ziehbar (lsa_im_pool), steht nicht in Lenas Board (pruef_board), nicht in
--      der gezielten Liste (pruef_ziel_roh) und nicht im Abschnitt 'nachpruefen' von pruef_ziel_liste, nicht in
--      pruef_admin_liste; sie steht in task_archiv.
--   2) Archivieren und Wiederherstellen dürfen nur Admins (und Systemaufrufe); Lena und Coaches nicht, auch nicht
--      task_archiv lesen.
--   3) Wiederherstellen ändert nie den Status (ready bleibt ready, draft bleibt draft) und setzt is_active zurück.
--   4) Antworten, Prüfprotokoll und Lösungen der Aufgabe sind nach dem Archivieren unverändert vorhanden.
--   5) Archiviert heißt immer inaktiv (CHECK); aus anderem Grund inaktive Aufgaben archiviert die Funktion nicht;
--      jede Aktion steht im Admin-Protokoll.
-- ============================================================================
begin;
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(38);

\set lena  '5a100000-0000-4000-8000-0000000000b1'
\set admin '5a100000-0000-4000-8000-0000000000a1'
\set coach '5a100000-0000-4000-8000-0000000000d1'
\set kindp '5a100000-0000-4000-8000-0000000000c1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena', 'msa1-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'msa1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'msa1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kindp', 'msa1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena', 'msa1-lena@test.local', 'coach', 'MSA1 Lena', true),
  (:'admin', 'msa1-admin@test.local', 'admin', 'MSA1 Admin', false),
  (:'coach', 'msa1-coach@test.local', 'coach', 'MSA1 Coach', false),
  (:'kindp', 'msa1-kind@test.local', 'student', 'MSA1 Kind', false);
create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
end $$;
select pg_temp.system();

-- --- Fixture: eigener Skill mit Thema, drei LSA-Aufgaben --------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('zm_s', 'ZM Skill', 'mathematik', 9, 1);
insert into themen (thema_key, fach, klasse, label, stufe, sort) values ('zm_t', 'mathematik', 9, 'ZM Thema', 'zweite', 9950);
insert into skill_thema (skill_key, thema_key) values ('zm_s', 'zm_t');

create function pg_temp.aufgabe(p_text text, p_status text) returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref, skill_key,
                     sondierrang, class_level, afb, curriculum_grade, pruef_pilot)
  values ((select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
            where sub.name = 'Mathematik' order by c.sort_order limit 1),
          'exercise', 'NUMERIC', 'draft', p_text, 'test', 'zm-' || gen_random_uuid(), 'zm_s', 1, 9, 'I', 9, true)
  returning id into v;
  insert into task_solutions (task_id, correct_answers) values (v, '["5"]');
  if p_status = 'ready' then perform public.task_status_set(v, 'ready'); end if;
  return v;
end $$;

select pg_temp.aufgabe('Berechne 2 + 3.', 'ready') as r1 \gset
select pg_temp.aufgabe('Wie viel ist 10 durch 2?', 'draft') as d1 \gset
select pg_temp.aufgabe('Ziehe 4 von 9 ab.', 'draft') as d2 \gset

-- Antwort eines Kindes, Prüfprotokoll (Lena „unsicher“), damit 'nachpruefen' r1 enthält
insert into students (id, profile_id) values ('5a100000-0000-4000-8000-0000000000e1', :'kindp');
insert into lsa_sessions (id, student_id, subject, grade, status)
  values ('5a100000-0000-4000-8000-0000000000f1', '5a100000-0000-4000-8000-0000000000e1', 'mathematik', 9, 'completed');
insert into lsa_responses (session_id, task_id, response, correct, abgabeart)
  values ('5a100000-0000-4000-8000-0000000000f1', :'r1', '{"value": "5"}', true, 'antwort');
insert into task_pruefungen (task_id, entscheidung, geprueft_von, dauer_sek) values (:'r1', 'unsicher', :'lena', 30);

create temp table vorher as
  select (select count(*) from lsa_responses where task_id = :'r1') antworten,
         (select count(*) from task_pruefungen where task_id = :'r1') pruefungen,
         (select count(*) from task_solutions where task_id in (:'r1', :'d1')) loesungen,
         (select correct_answers::text from task_solutions where task_id = :'r1') loesung;

-- --- 1) vorher sichtbar ---------------------------------------------------------
select ok(public.lsa_im_pool(:'r1', false), 'vorher: r1 ziehbar');
select pg_temp.act_as(:'lena');
select ok(exists (select 1 from pruef_board() where task_id = :'d1'), 'vorher: d1 in Lenas Board');
select ok(exists (select 1 from pruef_ziel_liste() where abschnitt = 'nachpruefen' and :'r1' = any (task_ids)),
          'vorher: r1 in nachpruefen');
select pg_temp.system();
select ok(exists (select 1 from pruef_ziel_roh() where skill_key = 'zm_s' and :'d1' = any (task_ids)),
          'vorher: d1 in der gezielten Liste');

-- --- 2) Rechte ------------------------------------------------------------------
select pg_temp.act_as(:'lena');
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'nicht_notwendig')$q$, :'r1'), '42501', null,
                 'Lena archiviert nicht');
select throws_ok(format($q$select task_wiederherstellen(array[%L]::uuid[])$q$, :'r1'), '42501', null,
                 'Lena stellt nicht wieder her');
select throws_ok($q$select * from task_archiv()$q$, '42501', null, 'Lena sieht das Archiv nicht');
select pg_temp.act_as(:'coach');
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'nicht_notwendig')$q$, :'r1'), '42501', null,
                 'Coach archiviert nicht');
select throws_ok(format($q$select task_wiederherstellen(array[%L]::uuid[])$q$, :'r1'), '42501', null,
                 'Coach stellt nicht wieder her');
select pg_temp.act_as(:'kindp');
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'nicht_notwendig')$q$, :'r1'), '42501', null,
                 'Kind archiviert nicht');
reset role;
select ok(not has_function_privilege('anon', 'public.task_archivieren(uuid[], text)', 'execute'), 'anon: kein execute archivieren');
select ok(not has_function_privilege('anon', 'public.task_wiederherstellen(uuid[])', 'execute'), 'anon: kein execute wiederherstellen');
select ok(not has_function_privilege('anon', 'public.task_archiv(text)', 'execute'), 'anon: kein execute task_archiv');
set local role authenticated;
select pg_temp.act_as(:'lena');
update tasks set is_active = false, archiviert_am = now(), archiviert_grund = 'sonstiges' where id = :'d2';
reset role;
select is((select archiviert_am from tasks where id = :'d2'), null, 'direkter Update durch Lena archiviert nicht');

-- --- 3) Archivieren als Admin ---------------------------------------------------
select pg_temp.act_as(:'admin');
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'weg')$q$, :'r1'), '22023', null,
                 'unbekannter Grund');
select is(task_archivieren(array[:'r1', :'d1']::uuid[], 'nicht_notwendig'), 2, 'Admin archiviert zwei');
select is(task_archivieren(array[:'r1']::uuid[], 'nicht_notwendig'), 0, 'schon archiviert: übersprungen');
select is((select (is_active, archiviert_grund, archiviert_von, status) from tasks where id = :'r1')::text,
          format('(f,nicht_notwendig,%s,ready)', :'admin'), 'r1: inaktiv, Grund, von, Status ready unverändert');
select is((select status from tasks where id = :'d1'), 'draft', 'd1: Status draft unverändert');
select is((select count(*)::int from task_admin_protokoll where task_id in (:'r1', :'d1') and aktion = 'archivieren'
            and sammel and von = :'admin'), 2, 'je eine Protokollzeile');

-- --- 1) nachher unsichtbar --------------------------------------------------------
select pg_temp.system();
select ok(not public.lsa_im_pool(:'r1', false), 'nachher: r1 nicht ziehbar');
select ok(not exists (select 1 from pruef_ziel_roh() z where :'d1' = any (z.task_ids)), 'nachher: d1 nicht gezielt');
select pg_temp.act_as(:'lena');
select ok(not exists (select 1 from pruef_board() where task_id in (:'r1', :'d1')), 'nachher: nicht in Lenas Board');
select ok(not exists (select 1 from pruef_ziel_liste() where :'r1' = any (task_ids)), 'nachher: r1 nicht in nachpruefen');
select ok(exists (select 1 from pruef_board() where task_id = :'d2'), 'd2 (nicht archiviert) bleibt im Board');
select pg_temp.act_as(:'admin');
select ok(not exists (select 1 from pruef_admin_liste() where task_id in (:'r1', :'d1')), 'nachher: nicht in pruef_admin_liste');
select ok(exists (select 1 from pruef_admin_liste() where task_id = :'d2'), 'd2 bleibt in pruef_admin_liste');
select is((select count(*)::int from task_archiv('zm_s')), 2, 'task_archiv zeigt beide');
select is((select kurztext from task_archiv() where id = :'d1'), 'Wie viel ist 10 durch 2?', 'Kurztext aus der Frage');

-- --- 4) Daten unverändert -----------------------------------------------------------
select is((select (antworten, pruefungen, loesungen, loesung)::text from vorher),
          (select ((select count(*) from lsa_responses where task_id = :'r1'),
                   (select count(*) from task_pruefungen where task_id = :'r1'),
                   (select count(*) from task_solutions where task_id in (:'r1', :'d1')),
                   (select correct_answers::text from task_solutions where task_id = :'r1'))::text),
          'Antworten, Prüfprotokoll und Lösungen unverändert');

-- --- 5) CHECK und Sonderfälle -----------------------------------------------------
select pg_temp.system();
select throws_ok(format($q$update tasks set is_active = true where id = %L$q$, :'r1'), '23514', null,
                 'archiviert heißt inaktiv (CHECK)');
update tasks set is_active = false where id = :'d2';
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'sonstiges')$q$, :'d2'), '22023', null,
                 'aus anderem Grund inaktiv: nicht archivieren');
update tasks set is_active = true where id = :'d2';
update tasks set bauform_id = (select id from bauformen limit 1), bauform_version = 1, stufe = 1, rolle = 'uebung', einsatz = '{session}'
 where id = :'d2' and exists (select 1 from bauformen);
select throws_ok(format($q$select task_archivieren(array[%L]::uuid[], 'sonstiges')$q$, :'d2'), '22023', null,
                 'Bauform-Instanz: nicht archivieren');

-- --- 3) Wiederherstellen ------------------------------------------------------------
select pg_temp.act_as(:'admin');
select is(task_wiederherstellen(array[:'r1', :'d1', :'d2']::uuid[]), 2, 'zwei wiederhergestellt, d2 übersprungen');
select is((select (status, is_active, archiviert_am is null, archiviert_grund is null) from tasks where id = :'r1')::text,
          '(ready,t,t,t)', 'r1: ready wie vorher, aktiv, Archiv-Felder leer');
select is((select status from tasks where id = :'d1'), 'draft', 'd1 bleibt draft (nie ready durch Wiederherstellen)');
select is((select count(*)::int from task_admin_protokoll where task_id in (:'r1', :'d1') and aktion = 'wiederherstellen'),
          2, 'Wiederherstellen protokolliert');
select pg_temp.system();
select ok(public.lsa_im_pool(:'r1', false), 'r1 wieder ziehbar');

select * from finish();
rollback;
