-- ============================================================================
-- lsa_grade: „%“ ist ein Faktor 1/100 (Lenas Rückfrage vom 20.10.2026, 54f5e1df)
--
-- Zusagen:
--   A) Freie Schreibweise (Bruch, Dezimalzahl, Prozent): 12/25, 0,48, 48 % sind richtig;
--      0,48 %, 12/25 %, 48 (ohne %) sind falsch. „Prozent“ als Wort zählt wie „%“.
--   B) Antwort ist selbst ein Prozentsatz (acceptance.unit = '%'): „3“ und „3 %“ sind dasselbe,
--      0,03 ist falsch – wie bisher.
--   C) Andere Einheiten und unit_graded wie bisher; bei unit_graded mit canonical „20 %“ ist 0,2
--      'teilweise' (Wert richtig, Form falsch) und 20 'nicht'.
--   D) pruef_einheit: abgeleitetes „%“ ist keine Einheit der Aufgabe, ausdrückliches schon.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(27);

-- --- A)–C) lsa_grade ---------------------------------------------------------

select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"12/25"}'::jsonb), 'voll', 'Bruch: "12/25"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"0,48"}'::jsonb), 'voll', 'Dezimalzahl: "0,48"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"48 %"}'::jsonb), 'voll', 'Prozent mit Zeichen: "48 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"48%"}'::jsonb), 'voll', 'Prozent ohne Leerzeichen: "48%"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"48 Prozent"}'::jsonb), 'voll', 'Prozent als Wort: "48 Prozent"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"0,48 %"}'::jsonb), 'nicht', 'Dezimalzahl mit %: "0,48 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"12/25 %"}'::jsonb), 'nicht', 'Bruch mit %: "12/25 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"48"}'::jsonb), 'nicht', 'Prozentzahl ohne %: "48"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"0,48 Prozent"}'::jsonb), 'nicht', 'Dezimalzahl mit Prozent als Wort: "0,48 Prozent"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12/25","equivalents":["0,48","48 %"]}'::jsonb, '[]'::jsonb, '{"text":"4800 %"}'::jsonb), 'nicht', 'hundertfach: "4800 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"48 %"}'::jsonb, '[]'::jsonb, '{"text":"0,48"}'::jsonb), 'voll', 'Dezimalzahl gegen kanonisch 48 %: "0,48"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"48 %"}'::jsonb, '[]'::jsonb, '{"text":"0,0048"}'::jsonb), 'nicht', 'Hundertstel gegen kanonisch 48 %: "0,0048"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-0,5"}'::jsonb, '[]'::jsonb, '{"text":"-50 %"}'::jsonb), 'voll', 'negativ: "-50 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"1/2"}'::jsonb, '[]'::jsonb, '{"text":"+50 %"}'::jsonb), 'voll', 'mit Pluszeichen: "+50 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"1 1/2"}'::jsonb, '[]'::jsonb, '{"text":"150 %"}'::jsonb), 'voll', 'gemischter Bruch: "150 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3","equivalents":["3 %"],"unit":"%"}'::jsonb, '[]'::jsonb, '{"text":"3"}'::jsonb), 'voll', 'Prozentsatz: Zahl: "3"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3","equivalents":["3 %"],"unit":"%"}'::jsonb, '[]'::jsonb, '{"text":"3 %"}'::jsonb), 'voll', 'Prozentsatz: mit %: "3 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3","unit":"%"}'::jsonb, '[]'::jsonb, '{"text":"3 %"}'::jsonb), 'voll', 'Prozentsatz ohne Aequivalent: mit %: "3 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3","equivalents":["3 %"],"unit":"%"}'::jsonb, '[]'::jsonb, '{"text":"0,03"}'::jsonb), 'nicht', 'Prozentsatz: Faktor 100 vergessen: "0,03"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"12 cm"}'::jsonb, '[]'::jsonb, '{"text":"12"}'::jsonb), 'voll', 'andere Einheit wie bisher: "12"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"20 %","unit_graded":true}'::jsonb, '[]'::jsonb, '{"text":"20 %"}'::jsonb), 'voll', 'unit_graded: richtig: "20 %"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"20 %","unit_graded":true}'::jsonb, '[]'::jsonb, '{"text":"0,2"}'::jsonb), 'teilweise', 'unit_graded: Wert richtig, Form falsch: "0,2"');
select is(public.lsa_grade('NUMERIC', '{"canonical":"20 %","unit_graded":true}'::jsonb, '[]'::jsonb, '{"text":"20"}'::jsonb), 'nicht', 'unit_graded: Prozentzahl ohne %: "20"');

-- --- D) pruef_einheit -------------------------------------------------------
select is(public.pruef_einheit('{"canonical":"12/25"}'::jsonb, '["12/25","48 %"]'::jsonb), null, 'pruef_einheit: % aus den Antworten abgeleitet, keine Einheit');
select is(public.pruef_einheit('{"canonical":"20 %"}'::jsonb, '[]'::jsonb), null, 'pruef_einheit: % aus canonical abgeleitet, keine Einheit');
select is(public.pruef_einheit('{"canonical":"3","unit":"%"}'::jsonb, '["3"]'::jsonb), '%', 'pruef_einheit: ausdrückliches %');
select is(public.pruef_einheit('{"canonical":"12 cm"}'::jsonb, '[]'::jsonb), 'cm', 'pruef_einheit: andere Einheit abgeleitet wie bisher');

select * from finish();
rollback;
