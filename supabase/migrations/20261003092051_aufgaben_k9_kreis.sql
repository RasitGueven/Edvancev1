-- K9 Kreis, Migration 2 von 2 — 24 Aufgaben: je sechs zu geo_kreis_umfang, _flaeche, _rueck und _sektor.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-kreis.json (Quelle: tools/k9-kreis-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach <...>_substrat_k9_kreis.sql (Knoten + Fehlbild-Slugs muessen stehen).
-- geo_kreis_zusammen bekommt hier KEINE Aufgaben (Abbildungen; Generator specs/active/figur-kreis.md fehlt).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Fahrradrad, Pizza, Baumstamm, runder Tisch, Torte, Winkel aus dem Bogen). Alle ohne Abbildung lösbar. Jede Aufgabe nennt π-Taste oder 3,14 und die Rundung; beide Ergebnisse stehen als Varianten in correct_answers und acceptance.equivalents (exakter Textvergleich, keine Toleranz).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-kreis.csv. Pruefprotokoll: docs/prefill/k9-kreis-verifikation.md.
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
--   geo_kreis_umfang: kreis-umfang-03 = 1, kreis-umfang-04 = 2. Rang 1 aus Profil {flaeche_statt_umfang,pi_vergessen,radius_durchmesser_verwechselt}, Rang 2 aus Profil {einheit_uebersprungen,pi_vergessen,radius_durchmesser_verwechselt} (1 neue Fehlbilder)
--   geo_kreis_flaeche: kreis-flaeche-04 = 1, kreis-flaeche-06 = 2. Rang 1 aus Profil {einheit_uebersprungen,linearer_faktor,pi_vergessen,umfang_statt_flaeche}, Rang 2 aus Profil {falsche_groesse_beantwortet,pi_vergessen,radius_durchmesser_verwechselt} (2 neue Fehlbilder)
--   geo_kreis_rueck: kreis-rueck-06 = 1, kreis-rueck-03 = 2. Rang 1 aus Profil {abgeschnitten,bedingung_unvollstaendig,pi_vergessen,radius_durchmesser_verwechselt}, Rang 2 aus Profil {einheit_uebersprungen,pi_vergessen,radius_durchmesser_verwechselt} (1 neue Fehlbilder)
--   geo_kreis_sektor: kreis-sektor-05 = 1, kreis-sektor-03 = 2. Rang 1 aus Profil {kreisanteil_falsch,pi_vergessen,radius_durchmesser_verwechselt,zu_frueh_gerundet}, Rang 2 aus Profil {flaeche_statt_umfang,kreisanteil_falsch,pi_vergessen,zu_frueh_gerundet} (1 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne --single-transaction, und
-- eine Aufgabe ohne Loesung waere still kaputt.

begin;

select set_config('request.jwt.claim.role', 'service_role', true);

-- #1 kreis-umfang-01 · Umfang · Radius 4 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7723a47c-0524-45d7-89f7-42d2e0e85d00'::uuid, 'exercise', 'Umfang · Radius 4 cm', 'Ein Kreis hat den Radius 4 cm.

Wie groß ist sein Umfang? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 4 cm.\n\nWie groß ist sein Umfang? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-umfang-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Umfangsformel mit gegebenem Radius, ein Schritt.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, flaeche_statt_umfang).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '7723a47c-0524-45d7-89f7-42d2e0e85d00'::uuid,
  p_correct_answers => '["25,13","25.13","25,13 cm","25,13cm","25,12","25.12","25,12 cm","25,12cm"]'::jsonb,
  p_solution        => 'U = 2 · π · r = 2 · π · 4 cm ≈ 25,13 cm (π-Taste).
Mit π ≈ 3,14: U = 2 · 3,14 · 4 cm = 25,12 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Radius wie einen Durchmesser eingesetzt: π · 4.","socratic_question":"Ist 4 cm der Abstand vom Mittelpunkt zum Rand oder einmal ganz durch den Kreis?"},{"error":"π weggelassen: 2 · 4 = 8.","socratic_question":"Welche Zahl gehört in jede Formel am Kreis?"},{"error":"Mit der Flächenformel gerechnet: π · 4².","socratic_question":"Ist nach der Länge der Randlinie oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"25,13","equivalents":["25.13","25,13 cm","25,13cm","25,12","25.12","25,12 cm","25,12cm"],"known_errors":{"8":"pi_vergessen","12,57":"radius_durchmesser_verwechselt","12.57":"radius_durchmesser_verwechselt","12,57 cm":"radius_durchmesser_verwechselt","12,57cm":"radius_durchmesser_verwechselt","12,56":"radius_durchmesser_verwechselt","12.56":"radius_durchmesser_verwechselt","12,56 cm":"radius_durchmesser_verwechselt","12,56cm":"radius_durchmesser_verwechselt","8,00":"pi_vergessen","8.00":"pi_vergessen","8,00 cm":"pi_vergessen","8,00cm":"pi_vergessen","8 cm":"pi_vergessen","8cm":"pi_vergessen","50,27":"flaeche_statt_umfang","50.27":"flaeche_statt_umfang","50,27 cm":"flaeche_statt_umfang","50,27cm":"flaeche_statt_umfang","50,24":"flaeche_statt_umfang","50.24":"flaeche_statt_umfang","50,24 cm":"flaeche_statt_umfang","50,24cm":"flaeche_statt_umfang"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '7723a47c-0524-45d7-89f7-42d2e0e85d00'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7723a47c-0524-45d7-89f7-42d2e0e85d00'::uuid);

-- #2 kreis-umfang-02 · Umfang · Durchmesser 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '322960fb-0bfb-4396-b59b-75fd21a23652'::uuid, 'exercise', 'Umfang · Durchmesser 10 cm', 'Ein Kreis hat den Durchmesser 10 cm.

Wie groß ist sein Umfang? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Durchmesser 10 cm.\n\nWie groß ist sein Umfang? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-umfang-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Umfang aus dem Durchmesser, ein Schritt.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, flaeche_statt_umfang).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '322960fb-0bfb-4396-b59b-75fd21a23652'::uuid,
  p_correct_answers => '["31,42","31.42","31,42 cm","31,42cm","31,40","31.40","31,4","31.4","31,40 cm","31,40cm","31,4 cm","31,4cm"]'::jsonb,
  p_solution        => 'U = π · d = π · 10 cm ≈ 31,42 cm (π-Taste).
Mit π ≈ 3,14: U = 3,14 · 10 cm = 31,40 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: 2 · π · 10.","socratic_question":"Ist 10 cm der Radius oder der Durchmesser?"},{"error":"π weggelassen: Umfang = Durchmesser.","socratic_question":"Ist der Rand eines Kreises wirklich so lang wie sein Durchmesser?"},{"error":"Mit der Flächenformel gerechnet: π · 5².","socratic_question":"Ist nach der Randlinie oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"31,42","equivalents":["31.42","31,42 cm","31,42cm","31,40","31.40","31,4","31.4","31,40 cm","31,40cm","31,4 cm","31,4cm"],"known_errors":{"10":"pi_vergessen","62,83":"radius_durchmesser_verwechselt","62.83":"radius_durchmesser_verwechselt","62,83 cm":"radius_durchmesser_verwechselt","62,83cm":"radius_durchmesser_verwechselt","62,80":"radius_durchmesser_verwechselt","62.80":"radius_durchmesser_verwechselt","62,8":"radius_durchmesser_verwechselt","62.8":"radius_durchmesser_verwechselt","62,80 cm":"radius_durchmesser_verwechselt","62,80cm":"radius_durchmesser_verwechselt","62,8 cm":"radius_durchmesser_verwechselt","62,8cm":"radius_durchmesser_verwechselt","10,00":"pi_vergessen","10.00":"pi_vergessen","10,00 cm":"pi_vergessen","10,00cm":"pi_vergessen","10 cm":"pi_vergessen","10cm":"pi_vergessen","78,54":"flaeche_statt_umfang","78.54":"flaeche_statt_umfang","78,54 cm":"flaeche_statt_umfang","78,54cm":"flaeche_statt_umfang","78,50":"flaeche_statt_umfang","78.50":"flaeche_statt_umfang","78,5":"flaeche_statt_umfang","78.5":"flaeche_statt_umfang","78,50 cm":"flaeche_statt_umfang","78,50cm":"flaeche_statt_umfang","78,5 cm":"flaeche_statt_umfang","78,5cm":"flaeche_statt_umfang"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '322960fb-0bfb-4396-b59b-75fd21a23652'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '322960fb-0bfb-4396-b59b-75fd21a23652'::uuid);

-- #3 kreis-umfang-03 · Umfang · Radius 3,6 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8e3e60dc-01bc-4a59-ae8e-65c20321deea'::uuid, 'exercise', 'Umfang · Radius 3,6 m', 'Ein Kreis hat den Radius 3,6 m.

Wie groß ist sein Umfang in Metern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 3,6 m.\n\nWie groß ist sein Umfang in Metern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm', false, 1, 'draft', 'edvance_k9_kreis', 'kreis-umfang-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Dezimalradius, Ergebnis nicht im Kopf überschlagbar.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, flaeche_statt_umfang).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '8e3e60dc-01bc-4a59-ae8e-65c20321deea'::uuid,
  p_correct_answers => '["22,62","22.62","22,62 m","22,62m","22,61","22.61","22,61 m","22,61m"]'::jsonb,
  p_solution        => 'U = 2 · π · 3,6 m ≈ 22,62 m (π-Taste).
