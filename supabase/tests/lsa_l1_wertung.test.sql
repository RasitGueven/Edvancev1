-- ============================================================================
-- LSA-Erlebnis L1, Punkte 2 und 3: Antwortkodierung und Wertung nach Eingabeformat.
-- Migrationen 20261021082844_lsa_bruch_term_wertung und 20261021083001_lsa_urteil_eingabeformat.
--   W1 Bruch nach Wert (lsa_bruch_wert_gleich): gekuerzt, ungekuerzt, negativ, Nenner 0, Dezimal
--   W2 lsa_antwort_korrekt: Wertvergleich nur bei fraction; bisherige Zeichenkettentreffer bleiben
--   W3 Term: Abgabeform der App trifft (a = 1, a = -1, a = 0, negatives b)
--   W4 lsa_grade mit input_hint: dasselbe Urteil wie correct
--   W5 lsa_submit Ende-zu-Ende: correct je Aufgabe und je Teil, Urteil
--   W6 Kodierung (Punkt 2): {dont_know:true} flach und je Teil {"2":{"dont_know":true}}
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(49);

\ir lsa_l1_fixture.sql

-- W1 Bruch nach Wert ------------------------------------------------------
select is(public.lsa_bruch_wert_gleich('-3/4', '["-3/4"]'), true, 'W1 gekuerzt: -3/4 trifft -3/4');
select is(public.lsa_bruch_wert_gleich('-3/4', '["-6/8"]'), true, 'W1 -3/4 trifft die ungekuerzte Loesung -6/8');
select is(public.lsa_bruch_wert_gleich('-6/8', '["-3/4"]'), true, 'W1 ungekuerzt: -6/8 trifft -3/4');
select is(public.lsa_bruch_wert_gleich('-3/4', '["-0,75"]'), true, 'W1 Dezimal-Loesung: -3/4 trifft -0,75');
select is(public.lsa_bruch_wert_gleich('-0,75', '["-3/4"]'), true, 'W1 Dezimal-Antwort: -0,75 trifft -3/4');
select is(public.lsa_bruch_wert_gleich('3/4', '["-3/4"]'), false, 'W1 negativ: 3/4 trifft -3/4 nicht');
select is(public.lsa_bruch_wert_gleich('-3/4', '["3/4"]'), false, 'W1 negativ: -3/4 trifft 3/4 nicht');
select is(public.lsa_bruch_wert_gleich('3/0', '["3/0","0"]'), false, 'W1 Nenner 0 trifft nie (auch nicht sich selbst)');
select is(public.lsa_bruch_wert_gleich('0/5', '["0"]'), true, 'W1 0/5 ist 0');
select is(public.lsa_bruch_wert_gleich('75 %', '["3/4"]'), false, 'W1 Prozent ist keine Zahl im Wertvergleich');
select is(public.lsa_bruch_wert_gleich('3/4', '["75 %","75"]'), false,
          'W1 Loesungen mit % nehmen nicht teil, der nackte Prozentwert ist eine andere Zahl');

-- W2 lsa_antwort_korrekt --------------------------------------------------
select is(public.lsa_antwort_korrekt('NUMERIC', 'fraction', '["3/4"]', '{"text":"6/8"}'), true,
          'W2 fraction: 6/8 trifft 3/4');
select is(public.lsa_antwort_korrekt('NUMERIC', 'number', '["3/4"]', '{"text":"6/8"}'), false,
          'W2 number: kein Wertvergleich, 6/8 trifft 3/4 nicht (wie bisher)');
select is(public.lsa_antwort_korrekt('NUMERIC', 'fraction', '["1/2","50"]', '{"text":"50"}'), true,
          'W2 Zeichenkettentreffer bleibt: „50“ zaehlt weiter, wenn es in correct_answers steht');
select is(public.lsa_antwort_korrekt('NUMERIC', 'fraction', '["1/2","50"]', '{"text":"0,5"}'), true,
          'W2 fraction: 0,5 trifft 1/2 nach Wert');
select is(public.lsa_antwort_korrekt('NUMERIC', 'fraction', '["3/4"]', '"6/8"'), false,
          'W2 nackter String ist keine Antwort (wie lsa_is_correct)');
