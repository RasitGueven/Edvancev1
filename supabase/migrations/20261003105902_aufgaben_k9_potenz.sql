-- K9-Rest, Thema potenz — 24 Aufgaben: je sechs zu zahl_potenz_gesetze, _negativ, _zehner und _rechnen.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-potenz.json (Quelle: tools/k9-potenz-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105853_substrat_k9_potenz.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Problemlösen (Zellkultur, Würfelzerlegung, Halbierung, Blutkörperchen, Viren und Sandkorn, Lichtweg). Alle ohne Abbildung lösbar, alle exakt. Die wissenschaftliche Schreibweise wird nie als Eingabe verlangt: gefragt ist die Hochzahl allein oder Vorfaktor und Hochzahl als zwei Teile (MULTI_PART). Negative Hochzahlen: Bruch und Dezimalzahl werden beide akzeptiert.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-potenz.csv. Pruefprotokoll: docs/prefill/k9-potenz-verifikation.md.
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
--   zahl_potenz_gesetze: potenz-gesetze-05 = 1, potenz-gesetze-06 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,mal_exponent,potenzgesetz_verwechselt}, Rang 2 aus Profil {falsche_groesse_beantwortet,linearer_faktor,potenzgesetz_verwechselt} (1 neue Fehlbilder)
--   zahl_potenz_negativ: potenz-negativ-06 = 1, potenz-negativ-02 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,negativer_exponent_negativ,potenzgesetz_verwechselt}, Rang 2 aus Profil {faktor_zehn_daneben,mal_exponent,negativer_exponent_negativ} (2 neue Fehlbilder)
--   zahl_potenz_zehner: potenz-zehner-04 = 1, potenz-zehner-03 = 2. Rang 1 aus Profil {faktor_zehn_daneben,mal_exponent,zehnerexponent_vorzeichen}, Rang 2 aus Profil {faktor_zehn_daneben,negativer_exponent_negativ,zehnerexponent_vorzeichen} (1 neue Fehlbilder)
--   zahl_potenz_rechnen: potenz-rechnen-01 = 1, potenz-rechnen-04 = 2. Rang 1 aus Profil {plus_statt_mal,potenzgesetz_verwechselt,zehnerexponent_vorzeichen}, Rang 2 aus Profil {faktor_zehn_daneben,multipliziert_statt_dividiert,potenzgesetz_verwechselt} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 potenz-gesetze-01 · Potenzgesetze · 2³ · 2⁴ = 2ⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0de77a9a-3e05-4e84-ac05-177a2a3012b6'::uuid, 'exercise', 'Potenzgesetze · 2³ · 2⁴ = 2ⁿ', '2³ · 2⁴ = 2ⁿ

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"2³ · 2⁴ = 2ⁿ\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Produkt gleicher Basen, Hochzahlen addieren.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0de77a9a-3e05-4e84-ac05-177a2a3012b6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0de77a9a-3e05-4e84-ac05-177a2a3012b6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0de77a9a-3e05-4e84-ac05-177a2a3012b6'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => 'Gleiche Basis beim Malnehmen: Hochzahlen addieren.
2³ · 2⁴ = 2³⁺⁴ = 2⁷, also n = 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahlen multipliziert statt addiert: 3 · 4 = 12.","socratic_question":"Wie viele Zweien stehen in 2³ · 2⁴, wenn du alles ausschreibst?"},{"error":"Den Wert 2⁷ = 128 angegeben statt der Hochzahl n.","socratic_question":"Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7"],"known_errors":{"12":"potenzgesetz_verwechselt","128":"falsche_groesse_beantwortet","+12":"potenzgesetz_verwechselt","+128":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 potenz-gesetze-02 · Potenzgesetze · (3²)⁴ = 3ⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '039682a2-4201-4933-92cc-da1031fee485'::uuid, 'exercise', 'Potenzgesetze · (3²)⁴ = 3ⁿ', '(3²)⁴ = 3ⁿ

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"(3²)⁴ = 3ⁿ\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Potenz einer Potenz, Hochzahlen multiplizieren.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '039682a2-4201-4933-92cc-da1031fee485'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '039682a2-4201-4933-92cc-da1031fee485'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '039682a2-4201-4933-92cc-da1031fee485'::uuid,
  p_correct_answers => '["8","+8"]'::jsonb,
  p_solution        => 'Potenz einer Potenz: Hochzahlen multiplizieren.
