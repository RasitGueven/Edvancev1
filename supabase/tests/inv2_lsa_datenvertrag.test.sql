-- ============================================================================
-- INV-2 (P01): Der Datenvertrag haelt — die Loesung ist nicht leakbar, und die
-- LSA setzt keinen Lernpfad.
--
-- Zwei Invarianten, beide produkt-tragend:
--
--   A) SICHERHEIT: `task_solutions` (correct_answers/solution/hints/
--      typical_errors) ist fuer `authenticated` NICHT lesbar. Waeren die
--      Loesungen im Netzwerk-Tab sichtbar, waere die LSA als Diagnose wertlos.
--      Geprueft wird die Tabelle UND das, was der question_payload-Builder
--      tatsaechlich ausliefert — beides, weil die eine Schicht die andere
--      nicht ersetzt.
--
--   B) FernUSG: `lsa_finish` liefert einen VORSCHLAG. Es setzt weder
--      student_focus_areas noch student_competency_mastery. Erst
--      `lsa_confirm_focus` (Coach) macht daraus einen Lernpfad.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

-- --- Fixtures --------------------------------------------------------------
\set student_uid '33333333-3333-3333-3333-333333333333'
\set coach_uid   '44444444-4444-4444-4444-444444444444'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'lsa-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'lsa-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'lsa-student@test.local', 'student', 'LSA Schuelerin'),
  (:'coach_uid',   'lsa-coach@test.local',   'coach',   'LSA Coach');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Zwei freigegebene Aufgaben an einem geseedeten Mathe-Cluster: ein MC-Item
-- (AFB I) und ein short_input-Item (AFB II) — genug, um die Mischung und
-- beide Grading-Zweige zu treffen.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie lang ist die Strecke?',
       -- Bestands-Payload MIT Loesung drin (kanonisches AnswerPayload) — genau
       -- der Fall, den der Builder wegfiltern muss.
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 'inv2-short', 'm'
  from skill_clusters c order by c.sort_order limit 1;

insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready',
       'Welcher Term ist aequivalent?',
       '{"input_type":"MC","options":[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}],"correct":["b"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 'inv2-mc'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'student_uid')      as sid,
       (select id from tasks where source_ref = 'inv2-short')           as t_short,
       (select id from tasks where source_ref = 'inv2-mc')              as t_mc,
       (select cluster_id from tasks where source_ref = 'inv2-mc')      as cid
\gset

insert into task_solutions (task_id, correct_answers, solution, hints, coach_hints, typical_errors) values
  (:'t_short', '["0,3 m","30 cm"]'::jsonb, 'DIE-GEHEIME-MUSTERLOESUNG',
   '[{"level":1,"text":"Denk an die Einheit."},{"level":2,"text":"1 m = 100 cm."}]'::jsonb,
   '[{"text":"Frag nach der Einheit."}]'::jsonb,
   '[{"error":"Einheit vergessen","socratic_question":"In welcher Einheit misst du?"}]'::jsonb),
  (:'t_mc', '["b"]'::jsonb, 'x+x = 2x', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb);

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) Die Loesung ist nicht leakbar
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: der Testnutzer ist ein student');

-- DER Test aus Spec §4. Kein Grant → schon das Tabellen-Tor ist zu, RLS kommt
-- gar nicht erst zum Zug.
select throws_ok(
  'select correct_answers from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'authenticated kann task_solutions.correct_answers NICHT selektieren'
);

select throws_ok(
  'select solution from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'authenticated kann task_solutions.solution NICHT selektieren'
);

select throws_ok(
  'select hints, typical_errors from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'authenticated kann hints/typical_errors NICHT selektieren'
);

-- Zweite Schicht: das, was tatsaechlich rausgeht. Der Builder liest aus einem
-- question_payload, in dem die Loesung DRIN steht (Fixture oben) — und darf
-- sie trotzdem nicht mitschleppen.
select is(
  (select public.lsa_question_payload(:'t_mc') ?| array['correct','accepted','solution','hints','typical_errors','correct_answers']),
  false,
  'question_payload traegt kein einziges Loesungsfeld'
);

select is(
  (select public.lsa_question_payload(:'t_mc') -> 'options'),
  '[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}]'::jsonb,
  'question_payload liefert Optionen nur als id+label'
);

select is(
  (select public.lsa_question_payload(:'t_short') ->> 'kind'),
  'short_input',
  'SHORT_TEXT wird auf kind=short_input abgebildet (Diskriminator: input_type)'
);

