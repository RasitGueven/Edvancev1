-- K8 Daten und Wahrscheinlichkeit, Migration 2 von 2 — 30 Aufgaben, je sechs zu den fuenf stoch_*-Knoten.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-stoch.json (Quelle: tools/k8-stoch-aufgaben.mjs,
-- tools/k8-stoch-aufgaben-2.mjs und tools/k8-stoch-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003104944_substrat_k8_stoch.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendungen mit steigender Schwierigkeit (AFB I, I, II, II) und zwei mit Sachkontext (Tombola, Lostrommel, Messreihe, Torstatistik, Abfüllmaschine, Jahrmarkt) oder Rückrichtung. Alle NUMERIC ohne Abbildung: Experimente als Text, Datenreihen als Liste. Wahrscheinlichkeiten gelten als Bruch (gekürzt und ungekürzt), Dezimalzahl und Prozent, sofern endlich. Keine Hinweise, keine Personen.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-stoch.csv. Pruefprotokoll: docs/prefill/k8-stoch-verifikation.md.
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
--   stoch_kenngroessen: stoch-kenngroessen-01 = 1, stoch-kenngroessen-04 = 2. Rang 1 aus Profil {median_ohne_sortieren,mittelwert_statt_median}, Rang 2 aus Profil {falsche_groesse_beantwortet,median_ohne_sortieren} (1 neue Fehlbilder)
--   stoch_laplace: stoch-laplace-01 = 1, stoch-laplace-06 = 2. Rang 1 aus Profil {umgekehrt_geteilt,verhaeltnis_statt_anteil}, Rang 2 aus Profil {multipliziert_statt_dividiert,verhaeltnis_statt_anteil} (1 neue Fehlbilder)
--   stoch_gegenereignis: stoch-gegenereignis-04 = 1, stoch-gegenereignis-03 = 2. Rang 1 aus Profil {bedingung_unvollstaendig,gegenereignis_nicht_abgezogen,nenner_addiert}, Rang 2 aus Profil {gegenereignis_nicht_abgezogen,verhaeltnis_statt_anteil} (1 neue Fehlbilder)
--   stoch_pfad_produkt: stoch-pfad-produkt-03 = 1, stoch-pfad-produkt-01 = 2. Rang 1 aus Profil {pfadregel_addiert,zuruecklegen_ignoriert}, Rang 2 aus Profil {pfadregel_addiert} (0 neue Fehlbilder)
--   stoch_pfad_summe: stoch-pfad-summe-04 = 1, stoch-pfad-summe-02 = 2. Rang 1 aus Profil {gegenereignis_nicht_abgezogen,nur_ein_pfad,pfadregel_addiert}, Rang 2 aus Profil {nur_ein_pfad,zuruecklegen_ignoriert} (1 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 stoch-kenngroessen-01 · Median · ungerade Anzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '68137794-b1f9-4c37-8a4a-cca2281bafcd'::uuid, 'exercise', 'Median · ungerade Anzahl', 'Gegeben ist die Datenreihe
8, 3, 11, 5, 18

Bestimme den Median.',
  '{"kind":"short_input","prompt":"Gegeben ist die Datenreihe\n8, 3, 11, 5, 18\n\nBestimme den Median."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: fünf Werte ordnen und den mittleren ablesen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (median_ohne_sortieren, mittelwert_statt_median).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '68137794-b1f9-4c37-8a4a-cca2281bafcd'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '68137794-b1f9-4c37-8a4a-cca2281bafcd'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '68137794-b1f9-4c37-8a4a-cca2281bafcd'::uuid,
  p_correct_answers => '["8","+8"]'::jsonb,
  p_solution        => 'Geordnet: 3, 5, 8, 11, 18.
Bei fünf Werten steht der Median an der dritten Stelle: Median = 8.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den mittleren Wert der ungeordneten Liste genommen: 11.","socratic_question":"Stehen die Werte schon der Größe nach da?"},{"error":"Den Durchschnitt berechnet: 45 : 5 = 9.","socratic_question":"Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8","equivalents":["+8"],"known_errors":{"9":"mittelwert_statt_median","11":"median_ohne_sortieren","+11":"median_ohne_sortieren","+9":"mittelwert_statt_median"}}'::jsonb);
  end if;
end
$loesung$;

-- #2 stoch-kenngroessen-02 · Median · gerade Anzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a7c6d101-1eee-49ef-a446-c0af40fe25da'::uuid, 'exercise', 'Median · gerade Anzahl', 'Gegeben ist die Datenreihe
14, 9, 21, 12, 17, 11

Bestimme den Median.',
  '{"kind":"short_input","prompt":"Gegeben ist die Datenreihe\n14, 9, 21, 12, 17, 11\n\nBestimme den Median."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: sechs Werte ordnen, Mittelwert der beiden mittleren Werte.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (median_ohne_sortieren, mittelwert_statt_median).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a7c6d101-1eee-49ef-a446-c0af40fe25da'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a7c6d101-1eee-49ef-a446-c0af40fe25da'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a7c6d101-1eee-49ef-a446-c0af40fe25da'::uuid,
  p_correct_answers => '["13","+13"]'::jsonb,
  p_solution        => 'Geordnet: 9, 11, 12, 14, 17, 21.
Bei sechs Werten liegt der Median zwischen dem dritten und vierten Wert: (12 + 14) : 2 = 13.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die beiden mittleren Werte der ungeordneten Liste gemittelt: (21 + 12) : 2 = 16,5.","socratic_question":"Hast du die Werte vor dem Abzählen der Größe nach geordnet?"},{"error":"Den Durchschnitt berechnet: 84 : 6 = 14.","socratic_question":"Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"13","equivalents":["+13"],"known_errors":{"14":"mittelwert_statt_median","16,5":"median_ohne_sortieren","+16,5":"median_ohne_sortieren","16.5":"median_ohne_sortieren","+16.5":"median_ohne_sortieren","+14":"mittelwert_statt_median"}}'::jsonb);
  end if;
end
$loesung$;

-- #3 stoch-kenngroessen-03 · Unteres Quartil · acht Werte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '4615926e-2f06-4780-9b12-d153117c045e'::uuid, 'exercise', 'Unteres Quartil · acht Werte', 'Gegeben ist die Datenreihe
11, 6, 18, 4, 15, 9, 6, 15

Bestimme das untere Quartil.',
  '{"kind":"short_input","prompt":"Gegeben ist die Datenreihe\n11, 6, 18, 4, 15, 9, 6, 15\n\nBestimme das untere Quartil."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: ordnen, Median bestimmen, dann den Median der unteren Hälfte.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, median_ohne_sortieren).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '4615926e-2f06-4780-9b12-d153117c045e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '4615926e-2f06-4780-9b12-d153117c045e'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '4615926e-2f06-4780-9b12-d153117c045e'::uuid,
  p_correct_answers => '["6","+6"]'::jsonb,
  p_solution        => 'Geordnet: 4, 6, 6, 9, 11, 15, 15, 18.
Untere Hälfte: 4, 6, 6, 9. Ihr Median ist (6 + 6) : 2 = 6.
Das untere Quartil ist 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Median der ganzen Reihe statt des unteren Quartils angegeben.","socratic_question":"Teilt dein Wert die Daten in zwei Hälften oder ein Viertel ab?"},{"error":"Das obere statt des unteren Quartils angegeben.","socratic_question":"Liegt das untere Quartil bei den kleinen oder bei den großen Werten?"},{"error":"Die ersten vier Werte ungeordnet genommen und deren Mitte gebildet: (6 + 18) : 2 = 12.","socratic_question":"Hast du die Werte vor dem Halbieren der Größe nach geordnet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","equivalents":["+6"],"known_errors":{"10":"falsche_groesse_beantwortet","12":"median_ohne_sortieren","15":"falsche_groesse_beantwortet","+10":"falsche_groesse_beantwortet","+15":"falsche_groesse_beantwortet","+12":"median_ohne_sortieren"}}'::jsonb);
  end if;
end
$loesung$;

-- #4 stoch-kenngroessen-04 · Oberes Quartil · neun Werte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f91e5425-b56b-434f-9ae1-814649f9aba3'::uuid, 'exercise', 'Oberes Quartil · neun Werte', 'Gegeben ist die Datenreihe
10, 5, 2, 12, 8, 3, 10, 7, 5

Bestimme das obere Quartil.',
  '{"kind":"short_input","prompt":"Gegeben ist die Datenreihe\n10, 5, 2, 12, 8, 3, 10, 7, 5\n\nBestimme das obere Quartil."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: ungerade Anzahl ordnen, Median, dann Median der oberen Hälfte.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, median_ohne_sortieren).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f91e5425-b56b-434f-9ae1-814649f9aba3'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f91e5425-b56b-434f-9ae1-814649f9aba3'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f91e5425-b56b-434f-9ae1-814649f9aba3'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Geordnet: 2, 3, 5, 5, 7, 8, 10, 10, 12.
Der Median ist 7. Obere Hälfte: 8, 10, 10, 12. Ihr Median ist (10 + 10) : 2 = 10.
Das obere Quartil ist 10.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Median der ganzen Reihe statt des oberen Quartils angegeben.","socratic_question":"Teilt dein Wert die Daten in zwei Hälften oder ein Viertel ab?"},{"error":"Die letzten vier Werte ungeordnet genommen und deren Mitte gebildet: (10 + 7) : 2 = 8,5.","socratic_question":"Hast du die Werte vor dem Halbieren der Größe nach geordnet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"7":"falsche_groesse_beantwortet","+7":"falsche_groesse_beantwortet","8,5":"median_ohne_sortieren","+8,5":"median_ohne_sortieren","8.5":"median_ohne_sortieren","+8.5":"median_ohne_sortieren"}}'::jsonb);
  end if;