(3²)⁴ = 3² · 3² · 3² · 3² = 3²·⁴ = 3⁸, also n = 8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahlen addiert statt multipliziert: 2 + 4 = 6.","socratic_question":"Wie oft steht 3² als Faktor in (3²)⁴?"},{"error":"Den Wert 3⁸ = 6561 angegeben statt der Hochzahl n.","socratic_question":"Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["+8"],"known_errors":{"6":"potenzgesetz_verwechselt","6561":"falsche_groesse_beantwortet","+6":"potenzgesetz_verwechselt","+6561":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 potenz-gesetze-03 · Potenzgesetze · (a⁴)³ : a⁵ = aⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd1e9b2a6-2dc9-4ac9-ae5b-5bf8b67ba570'::uuid, 'exercise', 'Potenzgesetze · (a⁴)³ : a⁵ = aⁿ', '(a⁴)³ : a⁵ = aⁿ   (a ≠ 0)

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"(a⁴)³ : a⁵ = aⁿ   (a ≠ 0)\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Potenzgesetze nacheinander (Potenz einer Potenz, dann Quotient).","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd1e9b2a6-2dc9-4ac9-ae5b-5bf8b67ba570'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd1e9b2a6-2dc9-4ac9-ae5b-5bf8b67ba570'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd1e9b2a6-2dc9-4ac9-ae5b-5bf8b67ba570'::uuid,
  p_correct_answers => '["7","+7"]'::jsonb,
  p_solution        => '(a⁴)³ = a⁴·³ = a¹².
a¹² : a⁵ = a¹²⁻⁵ = a⁷, also n = 7.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei der Potenz einer Potenz die Hochzahlen addiert: a⁷ : a⁵ = a².","socratic_question":"Wie oft steht a⁴ als Faktor in (a⁴)³?"},{"error":"Beim Teilen die Hochzahlen addiert wie beim Malnehmen: a¹²⁺⁵.","socratic_question":"Werden beim Teilen gleicher Basen die Hochzahlen addiert oder subtrahiert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7"],"known_errors":{"2":"potenzgesetz_verwechselt","17":"potenzgesetz_verwechselt","+2":"potenzgesetz_verwechselt","+17":"potenzgesetz_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 potenz-gesetze-04 · Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '361f1762-0b48-473e-9883-815ab81f90fc'::uuid, 'exercise', 'Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ', '2⁵ · 5⁵ = 10ⁿ

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"2⁵ · 5⁵ = 10ⁿ\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: gleiche Hochzahl bei verschiedenen Basen erkennen und die Basen multiplizieren.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '361f1762-0b48-473e-9883-815ab81f90fc'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '361f1762-0b48-473e-9883-815ab81f90fc'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '361f1762-0b48-473e-9883-815ab81f90fc'::uuid,
  p_correct_answers => '["5","+5"]'::jsonb,
  p_solution        => 'Gleiche Hochzahl: die Basen multiplizieren.
2⁵ · 5⁵ = (2 · 5)⁵ = 10⁵, also n = 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahlen addiert, obwohl die Basen verschieden sind: 10¹⁰.","socratic_question":"Darfst du Hochzahlen addieren, wenn die Basen 2 und 5 verschieden sind?"},{"error":"Den Wert 10⁵ = 100 000 angegeben statt der Hochzahl n.","socratic_question":"Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5"],"known_errors":{"10":"potenzgesetz_verwechselt","100000":"falsche_groesse_beantwortet","+10":"potenzgesetz_verwechselt","+100000":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 potenz-gesetze-05 · Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1d743a81-124c-42c5-9235-163c2c4c5309'::uuid, 'exercise', 'Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang', 'Eine Zellkultur verdoppelt ihre Zellzahl jede Stunde. Zu Beginn sind es 2⁵ Zellen.

Wie viele Zellen sind es nach 3 Stunden? Gib die Anzahl exakt als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Eine Zellkultur verdoppelt ihre Zellzahl jede Stunde. Zu Beginn sind es 2⁵ Zellen.\n\nWie viele Zellen sind es nach 3 Stunden? Gib die Anzahl exakt als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, 1, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Verdoppeln als Multiplikation mit 2³ erkennen, dann den Wert berechnen.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt, mal_exponent, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1d743a81-124c-42c5-9235-163c2c4c5309'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1d743a81-124c-42c5-9235-163c2c4c5309'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1d743a81-124c-42c5-9235-163c2c4c5309'::uuid,
  p_correct_answers => '["256","+256"]'::jsonb,
  p_solution        => 'Drei Verdopplungen: mal 2 · 2 · 2 = 2³.
2⁵ · 2³ = 2⁸ = 256 Zellen.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahlen multipliziert: 2¹⁵ = 32 768.","socratic_question":"Wie viele Zweien stehen in 2⁵ · 2³, wenn du alles ausschreibst?"},{"error":"Die Potenz 2⁸ als 2 · 8 = 16 gerechnet.","socratic_question":"Was bedeutet die Hochzahl 8 bei 2⁸?"},{"error":"Nur die Hochzahl 8 angegeben statt der Zellzahl.","socratic_question":"Gefragt ist die Anzahl der Zellen – ist das 8?"}]'::jsonb,
  p_acceptance      => '{"canonical":"256","equivalents":["+256"],"known_errors":{"8":"falsche_groesse_beantwortet","16":"mal_exponent","32768":"potenzgesetz_verwechselt","+32768":"potenzgesetz_verwechselt","+16":"mal_exponent","+8":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 potenz-gesetze-06 · Potenzgesetze · großer Würfel in kleine Würfel zerlegt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9daaeffc-8019-4a0e-a150-7f77026abc8e'::uuid, 'exercise', 'Potenzgesetze · großer Würfel in kleine Würfel zerlegt', 'Ein großer Würfel hat die Kantenlänge 16 cm. Er wird vollständig in kleine Würfel mit der Kantenlänge 2 cm zerlegt.

Die Anzahl der kleinen Würfel lässt sich als 2ⁿ schreiben. Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Ein großer Würfel hat die Kantenlänge 16 cm. Er wird vollständig in kleine Würfel mit der Kantenlänge 2 cm zerlegt.\n\nDie Anzahl der kleinen Würfel lässt sich als 2ⁿ schreiben. Bestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_gesetze',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, null, false, 2, 'draft', 'edvance_k9_potenz', 'potenz-gesetze-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Anzahl als Quotient zweier Würfelvolumen modellieren und mit Potenzgesetzen als Zweierpotenz schreiben.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, potenzgesetz_verwechselt, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9daaeffc-8019-4a0e-a150-7f77026abc8e'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9daaeffc-8019-4a0e-a150-7f77026abc8e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9daaeffc-8019-4a0e-a150-7f77026abc8e'::uuid,
  p_correct_answers => '["9","+9"]'::jsonb,
  p_solution        => 'Volumen groß: 16³ cm³ = (2⁴)³ cm³ = 2¹² cm³.
Volumen klein: 2³ cm³.
Anzahl: 2¹² : 2³ = 2⁹ = 512, also n = 9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Würfel entlang einer Kante gezählt: 16 : 2 = 8 = 2³.","socratic_question":"Wie viele kleine Würfel passen in eine Ebene, wie viele Ebenen gibt es?"},{"error":"Die Hochzahlen geteilt statt subtrahiert: 2¹² : 2³ als 2⁴.","socratic_question":"Werden beim Teilen gleicher Basen die Hochzahlen geteilt oder subtrahiert?"},{"error":"Die Anzahl 512 angegeben statt der Hochzahl n.","socratic_question":"Wird nach der Anzahl oder nach der Hochzahl n gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["+9"],"known_errors":{"3":"linearer_faktor","4":"potenzgesetz_verwechselt","512":"falsche_groesse_beantwortet","+3":"linearer_faktor","+4":"potenzgesetz_verwechselt","+512":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 potenz-negativ-01 · Negative Hochzahl · 2⁻³
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '46f1792e-a330-4665-ba1b-90f442e0db25'::uuid, 'exercise', 'Negative Hochzahl · 2⁻³', 'Berechne 2⁻³. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Berechne 2⁻³. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-negativ-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: negative Hochzahl als Kehrwert der Potenz.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '46f1792e-a330-4665-ba1b-90f442e0db25'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '46f1792e-a330-4665-ba1b-90f442e0db25'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '46f1792e-a330-4665-ba1b-90f442e0db25'::uuid,
  p_correct_answers => '["0,125","+0,125","0.125","+0.125","1/8","+1/8"]'::jsonb,
  p_solution        => '2⁻³ = 1/2³ = 1/8 = 0,125.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die negative Hochzahl als Minuszeichen gelesen: −2³ = −8.","socratic_question":"Ist 2⁻³ ein Kehrwert oder eine negative Zahl?"},{"error":"Die Potenz als 2 · (−3) = −6 gerechnet.","socratic_question":"Was bedeutet die Hochzahl bei einer Potenz – malnehmen mit 3 oder 3-mal malnehmen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,125","equivalents":["+0,125","0.125","+0.125","1/8","+1/8"],"known_errors":{"-8":"negativer_exponent_negativ","−8":"negativer_exponent_negativ","- 8":"negativer_exponent_negativ","-6":"mal_exponent","−6":"mal_exponent","- 6":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 potenz-negativ-02 · Negative Hochzahl · 10⁻²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3b3119d4-20b2-44b5-b874-12863dbd8c0b'::uuid, 'exercise', 'Negative Hochzahl · 10⁻²', 'Berechne 10⁻². Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Berechne 10⁻². Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k9_potenz', 'potenz-negativ-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Zehnerpotenz mit negativer Hochzahl als Dezimalzahl.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent, faktor_zehn_daneben).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3b3119d4-20b2-44b5-b874-12863dbd8c0b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3b3119d4-20b2-44b5-b874-12863dbd8c0b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3b3119d4-20b2-44b5-b874-12863dbd8c0b'::uuid,
  p_correct_answers => '["0,01","+0,01","0.01","+0.01","1/100","+1/100"]'::jsonb,
  p_solution        => '10⁻² = 1/10² = 1/100 = 0,01.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die negative Hochzahl als Minuszeichen gelesen: −10² = −100.","socratic_question":"Ist 10⁻² kleiner als null oder kleiner als eins?"},{"error":"Die Potenz als 10 · (−2) = −20 gerechnet.","socratic_question":"Was bedeutet die Hochzahl bei einer Potenz?"},{"error":"Das Komma nur um eine Stelle verschoben: 0,1.","socratic_question":"Durch welche Zahl teilst du bei 1/10²?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,01","equivalents":["+0,01","0.01","+0.01","1/100","+1/100"],"known_errors":{"-100":"negativer_exponent_negativ","−100":"negativer_exponent_negativ","- 100":"negativer_exponent_negativ","-20":"mal_exponent","−20":"mal_exponent","- 20":"mal_exponent","0,1":"faktor_zehn_daneben","+0,1":"faktor_zehn_daneben","0.1":"faktor_zehn_daneben","+0.1":"faktor_zehn_daneben","1/10":"faktor_zehn_daneben","+1/10":"faktor_zehn_daneben"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 potenz-negativ-03 · Negative Hochzahl · 4⁻¹ · 4³
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f05fb05f-c11b-4b9f-9a79-b03e0aeec898'::uuid, 'exercise', 'Negative Hochzahl · 4⁻¹ · 4³', 'Berechne 4⁻¹ · 4³. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Berechne 4⁻¹ · 4³. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-negativ-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Produktgesetz mit einer negativen Hochzahl.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f05fb05f-c11b-4b9f-9a79-b03e0aeec898'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f05fb05f-c11b-4b9f-9a79-b03e0aeec898'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f05fb05f-c11b-4b9f-9a79-b03e0aeec898'::uuid,
  p_correct_answers => '["16","+16"]'::jsonb,
  p_solution        => 'Gleiche Basis: Hochzahlen addieren.
4⁻¹ · 4³ = 4⁻¹⁺³ = 4² = 16.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"4⁻¹ als −4 gelesen: (−4) · 64 = −256.","socratic_question":"Ist 4⁻¹ gleich −4 oder gleich 1/4?"},{"error":"Die Hochzahlen multipliziert: 4⁻³ = 1/64.","socratic_question":"Werden beim Malnehmen gleicher Basen die Hochzahlen multipliziert oder addiert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"16","equivalents":["+16"],"known_errors":{"-256":"negativer_exponent_negativ","−256":"negativer_exponent_negativ","- 256":"negativer_exponent_negativ","0,015625":"potenzgesetz_verwechselt","+0,015625":"potenzgesetz_verwechselt","0.015625":"potenzgesetz_verwechselt","+0.015625":"potenzgesetz_verwechselt","1/64":"potenzgesetz_verwechselt","+1/64":"potenzgesetz_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 potenz-negativ-04 · Negative Hochzahl · (1/2)⁻² + 5⁰
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd4c57c1c-bfb2-455c-bc85-7149ca24c1cb'::uuid, 'exercise', 'Negative Hochzahl · (1/2)⁻² + 5⁰', 'Berechne (1/2)⁻² + 5⁰. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Berechne (1/2)⁻² + 5⁰. Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-negativ-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Bruch mit negativer Hochzahl und Hochzahl null in einem Term.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd4c57c1c-bfb2-455c-bc85-7149ca24c1cb'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd4c57c1c-bfb2-455c-bc85-7149ca24c1cb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd4c57c1c-bfb2-455c-bc85-7149ca24c1cb'::uuid,
  p_correct_answers => '["5","+5"]'::jsonb,
  p_solution        => '(1/2)⁻² = 2² = 4 (Kehrwert, dann quadrieren).
5⁰ = 1.
4 + 1 = 5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"(1/2)⁻² als −(1/2)² = −1/4 gelesen: −1/4 + 1 = 3/4.","socratic_question":"Wird bei einer negativen Hochzahl das Ergebnis negativ oder der Kehrwert gebildet?"},{"error":"5⁰ als 5 · 0 = 0 gerechnet: 4 + 0 = 4.","socratic_question":"Welchen Wert hat jede Zahl (außer 0) hoch null?"},{"error":"Beide Potenzen als Produkte gerechnet: (1/2) · (−2) + 5 · 0 = −1.","socratic_question":"Was bedeutet die Hochzahl bei einer Potenz?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5"],"known_errors":{"4":"mal_exponent","0,75":"negativer_exponent_negativ","+0,75":"negativer_exponent_negativ","0.75":"negativer_exponent_negativ","+0.75":"negativer_exponent_negativ","3/4":"negativer_exponent_negativ","+3/4":"negativer_exponent_negativ","+4":"mal_exponent","-1":"mal_exponent","−1":"mal_exponent","- 1":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 potenz-negativ-05 · Negative Hochzahl · Halbierung alle 4 Stunden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '03c74739-8440-4d6d-9c7c-95ebdf5a163c'::uuid, 'exercise', 'Negative Hochzahl · Halbierung alle 4 Stunden', 'Die Menge eines Stoffes halbiert sich alle 4 Stunden. Nach n Halbierungen ist noch der Anteil 2⁻ⁿ der Anfangsmenge vorhanden.

Welcher Anteil der Anfangsmenge ist nach 20 Stunden noch vorhanden? Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Die Menge eines Stoffes halbiert sich alle 4 Stunden. Nach n Halbierungen ist noch der Anteil 2⁻ⁿ der Anfangsmenge vorhanden.\n\nWelcher Anteil der Anfangsmenge ist nach 20 Stunden noch vorhanden? Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-negativ-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Anzahl der Halbierungen bestimmen, dann 2⁻ⁿ berechnen.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (negativer_exponent_negativ, mal_exponent).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '03c74739-8440-4d6d-9c7c-95ebdf5a163c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '03c74739-8440-4d6d-9c7c-95ebdf5a163c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '03c74739-8440-4d6d-9c7c-95ebdf5a163c'::uuid,
  p_correct_answers => '["0,03125","+0,03125","0.03125","+0.03125","1/32","+1/32"]'::jsonb,
  p_solution        => '20 Stunden : 4 Stunden = 5 Halbierungen.
2⁻⁵ = 1/2⁵ = 1/32 = 0,03125.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die negative Hochzahl als Minuszeichen gelesen: −2⁵ = −32.","socratic_question":"Kann ein Anteil, der noch vorhanden ist, negativ sein?"},{"error":"2⁵ als 2 · 5 = 10 gerechnet: 1/10.","socratic_question":"Wie oft wird bei 2⁵ mit 2 malgenommen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,03125","equivalents":["+0,03125","0.03125","+0.03125","1/32","+1/32"],"known_errors":{"-32":"negativer_exponent_negativ","−32":"negativer_exponent_negativ","- 32":"negativer_exponent_negativ","0,1":"mal_exponent","+0,1":"mal_exponent","0.1":"mal_exponent","+0.1":"mal_exponent","1/10":"mal_exponent","+1/10":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 potenz-negativ-06 · Negative Hochzahl · Faktor zwischen 2³ und 2⁻²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2c76b7c8-5c80-43e6-95c9-0f06a7d8161e'::uuid, 'exercise', 'Negative Hochzahl · Faktor zwischen 2³ und 2⁻²', 'Um welchen Faktor ist 2³ größer als 2⁻²?

Gib den Faktor exakt als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Um welchen Faktor ist 2³ größer als 2⁻²?\n\nGib den Faktor exakt als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_negativ',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  90, null, false, 1, 'draft', 'edvance_k9_potenz', 'potenz-negativ-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: den Faktor als Quotient erkennen und mit negativer Hochzahl rechnen.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (potenzgesetz_verwechselt, negativer_exponent_negativ, falsche_groesse_beantwortet).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2c76b7c8-5c80-43e6-95c9-0f06a7d8161e'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2c76b7c8-5c80-43e6-95c9-0f06a7d8161e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2c76b7c8-5c80-43e6-95c9-0f06a7d8161e'::uuid,
  p_correct_answers => '["32","+32"]'::jsonb,
  p_solution        => 'Faktor = 2³ : 2⁻² = 2³⁻⁽⁻²⁾ = 2⁵ = 32.
Probe: 2⁻² = 1/4, und 1/4 · 32 = 8 = 2³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Hochzahlen addiert statt subtrahiert: 2³⁺⁽⁻²⁾ = 2.","socratic_question":"Werden beim Teilen gleicher Basen die Hochzahlen addiert oder subtrahiert?"},{"error":"2⁻² als −4 gelesen: 8 : (−4) = −2.","socratic_question":"Ist 2⁻² eine negative Zahl oder ein Bruch?"},{"error":"Den Unterschied 8 − 1/4 berechnet statt des Faktors.","socratic_question":"Fragt „um welchen Faktor\" nach einer Differenz oder nach einem Quotienten?"}]'::jsonb,
  p_acceptance      => '{"canonical":"32","equivalents":["+32"],"known_errors":{"2":"potenzgesetz_verwechselt","+2":"potenzgesetz_verwechselt","-2":"negativer_exponent_negativ","−2":"negativer_exponent_negativ","- 2":"negativer_exponent_negativ","7,75":"falsche_groesse_beantwortet","+7,75":"falsche_groesse_beantwortet","7.75":"falsche_groesse_beantwortet","+7.75":"falsche_groesse_beantwortet","31/4":"falsche_groesse_beantwortet","+31/4":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 potenz-zehner-01 · Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fad44de2-b0f5-4aa8-9515-abc44cd5ab7e'::uuid, 'exercise', 'Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ', '3 200 000 = 3,2 · 10ⁿ

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"3 200 000 = 3,2 · 10ⁿ\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-zehner-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: große Zahl in wissenschaftlicher Schreibweise, Kommaverschiebung zählen.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fad44de2-b0f5-4aa8-9515-abc44cd5ab7e'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fad44de2-b0f5-4aa8-9515-abc44cd5ab7e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fad44de2-b0f5-4aa8-9515-abc44cd5ab7e'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => 'Das Komma wandert von 3 200 000,0 sechs Stellen nach links bis 3,2.
Also 3 200 000 = 3,2 · 10⁶, n = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei einer großen Zahl eine negative Hochzahl angegeben.","socratic_question":"Ist 3 200 000 größer oder kleiner als 1 – welches Vorzeichen braucht n dann?"},{"error":"Alle sieben Ziffern gezählt statt der Stellen, um die das Komma wandert.","socratic_question":"Um wie viele Stellen wandert das Komma von 3 200 000 bis 3,2?"},{"error":"Eine Stelle zu wenig gezählt: 3,2 · 10⁵ = 320 000.","socratic_question":"Wie groß ist 3,2 · 10⁵ – stimmt das mit 3 200 000 überein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"5":"faktor_zehn_daneben","7":"faktor_zehn_daneben","-6":"zehnerexponent_vorzeichen","−6":"zehnerexponent_vorzeichen","- 6":"zehnerexponent_vorzeichen","+7":"faktor_zehn_daneben","+5":"faktor_zehn_daneben"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 potenz-zehner-02 · Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '52be6dbe-9275-4b83-9ff1-b369e1e1168b'::uuid, 'exercise', 'Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ', '0,00045 = 4,5 · 10ⁿ

Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"0,00045 = 4,5 · 10ⁿ\n\nBestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-zehner-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: kleine Zahl in wissenschaftlicher Schreibweise, negative Hochzahl.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '52be6dbe-9275-4b83-9ff1-b369e1e1168b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '52be6dbe-9275-4b83-9ff1-b369e1e1168b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '52be6dbe-9275-4b83-9ff1-b369e1e1168b'::uuid,
  p_correct_answers => '["-4","−4","- 4"]'::jsonb,
  p_solution        => 'Das Komma wandert von 0,00045 vier Stellen nach rechts bis 4,5.
