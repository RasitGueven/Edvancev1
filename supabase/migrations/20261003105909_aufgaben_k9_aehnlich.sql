-- K9-Rest, Thema aehnlich — 24 Aufgaben: je sechs zu geo_aehnlich_streckfaktor, _flaeche, _strahlen_abschnitt und _strahlen_parallel.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-aehnlich.json (Quelle: tools/k9-aehnlich-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105900_substrat_k9_aehnlich.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit (AFB I, I, II, II), eine mit Sachkontext (AFB II) und eine Sachkontext- oder Rückrichtungsaufgabe (AFB III): Foto, Umfang des Bilddreiecks, Wandfarbe, Tankmodell im Maßstab, Straßen mit Querstraßen, Metallgestell, Schatten, Peilstab. Alles als Text ohne Abbildung; jede Strahlensatzfigur ist mit Scheitel S, Parallelen durch A, B und C, D und der Lage „A zwischen S und C, B zwischen S und D“ vollständig beschrieben. Alle Ergebnisse exakt.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-aehnlich.csv. Pruefprotokoll: docs/prefill/k9-aehnlich-verifikation.md.
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
--   geo_aehnlich_streckfaktor: aehnlich-streckfaktor-05 = 1, aehnlich-streckfaktor-02 = 2. Rang 1 aus Profil {additiv_statt_multiplikativ,falsche_groesse_beantwortet,streckfaktor_kehrwert}, Rang 2 aus Profil {additiv_statt_multiplikativ,streckfaktor_kehrwert} (0 neue Fehlbilder)
--   geo_aehnlich_flaeche: aehnlich-flaeche-05 = 1, aehnlich-flaeche-03 = 2. Rang 1 aus Profil {falsche_groesse_beantwortet,linearer_faktor,mal_exponent}, Rang 2 aus Profil {linearer_faktor,streckfaktor_kehrwert,wurzel_halbiert} (2 neue Fehlbilder)
--   geo_aehnlich_strahlen_abschnitt: aehnlich-abschnitt-06 = 1, aehnlich-abschnitt-01 = 2. Rang 1 aus Profil {additiv_statt_multiplikativ,falsche_groesse_beantwortet,strahlensatz_falsch_zugeordnet}, Rang 2 aus Profil {additiv_statt_multiplikativ,strahlensatz_falsch_zugeordnet} (0 neue Fehlbilder)
--   geo_aehnlich_strahlen_parallel: aehnlich-parallel-03 = 1, aehnlich-parallel-01 = 2. Rang 1 aus Profil {additiv_statt_multiplikativ,strahlensatz_falsch_zugeordnet,streckfaktor_kehrwert}, Rang 2 aus Profil {additiv_statt_multiplikativ,strahlensatz_falsch_zugeordnet} (0 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 aehnlich-streckfaktor-01 · Streckfaktor · 4 cm werden 10 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '93dbda80-cd5e-4a40-b0f5-98953e8fb588'::uuid, 'exercise', 'Streckfaktor · 4 cm werden 10 cm', 'Bei einer zentrischen Streckung wird eine 4 cm lange Strecke auf eine 10 cm lange Bildstrecke abgebildet.

Wie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Bei einer zentrischen Streckung wird eine 4 cm lange Strecke auf eine 10 cm lange Bildstrecke abgebildet.\n\nWie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: k = Bild : Original, eine Division.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (streckfaktor_kehrwert, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '93dbda80-cd5e-4a40-b0f5-98953e8fb588'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '93dbda80-cd5e-4a40-b0f5-98953e8fb588'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '93dbda80-cd5e-4a40-b0f5-98953e8fb588'::uuid,
  p_correct_answers => '["2,5","+2,5","2.5","+2.5"]'::jsonb,
  p_solution        => 'k = Bildlänge : Originallänge = 10 cm : 4 cm = 2,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Original durch Bild geteilt: 4 : 10 = 0,4.","socratic_question":"Wird die Strecke länger oder kürzer – muss k dann größer oder kleiner als 1 sein?"},{"error":"Den Zuwachs berechnet statt des Faktors: 10 − 4 = 6.","socratic_question":"Ist k ein Unterschied oder ein Faktor, mit dem man malnimmt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,5","equivalents":["+2,5","2.5","+2.5"],"known_errors":{"6":"additiv_statt_multiplikativ","0,4":"streckfaktor_kehrwert","+0,4":"streckfaktor_kehrwert","0.4":"streckfaktor_kehrwert","+0.4":"streckfaktor_kehrwert","+6":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 aehnlich-streckfaktor-02 · Bildlänge · 3,5 cm mit k = 4
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3efc2963-83cd-4bb7-b3ac-3f37534f4fd4'::uuid, 'exercise', 'Bildlänge · 3,5 cm mit k = 4', 'Eine 3,5 cm lange Strecke wird zentrisch mit dem Streckfaktor k = 4 gestreckt.

Wie lang ist die Bildstrecke? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine 3,5 cm lange Strecke wird zentrisch mit dem Streckfaktor k = 4 gestreckt.\n\nWie lang ist die Bildstrecke? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, 2, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Bildlänge = k · Originallänge, eine Multiplikation.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (additiv_statt_multiplikativ, streckfaktor_kehrwert).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3efc2963-83cd-4bb7-b3ac-3f37534f4fd4'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3efc2963-83cd-4bb7-b3ac-3f37534f4fd4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3efc2963-83cd-4bb7-b3ac-3f37534f4fd4'::uuid,
  p_correct_answers => '["14","14 cm","14cm"]'::jsonb,
  p_solution        => 'Bildlänge = k · Originallänge = 4 · 3,5 cm = 14 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"k addiert statt multipliziert: 3,5 + 4 = 7,5.","socratic_question":"Was bedeutet „Streckfaktor 4“ – 4 cm länger oder 4-mal so lang?"},{"error":"Durch k geteilt statt mit k multipliziert: 3,5 : 4.","socratic_question":"Bei k = 4 wird die Strecke größer oder kleiner?"}]'::jsonb,
  p_acceptance      => '{"canonical":"14","equivalents":["14 cm","14cm"],"known_errors":{"7,5":"additiv_statt_multiplikativ","7.5":"additiv_statt_multiplikativ","7,5 cm":"additiv_statt_multiplikativ","7,5cm":"additiv_statt_multiplikativ","0,875":"streckfaktor_kehrwert","0.875":"streckfaktor_kehrwert","0,875 cm":"streckfaktor_kehrwert","0,875cm":"streckfaktor_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 aehnlich-streckfaktor-03 · Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0644e069-c106-4cb4-8faa-bbad5edddb70'::uuid, 'exercise', 'Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm', 'Ein Dreieck wird zentrisch gestreckt. Die Seite a ist 12 cm lang, ihre Bildseite a′ nur 9 cm. Die Seite b des Dreiecks ist 6 cm lang.

Wie lang ist die Bildseite b′? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Dreieck wird zentrisch gestreckt. Die Seite a ist 12 cm lang, ihre Bildseite a′ nur 9 cm. Die Seite b des Dreiecks ist 6 cm lang.\n\nWie lang ist die Bildseite b′? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Streckfaktor einer Verkleinerung (0 < k < 1) bestimmen und auf eine zweite Seite anwenden.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (streckfaktor_kehrwert, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0644e069-c106-4cb4-8faa-bbad5edddb70'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0644e069-c106-4cb4-8faa-bbad5edddb70'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0644e069-c106-4cb4-8faa-bbad5edddb70'::uuid,
  p_correct_answers => '["4,5","4.5","4,5 cm","4,5cm"]'::jsonb,
  p_solution        => 'k = 9 cm : 12 cm = 0,75 (Verkleinerung, k < 1).
b′ = k · b = 0,75 · 6 cm = 4,5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit dem Kehrwert gerechnet: k = 12 : 9, also b′ = 8 cm.","socratic_question":"Wird das Dreieck größer oder kleiner – passt dazu ein b′ über 6 cm?"},{"error":"Gleich viel abgezogen wie bei a: 6 cm − 3 cm.","socratic_question":"Wird jede Seite um gleich viel kürzer oder auf denselben Bruchteil verkleinert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4,5","equivalents":["4.5","4,5 cm","4,5cm"],"known_errors":{"3":"additiv_statt_multiplikativ","8":"streckfaktor_kehrwert","8 cm":"streckfaktor_kehrwert","8cm":"streckfaktor_kehrwert","3 cm":"additiv_statt_multiplikativ","3cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 aehnlich-streckfaktor-04 · Rückrichtung · Original aus 7 cm Bild und k = 2,5
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '75cb4657-94a9-4348-b6b1-807f241f4914'::uuid, 'exercise', 'Rückrichtung · Original aus 7 cm Bild und k = 2,5', 'Bei einer zentrischen Streckung mit dem Streckfaktor k = 2,5 entsteht eine 7 cm lange Bildstrecke.

Wie lang war die Originalstrecke? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Bei einer zentrischen Streckung mit dem Streckfaktor k = 2,5 entsteht eine 7 cm lange Bildstrecke.\n\nWie lang war die Originalstrecke? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung, Originallänge = Bildlänge : k mit Dezimalfaktor.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (streckfaktor_kehrwert, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '75cb4657-94a9-4348-b6b1-807f241f4914'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '75cb4657-94a9-4348-b6b1-807f241f4914'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '75cb4657-94a9-4348-b6b1-807f241f4914'::uuid,
  p_correct_answers => '["2,8","2.8","2,8 cm","2,8cm"]'::jsonb,
  p_solution        => 'Bildlänge = k · Originallänge, also Originallänge = Bildlänge : k.
Originallänge = 7 cm : 2,5 = 2,8 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit k multipliziert statt durch k geteilt: 7 · 2,5.","socratic_question":"Ist die Originalstrecke bei k = 2,5 länger oder kürzer als ihr Bild?"},{"error":"k abgezogen statt durch k geteilt: 7 − 2,5.","socratic_question":"Wie kommt man vom Bild zurück, wenn man beim Strecken malgenommen hat?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,8","equivalents":["2.8","2,8 cm","2,8cm"],"known_errors":{"17,5":"streckfaktor_kehrwert","17.5":"streckfaktor_kehrwert","17,5 cm":"streckfaktor_kehrwert","17,5cm":"streckfaktor_kehrwert","4,5":"additiv_statt_multiplikativ","4.5":"additiv_statt_multiplikativ","4,5 cm":"additiv_statt_multiplikativ","4,5cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 aehnlich-streckfaktor-05 · Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6'::uuid, 'exercise', 'Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert', 'Ein Foto ist 9 cm breit und 13 cm hoch. Es wird ohne Verzerrung vergrößert, sodass es 27 cm breit ist.

Wie hoch ist das vergrößerte Foto? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Foto ist 9 cm breit und 13 cm hoch. Es wird ohne Verzerrung vergrößert, sodass es 27 cm breit ist.\n\nWie hoch ist das vergrößerte Foto? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'cm', false, 1, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Faktor aus einer Seite erkennen und auf die andere Seite übertragen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (additiv_statt_multiplikativ, falsche_groesse_beantwortet, streckfaktor_kehrwert).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6'::uuid,
  p_correct_answers => '["39","39 cm","39cm"]'::jsonb,
  p_solution        => 'k = 27 cm : 9 cm = 3.
Höhe = 3 · 13 cm = 39 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zur Höhe dieselben 18 cm addiert wie zur Breite: 13 + 18.","socratic_question":"Bleibt das Foto unverzerrt, wenn beide Seiten um gleich viel wachsen?"},{"error":"Nur den Vergrößerungsfaktor 3 angegeben.","socratic_question":"Gefragt ist die Höhe in Zentimetern – was fehlt noch?"},{"error":"Durch 3 geteilt statt mit 3 multipliziert: 13 : 3.","socratic_question":"Wird das Foto größer oder kleiner?"}]'::jsonb,
  p_acceptance      => '{"canonical":"39","equivalents":["39 cm","39cm"],"known_errors":{"3":"falsche_groesse_beantwortet","31":"additiv_statt_multiplikativ","31 cm":"additiv_statt_multiplikativ","31cm":"additiv_statt_multiplikativ","3 cm":"falsche_groesse_beantwortet","3cm":"falsche_groesse_beantwortet","4,33":"streckfaktor_kehrwert","4.33":"streckfaktor_kehrwert","4,33 cm":"streckfaktor_kehrwert","4,33cm":"streckfaktor_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 aehnlich-streckfaktor-06 · Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '51490b4f-18e9-4a15-8ee2-7e160526f2d9'::uuid, 'exercise', 'Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm', 'Ein Dreieck hat die Seitenlängen 5 cm, 6 cm und 7 cm. Es wird zentrisch gestreckt. Das Bilddreieck hat den Umfang 45 cm.

Wie lang ist die kürzeste Seite des Bilddreiecks? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Dreieck hat die Seitenlängen 5 cm, 6 cm und 7 cm. Es wird zentrisch gestreckt. Das Bilddreieck hat den Umfang 45 cm.\n\nWie lang ist die kürzeste Seite des Bilddreiecks? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_streckfaktor',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  90, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-streckfaktor-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Den Streckfaktor über den Umfang erschließen, dann eine Seite strecken – Weg selbst finden.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (additiv_statt_multiplikativ, streckfaktor_kehrwert, falsche_groesse_beantwortet).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '51490b4f-18e9-4a15-8ee2-7e160526f2d9'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '51490b4f-18e9-4a15-8ee2-7e160526f2d9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '51490b4f-18e9-4a15-8ee2-7e160526f2d9'::uuid,
  p_correct_answers => '["12,5","12.5","12,5 cm","12,5cm"]'::jsonb,
  p_solution        => 'Umfang des Originals: 5 cm + 6 cm + 7 cm = 18 cm.
Auch der Umfang wird mit k gestreckt: k = 45 cm : 18 cm = 2,5.
Kürzeste Bildseite: 2,5 · 5 cm = 12,5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Zuwachs von 27 cm gleichmäßig verteilt: jede Seite 9 cm länger, also 14 cm.","socratic_question":"Wäre das Bilddreieck dann noch ähnlich zum Original?"},{"error":"Durch k geteilt statt mit k multipliziert: 5 : 2,5.","socratic_question":"Das Bild hat einen größeren Umfang – muss die Seite länger oder kürzer werden?"},{"error":"Nur den Streckfaktor 2,5 angegeben.","socratic_question":"Gefragt ist eine Seitenlänge – was musst du mit k noch tun?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12,5","equivalents":["12.5","12,5 cm","12,5cm"],"known_errors":{"2":"streckfaktor_kehrwert","14":"additiv_statt_multiplikativ","14 cm":"additiv_statt_multiplikativ","14cm":"additiv_statt_multiplikativ","2 cm":"streckfaktor_kehrwert","2cm":"streckfaktor_kehrwert","2,5":"falsche_groesse_beantwortet","2.5":"falsche_groesse_beantwortet","2,5 cm":"falsche_groesse_beantwortet","2,5cm":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 aehnlich-flaeche-01 · Bildfläche · 6 cm² mit k = 3
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6e18016e-5c62-4ba8-a1ed-a924506930e7'::uuid, 'exercise', 'Bildfläche · 6 cm² mit k = 3', 'Eine Figur hat den Flächeninhalt 6 cm². Sie wird zentrisch mit dem Streckfaktor k = 3 gestreckt.

Wie groß ist der Flächeninhalt der Bildfigur? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Eine Figur hat den Flächeninhalt 6 cm². Sie wird zentrisch mit dem Streckfaktor k = 3 gestreckt.\n\nWie groß ist der Flächeninhalt der Bildfigur? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm²', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Flächen wachsen mit k², ein Schritt.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, mal_exponent).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6e18016e-5c62-4ba8-a1ed-a924506930e7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6e18016e-5c62-4ba8-a1ed-a924506930e7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6e18016e-5c62-4ba8-a1ed-a924506930e7'::uuid,
  p_correct_answers => '["54","54 cm²","54cm²"]'::jsonb,
  p_solution        => 'Flächen wachsen mit k²: A′ = k² · A = 3² · 6 cm² = 9 · 6 cm² = 54 cm².',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit k multipliziert: 3 · 6 = 18.","socratic_question":"Wenn Länge und Breite je 3-mal so groß werden – wie viel mal so groß wird die Fläche?"},{"error":"k² als 2 · k gerechnet: 6 · 6 = 36.","socratic_question":"Ist 3² dasselbe wie 2 · 3?"}]'::jsonb,
  p_acceptance      => '{"canonical":"54","equivalents":["54 cm²","54cm²"],"known_errors":{"18":"linearer_faktor","36":"mal_exponent","18 cm²":"linearer_faktor","18cm²":"linearer_faktor","36 cm²":"mal_exponent","36cm²":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 aehnlich-flaeche-02 · Volumen · 5 cm³ mit k = 2
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1cba711e-7175-49db-b76a-8c3304b5bc64'::uuid, 'exercise', 'Volumen · 5 cm³ mit k = 2', 'Ein Körper hat das Volumen 5 cm³. Ein dazu ähnlicher Körper ist mit dem Streckfaktor k = 2 vergrößert.

Wie groß ist das Volumen des vergrößerten Körpers? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Körper hat das Volumen 5 cm³. Ein dazu ähnlicher Körper ist mit dem Streckfaktor k = 2 vergrößert.\n\nWie groß ist das Volumen des vergrößerten Körpers? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm³', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Volumen wachsen mit k³, ein Schritt.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, mal_exponent).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1cba711e-7175-49db-b76a-8c3304b5bc64'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1cba711e-7175-49db-b76a-8c3304b5bc64'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1cba711e-7175-49db-b76a-8c3304b5bc64'::uuid,
  p_correct_answers => '["40","40 cm³","40cm³"]'::jsonb,
  p_solution        => 'Volumen wachsen mit k³: V′ = k³ · V = 2³ · 5 cm³ = 8 · 5 cm³ = 40 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit k multipliziert: 2 · 5 = 10.","socratic_question":"Wie viele Richtungen hat ein Körper – und in jeder wird mit k gestreckt?"},{"error":"Mit k² gerechnet wie bei Flächen: 4 · 5 = 20.","socratic_question":"Wächst ein Volumen wie eine Fläche oder in einer Richtung mehr?"},{"error":"k³ als 3 · k gerechnet: 6 · 5 = 30.","socratic_question":"Ist 2³ dasselbe wie 3 · 2?"}]'::jsonb,
  p_acceptance      => '{"canonical":"40","equivalents":["40 cm³","40cm³"],"known_errors":{"10":"linearer_faktor","20":"linearer_faktor","30":"mal_exponent","10 cm³":"linearer_faktor","10cm³":"linearer_faktor","20 cm³":"linearer_faktor","20cm³":"linearer_faktor","30 cm³":"mal_exponent","30cm³":"mal_exponent"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 aehnlich-flaeche-03 · Streckfaktor aus 12 cm² und 75 cm²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4186f7c2-c0bf-4563-a14c-bc04d0817ee6'::uuid, 'exercise', 'Streckfaktor aus 12 cm² und 75 cm²', 'Eine Figur mit dem Flächeninhalt 12 cm² wird zentrisch gestreckt. Die Bildfigur hat den Flächeninhalt 75 cm².

Wie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Eine Figur mit dem Flächeninhalt 12 cm² wird zentrisch gestreckt. Die Bildfigur hat den Flächeninhalt 75 cm².\n\nWie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Rückrichtung über das Flächenverhältnis, Wurzel ziehen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, streckfaktor_kehrwert, wurzel_halbiert).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4186f7c2-c0bf-4563-a14c-bc04d0817ee6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4186f7c2-c0bf-4563-a14c-bc04d0817ee6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4186f7c2-c0bf-4563-a14c-bc04d0817ee6'::uuid,
  p_correct_answers => '["2,5","+2,5","2.5","+2.5"]'::jsonb,
  p_solution        => 'Flächenverhältnis: k² = 75 cm² : 12 cm² = 6,25.
k = √6,25 = 2,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Flächenverhältnis als Streckfaktor genommen: 6,25.","socratic_question":"Welcher Faktor gehört zu den Flächen – k oder k²?"},{"error":"Original durch Bild geteilt: √(12 : 75) = 0,4.","socratic_question":"Die Figur wird größer – muss k dann größer oder kleiner als 1 sein?"},{"error":"k² halbiert statt die Wurzel gezogen: 6,25 : 2.","socratic_question":"Welche Zahl ergibt mit sich selbst multipliziert 6,25?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,5","equivalents":["+2,5","2.5","+2.5"],"known_errors":{"6,25":"linearer_faktor","+6,25":"linearer_faktor","6.25":"linearer_faktor","+6.25":"linearer_faktor","0,4":"streckfaktor_kehrwert","+0,4":"streckfaktor_kehrwert","0.4":"streckfaktor_kehrwert","+0.4":"streckfaktor_kehrwert","3,125":"wurzel_halbiert","+3,125":"wurzel_halbiert","3.125":"wurzel_halbiert","+3.125":"wurzel_halbiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 aehnlich-flaeche-04 · Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e9add498-a88c-46e5-8905-25a5d1ec9ce7'::uuid, 'exercise', 'Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm', 'Zwei Quader sind zueinander ähnlich. Eine Kante des kleinen Quaders ist 4 cm lang, die entsprechende Kante des großen Quaders 6 cm. Der kleine Quader hat das Volumen 32 cm³.

Wie groß ist das Volumen des großen Quaders? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Quader sind zueinander ähnlich. Eine Kante des kleinen Quaders ist 4 cm lang, die entsprechende Kante des großen Quaders 6 cm. Der kleine Quader hat das Volumen 32 cm³.\n\nWie groß ist das Volumen des großen Quaders? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm³', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Streckfaktor aus entsprechenden Kanten bestimmen, dann mit k³ rechnen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, streckfaktor_kehrwert).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e9add498-a88c-46e5-8905-25a5d1ec9ce7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e9add498-a88c-46e5-8905-25a5d1ec9ce7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e9add498-a88c-46e5-8905-25a5d1ec9ce7'::uuid,
  p_correct_answers => '["108","108 cm³","108cm³"]'::jsonb,
  p_solution        => 'k = 6 cm : 4 cm = 1,5.
k³ = 1,5³ = 3,375.
V = 3,375 · 32 cm³ = 108 cm³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit k multipliziert: 1,5 · 32 = 48.","socratic_question":"Wird ein Körper nur in einer Richtung gestreckt?"},{"error":"Mit k² gerechnet wie bei Flächen: 2,25 · 32 = 72.","socratic_question":"Ein Volumen hat drei Richtungen – welche Hochzahl gehört zu k?"},{"error":"Mit dem Kehrwert 4 : 6 gerechnet: das Volumen wird kleiner.","socratic_question":"Soll das Volumen des großen Quaders größer oder kleiner als 32 cm³ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"108","equivalents":["108 cm³","108cm³"],"known_errors":{"48":"linearer_faktor","72":"linearer_faktor","48 cm³":"linearer_faktor","48cm³":"linearer_faktor","72 cm³":"linearer_faktor","72cm³":"linearer_faktor","9,48":"streckfaktor_kehrwert","9.48":"streckfaktor_kehrwert","9,48 cm³":"streckfaktor_kehrwert","9,48cm³":"streckfaktor_kehrwert"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 aehnlich-flaeche-05 · Farbe · Wandbild mit 2,5-mal so langen Seiten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '93e695a0-efbe-490f-b931-299545068f26'::uuid, 'exercise', 'Farbe · Wandbild mit 2,5-mal so langen Seiten', 'Für ein Wandbild werden 0,4 Liter Farbe gebraucht. Ein zweites Wandbild hat dieselbe Form, aber alle Seiten sind 2,5-mal so lang. Die Farbe wird gleich dick aufgetragen.

Wie viele Liter Farbe braucht das zweite Wandbild? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Für ein Wandbild werden 0,4 Liter Farbe gebraucht. Ein zweites Wandbild hat dieselbe Form, aber alle Seiten sind 2,5-mal so lang. Die Farbe wird gleich dick aufgetragen.\n\nWie viele Liter Farbe braucht das zweite Wandbild? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'l', false, 1, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Die Farbmenge als Fläche erkennen und mit k² rechnen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, mal_exponent, falsche_groesse_beantwortet).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '93e695a0-efbe-490f-b931-299545068f26'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '93e695a0-efbe-490f-b931-299545068f26'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '93e695a0-efbe-490f-b931-299545068f26'::uuid,
  p_correct_answers => '["2,5","2.5","2,5 l","2,5l"]'::jsonb,
  p_solution        => 'Die Farbmenge wächst wie die Fläche, also mit k².
k² = 2,5² = 6,25.
Farbe = 6,25 · 0,4 l = 2,5 l.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit k multipliziert: 2,5 · 0,4 = 1.","socratic_question":"Hängt die Farbmenge an einer Länge oder an einer Fläche?"},{"error":"2,5² als 2 · 2,5 gerechnet: 5 · 0,4 = 2.","socratic_question":"Ist 2,5² dasselbe wie 2 · 2,5?"},{"error":"Nur den Flächenfaktor 6,25 angegeben.","socratic_question":"Gefragt ist die Farbmenge in Litern – was fehlt noch?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2,5","equivalents":["2.5","2,5 l","2,5l"],"known_errors":{"1":"linearer_faktor","2":"mal_exponent","1 l":"linearer_faktor","1l":"linearer_faktor","2 l":"mal_exponent","2l":"mal_exponent","6,25":"falsche_groesse_beantwortet","6.25":"falsche_groesse_beantwortet","6,25 l":"falsche_groesse_beantwortet","6,25l":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 aehnlich-flaeche-06 · Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7f8af94f-4ac8-40e9-851e-7e36a48335cd'::uuid, 'exercise', 'Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter', 'Ein Modell eines Wassertanks ist im Maßstab 1 : 50 gebaut. Das Modell fasst 0,2 Liter.

Wie viele Kubikmeter fasst der echte Tank? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Modell eines Wassertanks ist im Maßstab 1 : 50 gebaut. Das Modell fasst 0,2 Liter.\n\nWie viele Kubikmeter fasst der echte Tank? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_flaeche',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm³', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-flaeche-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Maßstab als Streckfaktor, k³ und Umrechnung von Litern in Kubikmeter verbinden.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (linearer_faktor, einheit_uebersprungen).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7f8af94f-4ac8-40e9-851e-7e36a48335cd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7f8af94f-4ac8-40e9-851e-7e36a48335cd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7f8af94f-4ac8-40e9-851e-7e36a48335cd'::uuid,
  p_correct_answers => '["25","25 m³","25m³"]'::jsonb,
  p_solution        => 'Der echte Tank ist in jeder Richtung 50-mal so groß: k = 50, Volumen wächst mit k³ = 125 000.
V = 125 000 · 0,2 l = 25 000 l.
1 m³ = 1000 l, also V = 25 000 l : 1000 = 25 m³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur mit k = 50 multipliziert: 10 l = 0,01 m³.","socratic_question":"Wird der Tank nur in einer Richtung 50-mal so groß?"},{"error":"Mit k² gerechnet wie bei Flächen: 500 l = 0,5 m³.","socratic_question":"Ein Volumen hat drei Richtungen – welche Hochzahl gehört zu k?"},{"error":"Nicht in Kubikmeter umgerechnet: 25 000 (Liter).","socratic_question":"In welcher Einheit ist das Volumen gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"25","equivalents":["25 m³","25m³"],"known_errors":{"25000":"einheit_uebersprungen","0,01":"linearer_faktor","0.01":"linearer_faktor","0,01 m³":"linearer_faktor","0,01m³":"linearer_faktor","0,5":"linearer_faktor","0.5":"linearer_faktor","0,5 m³":"linearer_faktor","0,5m³":"linearer_faktor","25000 m³":"einheit_uebersprungen","25000m³":"einheit_uebersprungen"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 aehnlich-abschnitt-01 · Erster Strahlensatz · SD aus SA, SC und SB
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f8083d9b-72c9-4a72-a0c0-0adb8787bfce'::uuid, 'exercise', 'Erster Strahlensatz · SD aus SA, SC und SB', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis A ist 3 cm lang, die Strecke von S bis C 7,5 cm und die Strecke von S bis B 4 cm.

Wie lang ist die Strecke von S bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis A ist 3 cm lang, die Strecke von S bis C 7,5 cm und die Strecke von S bis B 4 cm.\n\nWie lang ist die Strecke von S bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, 2, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Verhältnisgleichung SD : SB = SC : SA direkt aufstellen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f8083d9b-72c9-4a72-a0c0-0adb8787bfce'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f8083d9b-72c9-4a72-a0c0-0adb8787bfce'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f8083d9b-72c9-4a72-a0c0-0adb8787bfce'::uuid,
  p_correct_answers => '["10","10 cm","10cm"]'::jsonb,
  p_solution        => 'Erster Strahlensatz: SD : SB = SC : SA.
SD = SB · SC : SA = 4 cm · 7,5 : 3 = 10 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Verhältnisse vertauscht: SD = SB · SA : SC = 1,6 cm.","socratic_question":"D liegt weiter von S entfernt als B – kann SD kürzer als SB sein?"},{"error":"Auf dem zweiten Strahl gleich viel addiert wie auf dem ersten: 4 cm + 4,5 cm.","socratic_question":"Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["10 cm","10cm"],"known_errors":{"1,6":"strahlensatz_falsch_zugeordnet","1.6":"strahlensatz_falsch_zugeordnet","1,6 cm":"strahlensatz_falsch_zugeordnet","1,6cm":"strahlensatz_falsch_zugeordnet","8,5":"additiv_statt_multiplikativ","8.5":"additiv_statt_multiplikativ","8,5 cm":"additiv_statt_multiplikativ","8,5cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 aehnlich-abschnitt-02 · Erster Strahlensatz · SC aus SA, SB und SD
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '234e8b8c-ce4d-47bb-8501-86744037c41d'::uuid, 'exercise', 'Erster Strahlensatz · SC aus SA, SB und SD', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis A ist 2 cm lang, die Strecke von S bis B 5 cm und die Strecke von S bis D 15 cm.

Wie lang ist die Strecke von S bis C? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis A ist 2 cm lang, die Strecke von S bis B 5 cm und die Strecke von S bis D 15 cm.\n\nWie lang ist die Strecke von S bis C? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Verhältnisgleichung aufstellen und nach dem gesuchten Abschnitt auflösen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '234e8b8c-ce4d-47bb-8501-86744037c41d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '234e8b8c-ce4d-47bb-8501-86744037c41d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '234e8b8c-ce4d-47bb-8501-86744037c41d'::uuid,
  p_correct_answers => '["6","6 cm","6cm"]'::jsonb,
  p_solution        => 'Erster Strahlensatz: SC : SA = SD : SB.
SC = SA · SD : SB = 2 cm · 15 : 5 = 6 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Strecken falsch zugeordnet: SC = SB · SD : SA = 37,5 cm.","socratic_question":"Welche Strecke liegt auf demselben Strahl wie SC?"},{"error":"Auf dem ersten Strahl gleich viel addiert wie auf dem zweiten: 2 cm + 10 cm.","socratic_question":"Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["6 cm","6cm"],"known_errors":{"12":"additiv_statt_multiplikativ","37,5":"strahlensatz_falsch_zugeordnet","37.5":"strahlensatz_falsch_zugeordnet","37,5 cm":"strahlensatz_falsch_zugeordnet","37,5cm":"strahlensatz_falsch_zugeordnet","12 cm":"additiv_statt_multiplikativ","12cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 aehnlich-abschnitt-03 · Erster Strahlensatz · Teilstück BD
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f06ce97a-7c42-400e-8cb0-7b53f6f98be1'::uuid, 'exercise', 'Erster Strahlensatz · Teilstück BD', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis A ist 4 cm lang, die Strecke von A bis C 6 cm und die Strecke von S bis B 5 cm.

Wie lang ist die Strecke von B bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis A ist 4 cm lang, die Strecke von A bis C 6 cm und die Strecke von S bis B 5 cm.\n\nWie lang ist die Strecke von B bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Gegeben und gesucht sind Teilstücke; ganze Strecke und Teilstück sauber trennen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, falsche_groesse_beantwortet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f06ce97a-7c42-400e-8cb0-7b53f6f98be1'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f06ce97a-7c42-400e-8cb0-7b53f6f98be1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f06ce97a-7c42-400e-8cb0-7b53f6f98be1'::uuid,
  p_correct_answers => '["7,5","7.5","7,5 cm","7,5cm"]'::jsonb,
  p_solution        => 'Erster Strahlensatz für die Teilstücke: BD : SB = AC : SA.
BD = SB · AC : SA = 5 cm · 6 : 4 = 7,5 cm.
Probe: SC = 10 cm, SD = 5 cm · 10 : 4 = 12,5 cm, BD = 12,5 cm − 5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Teilstück AC mit der ganzen Strecke SC verglichen: BD = SB · AC : SC = 3 cm.","socratic_question":"Gehört zu SB auf dem ersten Strahl SA oder SC?"},{"error":"Die ganze Strecke SD berechnet statt des Teilstücks BD.","socratic_question":"Ist nach der Strecke von S bis D oder von B bis D gefragt?"},{"error":"Den Unterschied der Anfangsstücke addiert: 6 cm + 1 cm.","socratic_question":"Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,5","equivalents":["7.5","7,5 cm","7,5cm"],"known_errors":{"3":"strahlensatz_falsch_zugeordnet","7":"additiv_statt_multiplikativ","3 cm":"strahlensatz_falsch_zugeordnet","3cm":"strahlensatz_falsch_zugeordnet","12,5":"falsche_groesse_beantwortet","12.5":"falsche_groesse_beantwortet","12,5 cm":"falsche_groesse_beantwortet","12,5cm":"falsche_groesse_beantwortet","7 cm":"additiv_statt_multiplikativ","7cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 aehnlich-abschnitt-04 · Erster Strahlensatz · BD aus SC, SD und AC
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9dc1b8dc-5c53-43dc-a32f-e5dcd77fb5cb'::uuid, 'exercise', 'Erster Strahlensatz · BD aus SC, SD und AC', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis C ist 9 cm lang, die Strecke von A bis C 3 cm und die Strecke von S bis D 12 cm.

Wie lang ist die Strecke von B bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis C ist 9 cm lang, die Strecke von A bis C 3 cm und die Strecke von S bis D 12 cm.\n\nWie lang ist die Strecke von B bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Teilstück auf dem zweiten Strahl aus ganzen Strecken und einem Teilstück.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, falsche_groesse_beantwortet).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9dc1b8dc-5c53-43dc-a32f-e5dcd77fb5cb'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9dc1b8dc-5c53-43dc-a32f-e5dcd77fb5cb'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9dc1b8dc-5c53-43dc-a32f-e5dcd77fb5cb'::uuid,
  p_correct_answers => '["4","4 cm","4cm"]'::jsonb,
  p_solution        => 'Erster Strahlensatz: BD : SD = AC : SC.
BD = SD · AC : SC = 12 cm · 3 : 9 = 4 cm.
Probe: SA = 6 cm, SB = 12 cm · 6 : 9 = 8 cm, BD = 12 cm − 8 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"BD : SD = AC : SA gesetzt, also SD mit SA statt mit SC verglichen: 12 · 3 : 6 = 6.","socratic_question":"Zu SD gehört auf dem ersten Strahl welche Strecke – SA oder SC?"},{"error":"Die Strecke SB berechnet statt BD.","socratic_question":"Ist nach der Strecke von S bis B oder von B bis D gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 cm","4cm"],"known_errors":{"6":"strahlensatz_falsch_zugeordnet","8":"falsche_groesse_beantwortet","6 cm":"strahlensatz_falsch_zugeordnet","6cm":"strahlensatz_falsch_zugeordnet","8 cm":"falsche_groesse_beantwortet","8cm":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 aehnlich-abschnitt-05 · Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cff72027-8549-47c3-a12c-e1ff333fa4fd'::uuid, 'exercise', 'Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen', 'Zwei gerade Straßen gehen von einer Kreuzung S aus. Zwei zueinander parallele Querstraßen verbinden sie. Die erste Querstraße trifft die erste Straße im Punkt A und die zweite Straße im Punkt B. Die zweite Querstraße trifft die erste Straße im Punkt C und die zweite Straße im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Von S bis A sind es 240 m, von A bis C 360 m und von S bis B 300 m.

Wie lang ist der Weg von B bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei gerade Straßen gehen von einer Kreuzung S aus. Zwei zueinander parallele Querstraßen verbinden sie. Die erste Querstraße trifft die erste Straße im Punkt A und die zweite Straße im Punkt B. Die zweite Querstraße trifft die erste Straße im Punkt C und die zweite Straße im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nVon S bis A sind es 240 m, von A bis C 360 m und von S bis B 300 m.\n\nWie lang ist der Weg von B bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Strahlensatzfigur in der Situation erkennen, Teilstück berechnen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, falsche_groesse_beantwortet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cff72027-8549-47c3-a12c-e1ff333fa4fd'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cff72027-8549-47c3-a12c-e1ff333fa4fd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cff72027-8549-47c3-a12c-e1ff333fa4fd'::uuid,
  p_correct_answers => '["450","450 m","450m"]'::jsonb,
  p_solution        => 'Erster Strahlensatz: BD : SB = AC : SA.
BD = 300 m · 360 : 240 = 450 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Teilstück AC mit der ganzen Strecke SC verglichen: 300 · 360 : 600 = 180.","socratic_question":"Gehört zu SB auf der ersten Straße SA oder SC?"},{"error":"Die ganze Strecke von S bis D berechnet: 750 m.","socratic_question":"Ist nach dem Weg von S bis D oder von B bis D gefragt?"},{"error":"Den Unterschied der Anfangsstücke addiert: 360 m + 60 m.","socratic_question":"Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"450","equivalents":["450 m","450m"],"known_errors":{"180":"strahlensatz_falsch_zugeordnet","420":"additiv_statt_multiplikativ","750":"falsche_groesse_beantwortet","180 m":"strahlensatz_falsch_zugeordnet","180m":"strahlensatz_falsch_zugeordnet","750 m":"falsche_groesse_beantwortet","750m":"falsche_groesse_beantwortet","420 m":"additiv_statt_multiplikativ","420m":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 aehnlich-abschnitt-06 · Erster Strahlensatz · Metallgestell mit parallelen Streben
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '421cad19-9629-4f75-8e01-c63e86692329'::uuid, 'exercise', 'Erster Strahlensatz · Metallgestell mit parallelen Streben', 'Zwei gerade Metallstangen sind oben im Punkt S verbunden und laufen schräg auseinander nach unten. Zwei zueinander parallele Querstreben verbinden sie. Die obere Strebe ist an der ersten Stange im Punkt A und an der zweiten Stange im Punkt B befestigt, die untere Strebe an der ersten Stange im Punkt C und an der zweiten Stange im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Auf der ersten Stange ist es von S bis A 1 m und von S bis C 2,5 m. Auf der zweiten Stange ist es von S bis D 3 m.

Wie weit ist B auf der zweiten Stange von D entfernt? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei gerade Metallstangen sind oben im Punkt S verbunden und laufen schräg auseinander nach unten. Zwei zueinander parallele Querstreben verbinden sie. Die obere Strebe ist an der ersten Stange im Punkt A und an der zweiten Stange im Punkt B befestigt, die untere Strebe an der ersten Stange im Punkt C und an der zweiten Stange im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nAuf der ersten Stange ist es von S bis A 1 m und von S bis C 2,5 m. Auf der zweiten Stange ist es von S bis D 3 m.\n\nWie weit ist B auf der zweiten Stange von D entfernt? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_abschnitt',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm', false, 1, 'draft', 'edvance_k9_aehnlich', 'aehnlich-abschnitt-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Figur aus der Beschreibung aufbauen, erst SB, dann das Teilstück BD bestimmen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '421cad19-9629-4f75-8e01-c63e86692329'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '421cad19-9629-4f75-8e01-c63e86692329'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '421cad19-9629-4f75-8e01-c63e86692329'::uuid,
  p_correct_answers => '["1,8","1.8","1,8 m","1,8m"]'::jsonb,
  p_solution        => 'Erster Strahlensatz: SB : SD = SA : SC.
SB = 3 m · 1 : 2,5 = 1,2 m.
BD = SD − SB = 3 m − 1,2 m = 1,8 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Strecke SB angegeben statt des Abstands von B bis D.","socratic_question":"Ist nach der Strecke von S bis B oder von B bis D gefragt?"},{"error":"SA mit dem Teilstück AC statt mit SC verglichen: 3 · 1 : 1,5 = 2.","socratic_question":"Gehört zu SD auf der ersten Stange SC oder AC?"},{"error":"Auf der zweiten Stange denselben Abstand angenommen wie auf der ersten: 1,5 m.","socratic_question":"Sind die Stangen gleich lang – wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,8","equivalents":["1.8","1,8 m","1,8m"],"known_errors":{"2":"strahlensatz_falsch_zugeordnet","1,2":"falsche_groesse_beantwortet","1.2":"falsche_groesse_beantwortet","1,2 m":"falsche_groesse_beantwortet","1,2m":"falsche_groesse_beantwortet","2 m":"strahlensatz_falsch_zugeordnet","2m":"strahlensatz_falsch_zugeordnet","1,5":"additiv_statt_multiplikativ","1.5":"additiv_statt_multiplikativ","1,5 m":"additiv_statt_multiplikativ","1,5m":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 aehnlich-parallel-01 · Zweiter Strahlensatz · CD aus SA, SC und AB
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '627d8f56-d275-4994-bff9-f2185622d598'::uuid, 'exercise', 'Zweiter Strahlensatz · CD aus SA, SC und AB', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis A ist 2 cm lang, die Strecke von S bis C 5 cm und die Strecke von A bis B 3 cm.

Wie lang ist die Strecke von C bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis A ist 2 cm lang, die Strecke von S bis C 5 cm und die Strecke von A bis B 3 cm.\n\nWie lang ist die Strecke von C bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, 2, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Verhältnisgleichung CD : AB = SC : SA direkt aufstellen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '627d8f56-d275-4994-bff9-f2185622d598'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '627d8f56-d275-4994-bff9-f2185622d598'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '627d8f56-d275-4994-bff9-f2185622d598'::uuid,
  p_correct_answers => '["7,5","7.5","7,5 cm","7,5cm"]'::jsonb,
  p_solution        => 'Zweiter Strahlensatz: CD : AB = SC : SA.
CD = AB · SC : SA = 3 cm · 5 : 2 = 7,5 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Verhältnisse vertauscht: CD = AB · SA : SC = 1,2 cm.","socratic_question":"Die Parallele durch C liegt weiter von S entfernt – muss CD länger oder kürzer als AB sein?"},{"error":"Gleich viel addiert wie auf dem Strahl: 3 cm + 3 cm.","socratic_question":"Wachsen die Parallelstrecken um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,5","equivalents":["7.5","7,5 cm","7,5cm"],"known_errors":{"6":"additiv_statt_multiplikativ","1,2":"strahlensatz_falsch_zugeordnet","1.2":"strahlensatz_falsch_zugeordnet","1,2 cm":"strahlensatz_falsch_zugeordnet","1,2cm":"strahlensatz_falsch_zugeordnet","6 cm":"additiv_statt_multiplikativ","6cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 aehnlich-parallel-02 · Zweiter Strahlensatz · SA aus den Parallelstrecken
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9e52eb0d-bf0a-4770-aec2-d9598a087c45'::uuid, 'exercise', 'Zweiter Strahlensatz · SA aus den Parallelstrecken', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis C ist 10 cm lang, die Strecke von A bis B 3 cm und die Strecke von C bis D 7,5 cm.

Wie lang ist die Strecke von S bis A? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis C ist 10 cm lang, die Strecke von A bis B 3 cm und die Strecke von C bis D 7,5 cm.\n\nWie lang ist die Strecke von S bis A? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'I', 'geometrie', 'Operieren',
  45, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Verhältnisgleichung aufstellen und nach dem Scheitelabschnitt auflösen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '9e52eb0d-bf0a-4770-aec2-d9598a087c45'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9e52eb0d-bf0a-4770-aec2-d9598a087c45'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '9e52eb0d-bf0a-4770-aec2-d9598a087c45'::uuid,
  p_correct_answers => '["4","4 cm","4cm"]'::jsonb,
  p_solution        => 'Zweiter Strahlensatz: SA : SC = AB : CD.
SA = SC · AB : CD = 10 cm · 3 : 7,5 = 4 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Parallelstrecken vertauscht: SA = SC · CD : AB = 25 cm.","socratic_question":"A liegt zwischen S und C – kann SA länger als SC sein?"},{"error":"Denselben Unterschied abgezogen wie bei den Parallelen: 10 cm − 4,5 cm.","socratic_question":"Hängen die Strecken über einen Unterschied oder über ein Verhältnis zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 cm","4cm"],"known_errors":{"25":"strahlensatz_falsch_zugeordnet","25 cm":"strahlensatz_falsch_zugeordnet","25cm":"strahlensatz_falsch_zugeordnet","5,5":"additiv_statt_multiplikativ","5.5":"additiv_statt_multiplikativ","5,5 cm":"additiv_statt_multiplikativ","5,5cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 aehnlich-parallel-03 · Zweiter Strahlensatz · CD aus SA, AC und AB
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '59b87dce-2116-4855-9e94-54dff17ff05a'::uuid, 'exercise', 'Zweiter Strahlensatz · CD aus SA, AC und AB', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis A ist 5 cm lang, die Strecke von A bis C 3 cm und die Strecke von A bis B 4 cm.

Wie lang ist die Strecke von C bis D? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis A ist 5 cm lang, die Strecke von A bis C 3 cm und die Strecke von A bis B 4 cm.\n\nWie lang ist die Strecke von C bis D? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, 1, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Aus dem Teilstück AC erst SC bilden, dann den zweiten Strahlensatz anwenden.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, streckfaktor_kehrwert, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '59b87dce-2116-4855-9e94-54dff17ff05a'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '59b87dce-2116-4855-9e94-54dff17ff05a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '59b87dce-2116-4855-9e94-54dff17ff05a'::uuid,
  p_correct_answers => '["6,4","6.4","6,4 cm","6,4cm"]'::jsonb,
  p_solution        => 'SC = SA + AC = 5 cm + 3 cm = 8 cm.
Zweiter Strahlensatz: CD : AB = SC : SA.
CD = 4 cm · 8 : 5 = 6,4 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Teilstück AC statt der ganzen Strecke SC verwendet: 4 · 3 : 5 = 2,4.","socratic_question":"Gehört zu den Parallelstrecken das Teilstück AC oder die Strecke vom Scheitel S aus?"},{"error":"Mit dem Kehrwert des Faktors gerechnet: 4 · 5 : 8 = 2,5.","socratic_question":"Muss CD länger oder kürzer als AB sein?"},{"error":"AC einfach zu AB addiert: 4 cm + 3 cm.","socratic_question":"Wachsen die Parallelstrecken um gleich viel oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6,4","equivalents":["6.4","6,4 cm","6,4cm"],"known_errors":{"7":"additiv_statt_multiplikativ","2,4":"strahlensatz_falsch_zugeordnet","2.4":"strahlensatz_falsch_zugeordnet","2,4 cm":"strahlensatz_falsch_zugeordnet","2,4cm":"strahlensatz_falsch_zugeordnet","2,5":"streckfaktor_kehrwert","2.5":"streckfaktor_kehrwert","2,5 cm":"streckfaktor_kehrwert","2,5cm":"streckfaktor_kehrwert","7 cm":"additiv_statt_multiplikativ","7cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 aehnlich-parallel-04 · Zweiter Strahlensatz · AB aus SB, BD und CD
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '59bdf7d8-248a-4c9a-8f96-01aba8f098c1'::uuid, 'exercise', 'Zweiter Strahlensatz · AB aus SB, BD und CD', 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.

Die Strecke von S bis B ist 6 cm lang, die Strecke von B bis D 4,5 cm und die Strecke von C bis D 7 cm.

Wie lang ist die Strecke von A bis B? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nDie Strecke von S bis B ist 6 cm lang, die Strecke von B bis D 4,5 cm und die Strecke von C bis D 7 cm.\n\nWie lang ist die Strecke von A bis B? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Operieren',
  60, 'cm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Werte auf dem zweiten Strahl, Teilstück BD, Rückrichtung zur kürzeren Parallelstrecke.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '59bdf7d8-248a-4c9a-8f96-01aba8f098c1'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '59bdf7d8-248a-4c9a-8f96-01aba8f098c1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '59bdf7d8-248a-4c9a-8f96-01aba8f098c1'::uuid,
  p_correct_answers => '["4","4 cm","4cm"]'::jsonb,
  p_solution        => 'SD = SB + BD = 6 cm + 4,5 cm = 10,5 cm.
Zweiter Strahlensatz: AB : CD = SB : SD.
AB = 7 cm · 6 : 10,5 = 4 cm.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Das Teilstück BD mit SB verglichen: 7 · 4,5 : 6 = 5,25.","socratic_question":"Gehört zu den Parallelstrecken das Teilstück BD oder die Strecke vom Scheitel S aus?"},{"error":"Die Verhältnisse vertauscht: 7 · 10,5 : 6 = 12,25.","socratic_question":"AB liegt näher an S als CD – muss AB länger oder kürzer sein?"},{"error":"Den Abschnitt BD von CD abgezogen: 7 cm − 4,5 cm.","socratic_question":"Hängen die Strecken über einen Unterschied oder über ein Verhältnis zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","equivalents":["4 cm","4cm"],"known_errors":{"5,25":"strahlensatz_falsch_zugeordnet","5.25":"strahlensatz_falsch_zugeordnet","5,25 cm":"strahlensatz_falsch_zugeordnet","5,25cm":"strahlensatz_falsch_zugeordnet","12,25":"strahlensatz_falsch_zugeordnet","12.25":"strahlensatz_falsch_zugeordnet","12,25 cm":"strahlensatz_falsch_zugeordnet","12,25cm":"strahlensatz_falsch_zugeordnet","2,5":"additiv_statt_multiplikativ","2.5":"additiv_statt_multiplikativ","2,5 cm":"additiv_statt_multiplikativ","2,5cm":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 aehnlich-parallel-05 · Zweiter Strahlensatz · Baumhöhe über den Schatten
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '49d26b4c-2b05-4699-b637-3f0a13ba1bc7'::uuid, 'exercise', 'Zweiter Strahlensatz · Baumhöhe über den Schatten', 'Ein 1,5 m langer Stab steht senkrecht auf ebenem Boden und wirft einen 2 m langen Schatten. Ein senkrecht stehender Baum wirft zur selben Zeit einen 12 m langen Schatten.

Wie hoch ist der Baum? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein 1,5 m langer Stab steht senkrecht auf ebenem Boden und wirft einen 2 m langen Schatten. Ein senkrecht stehender Baum wirft zur selben Zeit einen 12 m langen Schatten.\n\nWie hoch ist der Baum? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'II', 'geometrie', 'Modellieren, Operieren',
  90, 'm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Stab und Baum als Parallelstrecken, Schatten als Abschnitte erkennen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '49d26b4c-2b05-4699-b637-3f0a13ba1bc7'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = '49d26b4c-2b05-4699-b637-3f0a13ba1bc7'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '49d26b4c-2b05-4699-b637-3f0a13ba1bc7'::uuid,
  p_correct_answers => '["9","9 m","9m"]'::jsonb,
  p_solution        => 'Die Sonnenstrahlen sind parallel; Höhe und Schatten stehen beim Stab und beim Baum im selben Verhältnis.
Höhe : 12 m = 1,5 m : 2 m.
Höhe = 1,5 m · 12 : 2 = 9 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Höhe und Schatten vertauscht: 2 · 12 : 1,5 = 16.","socratic_question":"Der Stab ist kürzer als sein Schatten – gilt das dann auch für den Baum?"},{"error":"Zur Stabhöhe den Unterschied der Schatten addiert: 1,5 m + 10 m.","socratic_question":"Wächst die Höhe um gleich viel wie der Schatten oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["9 m","9m"],"known_errors":{"16":"strahlensatz_falsch_zugeordnet","16 m":"strahlensatz_falsch_zugeordnet","16m":"strahlensatz_falsch_zugeordnet","11,5":"additiv_statt_multiplikativ","11.5":"additiv_statt_multiplikativ","11,5 m":"additiv_statt_multiplikativ","11,5m":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 aehnlich-parallel-06 · Zweiter Strahlensatz · Baumhöhe über einen Peilstab
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ae9f75b4-3990-401b-bab1-479503f08594'::uuid, 'exercise', 'Zweiter Strahlensatz · Baumhöhe über einen Peilstab', 'Auf ebenem Boden liegen ein Punkt S, der Fußpunkt eines senkrechten, 1,6 m hohen Stabs und der Fußpunkt eines senkrechten Baums in dieser Reihenfolge auf einer Geraden. Der Punkt S ist 2,5 m vom Stab entfernt, der Stab steht 10 m vom Baum entfernt. Die Gerade durch S und die Spitze des Stabs geht genau durch die Spitze des Baums.

Wie hoch ist der Baum? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Auf ebenem Boden liegen ein Punkt S, der Fußpunkt eines senkrechten, 1,6 m hohen Stabs und der Fußpunkt eines senkrechten Baums in dieser Reihenfolge auf einer Geraden. Der Punkt S ist 2,5 m vom Stab entfernt, der Stab steht 10 m vom Baum entfernt. Die Gerade durch S und die Spitze des Stabs geht genau durch die Spitze des Baums.\n\nWie hoch ist der Baum? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'geo_aehnlich_strahlen_parallel',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid),
  'III', 'geometrie', 'Problemlösen, Operieren',
  120, 'm', false, null, 'draft', 'edvance_k9_aehnlich', 'aehnlich-parallel-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Strahlensatzfigur aus der Beschreibung bilden, die ganze Strecke von S bis zum Baum zusammensetzen.","charge":"k9-aehnlich"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-aehnlich"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).","charge":"k9-aehnlich"},"cluster_id":{"art":"neu","grund":"Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.","charge":"k9-aehnlich"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Geometrie (Geo-2, Geo-9).","charge":"k9-aehnlich"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-aehnlich"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-aehnlich"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-aehnlich"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-aehnlich"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (strahlensatz_falsch_zugeordnet, streckfaktor_kehrwert, additiv_statt_multiplikativ).","charge":"k9-aehnlich"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-aehnlich"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ae9f75b4-3990-401b-bab1-479503f08594'::uuid and t.status = 'draft' and t.source = 'edvance_k9_aehnlich')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ae9f75b4-3990-401b-bab1-479503f08594'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ae9f75b4-3990-401b-bab1-479503f08594'::uuid,
  p_correct_answers => '["8","8 m","8m"]'::jsonb,
  p_solution        => 'Entfernung von S bis zum Baum: 2,5 m + 10 m = 12,5 m.
Stab und Baum sind parallel. Zweiter Strahlensatz: Höhe : 1,6 m = 12,5 m : 2,5 m.
Höhe = 1,6 m · 12,5 : 2,5 = 8 m.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Abstand Stab–Baum statt der ganzen Strecke von S bis zum Baum verwendet: 1,6 · 10 : 2,5 = 6,4.","socratic_question":"Gemessen von welchem Punkt aus stehen die Entfernungen im Verhältnis der Höhen?"},{"error":"Mit dem Kehrwert des Faktors gerechnet: 1,6 · 2,5 : 12,5 = 0,32.","socratic_question":"Ist der Baum weiter von S entfernt als der Stab – muss er dann höher oder niedriger sein?"},{"error":"Den Abstand zum Baum einfach zur Stabhöhe addiert: 1,6 m + 10 m.","socratic_question":"Wächst die Höhe um gleich viel wie die Entfernung oder im gleichen Verhältnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["8 m","8m"],"known_errors":{"6,4":"strahlensatz_falsch_zugeordnet","6.4":"strahlensatz_falsch_zugeordnet","6,4 m":"strahlensatz_falsch_zugeordnet","6,4m":"strahlensatz_falsch_zugeordnet","0,32":"streckfaktor_kehrwert","0.32":"streckfaktor_kehrwert","0,32 m":"streckfaktor_kehrwert","0,32m":"streckfaktor_kehrwert","11,6":"additiv_statt_multiplikativ","11.6":"additiv_statt_multiplikativ","11,6 m":"additiv_statt_multiplikativ","11,6m":"additiv_statt_multiplikativ"}}'::jsonb);
  end if;
end
$loesung$;