Mit π ≈ 3,14: U = 2 · 3,14 · 3,6 m ≈ 22,61 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Radius wie einen Durchmesser eingesetzt: π · 3,6.","socratic_question":"Wie viele Radien passen in einen Durchmesser?"},{"error":"π weggelassen: 2 · 3,6 = 7,2.","socratic_question":"Welcher Faktor fehlt in deiner Rechnung?"},{"error":"Mit der Flächenformel gerechnet: π · 3,6².","socratic_question":"Kommt bei deiner Formel eine Länge oder eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"22,62","equivalents":["22.62","22,62 m","22,62m","22,61","22.61","22,61 m","22,61m"],"known_errors":{"11,31":"radius_durchmesser_verwechselt","11.31":"radius_durchmesser_verwechselt","11,31 m":"radius_durchmesser_verwechselt","11,31m":"radius_durchmesser_verwechselt","11,30":"radius_durchmesser_verwechselt","11.30":"radius_durchmesser_verwechselt","11,3":"radius_durchmesser_verwechselt","11.3":"radius_durchmesser_verwechselt","11,30 m":"radius_durchmesser_verwechselt","11,30m":"radius_durchmesser_verwechselt","11,3 m":"radius_durchmesser_verwechselt","11,3m":"radius_durchmesser_verwechselt","7,20":"pi_vergessen","7.20":"pi_vergessen","7,2":"pi_vergessen","7.2":"pi_vergessen","7,20 m":"pi_vergessen","7,20m":"pi_vergessen","7,2 m":"pi_vergessen","7,2m":"pi_vergessen","40,72":"flaeche_statt_umfang","40.72":"flaeche_statt_umfang","40,72 m":"flaeche_statt_umfang","40,72m":"flaeche_statt_umfang","40,69":"flaeche_statt_umfang","40.69":"flaeche_statt_umfang","40,69 m":"flaeche_statt_umfang","40,69m":"flaeche_statt_umfang"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '8e3e60dc-01bc-4a59-ae8e-65c20321deea'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8e3e60dc-01bc-4a59-ae8e-65c20321deea'::uuid);

-- #4 kreis-umfang-04 · Umfang · Radius 45 cm, Ergebnis in Metern
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'eabc5d92-2564-456e-9296-c60d17809021'::uuid, 'exercise', 'Umfang · Radius 45 cm, Ergebnis in Metern', 'Ein Kreis hat den Radius 45 cm.

Wie groß ist sein Umfang in Metern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 45 cm.\n\nWie groß ist sein Umfang in Metern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm', false, 2, 'draft', 'edvance_k9_kreis', 'kreis-umfang-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Umfang plus Umrechnung von Zentimetern in Meter.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'eabc5d92-2564-456e-9296-c60d17809021'::uuid,
  p_correct_answers => '["2,83","2.83","2,83 m","2,83m"]'::jsonb,
  p_solution        => 'r = 45 cm = 0,45 m.
U = 2 · π · 0,45 m ≈ 2,83 m (π-Taste).
Mit π ≈ 3,14: U = 2 · 3,14 · 0,45 m ≈ 2,83 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht in Meter umgerechnet: der Umfang in Zentimetern.","socratic_question":"In welcher Einheit ist das Ergebnis gefragt?"},{"error":"Den Radius wie einen Durchmesser eingesetzt: π · 0,45.","socratic_question":"Ist 45 cm der Radius oder der Durchmesser?"},{"error":"π weggelassen: 2 · 0,45 = 0,9.","socratic_question":"Welche Zahl fehlt in der Umfangsformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,83","equivalents":["2.83","2,83 m","2,83m"],"known_errors":{"282,74":"einheit_uebersprungen","282.74":"einheit_uebersprungen","282,74 m":"einheit_uebersprungen","282,74m":"einheit_uebersprungen","282,60":"einheit_uebersprungen","282.60":"einheit_uebersprungen","282,6":"einheit_uebersprungen","282.6":"einheit_uebersprungen","282,60 m":"einheit_uebersprungen","282,60m":"einheit_uebersprungen","282,6 m":"einheit_uebersprungen","282,6m":"einheit_uebersprungen","1,41":"radius_durchmesser_verwechselt","1.41":"radius_durchmesser_verwechselt","1,41 m":"radius_durchmesser_verwechselt","1,41m":"radius_durchmesser_verwechselt","0,90":"pi_vergessen","0.90":"pi_vergessen","0,9":"pi_vergessen","0.9":"pi_vergessen","0,90 m":"pi_vergessen","0,90m":"pi_vergessen","0,9 m":"pi_vergessen","0,9m":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'eabc5d92-2564-456e-9296-c60d17809021'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'eabc5d92-2564-456e-9296-c60d17809021'::uuid);

-- #5 kreis-umfang-05 · Umfang · Fahrradrad mit 70 cm Durchmesser
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2ffd9c4c-46cf-4a66-a843-f5df51941807'::uuid, 'exercise', 'Umfang · Fahrradrad mit 70 cm Durchmesser', 'Ein Fahrradrad hat einen Durchmesser von 70 cm.

Wie viele Zentimeter legt das Rad bei einer vollen Umdrehung zurück? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Fahrradrad hat einen Durchmesser von 70 cm.\n\nWie viele Zentimeter legt das Rad bei einer vollen Umdrehung zurück? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-umfang-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Eine Radumdrehung muss als Umfang erkannt werden.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Kreisformel übersetzen, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, flaeche_statt_umfang).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '2ffd9c4c-46cf-4a66-a843-f5df51941807'::uuid,
  p_correct_answers => '["219,91","219.91","219,91 cm","219,91cm","219,80","219.80","219,8","219.8","219,80 cm","219,80cm","219,8 cm","219,8cm"]'::jsonb,
  p_solution        => 'Bei einer Umdrehung rollt der ganze Rand einmal ab: Weg = Umfang.
U = π · 70 cm ≈ 219,91 cm (π-Taste).
Mit π ≈ 3,14: U = 3,14 · 70 cm = 219,80 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: 2 · π · 70.","socratic_question":"Sind 70 cm der Radius oder der Durchmesser des Rades?"},{"error":"π weggelassen: Weg = Durchmesser.","socratic_question":"Rollt das Rad bei einer Umdrehung nur so weit, wie es hoch ist?"},{"error":"Die Fläche des Rades berechnet statt seines Umfangs.","socratic_question":"Ist ein zurückgelegter Weg eine Länge oder eine Fläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"219,91","equivalents":["219.91","219,91 cm","219,91cm","219,80","219.80","219,8","219.8","219,80 cm","219,80cm","219,8 cm","219,8cm"],"known_errors":{"70":"pi_vergessen","439,82":"radius_durchmesser_verwechselt","439.82":"radius_durchmesser_verwechselt","439,82 cm":"radius_durchmesser_verwechselt","439,82cm":"radius_durchmesser_verwechselt","439,60":"radius_durchmesser_verwechselt","439.60":"radius_durchmesser_verwechselt","439,6":"radius_durchmesser_verwechselt","439.6":"radius_durchmesser_verwechselt","439,60 cm":"radius_durchmesser_verwechselt","439,60cm":"radius_durchmesser_verwechselt","439,6 cm":"radius_durchmesser_verwechselt","439,6cm":"radius_durchmesser_verwechselt","70,00":"pi_vergessen","70.00":"pi_vergessen","70,00 cm":"pi_vergessen","70,00cm":"pi_vergessen","70 cm":"pi_vergessen","70cm":"pi_vergessen","3848,45":"flaeche_statt_umfang","3848.45":"flaeche_statt_umfang","3848,45 cm":"flaeche_statt_umfang","3848,45cm":"flaeche_statt_umfang","3846,50":"flaeche_statt_umfang","3846.50":"flaeche_statt_umfang","3846,5":"flaeche_statt_umfang","3846.5":"flaeche_statt_umfang","3846,50 cm":"flaeche_statt_umfang","3846,50cm":"flaeche_statt_umfang","3846,5 cm":"flaeche_statt_umfang","3846,5cm":"flaeche_statt_umfang"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '2ffd9c4c-46cf-4a66-a843-f5df51941807'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2ffd9c4c-46cf-4a66-a843-f5df51941807'::uuid);

-- #6 kreis-umfang-06 · Umfang · Umdrehungen für 100 m bei 60 cm Durchmesser
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e8a7a4ff-bdbc-49a5-afd8-709da6edc93a'::uuid, 'exercise', 'Umfang · Umdrehungen für 100 m bei 60 cm Durchmesser', 'Ein Rad hat einen Durchmesser von 60 cm. Es soll eine Strecke von 100 m zurücklegen.

Wie viele volle Umdrehungen muss das Rad mindestens machen? Gib eine ganze Zahl an und runde dafür auf. Rechne mit der π-Taste oder mit π ≈ 3,14.',
  '{"kind":"short_input","prompt":"Ein Rad hat einen Durchmesser von 60 cm. Es soll eine Strecke von 100 m zurücklegen.\n\nWie viele volle Umdrehungen muss das Rad mindestens machen? Gib eine ganze Zahl an und runde dafür auf. Rechne mit der π-Taste oder mit π ≈ 3,14."}'::jsonb, 'NUMERIC', 'geo_kreis_umfang',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'Umdrehungen', false, null, 'draft', 'edvance_k9_kreis', 'kreis-umfang-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Strecke durch Umfang teilen, Einheiten angleichen und sinnvoll aufrunden.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e8a7a4ff-bdbc-49a5-afd8-709da6edc93a'::uuid,
  p_correct_answers => '["54","54 Umdrehungen","54Umdrehungen"]'::jsonb,
  p_solution        => 'U = π · 60 cm ≈ 188,50 cm (mit 3,14: 188,40 cm).
100 m = 10 000 cm.
10 000 cm : 188,50 cm ≈ 53,05 (mit 3,14: ≈ 53,08).
Nach 53 Umdrehungen fehlt noch ein Stück, also mindestens 54 Umdrehungen.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgerundet: 53 Umdrehungen reichen noch nicht ganz.","socratic_question":"Kommt das Rad nach 53 Umdrehungen schon ganz bis 100 m?"},{"error":"Den Durchmesser als Radius eingesetzt: Umfang doppelt so groß.","socratic_question":"Sind 60 cm der Radius oder der Durchmesser?"},{"error":"π weggelassen: durch den Durchmesser statt durch den Umfang geteilt.","socratic_question":"Wie weit kommt das Rad bei einer Umdrehung?"}]'::jsonb,
  p_acceptance      => '{"canonical":"54","equivalents":["54 Umdrehungen","54Umdrehungen"],"known_errors":{"27":"radius_durchmesser_verwechselt","53":"abgeschnitten","167":"pi_vergessen","53 Umdrehungen":"abgeschnitten","53Umdrehungen":"abgeschnitten","27 Umdrehungen":"radius_durchmesser_verwechselt","27Umdrehungen":"radius_durchmesser_verwechselt","167 Umdrehungen":"pi_vergessen","167Umdrehungen":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e8a7a4ff-bdbc-49a5-afd8-709da6edc93a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e8a7a4ff-bdbc-49a5-afd8-709da6edc93a'::uuid);

