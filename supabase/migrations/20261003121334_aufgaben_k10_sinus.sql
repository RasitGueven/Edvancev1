-- K10-Rest, Thema sinus — 30 Aufgaben: je sechs zu fkt_sinus_einheitskreis, _bogenmass, _graph, _parameter und _periodisch.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-sinus.json (Quelle: tools/k10-sinus-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003121329_substrat_k10_trigo.sql und 20261003121331_substrat_k10_sinus.sql (Knoten + Fehlbild-Slugs muessen stehen).
-- Keine Abbildungen: Der Generator koordinatensystem zeichnet keine Sinuskurve; Graph-Eigenschaften stehen im Text.
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (zweiter Winkel mit gleichem Sinus, Punkt aus y-Koordinate, Bogen → Winkel, Stelle mit gleichem Funktionswert, a und b aus Amplitude/Periode bzw. Hoch-/Tiefpunkt; Karussell, Riesenrad, Gezeiten, Tageslänge, Schaukel). Koordinaten und Parameter als MULTI_PART (Eingabe nur Zahlen). Bogenmaß als Dezimalzahl (π-Regel, beide Rechenwege richtig) oder als Faktor k in k · π (Bruch erlaubt). Jede Aufgabe nennt die Winkeleinheit und die Rundung; keine Abbildungen; alle Werte exakt nachgerechnet.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k10-sinus.csv. Pruefprotokoll: docs/prefill/k10-sinus-verifikation.md.
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
--   fkt_sinus_einheitskreis: sinus-einheitskreis-06 = 1, sinus-einheitskreis-03 = 2. Rang 1 aus Profil {bogenmass_modus,quadrant_vorzeichen,wurzel_vergessen}, Rang 2 aus Profil {koordinaten_vertauscht,quadrant_vorzeichen} (1 neue Fehlbilder)
--   fkt_sinus_bogenmass: sinus-bogenmass-05 = 1, sinus-bogenmass-06 = 2. Rang 1 aus Profil {grad_bogen_faktor_falsch,kreisanteil_falsch,pi_vergessen}, Rang 2 aus Profil {grad_bogen_faktor_falsch,multipliziert_statt_dividiert} (1 neue Fehlbilder)
--   fkt_sinus_graph: sinus-graph-04 = 1, sinus-graph-03 = 2. Rang 1 aus Profil {bogenmass_modus,quadrant_vorzeichen}, Rang 2 aus Profil {einheit_uebersprungen,falsche_groesse_beantwortet} (2 neue Fehlbilder)
--   fkt_sinus_parameter: sinus-parameter-04 = 1, sinus-parameter-06 = 2. Rang 1 aus Profil {amplitude_verwechselt,betrag_fehler,periode_falsch}, Rang 2 aus Profil {amplitude_verwechselt,falsche_groesse_beantwortet,periode_falsch} (1 neue Fehlbilder)
--   fkt_sinus_periodisch: sinus-periodisch-06 = 1, sinus-periodisch-04 = 2. Rang 1 aus Profil {amplitude_verwechselt,falsche_groesse_beantwortet,periode_falsch}, Rang 2 aus Profil {bogenmass_modus,zu_frueh_gerundet} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 sinus-einheitskreis-01 · sin 150° · exakter Wert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5564f507-357e-4975-98fb-80ee85d1de4a'::uuid, 'exercise', 'sin 150° · exakter Wert', 'Der Winkel α = 150° ist im Gradmaß angegeben.

Bestimme sin 150°. Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Der Winkel α = 150° ist im Gradmaß angegeben.\n\nBestimme sin 150°. Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Sinuswert im zweiten Viertel über den Bezugswinkel 30° bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5564f507-357e-4975-98fb-80ee85d1de4a'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5564f507-357e-4975-98fb-80ee85d1de4a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5564f507-357e-4975-98fb-80ee85d1de4a'::uuid,
  p_correct_answers => '["0,5","+0,5","0.5","+0.5"]'::jsonb,
  p_solution        => 'Am Einheitskreis liegt der Punkt zu 150° im zweiten Viertel, oberhalb der x-Achse.
Bezugswinkel: 180° − 150° = 30°, sin 30° = 0,5.
Im zweiten Viertel ist der Sinus positiv: sin 150° = 0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Im zweiten Viertel ein Minus vor den Sinus gesetzt: −0,5.","socratic_question":"Liegt der Punkt zu 150° oberhalb oder unterhalb der x-Achse?"},{"error":"Den Taschenrechner im Bogenmaß gelassen: sin(150) im Bogenmaß ≈ −0,71.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,5","equivalents":["+0,5","0.5","+0.5"],"known_errors":{"-0,5":"quadrant_vorzeichen","−0,5":"quadrant_vorzeichen","- 0,5":"quadrant_vorzeichen","-0.5":"quadrant_vorzeichen","−0.5":"quadrant_vorzeichen","- 0.5":"quadrant_vorzeichen","-0,71":"bogenmass_modus","−0,71":"bogenmass_modus","- 0,71":"bogenmass_modus","-0.71":"bogenmass_modus","−0.71":"bogenmass_modus","- 0.71":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 sinus-einheitskreis-02 · cos 200° · gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c142139e-ecfa-4583-980d-dd926f0b874d'::uuid, 'exercise', 'cos 200° · gerundet', 'Der Winkel α = 200° ist im Gradmaß angegeben.

Bestimme cos 200°. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Der Winkel α = 200° ist im Gradmaß angegeben.\n\nBestimme cos 200°. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Kosinuswert im dritten Viertel mit dem Taschenrechner bestimmen und runden.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c142139e-ecfa-4583-980d-dd926f0b874d'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c142139e-ecfa-4583-980d-dd926f0b874d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c142139e-ecfa-4583-980d-dd926f0b874d'::uuid,
  p_correct_answers => '["-0,94","−0,94","- 0,94","-0.94","−0.94","- 0.94"]'::jsonb,
  p_solution        => 'Taschenrechner im Gradmaß (DEG): cos 200° ≈ −0,9397.
Der Punkt zu 200° liegt im dritten Viertel links der y-Achse, der Kosinus ist negativ.
cos 200° ≈ -0,94.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Wert des Bezugswinkels 20° genommen, ohne Minus: 0,94.","socratic_question":"Liegt der Punkt zu 200° links oder rechts der y-Achse?"},{"error":"Den Taschenrechner im Bogenmaß gelassen: cos(200) im Bogenmaß ≈ 0,49.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-0,94","equivalents":["−0,94","- 0,94","-0.94","−0.94","- 0.94"],"known_errors":{"0,94":"quadrant_vorzeichen","+0,94":"quadrant_vorzeichen","0.94":"quadrant_vorzeichen","+0.94":"quadrant_vorzeichen","0,49":"bogenmass_modus","+0,49":"bogenmass_modus","0.49":"bogenmass_modus","+0.49":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 sinus-einheitskreis-03 · Punkt auf dem Einheitskreis · α = 240°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '82cb7f14-5213-4aea-a297-c480c557463c'::uuid, 'exercise', 'Punkt auf dem Einheitskreis · α = 240°', 'Der Punkt P liegt auf dem Einheitskreis (Mittelpunkt im Ursprung, Radius 1). Die Strecke vom Ursprung zu P bildet mit der positiven x-Achse den Winkel α = 240° (Gradmaß, gegen den Uhrzeigersinn gemessen).

Gib die Koordinaten von P an. Runde auf zwei Stellen nach dem Komma.',
  null, 'MULTI_PART', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von P","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"y-Koordinate von P","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Koordinaten (cos α | sin α) im dritten Viertel mit beiden Vorzeichen angeben.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, koordinaten_vertauscht).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '82cb7f14-5213-4aea-a297-c480c557463c'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '82cb7f14-5213-4aea-a297-c480c557463c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '82cb7f14-5213-4aea-a297-c480c557463c'::uuid,
  p_correct_answers => '{"1":["-0,50","−0,50","- 0,50","-0.50","−0.50","- 0.50","-0,5","−0,5","- 0,5","-0.5","−0.5","- 0.5"],"2":["-0,87","−0,87","- 0,87","-0.87","−0.87","- 0.87"]}'::jsonb,
  p_solution        => 'Am Einheitskreis gilt P(cos α | sin α).
240° liegt im dritten Viertel: beide Koordinaten sind negativ. Bezugswinkel 240° − 180° = 60°.
x = cos 240° = −cos 60° = -0,50.
y = sin 240° = −sin 60° ≈ -0,87.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Minus im dritten Viertel übersehen: 0,5 statt −0,5.","socratic_question":"Liegt P links oder rechts der y-Achse?"},{"error":"Den Sinus als x-Koordinate genommen.","socratic_question":"Welche Koordinate gehört am Einheitskreis zum Kosinus?"},{"error":"Das Minus im dritten Viertel übersehen: 0,87 statt −0,87.","socratic_question":"Liegt P oberhalb oder unterhalb der x-Achse?"},{"error":"Den Kosinus als y-Koordinate genommen.","socratic_question":"Welche Koordinate gehört am Einheitskreis zum Sinus?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"-0,50","equivalents":["−0,50","- 0,50","-0.50","−0.50","- 0.50","-0,5","−0,5","- 0,5","-0.5","−0.5","- 0.5"],"known_errors":{"0,50":"quadrant_vorzeichen","+0,50":"quadrant_vorzeichen","0.50":"quadrant_vorzeichen","+0.50":"quadrant_vorzeichen","0,5":"quadrant_vorzeichen","+0,5":"quadrant_vorzeichen","0.5":"quadrant_vorzeichen","+0.5":"quadrant_vorzeichen","-0,87":"koordinaten_vertauscht","−0,87":"koordinaten_vertauscht","- 0,87":"koordinaten_vertauscht","-0.87":"koordinaten_vertauscht","−0.87":"koordinaten_vertauscht","- 0.87":"koordinaten_vertauscht"}},"2":{"canonical":"-0,87","equivalents":["−0,87","- 0,87","-0.87","−0.87","- 0.87"],"known_errors":{"0,87":"quadrant_vorzeichen","+0,87":"quadrant_vorzeichen","0.87":"quadrant_vorzeichen","+0.87":"quadrant_vorzeichen","-0,50":"koordinaten_vertauscht","−0,50":"koordinaten_vertauscht","- 0,50":"koordinaten_vertauscht","-0.50":"koordinaten_vertauscht","−0.50":"koordinaten_vertauscht","- 0.50":"koordinaten_vertauscht","-0,5":"koordinaten_vertauscht","−0,5":"koordinaten_vertauscht","- 0,5":"koordinaten_vertauscht","-0.5":"koordinaten_vertauscht","−0.5":"koordinaten_vertauscht","- 0.5":"koordinaten_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #4 sinus-einheitskreis-04 · Winkel aus cos α = −0,6 · zweites Viertel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5511e07a-0da1-4f7b-8da7-38ad45dc41ea'::uuid, 'exercise', 'Winkel aus cos α = −0,6 · zweites Viertel', 'Für einen Winkel α zwischen 90° und 180° gilt cos α = −0,6.

Wie groß ist α im Gradmaß? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Für einen Winkel α zwischen 90° und 180° gilt cos α = −0,6.\n\nWie groß ist α im Gradmaß? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Winkel aus einem negativen Kosinuswert mit cos⁻¹ bestimmen und das Viertel prüfen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5511e07a-0da1-4f7b-8da7-38ad45dc41ea'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5511e07a-0da1-4f7b-8da7-38ad45dc41ea'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5511e07a-0da1-4f7b-8da7-38ad45dc41ea'::uuid,
  p_correct_answers => '["126,9","126.9","126,9 °","126,9°"]'::jsonb,
  p_solution        => 'Taschenrechner im Gradmaß: α = cos⁻¹(−0,6) ≈ 126,87°.
Der Wert liegt zwischen 90° und 180°, passt also.
α ≈ 126,9°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Minus weggelassen: cos⁻¹(0,6) ≈ 53,1° liegt im ersten Viertel.","socratic_question":"Ist der Kosinus im ersten Viertel positiv oder negativ?"},{"error":"Den Taschenrechner im Bogenmaß gelassen: cos⁻¹(−0,6) ≈ 2,2.","socratic_question":"Kann ein Winkel zwischen 90° und 180° die Größe 2,2 haben?"}]'::jsonb,
  p_acceptance      => '{"canonical":"126,9","equivalents":["126.9","126,9 °","126,9°"],"known_errors":{"53,1":"quadrant_vorzeichen","53.1":"quadrant_vorzeichen","53,1 °":"quadrant_vorzeichen","53,1°":"quadrant_vorzeichen","2,2":"bogenmass_modus","2.2":"bogenmass_modus","2,2 °":"bogenmass_modus","2,2°":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 sinus-einheitskreis-05 · Rückrichtung · zweiter Winkel mit sin α = sin 50°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd051d804-ac22-4995-a537-703ad36ed510'::uuid, 'exercise', 'Rückrichtung · zweiter Winkel mit sin α = sin 50°', 'Es gilt sin 50° ≈ 0,77 (Gradmaß).

Es gibt einen zweiten Winkel α zwischen 0° und 360°, für den sin α = sin 50° gilt. Wie groß ist α im Gradmaß? Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Es gilt sin 50° ≈ 0,77 (Gradmaß).\n\nEs gibt einen zweiten Winkel α zwischen 0° und 360°, für den sin α = sin 50° gilt. Wie groß ist α im Gradmaß? Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: den zweiten Winkel mit gleichem Sinuswert über die Symmetrie zur y-Achse finden.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd051d804-ac22-4995-a537-703ad36ed510'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd051d804-ac22-4995-a537-703ad36ed510'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd051d804-ac22-4995-a537-703ad36ed510'::uuid,
  p_correct_answers => '["130","130 °","130°"]'::jsonb,
  p_solution        => 'Gleicher Sinus heißt gleiche y-Koordinate am Einheitskreis.
Der zweite Punkt liegt spiegelbildlich zur y-Achse im zweiten Viertel.
α = 180° − 50° = 130°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Winkel im vierten Viertel genommen: Dort ist der Sinus negativ, sin 310° ≈ −0,77.","socratic_question":"Liegt der Punkt zu 310° oberhalb oder unterhalb der x-Achse?"},{"error":"Den Winkel im dritten Viertel genommen: Dort ist der Sinus negativ, sin 230° ≈ −0,77.","socratic_question":"Welches Vorzeichen hat der Sinus im dritten Viertel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"130","equivalents":["130 °","130°"],"known_errors":{"230":"quadrant_vorzeichen","310":"quadrant_vorzeichen","310 °":"quadrant_vorzeichen","310°":"quadrant_vorzeichen","230 °":"quadrant_vorzeichen","230°":"quadrant_vorzeichen"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 sinus-einheitskreis-06 · Rückrichtung · Punkt mit y = −0,6 im vierten Viertel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97'::uuid, 'exercise', 'Rückrichtung · Punkt mit y = −0,6 im vierten Viertel', 'Ein Punkt P auf dem Einheitskreis (Mittelpunkt im Ursprung, Radius 1) liegt im vierten Viertel und hat die y-Koordinate −0,6. α ist der Winkel zwischen der positiven x-Achse und der Strecke vom Ursprung zu P, gegen den Uhrzeigersinn gemessen, mit 0° ≤ α < 360°.

Bestimme die x-Koordinate von P und den Winkel α im Gradmaß. Runde auf zwei Stellen nach dem Komma.',
  null, 'MULTI_PART', 'fkt_sinus_einheitskreis',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, 1, 'draft', 'edvance_k10_sinus', 'sinus-einheitskreis-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"x-Koordinate von P","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Winkel α in Grad","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus der y-Koordinate über x² + y² = 1 die x-Koordinate und über sin⁻¹ den Winkel im vierten Viertel bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, wurzel_vergessen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97'::uuid,
  p_correct_answers => '{"1":["0,80","+0,80","0.80","+0.80","0,8","+0,8","0.8","+0.8"],"2":["323,13","+323,13","323.13","+323.13"]}'::jsonb,
  p_solution        => 'Am Einheitskreis gilt x² + y² = 1, also x² = 1 − 0,36 = 0,64.
Im vierten Viertel ist x positiv: x = √0,64 = 0,80.
sin⁻¹(−0,6) ≈ −36,87°; im Bereich 0° bis 360°: α = 360° − 36,87° ≈ 323,13°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ein Minus gesetzt: Im vierten Viertel liegt P rechts der y-Achse, x ist positiv.","socratic_question":"Liegt das vierte Viertel links oder rechts der y-Achse?"},{"error":"x² = 0,64 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du x oder x² berechnet?"},{"error":"Den Winkel im dritten Viertel genommen: Dort ist der Kosinus negativ, P läge links der y-Achse.","socratic_question":"Liegt dein Winkel im vierten Viertel, also zwischen 270° und 360°?"},{"error":"Im Bogenmaß gerechnet: 2π + sin⁻¹(−0,6) ≈ 5,64.","socratic_question":"Ist nach dem Winkel im Gradmaß gefragt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0,80","equivalents":["+0,80","0.80","+0.80","0,8","+0,8","0.8","+0.8"],"known_errors":{"-0,80":"quadrant_vorzeichen","−0,80":"quadrant_vorzeichen","- 0,80":"quadrant_vorzeichen","-0.80":"quadrant_vorzeichen","−0.80":"quadrant_vorzeichen","- 0.80":"quadrant_vorzeichen","-0,8":"quadrant_vorzeichen","−0,8":"quadrant_vorzeichen","- 0,8":"quadrant_vorzeichen","-0.8":"quadrant_vorzeichen","−0.8":"quadrant_vorzeichen","- 0.8":"quadrant_vorzeichen","0,64":"wurzel_vergessen","+0,64":"wurzel_vergessen","0.64":"wurzel_vergessen","+0.64":"wurzel_vergessen"}},"2":{"canonical":"323,13","equivalents":["+323,13","323.13","+323.13"],"known_errors":{"216,87":"quadrant_vorzeichen","+216,87":"quadrant_vorzeichen","216.87":"quadrant_vorzeichen","+216.87":"quadrant_vorzeichen","5,64":"bogenmass_modus","+5,64":"bogenmass_modus","5.64":"bogenmass_modus","+5.64":"bogenmass_modus"}}}'::jsonb);
  end if;
end
$loesung$;

-- #7 sinus-bogenmass-01 · 60° als Vielfaches von π
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd24bac46-6ac1-4560-bd4f-ab856150108e'::uuid, 'exercise', '60° als Vielfaches von π', 'Der Winkel 60° ist im Gradmaß angegeben. Im Bogenmaß lässt er sich als k · π schreiben.

Wie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).',
  '{"kind":"short_input","prompt":"Der Winkel 60° ist im Gradmaß angegeben. Im Bogenmaß lässt er sich als k · π schreiben.\n\nWie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3)."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gradmaß über 180° = π in einen Faktor von π umrechnen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kreisanteil_falsch, grad_bogen_faktor_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd24bac46-6ac1-4560-bd4f-ab856150108e'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd24bac46-6ac1-4560-bd4f-ab856150108e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd24bac46-6ac1-4560-bd4f-ab856150108e'::uuid,
  p_correct_answers => '["1/3","+1/3"]'::jsonb,
  p_solution        => '180° entsprechen π.
60° = 60/180 · π = 1/3 · π.
k = 1/3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 360° = π gerechnet: 60/360 = 1/6.","socratic_question":"Wie viel Grad entsprechen π: ein halber oder ein ganzer Kreis?"},{"error":"Den Faktor umgedreht: 180/60 = 3.","socratic_question":"Muss 60° ein größerer oder ein kleinerer Teil von π sein als 180°?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/3","equivalents":["+1/3"],"known_errors":{"3":"grad_bogen_faktor_falsch","1/6":"kreisanteil_falsch","+1/6":"kreisanteil_falsch","+3":"grad_bogen_faktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 sinus-bogenmass-02 · 50° im Bogenmaß · Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '718f0c9a-6a29-4ce7-b8ea-ce46d94c3f65'::uuid, 'exercise', '50° im Bogenmaß · Dezimalzahl', 'Der Winkel 50° ist im Gradmaß angegeben.

Rechne ihn ins Bogenmaß um und gib das Ergebnis als Dezimalzahl an. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Der Winkel 50° ist im Gradmaß angegeben.\n\nRechne ihn ins Bogenmaß um und gib das Ergebnis als Dezimalzahl an. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gradmaß mit dem Faktor π/180 ins Bogenmaß umrechnen und runden.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grad_bogen_faktor_falsch, pi_vergessen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '718f0c9a-6a29-4ce7-b8ea-ce46d94c3f65'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '718f0c9a-6a29-4ce7-b8ea-ce46d94c3f65'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '718f0c9a-6a29-4ce7-b8ea-ce46d94c3f65'::uuid,
  p_correct_answers => '["0,87","+0,87","0.87","+0.87"]'::jsonb,
  p_solution        => 'x = 50 · π/180 ≈ 0,87 (π-Taste).
Mit π ≈ 3,14: x = 50 · 3,14 : 180 ≈ 0,87.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 180/π statt π/180 multipliziert: ≈ 2864,79.","socratic_question":"Ein voller Kreis hat im Bogenmaß etwa 6,28 – kann 50° dann über 2000 sein?"},{"error":"π weggelassen: 50/180 ≈ 0,28.","socratic_question":"Welcher Faktor gehört zu 180° im Bogenmaß?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,87","equivalents":["+0,87","0.87","+0.87"],"known_errors":{"2864,79":"grad_bogen_faktor_falsch","+2864,79":"grad_bogen_faktor_falsch","2864.79":"grad_bogen_faktor_falsch","+2864.79":"grad_bogen_faktor_falsch","2866,24":"grad_bogen_faktor_falsch","+2866,24":"grad_bogen_faktor_falsch","2866.24":"grad_bogen_faktor_falsch","+2866.24":"grad_bogen_faktor_falsch","0,28":"pi_vergessen","+0,28":"pi_vergessen","0.28":"pi_vergessen","+0.28":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 sinus-bogenmass-03 · x = 4 im Bogenmaß · in Grad
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0caf97f5-5562-4905-9329-0e884f7e566d'::uuid, 'exercise', 'x = 4 im Bogenmaß · in Grad', 'Ein Winkel hat im Bogenmaß die Größe x = 4.

Wie groß ist er im Gradmaß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Winkel hat im Bogenmaß die Größe x = 4.\n\nWie groß ist er im Gradmaß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung vom Bogenmaß ins Gradmaß ohne π im Ausgangswert.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grad_bogen_faktor_falsch, pi_vergessen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0caf97f5-5562-4905-9329-0e884f7e566d'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0caf97f5-5562-4905-9329-0e884f7e566d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0caf97f5-5562-4905-9329-0e884f7e566d'::uuid,
  p_correct_answers => '["229,2","229.2","229,2 °","229,2°","229,3","229.3","229,3 °","229,3°"]'::jsonb,
  p_solution        => 'Bogenmaß → Gradmaß: mit 180/π multiplizieren.
α = 4 · 180°/π ≈ 229,2° (π-Taste).
Mit π ≈ 3,14: α = 720° : 3,14 ≈ 229,3°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit π/180 statt 180/π multipliziert: ≈ 0,07.","socratic_question":"π im Bogenmaß sind 180°. Ist 4 mehr oder weniger als π?"},{"error":"Nicht durch π geteilt: 4 · 180 = 720.","socratic_question":"Welche Bogenmaß-Zahl gehört zu 180°: 1 oder π?"}]'::jsonb,
  p_acceptance      => '{"canonical":"229,2","equivalents":["229.2","229,2 °","229,2°","229,3","229.3","229,3 °","229,3°"],"known_errors":{"720":"pi_vergessen","0,07":"grad_bogen_faktor_falsch","0.07":"grad_bogen_faktor_falsch","0,07 °":"grad_bogen_faktor_falsch","0,07°":"grad_bogen_faktor_falsch","720,0":"pi_vergessen","720.0":"pi_vergessen","720,0 °":"pi_vergessen","720,0°":"pi_vergessen","720 °":"pi_vergessen","720°":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 sinus-bogenmass-04 · x = 5π/4 im Bogenmaß · in Grad
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '80a3d680-4289-4cc6-8b87-793c602c5c1f'::uuid, 'exercise', 'x = 5π/4 im Bogenmaß · in Grad', 'Ein Winkel hat im Bogenmaß die Größe x = 5π/4.

Wie groß ist er im Gradmaß? Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Ein Winkel hat im Bogenmaß die Größe x = 5π/4.\n\nWie groß ist er im Gradmaß? Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Bogenmaß mit π im Bruch ins Gradmaß umrechnen, π kürzt sich.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kreisanteil_falsch, grad_bogen_faktor_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '80a3d680-4289-4cc6-8b87-793c602c5c1f'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '80a3d680-4289-4cc6-8b87-793c602c5c1f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '80a3d680-4289-4cc6-8b87-793c602c5c1f'::uuid,
  p_correct_answers => '["225","225 °","225°"]'::jsonb,
  p_solution        => 'π entspricht 180°.
x = 5/4 · π entspricht 5/4 · 180° = 225°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit π = 360° gerechnet: 5/4 · 360° = 450°.","socratic_question":"Entspricht π einem halben oder einem ganzen Kreis?"},{"error":"Mit π/180 statt 180/π multipliziert: ≈ 0,07.","socratic_question":"Ist 5π/4 mehr oder weniger als π, also mehr oder weniger als 180°?"}]'::jsonb,
  p_acceptance      => '{"canonical":"225","equivalents":["225 °","225°"],"known_errors":{"450":"kreisanteil_falsch","450 °":"kreisanteil_falsch","450°":"kreisanteil_falsch","0,07":"grad_bogen_faktor_falsch","0.07":"grad_bogen_faktor_falsch","0,07 °":"grad_bogen_faktor_falsch","0,07°":"grad_bogen_faktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 sinus-bogenmass-05 · Bogenlänge · Karussellsitz dreht sich um 130°
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b3ce89d7-2f07-4438-802b-b3653ad330da'::uuid, 'exercise', 'Bogenlänge · Karussellsitz dreht sich um 130°', 'Ein Karussellsitz bewegt sich auf einem Kreis mit dem Radius 1 m. Er dreht sich um 130° (Gradmaß) weiter.

Wie viele Meter legt der Sitz auf dem Kreisbogen zurück? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Karussellsitz bewegt sich auf einem Kreis mit dem Radius 1 m. Er dreht sich um 130° (Gradmaß) weiter.\n\nWie viele Meter legt der Sitz auf dem Kreisbogen zurück? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'm', false, 1, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Am Kreis mit Radius 1 ist die Bogenlänge gleich dem Bogenmaß des Winkels.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grad_bogen_faktor_falsch, kreisanteil_falsch, pi_vergessen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b3ce89d7-2f07-4438-802b-b3653ad330da'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b3ce89d7-2f07-4438-802b-b3653ad330da'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b3ce89d7-2f07-4438-802b-b3653ad330da'::uuid,
  p_correct_answers => '["2,27","2.27","2,27 m","2,27m"]'::jsonb,
  p_solution        => 'Am Kreis mit Radius 1 ist die Bogenlänge gleich dem Bogenmaß: b = 130 · π/180.
b ≈ 2,27 m (π-Taste).
Mit π ≈ 3,14: b = 130 · 3,14 : 180 ≈ 2,27 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 180/π statt π/180 multipliziert: ≈ 7448 m.","socratic_question":"Ein ganzer Umlauf ist etwa 6,28 m lang – kann ein Teil davon länger sein?"},{"error":"Den Anteil umgedreht: 360/130 statt 130/360 vom Umfang.","socratic_question":"Ist der Bogen kürzer oder länger als ein ganzer Umlauf?"},{"error":"π weggelassen: 130/180 ≈ 0,72.","socratic_question":"Welche Bogenlänge hat ein halber Kreis mit Radius 1?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,27","equivalents":["2.27","2,27 m","2,27m"],"known_errors":{"7448,45":"grad_bogen_faktor_falsch","7448.45":"grad_bogen_faktor_falsch","7448,45 m":"grad_bogen_faktor_falsch","7448,45m":"grad_bogen_faktor_falsch","7452,23":"grad_bogen_faktor_falsch","7452.23":"grad_bogen_faktor_falsch","7452,23 m":"grad_bogen_faktor_falsch","7452,23m":"grad_bogen_faktor_falsch","17,40":"kreisanteil_falsch","17.40":"kreisanteil_falsch","17,4":"kreisanteil_falsch","17.4":"kreisanteil_falsch","17,40 m":"kreisanteil_falsch","17,40m":"kreisanteil_falsch","17,4 m":"kreisanteil_falsch","17,4m":"kreisanteil_falsch","17,39":"kreisanteil_falsch","17.39":"kreisanteil_falsch","17,39 m":"kreisanteil_falsch","17,39m":"kreisanteil_falsch","0,72":"pi_vergessen","0.72":"pi_vergessen","0,72 m":"pi_vergessen","0,72m":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 sinus-bogenmass-06 · Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4bea8500-6a8c-4719-98b7-8c68d02543b1'::uuid, 'exercise', 'Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm', 'Ein Kreis hat den Radius 3 cm. Ein Kreisbogen auf diesem Kreis ist 5 cm lang.

Wie groß ist der zugehörige Mittelpunktswinkel im Gradmaß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kreis hat den Radius 3 cm. Ein Kreisbogen auf diesem Kreis ist 5 cm lang.\n\nWie groß ist der zugehörige Mittelpunktswinkel im Gradmaß? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_bogenmass',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, '°', false, 2, 'draft', 'edvance_k10_sinus', 'sinus-bogenmass-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Bogenmaß als Bogenlänge durch Radius bilden, dann ins Gradmaß umrechnen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (multipliziert_statt_dividiert, grad_bogen_faktor_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4bea8500-6a8c-4719-98b7-8c68d02543b1'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4bea8500-6a8c-4719-98b7-8c68d02543b1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4bea8500-6a8c-4719-98b7-8c68d02543b1'::uuid,
  p_correct_answers => '["95,5","95.5","95,5 °","95,5°"]'::jsonb,
  p_solution        => 'Bogenmaß: x = Bogenlänge : Radius = 5 : 3.
In Grad: α = 5/3 · 180°/π ≈ 95,5° (π-Taste).
Mit π ≈ 3,14: α = 300° : 3,14 ≈ 95,5°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bogenlänge mal Radius statt geteilt durch den Radius.","socratic_question":"Wie hängen Bogenlänge, Radius und Bogenmaß zusammen: b = x · r?"},{"error":"Mit π/180 statt 180/π multipliziert: ≈ 0,03.","socratic_question":"Ein Bogen von 5 cm bei 3 cm Radius: Ist der Winkel eher klein oder fast ein rechter?"}]'::jsonb,
  p_acceptance      => '{"canonical":"95,5","equivalents":["95.5","95,5 °","95,5°"],"known_errors":{"859,4":"multipliziert_statt_dividiert","859.4":"multipliziert_statt_dividiert","859,4 °":"multipliziert_statt_dividiert","859,4°":"multipliziert_statt_dividiert","859,9":"multipliziert_statt_dividiert","859.9":"multipliziert_statt_dividiert","859,9 °":"multipliziert_statt_dividiert","859,9°":"multipliziert_statt_dividiert","0,03":"grad_bogen_faktor_falsch","0.03":"grad_bogen_faktor_falsch","0,03 °":"grad_bogen_faktor_falsch","0,03°":"grad_bogen_faktor_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 sinus-graph-01 · Funktionswert · sin(7π/6)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '50da3bb2-6650-498a-804f-05863e2da59b'::uuid, 'exercise', 'Funktionswert · sin(7π/6)', 'Gegeben ist f(x) = sin x, x im Bogenmaß.

Berechne f(7π/6). Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(7π/6). Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-graph-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Funktionswert an einer Bogenmaß-Stelle über den Einheitskreis bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '50da3bb2-6650-498a-804f-05863e2da59b'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '50da3bb2-6650-498a-804f-05863e2da59b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '50da3bb2-6650-498a-804f-05863e2da59b'::uuid,
  p_correct_answers => '["-0,5","−0,5","- 0,5","-0.5","−0.5","- 0.5"]'::jsonb,
  p_solution        => '7π/6 im Bogenmaß entspricht 7/6 · 180° = 210°.
210° liegt im dritten Viertel, der Sinus ist negativ. Bezugswinkel 30°, sin 30° = 0,5.
f(7π/6) = sin 210° = -0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Minus im dritten Viertel übersehen: 0,5.","socratic_question":"Liegt der Punkt zu 7π/6 oberhalb oder unterhalb der x-Achse?"},{"error":"Den Taschenrechner im Gradmaß gelassen: sin(3,67°) ≈ 0,06.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-0,5","equivalents":["−0,5","- 0,5","-0.5","−0.5","- 0.5"],"known_errors":{"0,5":"quadrant_vorzeichen","+0,5":"quadrant_vorzeichen","0.5":"quadrant_vorzeichen","+0.5":"quadrant_vorzeichen","0,06":"bogenmass_modus","+0,06":"bogenmass_modus","0.06":"bogenmass_modus","+0.06":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 sinus-graph-02 · Funktionswert · sin(π/3) gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '957ef3a2-42ec-4e74-97d7-b75be722fc12'::uuid, 'exercise', 'Funktionswert · sin(π/3) gerundet', 'Gegeben ist f(x) = sin x, x im Bogenmaß.

Berechne f(π/3). Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(π/3). Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-graph-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Funktionswert an einer Bogenmaß-Stelle im ersten Viertel bestimmen und runden.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '957ef3a2-42ec-4e74-97d7-b75be722fc12'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '957ef3a2-42ec-4e74-97d7-b75be722fc12'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '957ef3a2-42ec-4e74-97d7-b75be722fc12'::uuid,
  p_correct_answers => '["0,87","+0,87","0.87","+0.87"]'::jsonb,
  p_solution        => 'Taschenrechner im Bogenmaß (RAD): sin(π/3) ≈ 0,8660.
(Gleichwertig: π/3 entspricht 60°, sin 60° ≈ 0,8660.)
f(π/3) ≈ 0,87.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Taschenrechner im Gradmaß gelassen: sin(1,05°) ≈ 0,02.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,87","equivalents":["+0,87","0.87","+0.87"],"known_errors":{"0,02":"bogenmass_modus","+0,02":"bogenmass_modus","0.02":"bogenmass_modus","+0.02":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 sinus-graph-03 · Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3b59c4a1-2216-48a5-9462-64c03187acd9'::uuid, 'exercise', 'Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π', 'Der Graph von f(x) = sin x (x im Bogenmaß) hat im Intervall [0; 2π] genau einen Hochpunkt und genau einen Tiefpunkt. Ihre x-Koordinaten lassen sich als k · π schreiben.

Gib jeweils k an. Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).',
  null, 'MULTI_PART', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k10_sinus', 'sinus-graph-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"k für den Hochpunkt","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"k für den Tiefpunkt","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Lage von Hoch- und Tiefpunkt des Graphen aus dem Einheitskreis ins Bogenmaß übertragen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, einheit_uebersprungen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3b59c4a1-2216-48a5-9462-64c03187acd9'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3b59c4a1-2216-48a5-9462-64c03187acd9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3b59c4a1-2216-48a5-9462-64c03187acd9'::uuid,
  p_correct_answers => '{"1":["0,5","+0,5","0.5","+0.5","1/2","+1/2"],"2":["1,5","+1,5","1.5","+1.5","3/2","+3/2"]}'::jsonb,
  p_solution        => 'Der Sinus ist am größten (1) bei 90° und am kleinsten (−1) bei 270°.
90° = π/2, also k = 0,5 für den Hochpunkt.
270° = 3π/2, also k = 1,5 für den Tiefpunkt.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Stelle des Tiefpunkts angegeben.","socratic_question":"Ist sin x an deiner Stelle 1 oder −1?"},{"error":"Den Winkel im Gradmaß angegeben: 90.","socratic_question":"Ist nach dem Gradmaß oder nach dem Faktor vor π gefragt?"},{"error":"Die Stelle des Hochpunkts angegeben.","socratic_question":"Ist sin x an deiner Stelle 1 oder −1?"},{"error":"Den Winkel im Gradmaß angegeben: 270.","socratic_question":"Ist nach dem Gradmaß oder nach dem Faktor vor π gefragt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0,5","equivalents":["+0,5","0.5","+0.5","1/2","+1/2"],"known_errors":{"90":"einheit_uebersprungen","1,5":"falsche_groesse_beantwortet","+1,5":"falsche_groesse_beantwortet","1.5":"falsche_groesse_beantwortet","+1.5":"falsche_groesse_beantwortet","3/2":"falsche_groesse_beantwortet","+3/2":"falsche_groesse_beantwortet","+90":"einheit_uebersprungen"}},"2":{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5","3/2","+3/2"],"known_errors":{"270":"einheit_uebersprungen","0,5":"falsche_groesse_beantwortet","+0,5":"falsche_groesse_beantwortet","0.5":"falsche_groesse_beantwortet","+0.5":"falsche_groesse_beantwortet","1/2":"falsche_groesse_beantwortet","+1/2":"falsche_groesse_beantwortet","+270":"einheit_uebersprungen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #16 sinus-graph-04 · Funktionswert · sin(5) mit Vorzeichen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '516304d3-5cb1-4223-8afd-69958fe1890a'::uuid, 'exercise', 'Funktionswert · sin(5) mit Vorzeichen', 'Gegeben ist f(x) = sin x, x im Bogenmaß.

Berechne f(5). Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(5). Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k10_sinus', 'sinus-graph-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Bogenmaß-Stelle ohne π, Lage im vierten Viertel erkennen, negatives Ergebnis.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bogenmass_modus, quadrant_vorzeichen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '516304d3-5cb1-4223-8afd-69958fe1890a'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '516304d3-5cb1-4223-8afd-69958fe1890a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '516304d3-5cb1-4223-8afd-69958fe1890a'::uuid,
  p_correct_answers => '["-0,96","−0,96","- 0,96","-0.96","−0.96","- 0.96"]'::jsonb,
  p_solution        => 'Taschenrechner im Bogenmaß (RAD): sin(5) ≈ −0,9589.
Probe: 3π/2 ≈ 4,71 < 5 < 2π ≈ 6,28, die Stelle liegt im vierten Viertel, dort ist sin x negativ.
f(5) ≈ -0,96.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Taschenrechner im Gradmaß gelassen: sin 5° ≈ 0,09.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"},{"error":"Das Minus weggelassen: 0,96.","socratic_question":"Liegt x = 5 zwischen 3π/2 und 2π? Welches Vorzeichen hat sin x dort?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-0,96","equivalents":["−0,96","- 0,96","-0.96","−0.96","- 0.96"],"known_errors":{"0,09":"bogenmass_modus","+0,09":"bogenmass_modus","0.09":"bogenmass_modus","+0.09":"bogenmass_modus","0,96":"quadrant_vorzeichen","+0,96":"quadrant_vorzeichen","0.96":"quadrant_vorzeichen","+0.96":"quadrant_vorzeichen"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 sinus-graph-05 · Rückrichtung · zweite Stelle mit sin x = sin(π/5)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b0fd871b-5f23-478b-b8c2-3b34a8e3aa02'::uuid, 'exercise', 'Rückrichtung · zweite Stelle mit sin x = sin(π/5)', 'Der Graph von f(x) = sin x (x im Bogenmaß) hat an der Stelle x = π/5 den Wert f(π/5) ≈ 0,59.

Es gibt genau eine weitere Stelle im Intervall [0; 2π] mit demselben Funktionswert. Sie lässt sich als k · π schreiben. Wie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).',
  '{"kind":"short_input","prompt":"Der Graph von f(x) = sin x (x im Bogenmaß) hat an der Stelle x = π/5 den Wert f(π/5) ≈ 0,59.\n\nEs gibt genau eine weitere Stelle im Intervall [0; 2π] mit demselben Funktionswert. Sie lässt sich als k · π schreiben. Wie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3)."}'::jsonb, 'NUMERIC', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-graph-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: Symmetrie des Graphen zur Geraden x = π/2 nutzen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (quadrant_vorzeichen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b0fd871b-5f23-478b-b8c2-3b34a8e3aa02'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b0fd871b-5f23-478b-b8c2-3b34a8e3aa02'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b0fd871b-5f23-478b-b8c2-3b34a8e3aa02'::uuid,
  p_correct_answers => '["0,8","+0,8","0.8","+0.8","4/5","+4/5"]'::jsonb,
  p_solution        => 'Der Graph ist zwischen 0 und π symmetrisch zur Geraden x = π/2.
Zweite Stelle: π − π/5 = 4π/5.
k = 0,8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"π + π/5 genommen: Dort ist sin x negativ (≈ −0,59).","socratic_question":"Ist sin x zwischen π und 2π positiv oder negativ?"},{"error":"2π − π/5 genommen: Dort ist sin x negativ (≈ −0,59).","socratic_question":"Ist sin x zwischen π und 2π positiv oder negativ?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,8","equivalents":["+0,8","0.8","+0.8","4/5","+4/5"],"known_errors":{"1,2":"quadrant_vorzeichen","+1,2":"quadrant_vorzeichen","1.2":"quadrant_vorzeichen","+1.2":"quadrant_vorzeichen","6/5":"quadrant_vorzeichen","+6/5":"quadrant_vorzeichen","1,8":"quadrant_vorzeichen","+1,8":"quadrant_vorzeichen","1.8":"quadrant_vorzeichen","+1.8":"quadrant_vorzeichen","9/5":"quadrant_vorzeichen","+9/5":"quadrant_vorzeichen"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 sinus-graph-06 · Anzahl der Nullstellen in [0; 20]
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2c93e7d0-82d4-4abb-8493-cc03f04ad49b'::uuid, 'exercise', 'Anzahl der Nullstellen in [0; 20]', 'Gegeben ist f(x) = sin x, x im Bogenmaß.

Wie viele Nullstellen hat f im Intervall [0; 20]? Die Intervallgrenzen gehören dazu. Gib eine ganze Zahl an.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nWie viele Nullstellen hat f im Intervall [0; 20]? Die Intervallgrenzen gehören dazu. Gib eine ganze Zahl an."}'::jsonb, 'NUMERIC', 'fkt_sinus_graph',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-graph-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Nullstellen als Vielfache von π erkennen und im Intervall abzählen, Randstelle 0 mitzählen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pi_vergessen, bogenmass_modus).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2c93e7d0-82d4-4abb-8493-cc03f04ad49b'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2c93e7d0-82d4-4abb-8493-cc03f04ad49b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2c93e7d0-82d4-4abb-8493-cc03f04ad49b'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => 'Die Nullstellen von sin x sind 0, π, 2π, 3π, …
20 : π ≈ 6,37, also liegen 0, π, 2π, …, 6π im Intervall (6π ≈ 18,85; 7π ≈ 21,99 liegt außerhalb).
Das sind 7 Nullstellen.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"π weggelassen: Nullstellen bei 0, 1, 2, …, 20 gezählt.","socratic_question":"Wo schneidet der Graph von sin x die x-Achse zum zweiten Mal: bei 1 oder bei π?"},{"error":"Im Gradmaß gedacht: Zwischen 0° und 20° liegt nur die Nullstelle 0.","socratic_question":"Ist das Intervall [0; 20] im Gradmaß oder im Bogenmaß gemeint?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7"],"known_errors":{"1":"bogenmass_modus","21":"pi_vergessen","+21":"pi_vergessen","+1":"bogenmass_modus"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 sinus-parameter-01 · Amplitude · f(x) = 3·sin(2x)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ee9a28cd-1129-405c-9b83-d8972ddf4681'::uuid, 'exercise', 'Amplitude · f(x) = 3·sin(2x)', 'Gegeben ist f(x) = 3 · sin(2x), x im Bogenmaß.

Wie groß ist die Amplitude von f? Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = 3 · sin(2x), x im Bogenmaß.\n\nWie groß ist die Amplitude von f? Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-parameter-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Amplitude als Faktor a vor dem Sinus ablesen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (amplitude_verwechselt).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ee9a28cd-1129-405c-9b83-d8972ddf4681'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ee9a28cd-1129-405c-9b83-d8972ddf4681'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ee9a28cd-1129-405c-9b83-d8972ddf4681'::uuid,
  p_correct_answers => '["3","+3"]'::jsonb,
  p_solution        => 'Bei f(x) = a · sin(b · x) ist die Amplitude |a|.
Hier ist a = 3, die Amplitude ist 3.
Die Funktionswerte liegen zwischen −3 und 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Abstand zwischen Hoch- und Tiefpunkt angegeben: 3 − (−3) = 6.","socratic_question":"Wie weit liegt der Hochpunkt über der x-Achse?"},{"error":"Die Amplitude halbiert: 1,5.","socratic_question":"Welchen größten Wert nimmt 3 · sin(2x) an?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","equivalents":["+3"],"known_errors":{"6":"amplitude_verwechselt","+6":"amplitude_verwechselt","1,5":"amplitude_verwechselt","+1,5":"amplitude_verwechselt","1.5":"amplitude_verwechselt","+1.5":"amplitude_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 sinus-parameter-02 · Periode · f(x) = sin(4x) als Vielfaches von π
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5d143147-03ad-46b0-a2d2-6308111eac90'::uuid, 'exercise', 'Periode · f(x) = sin(4x) als Vielfaches von π', 'Gegeben ist f(x) = sin(4x), x im Bogenmaß. Die Periode p von f lässt sich als p = k · π schreiben.

Wie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = sin(4x), x im Bogenmaß. Die Periode p von f lässt sich als p = k · π schreiben.\n\nWie groß ist k? Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3)."}'::jsonb, 'NUMERIC', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-parameter-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Periode mit p = 2π : b bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (periode_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5d143147-03ad-46b0-a2d2-6308111eac90'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5d143147-03ad-46b0-a2d2-6308111eac90'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5d143147-03ad-46b0-a2d2-6308111eac90'::uuid,
  p_correct_answers => '["0,5","+0,5","0.5","+0.5","1/2","+1/2"]'::jsonb,
  p_solution        => 'Periode p = 2π : b = 2π : 4 = π/2.
k = 0,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor b = 4 als Periode genommen.","socratic_question":"Wird der Graph durch b = 4 gestreckt oder gestaucht?"},{"error":"2π · 4 = 8π statt 2π : 4 gerechnet.","socratic_question":"Wiederholt sich sin(4x) schneller oder langsamer als sin x?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,5","equivalents":["+0,5","0.5","+0.5","1/2","+1/2"],"known_errors":{"4":"periode_falsch","8":"periode_falsch","+4":"periode_falsch","+8":"periode_falsch"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 sinus-parameter-03 · Periode · f(x) = 2·sin(0,5x) als Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9958d2ae-a87d-41b5-a7b7-f9e453c879d1'::uuid, 'exercise', 'Periode · f(x) = 2·sin(0,5x) als Dezimalzahl', 'Gegeben ist f(x) = 2 · sin(0,5x), x im Bogenmaß.

Wie groß ist die Periode von f? Gib sie als Dezimalzahl an. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Gegeben ist f(x) = 2 · sin(0,5x), x im Bogenmaß.\n\nWie groß ist die Periode von f? Gib sie als Dezimalzahl an. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-parameter-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Periode bei b < 1 berechnen (Streckung) und als Dezimalzahl runden.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (periode_falsch, pi_vergessen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9958d2ae-a87d-41b5-a7b7-f9e453c879d1'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9958d2ae-a87d-41b5-a7b7-f9e453c879d1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9958d2ae-a87d-41b5-a7b7-f9e453c879d1'::uuid,
  p_correct_answers => '["12,57","+12,57","12.57","+12.57","12,56","+12,56","12.56","+12.56"]'::jsonb,
  p_solution        => 'Periode p = 2π : b = 2π : 0,5 = 4π.
p ≈ 12,57 (π-Taste).
Mit π ≈ 3,14: p = 4 · 3,14 = 12,56.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2π · 0,5 = π statt 2π : 0,5 gerechnet.","socratic_question":"Wiederholt sich sin(0,5x) schneller oder langsamer als sin x?"},{"error":"Den Faktor b = 0,5 als Periode genommen.","socratic_question":"Welche Periode hat sin x – und was macht der Faktor 0,5 damit?"},{"error":"π weggelassen: 2 : 0,5 = 4.","socratic_question":"Welche Periode hat sin x im Bogenmaß?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,57","equivalents":["+12,57","12.57","+12.57","12,56","+12,56","12.56","+12.56"],"known_errors":{"4":"pi_vergessen","3,14":"periode_falsch","+3,14":"periode_falsch","3.14":"periode_falsch","+3.14":"periode_falsch","0,50":"periode_falsch","+0,50":"periode_falsch","0.50":"periode_falsch","+0.50":"periode_falsch","0,5":"periode_falsch","+0,5":"periode_falsch","0.5":"periode_falsch","+0.5":"periode_falsch","4,00":"pi_vergessen","+4,00":"pi_vergessen","4.00":"pi_vergessen","+4.00":"pi_vergessen","+4":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 sinus-parameter-04 · Größter Wert und Periode · f(x) = −4·sin(2x)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6e99f959-15b4-4f00-9631-5d39754d4982'::uuid, 'exercise', 'Größter Wert und Periode · f(x) = −4·sin(2x)', 'Gegeben ist f(x) = −4 · sin(2x), x im Bogenmaß.

Bestimme den größten Funktionswert von f und die Periode p = k · π. Gib den exakten Wert an. Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).',
  null, 'MULTI_PART', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k10_sinus', 'sinus-parameter-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"größter Funktionswert","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"k in p = k · π","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: negativer Faktor a – größter Funktionswert ist |a|; Periode als Vielfaches von π.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (betrag_fehler, amplitude_verwechselt, periode_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6e99f959-15b4-4f00-9631-5d39754d4982'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6e99f959-15b4-4f00-9631-5d39754d4982'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6e99f959-15b4-4f00-9631-5d39754d4982'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["1","+1"]}'::jsonb,
  p_solution        => 'Das Minus spiegelt den Graphen an der x-Achse, die Werte liegen weiter zwischen −4 und 4.
Größter Funktionswert: 4 (z. B. bei sin(2x) = −1).
Periode: p = 2π : 2 = π, also k = 1.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor −4 als größten Wert genommen.","socratic_question":"Welchen Wert hat f an einer Stelle, an der sin(2x) = −1 ist?"},{"error":"Den Abstand zwischen größtem und kleinstem Wert angegeben: 8.","socratic_question":"Wie weit liegt der höchste Punkt über der x-Achse?"},{"error":"2π · 2 = 4π statt 2π : 2 gerechnet.","socratic_question":"Wiederholt sich sin(2x) schneller oder langsamer als sin x?"},{"error":"Mit p = π : b statt 2π : b gerechnet.","socratic_question":"Welche Periode hat sin x?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"8":"amplitude_verwechselt","-4":"betrag_fehler","−4":"betrag_fehler","- 4":"betrag_fehler","+8":"amplitude_verwechselt"}},"2":{"canonical":"1","equivalents":["+1"],"known_errors":{"4":"periode_falsch","+4":"periode_falsch","0,5":"periode_falsch","+0,5":"periode_falsch","0.5":"periode_falsch","+0.5":"periode_falsch","1/2":"periode_falsch","+1/2":"periode_falsch"}}}'::jsonb);
  end if;
