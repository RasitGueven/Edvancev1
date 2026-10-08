-- Erklärsequenzen Lineare Funktionen (E2b), Migration 1 von 2 — 12 Check-Aufgaben, nur Einsatz check.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/erklaer-k8-linfkt-checks.json (Quelle:
-- tools/erklaer-k8-linfkt/*.mjs und tools/erklaer-k8-linfkt-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: vor der Erklär-Migration (erklaer_check verweist auf diese Aufgaben).
--
-- Je Kernidee zwei Check-Aufgaben (Runde 1 und Runde 2), NUMERIC, mit known_errors, die auf die Varianten der Kernidee zeigen. Keine Hinweise, kein Sondierrang, Einsatz nur check (Entscheidung 28).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/erklaer-k8-linfkt-checks.csv. Pruefprotokoll: docs/prefill/erklaer-k8-linfkt-checks-verifikation.md.
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
--   fkt_linear_steigung: kein Rang: Check-Aufgaben der Erklaersequenz sondieren nie (Einsatz nur check)
--   fkt_linear_yabschnitt: kein Rang: Check-Aufgaben der Erklaersequenz sondieren nie (Einsatz nur check)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 erklaer-steigung-k1-c1 · Check · Steigung am Graphen ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid, 'exercise', 'Check · Steigung am Graphen ablesen', 'Die Abbildung zeigt eine Gerade durch die Punkte A und B.

Bestimme die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt eine Gerade durch die Punkte A und B.\n\nBestimme die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, true, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k1-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Steigung am Gitter abzählen, ganzzahlig, steigende Gerade.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB I, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Ohne Abbildung nicht lösbar (Generator koordinatensystem).","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => 'Von A(-1 | -2) nach B(1 | 6): 2 nach rechts, 8 nach oben.
m = 8 / 2 = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Rüber durch hoch geteilt: 2 / 8 = 1/4.","socratic_question":"Welche Zahl gehört nach oben in den Bruch: die Kästchen nach oben oder nach rechts?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","known_errors":{"1/4":"steigung_kehrwert","+1/4":"steigung_kehrwert","0,25":"steigung_kehrwert","+0,25":"steigung_kehrwert","0.25":"steigung_kehrwert","+0.25":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid, 'koordinatensystem', '{"x_min":-2,"x_max":2,"y_min":-3,"y_max":7,"funktionen":[{"typ":"linear","m":4,"b":2}],"punkte":[{"x":-1,"y":-2,"label":"A"},{"x":1,"y":6,"label":"B"}]}'::jsonb, 'Koordinatensystem mit Gitter und einer steigenden Geraden durch die Punkte A und B.'
 where exists (select 1 from public.tasks t where t.id = '439fc7f8-ec08-40bb-807a-d2df30c5ec73'::uuid and t.source = 'edvance_erklaer_k8_linfkt')
on conflict (task_id) do nothing;

-- #2 erklaer-steigung-k1-c2 · Check · Steigung am Graphen ablesen · Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid, 'exercise', 'Check · Steigung am Graphen ablesen · Bruch', 'In der Abbildung siehst du eine Gerade mit den Punkten A und B.

Wie groß ist die Steigung m dieser Geraden?',
  '{"kind":"short_input","prompt":"In der Abbildung siehst du eine Gerade mit den Punkten A und B.\n\nWie groß ist die Steigung m dieser Geraden?"}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k1-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: am Gitter abzählen, Ergebnis als Bruch bzw. Dezimalzahl.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Ohne Abbildung nicht lösbar (Generator koordinatensystem).","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid,
  p_correct_answers => '["3/2","+3/2","1,5","+1,5","1.5","+1.5"]'::jsonb,
  p_solution        => 'Von A(-2 | -2) nach B(2 | 4): 4 nach rechts, 6 nach oben.
m = 6 / 4 = 3/2 = 1,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Rüber durch hoch geteilt: 4 / 6 = 2/3.","socratic_question":"Welche Zahl gehört nach oben in den Bruch: die Kästchen nach oben oder nach rechts?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"3/2","known_errors":{"2/3":"steigung_kehrwert","+2/3":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid, 'koordinatensystem', '{"x_min":-3,"x_max":3,"y_min":-3,"y_max":5,"funktionen":[{"typ":"linear","m":1.5,"b":1}],"punkte":[{"x":-2,"y":-2,"label":"A"},{"x":2,"y":4,"label":"B"}]}'::jsonb, 'Koordinatensystem mit Gitter und einer steigenden Geraden durch die Punkte A und B.'
 where exists (select 1 from public.tasks t where t.id = '7adc816d-5a5e-4fc2-9515-66c3314096ec'::uuid and t.source = 'edvance_erklaer_k8_linfkt')
on conflict (task_id) do nothing;

-- #3 erklaer-steigung-k2-c1 · Check · Steigung aus zwei Punkten · negative Koordinaten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid, 'exercise', 'Check · Steigung aus zwei Punkten · negative Koordinaten', 'Eine Gerade geht durch die Punkte A(-3 | -2) und B(1 | 4).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(-3 | -2) und B(1 | 4).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k2-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Differenzen mit negativen Koordinaten (Minus vor Minus), Ergebnis als Bruch.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a84e26a2-a6d2-4224-905f-a6a26f9eae56'::uuid,
  p_correct_answers => '["3/2","+3/2","1,5","+1,5","1.5","+1.5"]'::jsonb,
  p_solution        => 'm = (4 - (-2)) / (1 - (-3)) = 6 / 4 = 3/2 = 1,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Oben B minus A, unten A minus B gerechnet: 6 / (-4) = -3/2.","socratic_question":"Hast du oben und unten mit demselben Punkt angefangen?","fehlbild":"seiten_verwechselt"},{"error":"Rüber durch hoch geteilt: 4 / 6 = 2/3.","socratic_question":"Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"3/2","known_errors":{"-3/2":"seiten_verwechselt","−3/2":"seiten_verwechselt","- 3/2":"seiten_verwechselt","-1,5":"seiten_verwechselt","−1,5":"seiten_verwechselt","- 1,5":"seiten_verwechselt","-1.5":"seiten_verwechselt","−1.5":"seiten_verwechselt","- 1.5":"seiten_verwechselt","2/3":"steigung_kehrwert","+2/3":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 erklaer-steigung-k2-c2 · Check · Steigung aus zwei Punkten · fallend
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  'ddb0a7df-2c8b-4c51-84c9-1c1a8e0a05cd'::uuid, 'exercise', 'Check · Steigung aus zwei Punkten · fallend', 'Eine Gerade geht durch die Punkte A(-2 | 4) und B(1 | -5).

Berechne die Steigung m der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade geht durch die Punkte A(-2 | 4) und B(1 | -5).\n\nBerechne die Steigung m der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k2-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: fallende Gerade, Differenzen mit negativen Koordinaten.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ddb0a7df-2c8b-4c51-84c9-1c1a8e0a05cd'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ddb0a7df-2c8b-4c51-84c9-1c1a8e0a05cd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ddb0a7df-2c8b-4c51-84c9-1c1a8e0a05cd'::uuid,
  p_correct_answers => '["-3","−3","- 3"]'::jsonb,
  p_solution        => 'm = (-5 - 4) / (1 - (-2)) = -9 / 3 = -3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Oben B minus A, unten A minus B gerechnet: -9 / (-3) = 3.","socratic_question":"Fällt die Gerade von A nach B oder steigt sie? Passt dein Vorzeichen dazu?","fehlbild":"seiten_verwechselt"},{"error":"Rüber durch hoch geteilt: 3 / (-9) = -1/3.","socratic_question":"Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"-3","known_errors":{"3":"seiten_verwechselt","+3":"seiten_verwechselt","-1/3":"steigung_kehrwert","−1/3":"steigung_kehrwert","- 1/3":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 erklaer-steigung-k3-c1 · Check · Punkt aus Steigung und Punkt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid, 'exercise', 'Check · Punkt aus Steigung und Punkt', 'Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 1).

Welche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 5?',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 1).\n\nWelche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 5?"}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Problemlösen',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k3-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: Schritte zählen, Steigung mehrfach addieren, beim Punkt starten.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '196e845f-909a-4b77-a5c9-45c02428dd4f'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Von x = 2 bis x = 5 sind es 3 Schritte nach rechts.
Jeder Schritt bringt 3 nach oben: 1 + 3 · 3 = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung nur einmal addiert: 1 + 3 = 4.","socratic_question":"Wie viele Schritte nach rechts liegen zwischen x = 2 und x = 5?","fehlbild":"nur_einmal_addiert"},{"error":"Wie bei einer Ursprungsgeraden gerechnet: 3 · 5 = 15.","socratic_question":"Geht die Gerade durch den Ursprung? Prüfe es mit dem Punkt P.","fehlbild":"b_ignoriert"},{"error":"Mit dem Kehrwert der Steigung gerechnet: 1 + 3 · 1/3 = 2.","socratic_question":"Wie viel geht es bei einem Schritt nach rechts nach oben?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","known_errors":{"2":"steigung_kehrwert","4":"nur_einmal_addiert","15":"b_ignoriert","+4":"nur_einmal_addiert","+15":"b_ignoriert","+2":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 erklaer-steigung-k3-c2 · Check · Punkt aus Steigung und Punkt · größere Steigung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid, 'exercise', 'Check · Punkt aus Steigung und Punkt · größere Steigung', 'Eine Gerade hat die Steigung 4 und geht durch den Punkt P(1 | 2).

Welche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 4 und geht durch den Punkt P(1 | 2).\n\nWelche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?"}'::jsonb, 'NUMERIC', 'fkt_linear_steigung',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Problemlösen',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-steigung-k3-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: Schritte zählen, Steigung mehrfach addieren, beim Punkt starten.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'eb9da0e1-e2c6-4e7e-bc06-fc2d42a3931c'::uuid,
  p_correct_answers => '["14","+14"]'::jsonb,
  p_solution        => 'Von x = 1 bis x = 4 sind es 3 Schritte nach rechts.
Jeder Schritt bringt 4 nach oben: 2 + 3 · 4 = 14.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung nur einmal addiert: 2 + 4 = 6.","socratic_question":"Wie viele Schritte nach rechts liegen zwischen x = 1 und x = 4?","fehlbild":"nur_einmal_addiert"},{"error":"Wie bei einer Ursprungsgeraden gerechnet: 4 · 4 = 16.","socratic_question":"Geht die Gerade durch den Ursprung? Prüfe es mit dem Punkt P.","fehlbild":"b_ignoriert"},{"error":"Mit dem Kehrwert der Steigung gerechnet: 2 + 3 · 1/4 = 2,75.","socratic_question":"Wie viel geht es bei einem Schritt nach rechts nach oben?","fehlbild":"steigung_kehrwert"}]'::jsonb,
  p_acceptance      => '{"canonical":"14","known_errors":{"6":"nur_einmal_addiert","16":"b_ignoriert","+6":"nur_einmal_addiert","+16":"b_ignoriert","11/4":"steigung_kehrwert","+11/4":"steigung_kehrwert","2,75":"steigung_kehrwert","+2,75":"steigung_kehrwert","2.75":"steigung_kehrwert","+2.75":"steigung_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 erklaer-yabschnitt-k1-c1 · Check · y-Achsenabschnitt aus der Gleichung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '9a7cc9ef-d806-45b3-b17e-c60364fc2fa3'::uuid, 'exercise', 'Check · y-Achsenabschnitt aus der Gleichung', 'Gegeben ist die Funktion f(x) = -2x + 6.

Gib den y-Achsenabschnitt des Graphen von f an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = -2x + 6.\n\nGib den y-Achsenabschnitt des Graphen von f an."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k1-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: b direkt aus der Normalform ablesen.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB I, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9a7cc9ef-d806-45b3-b17e-c60364fc2fa3'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9a7cc9ef-d806-45b3-b17e-c60364fc2fa3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9a7cc9ef-d806-45b3-b17e-c60364fc2fa3'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => 'Der y-Achsenabschnitt ist die Zahl ohne x: b = 6.
Probe: f(0) = -2 · 0 + 6 = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung -2 angegeben statt b.","socratic_question":"Welche Zahl steht in f(x) = mx + b allein, ohne x?","fehlbild":"m_b_vertauscht"},{"error":"Die Nullstelle angegeben: -2x + 6 = 0 bei x = 3.","socratic_question":"Liegt der y-Achsenabschnitt auf der x-Achse oder auf der y-Achse?","fehlbild":"achsenabschnitt_verwechselt"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","known_errors":{"3":"achsenabschnitt_verwechselt","-2":"m_b_vertauscht","−2":"m_b_vertauscht","- 2":"m_b_vertauscht","+3":"achsenabschnitt_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 erklaer-yabschnitt-k1-c2 · Check · y-Achsenabschnitt · negatives b
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '31b05259-95e6-4f67-a5db-6d75c546029e'::uuid, 'exercise', 'Check · y-Achsenabschnitt · negatives b', 'Gegeben ist die Funktion f(x) = 5x - 4.

An welcher Stelle schneidet der Graph von f die y-Achse? Gib den y-Wert an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 5x - 4.\n\nAn welcher Stelle schneidet der Graph von f die y-Achse? Gib den y-Wert an."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k1-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: b mit Vorzeichen aus der Normalform ablesen.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB I, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '31b05259-95e6-4f67-a5db-6d75c546029e'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '31b05259-95e6-4f67-a5db-6d75c546029e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '31b05259-95e6-4f67-a5db-6d75c546029e'::uuid,
  p_correct_answers => '["-4","−4","- 4"]'::jsonb,
  p_solution        => 'Bei x = 0 fällt 5x weg: f(0) = 5 · 0 - 4 = -4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Steigung 5 angegeben statt b.","socratic_question":"Welche Zahl steht in f(x) = mx + b allein, ohne x?","fehlbild":"m_b_vertauscht"},{"error":"Das Minus von b weggelassen: 4 statt -4.","socratic_question":"Gehört das Minus vor der 4 zu b dazu?","fehlbild":"betrag_fehler"},{"error":"Die Nullstelle angegeben: 5x - 4 = 0 bei x = 0,8.","socratic_question":"Liegt der y-Achsenabschnitt auf der x-Achse oder auf der y-Achse?","fehlbild":"achsenabschnitt_verwechselt"}]'::jsonb,
  p_acceptance      => '{"canonical":"-4","known_errors":{"4":"betrag_fehler","5":"m_b_vertauscht","+5":"m_b_vertauscht","+4":"betrag_fehler","0,8":"achsenabschnitt_verwechselt","+0,8":"achsenabschnitt_verwechselt","0.8":"achsenabschnitt_verwechselt","+0.8":"achsenabschnitt_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 erklaer-yabschnitt-k2-c1 · Check · b aus Steigung und Punkt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '5bb6895e-1e3e-4cc5-8ff5-05424673198c'::uuid, 'exercise', 'Check · b aus Steigung und Punkt', 'Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 5).

Bestimme den y-Achsenabschnitt b der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 5).\n\nBestimme den y-Achsenabschnitt b der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k2-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: b = y - m · x mit einem Punkt, Ergebnis negativ.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5bb6895e-1e3e-4cc5-8ff5-05424673198c'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5bb6895e-1e3e-4cc5-8ff5-05424673198c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5bb6895e-1e3e-4cc5-8ff5-05424673198c'::uuid,
  p_correct_answers => '["-1","−1","- 1"]'::jsonb,
  p_solution        => 'b = 5 - 3 · 2 = 5 - 6 = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Steigung mal x addiert statt abgezogen: 5 + 3 · 2 = 11.","socratic_question":"Gehst du von P zur y-Achse nach rechts oder nach links?","fehlbild":"addiert_statt_subtrahiert"},{"error":"Vorzeichen gekippt: 1 statt -1.","socratic_question":"Liegt der Schnittpunkt mit der y-Achse über oder unter der x-Achse?","fehlbild":"betrag_fehler"}]'::jsonb,
  p_acceptance      => '{"canonical":"-1","known_errors":{"1":"betrag_fehler","11":"addiert_statt_subtrahiert","+11":"addiert_statt_subtrahiert","+1":"betrag_fehler"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 erklaer-yabschnitt-k2-c2 · Check · b aus Steigung und Punkt · fallend
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '8361e4fe-9f16-466e-979b-4b8d36388c4a'::uuid, 'exercise', 'Check · b aus Steigung und Punkt · fallend', 'Eine Gerade hat die Steigung -2 und geht durch den Punkt P(3 | 1).

Bestimme den y-Achsenabschnitt b der Geraden.',
  '{"kind":"short_input","prompt":"Eine Gerade hat die Steigung -2 und geht durch den Punkt P(3 | 1).\n\nBestimme den y-Achsenabschnitt b der Geraden."}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k2-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: b = y - m · x mit negativer Steigung (Minus vor Minus).","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8361e4fe-9f16-466e-979b-4b8d36388c4a'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8361e4fe-9f16-466e-979b-4b8d36388c4a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8361e4fe-9f16-466e-979b-4b8d36388c4a'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => 'b = 1 - (-2) · 3 = 1 + 6 = 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Steigung mal x addiert statt abgezogen: 1 + (-2) · 3 = -5.","socratic_question":"Gehst du von P zur y-Achse nach rechts oder nach links?","fehlbild":"addiert_statt_subtrahiert"},{"error":"Vorzeichen gekippt: -7 statt 7.","socratic_question":"Die Gerade fällt. Liegt sie links von P höher oder tiefer?","fehlbild":"betrag_fehler"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","known_errors":{"-5":"addiert_statt_subtrahiert","−5":"addiert_statt_subtrahiert","- 5":"addiert_statt_subtrahiert","-7":"betrag_fehler","−7":"betrag_fehler","- 7":"betrag_fehler"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 erklaer-yabschnitt-k3-c1 · Check · Startwert im Sachzusammenhang · Taxi
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '7d2e7681-e25f-449b-86ee-879fad3fdd41'::uuid, 'exercise', 'Check · Startwert im Sachzusammenhang · Taxi', 'Ein Taxi berechnet für eine Fahrt von x km den Preis P(x) = 2x + 4 in Euro.

Wie hoch ist die Grundgebühr in Euro?',
  '{"kind":"short_input","prompt":"Ein Taxi berechnet für eine Fahrt von x km den Preis P(x) = 2x + 4 in Euro.\n\nWie hoch ist die Grundgebühr in Euro?"}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k3-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: den Startwert b im Sachzusammenhang deuten.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7d2e7681-e25f-449b-86ee-879fad3fdd41'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7d2e7681-e25f-449b-86ee-879fad3fdd41'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7d2e7681-e25f-449b-86ee-879fad3fdd41'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => 'Die Grundgebühr ist der Preis bei x = 0: P(0) = 2 · 0 + 4 = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Preis pro Kilometer angegeben statt der Grundgebühr.","socratic_question":"Welcher Betrag kommt für jeden Kilometer neu dazu, welcher ist von Anfang an da?","fehlbild":"groessen_vertauscht"},{"error":"Die Nullstelle angegeben: 2x + 4 = 0 bei x = -2.","socratic_question":"Wie viel kostet die Fahrt, bevor ein Kilometer gefahren ist?","fehlbild":"achsenabschnitt_verwechselt"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","known_errors":{"2":"groessen_vertauscht","+2":"groessen_vertauscht","-2":"achsenabschnitt_verwechselt","−2":"achsenabschnitt_verwechselt","- 2":"achsenabschnitt_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 erklaer-yabschnitt-k3-c2 · Check · Startwert im Sachzusammenhang · Kerze
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am, einsatz)
values (
  '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid, 'exercise', 'Check · Startwert im Sachzusammenhang · Kerze', 'Eine Kerze brennt gleichmäßig ab. Ihre Höhe in cm nach x Stunden ist h(x) = -3x + 15.

Wie hoch ist die Kerze zu Beginn, in cm?',
  '{"kind":"short_input","prompt":"Eine Kerze brennt gleichmäßig ab. Ihre Höhe in cm nach x Stunden ist h(x) = -3x + 15.\n\nWie hoch ist die Kerze zu Beginn, in cm?"}'::jsonb, 'NUMERIC', 'fkt_linear_yabschnitt',
  null, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren',
  60, null, false, null, 'draft', 'edvance_erklaer_k8_linfkt', 'erklaer-yabschnitt-k3-c2',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: den Startwert b bei fallender Größe deuten.","charge":"erklaer-k8-linfkt-checks"},"est_duration_sec":{"art":"neu","grund":"Zeitregel wie k8-linfkt: AFB II, kein Sachkontext.","charge":"erklaer-k8-linfkt-checks"},"curriculum_grade":{"art":"neu","grund":"skills.klasse_herkunft = 8 (Bestand, dbread).","charge":"erklaer-k8-linfkt-checks"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.","charge":"erklaer-k8-linfkt-checks"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).","charge":"erklaer-k8-linfkt-checks"},"competency_process":{"art":"neu","grund":"Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.","charge":"erklaer-k8-linfkt-checks"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text.","charge":"erklaer-k8-linfkt-checks"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"erklaer-k8-linfkt-checks"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"erklaer-k8-linfkt-checks"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.","charge":"erklaer-k8-linfkt-checks"},"hints":{"art":"leer","grund":"Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).","charge":"erklaer-k8-linfkt-checks"}}'::jsonb, now(), '{check}'::text[])
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid and t.status = 'draft' and t.source = 'edvance_erklaer_k8_linfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '58e43502-1bd9-43da-a51d-89e129e11a3a'::uuid,
  p_correct_answers => '["15","+15"]'::jsonb,
  p_solution        => 'Zu Beginn ist x = 0: h(0) = -3 · 0 + 15 = 15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Änderung pro Stunde angegeben statt der Anfangshöhe.","socratic_question":"Welche Zahl sagt, wie hoch die Kerze ist, bevor sie brennt?","fehlbild":"groessen_vertauscht"},{"error":"Die Nullstelle angegeben: Nach 5 Stunden ist die Kerze abgebrannt.","socratic_question":"Ist nach dem Anfang oder nach dem Ende gefragt?","fehlbild":"achsenabschnitt_verwechselt"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","known_errors":{"5":"achsenabschnitt_verwechselt","-3":"groessen_vertauscht","−3":"groessen_vertauscht","- 3":"groessen_vertauscht","+5":"achsenabschnitt_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;
