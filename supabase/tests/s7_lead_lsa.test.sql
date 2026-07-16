-- ============================================================================
-- S7 (Lead→LSA): lead_lsa_freigeben / lead_convert / lead_delete-Kaskade /
-- Guards / lead_assessment_upsert — und die A3-Regression.
--
-- Bewiesen wird:
--   1. Freigabe-Gates: nur Admin; ohne DSGVO-Einwilligung keine Freigabe und
--      KEIN angelegter Datensatz.
--   2. Freigabe legt den provisorischen Schüler idempotent an (profile_id NULL,
--      is_provisional, lead_id) und startet die Session über lsa_start;
--      leads.status='lsa_freigegeben'.
--   3. Guards: provisorische Zeilen entstehen NUR über die RPC; ein
--      provisorischer Schüler trägt NIE ein Abo; is_provisional ⇔ lead_id.
--   4. lsa_finish rückt den Lead auf 'lsa_fertig' (additiver Trigger).
--   5. lead_convert: Datensatz-Flip; danach ist das Abo frei; converted ist
--      endgültig (kein zweites Convert, kein lead_delete).
--   6. lead_delete: die Kaskade räumt Schüler + Sessions + Responses restlos —
--      kein verwaistes Datum.
--   7. A3-Regression: lsa_start (unverändert, kein Overload) und
--      lead_lsa_freigeben kennen lead_assessments nicht.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(38);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   'dddddddd-dddd-dddd-dddd-dddddddddddd'
\set coach_uid   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
\set student_uid 'ffffffff-ffff-ffff-ffff-ffffffffffff'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   's7-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   's7-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 's7-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'admin_uid',   's7-admin@test.local',   'admin',   'S7 Admin'),
  (:'coach_uid',   's7-coach@test.local',   'coach',   'S7 Coach'),
  (:'student_uid', 's7-student@test.local', 'student', 'S7 Schueler');

-- L1: voller Flow (Freigabe → fertig → Konversion). L2: Lösch-Flow.
-- L3: OHNE DSGVO-Einwilligung.
insert into leads (full_name, first_name, class_level, subjects, status,
                   consent_dsgvo_at, consent_dsgvo_by)
values ('S7 Kind Eins', 'Eins', 8, '{Mathematik}', 'contacted', now(), :'admin_uid'),
       ('S7 Kind Zwei', 'Zwei', 8, '{Mathematik}', 'contacted', now(), :'admin_uid');
insert into leads (full_name, first_name, class_level, subjects, status)
values ('S7 Kind Drei', 'Drei', 8, '{Mathematik}', 'new');

select (select id from leads where full_name = 'S7 Kind Eins') as lead1,
       (select id from leads where full_name = 'S7 Kind Zwei') as lead2,
       (select id from leads where full_name = 'S7 Kind Drei') as lead3
\gset

-- Zwei freigegebene Pool-Items (Muster aus a3_lead_assessments.test.sql).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready', 'Welcher Term ist aequivalent?',
       '{"input_type":"MC","options":[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}],"correct":["b"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 's7-mc'
  from skill_clusters c order by c.sort_order limit 1;

insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready', 'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 's7-short', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from tasks where source_ref = 's7-mc')    as t_mc,
       (select id from tasks where source_ref = 's7-short') as t_short
\gset

insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_mc',    '["b"]'::jsonb,     'x+x = 2x'),
  (:'t_short', '["0,3 m"]'::jsonb, 'GEHEIM');

insert into tiers (name, price_cents) values ('S7 Testtarif', 19900);
select (select id from tiers where name = 'S7 Testtarif') as tier_id \gset

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- 1. Freigabe-Gates
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.lead_lsa_freigeben(%L, 8, 'Mathematik')$f$, :'lead1'),
  '42501', NULL,
  'Ein Coach darf die LSA nicht freigeben (nur Admin)'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.lead_lsa_freigeben(%L, 8, 'Mathematik')$f$, :'lead3'),
  'P0001', NULL,
  'Ohne DSGVO-Einwilligung keine Freigabe (consent_dsgvo_at ist null)'
);

select is(
  (select count(*) from students where lead_id = :'lead3'),
  0::bigint,
  'Die verweigerte Freigabe hat KEINEN provisorischen Schueler hinterlassen'
);

-- ============================================================================
-- 2. Freigabe: provisorischer Schueler + Session ueber lsa_start
-- ============================================================================
select lives_ok(
  format($f$select public.lead_lsa_freigeben(%L, 8, 'Mathematik')$f$, :'lead1'),
  'Admin gibt die LSA fuer Lead 1 frei'
);

select is(
  (select count(*) from students
    where lead_id = :'lead1' and is_provisional and profile_id is null),
  1::bigint,
  'Genau ein provisorischer Schueler: is_provisional, lead_id gesetzt, profile_id NULL'
);

