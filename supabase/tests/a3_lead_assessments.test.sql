-- ============================================================================
-- A3 (S5): lead_assessments — zwei getrennte Einschätzungen, und die BEWEIS-
-- barkeit, dass keine davon die LSA-Item-Auswahl beeinflusst.
--
-- Zwei Invarianten:
--   A) Je eine Eltern- und eine Kind-Einschätzung pro Lead — der Unique greift.
--      RLS: nur coach/admin, kein Schüler.
--   B) Es gibt KEINEN Pfad, über den eine Einschätzung in lsa_start sichtbar
--      wird — strukturell bewiesen, nicht behauptet:
--        - lsa_start-Definition nennt lead_assessments nirgends,
--        - keine Tabelle referenziert lead_assessments (kein Join-Pfad),
--        - lead_assessments hängt ausschließlich an leads,
--        - lsa_start-Signatur trägt keinen Lead-/Einschätzungs-Parameter,
--        - lsa_start zieht auch bei vorhandener Einschätzung nur aus dem Pool.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(13);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   '77777777-7777-7777-7777-777777777777'
\set student_uid '88888888-8888-8888-8888-888888888888'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'a3-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'a3-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'admin_uid',   'a3-admin@test.local',   'admin',   'A3 Admin'),
  (:'student_uid', 'a3-student@test.local', 'student', 'A3 Schuelerin');

insert into students (profile_id, class_level) values (:'student_uid', 8);

insert into leads (full_name, class_level, subjects, status)
values ('A3 Interessent', 8, '{Mathematik}', 'new');

-- Zwei freigegebene, NICHT-Tutorial Pool-Items am ersten Mathe-Cluster.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready', 'Welcher Term ist aequivalent?',
       '{"input_type":"MC","options":[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}],"correct":["b"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 'a3-mc'
  from skill_clusters c order by c.sort_order limit 1;

insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready', 'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 'a3-short', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id   from leads    where full_name = 'A3 Interessent')     as lead_id,
       (select id   from students where profile_id = :'student_uid')      as sid,
       (select id   from tasks    where source_ref = 'a3-mc')             as t_mc,
       (select id   from tasks    where source_ref = 'a3-short')          as t_short
\gset

insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_mc',    '["b"]'::jsonb,     'x+x = 2x'),
  (:'t_short', '["0,3 m"]'::jsonb, 'GEHEIM');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) Je eine Einschätzung pro Quelle — der Unique greift. RLS: nur coach/admin.
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'admin_uid');

select lives_ok(
  format($f$insert into lead_assessments (lead_id, source, note, weak_topics)
            values (%L, 'parent', 'Kind hat Probleme mit Bruchrechnen',
                    '{Bruchrechnen}')$f$, :'lead_id'),
  'Admin legt die Eltern-Einschätzung an'
);

select lives_ok(
  format($f$insert into lead_assessments (lead_id, source, note, weak_topics)
            values (%L, 'child', 'Ich verstehe Textaufgaben nicht', '{Sachrechnen}')$f$, :'lead_id'),
  'Admin legt die Kind-Einschätzung an (gleicher Lead, andere Quelle)'
);

select throws_ok(
  format($f$insert into lead_assessments (lead_id, source, note)
            values (%L, 'parent', 'zweite Eltern-Einschätzung')$f$, :'lead_id'),
  '23505', NULL,
  'Eine zweite Einschätzung derselben Quelle wird abgewiesen (Unique lead_id, source)'
);

select is(
  (select count(*) from lead_assessments where lead_id = :'lead_id'),
  2::bigint,
  'Genau zwei Einschätzungen am Lead — je eine pro Quelle'
);

-- RLS: der Schüler sieht keine Einschätzung und darf keine anlegen.
select pg_temp.act_as(:'student_uid');

select is(
  (select count(*) from lead_assessments),
  0::bigint,
  'Ein Schüler sieht keine einzige Einschätzung (RLS: nur coach/admin)'
);

select throws_ok(
  format($f$insert into lead_assessments (lead_id, source, note)
            values (%L, 'child', 'darf ich nicht')$f$, :'lead_id'),
  '42501', NULL,
  'Ein Schüler darf keine Einschätzung schreiben (RLS with check)'
);

-- ============================================================================
-- B) Kein Pfad von der Einschätzung in die Item-Auswahl — strukturell bewiesen
-- ============================================================================
reset role;

select is(
  pg_get_functiondef('public.lsa_start(uuid,integer,text)'::regprocedure) !~* 'lead_assessments',
  true,
  'Die Definition von lsa_start nennt lead_assessments an KEINER Stelle'
);

select is(
  (select count(*) from pg_constraint
    where contype = 'f' and confrelid = 'lead_assessments'::regclass),
  0::bigint,
  'KEINE Tabelle referenziert lead_assessments — es gibt keinen Join-Pfad in den Pool'
);

select is(
  (select array_agg(distinct confrelid::regclass::text order by confrelid::regclass::text)
     from pg_constraint
    where contype = 'f' and conrelid = 'lead_assessments'::regclass),
  array['leads'],
  'lead_assessments hängt ausschließlich an leads (einziges FK-Ziel)'
);

select is(
  pg_get_function_identity_arguments('public.lsa_start(uuid,integer,text)'::regprocedure),
  'uuid, integer, text',
  'lsa_start nimmt weiterhin (student_id, grade, subject) — kein Lead-/Einschätzungs-Parameter'
);

select is(
  (select count(*) from pg_proc
    where proname = 'lsa_start' and pronamespace = 'public'::regnamespace),
  1::bigint,
  'Es gibt genau eine lsa_start — kein Lead-Overload, der die Einschätzung ziehen könnte'
);

-- Verhaltensnachweis: die Einschätzungen liegen am Lead (oben eingefügt). lsa_start
-- läuft trotzdem — und zieht ausschließlich aus dem freigegebenen, nicht-Tutorial
-- Pool. Die item_ids enthalten kein einziges Item außerhalb des Pools.
select pg_temp.act_as(:'admin_uid');

select lives_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid'),
  'lsa_start läuft — die vorhandene Einschätzung ist für die Auswahl irrelevant'
);

select is(
  (select count(*) from unnest(
     (select item_ids from lsa_sessions where student_id = :'sid'
       order by created_at desc limit 1)) as iid
    where iid not in (
      select id from tasks
       where status = 'ready' and coalesce(is_tutorial, false) = false)),
  0::bigint,
  'Jedes gezogene Item stammt aus dem Pool — nichts, was aus einer Einschätzung käme'
);

select * from finish();
rollback;
