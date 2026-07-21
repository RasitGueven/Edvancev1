-- ============================================================================
-- S9 (Platz-Mechanik): Kiosk fuer die LSA — die drei Beweise aus
-- docs/specs/PLATZ-analyse.md §3, plus Regression.
--
-- DIE KERNANFORDERUNG: Ein Platz-Kontext kann ueber KEINEN Weg etwas
-- ausserhalb seiner zugewiesenen Session lesen. Konkret:
--
--   1. Platz OHNE Zuweisung: platz_state()='wartet'; alle lsa_* → 42501;
--      select auf students/leads/lead_assessments/lsa_sessions/lsa_responses/
--      student_progress → 0 Zeilen (mit Anti-Vakuum: die Zeilen EXISTIEREN).
--   2. Platz MIT Zuweisung: erreicht genau die EINE Session; eine zweite
--      Session (anderer Lead, anderer Platz) ist ueber keinen Parameter
--      erreichbar — die platz_*-RPCs nehmen keine session_id von aussen, und
--      lsa_* bleiben auch mit Zuweisung zu.
--   3. Nach lsa_finish / expires_at / platz_release / abort: alle platz_*
--      fallen auf 'wartet'/42501 zurueck; die alte Session ist nicht mehr
--      adressierbar. expires_at wird bei JEDEM Aufruf geprueft (§3.4).
--
--   Plus: §3.6(ii) — lsa_question_payload ist fuer authenticated nicht mehr
--   direkt aufrufbar (nur noch ueber die Tore). Und die P01-Regression:
--   lsa_may_act_for/lsa_start/lsa_submit/lsa_finish kennen 'platz' an KEINER
--   Stelle (byte-identisch im Sinne der Analyse §3.5).
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(69);

-- --- Fixtures ---------------------------------------------------------------
\set admin_uid    'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa'
\set coach_uid    'bbbbbbbb-1111-1111-1111-bbbbbbbbbbbb'
\set student_uid  'cccccccc-1111-1111-1111-cccccccccccc'
\set platz1_uid   'dddddddd-1111-1111-1111-dddddddddddd'
\set platz2_uid   'eeeeeeee-1111-1111-1111-eeeeeeeeeeee'
\set dead_uuid    '00000000-0000-0000-0000-00000000dead'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   's9-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   's9-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 's9-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'platz1_uid',  's9-platz1@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'platz2_uid',  's9-platz2@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

-- Die Platz-Konten sind NORMALE student-Profile — keine neue Rolle. Was sie zu
-- Plaetzen macht, ist ausschliesslich die platz_devices-Zeile.
insert into profiles (id, email, role, full_name) values
  (:'admin_uid',   's9-admin@test.local',   'admin',   'S9 Admin'),
  (:'coach_uid',   's9-coach@test.local',   'coach',   'S9 Coach'),
  (:'student_uid', 's9-student@test.local', 'student', 'S9 Echter Schueler'),
  (:'platz1_uid',  's9-platz1@test.local',  'student', 'S9 Platz 1'),
  (:'platz2_uid',  's9-platz2@test.local',  'student', 'S9 Platz 2');

-- Ein ECHTER Schueler mit students-Zeile — Anti-Vakuum fuer die 0-Zeilen-Tests.
insert into students (profile_id, class_level) values (:'student_uid', 8);

insert into platz_devices (profile_id, label) values
  (:'platz1_uid', 'Platz 1 (Fenster)'),
  (:'platz2_uid', 'Platz 2 (Tuer)');

-- Zwei Leads mit DSGVO-Consent → zwei Sessions (Muster aus s7).
insert into leads (full_name, first_name, class_level, subjects, status,
                   consent_dsgvo_at, consent_dsgvo_by)
values ('S9 Kind Eins', 'Eins', 8, '{Mathematik}', 'contacted', now(), :'admin_uid'),
       ('S9 Kind Zwei', 'Zwei', 8, '{Mathematik}', 'contacted', now(), :'admin_uid');

select (select id from leads where full_name = 'S9 Kind Eins') as lead1,
       (select id from leads where full_name = 'S9 Kind Zwei') as lead2
\gset

-- Anti-Vakuum fuer lead_assessments: es gibt eine Zeile, die der Platz NICHT
-- sehen darf.
insert into lead_assessments (lead_id, source, note, weak_topics)
values (:'lead1', 'parent', 'S9 Einschaetzung', '{Bruchrechnen}');

