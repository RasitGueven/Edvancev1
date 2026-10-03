-- K10-Rest, Thema exp — 30 Aufgaben: je sechs zu fkt_exp_wachstum, _term, _halbwert, _gleichung und _anwendung.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-exp.json (Quelle: tools/k10-exp-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003121328_substrat_k10_exp.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Maschine, Zinseszins, Bakterien, Medikament, Tierpopulation, Fische, Zerfall, Gemeinde, zwei Anlagen). Terme f(x) = a·bˣ über zwei Teile a und b (MULTI_PART). Zwei Term-Aufgaben mit Abbildung (Koordinatensystem, nur Punkte des Graphen ablesen), alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt die Rundung; Logarithmen und gebrochene Hochzahlen auf 60 Stellen nachgerechnet.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k10-exp.csv. Pruefprotokoll: docs/prefill/k10-exp-verifikation.md.
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
--   fkt_exp_wachstum: exp-wachstum-03 = 1, exp-wachstum-04 = 2. Rang 1 aus Profil {mal_exponent,prozente_addiert,wachstumsfaktor_falsch}, Rang 2 aus Profil {linear_statt_exponentiell,mal_exponent} (1 neue Fehlbilder)
--   fkt_exp_term: exp-term-05 = 1, exp-term-03 = 2. Rang 1 aus Profil {anfangswert_faktor_vertauscht,linear_statt_exponentiell,wurzel_vergessen}, Rang 2 aus Profil {mal_exponent,negativer_exponent_negativ} (2 neue Fehlbilder)
--   fkt_exp_halbwert: exp-halbwert-02 = 1, exp-halbwert-04 = 2. Rang 1 aus Profil {linear_statt_exponentiell,mal_exponent,zeit_statt_perioden}, Rang 2 aus Profil {prozente_addiert,wachstumsfaktor_falsch} (2 neue Fehlbilder)
--   fkt_exp_gleichung: exp-gleichung-06 = 1, exp-gleichung-05 = 2. Rang 1 aus Profil {betrag_fehler,log_falsch_geteilt,vorrang_ignoriert}, Rang 2 aus Profil {mal_exponent,negativer_exponent_negativ} (2 neue Fehlbilder)
--   fkt_exp_anwendung: exp-anwendung-04 = 1, exp-anwendung-02 = 2. Rang 1 aus Profil {linear_statt_exponentiell,zeit_statt_perioden}, Rang 2 aus Profil {abnahmefaktor_falsch,prozente_addiert} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 exp-wachstum-01 · Wachstumsfaktor · Zunahme um 4 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fef2acea-a040-46f5-8ebd-73f1bb5c6383'::uuid, 'exercise', 'Wachstumsfaktor · Zunahme um 4 %', 'Ein Bestand nimmt in jedem Jahr um 4 % zu.

Mit welchem Faktor wird der Bestand jedes Jahr multipliziert? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Bestand nimmt in jedem Jahr um 4 % zu.\n\nMit welchem Faktor wird der Bestand jedes Jahr multipliziert? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-wachstum-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Wachstumsfaktor q = 1 + p/100 aus einem ganzzahligen Prozentsatz bilden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wachstumsfaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fef2acea-a040-46f5-8ebd-73f1bb5c6383'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fef2acea-a040-46f5-8ebd-73f1bb5c6383'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fef2acea-a040-46f5-8ebd-73f1bb5c6383'::uuid,
  p_correct_answers => '["1,04","+1,04","1.04","+1.04"]'::jsonb,
  p_solution        => 'Zunahme um 4 %: zum Ganzen (100 % = 1) kommen 4 % = 0,04 dazu.
q = 1 + 0,04 = 1,04.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Prozentsatz als Zehntel angehängt: 1,4 statt 1,04.","socratic_question":"Wie viel ist 4 % als Dezimalzahl – 0,4 oder 0,04?"},{"error":"Nur den Zuwachs 0,04 angegeben, die 1 für den alten Bestand fehlt.","socratic_question":"Was passiert mit dem Bestand, wenn du ihn mit 0,04 multiplizierst?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,04","equivalents":["+1,04","1.04","+1.04"],"known_errors":{"1,4":"wachstumsfaktor_falsch","+1,4":"wachstumsfaktor_falsch","1.4":"wachstumsfaktor_falsch","+1.4":"wachstumsfaktor_falsch","0,04":"wachstumsfaktor_falsch","+0,04":"wachstumsfaktor_falsch","0.04":"wachstumsfaktor_falsch","+0.04":"wachstumsfaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 exp-wachstum-02 · Abnahmefaktor · Abnahme um 15 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3f468bf7-9fb7-4dab-a316-c5af7d852acd'::uuid, 'exercise', 'Abnahmefaktor · Abnahme um 15 %', 'Ein Bestand nimmt in jedem Jahr um 15 % ab.

Mit welchem Faktor wird der Bestand jedes Jahr multipliziert? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Bestand nimmt in jedem Jahr um 15 % ab.\n\nMit welchem Faktor wird der Bestand jedes Jahr multipliziert? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-wachstum-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Faktor q = 1 − p/100 bei prozentualer Abnahme bilden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abnahmefaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3f468bf7-9fb7-4dab-a316-c5af7d852acd'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3f468bf7-9fb7-4dab-a316-c5af7d852acd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3f468bf7-9fb7-4dab-a316-c5af7d852acd'::uuid,
  p_correct_answers => '["0,85","+0,85","0.85","+0.85"]'::jsonb,
  p_solution        => 'Abnahme um 15 %: Vom Ganzen (100 %) bleiben 100 % − 15 % = 85 % übrig.
q = 1 − 0,15 = 0,85.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Anteil genommen, der wegfällt: 0,15 statt 0,85.","socratic_question":"Wie viel Prozent des Bestands sind nach einem Jahr noch da?"},{"error":"Die 15 % zum Ganzen addiert, obwohl der Bestand abnimmt: 1,15.","socratic_question":"Wird der Bestand größer oder kleiner, wenn du mit 1,15 multiplizierst?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,85","equivalents":["+0,85","0.85","+0.85"],"known_errors":{"0,15":"abnahmefaktor_falsch","+0,15":"abnahmefaktor_falsch","0.15":"abnahmefaktor_falsch","+0.15":"abnahmefaktor_falsch","1,15":"abnahmefaktor_falsch","+1,15":"abnahmefaktor_falsch","1.15":"abnahmefaktor_falsch","+1.15":"abnahmefaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 exp-wachstum-03 · Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f7e14298-714a-44b5-b2c8-6b93442256b5'::uuid, 'exercise', 'Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte', 'Eine Größe hat den Anfangswert 500. Sie nimmt in jedem Schritt um 6 % zu.

Welchen Wert hat sie nach 4 Schritten? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Größe hat den Anfangswert 500. Sie nimmt in jedem Schritt um 6 % zu.\n\nWelchen Wert hat sie nach 4 Schritten? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k10_exp', 'exp-wachstum-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wachstumsfaktor bilden und als Potenz über mehrere Schritte anwenden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, mal_exponent, wachstumsfaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f7e14298-714a-44b5-b2c8-6b93442256b5'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f7e14298-714a-44b5-b2c8-6b93442256b5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f7e14298-714a-44b5-b2c8-6b93442256b5'::uuid,
  p_correct_answers => '["631,24","+631,24","631.24","+631.24"]'::jsonb,
  p_solution        => 'Wachstumsfaktor q = 1,06.
Nach 4 Schritten: 500 · 1,06⁴ ≈ 500 · 1,26248 ≈ 631,24.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jeden Schritt 6 % vom Anfangswert addiert: 500 + 4 · 30 = 620.","socratic_question":"Wovon werden im zweiten Schritt die 6 % berechnet?"},{"error":"1,06⁴ als 1,06 · 4 gerechnet.","socratic_question":"Was bedeutet die kleine 4 an 1,06?"},{"error":"Mit dem Faktor 1,6 statt 1,06 gerechnet.","socratic_question":"Wie viel ist 6 % als Dezimalzahl?"}]'::jsonb,
  p_acceptance      => '{"canonical":"631,24","equivalents":["+631,24","631.24","+631.24"],"known_errors":{"620":"prozente_addiert","2120":"mal_exponent","+620":"prozente_addiert","+2120":"mal_exponent","3276,80":"wachstumsfaktor_falsch","+3276,80":"wachstumsfaktor_falsch","3276.80":"wachstumsfaktor_falsch","+3276.80":"wachstumsfaktor_falsch","3276,8":"wachstumsfaktor_falsch","+3276,8":"wachstumsfaktor_falsch","3276.8":"wachstumsfaktor_falsch","+3276.8":"wachstumsfaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 exp-wachstum-04 · Exponentiell fortsetzen · 40, 60, 90, …
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '36b07433-c75c-4ea5-8f7d-62ac59599228'::uuid, 'exercise', 'Exponentiell fortsetzen · 40, 60, 90, …', 'Die Werte 40, 60, 90, … wachsen exponentiell: Von einem Wert zum nächsten wird immer mit demselben Faktor multipliziert.

