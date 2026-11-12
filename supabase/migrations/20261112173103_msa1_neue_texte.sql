-- MSA-1 M4.2 · Fehlende Texte (12.11.2026): neue LSA-Aufgaben für die zwei Skills, die auch mit allen Entwürfen die Regel
-- „2 Texte, davon 1 ohne MC, plus 1 Reserve“ nicht erreichen (docs/msa/msa1/ist.md §1): bruch_div (1 Text, +2) und
-- geo_kreis_zusammen (0 Texte, +3). Damit hat jeder der beiden Skills 3 verschiedene Textschlüssel, alle ohne MC.
-- Beschreibung und Prüfung (Blindlöser, verify-tasks, Wertung in allen Schreibweisen): docs/msa/msa1/m4/neue-aufgaben.md.
-- geo_kreis_zusammen ohne Figur: Die zusammengesetzte Fläche steht in Worten (Quadrat mit Halbkreis, Fenster mit
-- Rundbogen, Kreisring); die Aufgaben tragen fachlich ohne Zeichnung. Werte mit π-Taste und mit π ≈ 3,14 gelten.
-- Fehlbilder aus fehlbild_labels wie bei den Geschwistern. Status draft, Pool lsa, nie ready; Lena prüft in
-- „Gezielt prüfen“, freigeben nur Admins. Cluster und Kompetenz wie das Geschwister (source_ref).
-- Idempotent (feste ids); ohne Skill oder Geschwister (CI-Neuaufbau) übersprungen. Ein DO-Block, keine Hilfstabelle.
-- Prüfabfrage: select skill_key, count(*) from tasks where source_ref in ('brueche-dividieren-08','brueche-dividieren-09',
--   'kreis-zusammen-01','kreis-zusammen-02','kreis-zusammen-03') group by 1;   → bruch_div 2, geo_kreis_zusammen 3
-- Rollback: supabase/rollback/20261112173103_msa1_neue_texte.sql (archiviert die fünf, löscht nichts)
do $neu$
declare
  v_daten jsonb := $daten$[
 {
  "id": "29bff5a9-52d3-4bfa-b54a-01a7aaff3ad9",
  "skill_key": "bruch_div",
  "geschwister": "brueche-dividieren-01",
  "source": "edvance_fundament",
  "source_ref": "brueche-dividieren-08",
  "title": "Brüche · Dividieren · Sachaufgabe Gläser",
  "question": "Eine Flasche enthält 3/4 Liter Saft. Der Saft wird in Gläser gefüllt, in jedes Glas passt 1/8 Liter.\nWie viele Gläser werden voll? Gib die Anzahl an.",
  "input_type": "NUMERIC",
  "bruch": false,
  "unit": null,
  "afb": "II",
  "curriculum_grade": 6,
  "est_duration_sec": 90,
  "correct_answers": [
   "6"
  ],
  "acceptance": {
   "canonical": "6",
   "known_errors": {
    "3/32": "nicht_gestuerzt",
    "3 / 32": "nicht_gestuerzt",
    "1/6": "falschen_gestuerzt",
    "1 / 6": "falschen_gestuerzt"
   }
  },
  "solution": "3/4 : 1/8 = 3/4 · 8/1 = 24/4 = 6. Es werden 6 Gläser voll."
 },
 {
  "id": "22636f3b-361e-43b2-aed0-550efdca0007",
  "skill_key": "bruch_div",
  "geschwister": "brueche-dividieren-01",
  "source": "edvance_fundament",
  "source_ref": "brueche-dividieren-09",
  "title": "Brüche · Dividieren · Bruch durch ganze Zahl",
  "question": "Teile den Bruch durch die ganze Zahl. Gib das Ergebnis als vollständig gekürzten Bruch an.\n6/7 : 3 = ?",
  "input_type": "NUMERIC",
  "bruch": true,
  "unit": null,
  "afb": "I",
  "curriculum_grade": 6,
  "est_duration_sec": 60,
  "correct_answers": [
   "2/7",
   "2 / 7"
  ],
  "acceptance": {
   "canonical": "2/7",
   "require_reduced": true,
   "known_errors": {
    "18/7": "nicht_gestuerzt",
    "18 / 7": "nicht_gestuerzt",
    "6/21": "teilgekuerzt",
    "6 / 21": "teilgekuerzt",
    "7/2": "falschen_gestuerzt",
    "7 / 2": "falschen_gestuerzt"
   }
  },
  "solution": "Durch 3 teilen heißt mit 1/3 malnehmen: 6/7 · 1/3 = 6/21 = 2/7."
 },
 {
  "id": "df326675-cb54-4d4d-acad-ab6e4754cf96",
  "skill_key": "geo_kreis_zusammen",
  "geschwister": "kreis-flaeche-02",
  "source": "edvance_k9_kreis",
  "source_ref": "kreis-zusammen-01",
  "title": "Kreis · Zusammengesetzt · Quadrat mit Halbkreis",
  "question": "Eine Fläche besteht aus einem Quadrat mit der Seitenlänge 6 cm. An eine Seite des Quadrats ist außen ein Halbkreis angesetzt, diese Seite ist sein Durchmesser.\nWie groß ist die gesamte Fläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.",
  "input_type": "NUMERIC",
  "bruch": null,
  "unit": "cm²",
  "afb": "I",
  "curriculum_grade": 9,
  "est_duration_sec": 120,
  "correct_answers": [
   "50,14",
   "50.14",
   "50,14 cm²",
   "50,14cm²",
   "50,13",
   "50.13",
   "50,13 cm²",
   "50,13cm²"
  ],
  "acceptance": {
   "canonical": "50,14",
   "equivalents": [
    "50.14",
    "50,14 cm²",
    "50,14cm²",
    "50,13",
    "50.13",
    "50,13 cm²",
    "50,13cm²"
   ],
   "known_errors": {
    "36": "teilflaeche_vergessen",
    "36 cm²": "teilflaeche_vergessen",
    "36cm²": "teilflaeche_vergessen",
    "36,00": "teilflaeche_vergessen",
    "36.00": "teilflaeche_vergessen",
    "36,00 cm²": "teilflaeche_vergessen",
    "36,00cm²": "teilflaeche_vergessen",
    "14,14": "teilflaeche_vergessen",
    "14.14": "teilflaeche_vergessen",
    "14,14 cm²": "teilflaeche_vergessen",
    "14,14cm²": "teilflaeche_vergessen",
    "14,13": "teilflaeche_vergessen",
    "14.13": "teilflaeche_vergessen",
    "14,13 cm²": "teilflaeche_vergessen",
    "14,13cm²": "teilflaeche_vergessen",
    "64,27": "halbieren_vergessen",
    "64.27": "halbieren_vergessen",
    "64,27 cm²": "halbieren_vergessen",
    "64,27cm²": "halbieren_vergessen",
    "64,26": "halbieren_vergessen",
    "64.26": "halbieren_vergessen",
    "64,26 cm²": "halbieren_vergessen",
    "64,26cm²": "halbieren_vergessen",
    "92,55": "radius_durchmesser_verwechselt",
    "92.55": "radius_durchmesser_verwechselt",
    "92,55 cm²": "radius_durchmesser_verwechselt",
    "92,55cm²": "radius_durchmesser_verwechselt",
    "92,52": "radius_durchmesser_verwechselt",
    "92.52": "radius_durchmesser_verwechselt",
    "92,52 cm²": "radius_durchmesser_verwechselt",
    "92,52cm²": "radius_durchmesser_verwechselt",
    "40,5": "pi_vergessen",
    "40.5": "pi_vergessen",
    "40,5 cm²": "pi_vergessen",
    "40,5cm²": "pi_vergessen",
    "40,50": "pi_vergessen",
    "40.50": "pi_vergessen",
    "40,50 cm²": "pi_vergessen",
    "40,50cm²": "pi_vergessen"
   }
  },
  "solution": "Quadrat: 6 · 6 = 36 cm². Halbkreis mit r = 3 cm: π · 3² : 2 ≈ 14,14 cm². Zusammen: 36 + 14,14 ≈ 50,14 cm² (mit π ≈ 3,14: 50,13 cm²)."
 },
 {
  "id": "7d5cdf09-f5cd-48b9-a83e-8f19e82c92fa",
  "skill_key": "geo_kreis_zusammen",
  "geschwister": "kreis-flaeche-02",
  "source": "edvance_k9_kreis",
  "source_ref": "kreis-zusammen-02",
  "title": "Kreis · Zusammengesetzt · Fenster mit Rundbogen",
  "question": "Ein Fenster besteht aus einem Rechteck, 80 cm breit und 120 cm hoch, und einem Halbkreis, der oben auf der Breite aufsitzt.\nWie groß ist die Glasfläche in cm²? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Quadratzentimeter.",
  "input_type": "NUMERIC",
  "bruch": null,
  "unit": "cm²",
  "afb": "II",
  "curriculum_grade": 9,
  "est_duration_sec": 150,
  "correct_answers": [
   "12113",
   "12113 cm²",
   "12113cm²",
   "12112",
   "12112 cm²",
   "12112cm²"
  ],
  "acceptance": {
   "canonical": "12113",
   "equivalents": [
    "12113 cm²",
    "12113cm²",
    "12112",
    "12112 cm²",
    "12112cm²"
   ],
   "known_errors": {
    "9600": "teilflaeche_vergessen",
    "9600 cm²": "teilflaeche_vergessen",
    "9600cm²": "teilflaeche_vergessen",
    "2513": "teilflaeche_vergessen",
    "2513 cm²": "teilflaeche_vergessen",
    "2513cm²": "teilflaeche_vergessen",
    "2512": "teilflaeche_vergessen",
    "2512 cm²": "teilflaeche_vergessen",
    "2512cm²": "teilflaeche_vergessen",
    "14627": "halbieren_vergessen",
    "14627 cm²": "halbieren_vergessen",
    "14627cm²": "halbieren_vergessen",
    "14624": "halbieren_vergessen",
    "14624 cm²": "halbieren_vergessen",
    "14624cm²": "halbieren_vergessen",
    "19653": "radius_durchmesser_verwechselt",
    "19653 cm²": "radius_durchmesser_verwechselt",
    "19653cm²": "radius_durchmesser_verwechselt",
    "19648": "radius_durchmesser_verwechselt",
    "19648 cm²": "radius_durchmesser_verwechselt",
    "19648cm²": "radius_durchmesser_verwechselt",
    "10400": "pi_vergessen",
    "10400 cm²": "pi_vergessen",
    "10400cm²": "pi_vergessen"
   }
  },
  "solution": "Rechteck: 80 · 120 = 9600 cm². Halbkreis mit r = 40 cm: π · 40² : 2 ≈ 2513,27 cm². Zusammen ≈ 12113 cm² (mit π ≈ 3,14: 12112 cm²)."
 },
 {
  "id": "c5d73909-c63b-434e-9daa-67a06db1fb7e",
  "skill_key": "geo_kreis_zusammen",
  "geschwister": "kreis-flaeche-02",
  "source": "edvance_k9_kreis",
  "source_ref": "kreis-zusammen-03",
  "title": "Kreis · Zusammengesetzt · Tischplatte mit Loch",
  "question": "Eine runde Tischplatte hat den Radius 50 cm. In der Mitte ist ein rundes Loch mit dem Radius 10 cm für einen Sonnenschirm.\nWie groß ist die Fläche der Tischplatte ohne das Loch? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Quadratzentimeter.",
  "input_type": "NUMERIC",
  "bruch": null,
  "unit": "cm²",
  "afb": "II",
  "curriculum_grade": 9,
  "est_duration_sec": 120,
  "correct_answers": [
   "7540",
   "7540 cm²",
   "7540cm²",
   "7536",
   "7536 cm²",
   "7536cm²"
  ],
  "acceptance": {
   "canonical": "7540",
   "equivalents": [
    "7540 cm²",
    "7540cm²",
    "7536",
    "7536 cm²",
    "7536cm²"
   ],
   "known_errors": {
    "7854": "teilflaeche_vergessen",
    "7854 cm²": "teilflaeche_vergessen",
    "7854cm²": "teilflaeche_vergessen",
    "7850": "teilflaeche_vergessen",
    "7850 cm²": "teilflaeche_vergessen",
    "7850cm²": "teilflaeche_vergessen",
    "2400": "pi_vergessen",
    "2400 cm²": "pi_vergessen",
    "2400cm²": "pi_vergessen"
   }
  },
  "solution": "Große Kreisfläche: π · 50² ≈ 7853,98 cm². Loch: π · 10² ≈ 314,16 cm². Differenz: π · 2400 ≈ 7540 cm² (mit π ≈ 3,14: 7536 cm²)."
 }
]$daten$::jsonb;
  n jsonb;
  g record;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);
  for n in select * from jsonb_array_elements(v_daten) loop
    continue when not exists (select 1 from public.skills s where s.skill_key = n ->> 'skill_key');
    select t.cluster_id, t.competency_id, t.competency_content, t.competency_process into g
      from public.tasks t where t.source_ref = n ->> 'geschwister' limit 1;
    continue when not found;
    insert into public.tasks (
      id, content_type, title, question, question_payload, input_type, skill_key, bruch, unit,
      class_level, curriculum_grade, cluster_id, competency_id, afb, competency_content, competency_process,
      estimated_minutes, est_duration_sec, needs_image, status, source, source_ref, sondierrang,
      is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot)
    values ((n ->> 'id')::uuid, 'exercise', n ->> 'title', n ->> 'question', null, n ->> 'input_type', n ->> 'skill_key',
            (n ->> 'bruch')::boolean, n ->> 'unit', null, (n ->> 'curriculum_grade')::int, g.cluster_id, g.competency_id,
            n ->> 'afb', g.competency_content, g.competency_process, 3, (n ->> 'est_duration_sec')::int, false, 'draft',
            n ->> 'source', n ->> 'source_ref', 3, false, true, false, false, '[]'::jsonb, '[]'::jsonb, '{lsa}'::text[], true)
    on conflict do nothing;
    if not exists (select 1 from public.task_solutions s where s.task_id = (n ->> 'id')::uuid) then
      perform public.task_solution_upsert(
        p_task_id => (n ->> 'id')::uuid, p_correct_answers => n -> 'correct_answers', p_solution => n ->> 'solution',
        p_hints => '[]'::jsonb, p_coach_hints => '[]'::jsonb, p_typical_errors => '[]'::jsonb, p_beleg => null,
        p_acceptance => n -> 'acceptance', p_option_scores => null);
    end if;
  end loop;
end
$neu$;