Die Zahl ist kleiner als 1, die Hochzahl also negativ: 0,00045 = 4,5 · 10⁻⁴, n = -4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei einer Zahl kleiner als 1 eine positive Hochzahl angegeben.","socratic_question":"Ist 4,5 · 10⁴ eine große oder eine kleine Zahl?"},{"error":"Eine Stelle zu viel gezählt: 4,5 · 10⁻⁵ = 0,000045.","socratic_question":"Wie viele Nullen stehen nach dem Komma vor der 4?"},{"error":"Nur die Nullen nach dem Komma gezählt: 4,5 · 10⁻³ = 0,0045.","socratic_question":"Um wie viele Stellen wandert das Komma, bis es hinter der 4 steht?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-4","equivalents":["−4","- 4"],"known_errors":{"4":"zehnerexponent_vorzeichen","+4":"zehnerexponent_vorzeichen","-5":"faktor_zehn_daneben","−5":"faktor_zehn_daneben","- 5":"faktor_zehn_daneben","-3":"faktor_zehn_daneben","−3":"faktor_zehn_daneben","- 3":"faktor_zehn_daneben"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 potenz-zehner-03 · Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'efac8563-dcac-4e79-9092-21d534c29667'::uuid, 'exercise', 'Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl', 'Schreibe 7,2 · 10⁻³ als Dezimalzahl. Gib die Zahl exakt an.',
  '{"kind":"short_input","prompt":"Schreibe 7,2 · 10⁻³ als Dezimalzahl. Gib die Zahl exakt an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_potenz', 'potenz-zehner-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung, aus der wissenschaftlichen Schreibweise die Dezimalzahl bilden.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben, negativer_exponent_negativ).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'efac8563-dcac-4e79-9092-21d534c29667'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'efac8563-dcac-4e79-9092-21d534c29667'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'efac8563-dcac-4e79-9092-21d534c29667'::uuid,
  p_correct_answers => '["0,0072","+0,0072","0.0072","+0.0072"]'::jsonb,
  p_solution        => '10⁻³ = 0,001: das Komma wandert drei Stellen nach links.