-- #7 kreis-flaeche-01 · Fläche · Radius 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8e606b89-1825-4147-9f71-871d36199218'::uuid, 'exercise', 'Fläche · Radius 6 cm', 'Ein Kreis hat den Radius 6 cm.

Wie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 6 cm.\n\nWie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Flächenformel mit gegebenem Radius.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umfang_statt_flaeche, pi_vergessen, radius_durchmesser_verwechselt).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '8e606b89-1825-4147-9f71-871d36199218'::uuid,
  p_correct_answers => '["113,10","113.10","113,1","113.1","113,10 cm²","113,10cm²","113,1 cm²","113,1cm²","113,04","113.04","113,04 cm²","113,04cm²"]'::jsonb,
  p_solution        => 'A = π · r² = π · (6 cm)² = π · 36 cm² ≈ 113,10 cm² (π-Taste).
Mit π ≈ 3,14: A = 3,14 · 36 cm² = 113,04 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Umfang berechnet (oder r² als 2 · r): 2 · π · 6.","socratic_question":"Was bedeutet das Hoch-Zwei bei r²?"},{"error":"π weggelassen: 6² = 36.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"},{"error":"Den Radius wie einen Durchmesser halbiert: π · 3².","socratic_question":"Ist 6 cm schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"113,10","equivalents":["113.10","113,1","113.1","113,10 cm²","113,10cm²","113,1 cm²","113,1cm²","113,04","113.04","113,04 cm²","113,04cm²"],"known_errors":{"36":"pi_vergessen","37,70":"umfang_statt_flaeche","37.70":"umfang_statt_flaeche","37,7":"umfang_statt_flaeche","37.7":"umfang_statt_flaeche","37,70 cm²":"umfang_statt_flaeche","37,70cm²":"umfang_statt_flaeche","37,7 cm²":"umfang_statt_flaeche","37,7cm²":"umfang_statt_flaeche","37,68":"umfang_statt_flaeche","37.68":"umfang_statt_flaeche","37,68 cm²":"umfang_statt_flaeche","37,68cm²":"umfang_statt_flaeche","36,00":"pi_vergessen","36.00":"pi_vergessen","36,00 cm²":"pi_vergessen","36,00cm²":"pi_vergessen","36 cm²":"pi_vergessen","36cm²":"pi_vergessen","28,27":"radius_durchmesser_verwechselt","28.27":"radius_durchmesser_verwechselt","28,27 cm²":"radius_durchmesser_verwechselt","28,27cm²":"radius_durchmesser_verwechselt","28,26":"radius_durchmesser_verwechselt","28.26":"radius_durchmesser_verwechselt","28,26 cm²":"radius_durchmesser_verwechselt","28,26cm²":"radius_durchmesser_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '8e606b89-1825-4147-9f71-871d36199218'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8e606b89-1825-4147-9f71-871d36199218'::uuid);

-- #8 kreis-flaeche-02 · Fläche · Durchmesser 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1338a319-aa9f-4b2e-8deb-d1b21393a798'::uuid, 'exercise', 'Fläche · Durchmesser 10 cm', 'Ein Kreis hat den Durchmesser 10 cm.

Wie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Durchmesser 10 cm.\n\nWie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Radius aus dem Durchmesser, dann Flächenformel.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, umfang_statt_flaeche).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '1338a319-aa9f-4b2e-8deb-d1b21393a798'::uuid,
  p_correct_answers => '["78,54","78.54","78,54 cm²","78,54cm²","78,50","78.50","78,5","78.5","78,50 cm²","78,50cm²","78,5 cm²","78,5cm²"]'::jsonb,
  p_solution        => 'r = 10 cm : 2 = 5 cm.
A = π · (5 cm)² = π · 25 cm² ≈ 78,54 cm² (π-Taste).
Mit π ≈ 3,14: A = 3,14 · 25 cm² = 78,50 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: π · 10².","socratic_question":"Ist 10 cm der Radius oder der Durchmesser?"},{"error":"π weggelassen: 5² = 25.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"},{"error":"Den Umfang berechnet: π · 10.","socratic_question":"Kommt bei π · d eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"78,54","equivalents":["78.54","78,54 cm²","78,54cm²","78,50","78.50","78,5","78.5","78,50 cm²","78,50cm²","78,5 cm²","78,5cm²"],"known_errors":{"25":"pi_vergessen","314":"radius_durchmesser_verwechselt","314,16":"radius_durchmesser_verwechselt","314.16":"radius_durchmesser_verwechselt","314,16 cm²":"radius_durchmesser_verwechselt","314,16cm²":"radius_durchmesser_verwechselt","314,00":"radius_durchmesser_verwechselt","314.00":"radius_durchmesser_verwechselt","314,00 cm²":"radius_durchmesser_verwechselt","314,00cm²":"radius_durchmesser_verwechselt","314 cm²":"radius_durchmesser_verwechselt","314cm²":"radius_durchmesser_verwechselt","25,00":"pi_vergessen","25.00":"pi_vergessen","25,00 cm²":"pi_vergessen","25,00cm²":"pi_vergessen","25 cm²":"pi_vergessen","25cm²":"pi_vergessen","31,42":"umfang_statt_flaeche","31.42":"umfang_statt_flaeche","31,42 cm²":"umfang_statt_flaeche","31,42cm²":"umfang_statt_flaeche","31,40":"umfang_statt_flaeche","31.40":"umfang_statt_flaeche","31,4":"umfang_statt_flaeche","31.4":"umfang_statt_flaeche","31,40 cm²":"umfang_statt_flaeche","31,40cm²":"umfang_statt_flaeche","31,4 cm²":"umfang_statt_flaeche","31,4cm²":"umfang_statt_flaeche"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '1338a319-aa9f-4b2e-8deb-d1b21393a798'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1338a319-aa9f-4b2e-8deb-d1b21393a798'::uuid);

-- #9 kreis-flaeche-03 · Fläche · Radius 2,4 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7223ee1a-3043-487e-850c-e9da8501d935'::uuid, 'exercise', 'Fläche · Radius 2,4 m', 'Ein Kreis hat den Radius 2,4 m.

Wie groß ist sein Flächeninhalt in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 2,4 m.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat einer Dezimalzahl in der Flächenformel.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umfang_statt_flaeche, pi_vergessen, radius_durchmesser_verwechselt).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '7223ee1a-3043-487e-850c-e9da8501d935'::uuid,
  p_correct_answers => '["18,10","18.10","18,1","18.1","18,10 m²","18,10m²","18,1 m²","18,1m²","18,09","18.09","18,09 m²","18,09m²"]'::jsonb,
  p_solution        => 'A = π · (2,4 m)² = π · 5,76 m² ≈ 18,10 m² (π-Taste).