-- Zwei freigegebene Pool-Items (Muster aus s7/inv2).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'MC', 'ready', 'Welcher Term ist aequivalent?',
       '{"input_type":"MC","options":[{"id":"a","label":"2x"},{"id":"b","label":"x+x"}],"correct":["b"]}'::jsonb,
       'I', 'Terme und Gleichungen', 240, 8, 'test', 's9-mc'
  from skill_clusters c order by c.sort_order limit 1;

insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready', 'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 's9-short', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from tasks where source_ref = 's9-mc')    as t_mc,
       (select id from tasks where source_ref = 's9-short') as t_short
\gset

insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_mc',    '["b"]'::jsonb,     'x+x = 2x'),
  (:'t_short', '["0,3 m"]'::jsonb, 'GEHEIM');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- Beide Sessions ueber den echten Weg (lead_lsa_freigeben → lsa_start).
select pg_temp.act_as(:'admin_uid');
select public.lead_lsa_freigeben(:'lead1', 8, 'Mathematik');
select public.lead_lsa_freigeben(:'lead2', 8, 'Mathematik');

select (select id from students where lead_id = :'lead1') as sid1,
       (select id from students where lead_id = :'lead2') as sid2
\gset
select (select id from lsa_sessions where student_id = :'sid1') as s1,
       (select id from lsa_sessions where student_id = :'sid2') as s2
\gset

-- ============================================================================
-- 1. Platz OHNE Zuweisung: 'wartet', alle lsa_* zu, RLS zeigt NICHTS
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'platz1_uid');

select is(
  (select public.platz_state() ->> 'status'),
  'wartet',
  'Platz ohne Zuweisung: platz_state() = wartet'
);

select throws_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid1'),
  '42501', NULL,
  'Platz ohne Zuweisung: lsa_start → 42501 (kein get_my_student_id, kein coach/admin)'
);

select throws_ok(
  format($f$select public.lsa_submit(%L, %L, '{"text":"42"}'::jsonb, 1000)$f$, :'s1', :'t_mc'),
  '42501', NULL,
  'Platz ohne Zuweisung: lsa_submit → 42501'
);

select throws_ok(
  format($f$select public.lsa_hint(%L, %L, 1)$f$, :'s1', :'t_mc'),
  '42501', NULL,
  'Platz ohne Zuweisung: lsa_hint → 42501'
);

select throws_ok(
  format($f$select public.lsa_finish(%L)$f$, :'s1'),
  '42501', NULL,
  'Platz ohne Zuweisung: lsa_finish → 42501'
);

-- §3.6(ii): der Builder ist fuer authenticated nicht mehr direkt aufrufbar.
select throws_ok(
  format($f$select public.lsa_question_payload(%L)$f$, :'t_mc'),
  '42501', NULL,
  'lsa_question_payload ist fuer authenticated NICHT direkt aufrufbar (§3.6(ii))'
);

select throws_ok(
  'select public.platz_next()',
  '42501', NULL,
  'Platz ohne Zuweisung: platz_next → 42501'
);

select throws_ok(
  format($f$select public.platz_submit(%L, '{"text":"42"}'::jsonb, 1000)$f$, :'t_mc'),
  '42501', NULL,
  'Platz ohne Zuweisung: platz_submit → 42501'
);

select throws_ok(
  'select public.platz_finish()',
  '42501', NULL,
  'Platz ohne Zuweisung: platz_finish → 42501'
);

select is((select count(*) from students),         0::bigint, 'RLS: der Platz sieht 0 Zeilen in students');
select is((select count(*) from leads),            0::bigint, 'RLS: der Platz sieht 0 Zeilen in leads');
select is((select count(*) from lead_assessments), 0::bigint, 'RLS: der Platz sieht 0 Zeilen in lead_assessments');
select is((select count(*) from lsa_sessions),     0::bigint, 'RLS: der Platz sieht 0 Zeilen in lsa_sessions');
select is((select count(*) from lsa_responses),    0::bigint, 'RLS: der Platz sieht 0 Zeilen in lsa_responses');
select is((select count(*) from student_progress), 0::bigint, 'RLS: der Platz sieht 0 Zeilen in student_progress');
select is((select count(*) from platz_assignments), 0::bigint, 'RLS: der Platz sieht 0 Zeilen in platz_assignments (keine Zuweisung)');

-- Anti-Vakuum: die 0-Zeilen oben sind RLS, nicht Leere.
reset role;
select is(
  (select (select count(*) from students) >= 3
      and (select count(*) from leads) >= 2
      and (select count(*) from lsa_sessions) >= 2
      and (select count(*) from lead_assessments) >= 1),
  true,
  'Anti-Vakuum: students/leads/lsa_sessions/lead_assessments SIND befuellt'
);

