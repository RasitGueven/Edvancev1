-- ============================================================================
-- INV11: Das Skill-Urteil liest Vorzeichen-Schreibweisen wie lsa_is_correct
--        (K12, docs/prefill/befunde-k9-kreis.md)
--
-- Zusagen:
--   A) lsa_normalize_number: U+2212/U+2013/U+2014 -> "-", fuehrendes "+" weg,
--      Leerraum zwischen Vorzeichen und Zahl weg, aussen getrimmt, Komma -> Punkt.
--      Vor Nicht-Ziffern bleibt das Vorzeichen stehen.
--   B) lsa_grade wertet "+11", "- 3", "−3", "–3", "-3", "3,5", "3.5", " 7 " gegen
--      die kanonische Loesung als 'voll' — so, wie die Chargen sie nur mit
--      canonical (ohne equivalents) in acceptance tragen. Mit Einheit und als
--      Bruch ebenso ("+11 €", "+1/2", "- 2,5").
--   C) Falsche Werte bleiben falsch: "+12" bei 11, "3" bei -3, "+3" bei -3.
--      require_reduced sieht durch das "+" hindurch: "+2/4" ist 'teilweise'.
--   D) lsa_is_correct und lsa_normalize_answer sind unveraendert: "+11" ist
--      dort nur richtig, wenn es in correct_answers steht.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(26);

-- --- A) Normalisierung -------------------------------------------------------

select is(public.lsa_normalize_number('+11'),   '11',   '"+11" -> "11"');
select is(public.lsa_normalize_number('- 3'),   '-3',   '"- 3" -> "-3"');
select is(public.lsa_normalize_number('−3'),    '-3',   'U+2212 -> "-"');
select is(public.lsa_normalize_number('–3'),    '-3',   'U+2013 -> "-"');
select is(public.lsa_normalize_number('— 3'),   '-3',   'U+2014 mit Leerzeichen -> "-3"');
select is(public.lsa_normalize_number(' 7 '),   '7',    'aussen getrimmt');
select is(public.lsa_normalize_number('3,5'),   '3.5',  'Dezimalkomma wie bisher');
select is(public.lsa_normalize_number('+ x'),   '+ x',  'Vor einer Nicht-Ziffer bleibt das Vorzeichen');
select is(public.lsa_split_value_unit('+11 €'), array['11', '€'], 'Zahl und Einheit nach "+" getrennt');

-- --- B) Richtige Schreibweisen: 'voll' ----------------------------------------

select is(public.lsa_grade('NUMERIC', '{"canonical":"11"}'::jsonb, '["11","+11"]'::jsonb,
                           '{"value":"+11"}'::jsonb), 'voll', '"+11" bei Loesung 11');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3","−3","- 3"]'::jsonb,
                           '{"value":"- 3"}'::jsonb), 'voll', '"- 3" bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3","−3","- 3"]'::jsonb,
                           '{"value":"−3"}'::jsonb), 'voll', '"−3" (U+2212) bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3"]'::jsonb,
                           '{"value":"–3"}'::jsonb), 'voll', '"–3" (U+2013) bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3"]'::jsonb,
                           '{"value":"-3"}'::jsonb), 'voll', '"-3" bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3,5"}'::jsonb, '["3,5","3.5"]'::jsonb,
                           '{"value":"3,5"}'::jsonb), 'voll', '"3,5" bei Loesung 3,5');
select is(public.lsa_grade('NUMERIC', '{"canonical":"3,5"}'::jsonb, '["3,5","3.5"]'::jsonb,
                           '{"value":"3.5"}'::jsonb), 'voll', '"3.5" bei Loesung 3,5');
select is(public.lsa_grade('NUMERIC', '{"canonical":"7"}'::jsonb, '["7"]'::jsonb,
                           '{"value":" 7 "}'::jsonb), 'voll', '" 7 " bei Loesung 7');
select is(public.lsa_grade('NUMERIC', '{"canonical":"11"}'::jsonb, '["11","+11 €"]'::jsonb,
                           '{"value":"+11 €"}'::jsonb), 'voll', '"+11 €" bei Loesung 11');
select is(public.lsa_grade('NUMERIC', '{"canonical":"1/2"}'::jsonb, '["1/2","+1/2"]'::jsonb,
                           '{"value":"+1/2"}'::jsonb), 'voll', '"+1/2" bei Loesung 1/2');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-2,5"}'::jsonb, '["-2,5","- 2,5"]'::jsonb,
                           '{"value":"- 2,5"}'::jsonb), 'voll', '"- 2,5" bei Loesung -2,5');

-- --- C) Falsche Werte bleiben falsch ------------------------------------------

select is(public.lsa_grade('NUMERIC', '{"canonical":"11"}'::jsonb, '["11","+11"]'::jsonb,
                           '{"value":"+12"}'::jsonb), 'nicht', '"+12" bei Loesung 11');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3","−3","- 3"]'::jsonb,
                           '{"value":"3"}'::jsonb), 'nicht', '"3" bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"-3"}'::jsonb, '["-3","−3","- 3"]'::jsonb,
                           '{"value":"+3"}'::jsonb), 'nicht', '"+3" bei Loesung -3');
select is(public.lsa_grade('NUMERIC', '{"canonical":"1/2","require_reduced":true}'::jsonb,
                           '["1/2"]'::jsonb, '{"value":"+2/4"}'::jsonb),
          'teilweise', '"+2/4" mit require_reduced: richtig gerechnet, nicht gekuerzt');

-- --- D) lsa_is_correct unveraendert -------------------------------------------

select is(public.lsa_normalize_answer('−3'), '−3', 'lsa_normalize_answer bildet U+2212 weiter nicht ab');
select ok(not public.lsa_is_correct('NUMERIC', '["11"]'::jsonb, '{"value":"+11"}'::jsonb),
          'lsa_is_correct: "+11" ohne Eintrag in correct_answers bleibt falsch');

select * from finish();
rollback;