Mit π ≈ 3,14: A = 3,14 · 5,76 m² ≈ 18,09 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Umfang berechnet (oder 2,4² als 2 · 2,4): 2 · π · 2,4.","socratic_question":"Was ist 2,4² – 2,4 · 2 oder 2,4 · 2,4?"},{"error":"π weggelassen: 2,4² = 5,76.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"},{"error":"Den Radius wie einen Durchmesser halbiert: π · 1,2².","socratic_question":"Ist 2,4 m schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"18,10","equivalents":["18.10","18,1","18.1","18,10 m²","18,10m²","18,1 m²","18,1m²","18,09","18.09","18,09 m²","18,09m²"],"known_errors":{"15,08":"umfang_statt_flaeche","15.08":"umfang_statt_flaeche","15,08 m²":"umfang_statt_flaeche","15,08m²":"umfang_statt_flaeche","15,07":"umfang_statt_flaeche","15.07":"umfang_statt_flaeche","15,07 m²":"umfang_statt_flaeche","15,07m²":"umfang_statt_flaeche","5,76":"pi_vergessen","5.76":"pi_vergessen","5,76 m²":"pi_vergessen","5,76m²":"pi_vergessen","4,52":"radius_durchmesser_verwechselt","4.52":"radius_durchmesser_verwechselt","4,52 m²":"radius_durchmesser_verwechselt","4,52m²":"radius_durchmesser_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '7223ee1a-3043-487e-850c-e9da8501d935'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7223ee1a-3043-487e-850c-e9da8501d935'::uuid);

-- #10 kreis-flaeche-04 · Fläche · Radius 80 cm, Ergebnis in m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e0cfc702-9b40-450e-b530-1b6bb53976a8'::uuid, 'exercise', 'Fläche · Radius 80 cm, Ergebnis in m²', 'Ein Kreis hat den Radius 80 cm.

Wie groß ist sein Flächeninhalt in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 80 cm.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm²', false, 1, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Flächenformel plus Umrechnung in eine Flächeneinheit.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, linearer_faktor, pi_vergessen, umfang_statt_flaeche).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e0cfc702-9b40-450e-b530-1b6bb53976a8'::uuid,
  p_correct_answers => '["2,01","2.01","2,01 m²","2,01m²"]'::jsonb,
  p_solution        => 'r = 80 cm = 0,8 m.
A = π · (0,8 m)² = π · 0,64 m² ≈ 2,01 m² (π-Taste).
Mit π ≈ 3,14: A = 3,14 · 0,64 m² ≈ 2,01 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht umgerechnet: die Fläche in Quadratzentimetern.","socratic_question":"In welcher Einheit ist das Ergebnis gefragt?"},{"error":"Mit 100 statt mit 10 000 umgerechnet.","socratic_question":"Wie viele Quadratzentimeter hat ein Quadratmeter?"},{"error":"π weggelassen: 0,8² = 0,64.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"},{"error":"Den Umfang berechnet: 2 · π · 0,8.","socratic_question":"Kommt bei deiner Formel eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,01","equivalents":["2.01","2,01 m²","2,01m²"],"known_errors":{"20096":"einheit_uebersprungen","20106,19":"einheit_uebersprungen","20106.19":"einheit_uebersprungen","20106,19 m²":"einheit_uebersprungen","20106,19m²":"einheit_uebersprungen","20096,00":"einheit_uebersprungen","20096.00":"einheit_uebersprungen","20096,00 m²":"einheit_uebersprungen","20096,00m²":"einheit_uebersprungen","20096 m²":"einheit_uebersprungen","20096m²":"einheit_uebersprungen","201,06":"linearer_faktor","201.06":"linearer_faktor","201,06 m²":"linearer_faktor","201,06m²":"linearer_faktor","200,96":"linearer_faktor","200.96":"linearer_faktor","200,96 m²":"linearer_faktor","200,96m²":"linearer_faktor","0,64":"pi_vergessen","0.64":"pi_vergessen","0,64 m²":"pi_vergessen","0,64m²":"pi_vergessen","5,03":"umfang_statt_flaeche","5.03":"umfang_statt_flaeche","5,03 m²":"umfang_statt_flaeche","5,03m²":"umfang_statt_flaeche","5,02":"umfang_statt_flaeche","5.02":"umfang_statt_flaeche","5,02 m²":"umfang_statt_flaeche","5,02m²":"umfang_statt_flaeche"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e0cfc702-9b40-450e-b530-1b6bb53976a8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e0cfc702-9b40-450e-b530-1b6bb53976a8'::uuid);

-- #11 kreis-flaeche-05 · Fläche · Pizza mit 30 cm Durchmesser
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6f8c3f6a-68ad-4be5-9e1e-9a85259d2ecd'::uuid, 'exercise', 'Fläche · Pizza mit 30 cm Durchmesser', 'Eine runde Pizza hat einen Durchmesser von 30 cm.

Wie viele Quadratzentimeter ist die Pizza groß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine runde Pizza hat einen Durchmesser von 30 cm.\n\nWie viele Quadratzentimeter ist die Pizza groß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Der Durchmesser muss als solcher erkannt und halbiert werden.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Kreisformel übersetzen, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, umfang_statt_flaeche, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '6f8c3f6a-68ad-4be5-9e1e-9a85259d2ecd'::uuid,
  p_correct_answers => '["706,86","706.86","706,86 cm²","706,86cm²","706,50","706.50","706,5","706.5","706,50 cm²","706,50cm²","706,5 cm²","706,5cm²"]'::jsonb,
  p_solution        => 'r = 30 cm : 2 = 15 cm.
A = π · (15 cm)² = π · 225 cm² ≈ 706,86 cm² (π-Taste).
Mit π ≈ 3,14: A = 3,14 · 225 cm² = 706,50 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: π · 30².","socratic_question":"Sind 30 cm der Radius oder der Durchmesser der Pizza?"},{"error":"Den Rand der Pizza berechnet statt ihrer Fläche.","socratic_question":"Wird nach dem Rand oder nach der ganzen Pizza gefragt?"},{"error":"π weggelassen: 15² = 225.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"706,86","equivalents":["706.86","706,86 cm²","706,86cm²","706,50","706.50","706,5","706.5","706,50 cm²","706,50cm²","706,5 cm²","706,5cm²"],"known_errors":{"225":"pi_vergessen","2826":"radius_durchmesser_verwechselt","2827,43":"radius_durchmesser_verwechselt","2827.43":"radius_durchmesser_verwechselt","2827,43 cm²":"radius_durchmesser_verwechselt","2827,43cm²":"radius_durchmesser_verwechselt","2826,00":"radius_durchmesser_verwechselt","2826.00":"radius_durchmesser_verwechselt","2826,00 cm²":"radius_durchmesser_verwechselt","2826,00cm²":"radius_durchmesser_verwechselt","2826 cm²":"radius_durchmesser_verwechselt","2826cm²":"radius_durchmesser_verwechselt","94,25":"umfang_statt_flaeche","94.25":"umfang_statt_flaeche","94,25 cm²":"umfang_statt_flaeche","94,25cm²":"umfang_statt_flaeche","94,20":"umfang_statt_flaeche","94.20":"umfang_statt_flaeche","94,2":"umfang_statt_flaeche","94.2":"umfang_statt_flaeche","94,20 cm²":"umfang_statt_flaeche","94,20cm²":"umfang_statt_flaeche","94,2 cm²":"umfang_statt_flaeche","94,2cm²":"umfang_statt_flaeche","225,00":"pi_vergessen","225.00":"pi_vergessen","225,00 cm²":"pi_vergessen","225,00cm²":"pi_vergessen","225 cm²":"pi_vergessen","225cm²":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '6f8c3f6a-68ad-4be5-9e1e-9a85259d2ecd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6f8c3f6a-68ad-4be5-9e1e-9a85259d2ecd'::uuid);

-- #12 kreis-flaeche-06 · Fläche · eine große Pizza gegen zwei kleine
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9ef4de2a-1a55-49a3-ac80-2a03594006b8'::uuid, 'exercise', 'Fläche · eine große Pizza gegen zwei kleine', 'Eine große Pizza hat einen Durchmesser von 30 cm. Eine kleine Pizza hat einen Durchmesser von 20 cm.

Um wie viele Quadratzentimeter ist die große Pizza größer als zwei kleine Pizzen zusammen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine große Pizza hat einen Durchmesser von 30 cm. Eine kleine Pizza hat einen Durchmesser von 20 cm.\n\nUm wie viele Quadratzentimeter ist die große Pizza größer als zwei kleine Pizzen zusammen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'cm²', false, 2, 'draft', 'edvance_k9_kreis', 'kreis-flaeche-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: zwei Flächen modellieren, verdoppeln und vergleichen – Rechenweg selbst wählen.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, falsche_groesse_beantwortet, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '9ef4de2a-1a55-49a3-ac80-2a03594006b8'::uuid,
  p_correct_answers => '["78,54","78.54","78,54 cm²","78,54cm²","78,50","78.50","78,5","78.5","78,50 cm²","78,50cm²","78,5 cm²","78,5cm²"]'::jsonb,
  p_solution        => 'Große Pizza: π · (15 cm)² = π · 225 cm².
Zwei kleine: 2 · π · (10 cm)² = π · 200 cm².
Unterschied: π · 25 cm² ≈ 78,54 cm² (π-Taste).
Mit π ≈ 3,14: 706,50 cm² − 628,00 cm² = 78,50 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Durchmesser als Radien eingesetzt.","socratic_question":"Sind 30 cm und 20 cm Radien oder Durchmesser?"},{"error":"Die Fläche der großen Pizza angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel die große Pizza größer ist – was fehlt noch?"},{"error":"π weggelassen: 225 − 200 = 25.","socratic_question":"Welcher Faktor gehört zu jeder Kreisfläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"78,54","equivalents":["78.54","78,54 cm²","78,54cm²","78,50","78.50","78,5","78.5","78,50 cm²","78,50cm²","78,5 cm²","78,5cm²"],"known_errors":{"25":"pi_vergessen","314":"radius_durchmesser_verwechselt","314,16":"radius_durchmesser_verwechselt","314.16":"radius_durchmesser_verwechselt","314,16 cm²":"radius_durchmesser_verwechselt","314,16cm²":"radius_durchmesser_verwechselt","314,00":"radius_durchmesser_verwechselt","314.00":"radius_durchmesser_verwechselt","314,00 cm²":"radius_durchmesser_verwechselt","314,00cm²":"radius_durchmesser_verwechselt","314 cm²":"radius_durchmesser_verwechselt","314cm²":"radius_durchmesser_verwechselt","706,86":"falsche_groesse_beantwortet","706.86":"falsche_groesse_beantwortet","706,86 cm²":"falsche_groesse_beantwortet","706,86cm²":"falsche_groesse_beantwortet","706,50":"falsche_groesse_beantwortet","706.50":"falsche_groesse_beantwortet","706,5":"falsche_groesse_beantwortet","706.5":"falsche_groesse_beantwortet","706,50 cm²":"falsche_groesse_beantwortet","706,50cm²":"falsche_groesse_beantwortet","706,5 cm²":"falsche_groesse_beantwortet","706,5cm²":"falsche_groesse_beantwortet","25,00":"pi_vergessen","25.00":"pi_vergessen","25,00 cm²":"pi_vergessen","25,00cm²":"pi_vergessen","25 cm²":"pi_vergessen","25cm²":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '9ef4de2a-1a55-49a3-ac80-2a03594006b8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9ef4de2a-1a55-49a3-ac80-2a03594006b8'::uuid);

-- #13 kreis-rueck-01 · Rückrichtung · Durchmesser aus 50 cm Umfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd54793cf-fe41-46a5-bc1b-8aa7fd73e44b'::uuid, 'exercise', 'Rückrichtung · Durchmesser aus 50 cm Umfang', 'Ein Kreis hat den Umfang 50 cm.

Wie groß ist sein Durchmesser? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Umfang 50 cm.\n\nWie groß ist sein Durchmesser? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-rueck-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Umfangsformel nach d umstellen, eine Division.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, multipliziert_statt_dividiert, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd54793cf-fe41-46a5-bc1b-8aa7fd73e44b'::uuid,
  p_correct_answers => '["15,92","15.92","15,92 cm","15,92cm"]'::jsonb,
  p_solution        => 'U = π · d, also d = U : π.
d = 50 cm : π ≈ 15,92 cm (π-Taste).
Mit π ≈ 3,14: d = 50 cm : 3,14 ≈ 15,92 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Radius berechnet statt des Durchmessers.","socratic_question":"Ist nach dem Radius oder nach dem Durchmesser gefragt?"},{"error":"Mit π multipliziert statt durch π geteilt.","socratic_question":"Ist der Durchmesser größer oder kleiner als der Umfang?"},{"error":"π weggelassen: Durchmesser = Umfang.","socratic_question":"Kann der Durchmesser so lang sein wie der ganze Rand?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15,92","equivalents":["15.92","15,92 cm","15,92cm"],"known_errors":{"50":"pi_vergessen","157":"multipliziert_statt_dividiert","7,96":"radius_durchmesser_verwechselt","7.96":"radius_durchmesser_verwechselt","7,96 cm":"radius_durchmesser_verwechselt","7,96cm":"radius_durchmesser_verwechselt","157,08":"multipliziert_statt_dividiert","157.08":"multipliziert_statt_dividiert","157,08 cm":"multipliziert_statt_dividiert","157,08cm":"multipliziert_statt_dividiert","157,00":"multipliziert_statt_dividiert","157.00":"multipliziert_statt_dividiert","157,00 cm":"multipliziert_statt_dividiert","157,00cm":"multipliziert_statt_dividiert","157 cm":"multipliziert_statt_dividiert","157cm":"multipliziert_statt_dividiert","50,00":"pi_vergessen","50.00":"pi_vergessen","50,00 cm":"pi_vergessen","50,00cm":"pi_vergessen","50 cm":"pi_vergessen","50cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd54793cf-fe41-46a5-bc1b-8aa7fd73e44b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd54793cf-fe41-46a5-bc1b-8aa7fd73e44b'::uuid);

-- #14 kreis-rueck-02 · Rückrichtung · Radius aus 40 cm Umfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '23fcb661-3095-4ad3-9cfd-d6048893a0c7'::uuid, 'exercise', 'Rückrichtung · Radius aus 40 cm Umfang', 'Ein Kreis hat den Umfang 40 cm.

Wie groß ist sein Radius? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Umfang 40 cm.\n\nWie groß ist sein Radius? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-rueck-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Umfangsformel nach r umstellen.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, multipliziert_statt_dividiert, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '23fcb661-3095-4ad3-9cfd-d6048893a0c7'::uuid,
  p_correct_answers => '["6,37","6.37","6,37 cm","6,37cm"]'::jsonb,
  p_solution        => 'U = 2 · π · r, also r = U : (2 · π).
r = 40 cm : (2 · π) ≈ 6,37 cm (π-Taste).
Mit π ≈ 3,14: r = 40 cm : 6,28 ≈ 6,37 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser berechnet statt des Radius.","socratic_question":"Ist nach dem Radius oder nach dem Durchmesser gefragt?"},{"error":"Mit 2 · π multipliziert statt dadurch geteilt.","socratic_question":"Muss der Radius kleiner oder größer als der Umfang sein?"},{"error":"π weggelassen: 40 : 2 = 20.","socratic_question":"Durch welche Zahl musst du neben der 2 noch teilen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6,37","equivalents":["6.37","6,37 cm","6,37cm"],"known_errors":{"20":"pi_vergessen","12,73":"radius_durchmesser_verwechselt","12.73":"radius_durchmesser_verwechselt","12,73 cm":"radius_durchmesser_verwechselt","12,73cm":"radius_durchmesser_verwechselt","12,74":"radius_durchmesser_verwechselt","12.74":"radius_durchmesser_verwechselt","12,74 cm":"radius_durchmesser_verwechselt","12,74cm":"radius_durchmesser_verwechselt","251,33":"multipliziert_statt_dividiert","251.33":"multipliziert_statt_dividiert","251,33 cm":"multipliziert_statt_dividiert","251,33cm":"multipliziert_statt_dividiert","251,20":"multipliziert_statt_dividiert","251.20":"multipliziert_statt_dividiert","251,2":"multipliziert_statt_dividiert","251.2":"multipliziert_statt_dividiert","251,20 cm":"multipliziert_statt_dividiert","251,20cm":"multipliziert_statt_dividiert","251,2 cm":"multipliziert_statt_dividiert","251,2cm":"multipliziert_statt_dividiert","20,00":"pi_vergessen","20.00":"pi_vergessen","20,00 cm":"pi_vergessen","20,00cm":"pi_vergessen","20 cm":"pi_vergessen","20cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '23fcb661-3095-4ad3-9cfd-d6048893a0c7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '23fcb661-3095-4ad3-9cfd-d6048893a0c7'::uuid);

-- #15 kreis-rueck-03 · Rückrichtung · Durchmesser in cm aus 2 m Umfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b450d36c-e3bf-4cbf-ab4f-3c874a8cbf63'::uuid, 'exercise', 'Rückrichtung · Durchmesser in cm aus 2 m Umfang', 'Ein Kreis hat den Umfang 2 m.

Wie groß ist sein Durchmesser in Zentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Umfang 2 m.\n\nWie groß ist sein Durchmesser in Zentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 2, 'draft', 'edvance_k9_kreis', 'kreis-rueck-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Umstellen und dabei von Metern in Zentimeter umrechnen.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'b450d36c-e3bf-4cbf-ab4f-3c874a8cbf63'::uuid,
  p_correct_answers => '["63,66","63.66","63,66 cm","63,66cm","63,69","63.69","63,69 cm","63,69cm"]'::jsonb,
  p_solution        => 'U = 2 m = 200 cm.
d = 200 cm : π ≈ 63,66 cm (π-Taste).
Mit π ≈ 3,14: d = 200 cm : 3,14 ≈ 63,69 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht in Zentimeter umgerechnet: der Durchmesser in Metern.","socratic_question":"In welcher Einheit ist der Durchmesser gefragt?"},{"error":"Den Radius berechnet statt des Durchmessers.","socratic_question":"Ist nach dem Radius oder nach dem Durchmesser gefragt?"},{"error":"π weggelassen: Durchmesser = Umfang.","socratic_question":"Kann der Durchmesser so lang sein wie der ganze Rand?"}]'::jsonb,
  p_acceptance      => '{"canonical":"63,66","equivalents":["63.66","63,66 cm","63,66cm","63,69","63.69","63,69 cm","63,69cm"],"known_errors":{"200":"pi_vergessen","0,64":"einheit_uebersprungen","0.64":"einheit_uebersprungen","0,64 cm":"einheit_uebersprungen","0,64cm":"einheit_uebersprungen","31,83":"radius_durchmesser_verwechselt","31.83":"radius_durchmesser_verwechselt","31,83 cm":"radius_durchmesser_verwechselt","31,83cm":"radius_durchmesser_verwechselt","31,85":"radius_durchmesser_verwechselt","31.85":"radius_durchmesser_verwechselt","31,85 cm":"radius_durchmesser_verwechselt","31,85cm":"radius_durchmesser_verwechselt","200,00":"pi_vergessen","200.00":"pi_vergessen","200,00 cm":"pi_vergessen","200,00cm":"pi_vergessen","200 cm":"pi_vergessen","200cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'b450d36c-e3bf-4cbf-ab4f-3c874a8cbf63'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b450d36c-e3bf-4cbf-ab4f-3c874a8cbf63'::uuid);

