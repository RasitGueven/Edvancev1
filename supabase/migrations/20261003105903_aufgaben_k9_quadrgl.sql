-- K9-Rest, Thema quadrgl — 24 Aufgaben: je sechs zu gleichung_quadr_wurzel, _faktor, _formel und _anzahl.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-quadrgl.json (Quelle: tools/k9-quadrgl-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105854_substrat_k9_quadrgl.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Beet, Ball, Rechteck, Zaun) und eine Problemlöse- oder Rückrichtungsaufgabe. Zwei Lösungen immer als MULTI_PART (Teil 1 kleinere, Teil 2 größere Lösung), eine Lösung als NUMERIC. Alle ohne Abbildung lösbar; jede Aufgabe nennt „exakt" oder die Rundung (exakter Textvergleich, keine Toleranz).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-quadrgl.csv. Pruefprotokoll: docs/prefill/k9-quadrgl-verifikation.md.
--
-- Loesungen ueber public.task_solution_upsert. Die RPC laesst nur admin, Pruefer oder
-- einen Systemaufruf (ist_systemaufruf(): auth.role() = 'service_role') schreiben.
-- In Prod liefert auth.role() ohne JWT NULL (-> Systemaufruf), in der CI-Grundlage
-- (supabase/test-grundlage.sql) aber 'anon' — dort scheiterte die Datei mit "kein
-- Pruefrecht". Deshalb erklaert sie sich ausdruecklich und TRANSAKTIONSLOKAL als
-- Systemaufruf (set_config(..., true)); die Einstellung endet mit dem commit.
-- correct_answers traegt bei MULTI_PART je
-- Teilaufgabe ein Array; acceptance.known_errors in Objektform {falscher_wert: slug},
-- genau so liest lsa_fehlbild_match sie.
--
-- cluster_id per Unterabfrage auf die feste id: skill_clusters wird geseedet, nicht
-- migriert — im CI-Neuaufbau bleibt cluster_id null, in Prod trifft die id.
-- Figuren: task_figures-Zeilen ohne svg_hash; die Abbildung erscheint erst nach
-- scripts/figures/upload_figures.py (Rasit). Bis dahin liefert der Payload kein Bild.
--
-- Sondierrang (Verfahren docs/sondierrang_vorschlag.md, Profil = Menge der Slugs,
-- bei MULTI_PART ueber alle Teile):
--   gleichung_quadr_wurzel: quadrgl-wurzel-06 = 1, quadrgl-wurzel-02 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,quadrat_gliedweise,vorzeichen_aus_klammer,wurzel_vergessen}, Rang 2 aus Profil {falsche_gegenoperation,negative_loesung_vergessen,wurzel_vergessen} (2 neue Fehlbilder)
--   gleichung_quadr_faktor: quadrgl-faktor-04 = 1, quadrgl-faktor-05 = 2. Rang 1 aus Profil {division_vergessen,loesung_null_verloren,vorzeichen_aus_klammer}, Rang 2 aus Profil {division_vergessen,vorzeichen_beim_umstellen} (1 neue Fehlbilder)
--   gleichung_quadr_formel: quadrgl-formel-05 = 1, quadrgl-formel-03 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,pq_vorzeichen,wurzel_vergessen}, Rang 2 aus Profil {division_vergessen,pq_vorzeichen} (1 neue Fehlbilder)
--   gleichung_quadr_anzahl: quadrgl-anzahl-06 = 1, quadrgl-anzahl-04 = 2. Rang 1 aus Profil {betrag_fehler,halbieren_vergessen}, Rang 2 aus Profil {division_vergessen,vorzeichen_potenz} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 quadrgl-wurzel-01 · Wurzelziehen · x² = 49
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9264f90a-1f7b-4170-97da-198c1acc89a3'::uuid, 'exercise', 'Wurzelziehen · x² = 49', 'Löse die Gleichung x² = 49.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: reine Quadratgleichung, Wurzel einer Quadratzahl, beide Vorzeichen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negative_loesung_vergessen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9264f90a-1f7b-4170-97da-198c1acc89a3'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9264f90a-1f7b-4170-97da-198c1acc89a3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9264f90a-1f7b-4170-97da-198c1acc89a3'::uuid,
  p_correct_answers => '{"1":["-7","−7","- 7"],"2":["7","+7"]}'::jsonb,
  p_solution        => 'x² = 49 hat zwei Lösungen: x = √49 oder x = −√49.
√49 = 7.
Kleinere Lösung: -7. Größere Lösung: 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die positive Lösung 7 gefunden, die negative fehlt.","socratic_question":"Welche Zahl ergibt mit sich selbst multipliziert ebenfalls 49?"},{"error":"Die Wurzel nicht gezogen: −49.","socratic_question":"Ist x selbst 49 oder ist x² gleich 49?"},{"error":"Die Wurzel nicht gezogen: 49.","socratic_question":"Ergibt 49 · 49 wirklich 49?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-7","equivalents":["−7","- 7"],"known_errors":{"7":"negative_loesung_vergessen","+7":"negative_loesung_vergessen","-49":"wurzel_vergessen","−49":"wurzel_vergessen","- 49":"wurzel_vergessen"}},"2":{"canonical":"7","equivalents":["+7"],"known_errors":{"49":"wurzel_vergessen","+49":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #2 quadrgl-wurzel-02 · Wurzelziehen · 2x² − 18 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4d1a2438-3610-4dc9-b5be-8d35cb5199bd'::uuid, 'exercise', 'Wurzelziehen · 2x² − 18 = 0', 'Löse die Gleichung 2x² − 18 = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: erst nach x² umstellen (zwei Schritte), dann Wurzel einer Quadratzahl.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negative_loesung_vergessen, falsche_gegenoperation, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4d1a2438-3610-4dc9-b5be-8d35cb5199bd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4d1a2438-3610-4dc9-b5be-8d35cb5199bd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4d1a2438-3610-4dc9-b5be-8d35cb5199bd'::uuid,
  p_correct_answers => '{"1":["-3","−3","- 3"],"2":["3","+3"]}'::jsonb,
  p_solution        => '2x² − 18 = 0 | + 18
