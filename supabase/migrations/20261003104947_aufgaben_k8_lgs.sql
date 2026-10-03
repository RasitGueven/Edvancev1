-- K8 Lineare Gleichungssysteme, Migration 2 von 2 — 30 Aufgaben, je sechs zu den fuenf gleichung_lgs_*-Knoten.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-lgs.json (Quelle: tools/k8-lgs-aufgaben.mjs,
-- tools/k8-lgs-aufgaben-2.mjs und tools/k8-lgs-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003104943_substrat_k8_lgs.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendungen mit steigender Schwierigkeit und zwei mit Sachkontext (Eintritt, Tarife, Mischung, Zahlenrätsel) bzw. Deutung; im Sachknoten alle sechs mit Kontext (vier mit MC-Teil „Welches Gleichungssystem passt?“, zwei selbst aufstellen). Lösungen als MULTI_PART x | y mit known_errors je Teil; Lösungsanzahl (keine/unendlich viele) als MC. Grafisch: zwei Geraden am Generator koordinatensystem. Keine Hinweise, keine Personen.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-lgs.csv. Pruefprotokoll: docs/prefill/k8-lgs-verifikation.md.
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
--   gleichung_lgs_einsetzen: lgs-einsetzen-03 = 1, lgs-einsetzen-04 = 2. Rang 1 aus Profil {division_vergessen,klammer_vergessen}, Rang 2 aus Profil {klammer_vergessen,vorzeichen_beim_umstellen} (1 neue Fehlbilder)
--   gleichung_lgs_gleichsetzen: lgs-gleichsetzen-01 = 1, lgs-gleichsetzen-06 = 2. Rang 1 aus Profil {falsches_vorzeichen_beim_zusammenfuehren,variablen_nicht_zusammengefuehrt}, Rang 2 aus Profil {loesungsanzahl_verwechselt,parallele_uebersehen} (2 neue Fehlbilder)
--   gleichung_lgs_addition: lgs-addition-04 = 1, lgs-addition-06 = 2. Rang 1 aus Profil {nicht_alle_glieder_multipliziert,seiten_ungleich_verknuepft}, Rang 2 aus Profil {loesungsanzahl_verwechselt,parallele_uebersehen} (2 neue Fehlbilder)
--   gleichung_lgs_grafisch: lgs-grafisch-03 = 1, lgs-grafisch-06 = 2. Rang 1 aus Profil {koordinate_vorzeichen_verloren,koordinaten_vertauscht}, Rang 2 aus Profil {loesungsanzahl_verwechselt,parallele_uebersehen} (2 neue Fehlbilder)
--   gleichung_lgs_sachaufgabe: lgs-sach-04 = 1, lgs-sach-03 = 2. Rang 1 aus Profil {bedingung_unvollstaendig,division_vergessen,groessen_vertauscht,variablen_nicht_zusammengefuehrt}, Rang 2 aus Profil {groessen_vertauscht,klammer_falsch_gesetzt,seiten_ungleich_verknuepft} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 lgs-einsetzen-01 · Einsetzungsverfahren · y steht frei · Klammer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '59fc7bef-3dd3-4c74-b0b1-4f2cea3a38d9'::uuid, 'exercise', 'Einsetzungsverfahren · y steht frei · Klammer', 'Löse das Gleichungssystem mit dem Einsetzungsverfahren.

I: y = x + 1
II: 3x + 2y = 17',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: y ist schon freigestellt, Einsetzen mit einer Plusklammer, Ergebnis ganzzahlig.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '59fc7bef-3dd3-4c74-b0b1-4f2cea3a38d9'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '59fc7bef-3dd3-4c74-b0b1-4f2cea3a38d9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '59fc7bef-3dd3-4c74-b0b1-4f2cea3a38d9'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'I in II einsetzen: 3x + 2·(x + 1) = 17
3x + 2x + 2 = 17
5x + 2 = 17 | -2
5x = 15 | :5
x = 3
In I einsetzen: y = 3 + 1 = 4
Lösung: x = 3, y = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer eingesetzt: 3x + 2x + 1 = 17, also 5x = 16 und x = 3,2.","socratic_question":"Womit wird die 2 in 2y multipliziert, wenn du für y den ganzen Term x + 1 einsetzt?"},{"error":"Bei 5x = 15 stehen geblieben und 15 als x genommen.","socratic_question":"Steht in der Zeile 5x = 15 schon x allein auf einer Seite?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","equivalents":["+3"],"known_errors":{"15":"division_vergessen","3,2":"klammer_vergessen","+3,2":"klammer_vergessen","3.2":"klammer_vergessen","+3.2":"klammer_vergessen","+15":"division_vergessen"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"16":"division_vergessen","4,2":"klammer_vergessen","+4,2":"klammer_vergessen","4.2":"klammer_vergessen","+4.2":"klammer_vergessen","+16":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #2 lgs-einsetzen-02 · Einsetzungsverfahren · x steht frei
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '686a3356-9cec-46b5-9625-24e8b3159661'::uuid, 'exercise', 'Einsetzungsverfahren · x steht frei', 'Löse das Gleichungssystem mit dem Einsetzungsverfahren.

I: x = 2y
II: x + 3y = 20',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: x ist freigestellt, Einsetzen ohne Klammer, gleichartige Glieder zusammenfassen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (division_vergessen, falsche_groesse_beantwortet).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '686a3356-9cec-46b5-9625-24e8b3159661'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '686a3356-9cec-46b5-9625-24e8b3159661'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '686a3356-9cec-46b5-9625-24e8b3159661'::uuid,
  p_correct_answers => '{"1":["8","+8"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'I in II einsetzen: 2y + 3y = 20
5y = 20 | :5
y = 4
In I einsetzen: x = 2·4 = 8
Lösung: x = 8, y = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei 5y = 20 stehen geblieben: y = 20 und dann x = 40.","socratic_question":"Was musst du mit 5y = 20 noch tun, damit y allein steht?"},{"error":"Den Wert von y als x angegeben, das Rückeinsetzen in I fehlt.","socratic_question":"Welche Variable hast du mit 5y = 20 berechnet, und wie kommst du jetzt an x?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"8","equivalents":["+8"],"known_errors":{"4":"falsche_groesse_beantwortet","40":"division_vergessen","+40":"division_vergessen","+4":"falsche_groesse_beantwortet"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"20":"division_vergessen","+20":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #3 lgs-einsetzen-03 · Einsetzungsverfahren · Minusklammer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fd5eeb1f-97c2-49a8-ba75-d620da074fc2'::uuid, 'exercise', 'Einsetzungsverfahren · Minusklammer', 'Löse das Gleichungssystem mit dem Einsetzungsverfahren.

I: y = 2x - 3
II: 4x - y = 7',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Einsetzen in ein Minus, die Klammer muss aufgelöst werden (Vorzeichenwechsel).","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fd5eeb1f-97c2-49a8-ba75-d620da074fc2'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fd5eeb1f-97c2-49a8-ba75-d620da074fc2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fd5eeb1f-97c2-49a8-ba75-d620da074fc2'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["1","+1"]}'::jsonb,
  p_solution        => 'I in II einsetzen: 4x - (2x - 3) = 7
4x - 2x + 3 = 7
2x + 3 = 7 | -3
2x = 4 | :2
x = 2
In I einsetzen: y = 2·2 - 3 = 1
Lösung: x = 2, y = 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer eingesetzt: 4x - 2x - 3 = 7, das Minus trifft nur 2x.","socratic_question":"Was wird von 4x abgezogen: nur 2x oder der ganze Term 2x - 3?"},{"error":"Bei 2x = 4 stehen geblieben und 4 als x genommen.","socratic_question":"Steht in 2x = 4 schon x allein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"division_vergessen","5":"klammer_vergessen","+5":"klammer_vergessen","+4":"division_vergessen"}},"2":{"canonical":"1","equivalents":["+1"],"known_errors":{"5":"division_vergessen","7":"klammer_vergessen","+7":"klammer_vergessen","+5":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #4 lgs-einsetzen-04 · Einsetzungsverfahren · erst umstellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '158c874c-248c-40ed-b8b5-af3eb627517a'::uuid, 'exercise', 'Einsetzungsverfahren · erst umstellen', 'Löse das Gleichungssystem mit dem Einsetzungsverfahren. Stelle dazu zuerst Gleichung I nach x um.

I: x + 2y = 11
II: 3x - 4y = 3',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst umstellen, dann einen Term mit zwei Gliedern in eine Klammer einsetzen und ausmultiplizieren.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, vorzeichen_beim_umstellen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '158c874c-248c-40ed-b8b5-af3eb627517a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '158c874c-248c-40ed-b8b5-af3eb627517a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '158c874c-248c-40ed-b8b5-af3eb627517a'::uuid,
  p_correct_answers => '{"1":["5","+5"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'I nach x umstellen: x = 11 - 2y
In II einsetzen: 3·(11 - 2y) - 4y = 3
33 - 6y - 4y = 3
33 - 10y = 3 | -33
-10y = -30 | :(-10)
y = 3
In I einsetzen: x = 11 - 2·3 = 5
Lösung: x = 5, y = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer eingesetzt: 3·11 - 2y - 4y = 3, die 3 trifft nur die 11.","socratic_question":"Womit wird die 3 multipliziert, wenn du für x den Term 11 - 2y einsetzt?"},{"error":"Bei -10y = -30 das Minus am Ergebnis gelassen: y = -3.","socratic_question":"Was ergibt eine negative Zahl geteilt durch eine negative Zahl?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"5","equivalents":["+5"],"known_errors":{"1":"klammer_vergessen","17":"vorzeichen_beim_umstellen","+1":"klammer_vergessen","+17":"vorzeichen_beim_umstellen"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"5":"klammer_vergessen","+5":"klammer_vergessen","-3":"vorzeichen_beim_umstellen","−3":"vorzeichen_beim_umstellen","- 3":"vorzeichen_beim_umstellen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #5 lgs-einsetzen-05 · Einsetzungsverfahren · Sachkontext · Kinokarten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6ffa3e34-6e9c-4b46-b615-0ea96683fa4f'::uuid, 'exercise', 'Einsetzungsverfahren · Sachkontext · Kinokarten', 'Ein Kino verkauft an einem Nachmittag 50 Karten. Eine Kinderkarte kostet 6 €, eine Erwachsenenkarte 9 €. Zusammen nimmt das Kino 360 € ein.

Stelle ein Gleichungssystem auf (x: Anzahl der Kinderkarten, y: Anzahl der Erwachsenenkarten) und löse es mit dem Einsetzungsverfahren.',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Anzahl der Kinderkarten: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Anzahl der Erwachsenenkarten: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Bedingungen aus dem Text als Gleichungen aufstellen, dann einsetzen mit Klammer.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, klammer_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6ffa3e34-6e9c-4b46-b615-0ea96683fa4f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6ffa3e34-6e9c-4b46-b615-0ea96683fa4f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6ffa3e34-6e9c-4b46-b615-0ea96683fa4f'::uuid,
  p_correct_answers => '{"1":["30","+30"],"2":["20","+20"]}'::jsonb,
  p_solution        => 'I: x + y = 50 (Anzahl der Karten)
II: 6x + 9y = 360 (Einnahmen in €)
I nach x umstellen: x = 50 - y
In II einsetzen: 6·(50 - y) + 9y = 360
300 - 6y + 9y = 360
300 + 3y = 360 | -300
3y = 60 | :3
y = 20
x = 50 - 20 = 30
Lösung: x = 30 Kinderkarten, y = 20 Erwachsenenkarten.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Preise vertauscht: 9x + 6y = 360 statt 6x + 9y = 360.","socratic_question":"Welcher Preis gehört zu x, der Anzahl der Kinderkarten?"},{"error":"Ohne Klammer eingesetzt: 6·50 - y + 9y = 360, die 6 trifft nur die 50.","socratic_question":"Womit wird die 6 multipliziert, wenn du für x den Term 50 - y einsetzt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"30","equivalents":["+30"],"known_errors":{"20":"groessen_vertauscht","+20":"groessen_vertauscht","42,5":"klammer_vergessen","+42,5":"klammer_vergessen","42.5":"klammer_vergessen","+42.5":"klammer_vergessen"}},"2":{"canonical":"20","equivalents":["+20"],"known_errors":{"30":"groessen_vertauscht","+30":"groessen_vertauscht","7,5":"klammer_vergessen","+7,5":"klammer_vergessen","7.5":"klammer_vergessen","+7.5":"klammer_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #6 lgs-einsetzen-06 · Einsetzungsverfahren · Zahlenrätsel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8ccd8989-eb3b-4954-bcb6-5bd202d6710e'::uuid, 'exercise', 'Einsetzungsverfahren · Zahlenrätsel', 'Von zwei Zahlen ist die erste um 6 größer als die zweite. Das Doppelte der ersten Zahl und die zweite Zahl ergeben zusammen 36.

Bestimme beide Zahlen mit dem Einsetzungsverfahren (x: erste Zahl, y: zweite Zahl).',
  null, 'MULTI_PART', 'gleichung_lgs_einsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-einsetzen-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"erste Zahl: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"zweite Zahl: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zahlenrätsel in zwei Gleichungen übersetzen, „um 6 größer“ richtig zuordnen, mit Klammer einsetzen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, groessen_vertauscht).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8ccd8989-eb3b-4954-bcb6-5bd202d6710e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8ccd8989-eb3b-4954-bcb6-5bd202d6710e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8ccd8989-eb3b-4954-bcb6-5bd202d6710e'::uuid,
  p_correct_answers => '{"1":["14","+14"],"2":["8","+8"]}'::jsonb,
  p_solution        => 'I: x = y + 6
II: 2x + y = 36
I in II einsetzen: 2·(y + 6) + y = 36
2y + 12 + y = 36
3y + 12 = 36 | -12
3y = 24 | :3
y = 8
x = 8 + 6 = 14
Lösung: x = 14, y = 8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer eingesetzt: 2y + 6 + y = 36, die 2 trifft nur das y.","socratic_question":"Was wird verdoppelt: nur y oder die ganze erste Zahl y + 6?"},{"error":"Die zweite Zahl um 6 größer gemacht: y = x + 6 statt x = y + 6.","socratic_question":"Welche der beiden Zahlen ist die größere?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"14","equivalents":["+14"],"known_errors":{"10":"groessen_vertauscht","16":"klammer_vergessen","+16":"klammer_vergessen","+10":"groessen_vertauscht"}},"2":{"canonical":"8","equivalents":["+8"],"known_errors":{"10":"klammer_vergessen","16":"groessen_vertauscht","+10":"klammer_vergessen","+16":"groessen_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #7 lgs-gleichsetzen-01 · Gleichsetzungsverfahren · beide nach y aufgelöst
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5b073ffe-951e-4339-bceb-fefd24b204e4'::uuid, 'exercise', 'Gleichsetzungsverfahren · beide nach y aufgelöst', 'Löse das Gleichungssystem mit dem Gleichsetzungsverfahren.

I: y = 2x + 1
II: y = x + 4',
  null, 'MULTI_PART', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: beide Gleichungen nach y aufgelöst, positive Koeffizienten, ganzzahlige Lösung.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (variablen_nicht_zusammengefuehrt, falsches_vorzeichen_beim_zusammenfuehren).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5b073ffe-951e-4339-bceb-fefd24b204e4'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5b073ffe-951e-4339-bceb-fefd24b204e4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5b073ffe-951e-4339-bceb-fefd24b204e4'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["7","+7"]}'::jsonb,
  p_solution        => 'Gleichsetzen: 2x + 1 = x + 4 | -x
x + 1 = 4 | -1
x = 3
In II einsetzen: y = 3 + 4 = 7
Lösung: x = 3, y = 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das x auf der rechten Seite nicht abgezogen und durch 2 geteilt: x = 3 : 2 = 1,5.","socratic_question":"Auf welchen Seiten steht x? Wie bringst du alle x auf eine Seite?"},{"error":"Die 1 addiert statt abgezogen: x = 4 + 1 = 5.","socratic_question":"Wie bekommst du die +1 von der linken Seite weg?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","equivalents":["+3"],"known_errors":{"5":"falsches_vorzeichen_beim_zusammenfuehren","1,5":"variablen_nicht_zusammengefuehrt","+1,5":"variablen_nicht_zusammengefuehrt","1.5":"variablen_nicht_zusammengefuehrt","+1.5":"variablen_nicht_zusammengefuehrt","+5":"falsches_vorzeichen_beim_zusammenfuehren"}},"2":{"canonical":"7","equivalents":["+7"],"known_errors":{"4":"variablen_nicht_zusammengefuehrt","9":"falsches_vorzeichen_beim_zusammenfuehren","+4":"variablen_nicht_zusammengefuehrt","+9":"falsches_vorzeichen_beim_zusammenfuehren"}}}'::jsonb);
  end if;
end
$loesung$;

-- #8 lgs-gleichsetzen-02 · Gleichsetzungsverfahren · Konstante mit Minus
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0a8987a7-5605-43d6-b24b-16436d3d8096'::uuid, 'exercise', 'Gleichsetzungsverfahren · Konstante mit Minus', 'Löse das Gleichungssystem mit dem Gleichsetzungsverfahren.

I: y = 3x - 2
II: y = x + 6',
  null, 'MULTI_PART', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: beide nach y aufgelöst, eine negative Konstante, ganzzahlige Lösung.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsches_vorzeichen_beim_zusammenfuehren, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0a8987a7-5605-43d6-b24b-16436d3d8096'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0a8987a7-5605-43d6-b24b-16436d3d8096'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0a8987a7-5605-43d6-b24b-16436d3d8096'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["10","+10"]}'::jsonb,
  p_solution        => 'Gleichsetzen: 3x - 2 = x + 6 | -x
2x - 2 = 6 | +2
2x = 8 | :2
x = 4
In II einsetzen: y = 4 + 6 = 10
Lösung: x = 4, y = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die -2 falsch herübergebracht: 2x = 6 - 2 = 4 statt 2x = 6 + 2 = 8.","socratic_question":"Mit welcher Rechnung verschwindet die -2 auf der linken Seite?"},{"error":"Bei 2x = 8 stehen geblieben und 8 als x genommen.","socratic_question":"Steht in 2x = 8 schon x allein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"2":"falsches_vorzeichen_beim_zusammenfuehren","8":"division_vergessen","+2":"falsches_vorzeichen_beim_zusammenfuehren","+8":"division_vergessen"}},"2":{"canonical":"10","equivalents":["+10"],"known_errors":{"8":"falsches_vorzeichen_beim_zusammenfuehren","14":"division_vergessen","+8":"falsches_vorzeichen_beim_zusammenfuehren","+14":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #9 lgs-gleichsetzen-03 · Gleichsetzungsverfahren · negativer Koeffizient
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f028a616-4848-4839-86c5-b8520f6a0e15'::uuid, 'exercise', 'Gleichsetzungsverfahren · negativer Koeffizient', 'Löse das Gleichungssystem mit dem Gleichsetzungsverfahren.

I: y = -2x + 7
II: y = x - 5',
  null, 'MULTI_PART', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negativer Koeffizient, Division durch eine negative Zahl, negatives y.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_beim_umstellen, variablen_nicht_zusammengefuehrt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f028a616-4848-4839-86c5-b8520f6a0e15'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f028a616-4848-4839-86c5-b8520f6a0e15'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f028a616-4848-4839-86c5-b8520f6a0e15'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["-1","−1","- 1"]}'::jsonb,
  p_solution        => 'Gleichsetzen: -2x + 7 = x - 5 | -x
-3x + 7 = -5 | -7
-3x = -12 | :(-3)
x = 4
In II einsetzen: y = 4 - 5 = -1
Lösung: x = 4, y = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei -3x = -12 das Minus am Ergebnis gelassen: x = -4.","socratic_question":"Was ergibt -12 geteilt durch -3?"},{"error":"Nur durch den linken Koeffizienten -2 geteilt, das x von rechts nicht abgezogen.","socratic_question":"Wie viele x stehen links, nachdem du das x von der rechten Seite herübergebracht hast?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"6":"variablen_nicht_zusammengefuehrt","-4":"vorzeichen_beim_umstellen","−4":"vorzeichen_beim_umstellen","- 4":"vorzeichen_beim_umstellen","+6":"variablen_nicht_zusammengefuehrt"}},"2":{"canonical":"-1","equivalents":["−1","- 1"],"known_errors":{"1":"variablen_nicht_zusammengefuehrt","-9":"vorzeichen_beim_umstellen","−9":"vorzeichen_beim_umstellen","- 9":"vorzeichen_beim_umstellen","+1":"variablen_nicht_zusammengefuehrt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #10 lgs-gleichsetzen-04 · Gleichsetzungsverfahren · erst nach y auflösen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2d1d05f3-9234-4580-ac86-76776714e9c1'::uuid, 'exercise', 'Gleichsetzungsverfahren · erst nach y auflösen', 'Löse das Gleichungssystem mit dem Gleichsetzungsverfahren. Löse dazu zuerst beide Gleichungen nach y auf.

I: x + y = 5
II: 2x - y = 4',
  null, 'MULTI_PART', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: beide Gleichungen erst nach y umstellen (II mit -y), dann gleichsetzen, negativer Koeffizient.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_beim_umstellen, variablen_nicht_zusammengefuehrt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2d1d05f3-9234-4580-ac86-76776714e9c1'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2d1d05f3-9234-4580-ac86-76776714e9c1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2d1d05f3-9234-4580-ac86-76776714e9c1'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'I nach y: y = -x + 5
II nach y: -y = -2x + 4, also y = 2x - 4
Gleichsetzen: -x + 5 = 2x - 4 | -2x
-3x + 5 = -4 | -5
-3x = -9 | :(-3)
x = 3
In I einsetzen: y = -3 + 5 = 2
Lösung: x = 3, y = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei -3x = -9 das Minus am Ergebnis gelassen: x = -3.","socratic_question":"Welches Vorzeichen hat der Quotient zweier negativer Zahlen?"},{"error":"Nur durch den linken Koeffizienten -1 geteilt, das 2x von rechts nicht herübergebracht.","socratic_question":"Stehen nach deinem Schritt alle x auf einer Seite?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","equivalents":["+3"],"known_errors":{"9":"variablen_nicht_zusammengefuehrt","-3":"vorzeichen_beim_umstellen","−3":"vorzeichen_beim_umstellen","- 3":"vorzeichen_beim_umstellen","+9":"variablen_nicht_zusammengefuehrt"}},"2":{"canonical":"2","equivalents":["+2"],"known_errors":{"8":"vorzeichen_beim_umstellen","+8":"vorzeichen_beim_umstellen","-4":"variablen_nicht_zusammengefuehrt","−4":"variablen_nicht_zusammengefuehrt","- 4":"variablen_nicht_zusammengefuehrt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #11 lgs-gleichsetzen-05 · Gleichsetzungsverfahren · Sachkontext · zwei Tarife
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4d293e0f-925f-4025-8b92-7c8a6236e2bb'::uuid, 'exercise', 'Gleichsetzungsverfahren · Sachkontext · zwei Tarife', 'Ein Fahrradverleih bietet zwei Tarife an. Tarif A: 5 € Grundgebühr und 2 € je Stunde. Tarif B: 11 € Grundgebühr und 1 € je Stunde.

Bei welcher Leihdauer kosten beide Tarife gleich viel, und wie viel kostet es dann? Stelle für jeden Tarif eine Gleichung auf (x: Leihdauer in Stunden, y: Kosten in €) und löse mit dem Gleichsetzungsverfahren.',
  null, 'MULTI_PART', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Leihdauer in Stunden: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Kosten in €: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Tarife als Gleichungen y = mx + b aufstellen, gleichsetzen, Ergebnis im Kontext deuten.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (variablen_nicht_zusammengefuehrt, falsches_vorzeichen_beim_zusammenfuehren).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4d293e0f-925f-4025-8b92-7c8a6236e2bb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4d293e0f-925f-4025-8b92-7c8a6236e2bb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4d293e0f-925f-4025-8b92-7c8a6236e2bb'::uuid,
  p_correct_answers => '{"1":["6","+6"],"2":["17","+17","17 €","17€","+17 €","+17€"]}'::jsonb,
  p_solution        => 'Tarif A: y = 2x + 5
Tarif B: y = x + 11
Gleichsetzen: 2x + 5 = x + 11 | -x
x + 5 = 11 | -5
x = 6
In B einsetzen: y = 6 + 11 = 17
Nach 6 Stunden kosten beide Tarife 17 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das x von Tarif B nicht abgezogen und durch 2 geteilt: x = 6 : 2 = 3.","socratic_question":"Auf welchen Seiten der Gleichung 2x + 5 = x + 11 steht x?"},{"error":"Die 5 addiert statt abgezogen: x = 11 + 5 = 16.","socratic_question":"Wie bekommst du die +5 von der linken Seite weg?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"6","equivalents":["+6"],"known_errors":{"3":"variablen_nicht_zusammengefuehrt","16":"falsches_vorzeichen_beim_zusammenfuehren","+3":"variablen_nicht_zusammengefuehrt","+16":"falsches_vorzeichen_beim_zusammenfuehren"}},"2":{"canonical":"17","equivalents":["+17","17 €","17€","+17 €","+17€"],"known_errors":{"11":"variablen_nicht_zusammengefuehrt","27":"falsches_vorzeichen_beim_zusammenfuehren","+11":"variablen_nicht_zusammengefuehrt","11 €":"variablen_nicht_zusammengefuehrt","11€":"variablen_nicht_zusammengefuehrt","+11 €":"variablen_nicht_zusammengefuehrt","+11€":"variablen_nicht_zusammengefuehrt","+27":"falsches_vorzeichen_beim_zusammenfuehren","27 €":"falsches_vorzeichen_beim_zusammenfuehren","27€":"falsches_vorzeichen_beim_zusammenfuehren","+27 €":"falsches_vorzeichen_beim_zusammenfuehren","+27€":"falsches_vorzeichen_beim_zusammenfuehren"}}}'::jsonb);
  end if;
end
$loesung$;

-- #12 lgs-gleichsetzen-06 · Gleichsetzungsverfahren · Sachkontext · gleiche Stundenpreise
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '341951eb-c62b-414a-aedf-c86e61d27bf5'::uuid, 'exercise', 'Gleichsetzungsverfahren · Sachkontext · gleiche Stundenpreise', 'Ein Kletterpark bietet zwei Tarife an. Tarif A: 4 € Grundgebühr und 2 € je Stunde. Tarif B: 6 € Grundgebühr und 2 € je Stunde.

Mit x = Stunden und y = Kosten in € gilt:
I: y = 2x + 4
II: y = 2x + 6

Wie viele Lösungen hat das Gleichungssystem? Nutze das Gleichsetzungsverfahren.',
  '{"options":[{"id":"a","label":"genau eine Lösung"},{"id":"b","label":"keine Lösung"},{"id":"c","label":"unendlich viele Lösungen"}],"input_type":"MC"}'::jsonb, 'MC', 'gleichung_lgs_gleichsetzen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Argumentieren',
  90, null, false, 2, 'draft', 'edvance_k8_lgs', 'lgs-gleichsetzen-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden und deuten: Gleichsetzen endet mit einer falschen Aussage, daraus die Lösungsanzahl schließen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösungsanzahl aus Rechnung oder Lage der Geraden begründen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"correct_answers":{"art":"neu","grund":"Lösungsanzahl aus dem Koeffizientensystem nachgerechnet (Determinante, Verträglichkeit).","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (parallele_uebersehen, loesungsanzahl_verwechselt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '341951eb-c62b-414a-aedf-c86e61d27bf5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '341951eb-c62b-414a-aedf-c86e61d27bf5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '341951eb-c62b-414a-aedf-c86e61d27bf5'::uuid,
  p_correct_answers => '["b"]'::jsonb,
  p_solution        => 'Gleichsetzen: 2x + 4 = 2x + 6 | -2x
4 = 6
Das ist eine falsche Aussage, für kein x erfüllt.
Das Gleichungssystem hat keine Lösung: Tarif B ist immer 2 € teurer, die Geraden sind parallel.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Genau eine Lösung angenommen, obwohl beide Tarife denselben Stundenpreis haben.","socratic_question":"Wie groß ist der Preisunterschied nach einer, nach zwei, nach zehn Stunden?"},{"error":"Die falsche Aussage 4 = 6 als „unendlich viele Lösungen“ gelesen.","socratic_question":"Gibt es eine Stundenzahl, für die 4 = 6 stimmt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"b","known_errors":{"a":"parallele_uebersehen","c":"loesungsanzahl_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 lgs-addition-01 · Additionsverfahren · y fällt direkt weg
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '04167489-16b6-4f8e-bd85-5aff2f8433a9'::uuid, 'exercise', 'Additionsverfahren · y fällt direkt weg', 'Löse das Gleichungssystem mit dem Additionsverfahren.

I: x + 2y = 12
II: x - 2y = 4',
  null, 'MULTI_PART', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-addition-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Addieren genügt, y fällt sofort weg, ganzzahlige Lösung.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (seiten_ungleich_verknuepft, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '04167489-16b6-4f8e-bd85-5aff2f8433a9'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '04167489-16b6-4f8e-bd85-5aff2f8433a9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '04167489-16b6-4f8e-bd85-5aff2f8433a9'::uuid,
  p_correct_answers => '{"1":["8","+8"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'I + II: (x + 2y) + (x - 2y) = 12 + 4
2x = 16 | :2
x = 8
In I einsetzen: 8 + 2y = 12 | -8
2y = 4 | :2
y = 2
Lösung: x = 8, y = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Links addiert, rechts subtrahiert: 2x = 12 - 4 = 8.","socratic_question":"Hast du links und rechts dieselbe Rechenart benutzt?"},{"error":"Bei 2x = 16 stehen geblieben und 16 als x genommen.","socratic_question":"Steht in 2x = 16 schon x allein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"8","equivalents":["+8"],"known_errors":{"4":"seiten_ungleich_verknuepft","16":"division_vergessen","+4":"seiten_ungleich_verknuepft","+16":"division_vergessen"}},"2":{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"seiten_ungleich_verknuepft","+4":"seiten_ungleich_verknuepft","-2":"division_vergessen","−2":"division_vergessen","- 2":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #14 lgs-addition-02 · Additionsverfahren · negative rechte Seite
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8a6667f5-f069-4df5-8411-c4533e44b757'::uuid, 'exercise', 'Additionsverfahren · negative rechte Seite', 'Löse das Gleichungssystem mit dem Additionsverfahren.

I: 3x + 2y = 18
II: x - 2y = -2',
  null, 'MULTI_PART', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-addition-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Addieren genügt, rechts wird eine negative Zahl addiert.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (seiten_ungleich_verknuepft, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8a6667f5-f069-4df5-8411-c4533e44b757'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8a6667f5-f069-4df5-8411-c4533e44b757'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8a6667f5-f069-4df5-8411-c4533e44b757'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'I + II: 4x = 18 + (-2) = 16 | :4
x = 4
In I einsetzen: 12 + 2y = 18 | -12
2y = 6 | :2
y = 3
Lösung: x = 4, y = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Links addiert, rechts subtrahiert: 4x = 18 - (-2) = 20.","socratic_question":"Wenn du links die Gleichungen addierst, was musst du dann rechts mit 18 und -2 tun?"},{"error":"Bei 4x = 16 stehen geblieben und 16 als x genommen.","socratic_question":"Steht in 4x = 16 schon x allein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"5":"seiten_ungleich_verknuepft","16":"division_vergessen","+5":"seiten_ungleich_verknuepft","+16":"division_vergessen"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"1,5":"seiten_ungleich_verknuepft","+1,5":"seiten_ungleich_verknuepft","1.5":"seiten_ungleich_verknuepft","+1.5":"seiten_ungleich_verknuepft","-15":"division_vergessen","−15":"division_vergessen","- 15":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #15 lgs-addition-03 · Additionsverfahren · eine Gleichung mal Faktor
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b0a46ab7-8546-455a-af17-41d97b6da549'::uuid, 'exercise', 'Additionsverfahren · eine Gleichung mal Faktor', 'Löse das Gleichungssystem mit dem Additionsverfahren. Multipliziere dazu Gleichung II mit 2.

I: 2x + 3y = 13
II: x + y = 5',
  null, 'MULTI_PART', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-addition-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: eine Gleichung mit einem Faktor multiplizieren, dann subtrahieren.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösen nach festem Verfahren.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nicht_alle_glieder_multipliziert, seiten_ungleich_verknuepft).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b0a46ab7-8546-455a-af17-41d97b6da549'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b0a46ab7-8546-455a-af17-41d97b6da549'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b0a46ab7-8546-455a-af17-41d97b6da549'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'II · 2: 2x + 2y = 10
I - 2·II: (2x + 3y) - (2x + 2y) = 13 - 10
y = 3
In II einsetzen: x + 3 = 5 | -3
x = 2
Lösung: x = 2, y = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Beim Multiplizieren die rechte Seite vergessen: 2x + 2y = 5 statt 10.","socratic_question":"Hast du nach dem Malnehmen mit 2 jedes Glied der Gleichung II verdoppelt, auch die 5?"},{"error":"Links subtrahiert, rechts addiert: y = 13 + 10 = 23.","socratic_question":"Welche Rechenart hast du links benutzt, welche rechts?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"-3":"nicht_alle_glieder_multipliziert","−3":"nicht_alle_glieder_multipliziert","- 3":"nicht_alle_glieder_multipliziert","-18":"seiten_ungleich_verknuepft","−18":"seiten_ungleich_verknuepft","- 18":"seiten_ungleich_verknuepft"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"8":"nicht_alle_glieder_multipliziert","23":"seiten_ungleich_verknuepft","+8":"nicht_alle_glieder_multipliziert","+23":"seiten_ungleich_verknuepft"}}}'::jsonb);
  end if;
end
$loesung$;

-- #16 lgs-addition-04 · Additionsverfahren · Faktor selbst finden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ca914e37-5069-4fe6-bbec-d3965feca69a'::uuid, 'exercise', 'Additionsverfahren · Faktor selbst finden', 'Löse das Gleichungssystem mit dem Additionsverfahren. Multipliziere dazu eine Gleichung mit einer passenden Zahl.

I: 4x + 3y = 5
II: 2x - y = 5',
  null, 'MULTI_PART', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Problemlösen',
  60, null, false, 1, 'draft', 'edvance_k8_lgs', 'lgs-addition-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: den Faktor selbst wählen (II mal 3), negativer Koeffizient, negatives y.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Rechenweg (Faktor) selbst finden, dann lösen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nicht_alle_glieder_multipliziert, seiten_ungleich_verknuepft).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ca914e37-5069-4fe6-bbec-d3965feca69a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ca914e37-5069-4fe6-bbec-d3965feca69a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ca914e37-5069-4fe6-bbec-d3965feca69a'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["-1","−1","- 1"]}'::jsonb,
  p_solution        => 'II · 3: 6x - 3y = 15