end
$loesung$;

-- #5 stoch-kenngroessen-05 · Spannweite · Sachkontext · Morgentemperaturen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ae38bcca-7313-4863-95a6-8117a7b524d1'::uuid, 'exercise', 'Spannweite · Sachkontext · Morgentemperaturen', 'An sieben Tagen wurde jeweils um 7 Uhr die Temperatur gemessen (in °C):
3, −2, 5, −5, 1, 0, 7

Bestimme die Spannweite der Messwerte.',
  '{"kind":"short_input","prompt":"An sieben Tagen wurde jeweils um 7 Uhr die Temperatur gemessen (in °C):\n3, −2, 5, −5, 1, 0, 7\n\nBestimme die Spannweite der Messwerte."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, '°C', false, null, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: größten und kleinsten Wert finden, Differenz mit negativer Zahl.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (seiten_verwechselt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ae38bcca-7313-4863-95a6-8117a7b524d1'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ae38bcca-7313-4863-95a6-8117a7b524d1'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ae38bcca-7313-4863-95a6-8117a7b524d1'::uuid,
  p_correct_answers => '["12","+12","12 °C","12°C","+12 °C","+12°C"]'::jsonb,
  p_solution        => 'Größter Wert: 7 °C, kleinster Wert: −5 °C.
Spannweite = 7 − (−5) = 12 °C.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Kleinster minus größter Wert gerechnet: −5 − 7 = −12.","socratic_question":"Kann ein Abstand zwischen zwei Werten negativ sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12","equivalents":["+12","12 °C","12°C","+12 °C","+12°C"],"known_errors":{"-12":"seiten_verwechselt","−12":"seiten_verwechselt","- 12":"seiten_verwechselt","-12 °C":"seiten_verwechselt","-12°C":"seiten_verwechselt","−12 °C":"seiten_verwechselt","−12°C":"seiten_verwechselt","- 12 °C":"seiten_verwechselt","- 12°C":"seiten_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #6 stoch-kenngroessen-06 · Median · Sachkontext · Tore mit Ausreißer
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'de46168f-2460-44ed-a479-5e81786512c9'::uuid, 'exercise', 'Median · Sachkontext · Tore mit Ausreißer', 'Eine Handballmannschaft hat in zehn Spielen folgende Anzahlen an Toren erzielt:
12, 7, 15, 9, 30, 11, 8, 14, 10, 13

Bestimme den Median der Torzahlen.',
  '{"kind":"short_input","prompt":"Eine Handballmannschaft hat in zehn Spielen folgende Anzahlen an Toren erzielt:\n12, 7, 15, 9, 30, 11, 8, 14, 10, 13\n\nBestimme den Median der Torzahlen."}'::jsonb, 'NUMERIC', 'stoch_kenngroessen',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-kenngroessen-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zehn Werte ordnen, Median zwischen zwei Werten, Ausreißer im Datensatz.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-1/Sto-2: Kenngrößen); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mittelwert_statt_median, median_ohne_sortieren).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'de46168f-2460-44ed-a479-5e81786512c9'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'de46168f-2460-44ed-a479-5e81786512c9'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'de46168f-2460-44ed-a479-5e81786512c9'::uuid,
  p_correct_answers => '["11,5","+11,5","11.5","+11.5"]'::jsonb,
  p_solution        => 'Geordnet: 7, 8, 9, 10, 11, 12, 13, 14, 15, 30.
Bei zehn Werten liegt der Median zwischen dem fünften und sechsten Wert: (11 + 12) : 2 = 11,5.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Den Durchschnitt berechnet: 129 : 10 = 12,9.","socratic_question":"Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?"},{"error":"Die beiden mittleren Werte der ungeordneten Liste gemittelt: (30 + 11) : 2 = 20,5.","socratic_question":"Hast du die Werte vor dem Abzählen der Größe nach geordnet?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11,5","equivalents":["+11,5","11.5","+11.5"],"known_errors":{"12,9":"mittelwert_statt_median","+12,9":"mittelwert_statt_median","12.9":"mittelwert_statt_median","+12.9":"mittelwert_statt_median","20,5":"median_ohne_sortieren","+20,5":"median_ohne_sortieren","20.5":"median_ohne_sortieren","+20.5":"median_ohne_sortieren"}}'::jsonb);
  end if;
end
$loesung$;

-- #7 stoch-laplace-01 · Laplace · Würfel · größer als vier
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'df9fd43a-6a01-41a5-b08a-193c0afabb55'::uuid, 'exercise', 'Laplace · Würfel · größer als vier', 'Ein fairer Würfel wird einmal geworfen.

Wie groß ist die Wahrscheinlichkeit, eine Zahl größer als 4 zu werfen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"Ein fairer Würfel wird einmal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, eine Zahl größer als 4 zu werfen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k8_stoch', 'stoch-laplace-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: günstige und mögliche Ergebnisse abzählen, Bruch bilden.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'df9fd43a-6a01-41a5-b08a-193c0afabb55'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'df9fd43a-6a01-41a5-b08a-193c0afabb55'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'df9fd43a-6a01-41a5-b08a-193c0afabb55'::uuid,
  p_correct_answers => '["1/3","2/6"]'::jsonb,
  p_solution        => 'Günstig sind 5 und 6, also 2 von 6 möglichen Ergebnissen.
P = 2/6 = 1/3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die günstigen durch die übrigen Ergebnisse geteilt: 2/4.","socratic_question":"Wie viele Ergebnisse sind insgesamt möglich?"},{"error":"Mögliche durch günstige Ergebnisse geteilt: 6 : 2 = 3.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/3","equivalents":["2/6"],"known_errors":{"3":"umgekehrt_geteilt","1/2":"verhaeltnis_statt_anteil","2/4":"verhaeltnis_statt_anteil","0,5":"verhaeltnis_statt_anteil","0.5":"verhaeltnis_statt_anteil","50 %":"verhaeltnis_statt_anteil","50%":"verhaeltnis_statt_anteil","300 %":"umgekehrt_geteilt","300%":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 stoch-laplace-02 · Laplace · Urne · rote Kugel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid, 'exercise', 'Laplace · Urne · rote Kugel', 'In einer Urne liegen 3 rote und 2 blaue Kugeln. Eine Kugel wird zufällig gezogen.

