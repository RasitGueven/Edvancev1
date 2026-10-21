-- PRUEFUNG zu Lenas Rückfrage vom 20.10.2026 (54f5e1df, Prozent-Schreibweisen):
--   M1 20261021073327_lsa_grade_prozent_faktor, M2 20261021073637_lena_rf_prozent_schreibweisen,
--   M3 20261021073713_lena_rf_an_lena.
--
--   ~/bin/dbread -f supabase/checks/lena_rf_prozent.PRUEFUNG.sql
--
-- Nur Lesezugriffe (läuft in der read-only-Sitzung von dbread), ein do-Block, jede Abweichung ist ein
-- raise exception. Nach M1 aufrufen. M2 und M3 richten sich nach dem Stand: alter Stand → Hinweis
-- „steht aus“, neuer Stand → wird geprüft.

do $p$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  c_urne  constant uuid := '54f5e1df-adc9-4fa3-b9c1-c15301c29cbe';
  c_muenze constant uuid := '939baa76-0207-496c-a768-4df2988f7f12';
  c_antwort constant text := 'Danke dir, du hast völlig recht: 0,48 % und 12/25 % sind nicht dasselbe wie 48 %. Wir haben das so umgestellt, dass bei Prozent nur noch 48 % zählt (12/25 und 0,48 sind natürlich weiter richtig). Auch 48 ohne Prozentzeichen zählt nicht mehr, denn das wäre 48 und nicht 0,48. Denselben Fehler haben wir bei der Münz-Aufgabe (50 %) gefunden und mitkorrigiert. Wenn Rot und Blau vertauscht werden, kommt hier immer dasselbe Ergebnis heraus: In jedem Weg werden dieselben zwei Zahlen malgenommen, nur in anderer Reihenfolge. Deshalb können wir diesen Fehler an der Antwort leider nicht erkennen. Zu deinem zweiten Beispiel: Welches Endergebnis würde ein Kind da typischerweise eintippen, wenn es die Gesamtzahl übersieht? Dann nehmen wir es als typischen Fehler auf.';
  r       record;
  v_n     integer;
  v_m2    boolean;
  v_st    text;
  v_m     text[];
