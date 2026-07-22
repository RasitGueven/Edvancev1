-- ============================================================================
-- Gleichungen + Prozent, Charge 01 — 45 Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/gleichungen_prozent.py. Nicht von Hand pflegen.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_gleichungen_prozent_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
--
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- BINAER: kein require_reduced, kein 'teilweise'. Eine Gleichung ist geloest
-- oder nicht. Deshalb tragen alle Aufgaben known_errors — bei binaerer
-- Bewertung sind die Fehlbilder die einzige Feindiagnostik.
--
-- EINHEITEN: Das Kind tippt NUR DIE ZAHL ("12", nicht "12 €"). Die Einheit
-- steht im Eingabefeld und kommt aus der SPALTE tasks.unit —
-- lsa_question_payload baut daraus das unit-Feld des Schueler-Payloads.
-- acceptance.unit ist zusaetzlich gesetzt (es beschreibt die Loesung), aber
-- unit_graded bleibt aus: die Einheit ist hier nicht die Kompetenz.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder ausschliesslich in
-- task_solutions. In `tasks` steht nur die Frage (und die Einheit, die das Kind
-- ohnehin sieht).
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

-- ── 0. Voraussetzungen ─────────────────────────────────────────────────────

do $$
begin
  if not exists (
    select 1 from skill_clusters sc
      join subjects s on s.id = sc.subject_id
     where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen'
  ) then
    raise exception 'Cluster "Zahl & Rechnen" (Mathematik) fehlt — erst supabase/seed.sql einspielen.';
  end if;
  if not exists (select 1 from process_competencies where code = 'Ope') then
    raise exception 'Prozesskompetenz "Ope" fehlt — erst supabase/seed.sql einspielen.';
  end if;
  if to_regprocedure('public.lsa_grade(text,jsonb,jsonb,jsonb)') is null then
    raise exception 'lsa_grade fehlt — A11 ist nicht eingespielt.';
  end if;
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image, unit,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.titel, v.frage, v.afb, 7, false, v.unit,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_strip_nulls(jsonb_build_object(
    'kind', 'short_input', 'prompt', v.frage, 'unit', v.unit))