2x² = 18 | : 2
x² = 9
x = −√9 oder x = √9.
Kleinere Lösung: -3. Größere Lösung: 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die positive Lösung 3 gefunden, die negative fehlt.","socratic_question":"Welche zweite Zahl ergibt quadriert ebenfalls 9?"},{"error":"Mit 2 multipliziert statt durch 2 geteilt: x² = 36.","socratic_question":"Wie macht man ein „mal 2\" rückgängig?"},{"error":"Bei x² = 9 aufgehört, die Wurzel nicht gezogen.","socratic_question":"Steht nach dem Umstellen schon x oder noch x² da?"},{"error":"Mit 2 multipliziert statt durch 2 geteilt: x² = 36.","socratic_question":"Wie macht man ein „mal 2\" rückgängig?"},{"error":"Bei x² = 9 aufgehört, die Wurzel nicht gezogen.","socratic_question":"Steht nach dem Umstellen schon x oder noch x² da?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"3":"negative_loesung_vergessen","+3":"negative_loesung_vergessen","-6":"falsche_gegenoperation","−6":"falsche_gegenoperation","- 6":"falsche_gegenoperation","-9":"wurzel_vergessen","−9":"wurzel_vergessen","- 9":"wurzel_vergessen"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"6":"falsche_gegenoperation","9":"wurzel_vergessen","+6":"falsche_gegenoperation","+9":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #3 quadrgl-wurzel-03 · Wurzelziehen · (x − 2)² = 25
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '504bbd98-9c80-4124-a66a-9dc7b6651bb9'::uuid, 'exercise', 'Wurzelziehen · (x − 2)² = 25', 'Löse die Gleichung (x − 2)² = 25.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel aus der Klammer ziehen, zwei Fälle getrennt nach x auflösen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, negative_loesung_vergessen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '504bbd98-9c80-4124-a66a-9dc7b6651bb9'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '504bbd98-9c80-4124-a66a-9dc7b6651bb9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '504bbd98-9c80-4124-a66a-9dc7b6651bb9'::uuid,
  p_correct_answers => '{"1":["-3","−3","- 3"],"2":["7","+7"]}'::jsonb,
  p_solution        => '(x − 2)² = 25
x − 2 = 5 oder x − 2 = −5 | + 2
x = 7 oder x = −3.
Kleinere Lösung: -3. Größere Lösung: 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 2 aus der Klammer mit falschem Vorzeichen verrechnet: x + 2 = −5.","socratic_question":"Welche Zahl musst du zu x − 2 addieren, damit nur x übrig bleibt?"},{"error":"Nur den Fall x − 2 = 5 gerechnet, der Fall x − 2 = −5 fehlt.","socratic_question":"Welche zweite Zahl ergibt quadriert ebenfalls 25?"},{"error":"Die Wurzel nicht gezogen: x − 2 = −25.","socratic_question":"Ist x − 2 gleich 25 oder ist das Quadrat von x − 2 gleich 25?"},{"error":"Die 2 aus der Klammer mit falschem Vorzeichen verrechnet: x + 2 = 5.","socratic_question":"Welche Zahl musst du zu x − 2 addieren, damit nur x übrig bleibt?"},{"error":"Die Wurzel nicht gezogen: x − 2 = 25.","socratic_question":"Ist x − 2 gleich 25 oder ist das Quadrat von x − 2 gleich 25?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"7":"negative_loesung_vergessen","-7":"vorzeichen_aus_klammer","−7":"vorzeichen_aus_klammer","- 7":"vorzeichen_aus_klammer","+7":"negative_loesung_vergessen","-23":"wurzel_vergessen","−23":"wurzel_vergessen","- 23":"wurzel_vergessen"}},"2":{"canonical":"7","equivalents":["+7"],"known_errors":{"3":"vorzeichen_aus_klammer","27":"wurzel_vergessen","+3":"vorzeichen_aus_klammer","+27":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #4 quadrgl-wurzel-04 · Wurzelziehen · 3x² = 60, gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cd6693f5-cc93-4628-baf9-f45436706641'::uuid, 'exercise', 'Wurzelziehen · 3x² = 60, gerundet', 'Löse die Gleichung 3x² = 60.

Runde die Lösungen auf zwei Stellen nach dem Komma.',
  null, 'MULTI_PART', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Koeffizient abdividieren, Wurzel einer Nicht-Quadratzahl, runden.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negative_loesung_vergessen, division_vergessen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cd6693f5-cc93-4628-baf9-f45436706641'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cd6693f5-cc93-4628-baf9-f45436706641'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cd6693f5-cc93-4628-baf9-f45436706641'::uuid,
  p_correct_answers => '{"1":["-4,47","−4,47","- 4,47","-4.47","−4.47","- 4.47"],"2":["4,47","+4,47","4.47","+4.47"]}'::jsonb,
  p_solution        => '3x² = 60 | : 3
x² = 20
x = −√20 oder x = √20, √20 ≈ 4,472.
Kleinere Lösung: -4,47. Größere Lösung: 4,47.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die positive Lösung gefunden, die negative fehlt.","socratic_question":"Welche zweite Zahl ergibt quadriert ebenfalls 20?"},{"error":"Nicht durch 3 geteilt: die Wurzel aus 60 gezogen.","socratic_question":"Steht vor x² noch ein Faktor, wenn du die Wurzel ziehst?"},{"error":"Bei x² = 20 aufgehört, die Wurzel nicht gezogen.","socratic_question":"Ist x gleich 20 oder ist x² gleich 20?"},{"error":"Nicht durch 3 geteilt: die Wurzel aus 60 gezogen.","socratic_question":"Steht vor x² noch ein Faktor, wenn du die Wurzel ziehst?"},{"error":"Bei x² = 20 aufgehört, die Wurzel nicht gezogen.","socratic_question":"Ist x gleich 20 oder ist x² gleich 20?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-4,47","equivalents":["−4,47","- 4,47","-4.47","−4.47","- 4.47"],"known_errors":{"4,47":"negative_loesung_vergessen","+4,47":"negative_loesung_vergessen","4.47":"negative_loesung_vergessen","+4.47":"negative_loesung_vergessen","-7,75":"division_vergessen","−7,75":"division_vergessen","- 7,75":"division_vergessen","-7.75":"division_vergessen","−7.75":"division_vergessen","- 7.75":"division_vergessen","-20,00":"wurzel_vergessen","−20,00":"wurzel_vergessen","- 20,00":"wurzel_vergessen","-20.00":"wurzel_vergessen","−20.00":"wurzel_vergessen","- 20.00":"wurzel_vergessen","-20":"wurzel_vergessen","−20":"wurzel_vergessen","- 20":"wurzel_vergessen"}},"2":{"canonical":"4,47","equivalents":["+4,47","4.47","+4.47"],"known_errors":{"20":"wurzel_vergessen","7,75":"division_vergessen","+7,75":"division_vergessen","7.75":"division_vergessen","+7.75":"division_vergessen","20,00":"wurzel_vergessen","+20,00":"wurzel_vergessen","20.00":"wurzel_vergessen","+20.00":"wurzel_vergessen","+20":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #5 quadrgl-wurzel-05 · Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'bc0cdfe9-2416-4d02-a623-feb820083f07'::uuid, 'exercise', 'Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²', 'Ein rechteckiges Beet ist doppelt so lang wie breit. Sein Flächeninhalt beträgt 98 m².

Wie breit ist das Beet? Als Breite ist nur eine positive Lösung sinnvoll. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechteckiges Beet ist doppelt so lang wie breit. Sein Flächeninhalt beträgt 98 m².\n\nWie breit ist das Beet? Als Breite ist nur eine positive Lösung sinnvoll. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Gleichung 2x² = 98 aufstellen, nur die positive Lösung ist eine Länge.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (division_vergessen, wurzel_vergessen, falsche_gegenoperation).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'bc0cdfe9-2416-4d02-a623-feb820083f07'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'bc0cdfe9-2416-4d02-a623-feb820083f07'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'bc0cdfe9-2416-4d02-a623-feb820083f07'::uuid,
  p_correct_answers => '["7","7 m","7m"]'::jsonb,
  p_solution        => 'Breite x, Länge 2x: x · 2x = 98
2x² = 98 | : 2
x² = 49
x = 7 oder x = −7; eine Breite ist positiv.
Das Beet ist 7 m breit.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht durch 2 geteilt: die Wurzel aus 98 gezogen (≈ 9,90).","socratic_question":"Wie viele Breiten stecken im Flächeninhalt, wenn die Länge 2x ist?"},{"error":"Bei x² = 49 aufgehört, die Wurzel nicht gezogen.","socratic_question":"Ist die Breite 49 m oder ist das Quadrat der Breite 49?"},{"error":"Mit 2 multipliziert statt durch 2 geteilt: x² = 196.","socratic_question":"Wie macht man ein „mal 2\" rückgängig?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["7 m","7m"],"known_errors":{"14":"falsche_gegenoperation","49":"wurzel_vergessen","9,90":"division_vergessen","9.90":"division_vergessen","9,9":"division_vergessen","9.9":"division_vergessen","9,90 m":"division_vergessen","9,90m":"division_vergessen","9,9 m":"division_vergessen","9,9m":"division_vergessen","49 m":"wurzel_vergessen","49m":"wurzel_vergessen","14 m":"falsche_gegenoperation","14m":"falsche_gegenoperation"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 quadrgl-wurzel-06 · Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid, 'exercise', 'Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²', 'Verlängert man jede Seite eines Quadrats um 3 cm, so hat das neue Quadrat einen Flächeninhalt von 121 cm².

Wie lang war eine Seite des ursprünglichen Quadrats? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Verlängert man jede Seite eines Quadrats um 3 cm, so hat das neue Quadrat einen Flächeninhalt von 121 cm².\n\nWie lang war eine Seite des ursprünglichen Quadrats? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_wurzel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, 'cm', false, 1, 'draft', 'edvance_k9_quadrgl', 'quadrgl-wurzel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Gleichung (x + 3)² = 121 selbst aufstellen, lösen und die sinnvolle Lösung wählen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, falsche_groesse_beantwortet, quadrat_gliedweise, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3a42b89c-7f8a-4b64-94ff-d1d4ac576c32'::uuid,
  p_correct_answers => '["8","8 cm","8cm"]'::jsonb,
  p_solution        => 'Ursprüngliche Seite x: (x + 3)² = 121
x + 3 = 11 oder x + 3 = −11 | − 3
x = 8 oder x = −14; eine Seitenlänge ist positiv.
Die Seite war 8 cm lang.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 3 aus der Klammer mit falschem Vorzeichen verrechnet: 11 + 3.","socratic_question":"War das ursprüngliche Quadrat kleiner oder größer als das neue?"},{"error":"Die Seite des neuen Quadrats angegeben, nicht die des ursprünglichen.","socratic_question":"Nach welchem der beiden Quadrate ist gefragt?"},{"error":"Die Klammer gliedweise quadriert: x² + 9 = 121 (≈ 10,58).","socratic_question":"Was ergibt (x + 3) · (x + 3) ausmultipliziert?"},{"error":"Die Wurzel nicht gezogen: x + 3 = 121.","socratic_question":"Ist die neue Seite 121 cm lang oder ist ihr Quadrat 121?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["8 cm","8cm"],"known_errors":{"11":"falsche_groesse_beantwortet","14":"vorzeichen_aus_klammer","118":"wurzel_vergessen","14 cm":"vorzeichen_aus_klammer","14cm":"vorzeichen_aus_klammer","11 cm":"falsche_groesse_beantwortet","11cm":"falsche_groesse_beantwortet","10,58":"quadrat_gliedweise","10.58":"quadrat_gliedweise","10,58 cm":"quadrat_gliedweise","10,58cm":"quadrat_gliedweise","118 cm":"wurzel_vergessen","118cm":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 quadrgl-faktor-01 · Ausklammern · x² − 5x = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b47ef7d3-1933-416f-8fe8-edcbc8fe8929'::uuid, 'exercise', 'Ausklammern · x² − 5x = 0', 'Löse die Gleichung x² − 5x = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: x ausklammern, Satz vom Nullprodukt, ganzzahlige Lösungen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (loesung_null_verloren, vorzeichen_aus_klammer).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b47ef7d3-1933-416f-8fe8-edcbc8fe8929'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b47ef7d3-1933-416f-8fe8-edcbc8fe8929'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b47ef7d3-1933-416f-8fe8-edcbc8fe8929'::uuid,
  p_correct_answers => '{"1":["0"],"2":["5","+5"]}'::jsonb,
  p_solution        => 'x ausklammern: x · (x − 5) = 0.
Ein Produkt ist null, wenn ein Faktor null ist: x = 0 oder x − 5 = 0, also x = 5.
Kleinere Lösung: 0. Größere Lösung: 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch x geteilt und dabei die Lösung x = 0 verloren.","socratic_question":"Was ergibt die linke Seite, wenn du x = 0 einsetzt?"},{"error":"Aus (x − 5) den Wert −5 abgelesen statt 5.","socratic_question":"Für welches x wird x − 5 wirklich null?"},{"error":"Aus (x − 5) den Wert −5 abgelesen; dann wäre 0 die größere Lösung.","socratic_question":"Setze −5 in x − 5 ein: Kommt null heraus?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0","known_errors":{"5":"loesung_null_verloren","+5":"loesung_null_verloren","-5":"vorzeichen_aus_klammer","−5":"vorzeichen_aus_klammer","- 5":"vorzeichen_aus_klammer"}},"2":{"canonical":"5","equivalents":["+5"],"known_errors":{"0":"vorzeichen_aus_klammer"}}}'::jsonb);
  end if;
end
$loesung$;

-- #8 quadrgl-faktor-02 · Nullprodukt · (x − 3)(x + 5) = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1c4a31af-20bc-4348-b8d9-cd83b273ff38'::uuid, 'exercise', 'Nullprodukt · (x − 3)(x + 5) = 0', 'Löse die Gleichung (x − 3)(x + 5) = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gleichung liegt schon als Produkt vor, Faktoren einzeln null setzen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1c4a31af-20bc-4348-b8d9-cd83b273ff38'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1c4a31af-20bc-4348-b8d9-cd83b273ff38'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1c4a31af-20bc-4348-b8d9-cd83b273ff38'::uuid,
  p_correct_answers => '{"1":["-5","−5","- 5"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'Ein Produkt ist null, wenn ein Faktor null ist.
x − 3 = 0, also x = 3, oder x + 5 = 0, also x = −5.
Kleinere Lösung: -5. Größere Lösung: 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Werte aus den Klammern mit falschem Vorzeichen abgelesen: 5 und −3.","socratic_question":"Für welches x wird x + 5 null?"},{"error":"Die Werte aus den Klammern mit falschem Vorzeichen abgelesen: 5 und −3.","socratic_question":"Setze 5 in x + 5 ein: Kommt null heraus?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"-3":"vorzeichen_aus_klammer","−3":"vorzeichen_aus_klammer","- 3":"vorzeichen_aus_klammer"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"5":"vorzeichen_aus_klammer","+5":"vorzeichen_aus_klammer"}}}'::jsonb);
  end if;
