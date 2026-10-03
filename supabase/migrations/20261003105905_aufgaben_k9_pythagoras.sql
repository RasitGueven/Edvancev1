-- K9-Rest, Thema pythagoras — 30 Aufgaben: je sechs zu geo_pythagoras_hypotenuse, _kathete, _umkehrung, _abstand und _anwendung.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-pythagoras.json (Quelle: tools/k9-pythagoras-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105857_substrat_k9_pythagoras.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Boot, Feld, Drachen, Mast, Gartenhaus, Latten, Karte, Leiter). Drei Abstands-Aufgaben mit Abbildung (Koordinatensystem, Punkte ablesen), alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird; Werte exakt nachgerechnet (Wurzel auf 40 Stellen).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-pythagoras.csv. Pruefprotokoll: docs/prefill/k9-pythagoras-verifikation.md.
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
--   geo_pythagoras_hypotenuse: pyth-hypotenuse-03 = 1, pyth-hypotenuse-04 = 2. Rang 1 aus Profil {hypotenuse_verwechselt,mal_exponent,wurzel_gliedweise,wurzel_vergessen}, Rang 2 aus Profil {einheit_uebersprungen,wurzel_gliedweise,wurzel_vergessen} (1 neue Fehlbilder)
--   geo_pythagoras_kathete: pyth-kathete-03 = 1, pyth-kathete-04 = 2. Rang 1 aus Profil {hypotenuse_verwechselt,wurzel_gliedweise,wurzel_vergessen}, Rang 2 aus Profil {falsche_groesse_beantwortet,halbieren_vergessen,hypotenuse_verwechselt} (2 neue Fehlbilder)
--   geo_pythagoras_umkehrung: pyth-umkehrung-05 = 1, pyth-umkehrung-04 = 2. Rang 1 aus Profil {hypotenuse_verwechselt,wurzel_gliedweise,wurzel_vergessen}, Rang 2 aus Profil {falsche_groesse_beantwortet,wurzel_vergessen,zu_frueh_gerundet} (2 neue Fehlbilder)
--   geo_pythagoras_abstand: pyth-abstand-06 = 1, pyth-abstand-02 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,vorzeichen_ignoriert,wurzel_gliedweise,wurzel_vergessen}, Rang 2 aus Profil {hypotenuse_verwechselt,wurzel_gliedweise,wurzel_vergessen} (1 neue Fehlbilder)
--   geo_pythagoras_anwendung: pyth-anwendung-02 = 1, pyth-anwendung-04 = 2. Rang 1 aus Profil {hypotenuse_verwechselt,wurzel_gliedweise,wurzel_vergessen}, Rang 2 aus Profil {falsche_groesse_beantwortet,halbieren_vergessen,hypotenuse_verwechselt} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 pyth-hypotenuse-01 · Hypotenuse · Katheten 6 cm und 8 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4a99bc6f-8dfe-4657-8d4f-11456d874baa'::uuid, 'exercise', 'Hypotenuse · Katheten 6 cm und 8 cm', 'Ein rechtwinkliges Dreieck hat die Katheten a = 6 cm und b = 8 cm.

Wie lang ist die Hypotenuse c? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechtwinkliges Dreieck hat die Katheten a = 6 cm und b = 8 cm.\n\nWie lang ist die Hypotenuse c? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Satz des Pythagoras mit zwei gegebenen Katheten, Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4a99bc6f-8dfe-4657-8d4f-11456d874baa'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4a99bc6f-8dfe-4657-8d4f-11456d874baa'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4a99bc6f-8dfe-4657-8d4f-11456d874baa'::uuid,
  p_correct_answers => '["10","10 cm","10cm"]'::jsonb,
  p_solution        => 'c² = a² + b² = 6² + 8² = 36 + 64 = 100.
