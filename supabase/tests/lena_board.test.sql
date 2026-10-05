-- ============================================================================
-- Lena-Board: "Aufgaben pruefen" (Migrationen 20261005071058 … 20261005071650).
-- Rechte, Statusfluss, Versionspruefung, Schreibweg ueber pruef_*, Wertung wie die Engine.
-- Eigene Fixtures (Quelle 'lena_test'), alles in einer Transaktion, am Ende rollback.
--
-- Lauf: npx supabase test db  (lokal: bash tools/lena-board-wegwerf-db.sh <db> --tests)
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(78);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   '1b000000-0000-4000-8000-00000000000a'
\set lena_uid    '1b000000-0000-4000-8000-00000000000b'
\set coach_uid   '1b000000-0000-4000-8000-00000000000c'
\set student_uid '1b000000-0000-4000-8000-00000000000d'
\set parent_uid  '1b000000-0000-4000-8000-00000000000e'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'lb-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',    'lb-lena@test.local',    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'lb-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'lb-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'parent_uid',  'lb-parent@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid',   'lb-admin@test.local',   'admin',   'LB Admin',   false),
  (:'lena_uid',    'lb-lena@test.local',    'coach',   'LB Lena',    true),
  (:'coach_uid',   'lb-coach@test.local',   'coach',   'LB Coach',   false),
  (:'student_uid', 'lb-student@test.local', 'student', 'LB Schueler', false),
  (:'parent_uid',  'lb-parent@test.local',  'parent',  'LB Eltern',  false);
insert into parent_student (parent_id, student_id) values (:'parent_uid', :'student_uid');
-- Datenmigration 4 schaltet den Pilot ein; die Tests brauchen das ganze Board.
update pruef_einstellungen set nur_pilot = false;

-- Eine Kreis-Aufgabe als Vorlage: NUMERIC, flach mit Regel, Fehlbild pi_vergessen.
create function pg_temp.aufgabe(p_ref text, p_ca jsonb, p_acc jsonb, p_loesung text,
                                p_status text default 'draft', p_quelle text default 'lena_test',
                                p_bild boolean default false)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, source, source_ref, status, needs_image)
  values ('exercise', 'NUMERIC', 'AFB II · ' || p_ref, 'Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang?',
          'II', (select id from skill_clusters order by id limit 1), 9, 'geo_kreis_umfang',
          p_quelle, p_ref, p_status, p_bild)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution)
  values (v, p_ca, p_acc, p_loesung);
  return v;
end $$;

select pg_temp.aufgabe('lb-kreis', '["22,62", "22.62", "22,62 m", "22,62m"]',
  '{"canonical": "22,62", "equivalents": ["22.62", "22,62 m", "22,62m"], "known_errors": {"7,2": "pi_vergessen", "7.2": "pi_vergessen"}}',
  'U = 2 · π · 3,6 m ≈ 22,62 m') as kreis \gset
select pg_temp.aufgabe('lb-passt', '["22,62", "22.62"]',
  '{"canonical": "22,62", "equivalents": ["22.62"], "known_errors": {"7,2": "pi_vergessen"}}',
  'U ≈ 22,62') as passt \gset
select pg_temp.aufgabe('lb-minus', '["−24", "-24"]',
  '{"canonical": "−24", "equivalents": ["-24"], "known_errors": {"−24": "vorzeichen_ignoriert"}}',
  '(−3) · 4 · (−2) = 24') as minus \gset
