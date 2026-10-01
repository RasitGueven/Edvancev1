-- K8-/K9-Vorlauf, Migration 3 von 3 — 12 Aufgaben zu geo_koordinaten und term_einsetzen.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-vorlauf.json — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261001115718_tiefe_k8_vorlauf.sql und
-- 20261001115812_substrat_k8_vorlauf.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Zwölf neue Fundament-Aufgaben zu den Vorlauf-Knoten geo_koordinaten und term_einsetzen (je sechs: vier reine Anwendung mit steigender Schwierigkeit, zwei mit Sachkontext oder Rückrichtung). Neu angelegt, nicht aus dem Bestand; Quelle dieser Datei, Migration per tools/vorlauf-build.mjs.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-vorlauf.csv. Pruefprotokoll: docs/prefill/k8-vorlauf-verifikation.md.
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
--   geo_koordinaten: vorlauf-koord-02 = 1, vorlauf-koord-01 = 2. Rang 1 aus Profil {koordinate_vorzeichen_verloren,koordinaten_vertauscht}, Rang 2 aus Profil {koordinaten_vertauscht} (0 neue Fehlbilder)
--   term_einsetzen: vorlauf-einsetzen-04 = 1, vorlauf-einsetzen-05 = 2. Rang 1 aus Profil {vorrang_ignoriert,vorzeichen_ignoriert,vorzeichen_potenz}, Rang 2 aus Profil {halbieren_vergessen,plus_statt_mal} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne --single-transaction, und
-- eine Aufgabe ohne Loesung waere still kaputt.

begin;

select set_config('request.jwt.claim.role', 'service_role', true);