I + 3·II: (4x + 3y) + (6x - 3y) = 5 + 15
10x = 20 | :10
x = 2
In II einsetzen: 2·2 - y = 5, also y = 4 - 5 = -1
Lösung: x = 2, y = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Beim Multiplizieren die rechte Seite vergessen: 6x - 3y = 5 statt 15.","socratic_question":"Hast du nach dem Malnehmen mit 3 auch die rechte Seite von II verdreifacht?"},{"error":"Links addiert, rechts subtrahiert: 10x = 5 - 15 = -10.","socratic_question":"Hast du die rechten Seiten genauso verknüpft wie die linken?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"1":"nicht_alle_glieder_multipliziert","+1":"nicht_alle_glieder_multipliziert","-1":"seiten_ungleich_verknuepft","−1":"seiten_ungleich_verknuepft","- 1":"seiten_ungleich_verknuepft"}},"2":{"canonical":"-1","equivalents":["−1","- 1"],"known_errors":{"-3":"nicht_alle_glieder_multipliziert","−3":"nicht_alle_glieder_multipliziert","- 3":"nicht_alle_glieder_multipliziert","-7":"seiten_ungleich_verknuepft","−7":"seiten_ungleich_verknuepft","- 7":"seiten_ungleich_verknuepft"}}}'::jsonb);
  end if;