7,2 · 10⁻³ = 0,0072.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Komma nach rechts verschoben: 7 200.","socratic_question":"Macht eine negative Hochzahl die Zahl größer oder kleiner?"},{"error":"Das Komma nur zwei Stellen verschoben: 0,072.","socratic_question":"Wie viele Stellen muss das Komma bei 10⁻³ wandern?"},{"error":"Das Komma vier Stellen verschoben: 0,00072.","socratic_question":"Wie viele Nullen hat 0,001 nach dem Komma, bevor die 1 kommt?"},{"error":"10⁻³ als −1 000 gelesen: −7 200.","socratic_question":"Ist 10⁻³ eine negative Zahl oder ein Tausendstel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,0072","equivalents":["+0,0072","0.0072","+0.0072"],"known_errors":{"7200":"zehnerexponent_vorzeichen","+7200":"zehnerexponent_vorzeichen","0,072":"faktor_zehn_daneben","+0,072":"faktor_zehn_daneben","0.072":"faktor_zehn_daneben","+0.072":"faktor_zehn_daneben","0,00072":"faktor_zehn_daneben","+0,00072":"faktor_zehn_daneben","0.00072":"faktor_zehn_daneben","+0.00072":"faktor_zehn_daneben","-7200":"negativer_exponent_negativ","−7200":"negativer_exponent_negativ","- 7200":"negativer_exponent_negativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 potenz-zehner-04 · Zehnerpotenz · 4,05 · 10⁵ als Zahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'aeb4bcf2-43d5-4b95-80ec-b0ab2cd08396'::uuid, 'exercise', 'Zehnerpotenz · 4,05 · 10⁵ als Zahl', 'Schreibe 4,05 · 10⁵ als Zahl ohne Zehnerpotenz. Gib die Zahl exakt an.',
  '{"kind":"short_input","prompt":"Schreibe 4,05 · 10⁵ als Zahl ohne Zehnerpotenz. Gib die Zahl exakt an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_potenz', 'potenz-zehner-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung mit Null im Vorfaktor, Stellen auffüllen.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben, mal_exponent).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'aeb4bcf2-43d5-4b95-80ec-b0ab2cd08396'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'aeb4bcf2-43d5-4b95-80ec-b0ab2cd08396'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'aeb4bcf2-43d5-4b95-80ec-b0ab2cd08396'::uuid,
  p_correct_answers => '["405000","+405000"]'::jsonb,
  p_solution        => 'Das Komma wandert fünf Stellen nach rechts; fehlende Stellen werden mit Nullen gefüllt.
