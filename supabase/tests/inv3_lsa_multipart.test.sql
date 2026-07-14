-- ============================================================================
-- INV-3 (P02): Multi-Part haelt den Datenvertrag — und die Diagnostik bleibt
-- pro Teilaufgabe.
--
-- Vier Invarianten:
--
--   A) STRUKTUR: tasks.parts ist ein Vertrag, keine Ablage. Eine Loesung, ein
--      fehlender Stamm, ein nicht auto-gradebarer Antworttyp oder eine fehlende
--      Zeitangabe kommen gar nicht erst in die Tabelle (CHECK, nicht Bitte).
--
--   B) SICHERHEIT: die Whitelist von lsa_question_payload gilt REKURSIV. Auch in
--      der Teilaufgabe darf kein Loesungsfeld auftauchen — auf keiner Ebene.
--
--   C) AUSWERTUNG: lsa_submit schreibt eine Zeile PRO TEILAUFGABE und verraet dem
--      Kind auf keiner Ebene ein Richtig/Falsch. lsa_finish aggregiert nach
--      Teilaufgaben-Kompetenz — kein Item-Gesamtergebnis, keine "2 von 3"-Quote.
--
--   D) INV-2 (unveraendert): die LSA schreibt KEINE xp_events und fasst
--      student_progress nicht an. Und das flache Bestandsitem laeuft daneben
--      unveraendert weiter — Multi-Part liegt neben ihm, nicht darueber.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(23);

-- T1b verbietet Loesungsfelder in tasks.question_payload
-- (`tasks_question_payload_no_solution`). Die Fixtures unten tragen bewusst
-- `accepted` im Payload, um zu beweisen, dass der Builder unabhaengig von der
-- Datenlage filtert. Lokal aufgehoben; die Transaktion endet in `rollback`.
alter table tasks drop constraint tasks_question_payload_no_solution;

-- --- Fixtures --------------------------------------------------------------
\set student_uid '55555555-5555-5555-5555-555555555555'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'mp-student@test.local', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'mp-student@test.local', 'student', 'MP Schuelerin');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Ein flaches Bestandsitem — es MUSS unveraendert weiterlaufen (Regression).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'II', 'Daten und Zufall', 300, 8, 'test', 'inv3-flat', 'm'
  from skill_clusters c order by c.sort_order limit 1;

-- Ein Ersatz-Item (draft → nicht im Pool), an dem die task_solutions-Constraint
-- geprueft wird, ohne den PK der echten Fixtures zu belegen.
insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref)
select c.id, 'exercise', 'SHORT_TEXT', 'draft', 'Reserve', 'test', 'inv3-spare'
  from skill_clusters c order by c.sort_order limit 1;

-- Das Multi-Part-Item: EIN Stamm, drei Teilaufgaben, drei Kompetenzen, zwei
-- Antworttypen. competency_content des ITEMS ist bewusst 'Multi-Stamm' — taucht
-- es in der Auswertung auf, wurde nach Item statt nach Teilaufgabe aggregiert.
insert into tasks (
  cluster_id, content_type, input_type, status, question,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, parts
)
select c.id, 'exercise', 'MULTI_PART', 'ready',
       'Ein Pullover kostet 80 €. Im Schlussverkauf wird er um 20 % reduziert.',
       'II', 'Multi-Stamm', 420, 8, 'test', 'inv3-mp',
       '[
          {"nr":1,"kind":"short_input","prompt":"Wie viel Euro betraegt die Ermaessigung?",
           "unit":"€","competency_content":"Prozent und Zinsen","afb":"I"},
          {"nr":2,"kind":"mc","prompt":"Welcher Term beschreibt den neuen Preis?",
           "options":[{"id":"a","label":"80 mal 0,2"},{"id":"b","label":"80 mal 0,8"}],
           "competency_content":"Terme und Gleichungen","afb":"II"},
          {"nr":3,"kind":"short_input","prompt":"Wie viel cm misst der Aufnaeher?",
           "unit":"cm","competency_content":"Groessen und Messen","afb":"II"}
        ]'::jsonb
  from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'student_uid') as sid,
       (select id from tasks where source_ref = 'inv3-flat')       as t_flat,
       (select id from tasks where source_ref = 'inv3-spare')      as t_spare,
       (select id from tasks where source_ref = 'inv3-mp')         as t_mp,
       (select c.id from skill_clusters c order by c.sort_order limit 1) as cid
\gset

-- Die Loesung: flach als Array, Multi-Part als Objekt mit der Teilaufgaben-Nummer
-- als Schluessel. Beide Formen koexistieren in derselben Spalte.
insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_flat', '["0,3 m","30 cm"]'::jsonb,                        'GEHEIM-FLACH'),
  (:'t_mp',   '{"1":["16"],"2":["b"],"3":["12 cm","12"]}'::jsonb, 'GEHEIM-MULTI');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) tasks.parts ist ein Vertrag — nicht wohlmeinend, sondern durchgesetzt
