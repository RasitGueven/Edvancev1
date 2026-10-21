-- PRUEFUNG zum Prozent-Gate (Teil 2 nach #294):
--   M1 20261021081417_prozent_gate, M2 20261021081529_prozent_gate_daten.
--
--   ~/bin/dbread -f supabase/checks/prozent_gate.PRUEFUNG.sql
--
-- Nur Lesezugriffe (läuft in der read-only-Sitzung von dbread), ein do-Block, jede Abweichung ist ein
-- raise exception. Nach M1 aufrufen. P3 richtet sich nach dem Stand: alter Stand der acht Entwürfe → Hinweis
-- „M2 steht aus“, neuer Stand → wird geprüft. P2 verlangt den Stand nach M2.

do $p$
declare
  r      record;
  v_n    integer;
  v_m    text[];
  v_st   text;
  v_neu  integer;
  v_alt  integer;
begin
  -- ── 1. Die Regeln ─────────────────────────────────────────────────────────
  for r in
    select * from (values
      ('%',  '{"canonical":"12"}',                      '["12","12 %"]',          'prozent_ohne_marker'),
      ('%',  '{"canonical":"3","unit":"%"}',            '["3","3 %"]',            null),
      ('%',  null,                                       '["10"]',                 null),
      (null, '{"canonical":"3/5"}',                     '["3/5","0,6","60 %","60"]', 'prozentzahl_ohne_zeichen'),
      (null, '{"canonical":"3/5","equivalents":["60"]}', '["3/5"]',               'prozentzahl_ohne_zeichen'),
      (null, '{"canonical":"20 %"}',                    '["20 %","0,2","20"]',    'prozentzahl_ohne_zeichen'),
      (null, '{"canonical":"0,488"}',                   '["0,488","48,8"]',       'prozentzahl_ohne_zeichen'),
      (null, '{"canonical":"3/5"}',                     '["3/5","0,6","60 %","60%","60/100"]', null),
      (null, '{"canonical":"20 %"}',                    '["20 %","0,2","20/100"]', null),
      (null, '{"canonical":"0,5 m"}',                   '["0,5 m","50"]',         null),
      (null, '{"canonical":"0"}',                       '["0"]',                  null),
      (null, '{"canonical":"3","unit":"%"}',            '["3","300"]',            null)
    ) v(unit, acc, ca, soll)
  loop
    v_st := public.prozent_gate_fehler(r.unit, r.acc::jsonb, r.ca::jsonb);
    if v_st is distinct from r.soll then
      raise exception 'P1 prozent_gate_fehler(%, %, %) = %, erwartet %', r.unit, r.acc, r.ca, v_st, r.soll;
    end if;
  end loop;
  if not exists (select 1 from pg_proc where proname = 'freigabe_gate_fehler' and prosrc like '%prozent_gate_fehler(%') then
    raise exception 'P1 freigabe_gate_fehler ruft prozent_gate_fehler nicht auf';
  end if;
  raise notice 'P1 ok: prozent_ohne_marker, prozentzahl_ohne_zeichen, Prozentsatz mit Marker und andere Einheiten frei';

  -- ── 3. Die neun Entwürfe ──────────────────────────────────────────────────
  select count(*) filter (where s.correct_answers = v.neu), count(*) filter (where s.correct_answers is distinct from v.neu)
    into v_neu, v_alt
    from (values
        ('15164236-c70e-4a67-a567-e8dbb080d7af'::uuid, '["5/8", "0,625", "0.625", "62,5 %", "62,5%", "62.5 %", "62.5%"]'::jsonb, '["62,5", "62.5"]'::jsonb),
        ('2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid, '["0,65", "13/20", "65/100", "0.65", "65 %", "65%"]'::jsonb, '["65"]'::jsonb),
        ('d38afe88-221f-43a3-a3ec-469ea309dc42'::uuid, '["2/5", "4/10", "8/20", "10/25", "16/40", "20/50", "40/100", "80/200", "0,4", "0.4", "40 %", "40%"]'::jsonb, '["40"]'::jsonb),
        ('7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid, '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb, '["60"]'::jsonb),
        ('d1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid, '["3/5", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb, '["60"]'::jsonb),
        ('8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid, '["9/25", "0,36", "0.36", "36 %", "36%", "36/100"]'::jsonb, '["36"]'::jsonb),
        ('df337432-9db5-4a28-be26-e64132f93659'::uuid, '["1/4", "0,25", "0.25", "25 %", "25%", "25/100"]'::jsonb, '["25"]'::jsonb),
        ('3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid, '["0,488", "61/125", "122/250", "244/500", "488/1000", "0.488", "48,8 %", "48,8%", "48.8 %", "48.8%"]'::jsonb, '["48,8", "48.8"]'::jsonb)
    ) v(id, neu, weg)
    join public.task_solutions s on s.task_id = v.id;
  if v_neu + v_alt = 0 then
    raise notice 'P3 übersprungen: die acht Entwürfe fehlen (CI)';
  elsif v_neu = 0 then
    raise notice 'P3 M2 steht aus (% Entwürfe im alten Stand)', v_alt;
  elsif v_alt > 0 then
    raise exception 'P3 gemischter Stand: % bereinigt, % nicht', v_neu, v_alt;
  else
    for r in
      select t.id, t.input_type, t.status, s.acceptance a, s.correct_answers ca, v.weg, x.ausgang
        from (values
        ('15164236-c70e-4a67-a567-e8dbb080d7af'::uuid, '["5/8", "0,625", "0.625", "62,5 %", "62,5%", "62.5 %", "62.5%"]'::jsonb, '["62,5", "62.5"]'::jsonb),
        ('2b7059d7-e6f1-46a6-98bf-4ba1dbe57768'::uuid, '["0,65", "13/20", "65/100", "0.65", "65 %", "65%"]'::jsonb, '["65"]'::jsonb),
        ('d38afe88-221f-43a3-a3ec-469ea309dc42'::uuid, '["2/5", "4/10", "8/20", "10/25", "16/40", "20/50", "40/100", "80/200", "0,4", "0.4", "40 %", "40%"]'::jsonb, '["40"]'::jsonb),
        ('7e7ce00a-733b-404a-88fe-b41cf327f2f5'::uuid, '["3/5", "6/10", "12/20", "24/40", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb, '["60"]'::jsonb),
        ('d1f84813-9f5b-43ec-8e69-f3d566cffb09'::uuid, '["3/5", "0,6", "0.6", "60 %", "60%", "60/100"]'::jsonb, '["60"]'::jsonb),
        ('8bc01e5b-acf8-4808-a6ef-ce19acb8ea77'::uuid, '["9/25", "0,36", "0.36", "36 %", "36%", "36/100"]'::jsonb, '["36"]'::jsonb),
        ('df337432-9db5-4a28-be26-e64132f93659'::uuid, '["1/4", "0,25", "0.25", "25 %", "25%", "25/100"]'::jsonb, '["25"]'::jsonb),
        ('3cb3aa9d-a6ad-4bbb-9c1a-703b9868241f'::uuid, '["0,488", "61/125", "122/250", "244/500", "488/1000", "0.488", "48,8 %", "48,8%", "48.8 %", "48.8%"]'::jsonb, '["48,8", "48.8"]'::jsonb)
        ) v(id, neu, weg)
        join public.tasks t on t.id = v.id
        join public.task_solutions s on s.task_id = t.id
        left join public.task_pruefung_ausgang x on x.task_id = t.id
    loop
      if r.status <> 'draft' then raise exception 'P3 % Status % statt draft', r.id, r.status; end if;
      if r.a -> 'equivalents' is distinct from r.ca - (r.a ->> 'canonical') then
        raise exception 'P3 % equivalents passen nicht zu correct_answers', r.id;
      end if;
      if r.ausgang is not null and (r.ausgang -> 'correct_answers' is distinct from r.ca
           or r.ausgang #> '{acceptance,equivalents}' is distinct from r.ca - (r.a ->> 'canonical')) then
        raise exception 'P3 % Ausgangsfassung nicht nachgezogen', r.id;
      end if;
      v_m := array(select x from jsonb_array_elements_text(r.ca) x
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', x)) <> 'voll'
                       or not public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x)));
      if cardinality(v_m) > 0 then raise exception 'P3 % richtige Antworten nicht richtig: %', r.id, v_m; end if;
      v_m := array(select x from jsonb_array_elements_text(r.weg) x
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', x)) <> 'nicht'
                       or public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x)));
      if cardinality(v_m) > 0 then raise exception 'P3 % entfernte Werte nicht falsch: %', r.id, v_m; end if;
      v_m := array(select k from jsonb_object_keys(case when jsonb_typeof(r.a -> 'known_errors') = 'object'
                                                        then r.a -> 'known_errors' else '{}' end) k
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', k)) = 'voll'
                       or public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', k)));
      if cardinality(v_m) > 0 then raise exception 'P3 % Fehlerwerte richtig: %', r.id, v_m; end if;
    end loop;
    raise notice 'P3 ok: acht Entwürfe bereinigt, Status draft, Ausgangsfassung nachgezogen, Wertung stimmt';
  end if;

  -- ── 2. Bestand gegen das Gate ─────────────────────────────────────────────
  select count(*) into v_n from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.status = 'ready' and public.prozent_gate_fehler(t.unit, s.acceptance, s.correct_answers) is not null;
  if v_n <> 0 then raise exception 'P2 % freigegebene Aufgabe(n) verstoßen gegen das Prozent-Gate', v_n; end if;
  if v_neu > 0 then
    v_m := array(select left(t.id::text, 8) || ' ' || public.prozent_gate_fehler(t.unit, s.acceptance, s.correct_answers)
                   from public.tasks t join public.task_solutions s on s.task_id = t.id
                  where public.prozent_gate_fehler(t.unit, s.acceptance, s.correct_answers) is not null);
    -- 5bcca7e7 ist bewusst ausgelassen („in Prozent“ gefragt, Feld ohne %), Entwurf; Entscheidung steht aus.
    v_m := array(select x from unnest(v_m) x where x not like '5bcca7e7 %');
    if cardinality(v_m) > 0 then raise exception 'P2 Aufgaben verstoßen gegen das Prozent-Gate: %', v_m; end if;
    raise notice 'P2 ok: keine Aufgabe verstößt gegen das Prozent-Gate außer der ausgelassenen 5bcca7e7 (Entwurf)';
  else
    raise notice 'P2 ok: keine freigegebene Aufgabe verstößt gegen das Prozent-Gate (Bestand ohne M2 nicht geprüft)';
  end if;
end $p$;
