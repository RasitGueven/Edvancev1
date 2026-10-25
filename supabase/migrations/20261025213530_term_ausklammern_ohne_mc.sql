-- term_ausklammern: erste Aufgabe ohne MC (Rasit 25.10.2026). Batus Freigabeliste (docs/lsa/freigabeliste-batu-1025.md)
-- braucht je Bereich eine freigegebene Aufgabe ohne MC; bei term_ausklammern waren alle sechs Entwürfe MC.
--
-- Eingabe wie in der Schüler-App (edvance-app): Die Term-Tastatur kennt nur „a x + b“ (zwei Zahlenfelder, keine
-- Klammer), ein ausgeklammerter Term ist dort nicht eintippbar. Darum ein Mehrteiler mit drei Zahlenfeldern
-- (18x + 24 = ☐ · (☐x + ☐)); jede Lösung ist eine natürliche Zahl → input_hint 'number', Ziffernblock.
-- „So weit wie möglich“ macht die Lösung eindeutig: ggT(18, 24) = 6 → 6(3x + 4). Zahlen kommen in keinem der
-- sechs MC-Entwürfe vor (12x + 18, 4x + 20, 4x + 8, 6x + 12, 8x + 12, 9x + 27).
--
-- Status draft, pruef_pilot an: Lena prüft sie im LSA-Reiter (batu_lsa, P4), danach Freigabe durch den Admin.
-- Cluster, Kompetenz und einsatz wie die Geschwister. Idempotent; ohne Knoten (CI-Neuaufbau) übersprungen.
-- Kein begin/commit: mig klammert.

insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, competency_id, afb, competency_content, competency_process,
  estimated_minutes, est_duration_sec, needs_image, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot)
select
  '04a1a844-559d-4bb6-8c0c-c2a93bc18dee'::uuid, 'exercise', 'Terme · Ausklammern · 18x + 24 · Lücken',
  E'Klammere so weit wie möglich aus.\n\n18x + 24 = ☐ · (☐x + ☐)\n\nGib die drei fehlenden Zahlen an.',
  null, 'MULTI_PART', 'term_ausklammern', null, 7,
  (select g.cluster_id from public.tasks g where g.source_ref = 'term-ausklammern-06'),
  (select g.competency_id from public.tasks g where g.source_ref = 'term-ausklammern-06'),
  'II', 'arithmetik_algebra', 'Operieren', 3, 60, false, 'draft', 'edvance_fundament', 'term-ausklammern-07',
  false, true, false, false,
  '[{"nr": 1, "afb": "II", "kind": "short_input", "unit": null, "prompt": "Zahl vor der Klammer",
     "competency_content": "arithmetik_algebra", "competency_process": "Operieren"},
    {"nr": 2, "afb": "II", "kind": "short_input", "unit": null, "prompt": "Zahl vor dem x in der Klammer",
     "competency_content": "arithmetik_algebra", "competency_process": "Operieren"},
    {"nr": 3, "afb": "II", "kind": "short_input", "unit": null, "prompt": "Zahl ohne x in der Klammer",
     "competency_content": "arithmetik_algebra", "competency_process": "Operieren"}]'::jsonb,
  '[]'::jsonb, '{lsa,session}'::text[], true
 where exists (select 1 from public.skills s where s.skill_key = 'term_ausklammern')
on conflict do nothing;

do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = '04a1a844-559d-4bb6-8c0c-c2a93bc18dee'::uuid)
     and not exists (select 1 from public.task_solutions s where s.task_id = '04a1a844-559d-4bb6-8c0c-c2a93bc18dee'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
      p_task_id         => '04a1a844-559d-4bb6-8c0c-c2a93bc18dee'::uuid,
      p_correct_answers => '{"1": ["6", "+6"], "2": ["3", "+3"], "3": ["4", "+4"]}'::jsonb,
      p_solution        => E'Der größte gemeinsame Teiler von 18 und 24 ist 6.\n'
                           || E'18x + 24 = 6 · 3x + 6 · 4 = 6 · (3x + 4).\n'
                           || 'Probe: 6 · 3x + 6 · 4 = 18x + 24.',
      p_hints           => '[{"text": "Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl.", "level": 1, "status": "entwurf"},
                            {"text": "Suche die größte Zahl, durch die sich 18 und 24 beide ohne Rest teilen lassen. Die kommt vor die Klammer.", "level": 2, "status": "entwurf"},
                            {"text": "Teile 18x und 24 jeweils durch die Zahl vor der Klammer und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus: Kommt 18x + 24 heraus?", "level": 3, "status": "entwurf"}]'::jsonb,
      p_coach_hints     => '[]'::jsonb,
      p_typical_errors  => '[{"error": "Einen gemeinsamen Teiler ausgeklammert, aber nicht den größten: 2 · (9x + 12) oder 3 · (6x + 8).", "socratic_question": "Haben die Zahlen in deiner Klammer noch einen gemeinsamen Teiler?"},
                            {"error": "Den Faktor ausgeklammert, ein Glied aber nicht geteilt: 6 · (3x + 24) oder 6 · (18x + 4).", "socratic_question": "Rechne deine Klammer wieder aus – kommt 18x + 24 heraus?"}]'::jsonb,
      p_beleg           => null,
      p_acceptance      => '{"1": {"canonical": "6", "equivalents": ["+6"], "known_errors": {"2": "ausklammern_nicht_ggt", "3": "ausklammern_nicht_ggt"}},
                             "2": {"canonical": "3", "equivalents": ["+3"], "known_errors": {"18": "ausklammern_glied_nicht_geteilt", "9": "ausklammern_nicht_ggt"}},
                             "3": {"canonical": "4", "equivalents": ["+4"], "known_errors": {"24": "ausklammern_glied_nicht_geteilt", "12": "ausklammern_nicht_ggt", "8": "ausklammern_nicht_ggt"}}}'::jsonb,
      p_option_scores   => null);
  end if;
end
$loesung$;
