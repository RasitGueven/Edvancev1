-- K8 Flaechen, Migration 2 von 2 — 30 Aufgaben, je sechs zu den fuenf geo_flaeche_*-Knoten (Geo-8).
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-flaeche.json (Quelle: tools/k8-flaeche-aufgaben.mjs,
-- tools/k8-flaeche-aufgaben-2.mjs und tools/k8-flaeche-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003104945_substrat_k8_flaeche.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendungen mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Dachfläche, Grundstück, Papierdrachen, Fliesen, Garten, Giebelwand, Terrasse, Beet, Segel). Keine Abbildungen: jede Figur ist mit allen Maßen und ihrer Lage im Text beschrieben. Flächenterme als MC (falsche Optionen → Fehlbild) oder NUMERIC (Term aufstellen und auswerten), nie TERM. Keine Hinweise, keine Personen.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-flaeche.csv. Pruefprotokoll: docs/prefill/k8-flaeche-verifikation.md.
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
--   geo_flaeche_trapez: flaeche-trapez-04 = 1, flaeche-trapez-03 = 2. Rang 1 aus Profil {halbieren_vergessen,klammer_vergessen,nur_eine_grundseite}, Rang 2 aus Profil {falsche_hoehe,halbieren_vergessen,nur_eine_grundseite} (1 neue Fehlbilder)
--   geo_flaeche_drachen_raute: flaeche-raute-03 = 1, flaeche-drachen-04 = 2. Rang 1 aus Profil {falsche_hoehe,halbieren_vergessen,umfang_statt_flaeche}, Rang 2 aus Profil {halbieren_vergessen,plus_statt_mal} (1 neue Fehlbilder)
--   geo_flaeche_zusammengesetzt: flaeche-zus-04 = 1, flaeche-zus-03 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,halbieren_vergessen,teilflaeche_vergessen}, Rang 2 aus Profil {halbieren_vergessen,nur_eine_grundseite,teilflaeche_vergessen} (1 neue Fehlbilder)
--   geo_flaeche_term: flaeche-term-02 = 1, flaeche-term-03 = 2. Rang 1 aus Profil {klammer_vergessen,plus_statt_mal,umfang_statt_flaeche}, Rang 2 aus Profil {halbieren_vergessen,klammer_vergessen,plus_statt_mal} (1 neue Fehlbilder)
--   geo_flaeche_rueck: flaeche-rueck-06 = 1, flaeche-rueck-04 = 2. Rang 1 aus Profil {falsche_gegenoperation,halbieren_vergessen}, Rang 2 aus Profil {falsche_groesse_beantwortet,nur_eine_grundseite} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 flaeche-trapez-01 · Trapez · a = 8 cm, c = 4 cm, h = 5 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4bfe5d6e-3f3b-4a91-964c-6eb3f4157273'::uuid, 'exercise', 'Trapez · a = 8 cm, c = 4 cm, h = 5 cm', 'Ein Trapez hat die parallelen Seiten a = 8 cm und c = 4 cm und die Höhe h = 5 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein Trapez hat die parallelen Seiten a = 8 cm und c = 4 cm und die Höhe h = 5 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Trapezformel mit ganzen Zahlen, Mittelwert der Grundseiten ganzzahlig.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4bfe5d6e-3f3b-4a91-964c-6eb3f4157273'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4bfe5d6e-3f3b-4a91-964c-6eb3f4157273'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4bfe5d6e-3f3b-4a91-964c-6eb3f4157273'::uuid,
  p_correct_answers => '["30","+30","30 cm²","30cm²","+30 cm²","+30cm²"]'::jsonb,
  p_solution        => 'A = (a + c) : 2 · h = (8 cm + 4 cm) : 2 · 5 cm = 6 cm · 5 cm = 30 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der Seite a gerechnet: 8 · 5 = 40.","socratic_question":"Welche beiden Seiten des Trapezes sind parallel – und kommen beide in deiner Rechnung vor?"},{"error":"Nur mit der Seite c gerechnet: 4 · 5 = 20.","socratic_question":"Welche beiden Seiten des Trapezes sind parallel – und kommen beide in deiner Rechnung vor?"},{"error":"Die Summe der parallelen Seiten nicht halbiert: 12 · 5 = 60.","socratic_question":"Wie viel ist der Mittelwert von 8 cm und 4 cm?"}]'::jsonb,
  p_acceptance      => '{"canonical":"30","equivalents":["+30","30 cm²","30cm²","+30 cm²","+30cm²"],"known_errors":{"20":"nur_eine_grundseite","40":"nur_eine_grundseite","60":"halbieren_vergessen","+40":"nur_eine_grundseite","40 cm²":"nur_eine_grundseite","40cm²":"nur_eine_grundseite","+40 cm²":"nur_eine_grundseite","+40cm²":"nur_eine_grundseite","+20":"nur_eine_grundseite","20 cm²":"nur_eine_grundseite","20cm²":"nur_eine_grundseite","+20 cm²":"nur_eine_grundseite","+20cm²":"nur_eine_grundseite","+60":"halbieren_vergessen","60 cm²":"halbieren_vergessen","60cm²":"halbieren_vergessen","+60 cm²":"halbieren_vergessen","+60cm²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 flaeche-trapez-02 · Trapez · a = 10 cm, c = 6 cm, h = 7 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f1ecd67e-e9b9-4aed-9604-cf9dbf8826f5'::uuid, 'exercise', 'Trapez · a = 10 cm, c = 6 cm, h = 7 cm', 'Ein Trapez hat die parallelen Seiten a = 10 cm und c = 6 cm und die Höhe h = 7 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein Trapez hat die parallelen Seiten a = 10 cm und c = 6 cm und die Höhe h = 7 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Trapezformel mit ganzen Zahlen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen, klammer_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f1ecd67e-e9b9-4aed-9604-cf9dbf8826f5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f1ecd67e-e9b9-4aed-9604-cf9dbf8826f5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f1ecd67e-e9b9-4aed-9604-cf9dbf8826f5'::uuid,
  p_correct_answers => '["56","+56","56 cm²","56cm²","+56 cm²","+56cm²"]'::jsonb,
  p_solution        => 'A = (a + c) : 2 · h = (10 cm + 6 cm) : 2 · 7 cm = 8 cm · 7 cm = 56 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der Seite a gerechnet: 10 · 7 = 70.","socratic_question":"Ist ein Trapez ein Parallelogramm, bei dem eine Seite reicht?"},{"error":"Nur mit der Seite c gerechnet: 6 · 7 = 42.","socratic_question":"Ist ein Trapez ein Parallelogramm, bei dem eine Seite reicht?"},{"error":"Die Summe der parallelen Seiten nicht halbiert: 16 · 7 = 112.","socratic_question":"Wäre ein Rechteck mit 10 cm Länge und 7 cm Breite größer oder kleiner als dein Ergebnis?"},{"error":"Ohne Klammer gerechnet: 10 + 6 : 2 · 7 = 10 + 21 = 31.","socratic_question":"Welche Rechnung muss zuerst passieren, damit beide Seiten halbiert werden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"56","equivalents":["+56","56 cm²","56cm²","+56 cm²","+56cm²"],"known_errors":{"31":"klammer_vergessen","42":"nur_eine_grundseite","70":"nur_eine_grundseite","112":"halbieren_vergessen","+70":"nur_eine_grundseite","70 cm²":"nur_eine_grundseite","70cm²":"nur_eine_grundseite","+70 cm²":"nur_eine_grundseite","+70cm²":"nur_eine_grundseite","+42":"nur_eine_grundseite","42 cm²":"nur_eine_grundseite","42cm²":"nur_eine_grundseite","+42 cm²":"nur_eine_grundseite","+42cm²":"nur_eine_grundseite","+112":"halbieren_vergessen","112 cm²":"halbieren_vergessen","112cm²":"halbieren_vergessen","+112 cm²":"halbieren_vergessen","+112cm²":"halbieren_vergessen","+31":"klammer_vergessen","31 cm²":"klammer_vergessen","31cm²":"klammer_vergessen","+31 cm²":"klammer_vergessen","+31cm²":"klammer_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 flaeche-trapez-03 · Trapez · gleichschenklig, Schenkel als Ablenker
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5c219db6-804b-4819-b671-9cb512ab1b0b'::uuid, 'exercise', 'Trapez · gleichschenklig, Schenkel als Ablenker', 'Ein gleichschenkliges Trapez hat die parallelen Seiten a = 11 cm und c = 5 cm. Die beiden Schenkel sind je 5 cm lang, die Höhe beträgt h = 4 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein gleichschenkliges Trapez hat die parallelen Seiten a = 11 cm und c = 5 cm. Die beiden Schenkel sind je 5 cm lang, die Höhe beträgt h = 4 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Die Schenkellänge ist angegeben, aber nicht die Höhe; die richtige Länge muss ausgewählt werden.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_hoehe, nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5c219db6-804b-4819-b671-9cb512ab1b0b'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5c219db6-804b-4819-b671-9cb512ab1b0b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5c219db6-804b-4819-b671-9cb512ab1b0b'::uuid,
  p_correct_answers => '["32","+32","32 cm²","32cm²","+32 cm²","+32cm²"]'::jsonb,
  p_solution        => 'Die Schenkel stehen schräg, gebraucht wird die Höhe h = 4 cm.
