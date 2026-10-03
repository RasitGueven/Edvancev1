-- K9-Rest, Thema koerper — 30 Aufgaben (Prisma, Zylinder, Pyramide, Kegel, Kugel; je Knoten 6, AFB I/I/II/II/II-Sach/III), alle als Text ohne Abbildung.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-koerper.json (Quelle: tools/k9-koerper-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105858_substrat_k9_koerper.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Wassertrog, Wassertank, Pyramidendach, Trichter, kugelförmiger Behälter) und eine AFB III (Rückrichtung oder zusammengesetzter Körper). Alle ohne Abbildung lösbar, alle Maße im Text. Jede Aufgabe nennt die Rundung; π-Aufgaben nennen π-Taste oder 3,14, beide Ergebnisse stehen als Varianten in correct_answers und acceptance.equivalents (exakter Textvergleich, keine Toleranz).
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-koerper.csv. Pruefprotokoll: docs/prefill/k9-koerper-verifikation.md.
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
--   geo_koerper_prisma: koerper-prisma-02 = 1, koerper-prisma-05 = 2. Rang 1 aus Profil {halbieren_vergessen,mal_zwei_vergessen,volumen_statt_oberflaeche}, Rang 2 aus Profil {einheit_uebersprungen,halbieren_vergessen,liter_kubik_falsch} (2 neue Fehlbilder)
--   geo_koerper_zylinder: koerper-zylinder-03 = 1, koerper-zylinder-02 = 2. Rang 1 aus Profil {mal_exponent,oberflaeche_statt_volumen,pi_vergessen,radius_durchmesser_verwechselt}, Rang 2 aus Profil {mal_zwei_vergessen,radius_durchmesser_verwechselt,volumen_statt_oberflaeche} (2 neue Fehlbilder)
--   geo_koerper_pyramide: koerper-pyramide-05 = 1, koerper-pyramide-06 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,falsche_hoehe,halbieren_vergessen}, Rang 2 aus Profil {drittel_vergessen,mal_exponent,wurzel_vergessen} (3 neue Fehlbilder)
--   geo_koerper_kegel: koerper-kegel-01 = 1, koerper-kegel-04 = 2. Rang 1 aus Profil {drittel_vergessen,pi_vergessen,radius_durchmesser_verwechselt}, Rang 2 aus Profil {falsche_hoehe,hypotenuse_verwechselt,wurzel_vergessen} (3 neue Fehlbilder)
--   geo_koerper_kugel: koerper-kugel-06 = 1, koerper-kugel-05 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,halbieren_vergessen,pi_vergessen,radius_durchmesser_verwechselt}, Rang 2 aus Profil {liter_kubik_falsch,oberflaeche_statt_volumen,pi_vergessen,radius_durchmesser_verwechselt} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 koerper-prisma-01 · Prisma · Volumen eines Dreiecksprismas
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ca18a102-4cf1-45fe-8461-82d860a7288c'::uuid, 'exercise', 'Prisma · Volumen eines Dreiecksprismas', 'Ein gerades Prisma hat als Grundfläche ein Dreieck. Die Grundseite des Dreiecks ist 6 cm lang, die zugehörige Höhe des Dreiecks beträgt 4 cm. Das Prisma ist 10 cm hoch.

Wie groß ist das Volumen des Prismas? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein gerades Prisma hat als Grundfläche ein Dreieck. Die Grundseite des Dreiecks ist 6 cm lang, die zugehörige Höhe des Dreiecks beträgt 4 cm. Das Prisma ist 10 cm hoch.\n\nWie groß ist das Volumen des Prismas? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-prisma-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Dreiecksfläche als Grundfläche, dann V = G · h.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ca18a102-4cf1-45fe-8461-82d860a7288c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ca18a102-4cf1-45fe-8461-82d860a7288c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ca18a102-4cf1-45fe-8461-82d860a7288c'::uuid,
  p_correct_answers => '["120","120 cm³","120cm³"]'::jsonb,
  p_solution        => 'Grundfläche: G = ½ · 6 cm · 4 cm = 12 cm².
