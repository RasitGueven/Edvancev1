-- K9-Rest, Thema bedingt — 30 Aufgaben: je sechs zu stoch_bedingt_vierfeld, _wkeit, _unabhaengig, _umkehr und _irrefuehrend.
-- Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-bedingt.json (Quelle: tools/k9-bedingt-charge.mjs) — nicht von Hand editieren.
--
-- Einspiel-Reihenfolge: nach 20261003105859_substrat_k9_bedingt.sql (Knoten + Fehlbild-Slugs muessen stehen).
--
-- Je Knoten vier reine Anwendung mit steigender Schwierigkeit (AFB I, I, II, II), eine mit Sachkontext (AFB II) und eine Sachkontext- oder Rückrichtungsaufgabe (AFB III): Haustier-Befragung, Bus und Stufe, Gärtnerei, Werkstücke, Verkehrszählung, Chor, Bibliothek, Kino, Mensa, Lastenrad, Schnelltests auf Pflanzenkrankheiten, Prüfgerät, Schweißnähte, Säulendiagramme, Schlagzeile, Diebstahlraten. Der Tablet-Player zeigt reinen Text: Vierfeldertafeln stehen als Liste benannter Felder (eine Zeile je Feld bzw. Summe), gesuchte Felder sind MULTI_PART-Teile mit genau diesem Namen. Jede Aufgabe nennt Form und Rundung der Antwort. Alle Daten frei erfunden.
--
-- Status: 'draft' mit Kennzeichen tasks.vorbefuellt je Lena-Feld (art 'neu' bzw. 'leer'),
-- wie der uebrige vorbefuellte Bestand vor Lenas Pruefung. Werte + Gruende:
-- docs/prefill/k9-bedingt.csv. Pruefprotokoll: docs/prefill/k9-bedingt-verifikation.md.
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
--   stoch_bedingt_vierfeld: bedingt-vierfeld-04 = 1, bedingt-vierfeld-03 = 2. Rang 1 aus Profil {dezimalverschiebung,falsche_groesse_beantwortet,falsche_operation,grundwert_verwechselt,randsumme_verwechselt}, Rang 2 aus Profil {bezug_vertauscht,dezimalverschiebung,falsche_operation,randsumme_verwechselt} (1 neue Fehlbilder)
--   stoch_bedingt_wkeit: bedingt-wkeit-06 = 1, bedingt-wkeit-03 = 2. Rang 1 aus Profil {bedingung_vertauscht,falsche_groesse_beantwortet,gesamtheit_statt_bedingung}, Rang 2 aus Profil {bedingung_vertauscht,bezug_vertauscht,gesamtheit_statt_bedingung} (1 neue Fehlbilder)
--   stoch_bedingt_unabhaengig: bedingt-unabhaengig-06 = 1, bedingt-unabhaengig-01 = 2. Rang 1 aus Profil {absolut_statt_relativ,gesamtheit_statt_bedingung,grundwert_verwechselt}, Rang 2 aus Profil {falsche_groesse_beantwortet,falsche_operation} (2 neue Fehlbilder)
--   stoch_bedingt_umkehr: bedingt-umkehr-05 = 1, bedingt-umkehr-02 = 2. Rang 1 aus Profil {bedingung_vertauscht,bezug_vertauscht,falsche_groesse_beantwortet,gesamtheit_statt_bedingung,grundwert_verwechselt}, Rang 2 aus Profil {dezimalverschiebung,falsche_groesse_beantwortet,grundwert_verwechselt} (1 neue Fehlbilder)
--   stoch_bedingt_irrefuehrend: bedingt-irrefuehrend-02 = 1, bedingt-irrefuehrend-04 = 2. Rang 1 aus Profil {achse_abgeschnitten_uebersehen,bezug_vertauscht,falsche_operation}, Rang 2 aus Profil {bedingung_vertauscht,falsche_groesse_beantwortet,gesamtheit_statt_bedingung} (3 neue Fehlbilder)
--
-- Idempotent: on conflict do nothing; die Loesung nur, wenn noch keine Zeile besteht.
-- Kein begin/commit in der Datei: mig spielt sie mit psql -1 in EINER Transaktion ein,
-- CI (schema.yml) und die Wegwerf-DB ohne Klammer. Die Systemrolle setzt deshalb jeder
-- do-Block selbst (set_config(..., true) gilt bis zum Ende der umgebenden Transaktion).

-- #1 bedingt-vierfeld-01 · Vierfeldertafel · Haustier, zwei Felder
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '28ee89d3-0cdc-4842-869e-423c2bf78f8d'::uuid, 'exercise', 'Vierfeldertafel · Haustier, zwei Felder', 'In einer Befragung wurden 200 Jugendliche gefragt, ob sie ein Haustier haben.
Mädchen mit Haustier: 48
Mädchen ohne Haustier: ?
Jungen mit Haustier: ?
Jungen ohne Haustier: 30
Mädchen insgesamt: 110
Mit Haustier insgesamt: 108
Alle Befragten: 200

Ergänze die beiden fehlenden Felder. Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Mädchen ohne Haustier","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Jungen mit Haustier","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: je ein fehlendes Feld als Randsumme minus bekanntes Feld.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (randsumme_verwechselt, falsche_operation).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '28ee89d3-0cdc-4842-869e-423c2bf78f8d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '28ee89d3-0cdc-4842-869e-423c2bf78f8d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '28ee89d3-0cdc-4842-869e-423c2bf78f8d'::uuid,
  p_correct_answers => '{"1":["62","+62"],"2":["60","+60"]}'::jsonb,
  p_solution        => 'Mädchen ohne Haustier = Mädchen insgesamt − Mädchen mit Haustier = 110 − 48 = 62.
Jungen mit Haustier = Mit Haustier insgesamt − Mädchen mit Haustier = 108 − 48 = 60.
Probe: Jungen insgesamt = 200 − 110 = 90 = 60 + 30.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von der falschen Summe abgezogen: „Mit Haustier insgesamt“ statt „Mädchen insgesamt“: 108 − 48.","socratic_question":"Zu welcher Summe gehören die Mädchen ohne Haustier – zu allen Mädchen oder zu allen mit Haustier?"},{"error":"Addiert statt subtrahiert: 110 + 48.","socratic_question":"Können die Mädchen ohne Haustier mehr sein als alle Mädchen zusammen?"},{"error":"Von der falschen Summe abgezogen: „Mädchen insgesamt“ statt „Mit Haustier insgesamt“: 110 − 48.","socratic_question":"Welche Summe besteht aus Mädchen mit Haustier und Jungen mit Haustier?"},{"error":"Addiert statt subtrahiert: 108 + 48.","socratic_question":"Können die Jungen mit Haustier mehr sein als alle mit Haustier?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"62","equivalents":["+62"],"known_errors":{"60":"randsumme_verwechselt","158":"falsche_operation","+60":"randsumme_verwechselt","+158":"falsche_operation"}},"2":{"canonical":"60","equivalents":["+60"],"known_errors":{"62":"randsumme_verwechselt","156":"falsche_operation","+62":"randsumme_verwechselt","+156":"falsche_operation"}}}'::jsonb);
  end if;
end
$loesung$;

-- #2 bedingt-vierfeld-02 · Vierfeldertafel · Bus und Stufe, drei Felder
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cd7d81d2-819a-4887-ab77-6fa061b89358'::uuid, 'exercise', 'Vierfeldertafel · Bus und Stufe, drei Felder', 'Eine Schule hat 300 Schülerinnen und Schüler gefragt, ob sie mit dem Bus zur Schule kommen.
Unterstufe mit Bus: 72
Unterstufe ohne Bus: ?
Oberstufe mit Bus: ?
Oberstufe ohne Bus: ?
Unterstufe insgesamt: 160
Mit Bus insgesamt: 126
Alle Befragten: 300

Ergänze die drei fehlenden Felder. Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Unterstufe ohne Bus","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Oberstufe mit Bus","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Oberstufe ohne Bus","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: drei fehlende Felder nacheinander über Randsummen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.3":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (randsumme_verwechselt, falsche_operation, falsche_groesse_beantwortet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cd7d81d2-819a-4887-ab77-6fa061b89358'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cd7d81d2-819a-4887-ab77-6fa061b89358'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cd7d81d2-819a-4887-ab77-6fa061b89358'::uuid,
  p_correct_answers => '{"1":["88","+88"],"2":["54","+54"],"3":["86","+86"]}'::jsonb,
  p_solution        => 'Unterstufe ohne Bus = 160 − 72 = 88.