end
$loesung$;

-- #17 lgs-addition-05 · Additionsverfahren · Sachkontext · Eintrittspreise
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5fcdd8c8-f87d-4b0a-b5d3-6207fb130eeb'::uuid, 'exercise', 'Additionsverfahren · Sachkontext · Eintrittspreise', 'In einem Museum zahlen 2 Erwachsene und 3 Kinder zusammen 34 € Eintritt. 1 Erwachsener und 2 Kinder zahlen zusammen 20 €.

Wie viel kostet eine Karte für Erwachsene und wie viel eine Karte für Kinder? Stelle ein Gleichungssystem auf (x: Preis für Erwachsene, y: Preis für Kinder, in €) und löse es mit dem Additionsverfahren.',
  null, 'MULTI_PART', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-addition-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Preis für Erwachsene in €: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Preis für Kinder in €: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Preisangaben als Gleichungen aufstellen, eine Gleichung mit 2 multiplizieren und subtrahieren.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, nicht_alle_glieder_multipliziert).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5fcdd8c8-f87d-4b0a-b5d3-6207fb130eeb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5fcdd8c8-f87d-4b0a-b5d3-6207fb130eeb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5fcdd8c8-f87d-4b0a-b5d3-6207fb130eeb'::uuid,
  p_correct_answers => '{"1":["8","+8","8 €","8€","+8 €","+8€"],"2":["6","+6","6 €","6€","+6 €","+6€"]}'::jsonb,
  p_solution        => 'I: 2x + 3y = 34
