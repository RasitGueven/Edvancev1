-- K8 Lineare Funktionen, Migration 2 von 2 — 30 Aufgaben, je sechs zu den fuenf fkt_linear_*-Knoten.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-linfkt.json (Quelle: tools/k8-linfkt-aufgaben.mjs
-- und tools/k8-linfkt-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261001124808_substrat_k8_linfkt.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Fkt-6: Grundgebühr, Preis je km/Stunde/Minute, Anfangswert) oder Rückrichtung. Alle NUMERIC, damit die Fehlbild-Erkennung greift; die Graph-Aufgaben lesen am Generator koordinatensystem ab. Keine Hinweise, keine Personen.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-linfkt.csv. Pruefprotokoll: docs/prefill/k8-linfkt-verifikation.md.
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
--   fkt_linear_steigung: linfkt-steigung-06 = 1, linfkt-steigung-02 = 2. Rang 1 aus Profil {b_ignoriert,nur_einmal_addiert,steigung_kehrwert}, Rang 2 aus Profil {seiten_verwechselt,steigung_kehrwert} (1 neue Fehlbilder)
--   fkt_linear_yabschnitt: linfkt-yabschnitt-03 = 1, linfkt-yabschnitt-05 = 2. Rang 1 aus Profil {achsenabschnitt_verwechselt,betrag_fehler,m_b_vertauscht}, Rang 2 aus Profil {achsenabschnitt_verwechselt,groessen_vertauscht} (1 neue Fehlbilder)
--   fkt_linear_graph: linfkt-graph-01 = 1, linfkt-graph-06 = 2. Rang 1 aus Profil {achsenabschnitt_verwechselt,m_b_vertauscht}, Rang 2 aus Profil {groessen_vertauscht,steigung_kehrwert} (2 neue Fehlbilder)
--   fkt_linear_gleichung: linfkt-gleichung-01 = 1, linfkt-gleichung-04 = 2. Rang 1 aus Profil {m_b_vertauscht,vorzeichen_ignoriert}, Rang 2 aus Profil {addiert_statt_subtrahiert,steigung_kehrwert} (2 neue Fehlbilder)
--   fkt_linear_nullstelle: linfkt-nullstelle-02 = 1, linfkt-nullstelle-04 = 2. Rang 1 aus Profil {achsenabschnitt_verwechselt,betrag_fehler,division_vergessen}, Rang 2 aus Profil {betrag_fehler,falsche_gegenoperation} (1 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne --single-transaction, und
-- eine Aufgabe ohne Loesung waere still kaputt.

begin;

select set_config('request.jwt.claim.role', 'service_role', true);

-- #1 linfkt-steigung-01 · Steigung · zwei Punkte · erster Quadrant
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd8958025-3016-4995-8011-6ad2abe63fe5'::uuid, 'exercise', 'Steigung · zwei Punkte · erster Quadrant', 'Eine Gerade geht durch die Punkte A(1 | 2) und B(3 | 8).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(1 | 2) und B(3 | 8).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Steigungsformel mit positiven, ganzzahligen Koordinaten, Ergebnis ganzzahlig.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, seiten_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd8958025-3016-4995-8011-6ad2abe63fe5'::uuid,
  p_correct_answers => '["3","+3"]'::jsonb,
  p_solution        => 'm = (y₂ - y₁) / (x₂ - x₁) = (8 - 2) / (3 - 1) = 6 / 2 = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Waagerechte durch senkrechte Änderung geteilt: 2 / 6 = 1/3.","socratic_question":"Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?"},{"error":"Die Differenzen in verschiedener Reihenfolge gebildet: 6 / (-2) = -3.","socratic_question":"Hast du oben und unten mit demselben Punkt angefangen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","known_errors":{"1/3":"steigung_kehrwert","+1/3":"steigung_kehrwert","-3":"seiten_verwechselt","−3":"seiten_verwechselt","- 3":"seiten_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd8958025-3016-4995-8011-6ad2abe63fe5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd8958025-3016-4995-8011-6ad2abe63fe5'::uuid);

-- #2 linfkt-steigung-02 · Steigung · zwei Punkte · Punkt auf der y-Achse
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a0451e78-948c-4ef6-90ce-50a16fed9f39'::uuid, 'exercise', 'Steigung · zwei Punkte · Punkt auf der y-Achse', 'Eine Gerade geht durch die Punkte A(0 | 1) und B(2 | 5).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(0 | 1) und B(2 | 5).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Steigungsformel, ein Punkt auf der y-Achse, kleine ganze Zahlen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, seiten_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'a0451e78-948c-4ef6-90ce-50a16fed9f39'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => 'm = (5 - 1) / (2 - 0) = 4 / 2 = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Waagerechte durch senkrechte Änderung geteilt: 2 / 4 = 1/2.","socratic_question":"Welche Änderung gehört in den Zähler: die nach oben oder die nach rechts?"},{"error":"Die Differenzen in verschiedener Reihenfolge gebildet: 4 / (-2) = -2.","socratic_question":"Steigt die Gerade von A nach B oder fällt sie? Passt dein Vorzeichen dazu?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","known_errors":{"1/2":"steigung_kehrwert","+1/2":"steigung_kehrwert","-2":"seiten_verwechselt","−2":"seiten_verwechselt","- 2":"seiten_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'a0451e78-948c-4ef6-90ce-50a16fed9f39'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a0451e78-948c-4ef6-90ce-50a16fed9f39'::uuid);

-- #3 linfkt-steigung-03 · Steigung · zwei Punkte · fallende Gerade
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '438b3001-2778-4fec-be77-75354c88e454'::uuid, 'exercise', 'Steigung · zwei Punkte · fallende Gerade', 'Eine Gerade geht durch die Punkte A(-1 | 4) und B(2 | -2).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(-1 | 4) und B(2 | -2).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Differenzen mit negativen Koordinaten, Minus vor Minus im Nenner.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, betrag_fehler).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '438b3001-2778-4fec-be77-75354c88e454'::uuid,
  p_correct_answers => '["-2","−2","- 2"]'::jsonb,
  p_solution        => 'm = (-2 - 4) / (2 - (-1)) = -6 / 3 = -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Waagerechte durch senkrechte Änderung geteilt: 3 / (-6) = -1/2.","socratic_question":"Wie weit geht es von A nach B nach rechts, wie weit nach unten – und was davon steht im Zähler?"},{"error":"Betrag richtig, das Vorzeichen gekippt: 2 statt -2.","socratic_question":"Fällt die Gerade von links nach rechts oder steigt sie?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-2","known_errors":{"2":"betrag_fehler","-1/2":"steigung_kehrwert","−1/2":"steigung_kehrwert","- 1/2":"steigung_kehrwert","+2":"betrag_fehler"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '438b3001-2778-4fec-be77-75354c88e454'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '438b3001-2778-4fec-be77-75354c88e454'::uuid);