Oberstufe mit Bus = 126 − 72 = 54.
Oberstufe insgesamt = 300 − 160 = 140, also Oberstufe ohne Bus = 140 − 54 = 86.
Probe: Ohne Bus insgesamt = 88 + 86 = 174 = 300 − 126.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von „Mit Bus insgesamt“ statt von „Unterstufe insgesamt“ abgezogen: 126 − 72.","socratic_question":"Welche Summe besteht aus Unterstufe mit Bus und Unterstufe ohne Bus?"},{"error":"Addiert statt subtrahiert: 160 + 72.","socratic_question":"Kann ein Teil der Unterstufe größer sein als die ganze Unterstufe?"},{"error":"Von „Unterstufe insgesamt“ statt von „Mit Bus insgesamt“ abgezogen: 160 − 72.","socratic_question":"Welche Summe besteht aus Unterstufe mit Bus und Oberstufe mit Bus?"},{"error":"Addiert statt subtrahiert: 126 + 72.","socratic_question":"Kann ein Teil der Busfahrer größer sein als alle Busfahrer?"},{"error":"Die ganze Oberstufe angegeben statt nur die Oberstufe ohne Bus.","socratic_question":"Sind in deiner Zahl auch die Oberstufenschüler mit Bus enthalten?"},{"error":"Von „Mit Bus insgesamt“ abgezogen statt von „Oberstufe insgesamt“: 126 − 54.","socratic_question":"Zu welcher Summe gehört das Feld „Oberstufe ohne Bus“ – zu den Busfahrern?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"88","equivalents":["+88"],"known_errors":{"54":"randsumme_verwechselt","232":"falsche_operation","+54":"randsumme_verwechselt","+232":"falsche_operation"}},"2":{"canonical":"54","equivalents":["+54"],"known_errors":{"88":"randsumme_verwechselt","198":"falsche_operation","+88":"randsumme_verwechselt","+198":"falsche_operation"}},"3":{"canonical":"86","equivalents":["+86"],"known_errors":{"72":"randsumme_verwechselt","140":"falsche_groesse_beantwortet","+140":"falsche_groesse_beantwortet","+72":"randsumme_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #3 bedingt-vierfeld-03 · Vierfeldertafel · Feld und relative Häufigkeit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'e61dfd20-5b7c-4f12-94f9-f38a51ab64c5'::uuid, 'exercise', 'Vierfeldertafel · Feld und relative Häufigkeit', 'Eine Gärtnerei hat 250 Pflanzen beobachtet. Ein Teil wurde gedüngt.
Gedüngt, blüht: 86
Gedüngt, blüht nicht: ?
Nicht gedüngt, blüht: ?
Nicht gedüngt, blüht nicht: ?
Gedüngt insgesamt: 120
Blüht insgesamt: 140
Alle Pflanzen: 250

Gib die Anzahl im Feld „Nicht gedüngt, blüht“ an und dann die relative Häufigkeit dieses Feldes bezogen auf alle 250 Pflanzen als Dezimalzahl, gerundet auf zwei Stellen nach dem Komma.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Nicht gedüngt, blüht (Anzahl)","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Relative Häufigkeit von „Nicht gedüngt, blüht“ (Dezimalzahl, zwei Stellen)","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: fehlendes Feld ergänzen und als relative Häufigkeit (Anteil an allen) mit Rundung angeben.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (randsumme_verwechselt, falsche_operation, bezug_vertauscht, dezimalverschiebung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'e61dfd20-5b7c-4f12-94f9-f38a51ab64c5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'e61dfd20-5b7c-4f12-94f9-f38a51ab64c5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'e61dfd20-5b7c-4f12-94f9-f38a51ab64c5'::uuid,
  p_correct_answers => '{"1":["54","+54"],"2":["0,22","+0,22","0.22","+0.22"]}'::jsonb,
  p_solution        => 'Nicht gedüngt, blüht = Blüht insgesamt − Gedüngt, blüht = 140 − 86 = 54.
Relative Häufigkeit = 54 : 250 = 0,216 ≈ 0,22.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von „Gedüngt insgesamt“ statt von „Blüht insgesamt“ abgezogen: 120 − 86.","socratic_question":"Welche Summe besteht aus „Gedüngt, blüht“ und „Nicht gedüngt, blüht“?"},{"error":"Addiert statt subtrahiert: 140 + 86.","socratic_question":"Kann ein Teil der blühenden Pflanzen mehr sein als alle blühenden?"},{"error":"Mit dem falsch ergänzten Feld 120 − 86 = 34 weitergerechnet: 34 : 250.","socratic_question":"Stimmt die Anzahl, die du durch 250 geteilt hast?"},{"error":"Den Kehrwert gebildet: 250 : 54.","socratic_question":"Kann ein Anteil an allen Pflanzen größer als 1 sein?"},{"error":"Als Prozentzahl statt als Dezimalzahl angegeben: 21,6.","socratic_question":"Ist nach Prozent oder nach einer Dezimalzahl zwischen 0 und 1 gefragt?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"54","equivalents":["+54"],"known_errors":{"34":"randsumme_verwechselt","226":"falsche_operation","+34":"randsumme_verwechselt","+226":"falsche_operation"}},"2":{"canonical":"0,22","equivalents":["+0,22","0.22","+0.22"],"known_errors":{"0,14":"randsumme_verwechselt","+0,14":"randsumme_verwechselt","0.14":"randsumme_verwechselt","+0.14":"randsumme_verwechselt","4,63":"bezug_vertauscht","+4,63":"bezug_vertauscht","4.63":"bezug_vertauscht","+4.63":"bezug_vertauscht","21,6":"dezimalverschiebung","+21,6":"dezimalverschiebung","21.6":"dezimalverschiebung","+21.6":"dezimalverschiebung"}}}'::jsonb);
  end if;
end
$loesung$;

-- #4 bedingt-vierfeld-04 · Vierfeldertafel · aus Prozentangaben, Werkstücke
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '52f02da3-efb0-4667-8387-506d491e74c5'::uuid, 'exercise', 'Vierfeldertafel · aus Prozentangaben, Werkstücke', 'Eine Fabrik prüft 400 Werkstücke. 60 % davon stammen von Maschine A, der Rest von Maschine B. Von den Werkstücken aus Maschine A sind 5 % fehlerhaft. Insgesamt sind 26 Werkstücke fehlerhaft.

Bestimme die drei Felder der Vierfeldertafel. Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 1, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-04',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Fehlerhafte Werkstücke von Maschine A","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Fehlerhafte Werkstücke von Maschine B","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Fehlerfreie Werkstücke von Maschine B","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Felder erst aus Prozentangaben bestimmen, dann über Randsummen ergänzen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.3":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grundwert_verwechselt, dezimalverschiebung, falsche_operation, randsumme_verwechselt, falsche_groesse_beantwortet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '52f02da3-efb0-4667-8387-506d491e74c5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '52f02da3-efb0-4667-8387-506d491e74c5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '52f02da3-efb0-4667-8387-506d491e74c5'::uuid,
  p_correct_answers => '{"1":["12","+12"],"2":["14","+14"],"3":["146","+146"]}'::jsonb,
  p_solution        => 'Maschine A: 60 % von 400 = 240 Werkstücke, davon 5 % fehlerhaft: 240 · 0,05 = 12.
Fehlerhaft von Maschine B = 26 − 12 = 14.
Maschine B: 400 − 240 = 160 Werkstücke, davon fehlerfrei 160 − 14 = 146.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"5 % von allen 400 Werkstücken genommen statt von den 240 aus Maschine A.","socratic_question":"Worauf beziehen sich die 5 % – auf alle Werkstücke oder nur auf die von Maschine A?"},{"error":"5 % als 0,5 gerechnet statt als 0,05: 240 · 0,5.","socratic_question":"Wie schreibt man 5 % als Dezimalzahl?"},{"error":"Addiert statt subtrahiert: 26 + 12.","socratic_question":"Können die fehlerhaften von Maschine B mehr sein als alle fehlerhaften?"},{"error":"Mit den falschen 20 fehlerhaften von A weitergerechnet: 26 − 20.","socratic_question":"Wie viele Werkstücke kommen von Maschine A, und wie viele davon sind fehlerhaft?"},{"error":"Von „Fehlerfrei insgesamt“ (374) statt von „Maschine B insgesamt“ (160) abgezogen: 374 − 14.","socratic_question":"Welche Summe besteht aus fehlerhaften und fehlerfreien Werkstücken von Maschine B?"},{"error":"Alle Werkstücke von Maschine B angegeben, auch die fehlerhaften.","socratic_question":"Sind in deiner Zahl auch fehlerhafte Werkstücke enthalten?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"12","equivalents":["+12"],"known_errors":{"20":"grundwert_verwechselt","120":"dezimalverschiebung","+20":"grundwert_verwechselt","+120":"dezimalverschiebung"}},"2":{"canonical":"14","equivalents":["+14"],"known_errors":{"6":"grundwert_verwechselt","38":"falsche_operation","+38":"falsche_operation","+6":"grundwert_verwechselt"}},"3":{"canonical":"146","equivalents":["+146"],"known_errors":{"160":"falsche_groesse_beantwortet","360":"randsumme_verwechselt","+360":"randsumme_verwechselt","+160":"falsche_groesse_beantwortet"}}}'::jsonb);
  end if;
end
$loesung$;

-- #5 bedingt-vierfeld-05 · Vierfeldertafel · relative Häufigkeiten, Verkehrszählung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2f7128fa-73b2-4686-97b3-7a23bd286196'::uuid, 'exercise', 'Vierfeldertafel · relative Häufigkeiten, Verkehrszählung', 'Bei einer Verkehrszählung an einer Kreuzung wurde festgehalten, ob ein Fahrzeug ein Auto ist und ob es abbiegt. Die Anteile beziehen sich auf alle gezählten Fahrzeuge.
Autos, die abbiegen: 0,18
Autos, die geradeaus fahren: ?
Andere Fahrzeuge, die abbiegen: ?
Andere Fahrzeuge, die geradeaus fahren: ?
Autos insgesamt: 0,65
Abbiegende Fahrzeuge insgesamt: 0,30
Alle Fahrzeuge: 1

Gezählt wurden 400 Fahrzeuge. Ergänze die drei fehlenden Anteile exakt als Dezimalzahl und gib an, wie viele andere Fahrzeuge abgebogen sind.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Anteil: Autos, die geradeaus fahren","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Anteil: Andere Fahrzeuge, die abbiegen","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":3,"kind":"short_input","prompt":"Anteil: Andere Fahrzeuge, die geradeaus fahren","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":4,"kind":"short_input","prompt":"Anzahl anderer Fahrzeuge, die abgebogen sind","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Tafel mit relativen Häufigkeiten ergänzen und auf die Zahl der Fahrzeuge zurückrechnen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.3.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.3.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.3":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.4.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.4.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.4":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (randsumme_verwechselt, falsche_operation, falsche_groesse_beantwortet, dezimalverschiebung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2f7128fa-73b2-4686-97b3-7a23bd286196'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2f7128fa-73b2-4686-97b3-7a23bd286196'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2f7128fa-73b2-4686-97b3-7a23bd286196'::uuid,
  p_correct_answers => '{"1":["0,47","+0,47","0.47","+0.47"],"2":["0,12","+0,12","0.12","+0.12"],"3":["0,23","+0,23","0.23","+0.23"],"4":["48","+48"]}'::jsonb,
  p_solution        => 'Autos geradeaus = 0,65 − 0,18 = 0,47.
Andere abbiegend = 0,30 − 0,18 = 0,12.
Andere insgesamt = 1 − 0,65 = 0,35, also andere geradeaus = 0,35 − 0,12 = 0,23.
Anzahl andere abbiegend = 400 · 0,12 = 48.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von „Abbiegende insgesamt“ statt von „Autos insgesamt“ abgezogen: 0,30 − 0,18.","socratic_question":"Welche Summe besteht aus abbiegenden und geradeaus fahrenden Autos?"},{"error":"Addiert statt subtrahiert: 0,65 + 0,18.","socratic_question":"Kann ein Teil der Autos einen größeren Anteil haben als alle Autos?"},{"error":"Von „Autos insgesamt“ statt von „Abbiegende insgesamt“ abgezogen: 0,65 − 0,18.","socratic_question":"Welche Summe besteht aus abbiegenden Autos und abbiegenden anderen Fahrzeugen?"},{"error":"Addiert statt subtrahiert: 0,30 + 0,18.","socratic_question":"Kann ein Teil der Abbieger einen größeren Anteil haben als alle Abbieger?"},{"error":"Den Anteil aller anderen Fahrzeuge angegeben, auch der abbiegenden.","socratic_question":"Sind in deinem Anteil auch andere Fahrzeuge enthalten, die abbiegen?"},{"error":"Von „Geradeaus insgesamt“ (0,70) die abbiegenden anderen Fahrzeuge abgezogen: 0,70 − 0,12.","socratic_question":"Gehören die abbiegenden anderen Fahrzeuge zu den Geradeausfahrern?"},{"error":"Mit dem falschen Anteil 0,47 weitergerechnet: 400 · 0,47.","socratic_question":"Welcher Anteil gehört zu den anderen Fahrzeugen, die abbiegen?"},{"error":"Das Komma verschoben: 400 · 1,2 statt 400 · 0,12.","socratic_question":"Können mehr Fahrzeuge abgebogen sein als gezählt wurden?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"0,47","equivalents":["+0,47","0.47","+0.47"],"known_errors":{"0,12":"randsumme_verwechselt","+0,12":"randsumme_verwechselt","0.12":"randsumme_verwechselt","+0.12":"randsumme_verwechselt","0,83":"falsche_operation","+0,83":"falsche_operation","0.83":"falsche_operation","+0.83":"falsche_operation"}},"2":{"canonical":"0,12","equivalents":["+0,12","0.12","+0.12"],"known_errors":{"0,47":"randsumme_verwechselt","+0,47":"randsumme_verwechselt","0.47":"randsumme_verwechselt","+0.47":"randsumme_verwechselt","0,48":"falsche_operation","+0,48":"falsche_operation","0.48":"falsche_operation","+0.48":"falsche_operation"}},"3":{"canonical":"0,23","equivalents":["+0,23","0.23","+0.23"],"known_errors":{"0,35":"falsche_groesse_beantwortet","+0,35":"falsche_groesse_beantwortet","0.35":"falsche_groesse_beantwortet","+0.35":"falsche_groesse_beantwortet","0,58":"randsumme_verwechselt","+0,58":"randsumme_verwechselt","0.58":"randsumme_verwechselt","+0.58":"randsumme_verwechselt"}},"4":{"canonical":"48","equivalents":["+48"],"known_errors":{"188":"randsumme_verwechselt","480":"dezimalverschiebung","+188":"randsumme_verwechselt","+480":"dezimalverschiebung"}}}'::jsonb);
  end if;
end
$loesung$;

-- #6 bedingt-vierfeld-06 · Vierfeldertafel · Instrument und Chor aus Prozentangaben
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '1e23eb52-5227-413e-846c-db4109cc487b'::uuid, 'exercise', 'Vierfeldertafel · Instrument und Chor aus Prozentangaben', 'In einer Jahrgangsstufe mit 150 Schülerinnen und Schülern spielen 40 % ein Instrument. Von denen, die ein Instrument spielen, singen 25 % im Chor. Insgesamt singen 33 Schülerinnen und Schüler im Chor.

Wie viele singen im Chor, spielen aber kein Instrument? Wie viele singen nicht im Chor und spielen auch kein Instrument? Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_vierfeld',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'III', 'stochastik', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-vierfeld-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Im Chor, kein Instrument","unit":null,"afb":"III","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Nicht im Chor, kein Instrument","unit":null,"afb":"III","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Tafel selbst anlegen, Prozent vom richtigen Grundwert nehmen und über zwei Summen ergänzen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (randsumme_verwechselt, falsche_operation, falsche_groesse_beantwortet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '1e23eb52-5227-413e-846c-db4109cc487b'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '1e23eb52-5227-413e-846c-db4109cc487b'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '1e23eb52-5227-413e-846c-db4109cc487b'::uuid,
  p_correct_answers => '{"1":["18","+18"],"2":["72","+72"]}'::jsonb,
  p_solution        => 'Instrument: 40 % von 150 = 60. Davon im Chor: 25 % von 60 = 15.
