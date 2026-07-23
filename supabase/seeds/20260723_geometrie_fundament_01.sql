-- ============================================================================
-- Geometrie-Fundament — 38 draft-Aufgaben (6 Skills aus A18)
--
-- ERZEUGT von scripts/content/geometrie_fundament.py. Nicht von Hand pflegen.
--
-- SETZT A18 VORAUS (skills geo_*). FK task_solutions/tasks.skill_key -> skills.
-- Von Hand einspielen, NACH der A18-Migration:
--     psql "$DATABASE_URL" -f supabase/seeds/20260723_geometrie_fundament_01.sql
--
-- ANTWORTFORM: input_type NUMERIC, canonical ist eine REINE ZAHL. Einheit im
-- Fragetext und in tasks.unit (-> payload.unit). Wert-Pfad von lsa_grade, NICHT
-- TERM-Zweig (Selbsttest 3b). Alle Masse im Text, KEINE Abbildung noetig.
--
-- STATUS: alles 'draft'. Freigabe ist Lenas Schritt.
-- SOLUTION-LEAK: canonical + known_errors nur in task_solutions.
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from skills where skill_key = 'geo_umfang') then
    raise exception 'skills geo_* fehlen — A18 erst einspielen.';
  end if;
end $$;

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  skill_key, title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, unit, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.skill_key, v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Geometrie & Messen' limit 1),
  'geometrie', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.unit, v.payload
