-- Lenas Rückfrage vom 20.10.2026 (M2, Daten; nach 20261021073327_lsa_grade_prozent_faktor).
--
-- 1. 54f5e1df (Urne, 12/25) und 939baa76 (Münze, 1/2), Fertigkeit stoch_pfad_summe, freie Schreibweise.
--    Richtig sind Bruch, Dezimalzahl und Prozent mit Prozentzeichen; falsch sind die Dezimalzahl mit „%“
--    und die Prozentzahl ohne „%“ (Rasit, 21.10.2026). Entfernt aus correct_answers und equivalents:
--      54f5e1df: 48, 0,48 %, 0,48%, 0.48 %, 0.48%, +0,48 %, +0,48%, +0.48 %, +0.48%
--      939baa76: 50, 0,5 %, 0,5%, 0.5 %, 0.5%, +0,5 %, +0,5%, +0.5 %, +0.5%
--    Ergänzt als gleichwertige Brüche: 24/50 und 48/100 bzw. 50/100 (Hinweis der Zweitprüfung; lsa_grade wertete
--    sie schon als richtig, lsa_is_correct nicht).
--    Bei 54f5e1df fällt außerdem acceptance.unit = '%' weg. Die Antwort ist kein Prozentsatz, und das Feld
--    zeigt keine Einheit (tasks.unit ist leer; die App liest nur tasks.unit). Die Ausgangsfassung in
--    task_pruefung_ausgang wird gleich nachgezogen („48“ bzw. „50“), sonst meldet das Board die Korrektur
--    als Änderung.
-- Compare-and-set: geändert wird nur, wenn der Ist-Stand dem Stand aus Prod vom 21.10.2026 entspricht.
-- Ein zweiter Lauf ändert nichts. In der CI fehlen die Aufgaben, alle Updates treffen null Zeilen.
-- Kein begin/commit: mig klammert mit psql -1.

do $rf2$
declare
  v_n integer;
  v_l integer := 0;
  v_a integer := 0;
begin
  -- 1a. Lösungen
  update public.task_solutions s
     set correct_answers = v.ca_neu,
         acceptance = (s.acceptance - 'unit') || jsonb_build_object('equivalents', v.ca_neu - (s.acceptance ->> 'canonical'))
    from (values
      ('54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid,
       '["12/25", "0,48", "0.48", "48 %", "48%", "48", "0,48 %", "0,48%", "0.48 %", "0.48%", "+0,48", "+0,48 %", "+0,48%", "+0.48", "+0.48 %", "+0.48%"]'::jsonb,
       '["12/25", "24/50", "48/100", "0,48", "0.48", "48 %", "48%", "+0,48", "+0.48"]'::jsonb),
      ('939baa76-0207-496c-a768-4df2988f7f12'::uuid,
       '["1/2", "2/4", "0,5", "0.5", "50 %", "50%", "50", "0,5 %", "0,5%", "0.5 %", "0.5%", "+0,5", "+0,5 %", "+0,5%", "+0.5", "+0.5 %", "+0.5%"]'::jsonb,
       '["1/2", "2/4", "50/100", "0,5", "0.5", "50 %", "50%", "+0,5", "+0.5"]'::jsonb)
    ) v(task_id, ca_alt, ca_neu)
   where s.task_id = v.task_id
     and s.correct_answers = v.ca_alt
     and s.acceptance -> 'equivalents' = v.ca_alt - (s.acceptance ->> 'canonical');
  get diagnostics v_n = row_count; v_l := v_l + v_n;

  -- 1b. Ausgangsfassung (Board-Vergleich)
  update public.task_pruefung_ausgang a
     set ausgang = jsonb_set(jsonb_set(a.ausgang, '{correct_answers}', v.ca_neu),
                             '{acceptance,equivalents}', v.ca_neu - (a.ausgang #>> '{acceptance,canonical}'))
    from (values
      ('54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid,
       '["12/25", "0,48", "0.48", "48 %", "48%", "48"]'::jsonb, '["12/25", "24/50", "48/100", "0,48", "0.48", "48 %", "48%"]'::jsonb),
      ('939baa76-0207-496c-a768-4df2988f7f12'::uuid,
       '["1/2", "2/4", "0,5", "0.5", "50 %", "50%", "50"]'::jsonb, '["1/2", "2/4", "50/100", "0,5", "0.5", "50 %", "50%"]'::jsonb)
    ) v(task_id, ca_alt, ca_neu)
   where a.task_id = v.task_id
     and a.ausgang -> 'correct_answers' = v.ca_alt
     and a.ausgang #> '{acceptance,equivalents}' = v.ca_alt - (a.ausgang #>> '{acceptance,canonical}');
  get diagnostics v_a = row_count;

  raise notice 'lena_rf_prozent: Lösungen % · Ausgangsfassung %', v_l, v_a;
end $rf2$;