Chor ohne Instrument = 33 − 15 = 18.
Kein Instrument: 150 − 60 = 90. Davon nicht im Chor: 90 − 18 = 72.
Probe: Nicht im Chor insgesamt = 150 − 33 = 117 = (60 − 15) + 72.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Von „Instrument insgesamt“ (60) statt von „Chor insgesamt“ (33) abgezogen: 60 − 15.","socratic_question":"Welche Summe besteht aus „Chor mit Instrument“ und „Chor ohne Instrument“?"},{"error":"Addiert statt subtrahiert: 33 + 15.","socratic_question":"Können mehr Chorsänger kein Instrument spielen, als es Chorsänger gibt?"},{"error":"Alle angegeben, die nicht im Chor singen, auch die mit Instrument.","socratic_question":"Sind in deiner Zahl auch Schülerinnen und Schüler mit Instrument enthalten?"},{"error":"Von „Nicht im Chor insgesamt“ (117) die Chorsänger ohne Instrument (18) abgezogen: 117 − 18.","socratic_question":"Gehören die Chorsänger ohne Instrument zu denen, die nicht im Chor singen?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"18","equivalents":["+18"],"known_errors":{"45":"randsumme_verwechselt","48":"falsche_operation","+45":"randsumme_verwechselt","+48":"falsche_operation"}},"2":{"canonical":"72","equivalents":["+72"],"known_errors":{"99":"randsumme_verwechselt","117":"falsche_groesse_beantwortet","+117":"falsche_groesse_beantwortet","+99":"randsumme_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #7 bedingt-wkeit-01 · P(Haustier | Junge) · Dezimalzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f1aa77f4-a66c-48a6-8981-1ec5e61cac94'::uuid, 'exercise', 'P(Haustier | Junge) · Dezimalzahl', 'In einer Befragung wurden 200 Jugendliche gefragt, ob sie ein Haustier haben.
Mädchen mit Haustier: 48
Mädchen ohne Haustier: 62
Jungen mit Haustier: 60
Jungen ohne Haustier: 30
Mädchen insgesamt: 110
Jungen insgesamt: 90
Mit Haustier insgesamt: 108
Ohne Haustier insgesamt: 92
Alle Befragten: 200

Eine zufällig ausgewählte befragte Person ist ein Junge. Wie groß ist die Wahrscheinlichkeit, dass er ein Haustier hat? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"In einer Befragung wurden 200 Jugendliche gefragt, ob sie ein Haustier haben.\nMädchen mit Haustier: 48\nMädchen ohne Haustier: 62\nJungen mit Haustier: 60\nJungen ohne Haustier: 30\nMädchen insgesamt: 110\nJungen insgesamt: 90\nMit Haustier insgesamt: 108\nOhne Haustier insgesamt: 92\nAlle Befragten: 200\n\nEine zufällig ausgewählte befragte Person ist ein Junge. Wie groß ist die Wahrscheinlichkeit, dass er ein Haustier hat? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Zellwert durch die passende Randsumme, Werte direkt ablesbar.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f1aa77f4-a66c-48a6-8981-1ec5e61cac94'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f1aa77f4-a66c-48a6-8981-1ec5e61cac94'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f1aa77f4-a66c-48a6-8981-1ec5e61cac94'::uuid,
  p_correct_answers => '["0,67","+0,67","0.67","+0.67"]'::jsonb,
  p_solution        => 'Bedingung: Junge. Es zählen nur die 90 Jungen.
P(Haustier | Junge) = 60 : 90 ≈ 0,67.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch alle 200 Befragten geteilt statt durch die 90 Jungen.","socratic_question":"Aus welcher Gruppe wird gezogen, wenn schon feststeht, dass es ein Junge ist?"},{"error":"Durch alle mit Haustier geteilt: Das ist die Wahrscheinlichkeit, dass eine Person mit Haustier ein Junge ist.","socratic_question":"Steht fest, dass die Person ein Junge ist, oder dass sie ein Haustier hat?"},{"error":"Den Kehrwert gebildet: 90 : 60.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,67","equivalents":["+0,67","0.67","+0.67"],"known_errors":{"0,30":"gesamtheit_statt_bedingung","+0,30":"gesamtheit_statt_bedingung","0.30":"gesamtheit_statt_bedingung","+0.30":"gesamtheit_statt_bedingung","0,3":"gesamtheit_statt_bedingung","+0,3":"gesamtheit_statt_bedingung","0.3":"gesamtheit_statt_bedingung","+0.3":"gesamtheit_statt_bedingung","0,56":"bedingung_vertauscht","+0,56":"bedingung_vertauscht","0.56":"bedingung_vertauscht","+0.56":"bedingung_vertauscht","1,50":"bezug_vertauscht","+1,50":"bezug_vertauscht","1.50":"bezug_vertauscht","+1.50":"bezug_vertauscht","1,5":"bezug_vertauscht","+1,5":"bezug_vertauscht","1.5":"bezug_vertauscht","+1.5":"bezug_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #8 bedingt-wkeit-02 · P(Lieferant B | fehlerhaft) · Prozent
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '92bb0d6f-c6be-45ce-a0f1-d68021e5e95c'::uuid, 'exercise', 'P(Lieferant B | fehlerhaft) · Prozent', 'Ein Materialprüfgerät hat 500 Bauteile von zwei Lieferanten geprüft.
Lieferant A, fehlerhaft: 18
Lieferant A, in Ordnung: 282
Lieferant B, fehlerhaft: 11
Lieferant B, in Ordnung: 189
Lieferant A insgesamt: 300
Lieferant B insgesamt: 200
Fehlerhaft insgesamt: 29
In Ordnung insgesamt: 471
Alle Bauteile: 500

Aus den fehlerhaften Bauteilen wird eines zufällig ausgewählt. Mit welcher Wahrscheinlichkeit in Prozent stammt es von Lieferant B? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Materialprüfgerät hat 500 Bauteile von zwei Lieferanten geprüft.\nLieferant A, fehlerhaft: 18\nLieferant A, in Ordnung: 282\nLieferant B, fehlerhaft: 11\nLieferant B, in Ordnung: 189\nLieferant A insgesamt: 300\nLieferant B insgesamt: 200\nFehlerhaft insgesamt: 29\nIn Ordnung insgesamt: 471\nAlle Bauteile: 500\n\nAus den fehlerhaften Bauteilen wird eines zufällig ausgewählt. Mit welcher Wahrscheinlichkeit in Prozent stammt es von Lieferant B? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Zellwert durch Spaltensumme, Ergebnis in Prozent mit Rundung.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '92bb0d6f-c6be-45ce-a0f1-d68021e5e95c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '92bb0d6f-c6be-45ce-a0f1-d68021e5e95c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '92bb0d6f-c6be-45ce-a0f1-d68021e5e95c'::uuid,
  p_correct_answers => '["37,9","+37,9","37.9","+37.9"]'::jsonb,
  p_solution        => 'Bedingung: fehlerhaft. Es zählen nur die 29 fehlerhaften Bauteile, davon 11 von Lieferant B.
P(B | fehlerhaft) = 11 : 29 ≈ 0,3793, also ≈ 37,9 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch alle 500 Bauteile geteilt statt durch die 29 fehlerhaften.","socratic_question":"Aus welchen Bauteilen wird gezogen?"},{"error":"Durch alle Bauteile von Lieferant B geteilt: Das ist der Anteil fehlerhafter Teile bei Lieferant B.","socratic_question":"Steht fest, dass das Teil fehlerhaft ist, oder dass es von Lieferant B kommt?"},{"error":"Den Kehrwert gebildet: 29 : 11.","socratic_question":"Kann eine Wahrscheinlichkeit mehr als 100 % betragen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"37,9","equivalents":["+37,9","37.9","+37.9"],"known_errors":{"2,2":"gesamtheit_statt_bedingung","+2,2":"gesamtheit_statt_bedingung","2.2":"gesamtheit_statt_bedingung","+2.2":"gesamtheit_statt_bedingung","5,5":"bedingung_vertauscht","+5,5":"bedingung_vertauscht","5.5":"bedingung_vertauscht","+5.5":"bedingung_vertauscht","263,6":"bezug_vertauscht","+263,6":"bezug_vertauscht","263.6":"bezug_vertauscht","+263.6":"bezug_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #9 bedingt-wkeit-03 · P(Schwimmen | Erwachsene) · gekürzter Bruch
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '15c3975c-0191-4062-9316-1000bf387b74'::uuid, 'exercise', 'P(Schwimmen | Erwachsene) · gekürzter Bruch', 'Ein Sportverein hat 120 Mitglieder gefragt, ob sie das Schwimmangebot nutzen.
Kinder, schwimmen: 42
Kinder, schwimmen nicht: 28
Erwachsene, schwimmen: 18
Erwachsene, schwimmen nicht: 32
Kinder insgesamt: 70
Erwachsene insgesamt: 50
Schwimmen insgesamt: 60
Schwimmen nicht insgesamt: 60
Alle Mitglieder: 120

Ein zufällig ausgewähltes Mitglied ist erwachsen. Wie groß ist die Wahrscheinlichkeit, dass es das Schwimmangebot nutzt? Gib die Wahrscheinlichkeit exakt als gekürzten Bruch oder als Dezimalzahl an.',
  '{"kind":"short_input","prompt":"Ein Sportverein hat 120 Mitglieder gefragt, ob sie das Schwimmangebot nutzen.\nKinder, schwimmen: 42\nKinder, schwimmen nicht: 28\nErwachsene, schwimmen: 18\nErwachsene, schwimmen nicht: 32\nKinder insgesamt: 70\nErwachsene insgesamt: 50\nSchwimmen insgesamt: 60\nSchwimmen nicht insgesamt: 60\nAlle Mitglieder: 120\n\nEin zufällig ausgewähltes Mitglied ist erwachsen. Wie groß ist die Wahrscheinlichkeit, dass es das Schwimmangebot nutzt? Gib die Wahrscheinlichkeit exakt als gekürzten Bruch oder als Dezimalzahl an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: richtige Teilgruppe wählen und das Ergebnis als gekürzten Bruch angeben.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '15c3975c-0191-4062-9316-1000bf387b74'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '15c3975c-0191-4062-9316-1000bf387b74'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '15c3975c-0191-4062-9316-1000bf387b74'::uuid,
  p_correct_answers => '["0,36","+0,36","0.36","+0.36","9/25","+9/25"]'::jsonb,
  p_solution        => 'Bedingung: erwachsen. Es zählen nur die 50 Erwachsenen, davon schwimmen 18.
P(schwimmt | erwachsen) = 18/50 = 9/25 = 0,36.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch alle 120 Mitglieder geteilt statt durch die 50 Erwachsenen.","socratic_question":"Aus welcher Gruppe wird gezogen, wenn feststeht, dass das Mitglied erwachsen ist?"},{"error":"Durch alle Schwimmer geteilt: Das ist die Wahrscheinlichkeit, dass ein Schwimmer erwachsen ist.","socratic_question":"Steht fest, dass das Mitglied erwachsen ist, oder dass es schwimmt?"},{"error":"Den Kehrwert gebildet: 50/18.","socratic_question":"Kann eine Wahrscheinlichkeit größer als 1 sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,36","equivalents":["+0,36","0.36","+0.36","9/25","+9/25"],"known_errors":{"0,15":"gesamtheit_statt_bedingung","+0,15":"gesamtheit_statt_bedingung","0.15":"gesamtheit_statt_bedingung","+0.15":"gesamtheit_statt_bedingung","3/20":"gesamtheit_statt_bedingung","+3/20":"gesamtheit_statt_bedingung","0,3":"bedingung_vertauscht","+0,3":"bedingung_vertauscht","0.3":"bedingung_vertauscht","+0.3":"bedingung_vertauscht","3/10":"bedingung_vertauscht","+3/10":"bedingung_vertauscht","25/9":"bezug_vertauscht","+25/9":"bezug_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #10 bedingt-wkeit-04 · P(Popcorn | Kind) · erst ergänzen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '860f4fc6-feff-4a62-86f4-83b799940023'::uuid, 'exercise', 'P(Popcorn | Kind) · erst ergänzen', 'Ein Kino hat an einem Nachmittag 250 Besucherinnen und Besucher gezählt.
Erwachsene mit Popcorn: 45
Erwachsene insgesamt: 150
Mit Popcorn insgesamt: 105
Alle Besucher: 250

Eine zufällig ausgewählte Person ist ein Kind. Wie groß ist die Wahrscheinlichkeit, dass es Popcorn gekauft hat? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Kino hat an einem Nachmittag 250 Besucherinnen und Besucher gezählt.\nErwachsene mit Popcorn: 45\nErwachsene insgesamt: 150\nMit Popcorn insgesamt: 105\nAlle Besucher: 250\n\nEine zufällig ausgewählte Person ist ein Kind. Wie groß ist die Wahrscheinlichkeit, dass es Popcorn gekauft hat? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Felder der Tafel erst ergänzen, dann die bedingte Wahrscheinlichkeit bilden.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht, randsumme_verwechselt).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '860f4fc6-feff-4a62-86f4-83b799940023'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '860f4fc6-feff-4a62-86f4-83b799940023'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '860f4fc6-feff-4a62-86f4-83b799940023'::uuid,
  p_correct_answers => '["0,60","+0,60","0.60","+0.60","0,6","+0,6","0.6","+0.6"]'::jsonb,
  p_solution        => 'Kinder insgesamt = 250 − 150 = 100.
Kinder mit Popcorn = 105 − 45 = 60.
P(Popcorn | Kind) = 60 : 100 = 0,60.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch alle 250 Besucher geteilt statt durch die 100 Kinder.","socratic_question":"Aus welcher Gruppe wird gezogen, wenn feststeht, dass es ein Kind ist?"},{"error":"Durch alle mit Popcorn geteilt: Das ist die Wahrscheinlichkeit, dass eine Person mit Popcorn ein Kind ist.","socratic_question":"Steht fest, dass die Person ein Kind ist, oder dass sie Popcorn hat?"},{"error":"Die Kinder falsch ergänzt: 250 − 105 = 145 (das sind alle ohne Popcorn) statt 250 − 150 = 100.","socratic_question":"Welche Summe besteht aus Erwachsenen und Kindern?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,60","equivalents":["+0,60","0.60","+0.60","0,6","+0,6","0.6","+0.6"],"known_errors":{"0,24":"gesamtheit_statt_bedingung","+0,24":"gesamtheit_statt_bedingung","0.24":"gesamtheit_statt_bedingung","+0.24":"gesamtheit_statt_bedingung","0,57":"bedingung_vertauscht","+0,57":"bedingung_vertauscht","0.57":"bedingung_vertauscht","+0.57":"bedingung_vertauscht","0,41":"randsumme_verwechselt","+0,41":"randsumme_verwechselt","0.41":"randsumme_verwechselt","+0.41":"randsumme_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #11 bedingt-wkeit-05 · Bibliothek · verlängerte Romane in Prozent
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'cdb39700-560b-4daa-9d8d-dc112752dcea'::uuid, 'exercise', 'Bibliothek · verlängerte Romane in Prozent', 'Eine Bibliothek wertet 600 Ausleihen aus. 240 davon waren Sachbücher, der Rest Romane. 180 Ausleihen wurden verlängert, davon waren 96 Sachbücher.

Wie viel Prozent der ausgeliehenen Romane wurden verlängert? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Bibliothek wertet 600 Ausleihen aus. 240 davon waren Sachbücher, der Rest Romane. 180 Ausleihen wurden verlängert, davon waren 96 Sachbücher.\n\nWie viel Prozent der ausgeliehenen Romane wurden verlängert? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: Tafel aus einem Text gewinnen, Bedingung „Roman“ erkennen und in Prozent angeben.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'cdb39700-560b-4daa-9d8d-dc112752dcea'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'cdb39700-560b-4daa-9d8d-dc112752dcea'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'cdb39700-560b-4daa-9d8d-dc112752dcea'::uuid,
  p_correct_answers => '["23,3","+23,3","23.3","+23.3"]'::jsonb,
  p_solution        => 'Romane = 600 − 240 = 360.
Verlängerte Romane = 180 − 96 = 84.
Anteil = 84 : 360 ≈ 0,2333, also ≈ 23,3 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Durch alle 600 Ausleihen geteilt statt durch die 360 Romane.","socratic_question":"Bezieht sich die Frage auf alle Ausleihen oder nur auf die Romane?"},{"error":"Durch alle verlängerten Ausleihen geteilt: Das ist der Anteil der Romane unter den Verlängerungen.","socratic_question":"Wird nach den Romanen gefragt, die verlängert wurden, oder nach den Verlängerungen, die Romane waren?"},{"error":"Den Kehrwert gebildet: 360 : 84.","socratic_question":"Können mehr als 100 % der Romane verlängert worden sein?"}]'::jsonb,
  p_acceptance      => '{"canonical":"23,3","equivalents":["+23,3","23.3","+23.3"],"known_errors":{"14":"gesamtheit_statt_bedingung","14,0":"gesamtheit_statt_bedingung","+14,0":"gesamtheit_statt_bedingung","14.0":"gesamtheit_statt_bedingung","+14.0":"gesamtheit_statt_bedingung","+14":"gesamtheit_statt_bedingung","46,7":"bedingung_vertauscht","+46,7":"bedingung_vertauscht","46.7":"bedingung_vertauscht","+46.7":"bedingung_vertauscht","428,6":"bezug_vertauscht","+428,6":"bezug_vertauscht","428.6":"bezug_vertauscht","+428.6":"bezug_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #12 bedingt-wkeit-06 · Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge)
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2ad35b16-c351-4f0d-9cb1-8a6f564e9015'::uuid, 'exercise', 'Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge)', 'Von 250 befragten Jugendlichen sind 100 Jungen. 70 % der Jungen haben ein Haustier. Insgesamt haben 160 der Befragten ein Haustier.

Eine zufällig ausgewählte Person mit Haustier wird befragt. Wie groß ist die Wahrscheinlichkeit, dass es ein Junge ist? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"Von 250 befragten Jugendlichen sind 100 Jungen. 70 % der Jungen haben ein Haustier. Insgesamt haben 160 der Befragten ein Haustier.\n\nEine zufällig ausgewählte Person mit Haustier wird befragt. Wie groß ist die Wahrscheinlichkeit, dass es ein Junge ist? Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_wkeit',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'III', 'stochastik', 'Problemlösen, Operieren',
  120, null, false, 1, 'draft', 'edvance_k9_bedingt', 'bedingt-wkeit-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus einer bedingten Wahrscheinlichkeit die Tafel aufbauen und die umgekehrte Bedingung bestimmen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_vertauscht, gesamtheit_statt_bedingung, falsche_groesse_beantwortet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2ad35b16-c351-4f0d-9cb1-8a6f564e9015'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2ad35b16-c351-4f0d-9cb1-8a6f564e9015'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2ad35b16-c351-4f0d-9cb1-8a6f564e9015'::uuid,
  p_correct_answers => '["0,44","+0,44","0.44","+0.44"]'::jsonb,
  p_solution        => 'Jungen mit Haustier = 70 % von 100 = 70.
Bedingung: Haustier. Es zählen nur die 160 Personen mit Haustier.
P(Junge | Haustier) = 70 : 160 = 0,4375 ≈ 0,44.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die gegebene Wahrscheinlichkeit P(Haustier | Junge) = 0,70 übernommen.","socratic_question":"Steht diesmal fest, dass es ein Junge ist, oder dass die Person ein Haustier hat?"},{"error":"Durch alle 250 Befragten geteilt statt durch die 160 mit Haustier.","socratic_question":"Aus welcher Gruppe wird die Person ausgewählt?"},{"error":"Die Anzahl der Jungen mit Haustier (70) angegeben statt einer Wahrscheinlichkeit.","socratic_question":"Ist nach einer Anzahl oder nach einer Wahrscheinlichkeit gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"0,44","equivalents":["+0,44","0.44","+0.44"],"known_errors":{"70":"falsche_groesse_beantwortet","0,70":"bedingung_vertauscht","+0,70":"bedingung_vertauscht","0.70":"bedingung_vertauscht","+0.70":"bedingung_vertauscht","0,7":"bedingung_vertauscht","+0,7":"bedingung_vertauscht","0.7":"bedingung_vertauscht","+0.7":"bedingung_vertauscht","0,28":"gesamtheit_statt_bedingung","+0,28":"gesamtheit_statt_bedingung","0.28":"gesamtheit_statt_bedingung","+0.28":"gesamtheit_statt_bedingung","70,00":"falsche_groesse_beantwortet","+70,00":"falsche_groesse_beantwortet","70.00":"falsche_groesse_beantwortet","+70.00":"falsche_groesse_beantwortet","+70":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #13 bedingt-unabhaengig-01 · Erwartete Anzahl bei Unabhängigkeit
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '91229203-0300-42ac-a9a5-e5bb1dd2e768'::uuid, 'exercise', 'Erwartete Anzahl bei Unabhängigkeit', 'Von 200 befragten Jugendlichen sind 120 Mädchen. 90 der Befragten haben ein Haustier.

Wie viele Mädchen mit Haustier wären zu erwarten, wenn Geschlecht und Haustierbesitz unabhängig voneinander wären? Gib die Anzahl als ganze Zahl an.',
  '{"kind":"short_input","prompt":"Von 200 befragten Jugendlichen sind 120 Mädchen. 90 der Befragten haben ein Haustier.\n\nWie viele Mädchen mit Haustier wären zu erwarten, wenn Geschlecht und Haustierbesitz unabhängig voneinander wären? Gib die Anzahl als ganze Zahl an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: erwartete Anzahl = Zeilensumme · Spaltensumme : Gesamtzahl.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, falsche_operation).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '91229203-0300-42ac-a9a5-e5bb1dd2e768'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '91229203-0300-42ac-a9a5-e5bb1dd2e768'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '91229203-0300-42ac-a9a5-e5bb1dd2e768'::uuid,
  p_correct_answers => '["54","+54"]'::jsonb,
  p_solution        => 'Bei Unabhängigkeit haben die Mädchen denselben Anteil an Haustieren wie alle: 90 : 200 = 0,45.
Erwartete Anzahl = 120 · 0,45 = 120 · 90 : 200 = 54.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wahrscheinlichkeit 0,6 · 0,45 = 0,27 angegeben statt der Anzahl.","socratic_question":"Ist nach einer Wahrscheinlichkeit oder nach einer Anzahl von Mädchen gefragt?"},{"error":"Die Anteile addiert statt multipliziert: (0,6 + 0,45) · 200.","socratic_question":"Können mehr Mädchen ein Haustier haben, als es Mädchen gibt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"54","equivalents":["+54"],"known_errors":{"210":"falsche_operation","0,27":"falsche_groesse_beantwortet","+0,27":"falsche_groesse_beantwortet","0.27":"falsche_groesse_beantwortet","+0.27":"falsche_groesse_beantwortet","+210":"falsche_operation"}}'::jsonb);
  end if;
end
$loesung$;

-- #14 bedingt-unabhaengig-02 · P(A | B) und P(A) vergleichen · Prozentpunkte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'b67dead9-84f6-44fe-9ab9-86ae6134f716'::uuid, 'exercise', 'P(A | B) und P(A) vergleichen · Prozentpunkte', 'Von 200 befragten Jugendlichen sind 120 Mädchen. 63 der Mädchen haben ein Haustier. Insgesamt haben 90 der Befragten ein Haustier.

Um wie viele Prozentpunkte ist der Anteil der Haustierbesitzer unter den Mädchen größer als der Anteil der Haustierbesitzer unter allen Befragten? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Von 200 befragten Jugendlichen sind 120 Mädchen. 63 der Mädchen haben ein Haustier. Insgesamt haben 90 der Befragten ein Haustier.\n\nUm wie viele Prozentpunkte ist der Anteil der Haustierbesitzer unter den Mädchen größer als der Anteil der Haustierbesitzer unter allen Befragten? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei Anteile in Prozent berechnen und ihren Abstand angeben.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (gesamtheit_statt_bedingung, bedingung_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'b67dead9-84f6-44fe-9ab9-86ae6134f716'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'b67dead9-84f6-44fe-9ab9-86ae6134f716'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'b67dead9-84f6-44fe-9ab9-86ae6134f716'::uuid,
  p_correct_answers => '["7,5","+7,5","7.5","+7.5"]'::jsonb,
  p_solution        => 'Unter den Mädchen: 63 : 120 = 0,525 = 52,5 %.
Unter allen: 90 : 200 = 0,45 = 45 %.
Unterschied: 52,5 − 45 = 7,5 Prozentpunkte. Die Anteile sind verschieden, also sind Geschlecht und Haustierbesitz nicht unabhängig.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Mädchen mit Haustier durch alle 200 geteilt (31,5 %) und mit 45 % verglichen.","socratic_question":"Auf welche Gruppe bezieht sich „Anteil unter den Mädchen“?"},{"error":"Den Anteil der Mädchen unter den Haustierbesitzern (70 %) mit dem Mädchenanteil (60 %) verglichen.","socratic_question":"Welche beiden Anteile nennt die Frage genau?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,5","equivalents":["+7,5","7.5","+7.5"],"known_errors":{"10":"bedingung_vertauscht","13,5":"gesamtheit_statt_bedingung","+13,5":"gesamtheit_statt_bedingung","13.5":"gesamtheit_statt_bedingung","+13.5":"gesamtheit_statt_bedingung","10,0":"bedingung_vertauscht","+10,0":"bedingung_vertauscht","10.0":"bedingung_vertauscht","+10.0":"bedingung_vertauscht","+10":"bedingung_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #15 bedingt-unabhaengig-03 · Fehlende Zahl für Unabhängigkeit · Pflanzen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '91fc34f7-0f5c-4fcb-bc9a-35c8e49f8d1c'::uuid, 'exercise', 'Fehlende Zahl für Unabhängigkeit · Pflanzen', 'Von 300 Pflanzen wurden 120 gedüngt. Von den 180 nicht gedüngten Pflanzen blühen 117.

Wie viele der gedüngten Pflanzen müssten blühen, damit Blühen und Düngen unabhängig voneinander sind? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Von 300 Pflanzen wurden 120 gedüngt. Von den 180 nicht gedüngten Pflanzen blühen 117.\n\nWie viele der gedüngten Pflanzen müssten blühen, damit Blühen und Düngen unabhängig voneinander sind? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Bedingung für Unabhängigkeit (gleiche Anteile) als Rechnung umsetzen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (absolut_statt_relativ, gesamtheit_statt_bedingung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '91fc34f7-0f5c-4fcb-bc9a-35c8e49f8d1c'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '91fc34f7-0f5c-4fcb-bc9a-35c8e49f8d1c'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '91fc34f7-0f5c-4fcb-bc9a-35c8e49f8d1c'::uuid,
  p_correct_answers => '["78","+78"]'::jsonb,
  p_solution        => 'Unabhängig heißt: Der Anteil blühender Pflanzen ist bei gedüngten und nicht gedüngten gleich.
Anteil bei nicht gedüngten: 117 : 180 = 0,65.
Gedüngte, die blühen müssten: 120 · 0,65 = 78.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Dieselbe Anzahl wie bei den nicht gedüngten übernommen statt denselben Anteil.","socratic_question":"Sind gleich viele blühende Pflanzen dasselbe wie ein gleicher Anteil, wenn die Gruppen verschieden groß sind?"},{"error":"Den Anteil 117 : 300 an allen Pflanzen genommen statt 117 : 180 an den nicht gedüngten.","socratic_question":"Aus welcher Gruppe stammen die 117 blühenden Pflanzen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"78","equivalents":["+78"],"known_errors":{"117":"absolut_statt_relativ","+117":"absolut_statt_relativ","46,8":"gesamtheit_statt_bedingung","+46,8":"gesamtheit_statt_bedingung","46.8":"gesamtheit_statt_bedingung","+46.8":"gesamtheit_statt_bedingung"}}'::jsonb);
  end if;
end
$loesung$;

-- #16 bedingt-unabhaengig-04 · Befall im Gewächshaus und Freiland · Prozentpunkte
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '36c037ea-2bf9-4d79-8dd6-e45bd85f7ef5'::uuid, 'exercise', 'Befall im Gewächshaus und Freiland · Prozentpunkte', 'Eine Gärtnerei hat 240 Tomatenpflanzen auf Schädlingsbefall untersucht.
Gewächshaus mit Befall: 18
Gewächshaus ohne Befall: 132
Freiland mit Befall: 24
Freiland ohne Befall: 66
Gewächshaus insgesamt: 150
Freiland insgesamt: 90
Mit Befall insgesamt: 42
Ohne Befall insgesamt: 198
Alle Pflanzen: 240

Um wie viele Prozentpunkte ist der Anteil befallener Pflanzen im Freiland größer als im Gewächshaus? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Gärtnerei hat 240 Tomatenpflanzen auf Schädlingsbefall untersucht.\nGewächshaus mit Befall: 18\nGewächshaus ohne Befall: 132\nFreiland mit Befall: 24\nFreiland ohne Befall: 66\nGewächshaus insgesamt: 150\nFreiland insgesamt: 90\nMit Befall insgesamt: 42\nOhne Befall insgesamt: 198\nAlle Pflanzen: 240\n\nUm wie viele Prozentpunkte ist der Anteil befallener Pflanzen im Freiland größer als im Gewächshaus? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei bedingte Anteile aus der Tafel bilden und vergleichen, Rundung erst am Ende.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (absolut_statt_relativ, gesamtheit_statt_bedingung, zu_frueh_gerundet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '36c037ea-2bf9-4d79-8dd6-e45bd85f7ef5'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '36c037ea-2bf9-4d79-8dd6-e45bd85f7ef5'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '36c037ea-2bf9-4d79-8dd6-e45bd85f7ef5'::uuid,
  p_correct_answers => '["14,7","+14,7","14.7","+14.7"]'::jsonb,
  p_solution        => 'Freiland: 24 : 90 ≈ 26,67 %.
Gewächshaus: 18 : 150 = 12 %.
Unterschied: 26,67 − 12 ≈ 14,7 Prozentpunkte. Der Befall hängt also vom Standort ab.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Anzahlen verglichen statt der Anteile: 24 − 18.","socratic_question":"Sind die Gruppen im Gewächshaus und im Freiland gleich groß?"},{"error":"Beide Anzahlen durch alle 240 Pflanzen geteilt statt durch die Pflanzen des jeweiligen Standorts.","socratic_question":"Auf welche Pflanzen bezieht sich „Anteil im Freiland“?"},{"error":"Den Freiland-Anteil vorher auf 27 % gerundet: 27 − 12.","socratic_question":"Wann solltest du runden – zwischendurch oder erst am Ende?"}]'::jsonb,
  p_acceptance      => '{"canonical":"14,7","equivalents":["+14,7","14.7","+14.7"],"known_errors":{"6":"absolut_statt_relativ","15":"zu_frueh_gerundet","6,0":"absolut_statt_relativ","+6,0":"absolut_statt_relativ","6.0":"absolut_statt_relativ","+6.0":"absolut_statt_relativ","+6":"absolut_statt_relativ","2,5":"gesamtheit_statt_bedingung","+2,5":"gesamtheit_statt_bedingung","2.5":"gesamtheit_statt_bedingung","+2.5":"gesamtheit_statt_bedingung","15,0":"zu_frueh_gerundet","+15,0":"zu_frueh_gerundet","15.0":"zu_frueh_gerundet","+15.0":"zu_frueh_gerundet","+15":"zu_frueh_gerundet"}}'::jsonb);
  end if;
end
$loesung$;

-- #17 bedingt-unabhaengig-05 · Mensa und Unterstufe · Erwartung und Abweichung
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '239036c3-5e39-4ac1-83aa-bc320583b0ce'::uuid, 'exercise', 'Mensa und Unterstufe · Erwartung und Abweichung', 'An einer Schule mit 400 Schülerinnen und Schülern essen 35 % regelmäßig in der Mensa. 55 % aller Schülerinnen und Schüler gehören zur Unterstufe.

Wie viele Unterstufenschüler würden regelmäßig in der Mensa essen, wenn Mensabesuch und Stufe unabhängig voneinander wären? Tatsächlich sind es 95 Unterstufenschüler. Um wie viele liegt die tatsächliche Zahl über der erwarteten? Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Erwartete Anzahl bei Unabhängigkeit","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Unterschied zur tatsächlichen Zahl","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: erwartete Anzahl aus zwei Prozentangaben bilden und mit dem beobachteten Wert vergleichen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, falsche_operation).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '239036c3-5e39-4ac1-83aa-bc320583b0ce'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '239036c3-5e39-4ac1-83aa-bc320583b0ce'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '239036c3-5e39-4ac1-83aa-bc320583b0ce'::uuid,
  p_correct_answers => '{"1":["77","+77"],"2":["18","+18"]}'::jsonb,
  p_solution        => 'Bei Unabhängigkeit essen in der Unterstufe ebenfalls 35 %: Unterstufe = 55 % von 400 = 220, davon 35 %: 220 · 0,35 = 77.
Unterschied: 95 − 77 = 18. Die Zahl liegt deutlich über der Erwartung, Mensabesuch und Stufe sind nicht unabhängig.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Wahrscheinlichkeit 0,35 · 0,55 angegeben statt der Anzahl.","socratic_question":"Ist nach einer Wahrscheinlichkeit oder nach einer Anzahl gefragt?"},{"error":"Die Prozentsätze addiert statt multipliziert: 90 % von 400.","socratic_question":"Können mehr Unterstufenschüler in die Mensa gehen, als es Mensagänger gibt?"},{"error":"Addiert statt subtrahiert: 95 + 77.","socratic_question":"Wie bestimmt man, um wie viel eine Zahl größer ist als eine andere?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"77","equivalents":["+77"],"known_errors":{"360":"falsche_operation","0,1925":"falsche_groesse_beantwortet","+0,1925":"falsche_groesse_beantwortet","0.1925":"falsche_groesse_beantwortet","+0.1925":"falsche_groesse_beantwortet","+360":"falsche_operation"}},"2":{"canonical":"18","equivalents":["+18"],"known_errors":{"172":"falsche_operation","+172":"falsche_operation"}}}'::jsonb);
  end if;
