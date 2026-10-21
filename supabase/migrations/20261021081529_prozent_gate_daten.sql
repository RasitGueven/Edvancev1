-- Prozent-Gate (M2, Daten; nach 20261021081417_prozent_gate): acht Wahrscheinlichkeitsentwürfe bereinigen.
--
-- Die Aufgaben führen die Prozentzahl ohne „%“ als richtige Antwort (z. B. „60“ bei 3/5). Seit #294 gilt das als
-- falsch; das neue Gate (prozentzahl_ohne_zeichen) hielte sie vor 'ready' auf. Entfernt wird die Zahl ohne „%“ aus
-- correct_answers und equivalents; „X/100“ wird ergänzt, wo es fehlt und X eine ganze Zahl ist. „X %“ und „X%“
-- stehen überall schon. Kein Wert kollidiert mit known_errors; known_errors bleiben unverändert.
--
--   15164236  weg: 62,5, 62.5
--   2b7059d7  weg: 65
--   d38afe88  weg: 40
--   7e7ce00a  weg: 60  dazu: 60/100
--   d1f84813  weg: 60  dazu: 60/100
--   8bc01e5b  weg: 36  dazu: 36/100
--   df337432  weg: 25  dazu: 25/100
--   3cb3aa9d  weg: 48,8, 48.8
--
-- Ausgelassen: 5bcca7e7 (Tombola, 20 %). Die Aufgabe verlangt „Gib das Ergebnis in Prozent an“, das Feld zeigt aber
-- kein „%“. Dort meint ein Kind mit „20“ 20 %; ob „20“ falsch werden soll oder das Feld „%“ bekommt, entscheidet Rasit.
--
-- Alle acht stehen im Entwurf, keine hat eine Prüfzeile von Lena; 3cb3aa9d ist im Pilot. 2b7059d7 und 7e7ce00a
-- haben eine Ausgangsfassung (schon geöffnet): Sie wird gleich nachgezogen, sonst meldet das Board die Bereinigung
-- als Änderung (Vorgehen wie L1 / #274). Status bleibt.
--
-- Compare-and-set: geändert wird nur, wenn correct_answers und equivalents dem Stand aus Prod vom 21.10.2026
-- entsprechen. Ein zweiter Lauf ändert nichts. In der CI fehlen die Aufgaben, alle Updates treffen null Zeilen.
-- Kein begin/commit: mig klammert mit psql -1.

do $pz2$
declare
  v_l integer;
  v_a integer;
begin
  update public.task_solutions s
     set correct_answers = v.ca_neu,
         acceptance = s.acceptance || jsonb_build_object('equivalents', v.ca_neu - (s.acceptance ->> 'canonical'))
    from (values
      ('15164236-c70e-4a67-a567-e8dbb080d7af'::uuid,
       '["5/8", "0,625", "0.625", "62,5 %", "62,5%", "62,5", "62.5 %", "62.5%", "62.5"]'::jsonb,
       '["5/8", "0,625", "0.625", "62,5 %", "62,5%", "62.5 %", "62.5%"]'::jsonb),
      ('2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid,
       '["0,65", "13/20", "65/100", "0.65", "65 %", "65%", "65"]'::jsonb,
       '["0,65", "13/20", "65/100", "0.65", "65 %", "65%"]'::jsonb),
      ('d38afe88-221f-43a3-a3ec-469ea309dc42'::uuid,
       '["2/5", "4/10", "8/20", "10/25", "16/40", "20/50", "40/100", "80/200", "0,4", "0.4", "40 %", "40%", "40"]'::jsonb,
       '["2/5", "4/10", "8/20", "10/25", "16/40", "20/50", "40/100", "80/200", "0,4", "0.4", "40 %", "40%"]'::jsonb),
      ('7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid,
       '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60"]'::jsonb,
       '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb),
      ('d1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid,
       '["3/5", "0,6", "0.6", "60 %", "60%", "60"]'::jsonb,
       '["3/5", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb),
      ('8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid,
       '["9/25", "0,36", "0.36", "36 %", "36%", "36"]'::jsonb,
       '["9/25", "0,36", "0.36", "36 %", "36%", "36/100"]'::jsonb),
      ('df337432-9db5-4a28-be26-e64132f93659'::uuid,
       '["1/4", "0,25", "0.25", "25 %", "25%", "25"]'::jsonb,
       '["1/4", "0,25", "0.25", "25 %", "25%", "25/100"]'::jsonb),
      ('3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid,
       '["0,488", "61/125", "122/250", "244/500", "488/1000", "0.488", "48,8 %", "48,8%", "48,8", "48.8 %", "48.8%", "48.8"]'::jsonb,
       '["0,488", "61/125", "122/250", "244/500", "488/1000", "0.488", "48,8 %", "48,8%", "48.8 %", "48.8%"]'::jsonb)
    ) v(task_id, ca_alt, ca_neu)
   where s.task_id = v.task_id
     and s.correct_answers = v.ca_alt
     and s.acceptance -> 'equivalents' = v.ca_alt - (s.acceptance ->> 'canonical');
  get diagnostics v_l = row_count;

  update public.task_pruefung_ausgang a
     set ausgang = jsonb_set(jsonb_set(a.ausgang, '{correct_answers}', v.ca_neu),
                             '{acceptance,equivalents}', v.ca_neu - (a.ausgang #>> '{acceptance,canonical}'))
    from (values
      ('2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid,
       '["0,65", "13/20", "65/100", "0.65", "65 %", "65%", "65"]'::jsonb,
       '["0,65", "13/20", "65/100", "0.65", "65 %", "65%"]'::jsonb),
      ('7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid,
       '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60"]'::jsonb,
       '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb)
    ) v(task_id, ca_alt, ca_neu)
   where a.task_id = v.task_id
     and a.ausgang -> 'correct_answers' = v.ca_alt
     and a.ausgang #> '{acceptance,equivalents}' = v.ca_alt - (a.ausgang #>> '{acceptance,canonical}');
  get diagnostics v_a = row_count;

  raise notice 'prozent_gate_daten: Lösungen % · Ausgangsfassung %', v_l, v_a;
end $pz2$;
