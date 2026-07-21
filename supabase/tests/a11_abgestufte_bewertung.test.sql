-- ============================================================================
-- A11: Abgestufte Bewertung (voll | teilweise | nicht) mit Wertgleichheit.
--
-- Vier Zusagen:
--
--   A) WERTGLEICHHEIT: 11/12 und 22/24 sind dieselbe Zahl, 1/2 und 0,5 auch,
--      "1 1/2" und 3/2 ebenso. Der Parser kuerzt dabei NICHT — die geschriebene
--      Form bleibt erhalten, weil genau sie beurteilt wird.
--
--   B) DIE ZWISCHENSTUFE: mit require_reduced wird "22/24" zu 'teilweise'
--      (richtig gerechnet, nicht gekuerzt) statt zu 'nicht'. Ohne das Flag
--      bleibt es 'voll' — die Verschaerfung muss bestellt werden.
--
--   C) KEINE REGRESSION: ohne acceptance-Regel bewertet lsa_grade exakt wie
--      lsa_is_correct und kennt kein 'teilweise'. MC bleibt binaer.
--      lsa_is_correct selbst ist unveraendert — dieselbe Signatur, dasselbe
--      Ergebnis fuer denselben Fall.
--
--   D) ROBUSTHEIT: Muell-Eingaben geben NULL/false/'nicht' zurueck, sie werfen
--      nicht. Ein Auswertungspfad darf an "keine ahnung" nicht sterben.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(29);

-- --- A) Parser + Wertgleichheit --------------------------------------------

select is(
  public.lsa_parse_fraction('11/12'),
  array[11, 12]::numeric[],
  'Bruch wird als 11/12 gelesen — ungekuerzt, wie geschrieben'
);

select is(
  public.lsa_parse_fraction('22/24'),
  array[22, 24]::numeric[],
  'Der Parser kuerzt NICHT: 22/24 bleibt 22/24'
);

select is(
  public.lsa_parse_fraction('1 1/2'),
  array[3, 2]::numeric[],
  'Gemischter Bruch: 1 1/2 ist 3/2'
);

select is(
  public.lsa_parse_fraction('0,75'),
  array[75, 100]::numeric[],
  'Dezimal wird exakt zum Bruch (Komma kommt aus lsa_normalize_answer)'
);

select is(
  public.lsa_parse_fraction('-3'),
  array[-3, 1]::numeric[],
  'Ganze Zahl mit Vorzeichen: -3/1'
);

select is(
  public.lsa_parse_fraction('1,5 m'),
  array[15, 10]::numeric[],
  'Die Einheit stoert den Parser nicht — sie wird vorher abgetrennt'
);

select ok(
  public.lsa_values_equal('11/12', '22/24'),
  '11/12 = 22/24 — dieselbe Zahl, andere Schreibweise'
);

select ok(
  public.lsa_values_equal('0,5', '1/2'),
  '0,5 = 1/2 — Dezimal gegen Bruch'
);

select ok(
  public.lsa_values_equal('1 1/2', '3/2'),
  '1 1/2 = 3/2 — gemischt gegen unecht'
);

select ok(
  not public.lsa_values_equal('3/7', '11/12'),
  '3/7 ist NICHT 11/12 — ein echter Rechenfehler bleibt einer'
);

select ok(
  public.lsa_values_equal('0,33', '1/3', '{"mode":"absolute","value":0.01}'::jsonb),
  'tolerance absolute: 0,33 liegt nah genug an 1/3'
);

select ok(
  not public.lsa_values_equal('0,33', '1/3', '{"mode":"exact"}'::jsonb),
  'tolerance exact: 0,33 ist NICHT 1/3'
);

select ok(
  public.lsa_values_equal('0,33', '1/3', '{"mode":"decimals","value":2}'::jsonb),
  'tolerance decimals: auf 2 Stellen gerundet gleich'
);

-- --- Kuerzung ---------------------------------------------------------------

select ok(public.lsa_is_reduced('11/12'), '11/12 ist gekuerzt');
select ok(not public.lsa_is_reduced('22/24'), '22/24 ist NICHT gekuerzt');
select ok(public.lsa_is_reduced('3/2'), '3/2 ist gekuerzt (unecht, aber gekuerzt)');
select ok(not public.lsa_is_reduced('1 2/4'), 'Gemischt: der Bruchteil 2/4 ist nicht gekuerzt');
select ok(public.lsa_is_reduced('0,50'), 'Dezimalzahlen haben nichts zu kuerzen');