A = (11 cm + 5 cm) : 2 · 4 cm = 8 cm · 4 cm = 32 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Schenkellänge statt der Höhe eingesetzt: 8 · 5 = 40.","socratic_question":"Steht ein Schenkel senkrecht auf den parallelen Seiten?"},{"error":"Nur mit der Seite a gerechnet: 11 · 4 = 44.","socratic_question":"Welche beiden Seiten sind parallel – und kommen beide in deiner Rechnung vor?"},{"error":"Nur mit der Seite c gerechnet: 5 · 4 = 20.","socratic_question":"Welche beiden Seiten sind parallel – und kommen beide in deiner Rechnung vor?"},{"error":"Die Summe der parallelen Seiten nicht halbiert: 16 · 4 = 64.","socratic_question":"Wie viel ist der Mittelwert von 11 cm und 5 cm?"}]'::jsonb,
  p_acceptance      => '{"canonical":"32","equivalents":["+32","32 cm²","32cm²","+32 cm²","+32cm²"],"known_errors":{"20":"nur_eine_grundseite","40":"falsche_hoehe","44":"nur_eine_grundseite","64":"halbieren_vergessen","+40":"falsche_hoehe","40 cm²":"falsche_hoehe","40cm²":"falsche_hoehe","+40 cm²":"falsche_hoehe","+40cm²":"falsche_hoehe","+44":"nur_eine_grundseite","44 cm²":"nur_eine_grundseite","44cm²":"nur_eine_grundseite","+44 cm²":"nur_eine_grundseite","+44cm²":"nur_eine_grundseite","+20":"nur_eine_grundseite","20 cm²":"nur_eine_grundseite","20cm²":"nur_eine_grundseite","+20 cm²":"nur_eine_grundseite","+20cm²":"nur_eine_grundseite","+64":"halbieren_vergessen","64 cm²":"halbieren_vergessen","64cm²":"halbieren_vergessen","+64 cm²":"halbieren_vergessen","+64cm²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 flaeche-trapez-04 · Trapez · Dezimalmaße
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ffcbb7db-a7ab-4718-8e19-351a74a056c0'::uuid, 'exercise', 'Trapez · Dezimalmaße', 'Ein Trapez hat die parallelen Seiten a = 6,5 cm und c = 3,5 cm und die Höhe h = 4,2 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein Trapez hat die parallelen Seiten a = 6,5 cm und c = 3,5 cm und die Höhe h = 4,2 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 1, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Trapezformel mit Dezimalzahlen, Produkt mit einer Dezimalstelle.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen, klammer_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ffcbb7db-a7ab-4718-8e19-351a74a056c0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ffcbb7db-a7ab-4718-8e19-351a74a056c0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ffcbb7db-a7ab-4718-8e19-351a74a056c0'::uuid,
  p_correct_answers => '["21","+21","21 cm²","21cm²","+21 cm²","+21cm²"]'::jsonb,
  p_solution        => 'A = (6,5 cm + 3,5 cm) : 2 · 4,2 cm = 5 cm · 4,2 cm = 21 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der Seite a gerechnet: 6,5 · 4,2 = 27,3.","socratic_question":"Kommen beide parallelen Seiten in deiner Rechnung vor?"},{"error":"Nur mit der Seite c gerechnet: 3,5 · 4,2 = 14,7.","socratic_question":"Kommen beide parallelen Seiten in deiner Rechnung vor?"},{"error":"Die Summe der parallelen Seiten nicht halbiert: 10 · 4,2 = 42.","socratic_question":"Wie viel ist der Mittelwert von 6,5 cm und 3,5 cm?"},{"error":"Ohne Klammer gerechnet: 6,5 + 3,5 : 2 · 4,2 = 6,5 + 7,35 = 13,85.","socratic_question":"Wird bei dir die Seite a überhaupt halbiert und mit der Höhe malgenommen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"21","equivalents":["+21","21 cm²","21cm²","+21 cm²","+21cm²"],"known_errors":{"42":"halbieren_vergessen","27,3":"nur_eine_grundseite","+27,3":"nur_eine_grundseite","27.3":"nur_eine_grundseite","+27.3":"nur_eine_grundseite","27,3 cm²":"nur_eine_grundseite","27,3cm²":"nur_eine_grundseite","+27,3 cm²":"nur_eine_grundseite","+27,3cm²":"nur_eine_grundseite","27.3 cm²":"nur_eine_grundseite","27.3cm²":"nur_eine_grundseite","+27.3 cm²":"nur_eine_grundseite","+27.3cm²":"nur_eine_grundseite","14,7":"nur_eine_grundseite","+14,7":"nur_eine_grundseite","14.7":"nur_eine_grundseite","+14.7":"nur_eine_grundseite","14,7 cm²":"nur_eine_grundseite","14,7cm²":"nur_eine_grundseite","+14,7 cm²":"nur_eine_grundseite","+14,7cm²":"nur_eine_grundseite","14.7 cm²":"nur_eine_grundseite","14.7cm²":"nur_eine_grundseite","+14.7 cm²":"nur_eine_grundseite","+14.7cm²":"nur_eine_grundseite","+42":"halbieren_vergessen","42 cm²":"halbieren_vergessen","42cm²":"halbieren_vergessen","+42 cm²":"halbieren_vergessen","+42cm²":"halbieren_vergessen","13,85":"klammer_vergessen","+13,85":"klammer_vergessen","13.85":"klammer_vergessen","+13.85":"klammer_vergessen","13,85 cm²":"klammer_vergessen","13,85cm²":"klammer_vergessen","+13,85 cm²":"klammer_vergessen","+13,85cm²":"klammer_vergessen","13.85 cm²":"klammer_vergessen","13.85cm²":"klammer_vergessen","+13.85 cm²":"klammer_vergessen","+13.85cm²":"klammer_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 flaeche-trapez-05 · Trapez · Sachkontext · Dachfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fd558d3f-2e73-450f-a8e7-7c989eb1b314'::uuid, 'exercise', 'Trapez · Sachkontext · Dachfläche', 'Eine Dachfläche hat die Form eines Trapezes. Die untere Dachkante ist 12 m lang, die obere Dachkante 8 m. Beide Kanten sind parallel, ihr Abstand auf der Dachfläche beträgt 5 m.

Wie groß ist die Dachfläche?',
  '{"kind":"short_input","prompt":"Eine Dachfläche hat die Form eines Trapezes. Die untere Dachkante ist 12 m lang, die obere Dachkante 8 m. Beide Kanten sind parallel, ihr Abstand auf der Dachfläche beträgt 5 m.\n\nWie groß ist die Dachfläche?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: parallele Kanten und Abstand als a, c und h erkennen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fd558d3f-2e73-450f-a8e7-7c989eb1b314'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fd558d3f-2e73-450f-a8e7-7c989eb1b314'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fd558d3f-2e73-450f-a8e7-7c989eb1b314'::uuid,
  p_correct_answers => '["50","+50","50 m²","50m²","+50 m²","+50m²"]'::jsonb,
  p_solution        => 'a = 12 m, c = 8 m, h = 5 m.
A = (12 m + 8 m) : 2 · 5 m = 10 m · 5 m = 50 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der unteren Kante gerechnet: 12 · 5 = 60.","socratic_question":"Ist das Dach oben genauso breit wie unten?"},{"error":"Nur mit der oberen Kante gerechnet: 8 · 5 = 40.","socratic_question":"Ist das Dach unten genauso breit wie oben?"},{"error":"Die Summe der Kanten nicht halbiert: 20 · 5 = 100.","socratic_question":"Kann das Dach größer sein als ein Rechteck mit 12 m und 5 m?"}]'::jsonb,
  p_acceptance      => '{"canonical":"50","equivalents":["+50","50 m²","50m²","+50 m²","+50m²"],"known_errors":{"40":"nur_eine_grundseite","60":"nur_eine_grundseite","100":"halbieren_vergessen","+60":"nur_eine_grundseite","60 m²":"nur_eine_grundseite","60m²":"nur_eine_grundseite","+60 m²":"nur_eine_grundseite","+60m²":"nur_eine_grundseite","+40":"nur_eine_grundseite","40 m²":"nur_eine_grundseite","40m²":"nur_eine_grundseite","+40 m²":"nur_eine_grundseite","+40m²":"nur_eine_grundseite","+100":"halbieren_vergessen","100 m²":"halbieren_vergessen","100m²":"halbieren_vergessen","+100 m²":"halbieren_vergessen","+100m²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 flaeche-trapez-06 · Trapez · Sachkontext · Grundstückspreis
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '94fcae6b-947a-4db7-ab54-b4f13cc48c9b'::uuid, 'exercise', 'Trapez · Sachkontext · Grundstückspreis', 'Ein Grundstück hat die Form eines Trapezes. Die beiden parallelen Grundstücksseiten sind 32 m und 24 m lang, ihr Abstand beträgt 18 m. Ein Quadratmeter kostet 150 €.

Wie viel kostet das Grundstück?',
  '{"kind":"short_input","prompt":"Ein Grundstück hat die Form eines Trapezes. Die beiden parallelen Grundstücksseiten sind 32 m und 24 m lang, ihr Abstand beträgt 18 m. Ein Quadratmeter kostet 150 €.\n\nWie viel kostet das Grundstück?"}'::jsonb, 'NUMERIC', 'geo_flaeche_trapez',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, '€', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-trapez-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Trapezfläche und anschließend Preis, zwei Schritte.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '94fcae6b-947a-4db7-ab54-b4f13cc48c9b'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '94fcae6b-947a-4db7-ab54-b4f13cc48c9b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '94fcae6b-947a-4db7-ab54-b4f13cc48c9b'::uuid,
  p_correct_answers => '["75600","+75600","75600,00","+75600,00","75600.00","+75600.00","75600 €","75600€","+75600 €","+75600€","75600,00 €","75600,00€","+75600,00 €","+75600,00€","75600.00 €","75600.00€","+75600.00 €","+75600.00€"]'::jsonb,
  p_solution        => 'A = (32 m + 24 m) : 2 · 18 m = 28 m · 18 m = 504 m².