Wie groß ist die Wahrscheinlichkeit, eine rote Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 3 rote und 2 blaue Kugeln. Eine Kugel wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, eine rote Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-laplace-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Anteil der roten Kugeln an allen Kugeln.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid,
  p_correct_answers => '["3/5","0,6","0.6","60 %","60%","60"]'::jsonb,
  p_solution        => 'Insgesamt 3 + 2 = 5 Kugeln, davon 3 rote.
P(rot) = 3/5 = 0,6 = 60 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Rote durch blaue Kugeln geteilt: 3/2.","socratic_question":"Wie viele Kugeln liegen insgesamt in der Urne?"},{"error":"Alle Kugeln durch die roten geteilt: 5/3.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3/5","equivalents":["0,6","0.6","60 %","60%","60"],"known_errors":{"150":"verhaeltnis_statt_anteil","3/2":"verhaeltnis_statt_anteil","1,5":"verhaeltnis_statt_anteil","1.5":"verhaeltnis_statt_anteil","150 %":"verhaeltnis_statt_anteil","150%":"verhaeltnis_statt_anteil","5/3":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 stoch-laplace-03 · Laplace · Glücksrad · Primzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '743dc783-c0c1-4b97-957c-e8dfff38e3b6'::uuid, 'exercise', 'Laplace · Glücksrad · Primzahl', 'Ein Glücksrad hat 12 gleich große Felder mit den Zahlen 1 bis 12. Es wird einmal gedreht.

Wie groß ist die Wahrscheinlichkeit, dass es auf einer Primzahl stehen bleibt? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"Ein Glücksrad hat 12 gleich große Felder mit den Zahlen 1 bis 12. Es wird einmal gedreht.\n\nWie groß ist die Wahrscheinlichkeit, dass es auf einer Primzahl stehen bleibt? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-laplace-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: günstige Ergebnisse erst bestimmen (Primzahlen bis 12), dann Anteil bilden.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '743dc783-c0c1-4b97-957c-e8dfff38e3b6'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '743dc783-c0c1-4b97-957c-e8dfff38e3b6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '743dc783-c0c1-4b97-957c-e8dfff38e3b6'::uuid,
  p_correct_answers => '["5/12"]'::jsonb,
  p_solution        => 'Primzahlen bis 12: 2, 3, 5, 7, 11, also 5 günstige von 12 Feldern.
P = 5/12.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die günstigen durch die übrigen Felder geteilt: 5/7.","socratic_question":"Wie viele Felder hat das Glücksrad insgesamt?"},{"error":"Alle Felder durch die günstigen geteilt: 12/5.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5/12","known_errors":{"5/7":"verhaeltnis_statt_anteil","12/5":"umgekehrt_geteilt","2,4":"umgekehrt_geteilt","2.4":"umgekehrt_geteilt","240 %":"umgekehrt_geteilt","240%":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 stoch-laplace-04 · Laplace · Lostrommel · Niete
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid, 'exercise', 'Laplace · Lostrommel · Niete', 'In einer Lostrommel liegen 40 Lose: 6 Hauptgewinne, 10 Trostpreise und sonst nur Nieten. Ein Los wird zufällig gezogen.

Wie groß ist die Wahrscheinlichkeit, eine Niete zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"In einer Lostrommel liegen 40 Lose: 6 Hauptgewinne, 10 Trostpreise und sonst nur Nieten. Ein Los wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, eine Niete zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-laplace-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zahl der günstigen Ergebnisse erst aus dem Rest bestimmen, dann kürzen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid,
  p_correct_answers => '["3/5","6/10","12/20","24/40","0,6","0.6","60 %","60%","60"]'::jsonb,
  p_solution        => 'Nieten: 40 − 6 − 10 = 24.
P(Niete) = 24/40 = 3/5 = 0,6 = 60 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nieten durch die übrigen Lose geteilt: 24/16.","socratic_question":"Durch welche Zahl teilst du: durch alle Lose oder durch die Gewinnlose?"},{"error":"Alle Lose durch die Nieten geteilt: 40/24.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3/5","equivalents":["6/10","12/20","24/40","0,6","0.6","60 %","60%","60"],"known_errors":{"150":"verhaeltnis_statt_anteil","3/2":"verhaeltnis_statt_anteil","6/4":"verhaeltnis_statt_anteil","12/8":"verhaeltnis_statt_anteil","24/16":"verhaeltnis_statt_anteil","1,5":"verhaeltnis_statt_anteil","1.5":"verhaeltnis_statt_anteil","150 %":"verhaeltnis_statt_anteil","150%":"verhaeltnis_statt_anteil","5/3":"umgekehrt_geteilt","10/6":"umgekehrt_geteilt","20/12":"umgekehrt_geteilt","40/24":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 stoch-laplace-05 · Laplace · Sachkontext · Tombola in Prozent
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5bcca7e7-8a84-49b8-b115-6598e4b337c6'::uuid, 'exercise', 'Laplace · Sachkontext · Tombola in Prozent', 'Bei einer Tombola werden 150 Lose verkauft, 30 davon sind Gewinne. Ein Los wird zufällig gekauft.

Wie groß ist die Wahrscheinlichkeit für einen Gewinn? Gib das Ergebnis in Prozent an.',
  '{"kind":"short_input","prompt":"Bei einer Tombola werden 150 Lose verkauft, 30 davon sind Gewinne. Ein Los wird zufällig gekauft.\n\nWie groß ist die Wahrscheinlichkeit für einen Gewinn? Gib das Ergebnis in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-laplace-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Laplace-Wahrscheinlichkeit bilden und in Prozent umrechnen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5bcca7e7-8a84-49b8-b115-6598e4b337c6'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5bcca7e7-8a84-49b8-b115-6598e4b337c6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5bcca7e7-8a84-49b8-b115-6598e4b337c6'::uuid,
  p_correct_answers => '["20 %","1/5","2/10","3/15","5/25","6/30","10/50","15/75","30/150","0,2","0.2","20%","20"]'::jsonb,
  p_solution        => 'P(Gewinn) = 30/150 = 1/5 = 0,2 = 20 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Gewinne durch Nieten geteilt: 30/120 = 25 %.","socratic_question":"Wie viele Lose gibt es insgesamt?"},{"error":"Alle Lose durch die Gewinne geteilt: 150 : 30 = 5.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"20 %","equivalents":["1/5","2/10","3/15","5/25","6/30","10/50","15/75","30/150","0,2","0.2","20%","20"],"known_errors":{"5":"umgekehrt_geteilt","25":"verhaeltnis_statt_anteil","500":"umgekehrt_geteilt","1/4":"verhaeltnis_statt_anteil","2/8":"verhaeltnis_statt_anteil","3/12":"verhaeltnis_statt_anteil","5/20":"verhaeltnis_statt_anteil","6/24":"verhaeltnis_statt_anteil","10/40":"verhaeltnis_statt_anteil","15/60":"verhaeltnis_statt_anteil","30/120":"verhaeltnis_statt_anteil","0,25":"verhaeltnis_statt_anteil","0.25":"verhaeltnis_statt_anteil","25 %":"verhaeltnis_statt_anteil","25%":"verhaeltnis_statt_anteil","500 %":"umgekehrt_geteilt","500%":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 stoch-laplace-06 · Laplace · Rückrichtung · Gesamtzahl der Kugeln
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fdd119e8-2192-4691-bda5-d6a5a03317d4'::uuid, 'exercise', 'Laplace · Rückrichtung · Gesamtzahl der Kugeln', 'In einer Urne liegen nur rote und blaue Kugeln. 6 Kugeln sind rot. Die Wahrscheinlichkeit, zufällig eine rote Kugel zu ziehen, beträgt 2/5.

