-- K8-Charge 1, Teil 2 — 24 Aufgaben zu den vier binomischen Skills aus #150.
--
-- Sechs je Skill: vier reine Anwendung mit steigendem Anspruch, zwei mit
-- Sachkontext oder Rueckrichtung. Keine Abbildungen (needs_image false), keine
-- neuen Antwortformate, kein Eingriff in Bestandszeilen. status bleibt draft.
--
-- ============================================================================
-- Vier Befunde aus der Datenbank, die von der Charge abweichen
-- ============================================================================
--
-- 1. afb ist 'I' | 'II' | 'III', nicht 1 | 2 | 3.
--      tasks_afb_check CHECK (afb = ANY (ARRAY['I','II','III']))
--    Bestand: I 313, II 146, III 13.
--
-- 2. Es gibt KEINE Spalte known_errors. Die Zuordnung falscher Wert -> Slug
--    liegt in task_solutions.acceptance -> 'known_errors'; genau dort liest
--    lsa_fehlbild_match sie. Objektform gibt den Slug zurueck, Arrayform nur
--    den generischen Marker '__known__'. In Prod: 302 Zeilen mit known_errors,
--    ausnahmslos Objektform. task_solutions.typical_errors ist in allen 581
--    Zeilen ein leeres Array und wird von keiner Funktion ausgewertet.
--
-- 3. Das Antwortformat ist MC, nicht TERM — erzwungen von einem Trigger.
--    lsa_term_acceptance_guard (A13) haengt an task_solutions und tasks und
--    verbietet einer TERM-Aufgabe JEDES acceptance:
--      'TERM-Aufgabe % darf kein acceptance tragen — der Wert-Einheit-Pfad
--       kann Terme nicht bewerten'
--    Da acceptance der einzige Ort ist, an dem Fehlbilder liegen koennen, kann
--    eine TERM-Aufgabe grundsaetzlich kein Fehlbild tragen. lsa_fehlbild_match
--    hat zwar einen TERM-Zweig (v_term, lsa_normalize_term) — der bekommt aber
--    nie Daten. Gegen Prod belegt: known_errors nach input_type ist NUMERIC 302,
--    TERM 0, MC 0; TERM-Aufgaben mit acceptance: 0.
--
--    Der Bestand loest das an der anspruchsvollsten Term-Aufgabe genauso:
--    term_ausklammern ist MC, nicht TERM, und traegt die Denkfehler in den
--    Distraktoren ("2(2x + 4)" ist unvollstaendiges Faktorisieren). Dort bleibt
--    acceptance allerdings leer, der Slug wird also weggeworfen. Diese Charge
--    haengt ihn an: known_errors bildet Options-id -> Slug ab.
--
--    Zwei Aufgaben bleiben NUMERIC (geschicktes Rechnen), weil dort eine Zahl
--    die natuerliche Antwort ist und NUMERIC der einzige Pfad ist, den die
--    Fehlbild-Erfassung im Bestand nachweislich schon bedient.
--
-- 4. lsa_normalize_term senkt nur Gross-/Kleinschreibung und entfernt Leerraum
--    ('x^2+6x+9' und 'x²+6x+9' sind VERSCHIEDEN, die Reihenfolge wird nicht
--    normiert). Fuer MC ist das folgenlos — die Antwort ist eine Options-id.
--    Fuer eine kuenftige TERM-Charge waere es die naechste Huerde.
--
-- ============================================================================
-- Warum begin/commit IN der Datei steht
-- ============================================================================
-- scripts/db-migrate.sh ruft psql ohne --single-transaction. Zwischen tasks und
-- task_solutions liegt eine Abhaengigkeit; ein Abbruch dazwischen liesse
-- Aufgaben ohne Loesung stehen — still, und erst im Betrieb sichtbar.
--
-- cluster_id als Unterabfrage statt fester UUID, wie in
-- 20260814140000_p5_gleichung_modellieren_item1: skill_clusters wird per Skript
-- geseedet (npm run seed:clusters), nicht per Migration. In einer leeren
-- Datenbank (tools/neuaufbau-test.sh) bleibt cluster_id daher null. Das ist die
-- Seed-Reihenfolge, kein Fehler.

begin;