4,05 · 10⁵ = 405 000, eingegeben als 405000.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Komma nach links verschoben: 0,0000405.","socratic_question":"Macht eine positive Hochzahl die Zahl größer oder kleiner?"},{"error":"Fünf Ziffern insgesamt geschrieben statt das Komma fünf Stellen zu verschieben: 40 500.","socratic_question":"Um wie viele Stellen wandert das Komma, und wo steht es danach?"},{"error":"Das Komma sechs statt fünf Stellen verschoben: 4 050 000.","socratic_question":"Wie viele Nullen hat 10⁵, und um wie viele Stellen wandert das Komma?"},{"error":"10⁵ als 10 · 5 = 50 gerechnet: 202,5.","socratic_question":"Was bedeutet die Hochzahl 5 bei 10⁵?"}]'::jsonb,
  p_acceptance      => '{"canonical":"405000","equivalents":["+405000"],"known_errors":{"40500":"faktor_zehn_daneben","4050000":"faktor_zehn_daneben","0,0000405":"zehnerexponent_vorzeichen","+0,0000405":"zehnerexponent_vorzeichen","0.0000405":"zehnerexponent_vorzeichen","+0.0000405":"zehnerexponent_vorzeichen","+40500":"faktor_zehn_daneben","+4050000":"faktor_zehn_daneben","202,5":"mal_exponent","+202,5":"mal_exponent","202.5":"mal_exponent","+202.5":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 potenz-zehner-05 · Zehnerpotenz · Durchmesser eines roten Blutkörperchens
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0723e9b4-0faf-4150-95b0-1065cb950a04'::uuid, 'exercise', 'Zehnerpotenz · Durchmesser eines roten Blutkörperchens', 'Ein rotes Blutkörperchen hat einen Durchmesser von etwa 0,0000075 m.