-- #4 linfkt-steigung-04 · Steigung · zwei Punkte · Ergebnis als Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'::uuid, 'exercise', 'Steigung · zwei Punkte · Ergebnis als Bruch', 'Eine Gerade geht durch die Punkte A(-2 | -1) und B(4 | 2).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(-2 | -1) und B(4 | 2).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negative Koordinaten in beiden Punkten, Ergebnis als gekürzter Bruch.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, seiten_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'::uuid,
  p_correct_answers => '["1/2","+1/2","0,5","+0,5","0.5","+0.5"]'::jsonb,
  p_solution        => 'm = (2 - (-1)) / (4 - (-2)) = 3 / 6 = 1/2 = 0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Waagerechte durch senkrechte Änderung geteilt: 6 / 3 = 2.","socratic_question":"Geht die Gerade bei einem Schritt nach rechts um mehr oder um weniger als eins nach oben?"},{"error":"Die Differenzen in verschiedener Reihenfolge gebildet: 3 / (-6) = -1/2.","socratic_question":"Hast du oben und unten mit demselben Punkt angefangen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/2","known_errors":{"2":"steigung_kehrwert","+2":"steigung_kehrwert","-1/2":"seiten_verwechselt","−1/2":"seiten_verwechselt","- 1/2":"seiten_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'::uuid);

-- #5 linfkt-steigung-05 · Steigung · Sachkontext · Preis je Kilometer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9f8674f1-2917-4082-ad94-20b3af6c84c0'::uuid, 'exercise', 'Steigung · Sachkontext · Preis je Kilometer', 'Eine Taxifahrt kostet bei 4 km Strecke 11 € und bei 10 km Strecke 20 €. Der Preis steigt gleichmäßig mit der Strecke.

Wie viel Euro kostet jeder weitere Kilometer?',
  '{"kind":"short_input","prompt":"Eine Taxifahrt kostet bei 4 km Strecke 11 € und bei 10 km Strecke 20 €. Der Preis steigt gleichmäßig mit der Strecke.\n\nWie viel Euro kostet jeder weitere Kilometer?"}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, '€', false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Sachsituation als zwei Punkte lesen, Steigung als Preis je km deuten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, b_ignoriert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '9f8674f1-2917-4082-ad94-20b3af6c84c0'::uuid,
  p_correct_answers => '["1,5","+1,5","1.5","+1.5","1,50","+1,50","1.50","+1.50","1,5 €","1,5€","+1,5 €","+1,5€","1.5 €","1.5€","+1.5 €","+1.5€","1,50 €","1,50€","+1,50 €","+1,50€","1.50 €","1.50€","+1.50 €","+1.50€"]'::jsonb,
  p_solution        => 'Punkte (4 | 11) und (10 | 20).
m = (20 - 11) / (10 - 4) = 9 / 6 = 1,50 € pro km.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Kilometer durch Euro geteilt: 6 / 9 = 2/3.","socratic_question":"Gefragt sind Euro pro Kilometer – was gehört dann in den Zähler?"},{"error":"Den Gesamtpreis durch die Strecke geteilt, als gäbe es keinen Grundpreis: 11 / 4 = 2,75.","socratic_question":"Kostet die Fahrt bei 10 km dann wirklich 20 €?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,5","known_errors":{"2/3":"steigung_kehrwert","+2/3":"steigung_kehrwert","2/3 €":"steigung_kehrwert","2/3€":"steigung_kehrwert","+2/3 €":"steigung_kehrwert","+2/3€":"steigung_kehrwert","2,75":"b_ignoriert","+2,75":"b_ignoriert","2.75":"b_ignoriert","+2.75":"b_ignoriert","2,75 €":"b_ignoriert","2,75€":"b_ignoriert","+2,75 €":"b_ignoriert","+2,75€":"b_ignoriert","2.75 €":"b_ignoriert","2.75€":"b_ignoriert","+2.75 €":"b_ignoriert","+2.75€":"b_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '9f8674f1-2917-4082-ad94-20b3af6c84c0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9f8674f1-2917-4082-ad94-20b3af6c84c0'::uuid);

-- #6 linfkt-steigung-06 · Steigung · Rückrichtung · Punkt aus Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7cd1b9af-433f-459f-90a6-cf241c245739'::uuid, 'exercise', 'Steigung · Rückrichtung · Punkt aus Steigung', 'Eine Gerade hat die Steigung 2 und geht durch den Punkt P(1 | 3).

Welche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 2 und geht durch den Punkt P(1 | 3).\n\nWelche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?"}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Problemlösen',
  60, null, false, 1, 'draft', 'edvance_k8_linfkt', 'linfkt-steigung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: aus Steigung und Punkt den Zuwachs über drei Schritte bestimmen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rückrichtung: Lösungsweg selbst finden, dann rechnen.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, nur_einmal_addiert, b_ignoriert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '7cd1b9af-433f-459f-90a6-cf241c245739'::uuid,
  p_correct_answers => '["9","+9"]'::jsonb,
  p_solution        => 'Von x = 1 bis x = 4 sind es 3 Schritte nach rechts.
Jeder Schritt bringt 2 nach oben: 3 + 3 · 2 = 9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit dem Kehrwert der Steigung gerechnet: 3 + 3 · 1/2 = 4,5.","socratic_question":"Wie viel geht es bei einem Schritt nach rechts nach oben?"},{"error":"Die Steigung nur einmal addiert: 3 + 2 = 5.","socratic_question":"Wie viele Schritte nach rechts liegen zwischen x = 1 und x = 4?"},{"error":"Wie bei einer Ursprungsgeraden gerechnet: 2 · 4 = 8.","socratic_question":"Geht die Gerade durch den Ursprung? Prüfe es mit dem Punkt P."}]'::jsonb,
  p_acceptance      => '{"canonical":"9","known_errors":{"5":"nur_einmal_addiert","8":"b_ignoriert","4,5":"steigung_kehrwert","+4,5":"steigung_kehrwert","4.5":"steigung_kehrwert","+4.5":"steigung_kehrwert","+5":"nur_einmal_addiert","+8":"b_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '7cd1b9af-433f-459f-90a6-cf241c245739'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7cd1b9af-433f-459f-90a6-cf241c245739'::uuid);

-- #7 linfkt-yabschnitt-01 · y-Achsenabschnitt · aus der Gleichung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'de54e58b-fac9-4341-b38e-88c5233a90d3'::uuid, 'exercise', 'y-Achsenabschnitt · aus der Gleichung', 'Gegeben ist die Funktion f(x) = 3x + 5.

Gib den y-Achsenabschnitt des Graphen von f an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 3x + 5.\n\nGib den y-Achsenabschnitt des Graphen von f an."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: b direkt aus y = mx + b ablesen, beide Zahlen positiv.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'de54e58b-fac9-4341-b38e-88c5233a90d3'::uuid,
  p_correct_answers => '["5","+5"]'::jsonb,
  p_solution        => 'In f(x) = mx + b ist b der y-Achsenabschnitt: b = 5 (f(0) = 3 · 0 + 5 = 5).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung statt des y-Achsenabschnitts angegeben.","socratic_question":"Welche Zahl steht beim x – und welche steht allein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","known_errors":{"3":"m_b_vertauscht","+3":"m_b_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'de54e58b-fac9-4341-b38e-88c5233a90d3'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'de54e58b-fac9-4341-b38e-88c5233a90d3'::uuid);

-- #8 linfkt-yabschnitt-02 · y-Achsenabschnitt · fallende Gerade
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fa6fb2c7-da7b-44be-a425-f7dc8e06af6a'::uuid, 'exercise', 'y-Achsenabschnitt · fallende Gerade', 'Gegeben ist die Funktion f(x) = -2x + 7.