select (select id from students where lead_id = :'lead1') as sid1 \gset

select is(
  (select count(*) from lsa_sessions
    where student_id = :'sid1' and subject = 'Mathematik' and status = 'in_progress'),
  1::bigint,
  'Die LSA-Session laeuft — gestartet ueber die bestehende lsa_start-Logik'
);

select is(
  (select status from leads where id = :'lead1'),
  'lsa_freigegeben',
  'Der Lead steht auf lsa_freigegeben'
);

-- Idempotenz im Schueler-Teil: der zweite Aufruf legt KEINEN zweiten Schueler
-- an; die laufende Session laesst lsa_start (unveraendert) mit P0001 abweisen.
select throws_ok(
  format($f$select public.lead_lsa_freigeben(%L, 8, 'Mathematik')$f$, :'lead1'),
  'P0001', NULL,
  'Zweite Freigabe im selben Fach: lsa_start weist ab (Session laeuft bereits)'
);

select is(
  (select count(*) from students where lead_id = :'lead1'),
  1::bigint,
  'Auch nach dem zweiten Aufruf existiert genau EIN Schueler zum Lead (idempotent)'
);

-- ============================================================================
-- 3. Guards
-- ============================================================================
reset role;

-- 3a. Direkte provisorische Inserts sind gesperrt — einziger Erzeuger ist die RPC.
select throws_ok(
  format($f$insert into students (profile_id, class_level, is_provisional, lead_id)
            values (null, 8, true, %L)$f$, :'lead2'),
  '42501', NULL,
  'Ein direkter INSERT mit is_provisional=true wird abgewiesen (GUC-Schleuse)'
);

-- 3b. is_provisional ⇔ lead_id — nie das eine ohne das andere.
select throws_ok(
  format($f$insert into students (profile_id, class_level, is_provisional, lead_id)
            values (null, 8, false, %L)$f$, :'lead3'),
  '23514', NULL,
  'lead_id ohne is_provisional verletzt den CHECK (students_provisional_lead_ck)'
);

-- 3c. Ein provisorischer Schueler traegt NIE ein Abo.
select throws_ok(
  format($f$insert into student_subscriptions (student_id, tier_id)
            values (%L, %L)$f$, :'sid1', :'tier_id'),
  'P0001', NULL,
  'Abo fuer einen provisorischen Schueler wird abgewiesen (erst lead_convert)'
);

-- ============================================================================
-- 4. lsa_finish → Lead rueckt auf lsa_fertig (additiver Trigger)
-- ============================================================================
select pg_temp.act_as(:'admin_uid');

select (select id from lsa_sessions where student_id = :'sid1') as session1 \gset

select lives_ok(
  format($f$select public.lsa_finish(%L)$f$, :'session1'),
  'lsa_finish schliesst die Session ab (unveraenderte RPC)'
);

select is(
  (select status from leads where id = :'lead1'),
  'lsa_fertig',
  'Der Lead steht nach lsa_finish auf lsa_fertig'
);

-- ============================================================================
-- 5. lead_convert — der Datensatz-Flip
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.lead_convert(%L)$f$, :'lead1'),
  '42501', NULL,
  'Ein Coach darf nicht konvertieren (nur Admin)'
);

select pg_temp.act_as(:'admin_uid');
select lives_ok(
  format($f$select public.lead_convert(%L)$f$, :'lead1'),
  'Admin konvertiert Lead 1'
);

select is(
  (select count(*) from students
    where id = :'sid1' and not is_provisional and lead_id is null),
  1::bigint,
  'Der Schueler ist geflippt: is_provisional=false, lead_id=null (kein Kaskaden-Risiko mehr)'
);

select is(
  (select count(*) from leads
    where id = :'lead1' and status = 'converted' and converted_student_id = :'sid1'),
  1::bigint,
  'Der Lead ist converted und haelt die Verbindung ueber converted_student_id'
);

select is(
  (select count(*) from lsa_sessions where student_id = :'sid1'),
  1::bigint,
  'Die Session hing schon richtig — keine Migration, kein Verlust bei der Konversion'
);

-- Nach dem Flip ist das Abo frei.
reset role;
select lives_ok(
  format($f$insert into student_subscriptions (student_id, tier_id)
            values (%L, %L)$f$, :'sid1', :'tier_id'),
  'Nach lead_convert darf der (jetzt echte) Schueler ein Abo tragen'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.lead_convert(%L)$f$, :'lead1'),
  'P0001', NULL,
  'Ein bereits konvertierter Lead wird nicht erneut konvertiert'
);

select throws_ok(
  format($f$select public.lead_delete(%L)$f$, :'lead1'),
  'P0001', NULL,
  'Ein konvertierter Lead faellt weiterhin NICHT ueber lead_delete (Aufbewahrungspflicht)'
);

