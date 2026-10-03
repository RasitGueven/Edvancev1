-- K9-Rest, Thema wurzel — 30 Aufgaben: je sechs zu zahl_wurzel_quadrat, _naeherung, _irrational, _gesetze und _teilweise.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-wurzel.json (Quelle: tools/k9-wurzel-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105852_substrat_k9_wurzel.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Tischplatte, eingezäunter Platz, Beet, Teppich, Fliesen, Feld, Spielplatz; Rückrichtung 6·√3 = √b). Alle ohne Abbildung lösbar, Antworten sind Zahlen (kein √ als Eingabe). Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird; exakter Textvergleich, alle gleichwertigen Schreibweisen in correct_answers.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-wurzel.csv. Pruefprotokoll: docs/prefill/k9-wurzel-verifikation.md.
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
--   zahl_wurzel_quadrat: wurzel-quadrat-04 = 1, wurzel-quadrat-05 = 2. Rang 1 aus Profil {kommastellen_zu_viel,kommastellen_zu_wenig,wurzel_halbiert}, Rang 2 aus Profil {einheit_uebersprungen,kommastellen_zu_viel,wurzel_halbiert} (1 neue Fehlbilder)
--   zahl_wurzel_naeherung: wurzel-naeherung-06 = 1, wurzel-naeherung-05 = 2. Rang 1 aus Profil {abgeschnitten,einheit_uebersprungen,wurzel_halbiert}, Rang 2 aus Profil {abgeschnitten,kommastellen_zu_wenig,wurzel_halbiert} (1 neue Fehlbilder)
--   zahl_wurzel_irrational: wurzel-irrational-03 = 1, wurzel-irrational-06 = 2. Rang 1 aus Profil {abgeschnitten,teilgekuerzt}, Rang 2 aus Profil {falsche_groesse_beantwortet,irrational_verwechselt} (2 neue Fehlbilder)
--   zahl_wurzel_gesetze: wurzel-gesetze-04 = 1, wurzel-gesetze-05 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,wurzel_gliedweise,wurzel_halbiert}, Rang 2 aus Profil {falsche_groesse_beantwortet,plus_statt_mal,umfang_statt_flaeche} (2 neue Fehlbilder)
--   zahl_wurzel_teilweise: wurzel-teilweise-04 = 1, wurzel-teilweise-06 = 2. Rang 1 aus Profil {faktor_ohne_wurzel,falsche_groesse_beantwortet,wurzel_halbiert}, Rang 2 aus Profil {faktor_ohne_wurzel,mal_exponent} (1 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 wurzel-quadrat-01 · Quadratwurzel · Zahl, die quadriert 225 ergibt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4b3b14a9-0603-40d7-90b1-60f3517f7348'::uuid, 'exercise', 'Quadratwurzel · Zahl, die quadriert 225 ergibt', 'Welche positive Zahl ergibt quadriert 225?

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Welche positive Zahl ergibt quadriert 225?\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Wurzel aus einer bekannten Quadratzahl, ein Schritt.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_gegenoperation, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4b3b14a9-0603-40d7-90b1-60f3517f7348'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4b3b14a9-0603-40d7-90b1-60f3517f7348'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4b3b14a9-0603-40d7-90b1-60f3517f7348'::uuid,
  p_correct_answers => '["15","+15"]'::jsonb,
  p_solution        => 'Gesucht ist √225, also die positive Zahl, deren Quadrat 225 ist.
15 · 15 = 225, also √225 = 15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Quadriert statt die Wurzel zu ziehen: 225² = 50625.","socratic_question":"Welche Rechnung macht das Quadrieren wieder rückgängig?"},{"error":"Die Zahl halbiert statt die Wurzel zu ziehen: 225 : 2 = 112,5.","socratic_question":"Was kommt heraus, wenn du 112,5 mit sich selbst malnimmst?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","equivalents":["+15"],"known_errors":{"50625":"falsche_gegenoperation","+50625":"falsche_gegenoperation","112,5":"wurzel_halbiert","+112,5":"wurzel_halbiert","112.5":"wurzel_halbiert","+112.5":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 wurzel-quadrat-02 · Quadratwurzel · √0,49
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '55239bfc-349a-4285-b29e-2b1c105e6033'::uuid, 'exercise', 'Quadratwurzel · √0,49', 'Berechne √0,49.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √0,49.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Wurzel aus einer Dezimalzahl, die zu einer bekannten Quadratzahl gehört.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kommastellen_zu_viel, kommastellen_zu_wenig, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '55239bfc-349a-4285-b29e-2b1c105e6033'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '55239bfc-349a-4285-b29e-2b1c105e6033'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '55239bfc-349a-4285-b29e-2b1c105e6033'::uuid,
  p_correct_answers => '["0,7","+0,7","0.7","+0.7"]'::jsonb,
  p_solution        => '0,7 · 0,7 = 0,49, also √0,49 = 0,7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Komma falsch gesetzt: 0,07 statt 0,7.","socratic_question":"Was ergibt 0,07 · 0,07 – wie viele Stellen nach dem Komma hat das Ergebnis?"},{"error":"Das Komma weggelassen: √49 = 7 gerechnet.","socratic_question":"Ist 7 · 7 gleich 0,49?"},{"error":"Halbiert statt die Wurzel gezogen: 0,49 : 2 = 0,245.","socratic_question":"Was ergibt 0,245 · 0,245 ungefähr?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,7","equivalents":["+0,7","0.7","+0.7"],"known_errors":{"7":"kommastellen_zu_wenig","0,07":"kommastellen_zu_viel","+0,07":"kommastellen_zu_viel","0.07":"kommastellen_zu_viel","+0.07":"kommastellen_zu_viel","+7":"kommastellen_zu_wenig","0,245":"wurzel_halbiert","+0,245":"wurzel_halbiert","0.245":"wurzel_halbiert","+0.245":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 wurzel-quadrat-03 · Quadratwurzel · √(9/16)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'afc3b977-389b-4e8d-a157-9952b087c8e2'::uuid, 'exercise', 'Quadratwurzel · √(9/16)', 'Berechne √(9/16).

Gib das Ergebnis exakt an. Du kannst einen Bruch oder eine Dezimalzahl eingeben.',
  '{"kind":"short_input","prompt":"Berechne √(9/16).\n\nGib das Ergebnis exakt an. Du kannst einen Bruch oder eine Dezimalzahl eingeben."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel aus einem Bruch, Zähler und Nenner getrennt.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'afc3b977-389b-4e8d-a157-9952b087c8e2'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'afc3b977-389b-4e8d-a157-9952b087c8e2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'afc3b977-389b-4e8d-a157-9952b087c8e2'::uuid,
  p_correct_answers => '["0,75","+0,75","0.75","+0.75","3/4","+3/4"]'::jsonb,
  p_solution        => '√(9/16) = √9 / √16 = 3/4.
Als Dezimalzahl: 0,75.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wurzel nur aus dem Zähler gezogen, als stünde √9 / 16 da: 3/16.","socratic_question":"Steht nur die 9 oder der ganze Bruch unter der Wurzel?"},{"error":"Halbiert statt die Wurzel gezogen: 9/32.","socratic_question":"Was ergibt 3/4 · 3/4?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,75","equivalents":["+0,75","0.75","+0.75","3/4","+3/4"],"known_errors":{"0,1875":"klammer_vergessen","+0,1875":"klammer_vergessen","0.1875":"klammer_vergessen","+0.1875":"klammer_vergessen","3/16":"klammer_vergessen","+3/16":"klammer_vergessen","0,28125":"wurzel_halbiert","+0,28125":"wurzel_halbiert","0.28125":"wurzel_halbiert","+0.28125":"wurzel_halbiert","9/32":"wurzel_halbiert","+9/32":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 wurzel-quadrat-04 · Quadratwurzel · √0,0016
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '16d6e3b7-86f0-4661-b750-70bf5764e3ba'::uuid, 'exercise', 'Quadratwurzel · √0,0016', 'Berechne √0,0016.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √0,0016.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel aus einer kleinen Dezimalzahl, Kommastellen müssen stimmen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (kommastellen_zu_wenig, kommastellen_zu_viel, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '16d6e3b7-86f0-4661-b750-70bf5764e3ba'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '16d6e3b7-86f0-4661-b750-70bf5764e3ba'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '16d6e3b7-86f0-4661-b750-70bf5764e3ba'::uuid,
  p_correct_answers => '["0,04","+0,04","0.04","+0.04"]'::jsonb,
  p_solution        => '0,0016 hat vier Stellen nach dem Komma, die Wurzel daraus zwei.
0,04 · 0,04 = 0,0016, also √0,0016 = 0,04.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Komma falsch gesetzt: 0,4 statt 0,04.","socratic_question":"Was ergibt 0,4 · 0,4?"},{"error":"Zu viele Stellen nach dem Komma: 0,004.","socratic_question":"Wie viele Stellen nach dem Komma hat 0,004 · 0,004?"},{"error":"Halbiert statt die Wurzel gezogen: 0,0008.","socratic_question":"Ist die Wurzel aus einer Zahl zwischen 0 und 1 kleiner oder größer als die Zahl?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,04","equivalents":["+0,04","0.04","+0.04"],"known_errors":{"0,4":"kommastellen_zu_wenig","+0,4":"kommastellen_zu_wenig","0.4":"kommastellen_zu_wenig","+0.4":"kommastellen_zu_wenig","0,004":"kommastellen_zu_viel","+0,004":"kommastellen_zu_viel","0.004":"kommastellen_zu_viel","+0.004":"kommastellen_zu_viel","0,0008":"wurzel_halbiert","+0,0008":"wurzel_halbiert","0.0008":"wurzel_halbiert","+0.0008":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 wurzel-quadrat-05 · Quadratwurzel · Seite eines Quadrats mit 2,25 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '99b7829c-3536-4278-a84e-3dbeea10637c'::uuid, 'exercise', 'Quadratwurzel · Seite eines Quadrats mit 2,25 m²', 'Eine quadratische Tischplatte hat einen Flächeninhalt von 2,25 m².

Wie lang ist eine Seite der Tischplatte in Zentimetern? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine quadratische Tischplatte hat einen Flächeninhalt von 2,25 m².\n\nWie lang ist eine Seite der Tischplatte in Zentimetern? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'cm', false, 2, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche erkennen und umrechnen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, kommastellen_zu_viel, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '99b7829c-3536-4278-a84e-3dbeea10637c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '99b7829c-3536-4278-a84e-3dbeea10637c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '99b7829c-3536-4278-a84e-3dbeea10637c'::uuid,
  p_correct_answers => '["150","150 cm","150cm"]'::jsonb,
  p_solution        => 'Seitenlänge = √(2,25 m²) = 1,5 m, denn 1,5 · 1,5 = 2,25.
1,5 m = 150 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht in Zentimeter umgerechnet: die Seitenlänge in Metern.","socratic_question":"In welcher Einheit ist die Seitenlänge gefragt?"},{"error":"Das Komma falsch gesetzt: √2,25 als 0,15 gerechnet, also 15 cm.","socratic_question":"Ergibt 0,15 · 0,15 wirklich 2,25?"},{"error":"Die Fläche halbiert statt die Wurzel gezogen: 1,125 m.","socratic_question":"Welche Zahl ergibt mit sich selbst malgenommen 2,25?"}]'::jsonb,
  p_acceptance      => '{"canonical":"150","equivalents":["150 cm","150cm"],"known_errors":{"15":"kommastellen_zu_viel","1,5":"einheit_uebersprungen","1.5":"einheit_uebersprungen","1,5 cm":"einheit_uebersprungen","1,5cm":"einheit_uebersprungen","15 cm":"kommastellen_zu_viel","15cm":"kommastellen_zu_viel","112,5":"wurzel_halbiert","112.5":"wurzel_halbiert","112,5 cm":"wurzel_halbiert","112,5cm":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 wurzel-quadrat-06 · Quadratwurzel · Zaun um einen Platz mit 1296 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5f9d6c06-c962-4b38-9096-4a1ab9c97292'::uuid, 'exercise', 'Quadratwurzel · Zaun um einen Platz mit 1296 m²', 'Ein quadratischer Platz hat einen Flächeninhalt von 1296 m². Er soll ringsum eingezäunt werden.

Wie viele Meter Zaun werden gebraucht? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein quadratischer Platz hat einen Flächeninhalt von 1296 m². Er soll ringsum eingezäunt werden.\n\nWie viele Meter Zaun werden gebraucht? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_quadrat',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-quadrat-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus der Fläche erst die Seite bestimmen, dann den Umfang bilden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5f9d6c06-c962-4b38-9096-4a1ab9c97292'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5f9d6c06-c962-4b38-9096-4a1ab9c97292'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5f9d6c06-c962-4b38-9096-4a1ab9c97292'::uuid,
  p_correct_answers => '["144","144 m","144m"]'::jsonb,
  p_solution        => 'Seitenlänge: √1296 m = 36 m, denn 36 · 36 = 1296.
Zaun = Umfang = 4 · 36 m = 144 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Seitenlänge angegeben, nicht den ganzen Zaun.","socratic_question":"Wie viele Seiten hat der Platz, die eingezäunt werden?"},{"error":"Die Fläche halbiert statt die Wurzel gezogen.","socratic_question":"Welche Zahl ergibt mit sich selbst malgenommen 1296?"}]'::jsonb,
  p_acceptance      => '{"canonical":"144","equivalents":["144 m","144m"],"known_errors":{"36":"falsche_groesse_beantwortet","2592":"wurzel_halbiert","36 m":"falsche_groesse_beantwortet","36m":"falsche_groesse_beantwortet","2592 m":"wurzel_halbiert","2592m":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 wurzel-naeherung-01 · Näherung · √50 zwischen zwei ganzen Zahlen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6585552b-bb6b-4345-98cb-d427378cdfed'::uuid, 'exercise', 'Näherung · √50 zwischen zwei ganzen Zahlen', '√50 liegt zwischen zwei aufeinanderfolgenden ganzen Zahlen.

Gib beide Zahlen an.',
  null, 'MULTI_PART', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Kleinere Zahl","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Größere Zahl","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: benachbarte Quadratzahlen 49 und 64 erkennen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-wurzel"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-wurzel"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-wurzel"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-wurzel"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6585552b-bb6b-4345-98cb-d427378cdfed'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6585552b-bb6b-4345-98cb-d427378cdfed'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6585552b-bb6b-4345-98cb-d427378cdfed'::uuid,
  p_correct_answers => '{"1":["7","+7"],"2":["8","+8"]}'::jsonb,
  p_solution        => 'Benachbarte Quadratzahlen: 7² = 49 < 50 < 64 = 8².
Also liegt √50 zwischen 7 und 8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadratzahl 49 angegeben statt ihrer Wurzel.","socratic_question":"Liegt √50 wirklich in der Nähe von 49?"},{"error":"√50 als 50 : 2 = 25 genommen.","socratic_question":"Was ergibt 25 · 25 – liegt das in der Nähe von 50?"},{"error":"Die Quadratzahl 64 angegeben statt ihrer Wurzel.","socratic_question":"Liegt √50 wirklich in der Nähe von 64?"},{"error":"√50 als 50 : 2 = 25 genommen, dann 26 als nächste Zahl.","socratic_question":"Was ergibt 26 · 26 – liegt das in der Nähe von 50?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"7","equivalents":["+7"],"known_errors":{"25":"wurzel_halbiert","49":"falsche_groesse_beantwortet","+49":"falsche_groesse_beantwortet","+25":"wurzel_halbiert"}},"2":{"canonical":"8","equivalents":["+8"],"known_errors":{"26":"wurzel_halbiert","64":"falsche_groesse_beantwortet","+64":"falsche_groesse_beantwortet","+26":"wurzel_halbiert"}}}'::jsonb);
  end if;