Welcher Wert steht zwei Schritte nach 90? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Werte 40, 60, 90, … wachsen exponentiell: Von einem Wert zum nächsten wird immer mit demselben Faktor multipliziert.\n\nWelcher Wert steht zwei Schritte nach 90? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_exp', 'exp-wachstum-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: konstanten Quotienten statt konstanter Differenz erkennen und zwei Schritte weiterrechnen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linear_statt_exponentiell, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '36b07433-c75c-4ea5-8f7d-62ac59599228'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '36b07433-c75c-4ea5-8f7d-62ac59599228'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '36b07433-c75c-4ea5-8f7d-62ac59599228'::uuid,
  p_correct_answers => '["202,5","+202,5","202.5","+202.5"]'::jsonb,
  p_solution        => 'Faktor: 60 : 40 = 1,5 (auch 90 : 60 = 1,5).
Nächster Wert: 90 · 1,5 = 135, danach 135 · 1,5 = 202,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Linear fortgeschrieben: zweimal 30 addiert, 90 + 60 = 150.","socratic_question":"Ist der Abstand 40 → 60 derselbe wie 60 → 90 – oder bleibt etwas anderes gleich?"},{"error":"1,5² als 1,5 · 2 gerechnet: 90 · 3 = 270.","socratic_question":"Was bedeutet es, zweimal hintereinander mit 1,5 zu multiplizieren?"}]'::jsonb,
  p_acceptance      => '{"canonical":"202,5","equivalents":["+202,5","202.5","+202.5"],"known_errors":{"150":"linear_statt_exponentiell","270":"mal_exponent","+150":"linear_statt_exponentiell","+270":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 exp-wachstum-05 · Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f91618d9-3bbf-4b57-8901-8f898829fdef'::uuid, 'exercise', 'Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88', 'Der Wert einer Maschine wird jedes Jahr mit dem Faktor 0,88 multipliziert.

Um wie viel Prozent nimmt der Wert jedes Jahr ab? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Der Wert einer Maschine wird jedes Jahr mit dem Faktor 0,88 multipliziert.\n\nUm wie viel Prozent nimmt der Wert jedes Jahr ab? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, '%', false, null, 'draft', 'edvance_k10_exp', 'exp-wachstum-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: aus dem Abnahmefaktor die prozentuale Abnahme ablesen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (rate_aus_faktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f91618d9-3bbf-4b57-8901-8f898829fdef'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f91618d9-3bbf-4b57-8901-8f898829fdef'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f91618d9-3bbf-4b57-8901-8f898829fdef'::uuid,
  p_correct_answers => '["12","12 %","12%"]'::jsonb,
  p_solution        => 'Faktor 0,88 heißt: 88 % des Werts bleiben übrig.
Abnahme: 100 % − 88 % = 12 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 0,88 als 88 % Abnahme gelesen.","socratic_question":"Wie viel Prozent des Werts sind nach einem Jahr noch da – und wie viel fehlen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","equivalents":["12 %","12%"],"known_errors":{"88":"rate_aus_faktor_falsch","88 %":"rate_aus_faktor_falsch","88%":"rate_aus_faktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 exp-wachstum-06 · Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '530dd080-d2cc-4e4b-b4ad-31963a32158a'::uuid, 'exercise', 'Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre', 'Ein Kapital von 2000 € wird 5 Jahre lang mit 3 % Zinseszins verzinst: Die Zinsen werden jedes Jahr mitverzinst. Zum Vergleich gibt es bei einer anderen Anlage jedes Jahr nur 3 % des Startkapitals als Zinsen, die nicht mitverzinst werden.

Um wie viel Euro ist das Kapital nach 5 Jahren mit Zinseszins größer als bei der anderen Anlage? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kapital von 2000 € wird 5 Jahre lang mit 3 % Zinseszins verzinst: Die Zinsen werden jedes Jahr mitverzinst. Zum Vergleich gibt es bei einer anderen Anlage jedes Jahr nur 3 % des Startkapitals als Zinsen, die nicht mitverzinst werden.\n\nUm wie viel Euro ist das Kapital nach 5 Jahren mit Zinseszins größer als bei der anderen Anlage? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_exp_wachstum',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, '€', false, null, 'draft', 'edvance_k10_exp', 'exp-wachstum-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: exponentielles und lineares Fortschreiben selbst aufstellen und den Unterschied bilden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wachstumsfaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '530dd080-d2cc-4e4b-b4ad-31963a32158a'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '530dd080-d2cc-4e4b-b4ad-31963a32158a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '530dd080-d2cc-4e4b-b4ad-31963a32158a'::uuid,
  p_correct_answers => '["18,55","18.55","18,55 €","18,55€"]'::jsonb,
  p_solution        => 'Mit Zinseszins: 2000 € · 1,03⁵ ≈ 2318,55 €.
Ohne Zinseszins: jedes Jahr 60 €, also 2000 € + 5 · 60 € = 2300 €.
Unterschied: 2318,55 € − 2300 € ≈ 18,55 €.
(Erst am Ende runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Endkapital mit Zinseszins angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel es mehr ist – was fehlt noch?"},{"error":"Die Zinsen mit Zinseszins angegeben statt des Unterschieds zur anderen Anlage.","socratic_question":"Womit sollst du das Kapital mit Zinseszins vergleichen?"},{"error":"Mit dem Faktor 1,3 statt 1,03 gerechnet.","socratic_question":"Wie viel ist 3 % als Dezimalzahl?"}]'::jsonb,
  p_acceptance      => '{"canonical":"18,55","equivalents":["18.55","18,55 €","18,55€"],"known_errors":{"2318,55":"falsche_groesse_beantwortet","2318.55":"falsche_groesse_beantwortet","2318,55 €":"falsche_groesse_beantwortet","2318,55€":"falsche_groesse_beantwortet","318,55":"falsche_groesse_beantwortet","318.55":"falsche_groesse_beantwortet","318,55 €":"falsche_groesse_beantwortet","318,55€":"falsche_groesse_beantwortet","5125,86":"wachstumsfaktor_falsch","5125.86":"wachstumsfaktor_falsch","5125,86 €":"wachstumsfaktor_falsch","5125,86€":"wachstumsfaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 exp-term-01 · Term lesen · f(x) = 250 · 1,08ˣ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f52ef418-8b90-4c8f-903f-975f8bd8da41'::uuid, 'exercise', 'Term lesen · f(x) = 250 · 1,08ˣ', 'Gegeben ist die Exponentialfunktion f(x) = 250 · 1,08ˣ.

Gib den Anfangswert an und um wie viel Prozent der Funktionswert zunimmt, wenn x um 1 größer wird. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-term-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Anfangswert f(0)","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Zunahme in Prozent, wenn x um 1 größer wird","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Anfangswert und Wachstumsrate aus dem Funktionsterm ablesen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (anfangswert_faktor_vertauscht, rate_aus_faktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f52ef418-8b90-4c8f-903f-975f8bd8da41'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f52ef418-8b90-4c8f-903f-975f8bd8da41'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f52ef418-8b90-4c8f-903f-975f8bd8da41'::uuid,
  p_correct_answers => '{"1":["250","+250"],"2":["8","+8"]}'::jsonb,
  p_solution        => 'f(x) = a · bˣ: a ist der Anfangswert, b der Wachstumsfaktor.
f(0) = 250 · 1,08⁰ = 250.
b = 1,08 = 108 %, also Zunahme um 108 % − 100 % = 8 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Wachstumsfaktor 1,08 als Anfangswert genommen.","socratic_question":"Welchen Wert hat f(x) für x = 0?"},{"error":"Den Faktor 1,08 als 108 % Zunahme gelesen.","socratic_question":"Wenn 108 % des alten Werts da sind – um wie viel Prozent ist er gewachsen?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"250","equivalents":["+250"],"known_errors":{"1,08":"anfangswert_faktor_vertauscht","+1,08":"anfangswert_faktor_vertauscht","1.08":"anfangswert_faktor_vertauscht","+1.08":"anfangswert_faktor_vertauscht"}},"2":{"canonical":"8","equivalents":["+8"],"known_errors":{"108":"rate_aus_faktor_falsch","+108":"rate_aus_faktor_falsch"}}}'::jsonb);
  end if;