end
$loesung$;

-- #9 quadrgl-faktor-03 · Ausklammern · 3x² = 12x
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd7d81e80-6776-4308-a690-29675f7882d4'::uuid, 'exercise', 'Ausklammern · 3x² = 12x', 'Löse die Gleichung 3x² = 12x.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst auf null bringen, dann 3x ausklammern; Versuchung, durch x zu teilen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (loesung_null_verloren, division_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd7d81e80-6776-4308-a690-29675f7882d4'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd7d81e80-6776-4308-a690-29675f7882d4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd7d81e80-6776-4308-a690-29675f7882d4'::uuid,
  p_correct_answers => '{"1":["0"],"2":["4","+4"]}'::jsonb,
  p_solution        => '3x² = 12x | − 12x
3x² − 12x = 0
3x ausklammern: 3x · (x − 4) = 0.
3x = 0, also x = 0, oder x − 4 = 0, also x = 4.
Kleinere Lösung: 0. Größere Lösung: 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch x geteilt (3x = 12) und dabei die Lösung x = 0 verloren.","socratic_question":"Stimmt die Gleichung auch für x = 0?"},{"error":"Nicht durch 3 geteilt: x = 12.","socratic_question":"Setze 12 ein: Ist 3 · 12² gleich 12 · 12?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0","known_errors":{"4":"loesung_null_verloren","+4":"loesung_null_verloren"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"12":"division_vergessen","+12":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #10 quadrgl-faktor-04 · Nullprodukt · x(2x − 7) = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c3be2e88-1087-479f-bf95-9dbd732efa56'::uuid, 'exercise', 'Nullprodukt · x(2x − 7) = 0', 'Löse die Gleichung x · (2x − 7) = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zweiter Faktor mit Koeffizient, Lösung als Dezimalzahl.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (loesung_null_verloren, vorzeichen_aus_klammer, division_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c3be2e88-1087-479f-bf95-9dbd732efa56'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c3be2e88-1087-479f-bf95-9dbd732efa56'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c3be2e88-1087-479f-bf95-9dbd732efa56'::uuid,
  p_correct_answers => '{"1":["0"],"2":["3,5","+3,5","3.5","+3.5"]}'::jsonb,
  p_solution        => 'Ein Produkt ist null, wenn ein Faktor null ist.
x = 0 oder 2x − 7 = 0 | + 7, : 2, also x = 3,5.
Kleinere Lösung: 0. Größere Lösung: 3,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Faktor 2x − 7 betrachtet, die Lösung x = 0 verloren.","socratic_question":"Was ergibt x · (2x − 7), wenn x = 0 ist?"},{"error":"Aus 2x − 7 den Wert −3,5 abgelesen statt 3,5.","socratic_question":"Setze −3,5 in 2x − 7 ein: Kommt null heraus?"},{"error":"Aus 2x = 7 nicht durch 2 geteilt: x = 7.","socratic_question":"Wie kommst du von 2x = 7 zu x?"},{"error":"Aus 2x − 7 den Wert −3,5 abgelesen; dann wäre 0 die größere Lösung.","socratic_question":"Setze −3,5 in 2x − 7 ein: Kommt null heraus?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0","known_errors":{"3,5":"loesung_null_verloren","+3,5":"loesung_null_verloren","3.5":"loesung_null_verloren","+3.5":"loesung_null_verloren","-3,5":"vorzeichen_aus_klammer","−3,5":"vorzeichen_aus_klammer","- 3,5":"vorzeichen_aus_klammer","-3.5":"vorzeichen_aus_klammer","−3.5":"vorzeichen_aus_klammer","- 3.5":"vorzeichen_aus_klammer"}},"2":{"canonical":"3,5","equivalents":["+3,5","3.5","+3.5"],"known_errors":{"0":"vorzeichen_aus_klammer","7":"division_vergessen","+7":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #11 quadrgl-faktor-05 · Nullprodukt · Ball landet wieder, h = 20t − 5t²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9879542e-bb69-41c6-a77f-3916a26ffad1'::uuid, 'exercise', 'Nullprodukt · Ball landet wieder, h = 20t − 5t²', 'Ein Ball wird vom Boden aus senkrecht nach oben geworfen. Seine Höhe in Metern nach t Sekunden ist h = 20t − 5t².

Nach wie vielen Sekunden ist der Ball wieder am Boden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Ball wird vom Boden aus senkrecht nach oben geworfen. Seine Höhe in Metern nach t Sekunden ist h = 20t − 5t².\n\nNach wie vielen Sekunden ist der Ball wieder am Boden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 's', false, 2, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: h = 0 setzen, t ausklammern, die sinnvolle Lösung t > 0 wählen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (division_vergessen, vorzeichen_beim_umstellen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9879542e-bb69-41c6-a77f-3916a26ffad1'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9879542e-bb69-41c6-a77f-3916a26ffad1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9879542e-bb69-41c6-a77f-3916a26ffad1'::uuid,
  p_correct_answers => '["4","4 s","4s"]'::jsonb,
  p_solution        => 'Am Boden ist h = 0: 20t − 5t² = 0.
t ausklammern: t · (20 − 5t) = 0.
t = 0 (Abwurf) oder 20 − 5t = 0 | + 5t, : 5, also t = 4.
Der Ball ist nach 4 s wieder am Boden.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus 20 = 5t nicht durch 5 geteilt: t = 20.","socratic_question":"Wie kommst du von 5t = 20 zu t?"},{"error":"Beim Umstellen von 20 − 5t = 0 das Minus mitgenommen: t = −4.","socratic_question":"Kann eine Zeit nach dem Abwurf negativ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 s","4s"],"known_errors":{"20":"division_vergessen","20 s":"division_vergessen","20s":"division_vergessen","-4":"vorzeichen_beim_umstellen","−4":"vorzeichen_beim_umstellen","- 4":"vorzeichen_beim_umstellen","-4 s":"vorzeichen_beim_umstellen","-4s":"vorzeichen_beim_umstellen"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 quadrgl-faktor-06 · Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '90635757-ba7c-4bde-bd7c-04bd79bf8c35'::uuid, 'exercise', 'Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3', 'Die Gleichung 2x² + bx = 0 hat die Lösungen x = 0 und x = 3.

Welchen Wert hat b? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Gleichung 2x² + bx = 0 hat die Lösungen x = 0 und x = 3.\n\nWelchen Wert hat b? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_faktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-faktor-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – aus einer bekannten Lösung den Koeffizienten b bestimmen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, division_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '90635757-ba7c-4bde-bd7c-04bd79bf8c35'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '90635757-ba7c-4bde-bd7c-04bd79bf8c35'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '90635757-ba7c-4bde-bd7c-04bd79bf8c35'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => 'x ausklammern: x · (2x + b) = 0.
Die Lösung 3 macht den zweiten Faktor null: 2 · 3 + b = 0, also b = −6.
Probe: 2x² − 6x = 2x · (x − 3), Lösungen 0 und 3.
b = -6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Vorzeichen aus dem Faktor falsch übernommen: b = 6.","socratic_question":"Setze b = 6 ein: Ist 3 dann eine Lösung von 2x² + 6x = 0?"},{"error":"x = 3 eingesetzt (18 + 3b = 0), aber nicht durch 3 geteilt: b = −18.","socratic_question":"Wie kommst du von 3b = −18 zu b?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","equivalents":["−6","- 6"],"known_errors":{"6":"vorzeichen_aus_klammer","+6":"vorzeichen_aus_klammer","-18":"division_vergessen","−18":"division_vergessen","- 18":"division_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 quadrgl-formel-01 · p-q-Formel · x² + 2x − 15 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b6e77404-2577-4e03-b4ce-cb61a5f6a5f9'::uuid, 'exercise', 'p-q-Formel · x² + 2x − 15 = 0', 'Löse die Gleichung x² + 2x − 15 = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Normalform, p und q direkt ablesbar, Wurzel aus einer Quadratzahl.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b6e77404-2577-4e03-b4ce-cb61a5f6a5f9'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b6e77404-2577-4e03-b4ce-cb61a5f6a5f9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b6e77404-2577-4e03-b4ce-cb61a5f6a5f9'::uuid,
  p_correct_answers => '{"1":["-5","−5","- 5"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'p = 2, q = −15.
x = −p/2 ± √((p/2)² − q) = −1 ± √(1 + 15) = −1 ± 4.
Kleinere Lösung: -5. Größere Lösung: 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: 1 ± 4.","socratic_question":"Welches Vorzeichen hat der erste Summand −p/2, wenn p = 2 ist?"},{"error":"Die Wurzel nicht gezogen: −1 − 16.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"},{"error":"p mit falschem Vorzeichen eingesetzt: 1 ± 4.","socratic_question":"Welches Vorzeichen hat der erste Summand −p/2, wenn p = 2 ist?"},{"error":"Die Wurzel nicht gezogen: −1 + 16.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"-3":"pq_vorzeichen","−3":"pq_vorzeichen","- 3":"pq_vorzeichen","-17":"wurzel_vergessen","−17":"wurzel_vergessen","- 17":"wurzel_vergessen"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"5":"pq_vorzeichen","15":"wurzel_vergessen","+5":"pq_vorzeichen","+15":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #14 quadrgl-formel-02 · p-q-Formel · x² − 6x + 5 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '43f39bc1-e7b4-48e6-8b77-ff8e41e77142'::uuid, 'exercise', 'p-q-Formel · x² − 6x + 5 = 0', 'Löse die Gleichung x² − 6x + 5 = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Normalform mit negativem p, Wurzel aus einer Quadratzahl.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '43f39bc1-e7b4-48e6-8b77-ff8e41e77142'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '43f39bc1-e7b4-48e6-8b77-ff8e41e77142'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '43f39bc1-e7b4-48e6-8b77-ff8e41e77142'::uuid,
  p_correct_answers => '{"1":["1","+1"],"2":["5","+5"]}'::jsonb,
  p_solution        => 'p = −6, q = 5.
x = −p/2 ± √((p/2)² − q) = 3 ± √(9 − 5) = 3 ± 2.
Kleinere Lösung: 1. Größere Lösung: 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: −3 ± 2.","socratic_question":"Was ergibt −p/2, wenn p = −6 ist?"},{"error":"Die Wurzel nicht gezogen: 3 − 4.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"},{"error":"p mit falschem Vorzeichen eingesetzt: −3 ± 2.","socratic_question":"Was ergibt −p/2, wenn p = −6 ist?"},{"error":"Die Wurzel nicht gezogen: 3 + 4.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"1","equivalents":["+1"],"known_errors":{"-5":"pq_vorzeichen","−5":"pq_vorzeichen","- 5":"pq_vorzeichen","-1":"wurzel_vergessen","−1":"wurzel_vergessen","- 1":"wurzel_vergessen"}},"2":{"canonical":"5","equivalents":["+5"],"known_errors":{"7":"wurzel_vergessen","-1":"pq_vorzeichen","−1":"pq_vorzeichen","- 1":"pq_vorzeichen","+7":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #15 quadrgl-formel-03 · p-q-Formel · 2x² − 4x − 6 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1f2a206f-1f63-4866-b446-c8305de6b725'::uuid, 'exercise', 'p-q-Formel · 2x² − 4x − 6 = 0', 'Löse die Gleichung 2x² − 4x − 6 = 0.

Gib die Lösungen exakt an.',
  null, 'MULTI_PART', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst durch 2 auf Normalform bringen, dann p-q-Formel mit zwei negativen Koeffizienten.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, division_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1f2a206f-1f63-4866-b446-c8305de6b725'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1f2a206f-1f63-4866-b446-c8305de6b725'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1f2a206f-1f63-4866-b446-c8305de6b725'::uuid,
  p_correct_answers => '{"1":["-1","−1","- 1"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'Durch 2 teilen: x² − 2x − 3 = 0, also p = −2, q = −3.
x = 1 ± √(1 + 3) = 1 ± 2.
Kleinere Lösung: -1. Größere Lösung: 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: −1 ± 2.","socratic_question":"Was ergibt −p/2, wenn p = −2 ist?"},{"error":"Nicht durch 2 geteilt: mit p = −4 und q = −6 gerechnet (2 − √10 ≈ −1,16).","socratic_question":"Steht vor x² eine 1, wenn du die p-q-Formel benutzt?"},{"error":"p mit falschem Vorzeichen eingesetzt: −1 ± 2.","socratic_question":"Was ergibt −p/2, wenn p = −2 ist?"},{"error":"Nicht durch 2 geteilt: mit p = −4 und q = −6 gerechnet (2 + √10 ≈ 5,16).","socratic_question":"Steht vor x² eine 1, wenn du die p-q-Formel benutzt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-1","equivalents":["−1","- 1"],"known_errors":{"-3":"pq_vorzeichen","−3":"pq_vorzeichen","- 3":"pq_vorzeichen","-1,16":"division_vergessen","−1,16":"division_vergessen","- 1,16":"division_vergessen","-1.16":"division_vergessen","−1.16":"division_vergessen","- 1.16":"division_vergessen"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"1":"pq_vorzeichen","+1":"pq_vorzeichen","5,16":"division_vergessen","+5,16":"division_vergessen","5.16":"division_vergessen","+5.16":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #16 quadrgl-formel-04 · p-q-Formel · x² + 4x − 1 = 0, gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '725448a1-10e2-4e88-beb8-fe57f6e54d06'::uuid, 'exercise', 'p-q-Formel · x² + 4x − 1 = 0, gerundet', 'Löse die Gleichung x² + 4x − 1 = 0.

Runde die Lösungen auf zwei Stellen nach dem Komma.',
  null, 'MULTI_PART', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Lösung","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel aus einer Nicht-Quadratzahl, Lösungen runden.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrgl"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '725448a1-10e2-4e88-beb8-fe57f6e54d06'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '725448a1-10e2-4e88-beb8-fe57f6e54d06'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '725448a1-10e2-4e88-beb8-fe57f6e54d06'::uuid,
  p_correct_answers => '{"1":["-4,24","−4,24","- 4,24","-4.24","−4.24","- 4.24"],"2":["0,24","+0,24","0.24","+0.24"]}'::jsonb,
  p_solution        => 'p = 4, q = −1.
x = −2 ± √(4 + 1) = −2 ± √5, √5 ≈ 2,236.
Kleinere Lösung: -4,24. Größere Lösung: 0,24.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: 2 ± √5.","socratic_question":"Welches Vorzeichen hat −p/2, wenn p = 4 ist?"},{"error":"Die Wurzel nicht gezogen: −2 − 5.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"},{"error":"p mit falschem Vorzeichen eingesetzt: 2 ± √5.","socratic_question":"Welches Vorzeichen hat −p/2, wenn p = 4 ist?"},{"error":"Die Wurzel nicht gezogen: −2 + 5.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-4,24","equivalents":["−4,24","- 4,24","-4.24","−4.24","- 4.24"],"known_errors":{"-0,24":"pq_vorzeichen","−0,24":"pq_vorzeichen","- 0,24":"pq_vorzeichen","-0.24":"pq_vorzeichen","−0.24":"pq_vorzeichen","- 0.24":"pq_vorzeichen","-7,00":"wurzel_vergessen","−7,00":"wurzel_vergessen","- 7,00":"wurzel_vergessen","-7.00":"wurzel_vergessen","−7.00":"wurzel_vergessen","- 7.00":"wurzel_vergessen","-7":"wurzel_vergessen","−7":"wurzel_vergessen","- 7":"wurzel_vergessen"}},"2":{"canonical":"0,24","equivalents":["+0,24","0.24","+0.24"],"known_errors":{"3":"wurzel_vergessen","4,24":"pq_vorzeichen","+4,24":"pq_vorzeichen","4.24":"pq_vorzeichen","+4.24":"pq_vorzeichen","3,00":"wurzel_vergessen","+3,00":"wurzel_vergessen","3.00":"wurzel_vergessen","+3.00":"wurzel_vergessen","+3":"wurzel_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #17 quadrgl-formel-05 · p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee'::uuid, 'exercise', 'p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²', 'Ein Rechteck ist 4 cm länger als breit. Sein Flächeninhalt beträgt 60 cm².

Wie lang ist die längere Seite des Rechtecks? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Rechteck ist 4 cm länger als breit. Sein Flächeninhalt beträgt 60 cm².\n\nWie lang ist die längere Seite des Rechtecks? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'cm', false, 1, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Gleichung x(x + 4) = 60 aufstellen, lösen, sinnvolle Lösung wählen, Länge bilden.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, falsche_groesse_beantwortet, wurzel_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee'::uuid,
  p_correct_answers => '["10","10 cm","10cm"]'::jsonb,
  p_solution        => 'Breite x, Länge x + 4: x · (x + 4) = 60
x² + 4x − 60 = 0, p = 4, q = −60.
x = −2 ± √(4 + 60) = −2 ± 8, also x = 6 oder x = −10; eine Breite ist positiv.
Breite 6 cm, längere Seite 6 cm + 4 cm = 10 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: Breite 2 + 8 = 10, Länge 14.","socratic_question":"Setze deine Breite ein: Ist Breite · (Breite + 4) wirklich 60?"},{"error":"Die Breite angegeben, nicht die längere Seite.","socratic_question":"Ist nach der Breite oder nach der längeren Seite gefragt?"},{"error":"Die Wurzel nicht gezogen: Breite −2 + 64.","socratic_question":"Was ist mit dem Term unter der Wurzel zu tun?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["10 cm","10cm"],"known_errors":{"6":"falsche_groesse_beantwortet","14":"pq_vorzeichen","66":"wurzel_vergessen","14 cm":"pq_vorzeichen","14cm":"pq_vorzeichen","6 cm":"falsche_groesse_beantwortet","6cm":"falsche_groesse_beantwortet","66 cm":"wurzel_vergessen","66cm":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 quadrgl-formel-06 · p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5b36238f-c64c-4578-bd63-55249f185c78'::uuid, 'exercise', 'p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²', 'Ein rechteckiges Beet ist 20 m lang und 15 m breit. Rundherum wird ein Weg angelegt, der überall gleich breit ist. Beet und Weg zusammen bedecken 500 m².

Wie breit ist der Weg? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechteckiges Beet ist 20 m lang und 15 m breit. Rundherum wird ein Weg angelegt, der überall gleich breit ist. Beet und Weg zusammen bedecken 500 m².\n\nWie breit ist der Weg? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_formel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-formel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Modell (20 + 2x)(15 + 2x) = 500 selbst aufstellen, auf Normalform bringen, Formel anwenden, sinnvolle Lösung wählen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, division_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5b36238f-c64c-4578-bd63-55249f185c78'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5b36238f-c64c-4578-bd63-55249f185c78'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5b36238f-c64c-4578-bd63-55249f185c78'::uuid,
  p_correct_answers => '["2,5","2.5","2,5 m","2,5m"]'::jsonb,
  p_solution        => 'Wegbreite x: (20 + 2x) · (15 + 2x) = 500
300 + 70x + 4x² = 500
4x² + 70x − 200 = 0 | : 4
x² + 17,5x − 50 = 0, p = 17,5, q = −50.
x = −8,75 ± √(76,5625 + 50) = −8,75 ± 11,25, also x = 2,5 oder x = −20; eine Breite ist positiv.
Der Weg ist 2,5 m breit.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: 8,75 + 11,25 = 20.","socratic_question":"Setze 20 ein: Ist (20 + 40) · (15 + 40) gleich 500?"},{"error":"Nicht durch 4 geteilt: mit p = 70 und q = −200 gerechnet (≈ 2,75).","socratic_question":"Steht vor x² eine 1, wenn du die p-q-Formel benutzt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,5","equivalents":["2.5","2,5 m","2,5m"],"known_errors":{"20":"pq_vorzeichen","20 m":"pq_vorzeichen","20m":"pq_vorzeichen","2,75":"division_vergessen","2.75":"division_vergessen","2,75 m":"division_vergessen","2,75m":"division_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 quadrgl-anzahl-01 · Anzahl der Lösungen · x² + 4x + 5 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a549083d-c72d-44d6-9aba-a138ad6d2dc0'::uuid, 'exercise', 'Anzahl der Lösungen · x² + 4x + 5 = 0', 'Wie viele Lösungen hat die Gleichung x² + 4x + 5 = 0?

Gib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  '{"kind":"short_input","prompt":"Wie viele Lösungen hat die Gleichung x² + 4x + 5 = 0?\n\nGib die Anzahl als ganze Zahl an (0, 1 oder 2)."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Diskriminante mit ablesbarem p und q, Vorzeichen deuten.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a549083d-c72d-44d6-9aba-a138ad6d2dc0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a549083d-c72d-44d6-9aba-a138ad6d2dc0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a549083d-c72d-44d6-9aba-a138ad6d2dc0'::uuid,
  p_correct_answers => '["0"]'::jsonb,
  p_solution        => 'p = 4, q = 5.
D = (p/2)² − q = 2² − 5 = −1.
D < 0: Unter der Wurzel stünde eine negative Zahl, es gibt keine Lösung.
Anzahl: 0.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p nicht halbiert: D = 16 − 5 = 11 > 0, also zwei Lösungen.","socratic_question":"Was steckt in der Klammer von (p/2)²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0","known_errors":{"2":"halbieren_vergessen","+2":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 quadrgl-anzahl-02 · Diskriminante · x² − 6x + 8 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5'::uuid, 'exercise', 'Diskriminante · x² − 6x + 8 = 0', 'Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 6x + 8 = 0.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 6x + 8 = 0.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Diskriminante nach Formel berechnen, p negativ.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, halbieren_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5'::uuid,
  p_correct_answers => '["1","+1"]'::jsonb,
  p_solution        => 'p = −6, q = 8.
D = (−6/2)² − 8 = (−3)² − 8 = 9 − 8.
D = 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"(−3)² als −9 gerechnet: D = −9 − 8.","socratic_question":"Ist eine Zahl mal sich selbst je negativ?"},{"error":"p nicht halbiert: D = 36 − 8.","socratic_question":"Was steckt in der Klammer von (p/2)²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1","equivalents":["+1"],"known_errors":{"28":"halbieren_vergessen","-17":"vorzeichen_potenz","−17":"vorzeichen_potenz","- 17":"vorzeichen_potenz","+28":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 quadrgl-anzahl-03 · Diskriminante · x² − 5x − 6 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ef911123-949d-4ea9-a61d-beef95cc8dc0'::uuid, 'exercise', 'Diskriminante · x² − 5x − 6 = 0', 'Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 5x − 6 = 0.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 5x − 6 = 0.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: p/2 als Dezimalzahl, q negativ – zwei Vorzeichen sind zu beachten.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, halbieren_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ef911123-949d-4ea9-a61d-beef95cc8dc0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ef911123-949d-4ea9-a61d-beef95cc8dc0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ef911123-949d-4ea9-a61d-beef95cc8dc0'::uuid,
  p_correct_answers => '["12,25","+12,25","12.25","+12.25"]'::jsonb,
  p_solution        => 'p = −5, q = −6.
D = (−2,5)² − (−6) = 6,25 + 6.
D = 12,25.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"(−2,5)² als −6,25 gerechnet: D = −6,25 + 6.","socratic_question":"Ist eine Zahl mal sich selbst je negativ?"},{"error":"p nicht halbiert: D = 25 + 6.","socratic_question":"Was steckt in der Klammer von (p/2)²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,25","equivalents":["+12,25","12.25","+12.25"],"known_errors":{"31":"halbieren_vergessen","-0,25":"vorzeichen_potenz","−0,25":"vorzeichen_potenz","- 0,25":"vorzeichen_potenz","-0.25":"vorzeichen_potenz","−0.25":"vorzeichen_potenz","- 0.25":"vorzeichen_potenz","+31":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 quadrgl-anzahl-04 · Anzahl der Lösungen · 2x² − 8x + 8 = 0
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0c3d2396-131a-4cba-bd07-4597d92500cf'::uuid, 'exercise', 'Anzahl der Lösungen · 2x² − 8x + 8 = 0', 'Wie viele Lösungen hat die Gleichung 2x² − 8x + 8 = 0?

Gib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  '{"kind":"short_input","prompt":"Wie viele Lösungen hat die Gleichung 2x² − 8x + 8 = 0?\n\nGib die Anzahl als ganze Zahl an (0, 1 oder 2)."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst auf Normalform bringen, dann Diskriminante null erkennen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (division_vergessen, vorzeichen_potenz).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0c3d2396-131a-4cba-bd07-4597d92500cf'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0c3d2396-131a-4cba-bd07-4597d92500cf'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0c3d2396-131a-4cba-bd07-4597d92500cf'::uuid,
  p_correct_answers => '["1","+1"]'::jsonb,
  p_solution        => 'Durch 2 teilen: x² − 4x + 4 = 0, p = −4, q = 4.
D = (−2)² − 4 = 0.
D = 0: Es gibt genau eine Lösung (x = 2).
Anzahl: 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht durch 2 geteilt: D = (−4)² − 8 = 8 > 0, also zwei Lösungen.","socratic_question":"Steht vor x² eine 1, wenn du p und q abliest?"},{"error":"(−2)² als −4 gerechnet: D = −8 < 0, also keine Lösung.","socratic_question":"Ist eine Zahl mal sich selbst je negativ?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1","equivalents":["+1"],"known_errors":{"0":"vorzeichen_potenz","2":"division_vergessen","+2":"division_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 quadrgl-anzahl-05 · Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '95077a87-7e8a-4463-83b0-dbbf6facc879'::uuid, 'exercise', 'Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²', 'Ein rechteckiges Feld wird mit 20 m Zaun eingezäunt und soll 25 m² Fläche haben. Für seine Breite x in Metern gilt x · (10 − x) = 25.

Wie viele Lösungen hat diese Gleichung? Gib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  '{"kind":"short_input","prompt":"Ein rechteckiges Feld wird mit 20 m Zaun eingezäunt und soll 25 m² Fläche haben. Für seine Breite x in Metern gilt x · (10 − x) = 25.\n\nWie viele Lösungen hat diese Gleichung? Gib die Anzahl als ganze Zahl an (0, 1 oder 2)."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: gegebene Gleichung auf Normalform bringen, Diskriminante deuten.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, halbieren_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '95077a87-7e8a-4463-83b0-dbbf6facc879'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '95077a87-7e8a-4463-83b0-dbbf6facc879'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '95077a87-7e8a-4463-83b0-dbbf6facc879'::uuid,
  p_correct_answers => '["1","+1"]'::jsonb,
  p_solution        => 'x · (10 − x) = 25
10x − x² = 25 | + x² − 10x
0 = x² − 10x + 25, also p = −10, q = 25.
D = (−5)² − 25 = 0.
D = 0: genau eine Lösung (x = 5, das Feld ist ein Quadrat).
Anzahl: 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"(−5)² als −25 gerechnet: D = −50 < 0, also keine Lösung.","socratic_question":"Ist eine Zahl mal sich selbst je negativ?"},{"error":"p nicht halbiert: D = 100 − 25 > 0, also zwei Lösungen.","socratic_question":"Was steckt in der Klammer von (p/2)²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1","equivalents":["+1"],"known_errors":{"0":"vorzeichen_potenz","2":"halbieren_vergessen","+2":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 quadrgl-anzahl-06 · Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '56540a88-7b9e-4935-8702-26f9415e9d14'::uuid, 'exercise', 'Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung', 'Für welchen Wert von q hat die Gleichung x² + 6x + q = 0 genau eine Lösung?

Gib q exakt an.',
  '{"kind":"short_input","prompt":"Für welchen Wert von q hat die Gleichung x² + 6x + q = 0 genau eine Lösung?\n\nGib q exakt an."}'::jsonb, 'NUMERIC', 'gleichung_quadr_anzahl',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  90, null, false, 1, 'draft', 'edvance_k9_quadrgl', 'quadrgl-anzahl-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – Bedingung D = 0 aufstellen und nach q auflösen.","charge":"k9-quadrgl"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrgl"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).","charge":"k9-quadrgl"},"cluster_id":{"art":"neu","grund":"Themengebiet „Algebra & Funktionen\" (wie Binom und lineare Gleichungen).","charge":"k9-quadrgl"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).","charge":"k9-quadrgl"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrgl"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrgl"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrgl"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrgl"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, halbieren_vergessen).","charge":"k9-quadrgl"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrgl"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '56540a88-7b9e-4935-8702-26f9415e9d14'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrgl')
   and not exists (select 1 from public.task_solutions s where s.task_id = '56540a88-7b9e-4935-8702-26f9415e9d14'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '56540a88-7b9e-4935-8702-26f9415e9d14'::uuid,
  p_correct_answers => '["9","+9"]'::jsonb,
  p_solution        => 'Genau eine Lösung heißt D = 0.
D = (6/2)² − q = 9 − q = 0, also q = 9.
Probe: x² + 6x + 9 = (x + 3)², einzige Lösung x = −3.
q = 9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus 9 − q = 0 den Wert q = −9 gemacht.","socratic_question":"Setze q = −9 ein: Ist 9 − (−9) gleich null?"},{"error":"p nicht halbiert: q = 6² = 36.","socratic_question":"Was steckt in der Klammer von (p/2)²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["+9"],"known_errors":{"36":"halbieren_vergessen","-9":"betrag_fehler","−9":"betrag_fehler","- 9":"betrag_fehler","+36":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;
