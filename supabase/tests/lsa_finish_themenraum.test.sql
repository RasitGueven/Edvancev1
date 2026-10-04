-- ============================================================================
-- W5-d: lsa_finish sichert den Themenraum der Sitzung in result_summary.
--
--   1. lsa_themenraum: einstieg = thema_einstieg, darunter = Abschluss der
--      Einstiege OHNE die Einstiege selbst; Fremdknoten bleiben draussen.
--   2. lsa_finish mit thema_key schreibt result_summary.themenraum, stand =
--      completed_at. Ohne thema_key kein Feld.
--   3. Bestehende Felder unveraendert: dieselben Antworten mit und ohne Thema
--      ergeben bis auf 'themenraum' dasselbe result_summary.
--   4. Kanten aendern sich danach -> der gespeicherte Raum bleibt, ein zweiter
--      lsa_finish-Aufruf liefert ihn unveraendert.
--   5. Nachtrag (20261004001517): nur fehlende Felder, stand = 'nachgetragen'.
--   6. lsa_themenraum ist nicht fuer anon/authenticated ausfuehrbar.
--
-- Eigene Knoten mit Praefix W5D_, damit der Test vom Inhaltsbestand unabhaengig
-- ist. Alles in begin/rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

\set admin_uid 'aaaaaaaa-5d5d-5d5d-5d5d-aaaaaaaaaaaa'
\set st_a      'bbbbbbbb-5d5d-5d5d-5d5d-00000000000a'
\set st_b      'bbbbbbbb-5d5d-5d5d-5d5d-00000000000b'
\set st_c      'bbbbbbbb-5d5d-5d5d-5d5d-00000000000c'
\set st_d      'bbbbbbbb-5d5d-5d5d-5d5d-00000000000d'
\set se_a      'cccccccc-5d5d-5d5d-5d5d-00000000000a'
\set se_b      'cccccccc-5d5d-5d5d-5d5d-00000000000b'
\set se_c      'cccccccc-5d5d-5d5d-5d5d-00000000000c'
\set se_d      'cccccccc-5d5d-5d5d-5d5d-00000000000d'
\set task_1    'dddddddd-5d5d-5d5d-5d5d-000000000001'

insert into auth.users (id, email) values (:'admin_uid', 'w5d-admin@test.local');
insert into profiles (id, email, role, full_name)
  values (:'admin_uid', 'w5d-admin@test.local', 'admin', 'W5D Admin');

-- Graph: E1 -> {E2, G1}, E2 -> G2, G1 -> G3. F1 -> G3 (fremd, kein Einstieg).
-- E2 ist Einstieg UND Voraussetzung von E1: es darf nicht unter darunter stehen.
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('W5D_E1', 'W5D E1', 'mathematik', 9, 5),
  ('W5D_E2', 'W5D E2', 'mathematik', 9, 4),
  ('W5D_G1', 'W5D G1', 'mathematik', 7, 3),
  ('W5D_G2', 'W5D G2', 'mathematik', 6, 2),
  ('W5D_G3', 'W5D G3', 'mathematik', 5, 1),
  ('W5D_F1', 'W5D F1', 'mathematik', 6, 2);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('W5D_E1', 'W5D_E2'), ('W5D_E1', 'W5D_G1'),
  ('W5D_E2', 'W5D_G2'), ('W5D_G1', 'W5D_G3'),
  ('W5D_F1', 'W5D_G3');
insert into themen (thema_key, fach, klasse, label, stufe)
  values ('w5d_thema', 'mathematik', 9, 'W5D Thema', 'zweite');
insert into thema_einstieg (thema_key, skill_key)
  values ('w5d_thema', 'W5D_E1'), ('w5d_thema', 'W5D_E2');

-- ── 1. lsa_themenraum ──────────────────────────────────────────────────────
select is(
  public.lsa_themenraum('w5d_thema'),
  '{"thema_key": "w5d_thema",
    "einstieg": ["W5D_E1", "W5D_E2"],
    "darunter": ["W5D_G1", "W5D_G2", "W5D_G3"]}'::jsonb,
  'lsa_themenraum: Einstiege sortiert, darunter = Abschluss ohne Einstiege und ohne Fremdknoten'
);

-- ── Sitzungen: A mit Thema, B ohne, sonst identisch ────────────────────────
insert into students (id, is_provisional) values
  (:'st_a', false), (:'st_b', false), (:'st_c', false), (:'st_d', false);
insert into tasks (id, content_type, skill_key, question, input_type, status, competency_content, afb)
  values (:'task_1', 'exercise', 'W5D_E1', 'W5D Aufgabe', 'NUMERIC', 'draft', 'Arithmetik', 'II');
insert into lsa_sessions (id, student_id, subject, grade, item_ids, started_at, status, modus, thema_key) values
  (:'se_a', :'st_a', 'Mathematik', 9, array[:'task_1']::uuid[], now(), 'in_progress', 'adaptiv', 'w5d_thema'),
  (:'se_b', :'st_b', 'Mathematik', 9, array[:'task_1']::uuid[], now(), 'in_progress', 'adaptiv', null);