select is(public.lsa_antwort_korrekt('MC', null, '["b"]', '{"selected":["b"]}'), true, 'W2 MC unveraendert');

-- W3 Term -----------------------------------------------------------------
select is(public.lsa_antwort_korrekt('TERM', 'term', '["1x+5"]', '{"text":"x+5"}'), true, 'W3 a = 1: x+5 trifft 1x+5');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["-1x+5"]', '{"text":"-x+5"}'), true, 'W3 a = -1: -x+5 trifft -1x+5');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["5 - x"]', '{"text":"-x+5"}'), true, 'W3 a = -1: -x+5 trifft 5 - x');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["0x+7"]', '{"text":"7"}'), true, 'W3 a = 0: 7 trifft 0x+7');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["3x+(-6)","3x + -6"]', '{"text":"3x-6"}'), true,
          'W3 negatives b: 3x-6 trifft 3x + -6');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["-6+3x"]', '{"text":"3x-6"}'), true, 'W3 negatives b: 3x-6 trifft -6+3x');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["3x"]', '{"text":"3x"}'), true, 'W3 b = 0: 3x trifft 3x');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["3x+6"]', '{"text":"3x-6"}'), false, 'W3 3x-6 trifft 3x+6 nicht');
select is(public.lsa_antwort_korrekt('TERM', 'term', '["2x+1"]', '{"text":"x+1"}'), false, 'W3 x+1 trifft 2x+1 nicht');
select is(public.lsa_term_kanonisch('2(x+3)'), '2(x+3)', 'W3 nichtlinearer Ausdruck bleibt, wie er ist (keine Klammer-Magie)');
select is(public.lsa_term_kanonisch('3·x - 6'), '3x-6', 'W3 Malpunkt zwischen Ziffer und x faellt weg');
select is(public.lsa_term_kanonisch('2·3'), '2·3', 'W3 Malpunkt zwischen Ziffern bleibt');
select is(public.lsa_antwort_korrekt('SHORT_TEXT', 'term', '["x+5"]', '{"text":"1x + 5"}'), true,
          'W3 Teil mit term: dieselbe Normalisierung wie eine TERM-Aufgabe');

-- W4 lsa_grade mit input_hint ---------------------------------------------
select is(public.lsa_grade('NUMERIC', null, '["-3/4"]', '{"text":"-6/8"}'), 'nicht', 'W4 vorher: -6/8 gegen -3/4 nicht');
select is(public.lsa_grade('NUMERIC', null, '["-3/4"]', '{"text":"-6/8"}', 'fraction'), 'voll',
          'W4 mit fraction: voll (wie correct)');
select is(public.lsa_grade('NUMERIC', null, '["-3/4"]', '{"text":"-6/8"}', 'number'), 'nicht', 'W4 mit number: unveraendert');
select is(public.lsa_grade('TERM', null, '["1x+5"]', '{"text":"x+5"}', 'term'), 'voll', 'W4 Term kanonisch: voll');
select is(public.lsa_grade('NUMERIC', '{"canonical":"5/2","require_reduced":true}', '["5/2","10/4"]', '{"text":"20/8"}'),
          'teilweise', 'W4 vierstellig: 20/8 trifft canonical 5/2 nach Wert, ungekuerzt → teilweise');
select is(public.lsa_grade('NUMERIC', '{"canonical":"5/2","require_reduced":true}', '["5/2","10/4"]', '{"text":"20/8"}', 'fraction'),
          'teilweise', 'W4 fuenfstellig (fraction, ohne Einheit): ungekuerzt bleibt teilweise');
select is(public.lsa_grade('NUMERIC', '{"canonical":"48 %","equivalents":["12/25"]}', '["12/25","48 %"]', '{"text":"48"}', 'number'),
          public.lsa_grade('NUMERIC', '{"canonical":"48 %","equivalents":["12/25"]}', '["12/25","48 %"]', '{"text":"48"}'),
          'W4 number: fuenfstellig = vierstellig (#294 Prozent als Faktor unangetastet)');
select is(public.lsa_grade('NUMERIC', '{"canonical":"5/2","unit_graded":true,"unit":"cm","require_reduced":true}',
                           '["10/4"]', '{"text":"10/4"}', 'fraction'), 'teilweise',
          'W4 require_reduced: ungekuerzter Treffer nur ueber correct_answers → teilweise');