end
$loesung$;

-- #23 sinus-parameter-05 · Rückrichtung · a und b aus Amplitude 1,5 und Periode π
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '095a8d5c-4a0b-4fd3-97a0-01996b207163'::uuid, 'exercise', 'Rückrichtung · a und b aus Amplitude 1,5 und Periode π', 'Eine Funktion f(x) = a · sin(b · x) mit a > 0 und b > 0 (x im Bogenmaß) hat die Amplitude 1,5 und die Periode π.

Bestimme a und b. Gib den exakten Wert an.',
  null, 'MULTI_PART', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-parameter-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"b","unit":null,"afb":"II","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in der Rückrichtung: a aus der Amplitude, b aus b = 2π : p.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (amplitude_verwechselt, periode_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '095a8d5c-4a0b-4fd3-97a0-01996b207163'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '095a8d5c-4a0b-4fd3-97a0-01996b207163'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '095a8d5c-4a0b-4fd3-97a0-01996b207163'::uuid,
  p_correct_answers => '{"1":["1,5","+1,5","1.5","+1.5"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'Die Amplitude ist a, also a = 1,5.
Aus p = 2π : b folgt b = 2π : p = 2π : π = 2.
f(x) = 1,5 · sin(2x).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Amplitude verdoppelt: a = 3.","socratic_question":"Wie weit liegt der Hochpunkt von f über der x-Achse?"},{"error":"Die Amplitude halbiert: a = 0,75.","socratic_question":"Welchen größten Wert hat a · sin(b · x)?"},{"error":"Die Periode π als b genommen: b ≈ 3,14.","socratic_question":"Ist b die Periode oder der Faktor, der die Periode bestimmt?"},{"error":"b = p : 2π statt 2π : p gerechnet.","socratic_question":"Wird der Graph mit Periode π gegenüber sin x gestaucht oder gestreckt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5"],"known_errors":{"3":"amplitude_verwechselt","+3":"amplitude_verwechselt","0,75":"amplitude_verwechselt","+0,75":"amplitude_verwechselt","0.75":"amplitude_verwechselt","+0.75":"amplitude_verwechselt"}},"2":{"canonical":"2","equivalents":["+2"],"known_errors":{"3,14":"periode_falsch","+3,14":"periode_falsch","3.14":"periode_falsch","+3.14":"periode_falsch","0,5":"periode_falsch","+0,5":"periode_falsch","0.5":"periode_falsch","+0.5":"periode_falsch"}}}'::jsonb);
  end if;