select pg_temp.aufgabe('lb-unsicher', '["5"]', '{"canonical": "5"}', '= 5') as unsicher \gset
select pg_temp.aufgabe('lb-editor', '["1"]', '{"canonical": "1", "equivalents": ["+1"], "known_errors": {"7": "pi_vergessen"}}', '= 1') as editor \gset
select pg_temp.aufgabe('lb-bild', '["5"]', '{"canonical": "5"}', '= 5', p_bild => true) as bild \gset
select pg_temp.aufgabe('lb-vera', '["5"]', '{"canonical": "5"}', '= 5', p_quelle => 'VERA8_IQB') as vera \gset
select pg_temp.aufgabe('lb-ready', '["5"]', '{"canonical": "5"}', '= 5', p_status => 'ready') as fertig \gset
-- Multiple Choice und Teilaufgaben
insert into tasks (content_type, input_type, title, question, question_payload, afb, cluster_id, curriculum_grade,
                   skill_key, source, source_ref)
values ('exercise', 'MC', 'Term · Rechteck', 'Welcher Term beschreibt die Fläche?',
        '{"options": [{"id": "a", "label": "x + 5"}, {"id": "b", "label": "5x"}, {"id": "c", "label": "2x + 10"}, {"id": "d", "label": "x²"}]}',
        'I', (select id from skill_clusters order by id limit 1), 8, 'geo_kreis_umfang', 'lena_test', 'lb-mc')
returning id as mc \gset
insert into task_solutions (task_id, correct_answers, acceptance, solution)
values (:'mc', '["b"]', '{"canonical": "b", "known_errors": {"a": "plus_statt_mal"}}', 'A = 5x');
insert into tasks (content_type, input_type, title, question, parts, est_duration_sec, afb, cluster_id,
                   curriculum_grade, skill_key, source, source_ref)
values ('exercise', 'MULTI_PART', 'LGS · Einsetzen', 'Löse: I: y = x + 1, II: 3x + 2y = 17',
        '[{"nr": 1, "kind": "short_input", "prompt": "x ="}, {"nr": 2, "kind": "short_input", "prompt": "y ="}]',
        45, 'I', (select id from skill_clusters order by id limit 1), 8, 'geo_kreis_umfang', 'lena_test', 'lb-teile')
returning id as teile \gset
insert into task_solutions (task_id, correct_answers, acceptance, solution)
values (:'teile', '{"1": ["3", "+3"], "2": ["4"]}',
        '{"1": {"canonical": "3", "equivalents": ["+3"], "known_errors": {"3,2": "klammer_vergessen"}}, "2": {"canonical": "4"}}',
        'x = 3, y = 4');
-- Eine freigegebene Aufgabe mit Protokoll: Schueler und Eltern duerfen davon nichts lesen.
insert into task_pruefung_ausgang (task_id, ausgang) values (:'fertig', '{"skill_key": "geo_kreis_umfang"}');
insert into task_pruefungen (task_id, entscheidung, geprueft_von) values (:'fertig', 'passt', :'lena_uid');

-- Eine Fertigkeit ausserhalb von Thema und Voraussetzungen der Kreis-Aufgaben.
select skill_key as fremd from skill_thema where thema_key <> 'kreis'
   and skill_key not in (select voraussetzt_skill_key from skill_kante where skill_key = 'geo_kreis_umfang')
 order by skill_key limit 1 \gset

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.v(p_id uuid) returns bigint language sql as $$
  select pruef_version from tasks where id = p_id
$$;
-- Direktes UPDATE unter der Rolle des Aufrufers; liefert die Zahl getroffener Zeilen.
create function pg_temp.direkt_aendern(p_id uuid) returns int language plpgsql as $$
declare n int;
begin
  update tasks set afb = 'III' where id = p_id;
  get diagnostics n = row_count;
  return n;
end $$;
-- SQLSTATE und HINT eines Aufrufs, z. B. 'ED422:notiz_fehlt'.
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text; h text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate, h = pg_exception_hint;
  return s || ':' || coalesce(h, '');
end $$;

-- ============================================================================
-- 1 · Coach ohne Pruefrecht
-- ============================================================================
select pg_temp.act_as(:'coach_uid');
select throws_ok('select * from public.pruef_board()', '42501', null, '1: Coach ohne Pruefrecht → pruef_board 42501');
select throws_ok(format('select public.pruef_aufgabe(%L)', :'kreis'), '42501', null,
  '1: Coach ohne Pruefrecht → pruef_aufgabe 42501');