end
$loesung$;

-- #18 bedingt-unabhaengig-06 · Garten und Lastenrad · Unabhängigkeit und Abstand
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5d5efaf9-a722-422c-bb98-6eb56b710fb6'::uuid, 'exercise', 'Garten und Lastenrad · Unabhängigkeit und Abstand', 'Eine Gemeinde hat 500 Haushalte befragt. 200 Haushalte haben einen Garten. Von den Haushalten mit Garten besitzen 30 % ein Lastenrad.

Wie viele Haushalte ohne Garten müssten ein Lastenrad besitzen, damit Garten und Lastenrad unabhängig voneinander sind?
Tatsächlich besitzen insgesamt 114 Haushalte ein Lastenrad. Um wie viele Prozentpunkte ist der Anteil der Lastenradbesitzer bei den Haushalten mit Garten größer als bei den Haushalten ohne Garten? Gib das Ergebnis exakt an.',
  null, 'MULTI_PART', 'stoch_bedingt_unabhaengig',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'III', 'stochastik', 'Problemlösen, Operieren',
  120, null, false, 1, 'draft', 'edvance_k9_bedingt', 'bedingt-unabhaengig-06',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Haushalte ohne Garten mit Lastenrad bei Unabhängigkeit","unit":null,"afb":"III","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Unterschied der Anteile in Prozentpunkten","unit":null,"afb":"III","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Bedingung für Unabhängigkeit selbst ansetzen und die beobachteten Anteile vergleichen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (absolut_statt_relativ, grundwert_verwechselt, gesamtheit_statt_bedingung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5d5efaf9-a722-422c-bb98-6eb56b710fb6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5d5efaf9-a722-422c-bb98-6eb56b710fb6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5d5efaf9-a722-422c-bb98-6eb56b710fb6'::uuid,
  p_correct_answers => '{"1":["90","+90"],"2":["12","+12"]}'::jsonb,
  p_solution        => 'Unabhängig heißt: Auch ohne Garten besitzen 30 % ein Lastenrad. Ohne Garten: 500 − 200 = 300 Haushalte, davon 30 %: 90.
Mit Garten und Lastenrad: 30 % von 200 = 60. Ohne Garten mit Lastenrad: 114 − 60 = 54, das sind 54 : 300 = 18 %.
Unterschied: 30 − 18 = 12 Prozentpunkte.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Dieselbe Anzahl wie bei den Haushalten mit Garten (60) übernommen statt denselben Anteil.","socratic_question":"Sind die Gruppen mit und ohne Garten gleich groß?"},{"error":"30 % von allen 500 Haushalten genommen statt von den 300 ohne Garten.","socratic_question":"Von welcher Gruppe sollen 30 % ein Lastenrad haben?"},{"error":"Die Anzahlen 60 und 54 verglichen statt der Anteile.","socratic_question":"Wird nach einem Unterschied von Anzahlen oder von Anteilen gefragt?"},{"error":"Beide Anzahlen durch alle 500 Haushalte geteilt statt durch die Größe der jeweiligen Gruppe.","socratic_question":"Auf welche Haushalte bezieht sich „Anteil bei den Haushalten ohne Garten“?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"90","equivalents":["+90"],"known_errors":{"60":"absolut_statt_relativ","150":"grundwert_verwechselt","+60":"absolut_statt_relativ","+150":"grundwert_verwechselt"}},"2":{"canonical":"12","equivalents":["+12"],"known_errors":{"6":"absolut_statt_relativ","+6":"absolut_statt_relativ","1,2":"gesamtheit_statt_bedingung","+1,2":"gesamtheit_statt_bedingung","1.2":"gesamtheit_statt_bedingung","+1.2":"gesamtheit_statt_bedingung"}}}'::jsonb);
  end if;