end
$loesung$;

-- #24 sinus-parameter-06 · Rückrichtung · a und b aus Hoch- und Tiefpunkt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '742d6386-43fd-4a38-9f29-f9c31e828916'::uuid, 'exercise', 'Rückrichtung · a und b aus Hoch- und Tiefpunkt', 'Der Graph von f(x) = a · sin(b · x) mit a > 0 und b > 0 (x im Bogenmaß) hat den Hochpunkt H(π/8 | 2,5). Der nächste Tiefpunkt rechts davon ist T(3π/8 | −2,5).

Bestimme a und b. Gib den exakten Wert an.',
  null, 'MULTI_PART', 'fkt_sinus_parameter',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, null, false, 2, 'draft', 'edvance_k10_sinus', 'sinus-parameter-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"b","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus benachbartem Hoch- und Tiefpunkt Amplitude und halbe Periode gewinnen, dann b bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (amplitude_verwechselt, periode_falsch, falsche_groesse_beantwortet).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '742d6386-43fd-4a38-9f29-f9c31e828916'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '742d6386-43fd-4a38-9f29-f9c31e828916'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '742d6386-43fd-4a38-9f29-f9c31e828916'::uuid,
  p_correct_answers => '{"1":["2,5","+2,5","2.5","+2.5"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'Die Amplitude ist der Abstand des Hochpunkts von der x-Achse: a = 2,5.
