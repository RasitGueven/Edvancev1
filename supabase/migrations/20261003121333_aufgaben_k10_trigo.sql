-- K10-Rest, Thema trigo — 30 Aufgaben: je sechs zu geo_trigo_verhaeltnis, _seite, _winkel, _anwendung und _kosinussatz.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-trigo.json (Quelle: tools/k10-trigo-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003121329_substrat_k10_trigo.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (ähnliche Dreiecke, Rampe, Dach, Turm, Leuchtturm, Leiter, Straße, See); geo_trigo_anwendung ist durchgehend Sachkontext. Dreiecke als Text mit fester Benennung (rechter Winkel bei C, α bei A), keine Abbildung. Jede Aufgabe nennt Rundung und Gradmaß; Werte exakt nachgerechnet (Winkelfunktionen auf 40 Stellen).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k10-trigo.csv. Pruefprotokoll: docs/prefill/k10-trigo-verifikation.md.
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
--   geo_trigo_verhaeltnis: trigo-verhaeltnis-05 = 1, trigo-verhaeltnis-03 = 2. Rang 1 aus Profil {additiv_statt_multiplikativ,sin_cos_vertauscht,tangens_verwechselt}, Rang 2 aus Profil {hypotenuse_verwechselt,sin_cos_vertauscht,tangens_verwechselt} (1 neue Fehlbilder)
--   geo_trigo_seite: trigo-seite-03 = 1, trigo-seite-06 = 2. Rang 1 aus Profil {bogenmass_modus,multipliziert_statt_dividiert,sin_cos_vertauscht,tangens_verwechselt}, Rang 2 aus Profil {bogenmass_modus,halbieren_vergessen,zu_frueh_gerundet} (2 neue Fehlbilder)
--   geo_trigo_winkel: trigo-winkel-01 = 1, trigo-winkel-06 = 2. Rang 1 aus Profil {bogenmass_modus,sin_cos_vertauscht,tangens_verwechselt,umkehrfunktion_vergessen}, Rang 2 aus Profil {halbieren_vergessen,tangens_verwechselt,umkehrfunktion_vergessen} (1 neue Fehlbilder)
--   geo_trigo_anwendung: trigo-anwendung-04 = 1, trigo-anwendung-06 = 2. Rang 1 aus Profil {bogenmass_modus,multipliziert_statt_dividiert,tangens_verwechselt}, Rang 2 aus Profil {tangens_verwechselt,umkehrfunktion_vergessen,zu_frueh_gerundet} (2 neue Fehlbilder)
--   geo_trigo_kosinussatz: trigo-kosinussatz-04 = 1, trigo-kosinussatz-06 = 2. Rang 1 aus Profil {kosinussatz_vorzeichen,pythagoras_ohne_rechten_winkel,wurzel_vergessen,zu_frueh_gerundet}, Rang 2 aus Profil {falsche_groesse_beantwortet,kosinussatz_vorzeichen,umkehrfunktion_vergessen} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 trigo-verhaeltnis-01 · Sinus als Seitenverhältnis · a = 3 cm, c = 5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd2fd3cef-0e18-4a8c-9ae2-1c8dc92c4b86'::uuid, 'exercise', 'Sinus als Seitenverhältnis · a = 3 cm, c = 5 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind a = 3 cm, b = 4 cm und c = 5 cm.

Bestimme sin α als Seitenverhältnis. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind a = 3 cm, b = 4 cm und c = 5 cm.\n\nBestimme sin α als Seitenverhältnis. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: sin α = Gegenkathete : Hypotenuse mit allen drei gegebenen Seiten.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd2fd3cef-0e18-4a8c-9ae2-1c8dc92c4b86'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd2fd3cef-0e18-4a8c-9ae2-1c8dc92c4b86'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd2fd3cef-0e18-4a8c-9ae2-1c8dc92c4b86'::uuid,
  p_correct_answers => '["0,6","+0,6","0.6","+0.6"]'::jsonb,
  p_solution        => 'Für α ist a die Gegenkathete und c die Hypotenuse.
sin α = a : c = 3 : 5 = 0,6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ankathete statt Gegenkathete genommen: b : c = 0,8 ist cos α.","socratic_question":"Welche Seite liegt dem Winkel α gegenüber?"},{"error":"Durch die Kathete b statt durch die Hypotenuse geteilt: a : b = 0,75 ist tan α.","socratic_question":"Welche Seite steht beim Sinus im Nenner?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,6","equivalents":["+0,6","0.6","+0.6"],"known_errors":{"0,8":"sin_cos_vertauscht","+0,8":"sin_cos_vertauscht","0.8":"sin_cos_vertauscht","+0.8":"sin_cos_vertauscht","0,75":"tangens_verwechselt","+0,75":"tangens_verwechselt","0.75":"tangens_verwechselt","+0.75":"tangens_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 trigo-verhaeltnis-02 · Sinuswert · sin 35° mit dem Taschenrechner
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3ba41acb-6f44-46cf-bfb8-006789699045'::uuid, 'exercise', 'Sinuswert · sin 35° mit dem Taschenrechner', 'Berechne sin 35° mit dem Taschenrechner. Winkel sind im Gradmaß angegeben.

Runde auf vier Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Berechne sin 35° mit dem Taschenrechner. Winkel sind im Gradmaß angegeben.\n\nRunde auf vier Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: einen Sinuswert im Gradmaß mit dem Taschenrechner bestimmen und runden.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bogenmass_modus, sin_cos_vertauscht, tangens_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3ba41acb-6f44-46cf-bfb8-006789699045'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3ba41acb-6f44-46cf-bfb8-006789699045'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3ba41acb-6f44-46cf-bfb8-006789699045'::uuid,
  p_correct_answers => '["0,5736","+0,5736","0.5736","+0.5736"]'::jsonb,
  p_solution        => 'Taschenrechner auf Gradmaß (DEG) stellen.
sin 35° ≈ 0,5736.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Der Taschenrechner stand auf Bogenmaß: sin(35) ≈ −0,4282.","socratic_question":"Kann der Sinus eines spitzen Winkels negativ sein?"},{"error":"cos 35° ≈ 0,8192 statt sin 35° berechnet.","socratic_question":"Welche Taste hast du gedrückt: sin oder cos?"},{"error":"tan 35° ≈ 0,7002 statt sin 35° berechnet.","socratic_question":"Welche Taste hast du gedrückt: sin oder tan?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,5736","equivalents":["+0,5736","0.5736","+0.5736"],"known_errors":{"-0,4282":"bogenmass_modus","−0,4282":"bogenmass_modus","- 0,4282":"bogenmass_modus","-0.4282":"bogenmass_modus","−0.4282":"bogenmass_modus","- 0.4282":"bogenmass_modus","0,8192":"sin_cos_vertauscht","+0,8192":"sin_cos_vertauscht","0.8192":"sin_cos_vertauscht","+0.8192":"sin_cos_vertauscht","0,7002":"tangens_verwechselt","+0,7002":"tangens_verwechselt","0.7002":"tangens_verwechselt","+0.7002":"tangens_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 trigo-verhaeltnis-03 · Tangens · erst die fehlende Kathete, a = 9 cm, c = 15 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3ba007ed-a9f6-44fd-9800-07b92ffdbb65'::uuid, 'exercise', 'Tangens · erst die fehlende Kathete, a = 9 cm, c = 15 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind a = 9 cm und c = 15 cm.

Bestimme tan α. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind a = 9 cm und c = 15 cm.\n\nBestimme tan α. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: fehlende Kathete mit dem Satz des Pythagoras, dann tan α als Kathetenverhältnis.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (tangens_verwechselt, sin_cos_vertauscht, hypotenuse_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3ba007ed-a9f6-44fd-9800-07b92ffdbb65'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3ba007ed-a9f6-44fd-9800-07b92ffdbb65'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3ba007ed-a9f6-44fd-9800-07b92ffdbb65'::uuid,
  p_correct_answers => '["0,75","+0,75","0.75","+0.75"]'::jsonb,
  p_solution        => 'Fehlende Kathete: b = √(c² − a²) = √(225 − 81) = √144 = 12 cm.
tan α = Gegenkathete : Ankathete = a : b = 9 : 12 = 0,75.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch die Hypotenuse statt durch die Ankathete geteilt: a : c = 0,6 ist sin α.","socratic_question":"Welche zwei Seiten setzt der Tangens ins Verhältnis?"},{"error":"Gegenkathete und Ankathete vertauscht: b : a = 12 : 9.","socratic_question":"Welche Kathete liegt dem Winkel α gegenüber?"},{"error":"Für b die Quadrate addiert statt subtrahiert: b = √306.","socratic_question":"Kann die Kathete b länger sein als die Hypotenuse c?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,75","equivalents":["+0,75","0.75","+0.75"],"known_errors":{"0,6":"tangens_verwechselt","+0,6":"tangens_verwechselt","0.6":"tangens_verwechselt","+0.6":"tangens_verwechselt","1,33":"sin_cos_vertauscht","+1,33":"sin_cos_vertauscht","1.33":"sin_cos_vertauscht","+1.33":"sin_cos_vertauscht","0,51":"hypotenuse_verwechselt","+0,51":"hypotenuse_verwechselt","0.51":"hypotenuse_verwechselt","+0.51":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 trigo-verhaeltnis-04 · Kosinus von β · a = 5 cm, b = 12 cm, c = 13 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8d008461-ba47-4c47-9cfa-e485a413611d'::uuid, 'exercise', 'Kosinus von β · a = 5 cm, b = 12 cm, c = 13 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A. β ist der Winkel bei B.

Gegeben sind a = 5 cm, b = 12 cm und c = 13 cm.

Bestimme cos β. Runde auf vier Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A. β ist der Winkel bei B.\n\nGegeben sind a = 5 cm, b = 12 cm und c = 13 cm.\n\nBestimme cos β. Runde auf vier Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Gegen- und Ankathete für den Winkel β neu zuordnen, Bruch runden.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8d008461-ba47-4c47-9cfa-e485a413611d'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8d008461-ba47-4c47-9cfa-e485a413611d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8d008461-ba47-4c47-9cfa-e485a413611d'::uuid,
  p_correct_answers => '["0,3846","+0,3846","0.3846","+0.3846"]'::jsonb,
  p_solution        => 'Für β liegt b gegenüber (Gegenkathete), a liegt an β an (Ankathete).
cos β = Ankathete : Hypotenuse = a : c = 5 : 13 ≈ 0,3846.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Rollen von α übernommen: b : c ist sin β, nicht cos β.","socratic_question":"Welche Kathete liegt am Winkel β an?"},{"error":"Durch die Kathete b statt durch die Hypotenuse geteilt: 5 : 12.","socratic_question":"Welche Seite steht beim Kosinus im Nenner?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,3846","equivalents":["+0,3846","0.3846","+0.3846"],"known_errors":{"0,9231":"sin_cos_vertauscht","+0,9231":"sin_cos_vertauscht","0.9231":"sin_cos_vertauscht","+0.9231":"sin_cos_vertauscht","0,4167":"tangens_verwechselt","+0,4167":"tangens_verwechselt","0.4167":"tangens_verwechselt","+0.4167":"tangens_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 trigo-verhaeltnis-05 · Ähnliche Dreiecke · gleicher Sinus, c' = 12 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1b979a6a-de0f-434e-96c3-c5859a536a36'::uuid, 'exercise', 'Ähnliche Dreiecke · gleicher Sinus, c'' = 12 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Es ist a = 3 cm und c = 5 cm.

Ein zweites Dreieck A''B''C'' hat ebenfalls bei C'' einen rechten Winkel und bei A'' denselben Winkel α. Die Seite a'' liegt der Ecke A'' gegenüber, die Hypotenuse ist c'' = 12 cm.

Wie lang ist a''? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nEs ist a = 3 cm und c = 5 cm.\n\nEin zweites Dreieck A''B''C'' hat ebenfalls bei C'' einen rechten Winkel und bei A'' denselben Winkel α. Die Seite a'' liegt der Ecke A'' gegenüber, die Hypotenuse ist c'' = 12 cm.\n\nWie lang ist a''? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Rückrichtung: Das Seitenverhältnis bleibt in ähnlichen Dreiecken gleich; aus ihm eine Seite des zweiten Dreiecks bestimmen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, additiv_statt_multiplikativ).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1b979a6a-de0f-434e-96c3-c5859a536a36'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1b979a6a-de0f-434e-96c3-c5859a536a36'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1b979a6a-de0f-434e-96c3-c5859a536a36'::uuid,
  p_correct_answers => '["7,2","7.2","7,2 cm","7,2cm"]'::jsonb,
  p_solution        => 'Gleicher Winkel α, also gleiches Verhältnis: sin α = a : c = 3 : 5 = 0,6.
a'' = c'' · sin α = 12 cm · 0,6 = 7,2 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit b : c = 4 : 5 gerechnet, also mit cos α: 12 · 0,8.","socratic_question":"Welche Seite liegt dem Winkel α gegenüber?"},{"error":"Mit a : b = 3 : 4 gerechnet, also mit tan α: 12 · 0,75.","socratic_question":"Welches Verhältnis verbindet a mit der Hypotenuse?"},{"error":"Die Hypotenuse wächst um 7 cm, also a um 7 cm: 3 + 7.","socratic_question":"Bleibt in ähnlichen Dreiecken der Unterschied oder das Verhältnis der Seiten gleich?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,2","equivalents":["7.2","7,2 cm","7,2cm"],"known_errors":{"9":"tangens_verwechselt","10":"additiv_statt_multiplikativ","9,6":"sin_cos_vertauscht","9.6":"sin_cos_vertauscht","9,6 cm":"sin_cos_vertauscht","9,6cm":"sin_cos_vertauscht","9 cm":"tangens_verwechselt","9cm":"tangens_verwechselt","10 cm":"additiv_statt_multiplikativ","10cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 trigo-verhaeltnis-06 · Aus tan α = 0,75 und c = 20 cm die Seite a
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'be954f3b-2fd0-4e36-b508-662e15d93cdc'::uuid, 'exercise', 'Aus tan α = 0,75 und c = 20 cm die Seite a', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Es ist tan α = 0,75 und c = 20 cm.

Wie lang ist die Seite a? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nEs ist tan α = 0,75 und c = 20 cm.\n\nWie lang ist die Seite a? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_trigo_verhaeltnis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-verhaeltnis-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung vom Verhältnis zu den Seiten; Seitenverhältnis 3 : 4 erkennen, mit Pythagoras auf die Hypotenuse schließen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (tangens_verwechselt, sin_cos_vertauscht).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'be954f3b-2fd0-4e36-b508-662e15d93cdc'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'be954f3b-2fd0-4e36-b508-662e15d93cdc'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'be954f3b-2fd0-4e36-b508-662e15d93cdc'::uuid,
  p_correct_answers => '["12","12 cm","12cm"]'::jsonb,
  p_solution        => 'tan α = a : b = 0,75 = 3 : 4, also a = 3k und b = 4k.
Pythagoras: c = √((3k)² + (4k)²) = 5k = 20 cm, also k = 4 cm.
a = 3 · 4 cm = 12 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"tan α wie sin α benutzt: a = 0,75 · 20 cm.","socratic_question":"Steht beim Tangens die Hypotenuse im Verhältnis?"},{"error":"Die Ankathete b = 4k berechnet statt der Gegenkathete a.","socratic_question":"Welche Kathete liegt dem Winkel α gegenüber?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","equivalents":["12 cm","12cm"],"known_errors":{"15":"tangens_verwechselt","16":"sin_cos_vertauscht","15 cm":"tangens_verwechselt","15cm":"tangens_verwechselt","16 cm":"sin_cos_vertauscht","16cm":"sin_cos_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 trigo-seite-01 · Gegenkathete · α = 35°, c = 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fc481b89-f335-4f1a-924e-3dc94fb5768d'::uuid, 'exercise', 'Gegenkathete · α = 35°, c = 10 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind α = 35° und c = 10 cm.

Wie lang ist die Seite a? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind α = 35° und c = 10 cm.\n\nWie lang ist die Seite a? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-seite-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: a = c · sin α, gesuchte Seite im Zähler.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fc481b89-f335-4f1a-924e-3dc94fb5768d'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fc481b89-f335-4f1a-924e-3dc94fb5768d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fc481b89-f335-4f1a-924e-3dc94fb5768d'::uuid,
  p_correct_answers => '["5,74","5.74","5,74 cm","5,74cm"]'::jsonb,
  p_solution        => 'sin α = a : c, also a = c · sin α.
a = 10 cm · sin 35° ≈ 10 cm · 0,5736 ≈ 5,74 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit cos 35° gerechnet: Das ist die Ankathete b.","socratic_question":"Liegt a dem Winkel α gegenüber oder an ihm an?"},{"error":"Mit tan 35° gerechnet, obwohl die Hypotenuse gegeben ist.","socratic_question":"Welches Verhältnis enthält die Hypotenuse und die Gegenkathete?"},{"error":"Der Taschenrechner stand auf Bogenmaß: sin(35) ist negativ.","socratic_question":"Kann eine Seite negativ lang sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,74","equivalents":["5.74","5,74 cm","5,74cm"],"known_errors":{"7":"tangens_verwechselt","8,19":"sin_cos_vertauscht","8.19":"sin_cos_vertauscht","8,19 cm":"sin_cos_vertauscht","8,19cm":"sin_cos_vertauscht","7,00":"tangens_verwechselt","7.00":"tangens_verwechselt","7,00 cm":"tangens_verwechselt","7,00cm":"tangens_verwechselt","7 cm":"tangens_verwechselt","7cm":"tangens_verwechselt","-4,28":"bogenmass_modus","−4,28":"bogenmass_modus","- 4,28":"bogenmass_modus","-4.28":"bogenmass_modus","−4.28":"bogenmass_modus","- 4.28":"bogenmass_modus","-4,28 cm":"bogenmass_modus","-4,28cm":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 trigo-seite-02 · Gegenkathete über den Tangens · α = 40°, b = 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '881bdddb-0984-422c-bf46-c2a8446155fe'::uuid, 'exercise', 'Gegenkathete über den Tangens · α = 40°, b = 6 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind α = 40° und b = 6 cm.

Wie lang ist die Seite a? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind α = 40° und b = 6 cm.\n\nWie lang ist die Seite a? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-seite-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: a = b · tan α, zwei Katheten im Verhältnis.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '881bdddb-0984-422c-bf46-c2a8446155fe'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '881bdddb-0984-422c-bf46-c2a8446155fe'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '881bdddb-0984-422c-bf46-c2a8446155fe'::uuid,
  p_correct_answers => '["5,03","5.03","5,03 cm","5,03cm"]'::jsonb,
  p_solution        => 'tan α = a : b, also a = b · tan α.
a = 6 cm · tan 40° ≈ 6 cm · 0,8391 ≈ 5,03 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Gegen- und Ankathete vertauscht: tan α = b : a, also a = b : tan α.","socratic_question":"Welche Kathete liegt dem Winkel α gegenüber?"},{"error":"Mit sin 40° gerechnet, als wäre b die Hypotenuse.","socratic_question":"Ist b eine Kathete oder die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß: tan(40) ist negativ.","socratic_question":"Kann eine Seite negativ lang sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,03","equivalents":["5.03","5,03 cm","5,03cm"],"known_errors":{"7,15":"sin_cos_vertauscht","7.15":"sin_cos_vertauscht","7,15 cm":"sin_cos_vertauscht","7,15cm":"sin_cos_vertauscht","3,86":"tangens_verwechselt","3.86":"tangens_verwechselt","3,86 cm":"tangens_verwechselt","3,86cm":"tangens_verwechselt","-6,70":"bogenmass_modus","−6,70":"bogenmass_modus","- 6,70":"bogenmass_modus","-6.70":"bogenmass_modus","−6.70":"bogenmass_modus","- 6.70":"bogenmass_modus","-6,7":"bogenmass_modus","−6,7":"bogenmass_modus","- 6,7":"bogenmass_modus","-6.7":"bogenmass_modus","−6.7":"bogenmass_modus","- 6.7":"bogenmass_modus","-6,70 cm":"bogenmass_modus","-6,70cm":"bogenmass_modus","-6,7 cm":"bogenmass_modus","-6,7cm":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 trigo-seite-03 · Hypotenuse im Nenner · α = 28°, a = 4,5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '13d6dc4d-737e-4fd3-a67d-fb401ff5e223'::uuid, 'exercise', 'Hypotenuse im Nenner · α = 28°, a = 4,5 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind α = 28° und a = 4,5 cm.

Wie lang ist die Hypotenuse c? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind α = 28° und a = 4,5 cm.\n\nWie lang ist die Hypotenuse c? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k10_trigo', 'trigo-seite-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Die gesuchte Seite steht im Nenner; sin α = a : c nach c umstellen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (multipliziert_statt_dividiert, sin_cos_vertauscht, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '13d6dc4d-737e-4fd3-a67d-fb401ff5e223'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '13d6dc4d-737e-4fd3-a67d-fb401ff5e223'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '13d6dc4d-737e-4fd3-a67d-fb401ff5e223'::uuid,
  p_correct_answers => '["9,59","9.59","9,59 cm","9,59cm"]'::jsonb,
  p_solution        => 'sin α = a : c, also c = a : sin α.
c = 4,5 cm : sin 28° ≈ 4,5 cm : 0,4695 ≈ 9,59 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"a · sin α statt a : sin α gerechnet.","socratic_question":"Kann die Hypotenuse kürzer sein als die Kathete a?"},{"error":"Mit cos 28° gerechnet, als läge a am Winkel α an.","socratic_question":"Liegt a dem Winkel α gegenüber oder an ihm an?"},{"error":"Mit tan 28° gerechnet: Das ergibt die Kathete b, nicht die Hypotenuse.","socratic_question":"Welches Verhältnis enthält die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß.","socratic_question":"Hast du DEG oder RAD in der Anzeige?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9,59","equivalents":["9.59","9,59 cm","9,59cm"],"known_errors":{"2,11":"multipliziert_statt_dividiert","2.11":"multipliziert_statt_dividiert","2,11 cm":"multipliziert_statt_dividiert","2,11cm":"multipliziert_statt_dividiert","5,10":"sin_cos_vertauscht","5.10":"sin_cos_vertauscht","5,1":"sin_cos_vertauscht","5.1":"sin_cos_vertauscht","5,10 cm":"sin_cos_vertauscht","5,10cm":"sin_cos_vertauscht","5,1 cm":"sin_cos_vertauscht","5,1cm":"sin_cos_vertauscht","8,46":"tangens_verwechselt","8.46":"tangens_verwechselt","8,46 cm":"tangens_verwechselt","8,46cm":"tangens_verwechselt","16,61":"bogenmass_modus","16.61":"bogenmass_modus","16,61 cm":"bogenmass_modus","16,61cm":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 trigo-seite-04 · Ankathete · α = 52°, c = 8,4 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '33bdde50-6f8d-4d2e-a80c-62601488e4a2'::uuid, 'exercise', 'Ankathete · α = 52°, c = 8,4 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind α = 52° und c = 8,4 cm.

Wie lang ist die Seite b? Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind α = 52° und c = 8,4 cm.\n\nWie lang ist die Seite b? Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-seite-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Ankathete erkennen, Kosinus wählen, ohne gerundeten Zwischenwert rechnen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, zu_frueh_gerundet, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '33bdde50-6f8d-4d2e-a80c-62601488e4a2'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '33bdde50-6f8d-4d2e-a80c-62601488e4a2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '33bdde50-6f8d-4d2e-a80c-62601488e4a2'::uuid,
  p_correct_answers => '["5,17","5.17","5,17 cm","5,17cm"]'::jsonb,
  p_solution        => 'b liegt am Winkel α an (Ankathete): cos α = b : c, also b = c · cos α.
b = 8,4 cm · cos 52° ≈ 8,4 cm · 0,6157 ≈ 5,17 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit sin 52° gerechnet: Das ist die Gegenkathete a.","socratic_question":"Liegt b dem Winkel α gegenüber oder an ihm an?"},{"error":"cos 52° auf 0,62 gerundet und damit weitergerechnet.","socratic_question":"Wie stark ändert sich das Ergebnis, wenn du cos 52° vorher rundest?"},{"error":"Der Taschenrechner stand auf Bogenmaß: cos(52) ist negativ.","socratic_question":"Kann eine Seite negativ lang sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,17","equivalents":["5.17","5,17 cm","5,17cm"],"known_errors":{"6,62":"sin_cos_vertauscht","6.62":"sin_cos_vertauscht","6,62 cm":"sin_cos_vertauscht","6,62cm":"sin_cos_vertauscht","5,21":"zu_frueh_gerundet","5.21":"zu_frueh_gerundet","5,21 cm":"zu_frueh_gerundet","5,21cm":"zu_frueh_gerundet","-1,37":"bogenmass_modus","−1,37":"bogenmass_modus","- 1,37":"bogenmass_modus","-1.37":"bogenmass_modus","−1.37":"bogenmass_modus","- 1.37":"bogenmass_modus","-1,37 cm":"bogenmass_modus","-1,37cm":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 trigo-seite-05 · Rampe · 0,8 m Höhe unter 6°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '35cf2123-394c-461b-a303-5073c5cfb2d4'::uuid, 'exercise', 'Rampe · 0,8 m Höhe unter 6°', 'Eine Rampe steigt gleichmäßig unter einem Winkel von 6° gegen die Waagerechte an. Winkel sind im Gradmaß angegeben. Sie überwindet einen Höhenunterschied von 0,8 m.

Wie lang ist die schräge Fläche der Rampe? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Rampe steigt gleichmäßig unter einem Winkel von 6° gegen die Waagerechte an. Winkel sind im Gradmaß angegeben. Sie überwindet einen Höhenunterschied von 0,8 m.\n\nWie lang ist die schräge Fläche der Rampe? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-seite-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Rampe als Hypotenuse erkennen, gesuchte Länge im Nenner.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (multipliziert_statt_dividiert, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '35cf2123-394c-461b-a303-5073c5cfb2d4'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '35cf2123-394c-461b-a303-5073c5cfb2d4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '35cf2123-394c-461b-a303-5073c5cfb2d4'::uuid,
  p_correct_answers => '["7,65","7.65","7,65 m","7,65m"]'::jsonb,
  p_solution        => 'Höhenunterschied, waagerechte Strecke und Rampe bilden ein rechtwinkliges Dreieck. Die Rampe ist die Hypotenuse, die Höhe liegt dem 6°-Winkel gegenüber.
sin 6° = 0,8 m : Rampe, also Rampe = 0,8 m : sin 6° ≈ 0,8 m : 0,1045 ≈ 7,65 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"0,8 · sin 6° statt 0,8 : sin 6° gerechnet.","socratic_question":"Kann die Rampe kürzer sein als der Höhenunterschied?"},{"error":"Mit tan 6° gerechnet: Das ist die waagerechte Strecke, nicht die Rampe.","socratic_question":"Ist die Rampe eine Kathete oder die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß: sin(6) ist negativ.","socratic_question":"Kann eine Länge negativ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,65","equivalents":["7.65","7,65 m","7,65m"],"known_errors":{"0,08":"multipliziert_statt_dividiert","0.08":"multipliziert_statt_dividiert","0,08 m":"multipliziert_statt_dividiert","0,08m":"multipliziert_statt_dividiert","7,61":"tangens_verwechselt","7.61":"tangens_verwechselt","7,61 m":"tangens_verwechselt","7,61m":"tangens_verwechselt","-2,86":"bogenmass_modus","−2,86":"bogenmass_modus","- 2,86":"bogenmass_modus","-2.86":"bogenmass_modus","−2.86":"bogenmass_modus","- 2.86":"bogenmass_modus","-2,86 m":"bogenmass_modus","-2,86m":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 trigo-seite-06 · Flächeninhalt · α = 38°, c = 12 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6778b0b4-e325-4ce4-b2a9-c083b57a5987'::uuid, 'exercise', 'Flächeninhalt · α = 38°, c = 12 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind α = 38° und c = 12 cm.

Berechne den Flächeninhalt des Dreiecks. Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind α = 38° und c = 12 cm.\n\nBerechne den Flächeninhalt des Dreiecks. Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_seite',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm²', false, 2, 'draft', 'edvance_k10_trigo', 'trigo-seite-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: beide Katheten über Sinus und Kosinus bestimmen und den Flächeninhalt bilden.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, zu_frueh_gerundet, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6778b0b4-e325-4ce4-b2a9-c083b57a5987'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6778b0b4-e325-4ce4-b2a9-c083b57a5987'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6778b0b4-e325-4ce4-b2a9-c083b57a5987'::uuid,
  p_correct_answers => '["34,93","34.93","34,93 cm²","34,93cm²"]'::jsonb,
  p_solution        => 'a = c · sin α = 12 cm · sin 38° ≈ 7,3879 cm.
b = c · cos α = 12 cm · cos 38° ≈ 9,4561 cm.
Die Katheten stehen senkrecht aufeinander: A = ½ · a · b ≈ 34,93 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"a · b ohne den Faktor ½ gerechnet.","socratic_question":"Welcher Anteil des Rechtecks aus a und b ist das Dreieck?"},{"error":"sin 38° ≈ 0,62 und cos 38° ≈ 0,79 gerundet und damit weitergerechnet.","socratic_question":"Wie stark ändert sich das Ergebnis, wenn du die Werte vorher rundest?"},{"error":"Der Taschenrechner stand auf Bogenmaß.","socratic_question":"Hast du DEG oder RAD in der Anzeige?"}]'::jsonb,
  p_acceptance      => '{"canonical":"34,93","equivalents":["34.93","34,93 cm²","34,93cm²"],"known_errors":{"69,86":"halbieren_vergessen","69.86":"halbieren_vergessen","69,86 cm²":"halbieren_vergessen","69,86cm²":"halbieren_vergessen","35,27":"zu_frueh_gerundet","35.27":"zu_frueh_gerundet","35,27 cm²":"zu_frueh_gerundet","35,27cm²":"zu_frueh_gerundet","20,38":"bogenmass_modus","20.38":"bogenmass_modus","20,38 cm²":"bogenmass_modus","20,38cm²":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 trigo-winkel-01 · Winkel über den Sinus · a = 3 cm, c = 5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ccd00ca0-8589-4826-9f85-ed97dbb37116'::uuid, 'exercise', 'Winkel über den Sinus · a = 3 cm, c = 5 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind a = 3 cm und c = 5 cm.

Berechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind a = 3 cm und c = 5 cm.\n\nBerechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, 1, 'draft', 'edvance_k10_trigo', 'trigo-winkel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: sin α aus zwei Seiten, dann α mit sin⁻¹.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umkehrfunktion_vergessen, sin_cos_vertauscht, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ccd00ca0-8589-4826-9f85-ed97dbb37116'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ccd00ca0-8589-4826-9f85-ed97dbb37116'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ccd00ca0-8589-4826-9f85-ed97dbb37116'::uuid,
  p_correct_answers => '["36,9","36.9","36,9 °","36,9°"]'::jsonb,
  p_solution        => 'sin α = a : c = 3 : 5 = 0,6.
α = sin⁻¹(0,6) ≈ 36,9°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Sinuswert 0,6 als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"cos⁻¹ statt sin⁻¹ genommen: Das ist der Winkel β.","socratic_question":"Liegt a dem Winkel α gegenüber oder an ihm an?"},{"error":"tan⁻¹ genommen, obwohl die Hypotenuse gegeben ist.","socratic_question":"Welches Verhältnis enthält die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.","socratic_question":"Passt ein Winkel unter 1° zu einem Dreieck mit den Seiten 3 cm und 5 cm?"}]'::jsonb,
  p_acceptance      => '{"canonical":"36,9","equivalents":["36.9","36,9 °","36,9°"],"known_errors":{"31":"tangens_verwechselt","0,6":"umkehrfunktion_vergessen","0.6":"umkehrfunktion_vergessen","0,6 °":"umkehrfunktion_vergessen","0,6°":"umkehrfunktion_vergessen","53,1":"sin_cos_vertauscht","53.1":"sin_cos_vertauscht","53,1 °":"sin_cos_vertauscht","53,1°":"sin_cos_vertauscht","31,0":"tangens_verwechselt","31.0":"tangens_verwechselt","31,0 °":"tangens_verwechselt","31,0°":"tangens_verwechselt","31 °":"tangens_verwechselt","31°":"tangens_verwechselt","0,64":"bogenmass_modus","0.64":"bogenmass_modus","0,64 °":"bogenmass_modus","0,64°":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 trigo-winkel-02 · Winkel über den Tangens · a = 4 cm, b = 9 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b986435e-8d79-45e5-b7fe-69fb72db8bcb'::uuid, 'exercise', 'Winkel über den Tangens · a = 4 cm, b = 9 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind a = 4 cm und b = 9 cm.

Berechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind a = 4 cm und b = 9 cm.\n\nBerechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, null, 'draft', 'edvance_k10_trigo', 'trigo-winkel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: tan α aus zwei Katheten, dann α mit tan⁻¹.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umkehrfunktion_vergessen, sin_cos_vertauscht, tangens_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b986435e-8d79-45e5-b7fe-69fb72db8bcb'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b986435e-8d79-45e5-b7fe-69fb72db8bcb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b986435e-8d79-45e5-b7fe-69fb72db8bcb'::uuid,
  p_correct_answers => '["24,0","24.0","24","24,0 °","24,0°","24 °","24°"]'::jsonb,
  p_solution        => 'tan α = a : b = 4 : 9 ≈ 0,4444.
α = tan⁻¹(4 : 9) ≈ 24,0°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Tangenswert 4 : 9 als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"Gegen- und Ankathete vertauscht: tan⁻¹(9 : 4) ist der Winkel β.","socratic_question":"Welche Kathete liegt dem Winkel α gegenüber?"},{"error":"sin⁻¹ genommen, als wäre b die Hypotenuse.","socratic_question":"Ist b eine Kathete oder die Hypotenuse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"24,0","equivalents":["24.0","24","24,0 °","24,0°","24 °","24°"],"known_errors":{"66":"sin_cos_vertauscht","0,4":"umkehrfunktion_vergessen","0.4":"umkehrfunktion_vergessen","0,4 °":"umkehrfunktion_vergessen","0,4°":"umkehrfunktion_vergessen","66,0":"sin_cos_vertauscht","66.0":"sin_cos_vertauscht","66,0 °":"sin_cos_vertauscht","66,0°":"sin_cos_vertauscht","66 °":"sin_cos_vertauscht","66°":"sin_cos_vertauscht","26,4":"tangens_verwechselt","26.4":"tangens_verwechselt","26,4 °":"tangens_verwechselt","26,4°":"tangens_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 trigo-winkel-03 · Winkel über den Kosinus · b = 6,5 cm, c = 9 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ef367809-6ed4-4541-ab31-b1f5e19c643f'::uuid, 'exercise', 'Winkel über den Kosinus · b = 6,5 cm, c = 9 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Gegeben sind b = 6,5 cm und c = 9 cm.

Berechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nGegeben sind b = 6,5 cm und c = 9 cm.\n\nBerechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_trigo', 'trigo-winkel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Ankathete erkennen, Kosinus wählen, Dezimalzahlen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, umkehrfunktion_vergessen, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ef367809-6ed4-4541-ab31-b1f5e19c643f'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ef367809-6ed4-4541-ab31-b1f5e19c643f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ef367809-6ed4-4541-ab31-b1f5e19c643f'::uuid,
  p_correct_answers => '["43,8","43.8","43,8 °","43,8°"]'::jsonb,
  p_solution        => 'b liegt am Winkel α an: cos α = b : c = 6,5 : 9 ≈ 0,7222.
α = cos⁻¹(6,5 : 9) ≈ 43,8°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"sin⁻¹ statt cos⁻¹ genommen: Das ist der Winkel β.","socratic_question":"Liegt b dem Winkel α gegenüber oder an ihm an?"},{"error":"tan⁻¹ genommen, als wäre c eine Kathete.","socratic_question":"Ist c eine Kathete oder die Hypotenuse?"},{"error":"Den Kosinuswert als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.","socratic_question":"Passt ein Winkel unter 1° zu diesem Dreieck?"}]'::jsonb,
  p_acceptance      => '{"canonical":"43,8","equivalents":["43.8","43,8 °","43,8°"],"known_errors":{"46,2":"sin_cos_vertauscht","46.2":"sin_cos_vertauscht","46,2 °":"sin_cos_vertauscht","46,2°":"sin_cos_vertauscht","35,8":"tangens_verwechselt","35.8":"tangens_verwechselt","35,8 °":"tangens_verwechselt","35,8°":"tangens_verwechselt","0,7":"umkehrfunktion_vergessen","0.7":"umkehrfunktion_vergessen","0,7 °":"umkehrfunktion_vergessen","0,7°":"umkehrfunktion_vergessen","0,8":"bogenmass_modus","0.8":"bogenmass_modus","0,8 °":"bogenmass_modus","0,8°":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 trigo-winkel-04 · Beide spitzen Winkel · a = 5 cm, c = 8 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0c5d8ee8-fed2-4022-9d27-23860d1d7cc7'::uuid, 'exercise', 'Beide spitzen Winkel · a = 5 cm, c = 8 cm', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A. β ist der Winkel bei B.

