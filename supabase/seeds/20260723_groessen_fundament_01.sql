-- ============================================================================
-- Größen und Einheiten — Fundament-Charge 2 als DRAFT (34 Aufgaben)
--
-- ERZEUGT von scripts/content/fundament_charge2.py. Nicht von Hand pflegen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/<diese-datei>.sql
--
-- SETZT A13 (TERM-Grader-Fix) + A14 (skills, tasks.skill_key) VORAUS.
--
-- ANTWORTFORM: input_type NUMERIC, canonical ist eine REINE ZAHL. Die Einheit
-- steht im Fragetext und in tasks.unit (-> payload.unit). Das Kind tippt nur die
-- Zahl. Weil der Rest hinter der Zahl leer ist, greift der Wert-Pfad von
-- lsa_grade, NICHT der TERM-Zweig (Selbsttest 3b unten zeigt es).
--
-- STATUS: alles 'draft'. Freigabe ist Lenas Schritt.
-- SOLUTION-LEAK: canonical + known_errors nur in task_solutions (kein
-- anon/authenticated-Grant). tasks.question_payload traegt nur prompt + unit.
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='tasks' and column_name='skill_key') then
    raise exception 'tasks.skill_key fehlt — A14 erst einspielen.';
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
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.unit, v.payload
from (values
  ('groessen-laengen-01', 'groessen_laengen', 'Größen · Längen · 3 m', 'Wandle um.

3 m = ? cm', 'I', 'cm', jsonb_build_object('kind','short_input','prompt','Wandle um.

3 m = ? cm')),
  ('groessen-laengen-02', 'groessen_laengen', 'Größen · Längen · 250 cm', 'Wandle um.

250 cm = ? m', 'I', 'm', jsonb_build_object('kind','short_input','prompt','Wandle um.

250 cm = ? m')),
  ('groessen-laengen-03', 'groessen_laengen', 'Größen · Längen · 4,2 m', 'Wandle um.

4,2 m = ? mm', 'I', 'mm', jsonb_build_object('kind','short_input','prompt','Wandle um.

4,2 m = ? mm')),
  ('groessen-laengen-04', 'groessen_laengen', 'Größen · Längen · 7500 mm', 'Wandle um.

7500 mm = ? m', 'I', 'm', jsonb_build_object('kind','short_input','prompt','Wandle um.

7500 mm = ? m')),
  ('groessen-laengen-05', 'groessen_laengen', 'Größen · Längen · 6 km', 'Wandle um.

6 km = ? m', 'I', 'm', jsonb_build_object('kind','short_input','prompt','Wandle um.

6 km = ? m')),
  ('groessen-laengen-06', 'groessen_laengen', 'Größen · Längen · 3200 m', 'Wandle um.

3200 m = ? km', 'I', 'km', jsonb_build_object('kind','short_input','prompt','Wandle um.

3200 m = ? km')),
  ('groessen-massen-01', 'groessen_massen', 'Größen · Massen · 3 kg', 'Wandle um.

3 kg = ? g', 'I', 'g', jsonb_build_object('kind','short_input','prompt','Wandle um.

3 kg = ? g')),
  ('groessen-massen-02', 'groessen_massen', 'Größen · Massen · 2500 g', 'Wandle um.

2500 g = ? kg', 'I', 'kg', jsonb_build_object('kind','short_input','prompt','Wandle um.

2500 g = ? kg')),
  ('groessen-massen-03', 'groessen_massen', 'Größen · Massen · 4 t', 'Wandle um.

4 t = ? kg', 'I', 'kg', jsonb_build_object('kind','short_input','prompt','Wandle um.

4 t = ? kg')),
  ('groessen-massen-04', 'groessen_massen', 'Größen · Massen · 750 g', 'Wandle um.

750 g = ? kg', 'I', 'kg', jsonb_build_object('kind','short_input','prompt','Wandle um.

750 g = ? kg')),
  ('groessen-massen-05', 'groessen_massen', 'Größen · Massen · 5000 mg', 'Wandle um.

5000 mg = ? g', 'I', 'g', jsonb_build_object('kind','short_input','prompt','Wandle um.

5000 mg = ? g')),
  ('groessen-zeit-01', 'groessen_zeit', 'Größen · Zeit · 150 min', 'Wandle um.

150 min = ? h', 'I', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

150 min = ? h')),
  ('groessen-zeit-02', 'groessen_zeit', 'Größen · Zeit · 66 min', 'Wandle um.

66 min = ? h', 'I', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

66 min = ? h')),
  ('groessen-zeit-03', 'groessen_zeit', 'Größen · Zeit · 198 min', 'Wandle um.

198 min = ? h', 'I', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

198 min = ? h')),
  ('groessen-zeit-04', 'groessen_zeit', 'Größen · Zeit · 168 min', 'Wandle um.

168 min = ? h', 'I', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

168 min = ? h')),
  ('groessen-zeit-05', 'groessen_zeit', 'Größen · Zeit · 75 min', 'Wandle um.

75 min = ? h', 'II', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

75 min = ? h')),
  ('groessen-zeit-06', 'groessen_zeit', 'Größen · Zeit · 225 min', 'Wandle um.

225 min = ? h', 'II', 'h', jsonb_build_object('kind','short_input','prompt','Wandle um.

225 min = ? h')),
  ('groessen-flaechen-01', 'groessen_flaechen', 'Größen · Flächen · 3 dm²', 'Wandle um.

3 dm² = ? cm²', 'II', 'cm²', jsonb_build_object('kind','short_input','prompt','Wandle um.

3 dm² = ? cm²')),
  ('groessen-flaechen-02', 'groessen_flaechen', 'Größen · Flächen · 250 cm²', 'Wandle um.

250 cm² = ? dm²', 'II', 'dm²', jsonb_build_object('kind','short_input','prompt','Wandle um.

250 cm² = ? dm²')),
  ('groessen-flaechen-03', 'groessen_flaechen', 'Größen · Flächen · 4 m²', 'Wandle um.

4 m² = ? dm²', 'II', 'dm²', jsonb_build_object('kind','short_input','prompt','Wandle um.

4 m² = ? dm²')),
  ('groessen-flaechen-04', 'groessen_flaechen', 'Größen · Flächen · 3000000 mm²', 'Wandle um.

3000000 mm² = ? m²', 'II', 'm²', jsonb_build_object('kind','short_input','prompt','Wandle um.

3000000 mm² = ? m²')),
  ('groessen-flaechen-05', 'groessen_flaechen', 'Größen · Flächen · 4000000 cm²', 'Wandle um.

4000000 cm² = ? a', 'II', 'a', jsonb_build_object('kind','short_input','prompt','Wandle um.

4000000 cm² = ? a')),
  ('groessen-flaechen-06', 'groessen_flaechen', 'Größen · Flächen · 5000000 dm²', 'Wandle um.

5000000 dm² = ? ha', 'II', 'ha', jsonb_build_object('kind','short_input','prompt','Wandle um.

5000000 dm² = ? ha')),
  ('groessen-volumen-01', 'groessen_volumen', 'Größen · Volumen · 2 l', 'Wandle um.

2 l = ? cm³', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Wandle um.

2 l = ? cm³')),
  ('groessen-volumen-02', 'groessen_volumen', 'Größen · Volumen · 3 l', 'Wandle um.

3 l = ? ml', 'II', 'ml', jsonb_build_object('kind','short_input','prompt','Wandle um.

3 l = ? ml')),
  ('groessen-volumen-03', 'groessen_volumen', 'Größen · Volumen · 5000 cm³', 'Wandle um.

5000 cm³ = ? l', 'II', 'l', jsonb_build_object('kind','short_input','prompt','Wandle um.

5000 cm³ = ? l')),
  ('groessen-volumen-04', 'groessen_volumen', 'Größen · Volumen · 4 dm³', 'Wandle um.

4 dm³ = ? cm³', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Wandle um.

4 dm³ = ? cm³')),
  ('groessen-volumen-05', 'groessen_volumen', 'Größen · Volumen · 6000 mm³', 'Wandle um.

6000 mm³ = ? cm³', 'II', 'cm³', jsonb_build_object('kind','short_input','prompt','Wandle um.

6000 mm³ = ? cm³')),
  ('groessen-gemischt-01', 'groessen_gemischt', 'Größen · Gemischt · 1,05 m', 'Wandle um.

1,05 m = ? cm', 'II', 'cm', jsonb_build_object('kind','short_input','prompt','Wandle um.

1,05 m = ? cm')),
  ('groessen-gemischt-02', 'groessen_gemischt', 'Größen · Gemischt · 2,08 kg', 'Wandle um.

2,08 kg = ? g', 'II', 'g', jsonb_build_object('kind','short_input','prompt','Wandle um.

2,08 kg = ? g')),
  ('groessen-gemischt-03', 'groessen_gemischt', 'Größen · Gemischt · 3,4 kg', 'Wandle um.

3,4 kg = ? g', 'II', 'g', jsonb_build_object('kind','short_input','prompt','Wandle um.

3,4 kg = ? g')),
  ('groessen-gemischt-04', 'groessen_gemischt', 'Größen · Gemischt · 2,5 h', 'Wandle um.

2,5 h = ? min', 'II', 'min', jsonb_build_object('kind','short_input','prompt','Wandle um.

2,5 h = ? min')),
  ('groessen-gemischt-05', 'groessen_gemischt', 'Größen · Gemischt · 1,25 h', 'Wandle um.

1,25 h = ? min', 'II', 'min', jsonb_build_object('kind','short_input','prompt','Wandle um.

1,25 h = ? min')),
  ('groessen-gemischt-06', 'groessen_gemischt', 'Größen · Gemischt · 4,05 m', 'Wandle um.

4,05 m = ? cm', 'II', 'cm', jsonb_build_object('kind','short_input','prompt','Wandle um.

4,05 m = ? cm'))
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('groessen-laengen-01', '["300"]', '{"canonical": "300", "known_errors": {"0,03": "richtung_vertauscht", "30": "einheit_uebersprungen", "3000": "faktor_zehn_daneben"}}'),
  ('groessen-laengen-02', '["2,5"]', '{"canonical": "2,5", "known_errors": {"25000": "richtung_vertauscht", "25": "einheit_uebersprungen", "0,25": "faktor_zehn_daneben"}}'),
  ('groessen-laengen-03', '["4200"]', '{"canonical": "4200", "known_errors": {"0,0042": "richtung_vertauscht", "420": "einheit_uebersprungen", "42000": "faktor_zehn_daneben"}}'),
  ('groessen-laengen-04', '["7,5"]', '{"canonical": "7,5", "known_errors": {"7500000": "richtung_vertauscht", "75": "einheit_uebersprungen", "0,75": "faktor_zehn_daneben"}}'),
  ('groessen-laengen-05', '["6000"]', '{"canonical": "6000", "known_errors": {"0,006": "richtung_vertauscht", "600": "einheit_uebersprungen", "60000": "faktor_zehn_daneben"}}'),
  ('groessen-laengen-06', '["3,2"]', '{"canonical": "3,2", "known_errors": {"3200000": "richtung_vertauscht", "32": "einheit_uebersprungen", "0,32": "faktor_zehn_daneben"}}'),
  ('groessen-massen-01', '["3000"]', '{"canonical": "3000", "known_errors": {"0,003": "richtung_vertauscht", "30000": "faktor_zehn_daneben", "300": "faktor_hundert_statt_tausend"}}'),
  ('groessen-massen-02', '["2,5"]', '{"canonical": "2,5", "known_errors": {"2500000": "richtung_vertauscht", "0,25": "faktor_zehn_daneben", "25": "faktor_hundert_statt_tausend"}}'),
  ('groessen-massen-03', '["4000"]', '{"canonical": "4000", "known_errors": {"0,004": "richtung_vertauscht", "40000": "faktor_zehn_daneben", "400": "faktor_hundert_statt_tausend"}}'),
  ('groessen-massen-04', '["0,75"]', '{"canonical": "0,75", "known_errors": {"750000": "richtung_vertauscht", "0,075": "faktor_zehn_daneben", "7,5": "faktor_hundert_statt_tausend"}}'),
  ('groessen-massen-05', '["5"]', '{"canonical": "5", "known_errors": {"5000000": "richtung_vertauscht", "0,5": "faktor_zehn_daneben", "50": "faktor_hundert_statt_tausend"}}'),
  ('groessen-zeit-01', '["2,5"]', '{"canonical": "2,5", "known_errors": {"9000": "richtung_vertauscht", "2,3": "dezimal_statt_sexagesimal", "1,5": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-zeit-02', '["1,1"]', '{"canonical": "1,1", "known_errors": {"3960": "richtung_vertauscht", "1,06": "dezimal_statt_sexagesimal", "0,66": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-zeit-03', '["3,3"]', '{"canonical": "3,3", "known_errors": {"11880": "richtung_vertauscht", "3,18": "dezimal_statt_sexagesimal", "1,98": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-zeit-04', '["2,8"]', '{"canonical": "2,8", "known_errors": {"10080": "richtung_vertauscht", "2,48": "dezimal_statt_sexagesimal", "1,68": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-zeit-05', '["1,25"]', '{"canonical": "1,25", "known_errors": {"4500": "richtung_vertauscht", "1,15": "dezimal_statt_sexagesimal", "0,75": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-zeit-06', '["3,75"]', '{"canonical": "3,75", "known_errors": {"13500": "richtung_vertauscht", "3,45": "dezimal_statt_sexagesimal", "2,25": "faktor_hundert_statt_sechzig"}}'),
  ('groessen-flaechen-01', '["300"]', '{"canonical": "300", "known_errors": {"30": "linearer_faktor", "0,03": "richtung_vertauscht", "3": "einheit_uebersprungen"}}'),
  ('groessen-flaechen-02', '["2,5"]', '{"canonical": "2,5", "known_errors": {"25": "linearer_faktor", "25000": "richtung_vertauscht", "250": "einheit_uebersprungen"}}'),
  ('groessen-flaechen-03', '["400"]', '{"canonical": "400", "known_errors": {"40": "linearer_faktor", "0,04": "richtung_vertauscht", "4": "einheit_uebersprungen"}}'),
  ('groessen-flaechen-04', '["3"]', '{"canonical": "3", "known_errors": {"3000": "linearer_faktor", "300": "einheit_uebersprungen"}}'),
  ('groessen-flaechen-05', '["4"]', '{"canonical": "4", "known_errors": {"4000": "linearer_faktor", "400": "einheit_uebersprungen"}}'),
  ('groessen-flaechen-06', '["5"]', '{"canonical": "5", "known_errors": {"5000": "linearer_faktor", "500": "einheit_uebersprungen"}}'),
  ('groessen-volumen-01', '["2000"]', '{"canonical": "2000", "known_errors": {"20": "linearer_faktor", "0,002": "richtung_vertauscht", "2": "liter_kubik_falsch"}}'),
  ('groessen-volumen-02', '["3000"]', '{"canonical": "3000", "known_errors": {"30": "linearer_faktor", "0,003": "richtung_vertauscht", "3": "liter_kubik_falsch"}}'),
  ('groessen-volumen-03', '["5"]', '{"canonical": "5", "known_errors": {"500": "linearer_faktor", "5000000": "richtung_vertauscht", "5000": "liter_kubik_falsch"}}'),
  ('groessen-volumen-04', '["4000"]', '{"canonical": "4000", "known_errors": {"40": "linearer_faktor", "0,004": "richtung_vertauscht"}}'),
  ('groessen-volumen-05', '["6"]', '{"canonical": "6", "known_errors": {"600": "linearer_faktor", "6000000": "richtung_vertauscht"}}'),
  ('groessen-gemischt-01', '["105"]', '{"canonical": "105", "known_errors": {"150": "fuehrende_null_ignoriert"}}'),
  ('groessen-gemischt-02', '["2080"]', '{"canonical": "2080", "known_errors": {"2800": "fuehrende_null_ignoriert"}}'),
  ('groessen-gemischt-03', '["3400"]', '{"canonical": "3400", "known_errors": {"3004": "komma_als_trenner"}}'),
  ('groessen-gemischt-04', '["150"]', '{"canonical": "150", "known_errors": {"170": "dezimal_statt_sexagesimal", "125": "komma_als_trenner"}}'),
  ('groessen-gemischt-05', '["75"]', '{"canonical": "75", "known_errors": {"85": "dezimal_statt_sexagesimal"}}'),
  ('groessen-gemischt-06', '["405"]', '{"canonical": "405", "known_errors": {"450": "fuehrende_null_ignoriert"}}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── Selbsttest ─────────────────────────────────────────────────────────────
--   canonical -> 'voll', jedes Fehlbild -> 'nicht'. Weicht eine Probe ab,
--   bricht die Transaktion ab und NICHTS wird eingespielt.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
  v_anzahl int;
begin
  for r in
    select * from (values
      ('groessen-laengen-01', '300', 'voll', 'canonical'),
      ('groessen-laengen-01', '0,03', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-01', '30', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-01', '3000', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-laengen-02', '2,5', 'voll', 'canonical'),
      ('groessen-laengen-02', '25000', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-02', '25', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-02', '0,25', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-laengen-03', '4200', 'voll', 'canonical'),
      ('groessen-laengen-03', '0,0042', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-03', '420', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-03', '42000', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-laengen-04', '7,5', 'voll', 'canonical'),
      ('groessen-laengen-04', '7500000', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-04', '75', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-04', '0,75', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-laengen-05', '6000', 'voll', 'canonical'),
      ('groessen-laengen-05', '0,006', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-05', '600', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-05', '60000', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-laengen-06', '3,2', 'voll', 'canonical'),
      ('groessen-laengen-06', '3200000', 'nicht', 'richtung_vertauscht'),
      ('groessen-laengen-06', '32', 'nicht', 'einheit_uebersprungen'),
      ('groessen-laengen-06', '0,32', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-01', '3000', 'voll', 'canonical'),
      ('groessen-massen-01', '0,003', 'nicht', 'richtung_vertauscht'),
      ('groessen-massen-01', '30000', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-01', '300', 'nicht', 'faktor_hundert_statt_tausend'),
      ('groessen-massen-02', '2,5', 'voll', 'canonical'),
      ('groessen-massen-02', '2500000', 'nicht', 'richtung_vertauscht'),
      ('groessen-massen-02', '0,25', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-02', '25', 'nicht', 'faktor_hundert_statt_tausend'),
      ('groessen-massen-03', '4000', 'voll', 'canonical'),
      ('groessen-massen-03', '0,004', 'nicht', 'richtung_vertauscht'),
      ('groessen-massen-03', '40000', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-03', '400', 'nicht', 'faktor_hundert_statt_tausend'),
      ('groessen-massen-04', '0,75', 'voll', 'canonical'),
      ('groessen-massen-04', '750000', 'nicht', 'richtung_vertauscht'),
      ('groessen-massen-04', '0,075', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-04', '7,5', 'nicht', 'faktor_hundert_statt_tausend'),
      ('groessen-massen-05', '5', 'voll', 'canonical'),
      ('groessen-massen-05', '5000000', 'nicht', 'richtung_vertauscht'),
      ('groessen-massen-05', '0,5', 'nicht', 'faktor_zehn_daneben'),
      ('groessen-massen-05', '50', 'nicht', 'faktor_hundert_statt_tausend'),
      ('groessen-zeit-01', '2,5', 'voll', 'canonical'),
      ('groessen-zeit-01', '9000', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-01', '2,3', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-01', '1,5', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-zeit-02', '1,1', 'voll', 'canonical'),
      ('groessen-zeit-02', '3960', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-02', '1,06', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-02', '0,66', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-zeit-03', '3,3', 'voll', 'canonical'),
      ('groessen-zeit-03', '11880', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-03', '3,18', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-03', '1,98', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-zeit-04', '2,8', 'voll', 'canonical'),
      ('groessen-zeit-04', '10080', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-04', '2,48', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-04', '1,68', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-zeit-05', '1,25', 'voll', 'canonical'),
      ('groessen-zeit-05', '4500', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-05', '1,15', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-05', '0,75', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-zeit-06', '3,75', 'voll', 'canonical'),
      ('groessen-zeit-06', '13500', 'nicht', 'richtung_vertauscht'),
      ('groessen-zeit-06', '3,45', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-zeit-06', '2,25', 'nicht', 'faktor_hundert_statt_sechzig'),
      ('groessen-flaechen-01', '300', 'voll', 'canonical'),
      ('groessen-flaechen-01', '30', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-01', '0,03', 'nicht', 'richtung_vertauscht'),
      ('groessen-flaechen-01', '3', 'nicht', 'einheit_uebersprungen'),
      ('groessen-flaechen-02', '2,5', 'voll', 'canonical'),
      ('groessen-flaechen-02', '25', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-02', '25000', 'nicht', 'richtung_vertauscht'),
      ('groessen-flaechen-02', '250', 'nicht', 'einheit_uebersprungen'),
      ('groessen-flaechen-03', '400', 'voll', 'canonical'),
      ('groessen-flaechen-03', '40', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-03', '0,04', 'nicht', 'richtung_vertauscht'),
      ('groessen-flaechen-03', '4', 'nicht', 'einheit_uebersprungen'),
      ('groessen-flaechen-04', '3', 'voll', 'canonical'),
      ('groessen-flaechen-04', '3000', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-04', '300', 'nicht', 'einheit_uebersprungen'),
      ('groessen-flaechen-05', '4', 'voll', 'canonical'),
      ('groessen-flaechen-05', '4000', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-05', '400', 'nicht', 'einheit_uebersprungen'),
      ('groessen-flaechen-06', '5', 'voll', 'canonical'),
      ('groessen-flaechen-06', '5000', 'nicht', 'linearer_faktor'),
      ('groessen-flaechen-06', '500', 'nicht', 'einheit_uebersprungen'),
      ('groessen-volumen-01', '2000', 'voll', 'canonical'),
      ('groessen-volumen-01', '20', 'nicht', 'linearer_faktor'),
      ('groessen-volumen-01', '0,002', 'nicht', 'richtung_vertauscht'),
      ('groessen-volumen-01', '2', 'nicht', 'liter_kubik_falsch'),
      ('groessen-volumen-02', '3000', 'voll', 'canonical'),
      ('groessen-volumen-02', '30', 'nicht', 'linearer_faktor'),
      ('groessen-volumen-02', '0,003', 'nicht', 'richtung_vertauscht'),
      ('groessen-volumen-02', '3', 'nicht', 'liter_kubik_falsch'),
      ('groessen-volumen-03', '5', 'voll', 'canonical'),
      ('groessen-volumen-03', '500', 'nicht', 'linearer_faktor'),
      ('groessen-volumen-03', '5000000', 'nicht', 'richtung_vertauscht'),
      ('groessen-volumen-03', '5000', 'nicht', 'liter_kubik_falsch'),
      ('groessen-volumen-04', '4000', 'voll', 'canonical'),
      ('groessen-volumen-04', '40', 'nicht', 'linearer_faktor'),
      ('groessen-volumen-04', '0,004', 'nicht', 'richtung_vertauscht'),
      ('groessen-volumen-05', '6', 'voll', 'canonical'),
      ('groessen-volumen-05', '600', 'nicht', 'linearer_faktor'),
      ('groessen-volumen-05', '6000000', 'nicht', 'richtung_vertauscht'),
      ('groessen-gemischt-01', '105', 'voll', 'canonical'),
      ('groessen-gemischt-01', '150', 'nicht', 'fuehrende_null_ignoriert'),
      ('groessen-gemischt-02', '2080', 'voll', 'canonical'),
      ('groessen-gemischt-02', '2800', 'nicht', 'fuehrende_null_ignoriert'),
      ('groessen-gemischt-03', '3400', 'voll', 'canonical'),
      ('groessen-gemischt-03', '3004', 'nicht', 'komma_als_trenner'),
      ('groessen-gemischt-04', '150', 'voll', 'canonical'),
      ('groessen-gemischt-04', '170', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-gemischt-04', '125', 'nicht', 'komma_als_trenner'),
      ('groessen-gemischt-05', '75', 'voll', 'canonical'),
      ('groessen-gemischt-05', '85', 'nicht', 'dezimal_statt_sexagesimal'),
      ('groessen-gemischt-06', '405', 'voll', 'canonical'),
      ('groessen-gemischt-06', '450', 'nicht', 'fuehrende_null_ignoriert')
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

  -- 3b: diese Aufgaben betreten den TERM-Zweig NICHT (Rest hinter der Zahl leer).
  for r in
    select distinct s.acceptance ->> 'canonical' as canon
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref like 'groessen-%'
  loop
    if not public.lsa_is_unit((public.lsa_split_value_unit(r.canon))[2]) then
      v_fehler := v_fehler + 1;
      raise warning 'canonical % betritt den TERM/Einheit-Zweig — Rest ist keine leere Einheit', r.canon;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  select count(*) into v_anzahl from tasks
   where source='edvance_fundament' and source_ref like 'groessen-%' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  raise notice 'Größen und Einheiten: alle Proben bestanden.';
end $$;

commit;