-- ============================================================================
-- 2 · Lena: "Passt" bei einer unveraenderten Aufgabe
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select ok((select count(*) from public.pruef_board() b where b.task_id = :'passt' and b.lena_status = 'offen'
             and b.thema_key = 'kreis') = 1, '2: die Aufgabe steht offen im Board, Thema Kreis');
select is(public.pruef_aufgabe(:'passt') -> 'aenderungen', '[]'::jsonb, '2: Pruefkarte ohne Aenderungen');
select is(public.pruef_entscheiden(:'passt', pg_temp.v(:'passt'), 'passt', null, null, null, 12) ->> 'lena_status',
  'passt', '2: Passt → lena_status passt');
select results_eq(format('select status, reviewed_by from tasks where id = %L', :'passt'),
  $$values ('review'::text, null::uuid)$$, '2: status review, reviewed_by leer');
select results_eq(format('select count(*)::int, min(aenderungen::text), min(dauer_sek) from task_pruefungen where task_id = %L', :'passt'),
  $$values (1, '[]', 12)$$, '2: eine task_pruefungen-Zeile, aenderungen leer, Dauer 12 s');

-- ============================================================================
-- 3 · Lena gibt nicht frei und schreibt nicht an pruef_* vorbei
-- ============================================================================
select throws_ok(format('select public.task_status_set(%L, %L)', :'kreis', 'ready'), '42501', null,
  '3: task_status_set(ready) durch Lena → 42501');
select throws_ok(format('select public.task_solution_upsert(%L, %L::jsonb)', :'kreis', '["1"]'), '42501', null,
  '3: task_solution_upsert durch Lena → 42501');
set local role authenticated;
select is(pg_temp.direkt_aendern(:'kreis'), 0, '3: direktes UPDATE auf tasks durch Lena trifft 0 Zeilen');
reset role;

-- ============================================================================
-- 4 · Falsche Version
-- ============================================================================
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, 999, %L)', :'kreis', '{}')),
  'ED409:version', '4: falsche Version → ED409');

-- ============================================================================
-- 15 · Fehlbild wie die Engine (vor jeder Aenderung an der Kreis-Aufgabe)
-- ============================================================================
select is(public.pruef_wertung_testen(:'kreis', null, '22.620', null),
  '{"stufe": "voll", "fehlbild_slug": null, "fehlbild_klartext": null}'::jsonb,
  '15: 22.620 → voll nach lsa_grade, nicht in correct_answers, aber kein Fehlbild');
select is(public.pruef_wertung_testen(:'kreis', null, '7.2', null) ->> 'fehlbild_slug', 'pi_vergessen',
  '15: 7.2 → pi_vergessen');

-- ============================================================================
-- 6 · Antwort ausprobieren wertet wie die Engine
-- ============================================================================
select is(public.pruef_wertung_testen(:'kreis', null, '22.620', null) ->> 'stufe', 'voll', '6: 22.620 → voll');
select is(public.pruef_wertung_testen(:'kreis', null, '7,2', null) ->> 'stufe', 'nicht', '6: 7,2 → nicht');
select is(public.pruef_wertung_testen(:'kreis', null, '7,2', null) ->> 'fehlbild_slug', 'pi_vergessen',
  '6: 7,2 → pi_vergessen');
select is(public.pruef_wertung_testen(:'kreis', null, '68',
  '{"regel": {"art": "bereich", "mitte": "70", "toleranz": 5}, "werte": [{"teil": null, "werte": ["70"]}]}') ->> 'stufe',
  'voll', '6: Bereich 70 ± 5, 68 → voll');
select is(public.pruef_wertung_testen(:'kreis', null, '76',
  '{"regel": {"art": "bereich", "mitte": "70", "toleranz": 5}, "werte": [{"teil": null, "werte": ["70"]}]}') ->> 'stufe',
  'nicht', '6: Bereich 70 ± 5, 76 → nicht');