end
$loesung$;

-- #8 wurzel-naeherung-02 · Näherung · √10 auf eine Stelle
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fde9c9a1-f05a-42ff-ab98-d94ee6894d07'::uuid, 'exercise', 'Näherung · √10 auf eine Stelle', 'Berechne √10.

Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Berechne √10.\n\nRunde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Näherungswert einer Wurzel bestimmen und auf eine Stelle runden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fde9c9a1-f05a-42ff-ab98-d94ee6894d07'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fde9c9a1-f05a-42ff-ab98-d94ee6894d07'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fde9c9a1-f05a-42ff-ab98-d94ee6894d07'::uuid,
  p_correct_answers => '["3,2","+3,2","3.2","+3.2"]'::jsonb,
  p_solution        => '√10 ≈ 3,162…
Die zweite Stelle nach dem Komma ist eine 6, also aufrunden: √10 ≈ 3,2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgeschnitten statt gerundet: 3,1.","socratic_question":"Welche Ziffer steht nach der ersten Stelle – wird auf- oder abgerundet?"},{"error":"Halbiert statt die Wurzel gezogen: 10 : 2 = 5.","socratic_question":"Was ergibt 5 · 5 – ist das 10?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3,2","equivalents":["+3,2","3.2","+3.2"],"known_errors":{"5":"wurzel_halbiert","3,1":"abgeschnitten","+3,1":"abgeschnitten","3.1":"abgeschnitten","+3.1":"abgeschnitten","5,0":"wurzel_halbiert","+5,0":"wurzel_halbiert","5.0":"wurzel_halbiert","+5.0":"wurzel_halbiert","+5":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 wurzel-naeherung-03 · Näherung · √30 auf zwei Stellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0b9229a0-db38-4fc4-8b64-1213b5198f50'::uuid, 'exercise', 'Näherung · √30 auf zwei Stellen', 'Berechne √30.

Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Berechne √30.\n\nRunde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel ohne nahe Quadratzahl, auf zwei Stellen runden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0b9229a0-db38-4fc4-8b64-1213b5198f50'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0b9229a0-db38-4fc4-8b64-1213b5198f50'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0b9229a0-db38-4fc4-8b64-1213b5198f50'::uuid,
  p_correct_answers => '["5,48","+5,48","5.48","+5.48"]'::jsonb,
  p_solution        => '√30 ≈ 5,4772…