V = G · h = 12 cm² · 10 cm = 120 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei der Dreiecksfläche das ½ vergessen: 6 · 4 · 10 = 240.","socratic_question":"Wie berechnest du den Flächeninhalt eines Dreiecks?"},{"error":"Nur die Grundfläche berechnet, nicht das Volumen.","socratic_question":"Hast du die Höhe des Prismas schon verwendet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"120","equivalents":["120 cm³","120cm³"],"known_errors":{"12":"falsche_groesse_beantwortet","240":"halbieren_vergessen","240 cm³":"halbieren_vergessen","240cm³":"halbieren_vergessen","12 cm³":"falsche_groesse_beantwortet","12cm³":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 koerper-prisma-02 · Prisma · Oberfläche eines Dreiecksprismas
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'edeb2812-e0a3-415b-b097-e57181b53d6d'::uuid, 'exercise', 'Prisma · Oberfläche eines Dreiecksprismas', 'Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 3 cm, 4 cm und 5 cm. Der rechte Winkel liegt zwischen den Seiten 3 cm und 4 cm. Das Prisma ist 8 cm hoch.

Wie groß ist die Oberfläche des Prismas? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 3 cm, 4 cm und 5 cm. Der rechte Winkel liegt zwischen den Seiten 3 cm und 4 cm. Das Prisma ist 8 cm hoch.\n\nWie groß ist die Oberfläche des Prismas? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, 1, 'draft', 'edvance_k9_koerper', 'koerper-prisma-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: O = 2 · G + Mantel mit gegebenen Dreiecksseiten.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_zwei_vergessen, halbieren_vergessen, volumen_statt_oberflaeche).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'edeb2812-e0a3-415b-b097-e57181b53d6d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'edeb2812-e0a3-415b-b097-e57181b53d6d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'edeb2812-e0a3-415b-b097-e57181b53d6d'::uuid,
  p_correct_answers => '["108","108 cm²","108cm²"]'::jsonb,
  p_solution        => 'Grundfläche: G = ½ · 3 cm · 4 cm = 6 cm².
Mantel: M = Umfang · Höhe = (3 + 4 + 5) cm · 8 cm = 96 cm².
O = 2 · G + M = 12 cm² + 96 cm² = 108 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur eine Grundfläche gezählt: 6 + 96 = 102.","socratic_question":"Wie viele Dreiecksflächen hat das Prisma?"},{"error":"Bei der Dreiecksfläche das ½ vergessen: 2 · 12 + 96 = 120.","socratic_question":"Ist das Dreieck mit den Katheten 3 cm und 4 cm wirklich 12 cm² groß?"},{"error":"Das Volumen berechnet statt der Oberfläche: 6 · 8 = 48.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche aller Seiten gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"108","equivalents":["108 cm²","108cm²"],"known_errors":{"48":"volumen_statt_oberflaeche","102":"mal_zwei_vergessen","120":"halbieren_vergessen","102 cm²":"mal_zwei_vergessen","102cm²":"mal_zwei_vergessen","120 cm²":"halbieren_vergessen","120cm²":"halbieren_vergessen","48 cm²":"volumen_statt_oberflaeche","48cm²":"volumen_statt_oberflaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 koerper-prisma-03 · Prisma · Volumen mit Trapez als Grundfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e958eb79-345a-4079-867b-46ecb652b478'::uuid, 'exercise', 'Prisma · Volumen mit Trapez als Grundfläche', 'Ein gerades Prisma hat als Grundfläche ein Trapez. Die parallelen Seiten des Trapezes sind 8 cm und 5 cm lang, ihr Abstand beträgt 4 cm. Das Prisma ist 12 cm hoch.

Wie groß ist das Volumen des Prismas? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein gerades Prisma hat als Grundfläche ein Trapez. Die parallelen Seiten des Trapezes sind 8 cm und 5 cm lang, ihr Abstand beträgt 4 cm. Das Prisma ist 12 cm hoch.\n\nWie groß ist das Volumen des Prismas? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-prisma-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Grundfläche ist ein Trapez, erst die Fläche bestimmen, dann V = G · h.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e958eb79-345a-4079-867b-46ecb652b478'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e958eb79-345a-4079-867b-46ecb652b478'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e958eb79-345a-4079-867b-46ecb652b478'::uuid,
  p_correct_answers => '["312","312 cm³","312cm³"]'::jsonb,
  p_solution        => 'Grundfläche: G = (8 cm + 5 cm) : 2 · 4 cm = 26 cm².
V = G · h = 26 cm² · 12 cm = 312 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei der Trapezfläche das Halbieren vergessen: 13 · 4 · 12 = 624.","socratic_question":"Wie lautet die Formel für den Flächeninhalt eines Trapezes?"},{"error":"Nur die Grundfläche berechnet, nicht das Volumen.","socratic_question":"Hast du die Höhe des Prismas schon verwendet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"312","equivalents":["312 cm³","312cm³"],"known_errors":{"26":"falsche_groesse_beantwortet","624":"halbieren_vergessen","624 cm³":"halbieren_vergessen","624cm³":"halbieren_vergessen","26 cm³":"falsche_groesse_beantwortet","26cm³":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 koerper-prisma-04 · Prisma · Höhe aus Volumen und Dreiecksgrundfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '807dd2a7-18a0-4ff1-93e4-d2d26052cd12'::uuid, 'exercise', 'Prisma · Höhe aus Volumen und Dreiecksgrundfläche', 'Ein gerades Prisma hat das Volumen 180 cm³. Seine Grundfläche ist ein Dreieck mit der Grundseite 8 cm und der zugehörigen Höhe 5 cm.

Wie hoch ist das Prisma? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein gerades Prisma hat das Volumen 180 cm³. Seine Grundfläche ist ein Dreieck mit der Grundseite 8 cm und der zugehörigen Höhe 5 cm.\n\nWie hoch ist das Prisma? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_koerper', 'koerper-prisma-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: V = G · h nach h umstellen, Grundfläche erst aus dem Dreieck bestimmen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, multipliziert_statt_dividiert).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '807dd2a7-18a0-4ff1-93e4-d2d26052cd12'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '807dd2a7-18a0-4ff1-93e4-d2d26052cd12'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '807dd2a7-18a0-4ff1-93e4-d2d26052cd12'::uuid,
  p_correct_answers => '["9","9 cm","9cm"]'::jsonb,
  p_solution        => 'Grundfläche: G = ½ · 8 cm · 5 cm = 20 cm².
V = G · h, also h = V : G = 180 cm³ : 20 cm² = 9 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei der Dreiecksfläche das ½ vergessen: 180 : 40 = 4,5.","socratic_question":"Wie groß ist das Dreieck mit Grundseite 8 cm und Höhe 5 cm wirklich?"},{"error":"Volumen mit der Grundfläche multipliziert statt durch sie geteilt.","socratic_question":"Kann ein Prisma mit 180 cm³ Volumen so hoch sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["9 cm","9cm"],"known_errors":{"3600":"multipliziert_statt_dividiert","4,5":"halbieren_vergessen","4.5":"halbieren_vergessen","4,5 cm":"halbieren_vergessen","4,5cm":"halbieren_vergessen","3600 cm":"multipliziert_statt_dividiert","3600cm":"multipliziert_statt_dividiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 koerper-prisma-05 · Prisma · Wassertrog mit dreieckigem Querschnitt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9de789c5-cdc1-45c4-b38f-d809926410f5'::uuid, 'exercise', 'Prisma · Wassertrog mit dreieckigem Querschnitt', 'Ein Wassertrog hat die Form eines liegenden Dreiecksprismas. Der Querschnitt ist ein Dreieck: oben 60 cm breit und 40 cm tief. Der Trog ist 2 m lang. Es gilt 1 dm³ = 1 l.

Wie viele Liter Wasser fasst der Trog, wenn er randvoll ist? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein Wassertrog hat die Form eines liegenden Dreiecksprismas. Der Querschnitt ist ein Dreieck: oben 60 cm breit und 40 cm tief. Der Trog ist 2 m lang. Es gilt 1 dm³ = 1 l.\n\nWie viele Liter Wasser fasst der Trog, wenn er randvoll ist? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'l', false, 2, 'draft', 'edvance_k9_koerper', 'koerper-prisma-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Trog als Dreiecksprisma erkennen, Einheiten angleichen und in Liter umrechnen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, liter_kubik_falsch, einheit_uebersprungen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9de789c5-cdc1-45c4-b38f-d809926410f5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9de789c5-cdc1-45c4-b38f-d809926410f5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9de789c5-cdc1-45c4-b38f-d809926410f5'::uuid,
  p_correct_answers => '["240","240 l","240l"]'::jsonb,
  p_solution        => 'In Dezimeter umrechnen: 60 cm = 6 dm, 40 cm = 4 dm, 2 m = 20 dm.
Grundfläche: G = ½ · 6 dm · 4 dm = 12 dm².
V = G · Länge = 12 dm² · 20 dm = 240 dm³ = 240 l.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei der Dreiecksfläche das ½ vergessen: 24 · 20 = 480.","socratic_question":"Ist der Querschnitt ein Rechteck oder ein Dreieck?"},{"error":"In Kubikzentimetern gerechnet und die Zahl als Liter angegeben.","socratic_question":"Wie viele Kubikzentimeter passen in einen Liter?"},{"error":"Zentimeter und Meter gemischt, ohne umzurechnen.","socratic_question":"Sind alle drei Maße in derselben Einheit?"}]'::jsonb,
  p_acceptance      => '{"canonical":"240","equivalents":["240 l","240l"],"known_errors":{"480":"halbieren_vergessen","2400":"einheit_uebersprungen","240000":"liter_kubik_falsch","480 l":"halbieren_vergessen","480l":"halbieren_vergessen","240000 l":"liter_kubik_falsch","240000l":"liter_kubik_falsch","2400 l":"einheit_uebersprungen","2400l":"einheit_uebersprungen"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 koerper-prisma-06 · Prisma · Höhe aus der Oberfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e8aa50eb-5f6b-4296-a408-05257f00fe34'::uuid, 'exercise', 'Prisma · Höhe aus der Oberfläche', 'Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 6 cm, 8 cm und 10 cm. Der rechte Winkel liegt zwischen den Seiten 6 cm und 8 cm. Die Oberfläche des Prismas beträgt 288 cm².

Wie hoch ist das Prisma? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 6 cm, 8 cm und 10 cm. Der rechte Winkel liegt zwischen den Seiten 6 cm und 8 cm. Die Oberfläche des Prismas beträgt 288 cm².\n\nWie hoch ist das Prisma? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_prisma',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm', false, null, 'draft', 'edvance_k9_koerper', 'koerper-prisma-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung über die Oberfläche – Grundflächen abziehen, dann durch den Umfang teilen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_zwei_vergessen, halbieren_vergessen, volumen_statt_oberflaeche).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e8aa50eb-5f6b-4296-a408-05257f00fe34'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e8aa50eb-5f6b-4296-a408-05257f00fe34'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e8aa50eb-5f6b-4296-a408-05257f00fe34'::uuid,
  p_correct_answers => '["10","10 cm","10cm"]'::jsonb,
  p_solution        => 'Grundfläche: G = ½ · 6 cm · 8 cm = 24 cm², zwei Grundflächen: 48 cm².
Mantel: M = 288 cm² − 48 cm² = 240 cm².
M = Umfang · h mit Umfang 6 cm + 8 cm + 10 cm = 24 cm.
h = 240 cm² : 24 cm = 10 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur eine Grundfläche abgezogen: 264 : 24 = 11.","socratic_question":"Wie viele Dreiecksflächen gehören zur Oberfläche?"},{"error":"Bei der Dreiecksfläche das ½ vergessen: (288 − 96) : 24 = 8.","socratic_question":"Wie groß ist ein rechtwinkliges Dreieck mit den Katheten 6 cm und 8 cm?"},{"error":"Die Oberfläche wie ein Volumen durch die Grundfläche geteilt: 288 : 24 = 12.","socratic_question":"Ist 288 cm² ein Volumen oder eine Fläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["10 cm","10cm"],"known_errors":{"8":"halbieren_vergessen","11":"mal_zwei_vergessen","12":"volumen_statt_oberflaeche","11 cm":"mal_zwei_vergessen","11cm":"mal_zwei_vergessen","8 cm":"halbieren_vergessen","8cm":"halbieren_vergessen","12 cm":"volumen_statt_oberflaeche","12cm":"volumen_statt_oberflaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 koerper-zylinder-01 · Zylinder · Volumen, Radius 3 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2fd67e4c-9093-4e51-bd98-46e7d76e3a9f'::uuid, 'exercise', 'Zylinder · Volumen, Radius 3 cm', 'Ein Zylinder hat den Radius 3 cm und die Höhe 10 cm.

Wie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Zylinder hat den Radius 3 cm und die Höhe 10 cm.\n\nWie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Volumenformel mit gegebenem Radius und gegebener Höhe.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, pi_vergessen, oberflaeche_statt_volumen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2fd67e4c-9093-4e51-bd98-46e7d76e3a9f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2fd67e4c-9093-4e51-bd98-46e7d76e3a9f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2fd67e4c-9093-4e51-bd98-46e7d76e3a9f'::uuid,
  p_correct_answers => '["282,74","282.74","282,74 cm³","282,74cm³","282,60","282.60","282,6","282.6","282,60 cm³","282,60cm³","282,6 cm³","282,6cm³"]'::jsonb,
  p_solution        => 'V = π · r² · h = π · 9 cm² · 10 cm = π · 90 cm³ ≈ 282,74 cm³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 90 cm³ = 282,60 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 6 cm statt 3 cm gerechnet, Radius und Durchmesser verwechselt: π · 6² · 10.","socratic_question":"Ist 3 cm schon der Radius?"},{"error":"π weggelassen: 9 · 10 = 90.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"},{"error":"Die Oberfläche berechnet statt des Volumens.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"282,74","equivalents":["282.74","282,74 cm³","282,74cm³","282,60","282.60","282,6","282.6","282,60 cm³","282,60cm³","282,6 cm³","282,6cm³"],"known_errors":{"90":"pi_vergessen","1130,97":"radius_durchmesser_verwechselt","1130.97":"radius_durchmesser_verwechselt","1130,97 cm³":"radius_durchmesser_verwechselt","1130,97cm³":"radius_durchmesser_verwechselt","1130,40":"radius_durchmesser_verwechselt","1130.40":"radius_durchmesser_verwechselt","1130,4":"radius_durchmesser_verwechselt","1130.4":"radius_durchmesser_verwechselt","1130,40 cm³":"radius_durchmesser_verwechselt","1130,40cm³":"radius_durchmesser_verwechselt","1130,4 cm³":"radius_durchmesser_verwechselt","1130,4cm³":"radius_durchmesser_verwechselt","90,00":"pi_vergessen","90.00":"pi_vergessen","90,00 cm³":"pi_vergessen","90,00cm³":"pi_vergessen","90 cm³":"pi_vergessen","90cm³":"pi_vergessen","245,04":"oberflaeche_statt_volumen","245.04":"oberflaeche_statt_volumen","245,04 cm³":"oberflaeche_statt_volumen","245,04cm³":"oberflaeche_statt_volumen","244,92":"oberflaeche_statt_volumen","244.92":"oberflaeche_statt_volumen","244,92 cm³":"oberflaeche_statt_volumen","244,92cm³":"oberflaeche_statt_volumen"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 koerper-zylinder-02 · Zylinder · Oberfläche, Durchmesser 8 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd0b4dbc3-1278-4a60-bcbe-98ebc0060ad2'::uuid, 'exercise', 'Zylinder · Oberfläche, Durchmesser 8 cm', 'Ein Zylinder hat den Durchmesser 8 cm und die Höhe 5 cm.

Wie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Zylinder hat den Durchmesser 8 cm und die Höhe 5 cm.\n\nWie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, 2, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Radius aus dem Durchmesser, dann O = 2 · G + M.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, mal_zwei_vergessen, volumen_statt_oberflaeche).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd0b4dbc3-1278-4a60-bcbe-98ebc0060ad2'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd0b4dbc3-1278-4a60-bcbe-98ebc0060ad2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd0b4dbc3-1278-4a60-bcbe-98ebc0060ad2'::uuid,
  p_correct_answers => '["226,19","226.19","226,19 cm²","226,19cm²","226,08","226.08","226,08 cm²","226,08cm²"]'::jsonb,
  p_solution        => 'r = 8 cm : 2 = 4 cm.
Zwei Grundflächen: 2 · π · (4 cm)² = π · 32 cm².
Mantel: 2 · π · 4 cm · 5 cm = π · 40 cm².
O = π · 72 cm² ≈ 226,19 cm² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 72 cm² = 226,08 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt.","socratic_question":"Ist 8 cm der Radius oder der Durchmesser?"},{"error":"Nur eine Kreisfläche gezählt (Deckel oder Boden fehlt).","socratic_question":"Wie viele Kreisflächen hat ein geschlossener Zylinder?"},{"error":"Das Volumen berechnet statt der Oberfläche.","socratic_question":"Kommt bei deiner Rechnung cm² oder cm³ heraus?"}]'::jsonb,
  p_acceptance      => '{"canonical":"226,19","equivalents":["226.19","226,19 cm²","226,19cm²","226,08","226.08","226,08 cm²","226,08cm²"],"known_errors":{"653,45":"radius_durchmesser_verwechselt","653.45":"radius_durchmesser_verwechselt","653,45 cm²":"radius_durchmesser_verwechselt","653,45cm²":"radius_durchmesser_verwechselt","653,12":"radius_durchmesser_verwechselt","653.12":"radius_durchmesser_verwechselt","653,12 cm²":"radius_durchmesser_verwechselt","653,12cm²":"radius_durchmesser_verwechselt","175,93":"mal_zwei_vergessen","175.93":"mal_zwei_vergessen","175,93 cm²":"mal_zwei_vergessen","175,93cm²":"mal_zwei_vergessen","175,84":"mal_zwei_vergessen","175.84":"mal_zwei_vergessen","175,84 cm²":"mal_zwei_vergessen","175,84cm²":"mal_zwei_vergessen","251,33":"volumen_statt_oberflaeche","251.33":"volumen_statt_oberflaeche","251,33 cm²":"volumen_statt_oberflaeche","251,33cm²":"volumen_statt_oberflaeche","251,20":"volumen_statt_oberflaeche","251.20":"volumen_statt_oberflaeche","251,2":"volumen_statt_oberflaeche","251.2":"volumen_statt_oberflaeche","251,20 cm²":"volumen_statt_oberflaeche","251,20cm²":"volumen_statt_oberflaeche","251,2 cm²":"volumen_statt_oberflaeche","251,2cm²":"volumen_statt_oberflaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 koerper-zylinder-03 · Zylinder · Volumen, Radius 1,5 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '267a9ef3-4ac7-4b54-ba99-f84b90ae1521'::uuid, 'exercise', 'Zylinder · Volumen, Radius 1,5 m', 'Ein Zylinder hat den Radius 1,5 m und die Höhe 3,2 m.

Wie groß ist sein Volumen in Kubikmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Zylinder hat den Radius 1,5 m und die Höhe 3,2 m.\n\nWie groß ist sein Volumen in Kubikmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm³', false, 1, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat einer Dezimalzahl in der Volumenformel.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, radius_durchmesser_verwechselt, pi_vergessen, oberflaeche_statt_volumen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '267a9ef3-4ac7-4b54-ba99-f84b90ae1521'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '267a9ef3-4ac7-4b54-ba99-f84b90ae1521'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '267a9ef3-4ac7-4b54-ba99-f84b90ae1521'::uuid,
  p_correct_answers => '["22,62","22.62","22,62 m³","22,62m³","22,61","22.61","22,61 m³","22,61m³"]'::jsonb,
  p_solution        => 'V = π · (1,5 m)² · 3,2 m = π · 2,25 m² · 3,2 m = π · 7,2 m³ ≈ 22,62 m³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 7,2 m³ ≈ 22,61 m³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"1,5² als 2 · 1,5 gerechnet: π · 3 · 3,2.","socratic_question":"Was ist 1,5² – 1,5 · 2 oder 1,5 · 1,5?"},{"error":"Den Radius wie einen Durchmesser halbiert: π · 0,75² · 3,2.","socratic_question":"Ist 1,5 m schon der Radius?"},{"error":"π weggelassen: 2,25 · 3,2 = 7,2.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"},{"error":"Die Oberfläche berechnet statt des Volumens.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"22,62","equivalents":["22.62","22,62 m³","22,62m³","22,61","22.61","22,61 m³","22,61m³"],"known_errors":{"30,16":"mal_exponent","30.16":"mal_exponent","30,16 m³":"mal_exponent","30,16m³":"mal_exponent","30,14":"mal_exponent","30.14":"mal_exponent","30,14 m³":"mal_exponent","30,14m³":"mal_exponent","5,65":"radius_durchmesser_verwechselt","5.65":"radius_durchmesser_verwechselt","5,65 m³":"radius_durchmesser_verwechselt","5,65m³":"radius_durchmesser_verwechselt","7,20":"pi_vergessen","7.20":"pi_vergessen","7,2":"pi_vergessen","7.2":"pi_vergessen","7,20 m³":"pi_vergessen","7,20m³":"pi_vergessen","7,2 m³":"pi_vergessen","7,2m³":"pi_vergessen","44,30":"oberflaeche_statt_volumen","44.30":"oberflaeche_statt_volumen","44,3":"oberflaeche_statt_volumen","44.3":"oberflaeche_statt_volumen","44,30 m³":"oberflaeche_statt_volumen","44,30m³":"oberflaeche_statt_volumen","44,3 m³":"oberflaeche_statt_volumen","44,3m³":"oberflaeche_statt_volumen","44,27":"oberflaeche_statt_volumen","44.27":"oberflaeche_statt_volumen","44,27 m³":"oberflaeche_statt_volumen","44,27m³":"oberflaeche_statt_volumen"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 koerper-zylinder-04 · Zylinder · Oberfläche in m² bei gemischten Einheiten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5dd22acb-5345-4c8e-97d6-8f5cf323627a'::uuid, 'exercise', 'Zylinder · Oberfläche in m² bei gemischten Einheiten', 'Ein Zylinder hat den Radius 0,4 m und die Höhe 90 cm.

Wie groß ist seine Oberfläche in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Zylinder hat den Radius 0,4 m und die Höhe 90 cm.\n\nWie groß ist seine Oberfläche in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Oberflächenformel, vorher Zentimeter in Meter umrechnen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, mal_zwei_vergessen, radius_durchmesser_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5dd22acb-5345-4c8e-97d6-8f5cf323627a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5dd22acb-5345-4c8e-97d6-8f5cf323627a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5dd22acb-5345-4c8e-97d6-8f5cf323627a'::uuid,
  p_correct_answers => '["3,27","3.27","3,27 m²","3,27m²"]'::jsonb,
  p_solution        => 'h = 90 cm = 0,9 m.
Zwei Grundflächen: 2 · π · (0,4 m)² = π · 0,32 m².
Mantel: 2 · π · 0,4 m · 0,9 m = π · 0,72 m².
O = π · 1,04 m² ≈ 3,27 m² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 1,04 m² ≈ 3,27 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Höhe nicht in Meter umgerechnet: mit 90 statt 0,9 gerechnet.","socratic_question":"Sind Radius und Höhe in derselben Einheit?"},{"error":"Nur eine Kreisfläche gezählt (Deckel oder Boden fehlt).","socratic_question":"Wie viele Kreisflächen hat ein geschlossener Zylinder?"},{"error":"Den Radius wie einen Durchmesser halbiert.","socratic_question":"Ist 0,4 m schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3,27","equivalents":["3.27","3,27 m²","3,27m²"],"known_errors":{"227,20":"einheit_uebersprungen","227.20":"einheit_uebersprungen","227,2":"einheit_uebersprungen","227.2":"einheit_uebersprungen","227,20 m²":"einheit_uebersprungen","227,20m²":"einheit_uebersprungen","227,2 m²":"einheit_uebersprungen","227,2m²":"einheit_uebersprungen","227,08":"einheit_uebersprungen","227.08":"einheit_uebersprungen","227,08 m²":"einheit_uebersprungen","227,08m²":"einheit_uebersprungen","2,76":"mal_zwei_vergessen","2.76":"mal_zwei_vergessen","2,76 m²":"mal_zwei_vergessen","2,76m²":"mal_zwei_vergessen","1,38":"radius_durchmesser_verwechselt","1.38":"radius_durchmesser_verwechselt","1,38 m²":"radius_durchmesser_verwechselt","1,38m²":"radius_durchmesser_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 koerper-zylinder-05 · Zylinder · Wassertank in Litern
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a64cbccb-268c-4d5d-97b6-f925daf460e4'::uuid, 'exercise', 'Zylinder · Wassertank in Litern', 'Ein zylinderförmiger Wassertank hat innen einen Durchmesser von 1,2 m und eine Höhe von 1,5 m. Es gilt 1 dm³ = 1 l, also 1 m³ = 1000 l.

Wie viele Liter fasst der Tank? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Liter.',
  '{"kind":"short_input","prompt":"Ein zylinderförmiger Wassertank hat innen einen Durchmesser von 1,2 m und eine Höhe von 1,5 m. Es gilt 1 dm³ = 1 l, also 1 m³ = 1000 l.\n\nWie viele Liter fasst der Tank? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Liter."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'l', false, null, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Durchmesser halbieren, Volumen in m³ berechnen und in Liter umrechnen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, liter_kubik_falsch, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a64cbccb-268c-4d5d-97b6-f925daf460e4'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a64cbccb-268c-4d5d-97b6-f925daf460e4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a64cbccb-268c-4d5d-97b6-f925daf460e4'::uuid,
  p_correct_answers => '["1696","1696 l","1696l"]'::jsonb,
  p_solution        => 'r = 1,2 m : 2 = 0,6 m.
V = π · (0,6 m)² · 1,5 m = π · 0,54 m³ ≈ 1,69646 m³ (π-Taste), mit 3,14: 1,6956 m³.
1 m³ = 1000 l: V ≈ 1696 l (π-Taste), mit π ≈ 3,14 ebenfalls ≈ 1696 l.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: π · 1,2² · 1,5.","socratic_question":"Ist 1,2 m der Radius oder der Durchmesser des Tanks?"},{"error":"Den Wert in Kubikmetern als Liter angegeben.","socratic_question":"Wie viele Liter passen in einen Kubikmeter?"},{"error":"π weggelassen: 0,54 m³ = 540 l.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1696","equivalents":["1696 l","1696l"],"known_errors":{"540":"pi_vergessen","6782":"radius_durchmesser_verwechselt","6786":"radius_durchmesser_verwechselt","6786 l":"radius_durchmesser_verwechselt","6786l":"radius_durchmesser_verwechselt","6782 l":"radius_durchmesser_verwechselt","6782l":"radius_durchmesser_verwechselt","1,70":"liter_kubik_falsch","1.70":"liter_kubik_falsch","1,7":"liter_kubik_falsch","1.7":"liter_kubik_falsch","1,70 l":"liter_kubik_falsch","1,70l":"liter_kubik_falsch","1,7 l":"liter_kubik_falsch","1,7l":"liter_kubik_falsch","540 l":"pi_vergessen","540l":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 koerper-zylinder-06 · Zylinder · Dosenhöhe für einen Liter
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'bdee1a03-5e67-4293-a8b5-794de2e25331'::uuid, 'exercise', 'Zylinder · Dosenhöhe für einen Liter', 'Eine zylinderförmige Dose soll genau 1 Liter fassen. Ihr Durchmesser innen beträgt 10 cm. Es gilt 1 l = 1 dm³ = 1000 cm³.

Wie hoch muss die Dose innen sein? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine zylinderförmige Dose soll genau 1 Liter fassen. Ihr Durchmesser innen beträgt 10 cm. Es gilt 1 l = 1 dm³ = 1000 cm³.\n\nWie hoch muss die Dose innen sein? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_zylinder',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'cm', false, null, 'draft', 'edvance_k9_koerper', 'koerper-zylinder-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung – Liter in cm³ umrechnen, Volumenformel nach h umstellen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, liter_kubik_falsch, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'bdee1a03-5e67-4293-a8b5-794de2e25331'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'bdee1a03-5e67-4293-a8b5-794de2e25331'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'bdee1a03-5e67-4293-a8b5-794de2e25331'::uuid,
  p_correct_answers => '["12,7","12.7","12,7 cm","12,7cm"]'::jsonb,
  p_solution        => 'V = 1 l = 1000 cm³, r = 10 cm : 2 = 5 cm.
V = π · r² · h, also h = V : (π · r²) = 1000 cm³ : (π · 25 cm²) ≈ 12,73 cm, gerundet 12,7 cm (π-Taste).
Mit π ≈ 3,14: h = 1000 : 78,5 ≈ 12,74 cm, gerundet 12,7 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: 1000 : (π · 100).","socratic_question":"Ist 10 cm der Radius oder der Durchmesser?"},{"error":"Mit 1 l = 100 cm³ gerechnet.","socratic_question":"Wie viele Kubikzentimeter hat ein Liter?"},{"error":"π weggelassen: 1000 : 25 = 40.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,7","equivalents":["12.7","12,7 cm","12,7cm"],"known_errors":{"40":"pi_vergessen","3,2":"radius_durchmesser_verwechselt","3.2":"radius_durchmesser_verwechselt","3,2 cm":"radius_durchmesser_verwechselt","3,2cm":"radius_durchmesser_verwechselt","1,3":"liter_kubik_falsch","1.3":"liter_kubik_falsch","1,3 cm":"liter_kubik_falsch","1,3cm":"liter_kubik_falsch","40,0":"pi_vergessen","40.0":"pi_vergessen","40,0 cm":"pi_vergessen","40,0cm":"pi_vergessen","40 cm":"pi_vergessen","40cm":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 koerper-pyramide-01 · Pyramide · Volumen einer quadratischen Pyramide
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b844a22a-3ad5-40aa-88df-8d6b10531307'::uuid, 'exercise', 'Pyramide · Volumen einer quadratischen Pyramide', 'Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 6 cm. Sie ist 10 cm hoch.

Wie groß ist ihr Volumen? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 6 cm. Sie ist 10 cm hoch.\n\nWie groß ist ihr Volumen? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: V = ⅓ · G · h mit quadratischer Grundfläche.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (drittel_vergessen, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b844a22a-3ad5-40aa-88df-8d6b10531307'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b844a22a-3ad5-40aa-88df-8d6b10531307'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b844a22a-3ad5-40aa-88df-8d6b10531307'::uuid,
  p_correct_answers => '["120","120 cm³","120cm³"]'::jsonb,
  p_solution        => 'G = (6 cm)² = 36 cm².
V = ⅓ · G · h = ⅓ · 36 cm² · 10 cm = 120 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ⅓ vergessen: 36 · 10 = 360.","socratic_question":"Wie viel von einem Prisma mit gleicher Grundfläche und Höhe füllt eine Pyramide?"},{"error":"Nur die Grundfläche berechnet, nicht das Volumen.","socratic_question":"Hast du die Höhe der Pyramide schon verwendet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"120","equivalents":["120 cm³","120cm³"],"known_errors":{"36":"falsche_groesse_beantwortet","360":"drittel_vergessen","360 cm³":"drittel_vergessen","360cm³":"drittel_vergessen","36 cm³":"falsche_groesse_beantwortet","36cm³":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 koerper-pyramide-02 · Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0f084da1-12ff-4672-9d00-dc5f65503c1a'::uuid, 'exercise', 'Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe', 'Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 8 cm. Die Pyramide ist 3 cm hoch. Jede dreieckige Seitenfläche hat die Höhe h_s = 5 cm.

Wie groß ist die Oberfläche der Pyramide? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 8 cm. Die Pyramide ist 3 cm hoch. Jede dreieckige Seitenfläche hat die Höhe h_s = 5 cm.\n\nWie groß ist die Oberfläche der Pyramide? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Grundfläche plus vier Dreiecke; die passende Höhe auswählen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_hoehe, halbieren_vergessen, volumen_statt_oberflaeche).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0f084da1-12ff-4672-9d00-dc5f65503c1a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0f084da1-12ff-4672-9d00-dc5f65503c1a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0f084da1-12ff-4672-9d00-dc5f65503c1a'::uuid,
  p_correct_answers => '["144","144 cm²","144cm²"]'::jsonb,
  p_solution        => 'Grundfläche: G = (8 cm)² = 64 cm².
Eine Seitenfläche: ½ · 8 cm · 5 cm = 20 cm², vier Seitenflächen: 80 cm².
O = 64 cm² + 80 cm² = 144 cm².
(Für die Dreiecke zählt die Seitenhöhe h_s, nicht die Körperhöhe.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Für die Seitenflächen die Körperhöhe 3 cm statt h_s = 5 cm verwendet.","socratic_question":"Welche Höhe steht senkrecht auf der Grundseite eines Seitendreiecks?"},{"error":"Bei den Dreiecken das ½ vergessen: 64 + 160 = 224.","socratic_question":"Wie berechnest du den Flächeninhalt eines Dreiecks?"},{"error":"Das Volumen berechnet statt der Oberfläche.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche aller Seiten gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"144","equivalents":["144 cm²","144cm²"],"known_errors":{"64":"volumen_statt_oberflaeche","112":"falsche_hoehe","224":"halbieren_vergessen","112 cm²":"falsche_hoehe","112cm²":"falsche_hoehe","224 cm²":"halbieren_vergessen","224cm²":"halbieren_vergessen","64 cm²":"volumen_statt_oberflaeche","64cm²":"volumen_statt_oberflaeche"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 koerper-pyramide-03 · Pyramide · Volumen mit rechteckiger Grundfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0d01fa82-d4fb-4fc4-ba47-62d7175763ee'::uuid, 'exercise', 'Pyramide · Volumen mit rechteckiger Grundfläche', 'Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 4,5 m und 3,2 m. Sie ist 5 m hoch.

Wie groß ist ihr Volumen in Kubikmetern? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 4,5 m und 3,2 m. Sie ist 5 m hoch.\n\nWie groß ist ihr Volumen in Kubikmetern? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: rechteckige Grundfläche mit Dezimalzahlen, dann V = ⅓ · G · h.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (drittel_vergessen, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0d01fa82-d4fb-4fc4-ba47-62d7175763ee'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0d01fa82-d4fb-4fc4-ba47-62d7175763ee'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0d01fa82-d4fb-4fc4-ba47-62d7175763ee'::uuid,
  p_correct_answers => '["24","24 m³","24m³"]'::jsonb,
  p_solution        => 'G = 4,5 m · 3,2 m = 14,4 m².
V = ⅓ · 14,4 m² · 5 m = ⅓ · 72 m³ = 24 m³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ⅓ vergessen: 14,4 · 5 = 72.","socratic_question":"Wie viel von einem Quader mit gleicher Grundfläche und Höhe füllt eine Pyramide?"},{"error":"Nur die Grundfläche berechnet, nicht das Volumen.","socratic_question":"Hast du die Höhe der Pyramide schon verwendet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"24","equivalents":["24 m³","24m³"],"known_errors":{"72":"drittel_vergessen","72 m³":"drittel_vergessen","72m³":"drittel_vergessen","14,4":"falsche_groesse_beantwortet","14.4":"falsche_groesse_beantwortet","14,4 m³":"falsche_groesse_beantwortet","14,4m³":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 koerper-pyramide-04 · Pyramide · Oberfläche mit rechteckiger Grundfläche
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7fc20c4b-923f-4225-8df0-b20680379b53'::uuid, 'exercise', 'Pyramide · Oberfläche mit rechteckiger Grundfläche', 'Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 10 cm und 4 cm. Die beiden dreieckigen Seitenflächen über den 10-cm-Seiten haben jeweils die Höhe 10 cm. Die beiden dreieckigen Seitenflächen über den 4-cm-Seiten haben jeweils die Höhe 11 cm.

Wie groß ist die Oberfläche der Pyramide? Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 10 cm und 4 cm. Die beiden dreieckigen Seitenflächen über den 10-cm-Seiten haben jeweils die Höhe 10 cm. Die beiden dreieckigen Seitenflächen über den 4-cm-Seiten haben jeweils die Höhe 11 cm.\n\nWie groß ist die Oberfläche der Pyramide? Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Sorten Seitendreiecke mit verschiedenen Seitenhöhen richtig zuordnen, dann Grundfläche plus Mantel.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_hoehe, halbieren_vergessen, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7fc20c4b-923f-4225-8df0-b20680379b53'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7fc20c4b-923f-4225-8df0-b20680379b53'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7fc20c4b-923f-4225-8df0-b20680379b53'::uuid,
  p_correct_answers => '["184","184 cm²","184cm²"]'::jsonb,
  p_solution        => 'Grundfläche: G = 10 cm · 4 cm = 40 cm².
Zwei Dreiecke über den 10-cm-Seiten: 2 · ½ · 10 cm · 10 cm = 100 cm².
Zwei Dreiecke über den 4-cm-Seiten: 2 · ½ · 4 cm · 11 cm = 44 cm².
O = 40 cm² + 100 cm² + 44 cm² = 184 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Seitenhöhen vertauscht: zur 10-cm-Seite die Höhe 11 cm genommen.","socratic_question":"Welche Höhe gehört zu dem Dreieck über der 10-cm-Seite?"},{"error":"Bei den Dreiecken das ½ vergessen: 40 + 200 + 88 = 328.","socratic_question":"Wie berechnest du den Flächeninhalt eines Dreiecks?"},{"error":"Nur die vier Seitenflächen berechnet, die Grundfläche fehlt.","socratic_question":"Gehört die rechteckige Grundfläche zur Oberfläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"184","equivalents":["184 cm²","184cm²"],"known_errors":{"144":"falsche_groesse_beantwortet","190":"falsche_hoehe","328":"halbieren_vergessen","190 cm²":"falsche_hoehe","190cm²":"falsche_hoehe","328 cm²":"halbieren_vergessen","328cm²":"halbieren_vergessen","144 cm²":"falsche_groesse_beantwortet","144cm²":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 koerper-pyramide-05 · Pyramide · Dachfläche eines Pyramidendachs
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5beb71a7-cbef-4392-bcca-446b1bc97354'::uuid, 'exercise', 'Pyramide · Dachfläche eines Pyramidendachs', 'Ein Turm hat ein Dach in Form einer quadratischen Pyramide. Die Grundkante ist 6 m lang. Das Dach ist 4 m hoch, jede dreieckige Dachfläche hat die Höhe h_s = 5 m.

Wie viele Quadratmeter Dachfläche müssen gedeckt werden? Der Boden des Dachs gehört nicht dazu. Gib das Ergebnis genau an, ohne zu runden.',
  '{"kind":"short_input","prompt":"Ein Turm hat ein Dach in Form einer quadratischen Pyramide. Die Grundkante ist 6 m lang. Das Dach ist 4 m hoch, jede dreieckige Dachfläche hat die Höhe h_s = 5 m.\n\nWie viele Quadratmeter Dachfläche müssen gedeckt werden? Der Boden des Dachs gehört nicht dazu. Gib das Ergebnis genau an, ohne zu runden."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm²', false, 1, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Dachfläche als vier Seitendreiecke erkennen, ohne Boden, mit der Seitenhöhe.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, falsche_hoehe, falsche_groesse_beantwortet).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5beb71a7-cbef-4392-bcca-446b1bc97354'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5beb71a7-cbef-4392-bcca-446b1bc97354'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5beb71a7-cbef-4392-bcca-446b1bc97354'::uuid,
  p_correct_answers => '["60","60 m²","60m²"]'::jsonb,
  p_solution        => 'Gedeckt werden nur die vier dreieckigen Dachflächen.
Eine Fläche: ½ · 6 m · 5 m = 15 m².
Dachfläche: 4 · 15 m² = 60 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bei den Dreiecken das ½ vergessen: 4 · 30 = 120.","socratic_question":"Wie berechnest du den Flächeninhalt eines Dreiecks?"},{"error":"Die Dachhöhe 4 m statt der Höhe der Dachfläche verwendet.","socratic_question":"Welche Höhe gehört zu einer dreieckigen Dachfläche?"},{"error":"Den Boden mitgezählt: ganze Oberfläche statt Dachfläche.","socratic_question":"Wird der Boden des Dachs auch gedeckt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"60","equivalents":["60 m²","60m²"],"known_errors":{"48":"falsche_hoehe","96":"falsche_groesse_beantwortet","120":"halbieren_vergessen","120 m²":"halbieren_vergessen","120m²":"halbieren_vergessen","48 m²":"falsche_hoehe","48m²":"falsche_hoehe","96 m²":"falsche_groesse_beantwortet","96m²":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 koerper-pyramide-06 · Pyramide · Grundkante aus Volumen und Höhe
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5cad7848-0d28-4198-93a0-6232e6f988b1'::uuid, 'exercise', 'Pyramide · Grundkante aus Volumen und Höhe', 'Eine Pyramide mit quadratischer Grundfläche hat das Volumen 192 cm³ und ist 9 cm hoch.

Wie lang ist eine Seite der Grundfläche? Runde, falls nötig, auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Pyramide mit quadratischer Grundfläche hat das Volumen 192 cm³ und ist 9 cm hoch.\n\nWie lang ist eine Seite der Grundfläche? Runde, falls nötig, auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_pyramide',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm', false, 2, 'draft', 'edvance_k9_koerper', 'koerper-pyramide-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung in zwei Schritten – aus V = ⅓ · G · h die Grundfläche, daraus die Seitenlänge.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (drittel_vergessen, wurzel_vergessen, mal_exponent).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5cad7848-0d28-4198-93a0-6232e6f988b1'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5cad7848-0d28-4198-93a0-6232e6f988b1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5cad7848-0d28-4198-93a0-6232e6f988b1'::uuid,
  p_correct_answers => '["8,00","8.00","8","8,00 cm","8,00cm","8 cm","8cm"]'::jsonb,
  p_solution        => 'V = ⅓ · G · h, also G = 3 · V : h = 3 · 192 cm³ : 9 cm = 64 cm².
G = a², also a = √64 cm = 8,00 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ⅓ vergessen: G = 192 : 9, a = √21,33.","socratic_question":"Wie viel von einem Prisma mit gleicher Grundfläche und Höhe füllt eine Pyramide?"},{"error":"Die Grundfläche 64 cm² angegeben statt der Seitenlänge.","socratic_question":"Ist nach einer Fläche oder nach einer Länge gefragt?"},{"error":"a² als 2 · a gelesen: a = 64 : 2 = 32.","socratic_question":"Was bedeutet a² – a · 2 oder a · a?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8,00","equivalents":["8.00","8","8,00 cm","8,00cm","8 cm","8cm"],"known_errors":{"32":"mal_exponent","64":"wurzel_vergessen","4,62":"drittel_vergessen","4.62":"drittel_vergessen","4,62 cm":"drittel_vergessen","4,62cm":"drittel_vergessen","64,00":"wurzel_vergessen","64.00":"wurzel_vergessen","64,00 cm":"wurzel_vergessen","64,00cm":"wurzel_vergessen","64 cm":"wurzel_vergessen","64cm":"wurzel_vergessen","32,00":"mal_exponent","32.00":"mal_exponent","32,00 cm":"mal_exponent","32,00cm":"mal_exponent","32 cm":"mal_exponent","32cm":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 koerper-kegel-01 · Kegel · Volumen, Radius 3 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd8f2e2e3-5cc2-4bd6-bf37-e752b0132bea'::uuid, 'exercise', 'Kegel · Volumen, Radius 3 cm', 'Ein Kegel hat den Radius 3 cm und die Höhe 8 cm.

Wie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kegel hat den Radius 3 cm und die Höhe 8 cm.\n\nWie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, 1, 'draft', 'edvance_k9_koerper', 'koerper-kegel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: V = ⅓ · π · r² · h mit gegebenem Radius und Höhe.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (drittel_vergessen, pi_vergessen, radius_durchmesser_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd8f2e2e3-5cc2-4bd6-bf37-e752b0132bea'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd8f2e2e3-5cc2-4bd6-bf37-e752b0132bea'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd8f2e2e3-5cc2-4bd6-bf37-e752b0132bea'::uuid,
  p_correct_answers => '["75,40","75.40","75,4","75.4","75,40 cm³","75,40cm³","75,4 cm³","75,4cm³","75,36","75.36","75,36 cm³","75,36cm³"]'::jsonb,
  p_solution        => 'V = ⅓ · π · r² · h = ⅓ · π · 9 cm² · 8 cm = π · 24 cm³ ≈ 75,40 cm³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 24 cm³ = 75,36 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ⅓ vergessen: π · 9 · 8 = π · 72.","socratic_question":"Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?"},{"error":"π weggelassen: ⅓ · 9 · 8 = 24.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"},{"error":"Den Radius wie einen Durchmesser halbiert.","socratic_question":"Ist 3 cm schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"75,40","equivalents":["75.40","75,4","75.4","75,40 cm³","75,40cm³","75,4 cm³","75,4cm³","75,36","75.36","75,36 cm³","75,36cm³"],"known_errors":{"24":"pi_vergessen","226,19":"drittel_vergessen","226.19":"drittel_vergessen","226,19 cm³":"drittel_vergessen","226,19cm³":"drittel_vergessen","226,08":"drittel_vergessen","226.08":"drittel_vergessen","226,08 cm³":"drittel_vergessen","226,08cm³":"drittel_vergessen","24,00":"pi_vergessen","24.00":"pi_vergessen","24,00 cm³":"pi_vergessen","24,00cm³":"pi_vergessen","24 cm³":"pi_vergessen","24cm³":"pi_vergessen","18,85":"radius_durchmesser_verwechselt","18.85":"radius_durchmesser_verwechselt","18,85 cm³":"radius_durchmesser_verwechselt","18,85cm³":"radius_durchmesser_verwechselt","18,84":"radius_durchmesser_verwechselt","18.84":"radius_durchmesser_verwechselt","18,84 cm³":"radius_durchmesser_verwechselt","18,84cm³":"radius_durchmesser_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 koerper-kegel-02 · Kegel · Mantellinie aus Radius und Höhe
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8a2febbd-299f-437a-abed-bde7fa31fa87'::uuid, 'exercise', 'Kegel · Mantellinie aus Radius und Höhe', 'Ein Kegel hat den Radius 5 cm und die Höhe 12 cm.

Wie lang ist seine Mantellinie s (die Strecke von der Spitze zum Rand der Grundfläche)? Runde, falls nötig, auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kegel hat den Radius 5 cm und die Höhe 12 cm.\n\nWie lang ist seine Mantellinie s (die Strecke von der Spitze zum Rand der Grundfläche)? Runde, falls nötig, auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kegel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Mantellinie mit dem Satz des Pythagoras, s = √(r² + h²).","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (wurzel_vergessen, hypotenuse_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8a2febbd-299f-437a-abed-bde7fa31fa87'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8a2febbd-299f-437a-abed-bde7fa31fa87'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8a2febbd-299f-437a-abed-bde7fa31fa87'::uuid,
  p_correct_answers => '["13,00","13.00","13","13,00 cm","13,00cm","13 cm","13cm"]'::jsonb,
  p_solution        => 'Radius, Höhe und Mantellinie bilden ein rechtwinkliges Dreieck, s ist die Hypotenuse.
s = √(r² + h²) = √(25 + 144) cm = √169 cm = 13,00 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wurzel nicht gezogen: s² = 169 als Länge angegeben.","socratic_question":"Hast du s oder s² ausgerechnet?"},{"error":"Die Quadrate subtrahiert statt addiert: √(144 − 25).","socratic_question":"Welche Seite liegt dem rechten Winkel gegenüber?"}]'::jsonb,
  p_acceptance      => '{"canonical":"13,00","equivalents":["13.00","13","13,00 cm","13,00cm","13 cm","13cm"],"known_errors":{"169":"wurzel_vergessen","169,00":"wurzel_vergessen","169.00":"wurzel_vergessen","169,00 cm":"wurzel_vergessen","169,00cm":"wurzel_vergessen","169 cm":"wurzel_vergessen","169cm":"wurzel_vergessen","10,91":"hypotenuse_verwechselt","10.91":"hypotenuse_verwechselt","10,91 cm":"hypotenuse_verwechselt","10,91cm":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 koerper-kegel-03 · Kegel · Oberfläche aus Durchmesser und Mantellinie
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9373d252-76e6-4ef7-be85-4b2c095cd55b'::uuid, 'exercise', 'Kegel · Oberfläche aus Durchmesser und Mantellinie', 'Ein Kegel hat den Durchmesser 12 cm und die Mantellinie s = 10 cm.

Wie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kegel hat den Durchmesser 12 cm und die Mantellinie s = 10 cm.\n\nWie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kegel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Radius aus dem Durchmesser, Grundfläche und Mantel M = π · r · s addieren.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, falsche_groesse_beantwortet, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9373d252-76e6-4ef7-be85-4b2c095cd55b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9373d252-76e6-4ef7-be85-4b2c095cd55b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9373d252-76e6-4ef7-be85-4b2c095cd55b'::uuid,
  p_correct_answers => '["301,59","301.59","301,59 cm²","301,59cm²","301,44","301.44","301,44 cm²","301,44cm²"]'::jsonb,
  p_solution        => 'r = 12 cm : 2 = 6 cm.
Grundfläche: π · (6 cm)² = π · 36 cm².
Mantel: M = π · r · s = π · 6 cm · 10 cm = π · 60 cm².
O = π · 96 cm² ≈ 301,59 cm² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 96 cm² = 301,44 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt.","socratic_question":"Ist 12 cm der Radius oder der Durchmesser?"},{"error":"Nur den Mantel berechnet, die Grundfläche fehlt.","socratic_question":"Gehört die runde Grundfläche zur Oberfläche?"},{"error":"π weggelassen: 36 + 60 = 96.","socratic_question":"Welcher Faktor gehört zu Kreisfläche und Mantel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"301,59","equivalents":["301.59","301,59 cm²","301,59cm²","301,44","301.44","301,44 cm²","301,44cm²"],"known_errors":{"96":"pi_vergessen","829,38":"radius_durchmesser_verwechselt","829.38":"radius_durchmesser_verwechselt","829,38 cm²":"radius_durchmesser_verwechselt","829,38cm²":"radius_durchmesser_verwechselt","828,96":"radius_durchmesser_verwechselt","828.96":"radius_durchmesser_verwechselt","828,96 cm²":"radius_durchmesser_verwechselt","828,96cm²":"radius_durchmesser_verwechselt","188,50":"falsche_groesse_beantwortet","188.50":"falsche_groesse_beantwortet","188,5":"falsche_groesse_beantwortet","188.5":"falsche_groesse_beantwortet","188,50 cm²":"falsche_groesse_beantwortet","188,50cm²":"falsche_groesse_beantwortet","188,5 cm²":"falsche_groesse_beantwortet","188,5cm²":"falsche_groesse_beantwortet","188,40":"falsche_groesse_beantwortet","188.40":"falsche_groesse_beantwortet","188,4":"falsche_groesse_beantwortet","188.4":"falsche_groesse_beantwortet","188,40 cm²":"falsche_groesse_beantwortet","188,40cm²":"falsche_groesse_beantwortet","188,4 cm²":"falsche_groesse_beantwortet","188,4cm²":"falsche_groesse_beantwortet","96,00":"pi_vergessen","96.00":"pi_vergessen","96,00 cm²":"pi_vergessen","96,00cm²":"pi_vergessen","96 cm²":"pi_vergessen","96cm²":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 koerper-kegel-04 · Kegel · Oberfläche aus Radius und Höhe
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '285e2d3e-44af-431b-a520-485795c8bb8d'::uuid, 'exercise', 'Kegel · Oberfläche aus Radius und Höhe', 'Ein Kegel hat den Radius 8 cm und die Höhe 6 cm.

Wie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kegel hat den Radius 8 cm und die Höhe 6 cm.\n\nWie groß ist seine Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm²', false, 2, 'draft', 'edvance_k9_koerper', 'koerper-kegel-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: erst die Mantellinie mit dem Satz des Pythagoras, dann Grundfläche plus Mantel.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_hoehe, wurzel_vergessen, hypotenuse_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '285e2d3e-44af-431b-a520-485795c8bb8d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '285e2d3e-44af-431b-a520-485795c8bb8d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '285e2d3e-44af-431b-a520-485795c8bb8d'::uuid,
  p_correct_answers => '["452,39","452.39","452,39 cm²","452,39cm²","452,16","452.16","452,16 cm²","452,16cm²"]'::jsonb,
  p_solution        => 's = √(r² + h²) = √(64 + 36) cm = √100 cm = 10 cm.
Grundfläche: π · 64 cm², Mantel: π · 8 cm · 10 cm = π · 80 cm².
O = π · 144 cm² ≈ 452,39 cm² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 144 cm² = 452,16 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Im Mantel die Höhe 6 cm statt der Mantellinie verwendet.","socratic_question":"Welche Strecke steht in der Mantelformel M = π · r · s?"},{"error":"Für s die Wurzel nicht gezogen: mit s = 100 gerechnet.","socratic_question":"Kann die Mantellinie länger sein als Radius und Höhe zusammen?"},{"error":"Für s die Quadrate subtrahiert statt addiert: √(64 − 36).","socratic_question":"Ist die Mantellinie kürzer oder länger als der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"452,39","equivalents":["452.39","452,39 cm²","452,39cm²","452,16","452.16","452,16 cm²","452,16cm²"],"known_errors":{"351,86":"falsche_hoehe","351.86":"falsche_hoehe","351,86 cm²":"falsche_hoehe","351,86cm²":"falsche_hoehe","351,68":"falsche_hoehe","351.68":"falsche_hoehe","351,68 cm²":"falsche_hoehe","351,68cm²":"falsche_hoehe","2714,34":"wurzel_vergessen","2714.34":"wurzel_vergessen","2714,34 cm²":"wurzel_vergessen","2714,34cm²":"wurzel_vergessen","2712,96":"wurzel_vergessen","2712.96":"wurzel_vergessen","2712,96 cm²":"wurzel_vergessen","2712,96cm²":"wurzel_vergessen","334,05":"hypotenuse_verwechselt","334.05":"hypotenuse_verwechselt","334,05 cm²":"hypotenuse_verwechselt","334,05cm²":"hypotenuse_verwechselt","333,88":"hypotenuse_verwechselt","333.88":"hypotenuse_verwechselt","333,88 cm²":"hypotenuse_verwechselt","333,88cm²":"hypotenuse_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 koerper-kegel-05 · Kegel · Trichter in Millilitern
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cd5d283c-6279-456d-8368-b7dbf8715e0f'::uuid, 'exercise', 'Kegel · Trichter in Millilitern', 'Ein kegelförmiger Trichter ist oben innen 6 cm breit und innen 12 cm tief. Es gilt 1 cm³ = 1 ml.

Wie viele Milliliter passen in den Trichter, wenn unten zugehalten wird? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Milliliter.',
  '{"kind":"short_input","prompt":"Ein kegelförmiger Trichter ist oben innen 6 cm breit und innen 12 cm tief. Es gilt 1 cm³ = 1 ml.\n\nWie viele Milliliter passen in den Trichter, wenn unten zugehalten wird? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Milliliter."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'ml', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kegel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Trichter als Kegel erkennen, Durchmesser halbieren, cm³ als ml angeben.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (drittel_vergessen, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cd5d283c-6279-456d-8368-b7dbf8715e0f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cd5d283c-6279-456d-8368-b7dbf8715e0f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cd5d283c-6279-456d-8368-b7dbf8715e0f'::uuid,
  p_correct_answers => '["113","113 ml","113ml"]'::jsonb,
  p_solution        => 'Die obere Öffnung ist der Durchmesser: r = 6 cm : 2 = 3 cm.
V = ⅓ · π · (3 cm)² · 12 cm = π · 36 cm³ ≈ 113,10 cm³ (π-Taste), mit 3,14: 113,04 cm³.
Gerundet: 113 ml (π-Taste), mit π ≈ 3,14 ebenfalls 113 ml.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Faktor ⅓ vergessen: π · 9 · 12 = π · 108.","socratic_question":"Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?"},{"error":"Die Breite 6 cm als Radius eingesetzt.","socratic_question":"Ist die Breite der Öffnung der Radius oder der Durchmesser?"},{"error":"π weggelassen: ⅓ · 9 · 12 = 36.","socratic_question":"Welcher Faktor gehört zur Kreisfläche?"}]'::jsonb,
  p_acceptance      => '{"canonical":"113","equivalents":["113 ml","113ml"],"known_errors":{"36":"pi_vergessen","339":"drittel_vergessen","452":"radius_durchmesser_verwechselt","339 ml":"drittel_vergessen","339ml":"drittel_vergessen","452 ml":"radius_durchmesser_verwechselt","452ml":"radius_durchmesser_verwechselt","36 ml":"pi_vergessen","36ml":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 koerper-kegel-06 · Kegel · Volumen aus Mantellinie und Radius
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e92deeb5-bccf-4343-b226-d7b2e0beb277'::uuid, 'exercise', 'Kegel · Volumen aus Mantellinie und Radius', 'Ein Kegel hat den Radius 8 cm und die Mantellinie s = 17 cm.

Wie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kegel hat den Radius 8 cm und die Mantellinie s = 17 cm.\n\nWie groß ist sein Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kegel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kegel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: die fehlende Höhe erst mit dem Satz des Pythagoras aus s und r gewinnen, dann das Volumen.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (hypotenuse_verwechselt, falsche_hoehe, drittel_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e92deeb5-bccf-4343-b226-d7b2e0beb277'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e92deeb5-bccf-4343-b226-d7b2e0beb277'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e92deeb5-bccf-4343-b226-d7b2e0beb277'::uuid,
  p_correct_answers => '["1005,31","1005.31","1005,31 cm³","1005,31cm³","1004,80","1004.80","1004,8","1004.8","1004,80 cm³","1004,80cm³","1004,8 cm³","1004,8cm³"]'::jsonb,
  p_solution        => 'Die Mantellinie ist die Hypotenuse: h = √(s² − r²) = √(289 − 64) cm = √225 cm = 15 cm.
V = ⅓ · π · 64 cm² · 15 cm = π · 320 cm³ ≈ 1005,31 cm³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 320 cm³ = 1004,80 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Für h die Quadrate addiert statt subtrahiert: √(289 + 64).","socratic_question":"Ist die Höhe kürzer oder länger als die Mantellinie?"},{"error":"Die Mantellinie 17 cm als Höhe eingesetzt.","socratic_question":"Steht die Mantellinie senkrecht auf der Grundfläche?"},{"error":"Den Faktor ⅓ vergessen: π · 64 · 15 = π · 960.","socratic_question":"Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1005,31","equivalents":["1005.31","1005,31 cm³","1005,31cm³","1004,80","1004.80","1004,8","1004.8","1004,80 cm³","1004,80cm³","1004,8 cm³","1004,8cm³"],"known_errors":{"1259,20":"hypotenuse_verwechselt","1259.20":"hypotenuse_verwechselt","1259,2":"hypotenuse_verwechselt","1259.2":"hypotenuse_verwechselt","1259,20 cm³":"hypotenuse_verwechselt","1259,20cm³":"hypotenuse_verwechselt","1259,2 cm³":"hypotenuse_verwechselt","1259,2cm³":"hypotenuse_verwechselt","1258,57":"hypotenuse_verwechselt","1258.57":"hypotenuse_verwechselt","1258,57 cm³":"hypotenuse_verwechselt","1258,57cm³":"hypotenuse_verwechselt","1139,35":"falsche_hoehe","1139.35":"falsche_hoehe","1139,35 cm³":"falsche_hoehe","1139,35cm³":"falsche_hoehe","1138,77":"falsche_hoehe","1138.77":"falsche_hoehe","1138,77 cm³":"falsche_hoehe","1138,77cm³":"falsche_hoehe","3015,93":"drittel_vergessen","3015.93":"drittel_vergessen","3015,93 cm³":"drittel_vergessen","3015,93cm³":"drittel_vergessen","3014,40":"drittel_vergessen","3014.40":"drittel_vergessen","3014,4":"drittel_vergessen","3014.4":"drittel_vergessen","3014,40 cm³":"drittel_vergessen","3014,40cm³":"drittel_vergessen","3014,4 cm³":"drittel_vergessen","3014,4cm³":"drittel_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 koerper-kugel-01 · Kugel · Volumen, Radius 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8c265caf-ebcd-4622-afbd-482483867036'::uuid, 'exercise', 'Kugel · Volumen, Radius 6 cm', 'Eine Kugel hat den Radius 6 cm.

Wie groß ist ihr Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Kugel hat den Radius 6 cm.\n\nWie groß ist ihr Volumen? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kugel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: V = 4/3 · π · r³ mit gegebenem Radius.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (oberflaeche_statt_volumen, radius_durchmesser_verwechselt, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8c265caf-ebcd-4622-afbd-482483867036'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8c265caf-ebcd-4622-afbd-482483867036'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8c265caf-ebcd-4622-afbd-482483867036'::uuid,
  p_correct_answers => '["904,78","904.78","904,78 cm³","904,78cm³","904,32","904.32","904,32 cm³","904,32cm³"]'::jsonb,
  p_solution        => 'V = 4/3 · π · r³ = 4/3 · π · 216 cm³ = π · 288 cm³ ≈ 904,78 cm³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 288 cm³ = 904,32 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Oberfläche berechnet statt des Volumens: 4 · π · 36.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche gefragt?"},{"error":"Den Radius wie einen Durchmesser halbiert.","socratic_question":"Ist 6 cm schon der Radius?"},{"error":"π weggelassen: 4/3 · 216 = 288.","socratic_question":"Welcher Faktor fehlt in der Volumenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"904,78","equivalents":["904.78","904,78 cm³","904,78cm³","904,32","904.32","904,32 cm³","904,32cm³"],"known_errors":{"288":"pi_vergessen","452,39":"oberflaeche_statt_volumen","452.39":"oberflaeche_statt_volumen","452,39 cm³":"oberflaeche_statt_volumen","452,39cm³":"oberflaeche_statt_volumen","452,16":"oberflaeche_statt_volumen","452.16":"oberflaeche_statt_volumen","452,16 cm³":"oberflaeche_statt_volumen","452,16cm³":"oberflaeche_statt_volumen","113,10":"radius_durchmesser_verwechselt","113.10":"radius_durchmesser_verwechselt","113,1":"radius_durchmesser_verwechselt","113.1":"radius_durchmesser_verwechselt","113,10 cm³":"radius_durchmesser_verwechselt","113,10cm³":"radius_durchmesser_verwechselt","113,1 cm³":"radius_durchmesser_verwechselt","113,1cm³":"radius_durchmesser_verwechselt","113,04":"radius_durchmesser_verwechselt","113.04":"radius_durchmesser_verwechselt","113,04 cm³":"radius_durchmesser_verwechselt","113,04cm³":"radius_durchmesser_verwechselt","288,00":"pi_vergessen","288.00":"pi_vergessen","288,00 cm³":"pi_vergessen","288,00cm³":"pi_vergessen","288 cm³":"pi_vergessen","288cm³":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 koerper-kugel-02 · Kugel · Oberfläche, Durchmesser 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '360647d6-fac1-40b9-a886-e1a5fdbe843c'::uuid, 'exercise', 'Kugel · Oberfläche, Durchmesser 10 cm', 'Eine Kugel hat den Durchmesser 10 cm.

Wie groß ist ihre Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Kugel hat den Durchmesser 10 cm.\n\nWie groß ist ihre Oberfläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kugel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Radius aus dem Durchmesser, dann O = 4 · π · r².","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, volumen_statt_oberflaeche, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '360647d6-fac1-40b9-a886-e1a5fdbe843c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '360647d6-fac1-40b9-a886-e1a5fdbe843c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '360647d6-fac1-40b9-a886-e1a5fdbe843c'::uuid,
  p_correct_answers => '["314,16","314.16","314,16 cm²","314,16cm²","314,00","314.00","314","314,00 cm²","314,00cm²","314 cm²","314cm²"]'::jsonb,
  p_solution        => 'r = 10 cm : 2 = 5 cm.
O = 4 · π · r² = 4 · π · 25 cm² = π · 100 cm² ≈ 314,16 cm² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 100 cm² = 314,00 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: 4 · π · 100.","socratic_question":"Ist 10 cm der Radius oder der Durchmesser?"},{"error":"Das Volumen berechnet statt der Oberfläche.","socratic_question":"Kommt bei deiner Rechnung cm² oder cm³ heraus?"},{"error":"π weggelassen: 4 · 25 = 100.","socratic_question":"Welcher Faktor fehlt in der Oberflächenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"314,16","equivalents":["314.16","314,16 cm²","314,16cm²","314,00","314.00","314","314,00 cm²","314,00cm²","314 cm²","314cm²"],"known_errors":{"100":"pi_vergessen","1256":"radius_durchmesser_verwechselt","1256,64":"radius_durchmesser_verwechselt","1256.64":"radius_durchmesser_verwechselt","1256,64 cm²":"radius_durchmesser_verwechselt","1256,64cm²":"radius_durchmesser_verwechselt","1256,00":"radius_durchmesser_verwechselt","1256.00":"radius_durchmesser_verwechselt","1256,00 cm²":"radius_durchmesser_verwechselt","1256,00cm²":"radius_durchmesser_verwechselt","1256 cm²":"radius_durchmesser_verwechselt","1256cm²":"radius_durchmesser_verwechselt","523,60":"volumen_statt_oberflaeche","523.60":"volumen_statt_oberflaeche","523,6":"volumen_statt_oberflaeche","523.6":"volumen_statt_oberflaeche","523,60 cm²":"volumen_statt_oberflaeche","523,60cm²":"volumen_statt_oberflaeche","523,6 cm²":"volumen_statt_oberflaeche","523,6cm²":"volumen_statt_oberflaeche","523,33":"volumen_statt_oberflaeche","523.33":"volumen_statt_oberflaeche","523,33 cm²":"volumen_statt_oberflaeche","523,33cm²":"volumen_statt_oberflaeche","100,00":"pi_vergessen","100.00":"pi_vergessen","100,00 cm²":"pi_vergessen","100,00cm²":"pi_vergessen","100 cm²":"pi_vergessen","100cm²":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 koerper-kugel-03 · Kugel · Volumen, Radius 2,5 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9cee13c3-67ba-418d-ab9d-819a5f8c3a46'::uuid, 'exercise', 'Kugel · Volumen, Radius 2,5 m', 'Eine Kugel hat den Radius 2,5 m.

Wie groß ist ihr Volumen in Kubikmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Kugel hat den Radius 2,5 m.\n\nWie groß ist ihr Volumen in Kubikmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm³', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kugel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: dritte Potenz einer Dezimalzahl in der Volumenformel.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, oberflaeche_statt_volumen, radius_durchmesser_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9cee13c3-67ba-418d-ab9d-819a5f8c3a46'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9cee13c3-67ba-418d-ab9d-819a5f8c3a46'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9cee13c3-67ba-418d-ab9d-819a5f8c3a46'::uuid,
  p_correct_answers => '["65,45","65.45","65,45 m³","65,45m³","65,42","65.42","65,42 m³","65,42m³"]'::jsonb,
  p_solution        => 'r³ = 2,5 · 2,5 · 2,5 m³ = 15,625 m³.
V = 4/3 · π · 15,625 m³ ≈ 65,45 m³ (π-Taste).
Mit π ≈ 3,14: V = 4/3 · 3,14 · 15,625 m³ ≈ 65,42 m³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2,5³ als 3 · 2,5 gerechnet.","socratic_question":"Was ist 2,5³ – 2,5 · 3 oder 2,5 · 2,5 · 2,5?"},{"error":"Die Oberfläche berechnet statt des Volumens.","socratic_question":"Ist nach dem Rauminhalt oder nach der Fläche gefragt?"},{"error":"Den Radius wie einen Durchmesser halbiert.","socratic_question":"Ist 2,5 m schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"65,45","equivalents":["65.45","65,45 m³","65,45m³","65,42","65.42","65,42 m³","65,42m³"],"known_errors":{"31,42":"mal_exponent","31.42":"mal_exponent","31,42 m³":"mal_exponent","31,42m³":"mal_exponent","31,40":"mal_exponent","31.40":"mal_exponent","31,4":"mal_exponent","31.4":"mal_exponent","31,40 m³":"mal_exponent","31,40m³":"mal_exponent","31,4 m³":"mal_exponent","31,4m³":"mal_exponent","78,54":"oberflaeche_statt_volumen","78.54":"oberflaeche_statt_volumen","78,54 m³":"oberflaeche_statt_volumen","78,54m³":"oberflaeche_statt_volumen","78,50":"oberflaeche_statt_volumen","78.50":"oberflaeche_statt_volumen","78,5":"oberflaeche_statt_volumen","78.5":"oberflaeche_statt_volumen","78,50 m³":"oberflaeche_statt_volumen","78,50m³":"oberflaeche_statt_volumen","78,5 m³":"oberflaeche_statt_volumen","78,5m³":"oberflaeche_statt_volumen","8,18":"radius_durchmesser_verwechselt","8.18":"radius_durchmesser_verwechselt","8,18 m³":"radius_durchmesser_verwechselt","8,18m³":"radius_durchmesser_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 koerper-kugel-04 · Kugel · Oberfläche in m², Radius 40 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd885cc27-a9b5-4390-ba21-3561d1b8a86f'::uuid, 'exercise', 'Kugel · Oberfläche in m², Radius 40 cm', 'Eine Kugel hat den Radius 40 cm.

Wie groß ist ihre Oberfläche in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Kugel hat den Radius 40 cm.\n\nWie groß ist ihre Oberfläche in Quadratmetern? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'm²', false, null, 'draft', 'edvance_k9_koerper', 'koerper-kugel-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Oberflächenformel plus Umrechnung von Zentimetern in Meter.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (einheit_uebersprungen, volumen_statt_oberflaeche, radius_durchmesser_verwechselt).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd885cc27-a9b5-4390-ba21-3561d1b8a86f'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd885cc27-a9b5-4390-ba21-3561d1b8a86f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd885cc27-a9b5-4390-ba21-3561d1b8a86f'::uuid,
  p_correct_answers => '["2,01","2.01","2,01 m²","2,01m²"]'::jsonb,
  p_solution        => 'r = 40 cm = 0,4 m.
O = 4 · π · (0,4 m)² = π · 0,64 m² ≈ 2,01 m² (π-Taste).
Mit π ≈ 3,14: O = 3,14 · 0,64 m² ≈ 2,01 m².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nicht umgerechnet: die Oberfläche in Quadratzentimetern.","socratic_question":"In welcher Einheit ist das Ergebnis gefragt?"},{"error":"Das Volumen berechnet statt der Oberfläche.","socratic_question":"Kommt bei deiner Rechnung m² oder m³ heraus?"},{"error":"Den Radius wie einen Durchmesser halbiert.","socratic_question":"Ist 40 cm schon der Radius?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,01","equivalents":["2.01","2,01 m²","2,01m²"],"known_errors":{"20096":"einheit_uebersprungen","20106,19":"einheit_uebersprungen","20106.19":"einheit_uebersprungen","20106,19 m²":"einheit_uebersprungen","20106,19m²":"einheit_uebersprungen","20096,00":"einheit_uebersprungen","20096.00":"einheit_uebersprungen","20096,00 m²":"einheit_uebersprungen","20096,00m²":"einheit_uebersprungen","20096 m²":"einheit_uebersprungen","20096m²":"einheit_uebersprungen","0,27":"volumen_statt_oberflaeche","0.27":"volumen_statt_oberflaeche","0,27 m²":"volumen_statt_oberflaeche","0,27m²":"volumen_statt_oberflaeche","0,50":"radius_durchmesser_verwechselt","0.50":"radius_durchmesser_verwechselt","0,5":"radius_durchmesser_verwechselt","0.5":"radius_durchmesser_verwechselt","0,50 m²":"radius_durchmesser_verwechselt","0,50m²":"radius_durchmesser_verwechselt","0,5 m²":"radius_durchmesser_verwechselt","0,5m²":"radius_durchmesser_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 koerper-kugel-05 · Kugel · kugelförmiger Behälter in Litern
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '62b5810c-b021-4032-b17a-e072ffa3182b'::uuid, 'exercise', 'Kugel · kugelförmiger Behälter in Litern', 'Ein kugelförmiger Behälter hat innen einen Durchmesser von 40 cm. Es gilt 1 dm³ = 1 l.

Wie viele Liter fasst der Behälter? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein kugelförmiger Behälter hat innen einen Durchmesser von 40 cm. Es gilt 1 dm³ = 1 l.\n\nWie viele Liter fasst der Behälter? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'l', false, 2, 'draft', 'edvance_k9_koerper', 'koerper-kugel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Durchmesser halbieren, in Dezimeter umrechnen, Volumen als Liter angeben.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (radius_durchmesser_verwechselt, oberflaeche_statt_volumen, liter_kubik_falsch, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '62b5810c-b021-4032-b17a-e072ffa3182b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = '62b5810c-b021-4032-b17a-e072ffa3182b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '62b5810c-b021-4032-b17a-e072ffa3182b'::uuid,
  p_correct_answers => '["33,5","33.5","33,5 l","33,5l"]'::jsonb,
  p_solution        => 'r = 40 cm : 2 = 20 cm = 2 dm.
V = 4/3 · π · (2 dm)³ = 4/3 · π · 8 dm³ ≈ 33,51 dm³ (π-Taste), mit 3,14: 33,49 dm³.
Gerundet: 33,5 l (π-Taste), mit π ≈ 3,14 ebenfalls 33,5 l.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchmesser als Radius eingesetzt: 4/3 · π · 4³.","socratic_question":"Ist 40 cm der Radius oder der Durchmesser?"},{"error":"Die Oberfläche berechnet statt des Volumens.","socratic_question":"Ist nach dem Inhalt oder nach der Hülle gefragt?"},{"error":"In Kubikzentimetern gerechnet und mit 1 l = 100 cm³ umgerechnet.","socratic_question":"Wie viele Kubikzentimeter hat ein Liter?"},{"error":"π weggelassen: 4/3 · 8 ≈ 10,7.","socratic_question":"Welcher Faktor fehlt in der Volumenformel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"33,5","equivalents":["33.5","33,5 l","33,5l"],"known_errors":{"268,1":"radius_durchmesser_verwechselt","268.1":"radius_durchmesser_verwechselt","268,1 l":"radius_durchmesser_verwechselt","268,1l":"radius_durchmesser_verwechselt","267,9":"radius_durchmesser_verwechselt","267.9":"radius_durchmesser_verwechselt","267,9 l":"radius_durchmesser_verwechselt","267,9l":"radius_durchmesser_verwechselt","50,3":"oberflaeche_statt_volumen","50.3":"oberflaeche_statt_volumen","50,3 l":"oberflaeche_statt_volumen","50,3l":"oberflaeche_statt_volumen","50,2":"oberflaeche_statt_volumen","50.2":"oberflaeche_statt_volumen","50,2 l":"oberflaeche_statt_volumen","50,2l":"oberflaeche_statt_volumen","335,1":"liter_kubik_falsch","335.1":"liter_kubik_falsch","335,1 l":"liter_kubik_falsch","335,1l":"liter_kubik_falsch","334,9":"liter_kubik_falsch","334.9":"liter_kubik_falsch","334,9 l":"liter_kubik_falsch","334,9l":"liter_kubik_falsch","10,7":"pi_vergessen","10.7":"pi_vergessen","10,7 l":"pi_vergessen","10,7l":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 koerper-kugel-06 · Kugel · Halbkugel auf einem Zylinder
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ec4153b3-7ecd-404b-a2a4-8f111e3f4186'::uuid, 'exercise', 'Kugel · Halbkugel auf einem Zylinder', 'Ein Körper besteht aus einem Zylinder mit aufgesetzter Halbkugel. Zylinder und Halbkugel haben beide den Durchmesser 6 cm. Der Zylinder ist 10 cm hoch.

Wie groß ist das Volumen des ganzen Körpers? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Körper besteht aus einem Zylinder mit aufgesetzter Halbkugel. Zylinder und Halbkugel haben beide den Durchmesser 6 cm. Der Zylinder ist 10 cm hoch.\n\nWie groß ist das Volumen des ganzen Körpers? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'geo_koerper_kugel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm³', false, 1, 'draft', 'edvance_k9_koerper', 'koerper-kugel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: zusammengesetzten Körper zerlegen, Halbkugel als halbe Kugel erkennen und Volumen addieren.","charge":"k9-koerper"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-koerper"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).","charge":"k9-koerper"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.","charge":"k9-koerper"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-5).","charge":"k9-koerper"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-koerper"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-koerper"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k9-koerper"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-koerper"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen, radius_durchmesser_verwechselt, falsche_groesse_beantwortet, pi_vergessen).","charge":"k9-koerper"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-koerper"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ec4153b3-7ecd-404b-a2a4-8f111e3f4186'::uuid and t.status = 'draft' and t.source = 'edvance_k9_koerper')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ec4153b3-7ecd-404b-a2a4-8f111e3f4186'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ec4153b3-7ecd-404b-a2a4-8f111e3f4186'::uuid,
  p_correct_answers => '["339,29","339.29","339,29 cm³","339,29cm³","339,12","339.12","339,12 cm³","339,12cm³"]'::jsonb,
  p_solution        => 'r = 6 cm : 2 = 3 cm.
Zylinder: π · (3 cm)² · 10 cm = π · 90 cm³.
Halbkugel: ½ · 4/3 · π · (3 cm)³ = π · 18 cm³.
V = π · 108 cm³ ≈ 339,29 cm³ (π-Taste).
Mit π ≈ 3,14: V = 3,14 · 108 cm³ = 339,12 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Eine ganze Kugel statt einer Halbkugel addiert.","socratic_question":"Wie viel von einer Kugel sitzt auf dem Zylinder?"},{"error":"Den Durchmesser als Radius eingesetzt.","socratic_question":"Ist 6 cm der Radius oder der Durchmesser?"},{"error":"Nur den Zylinder berechnet, die Halbkugel fehlt.","socratic_question":"Aus welchen Teilen besteht der Körper?"},{"error":"π weggelassen: 90 + 18 = 108.","socratic_question":"Welcher Faktor gehört zu Zylinder und Kugel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"339,29","equivalents":["339.29","339,29 cm³","339,29cm³","339,12","339.12","339,12 cm³","339,12cm³"],"known_errors":{"108":"pi_vergessen","395,84":"halbieren_vergessen","395.84":"halbieren_vergessen","395,84 cm³":"halbieren_vergessen","395,84cm³":"halbieren_vergessen","395,64":"halbieren_vergessen","395.64":"halbieren_vergessen","395,64 cm³":"halbieren_vergessen","395,64cm³":"halbieren_vergessen","1583,36":"radius_durchmesser_verwechselt","1583.36":"radius_durchmesser_verwechselt","1583,36 cm³":"radius_durchmesser_verwechselt","1583,36cm³":"radius_durchmesser_verwechselt","1582,56":"radius_durchmesser_verwechselt","1582.56":"radius_durchmesser_verwechselt","1582,56 cm³":"radius_durchmesser_verwechselt","1582,56cm³":"radius_durchmesser_verwechselt","282,74":"falsche_groesse_beantwortet","282.74":"falsche_groesse_beantwortet","282,74 cm³":"falsche_groesse_beantwortet","282,74cm³":"falsche_groesse_beantwortet","282,60":"falsche_groesse_beantwortet","282.60":"falsche_groesse_beantwortet","282,6":"falsche_groesse_beantwortet","282.6":"falsche_groesse_beantwortet","282,60 cm³":"falsche_groesse_beantwortet","282,60cm³":"falsche_groesse_beantwortet","282,6 cm³":"falsche_groesse_beantwortet","282,6cm³":"falsche_groesse_beantwortet","108,00":"pi_vergessen","108.00":"pi_vergessen","108,00 cm³":"pi_vergessen","108,00cm³":"pi_vergessen","108 cm³":"pi_vergessen","108cm³":"pi_vergessen"}}'::jsonb);
  end if;
end
$loesung$;