Wie viele Kugeln liegen insgesamt in der Urne?',
  '{"kind":"short_input","prompt":"In einer Urne liegen nur rote und blaue Kugeln. 6 Kugeln sind rot. Die Wahrscheinlichkeit, zufällig eine rote Kugel zu ziehen, beträgt 2/5.\n\nWie viele Kugeln liegen insgesamt in der Urne?"}'::jsonb, 'NUMERIC', 'stoch_laplace',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Problemlösen',
  60, null, false, 2, 'draft', 'edvance_k8_stoch', 'stoch-laplace-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: aus Anteil und Zahl der günstigen die Gesamtzahl bestimmen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rückrichtung: Lösungsweg selbst finden, dann rechnen.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (verhaeltnis_statt_anteil, multipliziert_statt_dividiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'fdd119e8-2192-4691-bda5-d6a5a03317d4'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fdd119e8-2192-4691-bda5-d6a5a03317d4'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'fdd119e8-2192-4691-bda5-d6a5a03317d4'::uuid,
  p_correct_answers => '["15","+15"]'::jsonb,
  p_solution        => '6 rote Kugeln sind 2/5 aller Kugeln.
1/5 sind 6 : 2 = 3 Kugeln, alle Kugeln 5 · 3 = 15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2/5 als Verhältnis rot zu blau gelesen: 15 blaue, zusammen 21.","socratic_question":"Bedeutet 2/5 hier „2 von 5 Kugeln“ oder „2 rote auf 5 blaue“?"},{"error":"Die 6 mit 2/5 malgenommen statt durch 2/5 geteilt.","socratic_question":"Müssen insgesamt mehr oder weniger Kugeln in der Urne liegen als rote?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","equivalents":["+15"],"known_errors":{"21":"verhaeltnis_statt_anteil","+21":"verhaeltnis_statt_anteil","2,4":"multipliziert_statt_dividiert","+2,4":"multipliziert_statt_dividiert","2.4":"multipliziert_statt_dividiert","+2.4":"multipliziert_statt_dividiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 stoch-gegenereignis-01 · Gegenereignis · Würfel · keine Sechs
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f7a7bba2-dadd-4d81-8beb-91fca75ac78f'::uuid, 'exercise', 'Gegenereignis · Würfel · keine Sechs', 'Ein fairer Würfel wird einmal geworfen.

Wie groß ist die Wahrscheinlichkeit, keine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"Ein fairer Würfel wird einmal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, keine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: P(nicht E) = 1 − P(E) mit einem einfachen Bruch.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f7a7bba2-dadd-4d81-8beb-91fca75ac78f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f7a7bba2-dadd-4d81-8beb-91fca75ac78f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f7a7bba2-dadd-4d81-8beb-91fca75ac78f'::uuid,
  p_correct_answers => '["5/6"]'::jsonb,
  p_solution        => 'P(Sechs) = 1/6.
P(keine Sechs) = 1 − 1/6 = 5/6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wahrscheinlichkeit für eine Sechs angegeben statt für keine Sechs.","socratic_question":"Nach welchem Ereignis war gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5/6","known_errors":{"1/6":"gegenereignis_nicht_abgezogen"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 stoch-gegenereignis-02 · Gegenereignis · Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid, 'exercise', 'Gegenereignis · Dezimalzahl', 'Für ein Ereignis E gilt P(E) = 0,35.

Berechne die Wahrscheinlichkeit des Gegenereignisses von E. Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Für ein Ereignis E gilt P(E) = 0,35.\n\nBerechne die Wahrscheinlichkeit des Gegenereignisses von E. Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gegenwahrscheinlichkeit mit einer Dezimalzahl.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid,
  p_correct_answers => '["0,65","13/20","65/100","0.65","65 %","65%","65"]'::jsonb,
  p_solution        => 'P(nicht E) = 1 − 0,35 = 0,65 = 65 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"P(E) selbst angegeben statt der Gegenwahrscheinlichkeit.","socratic_question":"Nach welchem Ereignis ist gefragt: E oder „nicht E“?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,65","equivalents":["13/20","65/100","0.65","65 %","65%","65"],"known_errors":{"35":"gegenereignis_nicht_abgezogen","7/20":"gegenereignis_nicht_abgezogen","35/100":"gegenereignis_nicht_abgezogen","0,35":"gegenereignis_nicht_abgezogen","0.35":"gegenereignis_nicht_abgezogen","35 %":"gegenereignis_nicht_abgezogen","35%":"gegenereignis_nicht_abgezogen"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 stoch-gegenereignis-03 · Gegenereignis · Urne · keine blaue Kugel
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'eaf9ec0c-d93b-4d7a-b5da-f586538e84ad'::uuid, 'exercise', 'Gegenereignis · Urne · keine blaue Kugel', 'In einer Urne liegen 4 rote, 5 blaue und 3 grüne Kugeln. Eine Kugel wird zufällig gezogen.

Wie groß ist die Wahrscheinlichkeit, keine blaue Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 4 rote, 5 blaue und 3 grüne Kugeln. Eine Kugel wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, keine blaue Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: drei Farben, Gegenereignis „blau“ erkennen und von 1 abziehen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, verhaeltnis_statt_anteil).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'eaf9ec0c-d93b-4d7a-b5da-f586538e84ad'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'eaf9ec0c-d93b-4d7a-b5da-f586538e84ad'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'eaf9ec0c-d93b-4d7a-b5da-f586538e84ad'::uuid,
  p_correct_answers => '["7/12"]'::jsonb,
  p_solution        => 'Insgesamt 4 + 5 + 3 = 12 Kugeln, P(blau) = 5/12.
P(keine blaue) = 1 − 5/12 = 7/12.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wahrscheinlichkeit für eine blaue Kugel angegeben.","socratic_question":"Nach welchem Ereignis war gefragt?"},{"error":"Nicht-blaue durch blaue Kugeln geteilt: 7/5.","socratic_question":"Wie viele Kugeln liegen insgesamt in der Urne?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7/12","known_errors":{"5/12":"gegenereignis_nicht_abgezogen","7/5":"verhaeltnis_statt_anteil","1,4":"verhaeltnis_statt_anteil","1.4":"verhaeltnis_statt_anteil","140 %":"verhaeltnis_statt_anteil","140%":"verhaeltnis_statt_anteil"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 stoch-gegenereignis-04 · Gegenereignis · Glücksrad · weder rot noch blau
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '15164236-c70e-4a67-a567-e8dbb080d7af'::uuid, 'exercise', 'Gegenereignis · Glücksrad · weder rot noch blau', 'Ein Glücksrad hat rote, blaue und gelbe Felder. Es bleibt mit der Wahrscheinlichkeit 1/4 auf Rot und mit der Wahrscheinlichkeit 1/8 auf Blau stehen.

Wie groß ist die Wahrscheinlichkeit, dass es auf Gelb stehen bleibt? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Ein Glücksrad hat rote, blaue und gelbe Felder. Es bleibt mit der Wahrscheinlichkeit 1/4 auf Rot und mit der Wahrscheinlichkeit 1/8 auf Blau stehen.\n\nWie groß ist die Wahrscheinlichkeit, dass es auf Gelb stehen bleibt? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Wahrscheinlichkeiten addieren (Hauptnenner), dann Gegenwahrscheinlichkeit.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, bedingung_unvollstaendig, nenner_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '15164236-c70e-4a67-a567-e8dbb080d7af'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '15164236-c70e-4a67-a567-e8dbb080d7af'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '15164236-c70e-4a67-a567-e8dbb080d7af'::uuid,
  p_correct_answers => '["5/8","0,625","0.625","62,5 %","62,5%","62,5","62.5 %","62.5%","62.5"]'::jsonb,
  p_solution        => 'P(rot oder blau) = 1/4 + 1/8 = 2/8 + 1/8 = 3/8.
