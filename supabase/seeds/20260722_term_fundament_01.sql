-- ============================================================================
-- Termumformung, Charge 01 — Fundament-Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/term_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/20260722_term_fundament_01.sql
--
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- ZWEI ANTWORTFORMATE:
--   Zusammenfassen / Ausmultiplizieren / Minusklammer  -> SHORT_TEXT, Form ax+b
--   Ausklammern                                        -> MC, afb II
--
-- KEIN acceptance-SATZ BEI DEN TERM-AUFGABEN — und das ist Absicht:
--
--   lsa_grade nimmt den Zahlen-Pfad, sobald acceptance ein 'canonical' hat.
--   Dort trennt lsa_split_value_unit "5x+4" in Wert "5" und Einheit "x+4" und
--   vergleicht nur den Wert. Live geprueft: mit canonical "5x+4" bewertet
--   lsa_grade die Antworten "5x+9", "5x+6", "5x-4" und "5x" ALLE als 'voll'.
--   Genau die Fehlbilder dieser Aufgaben faenden also volle Punkte.
--
--   Ohne acceptance faellt lsa_grade auf lsa_is_correct zurueck: normalisierter
--   String-Vergleich gegen correct_answers. Das ist fuer Terme das richtige
--   Verfahren — und das einzige, das hier korrekt urteilt.
--
--   FOLGE: known_errors ist fuer diese Aufgaben NICHT speicherbar. Es lebt in
--   acceptance, und lsa_acceptance_valid laesst es nur in einem Satz MIT
--   canonical zu (ohne canonical wird acceptance als Teilaufgaben-Abbildung
--   gelesen und der Schluessel 'known_errors' abgewiesen). Die Fehlbilder
--   stehen deshalb hier als Kommentar und in AUTONOMY_NOTES.md, nicht als
--   Daten. Sie zu erfinden waere ein zweiter Ort fuer Fehlerdiagnostik.
--
-- EXAKTER STRING-VERGLEICH: "4+5x" zaehlt NICHT als richtig, obwohl es
-- wertgleich ist. Deshalb steht die Zielform im Aufgabentext. In
-- correct_answers steht zusaetzlich die Schreibweise mit Leerzeichen, weil die
-- Abgabeform der App noch nicht gegengelesen ist.
--
-- SOLUTION-LEAK: Bei MC sind die OPTIONEN schuelerlesbar (question_payload,
-- ueber lsa_question_payload) — die richtige Option-Id steht in
-- task_solutions.correct_answers. Auf task_solutions hat weder anon noch
-- authenticated ein Grant (geprueft), nur service_role.
--
-- IDEMPOTENT ueber (source, source_ref).
--
-- ── DIE VARIANTEN UND IHRE FEHLBILDER ──────────────────────────────────────
--   term-zusammenfassen-01: 3x + 5 + 2x - 1 = ?  ->  5x+4
--       9x                     alles_addiert
--       5x+6                   vorzeichen_verloren
--       5x                     konstante_vergessen
--   term-zusammenfassen-02: 4x + 9 + 3x - 2 = ?  ->  7x+7
--       14x                    alles_addiert
--       7x+11                  vorzeichen_verloren
--       7x                     konstante_vergessen
--   term-zusammenfassen-03: 2x + 7 + 6x - 10 = ?  ->  8x-3
--       5x                     alles_addiert
--       8x+17                  vorzeichen_verloren
--       8x                     konstante_vergessen
--   term-zusammenfassen-04: 5x + 3 + 4x - 8 = ?  ->  9x-5
--       4x                     alles_addiert
--       9x+11                  vorzeichen_verloren
--       9x                     konstante_vergessen
--   term-zusammenfassen-05: 7x + 4 - 2x + 6 = ?  ->  5x+10
--       15x                    alles_addiert
--       9x+10                  vorzeichen_verloren
--       5x                     konstante_vergessen
--   term-zusammenfassen-06: 9x + 2 - 4x + 5 = ?  ->  5x+7
--       12x                    alles_addiert
--       13x+7                  vorzeichen_verloren
--       5x                     konstante_vergessen
--   term-zusammenfassen-07: 6x + 8 - 2x + 3 = ?  ->  4x+11
--       15x                    alles_addiert
--       8x+11                  vorzeichen_verloren
--       4x                     konstante_vergessen
--   term-ausmultiplizieren-01: 3(x + 2) = ?  ->  3x+6
--       3x+2                   faktor_nur_erstes_glied
--       3x+5                   addiert_statt_multipliziert
--   term-ausmultiplizieren-02: 4(x + 5) = ?  ->  4x+20
--       4x+5                   faktor_nur_erstes_glied
--       4x+9                   addiert_statt_multipliziert
--   term-ausmultiplizieren-03: 5(x - 3) = ?  ->  5x-15
--       5x-3                   faktor_nur_erstes_glied
--       5x+2                   addiert_statt_multipliziert
--   term-ausmultiplizieren-04: -3(x + 2) = ?  ->  -3x-6
--       -3x+2                  faktor_nur_erstes_glied
--       -3x-1                  addiert_statt_multipliziert
--       -3x+6                  vorzeichen_bei_negativem_faktor
--   term-ausmultiplizieren-05: -2(x + 7) = ?  ->  -2x-14
--       -2x+7                  faktor_nur_erstes_glied
--       -2x+5                  addiert_statt_multipliziert
--       -2x+14                 vorzeichen_bei_negativem_faktor
--   term-ausmultiplizieren-06: -4(x - 3) = ?  ->  -4x+12
--       -4x-3                  faktor_nur_erstes_glied
--       -4x-7                  addiert_statt_multipliziert
--       -4x-12                 vorzeichen_bei_negativem_faktor
--   term-ausmultiplizieren-07: 6(x + 4) = ?  ->  6x+24
--       6x+4                   faktor_nur_erstes_glied
--       6x+10                  addiert_statt_multipliziert
--   term-ausklammern-01: 4x + 8 = ?  richtig = d) 4(x + 2)
--       2(2x + 4)              nicht_vollstaendig
--       4(x + 8)               nur_erstes_geteilt
--       4(x + 4)               falsch_geteilt
--   term-ausklammern-02: 6x + 12 = ?  richtig = c) 6(x + 2)
--       6(x + 12)              nur_erstes_geteilt
--       6(x + 4)               falsch_geteilt
--       3(2x + 4)              nicht_vollstaendig
--   term-ausklammern-03: 4x + 20 = ?  richtig = b) 4(x + 5)
--       4(x + 10)              falsch_geteilt
--       2(2x + 10)             nicht_vollstaendig
--       4(x + 20)              nur_erstes_geteilt
--   term-ausklammern-04: 9x + 27 = ?  richtig = a) 9(x + 3)
--       3(3x + 9)              nicht_vollstaendig
--       9(x + 27)              nur_erstes_geteilt
--       9(x + 9)               falsch_geteilt
--   term-ausklammern-05: 8x + 12 = ?  richtig = d) 4(2x + 3)
--       2(4x + 6)              nicht_vollstaendig
--       4(2x + 12)             nur_erstes_geteilt
--       4(2x + 6)              falsch_geteilt
--   term-ausklammern-06: 12x + 18 = ?  richtig = c) 6(2x + 3)
--       6(2x + 18)             nur_erstes_geteilt
--       6(2x + 6)              falsch_geteilt
--       3(4x + 6)              nicht_vollstaendig
--   term-minusklammer-01: 5 - (2x - 3) = ?  ->  -2x+8
--       -2x+2                  klammer_nicht_aufgeloest
--       2x+2                   beide_vorzeichen_behalten
--   term-minusklammer-02: 9 - (3x - 4) = ?  ->  -3x+13
--       -3x+5                  klammer_nicht_aufgeloest
--       3x+5                   beide_vorzeichen_behalten
--   term-minusklammer-03: 7 - (4x - 2) = ?  ->  -4x+9
--       -4x+5                  klammer_nicht_aufgeloest
--       4x+5                   beide_vorzeichen_behalten
--   term-minusklammer-04: 2 - (5x - 6) = ?  ->  -5x+8
--       -5x-4                  klammer_nicht_aufgeloest
--       5x-4                   beide_vorzeichen_behalten
--   term-minusklammer-05: 10 - (6x - 1) = ?  ->  -6x+11
--       -6x+9                  klammer_nicht_aufgeloest
--       6x+9                   beide_vorzeichen_behalten
--   term-minusklammer-06: 4 - (7x - 9) = ?  ->  -7x+13
--       -7x-5                  klammer_nicht_aufgeloest
--       7x-5                   beide_vorzeichen_behalten

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
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', v.input_type, 'draft', true, false,
  v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.payload