In wissenschaftlicher Schreibweise ist das 7,5 · 10ⁿ m. Bestimme n. Gib n als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Ein rotes Blutkörperchen hat einen Durchmesser von etwa 0,0000075 m.\n\nIn wissenschaftlicher Schreibweise ist das 7,5 · 10ⁿ m. Bestimme n. Gib n als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-zehner-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: sehr kleine Länge in wissenschaftlicher Schreibweise angeben.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0723e9b4-0faf-4150-95b0-1065cb950a04'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0723e9b4-0faf-4150-95b0-1065cb950a04'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0723e9b4-0faf-4150-95b0-1065cb950a04'::uuid,
  p_correct_answers => '["-6","−6","- 6"]'::jsonb,
  p_solution        => 'Das Komma wandert von 0,0000075 sechs Stellen nach rechts bis 7,5.
Die Zahl ist kleiner als 1: 0,0000075 m = 7,5 · 10⁻⁶ m, n = -6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei einer winzigen Länge eine positive Hochzahl angegeben.","socratic_question":"Wäre 7,5 · 10⁶ m eine winzige oder eine riesige Länge?"},{"error":"Eine Stelle zu viel gezählt: 7,5 · 10⁻⁷ m.","socratic_question":"Um wie viele Stellen wandert das Komma, bis es hinter der 7 steht?"},{"error":"Nur die Nullen nach dem Komma gezählt: 7,5 · 10⁻⁵ m.","socratic_question":"Muss das Komma bis hinter die 7 oder nur bis vor die 7 wandern?"}]'::jsonb,
  p_acceptance      => '{"canonical":"-6","equivalents":["−6","- 6"],"known_errors":{"6":"zehnerexponent_vorzeichen","+6":"zehnerexponent_vorzeichen","-7":"faktor_zehn_daneben","−7":"faktor_zehn_daneben","- 7":"faktor_zehn_daneben","-5":"faktor_zehn_daneben","−5":"faktor_zehn_daneben","- 5":"faktor_zehn_daneben"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 potenz-zehner-06 · Zehnerpotenz · Viren auf der Länge eines Sandkorns
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '446f3dc6-5f31-4c1a-a9e9-b9e0fd818f52'::uuid, 'exercise', 'Zehnerpotenz · Viren auf der Länge eines Sandkorns', 'Ein Virus ist etwa 1 · 10⁻⁷ m lang, ein Sandkorn etwa 1 · 10⁻³ m.

Wie viele solcher Viren passen nebeneinander auf die Länge des Sandkorns? Gib die Anzahl exakt als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Ein Virus ist etwa 1 · 10⁻⁷ m lang, ein Sandkorn etwa 1 · 10⁻³ m.\n\nWie viele solcher Viren passen nebeneinander auf die Länge des Sandkorns? Gib die Anzahl exakt als ganze Zahl an."}'::jsonb, 'NUMERIC', 'zahl_potenz_zehner',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-zehner-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Anzahl als Quotient zweier Längen in Zehnerpotenzen bilden und als Zahl angeben.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zehnerexponent_vorzeichen, faktor_zehn_daneben).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '446f3dc6-5f31-4c1a-a9e9-b9e0fd818f52'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '446f3dc6-5f31-4c1a-a9e9-b9e0fd818f52'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '446f3dc6-5f31-4c1a-a9e9-b9e0fd818f52'::uuid,
  p_correct_answers => '["10000","+10000"]'::jsonb,
  p_solution        => 'Anzahl = 10⁻³ m : 10⁻⁷ m = 10⁻³⁻⁽⁻⁷⁾ = 10⁴ = 10000.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Quotienten umgedreht: 10⁻⁷ : 10⁻³ = 10⁻⁴ = 0,0001.","socratic_question":"Kann eine Anzahl von Viren kleiner als 1 sein?"},{"error":"Eine Zehnerpotenz zu wenig: 1 000.","socratic_question":"Wie viele Zehnerpotenzen liegen zwischen 10⁻⁷ und 10⁻³?"},{"error":"Eine Zehnerpotenz zu viel: 100 000.","socratic_question":"Wie viele Zehnerpotenzen liegen zwischen 10⁻⁷ und 10⁻³?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10000","equivalents":["+10000"],"known_errors":{"1000":"faktor_zehn_daneben","100000":"faktor_zehn_daneben","0,0001":"zehnerexponent_vorzeichen","+0,0001":"zehnerexponent_vorzeichen","0.0001":"zehnerexponent_vorzeichen","+0.0001":"zehnerexponent_vorzeichen","+1000":"faktor_zehn_daneben","+100000":"faktor_zehn_daneben"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 potenz-rechnen-01 · Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a35d5827-c2d4-48a9-87b8-6c69c1078abe'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶)', 'Berechne (3 · 10⁴) · (2 · 10⁻⁶).

Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Vorfaktoren multiplizieren, Hochzahlen addieren, Ergebnis schon normiert.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (plus_statt_mal, potenzgesetz_verwechselt, zehnerexponent_vorzeichen).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a35d5827-c2d4-48a9-87b8-6c69c1078abe'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a35d5827-c2d4-48a9-87b8-6c69c1078abe'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a35d5827-c2d4-48a9-87b8-6c69c1078abe'::uuid,
  p_correct_answers => '{"1":["6","+6"],"2":["-2","−2","- 2"]}'::jsonb,
  p_solution        => 'Vorfaktoren: 3 · 2 = 6.