-- #1 vorlauf-koord-01 · Koordinaten · Punkt ablesen · 1. Quadrant
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid, 'exercise', 'Koordinaten · Punkt ablesen · 1. Quadrant', 'Lies die Koordinaten des Punktes P im Koordinatensystem ab.',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, true, 2, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von P","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von P","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Ablesen im ersten Quadranten, beide Werte positiv, ganzzahlig.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext (Teile 25 + 20 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6: KLP G9 Geo-6, Koordinatensystem in der Erprobungsstufe.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Ablesen nach festem Verfahren.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit Punkt) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"Ein Wert an der x-Achse ablesen.","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Aus den Figurparametern; Varianten mit Vorzeichen.","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"Ein Wert an der y-Achse ablesen.","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Aus den Figurparametern; Varianten mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Aus den Figurparametern abgeleitet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'P liegt 4 Einheiten rechts vom Ursprung und 3 Einheiten darüber.
x-Koordinate: 4, y-Koordinate: 3, also P(4|3).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"x- und y-Koordinate vertauscht: (3|4) statt (4|3).","socratic_question":"Welche Achse liest du zuerst ab – die waagerechte oder die senkrechte?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","known_errors":{"3":"koordinaten_vertauscht"}},"2":{"canonical":"3","known_errors":{"4":"koordinaten_vertauscht"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":4,"y":3,"label":"P"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Punkt P.'
 where exists (select 1 from public.tasks t where t.id = '650eed2a-79e5-4a6f-9ed2-a51053fe75c8'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #2 vorlauf-koord-02 · Koordinaten · Punkt ablesen · 2. Quadrant
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid, 'exercise', 'Koordinaten · Punkt ablesen · 2. Quadrant', 'Lies die Koordinaten des Punktes Q im Koordinatensystem ab.',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, true, 1, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von Q","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von Q","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Ablesen im zweiten Quadranten, ein negativer Wert.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext (Teile 25 + 20 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6 (Geo-6); negative Koordinaten setzen Ari-1 voraus, Kante auf vorzeichen_add_sub.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Ablesen nach festem Verfahren.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit Punkt) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"Negativen Wert an der x-Achse ablesen.","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Aus den Figurparametern; Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"Positiven Wert an der y-Achse ablesen.","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Aus den Figurparametern; Varianten mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Aus den Figurparametern abgeleitet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid,
  p_correct_answers => '{"1":["-4","−4","- 4"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'Q liegt 4 Einheiten links vom Ursprung und 2 Einheiten darüber.
Links heißt negativ: x-Koordinate -4, y-Koordinate 2, also Q(-4|2).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus der x-Koordinate fehlt: (4|2) statt (-4|2).","socratic_question":"Liegt Q links oder rechts der y-Achse – und was bedeutet das für das Vorzeichen?"},{"error":"x- und y-Koordinate vertauscht: (2|-4) statt (-4|2).","socratic_question":"Welche Achse liest du zuerst ab – die waagerechte oder die senkrechte?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-4","known_errors":{"2":"koordinaten_vertauscht","4":"koordinate_vorzeichen_verloren"}},"2":{"canonical":"2","known_errors":{"-4":"koordinaten_vertauscht","−4":"koordinaten_vertauscht"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":-4,"y":2,"label":"Q"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Punkt Q.'
 where exists (select 1 from public.tasks t where t.id = 'a1fa4311-c631-47ba-a4a7-15e12149db4c'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #3 vorlauf-koord-03 · Koordinaten · Punkt ablesen · 3. Quadrant
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd8195933-ba82-4768-ac40-064da27497a6'::uuid, 'exercise', 'Koordinaten · Punkt ablesen · 3. Quadrant', 'Lies die Koordinaten des Punktes R im Koordinatensystem ab.',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, true, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von R","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von R","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Ablesen im dritten Quadranten, beide Werte negativ; derselbe Ablauf wie in Aufgabe 2.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext (Teile 25 + 20 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6 (Geo-6); negative Koordinaten setzen Ari-1 voraus, Kante auf vorzeichen_add_sub.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Ablesen nach festem Verfahren.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit Punkt) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"Negativen Wert an der x-Achse ablesen.","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Aus den Figurparametern; Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"Negativen Wert an der y-Achse ablesen.","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Aus den Figurparametern; Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Aus den Figurparametern abgeleitet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd8195933-ba82-4768-ac40-064da27497a6'::uuid,
  p_correct_answers => '{"1":["-2","−2","- 2"],"2":["-5","−5","- 5"]}'::jsonb,
  p_solution        => 'R liegt 2 Einheiten links vom Ursprung und 5 Einheiten darunter.
Links und unten heißt negativ: x-Koordinate -2, y-Koordinate -5, also R(-2|-5).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus fehlt: (2|5) oder nur ein Wert ohne Minus.","socratic_question":"Liegt R oberhalb oder unterhalb der x-Achse – und links oder rechts der y-Achse?"},{"error":"x- und y-Koordinate vertauscht: (-5|-2) statt (-2|-5).","socratic_question":"Welche Achse liest du zuerst ab – die waagerechte oder die senkrechte?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-2","known_errors":{"2":"koordinate_vorzeichen_verloren","-5":"koordinaten_vertauscht","−5":"koordinaten_vertauscht"}},"2":{"canonical":"-5","known_errors":{"5":"koordinate_vorzeichen_verloren","-2":"koordinaten_vertauscht","−2":"koordinaten_vertauscht"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd8195933-ba82-4768-ac40-064da27497a6'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd8195933-ba82-4768-ac40-064da27497a6'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'd8195933-ba82-4768-ac40-064da27497a6'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":-2,"y":-5,"label":"R"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Punkt R.'
 where exists (select 1 from public.tasks t where t.id = 'd8195933-ba82-4768-ac40-064da27497a6'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #4 vorlauf-koord-04 · Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid, 'exercise', 'Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit', 'Lies die Koordinaten des Punktes T im Koordinatensystem ab. T liegt nicht auf einem Gitterpunkt.',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, true, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von T","unit":null,"afb":"I","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von T","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Zusammenhänge herstellen: der y-Wert liegt zwischen zwei Gitterlinien und muss als halbe Einheit erschlossen werden, dazu negativ.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext (Teile 30 + 30 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6 (Geo-6, Dezimalzahlen Klasse 6); negative Koordinaten setzen Ari-1 voraus.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Ablesen nach festem Verfahren, mit Zwischenwert.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit Punkt) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"Ganzzahligen Wert an der x-Achse ablesen.","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Aus den Figurparametern; Varianten mit Vorzeichen.","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"Halbe Einheit zwischen zwei Gitterlinien, negativ.","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Aus den Figurparametern; Komma und Punkt, Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Aus den Figurparametern abgeleitet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["-2,5","-2.5","−2,5","- 2,5"]}'::jsonb,
  p_solution        => 'T liegt 3 Einheiten rechts vom Ursprung und genau in der Mitte zwischen -2 und -3 unterhalb der x-Achse.
x-Koordinate 3, y-Koordinate -2,5, also T(3|-2,5).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus der y-Koordinate fehlt: (3|2,5) statt (3|-2,5).","socratic_question":"Liegt T oberhalb oder unterhalb der x-Achse?"},{"error":"x- und y-Koordinate vertauscht: (-2,5|3) statt (3|-2,5).","socratic_question":"Welche Achse liest du zuerst ab – die waagerechte oder die senkrechte?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","known_errors":{"-2,5":"koordinaten_vertauscht","−2,5":"koordinaten_vertauscht"}},"2":{"canonical":"-2,5","known_errors":{"3":"koordinaten_vertauscht","2,5":"koordinate_vorzeichen_verloren"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":3,"y":-2.5,"label":"T"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Punkt T zwischen zwei Gitterlinien.'
 where exists (select 1 from public.tasks t where t.id = 'e0daa32b-4d16-49ae-82b4-ece970facc2f'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #5 vorlauf-koord-05 · Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid, 'exercise', 'Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks', 'Die Punkte A, B und C sind drei Eckpunkte des Rechtecks ABCD.
Welche Koordinaten hat der vierte Eckpunkt D, der noch eingetragen werden muss?',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen, Operieren',
  60, null, true, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von D","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von D","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Rückrichtung: D ist nicht abzulesen, sondern aus den Eigenschaften des Rechtecks zu erschließen (gleiche x-Koordinate wie A, gleiche y-Koordinate wie C).","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext (Teile 30 + 30 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6 (Geo-6: ebene Figuren im Koordinatensystem); negative Koordinaten setzen Ari-1 voraus.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Fehlenden Punkt aus Figureigenschaften erschließen, dann Koordinaten angeben.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit A, B, C) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"x-Koordinate aus A übernehmen (senkrechte Seite AD).","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Rechteck: D hat die x-Koordinate von A; Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"y-Koordinate aus C übernehmen (waagerechte Seite CD).","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Rechteck: D hat die y-Koordinate von C; Varianten mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Aus den Figurparametern abgeleitet und am Rechteck geprüft.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid,
  p_correct_answers => '{"1":["-4","−4","- 4"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'Abgelesen: A(-4|-3), B(3|-3), C(3|2).
Im Rechteck ABCD liegt D senkrecht über A und waagerecht neben C.
Also hat D die x-Koordinate von A (-4) und die y-Koordinate von C (2): D(-4|2).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus der x-Koordinate fehlt: (4|2) statt (-4|2).","socratic_question":"Liegt D links oder rechts der y-Achse?"},{"error":"x- und y-Koordinate vertauscht: (2|-4) statt (-4|2).","socratic_question":"Welche Zahl gibt an, wie weit D nach links oder rechts liegt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-4","known_errors":{"2":"koordinaten_vertauscht","4":"koordinate_vorzeichen_verloren"}},"2":{"canonical":"2","known_errors":{"-4":"koordinaten_vertauscht","−4":"koordinaten_vertauscht"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":-4,"y":-3,"label":"A"},{"x":3,"y":-3,"label":"B"},{"x":3,"y":2,"label":"C"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Punkte A, B und C.'
 where exists (select 1 from public.tasks t where t.id = 'cef62bbd-6d88-4dc4-a1cc-3c9960e67584'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #6 vorlauf-koord-06 · Koordinaten · Sachkontext · Fahrt auf der Seekarte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid, 'exercise', 'Koordinaten · Sachkontext · Fahrt auf der Seekarte', 'Das Koordinatensystem ist eine Seekarte. Eine Einheit entspricht einem Kilometer.
Ein Boot startet im Punkt S. Es fährt 6 Kilometer nach rechts und danach 4 Kilometer nach unten.
In welchem Punkt kommt das Boot an?',
  null, 'MULTI_PART', 'geo_koordinaten',
  null, 6,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, null, true, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-koord-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Zielpunkts","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Zielpunkts","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Zwei Schritte verknüpfen: S ablesen, dann die Verschiebung nach rechts und unten auf die Koordinaten übertragen; Ziel im vierten Quadranten.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext (Teile 45 + 45 s).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 6 (Geo-6); negative Koordinaten setzen Ari-1 voraus.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen, wie geo_umfang und geo_flaeche_rechteck.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-6).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Bewegung im Sachkontext in Koordinaten übersetzen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Koordinatensystem mit Startpunkt S) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-vorlauf"},"parts.1.afb":{"art":"neu","grund":"x-Wert von S ablesen und um 6 erhöhen.","charge":"k8-vorlauf"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.1":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-vorlauf"},"parts.2.afb":{"art":"neu","grund":"y-Wert von S ablesen und um 4 verringern, Ergebnis negativ.","charge":"k8-vorlauf"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-vorlauf"},"correct_answers.2":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["-3","−3","- 3"]}'::jsonb,
  p_solution        => 'Abgelesen: S(-2|1).
6 nach rechts: x = -2 + 6 = 4.
4 nach unten: y = 1 - 4 = -3.
Das Boot kommt im Punkt (4|-3) an.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus der y-Koordinate fehlt: (4|3) statt (4|-3).","socratic_question":"Liegt der Zielpunkt oberhalb oder unterhalb der x-Achse?"},{"error":"x- und y-Koordinate vertauscht: (-3|4) statt (4|-3).","socratic_question":"Welcher Wert sagt, wie weit rechts das Boot ist – der erste oder der zweite?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","known_errors":{"-3":"koordinaten_vertauscht","−3":"koordinaten_vertauscht"}},"2":{"canonical":"-3","known_errors":{"3":"koordinate_vorzeichen_verloren","4":"koordinaten_vertauscht"}}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":-2,"y":1,"label":"S"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Startpunkt S.'
 where exists (select 1 from public.tasks t where t.id = '769c9fdb-c72a-46bd-9899-58c8773705d2'::uuid and t.source = 'edvance_fundament_vorlauf')
on conflict (task_id) do nothing;

-- #7 vorlauf-einsetzen-01 · Einsetzen · negativer Wert · 2 · x + 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dea9fea4-6976-4632-a33d-547693f1fbc9'::uuid, 'exercise', 'Einsetzen · negativer Wert · 2 · x + 5', 'Berechne den Wert des Terms für x = -4.

2 · x + 5 = ?',
  '{"kind":"short_input","prompt":"Berechne den Wert des Terms für x = -4.\n\n2 · x + 5 = ?"}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: einen negativen Wert in einen linearen Term einsetzen, ein Rechenschritt je Operation.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: KLP G9 Ari-4/Ari-5, Terme in der Ersten Stufe.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen, wie term_zusammenfassen und term_ausmultiplizieren.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-4/Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Einsetzen und ausrechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Reiner Term, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Minus als Bindestrich, Minuszeichen und mit Leerzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, betrag_fehler).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'dea9fea4-6976-4632-a33d-547693f1fbc9'::uuid,
  p_correct_answers => '["-3","−3","- 3"]'::jsonb,
  p_solution        => 'x = -4 mit Klammer einsetzen:
2 · (-4) + 5 = -8 + 5 = -3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus beim Einsetzen weggelassen: 2 · 4 + 5 = 13.","socratic_question":"Welche Zahl steht für x – und wie schreibst du sie, wenn sie hinter einem Malpunkt steht?"},{"error":"Vorzeichen des Ergebnisses gekippt: 3 statt -3.","socratic_question":"Ist -8 + 5 größer oder kleiner als null?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-3","known_errors":{"3":"betrag_fehler","13":"vorzeichen_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'dea9fea4-6976-4632-a33d-547693f1fbc9'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dea9fea4-6976-4632-a33d-547693f1fbc9'::uuid);

-- #8 vorlauf-einsetzen-02 · Einsetzen · negativer Wert und Vorrang · 5 - 3 · x
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '18d3aeac-c9bf-4fee-993f-fb8adbe1e5fa'::uuid, 'exercise', 'Einsetzen · negativer Wert und Vorrang · 5 - 3 · x', 'Berechne den Wert des Terms für x = -2.

5 - 3 · x = ?',
  '{"kind":"short_input","prompt":"Berechne den Wert des Terms für x = -2.\n\n5 - 3 · x = ?"}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Einsetzen mit Punkt vor Strich und Minus mal Minus — beides geübte Regeln, aber in einem Schritt kombiniert.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: KLP G9 Ari-4/Ari-5, Terme in der Ersten Stufe.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen, wie term_zusammenfassen und term_ausmultiplizieren.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-4/Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Einsetzen und ausrechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Reiner Term, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Variante mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorrang_ignoriert, vorzeichen_ignoriert).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '18d3aeac-c9bf-4fee-993f-fb8adbe1e5fa'::uuid,
  p_correct_answers => '["11","+11"]'::jsonb,
  p_solution        => 'x = -2 mit Klammer einsetzen, Punkt vor Strich:
5 - 3 · (-2) = 5 - (-6) = 5 + 6 = 11.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von links nach rechts gerechnet: (5 - 3) · (-2) = -4.","socratic_question":"Was wird zuerst gerechnet – die Subtraktion oder die Multiplikation?"},{"error":"Minus beim Einsetzen weggelassen: 5 - 3 · 2 = -1.","socratic_question":"Welche Zahl steht für x – und was ergibt Minus mal Minus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11","known_errors":{"-4":"vorrang_ignoriert","−4":"vorrang_ignoriert","-1":"vorzeichen_ignoriert","−1":"vorzeichen_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '18d3aeac-c9bf-4fee-993f-fb8adbe1e5fa'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = '18d3aeac-c9bf-4fee-993f-fb8adbe1e5fa'::uuid);

-- #9 vorlauf-einsetzen-03 · Einsetzen · Potenz im Term · 3 · x²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '16352abe-36f9-482c-972d-a7b10493919d'::uuid, 'exercise', 'Einsetzen · Potenz im Term · 3 · x²', 'Berechne den Wert des Terms für x = -2.

3 · x² = ?',
  '{"kind":"short_input","prompt":"Berechne den Wert des Terms für x = -2.\n\n3 · x² = ?"}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Zusammenhänge herstellen: das Quadrat bezieht sich nur auf x, und der eingesetzte negative Wert muss als Ganzes quadriert werden ((-2)² statt -2²).","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: KLP G9 Ari-4/Ari-5, Terme in der Ersten Stufe.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen, wie term_zusammenfassen und term_ausmultiplizieren.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-4/Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Einsetzen und ausrechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Reiner Term, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Variante mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, vorrang_ignoriert).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '16352abe-36f9-482c-972d-a7b10493919d'::uuid,
  p_correct_answers => '["12","+12"]'::jsonb,
  p_solution        => 'x = -2 mit Klammer einsetzen, Potenz vor Punkt:
3 · (-2)² = 3 · 4 = 12.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus beim Einsetzen nicht geklammert: 3 · (-2²) = 3 · (-4) = -12.","socratic_question":"Was ergibt (-2) · (-2)?"},{"error":"Erst multipliziert, dann quadriert: (3 · (-2))² = 36.","socratic_question":"Worauf bezieht sich das Quadrat – auf 3 · x oder nur auf x?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","known_errors":{"36":"vorrang_ignoriert","-12":"vorzeichen_potenz","−12":"vorzeichen_potenz"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '16352abe-36f9-482c-972d-a7b10493919d'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = '16352abe-36f9-482c-972d-a7b10493919d'::uuid);

-- #10 vorlauf-einsetzen-04 · Einsetzen · Potenz und Produkt · x² - 2 · x
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd6aba9d2-91cc-4ba5-bf71-91ac5b1477dd'::uuid, 'exercise', 'Einsetzen · Potenz und Produkt · x² - 2 · x', 'Berechne den Wert des Terms für x = -3.

x² - 2 · x = ?',
  '{"kind":"short_input","prompt":"Berechne den Wert des Terms für x = -3.\n\nx² - 2 · x = ?"}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Zusammenhänge herstellen: x kommt zweimal vor, einmal quadriert und einmal hinter einem Minus; Potenz-, Vorrang- und Vorzeichenregel müssen zusammenwirken.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: KLP G9 Ari-4/Ari-5, Terme in der Ersten Stufe.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen, wie term_zusammenfassen und term_ausmultiplizieren.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-4/Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Einsetzen und ausrechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Reiner Term, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Variante mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, vorzeichen_ignoriert, vorrang_ignoriert).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd6aba9d2-91cc-4ba5-bf71-91ac5b1477dd'::uuid,
  p_correct_answers => '["15","+15"]'::jsonb,
  p_solution        => 'x = -3 an beiden Stellen mit Klammer einsetzen:
(-3)² - 2 · (-3) = 9 - (-6) = 9 + 6 = 15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus beim Einsetzen nicht geklammert: -3² = -9, also -9 + 6 = -3.","socratic_question":"Was ergibt (-3) · (-3)?"},{"error":"Minus beim zweiten Einsetzen weggelassen: 9 - 2 · 3 = 3.","socratic_question":"Welche Zahl steht für x – auch an der zweiten Stelle?"},{"error":"Von links nach rechts gerechnet: (9 - 2) · (-3) = -21.","socratic_question":"Was wird zuerst gerechnet – die Subtraktion oder die Multiplikation?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","known_errors":{"3":"vorzeichen_ignoriert","-3":"vorzeichen_potenz","−3":"vorzeichen_potenz","-21":"vorrang_ignoriert","−21":"vorrang_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd6aba9d2-91cc-4ba5-bf71-91ac5b1477dd'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd6aba9d2-91cc-4ba5-bf71-91ac5b1477dd'::uuid);

-- #11 vorlauf-einsetzen-05 · Einsetzen · Formel mit zwei Variablen · Fläche des Dreiecks
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6a5e2a64-9e1f-4638-a76e-d4c09fd5f4ca'::uuid, 'exercise', 'Einsetzen · Formel mit zwei Variablen · Fläche des Dreiecks', 'Für den Flächeninhalt eines Dreiecks gilt die Formel A = g · h : 2.
Dabei ist g die Grundseite und h die Höhe.

Berechne A für g = 7 cm und h = 5 cm.',
  '{"kind":"short_input","prompt":"Für den Flächeninhalt eines Dreiecks gilt die Formel A = g · h : 2.\nDabei ist g die Grundseite und h die Höhe.\n\nBerechne A für g = 7 cm und h = 5 cm."}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  90, 'cm²', false, 2, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Formel mit zwei Variablen lesen, Werte richtig zuordnen und einsetzen; Ergebnis ist ein Dezimalwert.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext (Größen mit Einheit).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Einsetzen in eine Formel (Ari-4/Ari-5); die Dreiecksformel selbst ist Klasse 6 und wird hier gegeben.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die übrigen term_-Aufgaben; geprüft wird das Einsetzen, nicht die Geometrie.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra: Formel als Rechenvorschrift (Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Werte zuordnen, einsetzen, ausrechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Formel und Werte stehen im Text, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Komma und Punkt.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '6a5e2a64-9e1f-4638-a76e-d4c09fd5f4ca'::uuid,
  p_correct_answers => '["17,5","17.5"]'::jsonb,
  p_solution        => 'g = 7 und h = 5 einsetzen:
A = 7 · 5 : 2 = 35 : 2 = 17,5.
Der Flächeninhalt beträgt 17,5 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Halbieren vergessen: 7 · 5 = 35.","socratic_question":"Welcher Teil der Formel ist nach 7 · 5 noch nicht gerechnet?"},{"error":"Addiert statt multipliziert: (7 + 5) : 2 = 6.","socratic_question":"Welches Rechenzeichen steht in der Formel zwischen g und h?"}]'::jsonb,
  p_acceptance      => '{"canonical":"17,5","known_errors":{"6":"plus_statt_mal","35":"halbieren_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '6a5e2a64-9e1f-4638-a76e-d4c09fd5f4ca'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6a5e2a64-9e1f-4638-a76e-d4c09fd5f4ca'::uuid);