-- --- B) Die Zwischenstufe ---------------------------------------------------

-- Die Regel: kanonisch 11/12, Kuerzung verlangt.
select is(
  public.lsa_grade(
    'SHORT_TEXT',
    '{"canonical":"11/12","require_reduced":true}'::jsonb,
    '["11/12"]'::jsonb,
    '{"text":"11/12"}'::jsonb),
  'voll',
  'Gekuerzt und wertgleich → voll'
);

select is(
  public.lsa_grade(
    'SHORT_TEXT',
    '{"canonical":"11/12","require_reduced":true}'::jsonb,
    '["11/12"]'::jsonb,
    '{"text":"22/24"}'::jsonb),
  'teilweise',
  'Wertgleich, aber ungekuerzt → teilweise (DIE Zwischenstufe)'
);

select is(
  public.lsa_grade(
    'SHORT_TEXT',
    '{"canonical":"11/12"}'::jsonb,
    '["11/12"]'::jsonb,
    '{"text":"22/24"}'::jsonb),
  'voll',
  'Ohne require_reduced bleibt ungekuerzt voll — die Verschaerfung wird bestellt'
);

select is(
  public.lsa_grade(
    'SHORT_TEXT',
    '{"canonical":"11/12","require_reduced":true}'::jsonb,
    '["11/12"]'::jsonb,
    '{"text":"3/7"}'::jsonb),
  'nicht',
  'Falsch gerechnet bleibt nicht — teilweise ist keine Trostrunde'
);

-- Einheit als Kompetenz: "150 cm" ist dieselbe Laenge, aber gefragt war m.
select is(
  public.lsa_grade(
    'NUMERIC',
    '{"canonical":"1,5 m","equivalents":["150 cm"],"unit":"m","unit_graded":true}'::jsonb,
    '["1,5 m"]'::jsonb,
    '{"value":"150 cm"}'::jsonb),
  'nicht',
  'unit_graded: das Aequivalent in cm zaehlt nicht mit'
);

select is(
  public.lsa_grade(
    'NUMERIC',
    '{"canonical":"1,5 m","equivalents":["150 cm"],"unit":"m"}'::jsonb,
    '["1,5 m"]'::jsonb,
    '{"value":"150 cm"}'::jsonb),
  'voll',
  'Ohne unit_graded zaehlt das Aequivalent — die Einheit ist nicht die Kompetenz'
);

select is(
  public.lsa_grade(
    'NUMERIC',
    '{"canonical":"1,5 m","unit":"m","unit_graded":true}'::jsonb,
    '["1,5 m"]'::jsonb,
    '{"value":"1,5"}'::jsonb),
  'teilweise',
  'unit_graded: Wert richtig, Einheit fehlt → teilweise'
);

-- --- C) Keine Regression ----------------------------------------------------

select is(
  public.lsa_grade('SHORT_TEXT', null, '["11/12"]'::jsonb, '{"text":"11/12"}'::jsonb),
  'voll',
  'Ohne acceptance: Treffer wie bisher → voll'
);

select is(
  public.lsa_grade('SHORT_TEXT', null, '["11/12"]'::jsonb, '{"text":"22/24"}'::jsonb),
  'nicht',
  'Ohne acceptance KEIN teilweise — Bestandsaufgaben bewerten wie vor A11'
);

select is(
  public.lsa_grade('MC', '{"canonical":"b"}'::jsonb, '["b"]'::jsonb,
                   '{"selected":["b"]}'::jsonb),
  'voll',
  'MC bleibt binaer — die Abstufung dort ist option_scores, nicht lsa_grade'
);

-- --- D) Robustheit ----------------------------------------------------------

select is(
  public.lsa_grade('SHORT_TEXT', '{"canonical":"11/12","require_reduced":true}'::jsonb,
                   '["11/12"]'::jsonb, '{"text":"keine ahnung"}'::jsonb),
  'nicht',
  'Unlesbare Antwort wirft nicht, sie faellt durch'
);

select * from finish();
rollback;