Die dritte Stelle nach dem Komma ist eine 7, also aufrunden: √30 ≈ 5,48.
Probe: 5² = 25 < 30 < 36 = 6².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgeschnitten statt gerundet: 5,47.","socratic_question":"Welche Ziffer steht an der dritten Stelle nach dem Komma?"},{"error":"Halbiert statt die Wurzel gezogen: 30 : 2 = 15.","socratic_question":"Zwischen welchen Quadratzahlen liegt 30 – passt 15 dazu?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,48","equivalents":["+5,48","5.48","+5.48"],"known_errors":{"15":"wurzel_halbiert","5,47":"abgeschnitten","+5,47":"abgeschnitten","5.47":"abgeschnitten","+5.47":"abgeschnitten","15,00":"wurzel_halbiert","+15,00":"wurzel_halbiert","15.00":"wurzel_halbiert","+15.00":"wurzel_halbiert","+15":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 wurzel-naeherung-04 · Näherung · √0,9 auf zwei Stellen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd'::uuid, 'exercise', 'Näherung · √0,9 auf zwei Stellen', 'Berechne √0,9.

Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Berechne √0,9.\n\nRunde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl; auf zwei Stellen runden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_halbiert, abgeschnitten).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd'::uuid,
  p_correct_answers => '["0,95","+0,95","0.95","+0.95"]'::jsonb,
  p_solution        => '√0,9 ≈ 0,9486…
Die dritte Stelle nach dem Komma ist eine 8, also aufrunden: √0,9 ≈ 0,95.
Die Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl selbst.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Halbiert statt die Wurzel gezogen: 0,9 : 2 = 0,45.","socratic_question":"Was ergibt 0,45 · 0,45 – ist das 0,9?"},{"error":"Abgeschnitten statt gerundet: 0,94.","socratic_question":"Welche Ziffer steht an der dritten Stelle nach dem Komma?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,95","equivalents":["+0,95","0.95","+0.95"],"known_errors":{"0,45":"wurzel_halbiert","+0,45":"wurzel_halbiert","0.45":"wurzel_halbiert","+0.45":"wurzel_halbiert","0,94":"abgeschnitten","+0,94":"abgeschnitten","0.94":"abgeschnitten","+0.94":"abgeschnitten"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 wurzel-naeherung-05 · Näherung · Seite eines Beets mit 11 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cd35f4b2-62da-4f01-9215-bc9504f8e67a'::uuid, 'exercise', 'Näherung · Seite eines Beets mit 11 m²', 'Ein quadratisches Beet hat einen Flächeninhalt von 11 m².

