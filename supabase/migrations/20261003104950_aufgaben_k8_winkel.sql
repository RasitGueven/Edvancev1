-- K8 Thales und Winkelsätze, Migration 2 von 2 — 24 Aufgaben, je sechs zu den vier geo_winkel_*-Knoten.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-winkel.json (Quelle: tools/k8-winkel-aufgaben.mjs,
-- tools/k8-winkel-aufgaben-2.mjs und tools/k8-winkel-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003104946_substrat_k8_winkel.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Leiter, Straßenkreuzung, Bahnschienen, Zaunlatten, Satteldach, Halbkreisfenster) oder Rückrichtung. Alle NUMERIC mit Einheit °, ganzzahlige Grad. Parallelen, Dreiecke und Thaleskreise sind als Text beschrieben (kein Generator zeichnet sie); zwei Aufgaben zu Neben- und Scheitelwinkel zeigen einen einzelnen Winkel (Generator winkel). Keine Konstruktionen, keine Hinweise, keine Personen.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-winkel.csv. Pruefprotokoll: docs/prefill/k8-winkel-verifikation.md.
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
--   geo_winkel_neben_scheitel: winkel-neben-01 = 1, winkel-neben-04 = 2. Rang 1 aus Profil {summe_360_statt_180,winkelbeziehung_verwechselt}, Rang 2 aus Profil {halbieren_vergessen,winkelbeziehung_verwechselt} (1 neue Fehlbilder)
--   geo_winkel_parallelen: winkel-parallel-05 = 1, winkel-parallel-02 = 2. Rang 1 aus Profil {summe_360_statt_180,winkelbeziehung_verwechselt}, Rang 2 aus Profil {winkelbeziehung_verwechselt} (0 neue Fehlbilder)
--   geo_winkel_dreieck: winkel-dreieck-01 = 1, winkel-dreieck-06 = 2. Rang 1 aus Profil {basiswinkel_falsch_zugeordnet,halbieren_vergessen,summe_360_statt_180}, Rang 2 aus Profil {aussenwinkel_verwechselt,differenz_vergessen} (2 neue Fehlbilder)
--   geo_winkel_thales: winkel-thales-05 = 1, winkel-thales-04 = 2. Rang 1 aus Profil {differenz_vergessen,rechter_winkel_falsche_ecke}, Rang 2 aus Profil {basiswinkel_falsch_zugeordnet,halbieren_vergessen} (2 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 winkel-neben-01 · Nebenwinkel · Winkel aus der Abbildung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid, 'exercise', 'Nebenwinkel · Winkel aus der Abbildung', 'Die Abbildung zeigt den Winkel α. Verlängert man einen seiner Schenkel über den Scheitel hinaus, entsteht ein Nebenwinkel von α.

Wie groß ist dieser Nebenwinkel?',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Winkel α. Verlängert man einen seiner Schenkel über den Scheitel hinaus, entsteht ein Nebenwinkel von α.\n\nWie groß ist dieser Nebenwinkel?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', true, 1, 'draft', 'edvance_k8_winkel', 'winkel-neben-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Nebenwinkel als Ergänzung zu 180°, Gradzahl im Bild.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Die Gradzahl steht nur in der Abbildung (Generator winkel, task_figures).","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid,
  p_correct_answers => '["130","+130","130 °","130°","+130 °","+130°"]'::jsonb,
  p_solution        => 'α = 50° (Abbildung).
Nebenwinkel ergänzen sich zu 180°: 180° - 50° = 130°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Nebenwinkel für gleich groß gehalten: 50°.","socratic_question":"Bilden α und sein Nebenwinkel zusammen eine gerade Linie? Wie viel Grad hat sie?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 50° = 310°.","socratic_question":"Ist der Nebenwinkel spitz, stumpf oder überstumpf?"}]'::jsonb,
  p_acceptance      => '{"canonical":"130","equivalents":["+130","130 °","130°","+130 °","+130°"],"known_errors":{"50":"winkelbeziehung_verwechselt","310":"summe_360_statt_180","+50":"winkelbeziehung_verwechselt","50 °":"winkelbeziehung_verwechselt","50°":"winkelbeziehung_verwechselt","+50 °":"winkelbeziehung_verwechselt","+50°":"winkelbeziehung_verwechselt","+310":"summe_360_statt_180","310 °":"summe_360_statt_180","310°":"summe_360_statt_180","+310 °":"summe_360_statt_180","+310°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid, 'winkel', '{"grad":50,"benennung":"α","mit_bogen":true}'::jsonb, 'Ein Winkel α: zwei Schenkel mit gemeinsamem Scheitel, Winkelbogen und Gradangabe.'
 where exists (select 1 from public.tasks t where t.id = 'a2f85a2b-0c8c-4eae-a78c-5a97f39d2fbd'::uuid and t.source = 'edvance_k8_winkel')
on conflict (task_id) do nothing;

-- #2 winkel-neben-02 · Scheitelwinkel · Winkel aus der Abbildung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid, 'exercise', 'Scheitelwinkel · Winkel aus der Abbildung', 'Die Abbildung zeigt den Winkel α. Verlängert man beide Schenkel über den Scheitel hinaus, entsteht gegenüber von α sein Scheitelwinkel.

Wie groß ist der Scheitelwinkel von α?',
  '{"kind":"short_input","prompt":"Die Abbildung zeigt den Winkel α. Verlängert man beide Schenkel über den Scheitel hinaus, entsteht gegenüber von α sein Scheitelwinkel.\n\nWie groß ist der Scheitelwinkel von α?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', true, null, 'draft', 'edvance_k8_winkel', 'winkel-neben-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Scheitelwinkel sind gleich groß, Gradzahl im Bild.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Die Gradzahl steht nur in der Abbildung (Generator winkel, task_figures).","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (winkelbeziehung_verwechselt).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid,
  p_correct_answers => '["115","+115","115 °","115°","+115 °","+115°"]'::jsonb,
  p_solution        => 'α = 115° (Abbildung).
Scheitelwinkel sind gleich groß: Der Scheitelwinkel ist 115°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Scheitelwinkel wie einen Nebenwinkel zu 180° ergänzt: 180° - 115° = 65°.","socratic_question":"Liegt der gesuchte Winkel neben α oder gegenüber?"}]'::jsonb,
  p_acceptance      => '{"canonical":"115","equivalents":["+115","115 °","115°","+115 °","+115°"],"known_errors":{"65":"winkelbeziehung_verwechselt","+65":"winkelbeziehung_verwechselt","65 °":"winkelbeziehung_verwechselt","65°":"winkelbeziehung_verwechselt","+65 °":"winkelbeziehung_verwechselt","+65°":"winkelbeziehung_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;
insert into public.task_figures (task_id, generator, params, alt_text)
select 'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid, 'winkel', '{"grad":115,"benennung":"α","mit_bogen":true}'::jsonb, 'Ein Winkel α: zwei Schenkel mit gemeinsamem Scheitel, Winkelbogen und Gradangabe.'
 where exists (select 1 from public.tasks t where t.id = 'f0c5bda4-158b-4117-9239-7261065e16bb'::uuid and t.source = 'edvance_k8_winkel')
on conflict (task_id) do nothing;

-- #3 winkel-neben-03 · Nebenwinkel · Schnitt zweier Geraden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c0b1c3c5-0c12-4815-bce5-377fca8504c4'::uuid, 'exercise', 'Nebenwinkel · Schnitt zweier Geraden', 'Zwei Geraden schneiden sich im Punkt S. Rund um S liegen der Reihe nach die vier Winkel α, β, γ und δ: α liegt γ gegenüber, β liegt δ gegenüber. Der Winkel α ist 72° groß.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Zwei Geraden schneiden sich im Punkt S. Rund um S liegen der Reihe nach die vier Winkel α, β, γ und δ: α liegt γ gegenüber, β liegt δ gegenüber. Der Winkel α ist 72° groß.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-neben-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Lage aus dem Text erschließen (β liegt neben α), dann Nebenwinkel.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c0b1c3c5-0c12-4815-bce5-377fca8504c4'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c0b1c3c5-0c12-4815-bce5-377fca8504c4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c0b1c3c5-0c12-4815-bce5-377fca8504c4'::uuid,
  p_correct_answers => '["108","+108","108 °","108°","+108 °","+108°"]'::jsonb,
  p_solution        => 'β liegt neben α, beide zusammen bilden eine gerade Linie: Nebenwinkel.
β = 180° - 72° = 108°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"β für den Scheitelwinkel von α gehalten: 72°.","socratic_question":"Liegt β gegenüber von α oder direkt daneben?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 72° = 288°.","socratic_question":"Wie viel Grad haben zwei Winkel, die zusammen eine gerade Linie bilden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"108","equivalents":["+108","108 °","108°","+108 °","+108°"],"known_errors":{"72":"winkelbeziehung_verwechselt","288":"summe_360_statt_180","+72":"winkelbeziehung_verwechselt","72 °":"winkelbeziehung_verwechselt","72°":"winkelbeziehung_verwechselt","+72 °":"winkelbeziehung_verwechselt","+72°":"winkelbeziehung_verwechselt","+288":"summe_360_statt_180","288 °":"summe_360_statt_180","288°":"summe_360_statt_180","+288 °":"summe_360_statt_180","+288°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 winkel-neben-04 · Neben- und Scheitelwinkel · Summe zweier Gegenwinkel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e04364d3-e946-4be1-8aca-0b3b1c52353d'::uuid, 'exercise', 'Neben- und Scheitelwinkel · Summe zweier Gegenwinkel', 'Zwei Geraden schneiden sich im Punkt S. Rund um S liegen der Reihe nach die vier Winkel α, β, γ und δ: α liegt γ gegenüber, β liegt δ gegenüber. Die Winkel α und γ sind zusammen 140° groß.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Zwei Geraden schneiden sich im Punkt S. Rund um S liegen der Reihe nach die vier Winkel α, β, γ und δ: α liegt γ gegenüber, β liegt δ gegenüber. Die Winkel α und γ sind zusammen 140° groß.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  60, '°', false, 2, 'draft', 'edvance_k8_winkel', 'winkel-neben-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Scheitelwinkel (α = γ) und Nebenwinkel kombinieren, zwei Schritte.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (winkelbeziehung_verwechselt, halbieren_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e04364d3-e946-4be1-8aca-0b3b1c52353d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e04364d3-e946-4be1-8aca-0b3b1c52353d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e04364d3-e946-4be1-8aca-0b3b1c52353d'::uuid,
  p_correct_answers => '["110","+110","110 °","110°","+110 °","+110°"]'::jsonb,
  p_solution        => 'α und γ sind Scheitelwinkel, also gleich groß: α = 140° : 2 = 70°.
β ist Nebenwinkel von α: β = 180° - 70° = 110°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"β für gleich groß wie α gehalten: 70°.","socratic_question":"Liegt β gegenüber von α oder direkt daneben?"},{"error":"β und δ zusammen berechnet, aber nicht halbiert: 360° - 140° = 220°.","socratic_question":"Ist 220° ein einzelner Winkel oder zwei zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"110","equivalents":["+110","110 °","110°","+110 °","+110°"],"known_errors":{"70":"winkelbeziehung_verwechselt","220":"halbieren_vergessen","+70":"winkelbeziehung_verwechselt","70 °":"winkelbeziehung_verwechselt","70°":"winkelbeziehung_verwechselt","+70 °":"winkelbeziehung_verwechselt","+70°":"winkelbeziehung_verwechselt","+220":"halbieren_vergessen","220 °":"halbieren_vergessen","220°":"halbieren_vergessen","+220 °":"halbieren_vergessen","+220°":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 winkel-neben-05 · Nebenwinkel · Leiter auf dem Boden
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9e26a451-8496-4a05-9f4d-752d05fcddf9'::uuid, 'exercise', 'Nebenwinkel · Leiter auf dem Boden', 'Eine gerade Leiter lehnt an einer Wand und steht auf einem waagerechten Boden. Auf der Seite zur Wand hin bilden Leiter und Boden einen Winkel von 68°.

Wie groß ist der Winkel zwischen Leiter und Boden auf der anderen Seite der Leiter, von der Wand weg?',
  '{"kind":"short_input","prompt":"Eine gerade Leiter lehnt an einer Wand und steht auf einem waagerechten Boden. Auf der Seite zur Wand hin bilden Leiter und Boden einen Winkel von 68°.\n\nWie groß ist der Winkel zwischen Leiter und Boden auf der anderen Seite der Leiter, von der Wand weg?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren',
  90, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-neben-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Die beiden Winkel am Fuß der Leiter als Nebenwinkel erkennen.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9e26a451-8496-4a05-9f4d-752d05fcddf9'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9e26a451-8496-4a05-9f4d-752d05fcddf9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9e26a451-8496-4a05-9f4d-752d05fcddf9'::uuid,
  p_correct_answers => '["112","+112","112 °","112°","+112 °","+112°"]'::jsonb,
  p_solution        => 'Der Boden ist eine gerade Linie; die Leiter teilt den gestreckten Winkel am Fuß in zwei Nebenwinkel.
180° - 68° = 112°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Winkel auf der anderen Seite für gleich groß gehalten: 68°.","socratic_question":"Ergeben die beiden Winkel am Fuß der Leiter zusammen den geraden Boden?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 68° = 292°.","socratic_question":"Wie viel Grad hat der gerade Boden an der Stelle, an der die Leiter steht?"}]'::jsonb,
  p_acceptance      => '{"canonical":"112","equivalents":["+112","112 °","112°","+112 °","+112°"],"known_errors":{"68":"winkelbeziehung_verwechselt","292":"summe_360_statt_180","+68":"winkelbeziehung_verwechselt","68 °":"winkelbeziehung_verwechselt","68°":"winkelbeziehung_verwechselt","+68 °":"winkelbeziehung_verwechselt","+68°":"winkelbeziehung_verwechselt","+292":"summe_360_statt_180","292 °":"summe_360_statt_180","292°":"summe_360_statt_180","+292 °":"summe_360_statt_180","+292°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 winkel-neben-06 · Nebenwinkel · Kreuzung, ein Winkel viermal so groß
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7849cb37-1c84-425f-956a-44213a721a9f'::uuid, 'exercise', 'Nebenwinkel · Kreuzung, ein Winkel viermal so groß', 'Zwei gerade Straßen kreuzen sich. An der Kreuzung entstehen vier Winkel. Einer davon ist viermal so groß wie ein Winkel, der direkt neben ihm liegt.

Wie groß ist der kleinere dieser beiden Winkel?',
  '{"kind":"short_input","prompt":"Zwei gerade Straßen kreuzen sich. An der Kreuzung entstehen vier Winkel. Einer davon ist viermal so groß wie ein Winkel, der direkt neben ihm liegt.\n\nWie groß ist der kleinere dieser beiden Winkel?"}'::jsonb, 'NUMERIC', 'geo_winkel_neben_scheitel',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  90, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-neben-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Rückrichtung: aus dem Verhältnis zweier Nebenwinkel und ihrer Summe 180° den kleineren bestimmen.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7849cb37-1c84-425f-956a-44213a721a9f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7849cb37-1c84-425f-956a-44213a721a9f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7849cb37-1c84-425f-956a-44213a721a9f'::uuid,
  p_correct_answers => '["36","+36","36 °","36°","+36 °","+36°"]'::jsonb,
  p_solution        => 'Zwei Winkel, die direkt nebeneinander liegen, sind Nebenwinkel: zusammen 180°.
Kleiner Winkel x, großer 4x: x + 4x = 5x = 180°, also x = 36°.
(Probe: 4 · 36° = 144°, 36° + 144° = 180°.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 360° statt 180° gerechnet: 360° : 5 = 72°.","socratic_question":"Wie viel Grad haben zwei Winkel, die direkt nebeneinander an einer geraden Straße liegen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"36","equivalents":["+36","36 °","36°","+36 °","+36°"],"known_errors":{"72":"summe_360_statt_180","+72":"summe_360_statt_180","72 °":"summe_360_statt_180","72°":"summe_360_statt_180","+72 °":"summe_360_statt_180","+72°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 winkel-parallel-01 · Stufenwinkel · benannt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e1fa2b31-a4fb-44ca-848b-188d7d7ca0dd'::uuid, 'exercise', 'Stufenwinkel · benannt', 'Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 65° groß. Der Winkel β liegt bei B oberhalb von h und rechts von s. α und β sind Stufenwinkel.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 65° groß. Der Winkel β liegt bei B oberhalb von h und rechts von s. α und β sind Stufenwinkel.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-parallel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Stufenwinkel an Parallelen sind gleich groß, Beziehung genannt.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (winkelbeziehung_verwechselt).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e1fa2b31-a4fb-44ca-848b-188d7d7ca0dd'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e1fa2b31-a4fb-44ca-848b-188d7d7ca0dd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e1fa2b31-a4fb-44ca-848b-188d7d7ca0dd'::uuid,
  p_correct_answers => '["65","+65","65 °","65°","+65 °","+65°"]'::jsonb,
  p_solution        => 'Stufenwinkel an parallelen Geraden sind gleich groß: β = α = 65°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Stufenwinkel zu 180° ergänzt: 180° - 65° = 115°.","socratic_question":"Liegen α und β an ihrer Geraden an derselben Stelle – oben rechts?"}]'::jsonb,
  p_acceptance      => '{"canonical":"65","equivalents":["+65","65 °","65°","+65 °","+65°"],"known_errors":{"115":"winkelbeziehung_verwechselt","+115":"winkelbeziehung_verwechselt","115 °":"winkelbeziehung_verwechselt","115°":"winkelbeziehung_verwechselt","+115 °":"winkelbeziehung_verwechselt","+115°":"winkelbeziehung_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 winkel-parallel-02 · Wechselwinkel · benannt
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'facf174b-aad5-41c4-9f42-916eaafd9e20'::uuid, 'exercise', 'Wechselwinkel · benannt', 'Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 48° groß. Der Winkel β liegt bei B oberhalb von h und links von s. α und β sind Wechselwinkel.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 48° groß. Der Winkel β liegt bei B oberhalb von h und links von s. α und β sind Wechselwinkel.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, 2, 'draft', 'edvance_k8_winkel', 'winkel-parallel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Wechselwinkel an Parallelen sind gleich groß, Beziehung genannt.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (winkelbeziehung_verwechselt).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'facf174b-aad5-41c4-9f42-916eaafd9e20'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'facf174b-aad5-41c4-9f42-916eaafd9e20'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'facf174b-aad5-41c4-9f42-916eaafd9e20'::uuid,
  p_correct_answers => '["48","+48","48 °","48°","+48 °","+48°"]'::jsonb,
  p_solution        => 'Wechselwinkel an parallelen Geraden sind gleich groß: β = α = 48°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Wechselwinkel zu 180° ergänzt: 180° - 48° = 132°.","socratic_question":"Was gilt für Wechselwinkel an Parallelen: gleich groß oder zusammen 180°?"}]'::jsonb,
  p_acceptance      => '{"canonical":"48","equivalents":["+48","48 °","48°","+48 °","+48°"],"known_errors":{"132":"winkelbeziehung_verwechselt","+132":"winkelbeziehung_verwechselt","132 °":"winkelbeziehung_verwechselt","132°":"winkelbeziehung_verwechselt","+132 °":"winkelbeziehung_verwechselt","+132°":"winkelbeziehung_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 winkel-parallel-03 · Stufen- und Nebenwinkel · Lage gegeben
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f9f4e093-605a-4c0a-87da-172d58b74ae0'::uuid, 'exercise', 'Stufen- und Nebenwinkel · Lage gegeben', 'Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 70° groß. Der Winkel β liegt bei B oberhalb von h und links von s.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 70° groß. Der Winkel β liegt bei B oberhalb von h und links von s.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-parallel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Beziehung selbst erkennen, zwei Schritte (Stufenwinkel, dann Nebenwinkel).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f9f4e093-605a-4c0a-87da-172d58b74ae0'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f9f4e093-605a-4c0a-87da-172d58b74ae0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f9f4e093-605a-4c0a-87da-172d58b74ae0'::uuid,
  p_correct_answers => '["110","+110","110 °","110°","+110 °","+110°"]'::jsonb,
  p_solution        => 'Bei B oberhalb von h und rechts von s liegt der Stufenwinkel von α: 70°.
β ist dessen Nebenwinkel: β = 180° - 70° = 110°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"β für einen Stufenwinkel von α gehalten: 70°.","socratic_question":"Liegt β bei B auf derselben Seite von s wie α bei A?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 70° = 290°.","socratic_question":"Wie viel Grad haben zwei Nebenwinkel zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"110","equivalents":["+110","110 °","110°","+110 °","+110°"],"known_errors":{"70":"winkelbeziehung_verwechselt","290":"summe_360_statt_180","+70":"winkelbeziehung_verwechselt","70 °":"winkelbeziehung_verwechselt","70°":"winkelbeziehung_verwechselt","+70 °":"winkelbeziehung_verwechselt","+70°":"winkelbeziehung_verwechselt","+290":"summe_360_statt_180","290 °":"summe_360_statt_180","290°":"summe_360_statt_180","+290 °":"summe_360_statt_180","+290°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 winkel-parallel-04 · Wechsel-, Stufen- und Nebenwinkel · Lage gegeben
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '83a2860a-f361-447a-a164-c3d71a545095'::uuid, 'exercise', 'Wechsel-, Stufen- und Nebenwinkel · Lage gegeben', 'Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 105° groß. Der Winkel β liegt bei B unterhalb von h und links von s.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B. Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 105° groß. Der Winkel β liegt bei B unterhalb von h und links von s.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-parallel-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Beziehung selbst erkennen, Kette aus Nebenwinkel und Wechselwinkel.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '83a2860a-f361-447a-a164-c3d71a545095'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '83a2860a-f361-447a-a164-c3d71a545095'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '83a2860a-f361-447a-a164-c3d71a545095'::uuid,
  p_correct_answers => '["75","+75","75 °","75°","+75 °","+75°"]'::jsonb,
  p_solution        => 'Bei A oberhalb von g und rechts von s liegt der Nebenwinkel von α: 180° - 105° = 75°.
Dessen Stufenwinkel bei B (oberhalb von h, rechts von s) ist ebenfalls 75°, und β ist sein Scheitelwinkel: β = 75°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"β für gleich groß wie α gehalten: 105°.","socratic_question":"Ist β spitz oder stumpf, wenn α stumpf ist und β auf der anderen Seite von s liegt?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 105° = 255°.","socratic_question":"Kann ein Winkel zwischen zwei Geraden größer als 180° sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"75","equivalents":["+75","75 °","75°","+75 °","+75°"],"known_errors":{"105":"winkelbeziehung_verwechselt","255":"summe_360_statt_180","+105":"winkelbeziehung_verwechselt","105 °":"winkelbeziehung_verwechselt","105°":"winkelbeziehung_verwechselt","+105 °":"winkelbeziehung_verwechselt","+105°":"winkelbeziehung_verwechselt","+255":"summe_360_statt_180","255 °":"summe_360_statt_180","255°":"summe_360_statt_180","+255 °":"summe_360_statt_180","+255°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 winkel-parallel-05 · Nachbarwinkel · Weg über zwei Bahnschienen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c648786e-49ab-4451-bd09-85f9c82c4d1d'::uuid, 'exercise', 'Nachbarwinkel · Weg über zwei Bahnschienen', 'Zwei gerade Bahnschienen verlaufen parallel. Ein gerader Weg überquert beide Schienen schräg. Zwischen den Schienen bildet der Weg mit der ersten Schiene auf der rechten Seite des Weges einen Winkel von 58°.

Wie groß ist der Winkel, den der Weg zwischen den Schienen mit der zweiten Schiene auf der rechten Seite des Weges bildet?',
  '{"kind":"short_input","prompt":"Zwei gerade Bahnschienen verlaufen parallel. Ein gerader Weg überquert beide Schienen schräg. Zwischen den Schienen bildet der Weg mit der ersten Schiene auf der rechten Seite des Weges einen Winkel von 58°.\n\nWie groß ist der Winkel, den der Weg zwischen den Schienen mit der zweiten Schiene auf der rechten Seite des Weges bildet?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren',
  90, '°', false, 1, 'draft', 'edvance_k8_winkel', 'winkel-parallel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Lage übersetzen, Beziehung selbst erkennen (Ergänzung zu 180°).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'c648786e-49ab-4451-bd09-85f9c82c4d1d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c648786e-49ab-4451-bd09-85f9c82c4d1d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'c648786e-49ab-4451-bd09-85f9c82c4d1d'::uuid,
  p_correct_answers => '["122","+122","122 °","122°","+122 °","+122°"]'::jsonb,
  p_solution        => 'Schienen = Parallelen, Weg = schneidende Gerade. Beide Winkel liegen zwischen den Schienen auf derselben Seite des Weges.
Der Stufenwinkel des 58°-Winkels an der zweiten Schiene liegt außerhalb der Schienen; der gesuchte Winkel ist sein Nebenwinkel: 180° - 58° = 122°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die beiden Winkel für gleich groß gehalten: 58°.","socratic_question":"Liegen beide Winkel auf derselben Seite des Weges und zwischen den Schienen – was gilt dann?"},{"error":"Zu 360° statt zu 180° ergänzt: 360° - 58° = 302°.","socratic_question":"Kann der Winkel zwischen Weg und Schiene größer als 180° sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"122","equivalents":["+122","122 °","122°","+122 °","+122°"],"known_errors":{"58":"winkelbeziehung_verwechselt","302":"summe_360_statt_180","+58":"winkelbeziehung_verwechselt","58 °":"winkelbeziehung_verwechselt","58°":"winkelbeziehung_verwechselt","+58 °":"winkelbeziehung_verwechselt","+58°":"winkelbeziehung_verwechselt","+302":"summe_360_statt_180","302 °":"summe_360_statt_180","302°":"summe_360_statt_180","+302 °":"summe_360_statt_180","+302°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 winkel-parallel-06 · Wechselwinkel · schräge Querlatte am Zaun
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'dce9301f-2897-4941-b2e7-87d6d6995ccb'::uuid, 'exercise', 'Wechselwinkel · schräge Querlatte am Zaun', 'Bei einem Gartenzaun stehen die senkrechten Latten parallel zueinander. Eine gerade Querlatte ist schräg über alle Latten genagelt. An der ersten Latte schließen Latte und Querlatte oberhalb der Querlatte und rechts der Latte einen Winkel von 112° ein.

Wie groß ist an der zweiten Latte, die rechts neben der ersten steht, der Winkel unterhalb der Querlatte und links der Latte?',
  '{"kind":"short_input","prompt":"Bei einem Gartenzaun stehen die senkrechten Latten parallel zueinander. Eine gerade Querlatte ist schräg über alle Latten genagelt. An der ersten Latte schließen Latte und Querlatte oberhalb der Querlatte und rechts der Latte einen Winkel von 112° ein.\n\nWie groß ist an der zweiten Latte, die rechts neben der ersten steht, der Winkel unterhalb der Querlatte und links der Latte?"}'::jsonb, 'NUMERIC', 'geo_winkel_parallelen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren',
  90, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-parallel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Beziehung selbst erkennen (Wechselwinkel zwischen zwei Latten).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (winkelbeziehung_verwechselt).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'dce9301f-2897-4941-b2e7-87d6d6995ccb'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'dce9301f-2897-4941-b2e7-87d6d6995ccb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'dce9301f-2897-4941-b2e7-87d6d6995ccb'::uuid,
  p_correct_answers => '["112","+112","112 °","112°","+112 °","+112°"]'::jsonb,
  p_solution        => 'Latten = Parallelen, Querlatte = schneidende Gerade. Beide Winkel liegen zwischen den beiden Latten, auf verschiedenen Seiten der Querlatte: Wechselwinkel.
Wechselwinkel sind gleich groß: 112°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Wechselwinkel zu 180° ergänzt: 180° - 112° = 68°.","socratic_question":"Liegen die beiden Winkel auf derselben Seite der Querlatte oder auf verschiedenen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"112","equivalents":["+112","112 °","112°","+112 °","+112°"],"known_errors":{"68":"winkelbeziehung_verwechselt","+68":"winkelbeziehung_verwechselt","68 °":"winkelbeziehung_verwechselt","68°":"winkelbeziehung_verwechselt","+68 °":"winkelbeziehung_verwechselt","+68°":"winkelbeziehung_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 winkel-dreieck-01 · Basiswinkel · aus dem Winkel an der Spitze
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e26cdb23-39dd-4547-b72f-0d73ef7a247c'::uuid, 'exercise', 'Basiswinkel · aus dem Winkel an der Spitze', 'Das Dreieck ABC ist gleichschenklig mit den gleich langen Seiten AC und BC. Der Winkel γ bei C ist 40° groß.

Wie groß ist der Winkel α bei A?',
  '{"kind":"short_input","prompt":"Das Dreieck ABC ist gleichschenklig mit den gleich langen Seiten AC und BC. Der Winkel γ bei C ist 40° groß.\n\nWie groß ist der Winkel α bei A?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, 1, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Basiswinkelsatz und Winkelsumme, Spitze gegeben.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e26cdb23-39dd-4547-b72f-0d73ef7a247c'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e26cdb23-39dd-4547-b72f-0d73ef7a247c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e26cdb23-39dd-4547-b72f-0d73ef7a247c'::uuid,
  p_correct_answers => '["70","+70","70 °","70°","+70 °","+70°"]'::jsonb,
  p_solution        => 'C liegt zwischen den gleich langen Seiten, also ist γ der Winkel an der Spitze; α und β sind die gleich großen Basiswinkel.
α = (180° - 40°) : 2 = 70°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Winkel an der Spitze für einen Basiswinkel gehalten: α = 40°.","socratic_question":"Welche Ecke liegt zwischen den beiden gleich langen Seiten?"},{"error":"Den Rest für beide Basiswinkel zusammen nicht halbiert: 180° - 40° = 140°.","socratic_question":"Wie viele Basiswinkel teilen sich die restlichen 140°?"},{"error":"Mit 360° statt 180° als Winkelsumme gerechnet: (360° - 40°) : 2 = 160°.","socratic_question":"Wie groß ist die Winkelsumme in einem Dreieck?"}]'::jsonb,
  p_acceptance      => '{"canonical":"70","equivalents":["+70","70 °","70°","+70 °","+70°"],"known_errors":{"40":"basiswinkel_falsch_zugeordnet","140":"halbieren_vergessen","160":"summe_360_statt_180","+40":"basiswinkel_falsch_zugeordnet","40 °":"basiswinkel_falsch_zugeordnet","40°":"basiswinkel_falsch_zugeordnet","+40 °":"basiswinkel_falsch_zugeordnet","+40°":"basiswinkel_falsch_zugeordnet","+140":"halbieren_vergessen","140 °":"halbieren_vergessen","140°":"halbieren_vergessen","+140 °":"halbieren_vergessen","+140°":"halbieren_vergessen","+160":"summe_360_statt_180","160 °":"summe_360_statt_180","160°":"summe_360_statt_180","+160 °":"summe_360_statt_180","+160°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 winkel-dreieck-02 · Außenwinkel · aus zwei Innenwinkeln
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b86dc520-f0cc-4ef1-b931-56c66ca4729f'::uuid, 'exercise', 'Außenwinkel · aus zwei Innenwinkeln', 'Im Dreieck ABC ist α = 50° und β = 60°. Der Außenwinkel bei C liegt zwischen der Seite BC und der Verlängerung der Seite AC über C hinaus; er ist der Nebenwinkel von γ.

Wie groß ist der Außenwinkel bei C?',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist α = 50° und β = 60°. Der Außenwinkel bei C liegt zwischen der Seite BC und der Verlängerung der Seite AC über C hinaus; er ist der Nebenwinkel von γ.\n\nWie groß ist der Außenwinkel bei C?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Außenwinkel als Nebenwinkel des Innenwinkels (oder Außenwinkelsatz).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (aussenwinkel_verwechselt).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b86dc520-f0cc-4ef1-b931-56c66ca4729f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b86dc520-f0cc-4ef1-b931-56c66ca4729f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b86dc520-f0cc-4ef1-b931-56c66ca4729f'::uuid,
  p_correct_answers => '["110","+110","110 °","110°","+110 °","+110°"]'::jsonb,
  p_solution        => 'γ = 180° - 50° - 60° = 70°.
Außenwinkel bei C = 180° - 70° = 110°.
(Außenwinkelsatz: 50° + 60° = 110°.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Innenwinkel γ angegeben statt des Außenwinkels: 70°.","socratic_question":"Liegt der gesuchte Winkel innerhalb oder außerhalb des Dreiecks?"}]'::jsonb,
  p_acceptance      => '{"canonical":"110","equivalents":["+110","110 °","110°","+110 °","+110°"],"known_errors":{"70":"aussenwinkel_verwechselt","+70":"aussenwinkel_verwechselt","70 °":"aussenwinkel_verwechselt","70°":"aussenwinkel_verwechselt","+70 °":"aussenwinkel_verwechselt","+70°":"aussenwinkel_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 winkel-dreieck-03 · Dreieck und Parallele · Winkel bei B
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '90281ee4-13f9-4108-939c-5220439e4c71'::uuid, 'exercise', 'Dreieck und Parallele · Winkel bei B', 'Im Dreieck ABC liegt A links und B rechts. Die Gerade g geht durch C und ist parallel zur Seite AB. Auf g liegt links von C der Punkt P und rechts von C der Punkt Q. Der Winkel ∠PCA ist 52° groß, der Winkel γ = ∠ACB ist 67° groß.

Wie groß ist der Winkel β bei B?',
  '{"kind":"short_input","prompt":"Im Dreieck ABC liegt A links und B rechts. Die Gerade g geht durch C und ist parallel zur Seite AB. Auf g liegt links von C der Punkt P und rechts von C der Punkt Q. Der Winkel ∠PCA ist 52° groß, der Winkel γ = ∠ACB ist 67° groß.\n\nWie groß ist der Winkel β bei B?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: gestreckter Winkel auf g und Wechselwinkel an Parallelen kombinieren.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '90281ee4-13f9-4108-939c-5220439e4c71'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '90281ee4-13f9-4108-939c-5220439e4c71'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '90281ee4-13f9-4108-939c-5220439e4c71'::uuid,
  p_correct_answers => '["61","+61","61 °","61°","+61 °","+61°"]'::jsonb,
  p_solution        => 'Auf g bilden ∠PCA, γ und ∠QCB zusammen einen gestreckten Winkel: ∠QCB = 180° - 52° - 67° = 61°.
∠QCB und β sind Wechselwinkel an den Parallelen g und AB: β = 61°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die beiden bekannten Winkel nur addiert, nicht von 180° abgezogen: 52° + 67° = 119°.","socratic_question":"Wie viel Grad haben die drei Winkel auf der Geraden g bei C zusammen?"},{"error":"Mit 360° statt 180° gerechnet: 360° - 52° - 67° = 241°.","socratic_question":"Bilden die drei Winkel bei C eine gerade Linie oder eine volle Drehung?"}]'::jsonb,
  p_acceptance      => '{"canonical":"61","equivalents":["+61","61 °","61°","+61 °","+61°"],"known_errors":{"119":"differenz_vergessen","241":"summe_360_statt_180","+119":"differenz_vergessen","119 °":"differenz_vergessen","119°":"differenz_vergessen","+119 °":"differenz_vergessen","+119°":"differenz_vergessen","+241":"summe_360_statt_180","241 °":"summe_360_statt_180","241°":"summe_360_statt_180","+241 °":"summe_360_statt_180","+241°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 winkel-dreieck-04 · Außenwinkel · gleichschenkliges Dreieck
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '875bb8b8-fd63-4cc6-989d-c0c41029dd5d'::uuid, 'exercise', 'Außenwinkel · gleichschenkliges Dreieck', 'Das Dreieck ABC ist gleichschenklig mit den gleich langen Seiten AC und BC. Der Winkel γ bei C ist 50° groß. Der Außenwinkel bei A liegt zwischen der Seite AC und der Verlängerung der Seite BA über A hinaus.

Wie groß ist der Außenwinkel bei A?',
  '{"kind":"short_input","prompt":"Das Dreieck ABC ist gleichschenklig mit den gleich langen Seiten AC und BC. Der Winkel γ bei C ist 50° groß. Der Außenwinkel bei A liegt zwischen der Seite AC und der Verlängerung der Seite BA über A hinaus.\n\nWie groß ist der Außenwinkel bei A?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Basiswinkelsatz, Winkelsumme und Außenwinkel in drei Schritten.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (aussenwinkel_verwechselt, basiswinkel_falsch_zugeordnet).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '875bb8b8-fd63-4cc6-989d-c0c41029dd5d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '875bb8b8-fd63-4cc6-989d-c0c41029dd5d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '875bb8b8-fd63-4cc6-989d-c0c41029dd5d'::uuid,
  p_correct_answers => '["115","+115","115 °","115°","+115 °","+115°"]'::jsonb,
  p_solution        => 'γ liegt an der Spitze, α und β sind Basiswinkel: α = (180° - 50°) : 2 = 65°.
Außenwinkel bei A = 180° - 65° = 115°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Innenwinkel α angegeben statt des Außenwinkels: 65°.","socratic_question":"Liegt der gesuchte Winkel innerhalb oder außerhalb des Dreiecks?"},{"error":"γ als Basiswinkel bei A genommen und davon den Außenwinkel gebildet: 180° - 50° = 130°.","socratic_question":"Welche Ecke liegt zwischen den beiden gleich langen Seiten?"}]'::jsonb,
  p_acceptance      => '{"canonical":"115","equivalents":["+115","115 °","115°","+115 °","+115°"],"known_errors":{"65":"aussenwinkel_verwechselt","130":"basiswinkel_falsch_zugeordnet","+65":"aussenwinkel_verwechselt","65 °":"aussenwinkel_verwechselt","65°":"aussenwinkel_verwechselt","+65 °":"aussenwinkel_verwechselt","+65°":"aussenwinkel_verwechselt","+130":"basiswinkel_falsch_zugeordnet","130 °":"basiswinkel_falsch_zugeordnet","130°":"basiswinkel_falsch_zugeordnet","+130 °":"basiswinkel_falsch_zugeordnet","+130°":"basiswinkel_falsch_zugeordnet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 winkel-dreieck-05 · Basiswinkel · Neigung eines Satteldachs
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1a1092b8-1ddd-4b8a-9560-7647b94f4307'::uuid, 'exercise', 'Basiswinkel · Neigung eines Satteldachs', 'Der Querschnitt eines Satteldachs ist ein gleichschenkliges Dreieck: Die beiden Dachflächen sind gleich lang, die Grundseite ist der waagerechte Dachboden. Oben am First schließen die beiden Dachflächen einen Winkel von 110° ein.

Wie groß ist der Winkel zwischen einer Dachfläche und dem Dachboden?',
  '{"kind":"short_input","prompt":"Der Querschnitt eines Satteldachs ist ein gleichschenkliges Dreieck: Die beiden Dachflächen sind gleich lang, die Grundseite ist der waagerechte Dachboden. Oben am First schließen die beiden Dachflächen einen Winkel von 110° ein.\n\nWie groß ist der Winkel zwischen einer Dachfläche und dem Dachboden?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren',
  90, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Querschnitt als gleichschenkliges Dreieck lesen, Spitze am First.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1a1092b8-1ddd-4b8a-9560-7647b94f4307'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1a1092b8-1ddd-4b8a-9560-7647b94f4307'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1a1092b8-1ddd-4b8a-9560-7647b94f4307'::uuid,
  p_correct_answers => '["35","+35","35 °","35°","+35 °","+35°"]'::jsonb,
  p_solution        => 'Der First liegt zwischen den gleich langen Dachflächen: Er ist die Spitze. Die Winkel am Dachboden sind die gleich großen Basiswinkel.
(180° - 110°) : 2 = 35°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Winkel am First für einen Basiswinkel gehalten: 110°.","socratic_question":"Liegt der Winkel am First zwischen den beiden gleich langen Seiten oder an der Grundseite?"},{"error":"Den Rest für beide Basiswinkel zusammen nicht halbiert: 180° - 110° = 70°.","socratic_question":"Auf wie viele Winkel am Dachboden verteilen sich die restlichen 70°?"},{"error":"Mit 360° statt 180° als Winkelsumme gerechnet: (360° - 110°) : 2 = 125°.","socratic_question":"Wie groß ist die Winkelsumme in einem Dreieck?"}]'::jsonb,
  p_acceptance      => '{"canonical":"35","equivalents":["+35","35 °","35°","+35 °","+35°"],"known_errors":{"70":"halbieren_vergessen","110":"basiswinkel_falsch_zugeordnet","125":"summe_360_statt_180","+110":"basiswinkel_falsch_zugeordnet","110 °":"basiswinkel_falsch_zugeordnet","110°":"basiswinkel_falsch_zugeordnet","+110 °":"basiswinkel_falsch_zugeordnet","+110°":"basiswinkel_falsch_zugeordnet","+70":"halbieren_vergessen","70 °":"halbieren_vergessen","70°":"halbieren_vergessen","+70 °":"halbieren_vergessen","+70°":"halbieren_vergessen","+125":"summe_360_statt_180","125 °":"summe_360_statt_180","125°":"summe_360_statt_180","+125 °":"summe_360_statt_180","+125°":"summe_360_statt_180"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 winkel-dreieck-06 · Außenwinkel · Rückrichtung, Innenwinkel gesucht
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fee2cf1f-4ecc-4f68-ab73-03fdcee03528'::uuid, 'exercise', 'Außenwinkel · Rückrichtung, Innenwinkel gesucht', 'Im Dreieck ABC ist α = 48°. Der Außenwinkel bei C (der Nebenwinkel von γ) ist 125° groß.

Wie groß ist der Winkel β bei B?',
  '{"kind":"short_input","prompt":"Im Dreieck ABC ist α = 48°. Der Außenwinkel bei C (der Nebenwinkel von γ) ist 125° groß.\n\nWie groß ist der Winkel β bei B?"}'::jsonb, 'NUMERIC', 'geo_winkel_dreieck',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen',
  90, '°', false, 2, 'draft', 'edvance_k8_winkel', 'winkel-dreieck-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Rückrichtung: aus Außenwinkel und einem Innenwinkel den dritten Winkel erschließen.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (aussenwinkel_verwechselt, differenz_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fee2cf1f-4ecc-4f68-ab73-03fdcee03528'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fee2cf1f-4ecc-4f68-ab73-03fdcee03528'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fee2cf1f-4ecc-4f68-ab73-03fdcee03528'::uuid,
  p_correct_answers => '["77","+77","77 °","77°","+77 °","+77°"]'::jsonb,
  p_solution        => 'γ = 180° - 125° = 55°.
β = 180° - 48° - 55° = 77°.
(Außenwinkelsatz: 125° = 48° + β, also β = 77°.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Außenwinkel wie den Innenwinkel γ verwendet: 180° - 125° - 48° = 7°.","socratic_question":"Ist 125° der Winkel im Dreieck bei C oder der daneben?"},{"error":"Die beiden gegebenen Winkel addiert statt subtrahiert: 125° + 48° = 173°.","socratic_question":"Der Außenwinkel ist so groß wie zwei Innenwinkel zusammen – welcher davon fehlt noch?"}]'::jsonb,
  p_acceptance      => '{"canonical":"77","equivalents":["+77","77 °","77°","+77 °","+77°"],"known_errors":{"7":"aussenwinkel_verwechselt","173":"differenz_vergessen","+7":"aussenwinkel_verwechselt","7 °":"aussenwinkel_verwechselt","7°":"aussenwinkel_verwechselt","+7 °":"aussenwinkel_verwechselt","+7°":"aussenwinkel_verwechselt","+173":"differenz_vergessen","173 °":"differenz_vergessen","173°":"differenz_vergessen","+173 °":"differenz_vergessen","+173°":"differenz_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 winkel-thales-01 · Thales · Winkel β aus α
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9f171c32-9786-4617-b2e4-161c88071ea5'::uuid, 'exercise', 'Thales · Winkel β aus α', 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 35° groß.

Wie groß ist β?',
  '{"kind":"short_input","prompt":"Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 35° groß.\n\nWie groß ist β?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-thales-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Satz des Thales (γ = 90°) und Winkelsumme.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (rechter_winkel_falsche_ecke, differenz_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9f171c32-9786-4617-b2e4-161c88071ea5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9f171c32-9786-4617-b2e4-161c88071ea5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9f171c32-9786-4617-b2e4-161c88071ea5'::uuid,
  p_correct_answers => '["55","+55","55 °","55°","+55 °","+55°"]'::jsonb,
  p_solution        => 'C liegt auf dem Kreis über dem Durchmesser AB: Nach dem Satz des Thales ist γ = 90°.
β = 180° - 90° - 35° = 55°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den rechten Winkel bei B statt bei C angenommen: β = 90°.","socratic_question":"Welche Ecke liegt auf dem Kreis und nicht am Durchmesser?"},{"error":"Die bekannten Winkel nur addiert, nicht von 180° abgezogen: 90° + 35° = 125°.","socratic_question":"Wie groß ist die Winkelsumme, und was fehlt noch bis dahin?"}]'::jsonb,
  p_acceptance      => '{"canonical":"55","equivalents":["+55","55 °","55°","+55 °","+55°"],"known_errors":{"90":"rechter_winkel_falsche_ecke","125":"differenz_vergessen","+90":"rechter_winkel_falsche_ecke","90 °":"rechter_winkel_falsche_ecke","90°":"rechter_winkel_falsche_ecke","+90 °":"rechter_winkel_falsche_ecke","+90°":"rechter_winkel_falsche_ecke","+125":"differenz_vergessen","125 °":"differenz_vergessen","125°":"differenz_vergessen","+125 °":"differenz_vergessen","+125°":"differenz_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 winkel-thales-02 · Thales · Winkel bei C
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '22e90366-5528-4685-993e-42e88f3623f6'::uuid, 'exercise', 'Thales · Winkel bei C', 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 28° groß.

Wie groß ist γ?',
  '{"kind":"short_input","prompt":"Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 28° groß.\n\nWie groß ist γ?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-thales-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Satz des Thales erkennen, der gegebene Winkel ist Ablenkung.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Satz (Beziehung genannt oder direkt erkennbar).","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (rechter_winkel_falsche_ecke).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '22e90366-5528-4685-993e-42e88f3623f6'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '22e90366-5528-4685-993e-42e88f3623f6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '22e90366-5528-4685-993e-42e88f3623f6'::uuid,
  p_correct_answers => '["90","+90","90 °","90°","+90 °","+90°"]'::jsonb,
  p_solution        => 'C liegt auf dem Kreis über dem Durchmesser AB: Nach dem Satz des Thales ist γ = 90°, unabhängig von α.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den rechten Winkel bei B angenommen und γ aus der Winkelsumme berechnet: 180° - 90° - 28° = 62°.","socratic_question":"Welche Ecke liegt dem Durchmesser gegenüber?"}]'::jsonb,
  p_acceptance      => '{"canonical":"90","equivalents":["+90","90 °","90°","+90 °","+90°"],"known_errors":{"62":"rechter_winkel_falsche_ecke","+62":"rechter_winkel_falsche_ecke","62 °":"rechter_winkel_falsche_ecke","62°":"rechter_winkel_falsche_ecke","+62 °":"rechter_winkel_falsche_ecke","+62°":"rechter_winkel_falsche_ecke"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 winkel-thales-03 · Thales · Winkel am Mittelpunkt-Dreieck AMC
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9e7c1e4b-d317-44cf-8865-071c653ef2cf'::uuid, 'exercise', 'Thales · Winkel am Mittelpunkt-Dreieck AMC', 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 40° groß.

Wie groß ist der Winkel ∠ACM zwischen den Strecken CA und CM?',
  '{"kind":"short_input","prompt":"Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel α ist 40° groß.\n\nWie groß ist der Winkel ∠ACM zwischen den Strecken CA und CM?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  60, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-thales-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Dreieck AMC als gleichschenklig erkennen (MA = MC = Radius).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (basiswinkel_falsch_zugeordnet).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9e7c1e4b-d317-44cf-8865-071c653ef2cf'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9e7c1e4b-d317-44cf-8865-071c653ef2cf'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9e7c1e4b-d317-44cf-8865-071c653ef2cf'::uuid,
  p_correct_answers => '["40","+40","40 °","40°","+40 °","+40°"]'::jsonb,
  p_solution        => 'MA und MC sind Radien, also gleich lang: Das Dreieck AMC ist gleichschenklig mit der Spitze M.
Die Basiswinkel bei A und C sind gleich: ∠ACM = α = 40°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"α für den Winkel an der Spitze von Dreieck AMC gehalten: (180° - 40°) : 2 = 70°.","socratic_question":"Welche Ecke von Dreieck AMC liegt zwischen den beiden gleich langen Radien?"}]'::jsonb,
  p_acceptance      => '{"canonical":"40","equivalents":["+40","40 °","40°","+40 °","+40°"],"known_errors":{"70":"basiswinkel_falsch_zugeordnet","+70":"basiswinkel_falsch_zugeordnet","70 °":"basiswinkel_falsch_zugeordnet","70°":"basiswinkel_falsch_zugeordnet","+70 °":"basiswinkel_falsch_zugeordnet","+70°":"basiswinkel_falsch_zugeordnet"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 winkel-thales-04 · Thales · α aus dem Winkel bei M
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9ca300e1-76b9-4bb9-96cf-44cfda31824b'::uuid, 'exercise', 'Thales · α aus dem Winkel bei M', 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel ∠BMC zwischen den Strecken MB und MC ist 64° groß.

Wie groß ist α?',
  '{"kind":"short_input","prompt":"Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel ∠BMC zwischen den Strecken MB und MC ist 64° groß.\n\nWie groß ist α?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Problemlösen',
  60, '°', false, 2, 'draft', 'edvance_k8_winkel', 'winkel-thales-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Nebenwinkel bei M, dann gleichschenkliges Dreieck AMC (zwei Schritte).","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (basiswinkel_falsch_zugeordnet, halbieren_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9ca300e1-76b9-4bb9-96cf-44cfda31824b'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9ca300e1-76b9-4bb9-96cf-44cfda31824b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9ca300e1-76b9-4bb9-96cf-44cfda31824b'::uuid,
  p_correct_answers => '["32","+32","32 °","32°","+32 °","+32°"]'::jsonb,
  p_solution        => '∠AMC ist Nebenwinkel von ∠BMC: 180° - 64° = 116°.
Das Dreieck AMC ist gleichschenklig (MA = MC), Spitze M: α = (180° - 116°) : 2 = 32°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"64° als Basiswinkel β im Dreieck BMC genommen, dann α = 90° - 64° = 26°.","socratic_question":"Liegt der Winkel bei M zwischen den beiden gleich langen Radien?"},{"error":"Den Rest im Dreieck AMC nicht halbiert: 180° - 116° = 64°.","socratic_question":"Auf wie viele gleich große Winkel verteilen sich die restlichen 64° im Dreieck AMC?"}]'::jsonb,
  p_acceptance      => '{"canonical":"32","equivalents":["+32","32 °","32°","+32 °","+32°"],"known_errors":{"26":"basiswinkel_falsch_zugeordnet","64":"halbieren_vergessen","+26":"basiswinkel_falsch_zugeordnet","26 °":"basiswinkel_falsch_zugeordnet","26°":"basiswinkel_falsch_zugeordnet","+26 °":"basiswinkel_falsch_zugeordnet","+26°":"basiswinkel_falsch_zugeordnet","+64":"halbieren_vergessen","64 °":"halbieren_vergessen","64°":"halbieren_vergessen","+64 °":"halbieren_vergessen","+64°":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 winkel-thales-05 · Thales · Streben im Halbkreisfenster
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '11aebc7c-d30e-4577-89d5-52efed7d379f'::uuid, 'exercise', 'Thales · Streben im Halbkreisfenster', 'Ein Fenster hat oben einen Halbkreisbogen. Die waagerechte Unterkante AB des Bogens ist ein Durchmesser des Halbkreises. Eine gerade Strebe verläuft von A zu einem Punkt C auf dem Bogen, eine zweite von C zu B. Die Strebe AC bildet mit der Unterkante einen Winkel von 32°.

Wie groß ist der Winkel zwischen der Strebe CB und der Unterkante?',
  '{"kind":"short_input","prompt":"Ein Fenster hat oben einen Halbkreisbogen. Die waagerechte Unterkante AB des Bogens ist ein Durchmesser des Halbkreises. Eine gerade Strebe verläuft von A zu einem Punkt C auf dem Bogen, eine zweite von C zu B. Die Strebe AC bildet mit der Unterkante einen Winkel von 32°.\n\nWie groß ist der Winkel zwischen der Strebe CB und der Unterkante?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren',
  90, '°', false, 1, 'draft', 'edvance_k8_winkel', 'winkel-thales-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Thales-Situation im Fenster erkennen, dann Winkelsumme.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Sachsituation (Leiter, Kreuzung, Schienen, Zaun, Dach, Fenster) in eine Winkelfigur übersetzen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (rechter_winkel_falsche_ecke, differenz_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '11aebc7c-d30e-4577-89d5-52efed7d379f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '11aebc7c-d30e-4577-89d5-52efed7d379f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '11aebc7c-d30e-4577-89d5-52efed7d379f'::uuid,
  p_correct_answers => '["58","+58","58 °","58°","+58 °","+58°"]'::jsonb,
  p_solution        => 'AB ist Durchmesser, C liegt auf dem Bogen: Nach dem Satz des Thales ist der Winkel bei C ein rechter.
Winkel bei B = 180° - 90° - 32° = 58°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den rechten Winkel bei B angenommen: 90°.","socratic_question":"Welche Ecke des Dreiecks liegt auf dem Bogen?"},{"error":"Die bekannten Winkel nur addiert: 90° + 32° = 122°.","socratic_question":"Was muss mit 122° noch geschehen, damit der dritte Winkel herauskommt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"58","equivalents":["+58","58 °","58°","+58 °","+58°"],"known_errors":{"90":"rechter_winkel_falsche_ecke","122":"differenz_vergessen","+90":"rechter_winkel_falsche_ecke","90 °":"rechter_winkel_falsche_ecke","90°":"rechter_winkel_falsche_ecke","+90 °":"rechter_winkel_falsche_ecke","+90°":"rechter_winkel_falsche_ecke","+122":"differenz_vergessen","122 °":"differenz_vergessen","122°":"differenz_vergessen","+122 °":"differenz_vergessen","+122°":"differenz_vergessen"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 winkel-thales-06 · Thales · Rückrichtung über die Winkel bei M
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3e087e16-bd3e-4489-b3d9-6c6759c4ce74'::uuid, 'exercise', 'Thales · Rückrichtung über die Winkel bei M', 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel ∠AMC ist um 40° größer als der Winkel ∠BMC.

Wie groß ist α?',
  '{"kind":"short_input","prompt":"Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel ∠AMC ist um 40° größer als der Winkel ∠BMC.\n\nWie groß ist α?"}'::jsonb, 'NUMERIC', 'geo_winkel_thales',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen',
  90, '°', false, null, 'draft', 'edvance_k8_winkel', 'winkel-thales-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Rückrichtung: Winkel bei M aus Summe und Unterschied bestimmen, dann gleichschenkliges Dreieck AMC.","charge":"k8-winkel"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k8-winkel"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 NRW, Erste Stufe, Geometrie (Geo-1, Geo-2, Geo-7); in Köln üblich in Klasse 8.","charge":"k8-winkel"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_winkel_summe und geo_flaeche_* im Bestand.","charge":"k8-winkel"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Winkelbeziehungen, Winkelsätze, Satz des Thales).","charge":"k8-winkel"},"competency_process":{"art":"neu","grund":"Beziehung selbst erkennen oder Rückrichtung: Weg finden, dann rechnen.","charge":"k8-winkel"},"needs_image":{"art":"neu","grund":"Alle Angaben und die Lage stehen im Text, keine Abbildung nötig.","charge":"k8-winkel"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit und ohne Plus, mit und ohne °.","charge":"k8-winkel"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-winkel"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (halbieren_vergessen).","charge":"k8-winkel"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-winkel"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3e087e16-bd3e-4489-b3d9-6c6759c4ce74'::uuid and t.status = 'draft' and t.source = 'edvance_k8_winkel')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3e087e16-bd3e-4489-b3d9-6c6759c4ce74'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3e087e16-bd3e-4489-b3d9-6c6759c4ce74'::uuid,
  p_correct_answers => '["35","+35","35 °","35°","+35 °","+35°"]'::jsonb,
  p_solution        => '∠AMC und ∠BMC sind Nebenwinkel: zusammen 180°. ∠BMC = (180° - 40°) : 2 = 70°, ∠AMC = 110°.
Dreieck AMC ist gleichschenklig (MA = MC), Spitze M: α = (180° - 110°) : 2 = 35°.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Rest im Dreieck AMC nicht halbiert: 180° - 110° = 70°.","socratic_question":"Auf wie viele gleich große Winkel verteilen sich die restlichen 70° im Dreieck AMC?"}]'::jsonb,
  p_acceptance      => '{"canonical":"35","equivalents":["+35","35 °","35°","+35 °","+35°"],"known_errors":{"70":"halbieren_vergessen","+70":"halbieren_vergessen","70 °":"halbieren_vergessen","70°":"halbieren_vergessen","+70 °":"halbieren_vergessen","+70°":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;