from (values
  ('gleichung-einschrittig-01', 'Gleichungen · Einschrittig · x + 7 = 12', 'Löse die Gleichung. Gib den Wert für x an.

x + 7 = 12', 'I', null),
  ('gleichung-einschrittig-02', 'Gleichungen · Einschrittig · x − 4 = 9', 'Löse die Gleichung. Gib den Wert für x an.

x − 4 = 9', 'I', null),
  ('gleichung-einschrittig-03', 'Gleichungen · Einschrittig · 3x = 18', 'Löse die Gleichung. Gib den Wert für x an.

3x = 18', 'I', null),
  ('gleichung-einschrittig-04', 'Gleichungen · Einschrittig · x + 12 = 20', 'Löse die Gleichung. Gib den Wert für x an.

x + 12 = 20', 'I', null),
  ('gleichung-einschrittig-05', 'Gleichungen · Einschrittig · x − 9 = 6', 'Löse die Gleichung. Gib den Wert für x an.

x − 9 = 6', 'I', null),
  ('gleichung-einschrittig-06', 'Gleichungen · Einschrittig · 4x = 24', 'Löse die Gleichung. Gib den Wert für x an.

4x = 24', 'I', null),
  ('gleichung-zweischrittig-01', 'Gleichungen · Zweischrittig · 3x + 6 = 24', 'Löse die Gleichung. Gib den Wert für x an.

3x + 6 = 24', 'I', null),
  ('gleichung-zweischrittig-02', 'Gleichungen · Zweischrittig · 2x + 4 = 20', 'Löse die Gleichung. Gib den Wert für x an.

2x + 4 = 20', 'I', null),
  ('gleichung-zweischrittig-03', 'Gleichungen · Zweischrittig · 5x + 10 = 45', 'Löse die Gleichung. Gib den Wert für x an.

5x + 10 = 45', 'I', null),
  ('gleichung-zweischrittig-04', 'Gleichungen · Zweischrittig · 4x + 8 = 40', 'Löse die Gleichung. Gib den Wert für x an.

4x + 8 = 40', 'I', null),
  ('gleichung-zweischrittig-05', 'Gleichungen · Zweischrittig · 3x + 9 = 30', 'Löse die Gleichung. Gib den Wert für x an.

3x + 9 = 30', 'I', null),
  ('gleichung-zweischrittig-06', 'Gleichungen · Zweischrittig · 6x + 12 = 42', 'Löse die Gleichung. Gib den Wert für x an.

6x + 12 = 42', 'I', null),
  ('gleichung-negativ-01', 'Gleichungen · Negativer Koeffizient · 18 − 3x = 12', 'Löse die Gleichung. Gib den Wert für x an.

18 − 3x = 12', 'I', null),
  ('gleichung-negativ-02', 'Gleichungen · Negativer Koeffizient · 20 − 4x = 8', 'Löse die Gleichung. Gib den Wert für x an.

20 − 4x = 8', 'I', null),
  ('gleichung-negativ-03', 'Gleichungen · Negativer Koeffizient · 15 − 5x = 5', 'Löse die Gleichung. Gib den Wert für x an.

15 − 5x = 5', 'I', null),
  ('gleichung-negativ-04', 'Gleichungen · Negativer Koeffizient · 24 − 2x = 10', 'Löse die Gleichung. Gib den Wert für x an.

24 − 2x = 10', 'I', null),
  ('gleichung-negativ-05', 'Gleichungen · Negativer Koeffizient · 30 − 6x = 12', 'Löse die Gleichung. Gib den Wert für x an.

30 − 6x = 12', 'I', null),
  ('gleichung-beidseitig-01', 'Gleichungen · Variable beidseitig · 5x + 3 = 2x + 18', 'Löse die Gleichung. Gib den Wert für x an.

5x + 3 = 2x + 18', 'II', null),
  ('gleichung-beidseitig-02', 'Gleichungen · Variable beidseitig · 4x + 2 = 2x + 14', 'Löse die Gleichung. Gib den Wert für x an.

4x + 2 = 2x + 14', 'II', null),
  ('gleichung-beidseitig-03', 'Gleichungen · Variable beidseitig · 5x + 5 = 3x + 25', 'Löse die Gleichung. Gib den Wert für x an.

5x + 5 = 3x + 25', 'II', null),
  ('gleichung-beidseitig-04', 'Gleichungen · Variable beidseitig · 7x + 2 = 3x + 30', 'Löse die Gleichung. Gib den Wert für x an.

7x + 2 = 3x + 30', 'II', null),
  ('gleichung-beidseitig-05', 'Gleichungen · Variable beidseitig · 6x + 4 = 2x + 28', 'Löse die Gleichung. Gib den Wert für x an.

6x + 4 = 2x + 28', 'II', null),
  ('prozent-wert-01', 'Prozent · Prozentwert · 15 % von 80', 'Ein Pullover kostet 80 €. Der Preis wird um 15 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-wert-02', 'Prozent · Prozentwert · 20 % von 200', 'Ein Fahrrad kostet 200 €. Der Preis wird um 20 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-wert-03', 'Prozent · Prozentwert · 25 % von 60', 'Ein Rucksack kostet 60 €. Der Preis wird um 25 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-wert-04', 'Prozent · Prozentwert · 20 % von 150', 'Ein Paar Schuhe kostet 150 €. Der Preis wird um 20 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-wert-05', 'Prozent · Prozentwert · 50 % von 40', 'Ein Buch kostet 40 €. Der Preis wird um 50 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-wert-06', 'Prozent · Prozentwert · 10 % von 90', 'Eine Jacke kostet 90 €. Der Preis wird um 10 % reduziert.

Wie viel Euro beträgt die Ermäßigung?', 'I', '€'),
  ('prozent-satz-01', 'Prozent · Prozentsatz · 12 von 80', 'Von 80 Schülerinnen und Schülern haben 12 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-satz-02', 'Prozent · Prozentsatz · 20 von 80', 'Von 80 Schülerinnen und Schülern haben 20 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-satz-03', 'Prozent · Prozentsatz · 15 von 60', 'Von 60 Schülerinnen und Schülern haben 15 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-satz-04', 'Prozent · Prozentsatz · 9 von 90', 'Von 90 Schülerinnen und Schülern haben 9 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-satz-05', 'Prozent · Prozentsatz · 30 von 60', 'Von 60 Schülerinnen und Schülern haben 30 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-satz-06', 'Prozent · Prozentsatz · 16 von 80', 'Von 80 Schülerinnen und Schülern haben 16 eine Eins.

Wie viel Prozent sind das?', 'I', '%'),
  ('prozent-grundwert-01', 'Prozent · Grundwert · 12 sind 15 %', '12 Bücher sind 15 % aller Bücher.

Wie viele Bücher sind es insgesamt?', 'II', null),
  ('prozent-grundwert-02', 'Prozent · Grundwert · 20 sind 25 %', '20 Bälle sind 25 % aller Bälle.

Wie viele Bälle sind es insgesamt?', 'II', null),
  ('prozent-grundwert-03', 'Prozent · Grundwert · 30 sind 20 %', '30 Karten sind 20 % aller Karten.

Wie viele Karten sind es insgesamt?', 'II', null),
  ('prozent-grundwert-04', 'Prozent · Grundwert · 40 sind 50 %', '40 Stifte sind 50 % aller Stifte.

Wie viele Stifte sind es insgesamt?', 'II', null),
  ('prozent-grundwert-05', 'Prozent · Grundwert · 12 sind 25 %', '12 Hefte sind 25 % aller Hefte.

Wie viele Hefte sind es insgesamt?', 'II', null),
  ('prozent-grundwert-06', 'Prozent · Grundwert · 15 sind 50 %', '15 Plätze sind 50 % aller Plätze.

Wie viele Plätze sind es insgesamt?', 'II', null),
  ('prozent-veraenderung-01', 'Prozent · Veränderung · 200 € +20 %', 'Ein Fahrrad kostet 200 €. Der Preis steigt um 20 %.

Wie viel Euro kostet es danach?', 'II', '€'),
  ('prozent-veraenderung-02', 'Prozent · Veränderung · 80 € −25 %', 'Ein Pullover kostet 80 €. Der Preis sinkt um 25 %.

Wie viel Euro kostet es danach?', 'II', '€'),
  ('prozent-veraenderung-03', 'Prozent · Veränderung · 150 € +10 %', 'Ein Rucksack kostet 150 €. Der Preis steigt um 10 %.

Wie viel Euro kostet es danach?', 'II', '€'),
  ('prozent-veraenderung-04', 'Prozent · Veränderung · 60 € −25 %', 'Ein Buch kostet 60 €. Der Preis sinkt um 25 %.

Wie viel Euro kostet es danach?', 'II', '€'),
  ('prozent-veraenderung-05', 'Prozent · Veränderung · 250 € +20 %', 'Ein Zelt kostet 250 €. Der Preis steigt um 20 %.

Wie viel Euro kostet es danach?', 'II', '€')
) as v(source_ref, titel, frage, afb, unit)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung, Akzeptanz-Set und Fehlbilder (Server-Only-Zone) ────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('gleichung-einschrittig-01', '["5"]', '{"canonical": "5", "known_errors": {"19": "falsche_gegenoperation", "-5": "seiten_verwechselt"}}'),
  ('gleichung-einschrittig-02', '["13"]', '{"canonical": "13", "known_errors": {"5": "falsche_gegenoperation", "-5": "seiten_verwechselt"}}'),
  ('gleichung-einschrittig-03', '["6"]', '{"canonical": "6", "known_errors": {"15": "falsche_gegenoperation"}}'),
  ('gleichung-einschrittig-04', '["8"]', '{"canonical": "8", "known_errors": {"32": "falsche_gegenoperation", "-8": "seiten_verwechselt"}}'),
  ('gleichung-einschrittig-05', '["15"]', '{"canonical": "15", "known_errors": {"-3": "falsche_gegenoperation", "3": "seiten_verwechselt"}}'),
  ('gleichung-einschrittig-06', '["6"]', '{"canonical": "6", "known_errors": {"20": "falsche_gegenoperation"}}'),
  ('gleichung-zweischrittig-01', '["6"]', '{"canonical": "6", "known_errors": {"18": "division_vergessen", "10": "addiert_statt_subtrahiert", "8": "b_ignoriert"}}'),
  ('gleichung-zweischrittig-02', '["8"]', '{"canonical": "8", "known_errors": {"16": "division_vergessen", "12": "addiert_statt_subtrahiert", "10": "b_ignoriert"}}'),
  ('gleichung-zweischrittig-03', '["7"]', '{"canonical": "7", "known_errors": {"35": "division_vergessen", "11": "addiert_statt_subtrahiert", "9": "b_ignoriert"}}'),
  ('gleichung-zweischrittig-04', '["8"]', '{"canonical": "8", "known_errors": {"32": "division_vergessen", "12": "addiert_statt_subtrahiert", "10": "b_ignoriert"}}'),
  ('gleichung-zweischrittig-05', '["7"]', '{"canonical": "7", "known_errors": {"21": "division_vergessen", "13": "addiert_statt_subtrahiert", "10": "b_ignoriert"}}'),
  ('gleichung-zweischrittig-06', '["5"]', '{"canonical": "5", "known_errors": {"30": "division_vergessen", "9": "addiert_statt_subtrahiert", "7": "b_ignoriert"}}'),
  ('gleichung-negativ-01', '["2"]', '{"canonical": "2", "known_errors": {"-2": "vorzeichen_beim_umstellen", "6": "division_vergessen"}}'),
  ('gleichung-negativ-02', '["3"]', '{"canonical": "3", "known_errors": {"-3": "vorzeichen_beim_umstellen", "12": "division_vergessen"}}'),
  ('gleichung-negativ-03', '["2"]', '{"canonical": "2", "known_errors": {"-2": "vorzeichen_beim_umstellen", "10": "division_vergessen"}}'),
  ('gleichung-negativ-04', '["7"]', '{"canonical": "7", "known_errors": {"-7": "vorzeichen_beim_umstellen", "14": "division_vergessen"}}'),
  ('gleichung-negativ-05', '["3"]', '{"canonical": "3", "known_errors": {"-3": "vorzeichen_beim_umstellen", "18": "division_vergessen"}}'),
  ('gleichung-beidseitig-01', '["5"]', '{"canonical": "5", "known_errors": {"3": "variablen_nicht_zusammengefuehrt", "7": "falsches_vorzeichen_beim_zusammenfuehren"}}'),
  ('gleichung-beidseitig-02', '["6"]', '{"canonical": "6", "known_errors": {"3": "variablen_nicht_zusammengefuehrt", "8": "falsches_vorzeichen_beim_zusammenfuehren"}}'),
  ('gleichung-beidseitig-03', '["10"]', '{"canonical": "10", "known_errors": {"4": "variablen_nicht_zusammengefuehrt", "15": "falsches_vorzeichen_beim_zusammenfuehren"}}'),
  ('gleichung-beidseitig-04', '["7"]', '{"canonical": "7", "known_errors": {"4": "variablen_nicht_zusammengefuehrt", "8": "falsches_vorzeichen_beim_zusammenfuehren"}}'),
  ('gleichung-beidseitig-05', '["6"]', '{"canonical": "6", "known_errors": {"4": "variablen_nicht_zusammengefuehrt", "8": "falsches_vorzeichen_beim_zusammenfuehren"}}'),
  ('prozent-wert-01', '["12"]', '{"canonical": "12", "known_errors": {"1200": "dezimalverschiebung"}, "unit": "€"}'),
  ('prozent-wert-02', '["40"]', '{"canonical": "40", "known_errors": {"4000": "dezimalverschiebung", "1000": "grundwert_verwechselt"}, "unit": "€"}'),
  ('prozent-wert-03', '["15"]', '{"canonical": "15", "known_errors": {"1500": "dezimalverschiebung", "240": "grundwert_verwechselt"}, "unit": "€"}'),
  ('prozent-wert-04', '["30"]', '{"canonical": "30", "known_errors": {"3000": "dezimalverschiebung", "750": "grundwert_verwechselt"}, "unit": "€"}'),
  ('prozent-wert-05', '["20"]', '{"canonical": "20", "known_errors": {"2000": "dezimalverschiebung", "80": "grundwert_verwechselt"}, "unit": "€"}'),
  ('prozent-wert-06', '["9"]', '{"canonical": "9", "known_errors": {"900": "dezimalverschiebung"}, "unit": "€"}'),
  ('prozent-satz-01', '["15"]', '{"canonical": "15", "known_errors": {"0,15": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-satz-02', '["25"]', '{"canonical": "25", "known_errors": {"400": "bezug_vertauscht", "0,25": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-satz-03', '["25"]', '{"canonical": "25", "known_errors": {"400": "bezug_vertauscht", "0,25": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-satz-04', '["10"]', '{"canonical": "10", "known_errors": {"1000": "bezug_vertauscht", "0,1": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-satz-05', '["50"]', '{"canonical": "50", "known_errors": {"200": "bezug_vertauscht", "0,5": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-satz-06', '["20"]', '{"canonical": "20", "known_errors": {"500": "bezug_vertauscht", "0,2": "faktor_100_vergessen"}, "unit": "%"}'),
  ('prozent-grundwert-01', '["80"]', '{"canonical": "80", "known_errors": {"1,8": "multipliziert_statt_dividiert", "180": "dezimalverschiebung"}}'),
  ('prozent-grundwert-02', '["80"]', '{"canonical": "80", "known_errors": {"5": "multipliziert_statt_dividiert", "500": "dezimalverschiebung"}}'),
  ('prozent-grundwert-03', '["150"]', '{"canonical": "150", "known_errors": {"6": "multipliziert_statt_dividiert", "600": "dezimalverschiebung"}}'),
  ('prozent-grundwert-04', '["80"]', '{"canonical": "80", "known_errors": {"20": "multipliziert_statt_dividiert", "2000": "dezimalverschiebung"}}'),
  ('prozent-grundwert-05', '["48"]', '{"canonical": "48", "known_errors": {"3": "multipliziert_statt_dividiert", "300": "dezimalverschiebung"}}'),
  ('prozent-grundwert-06', '["30"]', '{"canonical": "30", "known_errors": {"7,5": "multipliziert_statt_dividiert", "750": "dezimalverschiebung"}}'),
  ('prozent-veraenderung-01', '["240"]', '{"canonical": "240", "known_errors": {"40": "nur_prozentwert", "160": "falsche_richtung"}, "unit": "€"}'),
  ('prozent-veraenderung-02', '["60"]', '{"canonical": "60", "known_errors": {"20": "nur_prozentwert", "100": "falsche_richtung"}, "unit": "€"}'),
  ('prozent-veraenderung-03', '["165"]', '{"canonical": "165", "known_errors": {"15": "nur_prozentwert", "135": "falsche_richtung"}, "unit": "€"}'),
  ('prozent-veraenderung-04', '["45"]', '{"canonical": "45", "known_errors": {"15": "nur_prozentwert", "75": "falsche_richtung"}, "unit": "€"}'),
  ('prozent-veraenderung-05', '["300"]', '{"canonical": "300", "known_errors": {"50": "nur_prozentwert", "200": "falsche_richtung"}, "unit": "€"}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Proben gegen lsa_grade, mit Negativkontrolle ────────────────────────
--
-- Der Generator kennt die Bewertungsfunktion nicht und baut sie nicht nach.
-- Er schreibt die Erwartung hierher, und die Datenbank prueft sie selbst.
--
-- Die letzte Zeile ist ABSICHTLICH falsch erwartet. Schlaegt sie nicht an,
-- prueft die Schleife in Wahrheit nichts — dann bricht der Block ebenfalls ab.

do $$
declare
  r           record;
  v_urteil    text;
  v_echte     int := 0;
  v_kontrolle int := 0;
begin
  for r in
    select * from (values
      ('gleichung-einschrittig-01', '5', 'voll', '—', false),
      ('gleichung-einschrittig-01', '19', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-einschrittig-01', '-5', 'nicht', 'seiten_verwechselt', false),
      ('gleichung-einschrittig-02', '13', 'voll', '—', false),
      ('gleichung-einschrittig-02', '5', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-einschrittig-02', '-5', 'nicht', 'seiten_verwechselt', false),
      ('gleichung-einschrittig-03', '6', 'voll', '—', false),
      ('gleichung-einschrittig-03', '15', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-einschrittig-04', '8', 'voll', '—', false),
      ('gleichung-einschrittig-04', '32', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-einschrittig-04', '-8', 'nicht', 'seiten_verwechselt', false),
      ('gleichung-einschrittig-05', '15', 'voll', '—', false),
      ('gleichung-einschrittig-05', '-3', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-einschrittig-05', '3', 'nicht', 'seiten_verwechselt', false),
      ('gleichung-einschrittig-06', '6', 'voll', '—', false),
      ('gleichung-einschrittig-06', '20', 'nicht', 'falsche_gegenoperation', false),
      ('gleichung-zweischrittig-01', '6', 'voll', '—', false),
      ('gleichung-zweischrittig-01', '18', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-01', '10', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-01', '8', 'nicht', 'b_ignoriert', false),
      ('gleichung-zweischrittig-02', '8', 'voll', '—', false),
      ('gleichung-zweischrittig-02', '16', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-02', '12', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-02', '10', 'nicht', 'b_ignoriert', false),
      ('gleichung-zweischrittig-03', '7', 'voll', '—', false),
      ('gleichung-zweischrittig-03', '35', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-03', '11', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-03', '9', 'nicht', 'b_ignoriert', false),
      ('gleichung-zweischrittig-04', '8', 'voll', '—', false),
      ('gleichung-zweischrittig-04', '32', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-04', '12', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-04', '10', 'nicht', 'b_ignoriert', false),
      ('gleichung-zweischrittig-05', '7', 'voll', '—', false),
      ('gleichung-zweischrittig-05', '21', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-05', '13', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-05', '10', 'nicht', 'b_ignoriert', false),
      ('gleichung-zweischrittig-06', '5', 'voll', '—', false),
      ('gleichung-zweischrittig-06', '30', 'nicht', 'division_vergessen', false),
      ('gleichung-zweischrittig-06', '9', 'nicht', 'addiert_statt_subtrahiert', false),
      ('gleichung-zweischrittig-06', '7', 'nicht', 'b_ignoriert', false),
      ('gleichung-negativ-01', '2', 'voll', '—', false),
      ('gleichung-negativ-01', '-2', 'nicht', 'vorzeichen_beim_umstellen', false),
      ('gleichung-negativ-01', '6', 'nicht', 'division_vergessen', false),
      ('gleichung-negativ-02', '3', 'voll', '—', false),
      ('gleichung-negativ-02', '-3', 'nicht', 'vorzeichen_beim_umstellen', false),
      ('gleichung-negativ-02', '12', 'nicht', 'division_vergessen', false),
      ('gleichung-negativ-03', '2', 'voll', '—', false),
      ('gleichung-negativ-03', '-2', 'nicht', 'vorzeichen_beim_umstellen', false),
      ('gleichung-negativ-03', '10', 'nicht', 'division_vergessen', false),
      ('gleichung-negativ-04', '7', 'voll', '—', false),
      ('gleichung-negativ-04', '-7', 'nicht', 'vorzeichen_beim_umstellen', false),
      ('gleichung-negativ-04', '14', 'nicht', 'division_vergessen', false),
      ('gleichung-negativ-05', '3', 'voll', '—', false),
      ('gleichung-negativ-05', '-3', 'nicht', 'vorzeichen_beim_umstellen', false),
      ('gleichung-negativ-05', '18', 'nicht', 'division_vergessen', false),
      ('gleichung-beidseitig-01', '5', 'voll', '—', false),
      ('gleichung-beidseitig-01', '3', 'nicht', 'variablen_nicht_zusammengefuehrt', false),
      ('gleichung-beidseitig-01', '7', 'nicht', 'falsches_vorzeichen_beim_zusammenfuehren', false),
      ('gleichung-beidseitig-02', '6', 'voll', '—', false),
      ('gleichung-beidseitig-02', '3', 'nicht', 'variablen_nicht_zusammengefuehrt', false),
      ('gleichung-beidseitig-02', '8', 'nicht', 'falsches_vorzeichen_beim_zusammenfuehren', false),
      ('gleichung-beidseitig-03', '10', 'voll', '—', false),
      ('gleichung-beidseitig-03', '4', 'nicht', 'variablen_nicht_zusammengefuehrt', false),
      ('gleichung-beidseitig-03', '15', 'nicht', 'falsches_vorzeichen_beim_zusammenfuehren', false),
      ('gleichung-beidseitig-04', '7', 'voll', '—', false),
      ('gleichung-beidseitig-04', '4', 'nicht', 'variablen_nicht_zusammengefuehrt', false),
      ('gleichung-beidseitig-04', '8', 'nicht', 'falsches_vorzeichen_beim_zusammenfuehren', false),
      ('gleichung-beidseitig-05', '6', 'voll', '—', false),
      ('gleichung-beidseitig-05', '4', 'nicht', 'variablen_nicht_zusammengefuehrt', false),
      ('gleichung-beidseitig-05', '8', 'nicht', 'falsches_vorzeichen_beim_zusammenfuehren', false),
      ('prozent-wert-01', '12', 'voll', '—', false),
      ('prozent-wert-01', '1200', 'nicht', 'dezimalverschiebung', false),
      ('prozent-wert-02', '40', 'voll', '—', false),
      ('prozent-wert-02', '4000', 'nicht', 'dezimalverschiebung', false),
      ('prozent-wert-02', '1000', 'nicht', 'grundwert_verwechselt', false),
      ('prozent-wert-03', '15', 'voll', '—', false),
      ('prozent-wert-03', '1500', 'nicht', 'dezimalverschiebung', false),
      ('prozent-wert-03', '240', 'nicht', 'grundwert_verwechselt', false),
      ('prozent-wert-04', '30', 'voll', '—', false),
      ('prozent-wert-04', '3000', 'nicht', 'dezimalverschiebung', false),
      ('prozent-wert-04', '750', 'nicht', 'grundwert_verwechselt', false),
      ('prozent-wert-05', '20', 'voll', '—', false),
      ('prozent-wert-05', '2000', 'nicht', 'dezimalverschiebung', false),
      ('prozent-wert-05', '80', 'nicht', 'grundwert_verwechselt', false),
      ('prozent-wert-06', '9', 'voll', '—', false),
      ('prozent-wert-06', '900', 'nicht', 'dezimalverschiebung', false),
      ('prozent-satz-01', '15', 'voll', '—', false),
      ('prozent-satz-01', '0,15', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-satz-02', '25', 'voll', '—', false),
      ('prozent-satz-02', '400', 'nicht', 'bezug_vertauscht', false),
      ('prozent-satz-02', '0,25', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-satz-03', '25', 'voll', '—', false),
      ('prozent-satz-03', '400', 'nicht', 'bezug_vertauscht', false),
      ('prozent-satz-03', '0,25', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-satz-04', '10', 'voll', '—', false),
      ('prozent-satz-04', '1000', 'nicht', 'bezug_vertauscht', false),
      ('prozent-satz-04', '0,1', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-satz-05', '50', 'voll', '—', false),
      ('prozent-satz-05', '200', 'nicht', 'bezug_vertauscht', false),
      ('prozent-satz-05', '0,5', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-satz-06', '20', 'voll', '—', false),
      ('prozent-satz-06', '500', 'nicht', 'bezug_vertauscht', false),
      ('prozent-satz-06', '0,2', 'nicht', 'faktor_100_vergessen', false),
      ('prozent-grundwert-01', '80', 'voll', '—', false),
      ('prozent-grundwert-01', '1,8', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-01', '180', 'nicht', 'dezimalverschiebung', false),
      ('prozent-grundwert-02', '80', 'voll', '—', false),
      ('prozent-grundwert-02', '5', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-02', '500', 'nicht', 'dezimalverschiebung', false),
      ('prozent-grundwert-03', '150', 'voll', '—', false),
      ('prozent-grundwert-03', '6', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-03', '600', 'nicht', 'dezimalverschiebung', false),
      ('prozent-grundwert-04', '80', 'voll', '—', false),
      ('prozent-grundwert-04', '20', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-04', '2000', 'nicht', 'dezimalverschiebung', false),
      ('prozent-grundwert-05', '48', 'voll', '—', false),
      ('prozent-grundwert-05', '3', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-05', '300', 'nicht', 'dezimalverschiebung', false),
      ('prozent-grundwert-06', '30', 'voll', '—', false),
      ('prozent-grundwert-06', '7,5', 'nicht', 'multipliziert_statt_dividiert', false),
      ('prozent-grundwert-06', '750', 'nicht', 'dezimalverschiebung', false),
      ('prozent-veraenderung-01', '240', 'voll', '—', false),
      ('prozent-veraenderung-01', '40', 'nicht', 'nur_prozentwert', false),
      ('prozent-veraenderung-01', '160', 'nicht', 'falsche_richtung', false),
      ('prozent-veraenderung-02', '60', 'voll', '—', false),
      ('prozent-veraenderung-02', '20', 'nicht', 'nur_prozentwert', false),
      ('prozent-veraenderung-02', '100', 'nicht', 'falsche_richtung', false),
      ('prozent-veraenderung-03', '165', 'voll', '—', false),
      ('prozent-veraenderung-03', '15', 'nicht', 'nur_prozentwert', false),
      ('prozent-veraenderung-03', '135', 'nicht', 'falsche_richtung', false),
      ('prozent-veraenderung-04', '45', 'voll', '—', false),
      ('prozent-veraenderung-04', '15', 'nicht', 'nur_prozentwert', false),
      ('prozent-veraenderung-04', '75', 'nicht', 'falsche_richtung', false),
      ('prozent-veraenderung-05', '300', 'voll', '—', false),
      ('prozent-veraenderung-05', '50', 'nicht', 'nur_prozentwert', false),
      ('prozent-veraenderung-05', '200', 'nicht', 'falsche_richtung', false),
      ('gleichung-einschrittig-01', '5', 'nicht', 'NEGATIVKONTROLLE', true)
    ) as p(source_ref, antwort, erwartet, label, ist_kontrolle)
  loop
    select public.lsa_grade(
             'NUMERIC', s.acceptance, s.correct_answers,
             jsonb_build_object('value', r.antwort)
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      if r.ist_kontrolle then
        v_kontrolle := v_kontrolle + 1;
        raise notice 'Negativkontrolle hat angeschlagen (so soll es sein): %/% ist %',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>');
      else
        v_echte := v_echte + 1;
        raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.label;
      end if;
    end if;
  end loop;

  if v_echte > 0 then
    raise exception '% echte Probe(n) fehlgeschlagen — nichts eingespielt.', v_echte;
  end if;
  if v_kontrolle <> 1 then
    raise exception 'Negativkontrolle hat NICHT angeschlagen — die Probenschleife prueft nichts.';
  end if;

  raise notice 'Gleichungen + Prozent: alle echten Proben bestanden, Negativkontrolle greift.';
end $$;

commit;