Von H zu T ist eine halbe Periode: 3π/8 − π/8 = π/4, also p = π/2.
b = 2π : p = 2π : π/2 = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Abstand zwischen Hoch- und Tiefpunkt als a genommen: 5.","socratic_question":"Wie weit liegt H über der x-Achse?"},{"error":"b = p : 2π statt 2π : p gerechnet: 0,25.","socratic_question":"Wird der Graph gegenüber sin x gestaucht oder gestreckt?"},{"error":"Den Abstand von H zu T als ganze Periode genommen: b = 8.","socratic_question":"Wie viele Perioden liegen zwischen einem Hochpunkt und dem nächsten Tiefpunkt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2,5","equivalents":["+2,5","2.5","+2.5"],"known_errors":{"5":"amplitude_verwechselt","+5":"amplitude_verwechselt"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"8":"falsche_groesse_beantwortet","0,25":"periode_falsch","+0,25":"periode_falsch","0.25":"periode_falsch","+0.25":"periode_falsch","+8":"falsche_groesse_beantwortet"}}}'::jsonb);
  end if;
end
$loesung$;

-- #25 sinus-periodisch-01 · Riesenrad · größte Höhe der Gondel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0fa3adaa-2c0f-4a5f-95a6-d809a1a67d49'::uuid, 'exercise', 'Riesenrad · größte Höhe der Gondel', 'Die Höhe einer Gondel eines Riesenrads über dem Boden wird beschrieben durch h(t) = 18 · sin(0,2 · t) + 20. Dabei ist t die Zeit in Minuten und h(t) die Höhe in Metern; das Argument des Sinus ist im Bogenmaß.

