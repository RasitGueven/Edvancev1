-- K9-Rest, Thema quadrfkt — 30 Aufgaben: je sechs zu fkt_quadr_parabel, _scheitel, _normalform, _nullstellen und _extrem.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-quadrfkt.json (Quelle: tools/k9-quadrfkt-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105856_substrat_k9_quadrfkt.sql (Knoten + Fehlbild-Slugs muessen stehen).
-- Vier Aufgaben mit Abbildung (Generator koordinatensystem, task_figures ohne svg_hash; Upload per scripts/figures/upload_figures.py).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Wasserstrahl, Brückenbogen, Wurfbahn, Ball) und eine AFB III (Rückrichtung oder Problemlösen, Zaun an der Mauer). Scheitelpunkte und Nullstellenpaare als MULTI_PART (Eingabe nur Zahlen). Vier Aufgaben mit Parabel im Koordinatensystem, alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt, ob exakt oder gerundet; alle Werte exakt nachgerechnet.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-quadrfkt.csv. Pruefprotokoll: docs/prefill/k9-quadrfkt-verifikation.md.
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
--   fkt_quadr_parabel: quadrfkt-parabel-06 = 1, quadrfkt-parabel-03 = 2. Rang 1 aus Profil {koordinate_vorzeichen_verloren,mal_exponent,umgekehrt_geteilt}, Rang 2 aus Profil {vorrang_ignoriert,vorzeichen_potenz} (2 neue Fehlbilder)
--   fkt_quadr_scheitel: quadrfkt-scheitel-03 = 1, quadrfkt-scheitel-04 = 2. Rang 1 aus Profil {koordinate_vorzeichen_verloren,koordinaten_vertauscht,vorzeichen_aus_klammer}, Rang 2 aus Profil {koordinaten_vertauscht,vorrang_ignoriert,vorzeichen_aus_klammer} (1 neue Fehlbilder)
--   fkt_quadr_normalform: quadrfkt-normalform-03 = 1, quadrfkt-normalform-06 = 2. Rang 1 aus Profil {ergaenzung_vorzeichen,halbieren_vergessen,mal_zwei_vergessen,vorzeichen_aus_klammer}, Rang 2 aus Profil {ergaenzung_vorzeichen,falsche_groesse_beantwortet} (1 neue Fehlbilder)
--   fkt_quadr_nullstellen: quadrfkt-nullstellen-03 = 1, quadrfkt-nullstellen-05 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,koordinate_vorzeichen_verloren,koordinaten_vertauscht}, Rang 2 aus Profil {pq_vorzeichen,vorzeichen_beim_umstellen} (2 neue Fehlbilder)
--   fkt_quadr_extrem: quadrfkt-extrem-03 = 1, quadrfkt-extrem-05 = 2. Rang 1 aus Profil {ergaenzung_vorzeichen,falsche_groesse_beantwortet,mal_zwei_vergessen}, Rang 2 aus Profil {ergaenzung_vorzeichen,falsche_groesse_beantwortet,vorrang_ignoriert} (1 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 quadrfkt-parabel-01 · Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0336c9f9-a802-4e69-b7aa-ee6373e590c2'::uuid, 'exercise', 'Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3', 'Gegeben ist die Funktion f(x) = 2(x − 1)² + 3.

Berechne f(4). Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 2(x − 1)² + 3.\n\nBerechne f(4). Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: eine positive Zahl in die Scheitelpunktform einsetzen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorrang_ignoriert, mal_exponent).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0336c9f9-a802-4e69-b7aa-ee6373e590c2'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0336c9f9-a802-4e69-b7aa-ee6373e590c2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0336c9f9-a802-4e69-b7aa-ee6373e590c2'::uuid,
  p_correct_answers => '["21","+21"]'::jsonb,
  p_solution        => 'Klammer zuerst: 4 − 1 = 3.
Quadrieren: 3² = 9.
Mal 2 und plus 3: f(4) = 2 · 9 + 3 = 21.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Erst mit 2 multipliziert, dann quadriert: (2 · 3)² + 3 = 39.","socratic_question":"Was wird zuerst gerechnet: das Quadrat oder das Mal 2?"},{"error":"Das Quadrat als „mal 2\" gerechnet: 3² = 6.","socratic_question":"Was bedeutet die kleine 2 an der Klammer?"}]'::jsonb,
  p_acceptance      => '{"canonical":"21","equivalents":["+21"],"known_errors":{"15":"mal_exponent","39":"vorrang_ignoriert","+39":"vorrang_ignoriert","+15":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 quadrfkt-parabel-02 · Verschiebung nach oben · aus der Abbildung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid, 'exercise', 'Verschiebung nach oben · aus der Abbildung', 'Die Abbildung zeigt eine verschobene Normalparabel.

Um wie viele Einheiten ist die Parabel gegenüber der Normalparabel nach oben verschoben? Die gesuchten Werte sind ganzzahlig.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt eine verschobene Normalparabel.\n\nUm wie viele Einheiten ist die Parabel gegenüber der Normalparabel nach oben verschoben? Die gesuchten Werte sind ganzzahlig."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, true, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: die Verschiebung einer Normalparabel am Gitter ablesen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid,
  p_correct_answers => '["3","+3"]'::jsonb,
  p_solution        => 'Der Scheitelpunkt der Normalparabel liegt bei (0|0).
Der Scheitelpunkt der abgebildeten Parabel liegt bei (2|3).
Die Parabel ist um 3 Einheiten nach oben (und um 2 nach rechts) verschoben.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Verschiebung nach rechts angegeben statt nach oben.","socratic_question":"Welche Koordinate des Scheitelpunkts sagt etwas über oben und unten?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","equivalents":["+3"],"known_errors":{"2":"koordinaten_vertauscht","+2":"koordinaten_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid, 'koordinatensystem', '{"x_min":-2,"x_max":6,"y_min":-1,"y_max":9,"funktionen":[{"typ":"quadratisch","a":1,"b":-4,"c":7}]}'::jsonb, 'Koordinatensystem mit Gitter und einer nach oben geöffneten, verschobenen Normalparabel.'
 where exists (select 1 from public.tasks t where t.id = '1e0aff9b-8268-4ac8-a77c-3a492d7c7dc8'::uuid and t.source = 'edvance_k9_quadrfkt')
on conflict (task_id) do nothing;

-- #3 quadrfkt-parabel-03 · Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '191789f5-7435-4ba3-a6f5-a94155f2b954'::uuid, 'exercise', 'Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5', 'Gegeben ist die Funktion f(x) = 3(x − 1)² − 5.

Berechne f(−2). Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben ist die Funktion f(x) = 3(x − 1)² − 5.\n\nBerechne f(−2). Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negatives Argument, die Klammer wird negativ und muss richtig quadriert werden.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, vorrang_ignoriert).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '191789f5-7435-4ba3-a6f5-a94155f2b954'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '191789f5-7435-4ba3-a6f5-a94155f2b954'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '191789f5-7435-4ba3-a6f5-a94155f2b954'::uuid,
  p_correct_answers => '["22","+22"]'::jsonb,
  p_solution        => 'Klammer zuerst: −2 − 1 = −3.