begin
  -- ── 1. lsa_grade: % als Faktor, Prozentsatz-Ausnahme ─────────────────────────
  for r in
    select * from (values
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '12/25',      'voll'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '0,48',       'voll'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '48 %',       'voll'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '48%',        'voll'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '48 Prozent', 'voll'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '0,48 %',     'nicht'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '12/25 %',    'nicht'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '48',         'nicht'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '0,48 Prozent', 'nicht'),
      ('{"canonical":"12/25","equivalents":["0,48","48 %"]}', '4800 %',     'nicht'),
      ('{"canonical":"48 %"}',                                '0,0048',     'nicht'),
      ('{"canonical":"48 %"}',                                '0,48',       'voll'),
      ('{"canonical":"-0,5"}',                                '-50 %',      'voll'),
      ('{"canonical":"1/2"}',                                 '+50 %',      'voll'),
      ('{"canonical":"1 1/2"}',                               '150 %',      'voll'),
      -- Prozentsatz (acceptance.unit = '%'): wie bisher, „3“ und „3 %“ sind dasselbe, 0,03 nicht.
      ('{"canonical":"3","equivalents":["3 %"],"unit":"%"}',  '3',          'voll'),
      ('{"canonical":"3","equivalents":["3 %"],"unit":"%"}',  '3 %',        'voll'),
      ('{"canonical":"3","equivalents":["3 %"],"unit":"%"}',  '0,03',       'nicht'),
      -- Andere Einheiten unverändert.
      ('{"canonical":"12 cm"}',                               '12',         'voll'),
      ('{"canonical":"12 €"}',                                '12 €',       'voll'),
      -- unit_graded mit canonical „20 %“: 0,2 ist der richtige Wert in falscher Form, 20 ist falsch.
      ('{"canonical":"20 %","unit_graded":true}',             '20 %',       'voll'),
      ('{"canonical":"20 %","unit_graded":true}',             '0,2',        'teilweise'),
      ('{"canonical":"20 %","unit_graded":true}',             '20',         'nicht')
    ) v(acc, eingabe, soll)
  loop
    v_st := public.lsa_grade('NUMERIC', r.acc::jsonb, '[]'::jsonb, jsonb_build_object('text', r.eingabe));
    if v_st is distinct from r.soll then
      raise exception 'P1 lsa_grade(%, „%“) = %, erwartet %', r.acc, r.eingabe, v_st, r.soll;
    end if;
  end loop;
  -- pruef_einheit: abgeleitetes % ist keine Einheit mehr, ausdrückliches schon.
  if public.pruef_einheit('{"canonical":"12/25"}', '["12/25","48 %"]') is not null
     or public.pruef_einheit('{"canonical":"20 %"}', '[]') is not null
     or public.pruef_einheit('{"canonical":"3","unit":"%"}', '["3"]') is distinct from '%'
     or public.pruef_einheit('{"canonical":"12 cm"}', '[]') is distinct from 'cm' then
    raise exception 'P1 pruef_einheit: abgeleitetes %% nicht leer bzw. Einheiten falsch';
  end if;
  -- Prozentsatz-Marker (M1, Datenteil): jede vorhandene der sechs Aufgaben trägt acceptance.unit = '%'.
  select count(*) filter (where s.acceptance ->> 'unit' is distinct from '%') into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.id in ('2d5e6e81-1f81-462c-8b70-db43a7454bb4', '86f705e2-6364-4749-8faf-c031e6bf7110',
                  'e059539e-120d-428b-ba3d-c11ae9c4a83d', '9031703f-4b09-41be-a1a3-6a0b55bc0603',
                  'f91618d9-3bbf-4b57-8901-8f898829fdef', '52d18200-7696-4bed-bba7-352cbb35436c');
  if v_n <> 0 then raise exception 'P1 Prozentsatz-Marker fehlt bei % Aufgabe(n)', v_n; end if;
  if exists (select 1 from public.tasks t join public.task_solutions s on s.task_id = t.id
              where t.unit = '%' and jsonb_typeof(s.acceptance) = 'object' and s.acceptance ? 'canonical'
                and s.acceptance ->> 'unit' is distinct from '%') then
    raise exception 'P1 Aufgabe mit %% am Antwortfeld ohne Prozentsatz-Marker';
  end if;
  raise notice 'P1 ok: lsa_grade wertet %% als Faktor, Prozentsatz-Ausnahme und andere Einheiten wie bisher, pruef_einheit, Prozentsatz-Marker';

  -- ── 2. Daten 54f5e1df / 939baa76 ──────────────────────────────────────────
  select s.correct_answers = '["12/25", "24/50", "48/100", "0,48", "0.48", "48 %", "48%", "+0,48", "+0.48"]'::jsonb into v_m2
    from public.task_solutions s where s.task_id = c_urne;
  if v_m2 is null then
    raise notice 'P2 übersprungen: 54f5e1df nicht vorhanden (CI)';
  elsif not v_m2 then
    raise notice 'P2 M2 steht aus';
  else
    select count(*) into v_n
      from public.task_solutions s
      join (values
        (c_urne,   '["12/25", "24/50", "48/100", "0,48", "0.48", "48 %", "48%", "+0,48", "+0.48"]'::jsonb),
        (c_muenze, '["1/2", "2/4", "50/100", "0,5", "0.5", "50 %", "50%", "+0,5", "+0.5"]'::jsonb)) v(id, ca) on v.id = s.task_id
     where s.correct_answers = v.ca
       and s.acceptance -> 'equivalents' = v.ca - (s.acceptance ->> 'canonical')
       and not s.acceptance ? 'unit';
    if v_n <> 2 then raise exception 'P2 correct_answers/equivalents: % von 2', v_n; end if;

    -- Jede richtige Schreibweise ist richtig, jede falsche falsch, jeder Fehlerwert falsch – in beiden Wertungen.
    for r in
      select t.id, t.input_type, s.acceptance a, s.correct_answers ca, v.richtig, v.falsch
        from public.tasks t join public.task_solutions s on s.task_id = t.id
        join (values
          (c_urne,   array['12/25', '24/50', '48/100', '0,48', '0.48', '48 %', '48%', '+0,48'],
                     array['0,48 %', '0,48%', '12/25 %', '12/25%', '48', '+0,48 %', '0.48 %']),
          (c_muenze, array['1/2', '2/4', '50/100', '0,5', '0.5', '50 %', '50%', '+0,5'],
                     array['0,5 %', '0,5%', '1/2 %', '1/2%', '50', '+0,5 %', '0.5 %'])) v(id, richtig, falsch) on v.id = t.id
    loop
      v_m := array(select x from unnest(r.richtig) x
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', x)) <> 'voll'
                       or not public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x)));
      if cardinality(v_m) > 0 then raise exception 'P2 % richtige Schreibweisen nicht richtig: %', r.id, v_m; end if;
      v_m := array(select x from unnest(r.falsch) x
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', x)) <> 'nicht'
                       or public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x)));
      if cardinality(v_m) > 0 then raise exception 'P2 % falsche Schreibweisen nicht falsch: %', r.id, v_m; end if;
      v_m := array(select k from jsonb_object_keys(r.a -> 'known_errors') k
                    where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', k)) <> 'nicht'
                       or public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', k))
                       or public.lsa_fehlbild_match('numeric', r.a -> 'known_errors', jsonb_build_object('text', k))
                          is distinct from r.a -> 'known_errors' ->> k);
      if cardinality(v_m) > 0 then raise exception 'P2 % Fehlerwerte kollidieren: %', r.id, v_m; end if;
    end loop;

    -- Ausgangsfassung von 939baa76 nachgezogen (54f5e1df hat nach M3 keine mehr).
    if exists (select 1 from public.task_pruefung_ausgang a where a.task_id in (c_urne, c_muenze)
                and (a.ausgang -> 'correct_answers' ? '48' or a.ausgang -> 'correct_answers' ? '50'
                     or a.ausgang #> '{acceptance,equivalents}' ? '48' or a.ausgang #> '{acceptance,equivalents}' ? '50')) then
      raise exception 'P2 Ausgangsfassung enthält noch 48 bzw. 50';
    end if;
    if exists (select 1 from public.task_solutions s
                where s.task_id in (c_urne, c_muenze) and public.pruef_einheit(s.acceptance, s.correct_answers) is not null) then
      raise exception 'P2 pruef_einheit bei 54f5e1df/939baa76 nicht leer';
    end if;

    raise notice 'P2 ok: 54f5e1df und 939baa76 bereinigt, Fehlerwerte ohne Kollision, Ausgangsfassung';
  end if;

  -- ── 3. Abnahme: alle Aufgaben mit Prozent-Schreibweisen ──────────────────
  -- Jede richtige Antwort ist 'voll', kein Fehlerwert ist 'voll'.
  v_n := 0;
  for r in
    select t.id, t.input_type, s.acceptance a, s.correct_answers ca
      from public.tasks t join public.task_solutions s on s.task_id = t.id
     where t.input_type not in ('MC', 'TERM', 'MULTI_PART')
       and jsonb_typeof(s.acceptance) = 'object' and s.acceptance ? 'canonical'
       and jsonb_typeof(s.correct_answers) = 'array'
       and (s.acceptance::text like '%\%%' or s.correct_answers::text like '%\%%' or t.unit = '%')
  loop
    v_n := v_n + 1;
    v_m := array(select x from jsonb_array_elements_text(r.ca) x
                  where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', x)) <> 'voll');
    if cardinality(v_m) > 0 then raise exception 'P3 % richtige Antworten nicht voll: %', r.id, v_m; end if;
    v_m := array(select k from jsonb_object_keys(case when jsonb_typeof(r.a -> 'known_errors') = 'object'
                                                      then r.a -> 'known_errors' else '{}' end) k
                  where public.lsa_grade(r.input_type, r.a, r.ca, jsonb_build_object('text', k)) = 'voll');
    if cardinality(v_m) > 0 then raise exception 'P3 % Fehlerwerte voll: %', r.id, v_m; end if;
  end loop;
  raise notice 'P3 ok: % Aufgaben mit Prozent-Schreibweisen, richtige Antworten voll, Fehlerwerte nicht voll', v_n;

  -- ── 4. Rückfrage an Lena zurück (M3) ──────────────────────────────────────
  select status into v_st from public.tasks where id = c_urne;
  if v_st is null then
    raise notice 'P4 übersprungen: 54f5e1df nicht vorhanden (CI)';
  elsif v_st = 'rueckfrage' then
    raise notice 'P4 M3 steht aus';
  else
    select count(*) into v_n
      from public.tasks t
      join lateral (select * from public.task_pruefungen p where p.task_id = t.id order by p.geprueft_am desc limit 1) p on true
     where t.id = c_urne and t.status = 'draft' and t.reviewed_by is null and t.reviewed_at is null
       and p.entscheidung = 'unsicher' and p.antwort = c_antwort
       and p.beantwortet_von = c_rasit and p.beantwortet_am is not null
       and not exists (select 1 from public.task_pruefung_ausgang a where a.task_id = t.id)
       and exists (select 1 from public.task_admin_protokoll x
                    where x.task_id = t.id and x.aktion = 'rueckfrage_an_lena' and x.von = c_rasit and x.grund = c_antwort);
    if v_n <> 1 then raise exception 'P4 54f5e1df nicht vollständig an Lena zurückgegeben (Status %)', v_st; end if;
    raise notice 'P4 ok: 54f5e1df draft, Antwort, beantwortet_von Rasit, Ausgangsfassung weg, Protokoll';
  end if;
end $p$;