Gib den y-Achsenabschnitt des Graphen von f an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = -2x + 7.\n\nGib den y-Achsenabschnitt des Graphen von f an."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: b ablesen, Steigung negativ als Ablenkung.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'fa6fb2c7-da7b-44be-a425-f7dc8e06af6a'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => 'b ist die Zahl ohne x: b = 7 (f(0) = -2 · 0 + 7 = 7).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung statt des y-Achsenabschnitts angegeben.","socratic_question":"Welchen Wert hat f, wenn x = 0 ist?"},{"error":"Die Nullstelle statt des y-Achsenabschnitts berechnet: -2x + 7 = 0 ergibt 3,5.","socratic_question":"Wo schneidet der Graph die senkrechte Achse – bei x = 0 oder bei y = 0?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","known_errors":{"-2":"m_b_vertauscht","−2":"m_b_vertauscht","- 2":"m_b_vertauscht","3,5":"achsenabschnitt_verwechselt","+3,5":"achsenabschnitt_verwechselt","3.5":"achsenabschnitt_verwechselt","+3.5":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'fa6fb2c7-da7b-44be-a425-f7dc8e06af6a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fa6fb2c7-da7b-44be-a425-f7dc8e06af6a'::uuid);

-- #9 linfkt-yabschnitt-03 · y-Achsenabschnitt · negativer Abschnitt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e4611c3d-02b9-4a0b-8e42-795f8a15a925'::uuid, 'exercise', 'y-Achsenabschnitt · negativer Abschnitt', 'Gegeben ist die Funktion f(x) = 4x - 6.

Gib den y-Achsenabschnitt des Graphen von f an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 4x - 6.\n\nGib den y-Achsenabschnitt des Graphen von f an."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: b steht als Subtraktion da und muss als negative Zahl gelesen werden.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht, betrag_fehler, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e4611c3d-02b9-4a0b-8e42-795f8a15a925'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => 'f(x) = 4x - 6 = 4x + (-6), also b = -6 (f(0) = -6).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung statt des y-Achsenabschnitts angegeben.","socratic_question":"Welche Zahl steht beim x – und welche steht allein?"},{"error":"Betrag richtig, das Minus vor der 6 nicht übernommen.","socratic_question":"Schneidet der Graph die y-Achse oberhalb oder unterhalb des Ursprungs?"},{"error":"Die Nullstelle statt des y-Achsenabschnitts berechnet: 4x - 6 = 0 ergibt 1,5.","socratic_question":"Wo schneidet der Graph die senkrechte Achse – bei x = 0 oder bei y = 0?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","known_errors":{"4":"m_b_vertauscht","6":"betrag_fehler","+4":"m_b_vertauscht","+6":"betrag_fehler","1,5":"achsenabschnitt_verwechselt","+1,5":"achsenabschnitt_verwechselt","1.5":"achsenabschnitt_verwechselt","+1.5":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e4611c3d-02b9-4a0b-8e42-795f8a15a925'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e4611c3d-02b9-4a0b-8e42-795f8a15a925'::uuid);

-- #10 linfkt-yabschnitt-04 · y-Achsenabschnitt · aus Steigung und Punkt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c2f24a82-07ce-4db6-bdcb-f667e34f2439'::uuid, 'exercise', 'y-Achsenabschnitt · aus Steigung und Punkt', 'Eine Gerade hat die Steigung 2 und geht durch den Punkt P(3 | 4).

Bestimme den y-Achsenabschnitt b der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 2 und geht durch den Punkt P(3 | 4).\n\nBestimme den y-Achsenabschnitt b der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Punkt in y = mx + b einsetzen und nach b auflösen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (addiert_statt_subtrahiert, betrag_fehler).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'c2f24a82-07ce-4db6-bdcb-f667e34f2439'::uuid,
  p_correct_answers => '["-2","−2","- 2"]'::jsonb,
  p_solution        => 'P einsetzen: 4 = 2 · 3 + b, also 4 = 6 + b und b = 4 - 6 = -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Beim Auflösen addiert statt subtrahiert: b = 4 + 6 = 10.","socratic_question":"Was musst du auf beiden Seiten tun, damit die 6 neben dem b verschwindet?"},{"error":"Betrag richtig, Vorzeichen gekippt: 6 - 4 = 2.","socratic_question":"Liegt der Punkt P unter- oder oberhalb der Geraden y = 2x? Was heißt das für b?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-2","known_errors":{"2":"betrag_fehler","10":"addiert_statt_subtrahiert","+10":"addiert_statt_subtrahiert","+2":"betrag_fehler"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'c2f24a82-07ce-4db6-bdcb-f667e34f2439'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c2f24a82-07ce-4db6-bdcb-f667e34f2439'::uuid);

-- #11 linfkt-yabschnitt-05 · y-Achsenabschnitt · Sachkontext · Grundpreis
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1c170c59-3c96-4767-b731-6d954e127025'::uuid, 'exercise', 'y-Achsenabschnitt · Sachkontext · Grundpreis', 'Bei einem Handytarif setzen sich die monatlichen Kosten aus einem festen Grundpreis und einem Preis pro Minute zusammen. Die Kosten in Euro für x Minuten werden durch K(x) = 0,1x + 8 beschrieben.

Wie hoch ist der monatliche Grundpreis in Euro?',
  '{"kind":"short_input","prompt":"Bei einem Handytarif setzen sich die monatlichen Kosten aus einem festen Grundpreis und einem Preis pro Minute zusammen. Die Kosten in Euro für x Minuten werden durch K(x) = 0,1x + 8 beschrieben.\n\nWie hoch ist der monatliche Grundpreis in Euro?"}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, '€', false, 2, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Parameter b in der Sachsituation als Grundpreis deuten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '1c170c59-3c96-4767-b731-6d954e127025'::uuid,
  p_correct_answers => '["8","+8","8 €","8€","+8 €","+8€"]'::jsonb,
  p_solution        => 'Der Grundpreis fällt auch bei 0 Minuten an: K(0) = 0,1 · 0 + 8 = 8 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Preis pro Minute statt des Grundpreises angegeben.","socratic_question":"Was kostet der Monat, wenn man gar nicht telefoniert?"},{"error":"Die Nullstelle von K berechnet: 0,1x + 8 = 0 ergibt -80.","socratic_question":"Welche Bedeutung hat x = 0 in diesem Tarif?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","known_errors":{"0,1":"groessen_vertauscht","+0,1":"groessen_vertauscht","0.1":"groessen_vertauscht","+0.1":"groessen_vertauscht","0,10":"groessen_vertauscht","+0,10":"groessen_vertauscht","0.10":"groessen_vertauscht","+0.10":"groessen_vertauscht","0,1 €":"groessen_vertauscht","0,1€":"groessen_vertauscht","+0,1 €":"groessen_vertauscht","+0,1€":"groessen_vertauscht","0.1 €":"groessen_vertauscht","0.1€":"groessen_vertauscht","+0.1 €":"groessen_vertauscht","+0.1€":"groessen_vertauscht","0,10 €":"groessen_vertauscht","0,10€":"groessen_vertauscht","+0,10 €":"groessen_vertauscht","+0,10€":"groessen_vertauscht","0.10 €":"groessen_vertauscht","0.10€":"groessen_vertauscht","+0.10 €":"groessen_vertauscht","+0.10€":"groessen_vertauscht","-80":"achsenabschnitt_verwechselt","−80":"achsenabschnitt_verwechselt","- 80":"achsenabschnitt_verwechselt","-80 €":"achsenabschnitt_verwechselt","-80€":"achsenabschnitt_verwechselt","−80 €":"achsenabschnitt_verwechselt","−80€":"achsenabschnitt_verwechselt","- 80 €":"achsenabschnitt_verwechselt","- 80€":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '1c170c59-3c96-4767-b731-6d954e127025'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1c170c59-3c96-4767-b731-6d954e127025'::uuid);