Quadrieren: (−3)² = 9.
Mal 3 und minus 5: f(−2) = 3 · 9 − 5 = 22.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Quadrat einer negativen Zahl negativ gerechnet: (−3)² = −9.","socratic_question":"Welches Vorzeichen hat das Produkt (−3) · (−3)?"},{"error":"Erst mit 3 multipliziert, dann quadriert: (3 · (−3))² − 5 = 76.","socratic_question":"Was wird zuerst gerechnet: das Quadrat oder das Mal 3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"22","equivalents":["+22"],"known_errors":{"76":"vorrang_ignoriert","-32":"vorzeichen_potenz","−32":"vorzeichen_potenz","- 32":"vorzeichen_potenz","+76":"vorrang_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 quadrfkt-parabel-04 · Streckfaktor · Parabel durch P(5|35)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '81c9b40a-8ec6-4a45-8e15-126c75b4e2eb'::uuid, 'exercise', 'Streckfaktor · Parabel durch P(5|35)', 'Die Parabel y = a · (x − 1)² + 3 geht durch den Punkt P(5|35).

Bestimme den Streckfaktor a. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Parabel y = a · (x − 1)² + 3 geht durch den Punkt P(5|35).\n\nBestimme den Streckfaktor a. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Punkt einsetzen und die Gleichung nach a umstellen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, vorzeichen_beim_umstellen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '81c9b40a-8ec6-4a45-8e15-126c75b4e2eb'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '81c9b40a-8ec6-4a45-8e15-126c75b4e2eb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '81c9b40a-8ec6-4a45-8e15-126c75b4e2eb'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => 'P einsetzen: 35 = a · (5 − 1)² + 3.
35 = a · 16 + 3, also 32 = 16 · a.
a = 32 : 16 = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Quadrat als „mal 2\" gerechnet: (5 − 1)² = 8.","socratic_question":"Was bedeutet die kleine 2 an der Klammer?"},{"error":"Die 3 beim Umstellen addiert statt subtrahiert: 38 : 16.","socratic_question":"Wie bringst du das „+ 3\" auf die andere Seite?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"mal_exponent","+4":"mal_exponent","2,375":"vorzeichen_beim_umstellen","+2,375":"vorzeichen_beim_umstellen","2.375":"vorzeichen_beim_umstellen","+2.375":"vorzeichen_beim_umstellen"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 quadrfkt-parabel-05 · Funktionswert · Wasserstrahl 5 m von der Düse
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ab03e9ba-d464-476a-9197-11b131b32469'::uuid, 'exercise', 'Funktionswert · Wasserstrahl 5 m von der Düse', 'Der Wasserstrahl eines Brunnens folgt der Funktion h(x) = −0,5 · (x − 2)² + 5. Dabei ist x der waagerechte Abstand von der Düse in Metern und h(x) die Höhe des Strahls in Metern.

Wie hoch ist der Strahl 5 m waagerecht von der Düse entfernt? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Der Wasserstrahl eines Brunnens folgt der Funktion h(x) = −0,5 · (x − 2)² + 5. Dabei ist x der waagerechte Abstand von der Düse in Metern und h(x) die Höhe des Strahls in Metern.\n\nWie hoch ist der Strahl 5 m waagerecht von der Düse entfernt? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: waagerechten Abstand als x erkennen und einsetzen, negativer Streckfaktor.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorrang_ignoriert, mal_exponent).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ab03e9ba-d464-476a-9197-11b131b32469'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ab03e9ba-d464-476a-9197-11b131b32469'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ab03e9ba-d464-476a-9197-11b131b32469'::uuid,
  p_correct_answers => '["0,5","0.5","0,5 m","0,5m"]'::jsonb,
  p_solution        => 'x = 5 einsetzen: 5 − 2 = 3, 3² = 9.
h(5) = −0,5 · 9 + 5 = −4,5 + 5 = 0,5 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Erst mit −0,5 multipliziert, dann quadriert: (−1,5)² + 5 = 7,25.","socratic_question":"Was wird zuerst gerechnet: das Quadrat oder das Mal −0,5?"},{"error":"Das Quadrat als „mal 2\" gerechnet: 3² = 6.","socratic_question":"Was bedeutet die kleine 2 an der Klammer?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,5","equivalents":["0.5","0,5 m","0,5m"],"known_errors":{"2":"mal_exponent","7,25":"vorrang_ignoriert","7.25":"vorrang_ignoriert","7,25 m":"vorrang_ignoriert","7,25m":"vorrang_ignoriert","2 m":"mal_exponent","2m":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 quadrfkt-parabel-06 · Streckfaktor · aus Scheitel und Punkt in der Abbildung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '787e947c-ce58-403a-8057-a15a82b50f94'::uuid, 'exercise', 'Streckfaktor · aus Scheitel und Punkt in der Abbildung', 'Die Abbildung zeigt eine Parabel, die aus der Normalparabel durch Strecken und Verschieben entsteht. Eingezeichnet sind ihr Scheitelpunkt S und ein weiterer Punkt P. Beide haben ganzzahlige Koordinaten.

Bestimme den Streckfaktor a der Parabel. Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt eine Parabel, die aus der Normalparabel durch Strecken und Verschieben entsteht. Eingezeichnet sind ihr Scheitelpunkt S und ein weiterer Punkt P. Beide haben ganzzahlige Koordinaten.\n\nBestimme den Streckfaktor a der Parabel. Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_parabel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, true, 1, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-parabel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Scheitelpunkt und zweiten Punkt ablesen, die Scheitelpunktform selbst aufstellen und nach a umstellen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, umgekehrt_geteilt, koordinate_vorzeichen_verloren).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '787e947c-ce58-403a-8057-a15a82b50f94'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '787e947c-ce58-403a-8057-a15a82b50f94'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '787e947c-ce58-403a-8057-a15a82b50f94'::uuid,
  p_correct_answers => '["0,5","+0,5","0.5","+0.5"]'::jsonb,
  p_solution        => 'Ablesen: S(1|−3) und P(5|5).
Scheitelpunktform: y = a · (x − 1)² − 3.
P einsetzen: 5 = a · (5 − 1)² − 3, also 8 = 16 · a.
a = 8 : 16 = 0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Quadrat als „mal 2\" gerechnet: (5 − 1)² = 8.","socratic_question":"Was bedeutet die kleine 2 an der Klammer?"},{"error":"Umgekehrt geteilt: 16 : 8 statt 8 : 16.","socratic_question":"Welche Zahl steht in 8 = a · 16 neben a – durch welche musst du teilen?"},{"error":"Die y-Koordinate des Scheitels ohne Minus gelesen: S(1|3).","socratic_question":"Liegt der Scheitelpunkt über oder unter der x-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,5","equivalents":["+0,5","0.5","+0.5"],"known_errors":{"1":"mal_exponent","2":"umgekehrt_geteilt","+1":"mal_exponent","+2":"umgekehrt_geteilt","0,125":"koordinate_vorzeichen_verloren","+0,125":"koordinate_vorzeichen_verloren","0.125":"koordinate_vorzeichen_verloren","+0.125":"koordinate_vorzeichen_verloren"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '787e947c-ce58-403a-8057-a15a82b50f94'::uuid, 'koordinatensystem', '{"x_min":-4,"x_max":6,"y_min":-4,"y_max":6,"funktionen":[{"typ":"quadratisch","a":0.5,"b":-1,"c":-2.5}],"punkte":[{"x":1,"y":-3,"label":"S"},{"x":5,"y":5,"label":"P"}]}'::jsonb, 'Koordinatensystem mit Gitter und einer nach oben geöffneten Parabel; ihr Scheitelpunkt S und ein Punkt P sind markiert.'
 where exists (select 1 from public.tasks t where t.id = '787e947c-ce58-403a-8057-a15a82b50f94'::uuid and t.source = 'edvance_k9_quadrfkt')
on conflict (task_id) do nothing;

-- #7 quadrfkt-scheitel-01 · Scheitelpunkt · y = (x − 3)² + 1
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f96d3513-0ae9-4316-a871-4bf72aff96c3'::uuid, 'exercise', 'Scheitelpunkt · y = (x − 3)² + 1', 'Gegeben ist die Parabel y = (x − 3)² + 1.

Gib die Koordinaten ihres Scheitelpunkts an. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: S(d|e) direkt aus der Scheitelpunktform ablesen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, koordinaten_vertauscht).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f96d3513-0ae9-4316-a871-4bf72aff96c3'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f96d3513-0ae9-4316-a871-4bf72aff96c3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f96d3513-0ae9-4316-a871-4bf72aff96c3'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["1","+1"]}'::jsonb,
  p_solution        => 'Scheitelpunktform y = (x − d)² + e mit S(d|e).
(x − 3) wird null für x = 3, also d = 3.
Außerhalb der Klammer steht + 1, also e = 1.
S(3|1).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Vorzeichen aus der Klammer übernommen: −3 statt 3.","socratic_question":"Für welches x wird die Klammer (x − 3) null?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Zahl steht außerhalb der Klammer?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","equivalents":["+3"],"known_errors":{"-3":"vorzeichen_aus_klammer","−3":"vorzeichen_aus_klammer","- 3":"vorzeichen_aus_klammer"}},"2":{"canonical":"1","equivalents":["+1"],"known_errors":{"3":"koordinaten_vertauscht","+3":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #8 quadrfkt-scheitel-02 · Scheitelpunkt · aus der Abbildung ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid, 'exercise', 'Scheitelpunkt · aus der Abbildung ablesen', 'Die Abbildung zeigt eine nach oben geöffnete Parabel.

