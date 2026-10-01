-- K8 Zinsrechnung, Migration 2 von 2 — 30 Aufgaben: je sechs zu den vier prozent_zins_*-Knoten, sechs zur Auffuellung von potenzen.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-zins.json (Quelle: tools/k8-zins-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261001123347_substrat_k8_zins.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Neue Aufgaben: je Zins-Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Sparen, Kredit, Ratenkauf, Überziehung, Preisänderung); dazu sechs potenzen-Aufgaben (Hochzahl 2 und 3, Dezimalbasis, Wachstumsfaktor), die auch der Kreis-Lauf nutzt. Teilzinsen nach kaufmännischer Konvention (30/360) im Aufgabentext; Zinseszins-Endkapital höchstens drei Jahre; alle Beträge unter 1000 €.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k8-zins.csv. Pruefprotokoll: docs/prefill/k8-zins-verifikation.md.
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
--   prozent_zins_jahreszins: zins-jahreszins-04 = 1, zins-jahreszins-06 = 2. Rang 1 aus Profil {dezimalverschiebung,nur_prozentwert}, Rang 2 aus Profil {bedingung_unvollstaendig,falsche_groesse_beantwortet} (2 neue Fehlbilder)
--   prozent_zins_teilzins: zins-teilzins-06 = 1, zins-teilzins-04 = 2. Rang 1 aus Profil {nur_prozentwert,zeitfaktor_vergessen,zu_frueh_gerundet}, Rang 2 aus Profil {zeitfaktor_vergessen,zinszeit_falsch_umgerechnet,zu_frueh_gerundet} (1 neue Fehlbilder)
--   prozent_zins_rueckrechnung: zins-rueckrechnung-06 = 1, zins-rueckrechnung-03 = 2. Rang 1 aus Profil {faktor_100_vergessen,falsche_groesse_beantwortet,grundwert_verwechselt}, Rang 2 aus Profil {faktor_100_vergessen,multipliziert_statt_dividiert} (1 neue Fehlbilder)
--   prozent_zins_zinseszins: zins-zinseszins-02 = 1, zins-zinseszins-05 = 2. Rang 1 aus Profil {nur_prozentwert,prozente_addiert,wachstumsfaktor_falsch,zu_frueh_gerundet}, Rang 2 aus Profil {bedingung_unvollstaendig,grundwert_verwechselt,prozente_addiert} (2 neue Fehlbilder)
--   potenzen: kein Rang: Auffuellung, Rang 1 und 2 liegen auf freigegebenen Bestandsaufgaben
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne --single-transaction, und
-- eine Aufgabe ohne Loesung waere still kaputt.

begin;

select set_config('request.jwt.claim.role', 'service_role', true);

-- #1 zins-jahreszins-01 · Jahreszinsen · Guthaben 600 € zu 3 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cee0061d-f262-48bc-a206-884b75fedbd4'::uuid, 'exercise', 'Jahreszinsen · Guthaben 600 € zu 3 %', 'Ein Guthaben von 600 € wird ein Jahr lang mit einem Zinssatz von 3 % verzinst.