end
$loesung$;

-- #8 exp-term-02 · Term aufstellen · Anfangswert 200, Abnahme 10 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a30145c7-5bc0-4f21-80ee-5237c1df2756'::uuid, 'exercise', 'Term aufstellen · Anfangswert 200, Abnahme 10 %', 'Eine Exponentialfunktion f(x) = a · bˣ hat an der Stelle x = 0 den Wert 200. Wenn x um 1 größer wird, nimmt der Funktionswert jeweils um 10 % ab.

Gib a und b an. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-term-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"b","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: a und b aus Anfangswert und prozentualer Abnahme bestimmen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (anfangswert_faktor_vertauscht, abnahmefaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a30145c7-5bc0-4f21-80ee-5237c1df2756'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a30145c7-5bc0-4f21-80ee-5237c1df2756'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a30145c7-5bc0-4f21-80ee-5237c1df2756'::uuid,
  p_correct_answers => '{"1":["200","+200"],"2":["0,9","+0,9","0.9","+0.9"]}'::jsonb,
  p_solution        => 'f(0) = a · b⁰ = a, also a = 200.
Abnahme um 10 %: Es bleiben 90 %, also b = 1 − 0,1 = 0,9.
f(x) = 200 · 0,9ˣ.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Anfangswert und Faktor vertauscht: a = 0,9.","socratic_question":"Welche Zahl in a · bˣ ist der Wert bei x = 0?"},{"error":"Den Anteil genommen, der wegfällt: b = 0,1.","socratic_question":"Wie viel Prozent des Werts bleiben bei jedem Schritt übrig?"},{"error":"Die 10 % addiert, obwohl der Wert abnimmt: b = 1,1.","socratic_question":"Wird der Wert größer oder kleiner, wenn du mit 1,1 multiplizierst?"},{"error":"Anfangswert und Faktor vertauscht: b = 200.","socratic_question":"Welche Zahl wird bei jedem Schritt erneut multipliziert?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"200","equivalents":["+200"],"known_errors":{"0,9":"anfangswert_faktor_vertauscht","+0,9":"anfangswert_faktor_vertauscht","0.9":"anfangswert_faktor_vertauscht","+0.9":"anfangswert_faktor_vertauscht"}},"2":{"canonical":"0,9","equivalents":["+0,9","0.9","+0.9"],"known_errors":{"200":"anfangswert_faktor_vertauscht","0,1":"abnahmefaktor_falsch","+0,1":"abnahmefaktor_falsch","0.1":"abnahmefaktor_falsch","+0.1":"abnahmefaktor_falsch","1,1":"abnahmefaktor_falsch","+1,1":"abnahmefaktor_falsch","1.1":"abnahmefaktor_falsch","+1.1":"abnahmefaktor_falsch","+200":"anfangswert_faktor_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #9 exp-term-03 · Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0b9ee008-01c1-4a82-8b69-cfe266a23af1'::uuid, 'exercise', 'Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ', 'Gegeben ist die Funktion f(x) = 80 · 0,5ˣ.

Berechne f(−2). Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 80 · 0,5ˣ.\n\nBerechne f(−2). Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_exp', 'exp-term-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negative Hochzahl als Kehrwert deuten und mit dem Anfangswert multiplizieren.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0b9ee008-01c1-4a82-8b69-cfe266a23af1'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0b9ee008-01c1-4a82-8b69-cfe266a23af1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0b9ee008-01c1-4a82-8b69-cfe266a23af1'::uuid,
  p_correct_answers => '["320","+320"]'::jsonb,
  p_solution        => '0,5⁻² = 1 : 0,5² = 1 : 0,25 = 4.
f(−2) = 80 · 4 = 320.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die negative Hochzahl als Minus vor dem Ergebnis gelesen: 0,5⁻² = −0,25.","socratic_question":"Was bedeutet eine negative Hochzahl: ein negatives Ergebnis oder der Kehrwert?"},{"error":"0,5⁻² als 0,5 · (−2) gerechnet.","socratic_question":"Was bedeutet die Hochzahl −2 an 0,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"320","equivalents":["+320"],"known_errors":{"-20":"negativer_exponent_negativ","−20":"negativer_exponent_negativ","- 20":"negativer_exponent_negativ","-80":"mal_exponent","−80":"mal_exponent","- 80":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 exp-term-04 · Punkte ablesen · f(3) aus zwei Punkten des Graphen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid, 'exercise', 'Punkte ablesen · f(3) aus zwei Punkten des Graphen', 'Die Punkte P und Q in der Abbildung liegen auf dem Graphen von f(x) = a · bˣ. P liegt auf der y-Achse. Beide Punkte haben ganzzahlige Koordinaten.

Lies ihre Koordinaten ab und berechne f(3). Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Punkte P und Q in der Abbildung liegen auf dem Graphen von f(x) = a · bˣ. P liegt auf der y-Achse. Beide Punkte haben ganzzahlige Koordinaten.\n\nLies ihre Koordinaten ab und berechne f(3). Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, null, 'draft', 'edvance_k10_exp', 'exp-term-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Anfangswert und Faktor aus zwei abgelesenen Punkten bestimmen, dann auswerten.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (anfangswert_faktor_vertauscht, linear_statt_exponentiell, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid,
  p_correct_answers => '["54","+54"]'::jsonb,
  p_solution        => 'Ablesen: P(0|2) und Q(1|6).
P auf der y-Achse: a = f(0) = 2.
Q: f(1) = 2 · b = 6, also b = 3.
f(3) = 2 · 3³ = 2 · 27 = 54.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Anfangswert und Faktor vertauscht: f(x) = 3 · 2ˣ.","socratic_question":"Welcher der beiden Punkte zeigt den Wert bei x = 0?"},{"error":"Linear fortgeschrieben: bei jedem Schritt 4 addiert.","socratic_question":"Wird bei f(x) = a · bˣ in jedem Schritt addiert oder multipliziert?"},{"error":"3³ als 3 · 3 gerechnet.","socratic_question":"Was bedeutet die kleine 3 an der 3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"54","equivalents":["+54"],"known_errors":{"14":"linear_statt_exponentiell","18":"mal_exponent","24":"anfangswert_faktor_vertauscht","+24":"anfangswert_faktor_vertauscht","+14":"linear_statt_exponentiell","+18":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid, 'koordinatensystem', '{"x_min":-1,"x_max":4,"y_min":-1,"y_max":8,"punkte":[{"x":0,"y":2,"label":"P"},{"x":1,"y":6,"label":"Q"}]}'::jsonb, 'Koordinatensystem mit Gitter und den Punkten P und Q.'
 where exists (select 1 from public.tasks t where t.id = 'f8140fab-2e2f-43cf-9b1f-646865613fa1'::uuid and t.source = 'edvance_k10_exp')
on conflict (task_id) do nothing;

-- #11 exp-term-05 · Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid, 'exercise', 'Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3', 'Die Punkte P und Q in der Abbildung liegen auf dem Graphen von f(x) = a · bˣ mit b > 0. Beide Punkte haben ganzzahlige Koordinaten.

Lies ihre Koordinaten ab und bestimme a und b. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, 1, 'draft', 'edvance_k10_exp', 'exp-term-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"b","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: aus zwei Punkten den Faktor über zwei Schritte und daraus a bestimmen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k10-exp"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, anfangswert_faktor_vertauscht, linear_statt_exponentiell).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid,
  p_correct_answers => '{"1":["1,5","+1,5","1.5","+1.5","3/2","+3/2"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'Ablesen: P(1|3) und Q(3|12).
Von x = 1 bis x = 3 wird zweimal mit b multipliziert: b² = 12 : 3 = 4, b = 2.
f(1) = a · 2 = 3, also a = 3 : 2 = 1,5.
f(x) = 1,5 · 2ˣ.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"b² = 4 als b genommen und deshalb a = 3 : 4 gerechnet.","socratic_question":"Liegen zwischen P und Q ein oder zwei Schritte in x-Richtung?"},{"error":"Anfangswert und Faktor vertauscht: a = 2.","socratic_question":"Welche Zahl in a · bˣ wird bei jedem Schritt erneut multipliziert?"},{"error":"b² = 4 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Von x = 1 bis x = 3 wird zweimal mit b multipliziert – was ist dann 12 : 3?"},{"error":"Wie bei einer Geraden die Steigung berechnet: 9 : 2.","socratic_question":"Wird bei f(x) = a · bˣ in jedem Schritt addiert oder multipliziert?"},{"error":"Anfangswert und Faktor vertauscht: b = 1,5.","socratic_question":"Welche Zahl in a · bˣ ist der Wert bei x = 0?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5","3/2","+3/2"],"known_errors":{"2":"anfangswert_faktor_vertauscht","0,75":"wurzel_vergessen","+0,75":"wurzel_vergessen","0.75":"wurzel_vergessen","+0.75":"wurzel_vergessen","3/4":"wurzel_vergessen","+3/4":"wurzel_vergessen","+2":"anfangswert_faktor_vertauscht"}},"2":{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"wurzel_vergessen","+4":"wurzel_vergessen","4,5":"linear_statt_exponentiell","+4,5":"linear_statt_exponentiell","4.5":"linear_statt_exponentiell","+4.5":"linear_statt_exponentiell","1,5":"anfangswert_faktor_vertauscht","+1,5":"anfangswert_faktor_vertauscht","1.5":"anfangswert_faktor_vertauscht","+1.5":"anfangswert_faktor_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid, 'koordinatensystem', '{"x_min":-1,"x_max":4,"y_min":-1,"y_max":13,"punkte":[{"x":1,"y":3,"label":"P"},{"x":3,"y":12,"label":"Q"}]}'::jsonb, 'Koordinatensystem mit Gitter und den Punkten P und Q.'
 where exists (select 1 from public.tasks t where t.id = '785c92ab-e234-469f-bb6a-59c0c11db8fd'::uuid and t.source = 'edvance_k10_exp')
on conflict (task_id) do nothing;

-- #12 exp-term-06 · Term aufstellen · Bakterien nach 2 und 4 Stunden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0a568e4e-b3e1-408c-89e1-ba380e9845a3'::uuid, 'exercise', 'Term aufstellen · Bakterien nach 2 und 4 Stunden', 'In einer Bakterienkultur werden nach 2 Stunden 360 Bakterien und nach 4 Stunden 810 Bakterien gezählt. Die Anzahl wächst exponentiell und wird durch f(x) = a · bˣ beschrieben (x in Stunden seit Beginn der Beobachtung).

Bestimme a und b. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_exp_term',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k10_exp', 'exp-term-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a (Anzahl zu Beginn)","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"b (Wachstumsfaktor pro Stunde)","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus zwei Messwerten den Faktor über zwei Schritte und den Anfangswert durch Zurückrechnen bestimmen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-exp"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linear_statt_exponentiell, anfangswert_faktor_vertauscht, wurzel_vergessen).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0a568e4e-b3e1-408c-89e1-ba380e9845a3'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0a568e4e-b3e1-408c-89e1-ba380e9845a3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0a568e4e-b3e1-408c-89e1-ba380e9845a3'::uuid,
  p_correct_answers => '{"1":["160","+160"],"2":["1,5","+1,5","1.5","+1.5"]}'::jsonb,
  p_solution        => 'Von x = 2 bis x = 4 wird zweimal mit b multipliziert: b² = 810 : 360 = 2,25, b = 1,5.
Zurückrechnen: f(2) = a · 1,5² = 360, also a = 360 : 2,25 = 160.
f(x) = 160 · 1,5ˣ.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Linear zurückgerechnet: 360 − 450 = −90.","socratic_question":"Wird die Anzahl in jeder Stunde um denselben Betrag größer oder mit demselben Faktor?"},{"error":"Anfangswert und Faktor vertauscht: a = 1,5.","socratic_question":"Welche Zahl in a · bˣ ist die Anzahl bei x = 0?"},{"error":"b² = 2,25 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Wie viele Stunden liegen zwischen den beiden Zählungen – und wie oft wird dabei mit b multipliziert?"},{"error":"Anfangswert und Faktor vertauscht: b = 160.","socratic_question":"Welche Zahl in a · bˣ wird jede Stunde erneut multipliziert?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"160","equivalents":["+160"],"known_errors":{"-90":"linear_statt_exponentiell","−90":"linear_statt_exponentiell","- 90":"linear_statt_exponentiell","1,5":"anfangswert_faktor_vertauscht","+1,5":"anfangswert_faktor_vertauscht","1.5":"anfangswert_faktor_vertauscht","+1.5":"anfangswert_faktor_vertauscht"}},"2":{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5"],"known_errors":{"160":"anfangswert_faktor_vertauscht","2,25":"wurzel_vergessen","+2,25":"wurzel_vergessen","2.25":"wurzel_vergessen","+2.25":"wurzel_vergessen","+160":"anfangswert_faktor_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #13 exp-halbwert-01 · Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '67e561b4-fcbf-40c1-a24f-6180f39bb1f3'::uuid, 'exercise', 'Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren', 'Ein Stoff hat eine Halbwertszeit von 5 Jahren. Zu Beginn sind 64 g vorhanden.

Wie viel Gramm sind nach 15 Jahren noch vorhanden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Stoff hat eine Halbwertszeit von 5 Jahren. Zu Beginn sind 64 g vorhanden.\n\nWie viel Gramm sind nach 15 Jahren noch vorhanden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, 'g', false, null, 'draft', 'edvance_k10_exp', 'exp-halbwert-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Anzahl der Halbwertszeiten bestimmen und entsprechend oft halbieren.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeit_statt_perioden, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '67e561b4-fcbf-40c1-a24f-6180f39bb1f3'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '67e561b4-fcbf-40c1-a24f-6180f39bb1f3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '67e561b4-fcbf-40c1-a24f-6180f39bb1f3'::uuid,
  p_correct_answers => '["8","8 g","8g"]'::jsonb,
  p_solution        => '15 Jahre sind 15 : 5 = 3 Halbwertszeiten.
64 g · 0,5³ = 64 g : 8 = 8 g.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 15 Jahre direkt als Hochzahl genommen: 64 · 0,5¹⁵.","socratic_question":"Wie oft halbiert sich die Menge in 15 Jahren, wenn sie sich alle 5 Jahre halbiert?"},{"error":"0,5³ als 0,5 · 3 gerechnet: 64 · 1,5 = 96.","socratic_question":"Kann nach drei Halbierungen mehr übrig sein als am Anfang?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["8 g","8g"],"known_errors":{"96":"mal_exponent","0,001953125":"zeit_statt_perioden","0.001953125":"zeit_statt_perioden","0,001953125 g":"zeit_statt_perioden","0,001953125g":"zeit_statt_perioden","96 g":"mal_exponent","96g":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 exp-halbwert-02 · Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '10179c4f-fa4f-439c-81e5-c5d0957ac2e7'::uuid, 'exercise', 'Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden', 'Ein Bestand von 300 verdoppelt sich alle 4 Stunden.

Wie groß ist der Bestand nach 12 Stunden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Bestand von 300 verdoppelt sich alle 4 Stunden.\n\nWie groß ist der Bestand nach 12 Stunden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k10_exp', 'exp-halbwert-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Anzahl der Verdopplungszeiten bestimmen und entsprechend oft verdoppeln.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeit_statt_perioden, linear_statt_exponentiell, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '10179c4f-fa4f-439c-81e5-c5d0957ac2e7'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '10179c4f-fa4f-439c-81e5-c5d0957ac2e7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '10179c4f-fa4f-439c-81e5-c5d0957ac2e7'::uuid,
  p_correct_answers => '["2400","+2400"]'::jsonb,
  p_solution        => '12 Stunden sind 12 : 4 = 3 Verdopplungszeiten.
300 · 2³ = 300 · 8 = 2400.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 12 Stunden direkt als Hochzahl genommen: 300 · 2¹².","socratic_question":"Wie oft verdoppelt sich der Bestand in 12 Stunden?"},{"error":"Bei jeder Verdopplungszeit nur 300 addiert: 300 + 3 · 300.","socratic_question":"Was wird verdoppelt: der Anfangsbestand oder der jeweils aktuelle Bestand?"},{"error":"2³ als 2 · 3 gerechnet: 300 · 6.","socratic_question":"Was ergibt 2 · 2 · 2?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2400","equivalents":["+2400"],"known_errors":{"1200":"linear_statt_exponentiell","1800":"mal_exponent","1228800":"zeit_statt_perioden","+1228800":"zeit_statt_perioden","+1200":"linear_statt_exponentiell","+1800":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 exp-halbwert-03 · Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6557a84f-4c11-4e4d-8fbe-ec66210f6027'::uuid, 'exercise', 'Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage', 'Ein Stoff hat eine Halbwertszeit von 8 Tagen. Zu Beginn sind 400 mg vorhanden.

Nach wie vielen Tagen sind nur noch 25 mg vorhanden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Stoff hat eine Halbwertszeit von 8 Tagen. Zu Beginn sind 400 mg vorhanden.\n\nNach wie vielen Tagen sind nur noch 25 mg vorhanden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, 'Tage', false, null, 'draft', 'edvance_k10_exp', 'exp-halbwert-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Verhältnis als Zweierpotenz erkennen, Anzahl der Halbwertszeiten in Zeit umrechnen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6557a84f-4c11-4e4d-8fbe-ec66210f6027'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6557a84f-4c11-4e4d-8fbe-ec66210f6027'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6557a84f-4c11-4e4d-8fbe-ec66210f6027'::uuid,
  p_correct_answers => '["32","32 Tage","32Tage"]'::jsonb,
  p_solution        => '400 mg : 25 mg = 16 = 2⁴: Die Menge hat sich 4-mal halbiert (400 → 200 → 100 → 50 → 25).
4 Halbwertszeiten: 4 · 8 Tage = 32 Tage.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Anzahl der Halbwertszeiten angegeben statt der Tage.","socratic_question":"Gefragt sind Tage – wie lang dauert eine Halbwertszeit?"}]'::jsonb,
  p_acceptance      => '{"canonical":"32","equivalents":["32 Tage","32Tage"],"known_errors":{"4":"falsche_groesse_beantwortet","4 Tage":"falsche_groesse_beantwortet","4Tage":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 exp-halbwert-04 · Verdopplung durch Probieren · 12 % pro Jahr
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3e496b46-156d-45cc-9b77-596261829fb8'::uuid, 'exercise', 'Verdopplung durch Probieren · 12 % pro Jahr', 'Ein Bestand wächst in jedem Jahr um 12 %.

Gib die Anzahl der ganzen Jahre an, nach denen sich der Bestand erstmals mindestens verdoppelt hat.',
  '{"kind":"short_input","prompt":"Ein Bestand wächst in jedem Jahr um 12 %.\n\nGib die Anzahl der ganzen Jahre an, nach denen sich der Bestand erstmals mindestens verdoppelt hat."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, 'Jahre', false, 2, 'draft', 'edvance_k10_exp', 'exp-halbwert-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Potenzen des Wachstumsfaktors probieren (oder logarithmieren) und die erste ganze Zahl über der Grenze wählen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, wachstumsfaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3e496b46-156d-45cc-9b77-596261829fb8'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3e496b46-156d-45cc-9b77-596261829fb8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3e496b46-156d-45cc-9b77-596261829fb8'::uuid,
  p_correct_answers => '["7","7 Jahre","7Jahre"]'::jsonb,
  p_solution        => 'Gesucht ist das kleinste ganze n mit 1,12ⁿ ≥ 2.
1,12⁶ ≈ 1,974 < 2, aber 1,12⁷ ≈ 2,211 ≥ 2.
(Oder: log 2 : log 1,12 ≈ 6,12, also aufrunden.)
Nach 7 Jahren.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jedes Jahr nur 12 % vom Anfangsbestand addiert: 100 % : 12 % ≈ 8,3, also 9 Jahre.","socratic_question":"Wovon werden im zweiten Jahr die 12 % berechnet?"},{"error":"Mit dem Faktor 1,2 statt 1,12 gerechnet.","socratic_question":"Wie viel ist 12 % als Dezimalzahl, und wie heißt dann der Faktor?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["7 Jahre","7Jahre"],"known_errors":{"4":"wachstumsfaktor_falsch","9":"prozente_addiert","9 Jahre":"prozente_addiert","9Jahre":"prozente_addiert","4 Jahre":"wachstumsfaktor_falsch","4Jahre":"wachstumsfaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 exp-halbwert-05 · Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b034cc64-2773-4753-a08d-be9bbb6319c6'::uuid, 'exercise', 'Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden', 'Ein Medikament wird im Körper abgebaut; die Menge halbiert sich immer in derselben Zeit. 12 Stunden nach der Einnahme sind noch 12,5 % der eingenommenen Menge im Körper.

Wie groß ist die Halbwertszeit in Stunden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Medikament wird im Körper abgebaut; die Menge halbiert sich immer in derselben Zeit. 12 Stunden nach der Einnahme sind noch 12,5 % der eingenommenen Menge im Körper.\n\nWie groß ist die Halbwertszeit in Stunden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'h', false, null, 'draft', 'edvance_k10_exp', 'exp-halbwert-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: aus dem Restanteil die Anzahl der Halbierungen und daraus die Halbwertszeit bestimmen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, linear_statt_exponentiell).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b034cc64-2773-4753-a08d-be9bbb6319c6'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b034cc64-2773-4753-a08d-be9bbb6319c6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b034cc64-2773-4753-a08d-be9bbb6319c6'::uuid,
  p_correct_answers => '["4","4 h","4h"]'::jsonb,
  p_solution        => '12,5 % = 0,125 = 1/8 = (1/2)³: In 12 Stunden hat sich die Menge 3-mal halbiert (100 % → 50 % → 25 % → 12,5 %).
Halbwertszeit: 12 h : 3 = 4 h.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Anzahl der Halbierungen angegeben statt der Halbwertszeit.","socratic_question":"Gefragt ist eine Zeit in Stunden – wie viele Stunden dauert eine Halbierung?"},{"error":"Linear gerechnet: 87,5 % Abbau in 12 Stunden, 50 % Abbau also in 12 · 50 : 87,5 Stunden.","socratic_question":"Wird in jeder Stunde dieselbe Menge abgebaut oder derselbe Anteil?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 h","4h"],"known_errors":{"3":"falsche_groesse_beantwortet","3 h":"falsche_groesse_beantwortet","3h":"falsche_groesse_beantwortet","6,86":"linear_statt_exponentiell","6.86":"linear_statt_exponentiell","6,86 h":"linear_statt_exponentiell","6,86h":"linear_statt_exponentiell"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 exp-halbwert-06 · Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '01afa83d-dfd8-44a6-b6e4-b75c28c273a0'::uuid, 'exercise', 'Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren', 'Eine Tierpopulation von 500 Tieren verdoppelt sich alle 3 Jahre.

Wie viele Tiere sind es nach 10 Jahren? Runde auf ganze Tiere.',
  '{"kind":"short_input","prompt":"Eine Tierpopulation von 500 Tieren verdoppelt sich alle 3 Jahre.\n\nWie viele Tiere sind es nach 10 Jahren? Runde auf ganze Tiere."}'::jsonb, 'NUMERIC', 'fkt_exp_halbwert',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k10_exp', 'exp-halbwert-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: nicht ganzzahlige Anzahl von Verdopplungszeiten als gebrochene Hochzahl einsetzen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeit_statt_perioden, linear_statt_exponentiell, zu_frueh_gerundet).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '01afa83d-dfd8-44a6-b6e4-b75c28c273a0'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '01afa83d-dfd8-44a6-b6e4-b75c28c273a0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '01afa83d-dfd8-44a6-b6e4-b75c28c273a0'::uuid,
  p_correct_answers => '["5040","+5040"]'::jsonb,
  p_solution        => '10 Jahre sind 10 : 3 Verdopplungszeiten.
500 · 2^(10/3) ≈ 500 · 10,0794 ≈ 5039,7.
Gerundet: 5040 Tiere.
(Die Hochzahl 10/3 nicht vorher runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 10 Jahre direkt als Hochzahl genommen: 500 · 2¹⁰.","socratic_question":"Wie oft verdoppelt sich die Population in 10 Jahren, wenn sie sich alle 3 Jahre verdoppelt?"},{"error":"Linear gerechnet: alle 3 Jahre 500 Tiere dazu.","socratic_question":"Was wird verdoppelt: die Anfangszahl oder die jeweils aktuelle Zahl?"},{"error":"Die Hochzahl 10/3 vorher auf 3,33 gerundet.","socratic_question":"Was passiert mit dem Ergebnis, wenn du 10/3 vor dem Potenzieren rundest?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5040","equivalents":["+5040"],"known_errors":{"2167":"linear_statt_exponentiell","5028":"zu_frueh_gerundet","512000":"zeit_statt_perioden","+512000":"zeit_statt_perioden","+2167":"linear_statt_exponentiell","+5028":"zu_frueh_gerundet"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 exp-gleichung-01 · Probieren · 3ˣ = 81
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c145fae7-4001-4d15-9218-64948c1964af'::uuid, 'exercise', 'Probieren · 3ˣ = 81', 'Löse die Gleichung 3ˣ = 81. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Löse die Gleichung 3ˣ = 81. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-gleichung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: ganzzahlige Lösung durch Potenzen der Basis finden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (log_falsch_geteilt).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c145fae7-4001-4d15-9218-64948c1964af'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c145fae7-4001-4d15-9218-64948c1964af'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c145fae7-4001-4d15-9218-64948c1964af'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => 'Potenzen von 3: 3¹ = 3, 3² = 9, 3³ = 27, 3⁴ = 81.
x = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c durch b geteilt: 81 : 3 = 27.","socratic_question":"Setze 27 ein: Ist 3²⁷ wirklich 81?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["+4"],"known_errors":{"27":"log_falsch_geteilt","+27":"log_falsch_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 exp-gleichung-02 · Probieren mit negativer Lösung · 2ˣ = 1/8
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b08dd57c-00cd-4d8d-b035-0d37075d6331'::uuid, 'exercise', 'Probieren mit negativer Lösung · 2ˣ = 1/8', 'Löse die Gleichung 2ˣ = 1/8. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Löse die Gleichung 2ˣ = 1/8. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_exp', 'exp-gleichung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Kehrwert einer Zweierpotenz als negative Hochzahl erkennen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, log_falsch_geteilt).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b08dd57c-00cd-4d8d-b035-0d37075d6331'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b08dd57c-00cd-4d8d-b035-0d37075d6331'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b08dd57c-00cd-4d8d-b035-0d37075d6331'::uuid,
  p_correct_answers => '["-3","−3","- 3"]'::jsonb,
  p_solution        => '2³ = 8, also 1/8 = 1/2³ = 2⁻³.
x = -3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahl ohne Minus angegeben: 2³ = 8, nicht 1/8.","socratic_question":"Ist 2³ gleich 8 oder gleich 1/8?"},{"error":"c durch b geteilt: 1/8 : 2 = 1/16.","socratic_question":"Setze dein Ergebnis ein: Ergibt 2 hoch diese Zahl wirklich 1/8?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"3":"betrag_fehler","+3":"betrag_fehler","0,0625":"log_falsch_geteilt","+0,0625":"log_falsch_geteilt","0.0625":"log_falsch_geteilt","+0.0625":"log_falsch_geteilt","1/16":"log_falsch_geteilt","+1/16":"log_falsch_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 exp-gleichung-03 · Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3f87ce05-a113-439a-8b18-18160b63ca52'::uuid, 'exercise', 'Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20', 'Eine Bakterienzahl wächst jede Stunde mit dem Faktor 1,5. Nach x Stunden hat sie sich verzwanzigfacht; dafür gilt 1,5ˣ = 20.

Bestimme x mit dem Logarithmus. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Bakterienzahl wächst jede Stunde mit dem Faktor 1,5. Nach x Stunden hat sie sich verzwanzigfacht; dafür gilt 1,5ˣ = 20.\n\nBestimme x mit dem Logarithmus. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k10_exp', 'exp-gleichung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Gleichung bˣ = c mit x = log c : log b lösen und runden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (log_falsch_geteilt, umgekehrt_geteilt).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3f87ce05-a113-439a-8b18-18160b63ca52'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3f87ce05-a113-439a-8b18-18160b63ca52'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3f87ce05-a113-439a-8b18-18160b63ca52'::uuid,
  p_correct_answers => '["7,39","+7,39","7.39","+7.39"]'::jsonb,
  p_solution        => 'x = log 20 : log 1,5 ≈ 1,30103 : 0,17609 ≈ 7,39.
Nach etwa 7,39 Stunden.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c durch b geteilt statt log c durch log b: 20 : 1,5.","socratic_question":"Setze dein Ergebnis ein: Ist 1,5 hoch diese Zahl wirklich 20?"},{"error":"Umgekehrt geteilt: log 1,5 : log 20.","socratic_question":"Welcher Logarithmus gehört in den Zähler – der von c oder der von b?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,39","equivalents":["+7,39","7.39","+7.39"],"known_errors":{"13,33":"log_falsch_geteilt","+13,33":"log_falsch_geteilt","13.33":"log_falsch_geteilt","+13.33":"log_falsch_geteilt","0,14":"umgekehrt_geteilt","+0,14":"umgekehrt_geteilt","0.14":"umgekehrt_geteilt","+0.14":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 exp-gleichung-04 · Logarithmus · 2,5 · 1,04ˣ = 4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '970789a3-e052-48e9-b5c8-7509083a901c'::uuid, 'exercise', 'Logarithmus · 2,5 · 1,04ˣ = 4', 'Löse die Gleichung 2,5 · 1,04ˣ = 4. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Löse die Gleichung 2,5 · 1,04ˣ = 4. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_exp', 'exp-gleichung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst durch den Vorfaktor teilen, dann logarithmieren und runden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorrang_ignoriert, log_falsch_geteilt).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '970789a3-e052-48e9-b5c8-7509083a901c'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '970789a3-e052-48e9-b5c8-7509083a901c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '970789a3-e052-48e9-b5c8-7509083a901c'::uuid,
  p_correct_answers => '["11,98","+11,98","11.98","+11.98"]'::jsonb,
  p_solution        => 'Durch 2,5 teilen: 1,04ˣ = 4 : 2,5 = 1,6.
x = log 1,6 : log 1,04 ≈ 0,20412 : 0,01703 ≈ 11,98.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Erst 2,5 · 1,04 = 2,6 gerechnet und dann 2,6ˣ = 4 gelöst.","socratic_question":"Wird in 2,5 · 1,04ˣ zuerst potenziert oder zuerst multipliziert?"},{"error":"Nach dem Teilen c durch b geteilt: 1,6 : 1,04.","socratic_question":"Setze dein Ergebnis ein: Ist 1,04 hoch diese Zahl wirklich 1,6?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11,98","equivalents":["+11,98","11.98","+11.98"],"known_errors":{"1,45":"vorrang_ignoriert","+1,45":"vorrang_ignoriert","1.45":"vorrang_ignoriert","+1.45":"vorrang_ignoriert","1,54":"log_falsch_geteilt","+1,54":"log_falsch_geteilt","1.54":"log_falsch_geteilt","+1.54":"log_falsch_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 exp-gleichung-05 · Rückrichtung · 2ˣ = c hat die Lösung x = −4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '356c43e5-5443-4664-83f9-e81054644920'::uuid, 'exercise', 'Rückrichtung · 2ˣ = c hat die Lösung x = −4', 'Die Gleichung 2ˣ = c hat die Lösung x = −4.

Wie groß ist c? Gib das Ergebnis exakt an. Du kannst auch einen Bruch eingeben.',
  '{"kind":"short_input","prompt":"Die Gleichung 2ˣ = c hat die Lösung x = −4.\n\nWie groß ist c? Gib das Ergebnis exakt an. Du kannst auch einen Bruch eingeben."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_exp', 'exp-gleichung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: aus der Lösung den Wert c als Potenz mit negativer Hochzahl berechnen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '356c43e5-5443-4664-83f9-e81054644920'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '356c43e5-5443-4664-83f9-e81054644920'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '356c43e5-5443-4664-83f9-e81054644920'::uuid,
  p_correct_answers => '["0,0625","+0,0625","0.0625","+0.0625","1/16","+1/16"]'::jsonb,
  p_solution        => 'c = 2⁻⁴ = 1 : 2⁴ = 1/16 = 0,0625.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die negative Hochzahl als Minus vor dem Ergebnis gelesen: 2⁻⁴ = −16.","socratic_question":"Kann eine Potenz von 2 negativ sein?"},{"error":"2⁻⁴ als 2 · (−4) gerechnet.","socratic_question":"Was bedeutet die Hochzahl −4 an der 2?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,0625","equivalents":["+0,0625","0.0625","+0.0625","1/16","+1/16"],"known_errors":{"-16":"negativer_exponent_negativ","−16":"negativer_exponent_negativ","- 16":"negativer_exponent_negativ","-8":"mal_exponent","−8":"mal_exponent","- 8":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 exp-gleichung-06 · Erst teilen, dann probieren · 3 · 2ˣ = 3/32
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '282318bf-0748-4764-8f2f-ac39dfd14d22'::uuid, 'exercise', 'Erst teilen, dann probieren · 3 · 2ˣ = 3/32', 'Löse die Gleichung 3 · 2ˣ = 3/32. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Löse die Gleichung 3 · 2ˣ = 3/32. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_exp_gleichung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, 1, 'draft', 'edvance_k10_exp', 'exp-gleichung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Vorfaktor abspalten, Bruch als Zweierpotenz mit negativer Hochzahl erkennen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, vorrang_ignoriert, log_falsch_geteilt).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '282318bf-0748-4764-8f2f-ac39dfd14d22'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '282318bf-0748-4764-8f2f-ac39dfd14d22'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '282318bf-0748-4764-8f2f-ac39dfd14d22'::uuid,
  p_correct_answers => '["-5","−5","- 5"]'::jsonb,
  p_solution        => 'Durch 3 teilen: 2ˣ = 1/32.
2⁵ = 32, also 1/32 = 2⁻⁵.
x = -5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahl ohne Minus angegeben: 2⁵ = 32, nicht 1/32.","socratic_question":"Ist 2⁵ gleich 32 oder gleich 1/32?"},{"error":"Erst 3 · 2 = 6 gerechnet und dann 6ˣ = 3/32 gelöst.","socratic_question":"Wird in 3 · 2ˣ zuerst potenziert oder zuerst multipliziert?"},{"error":"Nach dem Teilen c durch b geteilt: 1/32 : 2.","socratic_question":"Setze dein Ergebnis ein: Ergibt 2 hoch diese Zahl wirklich 1/32?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"5":"betrag_fehler","+5":"betrag_fehler","-1,32":"vorrang_ignoriert","−1,32":"vorrang_ignoriert","- 1,32":"vorrang_ignoriert","-1.32":"vorrang_ignoriert","−1.32":"vorrang_ignoriert","- 1.32":"vorrang_ignoriert","0,015625":"log_falsch_geteilt","+0,015625":"log_falsch_geteilt","0.015625":"log_falsch_geteilt","+0.015625":"log_falsch_geteilt","1/64":"log_falsch_geteilt","+1/64":"log_falsch_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 exp-anwendung-01 · Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '380b85ad-3967-4fad-b370-e113276310a6'::uuid, 'exercise', 'Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €', 'Ein Kapital von 1000 € wird mit 5 % pro Jahr verzinst; die Zinsen werden mitverzinst.

Gib die Anzahl der ganzen Jahre an, nach denen das Kapital erstmals mindestens 1500 € beträgt.',
  '{"kind":"short_input","prompt":"Ein Kapital von 1000 € wird mit 5 % pro Jahr verzinst; die Zinsen werden mitverzinst.\n\nGib die Anzahl der ganzen Jahre an, nach denen das Kapital erstmals mindestens 1500 € beträgt."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Modellieren, Operieren',
  75, 'Jahre', false, null, 'draft', 'edvance_k10_exp', 'exp-anwendung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Zinseszins-Gleichung aufstellen und die kleinste ganze Jahreszahl über der Grenze bestimmen.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, wachstumsfaktor_falsch).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '380b85ad-3967-4fad-b370-e113276310a6'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '380b85ad-3967-4fad-b370-e113276310a6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '380b85ad-3967-4fad-b370-e113276310a6'::uuid,
  p_correct_answers => '["9","9 Jahre","9Jahre"]'::jsonb,
  p_solution        => '1000 · 1,05ⁿ ≥ 1500, also 1,05ⁿ ≥ 1,5.
log 1,5 : log 1,05 ≈ 8,31; ganze Jahre: aufrunden.
Probe: 1,05⁸ ≈ 1,477 < 1,5 und 1,05⁹ ≈ 1,551 ≥ 1,5.
Nach 9 Jahren.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jedes Jahr nur 50 € (5 % vom Startkapital) gerechnet: 500 : 50 = 10.","socratic_question":"Wovon werden im zweiten Jahr die 5 % berechnet?"},{"error":"Mit dem Faktor 1,5 statt 1,05 gerechnet.","socratic_question":"Wie viel ist 5 % als Dezimalzahl, und wie heißt dann der Faktor?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["9 Jahre","9Jahre"],"known_errors":{"1":"wachstumsfaktor_falsch","10":"prozente_addiert","10 Jahre":"prozente_addiert","10Jahre":"prozente_addiert","1 Jahre":"wachstumsfaktor_falsch","1Jahre":"wachstumsfaktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 exp-anwendung-02 · Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '167c44e0-d197-4696-951a-a17b5f8337c4'::uuid, 'exercise', 'Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg', 'Von einem Stoff sind zu Beginn 80 mg im Blut. Die Menge nimmt jede Stunde um 15 % ab.

Gib die Anzahl der ganzen Stunden an, nach denen erstmals höchstens 20 mg im Blut sind.',
  '{"kind":"short_input","prompt":"Von einem Stoff sind zu Beginn 80 mg im Blut. Die Menge nimmt jede Stunde um 15 % ab.\n\nGib die Anzahl der ganzen Stunden an, nach denen erstmals höchstens 20 mg im Blut sind."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Modellieren, Operieren',
  75, 'h', false, 2, 'draft', 'edvance_k10_exp', 'exp-anwendung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Abnahmefaktor bilden, Gleichung lösen und auf ganze Stunden aufrunden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abnahmefaktor_falsch, prozente_addiert).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '167c44e0-d197-4696-951a-a17b5f8337c4'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '167c44e0-d197-4696-951a-a17b5f8337c4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '167c44e0-d197-4696-951a-a17b5f8337c4'::uuid,
  p_correct_answers => '["9","9 h","9h"]'::jsonb,
  p_solution        => '80 · 0,85ⁿ ≤ 20, also 0,85ⁿ ≤ 0,25.
log 0,25 : log 0,85 ≈ 8,53; ganze Stunden: aufrunden.
Probe: 0,85⁸ ≈ 0,272 > 0,25 und 0,85⁹ ≈ 0,232 ≤ 0,25.
Nach 9 Stunden.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit dem Faktor 0,15 statt 0,85 gerechnet.","socratic_question":"Wie viel Prozent der Menge sind nach einer Stunde noch da?"},{"error":"Jede Stunde 15 % der Anfangsmenge (12 mg) abgezogen: 60 : 12 = 5.","socratic_question":"Wovon werden in der zweiten Stunde die 15 % berechnet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["9 h","9h"],"known_errors":{"1":"abnahmefaktor_falsch","5":"prozente_addiert","1 h":"abnahmefaktor_falsch","1h":"abnahmefaktor_falsch","5 h":"prozente_addiert","5h":"prozente_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 exp-anwendung-03 · Bestand · Fische, jedes Jahr auf 80 %, unter 500
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e53c873e-f152-495a-a550-23751c7be490'::uuid, 'exercise', 'Bestand · Fische, jedes Jahr auf 80 %, unter 500', 'In einem See leben 2000 Fische. Der Bestand sinkt jedes Jahr auf 80 % des Vorjahres.

Gib die Anzahl der ganzen Jahre an, nach denen erstmals weniger als 500 Fische im See leben.',
  '{"kind":"short_input","prompt":"In einem See leben 2000 Fische. Der Bestand sinkt jedes Jahr auf 80 % des Vorjahres.\n\nGib die Anzahl der ganzen Jahre an, nach denen erstmals weniger als 500 Fische im See leben."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'Jahre', false, null, 'draft', 'edvance_k10_exp', 'exp-anwendung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: „auf 80 %\" als Faktor 0,8 deuten, Gleichung lösen, auf ganze Jahre aufrunden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (rate_aus_faktor_falsch, linear_statt_exponentiell).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e53c873e-f152-495a-a550-23751c7be490'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e53c873e-f152-495a-a550-23751c7be490'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e53c873e-f152-495a-a550-23751c7be490'::uuid,
  p_correct_answers => '["7","7 Jahre","7Jahre"]'::jsonb,
  p_solution        => '2000 · 0,8ⁿ < 500, also 0,8ⁿ < 0,25.
log 0,25 : log 0,8 ≈ 6,21; ganze Jahre: aufrunden.
Probe: 0,8⁶ ≈ 0,262 ≥ 0,25 und 0,8⁷ ≈ 0,210 < 0,25.
Nach 7 Jahren.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"„Auf 80 %\" als Abnahme um 80 % gelesen und mit dem Faktor 0,2 gerechnet.","socratic_question":"Heißt „sinkt auf 80 %\", dass 80 % übrig bleiben oder dass 80 % wegfallen?"},{"error":"Jedes Jahr 400 Fische abgezogen: 1500 : 400 = 3,75, also 4 Jahre.","socratic_question":"Sinkt der Bestand jedes Jahr um dieselbe Anzahl oder auf denselben Anteil?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["7 Jahre","7Jahre"],"known_errors":{"1":"rate_aus_faktor_falsch","4":"linear_statt_exponentiell","1 Jahre":"rate_aus_faktor_falsch","1Jahre":"rate_aus_faktor_falsch","4 Jahre":"linear_statt_exponentiell","4Jahre":"linear_statt_exponentiell"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 exp-anwendung-04 · Zerfall · Halbwertszeit 6 Stunden, unter 10 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0054a031-7aae-4035-a3e5-1e3c698c35d6'::uuid, 'exercise', 'Zerfall · Halbwertszeit 6 Stunden, unter 10 %', 'Ein radioaktiver Stoff hat eine Halbwertszeit von 6 Stunden.

Gib die Anzahl der ganzen Stunden an, nach denen erstmals weniger als 10 % der Anfangsmenge vorhanden sind.',
  '{"kind":"short_input","prompt":"Ein radioaktiver Stoff hat eine Halbwertszeit von 6 Stunden.\n\nGib die Anzahl der ganzen Stunden an, nach denen erstmals weniger als 10 % der Anfangsmenge vorhanden sind."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'h', false, 1, 'draft', 'edvance_k10_exp', 'exp-anwendung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zeit über die Halbwertszeit in die Hochzahl einbauen, logarithmieren und aufrunden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeit_statt_perioden, linear_statt_exponentiell).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0054a031-7aae-4035-a3e5-1e3c698c35d6'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0054a031-7aae-4035-a3e5-1e3c698c35d6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0054a031-7aae-4035-a3e5-1e3c698c35d6'::uuid,
  p_correct_answers => '["20","20 h","20h"]'::jsonb,
  p_solution        => 'Nach t Stunden ist der Anteil 0,5^(t/6).
0,5^(t/6) < 0,1 ergibt t/6 > log 0,1 : log 0,5 ≈ 3,32, also t > 6 · 3,32 ≈ 19,93.
Ganze Stunden: aufrunden, nach 20 Stunden.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Stunden direkt als Hochzahl genommen: 0,5ᵗ < 0,1.","socratic_question":"Halbiert sich die Menge jede Stunde oder alle 6 Stunden?"},{"error":"Linear gerechnet: alle 6 Stunden 50 % der Anfangsmenge weg, für 90 % also 10,8 Stunden.","socratic_question":"Wird in jeder Halbwertszeit dieselbe Menge abgebaut oder derselbe Anteil?"}]'::jsonb,
  p_acceptance      => '{"canonical":"20","equivalents":["20 h","20h"],"known_errors":{"4":"zeit_statt_perioden","11":"linear_statt_exponentiell","4 h":"zeit_statt_perioden","4h":"zeit_statt_perioden","11 h":"linear_statt_exponentiell","11h":"linear_statt_exponentiell"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 exp-anwendung-05 · Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c6e6dac0-bbb7-49ce-b424-f3ce3806c1a1'::uuid, 'exercise', 'Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl', 'Am Ende des Jahres 2020 hat eine Gemeinde 8000 Einwohner. Die Einwohnerzahl wächst jedes Jahr um 1,5 %.

Am Ende welchen Jahres hat die Gemeinde erstmals mehr als 9000 Einwohner? Rechne mit ganzen Jahren und gib die Jahreszahl an.',
  '{"kind":"short_input","prompt":"Am Ende des Jahres 2020 hat eine Gemeinde 8000 Einwohner. Die Einwohnerzahl wächst jedes Jahr um 1,5 %.\n\nAm Ende welchen Jahres hat die Gemeinde erstmals mehr als 9000 Einwohner? Rechne mit ganzen Jahren und gib die Jahreszahl an."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k10_exp', 'exp-anwendung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zeitpunkt berechnen und als Jahreszahl angeben (Anzahl der Jahre zum Startjahr addieren).","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, prozente_addiert).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c6e6dac0-bbb7-49ce-b424-f3ce3806c1a1'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c6e6dac0-bbb7-49ce-b424-f3ce3806c1a1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c6e6dac0-bbb7-49ce-b424-f3ce3806c1a1'::uuid,
  p_correct_answers => '["2028","+2028"]'::jsonb,
  p_solution        => '8000 · 1,015ⁿ > 9000, also 1,015ⁿ > 1,125.
log 1,125 : log 1,015 ≈ 7,91; ganze Jahre: n = 8.
Probe: 1,015⁷ ≈ 1,110 < 1,125 und 1,015⁸ ≈ 1,126 > 1,125.
2020 + 8 = 2028.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Anzahl der Jahre angegeben statt der Jahreszahl.","socratic_question":"Gefragt ist ein Jahr – in welchem Jahr ist das?"},{"error":"Jedes Jahr nur 1,5 % der Anfangszahl (120 Einwohner) addiert: 1000 : 120 ≈ 8,3, also 9 Jahre.","socratic_question":"Wovon werden im zweiten Jahr die 1,5 % berechnet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2028","equivalents":["+2028"],"known_errors":{"8":"falsche_groesse_beantwortet","2029":"prozente_addiert","+8":"falsche_groesse_beantwortet","+2029":"prozente_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 exp-anwendung-06 · Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7e3a4210-981c-424c-ba76-6d326165e335'::uuid, 'exercise', 'Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %', 'Anlage A: 2000 € werden mit 8 % pro Jahr verzinst. Anlage B: 5000 € werden mit 3 % pro Jahr verzinst. Bei beiden werden die Zinsen mitverzinst.

Gib die Anzahl der ganzen Jahre an, nach denen Anlage A erstmals mehr Geld enthält als Anlage B.',
  '{"kind":"short_input","prompt":"Anlage A: 2000 € werden mit 8 % pro Jahr verzinst. Anlage B: 5000 € werden mit 3 % pro Jahr verzinst. Bei beiden werden die Zinsen mitverzinst.\n\nGib die Anzahl der ganzen Jahre an, nach denen Anlage A erstmals mehr Geld enthält als Anlage B."}'::jsonb, 'NUMERIC', 'fkt_exp_anwendung',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, 'Jahre', false, null, 'draft', 'edvance_k10_exp', 'exp-anwendung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: zwei exponentielle Modelle gleichsetzen, durch Umformen auf bˣ = c bringen, logarithmieren und aufrunden.","charge":"k10-exp"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-exp"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-exp"},"cluster_id":{"art":"neu","grund":"Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.","charge":"k10-exp"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).","charge":"k10-exp"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-exp"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-exp"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-exp"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-exp"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zu_frueh_gerundet, prozente_addiert).","charge":"k10-exp"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-exp"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7e3a4210-981c-424c-ba76-6d326165e335'::uuid and t.status = 'draft' and t.source = 'edvance_k10_exp')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7e3a4210-981c-424c-ba76-6d326165e335'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7e3a4210-981c-424c-ba76-6d326165e335'::uuid,
  p_correct_answers => '["20","20 Jahre","20Jahre"]'::jsonb,
  p_solution        => '2000 · 1,08ⁿ > 5000 · 1,03ⁿ, also (1,08 : 1,03)ⁿ > 5000 : 2000 = 2,5.
n > log 2,5 : log(1,08 : 1,03) ≈ 0,39794 : 0,02059 ≈ 19,33.
Ganze Jahre: aufrunden, nach 20 Jahren.
(Den Quotienten 1,08 : 1,03 nicht vorher runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Quotienten 1,08 : 1,03 ≈ 1,0485 auf 1,05 gerundet.","socratic_question":"Was passiert mit dem Ergebnis, wenn du den Faktor vor dem Logarithmieren rundest?"},{"error":"Jedes Jahr gleiche Zinsen gerechnet: A + 160 €, B + 150 €, also erst nach 301 Jahren.","socratic_question":"Bleiben die Zinsen jedes Jahr gleich, wenn sie mitverzinst werden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"20","equivalents":["20 Jahre","20Jahre"],"known_errors":{"19":"zu_frueh_gerundet","301":"prozente_addiert","19 Jahre":"zu_frueh_gerundet","19Jahre":"zu_frueh_gerundet","301 Jahre":"prozente_addiert","301Jahre":"prozente_addiert"}}'::jsonb);
  end if;
end
$loesung$;