Lies die Koordinaten ihres Scheitelpunkts ab. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, true, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: den tiefsten Punkt einer Parabel am Gitter ablesen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (koordinaten_vertauscht, koordinate_vorzeichen_verloren).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid,
  p_correct_answers => '{"1":["-2","−2","- 2"],"2":["-3","−3","- 3"]}'::jsonb,
  p_solution        => 'Der tiefste Punkt der Parabel ist der Scheitelpunkt.
Er liegt 2 Einheiten links der y-Achse: x = -2.
Er liegt 3 Einheiten unter der x-Achse: y = -3.
S(−2|−3).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Achse zeigt nach rechts?"},{"error":"Das Minus vergessen: Der Scheitel liegt links der y-Achse.","socratic_question":"Liegt der Scheitelpunkt links oder rechts der y-Achse?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Achse zeigt nach oben?"},{"error":"Das Minus vergessen: Der Scheitel liegt unter der x-Achse.","socratic_question":"Liegt der Scheitelpunkt über oder unter der x-Achse?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"2":"koordinate_vorzeichen_verloren","-3":"koordinaten_vertauscht","−3":"koordinaten_vertauscht","- 3":"koordinaten_vertauscht","+2":"koordinate_vorzeichen_verloren"}},"2":{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"3":"koordinate_vorzeichen_verloren","-2":"koordinaten_vertauscht","−2":"koordinaten_vertauscht","- 2":"koordinaten_vertauscht","+3":"koordinate_vorzeichen_verloren"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid, 'koordinatensystem', '{"x_min":-6,"x_max":2,"y_min":-4,"y_max":5,"funktionen":[{"typ":"quadratisch","a":1,"b":4,"c":1}]}'::jsonb, 'Koordinatensystem mit Gitter und einer nach oben geöffneten Parabel.'
 where exists (select 1 from public.tasks t where t.id = 'a43a1329-4880-456e-8865-1b1cd82e2862'::uuid and t.source = 'edvance_k9_quadrfkt')
on conflict (task_id) do nothing;

-- #9 quadrfkt-scheitel-03 · Scheitelpunkt · y = −2(x + 4)² − 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1d8a70aa-9010-4259-9278-5cbc6425d3c0'::uuid, 'exercise', 'Scheitelpunkt · y = −2(x + 4)² − 5', 'Gegeben ist die Parabel y = −2(x + 4)² − 5.

Gib die Koordinaten ihres Scheitelpunkts an. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Plus in der Klammer und negativer Streckfaktor, der Faktor gehört nicht zum Scheitel.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, koordinaten_vertauscht, koordinate_vorzeichen_verloren).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1d8a70aa-9010-4259-9278-5cbc6425d3c0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1d8a70aa-9010-4259-9278-5cbc6425d3c0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1d8a70aa-9010-4259-9278-5cbc6425d3c0'::uuid,
  p_correct_answers => '{"1":["-4","−4","- 4"],"2":["-5","−5","- 5"]}'::jsonb,
  p_solution        => 'y = a(x − d)² + e mit S(d|e); der Faktor −2 ändert nur Öffnung und Streckung.
(x + 4) wird null für x = −4, also d = -4.
Außerhalb der Klammer steht − 5, also e = -5.
S(−4|−5).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Vorzeichen aus der Klammer übernommen: 4 statt −4.","socratic_question":"Für welches x wird die Klammer (x + 4) null?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Zahl steht in der Klammer?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Zahl steht außerhalb der Klammer?"},{"error":"Das Minus vor der 5 nicht übernommen.","socratic_question":"Welches Rechenzeichen steht vor der 5?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-4","equivalents":["−4","- 4"],"known_errors":{"4":"vorzeichen_aus_klammer","+4":"vorzeichen_aus_klammer","-5":"koordinaten_vertauscht","−5":"koordinaten_vertauscht","- 5":"koordinaten_vertauscht"}},"2":{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"5":"koordinate_vorzeichen_verloren","-4":"koordinaten_vertauscht","−4":"koordinaten_vertauscht","- 4":"koordinaten_vertauscht","+5":"koordinate_vorzeichen_verloren"}}}'::jsonb);
  end if;
end
$loesung$;

-- #10 quadrfkt-scheitel-04 · Scheitelpunkt · y = 4 − 2(x − 6)²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f70e9312-b530-4b4b-9c7a-087ef87fbba9'::uuid, 'exercise', 'Scheitelpunkt · y = 4 − 2(x − 6)²', 'Gegeben ist die Parabel y = 4 − 2(x − 6)².

Gib die Koordinaten ihres Scheitelpunkts an. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: ungewohnte Reihenfolge, die Scheitelpunktform muss erst erkannt werden.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, koordinaten_vertauscht, vorrang_ignoriert).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f70e9312-b530-4b4b-9c7a-087ef87fbba9'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f70e9312-b530-4b4b-9c7a-087ef87fbba9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f70e9312-b530-4b4b-9c7a-087ef87fbba9'::uuid,
  p_correct_answers => '{"1":["6","+6"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'Umgestellt: y = −2(x − 6)² + 4.
(x − 6) wird null für x = 6, also d = 6.
Außerhalb der Klammer steht + 4, also e = 4.
S(6|4).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Vorzeichen aus der Klammer übernommen: −6 statt 6.","socratic_question":"Für welches x wird die Klammer (x − 6) null?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Zahl steht in der Klammer?"},{"error":"x- und y-Koordinate vertauscht.","socratic_question":"Welche Zahl steht außerhalb der Klammer?"},{"error":"Die 4 mit der −2 verrechnet: 4 − 2 = 2.","socratic_question":"Gehört die −2 zur 4 oder zur Klammer?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"6","equivalents":["+6"],"known_errors":{"4":"koordinaten_vertauscht","-6":"vorzeichen_aus_klammer","−6":"vorzeichen_aus_klammer","- 6":"vorzeichen_aus_klammer","+4":"koordinaten_vertauscht"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"2":"vorrang_ignoriert","6":"koordinaten_vertauscht","+6":"koordinaten_vertauscht","+2":"vorrang_ignoriert"}}}'::jsonb);
  end if;
end
$loesung$;

-- #11 quadrfkt-scheitel-05 · Scheitelpunkt · Brückenbogen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0d7af296-4ca7-4db4-8c2e-d0f922d9150c'::uuid, 'exercise', 'Scheitelpunkt · Brückenbogen', 'Ein Brückenbogen hat die Form h(x) = −0,02 · (x − 25)² + 12,5. Dabei ist x der waagerechte Abstand vom linken Fußpunkt in Metern und h(x) die Höhe in Metern.

Wo liegt der höchste Punkt des Bogens? Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Abstand des höchsten Punkts vom linken Fußpunkt in m","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Höhe des höchsten Punkts in m","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: den höchsten Punkt als Scheitelpunkt erkennen, Dezimalzahlen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, koordinaten_vertauscht).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0d7af296-4ca7-4db4-8c2e-d0f922d9150c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0d7af296-4ca7-4db4-8c2e-d0f922d9150c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0d7af296-4ca7-4db4-8c2e-d0f922d9150c'::uuid,
  p_correct_answers => '{"1":["25","+25"],"2":["12,5","+12,5","12.5","+12.5"]}'::jsonb,
  p_solution        => 'Der Faktor −0,02 ist negativ: Die Parabel ist nach unten geöffnet, der Scheitel ist der höchste Punkt.