II: x + 2y = 20
II · 2: 2x + 4y = 40
2·II - I: (2x + 4y) - (2x + 3y) = 40 - 34
y = 6
In II einsetzen: x + 12 = 20, also x = 8
Eine Karte für Erwachsene kostet 8 €, für Kinder 6 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Erwachsene und Kinder beim Aufstellen vertauscht: 3x + 2y = 34 und 2x + y = 20.","socratic_question":"Zu welcher Variablen gehört die Anzahl der Erwachsenen in der ersten Angabe?"},{"error":"Beim Multiplizieren die rechte Seite vergessen: 2x + 4y = 20 statt 40.","socratic_question":"Hast du beim Verdoppeln von II auch die 20 verdoppelt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"8","equivalents":["+8","8 €","8€","+8 €","+8€"],"known_errors":{"6":"groessen_vertauscht","48":"nicht_alle_glieder_multipliziert","+6":"groessen_vertauscht","6 €":"groessen_vertauscht","6€":"groessen_vertauscht","+6 €":"groessen_vertauscht","+6€":"groessen_vertauscht","+48":"nicht_alle_glieder_multipliziert","48 €":"nicht_alle_glieder_multipliziert","48€":"nicht_alle_glieder_multipliziert","+48 €":"nicht_alle_glieder_multipliziert","+48€":"nicht_alle_glieder_multipliziert"}},"2":{"canonical":"6","equivalents":["+6","6 €","6€","+6 €","+6€"],"known_errors":{"8":"groessen_vertauscht","+8":"groessen_vertauscht","8 €":"groessen_vertauscht","8€":"groessen_vertauscht","+8 €":"groessen_vertauscht","+8€":"groessen_vertauscht","-14":"nicht_alle_glieder_multipliziert","−14":"nicht_alle_glieder_multipliziert","- 14":"nicht_alle_glieder_multipliziert","-14 €":"nicht_alle_glieder_multipliziert","-14€":"nicht_alle_glieder_multipliziert","−14 €":"nicht_alle_glieder_multipliziert","−14€":"nicht_alle_glieder_multipliziert","- 14 €":"nicht_alle_glieder_multipliziert","- 14€":"nicht_alle_glieder_multipliziert"}}}'::jsonb);
  end if;