Preis = 504 · 150 € = 75600 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der längeren Seite gerechnet: 32 · 18 = 576 m², 576 · 150 € = 86400 €.","socratic_question":"Ist das Grundstück auf beiden parallelen Seiten gleich breit?"},{"error":"Nur mit der kürzeren Seite gerechnet: 24 · 18 = 432 m², 432 · 150 € = 64800 €.","socratic_question":"Ist das Grundstück auf beiden parallelen Seiten gleich breit?"},{"error":"Die Summe der Seiten nicht halbiert: 1008 m², 1008 · 150 € = 151200 €.","socratic_question":"Wie viel ist der Mittelwert von 32 m und 24 m?"}]'::jsonb,
  p_acceptance      => '{"canonical":"75600","equivalents":["+75600","75600,00","+75600,00","75600.00","+75600.00","75600 €","75600€","+75600 €","+75600€","75600,00 €","75600,00€","+75600,00 €","+75600,00€","75600.00 €","75600.00€","+75600.00 €","+75600.00€"],"known_errors":{"64800":"nur_eine_grundseite","86400":"nur_eine_grundseite","151200":"halbieren_vergessen","+86400":"nur_eine_grundseite","86400,00":"nur_eine_grundseite","+86400,00":"nur_eine_grundseite","86400.00":"nur_eine_grundseite","+86400.00":"nur_eine_grundseite","86400 €":"nur_eine_grundseite","86400€":"nur_eine_grundseite","+86400 €":"nur_eine_grundseite","+86400€":"nur_eine_grundseite","86400,00 €":"nur_eine_grundseite","86400,00€":"nur_eine_grundseite","+86400,00 €":"nur_eine_grundseite","+86400,00€":"nur_eine_grundseite","86400.00 €":"nur_eine_grundseite","86400.00€":"nur_eine_grundseite","+86400.00 €":"nur_eine_grundseite","+86400.00€":"nur_eine_grundseite","+64800":"nur_eine_grundseite","64800,00":"nur_eine_grundseite","+64800,00":"nur_eine_grundseite","64800.00":"nur_eine_grundseite","+64800.00":"nur_eine_grundseite","64800 €":"nur_eine_grundseite","64800€":"nur_eine_grundseite","+64800 €":"nur_eine_grundseite","+64800€":"nur_eine_grundseite","64800,00 €":"nur_eine_grundseite","64800,00€":"nur_eine_grundseite","+64800,00 €":"nur_eine_grundseite","+64800,00€":"nur_eine_grundseite","64800.00 €":"nur_eine_grundseite","64800.00€":"nur_eine_grundseite","+64800.00 €":"nur_eine_grundseite","+64800.00€":"nur_eine_grundseite","+151200":"halbieren_vergessen","151200,00":"halbieren_vergessen","+151200,00":"halbieren_vergessen","151200.00":"halbieren_vergessen","+151200.00":"halbieren_vergessen","151200 €":"halbieren_vergessen","151200€":"halbieren_vergessen","+151200 €":"halbieren_vergessen","+151200€":"halbieren_vergessen","151200,00 €":"halbieren_vergessen","151200,00€":"halbieren_vergessen","+151200,00 €":"halbieren_vergessen","+151200,00€":"halbieren_vergessen","151200.00 €":"halbieren_vergessen","151200.00€":"halbieren_vergessen","+151200.00 €":"halbieren_vergessen","+151200.00€":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 flaeche-drachen-01 · Drachenviereck · e = 8 cm, f = 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c1440c89-6139-41c2-9aac-6f65cf638e2f'::uuid, 'exercise', 'Drachenviereck · e = 8 cm, f = 6 cm', 'Ein Drachenviereck hat die Diagonalen e = 8 cm und f = 6 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein Drachenviereck hat die Diagonalen e = 8 cm und f = 6 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-drachen-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Formel A = e · f : 2 mit ganzen Zahlen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c1440c89-6139-41c2-9aac-6f65cf638e2f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c1440c89-6139-41c2-9aac-6f65cf638e2f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c1440c89-6139-41c2-9aac-6f65cf638e2f'::uuid,
  p_correct_answers => '["24","+24","24 cm²","24cm²","+24 cm²","+24cm²"]'::jsonb,
  p_solution        => 'A = e · f : 2 = 8 cm · 6 cm : 2 = 48 cm² : 2 = 24 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 8 · 6 = 48 ist das umschließende Rechteck.","socratic_question":"Füllt der Drachen das Rechteck aus den beiden Diagonalen ganz aus?"},{"error":"Die Diagonalen addiert: 8 + 6 = 14.","socratic_question":"Kommt bei einer Summe von Längen eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"24","equivalents":["+24","24 cm²","24cm²","+24 cm²","+24cm²"],"known_errors":{"14":"plus_statt_mal","48":"halbieren_vergessen","+48":"halbieren_vergessen","48 cm²":"halbieren_vergessen","48cm²":"halbieren_vergessen","+48 cm²":"halbieren_vergessen","+48cm²":"halbieren_vergessen","+14":"plus_statt_mal","14 cm²":"plus_statt_mal","14cm²":"plus_statt_mal","+14 cm²":"plus_statt_mal","+14cm²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 flaeche-raute-02 · Raute · e = 10 cm, f = 7 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f8054c53-9d2a-4d33-88b4-c3086fa96bfd'::uuid, 'exercise', 'Raute · e = 10 cm, f = 7 cm', 'Eine Raute hat die Diagonalen e = 10 cm und f = 7 cm.

Wie groß ist ihr Flächeninhalt?',
  '{"kind":"short_input","prompt":"Eine Raute hat die Diagonalen e = 10 cm und f = 7 cm.\n\nWie groß ist ihr Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-raute-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Formel A = e · f : 2 mit ganzen Zahlen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f8054c53-9d2a-4d33-88b4-c3086fa96bfd'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f8054c53-9d2a-4d33-88b4-c3086fa96bfd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f8054c53-9d2a-4d33-88b4-c3086fa96bfd'::uuid,
  p_correct_answers => '["35","+35","35 cm²","35cm²","+35 cm²","+35cm²"]'::jsonb,
  p_solution        => 'A = e · f : 2 = 10 cm · 7 cm : 2 = 70 cm² : 2 = 35 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 10 · 7 = 70 ist das umschließende Rechteck.","socratic_question":"Welcher Teil des Rechtecks aus den Diagonalen gehört zur Raute?"},{"error":"Die Diagonalen addiert: 10 + 7 = 17.","socratic_question":"Kommt bei einer Summe von Längen eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"35","equivalents":["+35","35 cm²","35cm²","+35 cm²","+35cm²"],"known_errors":{"17":"plus_statt_mal","70":"halbieren_vergessen","+70":"halbieren_vergessen","70 cm²":"halbieren_vergessen","70cm²":"halbieren_vergessen","+70 cm²":"halbieren_vergessen","+70cm²":"halbieren_vergessen","+17":"plus_statt_mal","17 cm²":"plus_statt_mal","17cm²":"plus_statt_mal","+17 cm²":"plus_statt_mal","+17cm²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 flaeche-raute-03 · Raute · Seitenlänge als Ablenker
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6274f6a5-65e5-40f4-be09-36fa8931c424'::uuid, 'exercise', 'Raute · Seitenlänge als Ablenker', 'Eine Raute hat die Seitenlänge 13 cm. Ihre Diagonalen sind e = 24 cm und f = 10 cm lang.

Wie groß ist ihr Flächeninhalt?',
  '{"kind":"short_input","prompt":"Eine Raute hat die Seitenlänge 13 cm. Ihre Diagonalen sind e = 24 cm und f = 10 cm lang.\n\nWie groß ist ihr Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 1, 'draft', 'edvance_k8_flaeche', 'flaeche-raute-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Seitenlänge ist gegeben, aber nicht nötig; die Diagonalen müssen ausgewählt werden.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_hoehe, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6274f6a5-65e5-40f4-be09-36fa8931c424'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6274f6a5-65e5-40f4-be09-36fa8931c424'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6274f6a5-65e5-40f4-be09-36fa8931c424'::uuid,
  p_correct_answers => '["120","+120","120 cm²","120cm²","+120 cm²","+120cm²"]'::jsonb,
  p_solution        => 'Die Seitenlänge wird nicht gebraucht.