Zehnerpotenzen: 10⁴ · 10⁻⁶ = 10⁴⁺⁽⁻⁶⁾ = 10⁻².
Ergebnis: 6 · 10⁻², also a = 6 und n = -2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Vorfaktoren addiert statt multipliziert: 3 + 2 = 5.","socratic_question":"Werden die Vorfaktoren addiert oder multipliziert?"},{"error":"Die Hochzahlen multipliziert: 4 · (−6) = −24.","socratic_question":"Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?"},{"error":"Positive Hochzahl angegeben, obwohl das Ergebnis 0,06 kleiner als 1 ist.","socratic_question":"Ist das Ergebnis größer oder kleiner als 1?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"6","equivalents":["+6"],"known_errors":{"5":"plus_statt_mal","+5":"plus_statt_mal"}},"2":{"canonical":"-2","equivalents":["−2","- 2"],"known_errors":{"2":"zehnerexponent_vorzeichen","-24":"potenzgesetz_verwechselt","−24":"potenzgesetz_verwechselt","- 24":"potenzgesetz_verwechselt","+2":"zehnerexponent_vorzeichen"}}}'::jsonb);
  end if;
end
$loesung$;

-- #20 potenz-rechnen-02 · Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3510e4f2-f006-4d20-bdf8-8d8520ed09e1'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²)', 'Berechne (8 · 10⁶) : (2 · 10²).

Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"I","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Vorfaktoren dividieren, Hochzahlen subtrahieren, Ergebnis schon normiert.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (multipliziert_statt_dividiert, potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3510e4f2-f006-4d20-bdf8-8d8520ed09e1'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3510e4f2-f006-4d20-bdf8-8d8520ed09e1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3510e4f2-f006-4d20-bdf8-8d8520ed09e1'::uuid,
  p_correct_answers => '{"1":["4","+4"],"2":["4","+4"]}'::jsonb,
  p_solution        => 'Vorfaktoren: 8 : 2 = 4.
Zehnerpotenzen: 10⁶ : 10² = 10⁶⁻² = 10⁴.
Ergebnis: 4 · 10⁴, also a = 4 und n = 4.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Vorfaktoren multipliziert statt geteilt: 8 · 2 = 16.","socratic_question":"Welche Rechenart steht zwischen den beiden Klammern?"},{"error":"Die Hochzahlen geteilt statt subtrahiert: 6 : 2 = 3.","socratic_question":"Werden beim Teilen von Zehnerpotenzen die Hochzahlen geteilt oder subtrahiert?"},{"error":"Die Hochzahlen addiert wie beim Malnehmen: 6 + 2 = 8.","socratic_question":"Werden beim Teilen von Zehnerpotenzen die Hochzahlen addiert oder subtrahiert?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4","equivalents":["+4"],"known_errors":{"16":"multipliziert_statt_dividiert","+16":"multipliziert_statt_dividiert"}},"2":{"canonical":"4","equivalents":["+4"],"known_errors":{"3":"potenzgesetz_verwechselt","8":"potenzgesetz_verwechselt","+3":"potenzgesetz_verwechselt","+8":"potenzgesetz_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #21 potenz-rechnen-03 · Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd6b3bddd-410d-42b8-b8cd-5139727b1ed8'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren', 'Berechne (5 · 10³) · (4 · 10⁵).

Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Produkt mit Vorfaktor über 10, Ergebnis muss normiert werden.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_zehn_daneben, potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd6b3bddd-410d-42b8-b8cd-5139727b1ed8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd6b3bddd-410d-42b8-b8cd-5139727b1ed8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd6b3bddd-410d-42b8-b8cd-5139727b1ed8'::uuid,
  p_correct_answers => '{"1":["2","+2"],"2":["9","+9"]}'::jsonb,
  p_solution        => 'Vorfaktoren: 5 · 4 = 20. Zehnerpotenzen: 10³ · 10⁵ = 10⁸.