-- #12 vorlauf-einsetzen-06 · Einsetzen · Sachformel · Grad Celsius in Grad Fahrenheit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fbf4143f-5932-4a14-9337-575ea4c5d2b0'::uuid, 'exercise', 'Einsetzen · Sachformel · Grad Celsius in Grad Fahrenheit', 'Temperaturen in Grad Celsius (C) rechnet man mit der Formel F = 1,8 · C + 32 in Grad Fahrenheit (F) um.

Wie viel Grad Fahrenheit sind -10 Grad Celsius?',
  '{"kind":"short_input","prompt":"Temperaturen in Grad Celsius (C) rechnet man mit der Formel F = 1,8 · C + 32 in Grad Fahrenheit (F) um.\n\nWie viel Grad Fahrenheit sind -10 Grad Celsius?"}'::jsonb, 'NUMERIC', 'term_einsetzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, '°F', false, null, 'draft', 'edvance_fundament_vorlauf', 'vorlauf-einsetzen-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Sachformel lesen, negativen Wert mit Dezimalfaktor einsetzen, Vorrang beachten.","charge":"k8-vorlauf"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext (Temperatur-Umrechnung).","charge":"k8-vorlauf"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: KLP G9 Ari-4/Ari-5, Formel als Rechenvorschrift, rationale Zahlen.","charge":"k8-vorlauf"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die übrigen term_-Aufgaben; geprüft wird das Einsetzen.","charge":"k8-vorlauf"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra: Formel als Rechenvorschrift (Ari-5).","charge":"k8-vorlauf"},"competency_process":{"art":"neu","grund":"Sachangabe der Formelvariable zuordnen, dann rechnen.","charge":"k8-vorlauf"},"needs_image":{"art":"neu","grund":"Formel und Wert stehen im Text, keine Abbildung nötig.","charge":"k8-vorlauf"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Variante mit Vorzeichen.","charge":"k8-vorlauf"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-vorlauf"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, betrag_fehler, vorrang_ignoriert).","charge":"k8-vorlauf"},"hints":{"art":"leer","grund":"Vorlauf-Spec: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-vorlauf"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'fbf4143f-5932-4a14-9337-575ea4c5d2b0'::uuid,
  p_correct_answers => '["14","+14"]'::jsonb,
  p_solution        => 'C = -10 mit Klammer einsetzen, Punkt vor Strich:
F = 1,8 · (-10) + 32 = -18 + 32 = 14.
-10 Grad Celsius sind 14 Grad Fahrenheit.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Minus beim Einsetzen weggelassen: 1,8 · 10 + 32 = 50.","socratic_question":"Welche Temperatur setzt du für C ein – über oder unter null?"},{"error":"Vorzeichen des Ergebnisses gekippt: -14 statt 14.","socratic_question":"Ist -18 + 32 größer oder kleiner als null?"},{"error":"Erst addiert, dann multipliziert: 1,8 · (-10 + 32) = 39,6.","socratic_question":"Was wird zuerst gerechnet – die Multiplikation oder die Addition?"}]'::jsonb,
  p_acceptance      => '{"canonical":"14","known_errors":{"50":"vorzeichen_ignoriert","-14":"betrag_fehler","−14":"betrag_fehler","39,6":"vorrang_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'fbf4143f-5932-4a14-9337-575ea4c5d2b0'::uuid and t.status = 'draft' and t.source = 'edvance_fundament_vorlauf')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fbf4143f-5932-4a14-9337-575ea4c5d2b0'::uuid);

commit;