P(gelb) = 1 − 3/8 = 5/8 = 0,625 = 62,5 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"P(rot oder blau) angegeben, nicht von 1 abgezogen.","socratic_question":"Ist 3/8 die Wahrscheinlichkeit für Gelb oder für das Gegenteil?"},{"error":"Nur Rot von 1 abgezogen, Blau vergessen.","socratic_question":"Welche Felder gehören nicht zu Gelb?"},{"error":"Nur Blau von 1 abgezogen, Rot vergessen.","socratic_question":"Welche Felder gehören nicht zu Gelb?"},{"error":"Beim Addieren die Nenner addiert: 1/4 + 1/8 = 2/12, dann 1 − 2/12.","socratic_question":"Wie addierst du zwei Brüche mit verschiedenen Nennern?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5/8","equivalents":["0,625","0.625","62,5 %","62,5%","62,5","62.5 %","62.5%","62.5"],"known_errors":{"75":"bedingung_unvollstaendig","3/8":"gegenereignis_nicht_abgezogen","0,375":"gegenereignis_nicht_abgezogen","0.375":"gegenereignis_nicht_abgezogen","37,5 %":"gegenereignis_nicht_abgezogen","37,5%":"gegenereignis_nicht_abgezogen","37,5":"gegenereignis_nicht_abgezogen","37.5 %":"gegenereignis_nicht_abgezogen","37.5%":"gegenereignis_nicht_abgezogen","37.5":"gegenereignis_nicht_abgezogen","3/4":"bedingung_unvollstaendig","0,75":"bedingung_unvollstaendig","0.75":"bedingung_unvollstaendig","75 %":"bedingung_unvollstaendig","75%":"bedingung_unvollstaendig","7/8":"bedingung_unvollstaendig","0,875":"bedingung_unvollstaendig","0.875":"bedingung_unvollstaendig","87,5 %":"bedingung_unvollstaendig","87,5%":"bedingung_unvollstaendig","87,5":"bedingung_unvollstaendig","87.5 %":"bedingung_unvollstaendig","87.5%":"bedingung_unvollstaendig","87.5":"bedingung_unvollstaendig","5/6":"nenner_addiert","10/12":"nenner_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 stoch-gegenereignis-05 · Gegenereignis · Sachkontext · keine Niete
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd38afe88-221f-43a3-a3ec-469ea309dc42'::uuid, 'exercise', 'Gegenereignis · Sachkontext · keine Niete', 'In einer Lostrommel liegen 200 Lose. 30 davon sind Gewinne, 50 sind Trostpreise, alle übrigen sind Nieten. Ein Los wird zufällig gezogen.

Wie groß ist die Wahrscheinlichkeit, keine Niete zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"In einer Lostrommel liegen 200 Lose. 30 davon sind Gewinne, 50 sind Trostpreise, alle übrigen sind Nieten. Ein Los wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, keine Niete zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Ereignis „keine Niete“ als Gegenereignis oder als Summe bestimmen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, verhaeltnis_statt_anteil).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd38afe88-221f-43a3-a3ec-469ea309dc42'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd38afe88-221f-43a3-a3ec-469ea309dc42'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd38afe88-221f-43a3-a3ec-469ea309dc42'::uuid,
  p_correct_answers => '["2/5","4/10","8/20","10/25","16/40","20/50","40/100","80/200","0,4","0.4","40 %","40%","40"]'::jsonb,
  p_solution        => 'Nieten: 200 − 30 − 50 = 120, P(Niete) = 120/200.
P(keine Niete) = 1 − 120/200 = 80/200 = 2/5 = 0,4 = 40 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"P(Niete) angegeben statt P(keine Niete).","socratic_question":"Nach welchem Ereignis war gefragt?"},{"error":"Die Lose ohne Niete durch die Nieten geteilt: 80/120.","socratic_question":"Wie viele Lose liegen insgesamt in der Trommel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2/5","equivalents":["4/10","8/20","10/25","16/40","20/50","40/100","80/200","0,4","0.4","40 %","40%","40"],"known_errors":{"60":"gegenereignis_nicht_abgezogen","3/5":"gegenereignis_nicht_abgezogen","6/10":"gegenereignis_nicht_abgezogen","12/20":"gegenereignis_nicht_abgezogen","15/25":"gegenereignis_nicht_abgezogen","24/40":"gegenereignis_nicht_abgezogen","30/50":"gegenereignis_nicht_abgezogen","60/100":"gegenereignis_nicht_abgezogen","120/200":"gegenereignis_nicht_abgezogen","0,6":"gegenereignis_nicht_abgezogen","0.6":"gegenereignis_nicht_abgezogen","60 %":"gegenereignis_nicht_abgezogen","60%":"gegenereignis_nicht_abgezogen","2/3":"verhaeltnis_statt_anteil","4/6":"verhaeltnis_statt_anteil","8/12":"verhaeltnis_statt_anteil","10/15":"verhaeltnis_statt_anteil","16/24":"verhaeltnis_statt_anteil","20/30":"verhaeltnis_statt_anteil","40/60":"verhaeltnis_statt_anteil","80/120":"verhaeltnis_statt_anteil"}}'::jsonb);
  end if;
end
$loesung$;

-- #18 stoch-gegenereignis-06 · Gegenereignis · Rückrichtung · Zahl der roten Kugeln
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a45f865a-4684-4125-86cb-8df459348238'::uuid, 'exercise', 'Gegenereignis · Rückrichtung · Zahl der roten Kugeln', 'In einer Urne liegen 30 Kugeln. Die Wahrscheinlichkeit, zufällig keine rote Kugel zu ziehen, beträgt 0,7.

Wie viele rote Kugeln liegen in der Urne?',
  '{"kind":"short_input","prompt":"In einer Urne liegen 30 Kugeln. Die Wahrscheinlichkeit, zufällig keine rote Kugel zu ziehen, beträgt 0,7.\n\nWie viele rote Kugeln liegen in der Urne?"}'::jsonb, 'NUMERIC', 'stoch_gegenereignis',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Problemlösen',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-gegenereignis-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden in Rückrichtung: P(rot) über das Gegenereignis, dann Anzahl.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rückrichtung: Lösungsweg selbst finden, dann rechnen.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Minus/Plus-Formen und Einheit.","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, umgekehrt_geteilt).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a45f865a-4684-4125-86cb-8df459348238'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a45f865a-4684-4125-86cb-8df459348238'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a45f865a-4684-4125-86cb-8df459348238'::uuid,
  p_correct_answers => '["9","+9"]'::jsonb,
  p_solution        => 'P(rot) = 1 − 0,7 = 0,3.
Rote Kugeln: 0,3 · 30 = 9.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 0,7 gerechnet: das ist die Zahl der nicht roten Kugeln.","socratic_question":"Gehört 0,7 zu den roten Kugeln oder zu den übrigen?"},{"error":"Durch 0,3 geteilt statt mit 0,3 malgenommen.","socratic_question":"Können mehr rote Kugeln in der Urne liegen, als es Kugeln gibt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9","equivalents":["+9"],"known_errors":{"21":"gegenereignis_nicht_abgezogen","100":"umgekehrt_geteilt","+21":"gegenereignis_nicht_abgezogen","+100":"umgekehrt_geteilt"}}'::jsonb);
  end if;
end
$loesung$;

-- #19 stoch-pfad-produkt-01 · Produktregel · Münze · zweimal Kopf
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'df337432-9db5-4a28-be26-e64132f93659'::uuid, 'exercise', 'Produktregel · Münze · zweimal Kopf', 'Eine faire Münze wird zweimal geworfen.

Wie groß ist die Wahrscheinlichkeit, zweimal Kopf zu werfen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Eine faire Münze wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, zweimal Kopf zu werfen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: ein Pfad, zwei gleiche Stufen, multiplizieren.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'df337432-9db5-4a28-be26-e64132f93659'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'df337432-9db5-4a28-be26-e64132f93659'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'df337432-9db5-4a28-be26-e64132f93659'::uuid,
  p_correct_answers => '["1/4","0,25","0.25","25 %","25%","25"]'::jsonb,
  p_solution        => 'Pfad Kopf – Kopf: P = 1/2 · 1/2 = 1/4 = 0,25 = 25 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Entlang des Pfades addiert: 1/2 + 1/2 = 1.","socratic_question":"Ist „zweimal Kopf“ wirklich sicher?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/4","equivalents":["0,25","0.25","25 %","25%","25"],"known_errors":{"1":"pfadregel_addiert","100":"pfadregel_addiert","2/2":"pfadregel_addiert","100 %":"pfadregel_addiert","100%":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #20 stoch-pfad-produkt-02 · Produktregel · Würfel · zweimal Sechs
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'aab137cc-edfd-411f-ba49-af6a353a97e5'::uuid, 'exercise', 'Produktregel · Würfel · zweimal Sechs', 'Ein fairer Würfel wird zweimal geworfen.

Wie groß ist die Wahrscheinlichkeit, zweimal eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"Ein fairer Würfel wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, zweimal eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: ein Pfad, zwei gleiche Stufen, multiplizieren.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'aab137cc-edfd-411f-ba49-af6a353a97e5'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'aab137cc-edfd-411f-ba49-af6a353a97e5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'aab137cc-edfd-411f-ba49-af6a353a97e5'::uuid,
  p_correct_answers => '["1/36"]'::jsonb,
  p_solution        => 'Pfad Sechs – Sechs: P = 1/6 · 1/6 = 1/36.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Entlang des Pfades addiert: 1/6 + 1/6 = 2/6.","socratic_question":"Ist zweimal eine Sechs wahrscheinlicher oder unwahrscheinlicher als einmal eine Sechs?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/36","known_errors":{"1/3":"pfadregel_addiert","2/6":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #21 stoch-pfad-produkt-03 · Produktregel · Urne · mit Zurücklegen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid, 'exercise', 'Produktregel · Urne · mit Zurücklegen', 'In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.

Wie groß ist die Wahrscheinlichkeit, zweimal eine rote Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.\n\nWie groß ist die Wahrscheinlichkeit, zweimal eine rote Kugel zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zweistufig mit Zurücklegen, gleiche Wahrscheinlichkeit auf beiden Stufen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pfadregel_addiert, zuruecklegen_ignoriert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid,
  p_correct_answers => '["9/25","0,36","0.36","36 %","36%","36"]'::jsonb,
  p_solution        => 'Mit Zurücklegen bleibt P(rot) in beiden Zügen 3/5.
P(rot, rot) = 3/5 · 3/5 = 9/25 = 0,36 = 36 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Entlang des Pfades addiert: 3/5 + 3/5 = 6/5.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"},{"error":"Im zweiten Zug so gerechnet, als fehlte die erste Kugel: 3/5 · 2/4.","socratic_question":"Wie viele Kugeln liegen beim zweiten Zug in der Urne, wenn zurückgelegt wird?"}]'::jsonb,
  p_acceptance      => '{"canonical":"9/25","equivalents":["0,36","0.36","36 %","36%","36"],"known_errors":{"30":"zuruecklegen_ignoriert","120":"pfadregel_addiert","6/5":"pfadregel_addiert","1,2":"pfadregel_addiert","1.2":"pfadregel_addiert","120 %":"pfadregel_addiert","120%":"pfadregel_addiert","3/10":"zuruecklegen_ignoriert","6/20":"zuruecklegen_ignoriert","0,3":"zuruecklegen_ignoriert","0.3":"zuruecklegen_ignoriert","30 %":"zuruecklegen_ignoriert","30%":"zuruecklegen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #22 stoch-pfad-produkt-04 · Produktregel · Urne · ohne Zurücklegen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '71295abb-8ccc-418c-bff3-b70585fd60aa'::uuid, 'exercise', 'Produktregel · Urne · ohne Zurücklegen', 'In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.

Wie groß ist die Wahrscheinlichkeit, zwei blaue Kugeln zu ziehen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.\n\nWie groß ist die Wahrscheinlichkeit, zwei blaue Kugeln zu ziehen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zweistufig ohne Zurücklegen, Inhalt der Urne ändert sich.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zuruecklegen_ignoriert, pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '71295abb-8ccc-418c-bff3-b70585fd60aa'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '71295abb-8ccc-418c-bff3-b70585fd60aa'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '71295abb-8ccc-418c-bff3-b70585fd60aa'::uuid,
  p_correct_answers => '["1/3","2/6","3/9","5/15","6/18","10/30","15/45","30/90"]'::jsonb,
  p_solution        => '1. Zug: P(blau) = 6/10. Danach liegen noch 9 Kugeln da, 5 davon blau.
2. Zug: P(blau) = 5/9.
P(blau, blau) = 6/10 · 5/9 = 30/90 = 1/3.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Im zweiten Zug mit der alten Anzahl gerechnet: 6/10 · 6/10.","socratic_question":"Wie viele blaue Kugeln liegen nach dem ersten Zug noch in der Urne?"},{"error":"Entlang des Pfades addiert: 6/10 + 5/9.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/3","equivalents":["2/6","3/9","5/15","6/18","10/30","15/45","30/90"],"known_errors":{"9/25":"zuruecklegen_ignoriert","18/50":"zuruecklegen_ignoriert","36/100":"zuruecklegen_ignoriert","0,36":"zuruecklegen_ignoriert","0.36":"zuruecklegen_ignoriert","36 %":"zuruecklegen_ignoriert","36%":"zuruecklegen_ignoriert","52/45":"pfadregel_addiert","104/90":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 stoch-pfad-produkt-05 · Produktregel · Sachkontext · zwei Gewinnlose
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3c2b1997-3c6d-4b1b-b074-60cf1280946d'::uuid, 'exercise', 'Produktregel · Sachkontext · zwei Gewinnlose', 'In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.

Wie groß ist die Wahrscheinlichkeit, dass beide Lose Gewinne sind? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.\n\nWie groß ist die Wahrscheinlichkeit, dass beide Lose Gewinne sind? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Ziehen ohne Zurücklegen im Sachkontext erkennen und multiplizieren.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zuruecklegen_ignoriert, pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3c2b1997-3c6d-4b1b-b074-60cf1280946d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3c2b1997-3c6d-4b1b-b074-60cf1280946d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3c2b1997-3c6d-4b1b-b074-60cf1280946d'::uuid,
  p_correct_answers => '["1/15","2/30","3/45","6/90"]'::jsonb,
  p_solution        => '1. Los: P(Gewinn) = 3/10. Danach 9 Lose, 2 davon Gewinne.
2. Los: P(Gewinn) = 2/9.
P = 3/10 · 2/9 = 6/90 = 1/15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Im zweiten Zug mit der alten Anzahl gerechnet: 3/10 · 3/10.","socratic_question":"Wie viele Gewinnlose sind nach dem ersten Zug noch in der Trommel?"},{"error":"Entlang des Pfades addiert: 3/10 + 2/9.","socratic_question":"Ist „beide gewinnen“ wahrscheinlicher als „das erste gewinnt“?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/15","equivalents":["2/30","3/45","6/90"],"known_errors":{"9/100":"zuruecklegen_ignoriert","0,09":"zuruecklegen_ignoriert","0.09":"zuruecklegen_ignoriert","9 %":"zuruecklegen_ignoriert","9%":"zuruecklegen_ignoriert","47/90":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #24 stoch-pfad-produkt-06 · Produktregel · Sachkontext · drei Stufen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ddaa4ecd-1fff-4dec-ba4b-59e4069cfa9a'::uuid, 'exercise', 'Produktregel · Sachkontext · drei Stufen', 'Eine Maschine füllt Tüten ab. 10 % der Tüten sind zu leicht. Es werden drei Tüten zufällig und unabhängig voneinander geprüft.

Wie groß ist die Wahrscheinlichkeit, dass alle drei Tüten zu leicht sind? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Eine Maschine füllt Tüten ab. 10 % der Tüten sind zu leicht. Es werden drei Tüten zufällig und unabhängig voneinander geprüft.\n\nWie groß ist die Wahrscheinlichkeit, dass alle drei Tüten zu leicht sind? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_produkt',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-produkt-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: dreistufiger Pfad mit Prozentangabe, multiplizieren.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'ddaa4ecd-1fff-4dec-ba4b-59e4069cfa9a'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ddaa4ecd-1fff-4dec-ba4b-59e4069cfa9a'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'ddaa4ecd-1fff-4dec-ba4b-59e4069cfa9a'::uuid,
  p_correct_answers => '["0,001","1/1000","0.001","0,1 %","0,1%","0.1 %","0.1%"]'::jsonb,
  p_solution        => 'P(zu leicht) = 10 % = 0,1 für jede Tüte.
P(alle drei) = 0,1 · 0,1 · 0,1 = 0,001 = 1/1000 = 0,1 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Entlang des Pfades addiert: 0,1 + 0,1 + 0,1 = 0,3.","socratic_question":"Sind drei zu leichte Tüten häufiger als eine?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,001","equivalents":["1/1000","0.001","0,1 %","0,1%","0.1 %","0.1%"],"known_errors":{"30":"pfadregel_addiert","3/10":"pfadregel_addiert","0,3":"pfadregel_addiert","0.3":"pfadregel_addiert","30 %":"pfadregel_addiert","30%":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 stoch-pfad-summe-01 · Summenregel · Münze · genau einmal Kopf
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '939baa76-0207-496c-a768-4df2988f7f12'::uuid, 'exercise', 'Summenregel · Münze · genau einmal Kopf', 'Eine faire Münze wird zweimal geworfen.

Wie groß ist die Wahrscheinlichkeit, genau einmal Kopf zu werfen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Eine faire Münze wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, genau einmal Kopf zu werfen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei Pfade, je multiplizieren, dann addieren.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_ein_pfad, pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '939baa76-0207-496c-a768-4df2988f7f12'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '939baa76-0207-496c-a768-4df2988f7f12'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '939baa76-0207-496c-a768-4df2988f7f12'::uuid,
  p_correct_answers => '["1/2","2/4","0,5","0.5","50 %","50%","50"]'::jsonb,
  p_solution        => 'Passende Pfade: Kopf – Zahl und Zahl – Kopf.
P = 1/2 · 1/2 + 1/2 · 1/2 = 1/4 + 1/4 = 1/2 = 0,5 = 50 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Pfad Kopf – Zahl gezählt.","socratic_question":"Auf welchen Wegen kann genau einmal Kopf fallen?"},{"error":"Entlang der Pfade addiert statt multipliziert.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1/2","equivalents":["2/4","0,5","0.5","50 %","50%","50"],"known_errors":{"2":"pfadregel_addiert","25":"nur_ein_pfad","200":"pfadregel_addiert","1/4":"nur_ein_pfad","0,25":"nur_ein_pfad","0.25":"nur_ein_pfad","25 %":"nur_ein_pfad","25%":"nur_ein_pfad","200 %":"pfadregel_addiert","200%":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 stoch-pfad-summe-02 · Summenregel · Urne · zwei Farben mit Zurücklegen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid, 'exercise', 'Summenregel · Urne · zwei Farben mit Zurücklegen', 'In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.

Wie groß ist die Wahrscheinlichkeit, zwei verschiedenfarbige Kugeln zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.\n\nWie groß ist die Wahrscheinlichkeit, zwei verschiedenfarbige Kugeln zu ziehen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei Pfade mit Zurücklegen, gleiche Faktoren in beiden Reihenfolgen.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_ein_pfad, zuruecklegen_ignoriert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid,
  p_correct_answers => '["12/25","0,48","0.48","48 %","48%","48"]'::jsonb,
  p_solution        => 'Passende Pfade: rot – blau und blau – rot.
P = 3/5 · 2/5 + 2/5 · 3/5 = 6/25 + 6/25 = 12/25 = 0,48 = 48 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Pfad rot – blau gezählt.","socratic_question":"Kann die blaue Kugel auch zuerst gezogen werden?"},{"error":"Im zweiten Zug so gerechnet, als fehlte die erste Kugel.","socratic_question":"Wie viele Kugeln liegen beim zweiten Zug in der Urne, wenn zurückgelegt wird?"}]'::jsonb,
  p_acceptance      => '{"canonical":"12/25","equivalents":["0,48","0.48","48 %","48%","48"],"known_errors":{"24":"nur_ein_pfad","60":"zuruecklegen_ignoriert","6/25":"nur_ein_pfad","0,24":"nur_ein_pfad","0.24":"nur_ein_pfad","24 %":"nur_ein_pfad","24%":"nur_ein_pfad","3/5":"zuruecklegen_ignoriert","6/10":"zuruecklegen_ignoriert","12/20":"zuruecklegen_ignoriert","0,6":"zuruecklegen_ignoriert","0.6":"zuruecklegen_ignoriert","60 %":"zuruecklegen_ignoriert","60%":"zuruecklegen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 stoch-pfad-summe-03 · Summenregel · Urne · gleiche Farbe ohne Zurücklegen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '8b6561e6-1e6c-4c56-a35f-6ccc22f77807'::uuid, 'exercise', 'Summenregel · Urne · gleiche Farbe ohne Zurücklegen', 'In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.

Wie groß ist die Wahrscheinlichkeit, zwei Kugeln derselben Farbe zu ziehen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.\n\nWie groß ist die Wahrscheinlichkeit, zwei Kugeln derselben Farbe zu ziehen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Pfade ohne Zurücklegen, verschiedene Faktoren je Pfad.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_ein_pfad, zuruecklegen_ignoriert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '8b6561e6-1e6c-4c56-a35f-6ccc22f77807'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '8b6561e6-1e6c-4c56-a35f-6ccc22f77807'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '8b6561e6-1e6c-4c56-a35f-6ccc22f77807'::uuid,
  p_correct_answers => '["7/15","14/30","21/45","42/90"]'::jsonb,
  p_solution        => 'Passende Pfade: rot – rot und blau – blau.
P = 4/10 · 3/9 + 6/10 · 5/9 = 12/90 + 30/90 = 42/90 = 7/15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Pfad blau – blau gezählt.","socratic_question":"Welche zwei Farbpaare haben „dieselbe Farbe“?"},{"error":"Nur den Pfad rot – rot gezählt.","socratic_question":"Welche zwei Farbpaare haben „dieselbe Farbe“?"},{"error":"Im zweiten Zug mit der alten Anzahl gerechnet.","socratic_question":"Wie viele Kugeln liegen nach dem ersten Zug noch in der Urne?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7/15","equivalents":["14/30","21/45","42/90"],"known_errors":{"1/3":"nur_ein_pfad","2/6":"nur_ein_pfad","3/9":"nur_ein_pfad","5/15":"nur_ein_pfad","6/18":"nur_ein_pfad","10/30":"nur_ein_pfad","15/45":"nur_ein_pfad","30/90":"nur_ein_pfad","2/15":"nur_ein_pfad","4/30":"nur_ein_pfad","6/45":"nur_ein_pfad","12/90":"nur_ein_pfad","13/25":"zuruecklegen_ignoriert","26/50":"zuruecklegen_ignoriert","52/100":"zuruecklegen_ignoriert","0,52":"zuruecklegen_ignoriert","0.52":"zuruecklegen_ignoriert","52 %":"zuruecklegen_ignoriert","52%":"zuruecklegen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 stoch-pfad-summe-04 · Summenregel · Würfel · mindestens eine Sechs
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '64091830-731d-4ab2-b1f6-2166bb8539e6'::uuid, 'exercise', 'Summenregel · Würfel · mindestens eine Sechs', 'Ein fairer Würfel wird zweimal geworfen.

Wie groß ist die Wahrscheinlichkeit, mindestens eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"Ein fairer Würfel wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, mindestens eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: „mindestens einmal“ über das Gegenereignis „keine Sechs“ oder über drei Pfade.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, pfadregel_addiert, nur_ein_pfad).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '64091830-731d-4ab2-b1f6-2166bb8539e6'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '64091830-731d-4ab2-b1f6-2166bb8539e6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '64091830-731d-4ab2-b1f6-2166bb8539e6'::uuid,
  p_correct_answers => '["11/36"]'::jsonb,
  p_solution        => 'Gegenereignis: keine Sechs in beiden Würfen, P = 5/6 · 5/6 = 25/36.
P(mindestens eine Sechs) = 1 − 25/36 = 11/36.
(Oder drei Pfade: 1/36 + 5/36 + 5/36 = 11/36.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"P(keine Sechs) angegeben, nicht von 1 abgezogen.","socratic_question":"Nach welchem Ereignis war gefragt?"},{"error":"Die Wahrscheinlichkeiten der beiden Würfe addiert: 1/6 + 1/6.","socratic_question":"Wie oft passt „zweimal Sechs“ in deine Rechnung – einmal oder zweimal?"},{"error":"Nur den Pfad Sechs – keine Sechs gezählt.","socratic_question":"Auf welchen Wegen kann mindestens eine Sechs fallen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"11/36","known_errors":{"25/36":"gegenereignis_nicht_abgezogen","1/3":"pfadregel_addiert","2/6":"pfadregel_addiert","3/9":"pfadregel_addiert","4/12":"pfadregel_addiert","6/18":"pfadregel_addiert","12/36":"pfadregel_addiert","5/36":"nur_ein_pfad"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 stoch-pfad-summe-05 · Summenregel · Sachkontext · mindestens ein Gewinn
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid, 'exercise', 'Summenregel · Sachkontext · mindestens ein Gewinn', 'Bei einem Glücksspiel auf einem Jahrmarkt gewinnt man bei jeder Drehung eines Glücksrads mit der Wahrscheinlichkeit 0,2. Man dreht dreimal.

Wie groß ist die Wahrscheinlichkeit, mindestens einmal zu gewinnen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.',
  '{"kind":"short_input","prompt":"Bei einem Glücksspiel auf einem Jahrmarkt gewinnt man bei jeder Drehung eines Glücksrads mit der Wahrscheinlichkeit 0,2. Man dreht dreimal.\n\nWie groß ist die Wahrscheinlichkeit, mindestens einmal zu gewinnen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: dreistufig, „mindestens einmal“ über das Gegenereignis.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gegenereignis_nicht_abgezogen, pfadregel_addiert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid,
  p_correct_answers => '["0,488","61/125","122/250","244/500","488/1000","0.488","48,8 %","48,8%","48,8","48.8 %","48.8%","48.8"]'::jsonb,
  p_solution        => 'Gegenereignis: dreimal kein Gewinn, P = 0,8 · 0,8 · 0,8 = 0,512.
P(mindestens ein Gewinn) = 1 − 0,512 = 0,488 = 48,8 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"P(kein Gewinn) angegeben, nicht von 1 abgezogen.","socratic_question":"Nach welchem Ereignis war gefragt?"},{"error":"Die Gewinnwahrscheinlichkeiten der drei Drehungen addiert.","socratic_question":"Was käme bei sechs Drehungen heraus – passt das noch?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,488","equivalents":["61/125","122/250","244/500","488/1000","0.488","48,8 %","48,8%","48,8","48.8 %","48.8%","48.8"],"known_errors":{"60":"pfadregel_addiert","64/125":"gegenereignis_nicht_abgezogen","128/250":"gegenereignis_nicht_abgezogen","256/500":"gegenereignis_nicht_abgezogen","512/1000":"gegenereignis_nicht_abgezogen","0,512":"gegenereignis_nicht_abgezogen","0.512":"gegenereignis_nicht_abgezogen","51,2 %":"gegenereignis_nicht_abgezogen","51,2%":"gegenereignis_nicht_abgezogen","51,2":"gegenereignis_nicht_abgezogen","51.2 %":"gegenereignis_nicht_abgezogen","51.2%":"gegenereignis_nicht_abgezogen","51.2":"gegenereignis_nicht_abgezogen","3/5":"pfadregel_addiert","6/10":"pfadregel_addiert","0,6":"pfadregel_addiert","0.6":"pfadregel_addiert","60 %":"pfadregel_addiert","60%":"pfadregel_addiert"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 stoch-pfad-summe-06 · Summenregel · Sachkontext · genau ein Gewinnlos
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2d6edc4b-15e0-4090-b9af-1711ece32395'::uuid, 'exercise', 'Summenregel · Sachkontext · genau ein Gewinnlos', 'In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.

Wie groß ist die Wahrscheinlichkeit, genau ein Gewinnlos zu ziehen? Gib die Wahrscheinlichkeit als Bruch an.',
  '{"kind":"short_input","prompt":"In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.\n\nWie groß ist die Wahrscheinlichkeit, genau ein Gewinnlos zu ziehen? Gib die Wahrscheinlichkeit als Bruch an."}'::jsonb, 'NUMERIC', 'stoch_pfad_summe',
  8, 8,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren',
  90, null, false, null, 'draft', 'edvance_k8_stoch', 'stoch-pfad-summe-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Pfade ohne Zurücklegen im Sachkontext.","charge":"k8-stoch"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-stoch"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 8: KLP G9 Stochastik, Erste Stufe (Sto-3 bis Sto-5: Wahrscheinlichkeit, mehrstufige Zufallsexperimente); an Kölner Gymnasien üblich in Klasse 8.","charge":"k8-stoch"},"cluster_id":{"art":"neu","grund":"Daten & Zufall, Themengebiet der Stochastik (phase1 e).","charge":"k8-stoch"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (KLP Sto-1 bis Sto-5).","charge":"k8-stoch"},"competency_process":{"art":"neu","grund":"Sachsituation in ein Zufallsexperiment bzw. eine Datenreihe übersetzen und das Ergebnis deuten.","charge":"k8-stoch"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text (Experiment bzw. Datenreihe als Liste), keine Abbildung nötig.","charge":"k8-stoch"},"correct_answers":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-stoch"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-stoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_ein_pfad, zuruecklegen_ignoriert).","charge":"k8-stoch"},"hints":{"art":"leer","grund":"Auftrag W4 K8-Rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-stoch"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2d6edc4b-15e0-4090-b9af-1711ece32395'::uuid and t.status = 'draft' and t.source = 'edvance_k8_stoch')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2d6edc4b-15e0-4090-b9af-1711ece32395'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2d6edc4b-15e0-4090-b9af-1711ece32395'::uuid,
  p_correct_answers => '["7/15","14/30","21/45","42/90"]'::jsonb,
  p_solution        => 'Passende Pfade: Gewinn – Niete und Niete – Gewinn.
P = 3/10 · 7/9 + 7/10 · 3/9 = 21/90 + 21/90 = 42/90 = 7/15.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur den Pfad Gewinn – Niete gezählt.","socratic_question":"Kann das Gewinnlos auch als zweites gezogen werden?"},{"error":"Im zweiten Zug mit der alten Anzahl gerechnet.","socratic_question":"Wie viele Lose liegen nach dem ersten Zug noch in der Trommel?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7/15","equivalents":["14/30","21/45","42/90"],"known_errors":{"7/30":"nur_ein_pfad","21/90":"nur_ein_pfad","21/50":"zuruecklegen_ignoriert","42/100":"zuruecklegen_ignoriert","0,42":"zuruecklegen_ignoriert","0.42":"zuruecklegen_ignoriert","42 %":"zuruecklegen_ignoriert","42%":"zuruecklegen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;