S(25|12,5).
Abstand vom linken Fußpunkt: 25 m. Höhe: 12,5 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Vorzeichen aus der Klammer übernommen: −25 statt 25.","socratic_question":"Für welches x wird die Klammer (x − 25) null?"},{"error":"Die Höhe angegeben statt des Abstands.","socratic_question":"Welche Zahl gehört zu x, welche zu h?"},{"error":"Den Abstand angegeben statt der Höhe.","socratic_question":"Welche Zahl gehört zu x, welche zu h?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"25","equivalents":["+25"],"known_errors":{"-25":"vorzeichen_aus_klammer","−25":"vorzeichen_aus_klammer","- 25":"vorzeichen_aus_klammer","12,5":"koordinaten_vertauscht","+12,5":"koordinaten_vertauscht","12.5":"koordinaten_vertauscht","+12.5":"koordinaten_vertauscht"}},"2":{"canonical":"12,5","equivalents":["+12,5","12.5","+12.5"],"known_errors":{"25":"koordinaten_vertauscht","+25":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #12 quadrfkt-scheitel-06 · Rückrichtung · c aus dem Scheitel S(2|−1)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f8f95f00-a759-4d59-8294-542bb7e5b0c7'::uuid, 'exercise', 'Rückrichtung · c aus dem Scheitel S(2|−1)', 'Eine nach oben geöffnete Normalparabel (a = 1) hat den Scheitelpunkt S(2|−1). Ihre Gleichung lässt sich als y = x² + bx + c schreiben.

Welchen Wert hat c? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine nach oben geöffnete Normalparabel (a = 1) hat den Scheitelpunkt S(2|−1). Ihre Gleichung lässt sich als y = x² + bx + c schreiben.\n\nWelchen Wert hat c? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_scheitel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-scheitel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – Scheitelpunktform aufstellen und in die Normalform ausmultiplizieren.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_potenz, koordinate_vorzeichen_verloren).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f8f95f00-a759-4d59-8294-542bb7e5b0c7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f8f95f00-a759-4d59-8294-542bb7e5b0c7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f8f95f00-a759-4d59-8294-542bb7e5b0c7'::uuid,
  p_correct_answers => '["3","+3"]'::jsonb,
  p_solution        => 'Scheitelpunktform: y = (x − 2)² − 1.
Ausmultiplizieren: (x − 2)² = x² − 4x + 4.
y = x² − 4x + 4 − 1 = x² − 4x + 3, also c = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Quadrat von −2 negativ gerechnet: (−2)² = −4.","socratic_question":"Welches Vorzeichen hat (−2) · (−2)?"},{"error":"Die y-Koordinate des Scheitels ohne Minus übernommen: + 1 statt − 1.","socratic_question":"Liegt der Scheitelpunkt über oder unter der x-Achse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","equivalents":["+3"],"known_errors":{"5":"koordinate_vorzeichen_verloren","-5":"vorzeichen_potenz","−5":"vorzeichen_potenz","- 5":"vorzeichen_potenz","+5":"koordinate_vorzeichen_verloren"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 quadrfkt-normalform-01 · Quadratische Ergänzung · y = x² − 6x + 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ed2fb959-2f69-40c1-a8a7-7549097e3fb3'::uuid, 'exercise', 'Quadratische Ergänzung · y = x² − 6x + 5', 'Gegeben ist die Parabel y = x² − 6x + 5.

Bestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: quadratische Ergänzung mit a = 1 und geradem b.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, halbieren_vergessen, ergaenzung_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ed2fb959-2f69-40c1-a8a7-7549097e3fb3'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ed2fb959-2f69-40c1-a8a7-7549097e3fb3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ed2fb959-2f69-40c1-a8a7-7549097e3fb3'::uuid,
  p_correct_answers => '{"1":["3","+3"],"2":["-4","−4","- 4"]}'::jsonb,
  p_solution        => 'Halbe Zahl vor x: 6 : 2 = 3, ihr Quadrat 9.
y = x² − 6x + 9 − 9 + 5 = (x − 3)² − 4.
Scheitelpunkt: x = 3, y = -4, also S(3|−4).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x − 3)² den Wert −3 abgelesen.","socratic_question":"Für welches x wird die Klammer (x − 3) null?"},{"error":"Die Zahl vor x nicht halbiert: 6 statt 3.","socratic_question":"Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 6x + …?"},{"error":"Die Ergänzung 9 addiert statt abgezogen: 5 + 9 = 14.","socratic_question":"Du hast + 9 ergänzt – was musst du danach tun, damit der Term gleich bleibt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"3","equivalents":["+3"],"known_errors":{"6":"halbieren_vergessen","-3":"vorzeichen_aus_klammer","−3":"vorzeichen_aus_klammer","- 3":"vorzeichen_aus_klammer","+6":"halbieren_vergessen"}},"2":{"canonical":"-4","equivalents":["−4","- 4"],"known_errors":{"14":"ergaenzung_vorzeichen","+14":"ergaenzung_vorzeichen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #14 quadrfkt-normalform-02 · Quadratische Ergänzung · y = x² + 4x + 1
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dc585f12-7da2-4909-baeb-ceda0b4af570'::uuid, 'exercise', 'Quadratische Ergänzung · y = x² + 4x + 1', 'Gegeben ist die Parabel y = x² + 4x + 1.

Bestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: quadratische Ergänzung mit a = 1, positives b.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, halbieren_vergessen, ergaenzung_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'dc585f12-7da2-4909-baeb-ceda0b4af570'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dc585f12-7da2-4909-baeb-ceda0b4af570'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'dc585f12-7da2-4909-baeb-ceda0b4af570'::uuid,
  p_correct_answers => '{"1":["-2","−2","- 2"],"2":["-3","−3","- 3"]}'::jsonb,
  p_solution        => 'Halbe Zahl vor x: 4 : 2 = 2, ihr Quadrat 4.
y = x² + 4x + 4 − 4 + 1 = (x + 2)² − 3.
Scheitelpunkt: x = -2, y = -3, also S(−2|−3).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x + 2)² den Wert 2 abgelesen.","socratic_question":"Für welches x wird die Klammer (x + 2) null?"},{"error":"Die Zahl vor x nicht halbiert: −4 statt −2.","socratic_question":"Welche Zahl steht in der binomischen Formel (x + ?)² = x² + 4x + …?"},{"error":"Die Ergänzung 4 addiert statt abgezogen: 1 + 4 = 5.","socratic_question":"Du hast + 4 ergänzt – was musst du danach tun, damit der Term gleich bleibt?"},{"error":"Die Zahl vor x nicht halbiert und 4² = 16 ergänzt.","socratic_question":"Welche Zahl musst du quadrieren: 4 oder die Hälfte davon?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"2":"vorzeichen_aus_klammer","+2":"vorzeichen_aus_klammer","-4":"halbieren_vergessen","−4":"halbieren_vergessen","- 4":"halbieren_vergessen"}},"2":{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"5":"ergaenzung_vorzeichen","+5":"ergaenzung_vorzeichen","-15":"halbieren_vergessen","−15":"halbieren_vergessen","- 15":"halbieren_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #15 quadrfkt-normalform-03 · Quadratische Ergänzung · y = 2x² − 8x + 3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '45076244-62bd-4ca6-83a7-52308dfcbc8f'::uuid, 'exercise', 'Quadratische Ergänzung · y = 2x² − 8x + 3', 'Gegeben ist die Parabel y = 2x² − 8x + 3.

Bestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst den Faktor 2 ausklammern, dann ergänzen; der Faktor wirkt auf die abgezogene Zahl.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, halbieren_vergessen, ergaenzung_vorzeichen, mal_zwei_vergessen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '45076244-62bd-4ca6-83a7-52308dfcbc8f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '45076244-62bd-4ca6-83a7-52308dfcbc8f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '45076244-62bd-4ca6-83a7-52308dfcbc8f'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["-5","−5","- 5"]}'::jsonb,
  p_solution        => 'Ausklammern: y = 2(x² − 4x) + 3.