-- Rollenpruefung im Body: wer nicht in platz_devices steht, kommt nicht durch —
-- auch nicht als echter Schueler, auch nicht als Admin.
select pg_temp.act_as(:'student_uid');
select throws_ok(
  'select public.platz_state()',
  '42501', NULL,
  'Ein normaler Schueler (ohne platz_devices-Zeile) → platz_state 42501'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  'select public.platz_state()',
  '42501', NULL,
  'Auch der Admin ist kein Platz → platz_state 42501'
);

-- ============================================================================
-- 2. Zuweisung: genau die EINE Session — und keine andere
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz1_uid', :'s1'),
  '42501', NULL,
  'platz_assign: nur Admin (Coach → 42501)'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'dead_uuid', :'s1'),
  'P0002', NULL,
  'platz_assign: ein Konto ohne platz_devices-Zeile ist kein Platz (P0002)'
);

select lives_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz1_uid', :'s1'),
  'Admin weist Platz 1 die Session von Kind Eins zu'
);

select throws_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz1_uid', :'s2'),
  'P0001', NULL,
  'Eine zweite Zuweisung auf denselben Platz wird verweigert (aktive Zuweisung)'
);

select lives_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz2_uid', :'s2'),
  'Admin weist Platz 2 die Session von Kind Zwei zu'
);

-- Item-Reihenfolge der Session 1 (randomisiert) festhalten.
reset role;
select (select item_ids[1] from lsa_sessions where id = :'s1') as s1_first \gset
select (select case when item_ids[1] = :'t_mc'::uuid then :'t_short'::uuid
                    else :'t_mc'::uuid end
          from lsa_sessions where id = :'s1') as s1_other \gset
select (select array_length(item_ids, 1) from lsa_sessions where id = :'s1') as s1_total \gset

set local role authenticated;
select pg_temp.act_as(:'platz1_uid');

select is(
  (select public.platz_state() ->> 'status'),
  'zugewiesen',
  'Platz 1 ist zugewiesen'
);

select is(
  (select public.platz_state() ->> 'first_name'),
  'Eins',
  'Begruessung: der Rufname kommt ueber session → students.lead_id → leads.first_name'
);

select is(
  (select (public.platz_state() -> 'progress' ->> 'answered')::int),
  0,
  'Fortschritt vor der ersten Antwort: answered = 0'
);

select is(
  (select (public.platz_state() -> 'progress' ->> 'total')::int),
  :'s1_total'::int,
  'Fortschritt: total = geplante Items der Session'
);

-- Der Platz erfaehrt NIE etwas Adressierendes oder Auswertendes.
select is(
  (select public.platz_state() ?| array['session_id','student_id','lead_id','result_summary']),
  false,
  'platz_state traegt weder session_id noch student_id noch lead_id noch Auswertung'
);

select is(
  (select count(*) from platz_assignments),
  1::bigint,
  'RLS: der Platz sieht GENAU die eigene aktive Zuweisung — nicht die von Platz 2'
);

select is(
  (select public.platz_next() -> 'item' ->> 'task_id'),
  :'s1_first',
  'platz_next liefert das erste offene Item der ZUGEWIESENEN Session'
);

select throws_ok(
  format($f$select public.platz_submit(%L, '{"text":"42"}'::jsonb, 1000)$f$, :'s1_other'),
  'P0001', NULL,
  'platz_submit verweigert jedes Item ausser dem aktuell offenen (P0001)'
);

select is(
  (select public.platz_submit(:'s1_first', '{"text":"42"}'::jsonb, 4200)
          ?| array['correct','score','feedback','solution']),
  false,
  'platz_submit reicht durch und gibt KEIN Richtig/Falsch zurueck (P01-Zusage haelt)'
);

-- Der Claims-Tausch (Auftrags-Identitaet) ist geschlossen: der Aufrufer ist
-- nach dem Submit wieder der Platz.
select is(
  auth.uid(),
  :'platz1_uid'::uuid,
  'Nach platz_submit ist auth.uid() wieder der Platz (Claims-Tausch geschlossen)'
);

reset role;
select is(
  (select count(*) from lsa_responses
    where session_id = :'s1' and task_id = :'s1_first' and duration_ms = 4200),
  1::bigint,
  'Die Antwort liegt in der zugewiesenen Session — inkl. duration_ms (Eltern-Report)'
);