-- #12 linfkt-yabschnitt-06 · y-Achsenabschnitt · Sachkontext · Anfangswert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '871303c4-dcdb-4573-9dfb-6e3ca2085426'::uuid, 'exercise', 'y-Achsenabschnitt · Sachkontext · Anfangswert', 'Ein Wassertank wird gleichmäßig geleert. Der Wasserstand in cm nach t Minuten wird durch h(t) = -4t + 120 beschrieben.

Wie hoch steht das Wasser zu Beginn, also bei t = 0?',
  '{"kind":"short_input","prompt":"Ein Wassertank wird gleichmäßig geleert. Der Wasserstand in cm nach t Minuten wird durch h(t) = -4t + 120 beschrieben.\n\nWie hoch steht das Wasser zu Beginn, also bei t = 0?"}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, 'cm', false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-yabschnitt-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: y-Achsenabschnitt als Anfangswert einer Sachsituation deuten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '871303c4-dcdb-4573-9dfb-6e3ca2085426'::uuid,
  p_correct_answers => '["120","+120","120 cm","120cm","+120 cm","+120cm"]'::jsonb,
  p_solution        => 'Zu Beginn ist t = 0: h(0) = -4 · 0 + 120 = 120 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Änderung pro Minute statt des Anfangswerts angegeben.","socratic_question":"Was beschreibt die -4 – einen Wasserstand oder eine Änderung?"},{"error":"Den Zeitpunkt berechnet, an dem der Tank leer ist: -4t + 120 = 0 ergibt 30.","socratic_question":"Gefragt ist ein Wasserstand – passt dazu die Zeit, nach der der Tank leer ist?"}]'::jsonb,
  p_acceptance      => '{"canonical":"120","known_errors":{"30":"achsenabschnitt_verwechselt","-4":"groessen_vertauscht","−4":"groessen_vertauscht","- 4":"groessen_vertauscht","-4 cm":"groessen_vertauscht","-4cm":"groessen_vertauscht","−4 cm":"groessen_vertauscht","−4cm":"groessen_vertauscht","- 4 cm":"groessen_vertauscht","- 4cm":"groessen_vertauscht","+30":"achsenabschnitt_verwechselt","30 cm":"achsenabschnitt_verwechselt","30cm":"achsenabschnitt_verwechselt","+30 cm":"achsenabschnitt_verwechselt","+30cm":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '871303c4-dcdb-4573-9dfb-6e3ca2085426'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '871303c4-dcdb-4573-9dfb-6e3ca2085426'::uuid);

-- #13 linfkt-graph-01 · Graph · y-Achsenabschnitt ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid, 'exercise', 'Graph · y-Achsenabschnitt ablesen', 'Die Abbildung zeigt den Graphen einer linearen Funktion f.