end
$loesung$;

-- #19 bedingt-umkehr-01 · Schnelltest · befallene und erkannte Proben
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '3635d7e9-fca6-4c09-87c1-2711f3d7e6e0'::uuid, 'exercise', 'Schnelltest · befallene und erkannte Proben', 'Ein Labor untersucht 1000 Blattproben mit einem Schnelltest auf eine Pflanzenkrankheit. 2 % der Proben sind befallen. Der Test erkennt 90 % der befallenen Proben.

Wie viele Proben sind befallen? Wie viele Proben sind befallen und haben einen positiven Test? Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-01',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Befallene Proben","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Befallene Proben mit positivem Test","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: zwei Prozentwerte nacheinander als natürliche Häufigkeiten.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (dezimalverschiebung, grundwert_verwechselt).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '3635d7e9-fca6-4c09-87c1-2711f3d7e6e0'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '3635d7e9-fca6-4c09-87c1-2711f3d7e6e0'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '3635d7e9-fca6-4c09-87c1-2711f3d7e6e0'::uuid,
  p_correct_answers => '{"1":["20","+20"],"2":["18","+18"]}'::jsonb,
  p_solution        => 'Befallen: 2 % von 1000 = 20.
Davon erkannt: 90 % von 20 = 18.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"2 % als 0,2 gerechnet statt als 0,02.","socratic_question":"Wie schreibt man 2 % als Dezimalzahl?"},{"error":"90 % von allen 1000 Proben genommen statt von den 20 befallenen.","socratic_question":"Worauf beziehen sich die 90 % – auf alle Proben oder nur auf die befallenen?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"20","equivalents":["+20"],"known_errors":{"200":"dezimalverschiebung","+200":"dezimalverschiebung"}},"2":{"canonical":"18","equivalents":["+18"],"known_errors":{"900":"grundwert_verwechselt","+900":"grundwert_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #20 bedingt-umkehr-02 · Prüfgerät · intakte Teile und Fehlalarme
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5da9ef15-5323-4556-9565-6ec5378a8b29'::uuid, 'exercise', 'Prüfgerät · intakte Teile und Fehlalarme', 'Ein Prüfgerät kontrolliert 5000 Bauteile. 4 % der Bauteile sind defekt. Bei 3 % der intakten Bauteile meldet das Gerät fälschlich einen Defekt.

Wie viele Bauteile sind intakt? Bei wie vielen intakten Bauteilen meldet das Gerät fälschlich einen Defekt? Gib jeweils die Anzahl als ganze Zahl an.',
  null, 'MULTI_PART', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 2, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-02',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Intakte Bauteile","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Intakte Bauteile mit Fehlalarm","unit":null,"afb":"I","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: Gegenwahrscheinlichkeit als Anzahl und Fehlalarmquote auf die richtige Gruppe anwenden.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (falsche_groesse_beantwortet, dezimalverschiebung, grundwert_verwechselt).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5da9ef15-5323-4556-9565-6ec5378a8b29'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5da9ef15-5323-4556-9565-6ec5378a8b29'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5da9ef15-5323-4556-9565-6ec5378a8b29'::uuid,
  p_correct_answers => '{"1":["4800","+4800"],"2":["144","+144"]}'::jsonb,
  p_solution        => 'Defekt: 4 % von 5000 = 200, also intakt: 5000 − 200 = 4800.
Fehlalarme: 3 % von 4800 = 144.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die defekten Bauteile angegeben statt der intakten.","socratic_question":"Sind die 4 % die intakten oder die defekten Teile?"},{"error":"4 % als 0,4 gerechnet: 5000 − 2000.","socratic_question":"Wie schreibt man 4 % als Dezimalzahl?"},{"error":"3 % von allen 5000 Bauteilen genommen statt von den 4800 intakten.","socratic_question":"Worauf beziehen sich die 3 % – auf alle Teile oder nur auf die intakten?"},{"error":"3 % als 0,3 gerechnet: 4800 · 0,3.","socratic_question":"Wie schreibt man 3 % als Dezimalzahl?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"4800","equivalents":["+4800"],"known_errors":{"200":"falsche_groesse_beantwortet","3000":"dezimalverschiebung","+200":"falsche_groesse_beantwortet","+3000":"dezimalverschiebung"}},"2":{"canonical":"144","equivalents":["+144"],"known_errors":{"150":"grundwert_verwechselt","1440":"dezimalverschiebung","+150":"grundwert_verwechselt","+1440":"dezimalverschiebung"}}}'::jsonb);
  end if;