-- ============================================================================

select is(
  (select input_type from tasks where id = :'t_mp'),
  'MULTI_PART',
  'MULTI_PART ist ein erlaubter input_type (tasks_input_type_check erweitert)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               est_duration_sec, source, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', 'Stamm', 300, 'test',
              '[{"nr":1,"kind":"short_input","prompt":"a","correct":["16"]},
                {"nr":2,"kind":"short_input","prompt":"b"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'tasks.parts nimmt KEIN Loesungsfeld an (correct/accepted/solution/hints/...)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               est_duration_sec, source, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', '   ', 300, 'test',
              '[{"nr":1,"kind":"short_input","prompt":"a"},
                {"nr":2,"kind":"short_input","prompt":"b"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Multi-Part OHNE abtrennbaren Stamm wird abgewiesen (Spec §2: dann ist es keines)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', 'Stamm', 'test',
              '[{"nr":1,"kind":"short_input","prompt":"a"},
                {"nr":2,"kind":"short_input","prompt":"b"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Multi-Part ohne est_duration_sec wird abgewiesen (Zeitbudget, Spec §5)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               est_duration_sec, source, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', 'Stamm', 300, 'test',
              '[{"nr":1,"kind":"free_text","prompt":"Begruende deinen Weg."},
                {"nr":2,"kind":"short_input","prompt":"b"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Teilaufgaben-kind ist auf short_input|mc beschraenkt (auto-gradebar, Spec §2)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, parts)
            values (%L, 'exercise', 'SHORT_TEXT', 'ready', 'Flach', 'test',
              '[{"nr":1,"kind":"short_input","prompt":"a"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Ein flaches Item darf keine parts tragen'
);

select throws_ok(
  format($f$insert into task_solutions (task_id, correct_answers)
            values (%L, '{"1":"16"}'::jsonb)$f$, :'t_spare'),
  '23514', NULL,
  'correct_answers als Objekt: jeder Wert muss ein Array sein'
);

-- ============================================================================
-- B) Die Whitelist gilt REKURSIV
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(
  (select public.lsa_question_payload(:'t_mp') ->> 'kind'),
  'multi_part',
  'lsa_question_payload: MULTI_PART wird auf kind=multi_part abgebildet'
);

select is(
  (select public.lsa_question_payload(:'t_mp') ->> 'stem'),
  'Ein Pullover kostet 80 €. Im Schlussverkauf wird er um 20 % reduziert.',
  'Der Stamm steht oben — getrennt von den Teilaufgaben-Prompts (Spec §2)'
);

-- Feldgenau: die Teilaufgabe wird GEBAUT, nicht durchgereicht. competency_content
-- und afb sind Diagnostik-Metadaten und haben im Client-Payload nichts verloren.
select is(
  (select public.lsa_question_payload(:'t_mp') -> 'parts'),
  '[
     {"nr":1,"kind":"short_input","prompt":"Wie viel Euro betraegt die Ermaessigung?","unit":"€"},
     {"nr":2,"kind":"mc","prompt":"Welcher Term beschreibt den neuen Preis?",
      "options":[{"id":"a","label":"80 mal 0,2"},{"id":"b","label":"80 mal 0,8"}]},
     {"nr":3,"kind":"short_input","prompt":"Wie viel cm misst der Aufnaeher?","unit":"cm"}
   ]'::jsonb,
  'parts[] traegt exakt nr/kind/prompt/unit/options(id,label) — kein competency_*, kein afb'
);

-- DER rekursive Test: ueber den GESAMTEN Payload-Text, nicht nur die oberste
-- Ebene. Ein Loesungsfeld in einer Teilaufgabe wuerde hier auffallen.
select is(
  (select public.lsa_question_payload(:'t_mp')::text
          ~* '(correct|accepted|solution|correct_answers|hints|typical_errors|geheim)'),
  false,
  'Multi-Part-Payload traegt auf KEINER Ebene ein Loesungsfeld (rekursiv geprueft)'
);

-- ============================================================================
-- C) Auswertung pro Teilaufgabe
-- ============================================================================
select lives_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid'),
  'lsa_start: Multi-Part und flaches Item stehen gemeinsam im Zeitbudget-Pool'
);

-- Ab hier ohne RLS-Rolle: der Schueler hat auf lsa_sessions/lsa_responses bewusst
-- KEIN SELECT (die Zeilen tragen `correct`). Die RPC-Autorisierung haengt an den
-- JWT-Claims, act_as() wirkt also weiter.
reset role;
select pg_temp.act_as(:'student_uid');