-- #16 kreis-rueck-04 · Rückrichtung · Radius aus 12,5 m Umfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8815c3c7-740c-4037-ae21-1c8a931dfa42'::uuid, 'exercise', 'Rückrichtung · Radius aus 12,5 m Umfang', 'Ein Kreis hat den Umfang 12,5 m.

Wie groß ist sein Radius? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Umfang 12,5 m.\n\nWie groß ist sein Radius? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-rueck-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Dezimalumfang, Division durch 2π, Rundung erst am Ende.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, zu_frueh_gerundet, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '8815c3c7-740c-4037-ae21-1c8a931dfa42'::uuid,
  p_correct_answers => '["1,99","1.99","1,99 m","1,99m"]'::jsonb,
  p_solution        => 'r = U : (2 · π) = 12,5 m : (2 · π) ≈ 1,99 m (π-Taste).
Mit π ≈ 3,14: r = 12,5 m : 6,28 ≈ 1,99 m.
(2 · π nicht vorher auf 6,3 runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser berechnet statt des Radius.","socratic_question":"Ist nach dem Radius oder nach dem Durchmesser gefragt?"},{"error":"2 · π auf 6,3 gerundet und damit weitergerechnet.","socratic_question":"Was passiert mit dem Ergebnis, wenn du 2 · π vor dem Teilen rundest?"},{"error":"π weggelassen: 12,5 : 2 = 6,25.","socratic_question":"Durch welche Zahl musst du neben der 2 noch teilen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,99","equivalents":["1.99","1,99 m","1,99m"],"known_errors":{"3,98":"radius_durchmesser_verwechselt","3.98":"radius_durchmesser_verwechselt","3,98 m":"radius_durchmesser_verwechselt","3,98m":"radius_durchmesser_verwechselt","1,98":"zu_frueh_gerundet","1.98":"zu_frueh_gerundet","1,98 m":"zu_frueh_gerundet","1,98m":"zu_frueh_gerundet","6,25":"pi_vergessen","6.25":"pi_vergessen","6,25 m":"pi_vergessen","6,25m":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '8815c3c7-740c-4037-ae21-1c8a931dfa42'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8815c3c7-740c-4037-ae21-1c8a931dfa42'::uuid);

-- #17 kreis-rueck-05 · Rückrichtung · Baumstamm mit 2,20 m Umfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9794ca24-edb8-4285-b09c-ca20ca1d44da'::uuid, 'exercise', 'Rückrichtung · Baumstamm mit 2,20 m Umfang', 'Um einen runden Baumstamm wird ein Maßband gelegt. Es zeigt 2,20 m.

Wie dick ist der Stamm, also wie groß ist sein Durchmesser in Zentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Um einen runden Baumstamm wird ein Maßband gelegt. Es zeigt 2,20 m.\n\nWie dick ist der Stamm, also wie groß ist sein Durchmesser in Zentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-rueck-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: gemessener Umfang, Durchmesser in anderer Einheit gesucht.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Kreisformel übersetzen, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, einheit_uebersprungen, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '9794ca24-edb8-4285-b09c-ca20ca1d44da'::uuid,
  p_correct_answers => '["70,03","70.03","70,03 cm","70,03cm","70,06","70.06","70,06 cm","70,06cm"]'::jsonb,
  p_solution        => 'Das Maßband misst den Umfang: U = 2,20 m = 220 cm.
d = 220 cm : π ≈ 70,03 cm (π-Taste).
Mit π ≈ 3,14: d = 220 cm : 3,14 ≈ 70,06 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Radius berechnet statt des Durchmessers.","socratic_question":"Ist die Dicke des Stamms der Radius oder der Durchmesser?"},{"error":"Nicht in Zentimeter umgerechnet: der Durchmesser in Metern.","socratic_question":"In welcher Einheit ist die Dicke gefragt?"},{"error":"π weggelassen: Durchmesser = Umfang.","socratic_question":"Kann der Stamm so dick sein, wie das Maßband lang ist?"}]'::jsonb,
  p_acceptance      => '{"canonical":"70,03","equivalents":["70.03","70,03 cm","70,03cm","70,06","70.06","70,06 cm","70,06cm"],"known_errors":{"220":"pi_vergessen","35,01":"radius_durchmesser_verwechselt","35.01":"radius_durchmesser_verwechselt","35,01 cm":"radius_durchmesser_verwechselt","35,01cm":"radius_durchmesser_verwechselt","35,03":"radius_durchmesser_verwechselt","35.03":"radius_durchmesser_verwechselt","35,03 cm":"radius_durchmesser_verwechselt","35,03cm":"radius_durchmesser_verwechselt","0,70":"einheit_uebersprungen","0.70":"einheit_uebersprungen","0,7":"einheit_uebersprungen","0.7":"einheit_uebersprungen","0,70 cm":"einheit_uebersprungen","0,70cm":"einheit_uebersprungen","0,7 cm":"einheit_uebersprungen","0,7cm":"einheit_uebersprungen","220,00":"pi_vergessen","220.00":"pi_vergessen","220,00 cm":"pi_vergessen","220,00cm":"pi_vergessen","220 cm":"pi_vergessen","220cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '9794ca24-edb8-4285-b09c-ca20ca1d44da'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9794ca24-edb8-4285-b09c-ca20ca1d44da'::uuid);