Wie viel Euro Zinsen gibt es nach einem Jahr?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 600 € wird ein Jahr lang mit einem Zinssatz von 3 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-jahreszins-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Prozentwert mit ganzzahligem Zinssatz, ein Schritt.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (dezimalverschiebung, falsche_groesse_beantwortet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'cee0061d-f262-48bc-a206-884b75fedbd4'::uuid,
  p_correct_answers => '["18","18 €","18€"]'::jsonb,
  p_solution        => 'Jahreszinsen = Kapital · p/100
Z = 600 € · 3/100 = 18 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 3 statt mit 3/100 gerechnet: 600 · 3 = 1800.","socratic_question":"Wie viel sind 3 % – 3 Ganze oder 3 Hundertstel?"},{"error":"Neuen Kontostand statt der Zinsen angegeben: 600 + 18 = 618.","socratic_question":"Gefragt sind die Zinsen – ist das der ganze Kontostand oder nur der Teil, der dazukommt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"18","known_errors":{"618":"falsche_groesse_beantwortet","1800":"dezimalverschiebung","1800 €":"dezimalverschiebung","1800€":"dezimalverschiebung","618 €":"falsche_groesse_beantwortet","618€":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'cee0061d-f262-48bc-a206-884b75fedbd4'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cee0061d-f262-48bc-a206-884b75fedbd4'::uuid);

-- #2 zins-jahreszins-02 · Jahreszinsen · Guthaben 850 € zu 2 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '972862f3-5dfd-4c56-8509-15d15cec91dc'::uuid, 'exercise', 'Jahreszinsen · Guthaben 850 € zu 2 %', 'Ein Guthaben von 850 € wird ein Jahr lang mit einem Zinssatz von 2 % verzinst.

Wie viel Euro Zinsen gibt es nach einem Jahr?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 850 € wird ein Jahr lang mit einem Zinssatz von 2 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-jahreszins-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Prozentwert, ein Schritt; Kapital nicht rund.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (dezimalverschiebung, falsche_groesse_beantwortet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '972862f3-5dfd-4c56-8509-15d15cec91dc'::uuid,
  p_correct_answers => '["17","17 €","17€"]'::jsonb,
  p_solution        => 'Z = 850 € · 2/100 = 17 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 2 statt mit 2/100 gerechnet: 850 · 2 = 1700.","socratic_question":"Wie viel sind 2 % von 100 €? Passt das zu deinem Ergebnis?"},{"error":"Neuen Kontostand statt der Zinsen angegeben: 850 + 17 = 867.","socratic_question":"Gefragt sind die Zinsen – welcher Teil deiner Rechnung ist neu dazugekommen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"17","known_errors":{"867":"falsche_groesse_beantwortet","1700":"dezimalverschiebung","1700 €":"dezimalverschiebung","1700€":"dezimalverschiebung","867 €":"falsche_groesse_beantwortet","867€":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '972862f3-5dfd-4c56-8509-15d15cec91dc'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '972862f3-5dfd-4c56-8509-15d15cec91dc'::uuid);

-- #3 zins-jahreszins-03 · Jahreszinsen · Guthaben 640 € zu 2,5 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e8d5acdb-b1fd-4b74-8f18-2509c300cf90'::uuid, 'exercise', 'Jahreszinsen · Guthaben 640 € zu 2,5 %', 'Ein Guthaben von 640 € wird ein Jahr lang mit einem Zinssatz von 2,5 % verzinst.

Wie viel Euro Zinsen gibt es nach einem Jahr?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 640 € wird ein Jahr lang mit einem Zinssatz von 2,5 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-jahreszins-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zinssatz als Dezimalzahl, Prozentwert nicht im Kopf ablesbar.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (dezimalverschiebung, falsche_groesse_beantwortet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e8d5acdb-b1fd-4b74-8f18-2509c300cf90'::uuid,
  p_correct_answers => '["16","16 €","16€"]'::jsonb,
  p_solution        => 'Z = 640 € · 2,5/100 = 640 € · 0,025 = 16 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Mit 2,5 statt mit 2,5/100 gerechnet: 640 · 2,5 = 1600.","socratic_question":"Was bedeutet „Prozent\" – von wie vielen Teilen ist die Rede?"},{"error":"Neuen Kontostand statt der Zinsen angegeben: 640 + 16 = 656.","socratic_question":"Sind die Zinsen der ganze Betrag auf dem Konto oder nur das, was dazukommt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"16","known_errors":{"656":"falsche_groesse_beantwortet","1600":"dezimalverschiebung","1600 €":"dezimalverschiebung","1600€":"dezimalverschiebung","656 €":"falsche_groesse_beantwortet","656€":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e8d5acdb-b1fd-4b74-8f18-2509c300cf90'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e8d5acdb-b1fd-4b74-8f18-2509c300cf90'::uuid);

-- #4 zins-jahreszins-04 · Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ea141d44-521e-4250-a4bd-d9aa8e159238'::uuid, 'exercise', 'Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %', 'Auf ein Sparkonto werden 480 € eingezahlt. Der Zinssatz beträgt 3,5 % pro Jahr. Die Zinsen werden nach einem Jahr dem Konto gutgeschrieben.

Wie viel Euro sind nach einem Jahr auf dem Konto?',
  '{"kind":"short_input","prompt":"Auf ein Sparkonto werden 480 € eingezahlt. Der Zinssatz beträgt 3,5 % pro Jahr. Die Zinsen werden nach einem Jahr dem Konto gutgeschrieben.\n\nWie viel Euro sind nach einem Jahr auf dem Konto?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, 1, 'draft', 'edvance_k8_zins', 'zins-jahreszins-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Schritte (Zinsen, dann Kontostand); Ergebnis mit Cent.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_prozentwert, dezimalverschiebung).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'ea141d44-521e-4250-a4bd-d9aa8e159238'::uuid,
  p_correct_answers => '["496,80","496.80","496,8","496.8","496,80 €","496,80€","496,8 €","496,8€"]'::jsonb,
  p_solution        => 'Zinsen: 480 € · 3,5/100 = 16,80 €.
Kontostand: 480 € + 16,80 € = 496,80 €.
(Oder in einem Schritt: 480 € · 1,035 = 496,80 €.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Zinsen angegeben (16,80 €), nicht den Kontostand.","socratic_question":"Was steht nach einem Jahr auf dem Konto – nur die Zinsen oder auch das eingezahlte Geld?"},{"error":"Mit 3,5 statt mit 3,5/100 gerechnet: 480 + 480 · 3,5 = 2160.","socratic_question":"Kann das Geld in einem Jahr mit 3,5 % auf mehr als das Vierfache wachsen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"496,80","known_errors":{"2160":"dezimalverschiebung","16,80":"nur_prozentwert","16.80":"nur_prozentwert","16,8":"nur_prozentwert","16.8":"nur_prozentwert","16,80 €":"nur_prozentwert","16,80€":"nur_prozentwert","16,8 €":"nur_prozentwert","16,8€":"nur_prozentwert","2160 €":"dezimalverschiebung","2160€":"dezimalverschiebung"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'ea141d44-521e-4250-a4bd-d9aa8e159238'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ea141d44-521e-4250-a4bd-d9aa8e159238'::uuid);

-- #5 zins-jahreszins-05 · Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0e82ae91-8c55-4c75-ad2c-ef8ffb5649ad'::uuid, 'exercise', 'Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung', 'Für einen Kredit über 900 € verlangt ein Händler 6 % Zinsen pro Jahr. Nach einem Jahr wird der Kredit zusammen mit den Zinsen auf einmal zurückgezahlt.

Wie viel Euro werden insgesamt zurückgezahlt?',
  '{"kind":"short_input","prompt":"Für einen Kredit über 900 € verlangt ein Händler 6 % Zinsen pro Jahr. Nach einem Jahr wird der Kredit zusammen mit den Zinsen auf einmal zurückgezahlt.\n\nWie viel Euro werden insgesamt zurückgezahlt?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-jahreszins-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext Kredit: Rückzahlung = Kredit + Zinsen, die Situation muss übersetzt werden.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_prozentwert, dezimalverschiebung).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '0e82ae91-8c55-4c75-ad2c-ef8ffb5649ad'::uuid,
  p_correct_answers => '["954","954 €","954€"]'::jsonb,
  p_solution        => 'Zinsen: 900 € · 6/100 = 54 €.
Rückzahlung: 900 € + 54 € = 954 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Zinsen angegeben (54 €), nicht den ganzen Rückzahlungsbetrag.","socratic_question":"Was muss nach einem Jahr zurückgegeben werden – nur die Zinsen oder auch das geliehene Geld?"},{"error":"Mit 6 statt mit 6/100 gerechnet: 900 + 900 · 6 = 6300.","socratic_question":"Wären 6 % Zinsen mehr als das Sechsfache des Kredits?"}]'::jsonb,
  p_acceptance      => '{"canonical":"954","known_errors":{"54":"nur_prozentwert","6300":"dezimalverschiebung","54 €":"nur_prozentwert","54€":"nur_prozentwert","6300 €":"dezimalverschiebung","6300€":"dezimalverschiebung"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '0e82ae91-8c55-4c75-ad2c-ef8ffb5649ad'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0e82ae91-8c55-4c75-ad2c-ef8ffb5649ad'::uuid);

-- #6 zins-jahreszins-06 · Jahreszinsen · zwei Sparangebote vergleichen · 750 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f899a57b-8fec-459b-849c-d8ffaa51ee5e'::uuid, 'exercise', 'Jahreszinsen · zwei Sparangebote vergleichen · 750 €', 'Für 750 € gibt es zwei Sparangebote für ein Jahr:
Angebot A: 2 % Zinsen.
Angebot B: 1,5 % Zinsen und zusätzlich 5 € Bonus.

Um wie viel Euro bringt das bessere Angebot mehr als das andere?',
  '{"kind":"short_input","prompt":"Für 750 € gibt es zwei Sparangebote für ein Jahr:\nAngebot A: 2 % Zinsen.\nAngebot B: 1,5 % Zinsen und zusätzlich 5 € Bonus.\n\nUm wie viel Euro bringt das bessere Angebot mehr als das andere?"}'::jsonb, 'NUMERIC', 'prozent_zins_jahreszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'funktionen', 'Problemlösen, Modellieren',
  120, '€', false, 2, 'draft', 'edvance_k8_zins', 'zins-jahreszins-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: zwei Angebote modellieren, den Bonus einbeziehen, vergleichen und die Differenz bilden – Rechenweg selbst wählen.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_unvollstaendig, falsche_groesse_beantwortet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'f899a57b-8fec-459b-849c-d8ffaa51ee5e'::uuid,
  p_correct_answers => '["1,25","1.25","1,25 €","1,25€"]'::jsonb,
  p_solution        => 'Angebot A: 750 € · 2/100 = 15 €.
Angebot B: 750 € · 1,5/100 + 5 € = 11,25 € + 5 € = 16,25 €.
B bringt mehr: 16,25 € − 15 € = 1,25 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Bonus nicht berücksichtigt: 15 − 11,25 = 3,75.","socratic_question":"Welche Angabe zu Angebot B hast du noch nicht verwendet?"},{"error":"Den Ertrag von Angebot B angegeben statt des Unterschieds.","socratic_question":"Gefragt ist, um wie viel B mehr bringt – was musst du dafür noch rechnen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,25","known_errors":{"3,75":"bedingung_unvollstaendig","3.75":"bedingung_unvollstaendig","3,75 €":"bedingung_unvollstaendig","3,75€":"bedingung_unvollstaendig","16,25":"falsche_groesse_beantwortet","16.25":"falsche_groesse_beantwortet","16,25 €":"falsche_groesse_beantwortet","16,25€":"falsche_groesse_beantwortet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'f899a57b-8fec-459b-849c-d8ffaa51ee5e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f899a57b-8fec-459b-849c-d8ffaa51ee5e'::uuid);

-- #7 zins-teilzins-01 · Teilzinsen · 600 € zu 4 % für 3 Monate
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b0e9c1c6-561a-44ca-8903-62d4c8495b63'::uuid, 'exercise', 'Teilzinsen · 600 € zu 4 % für 3 Monate', 'Ein Guthaben von 600 € wird mit einem Zinssatz von 4 % pro Jahr verzinst. Das Geld bleibt nur 3 Monate auf dem Konto.

Wie viel Euro Zinsen gibt es für diese 3 Monate?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 600 € wird mit einem Zinssatz von 4 % pro Jahr verzinst. Das Geld bleibt nur 3 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 3 Monate?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-teilzins-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Jahreszinsen, dann ein glatter Zeitanteil (ein Viertel Jahr).","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeitfaktor_vergessen, zinszeit_falsch_umgerechnet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'b0e9c1c6-561a-44ca-8903-62d4c8495b63'::uuid,
  p_correct_answers => '["6","6 €","6€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 600 € · 4/100 = 24 €.
3 Monate sind 3/12 = 1/4 Jahr.
Zinsen: 24 € · 3/12 = 6 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zinsen für ein ganzes Jahr angegeben: 24 €.","socratic_question":"Für wie lange gilt der Zinssatz von 4 % – und wie lange liegt das Geld auf dem Konto?"},{"error":"Monate durch 100 statt durch 12 geteilt: 24 · 3/100 = 0,72.","socratic_question":"Wie viele Monate hat ein Jahr?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6","known_errors":{"24":"zeitfaktor_vergessen","24 €":"zeitfaktor_vergessen","24€":"zeitfaktor_vergessen","0,72":"zinszeit_falsch_umgerechnet","0.72":"zinszeit_falsch_umgerechnet","0,72 €":"zinszeit_falsch_umgerechnet","0,72€":"zinszeit_falsch_umgerechnet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'b0e9c1c6-561a-44ca-8903-62d4c8495b63'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b0e9c1c6-561a-44ca-8903-62d4c8495b63'::uuid);

-- #8 zins-teilzins-02 · Teilzinsen · 800 € zu 3 % für 5 Monate
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e9ac2c93-9310-446d-966b-c08e55253361'::uuid, 'exercise', 'Teilzinsen · 800 € zu 3 % für 5 Monate', 'Ein Guthaben von 800 € wird mit einem Zinssatz von 3 % pro Jahr verzinst. Das Geld bleibt 5 Monate auf dem Konto.

Wie viel Euro Zinsen gibt es für diese 5 Monate?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 800 € wird mit einem Zinssatz von 3 % pro Jahr verzinst. Das Geld bleibt 5 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 5 Monate?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-teilzins-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: wie Teilzins-01, Zeitanteil 5/12 ergibt glatt 10 €.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeitfaktor_vergessen, zinszeit_falsch_umgerechnet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e9ac2c93-9310-446d-966b-c08e55253361'::uuid,
  p_correct_answers => '["10","10 €","10€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 800 € · 3/100 = 24 €.
Zinsen für 5 Monate: 24 € · 5/12 = 10 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zinsen für ein ganzes Jahr angegeben: 24 €.","socratic_question":"Liegt das Geld ein ganzes Jahr auf dem Konto?"},{"error":"Mit 5 Jahren statt 5 Monaten gerechnet: 24 · 5 = 120.","socratic_question":"Sind 5 Monate mehr oder weniger als ein Jahr?"},{"error":"Monate durch 100 statt durch 12 geteilt: 24 · 5/100 = 1,2.","socratic_question":"Welcher Teil eines Jahres sind 5 Monate?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","known_errors":{"24":"zeitfaktor_vergessen","120":"zinszeit_falsch_umgerechnet","24 €":"zeitfaktor_vergessen","24€":"zeitfaktor_vergessen","120 €":"zinszeit_falsch_umgerechnet","120€":"zinszeit_falsch_umgerechnet","1,2":"zinszeit_falsch_umgerechnet","1.2":"zinszeit_falsch_umgerechnet","1,20":"zinszeit_falsch_umgerechnet","1.20":"zinszeit_falsch_umgerechnet","1,2 €":"zinszeit_falsch_umgerechnet","1,2€":"zinszeit_falsch_umgerechnet","1,20 €":"zinszeit_falsch_umgerechnet","1,20€":"zinszeit_falsch_umgerechnet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e9ac2c93-9310-446d-966b-c08e55253361'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e9ac2c93-9310-446d-966b-c08e55253361'::uuid);

-- #9 zins-teilzins-03 · Teilzinsen · 720 € zu 5 % für 40 Tage
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '7b761feb-7873-48c8-99cc-c2106ae5d530'::uuid, 'exercise', 'Teilzinsen · 720 € zu 5 % für 40 Tage', 'Ein Guthaben von 720 € wird mit einem Zinssatz von 5 % pro Jahr verzinst. Das Geld bleibt 40 Tage auf dem Konto.
Rechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage.

Wie viel Euro Zinsen gibt es für diese 40 Tage?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 720 € wird mit einem Zinssatz von 5 % pro Jahr verzinst. Das Geld bleibt 40 Tage auf dem Konto.\nRechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage.\n\nWie viel Euro Zinsen gibt es für diese 40 Tage?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-teilzins-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zeitanteil in Tagen nach der 360-Tage-Konvention.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeitfaktor_vergessen, zinszeit_falsch_umgerechnet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '7b761feb-7873-48c8-99cc-c2106ae5d530'::uuid,
  p_correct_answers => '["4","4 €","4€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 720 € · 5/100 = 36 €.
40 Tage sind 40/360 Jahr.
Zinsen: 36 € · 40/360 = 4 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zinsen für ein ganzes Jahr angegeben: 36 €.","socratic_question":"Für welchen Zeitraum gilt der Zinssatz – und wie lange liegt das Geld auf dem Konto?"},{"error":"Tage durch 100 statt durch 360 geteilt: 36 · 40/100 = 14,40.","socratic_question":"Wie viele Tage hat ein Zinsjahr laut Aufgabe?"},{"error":"Mit 40 Jahren statt 40 Tagen gerechnet: 36 · 40 = 1440.","socratic_question":"Sind 40 Tage mehr oder weniger als ein Jahr?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","known_errors":{"36":"zeitfaktor_vergessen","1440":"zinszeit_falsch_umgerechnet","36 €":"zeitfaktor_vergessen","36€":"zeitfaktor_vergessen","14,40":"zinszeit_falsch_umgerechnet","14.40":"zinszeit_falsch_umgerechnet","14,4":"zinszeit_falsch_umgerechnet","14.4":"zinszeit_falsch_umgerechnet","14,40 €":"zinszeit_falsch_umgerechnet","14,40€":"zinszeit_falsch_umgerechnet","14,4 €":"zinszeit_falsch_umgerechnet","14,4€":"zinszeit_falsch_umgerechnet","1440 €":"zinszeit_falsch_umgerechnet","1440€":"zinszeit_falsch_umgerechnet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '7b761feb-7873-48c8-99cc-c2106ae5d530'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '7b761feb-7873-48c8-99cc-c2106ae5d530'::uuid);

-- #10 zins-teilzins-04 · Teilzinsen · 900 € zu 2,5 % für 8 Monate
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '745351dc-794d-4939-9c33-fea2492bd8ff'::uuid, 'exercise', 'Teilzinsen · 900 € zu 2,5 % für 8 Monate', 'Ein Guthaben von 900 € wird mit einem Zinssatz von 2,5 % pro Jahr verzinst. Das Geld bleibt 8 Monate auf dem Konto.

Wie viel Euro Zinsen gibt es für diese 8 Monate?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 900 € wird mit einem Zinssatz von 2,5 % pro Jahr verzinst. Das Geld bleibt 8 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 8 Monate?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, 2, 'draft', 'edvance_k8_zins', 'zins-teilzins-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Dezimal-Zinssatz und Zeitanteil 8/12, der als Dezimalzahl nicht aufgeht.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeitfaktor_vergessen, zinszeit_falsch_umgerechnet, zu_frueh_gerundet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '745351dc-794d-4939-9c33-fea2492bd8ff'::uuid,
  p_correct_answers => '["15","15 €","15€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 900 € · 2,5/100 = 22,50 €.
Zinsen für 8 Monate: 22,50 € · 8/12 = 15 €.
(Den Zeitanteil 8/12 als Bruch stehen lassen, nicht vorher runden.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zinsen für ein ganzes Jahr angegeben: 22,50 €.","socratic_question":"Wie lange liegt das Geld auf dem Konto – und für wie lange gilt der Zinssatz?"},{"error":"Monate durch 100 statt durch 12 geteilt: 22,50 · 8/100 = 1,80.","socratic_question":"Welcher Bruchteil eines Jahres sind 8 Monate?"},{"error":"Zeitanteil 8/12 auf 0,67 gerundet und weitergerechnet: 22,50 · 0,67 = 15,08 (gerundet).","socratic_question":"Was passiert mit dem Ergebnis, wenn du 8/12 vor dem Multiplizieren rundest?"}]'::jsonb,
  p_acceptance      => '{"canonical":"15","known_errors":{"22,50":"zeitfaktor_vergessen","22.50":"zeitfaktor_vergessen","22,5":"zeitfaktor_vergessen","22.5":"zeitfaktor_vergessen","22,50 €":"zeitfaktor_vergessen","22,50€":"zeitfaktor_vergessen","22,5 €":"zeitfaktor_vergessen","22,5€":"zeitfaktor_vergessen","1,80":"zinszeit_falsch_umgerechnet","1.80":"zinszeit_falsch_umgerechnet","1,8":"zinszeit_falsch_umgerechnet","1.8":"zinszeit_falsch_umgerechnet","1,80 €":"zinszeit_falsch_umgerechnet","1,80€":"zinszeit_falsch_umgerechnet","1,8 €":"zinszeit_falsch_umgerechnet","1,8€":"zinszeit_falsch_umgerechnet","15,08":"zu_frueh_gerundet","15.08":"zu_frueh_gerundet","15,08 €":"zu_frueh_gerundet","15,08€":"zu_frueh_gerundet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '745351dc-794d-4939-9c33-fea2492bd8ff'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '745351dc-794d-4939-9c33-fea2492bd8ff'::uuid);

-- #11 zins-teilzins-05 · Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '663cac41-81da-41a8-9092-b63e0101e769'::uuid, 'exercise', 'Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage', 'Ein Girokonto ist 50 Tage lang um 500 € überzogen. Für die Überziehung verlangt die Bank 12 % Zinsen pro Jahr.
Rechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage. Runde das Ergebnis auf Cent.

Wie viel Euro Zinsen muss man für die 50 Tage zahlen?',
  '{"kind":"short_input","prompt":"Ein Girokonto ist 50 Tage lang um 500 € überzogen. Für die Überziehung verlangt die Bank 12 % Zinsen pro Jahr.\nRechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage. Runde das Ergebnis auf Cent.\n\nWie viel Euro Zinsen muss man für die 50 Tage zahlen?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-teilzins-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext Überziehung: Situation übersetzen, Tage-Konvention, Rundung erst am Ende.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (zeitfaktor_vergessen, zinszeit_falsch_umgerechnet, zu_frueh_gerundet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '663cac41-81da-41a8-9092-b63e0101e769'::uuid,
  p_correct_answers => '["8,33","8.33","8,33 €","8,33€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 500 € · 12/100 = 60 €.
Zinsen für 50 Tage: 60 € · 50/360 = 8,333… €.
Auf Cent gerundet: 8,33 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zinsen für ein ganzes Jahr angegeben: 60 €.","socratic_question":"Wie lange war das Konto überzogen?"},{"error":"Tage durch 100 statt durch 360 geteilt: 60 · 50/100 = 30.","socratic_question":"Wie viele Tage zählt ein Zinsjahr laut Aufgabe?"},{"error":"Zeitanteil 50/360 auf 0,14 gerundet: 60 · 0,14 = 8,40.","socratic_question":"Wann solltest du runden – beim Zeitanteil oder erst beim Ergebnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"8,33","known_errors":{"30":"zinszeit_falsch_umgerechnet","60":"zeitfaktor_vergessen","60 €":"zeitfaktor_vergessen","60€":"zeitfaktor_vergessen","30 €":"zinszeit_falsch_umgerechnet","30€":"zinszeit_falsch_umgerechnet","8,40":"zu_frueh_gerundet","8.40":"zu_frueh_gerundet","8,4":"zu_frueh_gerundet","8.4":"zu_frueh_gerundet","8,40 €":"zu_frueh_gerundet","8,40€":"zu_frueh_gerundet","8,4 €":"zu_frueh_gerundet","8,4€":"zu_frueh_gerundet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '663cac41-81da-41a8-9092-b63e0101e769'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '663cac41-81da-41a8-9092-b63e0101e769'::uuid);

-- #12 zins-teilzins-06 · Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2503c8e9-2f40-494e-865c-687d7256a771'::uuid, 'exercise', 'Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate', 'Ein Fahrrad kostet 840 €. Der Händler bietet an, den Preis erst später zu bezahlen. Dafür verlangt er 9 % Zinsen pro Jahr. Nach 7 Monaten wird alles auf einmal bezahlt.

Wie viel Euro werden insgesamt bezahlt?',
  '{"kind":"short_input","prompt":"Ein Fahrrad kostet 840 €. Der Händler bietet an, den Preis erst später zu bezahlen. Dafür verlangt er 9 % Zinsen pro Jahr. Nach 7 Monaten wird alles auf einmal bezahlt.\n\nWie viel Euro werden insgesamt bezahlt?"}'::jsonb, 'NUMERIC', 'prozent_zins_teilzins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'funktionen', 'Modellieren, Operieren',
  120, '€', false, 1, 'draft', 'edvance_k8_zins', 'zins-teilzins-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext Ratenkauf: Teilzinsen mit Zeitanteil 7/12, danach zum Preis addieren; mehrere Schritte selbst ordnen.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (nur_prozentwert, zeitfaktor_vergessen, zu_frueh_gerundet).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '2503c8e9-2f40-494e-865c-687d7256a771'::uuid,
  p_correct_answers => '["884,10","884.10","884,1","884.1","884,10 €","884,10€","884,1 €","884,1€"]'::jsonb,
  p_solution        => 'Jahreszinsen: 840 € · 9/100 = 75,60 €.
Zinsen für 7 Monate: 75,60 € · 7/12 = 44,10 €.
Gesamt: 840 € + 44,10 € = 884,10 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Nur die Zinsen angegeben (44,10 €), nicht den Gesamtbetrag.","socratic_question":"Was wird nach 7 Monaten bezahlt – nur die Zinsen oder auch das Fahrrad?"},{"error":"Zinsen für ein ganzes Jahr gerechnet: 840 + 75,60 = 915,60.","socratic_question":"Für wie viele Monate fallen Zinsen an?"},{"error":"Zeitanteil 7/12 auf 0,58 gerundet: 75,60 · 0,58 ≈ 43,85, also 883,85.","socratic_question":"Was ändert sich, wenn du 7/12 als Bruch stehen lässt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"884,10","known_errors":{"44,10":"nur_prozentwert","44.10":"nur_prozentwert","44,1":"nur_prozentwert","44.1":"nur_prozentwert","44,10 €":"nur_prozentwert","44,10€":"nur_prozentwert","44,1 €":"nur_prozentwert","44,1€":"nur_prozentwert","915,60":"zeitfaktor_vergessen","915.60":"zeitfaktor_vergessen","915,6":"zeitfaktor_vergessen","915.6":"zeitfaktor_vergessen","915,60 €":"zeitfaktor_vergessen","915,60€":"zeitfaktor_vergessen","915,6 €":"zeitfaktor_vergessen","915,6€":"zeitfaktor_vergessen","883,85":"zu_frueh_gerundet","883.85":"zu_frueh_gerundet","883,85 €":"zu_frueh_gerundet","883,85€":"zu_frueh_gerundet"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '2503c8e9-2f40-494e-865c-687d7256a771'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2503c8e9-2f40-494e-865c-687d7256a771'::uuid);

-- #13 zins-rueckrechnung-01 · Rückrechnung · Kapital aus 28 € Zinsen bei 4 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd0b5af07-3cd8-4da1-85ed-6a3e57cffc34'::uuid, 'exercise', 'Rückrechnung · Kapital aus 28 € Zinsen bei 4 %', 'Ein Guthaben bringt bei einem Zinssatz von 4 % in einem Jahr 28 € Zinsen.

Wie viel Euro beträgt das Guthaben?',
  '{"kind":"short_input","prompt":"Ein Guthaben bringt bei einem Zinssatz von 4 % in einem Jahr 28 € Zinsen.\n\nWie viel Euro beträgt das Guthaben?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Grundwert aus Prozentwert und glattem Prozentsatz.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd0b5af07-3cd8-4da1-85ed-6a3e57cffc34'::uuid,
  p_correct_answers => '["700","700 €","700€"]'::jsonb,
  p_solution        => '4 % des Guthabens sind 28 €.
1 % sind 28 € : 4 = 7 €.
100 % sind 7 € · 100 = 700 €.
Probe: 700 € · 4/100 = 28 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Multipliziert statt dividiert: 28 · 4/100 = 1,12.","socratic_question":"Ist das Guthaben größer oder kleiner als die Zinsen?"},{"error":"Nur 1 % ausgerechnet: 28 : 4 = 7.","socratic_question":"Für wie viel Prozent steht dein Ergebnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"700","known_errors":{"7":"faktor_100_vergessen","1,12":"multipliziert_statt_dividiert","1.12":"multipliziert_statt_dividiert","1,12 €":"multipliziert_statt_dividiert","1,12€":"multipliziert_statt_dividiert","7 €":"faktor_100_vergessen","7€":"faktor_100_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd0b5af07-3cd8-4da1-85ed-6a3e57cffc34'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd0b5af07-3cd8-4da1-85ed-6a3e57cffc34'::uuid);

-- #14 zins-rueckrechnung-02 · Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2d5e6e81-1f81-462c-8b70-db43a7454bb4'::uuid, 'exercise', 'Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €', 'Ein Guthaben von 500 € bringt in einem Jahr 15 € Zinsen.

Wie hoch ist der Zinssatz in Prozent?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 500 € bringt in einem Jahr 15 € Zinsen.\n\nWie hoch ist der Zinssatz in Prozent?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '%', false, null, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Prozentsatz aus zwei glatten Werten.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '2d5e6e81-1f81-462c-8b70-db43a7454bb4'::uuid,
  p_correct_answers => '["3","3 %","3%"]'::jsonb,
  p_solution        => 'p % = Zinsen : Kapital = 15 € : 500 € = 0,03 = 3 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Als Dezimalzahl stehen gelassen: 0,03 statt 3 %.","socratic_question":"Wie schreibst du 0,03 in Prozent?"},{"error":"Kapital durch Zinsen geteilt: 500 : 15 ≈ 33,33.","socratic_question":"Welcher Betrag ist der Anteil und welcher das Ganze?"},{"error":"Kapital durch Zinsen geteilt: 500 : 15 ≈ 33,3.","socratic_question":"Welcher Betrag ist der Anteil und welcher das Ganze?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3","known_errors":{"0,03":"faktor_100_vergessen","0.03":"faktor_100_vergessen","0,03 %":"faktor_100_vergessen","0,03%":"faktor_100_vergessen","33,33":"bezug_vertauscht","33.33":"bezug_vertauscht","33,33 %":"bezug_vertauscht","33,33%":"bezug_vertauscht","33,3":"bezug_vertauscht","33.3":"bezug_vertauscht","33,3 %":"bezug_vertauscht","33,3%":"bezug_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '2d5e6e81-1f81-462c-8b70-db43a7454bb4'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2d5e6e81-1f81-462c-8b70-db43a7454bb4'::uuid);

-- #15 zins-rueckrechnung-03 · Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '53f6be59-aaa0-450d-af10-6c9570a39ca9'::uuid, 'exercise', 'Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %', 'Ein Guthaben bringt bei einem Zinssatz von 3,5 % in einem Jahr 21 € Zinsen.

Wie viel Euro beträgt das Guthaben?',
  '{"kind":"short_input","prompt":"Ein Guthaben bringt bei einem Zinssatz von 3,5 % in einem Jahr 21 € Zinsen.\n\nWie viel Euro beträgt das Guthaben?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, 2, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Grundwert mit Dezimal-Zinssatz, Dreisatz nicht im Kopf.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '53f6be59-aaa0-450d-af10-6c9570a39ca9'::uuid,
  p_correct_answers => '["600","600 €","600€"]'::jsonb,
  p_solution        => 'Kapital = Zinsen : p/100 = 21 € : 0,035 = 600 €.
Probe: 600 € · 3,5/100 = 21 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Multipliziert statt dividiert: 21 · 3,5/100 = 0,735.","socratic_question":"Muss das Guthaben größer oder kleiner sein als 21 €?"},{"error":"Multipliziert statt dividiert: 21 · 3,5 = 73,5.","socratic_question":"Wenn du die Probe machst: Ergeben 3,5 % von deinem Ergebnis wirklich 21 €?"},{"error":"Nur 1 % ausgerechnet: 21 : 3,5 = 6.","socratic_question":"Für wie viel Prozent steht dein Ergebnis?"}]'::jsonb,
  p_acceptance      => '{"canonical":"600","known_errors":{"6":"faktor_100_vergessen","0,735":"multipliziert_statt_dividiert","0.735":"multipliziert_statt_dividiert","0,735 €":"multipliziert_statt_dividiert","0,735€":"multipliziert_statt_dividiert","73,5":"multipliziert_statt_dividiert","73.5":"multipliziert_statt_dividiert","73,50":"multipliziert_statt_dividiert","73.50":"multipliziert_statt_dividiert","73,5 €":"multipliziert_statt_dividiert","73,5€":"multipliziert_statt_dividiert","73,50 €":"multipliziert_statt_dividiert","73,50€":"multipliziert_statt_dividiert","6 €":"faktor_100_vergessen","6€":"faktor_100_vergessen"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '53f6be59-aaa0-450d-af10-6c9570a39ca9'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '53f6be59-aaa0-450d-af10-6c9570a39ca9'::uuid);

-- #16 zins-rueckrechnung-04 · Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '86f705e2-6364-4749-8faf-c031e6bf7110'::uuid, 'exercise', 'Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €', 'Ein Guthaben von 640 € bringt in einem Jahr 20,80 € Zinsen.

Wie hoch ist der Zinssatz in Prozent?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 640 € bringt in einem Jahr 20,80 € Zinsen.\n\nWie hoch ist der Zinssatz in Prozent?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '%', false, null, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Prozentsatz mit Cent-Betrag, Ergebnis ist ein Dezimal-Zinssatz.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '86f705e2-6364-4749-8faf-c031e6bf7110'::uuid,
  p_correct_answers => '["3,25","3.25","3,25 %","3,25%"]'::jsonb,
  p_solution        => 'p % = 20,80 € : 640 € = 0,0325 = 3,25 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Als Dezimalzahl stehen gelassen: 0,0325 statt 3,25 %.","socratic_question":"Wie wird aus 0,0325 eine Prozentangabe?"},{"error":"Kapital durch Zinsen geteilt: 640 : 20,80 ≈ 30,77.","socratic_question":"Welcher Betrag ist der Grundwert?"},{"error":"Kapital durch Zinsen geteilt: 640 : 20,80 ≈ 30,8.","socratic_question":"Welcher Betrag ist der Grundwert?"}]'::jsonb,
  p_acceptance      => '{"canonical":"3,25","known_errors":{"0,0325":"faktor_100_vergessen","0.0325":"faktor_100_vergessen","0,0325 %":"faktor_100_vergessen","0,0325%":"faktor_100_vergessen","30,77":"bezug_vertauscht","30.77":"bezug_vertauscht","30,77 %":"bezug_vertauscht","30,77%":"bezug_vertauscht","30,8":"bezug_vertauscht","30.8":"bezug_vertauscht","30,8 %":"bezug_vertauscht","30,8%":"bezug_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '86f705e2-6364-4749-8faf-c031e6bf7110'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '86f705e2-6364-4749-8faf-c031e6bf7110'::uuid);

-- #17 zins-rueckrechnung-05 · Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '77a9dabf-1e92-4a40-a28b-ba72bea91169'::uuid, 'exercise', 'Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %', 'Auf einem Sparkonto stehen nach einem Jahr 765 €. Die Zinsen von 2 % sind darin schon enthalten.

Wie viel Euro wurden am Anfang eingezahlt?',
  '{"kind":"short_input","prompt":"Auf einem Sparkonto stehen nach einem Jahr 765 €. Die Zinsen von 2 % sind darin schon enthalten.\n\nWie viel Euro wurden am Anfang eingezahlt?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  120, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung über den Wachstumsfaktor 1,02 – der naheliegende Weg (2 % vom Endbetrag abziehen) ist falsch und muss erkannt werden.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grundwert_verwechselt, multipliziert_statt_dividiert).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '77a9dabf-1e92-4a40-a28b-ba72bea91169'::uuid,
  p_correct_answers => '["750","750 €","750€"]'::jsonb,
  p_solution        => 'Der Kontostand ist 102 % der Einzahlung: Einzahlung · 1,02 = 765 €.
Einzahlung = 765 € : 1,02 = 750 €.
Probe: 750 € + 2 % von 750 € = 750 € + 15 € = 765 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2 % vom Endbetrag abgezogen: 765 − 15,30 = 749,70.","socratic_question":"Von welchem Betrag wurden die 2 % Zinsen berechnet – vom Anfangs- oder vom Endbetrag?"},{"error":"Mit 1,02 multipliziert statt dividiert: 765 · 1,02 = 780,30.","socratic_question":"War am Anfang mehr oder weniger Geld auf dem Konto als nach einem Jahr?"}]'::jsonb,
  p_acceptance      => '{"canonical":"750","known_errors":{"749,70":"grundwert_verwechselt","749.70":"grundwert_verwechselt","749,7":"grundwert_verwechselt","749.7":"grundwert_verwechselt","749,70 €":"grundwert_verwechselt","749,70€":"grundwert_verwechselt","749,7 €":"grundwert_verwechselt","749,7€":"grundwert_verwechselt","780,30":"multipliziert_statt_dividiert","780.30":"multipliziert_statt_dividiert","780,3":"multipliziert_statt_dividiert","780.3":"multipliziert_statt_dividiert","780,30 €":"multipliziert_statt_dividiert","780,30€":"multipliziert_statt_dividiert","780,3 €":"multipliziert_statt_dividiert","780,3€":"multipliziert_statt_dividiert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '77a9dabf-1e92-4a40-a28b-ba72bea91169'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '77a9dabf-1e92-4a40-a28b-ba72bea91169'::uuid);

-- #18 zins-rueckrechnung-06 · Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e059539e-120d-428b-ba3d-c11ae9c4a83d'::uuid, 'exercise', 'Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück', 'Für einen Kredit über 400 € müssen nach einem Jahr 428 € zurückgezahlt werden.

Wie hoch ist der Zinssatz in Prozent?',
  '{"kind":"short_input","prompt":"Für einen Kredit über 400 € müssen nach einem Jahr 428 € zurückgezahlt werden.\n\nWie hoch ist der Zinssatz in Prozent?"}'::jsonb, 'NUMERIC', 'prozent_zins_rueckrechnung',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, '%', false, 1, 'draft', 'edvance_k8_zins', 'zins-rueckrechnung-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext Kredit: erst die Zinsen als Differenz bestimmen, dann den Prozentsatz.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e059539e-120d-428b-ba3d-c11ae9c4a83d'::uuid,
  p_correct_answers => '["7","7 %","7%"]'::jsonb,
  p_solution        => 'Zinsen: 428 € − 400 € = 28 €.
Zinssatz: 28 € : 400 € = 0,07 = 7 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Rückzahlung als Prozent des Kredits angegeben (107 %) statt des Zinssatzes.","socratic_question":"Welcher Teil der 107 % sind die Zinsen?"},{"error":"Als Dezimalzahl stehen gelassen: 0,07 statt 7 %.","socratic_question":"Wie schreibst du 0,07 in Prozent?"},{"error":"Zinsen auf den Rückzahlungsbetrag bezogen: 28 : 428 ≈ 6,54 %.","socratic_question":"Auf welchen Betrag bezieht sich der Zinssatz – das Geliehene oder das Zurückgezahlte?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7","known_errors":{"107":"falsche_groesse_beantwortet","107 %":"falsche_groesse_beantwortet","107%":"falsche_groesse_beantwortet","0,07":"faktor_100_vergessen","0.07":"faktor_100_vergessen","0,07 %":"faktor_100_vergessen","0,07%":"faktor_100_vergessen","6,54":"grundwert_verwechselt","6.54":"grundwert_verwechselt","6,54 %":"grundwert_verwechselt","6,54%":"grundwert_verwechselt"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e059539e-120d-428b-ba3d-c11ae9c4a83d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e059539e-120d-428b-ba3d-c11ae9c4a83d'::uuid);

-- #19 zins-zinseszins-01 · Zinseszins · 500 € zu 4 % für 2 Jahre
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '736ea5a7-cc7f-44da-b042-8b0711207a15'::uuid, 'exercise', 'Zinseszins · 500 € zu 4 % für 2 Jahre', 'Ein Guthaben von 500 € wird jedes Jahr mit 4 % verzinst. Die Zinsen bleiben auf dem Konto und werden im nächsten Jahr mitverzinst.

Wie viel Euro sind nach 2 Jahren auf dem Konto?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 500 € wird jedes Jahr mit 4 % verzinst. Die Zinsen bleiben auf dem Konto und werden im nächsten Jahr mitverzinst.\n\nWie viel Euro sind nach 2 Jahren auf dem Konto?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'funktionen', 'Operieren',
  45, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-zinseszins-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei Jahre, Jahr für Jahr oder mit dem Faktor 1,04².","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, nur_prozentwert, wachstumsfaktor_falsch).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '736ea5a7-cc7f-44da-b042-8b0711207a15'::uuid,
  p_correct_answers => '["540,80","540.80","540,8","540.8","540,80 €","540,80€","540,8 €","540,8€"]'::jsonb,
  p_solution        => 'Nach 1 Jahr: 500 € · 1,04 = 520 €.
Nach 2 Jahren: 520 € · 1,04 = 540,80 €.
(Oder: 500 € · 1,04² = 500 € · 1,0816 = 540,80 €.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jedes Jahr nur 4 % vom Startkapital: 500 + 20 + 20 = 540.","socratic_question":"Wovon werden im zweiten Jahr die 4 % berechnet?"},{"error":"Nur die Zinsen angegeben (40,80 €), nicht den Kontostand.","socratic_question":"Was steht nach 2 Jahren auf dem Konto?"},{"error":"Faktor 1,4 statt 1,04: 500 · 1,4² = 980.","socratic_question":"Welcher Faktor gehört zu einer Zunahme um 4 %?"}]'::jsonb,
  p_acceptance      => '{"canonical":"540,80","known_errors":{"540":"prozente_addiert","980":"wachstumsfaktor_falsch","540 €":"prozente_addiert","540€":"prozente_addiert","40,80":"nur_prozentwert","40.80":"nur_prozentwert","40,8":"nur_prozentwert","40.8":"nur_prozentwert","40,80 €":"nur_prozentwert","40,80€":"nur_prozentwert","40,8 €":"nur_prozentwert","40,8€":"nur_prozentwert","980 €":"wachstumsfaktor_falsch","980€":"wachstumsfaktor_falsch"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '736ea5a7-cc7f-44da-b042-8b0711207a15'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '736ea5a7-cc7f-44da-b042-8b0711207a15'::uuid);

-- #20 zins-zinseszins-02 · Zinseszins · 800 € zu 5 % für 3 Jahre
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd9e29439-32a2-43b7-a35a-a0d166637802'::uuid, 'exercise', 'Zinseszins · 800 € zu 5 % für 3 Jahre', 'Ein Guthaben von 800 € wird jedes Jahr mit 5 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.

Wie viel Euro sind nach 3 Jahren auf dem Konto?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 800 € wird jedes Jahr mit 5 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nWie viel Euro sind nach 3 Jahren auf dem Konto?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, 1, 'draft', 'edvance_k8_zins', 'zins-zinseszins-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: drei Jahre, Faktor 1,05³ bzw. drei Schritte; Ergebnis mit Cent.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, nur_prozentwert, zu_frueh_gerundet, wachstumsfaktor_falsch).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'd9e29439-32a2-43b7-a35a-a0d166637802'::uuid,
  p_correct_answers => '["926,10","926.10","926,1","926.1","926,10 €","926,10€","926,1 €","926,1€"]'::jsonb,
  p_solution        => 'Nach 1 Jahr: 800 € · 1,05 = 840 €.
Nach 2 Jahren: 840 € · 1,05 = 882 €.
Nach 3 Jahren: 882 € · 1,05 = 926,10 €.
(Oder: 800 € · 1,05³ = 800 € · 1,157625 = 926,10 €.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jedes Jahr nur 5 % vom Startkapital: 800 + 3 · 40 = 920.","socratic_question":"Wovon werden im dritten Jahr die 5 % berechnet?"},{"error":"Nur die Zinsen angegeben (126,10 €), nicht den Kontostand.","socratic_question":"Was steht nach 3 Jahren auf dem Konto?"},{"error":"Faktor 1,157625 auf 1,158 gerundet: 800 · 1,158 = 926,40.","socratic_question":"Rechne Jahr für Jahr nach: Geht jedes Jahr glatt auf?"},{"error":"Faktor 1,157625 auf 1,16 gerundet: 800 · 1,16 = 928.","socratic_question":"Wann darfst du runden – vor oder nach dem Multiplizieren?"},{"error":"Faktor 1,5 statt 1,05: 800 · 1,5³ = 2700.","socratic_question":"Welcher Faktor gehört zu einer Zunahme um 5 %?"}]'::jsonb,
  p_acceptance      => '{"canonical":"926,10","known_errors":{"920":"prozente_addiert","928":"zu_frueh_gerundet","2700":"wachstumsfaktor_falsch","920 €":"prozente_addiert","920€":"prozente_addiert","126,10":"nur_prozentwert","126.10":"nur_prozentwert","126,1":"nur_prozentwert","126.1":"nur_prozentwert","126,10 €":"nur_prozentwert","126,10€":"nur_prozentwert","126,1 €":"nur_prozentwert","126,1€":"nur_prozentwert","926,40":"zu_frueh_gerundet","926.40":"zu_frueh_gerundet","926,4":"zu_frueh_gerundet","926.4":"zu_frueh_gerundet","926,40 €":"zu_frueh_gerundet","926,40€":"zu_frueh_gerundet","926,4 €":"zu_frueh_gerundet","926,4€":"zu_frueh_gerundet","928 €":"zu_frueh_gerundet","928€":"zu_frueh_gerundet","2700 €":"wachstumsfaktor_falsch","2700€":"wachstumsfaktor_falsch"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'd9e29439-32a2-43b7-a35a-a0d166637802'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd9e29439-32a2-43b7-a35a-a0d166637802'::uuid);

-- #21 zins-zinseszins-03 · Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'ab2df4fc-6d03-45a3-a974-7191461d00fc'::uuid, 'exercise', 'Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %', 'Ein Guthaben von 600 € wird jedes Jahr mit 3 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.

Wie viel Euro Zinsen sind nach 2 Jahren insgesamt dazugekommen?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 600 € wird jedes Jahr mit 3 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nWie viel Euro Zinsen sind nach 2 Jahren insgesamt dazugekommen?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Operieren',
  60, '€', false, null, 'draft', 'edvance_k8_zins', 'zins-zinseszins-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Zinseszins über zwei Jahre, dann die Zinsen als Differenz – gefragt ist nicht der Kontostand.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, falsche_groesse_beantwortet, wachstumsfaktor_falsch).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'ab2df4fc-6d03-45a3-a974-7191461d00fc'::uuid,
  p_correct_answers => '["36,54","36.54","36,54 €","36,54€"]'::jsonb,
  p_solution        => 'Nach 1 Jahr: 600 € · 1,03 = 618 €.
Nach 2 Jahren: 618 € · 1,03 = 636,54 €.
Zinsen insgesamt: 636,54 € − 600 € = 36,54 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Zweimal 3 % vom Startkapital: 18 + 18 = 36.","socratic_question":"Bekommen auch die Zinsen aus dem ersten Jahr im zweiten Jahr Zinsen?"},{"error":"Kontostand statt der Zinsen angegeben: 636,54.","socratic_question":"Gefragt sind nur die Zinsen – was musst du vom Kontostand noch abziehen?"},{"error":"Faktor 1,3 statt 1,03: 600 · 1,3² − 600 = 414.","socratic_question":"Welcher Faktor gehört zu einer Zunahme um 3 %?"}]'::jsonb,
  p_acceptance      => '{"canonical":"36,54","known_errors":{"36":"prozente_addiert","414":"wachstumsfaktor_falsch","36 €":"prozente_addiert","36€":"prozente_addiert","636,54":"falsche_groesse_beantwortet","636.54":"falsche_groesse_beantwortet","636,54 €":"falsche_groesse_beantwortet","636,54€":"falsche_groesse_beantwortet","414 €":"wachstumsfaktor_falsch","414€":"wachstumsfaktor_falsch"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'ab2df4fc-6d03-45a3-a974-7191461d00fc'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'ab2df4fc-6d03-45a3-a974-7191461d00fc'::uuid);

-- #22 zins-zinseszins-04 · Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3b7c2619-ae14-4c9c-b67b-89589310033f'::uuid, 'exercise', 'Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €', 'Ein Guthaben von 500 € wird jedes Jahr mit 10 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.

Nach wie vielen Jahren ist das Guthaben zum ersten Mal größer als 700 €?',
  '{"kind":"short_input","prompt":"Ein Guthaben von 500 € wird jedes Jahr mit 10 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nNach wie vielen Jahren ist das Guthaben zum ersten Mal größer als 700 €?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, 'Jahre', false, null, 'draft', 'edvance_k8_zins', 'zins-zinseszins-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen (Ari-8): die Hochzahl ist gesucht und wird durch systematisches Probieren Jahr für Jahr gefunden.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '3b7c2619-ae14-4c9c-b67b-89589310033f'::uuid,
  p_correct_answers => '["4","4 Jahre","4Jahre"]'::jsonb,
  p_solution        => 'Jahr für Jahr mit dem Faktor 1,1 probieren:
| Jahre | Guthaben |
| 1 | 500 € · 1,1 = 550 € |
| 2 | 550 € · 1,1 = 605 € |
| 3 | 605 € · 1,1 = 665,50 € (noch nicht über 700 €) |
| 4 | 665,50 € · 1,1 = 732,05 € (zum ersten Mal über 700 €) |
Nach 4 Jahren.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Jedes Jahr nur 50 € (10 % vom Start) gerechnet: nach 4 Jahren genau 700, erst nach 5 Jahren mehr.","socratic_question":"Bleiben die Zinsen jedes Jahr gleich, wenn sie mitverzinst werden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"4","known_errors":{"5":"prozente_addiert","5 Jahre":"prozente_addiert","5Jahre":"prozente_addiert"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '3b7c2619-ae14-4c9c-b67b-89589310033f'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3b7c2619-ae14-4c9c-b67b-89589310033f'::uuid);

-- #23 zins-zinseszins-05 · Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f07265aa-116a-4d92-9312-6cae6d7cba2d'::uuid, 'exercise', 'Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €', 'Ein Fahrrad kostet 400 €. Der Preis wird zuerst um 20 % erhöht. Später wird der neue Preis um 20 % gesenkt.

Wie viel Euro kostet das Fahrrad danach?',
  '{"kind":"short_input","prompt":"Ein Fahrrad kostet 400 €. Der Preis wird zuerst um 20 % erhöht. Später wird der neue Preis um 20 % gesenkt.\n\nWie viel Euro kostet das Fahrrad danach?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'funktionen', 'Modellieren, Operieren',
  90, '€', false, 2, 'draft', 'edvance_k8_zins', 'zins-zinseszins-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden (Fkt-9): zwei Veränderungen nacheinander, die zweite bezieht sich auf den neuen Preis.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, grundwert_verwechselt, bedingung_unvollstaendig).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'f07265aa-116a-4d92-9312-6cae6d7cba2d'::uuid,
  p_correct_answers => '["384","384 €","384€"]'::jsonb,
  p_solution        => 'Erhöhung: 400 € · 1,2 = 480 €.
Senkung vom neuen Preis: 480 € · 0,8 = 384 €.
(Oder: 400 € · 1,2 · 0,8 = 400 € · 0,96 = 384 €.)
Der Preis ist also nicht wieder 400 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Plus 20 % und minus 20 % gegeneinander aufgehoben: wieder 400 €.","socratic_question":"Von welchem Preis werden die 20 % beim Senken berechnet?"},{"error":"Die Senkung auf den alten Preis bezogen: 400 · 0,8 = 320.","socratic_question":"Welcher Preis gilt, wenn gesenkt wird – der alte oder der erhöhte?"},{"error":"Nur die Erhöhung gerechnet: 480 €.","socratic_question":"Welche Preisänderung aus dem Text fehlt noch?"}]'::jsonb,
  p_acceptance      => '{"canonical":"384","known_errors":{"320":"grundwert_verwechselt","400":"prozente_addiert","480":"bedingung_unvollstaendig","400 €":"prozente_addiert","400€":"prozente_addiert","320 €":"grundwert_verwechselt","320€":"grundwert_verwechselt","480 €":"bedingung_unvollstaendig","480€":"bedingung_unvollstaendig"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'f07265aa-116a-4d92-9312-6cae6d7cba2d'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f07265aa-116a-4d92-9312-6cae6d7cba2d'::uuid);

-- #24 zins-zinseszins-06 · Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '9031703f-4b09-41be-a1a3-6a0b55bc0603'::uuid, 'exercise', 'Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €', 'Ein Guthaben wächst in 2 Jahren von 500 € auf 551,25 €. Der Zinssatz ist in beiden Jahren gleich, die Zinsen bleiben auf dem Konto.

Wie hoch ist der Zinssatz in Prozent?',
  '{"kind":"short_input","prompt":"Ein Guthaben wächst in 2 Jahren von 500 € auf 551,25 €. Der Zinssatz ist in beiden Jahren gleich, die Zinsen bleiben auf dem Konto.\n\nWie hoch ist der Zinssatz in Prozent?"}'::jsonb, 'NUMERIC', 'prozent_zins_zinseszins',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'III', 'funktionen', 'Problemlösen, Operieren',
  90, '%', false, null, 'draft', 'edvance_k8_zins', 'zins-zinseszins-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: Rückrichtung über den Wachstumsfaktor – 1,1025 muss als 1,05² erkannt werden (Probieren mit Faktoren).","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (prozente_addiert, falsche_groesse_beantwortet, wachstumsfaktor_falsch).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '9031703f-4b09-41be-a1a3-6a0b55bc0603'::uuid,
  p_correct_answers => '["5","5 %","5%"]'::jsonb,
  p_solution        => 'Gesamtfaktor: 551,25 € : 500 € = 1,1025.
Gesucht ist q mit q · q = 1,1025.
Probieren: 1,04² = 1,0816 (zu klein), 1,05² = 1,1025 (passt).
q = 1,05, also 5 %.
Probe: 500 € · 1,05 = 525 €, 525 € · 1,05 = 551,25 €.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Gesamtzunahme halbiert: 10,25 % : 2 = 5,125 %.","socratic_question":"Bekommen die Zinsen des ersten Jahres im zweiten Jahr wieder Zinsen?"},{"error":"Die Zunahme über beide Jahre zusammen angegeben (10,25 %), nicht den Zinssatz pro Jahr.","socratic_question":"Gilt der gesuchte Zinssatz für beide Jahre zusammen oder für jedes Jahr?"},{"error":"Den Faktor 1,05 als Zinssatz angegeben.","socratic_question":"Wie viel Prozent Zunahme stecken im Faktor 1,05?"}]'::jsonb,
  p_acceptance      => '{"canonical":"5","known_errors":{"5,125":"prozente_addiert","5.125":"prozente_addiert","5,125 %":"prozente_addiert","5,125%":"prozente_addiert","10,25":"falsche_groesse_beantwortet","10.25":"falsche_groesse_beantwortet","10,25 %":"falsche_groesse_beantwortet","10,25%":"falsche_groesse_beantwortet","1,05":"wachstumsfaktor_falsch","1.05":"wachstumsfaktor_falsch","1,05 %":"wachstumsfaktor_falsch","1,05%":"wachstumsfaktor_falsch"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '9031703f-4b09-41be-a1a3-6a0b55bc0603'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '9031703f-4b09-41be-a1a3-6a0b55bc0603'::uuid);

-- #25 zins-potenzen-01 · Potenzen · 4³
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'fd7c0327-2903-4199-a275-be6c4b46cd1e'::uuid, 'exercise', 'Potenzen · 4³', 'Berechne.

4³ = ?',
  '{"kind":"short_input","prompt":"Berechne.\n\n4³ = ?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Potenz mit natürlicher Basis und Hochzahl 3.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, basis_exponent_vertauscht).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'fd7c0327-2903-4199-a275-be6c4b46cd1e'::uuid,
  p_correct_answers => '["64"]'::jsonb,
  p_solution        => '4³ = 4 · 4 · 4 = 16 · 4 = 64.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 4 · 3 = 12.","socratic_question":"Was bedeutet die kleine 3 – wie oft wird 4 mit sich selbst multipliziert?"},{"error":"Basis und Hochzahl vertauscht: 3⁴ = 81.","socratic_question":"Welche Zahl wird multipliziert, und wie oft?"}]'::jsonb,
  p_acceptance      => '{"canonical":"64","known_errors":{"12":"mal_exponent","81":"basis_exponent_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'fd7c0327-2903-4199-a275-be6c4b46cd1e'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'fd7c0327-2903-4199-a275-be6c4b46cd1e'::uuid);

-- #26 zins-potenzen-02 · Potenzen · 0,4²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e04a700d-23f0-4709-bf16-a4e65bca3cd2'::uuid, 'exercise', 'Potenzen · 0,4²', 'Berechne.

0,4² = ?',
  '{"kind":"short_input","prompt":"Berechne.\n\n0,4² = ?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'I', 'arithmetik_algebra', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Quadrat einer Dezimalzahl mit einer Nachkommastelle.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, kommastellen_zu_wenig).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'e04a700d-23f0-4709-bf16-a4e65bca3cd2'::uuid,
  p_correct_answers => '["0,16","0.16"]'::jsonb,
  p_solution        => '0,4² = 0,4 · 0,4 = 0,16.
(4 · 4 = 16, und das Ergebnis hat zwei Nachkommastellen.)',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 0,4 · 2 = 0,8.","socratic_question":"Was bedeutet die kleine 2 – womit wird 0,4 multipliziert?"},{"error":"Komma falsch gesetzt: 1,6 statt 0,16.","socratic_question":"Wie viele Nachkommastellen haben die beiden Faktoren zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,16","known_errors":{"0,8":"mal_exponent","0.8":"mal_exponent","1,6":"kommastellen_zu_wenig","1.6":"kommastellen_zu_wenig"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'e04a700d-23f0-4709-bf16-a4e65bca3cd2'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e04a700d-23f0-4709-bf16-a4e65bca3cd2'::uuid);

-- #27 zins-potenzen-03 · Potenzen · 2,5²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2fe1feb6-8551-4eb1-be91-f5092d383242'::uuid, 'exercise', 'Potenzen · 2,5²', 'Berechne.

2,5² = ?',
  '{"kind":"short_input","prompt":"Berechne.\n\n2,5² = ?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat einer Dezimalzahl, das Ergebnis hat zwei Nachkommastellen und ist nicht auswendig bekannt.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, quadrat_gliedweise).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '2fe1feb6-8551-4eb1-be91-f5092d383242'::uuid,
  p_correct_answers => '["6,25","6.25"]'::jsonb,
  p_solution        => '2,5² = 2,5 · 2,5 = 6,25.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 2,5 · 2 = 5.","socratic_question":"Was bedeutet die kleine 2 – womit wird 2,5 multipliziert?"},{"error":"Ganzen Teil und Nachkommateil einzeln quadriert: 2² + 0,5² = 4,25.","socratic_question":"Wenn du 2,5 · 2,5 ausführlich rechnest: Welche Teilprodukte entstehen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"6,25","known_errors":{"5":"mal_exponent","4,25":"quadrat_gliedweise","4.25":"quadrat_gliedweise"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '2fe1feb6-8551-4eb1-be91-f5092d383242'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2fe1feb6-8551-4eb1-be91-f5092d383242'::uuid);

-- #28 zins-potenzen-04 · Potenzen · 1,05²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'c5ff0008-b3f0-4ebf-aa68-31cff48d7342'::uuid, 'exercise', 'Potenzen · 1,05²', 'Berechne.

1,05² = ?',
  '{"kind":"short_input","prompt":"Berechne.\n\n1,05² = ?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Quadrat einer Dezimalzahl mit zwei Nachkommastellen (Wachstumsfaktor).","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, quadrat_gliedweise).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'c5ff0008-b3f0-4ebf-aa68-31cff48d7342'::uuid,
  p_correct_answers => '["1,1025","1.1025"]'::jsonb,
  p_solution        => '1,05² = 1,05 · 1,05 = 1,1025.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 1,05 · 2 = 2,1.","socratic_question":"Was bedeutet die kleine 2 – womit wird 1,05 multipliziert?"},{"error":"Gliedweise quadriert: 1² + 0,05² = 1,0025 – das mittlere Glied fehlt.","socratic_question":"Rechne 1,05 · 1,05 ausführlich: Wie viele Teilprodukte entstehen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,1025","known_errors":{"2,1":"mal_exponent","2.1":"mal_exponent","1,0025":"quadrat_gliedweise","1.0025":"quadrat_gliedweise"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'c5ff0008-b3f0-4ebf-aa68-31cff48d7342'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'c5ff0008-b3f0-4ebf-aa68-31cff48d7342'::uuid);

-- #29 zins-potenzen-05 · Potenzen · 1,05³
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'bb125765-c709-4f59-afff-4b4bd090dbbf'::uuid, 'exercise', 'Potenzen · 1,05³', 'Berechne.

1,05³ = ?',
  '{"kind":"short_input","prompt":"Berechne.\n\n1,05³ = ?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: dritte Potenz einer Dezimalzahl, zwei Multiplikationen nacheinander.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, basis_exponent_vertauscht).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => 'bb125765-c709-4f59-afff-4b4bd090dbbf'::uuid,
  p_correct_answers => '["1,157625","1.157625"]'::jsonb,
  p_solution        => '1,05² = 1,05 · 1,05 = 1,1025.
1,05³ = 1,1025 · 1,05 = 1,157625.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 1,05 · 3 = 3,15.","socratic_question":"Was bedeutet die kleine 3 – wie oft steht 1,05 als Faktor da?"},{"error":"Nur zweimal statt dreimal mit 1,05 multipliziert: 1,05² = 1,1025.","socratic_question":"Wie viele Faktoren 1,05 gehören zu 1,05³?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,157625","known_errors":{"3,15":"mal_exponent","3.15":"mal_exponent","1,1025":"basis_exponent_vertauscht","1.1025":"basis_exponent_vertauscht"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = 'bb125765-c709-4f59-afff-4b4bd090dbbf'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'bb125765-c709-4f59-afff-4b4bd090dbbf'::uuid);

-- #30 zins-potenzen-06 · Potenzen · Würfelvolumen · Kante 0,4 m
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '451bd34e-273d-40ac-a16d-3f13d271c5fa'::uuid, 'exercise', 'Potenzen · Würfelvolumen · Kante 0,4 m', 'Ein würfelförmiger Karton hat die Kantenlänge 0,4 m. Für das Volumen gilt V = a³.

Wie viele Kubikmeter beträgt das Volumen?',
  '{"kind":"short_input","prompt":"Ein würfelförmiger Karton hat die Kantenlänge 0,4 m. Für das Volumen gilt V = a³.\n\nWie viele Kubikmeter beträgt das Volumen?"}'::jsonb, 'NUMERIC', 'potenzen',
  null, 7,
  (select c.id from public.skill_clusters c where c.id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid),
  'II', 'arithmetik_algebra', 'Modellieren, Operieren',
  90, 'm³', false, null, 'draft', 'edvance_k8_zins', 'zins-potenzen-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Formel gegeben, dritte Potenz einer Dezimalzahl mit Kommaverschiebung.","charge":"k8-zins"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k8-zins"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"cluster_id":{"art":"neu","grund":"Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.","charge":"k8-zins"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k8-zins"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k8-zins"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.","charge":"k8-zins"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k8-zins"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (mal_exponent, kommastellen_zu_wenig).","charge":"k8-zins"},"hints":{"art":"leer","grund":"Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k8-zins"}}'::jsonb, now())
on conflict do nothing;
select public.task_solution_upsert(
  p_task_id         => '451bd34e-273d-40ac-a16d-3f13d271c5fa'::uuid,
  p_correct_answers => '["0,064","0.064","0,064 m³","0,064m³"]'::jsonb,
  p_solution        => 'V = a³ = 0,4³ = 0,4 · 0,4 · 0,4 = 0,16 · 0,4 = 0,064.
Das Volumen beträgt 0,064 m³.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Basis mal Hochzahl: 0,4 · 3 = 1,2.","socratic_question":"Was bedeutet a³ – wie oft wird a mit sich selbst multipliziert?"},{"error":"Komma falsch gesetzt: 0,64 statt 0,064.","socratic_question":"Wie viele Nachkommastellen haben drei Faktoren 0,4 zusammen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,064","known_errors":{"1,2":"mal_exponent","1.2":"mal_exponent","1,2 m³":"mal_exponent","1,2m³":"mal_exponent","0,64":"kommastellen_zu_wenig","0.64":"kommastellen_zu_wenig","0,64 m³":"kommastellen_zu_wenig","0,64m³":"kommastellen_zu_wenig"}}'::jsonb)
 where exists (select 1 from public.tasks t where t.id = '451bd34e-273d-40ac-a16d-3f13d271c5fa'::uuid and t.status = 'draft' and t.source = 'edvance_k8_zins')
   and not exists (select 1 from public.task_solutions s where s.task_id = '451bd34e-273d-40ac-a16d-3f13d271c5fa'::uuid);

commit;