select is(public.pruef_speichern(:'kreis', pg_temp.v(:'kreis'),
  '{"regel": {"art": "wert", "einheit_pflicht": true}}') -> 'aenderungen' -> 0 ->> 'feld',
  'einheit_pflicht', '6: Einheit Pflicht ueber pruef_speichern gesetzt');
select is(public.pruef_wertung_testen(:'kreis', null, '22,62 m', null) ->> 'stufe', 'voll', '6: Pflicht m, 22,62 m → voll');
select is(public.pruef_wertung_testen(:'kreis', null, '22,62m', null) ->> 'stufe', 'voll', '6: Pflicht m, 22,62m → voll');
select is(public.pruef_wertung_testen(:'kreis', null, '22,62', null) ->> 'stufe', 'teilweise',
  '6: Pflicht m, 22,62 → teilweise');
select ok((select acceptance @> '{"unit_graded": true, "unit": "m", "canonical": "22,62 m"}' from task_solutions
            where task_id = :'kreis'), '6: acceptance traegt unit_graded, unit und canonical mit Einheit');

-- ============================================================================
-- 13 · pruef_speichern schreibt nur Lenas Felder
-- ============================================================================
select (question, input_type, question_payload, parts, assets, unit, status)::text as vorher
  from tasks where id = :'kreis' \gset
select lives_ok(format('select public.pruef_speichern(%L, %s, %L)', :'kreis', pg_temp.v(:'kreis'),
  '{"question": "Anders", "input_type": "MC", "question_payload": {"options": []}, "parts": [], "assets": [{"x": 1}], "unit": "km", "status": "ready", "afb": "III"}'),
  '13: Entwurf mit fremden Feldern wird angenommen');
select is((select (question, input_type, question_payload, parts, assets, unit, status)::text from tasks where id = :'kreis'),
  :'vorher', '13: Text, Typ, Optionen, Teile, Bilder, Einheit und Status bleiben unveraendert');
select is((select afb from tasks where id = :'kreis'), 'III', '13: nur afb aus dem Entwurf ist geschrieben');

-- ============================================================================
-- 10 · Fertigkeit ausserhalb der Auswahl
-- ============================================================================
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'kreis', pg_temp.v(:'kreis'),
  json_build_object('skill_key', :'fremd'))), 'ED422:fertigkeit_unzulaessig', '10: fremde Fertigkeit → ED422');
select lives_ok(format('select public.pruef_speichern(%L, %s, %L)', :'kreis', pg_temp.v(:'kreis'),
  '{"skill_key": "term_einsetzen"}'), '10: eine Voraussetzung ist erlaubt');
select results_eq(format('select skill_key, thema_key from public.pruef_board() where task_id = %L', :'kreis'),
  $$values ('term_einsetzen'::text, 'kreis'::text)$$, '10: im Board bleibt die Aufgabe im Thema Kreis');
select is((select sondierrang from tasks where id = :'kreis'), null::int, '10: neue Fertigkeit → sondierrang leer');

-- ============================================================================
-- 5 · Richtige Antwort −24 → 24
-- ============================================================================
select is((select jsonb_agg(a ->> 'code' order by a ->> 'code') from jsonb_array_elements(public.pruef_aufgabe(:'minus') -> 'auffaelligkeiten') a),
  '["fehler_als_richtig", "loesungsweg_endet_falsch"]'::jsonb, '5: −24 als Fehler und Loesungsweg "= 24" → zwei Hinweise');
select lives_ok(format('select public.pruef_speichern(%L, %s, %L)', :'minus', pg_temp.v(:'minus'),
  '{"werte": [{"teil": null, "werte": ["24"]}]}'), '5: pruef_speichern −24 → 24');