end
$loesung$;

-- #21 bedingt-umkehr-03 · Schnelltest · positive Tests und Anteil wirklich befallen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '6a8af2d6-7306-488b-bd73-405bd3865931'::uuid, 'exercise', 'Schnelltest · positive Tests und Anteil wirklich befallen', 'Ein Labor untersucht 1000 Blattproben mit einem Schnelltest auf eine Pflanzenkrankheit. 2 % der Proben sind befallen. Der Test erkennt 90 % der befallenen Proben. Bei 5 % der gesunden Proben schlägt er fälschlich an.

Wie viele Proben haben insgesamt einen positiven Test? Wie viel Prozent der Proben mit positivem Test sind wirklich befallen? Gib die Anzahl als ganze Zahl an. Gib den Prozentsatz ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  null, 'MULTI_PART', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-03',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Proben mit positivem Test insgesamt","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Anteil wirklich befallener Proben unter den positiven (in %)","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: Tafel mit natürlichen Häufigkeiten aufbauen, positive Tests zählen und umkehren.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grundwert_verwechselt, falsche_groesse_beantwortet, bedingung_vertauscht, gesamtheit_statt_bedingung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '6a8af2d6-7306-488b-bd73-405bd3865931'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '6a8af2d6-7306-488b-bd73-405bd3865931'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '6a8af2d6-7306-488b-bd73-405bd3865931'::uuid,
  p_correct_answers => '{"1":["67","+67"],"2":["26,9","+26,9","26.9","+26.9"]}'::jsonb,
  p_solution        => 'Befallen: 20, davon positiv 90 %: 18.
Gesund: 980, davon fälschlich positiv 5 %: 49.
Positiv insgesamt: 18 + 49 = 67.
Anteil wirklich befallen: 18 : 67 ≈ 0,2687, also ≈ 26,9 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 5 % Fehlalarme von allen 1000 Proben genommen statt von den 980 gesunden: 18 + 50.","socratic_question":"Bei welchen Proben kann der Test fälschlich anschlagen?"},{"error":"Nur die befallenen Proben mit positivem Test gezählt, die Fehlalarme fehlen.","socratic_question":"Schlägt der Test auch bei gesunden Proben an?"},{"error":"Die Erkennungsrate 90 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Proben.","socratic_question":"Wird nach den befallenen Proben gefragt, die positiv sind, oder nach den positiven, die befallen sind?"},{"error":"Durch alle 1000 Proben geteilt statt durch die 67 positiven.","socratic_question":"Aus welchen Proben wird hier ausgewählt?"},{"error":"Mit den falsch gezählten 68 positiven Tests gerechnet.","socratic_question":"Wie viele gesunde Proben gibt es, und wie viele davon testen positiv?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"67","equivalents":["+67"],"known_errors":{"18":"falsche_groesse_beantwortet","68":"grundwert_verwechselt","+68":"grundwert_verwechselt","+18":"falsche_groesse_beantwortet"}},"2":{"canonical":"26,9","equivalents":["+26,9","26.9","+26.9"],"known_errors":{"90":"bedingung_vertauscht","90,0":"bedingung_vertauscht","+90,0":"bedingung_vertauscht","90.0":"bedingung_vertauscht","+90.0":"bedingung_vertauscht","+90":"bedingung_vertauscht","1,8":"gesamtheit_statt_bedingung","+1,8":"gesamtheit_statt_bedingung","1.8":"gesamtheit_statt_bedingung","+1.8":"gesamtheit_statt_bedingung","26,5":"grundwert_verwechselt","+26,5":"grundwert_verwechselt","26.5":"grundwert_verwechselt","+26.5":"grundwert_verwechselt"}}}'::jsonb);
  end if;
end
$loesung$;

-- #22 bedingt-umkehr-04 · Schnelltest · 1 % Befall, Anteil wirklich befallen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a784100b-b7e6-4cef-b62d-231262ed65e8'::uuid, 'exercise', 'Schnelltest · 1 % Befall, Anteil wirklich befallen', 'Eine Gärtnerei testet 10 000 Setzlinge auf einen Pilz. 1 % der Setzlinge ist befallen. Der Test erkennt 95 % der befallenen Setzlinge. Bei 2 % der gesunden Setzlinge schlägt er fälschlich an.

Wie viel Prozent der Setzlinge mit positivem Test sind wirklich befallen? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Gärtnerei testet 10 000 Setzlinge auf einen Pilz. 1 % der Setzlinge ist befallen. Der Test erkennt 95 % der befallenen Setzlinge. Bei 2 % der gesunden Setzlinge schlägt er fälschlich an.\n\nWie viel Prozent der Setzlinge mit positivem Test sind wirklich befallen? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: ganze Umkehrung in einem Zug, ohne vorgegebene Zwischenschritte.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_vertauscht, gesamtheit_statt_bedingung, grundwert_verwechselt).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a784100b-b7e6-4cef-b62d-231262ed65e8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a784100b-b7e6-4cef-b62d-231262ed65e8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a784100b-b7e6-4cef-b62d-231262ed65e8'::uuid,
  p_correct_answers => '["32,4","+32,4","32.4","+32.4"]'::jsonb,
  p_solution        => 'Befallen: 1 % von 10 000 = 100, davon positiv 95 %: 95.
Gesund: 9900, davon fälschlich positiv 2 %: 198.
Positiv insgesamt: 95 + 198 = 293.
Anteil wirklich befallen: 95 : 293 ≈ 0,3242, also ≈ 32,4 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Erkennungsrate 95 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Setzlingen.","socratic_question":"Wird nach den befallenen Setzlingen gefragt, die positiv sind, oder nach den positiven, die befallen sind?"},{"error":"Durch alle 10 000 Setzlinge geteilt statt durch die 293 positiven.","socratic_question":"Aus welchen Setzlingen wird hier ausgewählt?"},{"error":"Die 2 % Fehlalarme von allen 10 000 Setzlingen genommen statt von den 9900 gesunden.","socratic_question":"Bei welchen Setzlingen kann der Test fälschlich anschlagen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"32,4","equivalents":["+32,4","32.4","+32.4"],"known_errors":{"95":"bedingung_vertauscht","95,0":"bedingung_vertauscht","+95,0":"bedingung_vertauscht","95.0":"bedingung_vertauscht","+95.0":"bedingung_vertauscht","+95":"bedingung_vertauscht","0,95":"gesamtheit_statt_bedingung","+0,95":"gesamtheit_statt_bedingung","0.95":"gesamtheit_statt_bedingung","+0.95":"gesamtheit_statt_bedingung","32,2":"grundwert_verwechselt","+32,2":"grundwert_verwechselt","32.2":"grundwert_verwechselt","+32.2":"grundwert_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #23 bedingt-umkehr-05 · Saatgut · positive Tests und Anteil befallen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '5b30a658-06c2-4836-9084-91cd54095ab2'::uuid, 'exercise', 'Saatgut · positive Tests und Anteil befallen', 'Ein Labor prüft 2000 Saatgutproben mit einem Schnelltest auf einen Pilz. 5 % der Proben sind befallen. Der Test erkennt 80 % der befallenen Proben. Bei 4 % der gesunden Proben schlägt er fälschlich an.

Wie viele Proben haben insgesamt einen positiven Test? Wie viel Prozent der positiv getesteten Proben sind wirklich befallen? Gib die Anzahl als ganze Zahl an. Gib den Prozentsatz ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  null, 'MULTI_PART', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren, Operieren',
  90, null, false, 1, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-05',
  false, true, false, false, '[{"nr":1,"kind":"short_input","prompt":"Proben mit positivem Test insgesamt","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null},{"nr":2,"kind":"short_input","prompt":"Anteil wirklich befallener Proben unter den positiven (in %)","unit":null,"afb":"II","competency_content":"stochastik","competency_process":null}]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: aus der Beschreibung eines Prüfverfahrens die Tafel aufbauen und umkehren.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"parts.1.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.1.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.1":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"parts.2.afb":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"parts.2.competency_content":{"art":"neu","grund":"Wie die Aufgabe.","charge":"k9-bedingt"},"correct_answers.2":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (grundwert_verwechselt, falsche_groesse_beantwortet, bedingung_vertauscht, gesamtheit_statt_bedingung, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '5b30a658-06c2-4836-9084-91cd54095ab2'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '5b30a658-06c2-4836-9084-91cd54095ab2'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '5b30a658-06c2-4836-9084-91cd54095ab2'::uuid,
  p_correct_answers => '{"1":["156","+156"],"2":["51,3","+51,3","51.3","+51.3"]}'::jsonb,
  p_solution        => 'Befallen: 5 % von 2000 = 100, davon positiv 80 %: 80.
Gesund: 1900, davon fälschlich positiv 4 %: 76.
Positiv insgesamt: 80 + 76 = 156.
Anteil wirklich befallen: 80 : 156 ≈ 0,5128, also ≈ 51,3 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die 4 % Fehlalarme von allen 2000 Proben genommen statt von den 1900 gesunden: 80 + 80.","socratic_question":"Bei welchen Proben kann der Test fälschlich anschlagen?"},{"error":"Nur die befallenen Proben mit positivem Test gezählt, die Fehlalarme fehlen.","socratic_question":"Schlägt der Test auch bei gesunden Proben an?"},{"error":"Die Erkennungsrate 80 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Proben.","socratic_question":"Wird nach den befallenen Proben gefragt, die positiv sind, oder nach den positiven, die befallen sind?"},{"error":"Durch alle 2000 Proben geteilt statt durch die 156 positiven.","socratic_question":"Aus welchen Proben wird hier ausgewählt?"},{"error":"Den Kehrwert gebildet: 156 : 80.","socratic_question":"Können mehr als 100 % der positiven Proben befallen sein?"}]'::jsonb,
  p_acceptance      => '{"1":{"canonical":"156","equivalents":["+156"],"known_errors":{"80":"falsche_groesse_beantwortet","160":"grundwert_verwechselt","+160":"grundwert_verwechselt","+80":"falsche_groesse_beantwortet"}},"2":{"canonical":"51,3","equivalents":["+51,3","51.3","+51.3"],"known_errors":{"4":"gesamtheit_statt_bedingung","80":"bedingung_vertauscht","195":"bezug_vertauscht","80,0":"bedingung_vertauscht","+80,0":"bedingung_vertauscht","80.0":"bedingung_vertauscht","+80.0":"bedingung_vertauscht","+80":"bedingung_vertauscht","4,0":"gesamtheit_statt_bedingung","+4,0":"gesamtheit_statt_bedingung","4.0":"gesamtheit_statt_bedingung","+4.0":"gesamtheit_statt_bedingung","+4":"gesamtheit_statt_bedingung","195,0":"bezug_vertauscht","+195,0":"bezug_vertauscht","195.0":"bezug_vertauscht","+195.0":"bezug_vertauscht","+195":"bezug_vertauscht"}}}'::jsonb);
  end if;