Gegeben sind a = 5 cm und c = 8 cm.

Berechne die Winkel α und β. Gib die Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  null, 'MULTI_PART', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_trigo', 'trigo-winkel-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Winkel α in Grad","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Winkel β in Grad","unit":null,"afb":"II","competency_content":"geometrie","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: α mit sin⁻¹, dann β über die Winkelsumme als 90° − α.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"parts.1.afb":{"art":"neu","grund":"Anwenden: sin α aus zwei Seiten, dann sin⁻¹.","charge":"k10-trigo"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-trigo"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"parts.2.afb":{"art":"neu","grund":"Anwenden: zweiter spitzer Winkel über 90° − α.","charge":"k10-trigo"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-trigo"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umkehrfunktion_vergessen, sin_cos_vertauscht, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0c5d8ee8-fed2-4022-9d27-23860d1d7cc7'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0c5d8ee8-fed2-4022-9d27-23860d1d7cc7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0c5d8ee8-fed2-4022-9d27-23860d1d7cc7'::uuid,
  p_correct_answers => '{"1":["38,7","38.7","38,7 °","38,7°"],"2":["51,3","51.3","51,3 °","51,3°"]}'::jsonb,
  p_solution        => 'sin α = a : c = 5 : 8 = 0,625.
α = sin⁻¹(0,625) ≈ 38,7°.
Winkelsumme: α + β = 180° − 90° = 90°, also β = 90° − α ≈ 51,3°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Sinuswert 0,625 als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"cos⁻¹ statt sin⁻¹ genommen: Das ist der Winkel β.","socratic_question":"Liegt a dem Winkel α gegenüber oder an ihm an?"},{"error":"α im Bogenmaß berechnet und von 90 abgezogen.","socratic_question":"Passt ein Winkel von fast 90° zu den Seiten 5 cm und 8 cm?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"38,7","equivalents":["38.7","38,7 °","38,7°"],"known_errors":{"0,625":"umkehrfunktion_vergessen","0.625":"umkehrfunktion_vergessen","0,625 °":"umkehrfunktion_vergessen","0,625°":"umkehrfunktion_vergessen","51,3":"sin_cos_vertauscht","51.3":"sin_cos_vertauscht","51,3 °":"sin_cos_vertauscht","51,3°":"sin_cos_vertauscht"}},"2":{"canonical":"51,3","equivalents":["51.3","51,3 °","51,3°"],"known_errors":{"89,3":"bogenmass_modus","89.3":"bogenmass_modus","89,3 °":"bogenmass_modus","89,3°":"bogenmass_modus"}}}'::jsonb);
  end if;
end
$loesung$;

-- #17 trigo-winkel-05 · Dachneigung · Sparren 5,2 m, Höhe 2,4 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7a00ab4b-d497-46fc-87c4-8e706fc3aaff'::uuid, 'exercise', 'Dachneigung · Sparren 5,2 m, Höhe 2,4 m', 'Ein Dachsparren ist 5,2 m lang. Er reicht von der waagerechten Decke bis zum First, der 2,4 m senkrecht über der Decke liegt.

Unter welchem Winkel ist der Sparren gegen die Waagerechte geneigt? Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Dachsparren ist 5,2 m lang. Er reicht von der waagerechten Decke bis zum First, der 2,4 m senkrecht über der Decke liegt.\n\nUnter welchem Winkel ist der Sparren gegen die Waagerechte geneigt? Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, '°', false, null, 'draft', 'edvance_k10_trigo', 'trigo-winkel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Sparren als Hypotenuse und Dachhöhe als Gegenkathete erkennen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, umkehrfunktion_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7a00ab4b-d497-46fc-87c4-8e706fc3aaff'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7a00ab4b-d497-46fc-87c4-8e706fc3aaff'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7a00ab4b-d497-46fc-87c4-8e706fc3aaff'::uuid,
  p_correct_answers => '["27,5","27.5","27,5 °","27,5°"]'::jsonb,
  p_solution        => 'Sparren, Höhe und waagerechte Strecke bilden ein rechtwinkliges Dreieck; der Sparren ist die Hypotenuse, die Höhe liegt dem Neigungswinkel gegenüber.
sin α = 2,4 : 5,2 ≈ 0,4615.
α = sin⁻¹(2,4 : 5,2) ≈ 27,5°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"cos⁻¹ genommen: Das ist der Winkel am First.","socratic_question":"Liegt die Höhe dem gesuchten Winkel gegenüber oder an ihm an?"},{"error":"tan⁻¹ genommen, als wäre der Sparren die waagerechte Kathete.","socratic_question":"Ist der Sparren eine Kathete oder die Hypotenuse?"},{"error":"Den Sinuswert als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"27,5","equivalents":["27.5","27,5 °","27,5°"],"known_errors":{"62,5":"sin_cos_vertauscht","62.5":"sin_cos_vertauscht","62,5 °":"sin_cos_vertauscht","62,5°":"sin_cos_vertauscht","24,8":"tangens_verwechselt","24.8":"tangens_verwechselt","24,8 °":"tangens_verwechselt","24,8°":"tangens_verwechselt","0,5":"umkehrfunktion_vergessen","0.5":"umkehrfunktion_vergessen","0,5 °":"umkehrfunktion_vergessen","0,5°":"umkehrfunktion_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 trigo-winkel-06 · Winkel aus Flächeninhalt · a = 6 cm, A = 27 cm²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a8e2cd6c-586b-46d4-a25e-55aa33f9e02d'::uuid, 'exercise', 'Winkel aus Flächeninhalt · a = 6 cm, A = 27 cm²', 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.

Die Seite a ist 6 cm lang, der Flächeninhalt des Dreiecks beträgt 27 cm².

Berechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.\n\nDie Seite a ist 6 cm lang, der Flächeninhalt des Dreiecks beträgt 27 cm².\n\nBerechne den Winkel α. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_winkel',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, '°', false, 2, 'draft', 'edvance_k10_trigo', 'trigo-winkel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung über den Flächeninhalt zur zweiten Kathete, dann Winkel mit tan⁻¹.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, tangens_verwechselt, umkehrfunktion_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a8e2cd6c-586b-46d4-a25e-55aa33f9e02d'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a8e2cd6c-586b-46d4-a25e-55aa33f9e02d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a8e2cd6c-586b-46d4-a25e-55aa33f9e02d'::uuid,
  p_correct_answers => '["33,7","33.7","33,7 °","33,7°"]'::jsonb,
  p_solution        => 'Die Katheten stehen senkrecht aufeinander: A = ½ · a · b, also b = 2 · 27 cm² : 6 cm = 9 cm.
tan α = a : b = 6 : 9.
α = tan⁻¹(6 : 9) ≈ 33,7°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ½ im Flächeninhalt vergessen: b = 27 : 6 = 4,5 cm.","socratic_question":"Welcher Anteil des Rechtecks aus a und b ist das Dreieck?"},{"error":"sin⁻¹(6 : 9) genommen, als wäre b die Hypotenuse.","socratic_question":"Ist b eine Kathete oder die Hypotenuse?"},{"error":"Den Tangenswert 6 : 9 als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"33,7","equivalents":["33.7","33,7 °","33,7°"],"known_errors":{"53,1":"halbieren_vergessen","53.1":"halbieren_vergessen","53,1 °":"halbieren_vergessen","53,1°":"halbieren_vergessen","41,8":"tangens_verwechselt","41.8":"tangens_verwechselt","41,8 °":"tangens_verwechselt","41,8°":"tangens_verwechselt","0,7":"umkehrfunktion_vergessen","0.7":"umkehrfunktion_vergessen","0,7 °":"umkehrfunktion_vergessen","0,7°":"umkehrfunktion_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 trigo-anwendung-01 · Steigungswinkel · Straße mit 12 % Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b35bdec8-b1e3-415c-b9eb-7de20660cfdb'::uuid, 'exercise', 'Steigungswinkel · Straße mit 12 % Steigung', 'Ein Verkehrsschild zeigt für eine Straße 12 % Steigung. Das heißt: Auf 100 m waagerechter Strecke steigt die Straße um 12 m.

Unter welchem Winkel steigt die Straße gegen die Waagerechte an? Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Verkehrsschild zeigt für eine Straße 12 % Steigung. Das heißt: Auf 100 m waagerechter Strecke steigt die Straße um 12 m.\n\nUnter welchem Winkel steigt die Straße gegen die Waagerechte an? Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Modellieren, Operieren',
  75, '°', false, null, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Steigung in Prozent als tan α lesen, Winkel mit tan⁻¹.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umkehrfunktion_vergessen, tangens_verwechselt).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b35bdec8-b1e3-415c-b9eb-7de20660cfdb'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b35bdec8-b1e3-415c-b9eb-7de20660cfdb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b35bdec8-b1e3-415c-b9eb-7de20660cfdb'::uuid,
  p_correct_answers => '["6,8","6.8","6,8 °","6,8°"]'::jsonb,
  p_solution        => 'Steigung = Höhenunterschied : waagerechte Strecke = tan α.
tan α = 12 : 100 = 0,12.
α = tan⁻¹(0,12) ≈ 6,8°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Tangenswert 0,12 als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"sin⁻¹ genommen, als wären die 100 m die Länge der Straße selbst.","socratic_question":"Sind die 100 m waagerecht oder entlang der Straße gemessen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6,8","equivalents":["6.8","6,8 °","6,8°"],"known_errors":{"0,12":"umkehrfunktion_vergessen","0.12":"umkehrfunktion_vergessen","0,12 °":"umkehrfunktion_vergessen","0,12°":"umkehrfunktion_vergessen","6,9":"tangens_verwechselt","6.9":"tangens_verwechselt","6,9 °":"tangens_verwechselt","6,9°":"tangens_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 trigo-anwendung-02 · Turmhöhe · 40 m Entfernung, Höhenwinkel 38°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f9f98b88-0b52-4ade-8354-f7bb0894db0f'::uuid, 'exercise', 'Turmhöhe · 40 m Entfernung, Höhenwinkel 38°', 'Ein Punkt am Boden ist 40 m waagerecht vom Fuß eines senkrechten Turms entfernt. Von diesem Punkt aus sieht man die Turmspitze unter einem Winkel von 38° gegen die Waagerechte. Winkel sind im Gradmaß angegeben.

Wie hoch ist der Turm? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Punkt am Boden ist 40 m waagerecht vom Fuß eines senkrechten Turms entfernt. Von diesem Punkt aus sieht man die Turmspitze unter einem Winkel von 38° gegen die Waagerechte. Winkel sind im Gradmaß angegeben.\n\nWie hoch ist der Turm? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Modellieren, Operieren',
  75, 'm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Höhe = Entfernung · tan(Höhenwinkel), Standardsituation.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (tangens_verwechselt, sin_cos_vertauscht, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f9f98b88-0b52-4ade-8354-f7bb0894db0f'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f9f98b88-0b52-4ade-8354-f7bb0894db0f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f9f98b88-0b52-4ade-8354-f7bb0894db0f'::uuid,
  p_correct_answers => '["31,3","31.3","31,3 m","31,3m"]'::jsonb,
  p_solution        => 'Boden, Turm und Sichtlinie bilden ein rechtwinkliges Dreieck mit dem rechten Winkel am Fuß des Turms.
Der Turm liegt dem 38°-Winkel gegenüber, die 40 m liegen an ihm an: tan 38° = h : 40 m.
h = 40 m · tan 38° ≈ 40 m · 0,7813 ≈ 31,3 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit sin 38° gerechnet, als wäre die Entfernung die Sichtlinie.","socratic_question":"Sind die 40 m eine Kathete oder die Hypotenuse?"},{"error":"Gegen- und Ankathete vertauscht: h = 40 m : tan 38°.","socratic_question":"Welche Seite liegt dem 38°-Winkel gegenüber?"},{"error":"Der Taschenrechner stand auf Bogenmaß.","socratic_question":"Hast du DEG oder RAD in der Anzeige?"}]'::jsonb,
  p_acceptance      => '{"canonical":"31,3","equivalents":["31.3","31,3 m","31,3m"],"known_errors":{"24,6":"tangens_verwechselt","24.6":"tangens_verwechselt","24,6 m":"tangens_verwechselt","24,6m":"tangens_verwechselt","51,2":"sin_cos_vertauscht","51.2":"sin_cos_vertauscht","51,2 m":"sin_cos_vertauscht","51,2m":"sin_cos_vertauscht","12,4":"bogenmass_modus","12.4":"bogenmass_modus","12,4 m":"bogenmass_modus","12,4m":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 trigo-anwendung-03 · Steigung in Prozent · Steigungswinkel 8°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '52d18200-7696-4bed-bba7-352cbb35436c'::uuid, 'exercise', 'Steigung in Prozent · Steigungswinkel 8°', 'Ein Weg steigt gleichmäßig unter einem Winkel von 8° gegen die Waagerechte an. Winkel sind im Gradmaß angegeben.

Wie viel Prozent Steigung hat der Weg? Die Steigung in Prozent gibt an, um wie viele Meter der Weg auf 100 m waagerechter Strecke ansteigt. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Weg steigt gleichmäßig unter einem Winkel von 8° gegen die Waagerechte an. Winkel sind im Gradmaß angegeben.\n\nWie viel Prozent Steigung hat der Weg? Die Steigung in Prozent gibt an, um wie viele Meter der Weg auf 100 m waagerechter Strecke ansteigt. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, '%', false, null, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung vom Winkel zur Steigung, tan α in Prozent umrechnen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '52d18200-7696-4bed-bba7-352cbb35436c'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '52d18200-7696-4bed-bba7-352cbb35436c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '52d18200-7696-4bed-bba7-352cbb35436c'::uuid,
  p_correct_answers => '["14,1","14.1","14,1 %","14,1%"]'::jsonb,
  p_solution        => 'Steigung = Höhenunterschied : waagerechte Strecke = tan 8° ≈ 0,1405.
Auf 100 m waagerecht: 0,1405 · 100 ≈ 14,1 m, also 14,1 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit sin 8° gerechnet, als wären die 100 m entlang des Weges gemessen.","socratic_question":"Ist die waagerechte Strecke eine Kathete oder die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß: tan(8) ist negativ.","socratic_question":"Kann ein ansteigender Weg eine negative Steigung haben?"}]'::jsonb,
  p_acceptance      => '{"canonical":"14,1","equivalents":["14.1","14,1 %","14,1%"],"known_errors":{"13,9":"tangens_verwechselt","13.9":"tangens_verwechselt","13,9 %":"tangens_verwechselt","13,9%":"tangens_verwechselt","-680,0":"bogenmass_modus","−680,0":"bogenmass_modus","- 680,0":"bogenmass_modus","-680.0":"bogenmass_modus","−680.0":"bogenmass_modus","- 680.0":"bogenmass_modus","-680":"bogenmass_modus","−680":"bogenmass_modus","- 680":"bogenmass_modus","-680,0 %":"bogenmass_modus","-680,0%":"bogenmass_modus","-680 %":"bogenmass_modus","-680%":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 trigo-anwendung-04 · Entfernung vom Leuchtturm · 25 m hoch, Sichtwinkel 9°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '17b68c02-51e8-4484-b955-5ee77729c024'::uuid, 'exercise', 'Entfernung vom Leuchtturm · 25 m hoch, Sichtwinkel 9°', 'Ein Beobachter steht oben auf einem 25 m hohen Leuchtturm. Die Sichtlinie von dort zu einem Boot auf dem Wasser bildet mit der Waagerechten einen Winkel von 9°. Winkel sind im Gradmaß angegeben.

Wie weit ist das Boot waagerecht vom Fuß des Leuchtturms entfernt? Runde auf ganze Meter.',
  '{"kind":"short_input","prompt":"Ein Beobachter steht oben auf einem 25 m hohen Leuchtturm. Die Sichtlinie von dort zu einem Boot auf dem Wasser bildet mit der Waagerechten einen Winkel von 9°. Winkel sind im Gradmaß angegeben.\n\nWie weit ist das Boot waagerecht vom Fuß des Leuchtturms entfernt? Runde auf ganze Meter."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, 1, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wechselwinkel erkennen, gesuchte Strecke im Nenner (Entfernung = Höhe : tan).","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (multipliziert_statt_dividiert, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '17b68c02-51e8-4484-b955-5ee77729c024'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '17b68c02-51e8-4484-b955-5ee77729c024'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '17b68c02-51e8-4484-b955-5ee77729c024'::uuid,
  p_correct_answers => '["158","158 m","158m"]'::jsonb,
  p_solution        => 'Die Sichtlinie bildet auch mit der Wasserfläche beim Boot einen Winkel von 9° (Wechselwinkel).
Dort liegt der Turm (25 m) gegenüber, die gesuchte Entfernung e an: tan 9° = 25 m : e.
e = 25 m : tan 9° ≈ 25 m : 0,1584 ≈ 158 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"25 · tan 9° statt 25 : tan 9° gerechnet.","socratic_question":"Kann das Boot näher sein als der Turm hoch ist, wenn man so flach hinabschaut?"},{"error":"Mit sin 9° gerechnet: Das ist die Länge der Sichtlinie, nicht die waagerechte Entfernung.","socratic_question":"Ist die gesuchte Entfernung eine Kathete oder die Hypotenuse?"},{"error":"Der Taschenrechner stand auf Bogenmaß: tan(9) ist negativ.","socratic_question":"Kann eine Entfernung negativ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"158","equivalents":["158 m","158m"],"known_errors":{"4":"multipliziert_statt_dividiert","160":"tangens_verwechselt","4 m":"multipliziert_statt_dividiert","4m":"multipliziert_statt_dividiert","160 m":"tangens_verwechselt","160m":"tangens_verwechselt","-55":"bogenmass_modus","−55":"bogenmass_modus","- 55":"bogenmass_modus","-55 m":"bogenmass_modus","-55m":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 trigo-anwendung-05 · Leiter · 6 m lang, 70° zum Boden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '725e786e-b402-4264-a990-ad5db129fa6a'::uuid, 'exercise', 'Leiter · 6 m lang, 70° zum Boden', 'Eine 6 m lange Leiter lehnt an einer senkrechten Hauswand. Sie bildet mit dem waagerechten Boden einen Winkel von 70°. Winkel sind im Gradmaß angegeben.

In welcher Höhe berührt die Leiter die Wand? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine 6 m lange Leiter lehnt an einer senkrechten Hauswand. Sie bildet mit dem waagerechten Boden einen Winkel von 70°. Winkel sind im Gradmaß angegeben.\n\nIn welcher Höhe berührt die Leiter die Wand? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Leiter als Hypotenuse, Höhe an der Wand als Gegenkathete.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (sin_cos_vertauscht, tangens_verwechselt, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '725e786e-b402-4264-a990-ad5db129fa6a'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '725e786e-b402-4264-a990-ad5db129fa6a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '725e786e-b402-4264-a990-ad5db129fa6a'::uuid,
  p_correct_answers => '["5,64","5.64","5,64 m","5,64m"]'::jsonb,
  p_solution        => 'Leiter, Wand und Boden bilden ein rechtwinkliges Dreieck; die Leiter ist die Hypotenuse, die Höhe liegt dem 70°-Winkel gegenüber.
h = 6 m · sin 70° ≈ 6 m · 0,9397 ≈ 5,64 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit cos 70° gerechnet: Das ist der Abstand des Fußes von der Wand.","socratic_question":"Liegt die Höhe dem 70°-Winkel gegenüber oder an ihm an?"},{"error":"Mit tan 70° gerechnet, als wäre die Leiter eine Kathete.","socratic_question":"Kann die Höhe größer sein als die Leiter lang ist?"},{"error":"Der Taschenrechner stand auf Bogenmaß.","socratic_question":"Hast du DEG oder RAD in der Anzeige?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,64","equivalents":["5.64","5,64 m","5,64m"],"known_errors":{"2,05":"sin_cos_vertauscht","2.05":"sin_cos_vertauscht","2,05 m":"sin_cos_vertauscht","2,05m":"sin_cos_vertauscht","16,48":"tangens_verwechselt","16.48":"tangens_verwechselt","16,48 m":"tangens_verwechselt","16,48m":"tangens_verwechselt","4,64":"bogenmass_modus","4.64":"bogenmass_modus","4,64 m":"bogenmass_modus","4,64m":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 trigo-anwendung-06 · Höhengewinn · 500 m Straße mit 8 % Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '32f15d20-ea8e-4ff0-9d43-d10daa9500bc'::uuid, 'exercise', 'Höhengewinn · 500 m Straße mit 8 % Steigung', 'Eine Straße hat 8 % Steigung: Auf 100 m waagerechter Strecke steigt sie um 8 m. Ein Wagen fährt 500 m entlang der Straße bergauf.

Wie viele Meter Höhe gewinnt er dabei? Rechne ohne gerundete Zwischenergebnisse. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Straße hat 8 % Steigung: Auf 100 m waagerechter Strecke steigt sie um 8 m. Ein Wagen fährt 500 m entlang der Straße bergauf.\n\nWie viele Meter Höhe gewinnt er dabei? Rechne ohne gerundete Zwischenergebnisse. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm', false, 2, 'draft', 'edvance_k10_trigo', 'trigo-anwendung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Steigung zuerst in einen Winkel umrechnen, dann mit der Straßenlänge als Hypotenuse die Höhe bestimmen.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (tangens_verwechselt, zu_frueh_gerundet, umkehrfunktion_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '32f15d20-ea8e-4ff0-9d43-d10daa9500bc'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '32f15d20-ea8e-4ff0-9d43-d10daa9500bc'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '32f15d20-ea8e-4ff0-9d43-d10daa9500bc'::uuid,
  p_correct_answers => '["39,9","39.9","39,9 m","39,9m"]'::jsonb,
  p_solution        => 'Steigungswinkel: tan α = 8 : 100 = 0,08, also α = tan⁻¹(0,08) ≈ 4,5739°.
Die 500 m sind die Hypotenuse (entlang der Straße), die Höhe liegt α gegenüber.
h = 500 m · sin α ≈ 500 m · 0,0797 ≈ 39,9 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 500 m wie eine waagerechte Strecke behandelt: 500 · 0,08.","socratic_question":"Sind die 500 m waagerecht oder entlang der Straße gemessen?"},{"error":"Den Steigungswinkel auf 4,6° gerundet und damit weitergerechnet.","socratic_question":"Wie stark ändert sich das Ergebnis, wenn du den Winkel vorher rundest?"},{"error":"Den Tangenswert 0,08 als Winkel in den Sinus eingesetzt.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"39,9","equivalents":["39.9","39,9 m","39,9m"],"known_errors":{"40":"tangens_verwechselt","40,0":"tangens_verwechselt","40.0":"tangens_verwechselt","40,0 m":"tangens_verwechselt","40,0m":"tangens_verwechselt","40 m":"tangens_verwechselt","40m":"tangens_verwechselt","40,1":"zu_frueh_gerundet","40.1":"zu_frueh_gerundet","40,1 m":"zu_frueh_gerundet","40,1m":"zu_frueh_gerundet","0,7":"umkehrfunktion_vergessen","0.7":"umkehrfunktion_vergessen","0,7 m":"umkehrfunktion_vergessen","0,7m":"umkehrfunktion_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 trigo-kosinussatz-01 · Dritte Seite · a = 5 cm, b = 7 cm, γ = 50°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0fe09783-e4c8-41cc-b7f5-5dfcaaed760a'::uuid, 'exercise', 'Dritte Seite · a = 5 cm, b = 7 cm, γ = 50°', 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.

Gegeben sind a = 5 cm, b = 7 cm und γ = 50°.

Wie lang ist die Seite c? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.\n\nGegeben sind a = 5 cm, b = 7 cm und γ = 50°.\n\nWie lang ist die Seite c? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Kosinussatz c² = a² + b² − 2ab · cos γ direkt anwenden.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, pythagoras_ohne_rechten_winkel, wurzel_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0fe09783-e4c8-41cc-b7f5-5dfcaaed760a'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0fe09783-e4c8-41cc-b7f5-5dfcaaed760a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0fe09783-e4c8-41cc-b7f5-5dfcaaed760a'::uuid,
  p_correct_answers => '["5,39","5.39","5,39 cm","5,39cm"]'::jsonb,
  p_solution        => 'Kosinussatz: c² = a² + b² − 2ab · cos γ.
c² = 25 + 49 − 70 · cos 50° ≈ 29,0049 cm².
c ≈ 5,39 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Term 2ab · cos γ addiert statt abgezogen.","socratic_question":"Was bleibt vom Kosinussatz übrig, wenn γ = 90° ist?"},{"error":"Mit dem Satz des Pythagoras gerechnet: c = √74.","socratic_question":"Hat das Dreieck einen rechten Winkel?"},{"error":"c² ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon c ausgerechnet oder erst c²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,39","equivalents":["5.39","5,39 cm","5,39cm"],"known_errors":{"29":"wurzel_vergessen","10,91":"kosinussatz_vorzeichen","10.91":"kosinussatz_vorzeichen","10,91 cm":"kosinussatz_vorzeichen","10,91cm":"kosinussatz_vorzeichen","8,60":"pythagoras_ohne_rechten_winkel","8.60":"pythagoras_ohne_rechten_winkel","8,6":"pythagoras_ohne_rechten_winkel","8.6":"pythagoras_ohne_rechten_winkel","8,60 cm":"pythagoras_ohne_rechten_winkel","8,60cm":"pythagoras_ohne_rechten_winkel","8,6 cm":"pythagoras_ohne_rechten_winkel","8,6cm":"pythagoras_ohne_rechten_winkel","29,00":"wurzel_vergessen","29.00":"wurzel_vergessen","29,00 cm":"wurzel_vergessen","29,00cm":"wurzel_vergessen","29 cm":"wurzel_vergessen","29cm":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 trigo-kosinussatz-02 · Dritte Seite · a = 6 cm, b = 9 cm, γ = 72°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '77d9bfd8-a0f1-4714-90d6-1667633d6f67'::uuid, 'exercise', 'Dritte Seite · a = 6 cm, b = 9 cm, γ = 72°', 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.

Gegeben sind a = 6 cm, b = 9 cm und γ = 72°.

Wie lang ist die Seite c? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.\n\nGegeben sind a = 6 cm, b = 9 cm und γ = 72°.\n\nWie lang ist die Seite c? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Kosinussatz mit anderen Zahlen, Taschenrechner im Gradmaß.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, pythagoras_ohne_rechten_winkel, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '77d9bfd8-a0f1-4714-90d6-1667633d6f67'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '77d9bfd8-a0f1-4714-90d6-1667633d6f67'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '77d9bfd8-a0f1-4714-90d6-1667633d6f67'::uuid,
  p_correct_answers => '["9,14","9.14","9,14 cm","9,14cm"]'::jsonb,
  p_solution        => 'Kosinussatz: c² = a² + b² − 2ab · cos γ.
c² = 36 + 81 − 108 · cos 72° ≈ 83,6262 cm².
c ≈ 9,14 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Term 2ab · cos γ addiert statt abgezogen.","socratic_question":"Muss c bei einem spitzen Winkel γ kürzer oder länger sein als beim rechten Winkel?"},{"error":"Mit dem Satz des Pythagoras gerechnet: c = √117.","socratic_question":"Hat das Dreieck einen rechten Winkel?"},{"error":"Der Taschenrechner stand auf Bogenmaß.","socratic_question":"Hast du DEG oder RAD in der Anzeige?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9,14","equivalents":["9.14","9,14 cm","9,14cm"],"known_errors":{"12,26":"kosinussatz_vorzeichen","12.26":"kosinussatz_vorzeichen","12,26 cm":"kosinussatz_vorzeichen","12,26cm":"kosinussatz_vorzeichen","10,82":"pythagoras_ohne_rechten_winkel","10.82":"pythagoras_ohne_rechten_winkel","10,82 cm":"pythagoras_ohne_rechten_winkel","10,82cm":"pythagoras_ohne_rechten_winkel","14,88":"bogenmass_modus","14.88":"bogenmass_modus","14,88 cm":"bogenmass_modus","14,88cm":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 trigo-kosinussatz-03 · Winkel aus drei Seiten · 7 cm, 8 cm, 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '516c5bcd-87cf-4efb-8d02-2117ab4b6e94'::uuid, 'exercise', 'Winkel aus drei Seiten · 7 cm, 8 cm, 10 cm', 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.

Gegeben sind a = 7 cm, b = 8 cm und c = 10 cm.

Berechne den Winkel γ. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.\n\nGegeben sind a = 7 cm, b = 8 cm und c = 10 cm.\n\nBerechne den Winkel γ. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Kosinussatz nach cos γ umstellen, dann cos⁻¹.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, umkehrfunktion_vergessen, bogenmass_modus).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '516c5bcd-87cf-4efb-8d02-2117ab4b6e94'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '516c5bcd-87cf-4efb-8d02-2117ab4b6e94'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '516c5bcd-87cf-4efb-8d02-2117ab4b6e94'::uuid,
  p_correct_answers => '["83,3","83.3","83,3 °","83,3°"]'::jsonb,
  p_solution        => 'Kosinussatz nach cos γ umgestellt: cos γ = (a² + b² − c²) : (2ab).
cos γ = (49 + 64 − 100) : 112 = 13 : 112 ≈ 0,1161.
γ = cos⁻¹(13 : 112) ≈ 83,3°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit c² = a² + b² + 2ab · cos γ umgestellt: cos γ = −13 : 112.","socratic_question":"Welches Rechenzeichen steht vor 2ab · cos γ?"},{"error":"Den Kosinuswert als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"},{"error":"Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.","socratic_question":"Passt ein Winkel von gut 1° zu diesem Dreieck?"}]'::jsonb,
  p_acceptance      => '{"canonical":"83,3","equivalents":["83.3","83,3 °","83,3°"],"known_errors":{"96,7":"kosinussatz_vorzeichen","96.7":"kosinussatz_vorzeichen","96,7 °":"kosinussatz_vorzeichen","96,7°":"kosinussatz_vorzeichen","0,1":"umkehrfunktion_vergessen","0.1":"umkehrfunktion_vergessen","0,1 °":"umkehrfunktion_vergessen","0,1°":"umkehrfunktion_vergessen","1,5":"bogenmass_modus","1.5":"bogenmass_modus","1,5 °":"bogenmass_modus","1,5°":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 trigo-kosinussatz-04 · Dritte Seite bei stumpfem Winkel · γ = 115°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c75c2c98-1bae-4ea9-92fa-f4353fdcddb2'::uuid, 'exercise', 'Dritte Seite bei stumpfem Winkel · γ = 115°', 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.

Gegeben sind a = 4 cm, b = 6,5 cm und γ = 115°.

Wie lang ist die Seite c? Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.\n\nGegeben sind a = 4 cm, b = 6,5 cm und γ = 115°.\n\nWie lang ist die Seite c? Rechne ohne gerundete Zwischenergebnisse. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: stumpfer Winkel, cos γ ist negativ; das Minus im Kosinussatz macht c länger.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, pythagoras_ohne_rechten_winkel, zu_frueh_gerundet, wurzel_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c75c2c98-1bae-4ea9-92fa-f4353fdcddb2'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c75c2c98-1bae-4ea9-92fa-f4353fdcddb2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c75c2c98-1bae-4ea9-92fa-f4353fdcddb2'::uuid,
  p_correct_answers => '["8,96","8.96","8,96 cm","8,96cm"]'::jsonb,
  p_solution        => 'Kosinussatz: c² = a² + b² − 2ab · cos γ.
cos 115° ≈ −0,4226 ist negativ, das Minus macht daraus ein Plus.
c² = 16 + 42,25 − 52 · cos 115° ≈ 80,2261 cm².
c ≈ 8,96 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Term 2ab · cos γ addiert statt abgezogen.","socratic_question":"Muss c gegenüber einem stumpfen Winkel länger oder kürzer sein als beim rechten Winkel?"},{"error":"Mit dem Satz des Pythagoras gerechnet: c = √58,25.","socratic_question":"Hat das Dreieck einen rechten Winkel?"},{"error":"cos 115° auf −0,4 gerundet und damit weitergerechnet.","socratic_question":"Wie stark ändert sich das Ergebnis, wenn du cos 115° vorher rundest?"},{"error":"c² ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon c ausgerechnet oder erst c²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8,96","equivalents":["8.96","8,96 cm","8,96cm"],"known_errors":{"6,02":"kosinussatz_vorzeichen","6.02":"kosinussatz_vorzeichen","6,02 cm":"kosinussatz_vorzeichen","6,02cm":"kosinussatz_vorzeichen","7,63":"pythagoras_ohne_rechten_winkel","7.63":"pythagoras_ohne_rechten_winkel","7,63 cm":"pythagoras_ohne_rechten_winkel","7,63cm":"pythagoras_ohne_rechten_winkel","8,89":"zu_frueh_gerundet","8.89":"zu_frueh_gerundet","8,89 cm":"zu_frueh_gerundet","8,89cm":"zu_frueh_gerundet","80,23":"wurzel_vergessen","80.23":"wurzel_vergessen","80,23 cm":"wurzel_vergessen","80,23cm":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 trigo-kosinussatz-05 · Breite eines Sees · 320 m, 450 m, 64°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '79463f55-7678-49a4-8f1a-226cbe5e4e85'::uuid, 'exercise', 'Breite eines Sees · 320 m, 450 m, 64°', 'Die Punkte A und B liegen an gegenüberliegenden Ufern eines Sees. Von einem Messpunkt C an Land misst man: C ist 320 m von A und 450 m von B entfernt, der Winkel bei C zwischen den beiden Richtungen beträgt 64°. Winkel sind im Gradmaß angegeben. Das Dreieck ABC hat keinen rechten Winkel.

Wie weit sind A und B voneinander entfernt? Runde auf ganze Meter.',
  '{"kind":"short_input","prompt":"Die Punkte A und B liegen an gegenüberliegenden Ufern eines Sees. Von einem Messpunkt C an Land misst man: C ist 320 m von A und 450 m von B entfernt, der Winkel bei C zwischen den beiden Richtungen beträgt 64°. Winkel sind im Gradmaß angegeben. Das Dreieck ABC hat keinen rechten Winkel.\n\nWie weit sind A und B voneinander entfernt? Runde auf ganze Meter."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Messpunkt als Ecke C mit eingeschlossenem Winkel erkennen, Kosinussatz.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, pythagoras_ohne_rechten_winkel, wurzel_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '79463f55-7678-49a4-8f1a-226cbe5e4e85'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = '79463f55-7678-49a4-8f1a-226cbe5e4e85'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '79463f55-7678-49a4-8f1a-226cbe5e4e85'::uuid,
  p_correct_answers => '["423","423 m","423m"]'::jsonb,
  p_solution        => 'Im Dreieck ABC sind die Seiten an C bekannt: 320 m und 450 m, eingeschlossener Winkel γ = 64°.
Kosinussatz: AB² = 320² + 450² − 2 · 320 · 450 · cos 64° ≈ 178649 m².
AB ≈ 423 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Term 2ab · cos γ addiert statt abgezogen.","socratic_question":"Was bleibt vom Kosinussatz übrig, wenn γ = 90° ist?"},{"error":"Mit dem Satz des Pythagoras gerechnet, obwohl der Winkel bei C 64° beträgt.","socratic_question":"Hat das Dreieck einen rechten Winkel?"},{"error":"AB² ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann der See über 100 km breit sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"423","equivalents":["423 m","423m"],"known_errors":{"552":"pythagoras_ohne_rechten_winkel","657":"kosinussatz_vorzeichen","178649":"wurzel_vergessen","657 m":"kosinussatz_vorzeichen","657m":"kosinussatz_vorzeichen","552 m":"pythagoras_ohne_rechten_winkel","552m":"pythagoras_ohne_rechten_winkel","178649 m":"wurzel_vergessen","178649m":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 trigo-kosinussatz-06 · Größter Winkel · Seiten 5 cm, 6 cm, 9 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd2eeb8e8-ab12-47a0-be00-874e25cf172f'::uuid, 'exercise', 'Größter Winkel · Seiten 5 cm, 6 cm, 9 cm', 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.

Gegeben sind a = 5 cm, b = 6 cm und c = 9 cm.

Berechne den größten Winkel des Dreiecks. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.\n\nGegeben sind a = 5 cm, b = 6 cm und c = 9 cm.\n\nBerechne den größten Winkel des Dreiecks. Gib den Winkel im Gradmaß an. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_trigo_kosinussatz',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, '°', false, 2, 'draft', 'edvance_k10_trigo', 'trigo-kosinussatz-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: den größten Winkel der längsten Seite gegenüber erkennen, Kosinussatz umstellen, negativer Kosinuswert.","charge":"k10-trigo"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-trigo"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-trigo"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.","charge":"k10-trigo"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).","charge":"k10-trigo"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-trigo"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-trigo"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-trigo"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-trigo"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kosinussatz_vorzeichen, falsche_groesse_beantwortet, umkehrfunktion_vergessen).","charge":"k10-trigo"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-trigo"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd2eeb8e8-ab12-47a0-be00-874e25cf172f'::uuid and t.status = 'draft' and t.source = 'edvance_k10_trigo')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd2eeb8e8-ab12-47a0-be00-874e25cf172f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd2eeb8e8-ab12-47a0-be00-874e25cf172f'::uuid,
  p_correct_answers => '["109,5","109.5","109,5 °","109,5°"]'::jsonb,
  p_solution        => 'Der größte Winkel liegt der längsten Seite c gegenüber, also γ.
cos γ = (a² + b² − c²) : (2ab) = (25 + 36 − 81) : 60 = −20 : 60 ≈ −0,3333.
γ = cos⁻¹(−1/3) ≈ 109,5°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit c² = a² + b² + 2ab · cos γ umgestellt: cos γ = 20 : 60.","socratic_question":"Welches Rechenzeichen steht vor 2ab · cos γ?"},{"error":"Den Winkel α gegenüber der kürzesten Seite berechnet.","socratic_question":"Welcher Seite liegt der größte Winkel gegenüber?"},{"error":"Den Kosinuswert als Winkel angegeben.","socratic_question":"Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"109,5","equivalents":["109.5","109,5 °","109,5°"],"known_errors":{"70,5":"kosinussatz_vorzeichen","70.5":"kosinussatz_vorzeichen","70,5 °":"kosinussatz_vorzeichen","70,5°":"kosinussatz_vorzeichen","31,6":"falsche_groesse_beantwortet","31.6":"falsche_groesse_beantwortet","31,6 °":"falsche_groesse_beantwortet","31,6°":"falsche_groesse_beantwortet","-0,3":"umkehrfunktion_vergessen","−0,3":"umkehrfunktion_vergessen","- 0,3":"umkehrfunktion_vergessen","-0.3":"umkehrfunktion_vergessen","−0.3":"umkehrfunktion_vergessen","- 0.3":"umkehrfunktion_vergessen","-0,3 °":"umkehrfunktion_vergessen","-0,3°":"umkehrfunktion_vergessen"}}'::jsonb);
  end if;
end
$loesung$;