Lies den y-Achsenabschnitt des Graphen ab.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nLies den y-Achsenabschnitt des Graphen ab."}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, true, 1, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Schnittpunkt mit der y-Achse auf einem Gitterpunkt ablesen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (achsenabschnitt_verwechselt, m_b_vertauscht).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid,
  p_correct_answers => '["1","+1"]'::jsonb,
  p_solution        => 'Der Graph schneidet die y-Achse im Punkt (0 | 1), also b = 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Schnittpunkt mit der x-Achse statt mit der y-Achse abgelesen.","socratic_question":"Welche der beiden Achsen ist die senkrechte?"},{"error":"Die Steigung statt des y-Achsenabschnitts abgelesen.","socratic_question":"Gefragt ist ein Punkt auf einer Achse – oder eine Änderung?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1","known_errors":{"2":"m_b_vertauscht","-0,5":"achsenabschnitt_verwechselt","−0,5":"achsenabschnitt_verwechselt","- 0,5":"achsenabschnitt_verwechselt","-0.5":"achsenabschnitt_verwechselt","−0.5":"achsenabschnitt_verwechselt","- 0.5":"achsenabschnitt_verwechselt","+2":"m_b_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":2,"b":1,"label":"f"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion f.'
 where exists (select 1 from public.tasks t where t.id = '6c2393f4-f1d5-490e-adeb-c7b1c8fa611a'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #14 linfkt-graph-02 · Graph · Steigung ablesen · fallend
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid, 'exercise', 'Graph · Steigung ablesen · fallend', 'Die Abbildung zeigt den Graphen einer linearen Funktion f.

Lies die Steigung m des Graphen ab.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nLies die Steigung m des Graphen ab."}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, true, null, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Steigungsdreieck mit einem Schritt nach rechts, Steigung ganzzahlig.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, m_b_vertauscht).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid,
  p_correct_answers => '["-1","−1","- 1"]'::jsonb,
  p_solution        => 'Von (0 | 2) einen Schritt nach rechts geht der Graph einen Schritt nach unten, also m = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, die Richtung übersehen: der Graph fällt.","socratic_question":"Geht der Graph von links nach rechts nach oben oder nach unten?"},{"error":"Den y-Achsenabschnitt statt der Steigung abgelesen.","socratic_question":"Gefragt ist eine Änderung – oder ein Punkt auf der y-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-1","known_errors":{"1":"betrag_fehler","2":"m_b_vertauscht","+1":"betrag_fehler","+2":"m_b_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":-1,"b":2,"label":"f"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion f.'
 where exists (select 1 from public.tasks t where t.id = 'e80dd66b-ea62-4fa2-acbd-fbfe5d8190a6'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #15 linfkt-graph-03 · Graph · Steigung ablesen · Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid, 'exercise', 'Graph · Steigung ablesen · Bruch', 'Die Abbildung zeigt den Graphen einer linearen Funktion g.

Lies die Steigung m des Graphen von g ab.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Graphen einer linearen Funktion g.\n\nLies die Steigung m des Graphen von g ab."}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, null, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Steigungsdreieck über zwei Kästchen nach rechts, Steigung als Bruch.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (steigung_kehrwert, m_b_vertauscht).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid,
  p_correct_answers => '["1/2","+1/2","0,5","+0,5","0.5","+0.5"]'::jsonb,
  p_solution        => 'Von (0 | -1) zwei Schritte nach rechts und einen nach oben bis (2 | 0): m = 1/2 = 0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zwei nach rechts durch eins nach oben geteilt: 2 statt 1/2.","socratic_question":"Ist der Graph steiler oder flacher als eine Gerade, die bei jedem Schritt nach rechts einen nach oben geht?"},{"error":"Den y-Achsenabschnitt statt der Steigung abgelesen.","socratic_question":"Gefragt ist eine Änderung – oder ein Punkt auf der y-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/2","known_errors":{"2":"steigung_kehrwert","+2":"steigung_kehrwert","-1":"m_b_vertauscht","−1":"m_b_vertauscht","- 1":"m_b_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":0.5,"b":-1,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion g.'
 where exists (select 1 from public.tasks t where t.id = '9a48fec6-1176-4303-82e6-4150f2ffcfc0'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #16 linfkt-graph-04 · Graph · Funktionswert ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid, 'exercise', 'Graph · Funktionswert ablesen', 'Die Abbildung zeigt den Graphen einer linearen Funktion f.

Welchen y-Wert hat der Graph an der Stelle x = 2?',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nWelchen y-Wert hat der Graph an der Stelle x = 2?"}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, null, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Funktionswert im vierten Quadranten ablesen, Ergebnis negativ.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht, koordinate_vorzeichen_verloren).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid,
  p_correct_answers => '["-1","−1","- 1"]'::jsonb,
  p_solution        => 'Bei x = 2 senkrecht zum Graphen: der Punkt liegt bei (2 | -1), also f(2) = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Stelle gesucht, an der der y-Wert 2 ist: x = 0,5.","socratic_question":"Ist 2 hier ein x-Wert oder ein y-Wert?"},{"error":"Den Abstand zur x-Achse richtig abgelesen, das Minus fehlt.","socratic_question":"Liegt der Punkt über oder unter der x-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-1","known_errors":{"1":"koordinate_vorzeichen_verloren","0,5":"koordinaten_vertauscht","+0,5":"koordinaten_vertauscht","0.5":"koordinaten_vertauscht","+0.5":"koordinaten_vertauscht","+1":"koordinate_vorzeichen_verloren"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":-2,"b":3,"label":"f"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion f.'
 where exists (select 1 from public.tasks t where t.id = '24a633b2-ca0b-4909-9907-26bb0e6c163b'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #17 linfkt-graph-05 · Graph · Rückrichtung · Stelle zu einem y-Wert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid, 'exercise', 'Graph · Rückrichtung · Stelle zu einem y-Wert', 'Die Abbildung zeigt den Graphen einer linearen Funktion f.

An welcher Stelle x hat der Graph den y-Wert 1?',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nAn welcher Stelle x hat der Graph den y-Wert 1?"}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Problemlösen',
  60, null, true, null, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: vom y-Wert waagerecht zum Graphen, dann die Stelle ablesen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rückrichtung: Lösungsweg selbst finden, dann rechnen.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht, falsche_groesse_beantwortet).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => 'Waagerecht bei y = 1 zum Graphen: der Punkt liegt bei (2 | 1), also x = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den y-Wert an der Stelle x = 1 abgelesen statt die Stelle zum y-Wert 1.","socratic_question":"Ist 1 hier ein x-Wert oder ein y-Wert?"},{"error":"Den gegebenen y-Wert als Antwort wiederholt.","socratic_question":"Gesucht ist ein x-Wert – auf welcher Achse liest du ihn ab?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","known_errors":{"1":"falsche_groesse_beantwortet","-0,5":"koordinaten_vertauscht","−0,5":"koordinaten_vertauscht","- 0,5":"koordinaten_vertauscht","-0.5":"koordinaten_vertauscht","−0.5":"koordinaten_vertauscht","- 0.5":"koordinaten_vertauscht","+1":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select 'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":1.5,"b":-2,"label":"f"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion f.'
 where exists (select 1 from public.tasks t where t.id = 'ea0de2c5-d074-464b-a2ea-49a86dc907ab'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #18 linfkt-graph-06 · Graph · Sachkontext · Leihgebühr pro Stunde
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid, 'exercise', 'Graph · Sachkontext · Leihgebühr pro Stunde', 'Der Graph zeigt die Kosten y in Euro für das Ausleihen eines Fahrrads in Abhängigkeit von der Leihdauer x in Stunden.

Wie viel Euro kostet jede weitere Stunde?',
  '{"kind":"short_input","prompt":"Der Graph zeigt die Kosten y in Euro für das Ausleihen eines Fahrrads in Abhängigkeit von der Leihdauer x in Stunden.\n\nWie viel Euro kostet jede weitere Stunde?"}'::jsonb, 'NUMERIC', 'fkt_linear_graph',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, '€', true, 2, 'draft', 'edvance_k8_linfkt', 'linfkt-graph-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Steigung am Graphen ablesen und als Preis pro Stunde deuten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (Graph im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, steigung_kehrwert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid,
  p_correct_answers => '["2","+2","2 €","2€","+2 €","+2€"]'::jsonb,
  p_solution        => 'Der Graph beginnt bei (0 | 3) und steigt pro Stunde um 2: (1 | 5), (2 | 7), …
Jede weitere Stunde kostet 2 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Grundpreis statt des Preises pro Stunde abgelesen.","socratic_question":"Was kostet die Ausleihe für 0 Stunden – und was kommt pro Stunde dazu?"},{"error":"Stunden durch Euro geteilt: 1 / 2.","socratic_question":"Gefragt sind Euro pro Stunde – was gehört in den Zähler?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","known_errors":{"3":"groessen_vertauscht","+3":"groessen_vertauscht","3 €":"groessen_vertauscht","3€":"groessen_vertauscht","+3 €":"groessen_vertauscht","+3€":"groessen_vertauscht","1/2":"steigung_kehrwert","+1/2":"steigung_kehrwert","1/2 €":"steigung_kehrwert","1/2€":"steigung_kehrwert","+1/2 €":"steigung_kehrwert","+1/2€":"steigung_kehrwert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid);
insert into public.task_figures (task_id, generator, params, alt_text)
select '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid, 'koordinatensystem', '{"x_min":0,"x_max":5,"y_min":0,"y_max":13,"funktionen":[{"typ":"linear","m":2,"b":3,"label":"f"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion f.'
 where exists (select 1 from public.tasks t where t.id = '45928556-74be-4aa8-837f-97fa04a4dce3'::uuid and t.source = 'edvance_k8_linfkt')
on conflict (task_id) do nothing;

-- #19 linfkt-gleichung-01 · Funktionsgleichung · aus m und b · Funktionswert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a61e8be9-b55f-4c43-9971-7b74e3d55a33'::uuid, 'exercise', 'Funktionsgleichung · aus m und b · Funktionswert', 'Eine lineare Funktion f hat die Steigung 3 und den y-Achsenabschnitt -2.

Stelle die Funktionsgleichung auf und berechne damit f(4).',
  '{"kind":"short_input","prompt":"Eine lineare Funktion f hat die Steigung 3 und den y-Achsenabschnitt -2.\n\nStelle die Funktionsgleichung auf und berechne damit f(4)."}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: m und b in y = mx + b einsetzen, dann einen Wert berechnen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht, vorzeichen_ignoriert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'a61e8be9-b55f-4c43-9971-7b74e3d55a33'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'f(x) = 3x - 2.
f(4) = 3 · 4 - 2 = 12 - 2 = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Steigung und Achsenabschnitt vertauscht: f(x) = -2x + 3, f(4) = -5.","socratic_question":"Welche der beiden Zahlen gehört zum x?"},{"error":"Das Minus vor der 2 weggelassen: 3 · 4 + 2 = 14.","socratic_question":"Liegt der Schnittpunkt mit der y-Achse über oder unter null?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","known_errors":{"14":"vorzeichen_ignoriert","-5":"m_b_vertauscht","−5":"m_b_vertauscht","- 5":"m_b_vertauscht","+14":"vorzeichen_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'a61e8be9-b55f-4c43-9971-7b74e3d55a33'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a61e8be9-b55f-4c43-9971-7b74e3d55a33'::uuid);

-- #20 linfkt-gleichung-02 · Funktionsgleichung · fallend · Funktionswert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1bbce78e-f996-4c03-a78a-09b47f5c7445'::uuid, 'exercise', 'Funktionsgleichung · fallend · Funktionswert', 'Eine lineare Funktion f hat die Steigung -2 und schneidet die y-Achse bei y = 5.

Stelle die Funktionsgleichung auf und berechne damit f(3).',
  '{"kind":"short_input","prompt":"Eine lineare Funktion f hat die Steigung -2 und schneidet die y-Achse bei y = 5.\n\nStelle die Funktionsgleichung auf und berechne damit f(3)."}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gleichung aus m und b, Einsetzen mit negativem Faktor.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht, betrag_fehler).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '1bbce78e-f996-4c03-a78a-09b47f5c7445'::uuid,
  p_correct_answers => '["-1","−1","- 1"]'::jsonb,
  p_solution        => 'f(x) = -2x + 5.
f(3) = -2 · 3 + 5 = -6 + 5 = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Steigung und Achsenabschnitt vertauscht: f(x) = 5x - 2, f(3) = 13.","socratic_question":"Welche der beiden Zahlen gehört zum x?"},{"error":"Betrag richtig, Vorzeichen gekippt: 1 statt -1.","socratic_question":"Ist -6 + 5 größer oder kleiner als null?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-1","known_errors":{"1":"betrag_fehler","13":"m_b_vertauscht","+13":"m_b_vertauscht","+1":"betrag_fehler"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '1bbce78e-f996-4c03-a78a-09b47f5c7445'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1bbce78e-f996-4c03-a78a-09b47f5c7445'::uuid);

-- #21 linfkt-gleichung-03 · Funktionsgleichung · aus zwei Punkten · Funktionswert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b0f1b654-75da-4811-b7b4-065712b6e347'::uuid, 'exercise', 'Funktionsgleichung · aus zwei Punkten · Funktionswert', 'Eine Gerade geht durch die Punkte A(0 | 4) und B(2 | 10).

Bestimme die Funktionsgleichung und berechne damit f(5).',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(0 | 4) und B(2 | 10).\n\nBestimme die Funktionsgleichung und berechne damit f(5)."}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: m aus zwei Punkten, b aus dem Punkt auf der y-Achse, dann einsetzen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (m_b_vertauscht, seiten_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'b0f1b654-75da-4811-b7b4-065712b6e347'::uuid,
  p_correct_answers => '["19","+19"]'::jsonb,
  p_solution        => 'm = (10 - 4) / (2 - 0) = 3, b = 4 (A liegt auf der y-Achse).
f(x) = 3x + 4, f(5) = 15 + 4 = 19.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Steigung und Achsenabschnitt vertauscht: f(x) = 4x + 3, f(5) = 23.","socratic_question":"Welche Zahl hast du als Änderung pro Schritt berechnet, welche abgelesen?"},{"error":"Die Differenzen in verschiedener Reihenfolge gebildet: m = -3, f(5) = -11.","socratic_question":"Steigt die Gerade von A nach B oder fällt sie?"}]'::jsonb,
  p_acceptance      => '{"canonical":"19","known_errors":{"23":"m_b_vertauscht","+23":"m_b_vertauscht","-11":"seiten_verwechselt","−11":"seiten_verwechselt","- 11":"seiten_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'b0f1b654-75da-4811-b7b4-065712b6e347'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b0f1b654-75da-4811-b7b4-065712b6e347'::uuid);

-- #22 linfkt-gleichung-04 · Funktionsgleichung · aus zwei Punkten · Achsenabschnitt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ffc76634-86ca-4c53-b816-d18d7f868443'::uuid, 'exercise', 'Funktionsgleichung · aus zwei Punkten · Achsenabschnitt', 'Eine Gerade geht durch die Punkte A(1 | 1) und B(3 | 7). Ihre Funktionsgleichung hat die Form y = mx + b.

Welchen Wert hat b?',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(1 | 1) und B(3 | 7). Ihre Funktionsgleichung hat die Form y = mx + b.\n\nWelchen Wert hat b?"}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst m aus zwei Punkten, dann b durch Einsetzen; kein Punkt auf der y-Achse.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (addiert_statt_subtrahiert, steigung_kehrwert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'ffc76634-86ca-4c53-b816-d18d7f868443'::uuid,
  p_correct_answers => '["-2","−2","- 2"]'::jsonb,
  p_solution        => 'm = (7 - 1) / (3 - 1) = 3.
A einsetzen: 1 = 3 · 1 + b, also b = 1 - 3 = -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Beim Auflösen nach b addiert statt subtrahiert: 1 + 3 = 4.","socratic_question":"Was musst du auf beiden Seiten tun, damit die 3 neben dem b verschwindet?"},{"error":"Mit dem Kehrwert der Steigung gerechnet: m = 1/3, b = 2/3.","socratic_question":"Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-2","known_errors":{"4":"addiert_statt_subtrahiert","+4":"addiert_statt_subtrahiert","2/3":"steigung_kehrwert","+2/3":"steigung_kehrwert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'ffc76634-86ca-4c53-b816-d18d7f868443'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ffc76634-86ca-4c53-b816-d18d7f868443'::uuid);

-- #23 linfkt-gleichung-05 · Funktionsgleichung · Sachkontext · Carsharing
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '55d52e3e-cdd5-4e3c-9929-fb82aac16d33'::uuid, 'exercise', 'Funktionsgleichung · Sachkontext · Carsharing', 'Ein Carsharing-Tarif kostet 5 € Grundgebühr pro Fahrt und zusätzlich 0,30 € pro gefahrenem Kilometer.

Stelle eine Funktionsgleichung für die Kosten auf und berechne die Kosten in Euro für eine Fahrt von 20 km.',
  '{"kind":"short_input","prompt":"Ein Carsharing-Tarif kostet 5 € Grundgebühr pro Fahrt und zusätzlich 0,30 € pro gefahrenem Kilometer.\n\nStelle eine Funktionsgleichung für die Kosten auf und berechne die Kosten in Euro für eine Fahrt von 20 km."}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, '€', false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Grundgebühr und Preis pro km als b und m deuten, Gleichung aufstellen und auswerten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, b_ignoriert).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '55d52e3e-cdd5-4e3c-9929-fb82aac16d33'::uuid,
  p_correct_answers => '["11","+11","11 €","11€","+11 €","+11€"]'::jsonb,
  p_solution        => 'K(x) = 0,3x + 5 (x in km, K in €).
K(20) = 0,3 · 20 + 5 = 6 + 5 = 11 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Grundgebühr und Kilometerpreis vertauscht: 5 · 20 + 0,30 = 100,30.","socratic_question":"Welcher Betrag fällt bei jedem Kilometer an, welcher nur einmal?"},{"error":"Nur die Kilometerkosten berechnet, die Grundgebühr fehlt.","socratic_question":"Was kostet die Fahrt, wenn man null Kilometer fährt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11","known_errors":{"6":"b_ignoriert","100,3":"groessen_vertauscht","+100,3":"groessen_vertauscht","100.3":"groessen_vertauscht","+100.3":"groessen_vertauscht","100,30":"groessen_vertauscht","+100,30":"groessen_vertauscht","100.30":"groessen_vertauscht","+100.30":"groessen_vertauscht","100,3 €":"groessen_vertauscht","100,3€":"groessen_vertauscht","+100,3 €":"groessen_vertauscht","+100,3€":"groessen_vertauscht","100.3 €":"groessen_vertauscht","100.3€":"groessen_vertauscht","+100.3 €":"groessen_vertauscht","+100.3€":"groessen_vertauscht","100,30 €":"groessen_vertauscht","100,30€":"groessen_vertauscht","+100,30 €":"groessen_vertauscht","+100,30€":"groessen_vertauscht","100.30 €":"groessen_vertauscht","100.30€":"groessen_vertauscht","+100.30 €":"groessen_vertauscht","+100.30€":"groessen_vertauscht","+6":"b_ignoriert","6 €":"b_ignoriert","6€":"b_ignoriert","+6 €":"b_ignoriert","+6€":"b_ignoriert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '55d52e3e-cdd5-4e3c-9929-fb82aac16d33'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '55d52e3e-cdd5-4e3c-9929-fb82aac16d33'::uuid);

-- #24 linfkt-gleichung-06 · Funktionsgleichung · Sachkontext · Kerze
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '07f970aa-ff64-4158-a713-9943054621a0'::uuid, 'exercise', 'Funktionsgleichung · Sachkontext · Kerze', 'Eine Kerze ist 24 cm lang. Sie brennt gleichmäßig ab und wird dabei pro Stunde 1,5 cm kürzer.

Stelle eine Funktionsgleichung für die Länge der Kerze nach x Stunden auf. Wie lang ist die Kerze nach 6 Stunden noch?',
  '{"kind":"short_input","prompt":"Eine Kerze ist 24 cm lang. Sie brennt gleichmäßig ab und wird dabei pro Stunde 1,5 cm kürzer.\n\nStelle eine Funktionsgleichung für die Länge der Kerze nach x Stunden auf. Wie lang ist die Kerze nach 6 Stunden noch?"}'::jsonb, 'NUMERIC', 'fkt_linear_gleichung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, 'cm', false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-gleichung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: fallende Größe als negative Steigung modellieren, dann auswerten (Fkt-6).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, falsche_groesse_beantwortet).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '07f970aa-ff64-4158-a713-9943054621a0'::uuid,
  p_correct_answers => '["15","+15","15 cm","15cm","+15 cm","+15cm"]'::jsonb,
  p_solution        => 'L(x) = -1,5x + 24 (x in Stunden, L in cm).
L(6) = -1,5 · 6 + 24 = -9 + 24 = 15 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit positiver Steigung gerechnet, als würde die Kerze wachsen: 9 + 24 = 33.","socratic_question":"Wird die Kerze länger oder kürzer? Welches Vorzeichen hat dann die Steigung?"},{"error":"Die abgebrannte Länge statt der Restlänge angegeben.","socratic_question":"Gefragt ist, wie lang die Kerze noch ist – ist das der abgebrannte Teil?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","known_errors":{"9":"falsche_groesse_beantwortet","33":"vorzeichen_ignoriert","+33":"vorzeichen_ignoriert","33 cm":"vorzeichen_ignoriert","33cm":"vorzeichen_ignoriert","+33 cm":"vorzeichen_ignoriert","+33cm":"vorzeichen_ignoriert","+9":"falsche_groesse_beantwortet","9 cm":"falsche_groesse_beantwortet","9cm":"falsche_groesse_beantwortet","+9 cm":"falsche_groesse_beantwortet","+9cm":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '07f970aa-ff64-4158-a713-9943054621a0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '07f970aa-ff64-4158-a713-9943054621a0'::uuid);

-- #25 linfkt-nullstelle-01 · Nullstelle · positive Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '429c8aa1-d937-4231-a778-9a27cde1138c'::uuid, 'exercise', 'Nullstelle · positive Steigung', 'Gegeben ist die Funktion f(x) = 2x - 8.

Berechne die Nullstelle von f.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 2x - 8.\n\nBerechne die Nullstelle von f."}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: f(x) = 0 setzen, zwei Umformungsschritte, Ergebnis ganzzahlig.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, division_vergessen).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '429c8aa1-d937-4231-a778-9a27cde1138c'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => '2x - 8 = 0 | + 8
2x = 8 | : 2
x = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.","socratic_question":"Setze dein Ergebnis in f ein – kommt 0 heraus?"},{"error":"Nach dem ersten Schritt aufgehört: 2x = 8, aber nicht durch 2 geteilt.","socratic_question":"Steht nach deinem letzten Schritt wirklich x allein da?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","known_errors":{"8":"division_vergessen","-4":"betrag_fehler","−4":"betrag_fehler","- 4":"betrag_fehler","+8":"division_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '429c8aa1-d937-4231-a778-9a27cde1138c'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '429c8aa1-d937-4231-a778-9a27cde1138c'::uuid);

-- #26 linfkt-nullstelle-02 · Nullstelle · negative Nullstelle
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7e4040f5-19d5-474f-90d8-633835b9fdde'::uuid, 'exercise', 'Nullstelle · negative Nullstelle', 'Gegeben ist die Funktion f(x) = 3x + 6.

Berechne die Nullstelle von f.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 3x + 6.\n\nBerechne die Nullstelle von f."}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: f(x) = 0 setzen und auflösen, Ergebnis negativ und ganzzahlig.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, division_vergessen, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '7e4040f5-19d5-474f-90d8-633835b9fdde'::uuid,
  p_correct_answers => '["-2","−2","- 2"]'::jsonb,
  p_solution        => '3x + 6 = 0 | - 6
3x = -6 | : 3
x = -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.","socratic_question":"Setze dein Ergebnis in f ein – kommt 0 heraus?"},{"error":"Nach dem ersten Schritt aufgehört: 3x = -6, aber nicht durch 3 geteilt.","socratic_question":"Steht nach deinem letzten Schritt wirklich x allein da?"},{"error":"Den y-Achsenabschnitt statt der Nullstelle angegeben.","socratic_question":"An welcher Achse liegt die Nullstelle?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-2","known_errors":{"2":"betrag_fehler","6":"achsenabschnitt_verwechselt","+2":"betrag_fehler","-6":"division_vergessen","−6":"division_vergessen","- 6":"division_vergessen","+6":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '7e4040f5-19d5-474f-90d8-633835b9fdde'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7e4040f5-19d5-474f-90d8-633835b9fdde'::uuid);

-- #27 linfkt-nullstelle-03 · Nullstelle · negative Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '305c5063-1e7a-4919-a8ba-b97128fc0367'::uuid, 'exercise', 'Nullstelle · negative Steigung', 'Gegeben ist die Funktion f(x) = -4x + 10.

Berechne die Nullstelle von f.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = -4x + 10.\n\nBerechne die Nullstelle von f."}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Division durch einen negativen Koeffizienten, Ergebnis als Dezimalzahl.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_beim_umstellen, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '305c5063-1e7a-4919-a8ba-b97128fc0367'::uuid,
  p_correct_answers => '["2,5","+2,5","2.5","+2.5","5/2","+5/2"]'::jsonb,
  p_solution        => '-4x + 10 = 0 | - 10
-4x = -10 | : (-4)
x = 2,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen.","socratic_question":"Was kommt heraus, wenn du eine negative Zahl durch eine negative Zahl teilst?"},{"error":"Den y-Achsenabschnitt statt der Nullstelle angegeben.","socratic_question":"An welcher Achse liegt die Nullstelle?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,5","known_errors":{"10":"achsenabschnitt_verwechselt","-2,5":"vorzeichen_beim_umstellen","−2,5":"vorzeichen_beim_umstellen","- 2,5":"vorzeichen_beim_umstellen","-2.5":"vorzeichen_beim_umstellen","−2.5":"vorzeichen_beim_umstellen","- 2.5":"vorzeichen_beim_umstellen","+10":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '305c5063-1e7a-4919-a8ba-b97128fc0367'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '305c5063-1e7a-4919-a8ba-b97128fc0367'::uuid);

-- #28 linfkt-nullstelle-04 · Nullstelle · Steigung als Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c291bd8a-ee36-44f4-b195-66c4859f0217'::uuid, 'exercise', 'Nullstelle · Steigung als Dezimalzahl', 'Gegeben ist die Funktion f(x) = 0,5x + 3.

Berechne die Nullstelle von f.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 0,5x + 3.\n\nBerechne die Nullstelle von f."}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Division durch eine Dezimalzahl kleiner als eins, das Ergebnis wird betragsmäßig größer.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rechnen bzw. Ablesen nach festem Verfahren.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, falsche_gegenoperation).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'c291bd8a-ee36-44f4-b195-66c4859f0217'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => '0,5x + 3 = 0 | - 3
0,5x = -3 | : 0,5
x = -6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.","socratic_question":"Setze dein Ergebnis in f ein – kommt 0 heraus?"},{"error":"Mit 0,5 multipliziert statt durch 0,5 geteilt.","socratic_question":"Wie oft passt 0,5 in 3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","known_errors":{"6":"betrag_fehler","+6":"betrag_fehler","-1,5":"falsche_gegenoperation","−1,5":"falsche_gegenoperation","- 1,5":"falsche_gegenoperation","-1.5":"falsche_gegenoperation","−1.5":"falsche_gegenoperation","- 1.5":"falsche_gegenoperation"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'c291bd8a-ee36-44f4-b195-66c4859f0217'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c291bd8a-ee36-44f4-b195-66c4859f0217'::uuid);

-- #29 linfkt-nullstelle-05 · Nullstelle · Sachkontext · Akku leer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4edaa568-3b92-4a89-9105-3551d758e17e'::uuid, 'exercise', 'Nullstelle · Sachkontext · Akku leer', 'Der Ladestand eines Akkus in Prozent nach t Stunden wird durch L(t) = -16t + 80 beschrieben.

Nach wie vielen Stunden ist der Akku leer?',
  '{"kind":"short_input","prompt":"Der Ladestand eines Akkus in Prozent nach t Stunden wird durch L(t) = -16t + 80 beschrieben.\n\nNach wie vielen Stunden ist der Akku leer?"}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  90, 'h', false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: die Frage „leer\" als Nullstelle erkennen und im Sachkontext deuten (Fkt-6/7).","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in Parameter einer linearen Funktion übersetzen und deuten.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (achsenabschnitt_verwechselt, vorzeichen_beim_umstellen).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '4edaa568-3b92-4a89-9105-3551d758e17e'::uuid,
  p_correct_answers => '["5","+5","5 h","5h","+5 h","+5h"]'::jsonb,
  p_solution        => 'Leer heißt L(t) = 0:
-16t + 80 = 0 | - 80
-16t = -80 | : (-16)
t = 5 Stunden.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Anfangswert statt der Nullstelle angegeben.","socratic_question":"Beschreibt 80 den Ladestand am Anfang oder am Ende?"},{"error":"Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen.","socratic_question":"Kann eine Zeitdauer negativ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","known_errors":{"80":"achsenabschnitt_verwechselt","+80":"achsenabschnitt_verwechselt","80 h":"achsenabschnitt_verwechselt","80h":"achsenabschnitt_verwechselt","+80 h":"achsenabschnitt_verwechselt","+80h":"achsenabschnitt_verwechselt","-5":"vorzeichen_beim_umstellen","−5":"vorzeichen_beim_umstellen","- 5":"vorzeichen_beim_umstellen","-5 h":"vorzeichen_beim_umstellen","-5h":"vorzeichen_beim_umstellen","−5 h":"vorzeichen_beim_umstellen","−5h":"vorzeichen_beim_umstellen","- 5 h":"vorzeichen_beim_umstellen","- 5h":"vorzeichen_beim_umstellen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '4edaa568-3b92-4a89-9105-3551d758e17e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4edaa568-3b92-4a89-9105-3551d758e17e'::uuid);

-- #30 linfkt-nullstelle-06 · Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f95fc1f6-7ab9-4a8d-bd97-83bdf1a024bb'::uuid, 'exercise', 'Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle', 'Eine Gerade hat die Steigung 3 und die Nullstelle x = 2.

Bestimme den y-Achsenabschnitt b der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 3 und die Nullstelle x = 2.\n\nBestimme den y-Achsenabschnitt b der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_nullstelle',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen',
  90, null, false, null, 'draft', 'edvance_k8_linfkt', 'linfkt-nullstelle-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Verallgemeinern/Rückrichtung: die Bedingung f(2) = 0 selbst aufstellen und nach dem Parameter b auflösen.","charge":"k8-linfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k8-linfkt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); Thema lineare_funktionen steht im Katalog auf Klasse 8.","charge":"k8-linfkt"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Binom-Reihe und die Gleichungs-Voraussetzungen.","charge":"k8-linfkt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"k8-linfkt"},"competency_process":{"art":"neu","grund":"Rückrichtung: Lösungsweg selbst finden, dann rechnen.","charge":"k8-linfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-linfkt"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen, Bruch/Dezimal und Einheit.","charge":"k8-linfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-linfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, achsenabschnitt_verwechselt).","charge":"k8-linfkt"},"hints":{"art":"leer","grund":"Auftrag W1-1: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-linfkt"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'f95fc1f6-7ab9-4a8d-bd97-83bdf1a024bb'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => 'Die Nullstelle liegt auf der Geraden: f(2) = 0.
3 · 2 + b = 0, also b = -6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Betrag richtig, Vorzeichen gekippt: b = 6 statt -6.","socratic_question":"Setze x = 2 in f(x) = 3x + b mit deinem b ein – kommt 0 heraus?"},{"error":"Die Nullstelle als y-Achsenabschnitt übernommen.","socratic_question":"An welcher Achse liegt die Nullstelle, an welcher der y-Achsenabschnitt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","known_errors":{"2":"achsenabschnitt_verwechselt","6":"betrag_fehler","+6":"betrag_fehler","+2":"achsenabschnitt_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'f95fc1f6-7ab9-4a8d-bd97-83bdf1a024bb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f95fc1f6-7ab9-4a8d-bd97-83bdf1a024bb'::uuid);

commit;