Ergänzen: y = 2(x² − 4x + 4 − 4) + 3 = 2(x − 2)² − 8 + 3 = 2(x − 2)² − 5.
Scheitelpunkt: x = 2, y = -5, also S(2|−5).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x − 2)² den Wert −2 abgelesen.","socratic_question":"Für welches x wird die Klammer (x − 2) null?"},{"error":"Die Zahl vor x in der Klammer nicht halbiert: 4 statt 2.","socratic_question":"Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 4x + …?"},{"error":"Die Ergänzung addiert statt abgezogen: 2 · 4 + 3 = 11.","socratic_question":"Du hast in der Klammer + 4 ergänzt – was musst du danach abziehen?"},{"error":"Die abgezogene 4 nicht mit dem ausgeklammerten Faktor 2 multipliziert: 3 − 4 = −1.","socratic_question":"Was passiert mit der − 4, wenn du die Klammer mit 2 wieder auflöst?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"halbieren_vergessen","-2":"vorzeichen_aus_klammer","−2":"vorzeichen_aus_klammer","- 2":"vorzeichen_aus_klammer","+4":"halbieren_vergessen"}},"2":{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"11":"ergaenzung_vorzeichen","+11":"ergaenzung_vorzeichen","-1":"mal_zwei_vergessen","−1":"mal_zwei_vergessen","- 1":"mal_zwei_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #16 quadrfkt-normalform-04 · Quadratische Ergänzung · y = x² − 5x + 2
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cd17cea3-1055-4a70-a247-dab0845293c7'::uuid, 'exercise', 'Quadratische Ergänzung · y = x² − 5x + 2', 'Gegeben ist die Parabel y = x² − 5x + 2.

Bestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate des Scheitelpunkts","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: ungerades b, die Ergänzung ist eine Dezimalzahl.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, halbieren_vergessen, ergaenzung_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cd17cea3-1055-4a70-a247-dab0845293c7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cd17cea3-1055-4a70-a247-dab0845293c7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cd17cea3-1055-4a70-a247-dab0845293c7'::uuid,
  p_correct_answers => '{"1":["2,5","+2,5","2.5","+2.5"],"2":["-4,25","−4,25","- 4,25","-4.25","−4.25","- 4.25"]}'::jsonb,
  p_solution        => 'Halbe Zahl vor x: 5 : 2 = 2,5, ihr Quadrat 6,25.
y = x² − 5x + 6,25 − 6,25 + 2 = (x − 2,5)² − 4,25.
Scheitelpunkt: x = 2,5, y = -4,25, also S(2,5|−4,25).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x − 2,5)² den Wert −2,5 abgelesen.","socratic_question":"Für welches x wird die Klammer (x − 2,5) null?"},{"error":"Die Zahl vor x nicht halbiert: 5 statt 2,5.","socratic_question":"Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 5x + …?"},{"error":"Die Ergänzung 6,25 addiert statt abgezogen: 2 + 6,25 = 8,25.","socratic_question":"Du hast + 6,25 ergänzt – was musst du danach tun, damit der Term gleich bleibt?"},{"error":"Die Zahl vor x nicht halbiert und 5² = 25 ergänzt.","socratic_question":"Welche Zahl musst du quadrieren: 5 oder die Hälfte davon?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2,5","equivalents":["+2,5","2.5","+2.5"],"known_errors":{"5":"halbieren_vergessen","-2,5":"vorzeichen_aus_klammer","−2,5":"vorzeichen_aus_klammer","- 2,5":"vorzeichen_aus_klammer","-2.5":"vorzeichen_aus_klammer","−2.5":"vorzeichen_aus_klammer","- 2.5":"vorzeichen_aus_klammer","+5":"halbieren_vergessen"}},"2":{"canonical":"-4,25","equivalents":["−4,25","- 4,25","-4.25","−4.25","- 4.25"],"known_errors":{"8,25":"ergaenzung_vorzeichen","+8,25":"ergaenzung_vorzeichen","8.25":"ergaenzung_vorzeichen","+8.25":"ergaenzung_vorzeichen","-23":"halbieren_vergessen","−23":"halbieren_vergessen","- 23":"halbieren_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #17 quadrfkt-normalform-05 · Quadratische Ergänzung · höchster Punkt einer Wurfbahn
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd72d1b39-b747-42a8-a1d6-66ae99c7718b'::uuid, 'exercise', 'Quadratische Ergänzung · höchster Punkt einer Wurfbahn', 'Ein Ball fliegt auf der Bahn h(x) = −0,1x² + 2x + 1,5. Dabei ist x der waagerechte Abstand vom Abwurfpunkt in Metern und h(x) die Höhe des Balls in Metern.

Bestimme mit quadratischer Ergänzung, wo der Ball am höchsten ist. Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Waagerechter Abstand vom Abwurfpunkt am höchsten Punkt in m","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Größte Höhe des Balls in m","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: negativen Dezimalfaktor ausklammern und ergänzen, Scheitel als höchsten Punkt deuten.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer, halbieren_vergessen, ergaenzung_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd72d1b39-b747-42a8-a1d6-66ae99c7718b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd72d1b39-b747-42a8-a1d6-66ae99c7718b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd72d1b39-b747-42a8-a1d6-66ae99c7718b'::uuid,
  p_correct_answers => '{"1":["10","+10"],"2":["11,5","+11,5","11.5","+11.5"]}'::jsonb,
  p_solution        => 'Ausklammern: h(x) = −0,1(x² − 20x) + 1,5.
Ergänzen: h(x) = −0,1(x² − 20x + 100 − 100) + 1,5 = −0,1(x − 10)² + 10 + 1,5.
h(x) = −0,1(x − 10)² + 11,5: nach unten geöffnet, Scheitel S(10|11,5).
Am höchsten 10 m vom Abwurfpunkt entfernt, Höhe 11,5 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x − 10)² den Wert −10 abgelesen.","socratic_question":"Für welches x wird die Klammer (x − 10) null?"},{"error":"Die Zahl vor x in der Klammer nicht halbiert: 20 statt 10.","socratic_question":"Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 20x + …?"},{"error":"In der Klammer + 100 ein zweites Mal addiert statt abgezogen: −10 + 1,5 = −8,5.","socratic_question":"Du hast in der Klammer + 100 ergänzt – was musst du danach abziehen?"},{"error":"Die Zahl vor x nicht halbiert und 20² = 400 ergänzt.","socratic_question":"Welche Zahl musst du quadrieren: 20 oder die Hälfte davon?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"10","equivalents":["+10"],"known_errors":{"20":"halbieren_vergessen","-10":"vorzeichen_aus_klammer","−10":"vorzeichen_aus_klammer","- 10":"vorzeichen_aus_klammer","+20":"halbieren_vergessen"}},"2":{"canonical":"11,5","equivalents":["+11,5","11.5","+11.5"],"known_errors":{"-8,5":"ergaenzung_vorzeichen","−8,5":"ergaenzung_vorzeichen","- 8,5":"ergaenzung_vorzeichen","-8.5":"ergaenzung_vorzeichen","−8.5":"ergaenzung_vorzeichen","- 8.5":"ergaenzung_vorzeichen","41,5":"halbieren_vergessen","+41,5":"halbieren_vergessen","41.5":"halbieren_vergessen","+41.5":"halbieren_vergessen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #18 quadrfkt-normalform-06 · Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '97e9d281-b7ad-4eee-8a25-f500ae6c2f02'::uuid, 'exercise', 'Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle', 'Die Parabel y = x² + bx + 7 hat ihren Scheitelpunkt bei x = 3.

Welche y-Koordinate hat der Scheitelpunkt? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Parabel y = x² + bx + 7 hat ihren Scheitelpunkt bei x = 3.\n\nWelche y-Koordinate hat der Scheitelpunkt? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_normalform',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, 2, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-normalform-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus der Scheitelstelle erst b erschließen, dann ergänzen und den y-Wert bestimmen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (ergaenzung_vorzeichen, falsche_groesse_beantwortet).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '97e9d281-b7ad-4eee-8a25-f500ae6c2f02'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '97e9d281-b7ad-4eee-8a25-f500ae6c2f02'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '97e9d281-b7ad-4eee-8a25-f500ae6c2f02'::uuid,
  p_correct_answers => '["-2","−2","- 2"]'::jsonb,
  p_solution        => 'Scheitel bei x = 3 heißt: y = (x − 3)² + e.
(x − 3)² = x² − 6x + 9, also b = −6.
y = x² − 6x + 9 − 9 + 7 = (x − 3)² − 2.
Die y-Koordinate ist -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Ergänzung 9 addiert statt abgezogen: 7 + 9 = 16.","socratic_question":"Du hast + 9 ergänzt – was musst du danach tun, damit der Term gleich bleibt?"},{"error":"Den Wert von b angegeben statt der y-Koordinate.","socratic_question":"Ist nach b oder nach der y-Koordinate des Scheitels gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"16":"ergaenzung_vorzeichen","+16":"ergaenzung_vorzeichen","-6":"falsche_groesse_beantwortet","−6":"falsche_groesse_beantwortet","- 6":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 quadrfkt-nullstellen-01 · Nullstellen · f(x) = x² − 2x − 8
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3e49f5d3-1f90-41e4-977b-5e5eb6d8a40d'::uuid, 'exercise', 'Nullstellen · f(x) = x² − 2x − 8', 'Gegeben ist die Funktion f(x) = x² − 2x − 8.

Berechne ihre Nullstellen. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Nullstelle","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Nullstelle","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: p-q-Formel mit ganzzahligen Lösungen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3e49f5d3-1f90-41e4-977b-5e5eb6d8a40d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3e49f5d3-1f90-41e4-977b-5e5eb6d8a40d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3e49f5d3-1f90-41e4-977b-5e5eb6d8a40d'::uuid,
  p_correct_answers => '{"1":["-2","−2","- 2"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'f(x) = 0: x² − 2x − 8 = 0, p = −2, q = −8.
x = 1 ± √(1 + 8) = 1 ± 3.
Kleinere Nullstelle -2, größere Nullstelle 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: −1 ± 3, kleinere Lösung −4.","socratic_question":"Wie lautet −p/2, wenn p = −2 ist?"},{"error":"p mit falschem Vorzeichen eingesetzt: −1 ± 3, größere Lösung 2.","socratic_question":"Wie lautet −p/2, wenn p = −2 ist?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"-4":"pq_vorzeichen","−4":"pq_vorzeichen","- 4":"pq_vorzeichen"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"2":"pq_vorzeichen","+2":"pq_vorzeichen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #20 quadrfkt-nullstellen-02 · Nullstellen · f(x) = (x − 1)² − 4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '344b91f6-06af-4aec-93ae-52be49c38a2f'::uuid, 'exercise', 'Nullstellen · f(x) = (x − 1)² − 4', 'Gegeben ist die Funktion f(x) = (x − 1)² − 4.

Berechne ihre Nullstellen. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Nullstelle","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Nullstelle","unit":null,"afb":"I","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Nullstellen aus der Scheitelpunktform durch Wurzelziehen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_aus_klammer).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '344b91f6-06af-4aec-93ae-52be49c38a2f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '344b91f6-06af-4aec-93ae-52be49c38a2f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '344b91f6-06af-4aec-93ae-52be49c38a2f'::uuid,
  p_correct_answers => '{"1":["-1","−1","- 1"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'f(x) = 0: (x − 1)² = 4.
x − 1 = 2 oder x − 1 = −2.
x = 3 oder x = −1.
Kleinere Nullstelle -1, größere Nullstelle 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Aus (x − 1) den Wert −1 übernommen: x = −1 ± 2.","socratic_question":"Für welches x wird die Klammer (x − 1) null?"},{"error":"Aus (x − 1) den Wert −1 übernommen: x = −1 ± 2.","socratic_question":"Für welches x wird die Klammer (x − 1) null?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-1","equivalents":["−1","- 1"],"known_errors":{"-3":"vorzeichen_aus_klammer","−3":"vorzeichen_aus_klammer","- 3":"vorzeichen_aus_klammer"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"1":"vorzeichen_aus_klammer","+1":"vorzeichen_aus_klammer"}}}'::jsonb);
  end if;
end
$loesung$;

-- #21 quadrfkt-nullstellen-03 · Nullstellen · aus der Abbildung ablesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid, 'exercise', 'Nullstellen · aus der Abbildung ablesen', 'Die Abbildung zeigt die Parabel einer quadratischen Funktion f.

Lies die Nullstellen von f ab. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, true, 1, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Nullstelle","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Nullstelle","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: nach unten geöffnete Parabel, Schnittpunkte mit der x-Achse von Scheitel und y-Achsenabschnitt unterscheiden.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, koordinate_vorzeichen_verloren, koordinaten_vertauscht).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid,
  p_correct_answers => '{"1":["-5","−5","- 5"],"2":["3","+3"]}'::jsonb,
  p_solution        => 'Nullstellen sind die Stellen, an denen die Parabel die x-Achse schneidet.