select results_eq(format('select correct_answers ->> 0, acceptance ->> %L from task_solutions where task_id = %L', 'canonical', :'minus'),
  $$values ('24'::text, '24'::text)$$, '5: correct_answers und acceptance.canonical stehen auf 24');
select is(public.pruef_aufgabe(:'minus') -> 'auffaelligkeiten', '[]'::jsonb,
  '5: mit 24 ist der Loesungsweg stimmig, keine Auffaelligkeit');
select lives_ok(format('select public.pruef_entscheiden(%L, %s, %L)', :'minus', pg_temp.v(:'minus'), 'passt'),
  '5: Passt');
select ok((select aenderungen @> '[{"feld": "richtige_antwort", "vorher": ["−24"], "nachher": ["24"]}]'
             from task_pruefungen where task_id = :'minus' order by geprueft_am desc limit 1),
  '5: aenderungen enthaelt richtige Antwort −24 → 24');
select pg_temp.act_as(:'admin_uid');
select is(public.freigabe_thema('kreis', 13), 1, '5: freigabe_thema gibt nur die unveraenderte Aufgabe frei');
select results_eq(format('select status from tasks where id in (%L, %L) order by source_ref', :'minus', :'passt'),
  $$values ('review'::text), ('ready'::text)$$, '5: −24 → 24 bleibt review, die unveraenderte ist ready');

-- ============================================================================
-- 12 · Rueckgaengig: offen, die Aenderung bleibt
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select is(public.pruef_rueckgaengig(:'minus', pg_temp.v(:'minus')) ->> 'lena_status', 'offen', '12: Rueckgaengig → offen');
select results_eq(format('select t.status, s.correct_answers ->> 0 from tasks t join task_solutions s on s.task_id = t.id where t.id = %L', :'minus'),
  $$values ('draft'::text, '24'::text)$$, '12: status draft, Lenas 24 bleibt');
select is((select entscheidung from task_pruefungen where task_id = :'minus' order by geprueft_am desc limit 1),
  'zurueckgenommen', '12: Protokoll zurueckgenommen');

-- ============================================================================
-- 7 · Pflichtangaben
-- ============================================================================
select is(pg_temp.fehler(format('select public.pruef_entscheiden(%L, %s, %L)', :'unsicher', pg_temp.v(:'unsicher'), 'unsicher')),
  'ED422:notiz_fehlt', '7: Unsicher ohne Notiz → notiz_fehlt');
select is(pg_temp.fehler(format('select public.pruef_entscheiden(%L, %s, %L)', :'unsicher', pg_temp.v(:'unsicher'), 'passt_nicht')),
  'ED422:grund_fehlt', '7: Passt nicht ohne Grund → grund_fehlt');
select is(pg_temp.fehler(format('select public.pruef_entscheiden(%L, %s, %L, %L)', :'unsicher', pg_temp.v(:'unsicher'),
  'passt_nicht', '{sonstiges}')), 'ED422:notiz_fehlt', '7: Sonstiges ohne Notiz → notiz_fehlt');

-- ============================================================================
-- 8 · Unsicher → Rueckfrage → Admin: zurueck an Lena
-- ============================================================================
select is(public.pruef_entscheiden(:'unsicher', pg_temp.v(:'unsicher'), 'unsicher', null, 'Passt die Fertigkeit?') ->> 'lena_status',
  'unsicher', '8: Unsicher → rueckfrage');
select is(pg_temp.fehler(format('select public.pruef_rueckfrage_klaeren(%L, %L, %L)', :'unsicher', 'an_lena', 'x')),
  '42501:', '8: Lena klaert keine Rueckfrage');
select pg_temp.act_as(:'admin_uid');
select is(public.pruef_rueckfrage_klaeren(:'unsicher', 'an_lena', 'Ja, die passt.') ->> 'status', 'draft', '8: an_lena → draft');
select is((select count(*)::int from task_pruefung_ausgang where task_id = :'unsicher'), 0, '8: Ausgangsfassung geloescht');
select results_eq(format('select antwort, beantwortet_von from task_pruefungen where task_id = %L order by geprueft_am desc limit 1', :'unsicher'),
  format('values (%L::text, %L::uuid)', 'Ja, die passt.', :'admin_uid'), '8: Antwort an Lena gespeichert');