Wie lang ist eine Seite des Beets? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein quadratisches Beet hat einen Flächeninhalt von 11 m².\n\nWie lang ist eine Seite des Beets? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'm', false, 2, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche, auf Zentimeter runden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, wurzel_halbiert, kommastellen_zu_wenig).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cd35f4b2-62da-4f01-9215-bc9504f8e67a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cd35f4b2-62da-4f01-9215-bc9504f8e67a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cd35f4b2-62da-4f01-9215-bc9504f8e67a'::uuid,
  p_correct_answers => '["3,32","3.32","3,32 m","3,32m"]'::jsonb,
  p_solution        => 'Seitenlänge = √(11 m²) ≈ 3,3166… m.
Auf zwei Stellen gerundet: 3,32 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgeschnitten statt gerundet: 3,31 m.","socratic_question":"Welche Ziffer steht an der dritten Stelle nach dem Komma?"},{"error":"Die Fläche halbiert statt die Wurzel gezogen: 5,5 m.","socratic_question":"Wie groß wäre ein Beet mit 5,5 m Seitenlänge?"},{"error":"Nur auf eine Stelle gerundet: 3,3 m.","socratic_question":"Auf wie viele Stellen nach dem Komma sollst du runden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3,32","equivalents":["3.32","3,32 m","3,32m"],"known_errors":{"3,31":"abgeschnitten","3.31":"abgeschnitten","3,31 m":"abgeschnitten","3,31m":"abgeschnitten","5,50":"wurzel_halbiert","5.50":"wurzel_halbiert","5,5":"wurzel_halbiert","5.5":"wurzel_halbiert","5,50 m":"wurzel_halbiert","5,50m":"wurzel_halbiert","5,5 m":"wurzel_halbiert","5,5m":"wurzel_halbiert","3,3":"kommastellen_zu_wenig","3.3":"kommastellen_zu_wenig","3,3 m":"kommastellen_zu_wenig","3,3m":"kommastellen_zu_wenig"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 wurzel-naeherung-06 · Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '81015f65-8ac0-4ef3-abb8-9a7b87c44940'::uuid, 'exercise', 'Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern', 'Ein quadratischer Teppich soll einen Flächeninhalt von mindestens 6 m² haben.

