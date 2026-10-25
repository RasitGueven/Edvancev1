-- LSA-L4 Teil C: Fixture „Prod-Pool 25.10. abends“ für den lokalen Neuaufbau (simulation.sh mit POOLS=l4 bzw. lena).
-- NUR für eine Wegwerf-DB, nie gegen Prod. Form wie l2-fixture.sql.
--
-- Wie neuaufbau-fixture.sql ein Admin, aber als Aufgaben genau der freigegebene Prod-Pool aus l4-pool-fixture.sql
-- (synthetische ids, Skills, Eingabearten, Sondierränge). Mit -v l4_mit_lena (l4-lena-fixture.sql) zusätzlich die 36
-- Entwürfe aus Lenas Freigabeliste als freigegeben: „Batu nach Lenas Freigaben“. Inhalte gibt es nicht; der Text trägt den Text-Hash als
-- Buchstaben, damit Fast-Duplikate (gleicher Hash) auch hier denselben normalisierten Text haben. Richtig ist 7
-- bzw. a, wie in neuaufbau-fixture.sql.
\ir l4-pool-fixture.sql
\if :{?l4_mit_lena}
\else
delete from zz_l4_pool where lena;
\endif
\set admin 'a5a7c41d-adad-4000-8000-000000000001'
insert into auth.users (id, email, instance_id, aud, role)
values (:'admin', 'lsat-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, created_at)
values (:'admin', 'lsat-admin@test.local', 'admin', 'ZZ LSA-T Admin', '2000-01-01');

-- Der Neuaufbau bringt Aufgaben aus den Migrationen mit (Entwürfe, teils mit denselben ids wie in Prod). Nur der
-- Prod-Pool soll ziehbar sein: alle anderen inaktiv, die gleichnamigen werden überschrieben.
update tasks set is_active = false where id not in (select id from zz_l4_pool);
delete from task_solutions where task_id in (select id from zz_l4_pool);
insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ LSA-L4 Cluster', 5, 13);
insert into tasks (id, cluster_id, content_type, input_type, status, question, question_payload, parts, afb,
                   competency_content, est_duration_sec, class_level, curriculum_grade, source, source_ref,
                   skill_key, difficulty, einsatz, is_active, sondierrang)
select p.id, (select id from skill_clusters where name = 'ZZ LSA-L4 Cluster'), 'exercise', p.input_type, 'ready',
       'ZZ L2 ' || translate(p.text_hash, '0123456789', 'ghijklmnop') || ': Wie viel ist 3 + 4?',
       case when p.input_type = 'MC' then '{"input_type":"MC","options":[{"id":"a","label":"7"},{"id":"b","label":"8"},{"id":"c","label":"6"}]}'::jsonb end,
       case when p.input_type = 'MULTI_PART' then
         '[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 3 + 4?","competency_content":"zahlen","competency_process":null},
           {"nr":2,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 1 + 2?","competency_content":"zahlen","competency_process":null}]'::jsonb
       else '[]'::jsonb end,
       'I', 'Zahlen und Operationen', 60, 8, 8, 'test', 'lsal4-' || p.id, p.skill_key, 1, '{lsa}', true, p.sondierrang
  from zz_l4_pool p
on conflict (id) do update
   set cluster_id = excluded.cluster_id, content_type = excluded.content_type, input_type = excluded.input_type,
       status = excluded.status, question = excluded.question, question_payload = excluded.question_payload,
       parts = excluded.parts, source = excluded.source, source_ref = excluded.source_ref,
       skill_key = excluded.skill_key, einsatz = excluded.einsatz, is_active = excluded.is_active,
       is_tutorial = false, sondierrang = excluded.sondierrang, bruch = null, unit = null;

insert into task_solutions (task_id, correct_answers, solution, acceptance)
select t.id,
       case t.input_type when 'MC' then '["a"]'::jsonb when 'MULTI_PART' then '{"1":["7"],"2":["3"]}'::jsonb
                         else '["7"]'::jsonb end,
       'ZZ-LOESUNGSWEG',
       case t.input_type
         when 'MC' then jsonb_build_object('canonical', 'a', 'known_errors', jsonb_build_object('b', 'falsche_operation'))
         when 'MULTI_PART' then jsonb_build_object(
           '1', jsonb_build_object('canonical', '7', 'known_errors', jsonb_build_object('8', 'falsche_operation')),
           '2', jsonb_build_object('canonical', '3'))
         when 'TERM' then null  -- TERM trägt kein acceptance (Gate in task_solutions)
         else jsonb_build_object('canonical', '7', 'known_errors', jsonb_build_object('8', 'falsche_operation')) end
  from tasks t where t.source = 'test' and t.source_ref like 'lsal4-%';