Linker Schnittpunkt: x = -5. Rechter Schnittpunkt: x = 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die x-Koordinate des Scheitelpunkts abgelesen statt einer Nullstelle.","socratic_question":"Wo schneidet die Parabel die x-Achse?"},{"error":"Das Minus vergessen: Die Nullstelle liegt links der y-Achse.","socratic_question":"Liegt diese Nullstelle links oder rechts der y-Achse?"},{"error":"Das Vorzeichen falsch: Die Nullstelle liegt rechts der y-Achse.","socratic_question":"Liegt diese Nullstelle links oder rechts der y-Achse?"},{"error":"Den Schnittpunkt mit der y-Achse abgelesen statt mit der x-Achse.","socratic_question":"Auf welcher Achse liegen die Nullstellen?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-5","equivalents":["−5","- 5"],"known_errors":{"5":"koordinate_vorzeichen_verloren","-1":"falsche_groesse_beantwortet","−1":"falsche_groesse_beantwortet","- 1":"falsche_groesse_beantwortet","+5":"koordinate_vorzeichen_verloren"}},"2":{"canonical":"3","equivalents":["+3"],"known_errors":{"-3":"koordinate_vorzeichen_verloren","−3":"koordinate_vorzeichen_verloren","- 3":"koordinate_vorzeichen_verloren","7,5":"koordinaten_vertauscht","+7,5":"koordinaten_vertauscht","7.5":"koordinaten_vertauscht","+7.5":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid, 'koordinatensystem', '{"x_min":-6,"x_max":4,"y_min":-2,"y_max":9,"funktionen":[{"typ":"quadratisch","a":-0.5,"b":-1,"c":7.5}]}'::jsonb, 'Koordinatensystem mit Gitter und einer nach unten geöffneten Parabel, die die x-Achse zweimal schneidet.'
 where exists (select 1 from public.tasks t where t.id = '9d10386c-d849-4387-85e1-2cd4e9c64bb4'::uuid and t.source = 'edvance_k9_quadrfkt')
on conflict (task_id) do nothing;

-- #22 quadrfkt-nullstellen-04 · Nullstellen · f(x) = 2x² + 4x − 6
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cb03b892-5d43-4818-85b9-7160debaea43'::uuid, 'exercise', 'Nullstellen · f(x) = 2x² + 4x − 6', 'Gegeben ist die Funktion f(x) = 2x² + 4x − 6.

Berechne ihre Nullstellen. Die gesuchten Werte sind ganzzahlig.',
  null, 'MULTI_PART', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"kleinere Nullstelle","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"größere Nullstelle","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst durch den Faktor 2 teilen, dann p-q-Formel.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-quadrfkt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cb03b892-5d43-4818-85b9-7160debaea43'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cb03b892-5d43-4818-85b9-7160debaea43'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cb03b892-5d43-4818-85b9-7160debaea43'::uuid,
  p_correct_answers => '{"1":["-3","−3","- 3"],"2":["1","+1"]}'::jsonb,
  p_solution        => 'f(x) = 0, durch 2 teilen: x² + 2x − 3 = 0, p = 2, q = −3.
x = −1 ± √(1 + 3) = −1 ± 2.
Kleinere Nullstelle -3, größere Nullstelle 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: 1 ± 2, kleinere Lösung −1.","socratic_question":"Wie lautet −p/2, wenn p = 2 ist?"},{"error":"p mit falschem Vorzeichen eingesetzt: 1 ± 2, größere Lösung 3.","socratic_question":"Wie lautet −p/2, wenn p = 2 ist?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-3","equivalents":["−3","- 3"],"known_errors":{"-1":"pq_vorzeichen","−1":"pq_vorzeichen","- 1":"pq_vorzeichen"}},"2":{"canonical":"1","equivalents":["+1"],"known_errors":{"3":"pq_vorzeichen","+3":"pq_vorzeichen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #23 quadrfkt-nullstellen-05 · Nullstelle · wann der Ball den Boden trifft
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2fbd2563-648f-4990-9cff-429936af589d'::uuid, 'exercise', 'Nullstelle · wann der Ball den Boden trifft', 'Ein Ball wird geworfen. Seine Höhe über dem Boden ist h(t) = −5t² + 12t + 2 (t in Sekunden nach dem Abwurf, h in Metern).

Nach wie vielen Sekunden trifft der Ball auf dem Boden auf? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Ball wird geworfen. Seine Höhe über dem Boden ist h(t) = −5t² + 12t + 2 (t in Sekunden nach dem Abwurf, h in Metern).\n\nNach wie vielen Sekunden trifft der Ball auf dem Boden auf? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 's', false, 2, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Boden als h = 0 deuten, durch −5 teilen, p-q-Formel, negative Lösung verwerfen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pq_vorzeichen, vorzeichen_beim_umstellen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2fbd2563-648f-4990-9cff-429936af589d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2fbd2563-648f-4990-9cff-429936af589d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2fbd2563-648f-4990-9cff-429936af589d'::uuid,
  p_correct_answers => '["2,56","2.56","2,56 s","2,56s"]'::jsonb,
  p_solution        => 'Boden: h(t) = 0. Durch −5 teilen: t² − 2,4t − 0,4 = 0, p = −2,4, q = −0,4.
