-- ============================================================================
-- LSA-Taschenrechner (Migration 20261030091351).
--
--   A) lsa_question_payload liefert taschenrechner in allen drei Formen, die Vorschau bleibt identisch.
--   B) calculator_opened im Antwortobjekt ändert weder Abgabeart noch Wertung noch Fehlbild und wird
--      von lsa_submit wortwörtlich gespeichert, bei Mehrteilern je Teil.
--   C) pruef_taschenrechner_setzen: Lena nur vor der Freigabe, Admin auch danach, sonst niemand.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(27);

\set admin_uid   '3c000000-0000-4000-8000-00000000000a'
\set lena_uid    '3c000000-0000-4000-8000-00000000000b'
\set coach_uid   '3c000000-0000-4000-8000-00000000000c'
\set student_uid '3c000000-0000-4000-8000-00000000000d'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'tr-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',    'tr-lena@test.local',    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'tr-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'tr-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid',   'tr-admin@test.local',   'admin',   'TR Admin',    false),
  (:'lena_uid',    'tr-lena@test.local',    'coach',   'TR Lena',     true),
  (:'coach_uid',   'tr-coach@test.local',   'coach',   'TR Coach',    false),
  (:'student_uid', 'tr-student@test.local', 'student', 'TR Schueler', false);
insert into students (profile_id, class_level) values (:'student_uid', 9);
update pruef_einstellungen set nur_pilot = false;

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

create function pg_temp.flach(p_ref text, p_typ text, p_status text) returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (cluster_id, content_type, input_type, status, title, question, question_payload, afb,
                     competency_content, est_duration_sec, class_level, curriculum_grade, skill_key, source, source_ref)
  select c.id, 'exercise', p_typ, p_status, 'AFB II · ' || p_ref, 'Berechne.',
         case when p_typ = 'MC' then '{"options":[{"id":"a","label":"1"},{"id":"b","label":"2"}]}'::jsonb end,
         'II', 'Zahlen', 300, 9, 9, 'zahl_wurzel_naeherung', 'tr_test', p_ref
    from skill_clusters c order by c.sort_order limit 1
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance)
  values (v, case when p_typ = 'MC' then '["b"]'::jsonb else '["5,48"]'::jsonb end,
          case when p_typ = 'MC' then null else '{"canonical":"5,48","known_errors":{"15":"halbiert"}}'::jsonb end);
  return v;
end $$;

select pg_temp.flach('tr-kurz', 'NUMERIC', 'ready') as kurz,
       pg_temp.flach('tr-mc',   'MC',      'ready') as mc,
       pg_temp.flach('tr-frei', 'NUMERIC', 'ready') as frei,
       pg_temp.flach('tr-entw', 'NUMERIC', 'draft') as entw
\gset

insert into tasks (cluster_id, content_type, input_type, status, question, afb, competency_content,
                   est_duration_sec, class_level, source, source_ref, parts)
select c.id, 'exercise', 'MULTI_PART', 'ready', 'Ein Stamm.', 'II', 'Zahlen', 300, 9, 'tr_test', 'tr-mp',
       '[{"nr":1,"kind":"short_input","prompt":"a","competency_content":"Zahlen","afb":"I"},
         {"nr":2,"kind":"mc","prompt":"b","options":[{"id":"a","label":"1"},{"id":"b","label":"2"}],
          "competency_content":"Zahlen","afb":"I"}]'::jsonb
  from skill_clusters c order by c.sort_order limit 1;
select id as mp from tasks where source_ref = 'tr-mp' \gset
insert into task_solutions (task_id, correct_answers) values (:'mp', '{"1":["16"],"2":["b"]}');

-- ── A) Payload ──────────────────────────────────────────────────────────────
select is((public.lsa_question_payload(:'kurz') ->> 'taschenrechner'), 'false', 'Default: kein Rechner, Feld steht im Payload');

update tasks set taschenrechner = true where id in (:'kurz', :'mc', :'mp');
select is((public.lsa_question_payload(:'kurz') ->> 'taschenrechner'), 'true', 'short_input trägt das Feld');
select is((public.lsa_question_payload(:'mc') ->> 'taschenrechner'), 'true', 'mc trägt das Feld');
select is((public.lsa_question_payload(:'mp') ->> 'taschenrechner'), 'true', 'multi_part trägt das Feld');

select pg_temp.act_as(:'admin_uid');
select is(public.task_preview_payload(:'kurz'), public.lsa_question_payload(:'kurz'), 'Die Vorschau bleibt lsa_question_payload');

-- ── B) calculator_opened ändert keine Diagnose ──────────────────────────────
select is(public.lsa_abgabeart('NUMERIC', '{"text":"15","calculator_opened":true}'),
          public.lsa_abgabeart('NUMERIC', '{"text":"15"}'), 'Abgabeart short_input unverändert');
select is(public.lsa_abgabeart('NUMERIC', '{"text":"","calculator_opened":true}'), 'leer',
          'Ein leeres Feld bleibt leer, auch mit Flag');
select is(public.lsa_abgabeart('MC', '{"selected":["a"],"calculator_opened":false}'), 'antwort', 'Abgabeart mc unverändert');
select is(public.lsa_abgabeart('NUMERIC', '{"dont_know":true,"calculator_opened":true}'), 'weiss_nicht',
          '„Ich weiß es nicht“ bleibt weiss_nicht');