insert into lsa_responses (session_id, task_id, response, correct, duration_ms) values
  (:'se_a', :'task_1', '{"value": "3"}', true, 4000),
  (:'se_b', :'task_1', '{"value": "3"}', true, 4000);

select set_config('request.jwt.claims',
  json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

select lives_ok(format('select public.lsa_finish(%L)', :'se_a'), 'lsa_finish A (mit Thema)');
select lives_ok(format('select public.lsa_finish(%L)', :'se_b'), 'lsa_finish B (ohne Thema)');

-- ── 2. Feld wird geschrieben / fehlt ohne Thema ────────────────────────────
select is(
  (select (result_summary -> 'themenraum') - 'stand' from lsa_sessions where id = :'se_a'),
  public.lsa_themenraum('w5d_thema'),
  'A: result_summary.themenraum = lsa_themenraum zum Abschlusszeitpunkt'
);
select is(
  (select (result_summary -> 'themenraum' ->> 'stand')::timestamptz = completed_at
     from lsa_sessions where id = :'se_a'),
  true,
  'A: stand ist der Abschlusszeitpunkt'
);
select is(
  (select result_summary ? 'themenraum' from lsa_sessions where id = :'se_b'),
  false,
  'B: ohne thema_key kein Feld themenraum'
);

-- ── 3. Bestehende Felder unveraendert ──────────────────────────────────────
select is(
  (select result_summary - 'themenraum' from lsa_sessions where id = :'se_a'),
  (select result_summary from lsa_sessions where id = :'se_b'),
  'A ohne themenraum = B: alle bisherigen Felder unveraendert'
);
select is(
  (select array_agg(k order by k) from lsa_sessions s, jsonb_object_keys(s.result_summary) k
    where s.id = :'se_b'),
  array['afb', 'answered', 'answered_parts', 'competencies', 'planned', 'proposal', 'unbeantwortet'],
  'B: genau die bisherigen sieben Schluessel'
);
select is(
  (select (result_summary ->> 'answered')::int from lsa_sessions where id = :'se_a'),
  1,
  'A: answered wie bisher gezaehlt'
);

-- ── 4. Kanten aendern sich danach ──────────────────────────────────────────
create temp table w5d_vorher as
  select result_summary from lsa_sessions where id = :'se_a';

delete from skill_kante where skill_key = 'W5D_G1' and voraussetzt_skill_key = 'W5D_G3';
insert into skill_kante (skill_key, voraussetzt_skill_key) values ('W5D_E2', 'W5D_F1');
delete from thema_einstieg where thema_key = 'w5d_thema' and skill_key = 'W5D_E2';

select isnt(
  public.lsa_themenraum('w5d_thema') -> 'darunter',
  (select result_summary -> 'themenraum' -> 'darunter' from w5d_vorher),
  'Vorbedingung: der heutige Raum weicht jetzt vom gespeicherten ab'
);
select is(
  (select result_summary from lsa_sessions where id = :'se_a'),
  (select result_summary from w5d_vorher),
  'A: gespeicherter Themenraum bleibt nach Kantenaenderung unveraendert'
);
select is(
  public.lsa_finish(:'se_a'),
  (select result_summary from w5d_vorher),
  'A: zweiter lsa_finish-Aufruf liefert das gespeicherte result_summary'
);

-- ── 5. Nachtrag ────────────────────────────────────────────────────────────
-- C: abgeschlossen vor der Erweiterung, mit Thema. D: ohne Thema.
insert into lsa_sessions (id, student_id, subject, grade, status, completed_at, result_summary, thema_key) values
  (:'se_c', :'st_c', 'Mathematik', 9, 'completed', now(), '{"answered": 4, "planned": 6}', 'w5d_thema'),
  (:'se_d', :'st_d', 'Mathematik', 9, 'completed', now(), '{"answered": 2, "planned": 6}', null);

\ir ../migrations/20261004001517_lsa_themenraum_nachtrag.sql

select is(
  (select result_summary from lsa_sessions where id = :'se_c'),
  '{"answered": 4, "planned": 6}'::jsonb
    || jsonb_build_object('themenraum',
         public.lsa_themenraum('w5d_thema') || '{"stand": "nachgetragen"}'::jsonb),
  'C: Themenraum aus dem heutigen Stand nachgetragen, stand = nachgetragen, Rest unveraendert'
);
select is(
  (select result_summary from lsa_sessions where id = :'se_d'),
  '{"answered": 2, "planned": 6}'::jsonb,
  'D: ohne thema_key bleibt result_summary unberuehrt'
);
select is(
  (select result_summary from lsa_sessions where id = :'se_a'),
  (select result_summary from w5d_vorher),
  'A: vorhandener Themenraum wird vom Nachtrag nicht ueberschrieben'
);

-- ── 6. Rechte ──────────────────────────────────────────────────────────────
select ok(
  not has_function_privilege('authenticated', 'public.lsa_themenraum(text)', 'execute'),
  'lsa_themenraum ist fuer authenticated nicht ausfuehrbar'
);
select ok(
  not has_function_privilege('anon', 'public.lsa_themenraum(text)', 'execute'),
  'lsa_themenraum ist fuer anon nicht ausfuehrbar'
);

select * from finish();
rollback;