end
$loesung$;

-- #24 bedingt-umkehr-06 · Schweißnähte · Anteil echter Fehler ohne Gesamtzahl
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '18fe10bb-53d2-42a3-9b10-e4b04c65469d'::uuid, 'exercise', 'Schweißnähte · Anteil echter Fehler ohne Gesamtzahl', 'Ein Materialprüfgerät untersucht Schweißnähte. 4 % der Nähte sind fehlerhaft. Das Gerät meldet 95 % der fehlerhaften Nähte. Bei 10 % der fehlerfreien Nähte meldet es fälschlich einen Fehler.

Wie viel Prozent der gemeldeten Nähte sind tatsächlich fehlerhaft? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Ein Materialprüfgerät untersucht Schweißnähte. 4 % der Nähte sind fehlerhaft. Das Gerät meldet 95 % der fehlerhaften Nähte. Bei 10 % der fehlerfreien Nähte meldet es fälschlich einen Fehler.\n\nWie viel Prozent der gemeldeten Nähte sind tatsächlich fehlerhaft? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_umkehr',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'III', 'stochastik', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-umkehr-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen im Sachkontext: Eine Gesamtzahl selbst wählen, Tafel aufbauen und umkehren.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_vertauscht, gesamtheit_statt_bedingung, grundwert_verwechselt).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '18fe10bb-53d2-42a3-9b10-e4b04c65469d'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '18fe10bb-53d2-42a3-9b10-e4b04c65469d'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '18fe10bb-53d2-42a3-9b10-e4b04c65469d'::uuid,
  p_correct_answers => '["28,4","+28,4","28.4","+28.4"]'::jsonb,
  p_solution        => 'Man denkt sich zum Beispiel 1000 Nähte.
Fehlerhaft: 40, davon gemeldet 95 %: 38.
Fehlerfrei: 960, davon fälschlich gemeldet 10 %: 96.
Gemeldet insgesamt: 38 + 96 = 134.
Anteil tatsächlich fehlerhaft: 38 : 134 ≈ 0,2836, also ≈ 28,4 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Erkennungsrate 95 % übernommen: Das ist der Anteil gemeldeter Nähte unter den fehlerhaften.","socratic_question":"Wird nach den fehlerhaften Nähten gefragt, die gemeldet werden, oder nach den gemeldeten, die fehlerhaft sind?"},{"error":"Durch alle Nähte geteilt statt durch die gemeldeten.","socratic_question":"Aus welchen Nähten wird hier ausgewählt?"},{"error":"Die 10 % Fehlmeldungen von allen Nähten genommen statt von den fehlerfreien.","socratic_question":"Bei welchen Nähten kann das Gerät fälschlich einen Fehler melden?"}]'::jsonb,
  p_acceptance      => '{"canonical":"28,4","equivalents":["+28,4","28.4","+28.4"],"known_errors":{"95":"bedingung_vertauscht","95,0":"bedingung_vertauscht","+95,0":"bedingung_vertauscht","95.0":"bedingung_vertauscht","+95.0":"bedingung_vertauscht","+95":"bedingung_vertauscht","3,8":"gesamtheit_statt_bedingung","+3,8":"gesamtheit_statt_bedingung","3.8":"gesamtheit_statt_bedingung","+3.8":"gesamtheit_statt_bedingung","27,5":"grundwert_verwechselt","+27,5":"grundwert_verwechselt","27.5":"grundwert_verwechselt","+27.5":"grundwert_verwechselt"}}'::jsonb);
  end if;
end
$loesung$;

-- #25 bedingt-irrefuehrend-01 · Abgeschnittene Achse · gezeichnetes Verhältnis
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'd8be6909-8da5-4333-ac32-e6c6d1c34fa8'::uuid, 'exercise', 'Abgeschnittene Achse · gezeichnetes Verhältnis', 'In einem Säulendiagramm steht Säule A für den Wert 52 und Säule B für den Wert 48. Die Hochachse beginnt nicht bei 0, sondern bei 44.

Wie viel mal so hoch ist Säule A gezeichnet wie Säule B? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"In einem Säulendiagramm steht Säule A für den Wert 52 und Säule B für den Wert 48. Die Hochachse beginnt nicht bei 0, sondern bei 44.\n\nWie viel mal so hoch ist Säule A gezeichnet wie Säule B? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-01',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: sichtbare Säulenhöhen ab Achsenbeginn ins Verhältnis setzen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (achse_abgeschnitten_uebersehen, falsche_operation).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'd8be6909-8da5-4333-ac32-e6c6d1c34fa8'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'd8be6909-8da5-4333-ac32-e6c6d1c34fa8'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'd8be6909-8da5-4333-ac32-e6c6d1c34fa8'::uuid,
  p_correct_answers => '["2","+2"]'::jsonb,
  p_solution        => 'Gezeichnet wird nur der Teil ab 44.
Säule A: 52 − 44 = 8, Säule B: 48 − 44 = 4.
8 : 4 = 2. Säule A wirkt doppelt so hoch, obwohl die Werte kaum verschieden sind.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Werte statt der gezeichneten Höhen verglichen: 52 : 48 ≈ 1,08.","socratic_question":"Ab welcher Höhe beginnen die Säulen im Diagramm?"},{"error":"Die Werte statt der gezeichneten Höhen verglichen: 52 : 48 ≈ 1,1.","socratic_question":"Ab welcher Höhe beginnen die Säulen im Diagramm?"},{"error":"Den Unterschied der Werte angegeben statt eines Verhältnisses.","socratic_question":"Fragt „wie viel mal so hoch“ nach einer Differenz oder nach einem Faktor?"}]'::jsonb,
  p_acceptance      => '{"canonical":"2","equivalents":["+2"],"known_errors":{"4":"falsche_operation","1,08":"achse_abgeschnitten_uebersehen","+1,08":"achse_abgeschnitten_uebersehen","1.08":"achse_abgeschnitten_uebersehen","+1.08":"achse_abgeschnitten_uebersehen","1,1":"achse_abgeschnitten_uebersehen","+1,1":"achse_abgeschnitten_uebersehen","1.1":"achse_abgeschnitten_uebersehen","+1.1":"achse_abgeschnitten_uebersehen","+4":"falsche_operation"}}'::jsonb);
  end if;
end
$loesung$;

-- #26 bedingt-irrefuehrend-02 · Abgeschnittene Achse · tatsächliches Verhältnis
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '0f94090d-dced-46dd-ab0d-ff9152c75529'::uuid, 'exercise', 'Abgeschnittene Achse · tatsächliches Verhältnis', 'In einem Säulendiagramm steht Säule A für den Wert 75 und Säule B für den Wert 60. Die Hochachse beginnt bei 50, deshalb wirkt Säule A deutlich größer.

Wie viel mal so groß ist der Wert von A wie der Wert von B? Runde auf zwei Stellen nach dem Komma.',
  '{"kind":"short_input","prompt":"In einem Säulendiagramm steht Säule A für den Wert 75 und Säule B für den Wert 60. Die Hochachse beginnt bei 50, deshalb wirkt Säule A deutlich größer.\n\nWie viel mal so groß ist der Wert von A wie der Wert von B? Runde auf zwei Stellen nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'I', 'stochastik', 'Operieren',
  45, null, false, 1, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-02',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Reproduzieren: das echte Verhältnis der Werte bestimmen, unabhängig von der Zeichnung.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (achse_abgeschnitten_uebersehen, falsche_operation, bezug_vertauscht).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '0f94090d-dced-46dd-ab0d-ff9152c75529'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '0f94090d-dced-46dd-ab0d-ff9152c75529'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '0f94090d-dced-46dd-ab0d-ff9152c75529'::uuid,
  p_correct_answers => '["1,25","+1,25","1.25","+1.25"]'::jsonb,
  p_solution        => 'Es zählen die Werte, nicht die gezeichneten Höhen.
75 : 60 = 1,25. Gezeichnet ist Säule A dagegen (75 − 50) : (60 − 50) = 2,5-mal so hoch.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die gezeichneten Höhen ab 50 verglichen statt der Werte.","socratic_question":"Ist nach den Werten oder nach den gezeichneten Höhen gefragt?"},{"error":"Den Unterschied der Werte angegeben statt eines Verhältnisses.","socratic_question":"Fragt „wie viel mal so groß“ nach einer Differenz oder nach einem Faktor?"},{"error":"Den Kehrwert gebildet: 60 : 75.","socratic_question":"Ist A größer oder kleiner als B – muss der Faktor dann über oder unter 1 liegen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,25","equivalents":["+1,25","1.25","+1.25"],"known_errors":{"15":"falsche_operation","2,50":"achse_abgeschnitten_uebersehen","+2,50":"achse_abgeschnitten_uebersehen","2.50":"achse_abgeschnitten_uebersehen","+2.50":"achse_abgeschnitten_uebersehen","2,5":"achse_abgeschnitten_uebersehen","+2,5":"achse_abgeschnitten_uebersehen","2.5":"achse_abgeschnitten_uebersehen","+2.5":"achse_abgeschnitten_uebersehen","15,00":"falsche_operation","+15,00":"falsche_operation","15.00":"falsche_operation","+15.00":"falsche_operation","+15":"falsche_operation","0,80":"bezug_vertauscht","+0,80":"bezug_vertauscht","0.80":"bezug_vertauscht","+0.80":"bezug_vertauscht","0,8":"bezug_vertauscht","+0,8":"bezug_vertauscht","0.8":"bezug_vertauscht","+0.8":"bezug_vertauscht"}}'::jsonb);
  end if;
end
$loesung$;

-- #27 bedingt-irrefuehrend-03 · Absolut oder relativ · Radfahrer an zwei Schulen
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'a1c6838a-e550-4ed2-92cf-55244acded67'::uuid, 'exercise', 'Absolut oder relativ · Radfahrer an zwei Schulen', 'Eine Meldung lautet: „An Schule A fahren mehr Jugendliche mit dem Rad zur Schule als an Schule B.“ An Schule A fahren 36 von 240 Jugendlichen mit dem Rad, an Schule B 22 von 88.