Wie hoch ist die Gondel höchstens über dem Boden? Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"Die Höhe einer Gondel eines Riesenrads über dem Boden wird beschrieben durch h(t) = 18 · sin(0,2 · t) + 20. Dabei ist t die Zeit in Minuten und h(t) die Höhe in Metern; das Argument des Sinus ist im Bogenmaß.\n\nWie hoch ist die Gondel höchstens über dem Boden? Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Modellieren, Operieren',
  75, 'm', false, null, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren im Sachkontext: Höchstwert als Mittellinie plus Amplitude ablesen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, amplitude_verwechselt).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0fa3adaa-2c0f-4a5f-95a6-d809a1a67d49'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0fa3adaa-2c0f-4a5f-95a6-d809a1a67d49'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0fa3adaa-2c0f-4a5f-95a6-d809a1a67d49'::uuid,
  p_correct_answers => '["38","38 m","38m"]'::jsonb,
  p_solution        => 'Der Sinus nimmt höchstens den Wert 1 an.
h = 18 · 1 + 20 = 38 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Amplitude angegeben, die Mittellinie 20 m fehlt.","socratic_question":"In welcher Höhe liegt die Mitte des Riesenrads?"},{"error":"Den Abstand zwischen höchstem und tiefstem Punkt angegeben: 36 m.","socratic_question":"Ist nach der größten Höhe über dem Boden oder nach dem Durchmesser gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"38","equivalents":["38 m","38m"],"known_errors":{"18":"falsche_groesse_beantwortet","36":"amplitude_verwechselt","18 m":"falsche_groesse_beantwortet","18m":"falsche_groesse_beantwortet","36 m":"amplitude_verwechselt","36m":"amplitude_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 sinus-periodisch-02 · Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '21de966d-ff18-47b4-a99f-76331cb4b55b'::uuid, 'exercise', 'Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser', 'An einem Hafen wird der Wasserstand gegenüber dem mittleren Wasserstand beschrieben durch w(t) = 1,8 · sin(0,5 · t). Dabei ist t die Zeit in Stunden und w(t) der Wasserstand in Metern; das Argument des Sinus ist im Bogenmaß.

Wie viele Meter liegt Hochwasser über Niedrigwasser? Gib den exakten Wert an.',
  '{"kind":"short_input","prompt":"An einem Hafen wird der Wasserstand gegenüber dem mittleren Wasserstand beschrieben durch w(t) = 1,8 · sin(0,5 · t). Dabei ist t die Zeit in Stunden und w(t) der Wasserstand in Metern; das Argument des Sinus ist im Bogenmaß.\n\nWie viele Meter liegt Hochwasser über Niedrigwasser? Gib den exakten Wert an."}'::jsonb, 'NUMERIC', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'funktionen', 'Modellieren, Operieren',
  75, 'm', false, null, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren im Sachkontext: Abstand von Höchst- und Tiefstwert als doppelte Amplitude.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (amplitude_verwechselt).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '21de966d-ff18-47b4-a99f-76331cb4b55b'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '21de966d-ff18-47b4-a99f-76331cb4b55b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '21de966d-ff18-47b4-a99f-76331cb4b55b'::uuid,
  p_correct_answers => '["3,6","3.6","3,6 m","3,6m"]'::jsonb,
  p_solution        => 'Hochwasser: w = 1,8 m über dem Mittel. Niedrigwasser: w = −1,8 m.
Unterschied: 1,8 m − (−1,8 m) = 3,6 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Amplitude angegeben: Abstand vom Mittel, nicht von Hoch- zu Niedrigwasser.","socratic_question":"Wie tief liegt Niedrigwasser unter dem mittleren Wasserstand?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3,6","equivalents":["3.6","3,6 m","3,6m"],"known_errors":{"1,8":"amplitude_verwechselt","1.8":"amplitude_verwechselt","1,8 m":"amplitude_verwechselt","1,8m":"amplitude_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 sinus-periodisch-03 · Riesenrad · Dauer einer Umdrehung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0e776143-4575-4bd0-9237-df42d9b71283'::uuid, 'exercise', 'Riesenrad · Dauer einer Umdrehung', 'Die Höhe einer Gondel eines Riesenrads über dem Boden wird beschrieben durch h(t) = 18 · sin(0,2 · t) + 20. Dabei ist t die Zeit in Minuten und h(t) die Höhe in Metern; das Argument des Sinus ist im Bogenmaß.

Wie viele Minuten dauert eine volle Umdrehung? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Die Höhe einer Gondel eines Riesenrads über dem Boden wird beschrieben durch h(t) = 18 · sin(0,2 · t) + 20. Dabei ist t die Zeit in Minuten und h(t) die Höhe in Metern; das Argument des Sinus ist im Bogenmaß.\n\nWie viele Minuten dauert eine volle Umdrehung? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'min', false, null, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Umlaufzeit als Periode 2π : b deuten.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (periode_falsch, pi_vergessen).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0e776143-4575-4bd0-9237-df42d9b71283'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0e776143-4575-4bd0-9237-df42d9b71283'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0e776143-4575-4bd0-9237-df42d9b71283'::uuid,
  p_correct_answers => '["31,4","31.4","31,4 min","31,4min"]'::jsonb,
  p_solution        => 'Eine Umdrehung ist eine Periode: p = 2π : b = 2π : 0,2 = 10π.
p ≈ 31,4 min (π-Taste).
Mit π ≈ 3,14: p = 10 · 3,14 = 31,4 min.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2π · 0,2 statt 2π : 0,2 gerechnet: ≈ 1,3 min.","socratic_question":"Dreht sich ein großes Riesenrad in gut einer Minute einmal herum?"},{"error":"π weggelassen: 2 : 0,2 = 10 min.","socratic_question":"Welche Periode hat sin t?"}]'::jsonb,
  p_acceptance      => '{"canonical":"31,4","equivalents":["31.4","31,4 min","31,4min"],"known_errors":{"10":"pi_vergessen","1,3":"periode_falsch","1.3":"periode_falsch","1,3 min":"periode_falsch","1,3min":"periode_falsch","10,0":"pi_vergessen","10.0":"pi_vergessen","10,0 min":"pi_vergessen","10,0min":"pi_vergessen","10 min":"pi_vergessen","10min":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 sinus-periodisch-04 · Tageslänge · 50 Tage nach Frühlingsanfang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2d925ba5-b5d2-4d1d-b8d6-8477b072fa17'::uuid, 'exercise', 'Tageslänge · 50 Tage nach Frühlingsanfang', 'Die Tageslänge an einem Ort wird beschrieben durch L(t) = 4,3 · sin(0,0172 · t) + 12,2. Dabei ist t die Zeit in Tagen nach Frühlingsanfang und L(t) die Tageslänge in Stunden; das Argument des Sinus ist im Bogenmaß.

Wie lang ist der Tag 50 Tage nach Frühlingsanfang? Rechne ohne Zwischenrunden. Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Die Tageslänge an einem Ort wird beschrieben durch L(t) = 4,3 · sin(0,0172 · t) + 12,2. Dabei ist t die Zeit in Tagen nach Frühlingsanfang und L(t) die Tageslänge in Stunden; das Argument des Sinus ist im Bogenmaß.\n\nWie lang ist der Tag 50 Tage nach Frühlingsanfang? Rechne ohne Zwischenrunden. Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, 'h', false, 2, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Zeitpunkt in einen Sinusterm mit Mittellinie einsetzen, Taschenrechner im Bogenmaß.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bogenmass_modus, zu_frueh_gerundet).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2d925ba5-b5d2-4d1d-b8d6-8477b072fa17'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2d925ba5-b5d2-4d1d-b8d6-8477b072fa17'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2d925ba5-b5d2-4d1d-b8d6-8477b072fa17'::uuid,
  p_correct_answers => '["15,5","15.5","15,5 h","15,5h"]'::jsonb,
  p_solution        => 'Argument: 0,0172 · 50 = 0,86 (Bogenmaß).
