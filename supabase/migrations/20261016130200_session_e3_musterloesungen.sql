-- Session E3: Musterlösungen für gleichung_einschrittig (6), gleichung_zweischrittig (6) und term_ausklammern (6),
-- dazu acceptance mit einem Fehlbild je Ablenker für term_ausklammern. Erzeugt von tools/session-e3-rechencheck.py
-- (dort Rechen-Check mit sympy) — nicht von Hand editieren.
--
-- Nur leere Felder: solution nur, wenn leer; acceptance nur, wenn NULL (term_ausklammern hat keine). Hinweise bleiben
-- unberührt, status bleibt draft. tasks.vorbefuellt bekommt den Schlüssel solution, wenn er fehlt.
-- Bei term_ausklammern wird nur geschrieben, wenn die Optionen noch die Texte tragen, gegen die gerechnet wurde, und
-- correct_answers die richtige Option ist.
-- Neue Slugs (ausklammern_nicht_ggt, ausklammern_glied_nicht_geteilt, ausklammern_falsch_geteilt) mit Klartext, nicht freigegeben.
-- Fehlen die Aufgaben (CI-Neuaufbau), passiert nichts. Kein begin/commit: mig klammert mit psql -1.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('ausklammern_nicht_ggt', 'gleichungen_umformen', 'Klammert einen gemeinsamen Teiler aus, aber nicht den größten: 8x + 12 = 2(4x + 6).',
   'Ausklammern „so weit wie möglich“ heißt: den größten gemeinsamen Teiler vor die Klammer ziehen. Wer einen kleineren Teiler nimmt, rechnet richtig, ist aber nicht fertig – in der Klammer steckt noch ein gemeinsamer Faktor. Geübt wird, nach dem Ausklammern zu prüfen, ob die Zahlen in der Klammer noch einen Teiler teilen.'),
  ('ausklammern_glied_nicht_geteilt', 'gleichungen_umformen', 'Klammert den Faktor aus, lässt das zweite Glied aber unverändert in der Klammer: 4x + 8 = 4(x + 8).',
   'Beim Ausklammern wird jedes Glied durch den ausgeklammerten Faktor geteilt. Wer das zweite Glied stehen lässt, bekommt beim Ausmultiplizieren nicht mehr den Ausgangsterm zurück. Geübt wird die Probe durch Ausmultiplizieren.'),
  ('ausklammern_falsch_geteilt', 'gleichungen_umformen', 'Klammert den richtigen Faktor aus, teilt das zweite Glied aber durch eine andere Zahl: 6x + 12 = 6(x + 4).',
   'Vor der Klammer steht ein Faktor, in der Klammer muss jedes Glied durch genau diesen Faktor geteilt sein. Wer das zweite Glied durch eine andere Zahl teilt, etwa durch die Hälfte, bekommt beim Ausmultiplizieren einen anderen Term. Geübt wird die Probe durch Ausmultiplizieren.')
on conflict (slug) do nothing;

do $session_e3$
declare
  v_l integer; v_a integer; v_v integer;