t = 1,2 ± √(1,44 + 0,4) = 1,2 ± √1,84 ≈ 1,2 ± 1,356.
Die negative Lösung passt nicht (vor dem Abwurf). Der Ball trifft nach etwa 2,56 s auf.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"p mit falschem Vorzeichen eingesetzt: −1,2 + √1,84 ≈ 0,16.","socratic_question":"Wie lautet −p/2, wenn p = −2,4 ist?"},{"error":"Beim Teilen durch −5 das Vorzeichen von q nicht umgedreht: q = 0,4.","socratic_question":"Welches Vorzeichen hat 2 : (−5)?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,56","equivalents":["2.56","2,56 s","2,56s"],"known_errors":{"0,16":"pq_vorzeichen","0.16":"pq_vorzeichen","0,16 s":"pq_vorzeichen","0,16s":"pq_vorzeichen","2,22":"vorzeichen_beim_umstellen","2.22":"vorzeichen_beim_umstellen","2,22 s":"vorzeichen_beim_umstellen","2,22s":"vorzeichen_beim_umstellen"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 quadrfkt-nullstellen-06 · Rückrichtung · Scheitelhöhe aus den Nullstellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '52ca5f74-4822-4752-a21c-bba0800e0418'::uuid, 'exercise', 'Rückrichtung · Scheitelhöhe aus den Nullstellen', 'Eine nach oben geöffnete Normalparabel hat die Nullstellen −1 und 5.

Welche y-Koordinate hat ihr Scheitelpunkt? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine nach oben geöffnete Normalparabel hat die Nullstellen −1 und 5.\n\nWelche y-Koordinate hat ihr Scheitelpunkt? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_nullstellen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-nullstellen-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Scheitelstelle als Mitte der Nullstellen erkennen und den Funktionsterm selbst aufstellen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, halbieren_vergessen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '52ca5f74-4822-4752-a21c-bba0800e0418'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '52ca5f74-4822-4752-a21c-bba0800e0418'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '52ca5f74-4822-4752-a21c-bba0800e0418'::uuid,
  p_correct_answers => '["-9","−9","- 9"]'::jsonb,
  p_solution        => 'Funktionsterm aus den Nullstellen: f(x) = (x + 1)(x − 5).
Der Scheitel liegt in der Mitte der Nullstellen: x = (−1 + 5) : 2 = 2.
f(2) = 3 · (−3) = -9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die x-Koordinate des Scheitels angegeben statt der y-Koordinate.","socratic_question":"Ist nach der Stelle oder nach dem Funktionswert am Scheitel gefragt?"},{"error":"Die Mitte nicht halbiert: x = 4 statt 2 eingesetzt.","socratic_question":"Wie findest du die Mitte zwischen −1 und 5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-9","equivalents":["−9","- 9"],"known_errors":{"2":"falsche_groesse_beantwortet","+2":"falsche_groesse_beantwortet","-5":"halbieren_vergessen","−5":"halbieren_vergessen","- 5":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 quadrfkt-extrem-01 · Größter Funktionswert · f(x) = −(x − 4)² + 7
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1be8b1ae-0f25-45cf-a65a-19ddabc06c6c'::uuid, 'exercise', 'Größter Funktionswert · f(x) = −(x − 4)² + 7', 'Die Funktion f(x) = −(x − 4)² + 7 hat einen größten Funktionswert.

Wie groß ist dieser größte Funktionswert? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Funktion f(x) = −(x − 4)² + 7 hat einen größten Funktionswert.\n\nWie groß ist dieser größte Funktionswert? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Extremwert direkt aus der Scheitelpunktform ablesen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, koordinate_vorzeichen_verloren).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1be8b1ae-0f25-45cf-a65a-19ddabc06c6c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1be8b1ae-0f25-45cf-a65a-19ddabc06c6c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1be8b1ae-0f25-45cf-a65a-19ddabc06c6c'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => 'Die Parabel ist nach unten geöffnet (Minus vor der Klammer).
Der größte Wert liegt am Scheitel S(4|7).
Der größte Funktionswert ist 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Stelle x = 4 angegeben statt des Funktionswerts.","socratic_question":"Ist nach der Stelle oder nach dem Funktionswert gefragt?"},{"error":"Das Minus vor der Klammer auf die 7 übertragen.","socratic_question":"Welches Vorzeichen hat f(4) = −0² + 7?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7"],"known_errors":{"4":"falsche_groesse_beantwortet","+4":"falsche_groesse_beantwortet","-7":"koordinate_vorzeichen_verloren","−7":"koordinate_vorzeichen_verloren","- 7":"koordinate_vorzeichen_verloren"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 quadrfkt-extrem-02 · Kleinster Funktionswert · f(x) = x² − 8x + 10
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6fb41407-d8e5-4f86-8b5b-4a0b1eba8d1c'::uuid, 'exercise', 'Kleinster Funktionswert · f(x) = x² − 8x + 10', 'Die Funktion f(x) = x² − 8x + 10 hat einen kleinsten Funktionswert.

Wie groß ist dieser kleinste Funktionswert? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Funktion f(x) = x² − 8x + 10 hat einen kleinsten Funktionswert.\n\nWie groß ist dieser kleinste Funktionswert? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: quadratische Ergänzung, dann den Extremwert am Scheitel ablesen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (ergaenzung_vorzeichen, falsche_groesse_beantwortet).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6fb41407-d8e5-4f86-8b5b-4a0b1eba8d1c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6fb41407-d8e5-4f86-8b5b-4a0b1eba8d1c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6fb41407-d8e5-4f86-8b5b-4a0b1eba8d1c'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => 'Quadratische Ergänzung: f(x) = x² − 8x + 16 − 16 + 10 = (x − 4)² − 6.
Nach oben geöffnet, der kleinste Wert liegt am Scheitel S(4|−6).
Der kleinste Funktionswert ist -6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Ergänzung 16 addiert statt abgezogen: 10 + 16 = 26.","socratic_question":"Du hast + 16 ergänzt – was musst du danach tun, damit der Term gleich bleibt?"},{"error":"Die Stelle x = 4 angegeben statt des Funktionswerts.","socratic_question":"Ist nach der Stelle oder nach dem Funktionswert gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","equivalents":["−6","- 6"],"known_errors":{"4":"falsche_groesse_beantwortet","26":"ergaenzung_vorzeichen","+26":"ergaenzung_vorzeichen","+4":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 quadrfkt-extrem-03 · Größter Funktionswert · f(x) = −2x² + 12x − 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f1e39983-43c3-4048-a8fd-8efa86af128a'::uuid, 'exercise', 'Größter Funktionswert · f(x) = −2x² + 12x − 5', 'Die Funktion f(x) = −2x² + 12x − 5 hat einen größten Funktionswert.

Wie groß ist dieser größte Funktionswert? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Funktion f(x) = −2x² + 12x − 5 hat einen größten Funktionswert.\n\nWie groß ist dieser größte Funktionswert? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negativen Faktor ausklammern, ergänzen, Extremwert bestimmen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (ergaenzung_vorzeichen, falsche_groesse_beantwortet, mal_zwei_vergessen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f1e39983-43c3-4048-a8fd-8efa86af128a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f1e39983-43c3-4048-a8fd-8efa86af128a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f1e39983-43c3-4048-a8fd-8efa86af128a'::uuid,
  p_correct_answers => '["13","+13"]'::jsonb,
  p_solution        => 'Ausklammern: f(x) = −2(x² − 6x) − 5.
Ergänzen: f(x) = −2(x² − 6x + 9 − 9) − 5 = −2(x − 3)² + 18 − 5 = −2(x − 3)² + 13.
Nach unten geöffnet, der größte Funktionswert ist 13.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"In der Klammer + 9 ein zweites Mal addiert statt abgezogen: −18 − 5 = −23.","socratic_question":"Du hast in der Klammer + 9 ergänzt – was musst du danach abziehen?"},{"error":"Die Stelle x = 3 angegeben statt des Funktionswerts.","socratic_question":"Ist nach der Stelle oder nach dem Funktionswert gefragt?"},{"error":"Die abgezogene 9 nicht mit dem ausgeklammerten Faktor −2 multipliziert: 9 − 5 = 4.","socratic_question":"Was passiert mit der − 9, wenn du die Klammer mit −2 wieder auflöst?"}]'::jsonb,
  p_acceptance      => '{"canonical":"13","equivalents":["+13"],"known_errors":{"3":"falsche_groesse_beantwortet","4":"mal_zwei_vergessen","-23":"ergaenzung_vorzeichen","−23":"ergaenzung_vorzeichen","- 23":"ergaenzung_vorzeichen","+3":"falsche_groesse_beantwortet","+4":"mal_zwei_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 quadrfkt-extrem-04 · Zahlenrätsel · Summe 20, größtes Produkt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '547e47ca-bd44-479d-ae44-932644219954'::uuid, 'exercise', 'Zahlenrätsel · Summe 20, größtes Produkt', 'Zwei Zahlen haben die Summe 20. Ihr Produkt soll so groß wie möglich sein.