select (select id from lsa_sessions where student_id = :'sid' limit 1) as lsa_sid
\gset

select is(
  (select array_length(item_ids, 1) from lsa_sessions where id = :'lsa_sid'),
  2,
  'Die Session zieht beide Items (420 s + 300 s bleiben unter dem 20-min-Budget)'
);

-- EINE Anfrage mit allen Teilantworten (Spec §4). Teilaufgabe 1 und 2 richtig,
-- 3 falsch — der Client erfaehrt davon nichts.
select is(
  (select public.lsa_submit(:'lsa_sid', :'t_mp',
            '{"1":"16","2":"b","3":"99"}'::jsonb, 61000)::text
          ~* '(correct|score|feedback|solution|richtig|falsch|geheim)'),
  false,
  'lsa_submit verraet auf KEINER Ebene Korrektheit — auch nicht aggregiert, auch nicht als Zaehler'
);

select results_eq(
  format($f$select part_nr, correct from lsa_responses
             where session_id = %L and task_id = %L order by part_nr$f$,
         :'lsa_sid', :'t_mp'),
  $$ values (1, true), (2, true), (3, false) $$,
  'lsa_submit schreibt EINE Zeile pro Teilaufgabe — jede einzeln bewertet'
);

-- Append-only: der Unique-Index (session, task, part) haelt. Ein zweiter Submit
-- ueberschreibt nichts und dupliziert nichts.
select public.lsa_submit(:'lsa_sid', :'t_mp', '{"1":"999","2":"a","3":"12"}'::jsonb, 5000);

select is(
  (select count(*) from lsa_responses where session_id = :'lsa_sid' and task_id = :'t_mp'),
  3::bigint,
  'Ein zweiter Submit dupliziert die Teilaufgaben-Zeilen nicht (append-only)'
);

-- Das flache Item: unveraendert. Eine Zeile, part_nr null.
select public.lsa_submit(:'lsa_sid', :'t_flat', '{"text":"3 m"}'::jsonb, 4200);

select results_eq(
  format($f$select part_nr, correct from lsa_responses
             where session_id = %L and task_id = %L$f$, :'lsa_sid', :'t_flat'),
  $$ values (null::int, false) $$,
  'Das flache Bestandsitem laeuft unveraendert: eine Zeile, part_nr = null'
);

-- ============================================================================
-- D) result_summary: pro Kompetenz, nicht pro Item
-- ============================================================================
select public.lsa_finish(:'lsa_sid');

select results_eq(
  format($f$select (result_summary ->> 'answered')::int,
                  (result_summary ->> 'answered_parts')::int,
                  (result_summary ->> 'planned')::int
             from lsa_sessions where id = %L$f$, :'lsa_sid'),
  $$ values (2, 4, 2) $$,
  'Zwei Items, aber VIER Datenpunkte — das Multi-Part-Item liefert drei'
);

select is(
  (select jsonb_array_length(result_summary -> 'competencies')
     from lsa_sessions where id = :'lsa_sid'),
  4,
  'Vier Kompetenz-Eintraege: drei aus den Teilaufgaben, einer aus dem flachen Item'
);

select set_eq(
  format($f$select c ->> 'competency'
             from lsa_sessions s,
                  lateral jsonb_array_elements(s.result_summary -> 'competencies') as e(c)
            where s.id = %L$f$, :'lsa_sid'),
  $$ values ('Prozent und Zinsen'), ('Terme und Gleichungen'),
            ('Groessen und Messen'), ('Daten und Zufall') $$,
  'Aggregiert wird nach TEILAUFGABEN-Kompetenz — die Item-Kompetenz (Multi-Stamm) taucht nicht auf'
);

-- Kein Item-Gesamtergebnis, keine "2 von 3"-Quote, kein Item-Score (Spec §6).
select is(
  (select result_summary ?| array['score','item_scores','items','items_correct','per_item']
     from lsa_sessions where id = :'lsa_sid'),
  false,
  'result_summary kennt kein Item-Gesamtergebnis — nur Kompetenz-Datenpunkte'
);

-- ============================================================================
-- E) INV-2 haelt: die LSA ist keine Belohnungsschleife
-- ============================================================================
select is(
  (select count(*) from xp_events where student_id = :'sid'),
  0::bigint,
  'lsa_submit/lsa_finish schreiben KEINE xp_events (INV-2)'
);

select is(
  (select coalesce(sum(xp_total), 0)::bigint from student_progress where student_id = :'sid'),
  0::bigint,
  'lsa_submit/lsa_finish fassen student_progress nicht an (INV-2)'
);

select * from finish();
rollback;