from (values
  ('geo-umfang-01', 'geo_umfang', 'Geometrie · Umfang Rechteck · 4×7', 'Ein Rechteck ist 4 cm lang und 7 cm breit.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 4 cm lang und 7 cm breit.

Wie groß ist der Umfang in cm?')),
  ('geo-umfang-02', 'geo_umfang', 'Geometrie · Umfang Rechteck · 5×8', 'Ein Rechteck ist 5 cm lang und 8 cm breit.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 5 cm lang und 8 cm breit.

Wie groß ist der Umfang in cm?')),
  ('geo-umfang-03', 'geo_umfang', 'Geometrie · Umfang Rechteck · 3×7', 'Ein Rechteck ist 3 cm lang und 7 cm breit.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 3 cm lang und 7 cm breit.

Wie groß ist der Umfang in cm?')),
  ('geo-umfang-04', 'geo_umfang', 'Geometrie · Umfang Dreieck · 6,7,9', 'Ein Dreieck hat die Seiten 6 cm, 7 cm und 9 cm.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Seiten 6 cm, 7 cm und 9 cm.

Wie groß ist der Umfang in cm?')),
  ('geo-umfang-05', 'geo_umfang', 'Geometrie · Umfang Dreieck · 5,8,10', 'Ein Dreieck hat die Seiten 5 cm, 8 cm und 10 cm.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Seiten 5 cm, 8 cm und 10 cm.

Wie groß ist der Umfang in cm?')),
  ('geo-umfang-06', 'geo_umfang', 'Geometrie · Umfang Dreieck · 7,9,12', 'Ein Dreieck hat die Seiten 7 cm, 9 cm und 12 cm.

Wie groß ist der Umfang in cm?', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Seiten 7 cm, 9 cm und 12 cm.

Wie groß ist der Umfang in cm?')),
  ('geo-flaeche-rechteck-01', 'geo_flaeche_rechteck', 'Geometrie · Fläche Rechteck · 4×7', 'Ein Rechteck ist 4 cm lang und 7 cm breit.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 4 cm lang und 7 cm breit.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-rechteck-02', 'geo_flaeche_rechteck', 'Geometrie · Fläche Rechteck · 5×9', 'Ein Rechteck ist 5 cm lang und 9 cm breit.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 5 cm lang und 9 cm breit.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-rechteck-03', 'geo_flaeche_rechteck', 'Geometrie · Fläche Rechteck · 6×8', 'Ein Rechteck ist 6 cm lang und 8 cm breit.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Rechteck ist 6 cm lang und 8 cm breit.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-rechteck-04', 'geo_flaeche_rechteck', 'Geometrie · Fläche Quadrat · 5', 'Ein Quadrat hat die Seitenlänge 5 cm.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quadrat hat die Seitenlänge 5 cm.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-rechteck-05', 'geo_flaeche_rechteck', 'Geometrie · Fläche Quadrat · 7', 'Ein Quadrat hat die Seitenlänge 7 cm.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quadrat hat die Seitenlänge 7 cm.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-rechteck-06', 'geo_flaeche_rechteck', 'Geometrie · Fläche Quadrat · 9', 'Ein Quadrat hat die Seitenlänge 9 cm.

Wie groß ist die Fläche in cm²?', 'I', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quadrat hat die Seitenlänge 9 cm.

Wie groß ist die Fläche in cm²?')),
  ('geo-winkel-summe-01', 'geo_winkel_summe', 'Geometrie · Winkel Dreieck · 50,60', 'In einem Dreieck sind zwei Winkel 50° und 60° groß.

Wie groß ist der dritte Winkel in Grad?', 'I', '°', jsonb_build_object('kind','short_input','prompt','In einem Dreieck sind zwei Winkel 50° und 60° groß.

Wie groß ist der dritte Winkel in Grad?')),
  ('geo-winkel-summe-02', 'geo_winkel_summe', 'Geometrie · Winkel Dreieck · 40,75', 'In einem Dreieck sind zwei Winkel 40° und 75° groß.

Wie groß ist der dritte Winkel in Grad?', 'I', '°', jsonb_build_object('kind','short_input','prompt','In einem Dreieck sind zwei Winkel 40° und 75° groß.

Wie groß ist der dritte Winkel in Grad?')),
  ('geo-winkel-summe-03', 'geo_winkel_summe', 'Geometrie · Winkel Dreieck · 55,80', 'In einem Dreieck sind zwei Winkel 55° und 80° groß.

Wie groß ist der dritte Winkel in Grad?', 'I', '°', jsonb_build_object('kind','short_input','prompt','In einem Dreieck sind zwei Winkel 55° und 80° groß.

Wie groß ist der dritte Winkel in Grad?')),
  ('geo-winkel-summe-04', 'geo_winkel_summe', 'Geometrie · Winkel Viereck · 90,90,100', 'In einem Viereck sind drei Winkel 90°, 90° und 100° groß.

Wie groß ist der vierte Winkel in Grad?', 'II', '°', jsonb_build_object('kind','short_input','prompt','In einem Viereck sind drei Winkel 90°, 90° und 100° groß.

Wie groß ist der vierte Winkel in Grad?')),
  ('geo-winkel-summe-05', 'geo_winkel_summe', 'Geometrie · Winkel Viereck · 80,110,100', 'In einem Viereck sind drei Winkel 80°, 110° und 100° groß.

Wie groß ist der vierte Winkel in Grad?', 'II', '°', jsonb_build_object('kind','short_input','prompt','In einem Viereck sind drei Winkel 80°, 110° und 100° groß.

Wie groß ist der vierte Winkel in Grad?')),
  ('geo-winkel-summe-06', 'geo_winkel_summe', 'Geometrie · Winkel Viereck · 95,85,120', 'In einem Viereck sind drei Winkel 95°, 85° und 120° groß.

Wie groß ist der vierte Winkel in Grad?', 'II', '°', jsonb_build_object('kind','short_input','prompt','In einem Viereck sind drei Winkel 95°, 85° und 120° groß.

Wie groß ist der vierte Winkel in Grad?')),
  ('geo-flaeche-dreieck-01', 'geo_flaeche_dreieck', 'Geometrie · Fläche Dreieck · 8×6', 'Ein Dreieck hat die Grundseite 8 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Grundseite 8 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-02', 'geo_flaeche_dreieck', 'Geometrie · Fläche Dreieck · 10×4', 'Ein Dreieck hat die Grundseite 10 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Grundseite 10 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-03', 'geo_flaeche_dreieck', 'Geometrie · Fläche Dreieck · 12×5', 'Ein Dreieck hat die Grundseite 12 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 8 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Grundseite 12 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 8 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-04', 'geo_flaeche_dreieck', 'Geometrie · Fläche Dreieck · 6×8', 'Ein Dreieck hat die Grundseite 6 cm und die zugehörige Höhe 8 cm. Eine weitere Seite ist 5 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Dreieck hat die Grundseite 6 cm und die zugehörige Höhe 8 cm. Eine weitere Seite ist 5 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-05', 'geo_flaeche_dreieck', 'Geometrie · Fläche Parallelogramm · 7×6', 'Ein Parallelogramm hat die Grundseite 7 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 5 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Parallelogramm hat die Grundseite 7 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 5 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-06', 'geo_flaeche_dreieck', 'Geometrie · Fläche Parallelogramm · 9×4', 'Ein Parallelogramm hat die Grundseite 9 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 6 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Parallelogramm hat die Grundseite 9 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 6 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-flaeche-dreieck-07', 'geo_flaeche_dreieck', 'Geometrie · Fläche Parallelogramm · 8×5', 'Ein Parallelogramm hat die Grundseite 8 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Parallelogramm hat die Grundseite 8 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 7 cm lang.

Wie groß ist die Fläche in cm²?')),
  ('geo-volumen-quader-01', 'geo_volumen_quader', 'Geometrie · Volumen Quader · 2×3×4', 'Ein Quader hat die Kanten 2 cm, 3 cm und 4 cm.

Wie groß ist das Volumen in cm³?', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 2 cm, 3 cm und 4 cm.

Wie groß ist das Volumen in cm³?')),
  ('geo-volumen-quader-02', 'geo_volumen_quader', 'Geometrie · Volumen Quader · 3×4×5', 'Ein Quader hat die Kanten 3 cm, 4 cm und 5 cm.

Wie groß ist das Volumen in cm³?', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 3 cm, 4 cm und 5 cm.

Wie groß ist das Volumen in cm³?')),
  ('geo-volumen-quader-03', 'geo_volumen_quader', 'Geometrie · Volumen Quader · 2×5×6', 'Ein Quader hat die Kanten 2 cm, 5 cm und 6 cm.

Wie groß ist das Volumen in cm³?', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 2 cm, 5 cm und 6 cm.

Wie groß ist das Volumen in cm³?')),
  ('geo-volumen-quader-04', 'geo_volumen_quader', 'Geometrie · Volumen Quader · 4×6×7', 'Ein Quader hat die Kanten 4 cm, 6 cm und 7 cm.

Wie groß ist das Volumen in cm³?', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 4 cm, 6 cm und 7 cm.

Wie groß ist das Volumen in cm³?')),
  ('geo-volumen-quader-05', 'geo_volumen_quader', 'Geometrie · Oberfläche Quader · 2×3×5', 'Ein Quader hat die Kanten 2 cm, 3 cm und 5 cm.

Wie groß ist die Oberfläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 2 cm, 3 cm und 5 cm.

Wie groß ist die Oberfläche in cm²?')),
  ('geo-volumen-quader-06', 'geo_volumen_quader', 'Geometrie · Oberfläche Quader · 3×4×6', 'Ein Quader hat die Kanten 3 cm, 4 cm und 6 cm.

Wie groß ist die Oberfläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 3 cm, 4 cm und 6 cm.

Wie groß ist die Oberfläche in cm²?')),
  ('geo-volumen-quader-07', 'geo_volumen_quader', 'Geometrie · Oberfläche Quader · 2×4×7', 'Ein Quader hat die Kanten 2 cm, 4 cm und 7 cm.

Wie groß ist die Oberfläche in cm²?', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Ein Quader hat die Kanten 2 cm, 4 cm und 7 cm.

Wie groß ist die Oberfläche in cm²?')),
  ('geo-massstab-01', 'geo_massstab', 'Geometrie · Maßstab · 1:25000, 4 cm', 'Auf einer Karte im Maßstab 1:25000 ist eine Strecke 4 cm lang.

Wie lang ist die Strecke in Wirklichkeit in km?', 'II', 'km', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:25000 ist eine Strecke 4 cm lang.

Wie lang ist die Strecke in Wirklichkeit in km?')),
  ('geo-massstab-02', 'geo_massstab', 'Geometrie · Maßstab · 1:50000, 6 cm', 'Auf einer Karte im Maßstab 1:50000 ist eine Strecke 6 cm lang.

Wie lang ist die Strecke in Wirklichkeit in km?', 'II', 'km', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:50000 ist eine Strecke 6 cm lang.

Wie lang ist die Strecke in Wirklichkeit in km?')),
  ('geo-massstab-03', 'geo_massstab', 'Geometrie · Maßstab · 1:1000, 8 cm', 'Auf einer Karte im Maßstab 1:1000 ist eine Strecke 8 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?', 'II', 'm', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:1000 ist eine Strecke 8 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?')),
  ('geo-massstab-04', 'geo_massstab', 'Geometrie · Maßstab · 1:100, 25 cm', 'Auf einer Karte im Maßstab 1:100 ist eine Strecke 25 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?', 'II', 'm', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:100 ist eine Strecke 25 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?')),
  ('geo-massstab-05', 'geo_massstab', 'Geometrie · Maßstab · 1:250, 12 cm', 'Auf einer Karte im Maßstab 1:250 ist eine Strecke 12 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?', 'II', 'm', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:250 ist eine Strecke 12 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?')),
  ('geo-massstab-06', 'geo_massstab', 'Geometrie · Maßstab · 1:1000, 15 cm', 'Auf einer Karte im Maßstab 1:1000 ist eine Strecke 15 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?', 'II', 'm', jsonb_build_object('kind','short_input','prompt','Auf einer Karte im Maßstab 1:1000 ist eine Strecke 15 cm lang.

Wie lang ist die Strecke in Wirklichkeit in m?'))
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('geo-umfang-01', '["22"]', '{"canonical": "22", "known_errors": {"28": "flaeche_statt_umfang", "11": "nur_einmal_addiert"}}'),
  ('geo-umfang-02', '["26"]', '{"canonical": "26", "known_errors": {"40": "flaeche_statt_umfang", "13": "nur_einmal_addiert"}}'),
  ('geo-umfang-03', '["20"]', '{"canonical": "20", "known_errors": {"21": "flaeche_statt_umfang", "10": "nur_einmal_addiert"}}'),
  ('geo-umfang-04', '["22"]', '{"canonical": "22", "known_errors": {"13": "seite_vergessen"}}'),
  ('geo-umfang-05', '["23"]', '{"canonical": "23", "known_errors": {"13": "seite_vergessen"}}'),
  ('geo-umfang-06', '["28"]', '{"canonical": "28", "known_errors": {"16": "seite_vergessen"}}'),
  ('geo-flaeche-rechteck-01', '["28"]', '{"canonical": "28", "known_errors": {"22": "umfang_statt_flaeche", "11": "plus_statt_mal", "16": "nur_eine_seite"}}'),
  ('geo-flaeche-rechteck-02', '["45"]', '{"canonical": "45", "known_errors": {"28": "umfang_statt_flaeche", "14": "plus_statt_mal", "25": "nur_eine_seite"}}'),
  ('geo-flaeche-rechteck-03', '["48"]', '{"canonical": "48", "known_errors": {"28": "umfang_statt_flaeche", "14": "plus_statt_mal", "36": "nur_eine_seite"}}'),
  ('geo-flaeche-rechteck-04', '["25"]', '{"canonical": "25", "known_errors": {"20": "umfang_statt_flaeche", "10": "plus_statt_mal"}}'),
  ('geo-flaeche-rechteck-05', '["49"]', '{"canonical": "49", "known_errors": {"28": "umfang_statt_flaeche", "14": "plus_statt_mal"}}'),
  ('geo-flaeche-rechteck-06', '["81"]', '{"canonical": "81", "known_errors": {"36": "umfang_statt_flaeche", "18": "plus_statt_mal"}}'),
  ('geo-winkel-summe-01', '["70"]', '{"canonical": "70", "known_errors": {"250": "summe_360_statt_180", "110": "differenz_vergessen"}}'),
  ('geo-winkel-summe-02', '["65"]', '{"canonical": "65", "known_errors": {"245": "summe_360_statt_180", "115": "differenz_vergessen"}}'),
  ('geo-winkel-summe-03', '["45"]', '{"canonical": "45", "known_errors": {"225": "summe_360_statt_180", "135": "differenz_vergessen"}}'),
  ('geo-winkel-summe-04', '["80"]', '{"canonical": "80", "known_errors": {"-100": "summe_180_statt_360", "280": "differenz_vergessen"}}'),
  ('geo-winkel-summe-05', '["70"]', '{"canonical": "70", "known_errors": {"-110": "summe_180_statt_360", "290": "differenz_vergessen"}}'),
  ('geo-winkel-summe-06', '["60"]', '{"canonical": "60", "known_errors": {"-120": "summe_180_statt_360", "300": "differenz_vergessen"}}'),
  ('geo-flaeche-dreieck-01', '["24"]', '{"canonical": "24", "known_errors": {"48": "halbieren_vergessen", "28": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-02', '["20"]', '{"canonical": "20", "known_errors": {"40": "halbieren_vergessen", "35": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-03', '["30"]', '{"canonical": "30", "known_errors": {"60": "halbieren_vergessen", "48": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-04', '["24"]', '{"canonical": "24", "known_errors": {"48": "halbieren_vergessen", "15": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-05', '["42"]', '{"canonical": "42", "known_errors": {"21": "halbieren_faelschlich", "35": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-06', '["36"]', '{"canonical": "36", "known_errors": {"18": "halbieren_faelschlich", "54": "falsche_hoehe"}}'),
  ('geo-flaeche-dreieck-07', '["40"]', '{"canonical": "40", "known_errors": {"20": "halbieren_faelschlich", "56": "falsche_hoehe"}}'),
  ('geo-volumen-quader-01', '["24"]', '{"canonical": "24", "known_errors": {"52": "oberflaeche_statt_volumen", "6": "zwei_kanten"}}'),
  ('geo-volumen-quader-02', '["60"]', '{"canonical": "60", "known_errors": {"94": "oberflaeche_statt_volumen", "12": "zwei_kanten"}}'),
  ('geo-volumen-quader-03', '["60"]', '{"canonical": "60", "known_errors": {"104": "oberflaeche_statt_volumen", "10": "zwei_kanten"}}'),
  ('geo-volumen-quader-04', '["168"]', '{"canonical": "168", "known_errors": {"188": "oberflaeche_statt_volumen", "24": "zwei_kanten"}}'),
  ('geo-volumen-quader-05', '["62"]', '{"canonical": "62", "known_errors": {"30": "volumen_statt_oberflaeche", "31": "mal_zwei_vergessen"}}'),
  ('geo-volumen-quader-06', '["108"]', '{"canonical": "108", "known_errors": {"72": "volumen_statt_oberflaeche", "54": "mal_zwei_vergessen"}}'),
  ('geo-volumen-quader-07', '["100"]', '{"canonical": "100", "known_errors": {"56": "volumen_statt_oberflaeche", "50": "mal_zwei_vergessen"}}'),
  ('geo-massstab-01', '["1"]', '{"canonical": "1", "known_errors": {"10": "faktor_zehn_daneben", "100000": "einheit_ignoriert"}}'),
  ('geo-massstab-02', '["3"]', '{"canonical": "3", "known_errors": {"30": "faktor_zehn_daneben", "300000": "einheit_ignoriert"}}'),
  ('geo-massstab-03', '["80"]', '{"canonical": "80", "known_errors": {"0,008": "richtung_vertauscht", "800": "faktor_zehn_daneben", "8000": "einheit_ignoriert"}}'),
  ('geo-massstab-04', '["25"]', '{"canonical": "25", "known_errors": {"0,25": "richtung_vertauscht", "250": "faktor_zehn_daneben", "2500": "einheit_ignoriert"}}'),
  ('geo-massstab-05', '["30"]', '{"canonical": "30", "known_errors": {"0,048": "richtung_vertauscht", "300": "faktor_zehn_daneben", "3000": "einheit_ignoriert"}}'),
  ('geo-massstab-06', '["150"]', '{"canonical": "150", "known_errors": {"0,015": "richtung_vertauscht", "1500": "faktor_zehn_daneben", "15000": "einheit_ignoriert"}}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── Selbsttest ─────────────────────────────────────────────────────────────

do $$
declare
  r record; v_urteil text; v_fehler int := 0; v_anzahl int;
begin
  for r in select * from (values
      ('geo-umfang-01', '22', 'voll', 'canonical'),
      ('geo-umfang-01', '28', 'nicht', 'flaeche_statt_umfang'),
      ('geo-umfang-01', '11', 'nicht', 'nur_einmal_addiert'),
      ('geo-umfang-02', '26', 'voll', 'canonical'),
      ('geo-umfang-02', '40', 'nicht', 'flaeche_statt_umfang'),
      ('geo-umfang-02', '13', 'nicht', 'nur_einmal_addiert'),
      ('geo-umfang-03', '20', 'voll', 'canonical'),
      ('geo-umfang-03', '21', 'nicht', 'flaeche_statt_umfang'),
      ('geo-umfang-03', '10', 'nicht', 'nur_einmal_addiert'),
      ('geo-umfang-04', '22', 'voll', 'canonical'),
      ('geo-umfang-04', '13', 'nicht', 'seite_vergessen'),
      ('geo-umfang-05', '23', 'voll', 'canonical'),
      ('geo-umfang-05', '13', 'nicht', 'seite_vergessen'),
      ('geo-umfang-06', '28', 'voll', 'canonical'),
      ('geo-umfang-06', '16', 'nicht', 'seite_vergessen'),
      ('geo-flaeche-rechteck-01', '28', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-01', '22', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-01', '11', 'nicht', 'plus_statt_mal'),
      ('geo-flaeche-rechteck-01', '16', 'nicht', 'nur_eine_seite'),
      ('geo-flaeche-rechteck-02', '45', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-02', '28', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-02', '14', 'nicht', 'plus_statt_mal'),
      ('geo-flaeche-rechteck-02', '25', 'nicht', 'nur_eine_seite'),
      ('geo-flaeche-rechteck-03', '48', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-03', '28', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-03', '14', 'nicht', 'plus_statt_mal'),
      ('geo-flaeche-rechteck-03', '36', 'nicht', 'nur_eine_seite'),
      ('geo-flaeche-rechteck-04', '25', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-04', '20', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-04', '10', 'nicht', 'plus_statt_mal'),
      ('geo-flaeche-rechteck-05', '49', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-05', '28', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-05', '14', 'nicht', 'plus_statt_mal'),
      ('geo-flaeche-rechteck-06', '81', 'voll', 'canonical'),
      ('geo-flaeche-rechteck-06', '36', 'nicht', 'umfang_statt_flaeche'),
      ('geo-flaeche-rechteck-06', '18', 'nicht', 'plus_statt_mal'),
      ('geo-winkel-summe-01', '70', 'voll', 'canonical'),
      ('geo-winkel-summe-01', '250', 'nicht', 'summe_360_statt_180'),
      ('geo-winkel-summe-01', '110', 'nicht', 'differenz_vergessen'),
      ('geo-winkel-summe-02', '65', 'voll', 'canonical'),
      ('geo-winkel-summe-02', '245', 'nicht', 'summe_360_statt_180'),
      ('geo-winkel-summe-02', '115', 'nicht', 'differenz_vergessen'),
      ('geo-winkel-summe-03', '45', 'voll', 'canonical'),
      ('geo-winkel-summe-03', '225', 'nicht', 'summe_360_statt_180'),
      ('geo-winkel-summe-03', '135', 'nicht', 'differenz_vergessen'),
      ('geo-winkel-summe-04', '80', 'voll', 'canonical'),
      ('geo-winkel-summe-04', '-100', 'nicht', 'summe_180_statt_360'),
      ('geo-winkel-summe-04', '280', 'nicht', 'differenz_vergessen'),
      ('geo-winkel-summe-05', '70', 'voll', 'canonical'),
      ('geo-winkel-summe-05', '-110', 'nicht', 'summe_180_statt_360'),
      ('geo-winkel-summe-05', '290', 'nicht', 'differenz_vergessen'),
      ('geo-winkel-summe-06', '60', 'voll', 'canonical'),
      ('geo-winkel-summe-06', '-120', 'nicht', 'summe_180_statt_360'),
      ('geo-winkel-summe-06', '300', 'nicht', 'differenz_vergessen'),
      ('geo-flaeche-dreieck-01', '24', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-01', '48', 'nicht', 'halbieren_vergessen'),
      ('geo-flaeche-dreieck-01', '28', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-02', '20', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-02', '40', 'nicht', 'halbieren_vergessen'),
      ('geo-flaeche-dreieck-02', '35', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-03', '30', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-03', '60', 'nicht', 'halbieren_vergessen'),
      ('geo-flaeche-dreieck-03', '48', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-04', '24', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-04', '48', 'nicht', 'halbieren_vergessen'),
      ('geo-flaeche-dreieck-04', '15', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-05', '42', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-05', '21', 'nicht', 'halbieren_faelschlich'),
      ('geo-flaeche-dreieck-05', '35', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-06', '36', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-06', '18', 'nicht', 'halbieren_faelschlich'),
      ('geo-flaeche-dreieck-06', '54', 'nicht', 'falsche_hoehe'),
      ('geo-flaeche-dreieck-07', '40', 'voll', 'canonical'),
      ('geo-flaeche-dreieck-07', '20', 'nicht', 'halbieren_faelschlich'),
      ('geo-flaeche-dreieck-07', '56', 'nicht', 'falsche_hoehe'),
      ('geo-volumen-quader-01', '24', 'voll', 'canonical'),
      ('geo-volumen-quader-01', '52', 'nicht', 'oberflaeche_statt_volumen'),
      ('geo-volumen-quader-01', '6', 'nicht', 'zwei_kanten'),
      ('geo-volumen-quader-02', '60', 'voll', 'canonical'),
      ('geo-volumen-quader-02', '94', 'nicht', 'oberflaeche_statt_volumen'),
      ('geo-volumen-quader-02', '12', 'nicht', 'zwei_kanten'),
      ('geo-volumen-quader-03', '60', 'voll', 'canonical'),
      ('geo-volumen-quader-03', '104', 'nicht', 'oberflaeche_statt_volumen'),
      ('geo-volumen-quader-03', '10', 'nicht', 'zwei_kanten'),
      ('geo-volumen-quader-04', '168', 'voll', 'canonical'),
      ('geo-volumen-quader-04', '188', 'nicht', 'oberflaeche_statt_volumen'),
      ('geo-volumen-quader-04', '24', 'nicht', 'zwei_kanten'),
      ('geo-volumen-quader-05', '62', 'voll', 'canonical'),
      ('geo-volumen-quader-05', '30', 'nicht', 'volumen_statt_oberflaeche'),
      ('geo-volumen-quader-05', '31', 'nicht', 'mal_zwei_vergessen'),
      ('geo-volumen-quader-06', '108', 'voll', 'canonical'),
      ('geo-volumen-quader-06', '72', 'nicht', 'volumen_statt_oberflaeche'),
      ('geo-volumen-quader-06', '54', 'nicht', 'mal_zwei_vergessen'),
      ('geo-volumen-quader-07', '100', 'voll', 'canonical'),
      ('geo-volumen-quader-07', '56', 'nicht', 'volumen_statt_oberflaeche'),
      ('geo-volumen-quader-07', '50', 'nicht', 'mal_zwei_vergessen'),
      ('geo-massstab-01', '1', 'voll', 'canonical'),
      ('geo-massstab-01', '10', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-01', '100000', 'nicht', 'einheit_ignoriert'),
      ('geo-massstab-02', '3', 'voll', 'canonical'),
      ('geo-massstab-02', '30', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-02', '300000', 'nicht', 'einheit_ignoriert'),
      ('geo-massstab-03', '80', 'voll', 'canonical'),
      ('geo-massstab-03', '0,008', 'nicht', 'richtung_vertauscht'),
      ('geo-massstab-03', '800', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-03', '8000', 'nicht', 'einheit_ignoriert'),
      ('geo-massstab-04', '25', 'voll', 'canonical'),
      ('geo-massstab-04', '0,25', 'nicht', 'richtung_vertauscht'),
      ('geo-massstab-04', '250', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-04', '2500', 'nicht', 'einheit_ignoriert'),
      ('geo-massstab-05', '30', 'voll', 'canonical'),
      ('geo-massstab-05', '0,048', 'nicht', 'richtung_vertauscht'),
      ('geo-massstab-05', '300', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-05', '3000', 'nicht', 'einheit_ignoriert'),
      ('geo-massstab-06', '150', 'voll', 'canonical'),
      ('geo-massstab-06', '0,015', 'nicht', 'richtung_vertauscht'),
      ('geo-massstab-06', '1500', 'nicht', 'faktor_zehn_daneben'),
      ('geo-massstab-06', '15000', 'nicht', 'einheit_ignoriert')
    ) as p(source_ref, antwort, erwartet, label)
  loop
    select public.lsa_grade('NUMERIC', s.acceptance, s.correct_answers,
                            jsonb_build_object('text', r.antwort))
      into v_urteil
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;
    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
        r.source_ref, r.antwort, coalesce(v_urteil,'<null>'), r.erwartet, r.label;
    end if;
  end loop;

  -- 3b: kein TERM-Zweig (Rest hinter der Zahl leer).
  for r in select distinct s.acceptance ->> 'canonical' as canon
             from task_solutions s join tasks t on t.id = s.task_id
            where t.source = 'edvance_fundament' and t.source_ref like 'geo-%'
  loop
    if not public.lsa_is_unit((public.lsa_split_value_unit(r.canon))[2]) then
      v_fehler := v_fehler + 1;
      raise warning 'canonical % betritt den TERM/Einheit-Zweig', r.canon;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  select count(*) into v_anzahl from tasks
   where source='edvance_fundament' and source_ref like 'geo-%' and status <> 'draft';
  if v_anzahl > 0 then raise exception '% Aufgabe(n) nicht draft.', v_anzahl; end if;

  raise notice 'Geometrie-Fundament: alle Proben bestanden (38 Aufgaben).';
end $$;

commit;