select is(public.lsa_fehlbild_match('numeric', '{"15":"halbiert"}', '{"text":"15","calculator_opened":true}'), 'halbiert',
          'Fehlbild wird trotz Flag erkannt');
select is(public.lsa_fehlbild_match('mc', '{"a":"halbiert"}', '{"selected":["a"],"calculator_opened":true}'), 'halbiert',
          'Fehlbild mc wird trotz Flag erkannt');
select is(public.lsa_antwort_korrekt('NUMERIC', 'number', '["5,48"]', '{"text":"5,48","calculator_opened":true}'), true,
          'Richtige Antwort bleibt richtig');
select is(public.lsa_antwort_korrekt('NUMERIC', 'number', '["5,48"]', '{"text":"15","calculator_opened":true}'), false,
          'Falsche Antwort bleibt falsch');
select is(public.lsa_grade('NUMERIC', '{"canonical":"5,48"}', '["5,48"]', '{"text":"5,48","calculator_opened":true}'),
          public.lsa_grade('NUMERIC', '{"canonical":"5,48"}', '["5,48"]', '{"text":"5,48"}'), 'lsa_grade unverändert');

select id as sid from students where profile_id = :'student_uid' \gset
insert into lsa_sessions (student_id, subject, grade, status, modus, item_ids, started_at)
values (:'sid', 'mathematik', 9, 'in_progress', 'fest', array[:'kurz', :'mc', :'mp']::uuid[], now())
returning id as sess \gset

select pg_temp.act_as(:'student_uid');
select public.lsa_submit(:'sess', :'kurz', '{"text":"15","calculator_opened":true}', 1000) is not null as abgegeben \gset
select public.lsa_submit(:'sess', :'mc', '{"dont_know":true,"calculator_opened":false}', 1000) is not null as abgegeben \gset
select public.lsa_submit(:'sess', :'mp',
  '{"1":{"text":"16","calculator_opened":true},"2":{"selected":["b"],"calculator_opened":true}}', 1000) is not null as abgegeben \gset
select pg_temp.act_as(:'admin_uid');

select is((select response ->> 'calculator_opened' from lsa_responses where session_id = :'sess' and task_id = :'kurz'), 'true',
          'Einfache Aufgabe: Flag steht in response');
select is((select (correct, fehlbild_slug) from lsa_responses where session_id = :'sess' and task_id = :'kurz')::text,
          '(f,halbiert)', 'Einfache Aufgabe: Wertung und Fehlbild wie ohne Flag');
select is((select abgabeart from lsa_responses where session_id = :'sess' and task_id = :'mc'), 'weiss_nicht',
          '„Ich weiß es nicht“ mit Flag bleibt weiss_nicht');
select is((select count(*)::int from lsa_responses where session_id = :'sess' and task_id = :'mp'
            and response ->> 'calculator_opened' = 'true' and correct), 2,
          'Mehrteiler: Flag an jedem Teil, beide Teile richtig gewertet');

-- ── C) Pflege in der Prüfansicht ────────────────────────────────────────────
select pruef_version as v_entw from tasks where id = :'entw' \gset
select pruef_version as v_frei from tasks where id = :'frei' \gset

select pg_temp.act_as(:'coach_uid');
select throws_ok(format($$select public.pruef_taschenrechner_setzen(%L, %s, true)$$, :'entw', :v_entw), '42501', null,
                 'Coach ohne Prüfrecht darf nicht');
select pg_temp.act_as(:'student_uid');
select throws_ok(format($$select public.pruef_taschenrechner_setzen(%L, %s, true)$$, :'entw', :v_entw), '42501', null,
                 'Kind darf nicht');

select pg_temp.act_as(:'admin_uid');
select is((public.pruef_taschenrechner_setzen(:'frei', :v_frei, true) ->> 'hilfsmittel'), 'Taschenrechner, Stift und Zettel',
          'Admin darf bei einer freigegebenen Aufgabe; der Kopf nennt den Rechner');
select is((select status from tasks where id = :'frei'), 'ready', 'Die Aufgabe bleibt freigegeben');
select throws_ok(format($$select public.pruef_taschenrechner_setzen(%L, %s, false)$$, :'frei', :v_frei), 'ED409', null,
                 'Admin: veraltete Version wird abgewiesen');

select pruef_version as v_frei from tasks where id = :'frei' \gset
select pg_temp.act_as(:'lena_uid');
select throws_ok(format($$select public.pruef_taschenrechner_setzen(%L, %s, false)$$, :'frei', :v_frei), 'ED422', null,
                 'Lena darf eine freigegebene Aufgabe nicht ändern');
select throws_ok(format($$select public.pruef_taschenrechner_setzen(%L, %s, true)$$, :'entw', :v_entw - 1), 'ED409', null,
                 'Veraltete Version wird abgewiesen');
select is((public.pruef_taschenrechner_setzen(:'entw', :v_entw, true) ->> 'taschenrechner'), 'true',
          'Lena darf bei einem Entwurf');
select is((public.pruef_aufgabe(:'entw') -> 'kopf' ->> 'hilfsmittel'), 'Taschenrechner, Stift und Zettel',
          'pruef_aufgabe nennt den Rechner im Kopf');

select * from finish();
rollback;
