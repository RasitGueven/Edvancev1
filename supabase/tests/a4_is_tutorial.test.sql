-- ============================================================================
-- A4 (S5): tasks.is_tutorial — ein Tutorial-Item kann NIE in eine LSA-Session
-- gelangen. Die echten Pool-Items (is_tutorial=false) bleiben unberührt.
--
-- Deterministisch: es gibt genau EIN nicht-Tutorial ready-Item und genau EIN
-- Tutorial ready-Item — beide am selben Cluster/Fach/Jahrgang, beide mit Lösung,
-- beide würden ohne den Filter gezogen. Nach lsa_start MUSS item_ids exakt das
-- eine echte Item sein.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(5);

-- --- Fixtures --------------------------------------------------------------
\set student_uid '99999999-9999-9999-9999-999999999999'
\set coach_uid   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'a4-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'a4-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'a4-student@test.local', 'student', 'A4 Schuelerin'),
  (:'coach_uid',   'a4-coach@test.local',   'coach',   'A4 Coach');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Das ECHTE Pool-Item (is_tutorial default false).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready', 'Welcher Term ist aequivalent?',
       '{"input_type":"MC","options":[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}],"correct":["b"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 'a4-real'
  from skill_clusters c order by c.sort_order limit 1;

-- Das TUTORIAL-Item: sonst identisch qualifiziert (ready, Lösung, Fach, Jahrgang),
-- nur is_tutorial=true. Ohne den A4-Filter käme es in den Pool.
insert into tasks (
  cluster_id, content_type, input_type, status, is_tutorial, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready', true, 'So klickst du eine Auswahl an.',
       '{"input_type":"MC","options":[{"id":"a","label":"Ja"},{"id":"b","label":"Nein"}],"correct":["a"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 'a4-tut'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'student_uid') as sid,
       (select id from tasks where source_ref = 'a4-real')         as t_real,
       (select id from tasks where source_ref = 'a4-tut')          as t_tut
\gset

insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_real', '["b"]'::jsonb, 'x+x = 2x'),
  (:'t_tut',  '["a"]'::jsonb, 'egal');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- Der Default und die Unberührtheit des echten Pools
-- ============================================================================
select is(
  (select is_tutorial from tasks where source_ref = 'a4-real'),
  false,
  'Ein normal angelegtes Pool-Item ist is_tutorial=false (Default) — der echte Pool ist unberührt'
);

-- ============================================================================
-- Das Tutorial-Item kommt nie in die Session
-- ============================================================================
reset role;
select pg_temp.act_as(:'coach_uid');

select lives_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid'),
  'lsa_start läuft (Coach handelt für den Schüler)'
);

select is(
  (select count(*) from unnest(
     (select item_ids from lsa_sessions where student_id = :'sid'
       order by created_at desc limit 1)) as iid
    where iid = :'t_tut'),
  0::bigint,
  'Das Tutorial-Item ist in KEINER gezogenen Session enthalten'
);

select is(
  (select item_ids from lsa_sessions where student_id = :'sid'
    order by created_at desc limit 1),
  array[:'t_real']::uuid[],
  'Die Session enthält exakt das eine echte Item — das Tutorial ist herausgefiltert, nicht nur nachrangig'
);

-- Gegenprobe: würde man das Tutorial-Flag ignorieren, wären es ZWEI Items. Der
-- Filter ist also der Grund, nicht die Dauergrenze.
select is(
  (select count(*) from tasks t
     join task_solutions s on s.task_id = t.id
     join skill_clusters c on c.id = t.cluster_id
     join subjects sub     on sub.id = c.subject_id
    where t.status = 'ready' and coalesce(t.is_active, true)
      and sub.name = 'Mathematik' and coalesce(t.class_level, 8) <= 8
      and t.input_type in ('MC','SHORT_TEXT','NUMERIC','MULTI_PART')),
  2::bigint,
  'Ohne den is_tutorial-Filter wären zwei Items qualifiziert — der Filter macht den Unterschied'
);

select * from finish();
rollback;