-- #18 kreis-rueck-06 · Rückrichtung · runder Tisch für 8 Personen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cbc04c90-4544-45ca-b0a1-f7d0c2bfd50d'::uuid, 'exercise', 'Rückrichtung · runder Tisch für 8 Personen', 'An einem runden Tisch sollen 8 Personen sitzen. Jede Person braucht am Tischrand 60 cm Platz.

Wie groß muss der Durchmesser des Tisches mindestens sein? Gib ganze Zentimeter an und runde dafür auf. Rechne mit der π-Taste oder mit π ≈ 3,14.',
  '{"kind":"short_input","prompt":"An einem runden Tisch sollen 8 Personen sitzen. Jede Person braucht am Tischrand 60 cm Platz.\n\nWie groß muss der Durchmesser des Tisches mindestens sein? Gib ganze Zentimeter an und runde dafür auf. Rechne mit der π-Taste oder mit π ≈ 3,14."}'::jsonb, 'NUMERIC', 'geo_kreis_rueck',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'cm', false, 1, 'draft', 'edvance_k9_kreis', 'kreis-rueck-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: den nötigen Umfang erst aus der Situation bilden, dann umstellen und sinnvoll aufrunden.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, radius_durchmesser_verwechselt, bedingung_unvollstaendig, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'cbc04c90-4544-45ca-b0a1-f7d0c2bfd50d'::uuid,
  p_correct_answers => '["153","153 cm","153cm"]'::jsonb,
  p_solution        => 'Nötiger Umfang: 8 · 60 cm = 480 cm.
d = 480 cm : π ≈ 152,79 cm (mit 3,14: ≈ 152,87 cm).
Aufgerundet: mindestens 153 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgerundet: Mit 152 cm reicht der Rand nicht ganz.","socratic_question":"Reicht der Rand, wenn du abrundest?"},{"error":"Den Radius berechnet statt des Durchmessers.","socratic_question":"Ist nach dem Radius oder nach dem Durchmesser gefragt?"},{"error":"Nur mit dem Platz für eine Person gerechnet.","socratic_question":"Wie viele Personen sollen am Tisch sitzen?"},{"error":"π weggelassen: Durchmesser = Umfang.","socratic_question":"Kann der Durchmesser so lang sein wie der ganze Rand?"}]'::jsonb,
  p_acceptance      => '{"canonical":"153","equivalents":["153 cm","153cm"],"known_errors":{"20":"bedingung_unvollstaendig","77":"radius_durchmesser_verwechselt","152":"abgeschnitten","480":"pi_vergessen","152 cm":"abgeschnitten","152cm":"abgeschnitten","77 cm":"radius_durchmesser_verwechselt","77cm":"radius_durchmesser_verwechselt","20 cm":"bedingung_unvollstaendig","20cm":"bedingung_unvollstaendig","480 cm":"pi_vergessen","480cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'cbc04c90-4544-45ca-b0a1-f7d0c2bfd50d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cbc04c90-4544-45ca-b0a1-f7d0c2bfd50d'::uuid);

-- #19 kreis-sektor-01 · Kreisbogen · Radius 6 cm, 90°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd6136873-fa24-4c78-841f-1d9408da6053'::uuid, 'exercise', 'Kreisbogen · Radius 6 cm, 90°', 'Ein Kreisausschnitt hat den Radius 6 cm und den Mittelpunktswinkel 90°.

Wie lang ist der Kreisbogen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreisausschnitt hat den Radius 6 cm und den Mittelpunktswinkel 90°.\n\nWie lang ist der Kreisbogen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_kreis', 'kreis-sektor-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Viertel des Umfangs, Anteil direkt erkennbar.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kreisanteil_falsch, flaeche_statt_umfang, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd6136873-fa24-4c78-841f-1d9408da6053'::uuid,
  p_correct_answers => '["9,42","9.42","9,42 cm","9,42cm"]'::jsonb,
  p_solution        => 'Anteil: 90° von 360° = 1/4.