end
$loesung$;

-- #18 lgs-addition-06 · Additionsverfahren · Sachkontext · Vielfaches
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ffd185a0-239d-4e19-8600-87934606fffc'::uuid, 'exercise', 'Additionsverfahren · Sachkontext · Vielfaches', 'In einem Schreibwarenladen kosten 2 Hefte und 3 Stifte zusammen 7 €. 4 Hefte und 6 Stifte kosten zusammen 14 €.

Mit x = Preis eines Heftes und y = Preis eines Stiftes (in €) gilt:
I: 2x + 3y = 7
II: 4x + 6y = 14

Wie viele Lösungen hat das Gleichungssystem? Nutze das Additionsverfahren.',
  '{"options":[{"id":"a","label":"genau eine Lösung"},{"id":"b","label":"keine Lösung"},{"id":"c","label":"unendlich viele Lösungen"}],"input_type":"MC"}'::jsonb, 'MC', 'gleichung_lgs_addition',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Argumentieren',
  90, null, false, 2, 'draft', 'edvance_k8_lgs', 'lgs-addition-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden und deuten: Das Verfahren endet mit einer wahren Aussage, daraus die Lösungsanzahl schließen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösungsanzahl aus Rechnung oder Lage der Geraden begründen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"correct_answers":{"art":"neu","grund":"Lösungsanzahl aus dem Koeffizientensystem nachgerechnet (Determinante, Verträglichkeit).","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (parallele_uebersehen, loesungsanzahl_verwechselt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ffd185a0-239d-4e19-8600-87934606fffc'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ffd185a0-239d-4e19-8600-87934606fffc'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ffd185a0-239d-4e19-8600-87934606fffc'::uuid,
  p_correct_answers => '["c"]'::jsonb,
  p_solution        => 'I · 2: 4x + 6y = 14
II - 2·I: 0 = 0
Das ist eine wahre Aussage, jedes Zahlenpaar, das I erfüllt, erfüllt auch II.
Das Gleichungssystem hat unendlich viele Lösungen: Die zweite Angabe ist nur die doppelte erste, die Preise lassen sich so nicht eindeutig bestimmen.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Genau eine Lösung angenommen, obwohl II nur das Doppelte von I ist.","socratic_question":"Was erhältst du, wenn du Gleichung I mit 2 multiplizierst?"},{"error":"Die wahre Aussage 0 = 0 als „keine Lösung“ gelesen.","socratic_question":"Stimmt 0 = 0? Für welche Zahlenpaare?"}]'::jsonb,
  p_acceptance      => '{"canonical":"c","known_errors":{"a":"parallele_uebersehen","b":"loesungsanzahl_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 lgs-grafisch-01 · LGS grafisch · Schnittpunkt ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid, 'exercise', 'LGS grafisch · Schnittpunkt ablesen', 'Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems.

Lies die Lösung des Gleichungssystems am Schnittpunkt der Geraden ab.',
  null, 'MULTI_PART', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Darstellen',
  45, null, true, null, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Schnittpunkt im ersten Quadranten auf einem Gitterpunkt ablesen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösung aus der grafischen Darstellung ablesen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'Die Geraden schneiden sich im Punkt S(2 | 3).
Die Koordinaten des Schnittpunkts sind die Lösung: x = 2, y = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"x- und y-Koordinate des Schnittpunkts vertauscht: (3 | 2) statt (2 | 3).","socratic_question":"Welche Koordinate liest du an der waagerechten Achse ab?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"3":"koordinaten_vertauscht","+3":"koordinaten_vertauscht"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"2":"koordinaten_vertauscht","+2":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":1,"b":1,"label":"f"},{"typ":"linear","m":-0.5,"b":4,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.'
 where exists (select 1 from public.tasks t where t.id = '635ae61a-bd3c-4180-9a0f-c47f66e6bc62'::uuid and t.source = 'edvance_k8_lgs')
on conflict (task_id) do nothing;

-- #20 lgs-grafisch-02 · LGS grafisch · flache Gerade
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid, 'exercise', 'LGS grafisch · flache Gerade', 'Im Koordinatensystem sind die Graphen der Funktionen f und g gezeichnet. Sie stellen ein lineares Gleichungssystem dar.

Bestimme die Lösung des Gleichungssystems mithilfe der Zeichnung.',
  null, 'MULTI_PART', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'arithmetik_algebra', 'Darstellen',
  45, null, true, null, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Schnittpunkt im ersten Quadranten ablesen, eine Gerade mit gebrochener Steigung.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösung aus der grafischen Darstellung ablesen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["1","+1"]}'::jsonb,
  p_solution        => 'Die Geraden schneiden sich im Punkt S(4 | 1).
Lösung: x = 4, y = 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"x- und y-Koordinate des Schnittpunkts vertauscht: (1 | 4) statt (4 | 1).","socratic_question":"Wie weit liegt der Schnittpunkt rechts von der y-Achse, wie weit über der x-Achse?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"1":"koordinaten_vertauscht","+1":"koordinaten_vertauscht"}},"2":{"canonical":"1","equivalents":["+1"],"known_errors":{"4":"koordinaten_vertauscht","+4":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid, 'koordinatensystem', '{"x_min":-2,"x_max":7,"y_min":-3,"y_max":6,"funktionen":[{"typ":"linear","m":0.5,"b":-1,"label":"f"},{"typ":"linear","m":-1,"b":5,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.'
 where exists (select 1 from public.tasks t where t.id = 'a4edd0b8-6298-45c2-b050-72d8d32c91ba'::uuid and t.source = 'edvance_k8_lgs')
on conflict (task_id) do nothing;

-- #21 lgs-grafisch-03 · LGS grafisch · Schnittpunkt im dritten Quadranten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid, 'exercise', 'LGS grafisch · Schnittpunkt im dritten Quadranten', 'Die Geraden f und g gehören zu einem linearen Gleichungssystem.

Gib die Lösung des Gleichungssystems an. Lies dazu den Schnittpunkt der beiden Geraden ab.',
  null, 'MULTI_PART', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Darstellen',
  60, null, true, 1, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Schnittpunkt mit zwei negativen Koordinaten ablesen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösung aus der grafischen Darstellung ablesen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht, koordinate_vorzeichen_verloren).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid,
  p_correct_answers => '{"1":["-2","−2","- 2"],"2":["-1","−1","- 1"]}'::jsonb,
  p_solution        => 'Die Geraden schneiden sich im Punkt S(-2 | -1), links unterhalb des Ursprungs.
