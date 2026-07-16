-- ============================================================================
-- INV-7 (B01): Draft-Content verlaesst die Redaktion nicht — und der Beleg
--              erst recht nicht.
--
-- WARUM NEBEN INV-6: INV-6 fragt "kommt eine LOESUNG beim Kind an?" und war
--   gruen, waehrend jedes Kind trotzdem jede unfertige Aufgabe lesen konnte —
--   die alte Policy `authenticated_read_tasks` (qual: auth.role() =
--   'authenticated') kannte nur "eingeloggt", nicht WER. Seit C08 sind das 285
--   draft-Items mit zerfallenen Staemmen. Kein Leak, aber auch nichts, was auf
--   einem Schuelergeraet zu suchen hat.
--
--   INV-7 pinnt deshalb die zweite Frage fest: "kommt UNFERTIGES beim Kind an?"
--   Und die dritte, neu seit B01: der Quellenbeleg (task_solutions.beleg) ist
--   fuer einen Schueler ueber keinen Weg erreichbar.
--
-- ANTI-VAKUUM: Jede Verneinung ("der Schueler sieht X nicht") steht neben einer
--   Bejahung ("der Coach sieht X sehr wohl" / "der Schueler sieht das ready-Item").
--   Sonst waere der Test auch dann gruen, wenn RLS schlicht alles wegfiltert.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(12);

-- --- Fixtures --------------------------------------------------------------
\set student_uid '77777777-7777-7777-7777-777777777777'
\set coach_uid   '88888888-8888-8888-8888-888888888888'
\set beleg_sent  'SENTINEL-BELEG-7C1D'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'inv7-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'inv7-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'inv7-student@test.local', 'student', 'INV7 Schuelerin'),
  (:'coach_uid',   'inv7-coach@test.local',   'coach',   'INV7 Coach');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Ein freigegebenes Item (der LSA-Pool) …
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","kind":"short_input","prompt":"Wie lang ist die Strecke?"}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 'inv7-ready', 'm'
  from skill_clusters c order by c.sort_order limit 1;

-- … und ein unfertiges. Genau das, was seit C08 zu Hunderten in der Tabelle liegt:
-- halber Stamm, kein Typ, keine Loesung.
insert into tasks (
  cluster_id, content_type, status, question, class_level, source, source_ref
)
select c.id, 'exercise', 'draft', 'Halber Stamm, den niemand sehen soll',
       8, 'test', 'inv7-draft'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'student_uid') as sid,
       (select id from tasks where source_ref = 'inv7-ready')       as tid_ready,
       (select id from tasks where source_ref = 'inv7-draft')       as tid_draft
\gset

-- Die Loesung des ready-Items — MIT Quellenbeleg. Der Sentinel steckt im Beleg:
-- taucht er irgendwo im Schueler-Kontext auf, ist der neue Kanal undicht.
insert into task_solutions (task_id, correct_answers, solution, beleg, hints) values
  (:'tid_ready',
   '["16"]'::jsonb,
   'Erst die Einheit angleichen, dann teilen.',
   format('[{"feld":"part1.correct_answers","gate":"G2","quelle":"Auswertung","zitat":"%s"}]', :'beleg_sent')::jsonb,
   '[{"level":1,"text":"Denk an die Einheit."}]'::jsonb);

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) Der Schueler-Kontext: nur ready, kein draft
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: der Testnutzer ist ein student');

select is(
  (select count(*) from tasks where id = :'tid_ready'),
  1::bigint,
  'der Schueler sieht das freigegebene Item (Anti-Vakuum)'
);

select is(
  (select count(*) from tasks where id = :'tid_draft'),
  0::bigint,
  'der Schueler sieht das draft-Item NICHT'
);

-- Die generische Fassung: nicht nur DIESER Draft, sondern kein einziger.
select is(
  (select count(*) from tasks where status <> 'ready'),
  0::bigint,
  'select aus tasks liefert dem Schueler ausschliesslich ready-Items'
);

-- ============================================================================
-- B) Der Beleg ist fuer den Schueler ueber KEINEN Weg erreichbar
-- ============================================================================

select throws_ok(
  'select beleg from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'der Schueler kann task_solutions.beleg NICHT selektieren (kein Tabellen-Grant)'
);

-- Die Haertung aus A01 bleibt: der Lesepfad ist Coach/Admin — und er ist der
-- EINZIGE Weg zum Beleg.
select throws_ok(
  format($f$select public.task_solution_get(%L)$f$, :'tid_ready'),
  '42501',
  'task_solution_get: nur Coach/Admin',
  'task_solution_get liefert dem Schueler nichts'
);

-- Und er sickert auch nicht ueber tasks oder den Payload-Builder durch.
select is(
  (select coalesce(bool_or(to_jsonb(t)::text like '%' || :'beleg_sent' || '%'), false) from tasks t),
  false,
  'select * from tasks: der Beleg steht in keiner Spalte'
);

-- §3.6(ii)/S9: das authenticated-Grant auf lsa_question_payload ist zurueck-
-- gezogen (s9_platz_mechanik.test.sql pinnt die Nicht-Aufrufbarkeit). Der
-- Inhalts-Vertrag wird deshalb im Definer-Kontext geprueft — die Assertion
-- selbst ist unveraendert.
reset role;
select is(
  (select public.lsa_question_payload(:'tid_ready')::text like '%' || :'beleg_sent' || '%'),
  false,
  'lsa_question_payload gibt den Beleg nicht heraus'
);
set local role authenticated;

-- ============================================================================
-- C) Regression: die LSA haengt NICHT an der Policy (SECURITY DEFINER)
-- ============================================================================

select is(
  ((public.lsa_start(:'sid', 8, 'Mathematik')) ->> 'total_items')::int >= 1,
  true,
  'lsa_start liefert weiterhin Items — die neue Policy schneidet den Pool nicht ab'
);

reset role;
select pg_temp.act_as(:'student_uid');

select (select id from lsa_sessions where student_id = :'sid' limit 1) as lsa_sid \gset

select is(
  (select public.lsa_submit(:'lsa_sid', :'tid_ready', '{"text":"16"}'::jsonb, 4200)::text
          like '%' || :'beleg_sent' || '%'),
  false,
  'lsa_submit spiegelt den Beleg nicht zurueck — auch nicht bei richtiger Antwort'
);

-- ============================================================================
-- D) Der Coach-Kontext: er sieht die Redaktion. Sonst gaebe es kein Tool.
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'coach_uid');

select is(public.get_my_role(), 'coach', 'Fixture: der zweite Testnutzer ist ein coach');

select is(
  (select count(*) from tasks where id in (:'tid_ready', :'tid_draft')),
  2::bigint,
  'der Coach sieht beide Items — auch das draft'
);

select * from finish();
rollback;