b = 1/4 · 2 · π · 6 cm ≈ 9,42 cm (π-Taste).
Mit π ≈ 3,14: b = 1/4 · 2 · 3,14 · 6 cm ≈ 9,42 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den ganzen Umfang angegeben, der Anteil 90°/360° fehlt.","socratic_question":"Welcher Teil des ganzen Kreises ist der Ausschnitt?"},{"error":"Den Anteil umgedreht: mal 4 statt mal 1/4.","socratic_question":"Ist der Bogen länger oder kürzer als der ganze Umfang?"},{"error":"Die Fläche des Ausschnitts berechnet statt des Bogens.","socratic_question":"Ist eine Länge oder eine Fläche gefragt?"},{"error":"π weggelassen: 1/4 · 2 · 6 = 3.","socratic_question":"Welcher Faktor fehlt in der Umfangsformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9,42","equivalents":["9.42","9,42 cm","9,42cm"],"known_errors":{"3":"pi_vergessen","37,70":"kreisanteil_falsch","37.70":"kreisanteil_falsch","37,7":"kreisanteil_falsch","37.7":"kreisanteil_falsch","37,70 cm":"kreisanteil_falsch","37,70cm":"kreisanteil_falsch","37,7 cm":"kreisanteil_falsch","37,7cm":"kreisanteil_falsch","37,68":"kreisanteil_falsch","37.68":"kreisanteil_falsch","37,68 cm":"kreisanteil_falsch","37,68cm":"kreisanteil_falsch","150,80":"kreisanteil_falsch","150.80":"kreisanteil_falsch","150,8":"kreisanteil_falsch","150.8":"kreisanteil_falsch","150,80 cm":"kreisanteil_falsch","150,80cm":"kreisanteil_falsch","150,8 cm":"kreisanteil_falsch","150,8cm":"kreisanteil_falsch","150,72":"kreisanteil_falsch","150.72":"kreisanteil_falsch","150,72 cm":"kreisanteil_falsch","150,72cm":"kreisanteil_falsch","28,27":"flaeche_statt_umfang","28.27":"flaeche_statt_umfang","28,27 cm":"flaeche_statt_umfang","28,27cm":"flaeche_statt_umfang","28,26":"flaeche_statt_umfang","28.26":"flaeche_statt_umfang","28,26 cm":"flaeche_statt_umfang","28,26cm":"flaeche_statt_umfang","3,00":"pi_vergessen","3.00":"pi_vergessen","3,00 cm":"pi_vergessen","3,00cm":"pi_vergessen","3 cm":"pi_vergessen","3cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd6136873-fa24-4c78-841f-1d9408da6053'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd6136873-fa24-4c78-841f-1d9408da6053'::uuid);

-- #20 kreis-sektor-02 · Kreisausschnitt · Radius 4 cm, 90°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'eb59f15c-4906-4497-abf7-340b7430bd8a'::uuid, 'exercise', 'Kreisausschnitt · Radius 4 cm, 90°', 'Ein Kreisausschnitt hat den Radius 4 cm und den Mittelpunktswinkel 90°.

Wie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreisausschnitt hat den Radius 4 cm und den Mittelpunktswinkel 90°.\n\nWie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-sektor-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Viertel der Kreisfläche, Anteil direkt erkennbar.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kreisanteil_falsch, umfang_statt_flaeche, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'eb59f15c-4906-4497-abf7-340b7430bd8a'::uuid,
  p_correct_answers => '["12,57","12.57","12,57 cm²","12,57cm²","12,56","12.56","12,56 cm²","12,56cm²"]'::jsonb,
  p_solution        => 'Anteil: 90° von 360° = 1/4.
A = 1/4 · π · (4 cm)² = 1/4 · π · 16 cm² ≈ 12,57 cm² (π-Taste).
Mit π ≈ 3,14: A = 1/4 · 3,14 · 16 cm² = 12,56 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die ganze Kreisfläche angegeben, der Anteil 90°/360° fehlt.","socratic_question":"Welcher Teil des ganzen Kreises ist der Ausschnitt?"},{"error":"Den Anteil umgedreht: mal 4 statt mal 1/4.","socratic_question":"Ist der Ausschnitt größer oder kleiner als der ganze Kreis?"},{"error":"Den Kreisbogen berechnet statt der Fläche.","socratic_question":"Ist eine Länge oder eine Fläche gefragt?"},{"error":"π weggelassen: 1/4 · 16 = 4.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,57","equivalents":["12.57","12,57 cm²","12,57cm²","12,56","12.56","12,56 cm²","12,56cm²"],"known_errors":{"4":"pi_vergessen","50,27":"kreisanteil_falsch","50.27":"kreisanteil_falsch","50,27 cm²":"kreisanteil_falsch","50,27cm²":"kreisanteil_falsch","50,24":"kreisanteil_falsch","50.24":"kreisanteil_falsch","50,24 cm²":"kreisanteil_falsch","50,24cm²":"kreisanteil_falsch","201,06":"kreisanteil_falsch","201.06":"kreisanteil_falsch","201,06 cm²":"kreisanteil_falsch","201,06cm²":"kreisanteil_falsch","200,96":"kreisanteil_falsch","200.96":"kreisanteil_falsch","200,96 cm²":"kreisanteil_falsch","200,96cm²":"kreisanteil_falsch","6,28":"umfang_statt_flaeche","6.28":"umfang_statt_flaeche","6,28 cm²":"umfang_statt_flaeche","6,28cm²":"umfang_statt_flaeche","4,00":"pi_vergessen","4.00":"pi_vergessen","4,00 cm²":"pi_vergessen","4,00cm²":"pi_vergessen","4 cm²":"pi_vergessen","4cm²":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'eb59f15c-4906-4497-abf7-340b7430bd8a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'eb59f15c-4906-4497-abf7-340b7430bd8a'::uuid);

-- #21 kreis-sektor-03 · Kreisbogen · Radius 9 cm, 120°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '910071fc-b31d-41bf-85f7-bb70d2c01f1c'::uuid, 'exercise', 'Kreisbogen · Radius 9 cm, 120°', 'Ein Kreisausschnitt hat den Radius 9 cm und den Mittelpunktswinkel 120°.

Wie lang ist der Kreisbogen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreisausschnitt hat den Radius 9 cm und den Mittelpunktswinkel 120°.\n\nWie lang ist der Kreisbogen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 2, 'draft', 'edvance_k9_kreis', 'kreis-sektor-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Anteil 120°/360° = 1/3, als Dezimalzahl nicht abbrechend.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zu_frueh_gerundet, kreisanteil_falsch, flaeche_statt_umfang, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '910071fc-b31d-41bf-85f7-bb70d2c01f1c'::uuid,
  p_correct_answers => '["18,85","18.85","18,85 cm","18,85cm","18,84","18.84","18,84 cm","18,84cm"]'::jsonb,
  p_solution        => 'Anteil: 120° von 360° = 1/3 (nicht als 0,33 runden).
