-- ============================================================================
-- INV-6 (T1b): Ein Schueler-Kontext kommt ueber KEINEN Weg an eine Loesung.
--
-- WARUM ES DIESEN TEST BRAUCHT, OBWOHL INV-2 EXISTIERT: INV-2 prueft die
--   Server-Only-Zone (`task_solutions` ohne Grant) und den Builder
--   (`lsa_question_payload` filtert). Beides war schon gruen, WAEHREND der Leak
--   offen stand — denn er lief an beiden vorbei: die Loesung lag als Duplikat in
--   `tasks.solution` und in `tasks.question_payload`, und auf `tasks` darf JEDER
--   eingeloggte Nutzer lesen (Policy `authenticated_read_tasks`, qual:
--   auth.role() = 'authenticated' — keine Rollen-, Klassen- oder Zuweisungs-
--   Einschraenkung). Ein `select=*` ueber PostgREST holte die Loesung ab.
--   INV-2 konnte das nicht sehen, weil es die Tabelle `tasks` nie als
--   Angriffsflaeche befragt hat.
--
-- DIE METHODE — Sentinel statt Feldliste: Der Test pflanzt einen eindeutigen
--   String in die Loesung (`task_solutions.solution` / `.correct_answers`) und
--   fragt dann jede Tuer ab, die ein Schueler (und ein anonymer Besucher!)
--   ueberhaupt aufbekommt: die Tabelle `tasks` KOMPLETT (alle Spalten, als Text),
--   den Payload-Builder, und die gesamte LSA-Schleife (start/submit/hint/finish).
--   Taucht der Sentinel irgendwo auf, ist der Leak offen.
--
--   Der Trick ist `to_jsonb(t)::text`: der Test nennt keine Spaltennamen. Wer
--   morgen `tasks.loesung_v2` anlegt und befuellt, faellt hier auf — eine
--   Assertion gegen eine gepflegte Feldliste wuerde das durchwinken.
--
-- ABGRENZUNG: `typical_errors` bleibt bewusst in `tasks` (typische FEHLER sind
--   nicht die Loesung) und traegt deshalb keinen Sentinel.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

-- --- Fixtures --------------------------------------------------------------
\set student_uid '55555555-5555-5555-5555-555555555555'
\set sentinel    'SENTINEL-LOESUNG-9F3A'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'inv6-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'inv6-student@test.local', 'student', 'INV6 Schuelerin');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Eine freigegebene Aufgabe. Der question_payload ist SAUBER — nach T1b ist ein
-- Payload mit Loesungsfeld nicht mehr einfuegbar (siehe Assertion 3).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","kind":"short_input","prompt":"Wie lang ist die Strecke?"}'::jsonb,
       'II', 'Groessen und Messen', 300, 8, 'test', 'inv6-item', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'student_uid') as sid,
       (select id from tasks where source_ref = 'inv6-item')       as tid
\gset

-- Die Loesung lebt AUSSCHLIESSLICH hier — markiert mit dem Sentinel.
insert into task_solutions (task_id, correct_answers, solution, hints, typical_errors) values
  (:'tid',
   format('["%s"]', :'sentinel')::jsonb,
   :'sentinel',
   '[{"level":1,"text":"Denk an die Einheit."}]'::jsonb,
   '[]'::jsonb);

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) Die Struktur: `tasks` kann eine Loesung gar nicht mehr tragen
-- ============================================================================

select hasnt_column(
  'public', 'tasks', 'solution',
  'tasks.solution existiert nicht mehr (T1b-Drop)'
);

select is_empty(
  $$
    select id::text from tasks
     where question_payload ?| array['correct','accepted','pairs','blanks','expected']
  $$,
  'keine einzige Aufgabe traegt ein Loesungsfeld im question_payload'
);

-- Der CHECK ist der eigentliche Verschluss: der Zustand ist unrepraesentierbar.
-- Ohne ihn waere der Drop nur Hygiene und ein einziges Insert machte den Leak
-- lautlos wieder auf — bis hinunter zu `anon`.
select throws_ok(
  $$
    insert into tasks (cluster_id, content_type, input_type, status, question,
                       question_payload, afb, competency_content, est_duration_sec,
                       class_level, source, source_ref)
    select c.id, 'exercise', 'MC', 'ready', 'Neu',
           '{"input_type":"MC","correct":["b"]}'::jsonb,
           'I', 'Terme und Gleichungen', 60, 8, 'test', 'inv6-verboten'
      from skill_clusters c order by c.sort_order limit 1
  $$,
  '23514',
  null,
  'ein question_payload MIT Loesungsfeld ist nicht mehr einfuegbar (CHECK)'
);

-- ============================================================================
-- B) Der Schueler-Kontext: keine Tuer gibt den Sentinel her
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: der Testnutzer ist ein student');