sin(0,86) ≈ 0,7578 (Taschenrechner auf RAD).
L(50) = 4,3 · 0,7578… + 12,2 ≈ 15,5 h.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Taschenrechner im Gradmaß gelassen: sin(0,86°) ≈ 0,015.","socratic_question":"Steht dein Taschenrechner auf DEG oder auf RAD?"},{"error":"sin(0,86) auf 0,8 gerundet und damit weitergerechnet.","socratic_question":"Mit wie vielen Stellen hast du den Sinuswert weiterverwendet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15,5","equivalents":["15.5","15,5 h","15,5h"],"known_errors":{"12,3":"bogenmass_modus","12.3":"bogenmass_modus","12,3 h":"bogenmass_modus","12,3h":"bogenmass_modus","15,6":"zu_frueh_gerundet","15.6":"zu_frueh_gerundet","15,6 h":"zu_frueh_gerundet","15,6h":"zu_frueh_gerundet"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 sinus-periodisch-05 · Schaukel · b aus der Schwingungsdauer 3 s
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6b3e8dcf-463e-47c5-9596-4416e1a50bcb'::uuid, 'exercise', 'Schaukel · b aus der Schwingungsdauer 3 s', 'Die Auslenkung einer Schaukel aus der Ruhelage wird beschrieben durch s(t) = 1,2 · sin(b · t). Dabei ist t die Zeit in Sekunden und s(t) die Auslenkung in Metern; das Argument des Sinus ist im Bogenmaß. Eine volle Schwingung dauert 3 s.