b = 1/3 · 2 · π · 9 cm = 6 · π cm ≈ 18,85 cm (π-Taste).
Mit π ≈ 3,14: b = 6 · 3,14 cm = 18,84 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Anteil 1/3 auf 0,33 gerundet und damit weitergerechnet.","socratic_question":"Was passiert, wenn du 1/3 als Bruch stehen lässt?"},{"error":"Den ganzen Umfang angegeben, der Anteil 120°/360° fehlt.","socratic_question":"Welcher Teil des ganzen Kreises ist der Ausschnitt?"},{"error":"Die Fläche des Ausschnitts berechnet statt des Bogens.","socratic_question":"Ist eine Länge oder eine Fläche gefragt?"},{"error":"π weggelassen: 1/3 · 18 = 6.","socratic_question":"Welcher Faktor fehlt in der Umfangsformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"18,85","equivalents":["18.85","18,85 cm","18,85cm","18,84","18.84","18,84 cm","18,84cm"],"known_errors":{"6":"pi_vergessen","18,66":"zu_frueh_gerundet","18.66":"zu_frueh_gerundet","18,66 cm":"zu_frueh_gerundet","18,66cm":"zu_frueh_gerundet","18,65":"zu_frueh_gerundet","18.65":"zu_frueh_gerundet","18,65 cm":"zu_frueh_gerundet","18,65cm":"zu_frueh_gerundet","56,55":"kreisanteil_falsch","56.55":"kreisanteil_falsch","56,55 cm":"kreisanteil_falsch","56,55cm":"kreisanteil_falsch","56,52":"kreisanteil_falsch","56.52":"kreisanteil_falsch","56,52 cm":"kreisanteil_falsch","56,52cm":"kreisanteil_falsch","84,82":"flaeche_statt_umfang","84.82":"flaeche_statt_umfang","84,82 cm":"flaeche_statt_umfang","84,82cm":"flaeche_statt_umfang","84,78":"flaeche_statt_umfang","84.78":"flaeche_statt_umfang","84,78 cm":"flaeche_statt_umfang","84,78cm":"flaeche_statt_umfang","6,00":"pi_vergessen","6.00":"pi_vergessen","6,00 cm":"pi_vergessen","6,00cm":"pi_vergessen","6 cm":"pi_vergessen","6cm":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '910071fc-b31d-41bf-85f7-bb70d2c01f1c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '910071fc-b31d-41bf-85f7-bb70d2c01f1c'::uuid);

-- #22 kreis-sektor-04 · Kreisausschnitt · Radius 5 m, 72°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1f4b915d-49dd-441f-a09b-69264ad8ff94'::uuid, 'exercise', 'Kreisausschnitt · Radius 5 m, 72°', 'Ein Kreisausschnitt hat den Radius 5 m und den Mittelpunktswinkel 72°.

Wie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreisausschnitt hat den Radius 5 m und den Mittelpunktswinkel 72°.\n\nWie groß ist sein Flächeninhalt? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm²', false, null, 'draft', 'edvance_k9_kreis', 'kreis-sektor-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Anteil 72°/360° muss erst gekürzt werden (1/5).","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kreisanteil_falsch, umfang_statt_flaeche, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '1f4b915d-49dd-441f-a09b-69264ad8ff94'::uuid,
  p_correct_answers => '["15,71","15.71","15,71 m²","15,71m²","15,70","15.70","15,7","15.7","15,70 m²","15,70m²","15,7 m²","15,7m²"]'::jsonb,
  p_solution        => 'Anteil: 72° von 360° = 1/5.
A = 1/5 · π · (5 m)² = 5 · π m² ≈ 15,71 m² (π-Taste).
Mit π ≈ 3,14: A = 5 · 3,14 m² = 15,70 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die ganze Kreisfläche angegeben, der Anteil 72°/360° fehlt.","socratic_question":"Welcher Teil des ganzen Kreises ist der Ausschnitt?"},{"error":"Den Anteil umgedreht: mal 5 statt mal 1/5.","socratic_question":"Ist der Ausschnitt größer oder kleiner als der ganze Kreis?"},{"error":"Den Kreisbogen berechnet statt der Fläche.","socratic_question":"Ist eine Länge oder eine Fläche gefragt?"},{"error":"π weggelassen: 1/5 · 25 = 5.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15,71","equivalents":["15.71","15,71 m²","15,71m²","15,70","15.70","15,7","15.7","15,70 m²","15,70m²","15,7 m²","15,7m²"],"known_errors":{"5":"pi_vergessen","78,54":"kreisanteil_falsch","78.54":"kreisanteil_falsch","78,54 m²":"kreisanteil_falsch","78,54m²":"kreisanteil_falsch","78,50":"kreisanteil_falsch","78.50":"kreisanteil_falsch","78,5":"kreisanteil_falsch","78.5":"kreisanteil_falsch","78,50 m²":"kreisanteil_falsch","78,50m²":"kreisanteil_falsch","78,5 m²":"kreisanteil_falsch","78,5m²":"kreisanteil_falsch","392,70":"kreisanteil_falsch","392.70":"kreisanteil_falsch","392,7":"kreisanteil_falsch","392.7":"kreisanteil_falsch","392,70 m²":"kreisanteil_falsch","392,70m²":"kreisanteil_falsch","392,7 m²":"kreisanteil_falsch","392,7m²":"kreisanteil_falsch","392,50":"kreisanteil_falsch","392.50":"kreisanteil_falsch","392,5":"kreisanteil_falsch","392.5":"kreisanteil_falsch","392,50 m²":"kreisanteil_falsch","392,50m²":"kreisanteil_falsch","392,5 m²":"kreisanteil_falsch","392,5m²":"kreisanteil_falsch","6,28":"umfang_statt_flaeche","6.28":"umfang_statt_flaeche","6,28 m²":"umfang_statt_flaeche","6,28m²":"umfang_statt_flaeche","5,00":"pi_vergessen","5.00":"pi_vergessen","5,00 m²":"pi_vergessen","5,00m²":"pi_vergessen","5 m²":"pi_vergessen","5m²":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '1f4b915d-49dd-441f-a09b-69264ad8ff94'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1f4b915d-49dd-441f-a09b-69264ad8ff94'::uuid);

-- #23 kreis-sektor-05 · Kreisausschnitt · Tortenstück, 26 cm Durchmesser, 12 Stücke
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dce69732-829b-4a5b-8ce8-186093c118a6'::uuid, 'exercise', 'Kreisausschnitt · Tortenstück, 26 cm Durchmesser, 12 Stücke', 'Eine runde Torte hat einen Durchmesser von 26 cm. Sie wird in 12 gleich große Stücke geschnitten.

Wie groß ist die Oberseite eines Stücks in Quadratzentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine runde Torte hat einen Durchmesser von 26 cm. Sie wird in 12 gleich große Stücke geschnitten.\n\nWie groß ist die Oberseite eines Stücks in Quadratzentimetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm²', false, 1, 'draft', 'edvance_k9_kreis', 'kreis-sektor-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Anteil aus der Stückzahl, Radius aus dem Durchmesser.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Kreisformel übersetzen, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, kreisanteil_falsch, zu_frueh_gerundet, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'dce69732-829b-4a5b-8ce8-186093c118a6'::uuid,
  p_correct_answers => '["44,24","44.24","44,24 cm²","44,24cm²","44,22","44.22","44,22 cm²","44,22cm²"]'::jsonb,
  p_solution        => 'r = 26 cm : 2 = 13 cm. Ein Stück ist 1/12 der Torte (30° von 360°).
A = 1/12 · π · (13 cm)² = 1/12 · π · 169 cm² ≈ 44,24 cm² (π-Taste).
Mit π ≈ 3,14: A = 1/12 · 3,14 · 169 cm² ≈ 44,22 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: π · 26².","socratic_question":"Sind 26 cm der Radius oder der Durchmesser der Torte?"},{"error":"Die ganze Torte berechnet, der Anteil 1/12 fehlt.","socratic_question":"Wie viel von der Torte ist ein Stück?"},{"error":"Den Anteil 1/12 auf 0,08 gerundet und damit weitergerechnet.","socratic_question":"Was passiert, wenn du 1/12 als Bruch stehen lässt?"},{"error":"π weggelassen: 169 : 12.","socratic_question":"Welcher Faktor fehlt in der Flächenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"44,24","equivalents":["44.24","44,24 cm²","44,24cm²","44,22","44.22","44,22 cm²","44,22cm²"],"known_errors":{"176,98":"radius_durchmesser_verwechselt","176.98":"radius_durchmesser_verwechselt","176,98 cm²":"radius_durchmesser_verwechselt","176,98cm²":"radius_durchmesser_verwechselt","176,89":"radius_durchmesser_verwechselt","176.89":"radius_durchmesser_verwechselt","176,89 cm²":"radius_durchmesser_verwechselt","176,89cm²":"radius_durchmesser_verwechselt","530,93":"kreisanteil_falsch","530.93":"kreisanteil_falsch","530,93 cm²":"kreisanteil_falsch","530,93cm²":"kreisanteil_falsch","530,66":"kreisanteil_falsch","530.66":"kreisanteil_falsch","530,66 cm²":"kreisanteil_falsch","530,66cm²":"kreisanteil_falsch","42,47":"zu_frueh_gerundet","42.47":"zu_frueh_gerundet","42,47 cm²":"zu_frueh_gerundet","42,47cm²":"zu_frueh_gerundet","42,45":"zu_frueh_gerundet","42.45":"zu_frueh_gerundet","42,45 cm²":"zu_frueh_gerundet","42,45cm²":"zu_frueh_gerundet","14,08":"pi_vergessen","14.08":"pi_vergessen","14,08 cm²":"pi_vergessen","14,08cm²":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'dce69732-829b-4a5b-8ce8-186093c118a6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dce69732-829b-4a5b-8ce8-186093c118a6'::uuid);

-- #24 kreis-sektor-06 · Kreisausschnitt · Winkel aus 12,56 cm Bogen bei Radius 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a7b29e3e-5330-41fe-ae91-a44403e93157'::uuid, 'exercise', 'Kreisausschnitt · Winkel aus 12,56 cm Bogen bei Radius 10 cm', 'Ein Kreisbogen gehört zu einem Kreis mit dem Radius 10 cm. Der Bogen ist 12,56 cm lang.

Wie groß ist der Mittelpunktswinkel? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Grad.',
  '{"kind":"short_input","prompt":"Ein Kreisbogen gehört zu einem Kreis mit dem Radius 10 cm. Der Bogen ist 12,56 cm lang.\n\nWie groß ist der Mittelpunktswinkel? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Grad."}'::jsonb, 'NUMERIC', 'geo_kreis_sektor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, '°', false, null, 'draft', 'edvance_k9_kreis', 'kreis-sektor-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung im Sektor – Anteil aus Bogen und Umfang bilden, dann in Grad umrechnen.","charge":"k9-kreis"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-kreis"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.","charge":"k9-kreis"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.","charge":"k9-kreis"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-3).","charge":"k9-kreis"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-kreis"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-kreis"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-kreis"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-kreis"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-kreis"},"hints":{"art":"leer","grund":"Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-kreis"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'a7b29e3e-5330-41fe-ae91-a44403e93157'::uuid,
  p_correct_answers => '["72","72 °","72°"]'::jsonb,
  p_solution        => 'Umfang: U = 2 · π · 10 cm ≈ 62,83 cm (mit 3,14: 62,8 cm).
Anteil: 12,56 : 62,83 ≈ 0,2 (mit 3,14: genau 0,2).
α = 0,2 · 360° ≈ 72°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Anteil angegeben statt des Winkels.","socratic_question":"Ist nach dem Anteil oder nach dem Winkel in Grad gefragt?"},{"error":"Den Radius als Durchmesser eingesetzt: Umfang nur π · 10.","socratic_question":"Ist 10 cm der Radius oder der Durchmesser?"},{"error":"π weggelassen: Umfang als 2 · 10 gerechnet.","socratic_question":"Welcher Faktor fehlt in der Umfangsformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"72","equivalents":["72 °","72°"],"known_errors":{"144":"radius_durchmesser_verwechselt","226":"pi_vergessen","0,20":"falsche_groesse_beantwortet","0.20":"falsche_groesse_beantwortet","0,2":"falsche_groesse_beantwortet","0.2":"falsche_groesse_beantwortet","0,20 °":"falsche_groesse_beantwortet","0,20°":"falsche_groesse_beantwortet","0,2 °":"falsche_groesse_beantwortet","0,2°":"falsche_groesse_beantwortet","144 °":"radius_durchmesser_verwechselt","144°":"radius_durchmesser_verwechselt","226 °":"pi_vergessen","226°":"pi_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'a7b29e3e-5330-41fe-ae91-a44403e93157'::uuid and t.status = 'draft' and t.source = 'edvance_k9_kreis')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a7b29e3e-5330-41fe-ae91-a44403e93157'::uuid);

commit;