-- ============================================================================
-- 9 · Ausschluesse
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select is((select count(*)::int from public.pruef_board() where task_id in (:'bild', :'vera')), 0,
  '9: Bild fehlt und VERA8 stehen nicht im Board');
select is(public.pruef_ausschluss(:'bild'), 'bild_fehlt', '9: Grund bild_fehlt');
select is(public.pruef_ausschluss(:'vera'), 'vera8', '9: Grund vera8');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'vera', pg_temp.v(:'vera'), '{}')),
  'ED422:ausgeschlossen', '9: VERA8 ist fuer Lena nicht beschreibbar');

-- ============================================================================
-- 11 · Sicherheitsnetz im Editor
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select lives_ok(format('select public.task_solution_upsert(%L, p_correct_answers => %L::jsonb)', :'editor', '["5", "+5"]'),
  '11: Admin speichert nur correct_answers');
select is((select acceptance from task_solutions where task_id = :'editor'),
  '{"canonical": "5", "equivalents": ["+5"], "known_errors": {"7": "pi_vergessen"}}'::jsonb,
  '11: canonical und equivalents angeglichen, known_errors bleibt');

-- ============================================================================
-- Multiple Choice und Teilaufgaben
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select is((select jsonb_agg(a ->> 'wert' order by a ->> 'wert') from jsonb_array_elements(public.pruef_aufgabe(:'mc') -> 'auffaelligkeiten') a
            where a ->> 'code' = 'mc_ablenker_ohne_fehlbild'), '["c", "d"]'::jsonb, 'MC: Ablenker c und d ohne Fehlbild');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'mc', pg_temp.v(:'mc'), '{"mc": "x"}')),
  'ED422:mc_unbekannt', 'MC: unbekannte Option → ED422');
select lives_ok(format('select public.pruef_speichern(%L, %s, %L)', :'mc', pg_temp.v(:'mc'),
  '{"mc": "c", "fehler": [{"slug": "plus_statt_mal", "werte": [{"teil": null, "wert": "a"}], "text": "Addiert."}, {"slug": "umfang_statt_flaeche", "werte": [{"teil": null, "wert": "b"}], "text": null}]}'),
  'MC: richtige Option c, Fehlbilder fuer a und b');
select results_eq(format('select correct_answers, acceptance from task_solutions where task_id = %L', :'mc'),
  $$values ('["c"]'::jsonb, '{"canonical": "c", "known_errors": {"a": "plus_statt_mal", "b": "umfang_statt_flaeche"}}'::jsonb)$$,
  'MC: correct_answers und acceptance gemeinsam geschrieben');
select is((select typical_errors from task_solutions where task_id = :'mc'),
  '[{"error": "Addiert.", "fehlbild": "plus_statt_mal", "socratic_question": ""}]'::jsonb,
  'MC: der Satz zum Fehler steht mit fehlbild in typical_errors');
select is(public.pruef_wertung_testen(:'teile', 1, '3,2', null),
  '{"stufe": "nicht", "fehlbild_slug": "klammer_vergessen", "fehlbild_klartext": null}'::jsonb
    || jsonb_build_object('fehlbild_klartext', (select klartext from fehlbild_labels where slug = 'klammer_vergessen')),
  'Teil 1: 3,2 → nicht, klammer_vergessen');