select ok(not has_function_privilege('authenticated', 'public.lsa_antwort_korrekt(text, text, jsonb, jsonb)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_grade(text, jsonb, jsonb, jsonb, text)', 'execute'),
          'R Wertungsfunktionen nicht fuer anon/authenticated');
select ok(not has_function_privilege('authenticated', 'public.lsa_bruch_wert_gleich(text, jsonb)', 'execute'),
          'R lsa_bruch_wert_gleich nicht fuer authenticated');

-- W5 lsa_submit Ende-zu-Ende ----------------------------------------------
select pg_temp.l1_kind('Lina ZZ L1') as kind \gset
select pg_temp.l1_session(:'kind') as s \gset
select pg_temp.l1_aufgabe('w-frac', 'NUMERIC', '["-3/4"]') as t_frac \gset
select pg_temp.l1_aufgabe('w-num', 'NUMERIC', '["3/4"]', '[]', false) as t_num \gset
select pg_temp.l1_aufgabe('w-mp', 'MULTI_PART', '{"1":["1/2"],"2":["x+5"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},
    {"nr":2,"kind":"short_input","prompt":"Teil b","input_type":"TERM"}]') as t_mp \gset
-- Der offene Zweitbeleg der Fixture gilt fuer die Auswahl; fuer das Urteil hier zaehlt Probe 1.
delete from lsa_skill_urteil where session_id = :'s';

select pg_temp.l1_abgabe(:'s', :'t_frac', '{"text":"-6/8"}');
select is(pg_temp.l1_zeile(:'s', :'t_frac'), 'antwort/true', 'W5 Bruch-Aufgabe: -6/8 ist correct');
select is((select zustand from lsa_skill_urteil where session_id = :'s' and skill_key = 'zz_l1_s1'), 'traegt',
          'W5 das Urteil folgt correct (traegt nach Probe 1)');
select pg_temp.l1_abgabe(:'s', :'t_num', '{"text":"6/8"}');
select is(pg_temp.l1_zeile(:'s', :'t_num'), 'antwort/false', 'W5 Zahl-Aufgabe (bruch = false): 6/8 bleibt falsch');
select pg_temp.l1_abgabe(:'s', :'t_mp', '{"1":{"text":"2/4"},"2":"1x+5"}');
select is(pg_temp.l1_zeile(:'s', :'t_mp', 1), 'antwort/true', 'W5 Bruch-Teil: 2/4 trifft 1/2');
select is(pg_temp.l1_zeile(:'s', :'t_mp', 2), 'antwort/true', 'W5 Term-Teil (String-Kodierung): 1x+5 trifft x+5');

-- W6 Kodierung „Ich weiss es nicht“ (Punkt 2) -----------------------------
select pg_temp.l1_aufgabe('w-dk', 'NUMERIC', '["7"]') as t_dk \gset
select pg_temp.l1_aufgabe('w-mpdk', 'MULTI_PART', '{"1":["7"],"2":["8"],"3":["a"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},{"nr":2,"kind":"short_input","prompt":"Teil b"},
    {"nr":3,"kind":"mc","prompt":"Teil c","options":[{"id":"a","label":"ja"},{"id":"b","label":"nein"}]}]') as t_mpdk \gset
select pg_temp.l1_abgabe(:'s', :'t_dk', '{"dont_know":true}');
select is(pg_temp.l1_zeile(:'s', :'t_dk'), 'weiss_nicht/-', 'W6 flach: {dont_know:true} → weiss_nicht, kein correct');
select pg_temp.l1_abgabe(:'s', :'t_mpdk', '{"1":{"text":"7"},"2":{"dont_know":true},"3":{"dont_know":true}}');
select is(pg_temp.l1_zeile(:'s', :'t_mpdk', 1), 'antwort/true', 'W6 je Teil: Teil 1 beantwortet und richtig');
select is(pg_temp.l1_zeile(:'s', :'t_mpdk', 2), 'weiss_nicht/-', 'W6 je Teil: {"2":{"dont_know":true}} → weiss_nicht');
select is(pg_temp.l1_zeile(:'s', :'t_mpdk', 3), 'weiss_nicht/-', 'W6 je Teil: auch ein MC-Teil kann ausgelassen werden');

select * from finish();
rollback;