from (values
  ('term-zusammenfassen-01', 'Terme · Zusammenfassen · 3x + 5 + 2x - 1', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

3x + 5 + 2x - 1 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

3x + 5 + 2x - 1 = ?')),
  ('term-zusammenfassen-02', 'Terme · Zusammenfassen · 4x + 9 + 3x - 2', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

4x + 9 + 3x - 2 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

4x + 9 + 3x - 2 = ?')),
  ('term-zusammenfassen-03', 'Terme · Zusammenfassen · 2x + 7 + 6x - 10', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

2x + 7 + 6x - 10 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

2x + 7 + 6x - 10 = ?')),
  ('term-zusammenfassen-04', 'Terme · Zusammenfassen · 5x + 3 + 4x - 8', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

5x + 3 + 4x - 8 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

5x + 3 + 4x - 8 = ?')),
  ('term-zusammenfassen-05', 'Terme · Zusammenfassen · 7x + 4 - 2x + 6', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

7x + 4 - 2x + 6 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

7x + 4 - 2x + 6 = ?')),
  ('term-zusammenfassen-06', 'Terme · Zusammenfassen · 9x + 2 - 4x + 5', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

9x + 2 - 4x + 5 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

9x + 2 - 4x + 5 = ?')),
  ('term-zusammenfassen-07', 'Terme · Zusammenfassen · 6x + 8 - 2x + 3', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

6x + 8 - 2x + 3 = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Fasse zusammen. Gib das Ergebnis in der Form ax + b an.

6x + 8 - 2x + 3 = ?')),
  ('term-ausmultiplizieren-01', 'Terme · Ausmultiplizieren · 3(x + 2)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

3(x + 2) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

3(x + 2) = ?')),
  ('term-ausmultiplizieren-02', 'Terme · Ausmultiplizieren · 4(x + 5)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

4(x + 5) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

4(x + 5) = ?')),
  ('term-ausmultiplizieren-03', 'Terme · Ausmultiplizieren · 5(x - 3)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

5(x - 3) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

5(x - 3) = ?')),
  ('term-ausmultiplizieren-04', 'Terme · Ausmultiplizieren · -3(x + 2)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-3(x + 2) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-3(x + 2) = ?')),
  ('term-ausmultiplizieren-05', 'Terme · Ausmultiplizieren · -2(x + 7)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-2(x + 7) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-2(x + 7) = ?')),
  ('term-ausmultiplizieren-06', 'Terme · Ausmultiplizieren · -4(x - 3)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-4(x - 3) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

-4(x - 3) = ?')),
  ('term-ausmultiplizieren-07', 'Terme · Ausmultiplizieren · 6(x + 4)', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

6(x + 4) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.

6(x + 4) = ?')),
  ('term-ausklammern-01', 'Terme · Ausklammern · 4x + 8', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

4x + 8 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "2(2x + 4)"}, {"id": "b", "label": "4(x + 8)"}, {"id": "c", "label": "4(x + 4)"}, {"id": "d", "label": "4(x + 2)"}]'::jsonb)),
  ('term-ausklammern-02', 'Terme · Ausklammern · 6x + 12', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

6x + 12 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "6(x + 12)"}, {"id": "b", "label": "6(x + 4)"}, {"id": "c", "label": "6(x + 2)"}, {"id": "d", "label": "3(2x + 4)"}]'::jsonb)),
  ('term-ausklammern-03', 'Terme · Ausklammern · 4x + 20', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

4x + 20 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "4(x + 10)"}, {"id": "b", "label": "4(x + 5)"}, {"id": "c", "label": "2(2x + 10)"}, {"id": "d", "label": "4(x + 20)"}]'::jsonb)),
  ('term-ausklammern-04', 'Terme · Ausklammern · 9x + 27', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

9x + 27 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "9(x + 3)"}, {"id": "b", "label": "3(3x + 9)"}, {"id": "c", "label": "9(x + 27)"}, {"id": "d", "label": "9(x + 9)"}]'::jsonb)),
  ('term-ausklammern-05', 'Terme · Ausklammern · 8x + 12', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

8x + 12 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "2(4x + 6)"}, {"id": "b", "label": "4(2x + 12)"}, {"id": "c", "label": "4(2x + 6)"}, {"id": "d", "label": "4(2x + 3)"}]'::jsonb)),
  ('term-ausklammern-06', 'Terme · Ausklammern · 12x + 18', 'Klammere so weit wie möglich aus. Welcher Term ist richtig?

12x + 18 = ?', 'MC', 'II', jsonb_build_object('input_type', 'MC', 'options', '[{"id": "a", "label": "6(2x + 18)"}, {"id": "b", "label": "6(2x + 6)"}, {"id": "c", "label": "6(2x + 3)"}, {"id": "d", "label": "3(4x + 6)"}]'::jsonb)),
  ('term-minusklammer-01', 'Terme · Minusklammer · 5 - (2x - 3)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

5 - (2x - 3) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

5 - (2x - 3) = ?')),
  ('term-minusklammer-02', 'Terme · Minusklammer · 9 - (3x - 4)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

9 - (3x - 4) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

9 - (3x - 4) = ?')),
  ('term-minusklammer-03', 'Terme · Minusklammer · 7 - (4x - 2)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

7 - (4x - 2) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

7 - (4x - 2) = ?')),
  ('term-minusklammer-04', 'Terme · Minusklammer · 2 - (5x - 6)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

2 - (5x - 6) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

2 - (5x - 6) = ?')),
  ('term-minusklammer-05', 'Terme · Minusklammer · 10 - (6x - 1)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

10 - (6x - 1) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

10 - (6x - 1) = ?')),
  ('term-minusklammer-06', 'Terme · Minusklammer · 4 - (7x - 9)', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

4 - (7x - 9) = ?', 'SHORT_TEXT', 'I', jsonb_build_object('kind', 'short_input', 'prompt', 'Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an.

4 - (7x - 9) = ?'))
) as v(source_ref, titel, frage, input_type, afb, payload)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung (Server-Only-Zone) ──────────────────────────────────────────
--
-- Bei MC ist der Eintrag die Option-Id, bei den Term-Aufgaben der Antwortstring
-- in beiden Schreibweisen. acceptance bleibt NULL — Begruendung im Kopf.

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, null, now()
from (values
  ('term-zusammenfassen-01', '["5x+4", "5x + 4"]'),
  ('term-zusammenfassen-02', '["7x+7", "7x + 7"]'),
  ('term-zusammenfassen-03', '["8x-3", "8x - 3"]'),
  ('term-zusammenfassen-04', '["9x-5", "9x - 5"]'),
  ('term-zusammenfassen-05', '["5x+10", "5x + 10"]'),
  ('term-zusammenfassen-06', '["5x+7", "5x + 7"]'),
  ('term-zusammenfassen-07', '["4x+11", "4x + 11"]'),
  ('term-ausmultiplizieren-01', '["3x+6", "3x + 6"]'),
  ('term-ausmultiplizieren-02', '["4x+20", "4x + 20"]'),
  ('term-ausmultiplizieren-03', '["5x-15", "5x - 15"]'),
  ('term-ausmultiplizieren-04', '["-3x-6", "-3x - 6"]'),
  ('term-ausmultiplizieren-05', '["-2x-14", "-2x - 14"]'),
  ('term-ausmultiplizieren-06', '["-4x+12", "-4x + 12"]'),
  ('term-ausmultiplizieren-07', '["6x+24", "6x + 24"]'),
  ('term-ausklammern-01', '["d"]'),
  ('term-ausklammern-02', '["c"]'),
  ('term-ausklammern-03', '["b"]'),
  ('term-ausklammern-04', '["a"]'),
  ('term-ausklammern-05', '["d"]'),
  ('term-ausklammern-06', '["c"]'),
  ('term-minusklammer-01', '["-2x+8", "-2x + 8"]'),
  ('term-minusklammer-02', '["-3x+13", "-3x + 13"]'),
  ('term-minusklammer-03', '["-4x+9", "-4x + 9"]'),
  ('term-minusklammer-04', '["-5x+8", "-5x + 8"]'),
  ('term-minusklammer-05', '["-6x+11", "-6x + 11"]'),
  ('term-minusklammer-06', '["-7x+13", "-7x + 13"]')
) as v(source_ref, correct_answers)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Selbsttest: urteilt lsa_grade so, wie die Didaktik es will? ─────────
--
-- Das Generator-Skript kennt die Bewertungsfunktion nicht und baut sie nicht
-- nach. Es fragt hier die Datenbank:
--
--   jede akzeptierte Schreibweise der Loesung -> 'voll'
--   jedes Fehlbild                            -> 'nicht'
--   bei MC: die richtige Option-Id            -> 'voll', jede andere -> 'nicht'
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- eingespielt.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
  v_anzahl int;
begin
  for r in
    select * from (values
      ('term-zusammenfassen-01', '5x+4', 'voll', 'kanonisch'),
      ('term-zusammenfassen-01', '5x + 4', 'voll', 'kanonisch'),
      ('term-zusammenfassen-01', '9x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-01', '5x+6', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-01', '5x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-02', '7x+7', 'voll', 'kanonisch'),
      ('term-zusammenfassen-02', '7x + 7', 'voll', 'kanonisch'),
      ('term-zusammenfassen-02', '14x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-02', '7x+11', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-02', '7x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-03', '8x-3', 'voll', 'kanonisch'),
      ('term-zusammenfassen-03', '8x - 3', 'voll', 'kanonisch'),
      ('term-zusammenfassen-03', '5x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-03', '8x+17', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-03', '8x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-04', '9x-5', 'voll', 'kanonisch'),
      ('term-zusammenfassen-04', '9x - 5', 'voll', 'kanonisch'),
      ('term-zusammenfassen-04', '4x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-04', '9x+11', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-04', '9x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-05', '5x+10', 'voll', 'kanonisch'),
      ('term-zusammenfassen-05', '5x + 10', 'voll', 'kanonisch'),
      ('term-zusammenfassen-05', '15x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-05', '9x+10', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-05', '5x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-06', '5x+7', 'voll', 'kanonisch'),
      ('term-zusammenfassen-06', '5x + 7', 'voll', 'kanonisch'),
      ('term-zusammenfassen-06', '12x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-06', '13x+7', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-06', '5x', 'nicht', 'konstante_vergessen'),
      ('term-zusammenfassen-07', '4x+11', 'voll', 'kanonisch'),
      ('term-zusammenfassen-07', '4x + 11', 'voll', 'kanonisch'),
      ('term-zusammenfassen-07', '15x', 'nicht', 'alles_addiert'),
      ('term-zusammenfassen-07', '8x+11', 'nicht', 'vorzeichen_verloren'),
      ('term-zusammenfassen-07', '4x', 'nicht', 'konstante_vergessen'),
      ('term-ausmultiplizieren-01', '3x+6', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-01', '3x + 6', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-01', '3x+2', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-01', '3x+5', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-02', '4x+20', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-02', '4x + 20', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-02', '4x+5', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-02', '4x+9', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-03', '5x-15', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-03', '5x - 15', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-03', '5x-3', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-03', '5x+2', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-04', '-3x-6', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-04', '-3x - 6', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-04', '-3x+2', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-04', '-3x-1', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-04', '-3x+6', 'nicht', 'vorzeichen_bei_negativem_faktor'),
      ('term-ausmultiplizieren-05', '-2x-14', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-05', '-2x - 14', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-05', '-2x+7', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-05', '-2x+5', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-05', '-2x+14', 'nicht', 'vorzeichen_bei_negativem_faktor'),
      ('term-ausmultiplizieren-06', '-4x+12', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-06', '-4x + 12', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-06', '-4x-3', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-06', '-4x-7', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausmultiplizieren-06', '-4x-12', 'nicht', 'vorzeichen_bei_negativem_faktor'),
      ('term-ausmultiplizieren-07', '6x+24', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-07', '6x + 24', 'voll', 'kanonisch'),
      ('term-ausmultiplizieren-07', '6x+4', 'nicht', 'faktor_nur_erstes_glied'),
      ('term-ausmultiplizieren-07', '6x+10', 'nicht', 'addiert_statt_multipliziert'),
      ('term-ausklammern-01', 'd', 'voll', 'richtig'),
      ('term-ausklammern-01', 'a', 'nicht', 'nicht_vollstaendig'),
      ('term-ausklammern-01', 'b', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-01', 'c', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-02', 'c', 'voll', 'richtig'),
      ('term-ausklammern-02', 'a', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-02', 'b', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-02', 'd', 'nicht', 'nicht_vollstaendig'),
      ('term-ausklammern-03', 'b', 'voll', 'richtig'),
      ('term-ausklammern-03', 'a', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-03', 'c', 'nicht', 'nicht_vollstaendig'),
      ('term-ausklammern-03', 'd', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-04', 'a', 'voll', 'richtig'),
      ('term-ausklammern-04', 'b', 'nicht', 'nicht_vollstaendig'),
      ('term-ausklammern-04', 'c', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-04', 'd', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-05', 'd', 'voll', 'richtig'),
      ('term-ausklammern-05', 'a', 'nicht', 'nicht_vollstaendig'),
      ('term-ausklammern-05', 'b', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-05', 'c', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-06', 'c', 'voll', 'richtig'),
      ('term-ausklammern-06', 'a', 'nicht', 'nur_erstes_geteilt'),
      ('term-ausklammern-06', 'b', 'nicht', 'falsch_geteilt'),
      ('term-ausklammern-06', 'd', 'nicht', 'nicht_vollstaendig'),
      ('term-minusklammer-01', '-2x+8', 'voll', 'kanonisch'),
      ('term-minusklammer-01', '-2x + 8', 'voll', 'kanonisch'),
      ('term-minusklammer-01', '-2x+2', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-01', '2x+2', 'nicht', 'beide_vorzeichen_behalten'),
      ('term-minusklammer-02', '-3x+13', 'voll', 'kanonisch'),
      ('term-minusklammer-02', '-3x + 13', 'voll', 'kanonisch'),
      ('term-minusklammer-02', '-3x+5', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-02', '3x+5', 'nicht', 'beide_vorzeichen_behalten'),
      ('term-minusklammer-03', '-4x+9', 'voll', 'kanonisch'),
      ('term-minusklammer-03', '-4x + 9', 'voll', 'kanonisch'),
      ('term-minusklammer-03', '-4x+5', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-03', '4x+5', 'nicht', 'beide_vorzeichen_behalten'),
      ('term-minusklammer-04', '-5x+8', 'voll', 'kanonisch'),
      ('term-minusklammer-04', '-5x + 8', 'voll', 'kanonisch'),
      ('term-minusklammer-04', '-5x-4', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-04', '5x-4', 'nicht', 'beide_vorzeichen_behalten'),
      ('term-minusklammer-05', '-6x+11', 'voll', 'kanonisch'),
      ('term-minusklammer-05', '-6x + 11', 'voll', 'kanonisch'),
      ('term-minusklammer-05', '-6x+9', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-05', '6x+9', 'nicht', 'beide_vorzeichen_behalten'),
      ('term-minusklammer-06', '-7x+13', 'voll', 'kanonisch'),
      ('term-minusklammer-06', '-7x + 13', 'voll', 'kanonisch'),
      ('term-minusklammer-06', '-7x-5', 'nicht', 'klammer_nicht_aufgeloest'),
      ('term-minusklammer-06', '7x-5', 'nicht', 'beide_vorzeichen_behalten')
    ) as p(source_ref, antwort, erwartet, rolle)
  loop
    select public.lsa_grade(
             t.input_type,
             s.acceptance,
             s.correct_answers,
             case when t.input_type = 'MC'
                  then jsonb_build_object('selected', jsonb_build_array(r.antwort))
                  else jsonb_build_object('text', r.antwort) end
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.rolle;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  -- Die Aufgaben sind da, stehen auf draft, und keine Term-Aufgabe hat sich
  -- doch noch ein acceptance eingefangen (das wuerde die Bewertung kippen).
  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and source_ref like 'term-%';
  if v_anzahl <> 26 then
    raise exception 'nur % von 26 Term-Aufgaben angelegt.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and source_ref like 'term-%'
     and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Term-Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from task_solutions s join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament' and t.source_ref like 'term-%'
     and t.input_type <> 'MC' and s.acceptance is not null;
  if v_anzahl > 0 then
    raise exception '% Term-Aufgabe(n) haben ein acceptance — das kippt die Bewertung.', v_anzahl;
  end if;

  raise notice 'Termumformung: alle Proben bestanden, 26 Aufgaben.';
end $$;

commit;