begin
  create temp table e3_neu (task_id uuid, loesung text, acc jsonb, texte jsonb) on commit drop;
  insert into e3_neu values
  ('bfd877b9-cd3e-490c-82ad-0274b4f85a8b'::uuid, 'x + 7 = 12 | − 7
x = 5.', null::jsonb, null::jsonb),
  ('4f6f7cdd-3415-4185-8eae-95083d061b71'::uuid, 'x − 4 = 9 | + 4
x = 13.', null::jsonb, null::jsonb),
  ('152bcdcd-897b-452b-9a8f-402375540a3f'::uuid, '3x = 18 | : 3
x = 6.', null::jsonb, null::jsonb),
  ('d19c8070-85d9-44cc-b4cc-eac3e06010d0'::uuid, 'x + 12 = 20 | − 12
x = 8.', null::jsonb, null::jsonb),
  ('6fc6928a-6ae3-4c32-9c2e-b9a20451b97c'::uuid, 'x − 9 = 6 | + 9
x = 15.', null::jsonb, null::jsonb),
  ('fbd28765-b198-4ff6-bdbe-de9ccc5202de'::uuid, '4x = 24 | : 4
x = 6.', null::jsonb, null::jsonb),
  ('7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992'::uuid, '3x + 6 = 24 | − 6
3x = 18 | : 3
x = 6.', null::jsonb, null::jsonb),
  ('e8348c89-67cb-4650-be91-235e69321776'::uuid, '2x + 4 = 20 | − 4
2x = 16 | : 2
x = 8.', null::jsonb, null::jsonb),
  ('9d15a93e-961b-4569-be8b-c4482dc98301'::uuid, '5x + 10 = 45 | − 10
5x = 35 | : 5
x = 7.', null::jsonb, null::jsonb),
  ('b01451c0-53e5-4da7-9591-280448264835'::uuid, '4x + 8 = 40 | − 8
4x = 32 | : 4
x = 8.', null::jsonb, null::jsonb),
  ('17f3e728-2249-42ba-b5bf-c2a4b344dd00'::uuid, '3x + 9 = 30 | − 9
3x = 21 | : 3
x = 7.', null::jsonb, null::jsonb),
  ('ff5710af-0c0a-47e5-9a57-b2a5bb4ef82d'::uuid, '6x + 12 = 42 | − 12
6x = 30 | : 6
x = 5.', null::jsonb, null::jsonb),
  ('4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af'::uuid, 'Der größte gemeinsame Teiler von 4 und 8 ist 4.
4x + 8 = 4 · x + 4 · 2 = 4(x + 2).', '{"canonical":"d","known_errors":{"a":"ausklammern_nicht_ggt","b":"ausklammern_glied_nicht_geteilt","c":"ausklammern_falsch_geteilt"}}'::jsonb, '{"a":"2(2x + 4)","b":"4(x + 8)","c":"4(x + 4)","d":"4(x + 2)"}'::jsonb),
  ('65841bd8-ee27-454f-b2a4-ea6f1bb0db33'::uuid, 'Der größte gemeinsame Teiler von 6 und 12 ist 6.
6x + 12 = 6 · x + 6 · 2 = 6(x + 2).', '{"canonical":"c","known_errors":{"a":"ausklammern_glied_nicht_geteilt","b":"ausklammern_falsch_geteilt","d":"ausklammern_nicht_ggt"}}'::jsonb, '{"a":"6(x + 12)","b":"6(x + 4)","d":"3(2x + 4)","c":"6(x + 2)"}'::jsonb),
  ('81f97d0e-1e95-4bbd-bc6a-d05149786c58'::uuid, 'Der größte gemeinsame Teiler von 4 und 20 ist 4.
4x + 20 = 4 · x + 4 · 5 = 4(x + 5).', '{"canonical":"b","known_errors":{"a":"ausklammern_falsch_geteilt","c":"ausklammern_nicht_ggt","d":"ausklammern_glied_nicht_geteilt"}}'::jsonb, '{"a":"4(x + 10)","c":"2(2x + 10)","d":"4(x + 20)","b":"4(x + 5)"}'::jsonb),
  ('b15b6be0-1b87-477d-bd88-23b095501581'::uuid, 'Der größte gemeinsame Teiler von 9 und 27 ist 9.
9x + 27 = 9 · x + 9 · 3 = 9(x + 3).', '{"canonical":"a","known_errors":{"b":"ausklammern_nicht_ggt","c":"ausklammern_glied_nicht_geteilt","d":"ausklammern_falsch_geteilt"}}'::jsonb, '{"b":"3(3x + 9)","c":"9(x + 27)","d":"9(x + 9)","a":"9(x + 3)"}'::jsonb),
  ('ea237a07-681d-4680-bcd0-d94316c899e9'::uuid, 'Der größte gemeinsame Teiler von 8 und 12 ist 4.
8x + 12 = 4 · 2x + 4 · 3 = 4(2x + 3).', '{"canonical":"d","known_errors":{"a":"ausklammern_nicht_ggt","b":"ausklammern_glied_nicht_geteilt","c":"ausklammern_falsch_geteilt"}}'::jsonb, '{"a":"2(4x + 6)","b":"4(2x + 12)","c":"4(2x + 6)","d":"4(2x + 3)"}'::jsonb),
  ('02b24419-d7e8-40b8-8b74-ef3b4e806b3f'::uuid, 'Der größte gemeinsame Teiler von 12 und 18 ist 6.
12x + 18 = 6 · 2x + 6 · 3 = 6(2x + 3).', '{"canonical":"c","known_errors":{"a":"ausklammern_glied_nicht_geteilt","b":"ausklammern_falsch_geteilt","d":"ausklammern_nicht_ggt"}}'::jsonb, '{"a":"6(2x + 18)","b":"6(2x + 6)","d":"3(4x + 6)","c":"6(2x + 3)"}'::jsonb);

  -- Nur Aufgaben, deren Optionen (bei MC) und richtige Antwort noch zum Rechen-Check passen.
  delete from e3_neu n
   where n.texte is not null
     and not exists (select 1 from public.tasks t join public.task_solutions s on s.task_id = t.id
                      where t.id = n.task_id and s.correct_answers = jsonb_build_array(n.acc ->> 'canonical')
                        and not exists (select 1 from jsonb_each_text(n.texte) e
                                         where not exists (select 1 from jsonb_array_elements(t.question_payload -> 'options') o
                                                            where o ->> 'id' = e.key and o ->> 'label' = e.value)));

  update public.task_solutions s set solution = n.loesung
    from e3_neu n where s.task_id = n.task_id and nullif(btrim(coalesce(s.solution, '')), '') is null;
  get diagnostics v_l = row_count;
  update public.task_solutions s set acceptance = n.acc
    from e3_neu n where s.task_id = n.task_id and n.acc is not null and s.acceptance is null;
  get diagnostics v_a = row_count;
  update public.tasks t set vorbefuellt = t.vorbefuellt || jsonb_build_object('solution', '{"art":"neu","grund":"Nachgerechnet (tools/session-e3-rechencheck.py, sympy).","charge":"session-e3-ml","sicher":"hoch"}'::jsonb)
    from e3_neu n where t.id = n.task_id and not (t.vorbefuellt ? 'solution')
     and exists (select 1 from public.task_solutions s where s.task_id = t.id and s.solution = n.loesung);
  get diagnostics v_v = row_count;
  raise notice 'session_e3: % Musterloesung(en), % acceptance, % vorbefuellt-Marke(n)', v_l, v_a, v_v;
end $session_e3$;