-- ============================================================================
-- Die LSA-Schleife: der Schueler bekommt kein Richtig/Falsch
-- ============================================================================
select lives_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid'),
  'lsa_start: der Schueler darf seine eigene LSA starten'
);

-- Ab hier ohne RLS-Rolle (postgres). Zwei Gruende:
--   1. Der Schueler hat auf lsa_sessions/student_focus_areas bewusst KEIN
--      SELECT — die Assertions unten waeren als `authenticated` vakuum-gruen
--      (0 Zeilen, weil RLS filtert — nicht, weil nichts geschrieben wurde).
--   2. Die RPC-Autorisierung haengt an den JWT-Claims (get_my_role /
--      get_my_student_id), nicht an der pg-Rolle. act_as() wirkt weiter, die
--      FernUSG-Pruefungen unten sind also echt.
reset role;
select pg_temp.act_as(:'student_uid');

select (select id from lsa_sessions where student_id = :'sid' limit 1) as lsa_sid
\gset

-- Falsche Antwort auf das short_input-Item.
select is(
  (select public.lsa_submit(:'lsa_sid', :'t_short', '{"text":"3 m"}'::jsonb, 4200)
          ?| array['correct','score','solution','feedback']),
  false,
  'lsa_submit gibt dem Kind KEIN Richtig/Falsch zurueck (Diagnose, kein Uebungsmodus)'
);

-- Richtige Antwort auf das MC-Item — in der anderen Schreibweise, die Lena
-- explizit hinterlegt hat.
select lives_ok(
  format($f$select public.lsa_submit(%L, %L, '{"selected":["B"]}'::jsonb, 3100)$f$, :'lsa_sid', :'t_mc'),
  'lsa_submit: MC-Antwort wird angenommen'
);

-- Hinweise kommen einzeln auf Anfrage — und nur der angefragte Level.
select is(
  (select public.lsa_hint(:'lsa_sid', :'t_short', 1) ->> 'text'),
  'Denk an die Einheit.',
  'lsa_hint liefert genau den angefragten Hinweis-Level'
);

-- ============================================================================
-- B) FernUSG: lsa_finish schlaegt vor, es setzt nicht
-- ============================================================================
select is(
  (select public.lsa_finish(:'lsa_sid') -> 'proposal' ->> 'applied'),
  'false',
  'lsa_finish liefert einen Vorschlag (applied=false), keine Zuweisung'
);

-- Die Auswertung ist auch wirklich eine: beide Kompetenzfelder ausgewertet,
-- und die serverseitige Bewertung hat gegriffen (MC richtig, short_input
-- falsch → 1 von 2). Sonst waere „applied=false" oben vakuum-gruen.
select results_eq(
  format($f$select (s.result_summary ->> 'answered')::int,
                  jsonb_array_length(s.result_summary -> 'competencies'),
                  (select count(*) from lsa_responses r
                    where r.session_id = s.id and r.correct)::int
             from lsa_sessions s where s.id = %L$f$, :'lsa_sid'),
  $$ values (2, 2, 1) $$,
  'lsa_finish wertet serverseitig aus: 2 Antworten, 2 Kompetenzfelder, 1 richtig'
);

select is(
  (select count(*) from student_focus_areas where student_id = :'sid'),
  0::bigint,
  'lsa_finish schreibt KEINEN Lernpfad (student_focus_areas bleibt leer)'
);

select is(
  (select count(*) from student_competency_mastery where student_id = :'sid'),
  0::bigint,
  'lsa_finish setzt KEIN mastered/score (student_competency_mastery bleibt leer)'
);

-- Der Schueler kann sich den Pfad auch nicht selbst freigeben.
select throws_ok(
  format($f$select public.lsa_confirm_focus(%L)$f$, :'lsa_sid'),
  '42501',
  'LSA: Lernpfad-Freigabe nur durch Coach (FernUSG)',
  'lsa_confirm_focus: der Schueler darf seinen Lernpfad nicht selbst bestaetigen'
);

-- Erst der Coach macht aus dem Vorschlag einen Lernpfad.
select pg_temp.act_as(:'coach_uid');

select lives_ok(
  format($f$select public.lsa_confirm_focus(%L, array[%L]::uuid[])$f$, :'lsa_sid', :'cid'),
  'lsa_confirm_focus: der Coach darf den Fokus setzen — der eigene, bewusste Schritt'
);

select * from finish();
rollback;
