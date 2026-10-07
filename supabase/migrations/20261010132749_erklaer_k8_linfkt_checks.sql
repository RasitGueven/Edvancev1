-- Erklärsequenzen Lineare Funktionen (E2b), Migration 1 von 2 — 6 Check-Aufgaben, nur Einsatz check.
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