Wie groß ist das größte mögliche Produkt? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Zahlen haben die Summe 20. Ihr Produkt soll so groß wie möglich sein.\n\nWie groß ist das größte mögliche Produkt? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Produktfunktion P(x) = x · (20 − x) aufstellen und ihren Scheitel bestimmen.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, ergaenzung_vorzeichen).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '547e47ca-bd44-479d-ae44-932644219954'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '547e47ca-bd44-479d-ae44-932644219954'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '547e47ca-bd44-479d-ae44-932644219954'::uuid,
  p_correct_answers => '["100","+100"]'::jsonb,
  p_solution        => 'Erste Zahl x, zweite Zahl 20 − x. Produkt P(x) = x · (20 − x) = −x² + 20x.
Ergänzen: P(x) = −(x² − 20x + 100 − 100) = −(x − 10)² + 100.
Das größte Produkt ist 100 (für x = 10 und 20 − x = 10).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Zahl x = 10 angegeben statt des Produkts.","socratic_question":"Ist nach einer der Zahlen oder nach ihrem Produkt gefragt?"},{"error":"In der Klammer + 100 ein zweites Mal addiert statt abgezogen: P = −100.","socratic_question":"Kann das Produkt zweier Zahlen mit der Summe 20 negativ sein, wenn beide 10 sind?"}]'::jsonb,
  p_acceptance      => '{"canonical":"100","equivalents":["+100"],"known_errors":{"10":"falsche_groesse_beantwortet","+10":"falsche_groesse_beantwortet","-100":"ergaenzung_vorzeichen","−100":"ergaenzung_vorzeichen","- 100":"ergaenzung_vorzeichen"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 quadrfkt-extrem-05 · Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f38cec97-0b1e-400c-9708-fcf18e52b371'::uuid, 'exercise', 'Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1', 'Ein Ball wird senkrecht nach oben geworfen. Seine Höhe ist h(t) = −5t² + 20t + 1 (t in Sekunden nach dem Abwurf, h in Metern).

Welche maximale Höhe erreicht der Ball? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Ball wird senkrecht nach oben geworfen. Seine Höhe ist h(t) = −5t² + 20t + 1 (t in Sekunden nach dem Abwurf, h in Metern).\n\nWelche maximale Höhe erreicht der Ball? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'm', false, 2, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: höchsten Punkt als Scheitel deuten, die Höhe und nicht den Zeitpunkt angeben.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, ergaenzung_vorzeichen, vorrang_ignoriert).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f38cec97-0b1e-400c-9708-fcf18e52b371'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f38cec97-0b1e-400c-9708-fcf18e52b371'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f38cec97-0b1e-400c-9708-fcf18e52b371'::uuid,
  p_correct_answers => '["21","21 m","21m"]'::jsonb,
  p_solution        => 'Ausklammern: h(t) = −5(t² − 4t) + 1.
Ergänzen: h(t) = −5(t² − 4t + 4 − 4) + 1 = −5(t − 2)² + 20 + 1 = −5(t − 2)² + 21.
Nach 2 s erreicht der Ball die maximale Höhe 21 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Zeitpunkt t = 2 angegeben statt der Höhe.","socratic_question":"Ist nach dem Zeitpunkt oder nach der Höhe gefragt?"},{"error":"In der Klammer + 4 ein zweites Mal addiert statt abgezogen: −20 + 1 = −19.","socratic_question":"Kann die maximale Höhe des Balls negativ sein?"},{"error":"Beim Einsetzen von t = 2 erst mit −5 multipliziert, dann quadriert: (−10)² + 40 + 1.","socratic_question":"Was wird in −5t² zuerst gerechnet: das Quadrat oder das Mal −5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"21","equivalents":["21 m","21m"],"known_errors":{"2":"falsche_groesse_beantwortet","141":"vorrang_ignoriert","2 m":"falsche_groesse_beantwortet","2m":"falsche_groesse_beantwortet","-19":"ergaenzung_vorzeichen","−19":"ergaenzung_vorzeichen","- 19":"ergaenzung_vorzeichen","-19 m":"ergaenzung_vorzeichen","-19m":"ergaenzung_vorzeichen","141 m":"vorrang_ignoriert","141m":"vorrang_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 quadrfkt-extrem-06 · Größte Fläche · 40 m Zaun an einer Mauer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4a70a989-5a09-4037-af27-476e378e7120'::uuid, 'exercise', 'Größte Fläche · 40 m Zaun an einer Mauer', 'An einer langen Mauer soll mit 40 m Zaun eine rechteckige Fläche eingezäunt werden. Die Mauer bildet eine Seite des Rechtecks, die anderen drei Seiten werden mit dem Zaun begrenzt. Der ganze Zaun wird verbraucht.

Wie groß ist der größtmögliche Flächeninhalt in Quadratmetern? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"An einer langen Mauer soll mit 40 m Zaun eine rechteckige Fläche eingezäunt werden. Die Mauer bildet eine Seite des Rechtecks, die anderen drei Seiten werden mit dem Zaun begrenzt. Der ganze Zaun wird verbraucht.\n\nWie groß ist der größtmögliche Flächeninhalt in Quadratmetern? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'fkt_quadr_extrem',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, 'm²', false, null, 'draft', 'edvance_k9_quadrfkt', 'quadrfkt-extrem-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Zielfunktion A(x) aus dem Sachtext selbst aufstellen (Mauer als vierte Seite), Scheitel bestimmen, Fläche angeben.","charge":"k9-quadrfkt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-quadrfkt"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.","charge":"k9-quadrfkt"},"cluster_id":{"art":"neu","grund":"Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen\".","charge":"k9-quadrfkt"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).","charge":"k9-quadrfkt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-quadrfkt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-quadrfkt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-quadrfkt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-quadrfkt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, bedingung_unvollstaendig).","charge":"k9-quadrfkt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-quadrfkt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4a70a989-5a09-4037-af27-476e378e7120'::uuid and t.status = 'draft' and t.source = 'edvance_k9_quadrfkt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4a70a989-5a09-4037-af27-476e378e7120'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4a70a989-5a09-4037-af27-476e378e7120'::uuid,
  p_correct_answers => '["200","200 m²","200m²"]'::jsonb,
  p_solution        => 'Zwei Seiten senkrecht zur Mauer je x m, die Seite parallel zur Mauer (40 − 2x) m.
A(x) = x · (40 − 2x) = −2x² + 40x = −2(x² − 20x + 100 − 100) = −2(x − 10)² + 200.
Für x = 10 m (Seiten 10 m, 20 m, 10 m) ist die Fläche am größten: 200 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Seitenlänge x = 10 angegeben statt der Fläche.","socratic_question":"Ist nach einer Seitenlänge oder nach dem Flächeninhalt gefragt?"},{"error":"Die Mauer nicht beachtet: Zaun auf allen vier Seiten, Quadrat 10 m · 10 m.","socratic_question":"Wie viele Seiten des Rechtecks braucht der Zaun?"}]'::jsonb,
  p_acceptance      => '{"canonical":"200","equivalents":["200 m²","200m²"],"known_errors":{"10":"falsche_groesse_beantwortet","100":"bedingung_unvollstaendig","10 m²":"falsche_groesse_beantwortet","10m²":"falsche_groesse_beantwortet","100 m²":"bedingung_unvollstaendig","100m²":"bedingung_unvollstaendig"}}'::jsonb);
  end if;
end
$loesung$;