c = √100 = 10 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c² = 100 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon c ausgerechnet oder erst c²?"},{"error":"Die Wurzel Glied für Glied gezogen: √(6² + 8²) als 6 + 8.","socratic_question":"Ist √(36 + 64) dasselbe wie √36 + √64?"},{"error":"Die Quadrate subtrahiert, als wäre eine Kathete gesucht: √(64 − 36).","socratic_question":"Ist die Hypotenuse die längste oder eine kürzere Seite des Dreiecks?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["10 cm","10cm"],"known_errors":{"14":"wurzel_gliedweise","100":"wurzel_vergessen","100 cm":"wurzel_vergessen","100cm":"wurzel_vergessen","14 cm":"wurzel_gliedweise","14cm":"wurzel_gliedweise","5,29":"hypotenuse_verwechselt","5.29":"hypotenuse_verwechselt","5,29 cm":"hypotenuse_verwechselt","5,29cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 pyth-hypotenuse-02 · Hypotenuse · Katheten 5 cm und 7 cm, gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '75194d46-60d2-4d4a-b988-db2b3c5c1a65'::uuid, 'exercise', 'Hypotenuse · Katheten 5 cm und 7 cm, gerundet', 'Ein rechtwinkliges Dreieck hat die Katheten a = 5 cm und b = 7 cm.

Wie lang ist die Hypotenuse c? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein rechtwinkliges Dreieck hat die Katheten a = 5 cm und b = 7 cm.\n\nWie lang ist die Hypotenuse c? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Satz des Pythagoras, Wurzel aus einer Nicht-Quadratzahl runden.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '75194d46-60d2-4d4a-b988-db2b3c5c1a65'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '75194d46-60d2-4d4a-b988-db2b3c5c1a65'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '75194d46-60d2-4d4a-b988-db2b3c5c1a65'::uuid,
  p_correct_answers => '["8,60","8.60","8,6","8.6","8,60 cm","8,60cm","8,6 cm","8,6cm"]'::jsonb,
  p_solution        => 'c² = 5² + 7² = 25 + 49 = 74.
c = √74 ≈ 8,60 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c² = 74 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann die Hypotenuse länger sein als beide Katheten zusammen?"},{"error":"Die Wurzel Glied für Glied gezogen: c = 5 + 7.","socratic_question":"Ist √(25 + 49) dasselbe wie √25 + √49?"},{"error":"Die Quadrate subtrahiert: √(49 − 25).","socratic_question":"Muss die Hypotenuse länger oder kürzer als 7 cm sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8,60","equivalents":["8.60","8,6","8.6","8,60 cm","8,60cm","8,6 cm","8,6cm"],"known_errors":{"12":"wurzel_gliedweise","74":"wurzel_vergessen","74 cm":"wurzel_vergessen","74cm":"wurzel_vergessen","12 cm":"wurzel_gliedweise","12cm":"wurzel_gliedweise","4,90":"hypotenuse_verwechselt","4.90":"hypotenuse_verwechselt","4,9":"hypotenuse_verwechselt","4.9":"hypotenuse_verwechselt","4,90 cm":"hypotenuse_verwechselt","4,90cm":"hypotenuse_verwechselt","4,9 cm":"hypotenuse_verwechselt","4,9cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 pyth-hypotenuse-03 · Hypotenuse · Katheten 4,5 cm und 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ee07674f-0846-4f38-a0c7-247fd351b729'::uuid, 'exercise', 'Hypotenuse · Katheten 4,5 cm und 6 cm', 'Ein rechtwinkliges Dreieck hat die Katheten a = 4,5 cm und b = 6 cm.

Wie lang ist die Hypotenuse c? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechtwinkliges Dreieck hat die Katheten a = 4,5 cm und b = 6 cm.\n\nWie lang ist die Hypotenuse c? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat einer Dezimalzahl und Wurzel aus einer Dezimalzahl.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, mal_exponent, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ee07674f-0846-4f38-a0c7-247fd351b729'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ee07674f-0846-4f38-a0c7-247fd351b729'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ee07674f-0846-4f38-a0c7-247fd351b729'::uuid,
  p_correct_answers => '["7,5","7.5","7,5 cm","7,5cm"]'::jsonb,
  p_solution        => 'c² = 4,5² + 6² = 20,25 + 36 = 56,25.
c = √56,25 = 7,5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c² = 56,25 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Ist 56,25 schon die Länge oder erst ihr Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: c = 4,5 + 6.","socratic_question":"Ist √(20,25 + 36) dasselbe wie √20,25 + √36?"},{"error":"Quadrate als Verdopplung gerechnet: 4,5² als 2 · 4,5 und 6² als 2 · 6.","socratic_question":"Was bedeutet 4,5²: 4,5 · 2 oder 4,5 · 4,5?"},{"error":"Die Quadrate subtrahiert: √(36 − 20,25).","socratic_question":"Ist die Hypotenuse länger oder kürzer als die Katheten?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,5","equivalents":["7.5","7,5 cm","7,5cm"],"known_errors":{"56,25":"wurzel_vergessen","56.25":"wurzel_vergessen","56,25 cm":"wurzel_vergessen","56,25cm":"wurzel_vergessen","10,5":"wurzel_gliedweise","10.5":"wurzel_gliedweise","10,5 cm":"wurzel_gliedweise","10,5cm":"wurzel_gliedweise","4,58":"mal_exponent","4.58":"mal_exponent","4,58 cm":"mal_exponent","4,58cm":"mal_exponent","3,97":"hypotenuse_verwechselt","3.97":"hypotenuse_verwechselt","3,97 cm":"hypotenuse_verwechselt","3,97cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 pyth-hypotenuse-04 · Hypotenuse · Katheten 12 cm und 0,35 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5875fe3f-394d-4a2b-8977-bf825b5f9518'::uuid, 'exercise', 'Hypotenuse · Katheten 12 cm und 0,35 m', 'Ein rechtwinkliges Dreieck hat die Katheten a = 12 cm und b = 0,35 m.

Wie lang ist die Hypotenuse c in Zentimetern? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein rechtwinkliges Dreieck hat die Katheten a = 12 cm und b = 0,35 m.\n\nWie lang ist die Hypotenuse c in Zentimetern? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 2, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Einheiten angleichen, dann Satz des Pythagoras mit größeren Zahlen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5875fe3f-394d-4a2b-8977-bf825b5f9518'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5875fe3f-394d-4a2b-8977-bf825b5f9518'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5875fe3f-394d-4a2b-8977-bf825b5f9518'::uuid,
  p_correct_answers => '["37","37 cm","37cm"]'::jsonb,
  p_solution        => 'b = 0,35 m = 35 cm.
c² = 12² + 35² = 144 + 1225 = 1369.
c = √1369 = 37 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht umgerechnet: mit 12 und 0,35 gerechnet.","socratic_question":"Sind beide Katheten in derselben Einheit angegeben?"},{"error":"c² = 1369 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon c ausgerechnet oder erst c²?"},{"error":"Die Wurzel Glied für Glied gezogen: c = 12 + 35.","socratic_question":"Ist √(144 + 1225) dasselbe wie √144 + √1225?"}]'::jsonb,
  p_acceptance      => '{"canonical":"37","equivalents":["37 cm","37cm"],"known_errors":{"47":"wurzel_gliedweise","1369":"wurzel_vergessen","12,01":"einheit_uebersprungen","12.01":"einheit_uebersprungen","12,01 cm":"einheit_uebersprungen","12,01cm":"einheit_uebersprungen","1369 cm":"wurzel_vergessen","1369cm":"wurzel_vergessen","47 cm":"wurzel_gliedweise","47cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 pyth-hypotenuse-05 · Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e63c2e2e-396f-46f6-91d1-c34595a88dbc'::uuid, 'exercise', 'Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten', 'Ein Boot fährt vom Hafen aus 9 km genau nach Norden und danach 4 km genau nach Osten.

Wie weit ist das Boot jetzt in Luftlinie vom Hafen entfernt? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Boot fährt vom Hafen aus 9 km genau nach Norden und danach 4 km genau nach Osten.\n\nWie weit ist das Boot jetzt in Luftlinie vom Hafen entfernt? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'km', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Die Luftlinie muss als Hypotenuse eines rechtwinkligen Dreiecks erkannt werden.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e63c2e2e-396f-46f6-91d1-c34595a88dbc'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e63c2e2e-396f-46f6-91d1-c34595a88dbc'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e63c2e2e-396f-46f6-91d1-c34595a88dbc'::uuid,
  p_correct_answers => '["9,8","9.8","9,8 km","9,8km"]'::jsonb,
  p_solution        => 'Nord- und Ostrichtung stehen senkrecht aufeinander; die Luftlinie ist die Hypotenuse.
c² = 9² + 4² = 81 + 16 = 97.
c = √97 ≈ 9,8 km.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c² = 97 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann die Luftlinie länger sein als der gefahrene Weg?"},{"error":"Die gefahrenen Strecken addiert: 9 + 4.","socratic_question":"Ist die Luftlinie so lang wie der Umweg über beide Strecken?"},{"error":"Die Quadrate subtrahiert: √(81 − 16).","socratic_question":"Kann die Luftlinie kürzer sein als die 9 km nach Norden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9,8","equivalents":["9.8","9,8 km","9,8km"],"known_errors":{"13":"wurzel_gliedweise","97":"wurzel_vergessen","97 km":"wurzel_vergessen","97km":"wurzel_vergessen","13 km":"wurzel_gliedweise","13km":"wurzel_gliedweise","8,1":"hypotenuse_verwechselt","8.1":"hypotenuse_verwechselt","8,1 km":"hypotenuse_verwechselt","8,1km":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 pyth-hypotenuse-06 · Hypotenuse · Abkürzung über ein Feld
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b7eab8c9-653e-4b7f-b806-6fa49c8193e5'::uuid, 'exercise', 'Hypotenuse · Abkürzung über ein Feld', 'Ein rechteckiges Feld ist 120 m lang und 50 m breit. Ein Weg führt von einer Ecke an zwei Seiten entlang zur gegenüberliegenden Ecke. Quer über das Feld verläuft ein gerader Pfad zwischen denselben Ecken.

Wie viele Meter ist der Pfad kürzer als der Weg an den Seiten? Runde, falls nötig, auf ganze Meter.',
  '{"kind":"short_input","prompt":"Ein rechteckiges Feld ist 120 m lang und 50 m breit. Ein Weg führt von einer Ecke an zwei Seiten entlang zur gegenüberliegenden Ecke. Quer über das Feld verläuft ein gerader Pfad zwischen denselben Ecken.\n\nWie viele Meter ist der Pfad kürzer als der Weg an den Seiten? Runde, falls nötig, auf ganze Meter."}'::jsonb, 'NUMERIC', 'geo_pythagoras_hypotenuse',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-hypotenuse-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Diagonale als Hypotenuse erkennen und mit dem Weg entlang zweier Seiten vergleichen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b7eab8c9-653e-4b7f-b806-6fa49c8193e5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b7eab8c9-653e-4b7f-b806-6fa49c8193e5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b7eab8c9-653e-4b7f-b806-6fa49c8193e5'::uuid,
  p_correct_answers => '["40","40 m","40m"]'::jsonb,
  p_solution        => 'Weg an den Seiten: 120 m + 50 m = 170 m.
Pfad = Diagonale: √(120² + 50²) = √(14 400 + 2 500) = √16 900 = 130 m.
Ersparnis: 170 m − 130 m = 40 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Länge des Pfades angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel der Pfad kürzer ist – was fehlt noch?"},{"error":"Für die Diagonale die Quadrate subtrahiert: √(120² − 50²).","socratic_question":"Ist die Diagonale länger oder kürzer als die lange Seite des Feldes?"}]'::jsonb,
  p_acceptance      => '{"canonical":"40","equivalents":["40 m","40m"],"known_errors":{"61":"hypotenuse_verwechselt","130":"falsche_groesse_beantwortet","130 m":"falsche_groesse_beantwortet","130m":"falsche_groesse_beantwortet","61 m":"hypotenuse_verwechselt","61m":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 pyth-kathete-01 · Kathete · Hypotenuse 13 cm, Kathete 5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '238657cc-aaf5-46a0-a9d6-da57c60556c0'::uuid, 'exercise', 'Kathete · Hypotenuse 13 cm, Kathete 5 cm', 'Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 13 cm lang und die Kathete a = 5 cm lang.

Wie lang ist die Kathete b? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 13 cm lang und die Kathete a = 5 cm lang.\n\nWie lang ist die Kathete b? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Satz des Pythagoras nach einer Kathete umstellen, Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '238657cc-aaf5-46a0-a9d6-da57c60556c0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '238657cc-aaf5-46a0-a9d6-da57c60556c0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '238657cc-aaf5-46a0-a9d6-da57c60556c0'::uuid,
  p_correct_answers => '["12","12 cm","12cm"]'::jsonb,
  p_solution        => 'b² = c² − a² = 13² − 5² = 169 − 25 = 144.
b = √144 = 12 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert, als wäre die Hypotenuse gesucht: √(169 + 25).","socratic_question":"Kann eine Kathete länger sein als die Hypotenuse?"},{"error":"b² = 144 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon b ausgerechnet oder erst b²?"},{"error":"Die Wurzel Glied für Glied gezogen: √(13² − 5²) als 13 − 5.","socratic_question":"Ist √(169 − 25) dasselbe wie √169 − √25?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","equivalents":["12 cm","12cm"],"known_errors":{"8":"wurzel_gliedweise","144":"wurzel_vergessen","13,93":"hypotenuse_verwechselt","13.93":"hypotenuse_verwechselt","13,93 cm":"hypotenuse_verwechselt","13,93cm":"hypotenuse_verwechselt","144 cm":"wurzel_vergessen","144cm":"wurzel_vergessen","8 cm":"wurzel_gliedweise","8cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 pyth-kathete-02 · Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '379ce518-9974-42dc-9e4b-df29741ba395'::uuid, 'exercise', 'Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet', 'Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 10 cm lang und die Kathete a = 7 cm lang.

Wie lang ist die Kathete b? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 10 cm lang und die Kathete a = 7 cm lang.\n\nWie lang ist die Kathete b? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Kathete berechnen, Wurzel aus einer Nicht-Quadratzahl runden.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '379ce518-9974-42dc-9e4b-df29741ba395'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '379ce518-9974-42dc-9e4b-df29741ba395'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '379ce518-9974-42dc-9e4b-df29741ba395'::uuid,
  p_correct_answers => '["7,14","7.14","7,14 cm","7,14cm"]'::jsonb,
  p_solution        => 'b² = c² − a² = 10² − 7² = 100 − 49 = 51.
b = √51 ≈ 7,14 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert: √(100 + 49).","socratic_question":"Kann eine Kathete länger sein als die Hypotenuse?"},{"error":"b² = 51 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann eine Kathete länger sein als die Hypotenuse mit 10 cm?"},{"error":"Die Wurzel Glied für Glied gezogen: b = 10 − 7.","socratic_question":"Ist √(100 − 49) dasselbe wie √100 − √49?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,14","equivalents":["7.14","7,14 cm","7,14cm"],"known_errors":{"3":"wurzel_gliedweise","51":"wurzel_vergessen","12,21":"hypotenuse_verwechselt","12.21":"hypotenuse_verwechselt","12,21 cm":"hypotenuse_verwechselt","12,21cm":"hypotenuse_verwechselt","51,00":"wurzel_vergessen","51.00":"wurzel_vergessen","51,00 cm":"wurzel_vergessen","51,00cm":"wurzel_vergessen","51 cm":"wurzel_vergessen","51cm":"wurzel_vergessen","3,00":"wurzel_gliedweise","3.00":"wurzel_gliedweise","3,00 cm":"wurzel_gliedweise","3,00cm":"wurzel_gliedweise","3 cm":"wurzel_gliedweise","3cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 pyth-kathete-03 · Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'add6cee8-f9f3-494f-a321-cfaed9f5ac35'::uuid, 'exercise', 'Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm', 'Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 7,5 cm lang und die Kathete a = 4,5 cm lang.

Wie lang ist die Kathete b? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 7,5 cm lang und die Kathete a = 4,5 cm lang.\n\nWie lang ist die Kathete b? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Kathete aus Dezimalzahlen, Quadrate von Dezimalzahlen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'add6cee8-f9f3-494f-a321-cfaed9f5ac35'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'add6cee8-f9f3-494f-a321-cfaed9f5ac35'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'add6cee8-f9f3-494f-a321-cfaed9f5ac35'::uuid,
  p_correct_answers => '["6","6 cm","6cm"]'::jsonb,
  p_solution        => 'b² = 7,5² − 4,5² = 56,25 − 20,25 = 36.
b = √36 = 6 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert: √(56,25 + 20,25).","socratic_question":"Welche Seite liegt dem rechten Winkel bei C gegenüber?"},{"error":"b² = 36 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Ist 36 schon die Länge oder erst ihr Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: b = 7,5 − 4,5.","socratic_question":"Ist √(56,25 − 20,25) dasselbe wie 7,5 − 4,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["6 cm","6cm"],"known_errors":{"3":"wurzel_gliedweise","36":"wurzel_vergessen","8,75":"hypotenuse_verwechselt","8.75":"hypotenuse_verwechselt","8,75 cm":"hypotenuse_verwechselt","8,75cm":"hypotenuse_verwechselt","36 cm":"wurzel_vergessen","36cm":"wurzel_vergessen","3 cm":"wurzel_gliedweise","3cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 pyth-kathete-04 · Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '215a71de-a9ba-4d97-a94a-929c62c88601'::uuid, 'exercise', 'Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm', 'Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 25 cm lang und die Kathete a = 7 cm lang.

Wie groß ist der Flächeninhalt des Dreiecks? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C ist die Hypotenuse c = 25 cm lang und die Kathete a = 7 cm lang.\n\nWie groß ist der Flächeninhalt des Dreiecks? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst die fehlende Kathete, dann den Flächeninhalt des Dreiecks berechnen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, halbieren_vergessen, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '215a71de-a9ba-4d97-a94a-929c62c88601'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '215a71de-a9ba-4d97-a94a-929c62c88601'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '215a71de-a9ba-4d97-a94a-929c62c88601'::uuid,
  p_correct_answers => '["84","84 cm²","84cm²"]'::jsonb,
  p_solution        => 'b² = 25² − 7² = 625 − 49 = 576, also b = 24 cm.
Die Katheten stehen senkrecht aufeinander: A = a · b : 2 = 7 cm · 24 cm : 2 = 84 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Kathete b angegeben statt des Flächeninhalts.","socratic_question":"Ist nach einer Seite oder nach der Fläche gefragt?"},{"error":"Beim Flächeninhalt nicht halbiert: 7 · 24.","socratic_question":"Welchen Teil des Rechtecks mit den Seiten 7 cm und 24 cm bedeckt das Dreieck?"},{"error":"Für b die Quadrate addiert: √(625 + 49).","socratic_question":"Kann die Kathete b länger sein als die Hypotenuse?"}]'::jsonb,
  p_acceptance      => '{"canonical":"84","equivalents":["84 cm²","84cm²"],"known_errors":{"24":"falsche_groesse_beantwortet","168":"halbieren_vergessen","24 cm²":"falsche_groesse_beantwortet","24cm²":"falsche_groesse_beantwortet","168 cm²":"halbieren_vergessen","168cm²":"halbieren_vergessen","90,87":"hypotenuse_verwechselt","90.87":"hypotenuse_verwechselt","90,87 cm²":"hypotenuse_verwechselt","90,87cm²":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 pyth-kathete-05 · Kathete · Drachen an 60 m Schnur
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd0420f33-ea7e-47ff-9556-520c72a5dc4c'::uuid, 'exercise', 'Kathete · Drachen an 60 m Schnur', 'Ein Drachen hängt an einer 60 m langen, straff gespannten Schnur, die direkt am Boden festgehalten wird. Der Drachen steht genau über einem Punkt am Boden, der 25 m von dieser Stelle entfernt ist.

In welcher Höhe fliegt der Drachen? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Drachen hängt an einer 60 m langen, straff gespannten Schnur, die direkt am Boden festgehalten wird. Der Drachen steht genau über einem Punkt am Boden, der 25 m von dieser Stelle entfernt ist.\n\nIn welcher Höhe fliegt der Drachen? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Schnur als Hypotenuse erkennen, die Höhe ist eine Kathete.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd0420f33-ea7e-47ff-9556-520c72a5dc4c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd0420f33-ea7e-47ff-9556-520c72a5dc4c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd0420f33-ea7e-47ff-9556-520c72a5dc4c'::uuid,
  p_correct_answers => '["54,5","54.5","54,5 m","54,5m"]'::jsonb,
  p_solution        => 'Schnur (60 m) = Hypotenuse, Abstand am Boden (25 m) und Höhe h = Katheten.
h² = 60² − 25² = 3600 − 625 = 2975.
h = √2975 ≈ 54,5 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert: √(3600 + 625).","socratic_question":"Kann der Drachen höher fliegen, als die Schnur lang ist?"},{"error":"h² = 2975 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann der Drachen höher sein, als die Schnur lang ist?"},{"error":"Die Wurzel Glied für Glied gezogen: h = 60 − 25.","socratic_question":"Ist √(3600 − 625) dasselbe wie 60 − 25?"}]'::jsonb,
  p_acceptance      => '{"canonical":"54,5","equivalents":["54.5","54,5 m","54,5m"],"known_errors":{"35":"wurzel_gliedweise","65":"hypotenuse_verwechselt","2975":"wurzel_vergessen","65,0":"hypotenuse_verwechselt","65.0":"hypotenuse_verwechselt","65,0 m":"hypotenuse_verwechselt","65,0m":"hypotenuse_verwechselt","65 m":"hypotenuse_verwechselt","65m":"hypotenuse_verwechselt","2975 m":"wurzel_vergessen","2975m":"wurzel_vergessen","35,0":"wurzel_gliedweise","35.0":"wurzel_gliedweise","35,0 m":"wurzel_gliedweise","35,0m":"wurzel_gliedweise","35 m":"wurzel_gliedweise","35m":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 pyth-kathete-06 · Kathete · Höhe eines abgespannten Mastes
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4939a58d-47b1-4dc0-9ec9-e4e34a07c87e'::uuid, 'exercise', 'Kathete · Höhe eines abgespannten Mastes', 'Ein senkrechter Mast wird mit einem 25 m langen, straff gespannten Seil gehalten. Das Seil ist am Boden 7 m vom Fuß des Mastes entfernt befestigt. Am Mast ist es 2 m unterhalb der Spitze befestigt.

Wie hoch ist der Mast? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein senkrechter Mast wird mit einem 25 m langen, straff gespannten Seil gehalten. Das Seil ist am Boden 7 m vom Fuß des Mastes entfernt befestigt. Am Mast ist es 2 m unterhalb der Spitze befestigt.\n\nWie hoch ist der Mast? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_kathete',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-kathete-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: rechtwinkliges Dreieck in der Situation finden, Kathete berechnen und das Reststück ergänzen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, hypotenuse_verwechselt, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4939a58d-47b1-4dc0-9ec9-e4e34a07c87e'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4939a58d-47b1-4dc0-9ec9-e4e34a07c87e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4939a58d-47b1-4dc0-9ec9-e4e34a07c87e'::uuid,
  p_correct_answers => '["26","26 m","26m"]'::jsonb,
  p_solution        => 'Seil (25 m) = Hypotenuse, Bodenabstand (7 m) = Kathete.
Befestigungshöhe: √(25² − 7²) = √(625 − 49) = √576 = 24 m.
Masthöhe: 24 m + 2 m = 26 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Höhe der Befestigung angegeben, die 2 m bis zur Spitze fehlen.","socratic_question":"Ist das Seil an der Spitze des Mastes befestigt?"},{"error":"Die Quadrate addiert: √(625 + 49).","socratic_question":"Kann die Befestigung höher liegen, als das Seil lang ist?"},{"error":"Die Wurzel Glied für Glied gezogen: 25 − 7.","socratic_question":"Ist √(625 − 49) dasselbe wie 25 − 7?"}]'::jsonb,
  p_acceptance      => '{"canonical":"26","equivalents":["26 m","26m"],"known_errors":{"20":"wurzel_gliedweise","24":"falsche_groesse_beantwortet","24 m":"falsche_groesse_beantwortet","24m":"falsche_groesse_beantwortet","27,96":"hypotenuse_verwechselt","27.96":"hypotenuse_verwechselt","27,96 m":"hypotenuse_verwechselt","27,96m":"hypotenuse_verwechselt","20 m":"wurzel_gliedweise","20m":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 pyth-umkehrung-01 · Umkehrung · längste Seite zu 9 cm und 12 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '235952a2-3970-41ff-839c-51869e6f4878'::uuid, 'exercise', 'Umkehrung · längste Seite zu 9 cm und 12 cm', 'Die beiden kürzeren Seiten eines Dreiecks sind 9 cm und 12 cm lang.

Wie lang muss die längste Seite sein, damit das Dreieck rechtwinklig ist? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die beiden kürzeren Seiten eines Dreiecks sind 9 cm und 12 cm lang.\n\nWie lang muss die längste Seite sein, damit das Dreieck rechtwinklig ist? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Länge der dritten Seite aus der Umkehrung a² + b² = c², Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '235952a2-3970-41ff-839c-51869e6f4878'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '235952a2-3970-41ff-839c-51869e6f4878'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '235952a2-3970-41ff-839c-51869e6f4878'::uuid,
  p_correct_answers => '["15","15 cm","15cm"]'::jsonb,
  p_solution        => 'Rechtwinklig genau dann, wenn 9² + 12² = c² für die längste Seite c.
c² = 81 + 144 = 225, c = √225 = 15 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"c² = 225 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon die Seitenlänge oder erst ihr Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: c = 9 + 12.","socratic_question":"Kann ein Dreieck eine Seite haben, die so lang ist wie die beiden anderen zusammen?"},{"error":"Die Quadrate subtrahiert: √(144 − 81).","socratic_question":"Soll die gesuchte Seite die längste oder eine kürzere sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","equivalents":["15 cm","15cm"],"known_errors":{"21":"wurzel_gliedweise","225":"wurzel_vergessen","225 cm":"wurzel_vergessen","225cm":"wurzel_vergessen","21 cm":"wurzel_gliedweise","21cm":"wurzel_gliedweise","7,94":"hypotenuse_verwechselt","7.94":"hypotenuse_verwechselt","7,94 cm":"hypotenuse_verwechselt","7,94cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 pyth-umkehrung-02 · Umkehrung · welches der vier Dreiecke ist rechtwinklig?
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '893d7877-d9bd-4fa0-88b7-eb36f6bbadad'::uuid, 'exercise', 'Umkehrung · welches der vier Dreiecke ist rechtwinklig?', 'Genau eines der vier Dreiecke ist rechtwinklig.
(1) 5 cm, 6 cm, 8 cm
(2) 7 cm, 24 cm, 25 cm
(3) 5 cm, 7 cm, 8,6 cm
(4) 2 cm, 2,5 cm, 3 cm

Gib die Nummer des rechtwinkligen Dreiecks an. Die Antwort ist eine ganze Zahl.',
  '{"kind":"short_input","prompt":"Genau eines der vier Dreiecke ist rechtwinklig.\n(1) 5 cm, 6 cm, 8 cm\n(2) 7 cm, 24 cm, 25 cm\n(3) 5 cm, 7 cm, 8,6 cm\n(4) 2 cm, 2,5 cm, 3 cm\n\nGib die Nummer des rechtwinkligen Dreiecks an. Die Antwort ist eine ganze Zahl."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: a² + b² = c² für vier gegebene Dreiecke prüfen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zu_frueh_gerundet, mal_exponent).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '893d7877-d9bd-4fa0-88b7-eb36f6bbadad'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '893d7877-d9bd-4fa0-88b7-eb36f6bbadad'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '893d7877-d9bd-4fa0-88b7-eb36f6bbadad'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => 'Prüfe jeweils: Summe der Quadrate der kürzeren Seiten = Quadrat der längsten Seite?
(1) 25 + 36 = 61, 8² = 64: nein.
(2) 49 + 576 = 625, 25² = 625: ja.
(3) 25 + 49 = 74, 8,6² = 73,96: nein (nur ungefähr).
(4) 4 + 6,25 = 10,25, 3² = 9: nein.
Rechtwinklig ist Dreieck 2.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Dreieck (3) gewählt: √74 ≈ 8,6 wie eine Gleichheit behandelt, dabei ist 8,6² = 73,96 und nicht 74.","socratic_question":"Ist 8,6² genau 74 oder nur ungefähr?"},{"error":"Dreieck (4) gewählt: 2,5² als 2 · 2,5 = 5 gerechnet, dann 4 + 5 = 9 = 3².","socratic_question":"Was ist 2,5²: 2,5 · 2 oder 2,5 · 2,5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","equivalents":["+2"],"known_errors":{"3":"zu_frueh_gerundet","4":"mal_exponent","+3":"zu_frueh_gerundet","+4":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 pyth-umkehrung-03 · Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '070f3609-9adf-4c66-adaf-daabe4ae276c'::uuid, 'exercise', 'Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm', 'Ein Dreieck hat die Seitenlängen 6 cm, 7 cm und 9 cm. Mit a und b sind die beiden kürzeren Seiten gemeint, mit c die längste.

Um wie viele Quadratzentimeter ist a² + b² größer als c²? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Dreieck hat die Seitenlängen 6 cm, 7 cm und 9 cm. Mit a und b sind die beiden kürzeren Seiten gemeint, mit c die längste.\n\nUm wie viele Quadratzentimeter ist a² + b² größer als c²? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Summe der Kathetenquadrate mit dem Quadrat der längsten Seite vergleichen und den Unterschied angeben.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, mal_exponent, falsche_groesse_beantwortet).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '070f3609-9adf-4c66-adaf-daabe4ae276c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '070f3609-9adf-4c66-adaf-daabe4ae276c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '070f3609-9adf-4c66-adaf-daabe4ae276c'::uuid,
  p_correct_answers => '["4","4 cm²","4cm²"]'::jsonb,
  p_solution        => 'a² + b² = 6² + 7² = 36 + 49 = 85.
c² = 9² = 81.
85 − 81 = 4 cm². Das Dreieck ist also nicht rechtwinklig.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die falsche Seite als c genommen: 6² + 9² − 7².","socratic_question":"Welche der drei Seiten ist die längste?"},{"error":"Quadrate als Verdopplung gerechnet: 2 · 6 + 2 · 7 − 2 · 9.","socratic_question":"Was bedeutet 6²: 6 · 2 oder 6 · 6?"},{"error":"Nur a² + b² angegeben statt des Unterschieds zu c².","socratic_question":"Gefragt ist, um wie viel a² + b² größer ist – was fehlt noch?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 cm²","4cm²"],"known_errors":{"8":"mal_exponent","68":"hypotenuse_verwechselt","85":"falsche_groesse_beantwortet","68 cm²":"hypotenuse_verwechselt","68cm²":"hypotenuse_verwechselt","8 cm²":"mal_exponent","8cm²":"mal_exponent","85 cm²":"falsche_groesse_beantwortet","85cm²":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 pyth-umkehrung-04 · Umkehrung · wie viel länger müsste die längste Seite sein?
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1a311c06-45ab-49c7-a4bf-413242d50c6a'::uuid, 'exercise', 'Umkehrung · wie viel länger müsste die längste Seite sein?', 'Ein Dreieck hat die Seitenlängen 2,5 cm, 4 cm und 4,5 cm.

Um wie viele Zentimeter müsste die längste Seite länger sein, damit das Dreieck mit den beiden anderen Seiten rechtwinklig wird? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Dreieck hat die Seitenlängen 2,5 cm, 4 cm und 4,5 cm.\n\nUm wie viele Zentimeter müsste die längste Seite länger sein, damit das Dreieck mit den beiden anderen Seiten rechtwinklig wird? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 2, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Soll-Länge der längsten Seite aus der Umkehrung bestimmen und mit der Ist-Länge vergleichen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, falsche_groesse_beantwortet, zu_frueh_gerundet).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1a311c06-45ab-49c7-a4bf-413242d50c6a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1a311c06-45ab-49c7-a4bf-413242d50c6a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1a311c06-45ab-49c7-a4bf-413242d50c6a'::uuid,
  p_correct_answers => '["0,22","0.22","0,22 cm","0,22cm"]'::jsonb,
  p_solution        => 'Für einen rechten Winkel müsste die längste Seite √(2,5² + 4²) = √(6,25 + 16) = √22,25 ≈ 4,717 cm lang sein.
4,717 cm − 4,5 cm ≈ 0,22 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Quadrate verglichen: 22,25 − 20,25 = 2, ohne Wurzel.","socratic_question":"Ist nach einem Unterschied von Längen oder von Quadraten gefragt?"},{"error":"Die nötige Länge der Seite angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel die Seite länger sein müsste – was fehlt noch?"},{"error":"√22,25 vorher auf 4,7 gerundet: 4,7 − 4,5 = 0,2.","socratic_question":"Was passiert mit einem kleinen Unterschied, wenn du vorher rundest?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,22","equivalents":["0.22","0,22 cm","0,22cm"],"known_errors":{"2":"wurzel_vergessen","2 cm":"wurzel_vergessen","2cm":"wurzel_vergessen","4,72":"falsche_groesse_beantwortet","4.72":"falsche_groesse_beantwortet","4,72 cm":"falsche_groesse_beantwortet","4,72cm":"falsche_groesse_beantwortet","0,20":"zu_frueh_gerundet","0.20":"zu_frueh_gerundet","0,2":"zu_frueh_gerundet","0.2":"zu_frueh_gerundet","0,20 cm":"zu_frueh_gerundet","0,20cm":"zu_frueh_gerundet","0,2 cm":"zu_frueh_gerundet","0,2cm":"zu_frueh_gerundet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 pyth-umkehrung-05 · Umkehrung · rechte Ecke beim Abstecken
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8ea1d77f-e430-4e8d-8fbd-8258f50c9133'::uuid, 'exercise', 'Umkehrung · rechte Ecke beim Abstecken', 'Beim Bau eines Gartenhauses soll eine Ecke genau rechtwinklig werden. Von der Ecke aus wird auf der einen Seite 1,2 m abgemessen, auf der anderen Seite 1,6 m. Die beiden Endpunkte werden markiert.

Wie groß muss der Abstand der beiden Markierungen sein, damit die Ecke ein rechter Winkel ist? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Beim Bau eines Gartenhauses soll eine Ecke genau rechtwinklig werden. Von der Ecke aus wird auf der einen Seite 1,2 m abgemessen, auf der anderen Seite 1,6 m. Die beiden Endpunkte werden markiert.\n\nWie groß muss der Abstand der beiden Markierungen sein, damit die Ecke ein rechter Winkel ist? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, 1, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Die Umkehrung des Satzes als Prüfverfahren für einen rechten Winkel erkennen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8ea1d77f-e430-4e8d-8fbd-8258f50c9133'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8ea1d77f-e430-4e8d-8fbd-8258f50c9133'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8ea1d77f-e430-4e8d-8fbd-8258f50c9133'::uuid,
  p_correct_answers => '["2","2 m","2m"]'::jsonb,
  p_solution        => 'Die Ecke ist genau dann rechtwinklig, wenn der Abstand d die Gleichung 1,2² + 1,6² = d² erfüllt.
d² = 1,44 + 2,56 = 4, d = √4 = 2 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"d² = 4 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Ist 4 schon der Abstand oder erst sein Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: d = 1,2 + 1,6.","socratic_question":"Ist der direkte Abstand so lang wie beide Seiten zusammen?"},{"error":"Die Quadrate subtrahiert: √(2,56 − 1,44).","socratic_question":"Liegt der gesuchte Abstand dem rechten Winkel gegenüber?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","equivalents":["2 m","2m"],"known_errors":{"4":"wurzel_vergessen","4 m":"wurzel_vergessen","4m":"wurzel_vergessen","2,8":"wurzel_gliedweise","2.8":"wurzel_gliedweise","2,8 m":"wurzel_gliedweise","2,8m":"wurzel_gliedweise","1,06":"hypotenuse_verwechselt","1.06":"hypotenuse_verwechselt","1,06 m":"hypotenuse_verwechselt","1,06m":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 pyth-umkehrung-06 · Umkehrung · Latte um wie viele Zentimeter kürzen?
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '52d53fbc-2b53-48ec-a0b7-77f99826aa4d'::uuid, 'exercise', 'Umkehrung · Latte um wie viele Zentimeter kürzen?', 'Aus drei Latten wird ein Dreieck gelegt. Die beiden kürzeren Latten sind 3 m und 4 m lang, die längste ist 5,10 m lang. Der Winkel zwischen den beiden kürzeren Latten soll ein rechter Winkel werden.

Um wie viele Zentimeter muss die längste Latte dafür gekürzt werden? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Aus drei Latten wird ein Dreieck gelegt. Die beiden kürzeren Latten sind 3 m und 4 m lang, die längste ist 5,10 m lang. Der Winkel zwischen den beiden kürzeren Latten soll ein rechter Winkel werden.\n\nUm wie viele Zentimeter muss die längste Latte dafür gekürzt werden? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_umkehrung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-umkehrung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Soll-Länge über die Umkehrung bestimmen, mit der Ist-Länge vergleichen und in Zentimeter umrechnen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, einheit_uebersprungen, wurzel_vergessen).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '52d53fbc-2b53-48ec-a0b7-77f99826aa4d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '52d53fbc-2b53-48ec-a0b7-77f99826aa4d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '52d53fbc-2b53-48ec-a0b7-77f99826aa4d'::uuid,
  p_correct_answers => '["10","10 cm","10cm"]'::jsonb,
  p_solution        => 'Für einen rechten Winkel muss die längste Seite √(3² + 4²) m = √25 m = 5 m = 500 cm lang sein.
510 cm − 500 cm = 10 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die nötige Länge der Latte angegeben statt des Stücks, das ab muss.","socratic_question":"Gefragt ist, wie viel abgesägt wird – was fehlt noch?"},{"error":"Den Unterschied in Metern angegeben: 0,1.","socratic_question":"In welcher Einheit ist das Ergebnis gefragt?"},{"error":"Nur die Quadrate verglichen: 26,01 − 25 = 1,01, ohne Wurzel, dann mal 100.","socratic_question":"Ist nach einem Unterschied von Längen oder von Quadraten gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["10 cm","10cm"],"known_errors":{"101":"wurzel_vergessen","500":"falsche_groesse_beantwortet","500 cm":"falsche_groesse_beantwortet","500cm":"falsche_groesse_beantwortet","0,1":"einheit_uebersprungen","0.1":"einheit_uebersprungen","0,1 cm":"einheit_uebersprungen","0,1cm":"einheit_uebersprungen","101 cm":"wurzel_vergessen","101cm":"wurzel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 pyth-abstand-01 · Abstand · P(1|2) und Q(4|6)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dacb0349-eb7f-428d-8c25-85a9dc562474'::uuid, 'exercise', 'Abstand · P(1|2) und Q(4|6)', 'Gegeben sind die Punkte P(1|2) und Q(4|6) in einem Koordinatensystem.

Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben sind die Punkte P(1|2) und Q(4|6) in einem Koordinatensystem.\n\nWie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Koordinatendifferenzen bilden und den Satz des Pythagoras anwenden, Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'dacb0349-eb7f-428d-8c25-85a9dc562474'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dacb0349-eb7f-428d-8c25-85a9dc562474'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'dacb0349-eb7f-428d-8c25-85a9dc562474'::uuid,
  p_correct_answers => '["5","+5"]'::jsonb,
  p_solution        => 'Unterschied der x-Werte: 4 − 1 = 3, der y-Werte: 6 − 2 = 4.
Abstand² = 3² + 4² = 9 + 16 = 25.
Abstand = √25 = 5 Längeneinheiten.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abstand² = 25 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon den Abstand oder erst sein Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: 3 + 4.","socratic_question":"Ist der direkte Weg so lang wie der Weg erst nach rechts und dann nach oben?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5"],"known_errors":{"7":"wurzel_gliedweise","25":"wurzel_vergessen","+25":"wurzel_vergessen","+7":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 pyth-abstand-02 · Abstand · zwei Punkte aus der Abbildung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid, 'exercise', 'Abstand · zwei Punkte aus der Abbildung', 'Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.

Lies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.\n\nLies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, true, 2, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Koordinaten im ersten Quadranten ablesen, Abstand mit dem Satz des Pythagoras, Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, wurzel_gliedweise, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Abgelesen: P(1|1), Q(7|9).
Unterschied der x-Werte: 7 − 1 = 6, der y-Werte: 9 − 1 = 8.
Abstand = √(6² + 8²) = √(36 + 64) = √100 = 10 Längeneinheiten.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Abstand² = 100 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon den Abstand oder erst sein Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: 6 + 8.","socratic_question":"Ist der direkte Weg so lang wie der Weg erst nach rechts und dann nach oben?"},{"error":"Die Quadrate subtrahiert: √(64 − 36).","socratic_question":"Ist der Abstand länger oder kürzer als die beiden Koordinatenunterschiede?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"14":"wurzel_gliedweise","100":"wurzel_vergessen","+100":"wurzel_vergessen","+14":"wurzel_gliedweise","5,29":"hypotenuse_verwechselt","+5,29":"hypotenuse_verwechselt","5.29":"hypotenuse_verwechselt","+5.29":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid, 'koordinatensystem', '{"x_min":-1,"x_max":8,"y_min":-1,"y_max":10,"punkte":[{"x":1,"y":1,"label":"P"},{"x":7,"y":9,"label":"Q"}]}'::jsonb, 'Koordinatensystem mit Gitter und den Punkten P und Q.'
 where exists (select 1 from public.tasks t where t.id = '719b3012-468a-48c0-8105-66f02c75fb0f'::uuid and t.source = 'edvance_k9_pythagoras')
on conflict (task_id) do nothing;

-- #21 pyth-abstand-03 · Abstand · P(−2|3) und Q(4|−5) über die Achsen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b64244f5-d5d9-44f3-b0f9-cc51c25bef4c'::uuid, 'exercise', 'Abstand · P(−2|3) und Q(4|−5) über die Achsen', 'Gegeben sind die Punkte P(−2|3) und Q(4|−5) in einem Koordinatensystem.

Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben sind die Punkte P(−2|3) und Q(4|−5) in einem Koordinatensystem.\n\nWie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Koordinatendifferenzen über die Achsen hinweg mit Vorzeichen bilden.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b64244f5-d5d9-44f3-b0f9-cc51c25bef4c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b64244f5-d5d9-44f3-b0f9-cc51c25bef4c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b64244f5-d5d9-44f3-b0f9-cc51c25bef4c'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Unterschied der x-Werte: 4 − (−2) = 6, der y-Werte: 3 − (−5) = 8.
Abstand² = 6² + 8² = 36 + 64 = 100.
Abstand = √100 = 10 Längeneinheiten.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Vorzeichen übersehen: 4 − 2 = 2 und 5 − 3 = 2, also √8.","socratic_question":"Wie viele Einheiten liegen auf der x-Achse zwischen −2 und 4?"},{"error":"Abstand² = 100 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon den Abstand oder erst sein Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: 6 + 8.","socratic_question":"Ist √(36 + 64) dasselbe wie 6 + 8?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"14":"wurzel_gliedweise","100":"wurzel_vergessen","2,83":"vorzeichen_ignoriert","+2,83":"vorzeichen_ignoriert","2.83":"vorzeichen_ignoriert","+2.83":"vorzeichen_ignoriert","+100":"wurzel_vergessen","+14":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 pyth-abstand-04 · Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid, 'exercise', 'Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet', 'Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.

Lies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.\n\nLies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, true, null, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Koordinaten in verschiedenen Quadranten ablesen, Differenzen mit Vorzeichen, Wurzel runden.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid,
  p_correct_answers => '["5,83","+5,83","5.83","+5.83"]'::jsonb,
  p_solution        => 'Abgelesen: P(−3|2), Q(2|−1).
Unterschied der x-Werte: 2 − (−3) = 5, der y-Werte: 2 − (−1) = 3.
Abstand = √(5² + 3²) = √(25 + 9) = √34 ≈ 5,83 Längeneinheiten.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Vorzeichen übersehen: 3 − 2 = 1 und 2 − 1 = 1, also √2.","socratic_question":"Wie viele Kästchen liegen zwischen P und Q in x-Richtung?"},{"error":"Abstand² = 34 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon den Abstand oder erst sein Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: 5 + 3.","socratic_question":"Ist der direkte Weg so lang wie der Weg über die Kästchenlinien?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,83","equivalents":["+5,83","5.83","+5.83"],"known_errors":{"8":"wurzel_gliedweise","34":"wurzel_vergessen","1,41":"vorzeichen_ignoriert","+1,41":"vorzeichen_ignoriert","1.41":"vorzeichen_ignoriert","+1.41":"vorzeichen_ignoriert","+34":"wurzel_vergessen","+8":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-5,"y_max":5,"punkte":[{"x":-3,"y":2,"label":"P"},{"x":2,"y":-1,"label":"Q"}]}'::jsonb, 'Koordinatensystem mit Gitter und den Punkten P und Q.'
 where exists (select 1 from public.tasks t where t.id = 'd60ffe34-b219-4cfb-9eb6-727185238880'::uuid and t.source = 'edvance_k9_pythagoras')
on conflict (task_id) do nothing;

-- #23 pyth-abstand-05 · Abstand · Hafen und Leuchtturm auf einer Karte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '16d86280-3377-44a8-b009-07801586c50c'::uuid, 'exercise', 'Abstand · Hafen und Leuchtturm auf einer Karte', 'Die Abbildung zeigt eine Karte mit Gitter. Der Punkt H ist ein Hafen, der Punkt L ein Leuchtturm. Eine Längeneinheit entspricht 1 km.

Wie weit ist der Leuchtturm in Luftlinie vom Hafen entfernt? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt eine Karte mit Gitter. Der Punkt H ist ein Hafen, der Punkt L ein Leuchtturm. Eine Längeneinheit entspricht 1 km.\n\nWie weit ist der Leuchtturm in Luftlinie vom Hafen entfernt? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'km', true, null, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Karte als Koordinatensystem lesen, Luftlinie als Abstand zweier Punkte berechnen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Abbildung (Koordinatensystem) gehört zur Aufgabe; Generator koordinatensystem, task_figures.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (vorzeichen_ignoriert, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '16d86280-3377-44a8-b009-07801586c50c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '16d86280-3377-44a8-b009-07801586c50c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '16d86280-3377-44a8-b009-07801586c50c'::uuid,
  p_correct_answers => '["9,2","9.2","9,2 km","9,2km"]'::jsonb,
  p_solution        => 'Abgelesen: H(−4|−2), L(3|4).
Unterschied der x-Werte: 3 − (−4) = 7, der y-Werte: 4 − (−2) = 6.
Abstand = √(7² + 6²) = √(49 + 36) = √85 ≈ 9,2 km.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Vorzeichen übersehen: 4 − 3 = 1 und 4 − 2 = 2, also √5.","socratic_question":"Wie viele Kästchen liegen zwischen H und L in x-Richtung?"},{"error":"Abstand² = 85 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann die Luftlinie länger sein als der Weg entlang der Gitterlinien?"},{"error":"Die Wege entlang der Gitterlinien addiert: 7 + 6.","socratic_question":"Ist die Luftlinie so lang wie der Weg erst nach rechts und dann nach oben?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9,2","equivalents":["9.2","9,2 km","9,2km"],"known_errors":{"13":"wurzel_gliedweise","85":"wurzel_vergessen","2,2":"vorzeichen_ignoriert","2.2":"vorzeichen_ignoriert","2,2 km":"vorzeichen_ignoriert","2,2km":"vorzeichen_ignoriert","85 km":"wurzel_vergessen","85km":"wurzel_vergessen","13 km":"wurzel_gliedweise","13km":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select '16d86280-3377-44a8-b009-07801586c50c'::uuid, 'koordinatensystem', '{"x_min":-5,"x_max":5,"y_min":-3,"y_max":5,"punkte":[{"x":-4,"y":-2,"label":"H"},{"x":3,"y":4,"label":"L"}]}'::jsonb, 'Karte als Koordinatensystem mit Gitter und den Punkten H und L.'
 where exists (select 1 from public.tasks t where t.id = '16d86280-3377-44a8-b009-07801586c50c'::uuid and t.source = 'edvance_k9_pythagoras')
on conflict (task_id) do nothing;

-- #24 pyth-abstand-06 · Abstand · fehlende Koordinate aus dem Abstand
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '79cd7e85-5477-4cf6-b8ef-9b5899215087'::uuid, 'exercise', 'Abstand · fehlende Koordinate aus dem Abstand', 'Gegeben sind die Punkte P(−2|1) und Q(x|−5). Q liegt rechts von P. Der Abstand der Punkte P und Q beträgt 10 Längeneinheiten.

Wie groß ist die x-Koordinate von Q? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Gegeben sind die Punkte P(−2|1) und Q(x|−5). Q liegt rechts von P. Der Abstand der Punkte P und Q beträgt 10 Längeneinheiten.\n\nWie groß ist die x-Koordinate von Q? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_abstand',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, null, false, 1, 'draft', 'edvance_k9_pythagoras', 'pyth-abstand-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – aus Abstand und einer Koordinatendifferenz die andere Differenz und daraus die Koordinate bestimmen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_gliedweise, wurzel_vergessen, vorzeichen_ignoriert).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '79cd7e85-5477-4cf6-b8ef-9b5899215087'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '79cd7e85-5477-4cf6-b8ef-9b5899215087'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '79cd7e85-5477-4cf6-b8ef-9b5899215087'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => 'Unterschied der y-Werte: 1 − (−5) = 6.
Unterschied der x-Werte: √(10² − 6²) = √(100 − 36) = √64 = 8.
Q liegt rechts von P: x = −2 + 8 = 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Unterschied der x-Werte angegeben statt der Koordinate von Q.","socratic_question":"Bei welcher x-Koordinate beginnst du, wenn du von P aus 8 Einheiten nach rechts gehst?"},{"error":"Die Wurzel Glied für Glied gezogen: √(10² − 6²) als 10 − 6.","socratic_question":"Ist √(100 − 36) dasselbe wie 10 − 6?"},{"error":"Den x-Unterschied als 64 genommen, ohne die Wurzel zu ziehen.","socratic_question":"Ist 64 schon der Unterschied der x-Werte oder erst sein Quadrat?"},{"error":"Die Vorzeichen übersehen: y-Unterschied 5 − 1 = 4 statt 6.","socratic_question":"Wie viele Einheiten liegen auf der y-Achse zwischen 1 und −5?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"2":"wurzel_gliedweise","8":"falsche_groesse_beantwortet","62":"wurzel_vergessen","+8":"falsche_groesse_beantwortet","+2":"wurzel_gliedweise","+62":"wurzel_vergessen","7,17":"vorzeichen_ignoriert","+7,17":"vorzeichen_ignoriert","7.17":"vorzeichen_ignoriert","+7.17":"vorzeichen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 pyth-anwendung-01 · Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '21d8e109-03dd-4958-ab1f-4a9a2ba88a81'::uuid, 'exercise', 'Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm', 'Ein Rechteck ist 12 cm lang und 5 cm breit.

Wie lang ist seine Diagonale? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Rechteck ist 12 cm lang und 5 cm breit.\n\nWie lang ist seine Diagonale? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Diagonale als Hypotenuse im Rechteck erkennen, Ergebnis ganzzahlig.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_gliedweise, wurzel_vergessen, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '21d8e109-03dd-4958-ab1f-4a9a2ba88a81'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '21d8e109-03dd-4958-ab1f-4a9a2ba88a81'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '21d8e109-03dd-4958-ab1f-4a9a2ba88a81'::uuid,
  p_correct_answers => '["13","13 cm","13cm"]'::jsonb,
  p_solution        => 'Die Diagonale teilt das Rechteck in zwei rechtwinklige Dreiecke; sie ist die Hypotenuse.
d² = 12² + 5² = 144 + 25 = 169.
d = √169 = 13 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wurzel Glied für Glied gezogen: d = 12 + 5.","socratic_question":"Ist die Diagonale so lang wie zwei Seiten zusammen?"},{"error":"d² = 169 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon die Diagonale oder erst ihr Quadrat?"},{"error":"Die Quadrate subtrahiert: √(144 − 25).","socratic_question":"Kann die Diagonale kürzer sein als die lange Seite?"}]'::jsonb,
  p_acceptance      => '{"canonical":"13","equivalents":["13 cm","13cm"],"known_errors":{"17":"wurzel_gliedweise","169":"wurzel_vergessen","17 cm":"wurzel_gliedweise","17cm":"wurzel_gliedweise","169 cm":"wurzel_vergessen","169cm":"wurzel_vergessen","10,91":"hypotenuse_verwechselt","10.91":"hypotenuse_verwechselt","10,91 cm":"hypotenuse_verwechselt","10,91cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 pyth-anwendung-02 · Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '58c917d7-182f-4591-be02-374e86a79e41'::uuid, 'exercise', 'Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm', 'Ein gleichseitiges Dreieck hat die Seitenlänge 6 cm.

Wie lang ist seine Höhe? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein gleichseitiges Dreieck hat die Seitenlänge 6 cm.\n\nWie lang ist seine Höhe? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, 1, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Höhe teilt das gleichseitige Dreieck in zwei rechtwinklige Dreiecke mit halber Grundseite.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '58c917d7-182f-4591-be02-374e86a79e41'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '58c917d7-182f-4591-be02-374e86a79e41'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '58c917d7-182f-4591-be02-374e86a79e41'::uuid,
  p_correct_answers => '["5,20","5.20","5,2","5.2","5,20 cm","5,20cm","5,2 cm","5,2cm"]'::jsonb,
  p_solution        => 'Die Höhe halbiert die Grundseite: rechtwinkliges Dreieck mit Hypotenuse 6 cm und Kathete 3 cm.
h² = 6² − 3² = 36 − 9 = 27.
h = √27 ≈ 5,20 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert: √(36 + 9).","socratic_question":"Kann die Höhe länger sein als eine Seite des Dreiecks?"},{"error":"h² = 27 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann die Höhe länger sein als eine Seite des Dreiecks?"},{"error":"Die Wurzel Glied für Glied gezogen: h = 6 − 3.","socratic_question":"Ist √(36 − 9) dasselbe wie 6 − 3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5,20","equivalents":["5.20","5,2","5.2","5,20 cm","5,20cm","5,2 cm","5,2cm"],"known_errors":{"3":"wurzel_gliedweise","27":"wurzel_vergessen","6,71":"hypotenuse_verwechselt","6.71":"hypotenuse_verwechselt","6,71 cm":"hypotenuse_verwechselt","6,71cm":"hypotenuse_verwechselt","27,00":"wurzel_vergessen","27.00":"wurzel_vergessen","27,00 cm":"wurzel_vergessen","27,00cm":"wurzel_vergessen","27 cm":"wurzel_vergessen","27cm":"wurzel_vergessen","3,00":"wurzel_gliedweise","3.00":"wurzel_gliedweise","3,00 cm":"wurzel_gliedweise","3,00cm":"wurzel_gliedweise","3 cm":"wurzel_gliedweise","3cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 pyth-anwendung-03 · Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '437b6af2-c70c-4dc8-9f6b-9e155757405a'::uuid, 'exercise', 'Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm', 'Ein Quader ist 4 cm breit, 6 cm tief und 10 cm hoch.

Wie lang ist seine Raumdiagonale? Runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Quader ist 4 cm breit, 6 cm tief und 10 cm hoch.\n\nWie lang ist seine Raumdiagonale? Runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zweimal Satz des Pythagoras – erst Flächendiagonale der Grundfläche, dann Raumdiagonale.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '437b6af2-c70c-4dc8-9f6b-9e155757405a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '437b6af2-c70c-4dc8-9f6b-9e155757405a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '437b6af2-c70c-4dc8-9f6b-9e155757405a'::uuid,
  p_correct_answers => '["12,3","12.3","12,3 cm","12,3cm"]'::jsonb,
  p_solution        => 'Diagonale der Grundfläche: e² = 4² + 6² = 16 + 36 = 52.
Raumdiagonale: d² = e² + 10² = 52 + 100 = 152.
d = √152 ≈ 12,3 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Diagonale der Grundfläche angegeben, nicht die Raumdiagonale.","socratic_question":"Geht deine Diagonale auch durch den Raum nach oben?"},{"error":"d² = 152 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Hast du schon die Diagonale oder erst ihr Quadrat?"},{"error":"Die Wurzel Glied für Glied gezogen: 4 + 6 + 10.","socratic_question":"Ist die Raumdiagonale so lang wie alle drei Kanten zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,3","equivalents":["12.3","12,3 cm","12,3cm"],"known_errors":{"20":"wurzel_gliedweise","152":"wurzel_vergessen","7,2":"falsche_groesse_beantwortet","7.2":"falsche_groesse_beantwortet","7,2 cm":"falsche_groesse_beantwortet","7,2cm":"falsche_groesse_beantwortet","152 cm":"wurzel_vergessen","152cm":"wurzel_vergessen","20 cm":"wurzel_gliedweise","20cm":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 pyth-anwendung-04 · Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a21f48d2-f097-495a-91ed-093327524d91'::uuid, 'exercise', 'Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm', 'Ein gleichseitiges Dreieck hat die Seitenlänge 8 cm.

Wie groß ist sein Flächeninhalt? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein gleichseitiges Dreieck hat die Seitenlänge 8 cm.\n\nWie groß ist sein Flächeninhalt? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Höhe mit dem Satz des Pythagoras, dann Flächeninhalt des Dreiecks.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_groesse_beantwortet, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a21f48d2-f097-495a-91ed-093327524d91'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a21f48d2-f097-495a-91ed-093327524d91'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a21f48d2-f097-495a-91ed-093327524d91'::uuid,
  p_correct_answers => '["27,71","27.71","27,71 cm²","27,71cm²"]'::jsonb,
  p_solution        => 'Höhe: h² = 8² − 4² = 64 − 16 = 48, h = √48 ≈ 6,928 cm.
A = g · h : 2 = 8 cm · √48 cm : 2 ≈ 27,71 cm².
(Erst am Ende runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Beim Flächeninhalt nicht halbiert: 8 · h.","socratic_question":"Welcher Teil des Rechtecks mit den Seiten g und h ist das Dreieck?"},{"error":"Nur die Höhe angegeben statt des Flächeninhalts.","socratic_question":"Ist nach der Höhe oder nach der Fläche gefragt?"},{"error":"Für die Höhe die Quadrate addiert: √(64 + 16).","socratic_question":"Kann die Höhe länger sein als eine Seite des Dreiecks?"}]'::jsonb,
  p_acceptance      => '{"canonical":"27,71","equivalents":["27.71","27,71 cm²","27,71cm²"],"known_errors":{"55,43":"halbieren_vergessen","55.43":"halbieren_vergessen","55,43 cm²":"halbieren_vergessen","55,43cm²":"halbieren_vergessen","6,93":"falsche_groesse_beantwortet","6.93":"falsche_groesse_beantwortet","6,93 cm²":"falsche_groesse_beantwortet","6,93cm²":"falsche_groesse_beantwortet","35,78":"hypotenuse_verwechselt","35.78":"hypotenuse_verwechselt","35,78 cm²":"hypotenuse_verwechselt","35,78cm²":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 pyth-anwendung-05 · Anwendung · Leiter an einer Wand
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '208e0467-be77-4c56-9135-c9c93554aefd'::uuid, 'exercise', 'Anwendung · Leiter an einer Wand', 'Eine 5 m lange Leiter lehnt an einer senkrechten Hauswand. Ihr Fuß steht auf ebenem Boden 1,4 m von der Wand entfernt.

In welcher Höhe berührt die Leiter die Wand? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine 5 m lange Leiter lehnt an einer senkrechten Hauswand. Ihr Fuß steht auf ebenem Boden 1,4 m von der Wand entfernt.\n\nIn welcher Höhe berührt die Leiter die Wand? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Leiter als Hypotenuse, Wandhöhe als Kathete erkennen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, wurzel_vergessen, wurzel_gliedweise).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '208e0467-be77-4c56-9135-c9c93554aefd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = '208e0467-be77-4c56-9135-c9c93554aefd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '208e0467-be77-4c56-9135-c9c93554aefd'::uuid,
  p_correct_answers => '["4,8","4.8","4,8 m","4,8m"]'::jsonb,
  p_solution        => 'Leiter (5 m) = Hypotenuse, Bodenabstand (1,4 m) und Höhe h = Katheten.
h² = 5² − 1,4² = 25 − 1,96 = 23,04.
h = √23,04 = 4,8 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Quadrate addiert: √(25 + 1,96).","socratic_question":"Kann die Leiter höher reichen, als sie lang ist?"},{"error":"h² = 23,04 ausgerechnet, aber die Wurzel nicht gezogen.","socratic_question":"Kann die Leiter höher reichen, als sie lang ist?"},{"error":"Die Wurzel Glied für Glied gezogen: h = 5 − 1,4.","socratic_question":"Ist √(25 − 1,96) dasselbe wie 5 − 1,4?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4,8","equivalents":["4.8","4,8 m","4,8m"],"known_errors":{"5,19":"hypotenuse_verwechselt","5.19":"hypotenuse_verwechselt","5,19 m":"hypotenuse_verwechselt","5,19m":"hypotenuse_verwechselt","23,04":"wurzel_vergessen","23.04":"wurzel_vergessen","23,04 m":"wurzel_vergessen","23,04m":"wurzel_vergessen","3,6":"wurzel_gliedweise","3.6":"wurzel_gliedweise","3,6 m":"wurzel_gliedweise","3,6m":"wurzel_gliedweise"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 pyth-anwendung-06 · Anwendung · Leiterfuß näher an die Wand rücken
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dc3376fa-bda3-4f10-9656-a9d234fca69f'::uuid, 'exercise', 'Anwendung · Leiterfuß näher an die Wand rücken', 'Eine 4 m lange Leiter lehnt an einer senkrechten Wand und reicht bis in 3,60 m Höhe. Sie soll bis in 3,80 m Höhe reichen.

Um wie viele Zentimeter muss ihr Fuß dafür näher an die Wand gerückt werden? Runde auf ganze Zentimeter.',
  '{"kind":"short_input","prompt":"Eine 4 m lange Leiter lehnt an einer senkrechten Wand und reicht bis in 3,60 m Höhe. Sie soll bis in 3,80 m Höhe reichen.\n\nUm wie viele Zentimeter muss ihr Fuß dafür näher an die Wand gerückt werden? Runde auf ganze Zentimeter."}'::jsonb, 'NUMERIC', 'geo_pythagoras_anwendung',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'cm', false, null, 'draft', 'edvance_k9_pythagoras', 'pyth-anwendung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: zwei Lagen der Leiter je mit dem Satz des Pythagoras berechnen, den Unterschied bilden und umrechnen.","charge":"k9-pythagoras"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-pythagoras"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).","charge":"k9-pythagoras"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.","charge":"k9-pythagoras"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).","charge":"k9-pythagoras"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-pythagoras"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-pythagoras"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-pythagoras"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-pythagoras"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, zu_frueh_gerundet, hypotenuse_verwechselt).","charge":"k9-pythagoras"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-pythagoras"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'dc3376fa-bda3-4f10-9656-a9d234fca69f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_pythagoras')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dc3376fa-bda3-4f10-9656-a9d234fca69f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'dc3376fa-bda3-4f10-9656-a9d234fca69f'::uuid,
  p_correct_answers => '["49","49 cm","49cm"]'::jsonb,
  p_solution        => 'Abstand vorher: √(4² − 3,6²) = √(16 − 12,96) = √3,04 ≈ 1,7436 m.
Abstand nachher: √(4² − 3,8²) = √(16 − 14,44) = √1,56 ≈ 1,2490 m.
Unterschied: 1,7436 m − 1,2490 m ≈ 0,4946 m ≈ 49 cm.
(Erst am Ende runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den neuen Abstand des Fußes angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel der Fuß gerückt wird – was fehlt noch?"},{"error":"Die Abstände vorher auf 1,7 m und 1,2 m gerundet: 50 cm.","socratic_question":"Was passiert mit dem Unterschied, wenn du die Abstände vorher rundest?"},{"error":"Für die Abstände die Quadrate addiert statt subtrahiert.","socratic_question":"Kann der Abstand am Boden länger sein als die Leiter?"}]'::jsonb,
  p_acceptance      => '{"canonical":"49","equivalents":["49 cm","49cm"],"known_errors":{"14":"hypotenuse_verwechselt","50":"zu_frueh_gerundet","125":"falsche_groesse_beantwortet","125 cm":"falsche_groesse_beantwortet","125cm":"falsche_groesse_beantwortet","50 cm":"zu_frueh_gerundet","50cm":"zu_frueh_gerundet","14 cm":"hypotenuse_verwechselt","14cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;