Bestimme b. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Die Auslenkung einer Schaukel aus der Ruhelage wird beschrieben durch s(t) = 1,2 · sin(b · t). Dabei ist t die Zeit in Sekunden und s(t) die Auslenkung in Metern; das Argument des Sinus ist im Bogenmaß. Eine volle Schwingung dauert 3 s.\n\nBestimme b. Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext, Rückrichtung: aus der Periode den Faktor b = 2π : p bestimmen.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (periode_falsch, falsche_groesse_beantwortet).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6b3e8dcf-463e-47c5-9596-4416e1a50bcb'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6b3e8dcf-463e-47c5-9596-4416e1a50bcb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6b3e8dcf-463e-47c5-9596-4416e1a50bcb'::uuid,
  p_correct_answers => '["2,09","+2,09","2.09","+2.09"]'::jsonb,
  p_solution        => 'Die Schwingungsdauer ist die Periode: p = 3.
b = 2π : p = 2π : 3 ≈ 2,09 (π-Taste).
Mit π ≈ 3,14: b = 6,28 : 3 ≈ 2,09.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Periode 3 als b genommen.","socratic_question":"Ist b die Schwingungsdauer oder der Faktor, der sie bestimmt?"},{"error":"2π · 3 statt 2π : 3 gerechnet.","socratic_question":"Schwingt die Schaukel mit größerem b schneller oder langsamer?"},{"error":"Die Amplitude 1,2 m als b angegeben.","socratic_question":"Welche Zahl im Term gibt an, wie weit die Schaukel ausschlägt, und welche, wie schnell?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,09","equivalents":["+2,09","2.09","+2.09"],"known_errors":{"3":"periode_falsch","3,00":"periode_falsch","+3,00":"periode_falsch","3.00":"periode_falsch","+3.00":"periode_falsch","+3":"periode_falsch","18,85":"periode_falsch","+18,85":"periode_falsch","18.85":"periode_falsch","+18.85":"periode_falsch","18,84":"periode_falsch","+18,84":"periode_falsch","18.84":"periode_falsch","+18.84":"periode_falsch","1,20":"falsche_groesse_beantwortet","+1,20":"falsche_groesse_beantwortet","1.20":"falsche_groesse_beantwortet","+1.20":"falsche_groesse_beantwortet","1,2":"falsche_groesse_beantwortet","+1,2":"falsche_groesse_beantwortet","1.2":"falsche_groesse_beantwortet","+1.2":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 sinus-periodisch-06 · Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '413a5fa5-cf54-4e4d-a9bb-44d1abba7215'::uuid, 'exercise', 'Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen', 'An einer Küste beträgt der Wasserstand bei Hochwasser 6,5 m und bei Niedrigwasser 1,5 m. Von einem Hochwasser bis zum nächsten Niedrigwasser vergehen 6,2 Stunden. Der Wasserstand soll durch w(t) = a · sin(b · t) + d beschrieben werden, mit a > 0 und b > 0, t in Stunden, w(t) in Metern, das Argument des Sinus im Bogenmaß. d ist der mittlere Wasserstand.