-- Die ZWEITE Session ist ueber keinen Weg erreichbar: platz_* nehmen keine
-- session_id von aussen, und die lsa_* bleiben auch MIT Zuweisung zu.
set local role authenticated;
select pg_temp.act_as(:'platz1_uid');

select throws_ok(
  format($f$select public.lsa_submit(%L, %L, '{"text":"42"}'::jsonb, 1000)$f$, :'s2', :'t_mc'),
  '42501', NULL,
  'Auch MIT Zuweisung: lsa_submit auf die fremde Session → 42501'
);

select throws_ok(
  format($f$select public.lsa_finish(%L)$f$, :'s2'),
  '42501', NULL,
  'Auch MIT Zuweisung: lsa_finish auf die fremde Session → 42501'
);

-- ============================================================================
-- 3. Rueckfall: lsa_finish / expires_at / platz_release / abort → 'wartet'
-- ============================================================================
select is(
  (select public.platz_next() -> 'item' ->> 'task_id'),
  :'s1_other',
  'platz_next rueckt nach dem Submit auf das zweite Item vor'
);

select lives_ok(
  format($f$select public.platz_submit(%L, '{"text":"0,3 m"}'::jsonb, 3000)$f$, :'s1_other'),
  'Platz 1 beantwortet das letzte Item'
);

select is(
  (select public.platz_next()),
  '{"item": null, "done": true}'::jsonb,
  'Alle Items beantwortet: platz_next meldet done, kein weiteres Payload'
);

-- DER Beweis, dass die Auswertung nie das Tablet erreicht: platz_finish gibt
-- exakt {ok:true} zurueck — lsa_finish liefert intern die result_summary, und
-- sie wird verworfen.
select is(
  (select public.platz_finish()),
  '{"ok": true}'::jsonb,
  'platz_finish gibt exakt {ok:true} zurueck — KEINE Auswertungsdaten'
);

reset role;
select is(
  (select status from lsa_sessions where id = :'s1'),
  'completed',
  'Die Session ist ueber die unveraenderte lsa_finish abgeschlossen'
);

select is(
  (select count(*) from platz_assignments
    where platz_profile_id = :'platz1_uid' and released_at is not null),
  1::bigint,
  'Der Release-Trigger hat die Zuweisung mit dem Abschluss freigegeben'
);

set local role authenticated;
select pg_temp.act_as(:'platz1_uid');

select is(
  (select public.platz_state() ->> 'status'),
  'wartet',
  'Nach lsa_finish: der Platz ist wieder leer (wartet)'
);

select throws_ok(
  'select public.platz_next()',
  '42501', NULL,
  'Nach lsa_finish: platz_next → 42501 (vergangene Session nicht adressierbar)'
);

select throws_ok(
  format($f$select public.platz_submit(%L, '{"text":"42"}'::jsonb, 1000)$f$, :'s1_first'),
  '42501', NULL,
  'Nach lsa_finish: platz_submit → 42501'
);

select throws_ok(
  'select public.platz_finish()',
  '42501', NULL,
  'Nach lsa_finish: platz_finish → 42501'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz1_uid', :'s1'),
  'P0001', NULL,
  'Eine abgeschlossene Session ist nicht mehr zuweisbar (P0001)'
);

-- --- expires_at: bei JEDEM Aufruf geprueft (§3.4) ----------------------------
reset role;
update platz_assignments
   set expires_at = now() - interval '1 minute'
 where platz_profile_id = :'platz2_uid' and released_at is null;

set local role authenticated;
select pg_temp.act_as(:'platz2_uid');

select is(
  (select public.platz_state() ->> 'status'),
  'wartet',
  'Abgelaufene Zuweisung (expires_at < now): platz_state = wartet — ohne released_at'
);

select throws_ok(
  'select public.platz_next()',
  '42501', NULL,
  'Abgelaufene Zuweisung: platz_next → 42501'
);

select is(
  (select count(*) from platz_assignments),
  0::bigint,
  'RLS: die abgelaufene Zuweisung ist fuer den Platz unsichtbar'
);

-- Neuzuweisung nach Ablauf: platz_assign raeumt die abgelaufene Zeile
-- (Partial-Unique-Index bliebe sonst blockiert).
select pg_temp.act_as(:'admin_uid');
select lives_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz2_uid', :'s2'),
  'Nach Ablauf kann der Admin denselben Platz neu zuweisen (Alt-Zeile wird released)'
);

reset role;
select is(
  (select count(*) from platz_assignments
    where platz_profile_id = :'platz2_uid' and released_at is null),
  1::bigint,
  'Genau EINE aktive Zuweisung fuer Platz 2 — die abgelaufene ist released'
);