-- ============================================================================
-- 6. lead_delete — die Kaskade raeumt restlos (kein verwaistes Datum)
-- ============================================================================
select lives_ok(
  format($f$select public.lead_lsa_freigeben(%L, 8, 'Mathematik')$f$, :'lead2'),
  'Admin gibt die LSA fuer Lead 2 frei'
);

select (select id from students where lead_id = :'lead2') as sid2 \gset
select (select id from lsa_sessions where student_id = :'sid2') as session2 \gset

-- Eine echte Antwort, damit die Kaskade auch lsa_responses beweisbar trifft.
reset role;
insert into lsa_responses (session_id, task_id, response, correct, duration_ms)
values (:'session2', :'t_mc', '{"selected":["b"]}'::jsonb, true, 12000);

select is(
  (select count(*) from lsa_responses where session_id = :'session2'),
  1::bigint,
  'Vor der Loeschung liegt eine LSA-Antwort zur Session von Lead 2 vor'
);

select pg_temp.act_as(:'admin_uid');
select lives_ok(
  format($f$select public.lead_delete(%L)$f$, :'lead2'),
  'Admin loescht Lead 2 (nicht konvertiert — DSGVO-Zusage)'
);

reset role;
select is(
  (select count(*) from students where id = :'sid2'),
  0::bigint,
  'Der provisorische Schueler ist mit dem Lead gefallen (Kaskade students.lead_id)'
);

select is(
  (select count(*) from lsa_sessions where id = :'session2'),
  0::bigint,
  'Die LSA-Session ist mit dem Schueler gefallen'
);

select is(
  (select count(*) from lsa_responses where session_id = :'session2'),
  0::bigint,
  'Die LSA-Antworten sind mit der Session gefallen'
);

-- Der globale Nachweis: NICHTS zeigt mehr auf Lead 2 — kein verwaistes Datum.
select is(
  (select (select count(*) from students where lead_id = :'lead2')
        + (select count(*) from lead_assessments where lead_id = :'lead2')
        + (select count(*) from leads where id = :'lead2')),
  0::bigint,
  'Nach lead_delete existiert kein einziges Datum mehr zu Lead 2'
);

-- ============================================================================
-- 7. lead_assessment_upsert — der saubere Schreibweg
-- ============================================================================
select pg_temp.act_as(:'coach_uid');

select lives_ok(
  format($f$select public.lead_assessment_upsert(%L, 'parent',
            'Kind hat Probleme mit Bruchrechnen', '{Bruchrechnen}')$f$, :'lead3'),
  'Ein Coach legt die Eltern-Einschaetzung per Upsert an'
);

select lives_ok(
  format($f$select public.lead_assessment_upsert(%L, 'parent',
            'Korrigiert: eher Textaufgaben', '{Sachrechnen}')$f$, :'lead3'),
  'Der zweite Upsert derselben Quelle AKTUALISIERT statt zu duplizieren'
);

select is(
  (select count(*) from lead_assessments where lead_id = :'lead3' and source = 'parent'),
  1::bigint,
  'Genau EINE Eltern-Einschaetzung am Lead (Upsert auf lead_id, source)'
);

select is(
  (select note from lead_assessments where lead_id = :'lead3' and source = 'parent'),
  'Korrigiert: eher Textaufgaben',
  'Der Upsert hat die Notiz ueberschrieben'
);

select pg_temp.act_as(:'student_uid');
select throws_ok(
  format($f$select public.lead_assessment_upsert(%L, 'parent', 'x', '{}')$f$, :'lead3'),
  '42501', NULL,
  'Ein Schueler darf keine Einschaetzung schreiben (nur coach/admin)'
);

select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.lead_assessment_upsert(%L, 'teacher', 'x', '{}')$f$, :'lead3'),
  '23514', NULL,
  'Eine unbekannte Quelle wird abgewiesen (nur parent/child)'
);

-- ============================================================================
-- 8. A3-Regression: die Einschaetzung erreicht die Item-Auswahl weiterhin NIE
-- ============================================================================
reset role;

select is(
  pg_get_functiondef('public.lsa_start(uuid,integer,text)'::regprocedure) !~* 'lead_assessments',
  true,
  'lsa_start nennt lead_assessments weiterhin an KEINER Stelle'
);

select is(
  pg_get_functiondef('public.lead_lsa_freigeben(uuid,integer,text)'::regprocedure) !~* 'lead_assessments',
  true,
  'Auch lead_lsa_freigeben nennt lead_assessments an KEINER Stelle'
);

select is(
  (select count(*) from pg_proc
    where proname = 'lsa_start' and pronamespace = 'public'::regnamespace),
  1::bigint,
  'Es gibt weiterhin genau EINE lsa_start — kein Lead-Overload (A3-Invariante)'
);

select * from finish();
rollback;