Wie lang muss eine Seite mindestens sein? Gib ganze Zentimeter an und runde dafür auf.',
  '{"kind":"short_input","prompt":"Ein quadratischer Teppich soll einen Flächeninhalt von mindestens 6 m² haben.\n\nWie lang muss eine Seite mindestens sein? Gib ganze Zentimeter an und runde dafür auf."}'::jsonb, 'NUMERIC', 'zahl_wurzel_naeherung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, 'cm', false, 1, 'draft', 'edvance_k9_wurzel', 'wurzel-naeherung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Wurzel ziehen, in Zentimeter umrechnen und sinnvoll aufrunden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (abgeschnitten, einheit_uebersprungen, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '81015f65-8ac0-4ef3-abb8-9a7b87c44940'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '81015f65-8ac0-4ef3-abb8-9a7b87c44940'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '81015f65-8ac0-4ef3-abb8-9a7b87c44940'::uuid,
  p_correct_answers => '["245","245 cm","245cm"]'::jsonb,
  p_solution        => 'Seitenlänge = √(6 m²) ≈ 2,4495 m = 244,95 cm.
Mit 244 cm wäre der Teppich zu klein, also mindestens 245 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abgerundet: Mit 244 cm sind es weniger als 6 m².","socratic_question":"Reicht die Fläche, wenn du abrundest?"},{"error":"Nicht in Zentimeter umgerechnet: die Seitenlänge in Metern.","socratic_question":"In welcher Einheit ist die Seitenlänge gefragt?"},{"error":"Die Fläche halbiert statt die Wurzel gezogen: 3 m.","socratic_question":"Wie groß wäre ein Teppich mit 3 m Seitenlänge?"}]'::jsonb,
  p_acceptance      => '{"canonical":"245","equivalents":["245 cm","245cm"],"known_errors":{"244":"abgeschnitten","300":"wurzel_halbiert","244 cm":"abgeschnitten","244cm":"abgeschnitten","2,45":"einheit_uebersprungen","2.45":"einheit_uebersprungen","2,45 cm":"einheit_uebersprungen","2,45cm":"einheit_uebersprungen","300 cm":"wurzel_halbiert","300cm":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 wurzel-irrational-01 · Irrational · Anzahl unter fünf Zahlen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '54382934-12e4-4819-8dc4-5f4f5650471f'::uuid, 'exercise', 'Irrational · Anzahl unter fünf Zahlen', 'Wie viele der folgenden Zahlen sind irrational?

√2;   √9;   0,5;   √5;   3/7

Gib die Anzahl als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Wie viele der folgenden Zahlen sind irrational?\n\n√2;   √9;   0,5;   √5;   3/7\n\nGib die Anzahl als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Wurzeln aus Nicht-Quadratzahlen als irrational erkennen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (irrational_verwechselt).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '54382934-12e4-4819-8dc4-5f4f5650471f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '54382934-12e4-4819-8dc4-5f4f5650471f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '54382934-12e4-4819-8dc4-5f4f5650471f'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => '√9 = 3, 0,5 und 3/7 sind Brüche, also rational.
√2 und √5 sind Wurzeln aus Zahlen, die keine Quadratzahlen sind: irrational.
Anzahl: 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"√9 auch für irrational gehalten, obwohl √9 = 3.","socratic_question":"Welche ganze Zahl ergibt quadriert 9?"},{"error":"√9 und 3/7 für irrational gehalten; 3/7 ist ein Bruch und damit rational.","socratic_question":"Lässt sich 3/7 als Bruch schreiben?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","equivalents":["+2"],"known_errors":{"3":"irrational_verwechselt","4":"irrational_verwechselt","+3":"irrational_verwechselt","+4":"irrational_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 wurzel-irrational-02 · Rational · 0,375 als gekürzter Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9935f4bb-1222-4ead-bf3c-6b8cfd134395'::uuid, 'exercise', 'Rational · 0,375 als gekürzter Bruch', 'Schreibe 0,375 als vollständig gekürzten Bruch.

Gib den Nenner an.',
  '{"kind":"short_input","prompt":"Schreibe 0,375 als vollständig gekürzten Bruch.\n\nGib den Nenner an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: abbrechende Dezimalzahl als Bruch schreiben und vollständig kürzen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilgekuerzt).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9935f4bb-1222-4ead-bf3c-6b8cfd134395'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9935f4bb-1222-4ead-bf3c-6b8cfd134395'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9935f4bb-1222-4ead-bf3c-6b8cfd134395'::uuid,
  p_correct_answers => '["8","+8"]'::jsonb,
  p_solution        => '0,375 = 375/1000.
ggT(375; 1000) = 125, also 375/1000 = 3/8.
Nenner: 8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Gar nicht gekürzt: 375/1000.","socratic_question":"Haben 375 und 1000 noch einen gemeinsamen Teiler?"},{"error":"Nur durch 5 gekürzt: 75/200.","socratic_question":"Lässt sich 75/200 noch weiter kürzen?"},{"error":"Nur durch 25 gekürzt: 15/40.","socratic_question":"Lässt sich 15/40 noch weiter kürzen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["+8"],"known_errors":{"40":"teilgekuerzt","200":"teilgekuerzt","1000":"teilgekuerzt","+1000":"teilgekuerzt","+200":"teilgekuerzt","+40":"teilgekuerzt"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 wurzel-irrational-03 · Rational · 0,4545… als gekürzter Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ae8478c7-f104-407a-a75a-087d71e20757'::uuid, 'exercise', 'Rational · 0,4545… als gekürzter Bruch', 'Die Zahl 0,454545… (Periode 45) ist rational.

Schreibe sie als vollständig gekürzten Bruch und gib den Nenner an.',
  '{"kind":"short_input","prompt":"Die Zahl 0,454545… (Periode 45) ist rational.\n\nSchreibe sie als vollständig gekürzten Bruch und gib den Nenner an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: periodische Dezimalzahl als Bruch schreiben (Periode durch 99) und kürzen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilgekuerzt, abgeschnitten).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ae8478c7-f104-407a-a75a-087d71e20757'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ae8478c7-f104-407a-a75a-087d71e20757'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ae8478c7-f104-407a-a75a-087d71e20757'::uuid,
  p_correct_answers => '["11","+11"]'::jsonb,
  p_solution        => '0,454545… (Periode 45) = 45/99.
ggT(45; 99) = 9, also 45/99 = 5/11.
Nenner: 11.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht gekürzt: 45/99.","socratic_question":"Haben 45 und 99 noch einen gemeinsamen Teiler?"},{"error":"Die Periode abgeschnitten: 0,45 = 45/100 = 9/20.","socratic_question":"Ist 0,45 genau gleich 0,454545…?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11","equivalents":["+11"],"known_errors":{"20":"abgeschnitten","99":"teilgekuerzt","+99":"teilgekuerzt","+20":"abgeschnitten"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 wurzel-irrational-04 · Rational · Anzahl unter sechs Zahlen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '834de179-1fbd-4491-9d86-fd572310f3dd'::uuid, 'exercise', 'Rational · Anzahl unter sechs Zahlen', 'Wie viele der folgenden Zahlen sind rational?

√16;   √12;   0,333… (Periode 3);   π;   √0,25;   −5

Gib die Anzahl als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Wie viele der folgenden Zahlen sind rational?\n\n√16;   √12;   0,333… (Periode 3);   π;   √0,25;   −5\n\nGib die Anzahl als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Wurzeln, periodische Dezimalzahl, π und negative Zahl sicher zuordnen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (irrational_verwechselt).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '834de179-1fbd-4491-9d86-fd572310f3dd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '834de179-1fbd-4491-9d86-fd572310f3dd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '834de179-1fbd-4491-9d86-fd572310f3dd'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => 'Rational: √16 = 4, 0,333… (Periode 3) = 1/3, √0,25 = 0,5 und −5.
Irrational: √12 (12 ist keine Quadratzahl) und π.
Anzahl: 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die periodische Zahl 0,333… für irrational gehalten, obwohl sie 1/3 ist.","socratic_question":"Lässt sich 0,333… (Periode 3) als Bruch schreiben?"},{"error":"Die periodische Zahl und √0,25 für irrational gehalten.","socratic_question":"Welche Zahl ergibt quadriert 0,25?"},{"error":"π für rational gehalten, weil man oft mit 3,14 rechnet.","socratic_question":"Ist 3,14 der genaue Wert von π oder nur ein Näherungswert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["+4"],"known_errors":{"2":"irrational_verwechselt","3":"irrational_verwechselt","5":"irrational_verwechselt","+3":"irrational_verwechselt","+2":"irrational_verwechselt","+5":"irrational_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 wurzel-irrational-05 · Irrational · Fliesen mit rationaler Seitenlänge
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd851f251-cbe5-4804-b74d-2458c7a855af'::uuid, 'exercise', 'Irrational · Fliesen mit rationaler Seitenlänge', 'Ein Betrieb stellt quadratische Fliesen mit diesen Flächeninhalten her (in cm²):

49;   50;   2,25;   8;   0,64;   12,1

Bei wie vielen dieser Fliesen ist die Seitenlänge in cm eine rationale Zahl? Gib die Anzahl als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Ein Betrieb stellt quadratische Fliesen mit diesen Flächeninhalten her (in cm²):\n\n49;   50;   2,25;   8;   0,64;   12,1\n\nBei wie vielen dieser Fliesen ist die Seitenlänge in cm eine rationale Zahl? Gib die Anzahl als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: aus Flächeninhalten entscheiden, ob die Seitenlänge rational ist.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (irrational_verwechselt).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd851f251-cbe5-4804-b74d-2458c7a855af'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd851f251-cbe5-4804-b74d-2458c7a855af'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd851f251-cbe5-4804-b74d-2458c7a855af'::uuid,
  p_correct_answers => '["3","+3"]'::jsonb,
  p_solution        => 'Seitenlänge = Wurzel aus dem Flächeninhalt.
Rational: √49 = 7, √2,25 = 1,5, √0,64 = 0,8.
Irrational: √50, √8 und √12,1 (12,1 ist kein Quadrat einer Dezimalzahl, 3,4² = 11,56 und 3,5² = 12,25).
Anzahl: 3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"√12,1 für rational gehalten, weil 121 = 11² ist; 11² = 121, aber 1,1² = 1,21.","socratic_question":"Welche Zahl ergibt quadriert 12,1 – gibt es dafür eine abbrechende Dezimalzahl?"},{"error":"Die Wurzeln aus den Dezimalzahlen 2,25 und 0,64 für irrational gehalten.","socratic_question":"Was ergibt 1,5 · 1,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","equivalents":["+3"],"known_errors":{"1":"irrational_verwechselt","4":"irrational_verwechselt","+4":"irrational_verwechselt","+1":"irrational_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 wurzel-irrational-06 · Irrational · rationale Wurzeln von 1 bis 60
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'::uuid, 'exercise', 'Irrational · rationale Wurzeln von 1 bis 60', 'Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl?

Gib die Anzahl als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl?\n\nGib die Anzahl als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_irrational',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  90, null, false, 2, 'draft', 'edvance_k9_wurzel', 'wurzel-irrational-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: erkennen, dass √n für natürliches n genau bei Quadratzahlen rational ist, dann zählen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, irrational_verwechselt).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => '√n ist für eine natürliche Zahl n genau dann rational, wenn n eine Quadratzahl ist.
Quadratzahlen von 1 bis 60: 1, 4, 9, 16, 25, 36, 49 (64 ist schon zu groß).
Anzahl: 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die irrationalen Wurzeln gezählt statt der rationalen.","socratic_question":"Wurde nach den rationalen oder nach den irrationalen Wurzeln gefragt?"},{"error":"Alle Wurzeln für irrational gehalten, auch √1, √4, √9 …","socratic_question":"Ist √4 = 2 eine irrationale Zahl?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7"],"known_errors":{"0":"irrational_verwechselt","53":"falsche_groesse_beantwortet","+53":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 wurzel-gesetze-01 · Wurzelgesetz · √2 · √8
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a0a8c04b-145b-4010-8c46-b5c7520d54bb'::uuid, 'exercise', 'Wurzelgesetz · √2 · √8', 'Berechne √2 · √8.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √2 · √8.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Produktgesetz √a · √b = √(a · b), Ergebnis eine Quadratzahl.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a0a8c04b-145b-4010-8c46-b5c7520d54bb'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a0a8c04b-145b-4010-8c46-b5c7520d54bb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a0a8c04b-145b-4010-8c46-b5c7520d54bb'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => '√2 · √8 = √(2 · 8) = √16 = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur 2 · 8 = 16 gerechnet, die Wurzel aus 16 nicht gezogen.","socratic_question":"Steht 16 noch unter der Wurzel?"},{"error":"√16 als 16 : 2 = 8 genommen.","socratic_question":"Was ergibt 8 · 8?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["+4"],"known_errors":{"8":"wurzel_halbiert","16":"falsche_groesse_beantwortet","+16":"falsche_groesse_beantwortet","+8":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 wurzel-gesetze-02 · Wurzelgesetz · √50 : √2
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '760fc0ad-d0c6-4a09-889b-c116a2f0ff78'::uuid, 'exercise', 'Wurzelgesetz · √50 : √2', 'Berechne √50 : √2.

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √50 : √2.\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Quotientengesetz √a : √b = √(a : b), Ergebnis eine Quadratzahl.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '760fc0ad-d0c6-4a09-889b-c116a2f0ff78'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '760fc0ad-d0c6-4a09-889b-c116a2f0ff78'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '760fc0ad-d0c6-4a09-889b-c116a2f0ff78'::uuid,
  p_correct_answers => '["5","+5"]'::jsonb,
  p_solution        => '√50 : √2 = √(50 : 2) = √25 = 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur 50 : 2 = 25 gerechnet, die Wurzel aus 25 nicht gezogen.","socratic_question":"Steht 25 noch unter der Wurzel?"},{"error":"√25 als 25 : 2 = 12,5 genommen.","socratic_question":"Was ergibt 12,5 · 12,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5"],"known_errors":{"25":"falsche_groesse_beantwortet","+25":"falsche_groesse_beantwortet","12,5":"wurzel_halbiert","+12,5":"wurzel_halbiert","12.5":"wurzel_halbiert","+12.5":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 wurzel-gesetze-03 · Wurzel einer Summe · √(36 + 64)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '926f4f6e-7eca-43f5-92c2-855eff8167b4'::uuid, 'exercise', 'Wurzel einer Summe · √(36 + 64)', 'Berechne √(36 + 64).

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √(36 + 64).\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erkennen, dass es für die Summe kein Wurzelgesetz gibt; erst addieren, dann Wurzel ziehen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_gliedweise, falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '926f4f6e-7eca-43f5-92c2-855eff8167b4'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '926f4f6e-7eca-43f5-92c2-855eff8167b4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '926f4f6e-7eca-43f5-92c2-855eff8167b4'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Für Summen gibt es kein Wurzelgesetz: erst unter der Wurzel rechnen.
√(36 + 64) = √100 = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wurzel gliedweise gezogen: √36 + √64 = 6 + 8 = 14.","socratic_question":"Was ergibt 14 · 14 – ist das 36 + 64?"},{"error":"Nur 36 + 64 = 100 gerechnet, die Wurzel nicht gezogen.","socratic_question":"Steht 100 noch unter der Wurzel?"},{"error":"√100 als 100 : 2 = 50 genommen.","socratic_question":"Was ergibt 50 · 50?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"14":"wurzel_gliedweise","50":"wurzel_halbiert","100":"falsche_groesse_beantwortet","+14":"wurzel_gliedweise","+100":"falsche_groesse_beantwortet","+50":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 wurzel-gesetze-04 · Wurzel einer Summe · √(1,44 + 0,81)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ce24db36-6dac-4b3f-8395-e815549a7689'::uuid, 'exercise', 'Wurzel einer Summe · √(1,44 + 0,81)', 'Berechne √(1,44 + 0,81).

Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Berechne √(1,44 + 0,81).\n\nGib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Summe mit Dezimalzahlen unter der Wurzel, gliedweises Wurzelziehen ist verlockend.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_gliedweise, falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ce24db36-6dac-4b3f-8395-e815549a7689'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ce24db36-6dac-4b3f-8395-e815549a7689'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ce24db36-6dac-4b3f-8395-e815549a7689'::uuid,
  p_correct_answers => '["1,5","+1,5","1.5","+1.5"]'::jsonb,
  p_solution        => 'Erst unter der Wurzel addieren: 1,44 + 0,81 = 2,25.
√2,25 = 1,5, denn 1,5 · 1,5 = 2,25.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wurzel gliedweise gezogen: √1,44 + √0,81 = 1,2 + 0,9 = 2,1.","socratic_question":"Was ergibt 2,1 · 2,1 – ist das 2,25?"},{"error":"Nur 1,44 + 0,81 = 2,25 gerechnet, die Wurzel nicht gezogen.","socratic_question":"Steht 2,25 noch unter der Wurzel?"},{"error":"√2,25 als 2,25 : 2 = 1,125 genommen.","socratic_question":"Was ergibt 1,125 · 1,125?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5"],"known_errors":{"2,1":"wurzel_gliedweise","+2,1":"wurzel_gliedweise","2.1":"wurzel_gliedweise","+2.1":"wurzel_gliedweise","2,25":"falsche_groesse_beantwortet","+2,25":"falsche_groesse_beantwortet","2.25":"falsche_groesse_beantwortet","+2.25":"falsche_groesse_beantwortet","1,125":"wurzel_halbiert","+1,125":"wurzel_halbiert","1.125":"wurzel_halbiert","+1.125":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 wurzel-gesetze-05 · Wurzelgesetz · Rechteck √8 m mal √18 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4f7652bf-34f5-46ce-b17b-54ffd1fdd0d3'::uuid, 'exercise', 'Wurzelgesetz · Rechteck √8 m mal √18 m', 'Ein rechteckiges Feld ist √8 m lang und √18 m breit.

Wie groß ist sein Flächeninhalt in Quadratmetern? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechteckiges Feld ist √8 m lang und √18 m breit.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'm²', false, 2, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Flächeninhalt als Produkt zweier Wurzeln, Produktgesetz nutzen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, umfang_statt_flaeche, plus_statt_mal).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4f7652bf-34f5-46ce-b17b-54ffd1fdd0d3'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4f7652bf-34f5-46ce-b17b-54ffd1fdd0d3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4f7652bf-34f5-46ce-b17b-54ffd1fdd0d3'::uuid,
  p_correct_answers => '["12","12 m²","12m²"]'::jsonb,
  p_solution        => 'A = √8 m · √18 m = √(8 · 18) m² = √144 m² = 12 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur 8 · 18 = 144 gerechnet, die Wurzel nicht gezogen.","socratic_question":"Steht 144 noch unter der Wurzel?"},{"error":"Den Umfang berechnet statt des Flächeninhalts: etwa 14,14 m.","socratic_question":"Ist nach dem Rand oder nach der Fläche des Feldes gefragt?"},{"error":"Unter der Wurzel addiert statt multipliziert: √26 ≈ 5,10.","socratic_question":"Wie berechnet man den Flächeninhalt eines Rechtecks?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","equivalents":["12 m²","12m²"],"known_errors":{"144":"falsche_groesse_beantwortet","144 m²":"falsche_groesse_beantwortet","144m²":"falsche_groesse_beantwortet","14,14":"umfang_statt_flaeche","14.14":"umfang_statt_flaeche","14,14 m²":"umfang_statt_flaeche","14,14m²":"umfang_statt_flaeche","5,10":"plus_statt_mal","5.10":"plus_statt_mal","5,1":"plus_statt_mal","5.1":"plus_statt_mal","5,10 m²":"plus_statt_mal","5,10m²":"plus_statt_mal","5,1 m²":"plus_statt_mal","5,1m²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 wurzel-gesetze-06 · Wurzel einer Summe · ein Beet so groß wie zwei
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '88c99e21-a70e-42e5-b426-07e29b93d3fe'::uuid, 'exercise', 'Wurzel einer Summe · ein Beet so groß wie zwei', 'Zwei quadratische Beete haben die Flächeninhalte 9 m² und 16 m². Sie sollen durch ein einziges quadratisches Beet ersetzt werden, das genau so groß ist wie beide zusammen.

Wie lang ist eine Seite des neuen Beets? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei quadratische Beete haben die Flächeninhalte 9 m² und 16 m². Sie sollen durch ein einziges quadratisches Beet ersetzt werden, das genau so groß ist wie beide zusammen.\n\nWie lang ist eine Seite des neuen Beets? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-gesetze-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Flächen addieren und erst danach die Wurzel ziehen; die Seiten dürfen nicht addiert werden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_gliedweise, falsche_groesse_beantwortet, wurzel_halbiert).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '88c99e21-a70e-42e5-b426-07e29b93d3fe'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '88c99e21-a70e-42e5-b426-07e29b93d3fe'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '88c99e21-a70e-42e5-b426-07e29b93d3fe'::uuid,
  p_correct_answers => '["5","5 m","5m"]'::jsonb,
  p_solution        => 'Fläche des neuen Beets: 9 m² + 16 m² = 25 m².
Seitenlänge: √25 m = 5 m.
(Nicht 3 m + 4 m: ein Quadrat mit 7 m Seite hätte 49 m².)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Seitenlängen addiert: √9 + √16 = 3 + 4 = 7.","socratic_question":"Wie groß wäre ein quadratisches Beet mit 7 m Seitenlänge?"},{"error":"Den Flächeninhalt 25 angegeben statt der Seitenlänge.","socratic_question":"Wurde nach der Fläche oder nach der Seite gefragt?"},{"error":"√25 als 25 : 2 = 12,5 genommen.","socratic_question":"Was ergibt 12,5 · 12,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["5 m","5m"],"known_errors":{"7":"wurzel_gliedweise","25":"falsche_groesse_beantwortet","7 m":"wurzel_gliedweise","7m":"wurzel_gliedweise","25 m":"falsche_groesse_beantwortet","25m":"falsche_groesse_beantwortet","12,5":"wurzel_halbiert","12.5":"wurzel_halbiert","12,5 m":"wurzel_halbiert","12,5m":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 wurzel-teilweise-01 · Teilweise Wurzel ziehen · √72 = a · √2
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0bcc83c8-42f0-4956-b1d0-00446cb6e5e2'::uuid, 'exercise', 'Teilweise Wurzel ziehen · √72 = a · √2', 'Es gilt √72 = a · √2.

Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.',
  '{"kind":"short_input","prompt":"Es gilt √72 = a · √2.\n\nBestimme a. a ist eine natürliche Zahl. Gib a exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Quadratzahl-Faktor 36 abspalten, Form vorgegeben.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, wurzel_halbiert, falsche_groesse_beantwortet).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0bcc83c8-42f0-4956-b1d0-00446cb6e5e2'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0bcc83c8-42f0-4956-b1d0-00446cb6e5e2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0bcc83c8-42f0-4956-b1d0-00446cb6e5e2'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => '72 = 36 · 2, also √72 = √36 · √2 = 6 · √2.
a = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.","socratic_question":"Was ergibt (36 · √2)² – ist das 72?"},{"error":"√36 als 36 : 2 = 18 genommen.","socratic_question":"Was ergibt 18 · 18?"},{"error":"Den Näherungswert von √72 angegeben statt a.","socratic_question":"Nach welcher Zahl ist gefragt: nach √72 oder nach dem Faktor vor √2?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"18":"wurzel_halbiert","36":"faktor_ohne_wurzel","+36":"faktor_ohne_wurzel","+18":"wurzel_halbiert","8,49":"falsche_groesse_beantwortet","+8,49":"falsche_groesse_beantwortet","8.49":"falsche_groesse_beantwortet","+8.49":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 wurzel-teilweise-02 · Teilweise Wurzel ziehen · √48 = a · √3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '21427340-fc85-41c4-abea-99ad0121b83c'::uuid, 'exercise', 'Teilweise Wurzel ziehen · √48 = a · √3', 'Es gilt √48 = a · √3.

Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.',
  '{"kind":"short_input","prompt":"Es gilt √48 = a · √3.\n\nBestimme a. a ist eine natürliche Zahl. Gib a exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Quadratzahl-Faktor 16 abspalten, Form vorgegeben.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, wurzel_halbiert, falsche_groesse_beantwortet).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '21427340-fc85-41c4-abea-99ad0121b83c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '21427340-fc85-41c4-abea-99ad0121b83c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '21427340-fc85-41c4-abea-99ad0121b83c'::uuid,
  p_correct_answers => '["4","+4"]'::jsonb,
  p_solution        => '48 = 16 · 3, also √48 = √16 · √3 = 4 · √3.
a = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 16 herausgezogen, ohne aus ihm die Wurzel zu ziehen.","socratic_question":"Was ergibt (16 · √3)² – ist das 48?"},{"error":"√16 als 16 : 2 = 8 genommen.","socratic_question":"Was ergibt 8 · 8?"},{"error":"Den Näherungswert von √48 angegeben statt a.","socratic_question":"Nach welcher Zahl ist gefragt: nach √48 oder nach dem Faktor vor √3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["+4"],"known_errors":{"8":"wurzel_halbiert","16":"faktor_ohne_wurzel","+16":"faktor_ohne_wurzel","+8":"wurzel_halbiert","6,93":"falsche_groesse_beantwortet","+6,93":"falsche_groesse_beantwortet","6.93":"falsche_groesse_beantwortet","+6.93":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 wurzel-teilweise-03 · Teilweise Wurzel ziehen · √200 = a · √2
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ad08897e-a44b-43fb-a779-96b889c069db'::uuid, 'exercise', 'Teilweise Wurzel ziehen · √200 = a · √2', 'Es gilt √200 = a · √2.

Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.',
  '{"kind":"short_input","prompt":"Es gilt √200 = a · √2.\n\nBestimme a. a ist eine natürliche Zahl. Gib a exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: großer Radikand, der Quadratzahl-Faktor 100 muss erst gefunden werden.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, falsche_groesse_beantwortet).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ad08897e-a44b-43fb-a779-96b889c069db'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ad08897e-a44b-43fb-a779-96b889c069db'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ad08897e-a44b-43fb-a779-96b889c069db'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => '200 = 100 · 2, also √200 = √100 · √2 = 10 · √2.
a = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 100 herausgezogen, ohne aus ihm die Wurzel zu ziehen.","socratic_question":"Was ergibt (100 · √2)² – ist das 200?"},{"error":"Den Näherungswert von √200 angegeben statt a.","socratic_question":"Nach welcher Zahl ist gefragt: nach √200 oder nach dem Faktor vor √2?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"100":"faktor_ohne_wurzel","+100":"faktor_ohne_wurzel","14,14":"falsche_groesse_beantwortet","+14,14":"falsche_groesse_beantwortet","14.14":"falsche_groesse_beantwortet","+14.14":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 wurzel-teilweise-04 · Teilweise Wurzel ziehen · √18 · √6 = a · √3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1dece473-758d-4108-9969-02b495dbf4ed'::uuid, 'exercise', 'Teilweise Wurzel ziehen · √18 · √6 = a · √3', 'Es gilt √18 · √6 = a · √3.

Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.',
  '{"kind":"short_input","prompt":"Es gilt √18 · √6 = a · √3.\n\nBestimme a. a ist eine natürliche Zahl. Gib a exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst das Produktgesetz, dann teilweise die Wurzel ziehen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, wurzel_halbiert, falsche_groesse_beantwortet).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1dece473-758d-4108-9969-02b495dbf4ed'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1dece473-758d-4108-9969-02b495dbf4ed'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1dece473-758d-4108-9969-02b495dbf4ed'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => '√18 · √6 = √108.
108 = 36 · 3, also √108 = √36 · √3 = 6 · √3.
a = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.","socratic_question":"Was ergibt (36 · √3)² – ist das 108?"},{"error":"√36 als 36 : 2 = 18 genommen.","socratic_question":"Was ergibt 18 · 18?"},{"error":"Den Näherungswert von √108 angegeben statt a.","socratic_question":"Nach welcher Zahl ist gefragt: nach dem Produkt oder nach dem Faktor vor √3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"18":"wurzel_halbiert","36":"faktor_ohne_wurzel","+36":"faktor_ohne_wurzel","+18":"wurzel_halbiert","10,39":"falsche_groesse_beantwortet","+10,39":"falsche_groesse_beantwortet","10.39":"falsche_groesse_beantwortet","+10.39":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 wurzel-teilweise-05 · Teilweise Wurzel ziehen · Spielplatz mit 180 m²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'df6b2bcd-8643-46b2-9553-db75854b597d'::uuid, 'exercise', 'Teilweise Wurzel ziehen · Spielplatz mit 180 m²', 'Ein quadratischer Spielplatz hat einen Flächeninhalt von 180 m². Seine Seitenlänge lässt sich exakt als a · √5 m schreiben.

Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.',
  '{"kind":"short_input","prompt":"Ein quadratischer Spielplatz hat einen Flächeninhalt von 180 m². Seine Seitenlänge lässt sich exakt als a · √5 m schreiben.\n\nBestimme a. a ist eine natürliche Zahl. Gib a exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche, dann teilweise die Wurzel ziehen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, wurzel_halbiert, falsche_groesse_beantwortet).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'df6b2bcd-8643-46b2-9553-db75854b597d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'df6b2bcd-8643-46b2-9553-db75854b597d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'df6b2bcd-8643-46b2-9553-db75854b597d'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => 'Seitenlänge = √180 m.
180 = 36 · 5, also √180 = √36 · √5 = 6 · √5.
a = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.","socratic_question":"Was ergibt (36 · √5)² – ist das 180?"},{"error":"√36 als 36 : 2 = 18 genommen.","socratic_question":"Was ergibt 18 · 18?"},{"error":"Die Seitenlänge als Näherungswert angegeben statt a.","socratic_question":"Nach welcher Zahl ist gefragt: nach der Seitenlänge oder nach dem Faktor vor √5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"18":"wurzel_halbiert","36":"faktor_ohne_wurzel","+36":"faktor_ohne_wurzel","+18":"wurzel_halbiert","13,42":"falsche_groesse_beantwortet","+13,42":"falsche_groesse_beantwortet","13.42":"falsche_groesse_beantwortet","+13.42":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 wurzel-teilweise-06 · Rückrichtung · 6 · √3 = √b
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ef90a8ac-bbd4-4c36-9e02-26144cc9d9b0'::uuid, 'exercise', 'Rückrichtung · 6 · √3 = √b', 'Es gilt 6 · √3 = √b.

Bestimme b. b ist eine natürliche Zahl. Gib b exakt an.',
  '{"kind":"short_input","prompt":"Es gilt 6 · √3 = √b.\n\nBestimme b. b ist eine natürliche Zahl. Gib b exakt an."}'::jsonb, 'NUMERIC', 'zahl_wurzel_teilweise',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  90, null, false, 2, 'draft', 'edvance_k9_wurzel', 'wurzel-teilweise-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – den Faktor quadrieren und unter die Wurzel bringen.","charge":"k9-wurzel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-wurzel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).","charge":"k9-wurzel"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.","charge":"k9-wurzel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).","charge":"k9-wurzel"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-wurzel"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-wurzel"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-wurzel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-wurzel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_ohne_wurzel, mal_exponent).","charge":"k9-wurzel"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-wurzel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ef90a8ac-bbd4-4c36-9e02-26144cc9d9b0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_wurzel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ef90a8ac-bbd4-4c36-9e02-26144cc9d9b0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ef90a8ac-bbd4-4c36-9e02-26144cc9d9b0'::uuid,
  p_correct_answers => '["108","+108"]'::jsonb,
  p_solution        => '6 = √36, also 6 · √3 = √36 · √3 = √(36 · 3) = √108.
b = 108.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor 6 unter die Wurzel gebracht, ohne ihn zu quadrieren: √18.","socratic_question":"Was ergibt √18 ungefähr – ist das so viel wie 6 · √3?"},{"error":"6² als 2 · 6 = 12 gerechnet: √36.","socratic_question":"Was ergibt 6 · 6?"}]'::jsonb,
  p_acceptance      => '{"canonical":"108","equivalents":["+108"],"known_errors":{"18":"faktor_ohne_wurzel","36":"mal_exponent","+18":"faktor_ohne_wurzel","+36":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;