select (select id from platz_assignments
         where platz_profile_id = :'platz2_uid' and released_at is null) as a2b
\gset

-- --- platz_release: der Admin-Weg --------------------------------------------
select pg_temp.act_as(:'coach_uid');
select throws_ok(
  format($f$select public.platz_release(%L)$f$, :'a2b'),
  '42501', NULL,
  'platz_release: nur Admin (Coach → 42501)'
);

select pg_temp.act_as(:'admin_uid');
select throws_ok(
  format($f$select public.platz_release(%L)$f$, :'dead_uuid'),
  'P0002', NULL,
  'platz_release: unbekannte Zuweisung → P0002'
);

select lives_ok(
  format($f$select public.platz_release(%L)$f$, :'a2b'),
  'Admin gibt die Zuweisung von Platz 2 manuell frei'
);

set local role authenticated;
select pg_temp.act_as(:'platz2_uid');
select is(
  (select public.platz_state() ->> 'status'),
  'wartet',
  'Nach platz_release: der Platz ist wieder leer (wartet)'
);

-- --- abort: auch eine abgebrochene Session gibt den Platz frei ---------------
select pg_temp.act_as(:'admin_uid');
select lives_ok(
  format($f$select public.platz_assign(%L, %L)$f$, :'platz2_uid', :'s2'),
  'Admin weist Platz 2 die (noch laufende) Session erneut zu'
);

reset role;
update lsa_sessions set status = 'aborted' where id = :'s2';

select is(
  (select count(*) from platz_assignments
    where platz_profile_id = :'platz2_uid' and released_at is null),
  0::bigint,
  'Der Release-Trigger greift auch bei aborted'
);

set local role authenticated;
select pg_temp.act_as(:'platz2_uid');
select is(
  (select public.platz_state() ->> 'status'),
  'wartet',
  'Nach abort: der Platz ist wieder leer (wartet)'
);

-- ============================================================================
-- 4. Regression: der P01-Datenvertrag kennt die Platz-Mechanik NICHT
-- ============================================================================
reset role;

select is(
  pg_get_functiondef('public.lsa_may_act_for(uuid)'::regprocedure) !~* 'platz',
  true,
  'lsa_may_act_for nennt platz an KEINER Stelle (unveraendert)'
);

select is(
  pg_get_functiondef('public.lsa_start(uuid,integer,text)'::regprocedure) !~* 'platz',
  true,
  'lsa_start nennt platz an KEINER Stelle (unveraendert)'
);

select is(
  pg_get_functiondef('public.lsa_submit(uuid,uuid,jsonb,integer)'::regprocedure) !~* 'platz',
  true,
  'lsa_submit nennt platz an KEINER Stelle (unveraendert)'
);

select is(
  pg_get_functiondef('public.lsa_finish(uuid)'::regprocedure) !~* 'platz',
  true,
  'lsa_finish nennt platz an KEINER Stelle (unveraendert)'
);

select is(
  pg_get_functiondef('public.lsa_question_payload(uuid)'::regprocedure) !~* 'platz',
  true,
  'lsa_question_payload nennt platz an KEINER Stelle (nur das Grant hat sich geaendert)'
);

select is(
  (select count(*) from pg_proc
    where proname in ('lsa_submit', 'lsa_finish')
      and pronamespace = 'public'::regnamespace),
  2::bigint,
  'Genau EINE lsa_submit und EINE lsa_finish — kein Platz-Overload'
);

select is(
  has_function_privilege('authenticated', 'public.lsa_question_payload(uuid)', 'execute'),
  false,
  '§3.6(ii) gepinnt: authenticated hat KEIN execute mehr auf lsa_question_payload'
);

select is(
  has_function_privilege('service_role', 'public.lsa_question_payload(uuid)', 'execute'),
  true,
  'service_role behaelt execute auf lsa_question_payload (Seed-/Server-Pfad)'
);

select is(
  (select has_function_privilege('anon', 'public.platz_state()', 'execute')
       or has_function_privilege('anon', 'public.platz_next()', 'execute')
       or has_function_privilege('anon', 'public.platz_submit(uuid,jsonb,integer)', 'execute')
       or has_function_privilege('anon', 'public.platz_finish()', 'execute')
       or has_function_privilege('anon', 'public.platz_assign(uuid,uuid)', 'execute')
       or has_function_privilege('anon', 'public.platz_release(uuid)', 'execute')),
  false,
  'anon hat auf KEINE platz_*-Funktion execute'
);

select * from finish();
rollback;