Lösung: x = -2, y = -1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"x- und y-Koordinate des Schnittpunkts vertauscht: (-1 | -2) statt (-2 | -1).","socratic_question":"Welche Koordinate gehört zur waagerechten Achse?"},{"error":"Die Beträge richtig abgelesen, die Minuszeichen fehlen: (2 | 1).","socratic_question":"Liegt der Schnittpunkt rechts oder links von der y-Achse?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"2":"koordinate_vorzeichen_verloren","-1":"koordinaten_vertauscht","−1":"koordinaten_vertauscht","- 1":"koordinaten_vertauscht","+2":"koordinate_vorzeichen_verloren"}},"2":{"canonical":"-1","equivalents":["−1","- 1"],"known_errors":{"1":"koordinate_vorzeichen_verloren","-2":"koordinaten_vertauscht","−2":"koordinaten_vertauscht","- 2":"koordinaten_vertauscht","+1":"koordinate_vorzeichen_verloren"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":1,"b":1,"label":"f"},{"typ":"linear","m":-0.5,"b":-2,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.'
 where exists (select 1 from public.tasks t where t.id = '6bc7dd64-72ef-461c-b6cc-661ef4f08c78'::uuid and t.source = 'edvance_k8_lgs')
on conflict (task_id) do nothing;

-- #22 lgs-grafisch-04 · LGS · Lösungsanzahl · Geraden aufeinander
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '49e51e4e-c935-489b-af30-a41f8d0a932f'::uuid, 'exercise', 'LGS · Lösungsanzahl · Geraden aufeinander', 'Gegeben ist das Gleichungssystem
I: y = 0,5x + 1
II: 2y = x + 2

Wie viele Lösungen hat es? Denke an die Lage der beiden zugehörigen Geraden.',
  '{"options":[{"id":"a","label":"genau eine Lösung"},{"id":"b","label":"keine Lösung"},{"id":"c","label":"unendlich viele Lösungen"}],"input_type":"MC"}'::jsonb, 'MC', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Argumentieren',
  60, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: II in die Form y = mx + b bringen, Steigung und y-Achsenabschnitt vergleichen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösungsanzahl aus Rechnung oder Lage der Geraden begründen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"correct_answers":{"art":"neu","grund":"Lösungsanzahl aus dem Koeffizientensystem nachgerechnet (Determinante, Verträglichkeit).","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (parallele_uebersehen, loesungsanzahl_verwechselt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '49e51e4e-c935-489b-af30-a41f8d0a932f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '49e51e4e-c935-489b-af30-a41f8d0a932f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '49e51e4e-c935-489b-af30-a41f8d0a932f'::uuid,
  p_correct_answers => '["c"]'::jsonb,
  p_solution        => 'II durch 2 teilen: y = 0,5x + 1.
Beide Gleichungen haben dieselbe Steigung 0,5 und denselben y-Achsenabschnitt 1.
Die Geraden liegen aufeinander, jeder Punkt der Geraden ist eine Lösung: unendlich viele Lösungen.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Einen Schnittpunkt angenommen, ohne die Gleichungen in die Form y = mx + b zu bringen und zu vergleichen.","socratic_question":"Was erhältst du, wenn du II durch 2 teilst?"},{"error":"Gleiche Steigung als „keine Lösung“ gelesen, obwohl auch der y-Achsenabschnitt gleich ist.","socratic_question":"Haben die beiden Geraden einen gemeinsamen Punkt, zum Beispiel auf der y-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"c","known_errors":{"a":"parallele_uebersehen","b":"loesungsanzahl_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 lgs-grafisch-05 · LGS grafisch · Sachkontext · zwei Tarife
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0315634a-9c1d-4961-b214-07617add2874'::uuid, 'exercise', 'LGS grafisch · Sachkontext · zwei Tarife', 'Ein Kanuverleih bietet zwei Tarife an. Im Koordinatensystem gibt x die Leihdauer in Stunden an und y die Kosten in €. Die Gerade f gehört zu Tarif A, die Gerade g zu Tarif B.

Lies ab: Bei welcher Leihdauer kosten beide Tarife gleich viel, und wie viel kostet es dann?',
  null, 'MULTI_PART', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, true, null, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Leihdauer in Stunden: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Kosten in €: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Schnittpunkt im Sachkontext ablesen und beide Koordinaten deuten.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0315634a-9c1d-4961-b214-07617add2874'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0315634a-9c1d-4961-b214-07617add2874'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0315634a-9c1d-4961-b214-07617add2874'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["6","+6","6 €","6€","+6 €","+6€"]}'::jsonb,
  p_solution        => 'Die Geraden schneiden sich im Punkt S(4 | 6).
Nach 4 Stunden kosten beide Tarife 6 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Leihdauer und Kosten vertauscht: (6 | 4) statt (4 | 6).","socratic_question":"An welcher Achse stehen die Stunden, an welcher die Euro?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"6":"koordinaten_vertauscht","+6":"koordinaten_vertauscht"}},"2":{"canonical":"6","equivalents":["+6","6 €","6€","+6 €","+6€"],"known_errors":{"4":"koordinaten_vertauscht","+4":"koordinaten_vertauscht","4 €":"koordinaten_vertauscht","4€":"koordinaten_vertauscht","+4 €":"koordinaten_vertauscht","+4€":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '0315634a-9c1d-4961-b214-07617add2874'::uuid, 'koordinatensystem', '{"x_min":-1,"x_max":8,"y_min":-1,"y_max":9,"funktionen":[{"typ":"linear","m":1,"b":2,"label":"f"},{"typ":"linear","m":0.5,"b":4,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.'
 where exists (select 1 from public.tasks t where t.id = '0315634a-9c1d-4961-b214-07617add2874'::uuid and t.source = 'edvance_k8_lgs')
on conflict (task_id) do nothing;

-- #24 lgs-grafisch-06 · LGS grafisch · parallele Geraden deuten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4888b388-56c9-4c9a-8388-46367317b245'::uuid, 'exercise', 'LGS grafisch · parallele Geraden deuten', 'Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems.

Wie viele Lösungen hat das Gleichungssystem?',
  '{"options":[{"id":"a","label":"genau eine Lösung"},{"id":"b","label":"keine Lösung"},{"id":"c","label":"unendlich viele Lösungen"}],"input_type":"MC"}'::jsonb, 'MC', 'gleichung_lgs_grafisch',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Argumentieren',
  60, null, true, 2, 'draft', 'edvance_k8_lgs', 'lgs-grafisch-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden und deuten: aus der Lage der Geraden (parallel) auf die Lösungsanzahl schließen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Lösungsanzahl aus Rechnung oder Lage der Geraden begründen.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Ohne Abbildung (zwei Geraden im Koordinatensystem) nicht lösbar; Generator koordinatensystem, task_figures.","charge":"k8-lgs"},"correct_answers":{"art":"neu","grund":"Lösungsanzahl aus dem Koeffizientensystem nachgerechnet (Determinante, Verträglichkeit).","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (parallele_uebersehen, loesungsanzahl_verwechselt).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4888b388-56c9-4c9a-8388-46367317b245'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4888b388-56c9-4c9a-8388-46367317b245'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4888b388-56c9-4c9a-8388-46367317b245'::uuid,
  p_correct_answers => '["b"]'::jsonb,
  p_solution        => 'Die Geraden f und g sind parallel: Sie haben dieselbe Steigung, aber verschiedene y-Achsenabschnitte.
Parallele Geraden schneiden sich nie. Das Gleichungssystem hat keine Lösung.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Einen Schnittpunkt außerhalb des Bildes angenommen, obwohl die Geraden parallel sind.","socratic_question":"Kommen sich f und g näher, wenn du weiter nach rechts oder links schaust?"},{"error":"Parallele Geraden als „unendlich viele Lösungen“ gelesen.","socratic_question":"Gibt es einen Punkt, der auf beiden Geraden liegt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"b","known_errors":{"a":"parallele_uebersehen","c":"loesungsanzahl_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '4888b388-56c9-4c9a-8388-46367317b245'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"funktionen":[{"typ":"linear","m":0.5,"b":2,"label":"f"},{"typ":"linear","m":0.5,"b":-1,"label":"g"}]}'::jsonb, 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.'
 where exists (select 1 from public.tasks t where t.id = '4888b388-56c9-4c9a-8388-46367317b245'::uuid and t.source = 'edvance_k8_lgs')
on conflict (task_id) do nothing;

-- #25 lgs-sach-01 · LGS Sachaufgabe · Eintrittskarten · System wählen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '17e1d7e8-12f6-478e-a4c3-cb2ebc905145'::uuid, 'exercise', 'LGS Sachaufgabe · Eintrittskarten · System wählen', 'Ein Schwimmbad verkauft an einem Tag 120 Eintrittskarten. Eine Kinderkarte kostet 3 €, eine Erwachsenenkarte 5 €. Zusammen nimmt das Schwimmbad 460 € ein.

x ist die Anzahl der Kinderkarten, y die Anzahl der Erwachsenenkarten.',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-sach-01',
  false, true, false, false, '[{"nr":1,"kind":"mc","prompt":"Welches Gleichungssystem passt zu der Situation?","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null,"options":[{"id":"a","label":"I: x + y = 120; II: 5x + 3y = 460"},{"id":"b","label":"I: x + y = 120; II: 3x + 5y = 460"},{"id":"c","label":"I: x + y = 460; II: 3x + 5y = 120"}]},{"nr":2,"kind":"short_input","prompt":"Wie viele Kinderkarten wurden verkauft? x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Wie viele Erwachsenenkarten wurden verkauft? y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: passendes System zu Anzahl und Einnahmen erkennen, dann mit Einsetzen lösen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Option gleichwertig zum nachgerechneten System (Koeffizientenvergleich).","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.3":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, vorzeichen_beim_umstellen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '17e1d7e8-12f6-478e-a4c3-cb2ebc905145'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '17e1d7e8-12f6-478e-a4c3-cb2ebc905145'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '17e1d7e8-12f6-478e-a4c3-cb2ebc905145'::uuid,
  p_correct_answers => '{"1":["b"],"2":["70","+70"],"3":["50","+50"]}'::jsonb,
  p_solution        => 'Anzahl: x + y = 120, Einnahmen: 3x + 5y = 460, also System b.
I nach y: y = 120 - x
In II: 3x + 5·(120 - x) = 460
3x + 600 - 5x = 460
-2x = -140 | :(-2)
x = 70
y = 120 - 70 = 50
Es wurden 70 Kinderkarten und 50 Erwachsenenkarten verkauft.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Preise vertauscht: 5x + 3y = 460 statt 3x + 5y = 460.","socratic_question":"Was kostet eine Kinderkarte, und welche Variable zählt die Kinderkarten?"},{"error":"Anzahl und Einnahmen vertauscht: x + y = 460.","socratic_question":"Was zählt x + y: Karten oder Euro?"},{"error":"Bei -2x = -140 das Minus am Ergebnis gelassen: x = -70.","socratic_question":"Kann eine Anzahl von Karten negativ sein? Was ergibt -140 : (-2)?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"b","known_errors":{"a":"groessen_vertauscht","c":"groessen_vertauscht"}},"2":{"canonical":"70","equivalents":["+70"],"known_errors":{"50":"groessen_vertauscht","+50":"groessen_vertauscht","-70":"vorzeichen_beim_umstellen","−70":"vorzeichen_beim_umstellen","- 70":"vorzeichen_beim_umstellen"}},"3":{"canonical":"50","equivalents":["+50"],"known_errors":{"70":"groessen_vertauscht","190":"vorzeichen_beim_umstellen","+70":"groessen_vertauscht","+190":"vorzeichen_beim_umstellen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #26 lgs-sach-02 · LGS Sachaufgabe · Mischung · System wählen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7eb5ad20-a022-4e0e-8fd4-2a7ec2f655f1'::uuid, 'exercise', 'LGS Sachaufgabe · Mischung · System wählen', 'Eine Rösterei mischt zwei Kaffeesorten. Sorte A kostet 12 € je kg, Sorte B 18 € je kg. Es sollen 30 kg einer Mischung entstehen, die 14 € je kg kostet.

x ist die Menge von Sorte A in kg, y die Menge von Sorte B in kg.',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-sach-02',
  false, true, false, false, '[{"nr":1,"kind":"mc","prompt":"Welches Gleichungssystem passt zu der Situation?","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null,"options":[{"id":"a","label":"I: x + y = 30; II: 12x + 18y = 14"},{"id":"b","label":"I: x + y = 30; II: 18x + 12y = 420"},{"id":"c","label":"I: x + y = 30; II: 12x + 18y = 420"}]},{"nr":2,"kind":"short_input","prompt":"Menge von Sorte A in kg: x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Menge von Sorte B in kg: y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Gesamtwert der Mischung (30 · 14 €) als zweite Gleichung erkennen, dann lösen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Option gleichwertig zum nachgerechneten System (Koeffizientenvergleich).","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.3":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_unvollstaendig, groessen_vertauscht, vorzeichen_beim_umstellen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7eb5ad20-a022-4e0e-8fd4-2a7ec2f655f1'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7eb5ad20-a022-4e0e-8fd4-2a7ec2f655f1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7eb5ad20-a022-4e0e-8fd4-2a7ec2f655f1'::uuid,
  p_correct_answers => '{"1":["c"],"2":["20","+20","20 kg","20kg","+20 kg","+20kg"],"3":["10","+10","10 kg","10kg","+10 kg","+10kg"]}'::jsonb,
  p_solution        => 'Menge: x + y = 30, Wert: 12x + 18y = 30 · 14 = 420, also System c.
I nach y: y = 30 - x
In II: 12x + 18·(30 - x) = 420
12x + 540 - 18x = 420
-6x = -120 | :(-6)
x = 20
y = 30 - 20 = 10
Gemischt werden 20 kg von Sorte A und 10 kg von Sorte B.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Preis je kg als Gesamtwert genommen: 12x + 18y = 14, die 30 kg fehlen.","socratic_question":"Was kosten 30 kg der Mischung zusammen?"},{"error":"Die Preise der Sorten vertauscht: 18x + 12y = 420.","socratic_question":"Welche Sorte kostet 12 € je kg, und welche Variable gehört zu ihr?"},{"error":"Bei -6x = -120 das Minus am Ergebnis gelassen: x = -20.","socratic_question":"Kann eine Menge negativ sein? Was ergibt -120 : (-6)?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"c","known_errors":{"a":"bedingung_unvollstaendig","b":"groessen_vertauscht"}},"2":{"canonical":"20","equivalents":["+20","20 kg","20kg","+20 kg","+20kg"],"known_errors":{"10":"groessen_vertauscht","+10":"groessen_vertauscht","10 kg":"groessen_vertauscht","10kg":"groessen_vertauscht","+10 kg":"groessen_vertauscht","+10kg":"groessen_vertauscht","-20":"vorzeichen_beim_umstellen","−20":"vorzeichen_beim_umstellen","- 20":"vorzeichen_beim_umstellen","-20 kg":"vorzeichen_beim_umstellen","-20kg":"vorzeichen_beim_umstellen","−20 kg":"vorzeichen_beim_umstellen","−20kg":"vorzeichen_beim_umstellen","- 20 kg":"vorzeichen_beim_umstellen","- 20kg":"vorzeichen_beim_umstellen"}},"3":{"canonical":"10","equivalents":["+10","10 kg","10kg","+10 kg","+10kg"],"known_errors":{"20":"groessen_vertauscht","50":"vorzeichen_beim_umstellen","+20":"groessen_vertauscht","20 kg":"groessen_vertauscht","20kg":"groessen_vertauscht","+20 kg":"groessen_vertauscht","+20kg":"groessen_vertauscht","+50":"vorzeichen_beim_umstellen","50 kg":"vorzeichen_beim_umstellen","50kg":"vorzeichen_beim_umstellen","+50 kg":"vorzeichen_beim_umstellen","+50kg":"vorzeichen_beim_umstellen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #27 lgs-sach-03 · LGS Sachaufgabe · Zahlenrätsel · System wählen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '67e26196-727d-4fc1-bcf5-0ba79078adeb'::uuid, 'exercise', 'LGS Sachaufgabe · Zahlenrätsel · System wählen', 'Das Dreifache einer Zahl x und eine zweite Zahl y ergeben zusammen 26. Subtrahiert man y von x, erhält man 2.',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, 2, 'draft', 'edvance_k8_lgs', 'lgs-sach-03',
  false, true, false, false, '[{"nr":1,"kind":"mc","prompt":"Welches Gleichungssystem passt zu der Situation?","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null,"options":[{"id":"a","label":"I: 3x + y = 26; II: x - y = 2"},{"id":"b","label":"I: x + 3y = 26; II: x - y = 2"},{"id":"c","label":"I: 3(x + y) = 26; II: x - y = 2"}]},{"nr":2,"kind":"short_input","prompt":"Die Zahl x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Die Zahl y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zahlenrätsel in Gleichungen übersetzen (das Dreifache nur von x), mit Addieren lösen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Option gleichwertig zum nachgerechneten System (Koeffizientenvergleich).","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.3":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, klammer_falsch_gesetzt, seiten_ungleich_verknuepft).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '67e26196-727d-4fc1-bcf5-0ba79078adeb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '67e26196-727d-4fc1-bcf5-0ba79078adeb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '67e26196-727d-4fc1-bcf5-0ba79078adeb'::uuid,
  p_correct_answers => '{"1":["a"],"2":["7","+7"],"3":["5","+5"]}'::jsonb,
  p_solution        => 'Das Dreifache von x plus y: 3x + y = 26, x minus y: x - y = 2, also System a.
I + II: 4x = 28 | :4
x = 7
In II: 7 - y = 2, also y = 5
Die Zahlen sind x = 7 und y = 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Dreifache der falschen Zahl zugeordnet: x + 3y = 26.","socratic_question":"Von welcher Zahl wird das Dreifache genommen?"},{"error":"Eine Klammer um x + y gesetzt: Damit wird auch y verdreifacht.","socratic_question":"Wird im Text die Summe verdreifacht oder nur die Zahl x?"},{"error":"Links addiert, rechts subtrahiert: 4x = 26 - 2 = 24.","socratic_question":"Hast du die rechten Seiten genauso verknüpft wie die linken?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"a","known_errors":{"b":"groessen_vertauscht","c":"klammer_falsch_gesetzt"}},"2":{"canonical":"7","equivalents":["+7"],"known_errors":{"6":"seiten_ungleich_verknuepft","8":"groessen_vertauscht","+8":"groessen_vertauscht","+6":"seiten_ungleich_verknuepft"}},"3":{"canonical":"5","equivalents":["+5"],"known_errors":{"4":"seiten_ungleich_verknuepft","6":"groessen_vertauscht","+6":"groessen_vertauscht","+4":"seiten_ungleich_verknuepft"}}}'::jsonb);
  end if;
end
$loesung$;

-- #28 lgs-sach-04 · LGS Sachaufgabe · zwei Tarife · System wählen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '614b148f-4f0a-48ed-8796-a060b35a63b8'::uuid, 'exercise', 'LGS Sachaufgabe · zwei Tarife · System wählen', 'Zwei Taxiunternehmen berechnen ihre Preise so: Unternehmen A verlangt 4 € Grundgebühr und 2 € je Kilometer, Unternehmen B 7 € Grundgebühr und 1,50 € je Kilometer.

x ist die Strecke in km, y der Fahrpreis in €.',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren',
  90, null, false, 1, 'draft', 'edvance_k8_lgs', 'lgs-sach-04',
  false, true, false, false, '[{"nr":1,"kind":"mc","prompt":"Welches Gleichungssystem passt zu der Situation?","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null,"options":[{"id":"a","label":"I: y = 4x + 2; II: y = 7x + 1,5"},{"id":"b","label":"I: y = 2x + 4; II: y = 1,5x"},{"id":"c","label":"I: y = 2x + 4; II: y = 1,5x + 7"}]},{"nr":2,"kind":"short_input","prompt":"Bei welcher Strecke in km kosten beide Fahrten gleich viel? x =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Wie viel Euro kostet die Fahrt dann? y =","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Grundgebühr und Preis je km den Parametern zuordnen, gleichsetzen mit Dezimalkoeffizient.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Option gleichwertig zum nachgerechneten System (Koeffizientenvergleich).","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.3":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, bedingung_unvollstaendig, variablen_nicht_zusammengefuehrt, division_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '614b148f-4f0a-48ed-8796-a060b35a63b8'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = '614b148f-4f0a-48ed-8796-a060b35a63b8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '614b148f-4f0a-48ed-8796-a060b35a63b8'::uuid,
  p_correct_answers => '{"1":["c"],"2":["6","+6","6 km","6km","+6 km","+6km"],"3":["16","+16","16 €","16€","+16 €","+16€"]}'::jsonb,
  p_solution        => 'A: y = 2x + 4, B: y = 1,5x + 7, also System c.
Gleichsetzen: 2x + 4 = 1,5x + 7 | -1,5x
0,5x + 4 = 7 | -4
0,5x = 3 | :0,5
x = 6
In A: y = 2·6 + 4 = 16
Bei 6 km kosten beide Fahrten 16 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Grundgebühr und Preis je km vertauscht: y = 4x + 2.","socratic_question":"Welcher Betrag wird für jeden Kilometer neu fällig, welcher nur einmal?"},{"error":"Die Grundgebühr von Unternehmen B weggelassen: y = 1,5x.","socratic_question":"Was zahlt man bei Unternehmen B, bevor der erste Kilometer gefahren ist?"},{"error":"Durch 2 geteilt statt durch 2 - 1,5 = 0,5: x = 3 : 2 = 1,5.","socratic_question":"Wie viele x bleiben links, wenn du 1,5x auf beiden Seiten abziehst?"},{"error":"Bei 0,5x = 3 stehen geblieben und 3 als x genommen.","socratic_question":"Steht in 0,5x = 3 schon x allein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"c","known_errors":{"a":"groessen_vertauscht","b":"bedingung_unvollstaendig"}},"2":{"canonical":"6","equivalents":["+6","6 km","6km","+6 km","+6km"],"known_errors":{"3":"division_vergessen","1,5":"variablen_nicht_zusammengefuehrt","+1,5":"variablen_nicht_zusammengefuehrt","1.5":"variablen_nicht_zusammengefuehrt","+1.5":"variablen_nicht_zusammengefuehrt","1,5 km":"variablen_nicht_zusammengefuehrt","1,5km":"variablen_nicht_zusammengefuehrt","+1,5 km":"variablen_nicht_zusammengefuehrt","+1,5km":"variablen_nicht_zusammengefuehrt","1.5 km":"variablen_nicht_zusammengefuehrt","1.5km":"variablen_nicht_zusammengefuehrt","+1.5 km":"variablen_nicht_zusammengefuehrt","+1.5km":"variablen_nicht_zusammengefuehrt","+3":"division_vergessen","3 km":"division_vergessen","3km":"division_vergessen","+3 km":"division_vergessen","+3km":"division_vergessen"}},"3":{"canonical":"16","equivalents":["+16","16 €","16€","+16 €","+16€"],"known_errors":{"7":"variablen_nicht_zusammengefuehrt","10":"division_vergessen","+7":"variablen_nicht_zusammengefuehrt","7 €":"variablen_nicht_zusammengefuehrt","7€":"variablen_nicht_zusammengefuehrt","+7 €":"variablen_nicht_zusammengefuehrt","+7€":"variablen_nicht_zusammengefuehrt","+10":"division_vergessen","10 €":"division_vergessen","10€":"division_vergessen","+10 €":"division_vergessen","+10€":"division_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #29 lgs-sach-05 · LGS Sachaufgabe · Eintrittspreise · selbst aufstellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f3595c06-e95a-4b72-b137-75b3cd8f38c8'::uuid, 'exercise', 'LGS Sachaufgabe · Eintrittspreise · selbst aufstellen', 'Ein Zoo verlangt für Erwachsene und Kinder unterschiedliche Eintrittspreise. 2 Erwachsene und 3 Kinder zahlen zusammen 35 €, 3 Erwachsene und 2 Kinder zahlen zusammen 40 €.

Stelle ein Gleichungssystem auf und berechne beide Eintrittspreise (x: Preis für Erwachsene, y: Preis für Kinder, in €).',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Modellieren',
  120, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-sach-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Preis für Erwachsene in €: x =","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Preis für Kinder in €: y =","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: System ohne Vorgabe aufstellen, beide Gleichungen mit verschiedenen Faktoren multiplizieren.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (groessen_vertauscht, nicht_alle_glieder_multipliziert).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f3595c06-e95a-4b72-b137-75b3cd8f38c8'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f3595c06-e95a-4b72-b137-75b3cd8f38c8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f3595c06-e95a-4b72-b137-75b3cd8f38c8'::uuid,
  p_correct_answers => '{"1":["10","+10","10 €","10€","+10 €","+10€"],"2":["5","+5","5 €","5€","+5 €","+5€"]}'::jsonb,
  p_solution        => 'I: 2x + 3y = 35
II: 3x + 2y = 40
I · 3: 6x + 9y = 105
II · 2: 6x + 4y = 80
3·I - 2·II: 5y = 25 | :5
y = 5
In I: 2x + 15 = 35, also 2x = 20 und x = 10
Erwachsene zahlen 10 €, Kinder 5 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Erwachsene und Kinder beim Aufstellen vertauscht: 3x + 2y = 35 und 2x + 3y = 40.","socratic_question":"Zu welcher Variablen gehören die 2 Erwachsenen in der ersten Angabe?"},{"error":"Beim Multiplizieren von II die rechte Seite vergessen: 6x + 4y = 40 statt 80.","socratic_question":"Hast du beim Verdoppeln von II auch die 40 verdoppelt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"10","equivalents":["+10","10 €","10€","+10 €","+10€"],"known_errors":{"5":"groessen_vertauscht","+5":"groessen_vertauscht","5 €":"groessen_vertauscht","5€":"groessen_vertauscht","+5 €":"groessen_vertauscht","+5€":"groessen_vertauscht","-2":"nicht_alle_glieder_multipliziert","−2":"nicht_alle_glieder_multipliziert","- 2":"nicht_alle_glieder_multipliziert","-2 €":"nicht_alle_glieder_multipliziert","-2€":"nicht_alle_glieder_multipliziert","−2 €":"nicht_alle_glieder_multipliziert","−2€":"nicht_alle_glieder_multipliziert","- 2 €":"nicht_alle_glieder_multipliziert","- 2€":"nicht_alle_glieder_multipliziert"}},"2":{"canonical":"5","equivalents":["+5","5 €","5€","+5 €","+5€"],"known_errors":{"10":"groessen_vertauscht","13":"nicht_alle_glieder_multipliziert","+10":"groessen_vertauscht","10 €":"groessen_vertauscht","10€":"groessen_vertauscht","+10 €":"groessen_vertauscht","+10€":"groessen_vertauscht","+13":"nicht_alle_glieder_multipliziert","13 €":"nicht_alle_glieder_multipliziert","13€":"nicht_alle_glieder_multipliziert","+13 €":"nicht_alle_glieder_multipliziert","+13€":"nicht_alle_glieder_multipliziert"}}}'::jsonb);
  end if;
end
$loesung$;

-- #30 lgs-sach-06 · LGS Sachaufgabe · Rechteck · selbst aufstellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f2cff506-af02-4ea8-93b5-91957cab930e'::uuid, 'exercise', 'LGS Sachaufgabe · Rechteck · selbst aufstellen', 'Ein rechteckiges Beet hat einen Umfang von 34 m. Es ist 5 m länger als breit.

Stelle ein Gleichungssystem auf und berechne Länge und Breite des Beets (x: Länge, y: Breite, in m).',
  null, 'MULTI_PART', 'gleichung_lgs_sachaufgabe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'arithmetik_algebra', 'Modellieren',
  120, null, false, null, 'draft', 'edvance_k8_lgs', 'lgs-sach-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Länge in m: x =","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Breite in m: y =","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Umfang mit allen vier Seiten und den Unterschied selbst als System aufstellen und lösen.","charge":"k8-lgs"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-lgs"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Arithmetik/Algebra, Erste Stufe (Ari-9 LGS lösen, Ari-10 Sachsituationen); üblich in Klasse 8.","charge":"k8-lgs"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen, wie die Gleichungs-Voraussetzungen.","charge":"k8-lgs"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (KLP Ari-9, Ari-10).","charge":"k8-lgs"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Gleichungssystem übersetzen, lösen und deuten.","charge":"k8-lgs"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-lgs"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.1":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k8-lgs"},"correct_answers.2":{"art":"neu","grund":"Nachgerechnet (Cramer); Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-lgs"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-lgs"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (umfang_falsch_modelliert, klammer_vergessen).","charge":"k8-lgs"},"hints":{"art":"leer","grund":"Auftrag K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-lgs"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f2cff506-af02-4ea8-93b5-91957cab930e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_lgs')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f2cff506-af02-4ea8-93b5-91957cab930e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f2cff506-af02-4ea8-93b5-91957cab930e'::uuid,
  p_correct_answers => '{"1":["11","+11","11 m","11m","+11 m","+11m"],"2":["6","+6","6 m","6m","+6 m","+6m"]}'::jsonb,
  p_solution        => 'I: 2x + 2y = 34 (Umfang)
II: x = y + 5
II in I: 2·(y + 5) + 2y = 34
2y + 10 + 2y = 34
4y = 24 | :4
y = 6
x = 6 + 5 = 11
Das Beet ist 11 m lang und 6 m breit.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Umfang mit nur zwei Seiten angesetzt: x + y = 34.","socratic_question":"Wie viele Seiten hat ein Rechteck, und wie viele davon gehören zum Umfang?"},{"error":"Ohne Klammer eingesetzt: 2y + 5 + 2y = 34, die 2 trifft nur das y.","socratic_question":"Was wird verdoppelt, wenn du für x den Term y + 5 einsetzt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"11","equivalents":["+11","11 m","11m","+11 m","+11m"],"known_errors":{"19,5":"umfang_falsch_modelliert","+19,5":"umfang_falsch_modelliert","19.5":"umfang_falsch_modelliert","+19.5":"umfang_falsch_modelliert","19,5 m":"umfang_falsch_modelliert","19,5m":"umfang_falsch_modelliert","+19,5 m":"umfang_falsch_modelliert","+19,5m":"umfang_falsch_modelliert","19.5 m":"umfang_falsch_modelliert","19.5m":"umfang_falsch_modelliert","+19.5 m":"umfang_falsch_modelliert","+19.5m":"umfang_falsch_modelliert","12,25":"klammer_vergessen","+12,25":"klammer_vergessen","12.25":"klammer_vergessen","+12.25":"klammer_vergessen","12,25 m":"klammer_vergessen","12,25m":"klammer_vergessen","+12,25 m":"klammer_vergessen","+12,25m":"klammer_vergessen","12.25 m":"klammer_vergessen","12.25m":"klammer_vergessen","+12.25 m":"klammer_vergessen","+12.25m":"klammer_vergessen"}},"2":{"canonical":"6","equivalents":["+6","6 m","6m","+6 m","+6m"],"known_errors":{"14,5":"umfang_falsch_modelliert","+14,5":"umfang_falsch_modelliert","14.5":"umfang_falsch_modelliert","+14.5":"umfang_falsch_modelliert","14,5 m":"umfang_falsch_modelliert","14,5m":"umfang_falsch_modelliert","+14,5 m":"umfang_falsch_modelliert","+14,5m":"umfang_falsch_modelliert","14.5 m":"umfang_falsch_modelliert","14.5m":"umfang_falsch_modelliert","+14.5 m":"umfang_falsch_modelliert","+14.5m":"umfang_falsch_modelliert","7,25":"klammer_vergessen","+7,25":"klammer_vergessen","7.25":"klammer_vergessen","+7.25":"klammer_vergessen","7,25 m":"klammer_vergessen","7,25m":"klammer_vergessen","+7,25 m":"klammer_vergessen","+7,25m":"klammer_vergessen","7.25 m":"klammer_vergessen","7.25m":"klammer_vergessen","+7.25 m":"klammer_vergessen","+7.25m":"klammer_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;