with neu (
  source_ref, skill_key, afb, input_type, sondierrang,
  titel, frage, comp_process, optionen, antworten, fehlbilder
) as (
  values

  -- ══ term_binom_quadrat ════════════════════════════════════════════════════
  -- 01-04 reine Anwendung, aufsteigend: x -> x mit Minus -> Koeffizient ->
  -- Koeffizient mit Minus. 05 Sachkontext, 06 Rueckrichtung.

  ('binom-quadrat-01', 'term_binom_quadrat', 'I', 'MC', null::integer,
   'Binomische Formel · Quadrat · (x + 3)²',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(x + 3)² = ?',
   'Operieren',
   '[{"id":"a","label":"x² + 9"},
     {"id":"b","label":"x² + 3x + 9"},
     {"id":"c","label":"x² + 6x + 9"},
     {"id":"d","label":"x² + 6x + 6"}]'::jsonb,
   '["c"]'::jsonb,
   '{"a":"quadrat_gliedweise"}'::jsonb),

  ('binom-quadrat-02', 'term_binom_quadrat', 'I', 'MC', 1,
   'Binomische Formel · Quadrat · (x - 5)²',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(x - 5)² = ?',
   'Operieren',
   '[{"id":"a","label":"x² + 25"},
     {"id":"b","label":"x² - 10x + 25"},
     {"id":"c","label":"x² + 10x + 25"},
     {"id":"d","label":"x² - 10x - 25"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadrat_gliedweise","c":"falsches_vorzeichen_beim_zusammenfuehren"}'::jsonb),

  ('binom-quadrat-03', 'term_binom_quadrat', 'II', 'MC', null,
   'Binomische Formel · Quadrat · (2x + 3)²',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(2x + 3)² = ?',
   'Operieren',
   '[{"id":"a","label":"4x² + 12x + 9"},
     {"id":"b","label":"4x² + 9"},
     {"id":"c","label":"2x² + 12x + 9"},
     {"id":"d","label":"4x² + 6x + 9"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadrat_gliedweise"}'::jsonb),

  ('binom-quadrat-04', 'term_binom_quadrat', 'II', 'MC', null,
   'Binomische Formel · Quadrat · (3x - 4)²',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(3x - 4)² = ?',
   'Operieren',
   '[{"id":"a","label":"9x² + 16"},
     {"id":"b","label":"9x² + 24x + 16"},
     {"id":"c","label":"9x² - 24x - 16"},
     {"id":"d","label":"9x² - 24x + 16"}]'::jsonb,
   '["d"]'::jsonb,
   '{"a":"quadrat_gliedweise","b":"falsches_vorzeichen_beim_zusammenfuehren"}'::jsonb),

  ('binom-quadrat-05', 'term_binom_quadrat', 'II', 'MC', null,
   'Binomische Formel · Sachkontext · quadratisches Beet',
   E'Ein quadratisches Beet hat die Seitenlänge (x + 4) Meter.\nWelcher Term gibt den Flächeninhalt an?',
   'Modellieren, Operieren',
   '[{"id":"a","label":"x² + 8x + 16"},
     {"id":"b","label":"x² + 16"},
     {"id":"c","label":"4x + 16"},
     {"id":"d","label":"x² + 4x + 16"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadrat_gliedweise"}'::jsonb),

  ('binom-quadrat-06', 'term_binom_quadrat', 'III', 'MC', 2,
   'Binomische Formel · Rückrichtung · x² + 20x + 100',
   E'Schreibe als Quadrat einer Klammer. Welcher Term ist richtig?\n\nx² + 20x + 100 = ?',
   'Problemlösen, Operieren',
   '[{"id":"a","label":"(x + 20)²"},
     {"id":"b","label":"(x + 10)²"},
     {"id":"c","label":"(x + 100)²"},
     {"id":"d","label":"(x + 10)(x - 10)"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadrat_gliedweise"}'::jsonb),

  -- ══ term_binom_quadratdifferenz ═══════════════════════════════════════════

  ('binom-quadratdiff-01', 'term_binom_quadratdifferenz', 'I', 'MC', null,
   'Dritte binomische Formel · (x + 4)(x - 4)',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(x + 4)(x - 4) = ?',
   'Operieren',
   '[{"id":"a","label":"x² - 16"},
     {"id":"b","label":"x² + 16"},
     {"id":"c","label":"x² - 8x - 16"},
     {"id":"d","label":"x² - 4x - 16"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-quadratdiff-02', 'term_binom_quadratdifferenz', 'I', 'MC', null,
   'Dritte binomische Formel · (x - 7)(x + 7)',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(x - 7)(x + 7) = ?',
   'Operieren',
   '[{"id":"a","label":"x² + 49"},
     {"id":"b","label":"x² - 14x + 49"},
     {"id":"c","label":"x² - 49"},
     {"id":"d","label":"x² - 14x - 49"}]'::jsonb,
   '["c"]'::jsonb,
   '{"a":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-quadratdiff-03', 'term_binom_quadratdifferenz', 'II', 'MC', null,
   'Dritte binomische Formel · (3x + 5)(3x - 5)',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(3x + 5)(3x - 5) = ?',
   'Operieren',
   '[{"id":"a","label":"9x² - 25"},
     {"id":"b","label":"9x² + 25"},
     {"id":"c","label":"3x² - 25"},
     {"id":"d","label":"9x² - 30x - 25"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-quadratdiff-04', 'term_binom_quadratdifferenz', 'II', 'MC', null,
   'Dritte binomische Formel · (2x - 9)(2x + 9)',
   E'Multipliziere aus. Welcher Term ist richtig?\n\n(2x - 9)(2x + 9) = ?',
   'Operieren',
   '[{"id":"a","label":"4x² - 36x - 81"},
     {"id":"b","label":"4x² + 81"},
     {"id":"c","label":"2x² - 81"},
     {"id":"d","label":"4x² - 81"}]'::jsonb,
   '["d"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-quadratdiff-05', 'term_binom_quadratdifferenz', 'II', 'NUMERIC', 2,
   'Dritte binomische Formel · geschicktes Rechnen · 102 · 98',
   E'Berechne geschickt mit einer binomischen Formel.\n\n102 · 98 = ?',
   'Problemlösen, Operieren',
   null::jsonb,
   '["9996"]'::jsonb,
   '{"10004":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-quadratdiff-06', 'term_binom_quadratdifferenz', 'III', 'MC', 1,
   'Dritte binomische Formel · Sachkontext · Grundstück',
   E'Ein quadratisches Grundstück hat die Seitenlänge x Meter. Eine Seite wird um 5 Meter verlängert, die andere um 5 Meter verkürzt.\nWelcher Term gibt den Flächeninhalt des neuen Rechtecks an?',
   'Modellieren, Operieren',
   '[{"id":"a","label":"x²"},
     {"id":"b","label":"x² + 25"},
     {"id":"c","label":"x² - 25"},
     {"id":"d","label":"x² - 10x - 25"}]'::jsonb,
   '["c"]'::jsonb,
   '{"a":"differenz_ignoriert","b":"quadratdifferenz_vorzeichen"}'::jsonb),

  -- ══ term_binom_faktorisieren ══════════════════════════════════════════════

  ('binom-faktor-01', 'term_binom_faktorisieren', 'I', 'MC', null,
   'Faktorisieren · Differenz von Quadraten · x² - 25',
   E'Schreibe als Produkt zweier Klammern. Welcher Term ist richtig?\n\nx² - 25 = ?',
   'Operieren',
   '[{"id":"a","label":"(x + 5)(x - 5)"},
     {"id":"b","label":"(x - 5)(x - 5)"},
     {"id":"c","label":"(x + 5)(x + 5)"},
     {"id":"d","label":"(x + 25)(x - 1)"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen","c":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-faktor-02', 'term_binom_faktorisieren', 'I', 'MC', null,
   'Faktorisieren · vollständiges Quadrat · x² + 8x + 16',
   E'Schreibe als Quadrat einer Klammer. Welcher Term ist richtig?\n\nx² + 8x + 16 = ?',
   'Operieren',
   '[{"id":"a","label":"(x + 8)²"},
     {"id":"b","label":"(x + 4)²"},
     {"id":"c","label":"(x + 16)²"},
     {"id":"d","label":"(x + 4)(x - 4)"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadrat_gliedweise"}'::jsonb),

  ('binom-faktor-03', 'term_binom_faktorisieren', 'II', 'MC', 1,
   'Faktorisieren · gemeinsamer Faktor zuerst · 2x² - 18',
   E'Faktorisiere vollständig. Welcher Term ist richtig?\n\n2x² - 18 = ?',
   'Operieren',
   '[{"id":"a","label":"2(x² - 9)"},
     {"id":"b","label":"2(x + 3)(x - 3)"},
     {"id":"c","label":"2(x - 3)(x - 3)"},
     {"id":"d","label":"(2x + 3)(2x - 3)"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"faktorisierung_unvollstaendig","c":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-faktor-04', 'term_binom_faktorisieren', 'II', 'MC', null,
   'Faktorisieren · gemeinsamer Faktor und Quadrat · 3x² + 12x + 12',
   E'Faktorisiere vollständig. Welcher Term ist richtig?\n\n3x² + 12x + 12 = ?',
   'Operieren',
   '[{"id":"a","label":"3(x² + 4x + 4)"},
     {"id":"b","label":"3(x + 4)²"},
     {"id":"c","label":"3(x + 2)²"},
     {"id":"d","label":"(3x + 6)²"}]'::jsonb,
   '["c"]'::jsonb,
   '{"a":"faktorisierung_unvollstaendig"}'::jsonb),

  ('binom-faktor-05', 'term_binom_faktorisieren', 'III', 'MC', null,
   'Faktorisieren · zweistufig · x⁴ - 16',
   E'Faktorisiere vollständig. Welcher Term ist richtig?\n\nx⁴ - 16 = ?',
   'Problemlösen, Operieren',
   '[{"id":"a","label":"(x² + 4)(x² - 4)"},
     {"id":"b","label":"(x² + 4)(x + 2)(x - 2)"},
     {"id":"c","label":"(x² - 4)(x² - 4)"},
     {"id":"d","label":"(x + 2)⁴"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"faktorisierung_unvollstaendig"}'::jsonb),

  ('binom-faktor-06', 'term_binom_faktorisieren', 'II', 'NUMERIC', 2,
   'Faktorisieren · geschicktes Rechnen · 47² - 43²',
   E'Berechne geschickt mit einer binomischen Formel.\n\n47² - 43² = ?',
   'Problemlösen, Operieren',
   null::jsonb,
   '["360"]'::jsonb,
   '{"16":"quadrat_gliedweise","90":"faktorisierung_unvollstaendig"}'::jsonb),

  -- ══ term_binom_gemischt ═══════════════════════════════════════════════════

  ('binom-gemischt-01', 'term_binom_gemischt', 'II', 'MC', 2,
   'Gemischt · zwei Quadrate · (x + 3)² - (x - 3)²',
   E'Multipliziere aus und fasse zusammen. Welcher Term ist richtig?\n\n(x + 3)² - (x - 3)² = ?',
   'Operieren',
   '[{"id":"a","label":"0"},
     {"id":"b","label":"18"},
     {"id":"c","label":"12x"},
     {"id":"d","label":"2x² + 18"}]'::jsonb,
   '["c"]'::jsonb,
   '{"a":"quadrat_gliedweise","b":"klammer_vergessen"}'::jsonb),

  ('binom-gemischt-02', 'term_binom_gemischt', 'II', 'MC', 1,
   'Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2)',
   E'Multipliziere aus und fasse zusammen. Welcher Term ist richtig?\n\n(x + 5)² - (x + 2)(x - 2) = ?',
   'Operieren',
   '[{"id":"a","label":"10x + 29"},
     {"id":"b","label":"10x + 21"},
     {"id":"c","label":"29"},
     {"id":"d","label":"2x² + 10x + 21"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen","c":"quadrat_gliedweise"}'::jsonb),

  ('binom-gemischt-03', 'term_binom_gemischt', 'II', 'MC', null,
   'Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)²',
   E'Multipliziere aus und fasse zusammen. Welcher Term ist richtig?\n\n(x + 6)(x - 6) + (x + 2)² = ?',
   'Operieren',
   '[{"id":"a","label":"2x² + 4x + 40"},
     {"id":"b","label":"2x² + 4x - 32"},
     {"id":"c","label":"2x² - 32"},
     {"id":"d","label":"2x² + 4x - 40"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-gemischt-04', 'term_binom_gemischt', 'III', 'MC', null,
   'Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4)',
   E'Multipliziere aus und fasse zusammen. Welcher Term ist richtig?\n\n(3x - 2)² - (x + 4)(x - 4) = ?',
   'Problemlösen, Operieren',
   '[{"id":"a","label":"8x² - 12x + 20"},
     {"id":"b","label":"8x² - 12x - 12"},
     {"id":"c","label":"10x² - 12x + 20"},
     {"id":"d","label":"8x² - 12x - 20"}]'::jsonb,
   '["a"]'::jsonb,
   '{"b":"quadratdifferenz_vorzeichen"}'::jsonb),

  ('binom-gemischt-05', 'term_binom_gemischt', 'III', 'MC', null,
   'Gemischt · Sachkontext · Restfläche',
   E'Ein quadratisches Grundstück hat die Seitenlänge (x + 3) Meter. Davon wird ein quadratisches Beet mit der Seitenlänge (x - 1) Metern abgetrennt.\nWelcher Term gibt den Flächeninhalt der Restfläche an?',
   'Modellieren, Operieren',
   '[{"id":"a","label":"8"},
     {"id":"b","label":"8x + 8"},
     {"id":"c","label":"4x + 8"},
     {"id":"d","label":"2x² + 8x + 8"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadrat_gliedweise"}'::jsonb),

  ('binom-gemischt-06', 'term_binom_gemischt', 'II', 'MC', null,
   'Gemischt · vereinfachen · (x + 4)² - x² - 16',
   E'Vereinfache so weit wie möglich. Welcher Term ist richtig?\n\n(x + 4)² - x² - 16 = ?',
   'Operieren',
   '[{"id":"a","label":"0"},
     {"id":"b","label":"8x"},
     {"id":"c","label":"8x + 32"},
     {"id":"d","label":"8x - 32"}]'::jsonb,
   '["b"]'::jsonb,
   '{"a":"quadrat_gliedweise"}'::jsonb)

),
eingefuegt as (
  insert into public.tasks (
    content_type, title, question, question_payload, input_type, skill_key,
    class_level, curriculum_grade, cluster_id, afb,
    competency_content, competency_process,
    sondierrang, status, source, source_ref,
    is_diagnostic, is_active, needs_image, dialog_enabled, is_tutorial, parts, assets
  )
  select
    'exercise',
    n.titel,
    n.frage,
    -- question_payload haelt NUR die Frage (und bei MC die Optionen), niemals
    -- die Loesung: tasks_question_payload_no_solution verbietet die Schluessel
    -- correct/accepted/pairs/blanks/expected. Die Loesung liegt ausschliesslich
    -- in task_solutions. Formgleich zum Bestand (term_ausklammern fuer MC,
    -- afb1-geo-* fuer NUMERIC).
    case when n.input_type = 'MC'
         then jsonb_build_object('input_type', 'MC', 'options', n.optionen)
         else jsonb_build_object('kind', 'short_input', 'prompt', n.frage)
    end,
    n.input_type,
    n.skill_key,
    8, 8,
    (select c.id from public.skill_clusters c where c.name = 'Algebra & Funktionen' limit 1),
    n.afb,
    -- AM ITEM, nicht nur in parts[]: bei den zehn P5-Items blieb genau diese
    -- Spalte leer, und der Eltern-Report zeigte sie als "Ohne Zuordnung".
    -- 'arithmetik_algebra' ist ein im Bestand belegter Wert (301 Zeilen).
    'arithmetik_algebra',
    n.comp_process,
    n.sondierrang,
    'draft',
    'edvance_k8_binom',
    n.source_ref,
    false, true, false, false, false, '[]'::jsonb, '[]'::jsonb
  from neu n
  returning id, source_ref
)
insert into public.task_solutions (task_id, correct_answers, acceptance, hints, coach_hints, typical_errors)
select
  e.id,
  n.antworten,
  -- canonical = die richtige Antwort (Options-id bzw. Zahl); known_errors in
  -- Objektform, genau so liest lsa_fehlbild_match sie. Bei MC matcht sie ueber
  -- die gewaehlte Options-id, bei NUMERIC ueber den eingegebenen Wert.
  jsonb_build_object('canonical', n.antworten ->> 0, 'known_errors', n.fehlbilder),
  '[]'::jsonb, '[]'::jsonb, '[]'::jsonb
from eingefuegt e
join neu n on n.source_ref = e.source_ref;

commit;