-- ANTI-VAKUUM: Der Sentinel-Test unten ist nur dann ein Test, wenn der Schueler
-- die Aufgabe ueberhaupt SIEHT. Wuerde RLS die Zeile herausfiltern, waere
-- `bool_or(...) = false` trivial wahr — und INV-6 gruen, obwohl es nichts
-- geprueft hat. Diese Assertion pinnt die Sichtbarkeit fest: sie muss brechen,
-- bevor der Kern-Test lautlos verstummt.
select is(
  (select count(*) from tasks where id = :'tid'),
  1::bigint,
  'Anti-Vakuum: der Schueler sieht die Aufgabe (sonst prueft der Sentinel-Test nichts)'
);

-- DER Kern-Test. `to_jsonb(t)` serialisiert JEDE Spalte, die der Schueler lesen
-- darf — question_payload, question, und alles, was jemand spaeter hinzufuegt.
select is(
  (select coalesce(bool_or(to_jsonb(t)::text like '%' || :'sentinel' || '%'), false) from tasks t),
  false,
  'select * from tasks: der Schueler sieht die Loesung in KEINER Spalte'
);

select is(
  (select public.lsa_question_payload(:'tid') ?| array['correct','accepted','pairs','blanks','expected','solution','hints']),
  false,
  'lsa_question_payload traegt kein Loesungsfeld'
);

select is(
  (select public.lsa_question_payload(:'tid')::text like '%' || :'sentinel' || '%'),
  false,
  'lsa_question_payload gibt die Loesung auch inhaltlich nicht her'
);

-- Die Server-Only-Zone direkt: schon das Tabellen-Tor ist zu (kein Grant).
select throws_ok(
  'select solution from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'der Schueler kann task_solutions.solution NICHT selektieren'
);

select throws_ok(
  'select correct_answers from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'der Schueler kann task_solutions.correct_answers NICHT selektieren'
);

-- ============================================================================
-- C) Der RPC-Weg: die ganze LSA-Schleife, und nirgends faellt die Loesung raus
-- ============================================================================

select lives_ok(
  format($f$select public.lsa_start(%L, 8, 'Mathematik')$f$, :'sid'),
  'lsa_start: der Schueler darf seine eigene LSA starten'
);

-- Ab hier ohne RLS-Rolle (postgres): der Schueler hat auf lsa_sessions bewusst
-- kein SELECT, die Assertions waeren sonst vakuum-gruen. Die RPC-Autorisierung
-- haengt an den JWT-Claims, nicht an der pg-Rolle — act_as() wirkt weiter.
reset role;
select pg_temp.act_as(:'student_uid');

select (select id from lsa_sessions where student_id = :'sid' limit 1) as lsa_sid
\gset

select is(
  (select public.lsa_submit(:'lsa_sid', :'tid', format('{"text":"%s"}', :'sentinel')::jsonb, 4200)::text
          like '%' || :'sentinel' || '%'),
  false,
  'lsa_submit spiegelt die Loesung nicht zurueck — auch nicht bei RICHTIGER Antwort'
);

-- lsa_hint gibt Hinweise heraus — das ist Absicht (gestufte Hilfe). Der Test
-- haelt fest: es kommt der Hinweis, nicht die Loesung.
select is(
  (select public.lsa_hint(:'lsa_sid', :'tid', 1) ->> 'text'),
  'Denk an die Einheit.',
  'lsa_hint liefert den Hinweis (Level 1)'
);

select is(
  (select public.lsa_hint(:'lsa_sid', :'tid', 1)::text like '%' || :'sentinel' || '%'),
  false,
  'lsa_hint gibt dabei die Loesung NICHT mit heraus'
);

select is(
  (select public.lsa_finish(:'lsa_sid')::text like '%' || :'sentinel' || '%'),
  false,
  'lsa_finish gibt die Loesung nicht heraus'
);

-- ============================================================================
-- D) Der anonyme Besucher: zwei Schichten, und die aeussere ist duenner als sie
--    aussieht.
--
--    `tasks` traegt ein SELECT-GRANT fuer `anon` — das Tabellen-Tor steht also
--    offen. Was `anon` heute rettet, ist ALLEIN die RLS-Policy
--    `authenticated_read_tasks` (qual: auth.role() = 'authenticated'). Faellt die
--    weg oder wird sie gelockert, liest `anon` `tasks` sofort mit dem Key, der in
--    jedem Frontend-Bundle steht.
--
--    Wir behaupten hier deshalb NICHT „anon sieht die Loesung nicht" — das waere
--    vakuum-gruen (anon sieht 0 Zeilen, der Sentinel-Vergleich liefe ins Leere
--    und pruefte nichts). Wir pinnen stattdessen genau die Schicht fest, die
--    traegt: anon sieht ueberhaupt keine Aufgabe.
-- ============================================================================
set local role anon;
select set_config('request.jwt.claims', null, true);

select is(
  (select count(*) from tasks),
  0::bigint,
  'anon sieht ueberhaupt keine Aufgabe (RLS haelt, obwohl das SELECT-Grant offen ist)'
);

select throws_ok(
  'select solution from task_solutions',
  '42501',
  'permission denied for table task_solutions',
  'anon kann task_solutions nicht anfassen'
);

select * from finish();
rollback;