Um wie viele Prozentpunkte ist der Anteil der Radfahrer an Schule B größer als an Schule A? Gib die Zahl ohne %-Zeichen exakt an.',
  '{"kind":"short_input","prompt":"Eine Meldung lautet: „An Schule A fahren mehr Jugendliche mit dem Rad zur Schule als an Schule B.“ An Schule A fahren 36 von 240 Jugendlichen mit dem Rad, an Schule B 22 von 88.\n\nUm wie viele Prozentpunkte ist der Anteil der Radfahrer an Schule B größer als an Schule A? Gib die Zahl ohne %-Zeichen exakt an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-03',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: zwei Anteile mit verschiedenen Grundwerten bilden und in Prozentpunkten vergleichen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (absolut_statt_relativ, dezimalverschiebung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a1c6838a-e550-4ed2-92cf-55244acded67'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'a1c6838a-e550-4ed2-92cf-55244acded67'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'a1c6838a-e550-4ed2-92cf-55244acded67'::uuid,
  p_correct_answers => '["10","+10"]'::jsonb,
  p_solution        => 'Schule A: 36 : 240 = 0,15 = 15 %.
Schule B: 22 : 88 = 0,25 = 25 %.
Unterschied: 25 − 15 = 10 Prozentpunkte. A hat zwar mehr Radfahrer, B aber den größeren Anteil.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Anzahlen verglichen statt der Anteile: 36 − 22.","socratic_question":"Sind beide Schulen gleich groß?"},{"error":"Den Unterschied der Anteile als Dezimalzahl angegeben (0,1) statt in Prozentpunkten.","socratic_question":"Wie viele Prozentpunkte sind 0,1?"}]'::jsonb,
  p_acceptance      => '{"canonical":"10","equivalents":["+10"],"known_errors":{"14":"absolut_statt_relativ","+14":"absolut_statt_relativ","0,1":"dezimalverschiebung","+0,1":"dezimalverschiebung","0.1":"dezimalverschiebung","+0.1":"dezimalverschiebung"}}'::jsonb);
  end if;
end
$loesung$;

-- #28 bedingt-irrefuehrend-04 · Schlagzeile mit vertauschter Bedingung · Kettenriss
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '2708a240-7d4b-42bb-a028-d106ebe60765'::uuid, 'exercise', 'Schlagzeile mit vertauschter Bedingung · Kettenriss', 'Eine Fahrradwerkstatt hat 1200 Fahrräder untersucht. 400 davon waren nie geölt worden. Bei 40 Fahrrädern war die Kette gerissen, 30 davon waren nie geölt worden.
Eine Schlagzeile lautet: „75 % der ungeölten Ketten reißen!“

Wie viel Prozent der nie geölten Fahrräder hatten tatsächlich eine gerissene Kette? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.',
  '{"kind":"short_input","prompt":"Eine Fahrradwerkstatt hat 1200 Fahrräder untersucht. 400 davon waren nie geölt worden. Bei 40 Fahrrädern war die Kette gerissen, 30 davon waren nie geölt worden.\nEine Schlagzeile lautet: „75 % der ungeölten Ketten reißen!“\n\nWie viel Prozent der nie geölten Fahrräder hatten tatsächlich eine gerissene Kette? Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Operieren',
  60, null, false, 2, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-04',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden: die Bedingung einer Schlagzeile prüfen und die gemeinte bedingte Wahrscheinlichkeit richtig berechnen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Rechnen nach festem Verfahren.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (bedingung_vertauscht, gesamtheit_statt_bedingung, falsche_groesse_beantwortet).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '2708a240-7d4b-42bb-a028-d106ebe60765'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '2708a240-7d4b-42bb-a028-d106ebe60765'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '2708a240-7d4b-42bb-a028-d106ebe60765'::uuid,
  p_correct_answers => '["7,5","+7,5","7.5","+7.5"]'::jsonb,
  p_solution        => '75 % stimmt nur so: 30 von 40 Fahrrädern mit gerissener Kette waren nie geölt. Die Schlagzeile vertauscht die Bedingung.
Gefragt: Bedingung „nie geölt“, also 30 : 400 = 0,075 = 7,5 %.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die Zahl der Schlagzeile übernommen: Das ist der Anteil ungeölter Räder unter denen mit gerissener Kette.","socratic_question":"Steht fest, dass das Rad nie geölt wurde, oder dass die Kette gerissen ist?"},{"error":"Durch alle 1200 Fahrräder geteilt statt durch die 400 nie geölten.","socratic_question":"Auf welche Fahrräder bezieht sich die Frage?"},{"error":"Die Anzahl 30 angegeben statt eines Prozentsatzes.","socratic_question":"Ist nach einer Anzahl oder nach einem Anteil in Prozent gefragt?"}]'::jsonb,
  p_acceptance      => '{"canonical":"7,5","equivalents":["+7,5","7.5","+7.5"],"known_errors":{"30":"falsche_groesse_beantwortet","75":"bedingung_vertauscht","75,0":"bedingung_vertauscht","+75,0":"bedingung_vertauscht","75.0":"bedingung_vertauscht","+75.0":"bedingung_vertauscht","+75":"bedingung_vertauscht","2,5":"gesamtheit_statt_bedingung","+2,5":"gesamtheit_statt_bedingung","2.5":"gesamtheit_statt_bedingung","+2.5":"gesamtheit_statt_bedingung","30,0":"falsche_groesse_beantwortet","+30,0":"falsche_groesse_beantwortet","30.0":"falsche_groesse_beantwortet","+30.0":"falsche_groesse_beantwortet","+30":"falsche_groesse_beantwortet"}}'::jsonb);
  end if;
end
$loesung$;

-- #29 bedingt-irrefuehrend-05 · Absolut oder relativ · Diebstähle je 1000 Einwohner
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  '982be3c3-2d1f-4d59-817a-b7bd45ade1d6'::uuid, 'exercise', 'Absolut oder relativ · Diebstähle je 1000 Einwohner', 'Ein Bericht meldet: „In Ort A wurden im letzten Jahr 45 Fahrräder gestohlen, in Ort B nur 18. In Ort A ist das Rad also weniger sicher.“ Ort A hat 15 000 Einwohner, Ort B hat 4000 Einwohner.

Um wie viele Diebstähle je 1000 Einwohner liegt Ort B über Ort A? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Bericht meldet: „In Ort A wurden im letzten Jahr 45 Fahrräder gestohlen, in Ort B nur 18. In Ort A ist das Rad also weniger sicher.“ Ort A hat 15 000 Einwohner, Ort B hat 4000 Einwohner.\n\nUm wie viele Diebstähle je 1000 Einwohner liegt Ort B über Ort A? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'II', 'stochastik', 'Modellieren, Operieren',
  90, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-05',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Anwenden im Sachkontext: eine Aussage über absolute Zahlen durch eine Rate je 1000 Einwohner prüfen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Sachsituation in eine Rechnung übersetzen, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (absolut_statt_relativ, dezimalverschiebung).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '982be3c3-2d1f-4d59-817a-b7bd45ade1d6'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = '982be3c3-2d1f-4d59-817a-b7bd45ade1d6'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => '982be3c3-2d1f-4d59-817a-b7bd45ade1d6'::uuid,
  p_correct_answers => '["1,5","+1,5","1.5","+1.5"]'::jsonb,
  p_solution        => 'Ort A: 45 Diebstähle auf 15 000 Einwohner = 3 je 1000 Einwohner.
Ort B: 18 Diebstähle auf 4000 Einwohner = 4,5 je 1000 Einwohner.
Unterschied: 4,5 − 3 = 1,5 Diebstähle je 1000 Einwohner. Gemessen an der Einwohnerzahl liegt B vorn.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Die absoluten Anzahlen verglichen: 45 − 18.","socratic_question":"Sind beide Orte gleich groß?"},{"error":"Die Rate je Einwohner berechnet statt je 1000 Einwohner: 0,0015.","socratic_question":"Auf wie viele Einwohner soll sich die Rate beziehen?"}]'::jsonb,
  p_acceptance      => '{"canonical":"1,5","equivalents":["+1,5","1.5","+1.5"],"known_errors":{"27":"absolut_statt_relativ","+27":"absolut_statt_relativ","0,0015":"dezimalverschiebung","+0,0015":"dezimalverschiebung","0.0015":"dezimalverschiebung","+0.0015":"dezimalverschiebung"}}'::jsonb);
  end if;
end
$loesung$;

-- #30 bedingt-irrefuehrend-06 · Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, vorbefuellt, vorbefuellt_am)
values (
  'f8f3a464-6dea-4783-a9de-3d5dda5fd878'::uuid, 'exercise', 'Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis', 'Ein Werbeblatt zeigt ein Säulendiagramm. Säule A steht für den Wert 66, Säule B für den Wert 54. Gezeichnet ist Säule A genau dreimal so hoch wie Säule B, weil die Hochachse nicht bei 0 beginnt.

Bei welchem Wert beginnt die Hochachse? Gib das Ergebnis exakt an.',
  '{"kind":"short_input","prompt":"Ein Werbeblatt zeigt ein Säulendiagramm. Säule A steht für den Wert 66, Säule B für den Wert 54. Gezeichnet ist Säule A genau dreimal so hoch wie Säule B, weil die Hochachse nicht bei 0 beginnt.\n\nBei welchem Wert beginnt die Hochachse? Gib das Ergebnis exakt an."}'::jsonb, 'NUMERIC', 'stoch_bedingt_irrefuehrend',
  9, 9,
  (select c.id from public.skill_clusters c where c.id = '9fdfed01-ebda-4c79-89ea-5accacefee93'::uuid),
  'III', 'stochastik', 'Problemlösen, Operieren',
  120, null, false, null, 'draft', 'edvance_k9_bedingt', 'bedingt-irrefuehrend-06',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb,
  '{"afb":{"art":"neu","grund":"Problemlösen: aus dem gezeichneten Verhältnis eine Gleichung für den Achsenbeginn aufstellen und lösen.","charge":"k9-bedingt"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"k9-bedingt"},"curriculum_grade":{"art":"neu","grund":"Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).","charge":"k9-bedingt"},"cluster_id":{"art":"neu","grund":"Daten & Zufall wie die Stochastik-Knoten im Bestand.","charge":"k9-bedingt"},"competency_content":{"art":"neu","grund":"Inhaltsfeld Stochastik (Sto-3 bis Sto-5).","charge":"k9-bedingt"},"competency_process":{"art":"neu","grund":"Lösungsweg selbst finden, dann rechnen.","charge":"k9-bedingt"},"needs_image":{"art":"neu","grund":"Alle Angaben stehen im Text, keine Abbildung nötig.","charge":"k9-bedingt"},"correct_answers":{"art":"neu","grund":"Exakt nachgerechnet; alle gleichwertigen Schreibweisen.","charge":"k9-bedingt"},"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"k9-bedingt"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors (achse_abgeschnitten_uebersehen, halbieren_vergessen).","charge":"k9-bedingt"},"hints":{"art":"leer","grund":"Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise.","charge":"k9-bedingt"}}'::jsonb, now())
on conflict do nothing;
do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'f8f3a464-6dea-4783-a9de-3d5dda5fd878'::uuid and t.status = 'draft' and t.source = 'edvance_k9_bedingt')
   and not exists (select 1 from public.task_solutions s where s.task_id = 'f8f3a464-6dea-4783-a9de-3d5dda5fd878'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
  p_task_id         => 'f8f3a464-6dea-4783-a9de-3d5dda5fd878'::uuid,
  p_correct_answers => '["48","+48"]'::jsonb,
  p_solution        => 'Achsenbeginn s: Gezeichnete Höhen 66 − s und 54 − s.
66 − s = 3 · (54 − s) = 162 − 3s, also 2s = 96 und s = 48.
Probe: 66 − 48 = 18 und 54 − 48 = 6; 18 = 3 · 6.',
  p_hints           => '[]'::jsonb,
  p_coach_hints     => '[]'::jsonb,
  p_typical_errors  => '[{"error":"Angenommen, die Achse beginne bei 0.","socratic_question":"Wäre Säule A bei einem Achsenbeginn von 0 wirklich dreimal so hoch wie B?"},{"error":"Bei 2s = 96 nicht durch 2 geteilt.","socratic_question":"Was steht nach dem Umformen links – s oder 2s?"}]'::jsonb,
  p_acceptance      => '{"canonical":"48","equivalents":["+48"],"known_errors":{"0":"achse_abgeschnitten_uebersehen","96":"halbieren_vergessen","+96":"halbieren_vergessen"}}'::jsonb);
  end if;
end
$loesung$;