Bestimme a, d und b. Gib a und d exakt an, b auf zwei Stellen nach dem Komma gerundet. Rechne mit der π-Taste oder mit π ≈ 3,14.',
  null, 'MULTI_PART', 'fkt_sinus_periodisch',
  10, 10,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, null, false, 1, 'draft', 'edvance_k10_sinus', 'sinus-periodisch-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"a in m","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null},{"nr":2,"kind":"short_input","prompt":"d in m","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null},{"nr":3,"kind":"short_input","prompt":"b","unit":null,"afb":"III","competency_content":"funktionen","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Amplitude, Mittellinie und Periode aus Hoch- und Niedrigwasser selbst bestimmen, b aus der Periode.","charge":"k10-sinus"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k10-sinus"},"curriculum_grade":{"art":"neu","grund":"KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.","charge":"k10-sinus"},"cluster_id":{"art":"neu","grund":"Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen\".","charge":"k10-sinus"},"competency_content":{"art":"neu","grund":"Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).","charge":"k10-sinus"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k10-sinus"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k10-sinus"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k10-sinus"},"correct_answers.3":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k10-sinus"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k10-sinus"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (amplitude_verwechselt, falsche_groesse_beantwortet, periode_falsch).","charge":"k10-sinus"},"hints":{"art":"leer","grund":"Auftrag W4-k10-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k10-sinus"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '413a5fa5-cf54-4e4d-a9bb-44d1abba7215'::uuid and t.status = 'draft' and t.source = 'edvance_k10_sinus')
   and not exists (select 1 from public.task_solutions s where s.task_id = '413a5fa5-cf54-4e4d-a9bb-44d1abba7215'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '413a5fa5-cf54-4e4d-a9bb-44d1abba7215'::uuid,
  p_correct_answers => '{"1":["2,5","+2,5","2.5","+2.5"],"2":["4","+4"],"3":["0,51","+0,51","0.51","+0.51"]}'::jsonb,
  p_solution        => 'Amplitude: a = (6,5 − 1,5) : 2 = 2,5 m.
Mittlerer Wasserstand: d = (6,5 + 1,5) : 2 = 4 m.
Von Hoch- zu Niedrigwasser ist eine halbe Periode: p = 2 · 6,2 h = 12,4 h.
b = 2π : 12,4 ≈ 0,51 (π-Taste; mit π ≈ 3,14 ebenfalls 0,51).',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den ganzen Unterschied zwischen Hoch- und Niedrigwasser als a genommen: 5 m.","socratic_question":"Wie weit liegt Hochwasser über dem mittleren Wasserstand?"},{"error":"Die Amplitude statt des mittleren Wasserstands angegeben: 2,5 m.","socratic_question":"Welcher Wasserstand liegt genau in der Mitte zwischen 1,5 m und 6,5 m?"},{"error":"b = p : 2π statt 2π : p gerechnet: ≈ 1,97.","socratic_question":"Wird die Kurve mit Periode 12,4 h gegenüber sin t gestreckt oder gestaucht?"},{"error":"Die Zeit von Hoch- bis Niedrigwasser als ganze Periode genommen: ≈ 1,01.","socratic_question":"Ist nach 6,2 h wieder Hochwasser oder erst Niedrigwasser?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2,5","equivalents":["+2,5","2.5","+2.5"],"known_errors":{"5":"amplitude_verwechselt","+5":"amplitude_verwechselt"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"2,5":"falsche_groesse_beantwortet","+2,5":"falsche_groesse_beantwortet","2.5":"falsche_groesse_beantwortet","+2.5":"falsche_groesse_beantwortet"}},"3":{"canonical":"0,51","equivalents":["+0,51","0.51","+0.51"],"known_errors":{"1,97":"periode_falsch","+1,97":"periode_falsch","1.97":"periode_falsch","+1.97":"periode_falsch","1,01":"falsche_groesse_beantwortet","+1,01":"falsche_groesse_beantwortet","1.01":"falsche_groesse_beantwortet","+1.01":"falsche_groesse_beantwortet"}}}'::jsonb);
  end if;
end
$loesung$;