select is(public.pruef_wertung_testen(:'teile', 1, '3,0', null) ->> 'stufe', 'nicht', 'Teil 1: 3,0 → nicht (Textliste)');
select is(public.pruef_wertung_testen(:'teile', 1, '+3', null) ->> 'stufe', 'voll', 'Teil 1: +3 → voll');
select lives_ok(format('select public.pruef_speichern(%L, %s, %L)', :'teile', pg_temp.v(:'teile'),
  '{"werte": [{"teil": 1, "werte": ["3", "+3"]}, {"teil": 2, "werte": ["4", "4,0"]}], "fehler": [{"slug": "klammer_vergessen", "werte": [{"teil": 1, "wert": "3,2"}, {"teil": 2, "wert": "4,2"}], "text": null}]}'),
  'Teile: Werte je Teil und Fehler je Teil gespeichert');
select results_eq(format('select correct_answers -> %L, acceptance -> %L from task_solutions where task_id = %L', '2', '2', :'teile'),
  $$values ('["4", "4,0"]'::jsonb, '{"canonical": "4", "equivalents": ["4,0"], "known_errors": {"+4,2": "klammer_vergessen", "+4.2": "klammer_vergessen", "4,2": "klammer_vergessen", "4.2": "klammer_vergessen"}}'::jsonb)$$,
  'Teil 2: genau Lenas Liste, acceptance angeglichen, Fehlerwerte erweitert');
select is(public.pruef_aufgabe(:'teile') -> 'aenderungen' -> 0 ->> 'feld', 'richtige_antwort',
  'Teile: Aenderung je Teil erkannt');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'teile', pg_temp.v(:'teile'),
  '{"fehler": [{"slug": "klammer_vergessen", "werte": [{"teil": 9, "wert": "1"}]}]}')),
  'ED422:teil_unbekannt', 'Teile: unbekannter Teil → ED422');

-- ============================================================================
-- 14 · Schueler, Eltern und anon lesen nichts aus Ausgangsfassung und Protokoll
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');
select is((select count(*)::int from task_pruefung_ausgang), 0, '14: Schueler liest keine Ausgangsfassung');
select is((select count(*)::int from task_pruefungen), 0, '14: Schueler liest kein Protokoll');
select pg_temp.act_as(:'parent_uid');
select is((select count(*)::int from task_pruefung_ausgang), 0, '14: Eltern lesen keine Ausgangsfassung');
select is((select count(*)::int from task_pruefungen), 0, '14: Eltern lesen kein Protokoll');
reset role;
set local role anon;
select throws_ok('select count(*) from task_pruefungen', '42501', null, '14: anon hat keinen Zugriff');
reset role;

-- Consensus-Check: Toleranz, Pilot, Admin-Beanstandung
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'kreis', pg_temp.v(:'kreis'),
  '{"regel": {"art": "bereich", "mitte": "22,62", "toleranz": "1e300"}}')),
  'ED422:bereich_ungueltig', 'Bereich breiter als der Wert → ED422');
update pruef_einstellungen set nur_pilot = true;
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'unsicher', pg_temp.v(:'unsicher'), '{}')),
  'ED422:ausgeschlossen', 'nur_pilot: Aufgabe ausserhalb des Piloten ist auch per Adresse gesperrt');
update pruef_einstellungen set nur_pilot = false;
select pg_temp.act_as(:'admin_uid');
select lives_ok(format('select public.lena_beanstande(%L, %L, %L)', :'editor', 'formulierung', 'Admin'), 'Admin beanstandet');
select pg_temp.act_as(:'lena_uid');
select is(public.pruef_entscheiden(:'editor', pg_temp.v(:'editor'), 'passt') ->> 'lena_status', 'passt',
  'Lena bewertet neu: Passt');
select pg_temp.act_as(:'admin_uid');
select is(public.freigabe_thema('kreis', 13), 0, 'Sammelfreigabe laesst die vom Admin beanstandete Aufgabe aus');

-- Freigegebene Aufgaben liest Lena, aendert sie aber nicht.
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'fertig', pg_temp.v(:'fertig'), '{}')),
  'ED422:freigegeben', 'Freigegebene Aufgabe: pruef_speichern → ED422 freigegeben');

select * from finish();
rollback;