A = e · f : 2 = 24 cm · 10 cm : 2 = 240 cm² : 2 = 120 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 24 · 10 = 240.","socratic_question":"Füllt die Raute das Rechteck aus den beiden Diagonalen ganz aus?"},{"error":"Die Seite als Höhe genommen: 13 · 13 = 169, als wäre die Raute ein Quadrat.","socratic_question":"Steht bei einer Raute eine Seite senkrecht auf der anderen?"},{"error":"Den Umfang berechnet: 4 · 13 = 52.","socratic_question":"Ist nach der Randlänge oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"120","equivalents":["+120","120 cm²","120cm²","+120 cm²","+120cm²"],"known_errors":{"52":"umfang_statt_flaeche","169":"falsche_hoehe","240":"halbieren_vergessen","+240":"halbieren_vergessen","240 cm²":"halbieren_vergessen","240cm²":"halbieren_vergessen","+240 cm²":"halbieren_vergessen","+240cm²":"halbieren_vergessen","+169":"falsche_hoehe","169 cm²":"falsche_hoehe","169cm²":"falsche_hoehe","+169 cm²":"falsche_hoehe","+169cm²":"falsche_hoehe","+52":"umfang_statt_flaeche","52 cm²":"umfang_statt_flaeche","52cm²":"umfang_statt_flaeche","+52 cm²":"umfang_statt_flaeche","+52cm²":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 flaeche-drachen-04 · Drachenviereck · Dezimalmaße
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ef5c0139-1f43-4f58-9395-11b5e84364d0'::uuid, 'exercise', 'Drachenviereck · Dezimalmaße', 'Ein Drachenviereck hat die Diagonalen e = 7,5 cm und f = 4,8 cm.

Wie groß ist sein Flächeninhalt?',
  '{"kind":"short_input","prompt":"Ein Drachenviereck hat die Diagonalen e = 7,5 cm und f = 4,8 cm.\n\nWie groß ist sein Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k8_flaeche', 'flaeche-drachen-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Produkt zweier Dezimalzahlen, dann halbieren.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ef5c0139-1f43-4f58-9395-11b5e84364d0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ef5c0139-1f43-4f58-9395-11b5e84364d0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ef5c0139-1f43-4f58-9395-11b5e84364d0'::uuid,
  p_correct_answers => '["18","+18","18 cm²","18cm²","+18 cm²","+18cm²"]'::jsonb,
  p_solution        => 'A = e · f : 2 = 7,5 cm · 4,8 cm : 2 = 36 cm² : 2 = 18 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 7,5 · 4,8 = 36.","socratic_question":"Füllt der Drachen das Rechteck aus den beiden Diagonalen ganz aus?"},{"error":"Die Diagonalen addiert: 7,5 + 4,8 = 12,3.","socratic_question":"Kommt bei einer Summe von Längen eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"18","equivalents":["+18","18 cm²","18cm²","+18 cm²","+18cm²"],"known_errors":{"36":"halbieren_vergessen","+36":"halbieren_vergessen","36 cm²":"halbieren_vergessen","36cm²":"halbieren_vergessen","+36 cm²":"halbieren_vergessen","+36cm²":"halbieren_vergessen","12,3":"plus_statt_mal","+12,3":"plus_statt_mal","12.3":"plus_statt_mal","+12.3":"plus_statt_mal","12,3 cm²":"plus_statt_mal","12,3cm²":"plus_statt_mal","+12,3 cm²":"plus_statt_mal","+12,3cm²":"plus_statt_mal","12.3 cm²":"plus_statt_mal","12.3cm²":"plus_statt_mal","+12.3 cm²":"plus_statt_mal","+12.3cm²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 flaeche-drachen-05 · Drachen · Sachkontext · Papierdrachen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7cfb5d9f-a6d9-48d5-85e1-d470eee978c7'::uuid, 'exercise', 'Drachen · Sachkontext · Papierdrachen', 'Ein Drachen aus Papier hat die Form eines Drachenvierecks. Seine beiden Holzstäbe bilden die Diagonalen: Der Längsstab ist 90 cm lang, der Querstab 60 cm.

Wie groß ist die Fläche des Drachens?',
  '{"kind":"short_input","prompt":"Ein Drachen aus Papier hat die Form eines Drachenvierecks. Seine beiden Holzstäbe bilden die Diagonalen: Der Längsstab ist 90 cm lang, der Querstab 60 cm.\n\nWie groß ist die Fläche des Drachens?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-drachen-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Holzstäbe als Diagonalen erkennen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7cfb5d9f-a6d9-48d5-85e1-d470eee978c7'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7cfb5d9f-a6d9-48d5-85e1-d470eee978c7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7cfb5d9f-a6d9-48d5-85e1-d470eee978c7'::uuid,
  p_correct_answers => '["2700","+2700","2700 cm²","2700cm²","+2700 cm²","+2700cm²"]'::jsonb,
  p_solution        => 'Die Stäbe sind die Diagonalen: e = 90 cm, f = 60 cm.
A = 90 cm · 60 cm : 2 = 5400 cm² : 2 = 2700 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 90 · 60 = 5400 ist das Rechteck um den Drachen.","socratic_question":"Füllt der Drachen das Rechteck aus Längsstab und Querstab ganz aus?"},{"error":"Die Stablängen addiert: 90 + 60 = 150.","socratic_question":"Kommt bei einer Summe von Längen eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2700","equivalents":["+2700","2700 cm²","2700cm²","+2700 cm²","+2700cm²"],"known_errors":{"150":"plus_statt_mal","5400":"halbieren_vergessen","+5400":"halbieren_vergessen","5400 cm²":"halbieren_vergessen","5400cm²":"halbieren_vergessen","+5400 cm²":"halbieren_vergessen","+5400cm²":"halbieren_vergessen","+150":"plus_statt_mal","150 cm²":"plus_statt_mal","150cm²":"plus_statt_mal","+150 cm²":"plus_statt_mal","+150cm²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 flaeche-raute-06 · Raute · Sachkontext · vierzig Fliesen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0802547a-2b81-4d03-8c5c-941705076285'::uuid, 'exercise', 'Raute · Sachkontext · vierzig Fliesen', 'Eine Wand wird mit 40 rautenförmigen Fliesen belegt. Jede Fliese hat die Diagonalen 20 cm und 12 cm. Die Fliesen liegen ohne Fugen aneinander.

Wie groß ist die belegte Fläche insgesamt?',
  '{"kind":"short_input","prompt":"Eine Wand wird mit 40 rautenförmigen Fliesen belegt. Jede Fliese hat die Diagonalen 20 cm und 12 cm. Die Fliesen liegen ohne Fugen aneinander.\n\nWie groß ist die belegte Fläche insgesamt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_drachen_raute',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-raute-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Rautenfläche, dann mit der Anzahl malnehmen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0802547a-2b81-4d03-8c5c-941705076285'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0802547a-2b81-4d03-8c5c-941705076285'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0802547a-2b81-4d03-8c5c-941705076285'::uuid,
  p_correct_answers => '["4800","+4800","4800 cm²","4800cm²","+4800 cm²","+4800cm²"]'::jsonb,
  p_solution        => 'Eine Fliese: A = 20 cm · 12 cm : 2 = 120 cm².
40 Fliesen: 40 · 120 cm² = 4800 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: 20 · 12 = 240 je Fliese, 40 · 240 = 9600.","socratic_question":"Ist eine Fliese so groß wie das Rechteck aus ihren beiden Diagonalen?"},{"error":"Die Diagonalen addiert: 20 + 12 = 32 je Fliese, 40 · 32 = 1280.","socratic_question":"Kommt bei einer Summe von Längen eine Fläche heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4800","equivalents":["+4800","4800 cm²","4800cm²","+4800 cm²","+4800cm²"],"known_errors":{"1280":"plus_statt_mal","9600":"halbieren_vergessen","+9600":"halbieren_vergessen","9600 cm²":"halbieren_vergessen","9600cm²":"halbieren_vergessen","+9600 cm²":"halbieren_vergessen","+9600cm²":"halbieren_vergessen","+1280":"plus_statt_mal","1280 cm²":"plus_statt_mal","1280cm²":"plus_statt_mal","+1280 cm²":"plus_statt_mal","+1280cm²":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 flaeche-zus-01 · Haus-Form · Rechteck mit aufgesetztem Dreieck
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7585618a-0557-49ed-89be-997629dfaf03'::uuid, 'exercise', 'Haus-Form · Rechteck mit aufgesetztem Dreieck', 'Eine Figur besteht aus einem Rechteck mit der Länge 8 cm und der Breite 5 cm. Auf die obere, 8 cm lange Rechteckseite ist ein Dreieck aufgesetzt: Seine Grundseite ist genau diese Rechteckseite, seine Höhe beträgt 3 cm.

Wie groß ist der Flächeninhalt der ganzen Figur?',
  '{"kind":"short_input","prompt":"Eine Figur besteht aus einem Rechteck mit der Länge 8 cm und der Breite 5 cm. Auf die obere, 8 cm lange Rechteckseite ist ein Dreieck aufgesetzt: Seine Grundseite ist genau diese Rechteckseite, seine Höhe beträgt 3 cm.\n\nWie groß ist der Flächeninhalt der ganzen Figur?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei bekannte Teilflächen addieren.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7585618a-0557-49ed-89be-997629dfaf03'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7585618a-0557-49ed-89be-997629dfaf03'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7585618a-0557-49ed-89be-997629dfaf03'::uuid,
  p_correct_answers => '["52","+52","52 cm²","52cm²","+52 cm²","+52cm²"]'::jsonb,
  p_solution        => 'Rechteck: 8 cm · 5 cm = 40 cm².
Dreieck: 8 cm · 3 cm : 2 = 12 cm².
Ganze Figur: 40 cm² + 12 cm² = 52 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur das Rechteck berechnet, das Dreieck fehlt.","socratic_question":"Gehört das aufgesetzte Dreieck zur Figur dazu?"},{"error":"Nur das Dreieck berechnet, das Rechteck fehlt.","socratic_question":"Aus welchen Teilen besteht die ganze Figur?"},{"error":"Das Dreieck nicht halbiert: 40 + 24 = 64.","socratic_question":"Ist das Dreieck so groß wie ein Rechteck mit 8 cm und 3 cm?"}]'::jsonb,
  p_acceptance      => '{"canonical":"52","equivalents":["+52","52 cm²","52cm²","+52 cm²","+52cm²"],"known_errors":{"12":"teilflaeche_vergessen","40":"teilflaeche_vergessen","64":"halbieren_vergessen","+40":"teilflaeche_vergessen","40 cm²":"teilflaeche_vergessen","40cm²":"teilflaeche_vergessen","+40 cm²":"teilflaeche_vergessen","+40cm²":"teilflaeche_vergessen","+12":"teilflaeche_vergessen","12 cm²":"teilflaeche_vergessen","12cm²":"teilflaeche_vergessen","+12 cm²":"teilflaeche_vergessen","+12cm²":"teilflaeche_vergessen","+64":"halbieren_vergessen","64 cm²":"halbieren_vergessen","64cm²":"halbieren_vergessen","+64 cm²":"halbieren_vergessen","+64cm²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 flaeche-zus-02 · L-Form · Rechteck mit ausgeschnittener Ecke
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4379159d-98dc-49fd-a6da-8e9cbc916c71'::uuid, 'exercise', 'L-Form · Rechteck mit ausgeschnittener Ecke', 'Aus einem Rechteck mit der Länge 10 cm und der Breite 8 cm wird an einer Ecke ein kleineres Rechteck mit den Seiten 4 cm und 3 cm herausgeschnitten. Übrig bleibt eine L-förmige Figur.

Wie groß ist ihr Flächeninhalt?',
  '{"kind":"short_input","prompt":"Aus einem Rechteck mit der Länge 10 cm und der Breite 8 cm wird an einer Ecke ein kleineres Rechteck mit den Seiten 4 cm und 3 cm herausgeschnitten. Übrig bleibt eine L-förmige Figur.\n\nWie groß ist ihr Flächeninhalt?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: große Rechteckfläche minus kleine Rechteckfläche.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4379159d-98dc-49fd-a6da-8e9cbc916c71'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4379159d-98dc-49fd-a6da-8e9cbc916c71'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4379159d-98dc-49fd-a6da-8e9cbc916c71'::uuid,
  p_correct_answers => '["68","+68","68 cm²","68cm²","+68 cm²","+68cm²"]'::jsonb,
  p_solution        => 'Großes Rechteck: 10 cm · 8 cm = 80 cm².
Ausschnitt: 4 cm · 3 cm = 12 cm².
L-Form: 80 cm² - 12 cm² = 68 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Ausschnitt nicht abgezogen: nur das große Rechteck.","socratic_question":"Was passiert mit der Fläche, wenn eine Ecke herausgeschnitten wird?"},{"error":"Den Umfang berechnet: 2 · (10 + 8) = 36.","socratic_question":"Ist nach der Randlänge oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"68","equivalents":["+68","68 cm²","68cm²","+68 cm²","+68cm²"],"known_errors":{"36":"umfang_statt_flaeche","80":"teilflaeche_vergessen","+80":"teilflaeche_vergessen","80 cm²":"teilflaeche_vergessen","80cm²":"teilflaeche_vergessen","+80 cm²":"teilflaeche_vergessen","+80cm²":"teilflaeche_vergessen","+36":"umfang_statt_flaeche","36 cm²":"umfang_statt_flaeche","36cm²":"umfang_statt_flaeche","+36 cm²":"umfang_statt_flaeche","+36cm²":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 flaeche-zus-03 · Rechteck mit angesetztem Trapez
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4320eb31-3cbb-4733-ab23-e15fcb60d849'::uuid, 'exercise', 'Rechteck mit angesetztem Trapez', 'Eine Figur besteht aus einem Rechteck und einem Trapez. Das Rechteck ist 6 cm lang und 4 cm breit. An eine 6 cm lange Rechteckseite ist ein Trapez so angesetzt, dass diese Seite seine längere parallele Seite ist. Die kürzere parallele Seite des Trapezes ist 2 cm lang, seine Höhe beträgt 3 cm.

Wie groß ist der Flächeninhalt der ganzen Figur?',
  '{"kind":"short_input","prompt":"Eine Figur besteht aus einem Rechteck und einem Trapez. Das Rechteck ist 6 cm lang und 4 cm breit. An eine 6 cm lange Rechteckseite ist ein Trapez so angesetzt, dass diese Seite seine längere parallele Seite ist. Die kürzere parallele Seite des Trapezes ist 2 cm lang, seine Höhe beträgt 3 cm.\n\nWie groß ist der Flächeninhalt der ganzen Figur?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zerlegung in Rechteck und Trapez, Trapezformel als Teilschritt.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4320eb31-3cbb-4733-ab23-e15fcb60d849'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4320eb31-3cbb-4733-ab23-e15fcb60d849'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4320eb31-3cbb-4733-ab23-e15fcb60d849'::uuid,
  p_correct_answers => '["36","+36","36 cm²","36cm²","+36 cm²","+36cm²"]'::jsonb,
  p_solution        => 'Rechteck: 6 cm · 4 cm = 24 cm².
Trapez: (6 cm + 2 cm) : 2 · 3 cm = 12 cm².
Ganze Figur: 24 cm² + 12 cm² = 36 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur das Rechteck berechnet, das Trapez fehlt.","socratic_question":"Gehört das angesetzte Trapez zur Figur dazu?"},{"error":"Nur das Trapez berechnet, das Rechteck fehlt.","socratic_question":"Aus welchen Teilen besteht die ganze Figur?"},{"error":"Beim Trapez nur die längere Seite genommen: 24 + 18 = 42.","socratic_question":"Welche beiden Seiten des Trapezes sind parallel?"},{"error":"Beim Trapez nur die kürzere Seite genommen: 24 + 6 = 30.","socratic_question":"Welche beiden Seiten des Trapezes sind parallel?"},{"error":"Beim Trapez nicht halbiert: 24 + 24 = 48.","socratic_question":"Wie viel ist der Mittelwert von 6 cm und 2 cm?"}]'::jsonb,
  p_acceptance      => '{"canonical":"36","equivalents":["+36","36 cm²","36cm²","+36 cm²","+36cm²"],"known_errors":{"12":"teilflaeche_vergessen","24":"teilflaeche_vergessen","30":"nur_eine_grundseite","42":"nur_eine_grundseite","48":"halbieren_vergessen","+24":"teilflaeche_vergessen","24 cm²":"teilflaeche_vergessen","24cm²":"teilflaeche_vergessen","+24 cm²":"teilflaeche_vergessen","+24cm²":"teilflaeche_vergessen","+12":"teilflaeche_vergessen","12 cm²":"teilflaeche_vergessen","12cm²":"teilflaeche_vergessen","+12 cm²":"teilflaeche_vergessen","+12cm²":"teilflaeche_vergessen","+42":"nur_eine_grundseite","42 cm²":"nur_eine_grundseite","42cm²":"nur_eine_grundseite","+42 cm²":"nur_eine_grundseite","+42cm²":"nur_eine_grundseite","+30":"nur_eine_grundseite","30 cm²":"nur_eine_grundseite","30cm²":"nur_eine_grundseite","+30 cm²":"nur_eine_grundseite","+30cm²":"nur_eine_grundseite","+48":"halbieren_vergessen","48 cm²":"halbieren_vergessen","48cm²":"halbieren_vergessen","+48 cm²":"halbieren_vergessen","+48cm²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 flaeche-zus-04 · Quadrat mit ausgeschnittener Raute
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1155ecca-ce4c-41bb-bf6c-b6fe51ee455d'::uuid, 'exercise', 'Quadrat mit ausgeschnittener Raute', 'Aus einer quadratischen Platte mit der Seitenlänge 10 cm wird in der Mitte eine Raute ausgeschnitten. Die Diagonalen der Raute sind 6 cm und 4 cm lang.

Wie groß ist der Flächeninhalt der Platte nach dem Ausschneiden?',
  '{"kind":"short_input","prompt":"Aus einer quadratischen Platte mit der Seitenlänge 10 cm wird in der Mitte eine Raute ausgeschnitten. Die Diagonalen der Raute sind 6 cm und 4 cm lang.\n\nWie groß ist der Flächeninhalt der Platte nach dem Ausschneiden?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 1, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat minus Raute, Rautenformel als Teilschritt.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, halbieren_vergessen, falsche_groesse_beantwortet).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1155ecca-ce4c-41bb-bf6c-b6fe51ee455d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1155ecca-ce4c-41bb-bf6c-b6fe51ee455d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1155ecca-ce4c-41bb-bf6c-b6fe51ee455d'::uuid,
  p_correct_answers => '["88","+88","88 cm²","88cm²","+88 cm²","+88cm²"]'::jsonb,
  p_solution        => 'Quadrat: 10 cm · 10 cm = 100 cm².
Raute: 6 cm · 4 cm : 2 = 12 cm².
Rest: 100 cm² - 12 cm² = 88 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Raute nicht abgezogen: nur das Quadrat.","socratic_question":"Was passiert mit der Fläche der Platte, wenn ein Stück herausgeschnitten wird?"},{"error":"Die Raute nicht halbiert: 100 - 24 = 76.","socratic_question":"Ist die Raute so groß wie das Rechteck aus ihren Diagonalen?"},{"error":"Die Fläche des Ausschnitts angegeben statt der Restfläche.","socratic_question":"Ist nach dem Loch oder nach der übrigen Platte gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"88","equivalents":["+88","88 cm²","88cm²","+88 cm²","+88cm²"],"known_errors":{"12":"falsche_groesse_beantwortet","76":"halbieren_vergessen","100":"teilflaeche_vergessen","+100":"teilflaeche_vergessen","100 cm²":"teilflaeche_vergessen","100cm²":"teilflaeche_vergessen","+100 cm²":"teilflaeche_vergessen","+100cm²":"teilflaeche_vergessen","+76":"halbieren_vergessen","76 cm²":"halbieren_vergessen","76cm²":"halbieren_vergessen","+76 cm²":"halbieren_vergessen","+76cm²":"halbieren_vergessen","+12":"falsche_groesse_beantwortet","12 cm²":"falsche_groesse_beantwortet","12cm²":"falsche_groesse_beantwortet","+12 cm²":"falsche_groesse_beantwortet","+12cm²":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 flaeche-zus-05 · Sachkontext · Rasen um ein dreieckiges Beet
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '00682950-b934-4ded-9d9b-c8e68ed4313d'::uuid, 'exercise', 'Sachkontext · Rasen um ein dreieckiges Beet', 'Ein rechteckiger Garten ist 12 m lang und 9 m breit. Darin liegt ein dreieckiges Beet mit der Grundseite 4 m und der zugehörigen Höhe 3 m. Der Rest des Gartens ist Rasen.

Wie groß ist die Rasenfläche?',
  '{"kind":"short_input","prompt":"Ein rechteckiger Garten ist 12 m lang und 9 m breit. Darin liegt ein dreieckiges Beet mit der Grundseite 4 m und der zugehörigen Höhe 3 m. Der Rest des Gartens ist Rasen.\n\nWie groß ist die Rasenfläche?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Rasen als Rechteck minus Dreieck erkennen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, halbieren_vergessen, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '00682950-b934-4ded-9d9b-c8e68ed4313d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '00682950-b934-4ded-9d9b-c8e68ed4313d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '00682950-b934-4ded-9d9b-c8e68ed4313d'::uuid,
  p_correct_answers => '["102","+102","102 m²","102m²","+102 m²","+102m²"]'::jsonb,
  p_solution        => 'Garten: 12 m · 9 m = 108 m².
Beet: 4 m · 3 m : 2 = 6 m².
Rasen: 108 m² - 6 m² = 102 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Beet nicht abgezogen: der ganze Garten.","socratic_question":"Ist das Beet auch Rasen?"},{"error":"Das Dreieck nicht halbiert: 108 - 12 = 96.","socratic_question":"Ist das Beet so groß wie ein Rechteck mit 4 m und 3 m?"},{"error":"Den Umfang des Gartens berechnet: 2 · (12 + 9) = 42.","socratic_question":"Ist nach dem Zaun oder nach der Rasenfläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"102","equivalents":["+102","102 m²","102m²","+102 m²","+102m²"],"known_errors":{"42":"umfang_statt_flaeche","96":"halbieren_vergessen","108":"teilflaeche_vergessen","+108":"teilflaeche_vergessen","108 m²":"teilflaeche_vergessen","108m²":"teilflaeche_vergessen","+108 m²":"teilflaeche_vergessen","+108m²":"teilflaeche_vergessen","+96":"halbieren_vergessen","96 m²":"halbieren_vergessen","96m²":"halbieren_vergessen","+96 m²":"halbieren_vergessen","+96m²":"halbieren_vergessen","+42":"umfang_statt_flaeche","42 m²":"umfang_statt_flaeche","42m²":"umfang_statt_flaeche","+42 m²":"umfang_statt_flaeche","+42m²":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 flaeche-zus-06 · Sachkontext · Giebelwand mit Fenster
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7502a1e1-ab78-4418-83f6-fd0d045ccc86'::uuid, 'exercise', 'Sachkontext · Giebelwand mit Fenster', 'Die Giebelwand eines Hauses besteht aus einem Rechteck, das 9 m breit und 6 m hoch ist, und einem darauf sitzenden Dreieck mit der Grundseite 9 m und der Höhe 4 m. In der Wand ist ein rechteckiges Fenster, 1,5 m breit und 1,2 m hoch. Das Fenster wird nicht gestrichen.

Wie viele Quadratmeter Wandfläche müssen gestrichen werden?',
  '{"kind":"short_input","prompt":"Die Giebelwand eines Hauses besteht aus einem Rechteck, das 9 m breit und 6 m hoch ist, und einem darauf sitzenden Dreieck mit der Grundseite 9 m und der Höhe 4 m. In der Wand ist ein rechteckiges Fenster, 1,5 m breit und 1,2 m hoch. Das Fenster wird nicht gestrichen.\n\nWie viele Quadratmeter Wandfläche müssen gestrichen werden?"}'::jsonb, 'NUMERIC', 'geo_flaeche_zusammengesetzt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Modellieren',
  120, 'm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-zus-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: drei Teilflächen, zwei addieren und eine abziehen, mit Dezimalzahlen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7502a1e1-ab78-4418-83f6-fd0d045ccc86'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7502a1e1-ab78-4418-83f6-fd0d045ccc86'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7502a1e1-ab78-4418-83f6-fd0d045ccc86'::uuid,
  p_correct_answers => '["70,2","+70,2","70.2","+70.2","70,2 m²","70,2m²","+70,2 m²","+70,2m²","70.2 m²","70.2m²","+70.2 m²","+70.2m²"]'::jsonb,
  p_solution        => 'Rechteck: 9 m · 6 m = 54 m².
Dreieck: 9 m · 4 m : 2 = 18 m².
Fenster: 1,5 m · 1,2 m = 1,8 m².
Zu streichen: 54 m² + 18 m² - 1,8 m² = 70,2 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Fenster nicht abgezogen: 54 + 18 = 72.","socratic_question":"Wird das Fenster mitgestrichen?"},{"error":"Das Dreieck oben vergessen: 54 - 1,8 = 52,2.","socratic_question":"Aus welchen Teilen besteht die Giebelwand?"},{"error":"Das Dreieck nicht halbiert: 54 + 36 - 1,8 = 88,2.","socratic_question":"Ist das Giebeldreieck so groß wie ein Rechteck mit 9 m und 4 m?"}]'::jsonb,
  p_acceptance      => '{"canonical":"70,2","equivalents":["+70,2","70.2","+70.2","70,2 m²","70,2m²","+70,2 m²","+70,2m²","70.2 m²","70.2m²","+70.2 m²","+70.2m²"],"known_errors":{"72":"teilflaeche_vergessen","+72":"teilflaeche_vergessen","72 m²":"teilflaeche_vergessen","72m²":"teilflaeche_vergessen","+72 m²":"teilflaeche_vergessen","+72m²":"teilflaeche_vergessen","52,2":"teilflaeche_vergessen","+52,2":"teilflaeche_vergessen","52.2":"teilflaeche_vergessen","+52.2":"teilflaeche_vergessen","52,2 m²":"teilflaeche_vergessen","52,2m²":"teilflaeche_vergessen","+52,2 m²":"teilflaeche_vergessen","+52,2m²":"teilflaeche_vergessen","52.2 m²":"teilflaeche_vergessen","52.2m²":"teilflaeche_vergessen","+52.2 m²":"teilflaeche_vergessen","+52.2m²":"teilflaeche_vergessen","88,2":"halbieren_vergessen","+88,2":"halbieren_vergessen","88.2":"halbieren_vergessen","+88.2":"halbieren_vergessen","88,2 m²":"halbieren_vergessen","88,2m²":"halbieren_vergessen","+88,2 m²":"halbieren_vergessen","+88,2m²":"halbieren_vergessen","88.2 m²":"halbieren_vergessen","88.2m²":"halbieren_vergessen","+88.2 m²":"halbieren_vergessen","+88.2m²":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 flaeche-term-01 · Term · Rechteck x mal 5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '46192474-3c40-4cec-a9de-742684e86e01'::uuid, 'exercise', 'Term · Rechteck x mal 5', 'Ein Rechteck ist x cm lang und 5 cm breit.

Welcher Term beschreibt seinen Flächeninhalt in cm²?',
  '{"options":[{"id":"a","label":"x + 5"},{"id":"b","label":"5x"},{"id":"c","label":"2x + 10"},{"id":"d","label":"x²"}],"input_type":"MC"}'::jsonb, 'MC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Darstellen, Operieren',
  45, null, false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-term-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Rechteckformel mit einer Variablen als Seitenlänge.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Flächeninhalt als Term darstellen und gleichwertige Form erkennen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Einzige Option, die als Term in x gleichwertig zum Flächenterm ist (prefill-rechnen).","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (plus_statt_mal, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '46192474-3c40-4cec-a9de-742684e86e01'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '46192474-3c40-4cec-a9de-742684e86e01'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '46192474-3c40-4cec-a9de-742684e86e01'::uuid,
  p_correct_answers => '["b"]'::jsonb,
  p_solution        => 'A = Länge · Breite = x · 5 = 5x.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Länge und Breite addiert statt multipliziert.","socratic_question":"Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?"},{"error":"Den Umfang beschrieben: 2 · (x + 5).","socratic_question":"Beschreibt dein Term die Randlänge oder die Fläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"b","known_errors":{"a":"plus_statt_mal","c":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 flaeche-term-02 · Term · Rechteck (x + 3) mal 4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '770f72e9-c73c-45fc-9803-e3b20846de70'::uuid, 'exercise', 'Term · Rechteck (x + 3) mal 4', 'Ein Rechteck ist (x + 3) cm lang und 4 cm breit.

Welcher Term beschreibt seinen Flächeninhalt in cm²?',
  '{"options":[{"id":"a","label":"4x + 3"},{"id":"b","label":"x + 7"},{"id":"c","label":"4x + 12"},{"id":"d","label":"2x + 14"}],"input_type":"MC"}'::jsonb, 'MC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Darstellen, Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_flaeche', 'flaeche-term-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Rechteckformel, die Summe als Seitenlänge muss als Ganzes multipliziert werden.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Flächeninhalt als Term darstellen und gleichwertige Form erkennen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Einzige Option, die als Term in x gleichwertig zum Flächenterm ist (prefill-rechnen).","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, plus_statt_mal, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '770f72e9-c73c-45fc-9803-e3b20846de70'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '770f72e9-c73c-45fc-9803-e3b20846de70'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '770f72e9-c73c-45fc-9803-e3b20846de70'::uuid,
  p_correct_answers => '["c"]'::jsonb,
  p_solution        => 'A = 4 · (x + 3) = 4x + 12.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer gerechnet: nur x mit 4 multipliziert.","socratic_question":"Ist die ganze Länge x + 3 mit der Breite malzunehmen oder nur das x?"},{"error":"Länge und Breite addiert: x + 3 + 4.","socratic_question":"Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?"},{"error":"Den Umfang beschrieben: 2 · (x + 3) + 2 · 4.","socratic_question":"Beschreibt dein Term die Randlänge oder die Fläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"c","known_errors":{"a":"klammer_vergessen","b":"plus_statt_mal","d":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 flaeche-term-03 · Term · Dreieck mit Grundseite x + 4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '10f112ad-b1cc-4690-8925-773ef92d20e3'::uuid, 'exercise', 'Term · Dreieck mit Grundseite x + 4', 'Ein Dreieck hat die Grundseite (x + 4) cm und die zugehörige Höhe 6 cm.

Welcher Term beschreibt seinen Flächeninhalt in cm²?',
  '{"options":[{"id":"a","label":"6x + 24"},{"id":"b","label":"3x + 12"},{"id":"c","label":"3x + 4"},{"id":"d","label":"x + 10"}],"input_type":"MC"}'::jsonb, 'MC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Darstellen, Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_flaeche', 'flaeche-term-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Dreiecksformel mit Summe als Grundseite, halbieren und ausmultiplizieren.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Flächeninhalt als Term darstellen und gleichwertige Form erkennen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Einzige Option, die als Term in x gleichwertig zum Flächenterm ist (prefill-rechnen).","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, klammer_vergessen, plus_statt_mal).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '10f112ad-b1cc-4690-8925-773ef92d20e3'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '10f112ad-b1cc-4690-8925-773ef92d20e3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '10f112ad-b1cc-4690-8925-773ef92d20e3'::uuid,
  p_correct_answers => '["b"]'::jsonb,
  p_solution        => 'A = g · h : 2 = (x + 4) · 6 : 2 = 3 · (x + 4) = 3x + 12.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht halbiert: (x + 4) · 6.","socratic_question":"Ist ein Dreieck so groß wie das Rechteck aus Grundseite und Höhe?"},{"error":"Ohne Klammer gerechnet: nur x mit 6 multipliziert und halbiert.","socratic_question":"Ist die ganze Grundseite x + 4 mit der Höhe malzunehmen oder nur das x?"},{"error":"Grundseite und Höhe addiert: x + 4 + 6.","socratic_question":"Rechnest du Grundseite und Höhe zusammen oder malgenommen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"b","known_errors":{"a":"halbieren_vergessen","c":"klammer_vergessen","d":"plus_statt_mal"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 flaeche-term-04 · Term · Rechteck mit angesetztem Quadrat
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '11390e1a-2fc1-4cf1-93da-890ac936b56a'::uuid, 'exercise', 'Term · Rechteck mit angesetztem Quadrat', 'Eine Figur besteht aus einem Rechteck und einem Quadrat. Das Rechteck ist x cm lang und 4 cm breit. An eine 4 cm lange Seite des Rechtecks ist ein Quadrat mit der Seitenlänge 4 cm angesetzt.

Welcher Term beschreibt den Flächeninhalt der ganzen Figur in cm²?',
  '{"options":[{"id":"a","label":"4x"},{"id":"b","label":"4x + 8"},{"id":"c","label":"4x + 16"},{"id":"d","label":"8x"}],"input_type":"MC"}'::jsonb, 'MC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Darstellen, Operieren',
  60, null, false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-term-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Teilflächen als Terme aufstellen und zusammenfassen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Flächeninhalt als Term darstellen und gleichwertige Form erkennen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Einzige Option, die als Term in x gleichwertig zum Flächenterm ist (prefill-rechnen).","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (teilflaeche_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '11390e1a-2fc1-4cf1-93da-890ac936b56a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '11390e1a-2fc1-4cf1-93da-890ac936b56a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '11390e1a-2fc1-4cf1-93da-890ac936b56a'::uuid,
  p_correct_answers => '["c"]'::jsonb,
  p_solution        => 'Rechteck: x · 4 = 4x.
Quadrat: 4 · 4 = 16.
Ganze Figur: 4x + 16.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur das Rechteck beschrieben, das Quadrat fehlt.","socratic_question":"Gehört das angesetzte Quadrat zur Figur dazu?"}]'::jsonb,
  p_acceptance      => '{"canonical":"c","known_errors":{"a":"teilflaeche_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 flaeche-term-05 · Term · Sachkontext · Terrasse 3 m länger als breit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '214345b8-69d2-43d4-8c1b-1e8e7c428e1d'::uuid, 'exercise', 'Term · Sachkontext · Terrasse 3 m länger als breit', 'Eine rechteckige Terrasse ist 3 m länger als breit. Ihre Breite beträgt x m.

Stelle einen Term für ihren Flächeninhalt auf und berechne den Flächeninhalt für x = 4.',
  '{"kind":"short_input","prompt":"Eine rechteckige Terrasse ist 3 m länger als breit. Ihre Breite beträgt x m.\n\nStelle einen Term für ihren Flächeninhalt auf und berechne den Flächeninhalt für x = 4."}'::jsonb, 'NUMERIC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-term-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Länge als x + 3 erkennen, Term aufstellen und auswerten.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (klammer_vergessen, plus_statt_mal, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '214345b8-69d2-43d4-8c1b-1e8e7c428e1d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '214345b8-69d2-43d4-8c1b-1e8e7c428e1d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '214345b8-69d2-43d4-8c1b-1e8e7c428e1d'::uuid,
  p_correct_answers => '["28","+28","28 m²","28m²","+28 m²","+28m²"]'::jsonb,
  p_solution        => 'Länge: x + 3, Breite: x.
A = (x + 3) · x.
Für x = 4: A = 7 · 4 = 28, also 28 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Ohne Klammer gerechnet: x + 3 · x = 4 + 12 = 16.","socratic_question":"Wird die ganze Länge x + 3 mit der Breite malgenommen?"},{"error":"Länge und Breite addiert: 7 + 4 = 11.","socratic_question":"Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?"},{"error":"Den Umfang berechnet: 2 · (7 + 4) = 22.","socratic_question":"Ist nach dem Rand der Terrasse oder nach ihrer Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"28","equivalents":["+28","28 m²","28m²","+28 m²","+28m²"],"known_errors":{"11":"plus_statt_mal","16":"klammer_vergessen","22":"umfang_statt_flaeche","+16":"klammer_vergessen","16 m²":"klammer_vergessen","16m²":"klammer_vergessen","+16 m²":"klammer_vergessen","+16m²":"klammer_vergessen","+11":"plus_statt_mal","11 m²":"plus_statt_mal","11m²":"plus_statt_mal","+11 m²":"plus_statt_mal","+11m²":"plus_statt_mal","+22":"umfang_statt_flaeche","22 m²":"umfang_statt_flaeche","22m²":"umfang_statt_flaeche","+22 m²":"umfang_statt_flaeche","+22m²":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 flaeche-term-06 · Term · Sachkontext · Beet doppelt so lang wie breit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1f27364f-e37a-4203-8097-4c3331ea9940'::uuid, 'exercise', 'Term · Sachkontext · Beet doppelt so lang wie breit', 'Ein rechteckiges Beet ist doppelt so lang wie breit. Seine Breite beträgt x m.

Stelle einen Term für den Flächeninhalt des Beetes auf und berechne ihn für x = 3,5.',
  '{"kind":"short_input","prompt":"Ein rechteckiges Beet ist doppelt so lang wie breit. Seine Breite beträgt x m.\n\nStelle einen Term für den Flächeninhalt des Beetes auf und berechne ihn für x = 3,5."}'::jsonb, 'NUMERIC', 'geo_flaeche_term',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm²', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-term-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Länge als 2x erkennen, Term 2x · x mit Dezimalzahl auswerten.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (plus_statt_mal, umfang_statt_flaeche).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1f27364f-e37a-4203-8097-4c3331ea9940'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1f27364f-e37a-4203-8097-4c3331ea9940'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1f27364f-e37a-4203-8097-4c3331ea9940'::uuid,
  p_correct_answers => '["24,5","+24,5","24.5","+24.5","24,5 m²","24,5m²","+24,5 m²","+24,5m²","24.5 m²","24.5m²","+24.5 m²","+24.5m²"]'::jsonb,
  p_solution        => 'Länge: 2x, Breite: x.
A = 2x · x = 2x².
Für x = 3,5: A = 2 · 3,5 · 3,5 = 7 · 3,5 = 24,5, also 24,5 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Länge und Breite addiert: 7 + 3,5 = 10,5.","socratic_question":"Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?"},{"error":"Den Umfang berechnet: 2 · (7 + 3,5) = 21.","socratic_question":"Ist nach dem Rand des Beetes oder nach seiner Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"24,5","equivalents":["+24,5","24.5","+24.5","24,5 m²","24,5m²","+24,5 m²","+24,5m²","24.5 m²","24.5m²","+24.5 m²","+24.5m²"],"known_errors":{"21":"umfang_statt_flaeche","10,5":"plus_statt_mal","+10,5":"plus_statt_mal","10.5":"plus_statt_mal","+10.5":"plus_statt_mal","10,5 m²":"plus_statt_mal","10,5m²":"plus_statt_mal","+10,5 m²":"plus_statt_mal","+10,5m²":"plus_statt_mal","10.5 m²":"plus_statt_mal","10.5m²":"plus_statt_mal","+10.5 m²":"plus_statt_mal","+10.5m²":"plus_statt_mal","+21":"umfang_statt_flaeche","21 m²":"umfang_statt_flaeche","21m²":"umfang_statt_flaeche","+21 m²":"umfang_statt_flaeche","+21m²":"umfang_statt_flaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 flaeche-rueck-01 · Rückrichtung · Höhe im Parallelogramm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2fd82f3b-10ca-42b2-91f2-ab53c1eda527'::uuid, 'exercise', 'Rückrichtung · Höhe im Parallelogramm', 'Ein Parallelogramm hat den Flächeninhalt 42 cm² und die Grundseite g = 7 cm.

Wie lang ist die zugehörige Höhe h?',
  '{"kind":"short_input","prompt":"Ein Parallelogramm hat den Flächeninhalt 42 cm² und die Grundseite g = 7 cm.\n\nWie lang ist die zugehörige Höhe h?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: A = g · h nach h umstellen, eine Division.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_gegenoperation, halbieren_faelschlich).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2fd82f3b-10ca-42b2-91f2-ab53c1eda527'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2fd82f3b-10ca-42b2-91f2-ab53c1eda527'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2fd82f3b-10ca-42b2-91f2-ab53c1eda527'::uuid,
  p_correct_answers => '["6","+6","6 cm","6cm","+6 cm","+6cm"]'::jsonb,
  p_solution        => 'A = g · h, also h = A : g = 42 cm² : 7 cm = 6 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Multipliziert statt geteilt: 42 · 7 = 294.","socratic_question":"Welche Rechnung macht das „mal g“ aus der Formel rückgängig?"},{"error":"Mit der Dreiecksformel gerechnet: h = 2 · 42 : 7 = 12.","socratic_question":"Wird beim Parallelogramm halbiert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6","6 cm","6cm","+6 cm","+6cm"],"known_errors":{"12":"halbieren_faelschlich","294":"falsche_gegenoperation","+294":"falsche_gegenoperation","294 cm":"falsche_gegenoperation","294cm":"falsche_gegenoperation","+294 cm":"falsche_gegenoperation","+294cm":"falsche_gegenoperation","+12":"halbieren_faelschlich","12 cm":"halbieren_faelschlich","12cm":"halbieren_faelschlich","+12 cm":"halbieren_faelschlich","+12cm":"halbieren_faelschlich"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 flaeche-rueck-02 · Rückrichtung · Höhe im Dreieck
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fc23183f-db11-441d-ac0d-83baa0000aa0'::uuid, 'exercise', 'Rückrichtung · Höhe im Dreieck', 'Ein Dreieck hat den Flächeninhalt 30 cm² und die Grundseite g = 12 cm.

Wie lang ist die zugehörige Höhe h?',
  '{"kind":"short_input","prompt":"Ein Dreieck hat den Flächeninhalt 30 cm² und die Grundseite g = 12 cm.\n\nWie lang ist die zugehörige Höhe h?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: A = g · h : 2 nach h umstellen.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_gegenoperation).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fc23183f-db11-441d-ac0d-83baa0000aa0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fc23183f-db11-441d-ac0d-83baa0000aa0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fc23183f-db11-441d-ac0d-83baa0000aa0'::uuid,
  p_correct_answers => '["5","+5","5 cm","5cm","+5 cm","+5cm"]'::jsonb,
  p_solution        => 'A = g · h : 2, also h = 2 · A : g = 2 · 30 cm² : 12 cm = 60 cm² : 12 cm = 5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Halbieren beim Umstellen vergessen: 30 : 12 = 2,5.","socratic_question":"Wie groß wäre die Fläche mit h = 2,5 cm wirklich?"},{"error":"Die Formel vorwärts angewendet statt umgestellt: 30 · 12 : 2 = 180.","socratic_question":"Welche Rechnung macht das „mal g“ aus der Formel rückgängig?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5","5 cm","5cm","+5 cm","+5cm"],"known_errors":{"180":"falsche_gegenoperation","2,5":"halbieren_vergessen","+2,5":"halbieren_vergessen","2.5":"halbieren_vergessen","+2.5":"halbieren_vergessen","2,5 cm":"halbieren_vergessen","2,5cm":"halbieren_vergessen","+2,5 cm":"halbieren_vergessen","+2,5cm":"halbieren_vergessen","2.5 cm":"halbieren_vergessen","2.5cm":"halbieren_vergessen","+2.5 cm":"halbieren_vergessen","+2.5cm":"halbieren_vergessen","+180":"falsche_gegenoperation","180 cm":"falsche_gegenoperation","180cm":"falsche_gegenoperation","+180 cm":"falsche_gegenoperation","+180cm":"falsche_gegenoperation"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 flaeche-rueck-03 · Rückrichtung · Höhe im Trapez
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'bcd7aec3-3c43-4d3c-807b-7fe6a2641e70'::uuid, 'exercise', 'Rückrichtung · Höhe im Trapez', 'Ein Trapez hat den Flächeninhalt 63 cm² und die parallelen Seiten a = 12 cm und c = 6 cm.

Wie groß ist seine Höhe h?',
  '{"kind":"short_input","prompt":"Ein Trapez hat den Flächeninhalt 63 cm² und die parallelen Seiten a = 12 cm und c = 6 cm.\n\nWie groß ist seine Höhe h?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Trapezformel umstellen, Mittelwert der parallelen Seiten bilden.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, halbieren_vergessen).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'bcd7aec3-3c43-4d3c-807b-7fe6a2641e70'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'bcd7aec3-3c43-4d3c-807b-7fe6a2641e70'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'bcd7aec3-3c43-4d3c-807b-7fe6a2641e70'::uuid,
  p_correct_answers => '["7","+7","7 cm","7cm","+7 cm","+7cm"]'::jsonb,
  p_solution        => 'A = (a + c) : 2 · h, also h = A : ((a + c) : 2).
(12 cm + 6 cm) : 2 = 9 cm.
h = 63 cm² : 9 cm = 7 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit der Seite a gerechnet: 2 · 63 : 12 = 10,5.","socratic_question":"Kommen beide parallelen Seiten in deiner Rechnung vor?"},{"error":"Nur mit der Seite c gerechnet: 2 · 63 : 6 = 21.","socratic_question":"Kommen beide parallelen Seiten in deiner Rechnung vor?"},{"error":"Durch die Summe statt durch den Mittelwert geteilt: 63 : 18 = 3,5.","socratic_question":"Wie groß wäre die Fläche mit h = 3,5 cm wirklich?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7","7 cm","7cm","+7 cm","+7cm"],"known_errors":{"21":"nur_eine_grundseite","10,5":"nur_eine_grundseite","+10,5":"nur_eine_grundseite","10.5":"nur_eine_grundseite","+10.5":"nur_eine_grundseite","10,5 cm":"nur_eine_grundseite","10,5cm":"nur_eine_grundseite","+10,5 cm":"nur_eine_grundseite","+10,5cm":"nur_eine_grundseite","10.5 cm":"nur_eine_grundseite","10.5cm":"nur_eine_grundseite","+10.5 cm":"nur_eine_grundseite","+10.5cm":"nur_eine_grundseite","+21":"nur_eine_grundseite","21 cm":"nur_eine_grundseite","21cm":"nur_eine_grundseite","+21 cm":"nur_eine_grundseite","+21cm":"nur_eine_grundseite","3,5":"halbieren_vergessen","+3,5":"halbieren_vergessen","3.5":"halbieren_vergessen","+3.5":"halbieren_vergessen","3,5 cm":"halbieren_vergessen","3,5cm":"halbieren_vergessen","+3,5 cm":"halbieren_vergessen","+3,5cm":"halbieren_vergessen","3.5 cm":"halbieren_vergessen","3.5cm":"halbieren_vergessen","+3.5 cm":"halbieren_vergessen","+3.5cm":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 flaeche-rueck-04 · Rückrichtung · fehlende parallele Seite im Trapez
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c2d4c950-beab-4c0b-b4be-cee13fcbffbe'::uuid, 'exercise', 'Rückrichtung · fehlende parallele Seite im Trapez', 'Ein Trapez hat den Flächeninhalt 40 cm². Die parallele Seite a ist 9 cm lang, die Höhe beträgt h = 5 cm.

Wie lang ist die andere parallele Seite c?',
  '{"kind":"short_input","prompt":"Ein Trapez hat den Flächeninhalt 40 cm². Die parallele Seite a ist 9 cm lang, die Höhe beträgt h = 5 cm.\n\nWie lang ist die andere parallele Seite c?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen, Operieren',
  60, 'cm', false, 2, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Trapezformel in zwei Schritten umstellen (Summe a + c, dann c).","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Rückrichtung in zwei Schritten: Lösungsweg selbst finden.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_eine_grundseite, falsche_groesse_beantwortet).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c2d4c950-beab-4c0b-b4be-cee13fcbffbe'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c2d4c950-beab-4c0b-b4be-cee13fcbffbe'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c2d4c950-beab-4c0b-b4be-cee13fcbffbe'::uuid,
  p_correct_answers => '["7","+7","7 cm","7cm","+7 cm","+7cm"]'::jsonb,
  p_solution        => 'A = (a + c) : 2 · h, also a + c = 2 · A : h = 2 · 40 cm² : 5 cm = 16 cm.
c = 16 cm - 9 cm = 7 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Gerechnet, als gäbe es nur eine parallele Seite: 40 : 5 = 8.","socratic_question":"Welche Rolle spielt die Seite a in der Trapezformel?"},{"error":"Die Summe a + c angegeben statt der Seite c.","socratic_question":"Ist nach a + c oder nach c allein gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","equivalents":["+7","7 cm","7cm","+7 cm","+7cm"],"known_errors":{"8":"nur_eine_grundseite","16":"falsche_groesse_beantwortet","+8":"nur_eine_grundseite","8 cm":"nur_eine_grundseite","8cm":"nur_eine_grundseite","+8 cm":"nur_eine_grundseite","+8cm":"nur_eine_grundseite","+16":"falsche_groesse_beantwortet","16 cm":"falsche_groesse_beantwortet","16cm":"falsche_groesse_beantwortet","+16 cm":"falsche_groesse_beantwortet","+16cm":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 flaeche-rueck-05 · Rückrichtung · Sachkontext · Beet als Parallelogramm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '27c84f21-51c3-4fb3-a654-331c8c312f00'::uuid, 'exercise', 'Rückrichtung · Sachkontext · Beet als Parallelogramm', 'Ein Beet hat die Form eines Parallelogramms und ist 18 m² groß. Eine Seite des Beetes ist 4,5 m lang.

Wie groß ist die Höhe des Beetes zu dieser Seite?',
  '{"kind":"short_input","prompt":"Ein Beet hat die Form eines Parallelogramms und ist 18 m² groß. Eine Seite des Beetes ist 4,5 m lang.\n\nWie groß ist die Höhe des Beetes zu dieser Seite?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Parallelogrammformel umstellen, Division durch eine Dezimalzahl.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_gegenoperation, halbieren_faelschlich).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '27c84f21-51c3-4fb3-a654-331c8c312f00'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '27c84f21-51c3-4fb3-a654-331c8c312f00'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '27c84f21-51c3-4fb3-a654-331c8c312f00'::uuid,
  p_correct_answers => '["4","+4","4 m","4m","+4 m","+4m"]'::jsonb,
  p_solution        => 'A = g · h mit g = 4,5 m, also h = 18 m² : 4,5 m = 4 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Multipliziert statt geteilt: 18 · 4,5 = 81.","socratic_question":"Welche Rechnung macht das „mal g“ aus der Formel rückgängig?"},{"error":"Mit der Dreiecksformel gerechnet: 2 · 18 : 4,5 = 8.","socratic_question":"Wird beim Parallelogramm halbiert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["+4","4 m","4m","+4 m","+4m"],"known_errors":{"8":"halbieren_faelschlich","81":"falsche_gegenoperation","+81":"falsche_gegenoperation","81 m":"falsche_gegenoperation","81m":"falsche_gegenoperation","+81 m":"falsche_gegenoperation","+81m":"falsche_gegenoperation","+8":"halbieren_faelschlich","8 m":"halbieren_faelschlich","8m":"halbieren_faelschlich","+8 m":"halbieren_faelschlich","+8m":"halbieren_faelschlich"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 flaeche-rueck-06 · Rückrichtung · Sachkontext · dreieckiges Segel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '380c4ca9-3efc-45e9-8c4c-87b751e2f414'::uuid, 'exercise', 'Rückrichtung · Sachkontext · dreieckiges Segel', 'Ein dreieckiges Segel hat den Flächeninhalt 7,5 m². Seine untere Kante ist 3 m lang.

Wie lang ist die Höhe des Segels zu dieser Kante?',
  '{"kind":"short_input","prompt":"Ein dreieckiges Segel hat den Flächeninhalt 7,5 m². Seine untere Kante ist 3 m lang.\n\nWie lang ist die Höhe des Segels zu dieser Kante?"}'::jsonb, 'NUMERIC', 'geo_flaeche_rueck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, 1, 'draft', 'edvance_k8_flaeche', 'flaeche-rueck-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Dreiecksformel umstellen, Dezimalfläche.","charge":"k8-flaeche"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-flaeche"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geo-8 (Trapez, Drachen, Raute, zusammengesetzte Figuren, Flächenterme).","charge":"k8-flaeche"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_flaeche_rechteck und geo_flaeche_dreieck im Bestand.","charge":"k8-flaeche"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (KLP Geo-8).","charge":"k8-flaeche"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Flächenformel übersetzen, dann rechnen.","charge":"k8-flaeche"},"needs_image":{"art":"neu","grund":"Alle Maße und die Lage der Teilfiguren stehen im Text; kein Generator zeichnet Trapez, Drachen oder Raute (phase1 a).","charge":"k8-flaeche"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Plus-Form und Einheit.","charge":"k8-flaeche"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-flaeche"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_gegenoperation).","charge":"k8-flaeche"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-flaeche"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '380c4ca9-3efc-45e9-8c4c-87b751e2f414'::uuid and t.status = 'draft' and t.source = 'edvance_k8_flaeche')
   and not exists (select 1 from public.task_solutions s where s.task_id = '380c4ca9-3efc-45e9-8c4c-87b751e2f414'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '380c4ca9-3efc-45e9-8c4c-87b751e2f414'::uuid,
  p_correct_answers => '["5","+5","5 m","5m","+5 m","+5m"]'::jsonb,
  p_solution        => 'A = g · h : 2 mit g = 3 m, also h = 2 · 7,5 m² : 3 m = 15 m² : 3 m = 5 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Halbieren beim Umstellen vergessen: 7,5 : 3 = 2,5.","socratic_question":"Wie groß wäre das Segel mit h = 2,5 m wirklich?"},{"error":"Die Formel vorwärts angewendet statt umgestellt: 7,5 · 3 : 2 = 11,25.","socratic_question":"Welche Rechnung macht das „mal g“ aus der Formel rückgängig?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","equivalents":["+5","5 m","5m","+5 m","+5m"],"known_errors":{"2,5":"halbieren_vergessen","+2,5":"halbieren_vergessen","2.5":"halbieren_vergessen","+2.5":"halbieren_vergessen","2,5 m":"halbieren_vergessen","2,5m":"halbieren_vergessen","+2,5 m":"halbieren_vergessen","+2,5m":"halbieren_vergessen","2.5 m":"halbieren_vergessen","2.5m":"halbieren_vergessen","+2.5 m":"halbieren_vergessen","+2.5m":"halbieren_vergessen","11,25":"falsche_gegenoperation","+11,25":"falsche_gegenoperation","11.25":"falsche_gegenoperation","+11.25":"falsche_gegenoperation","11,25 m":"falsche_gegenoperation","11,25m":"falsche_gegenoperation","+11,25 m":"falsche_gegenoperation","+11,25m":"falsche_gegenoperation","11.25 m":"falsche_gegenoperation","11.25m":"falsche_gegenoperation","+11.25 m":"falsche_gegenoperation","+11.25m":"falsche_gegenoperation"}}'::jsonb);
  end if;
end
$loesung$;