20 · 10⁸ = 2 · 10¹ · 10⁸ = 2 · 10⁹.
Also a = 2 und n = 9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht normiert: 20 ist kein Vorfaktor zwischen 1 und 10.","socratic_question":"Liegt 20 zwischen 1 und 10?"},{"error":"Nicht normiert: 20 · 10⁸ ist richtig, aber nicht in der Form a · 10ⁿ mit a < 10.","socratic_question":"Wenn der Vorfaktor von 20 auf 2 schrumpft, was muss mit der Hochzahl passieren?"},{"error":"Die Hochzahlen multipliziert: 3 · 5 = 15.","socratic_question":"Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"2","equivalents":["+2"],"known_errors":{"20":"faktor_zehn_daneben","+20":"faktor_zehn_daneben"}},"2":{"canonical":"9","equivalents":["+9"],"known_errors":{"8":"faktor_zehn_daneben","15":"potenzgesetz_verwechselt","+8":"faktor_zehn_daneben","+15":"potenzgesetz_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #22 potenz-rechnen-04 · Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd7f1416b-ee9c-408c-8dd3-7e2bfc623a27'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren', 'Berechne (3 · 10⁵) : (6 · 10⁻²).

Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quotient mit negativer Hochzahl, Vorfaktor unter 1 muss normiert werden.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_zehn_daneben, multipliziert_statt_dividiert, potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd7f1416b-ee9c-408c-8dd3-7e2bfc623a27'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd7f1416b-ee9c-408c-8dd3-7e2bfc623a27'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd7f1416b-ee9c-408c-8dd3-7e2bfc623a27'::uuid,
  p_correct_answers => '{"1":["5","+5"],"2":["6","+6"]}'::jsonb,
  p_solution        => 'Vorfaktoren: 3 : 6 = 0,5. Zehnerpotenzen: 10⁵ : 10⁻² = 10⁵⁻⁽⁻²⁾ = 10⁷.
0,5 · 10⁷ = 5 · 10⁻¹ · 10⁷ = 5 · 10⁶.
Also a = 5 und n = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht normiert: 0,5 ist kein Vorfaktor zwischen 1 und 10.","socratic_question":"Liegt 0,5 zwischen 1 und 10?"},{"error":"Die Vorfaktoren multipliziert statt geteilt: 3 · 6 = 18.","socratic_question":"Welche Rechenart steht zwischen den beiden Klammern?"},{"error":"Nicht normiert: 0,5 · 10⁷ ist richtig, aber a muss mindestens 1 sein.","socratic_question":"Wenn der Vorfaktor von 0,5 auf 5 wächst, was muss mit der Hochzahl passieren?"},{"error":"Die Hochzahlen addiert statt subtrahiert: 10⁵⁺⁽⁻²⁾ = 10³.","socratic_question":"Was ergibt 5 − (−2)?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"5","equivalents":["+5"],"known_errors":{"18":"multipliziert_statt_dividiert","0,5":"faktor_zehn_daneben","+0,5":"faktor_zehn_daneben","0.5":"faktor_zehn_daneben","+0.5":"faktor_zehn_daneben","+18":"multipliziert_statt_dividiert"}},"2":{"canonical":"6","equivalents":["+6"],"known_errors":{"3":"potenzgesetz_verwechselt","7":"faktor_zehn_daneben","+7":"faktor_zehn_daneben","+3":"potenzgesetz_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #23 potenz-rechnen-05 · Wissenschaftliche Schreibweise · Lichtweg in einer Minute
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'bbe4791e-1ec3-485e-9b4c-bbab72c6506a'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · Lichtweg in einer Minute', 'Licht legt in einer Sekunde etwa 3 · 10⁸ m zurück.

Wie viele Meter legt es in einer Minute, also in 6 · 10¹ s, zurück? Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"II","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Strecke = Geschwindigkeit · Zeit in wissenschaftlicher Schreibweise, Ergebnis normieren.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_zehn_daneben, potenzgesetz_verwechselt).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'bbe4791e-1ec3-485e-9b4c-bbab72c6506a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'bbe4791e-1ec3-485e-9b4c-bbab72c6506a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'bbe4791e-1ec3-485e-9b4c-bbab72c6506a'::uuid,
  p_correct_answers => '{"1":["1,8","+1,8","1.8","+1.8"],"2":["10","+10"]}'::jsonb,
  p_solution        => 'Strecke = Geschwindigkeit · Zeit = (3 · 10⁸ m/s) · (6 · 10¹ s).
3 · 6 = 18 und 10⁸ · 10¹ = 10⁹: 18 · 10⁹ m = 1,8 · 10¹⁰ m.
Also a = 1,8 und n = 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht normiert: 18 ist kein Vorfaktor zwischen 1 und 10.","socratic_question":"Liegt 18 zwischen 1 und 10?"},{"error":"Nicht normiert: 18 · 10⁹ m ist richtig, aber a muss kleiner als 10 sein.","socratic_question":"Wenn der Vorfaktor von 18 auf 1,8 schrumpft, was muss mit der Hochzahl passieren?"},{"error":"Die Hochzahlen multipliziert: 8 · 1 = 8.","socratic_question":"Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"1,8","equivalents":["+1,8","1.8","+1.8"],"known_errors":{"18":"faktor_zehn_daneben","+18":"faktor_zehn_daneben"}},"2":{"canonical":"10","equivalents":["+10"],"known_errors":{"8":"potenzgesetz_verwechselt","9":"faktor_zehn_daneben","+9":"faktor_zehn_daneben","+8":"potenzgesetz_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #24 potenz-rechnen-06 · Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0a6f5de1-82ab-4f20-8f71-3fab440b2e95'::uuid, 'exercise', 'Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde', 'Die Sonne ist etwa 1,5 · 10¹¹ m von der Erde entfernt. Licht legt in einer Sekunde etwa 3 · 10⁸ m zurück.

Wie viele Sekunden braucht das Licht von der Sonne bis zur Erde? Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.',
  null, 'MULTI_PART', 'zahl_potenz_rechnen',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'arithmetik_algebra', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k9_potenz', 'potenz-rechnen-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Vorfaktor a","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Hochzahl n","unit":null,"afb":"III","competency_content":"arithmetik_algebra","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Zeit = Strecke : Geschwindigkeit selbst aufstellen, Quotient bilden und normieren.","charge":"k9-potenz"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-potenz"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).","charge":"k9-potenz"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.","charge":"k9-potenz"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).","charge":"k9-potenz"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-potenz"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-potenz"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-potenz"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-potenz"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-potenz"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (faktor_zehn_daneben, multipliziert_statt_dividiert).","charge":"k9-potenz"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-potenz"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0a6f5de1-82ab-4f20-8f71-3fab440b2e95'::uuid and t.status = 'draft' and t.source = 'edvance_k9_potenz')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0a6f5de1-82ab-4f20-8f71-3fab440b2e95'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0a6f5de1-82ab-4f20-8f71-3fab440b2e95'::uuid,
  p_correct_answers => '{"1":["5","+5"],"2":["2","+2"]}'::jsonb,
  p_solution        => 'Zeit = Strecke : Geschwindigkeit = (1,5 · 10¹¹ m) : (3 · 10⁸ m/s).
1,5 : 3 = 0,5 und 10¹¹ : 10⁸ = 10³: 0,5 · 10³ s = 5 · 10² s (500 s).
Also a = 5 und n = 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht normiert: 0,5 ist kein Vorfaktor zwischen 1 und 10.","socratic_question":"Liegt 0,5 zwischen 1 und 10?"},{"error":"Strecke mal Geschwindigkeit gerechnet: 1,5 · 3 = 4,5.","socratic_question":"Wie erhältst du aus Strecke und Geschwindigkeit die Zeit?"},{"error":"Nicht normiert: 0,5 · 10³ s ist richtig, aber a muss mindestens 1 sein.","socratic_question":"Wenn der Vorfaktor von 0,5 auf 5 wächst, was muss mit der Hochzahl passieren?"},{"error":"Strecke mal Geschwindigkeit gerechnet: 10¹¹ · 10⁸ = 10¹⁹.","socratic_question":"Wie erhältst du aus Strecke und Geschwindigkeit die Zeit?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"5","equivalents":["+5"],"known_errors":{"0,5":"faktor_zehn_daneben","+0,5":"faktor_zehn_daneben","0.5":"faktor_zehn_daneben","+0.5":"faktor_zehn_daneben","4,5":"multipliziert_statt_dividiert","+4,5":"multipliziert_statt_dividiert","4.5":"multipliziert_statt_dividiert","+4.5":"multipliziert_statt_dividiert"}},"2":{"canonical":"2","equivalents":["+2"],"known_errors":{"3":"faktor_zehn_daneben","19":"multipliziert_statt_dividiert","+3":"faktor_zehn_daneben","+19":"multipliziert_statt_dividiert"}}}'::jsonb);
  end if;
end
$loesung$;
