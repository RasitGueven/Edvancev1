-- LSA-T: Fixture für den CI-Neuaufbau (eingebunden von supabase/tests/lsa_testkinder.test.sql und
-- tools/lsa-testkinder/simulation.sh). NUR für eine Wegwerf-DB, nie gegen Prod.
--
-- Der Neuaufbau hat Skills, Kanten, Themen, Einstiege und den FWG-Plan aus den Migrationen, aber keine
-- LSA-Aufgaben und kein Admin-Profil. Hier: ein Admin und je Skill drei Aufgaben (Zahl, MC, Multi-Part; richtig
-- ist 7 bzw. a) mit hinterlegten Fehlbildern.
\set admin 'a5a7c41d-adad-4000-8000-000000000001'
insert into auth.users (id, email, instance_id, aud, role)
values (:'admin', 'lsat-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, created_at)
values (:'admin', 'lsat-admin@test.local', 'admin', 'ZZ LSA-T Admin', '2000-01-01');

-- Drei Aufgaben je Skill. Das hinterlegte Fehlbild folgt dem Skill, damit die Familien der Kinder etwas
-- zum Ausloesen haben; "-7" ist bei jeder Zahl-Aufgabe ein Vorzeichenfehler.
insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ LSA-T Cluster', 5, 13);
create temp table zz_lsat_skill as
select s.skill_key,
       case when s.skill_key = 'zahl_wurzel_gesetze' then 'wurzel_gliedweise'
            when s.skill_key like 'zahl_wurzel%' then 'faktor_ohne_wurzel'
            when s.skill_key like 'fkt_linear%' then 'steigung_kehrwert'
            when s.skill_key like 'prozent%' then 'multipliziert_statt_dividiert'
            else 'falsche_operation' end as slug
  from skills s;

insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, parts, afb,
                   competency_content, est_duration_sec, class_level, curriculum_grade, source, source_ref,
                   skill_key, difficulty, einsatz, is_active)
select (select id from skill_clusters where name = 'ZZ LSA-T Cluster'), 'exercise', a.typ, 'ready',
       'ZZ LSA-T ' || z.skill_key || ' ' || a.typ || ': Wie viel ist 3 + 4?',
       case when a.typ = 'MC' then '{"input_type":"MC","options":[{"id":"a","label":"7"},{"id":"b","label":"8"},{"id":"c","label":"6"}]}'::jsonb end,
       case when a.typ = 'MULTI_PART' then
         '[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 3 + 4?","competency_content":"zahlen","competency_process":null},
           {"nr":2,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 1 + 2?","competency_content":"zahlen","competency_process":null}]'::jsonb
       else '[]'::jsonb end,
       'I', 'Zahlen und Operationen', 60, 8, 8, 'test', 'lsat-' || z.skill_key || '-' || a.typ,
       z.skill_key, 1, '{lsa}', true
  from zz_lsat_skill z
 cross join (values ('NUMERIC'), ('MC'), ('MULTI_PART')) a(typ);

insert into task_solutions (task_id, correct_answers, solution, acceptance)
select t.id,
       case t.input_type when 'MC' then '["a"]'::jsonb when 'MULTI_PART' then '{"1":["7"],"2":["3"]}'::jsonb
                         else '["7"]'::jsonb end,
       'ZZ-LOESUNGSWEG',
       case t.input_type
         when 'MC' then jsonb_build_object('canonical', 'a', 'known_errors', jsonb_build_object('b', z.slug))
         when 'MULTI_PART' then jsonb_build_object(
           '1', jsonb_build_object('canonical', '7', 'known_errors', jsonb_build_object('8', z.slug)),
           '2', jsonb_build_object('canonical', '3'))
         else jsonb_build_object('canonical', '7',
                                 'known_errors', jsonb_build_object('8', z.slug, '-7', 'vorzeichen_ignoriert')) end
  from tasks t join zz_lsat_skill z on z.skill_key = t.skill_key
 where t.source = 'test' and t.source_ref like 'lsat-%';
