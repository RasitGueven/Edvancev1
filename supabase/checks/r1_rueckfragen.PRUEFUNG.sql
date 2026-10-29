-- PRUEFUNG zu R1 vom 29.10.2026 (Lenas Rückfragen): 20261029091200_r1_lena_rueckfragen und tools/r1-freigeben.sql.
-- Einordnung: docs/rueckfragen/R1/einordnung.md
--
--   ~/bin/dbread -f supabase/checks/r1_rueckfragen.PRUEFUNG.sql
--
-- Nur Lesezugriffe, ein do-Block, jede Abweichung ist ein raise exception. Nach der Migration aufrufen. Der Teil zur
-- Freigabe richtet sich nach dem Stand: A/B alle 'rueckfrage' → Freigabe steht aus (Hinweis), alle 'ready' → wird
-- geprüft, gemischt → Fehler.

do $p$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  c_ab    constant uuid[] := array['8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24', 'ffc76634-86ca-4c53-b816-d18d7f868443',
                                   '158c874c-248c-40ed-b8b5-af3eb627517a', '6274f6a5-65e5-40f4-be09-36fa8931c424'];
  c_c     constant uuid[] := array['a61e8be9-b55f-4c43-9971-7b74e3d55a33', '1bbce78e-f996-4c03-a78a-09b47f5c7445'];
  r    record;
  x    text;
  v_n  integer;
  v_ready integer;
begin
  -- ── 1. Neue Fassung kommt beim Kind an ──────────────────────────────────────
  if public.lsa_question_payload('8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24') ->> 'prompt' is distinct from
     E'Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?' then
    raise exception 'P1 lsa_question_payload 8c4a2d71 liefert nicht die neue Fassung';
  end if;
  raise notice 'P1 ok: lsa_question_payload 8c4a2d71 neu';

  -- ── 2. known_errors: Anzahl und neue Schlüssel ──────────────────────────────
  for r in
    select e.id, e.soll_n, e.neu, (select count(*) from jsonb_object_keys(s.acceptance -> 'known_errors')) ist_n,
           s.acceptance -> 'known_errors' ke
      from (values
        ('ffc76634-86ca-4c53-b816-d18d7f868443'::uuid, 15,
         '{"-18": "koordinaten_vertauscht", "6": "steigung_kehrwert", "0,67": "steigung_kehrwert", "2/3": "steigung_kehrwert"}'::jsonb),
        ('6274f6a5-65e5-40f4-be09-36fa8931c424', 42,
         '{"60": "teilflaeche_vergessen", "+30cm²": "teilflaeche_vergessen", "65 cm²": "falsche_hoehe", "156": "falsche_hoehe", "240": "halbieren_vergessen"}'),
        ('8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24', 3, '{"1021": "quadratdifferenz_vorzeichen"}')
      ) e(id, soll_n, neu)
      join public.task_solutions s on s.task_id = e.id
  loop
    if r.ist_n <> r.soll_n or not r.ke @> r.neu then
      raise exception 'P2 known_errors % hat % Schlüssel (erwartet %) oder es fehlt etwas aus %', r.id, r.ist_n, r.soll_n, r.neu;
    end if;
  end loop;
  raise notice 'P2 ok: known_errors in ffc76634 (15), 6274f6a5 (42), 8c4a2d71 (3)';

  -- ── 3. Wertung über die echten Funktionen ───────────────────────────────────
  -- Richtig in den üblichen Schreibweisen: lsa_antwort_korrekt (correct) und lsa_grade = voll, kein Fehlbild.
  for r in
    select t.id, t.input_type, public.lsa_question_payload(t.id) ->> 'input_hint' hint, s.correct_answers ca,
           s.acceptance acc, e.ein
      from (values
        ('8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid, array['1029', ' 1029 ', '+1029']),
        ('ffc76634-86ca-4c53-b816-d18d7f868443', array['-2', '−2', '- 2']),
        ('6274f6a5-65e5-40f4-be09-36fa8931c424', array['120', '+120', '120 cm²', '120cm²', '+120 cm²'])
      ) e(id, ein)
      join public.tasks t on t.id = e.id join public.task_solutions s on s.task_id = t.id
  loop
    foreach x in array r.ein loop
      if not public.lsa_antwort_korrekt(r.input_type, r.hint, r.ca, jsonb_build_object('text', x))
         or public.lsa_grade(r.input_type, r.acc, r.ca, jsonb_build_object('text', x), r.hint) <> 'voll'
         or public.lsa_fehlbild_match(r.input_type, r.acc -> 'known_errors', jsonb_build_object('text', x)) is not null then
        raise exception 'P3 % richtige Antwort „%“ nicht korrekt/voll oder mit Fehlbild', r.id, x;
      end if;
    end loop;
    -- Jeder Fehlerschlüssel: nicht korrekt, nicht voll, trifft genau sein Fehlbild.
    for x in select k from jsonb_object_keys(r.acc -> 'known_errors') k loop
      if public.lsa_antwort_korrekt(r.input_type, r.hint, r.ca, jsonb_build_object('text', x))
         or public.lsa_grade(r.input_type, r.acc, r.ca, jsonb_build_object('text', x), r.hint) = 'voll'
         or public.lsa_fehlbild_match(r.input_type, r.acc -> 'known_errors', jsonb_build_object('text', x))
            is distinct from r.acc -> 'known_errors' ->> x then
        raise exception 'P3 % Fehlerwert „%“ korrekt/voll oder trifft nicht %', r.id, x, r.acc -> 'known_errors' ->> x;
      end if;
    end loop;
  end loop;
  -- Getippte Varianten der neuen Fehler (Punkt statt Komma, typografisches Minus) treffen ebenfalls.
  for r in
    select * from (values
      ('ffc76634-86ca-4c53-b816-d18d7f868443'::uuid, '0.67', 'steigung_kehrwert'),
      ('ffc76634-86ca-4c53-b816-d18d7f868443', '−18', 'koordinaten_vertauscht'),
      ('6274f6a5-65e5-40f4-be09-36fa8931c424', '60 cm²', 'teilflaeche_vergessen'),
      ('6274f6a5-65e5-40f4-be09-36fa8931c424', '156cm²', 'falsche_hoehe')) v(id, ein, slug)
  loop
    if (select public.lsa_fehlbild_match(t.input_type, s.acceptance -> 'known_errors', jsonb_build_object('text', r.ein))
          from public.tasks t join public.task_solutions s on s.task_id = t.id where t.id = r.id) is distinct from r.slug then
      raise exception 'P3 % „%“ trifft nicht %', r.id, r.ein, r.slug;
    end if;
  end loop;
  -- B: beide Teile von 158c874c richtig, auch mit „+“.
  for r in select * from (values (1, '5'), (1, '+5'), (2, '3'), (2, '+3')) v(nr, ein) loop
    if (select not public.lsa_antwort_korrekt('NUMERIC', 'number', s.correct_answers -> r.nr::text, jsonb_build_object('text', r.ein))
               or public.lsa_grade('NUMERIC', s.acceptance -> r.nr::text, s.correct_answers -> r.nr::text,
                                   jsonb_build_object('text', r.ein)) <> 'voll'
          from public.task_solutions s where s.task_id = '158c874c-248c-40ed-b8b5-af3eb627517a') then
      raise exception 'P3 158c874c Teil % „%“ nicht richtig', r.nr, r.ein;
    end if;
  end loop;
  raise notice 'P3 ok: richtige Antworten korrekt und voll, jeder Fehlerwert trifft sein Fehlbild';

  -- ── 4. Gate, Einsatz, typical_errors-Slugs ──────────────────────────────────
  for r in select t.id, public.freigabe_gate_fehler(t.id) g, t.einsatz from public.tasks t
            where t.id = any(c_ab || c_c) loop
    if r.g is not null then raise exception 'P4 Gate % : %', r.id, r.g; end if;
    if r.einsatz is distinct from '{lsa}'::text[] then raise exception 'P4 einsatz % ist %', r.id, r.einsatz; end if;
  end loop;
  select count(*) into v_n
    from public.task_solutions s, jsonb_array_elements(s.typical_errors) te
   where s.task_id = any(c_ab)
     and not exists (select 1 from public.fehlbild_labels l where l.slug = te ->> 'fehlbild');
  if v_n > 0 then raise exception 'P4 % typical_errors mit unbekanntem Fehlbild', v_n; end if;
  select count(*) into v_n from (
    select s.task_id, te ->> 'fehlbild' from public.task_solutions s, jsonb_array_elements(s.typical_errors) te
     where s.task_id = any(c_ab) group by 1, 2 having count(*) > 1) d;
  if v_n > 0 then raise exception 'P4 % Fehlbild(er) doppelt in typical_errors', v_n; end if;
  if (select count(*) from public.tasks where id = any(c_ab || c_c)) <> 6 then raise exception 'P4 Aufgabe fehlt'; end if;
  raise notice 'P4 ok: Gate null, einsatz {lsa}, alle Fehlbilder bekannt';

  -- ── 5. Freigabe ─────────────────────────────────────────────────────────────
  if exists (select 1 from public.tasks where id = any(c_c) and status <> 'rueckfrage') then
    raise exception 'P5 Klasse C nicht mehr rueckfrage';
  end if;
  select count(*) filter (where status = 'ready'), count(*) filter (where status = 'rueckfrage') into v_ready, v_n
    from public.tasks where id = any(c_ab);
  if v_n = 4 then
    raise notice 'P5 Hinweis: Freigabe steht aus (A/B noch rueckfrage, C rueckfrage)';
  elsif v_ready = 4 then
    for r in
      select t.id,
             (select p.antwort is not null and p.beantwortet_von = c_rasit from public.task_pruefungen p
               where p.task_id = t.id order by p.geprueft_am desc limit 1) antwort_ok,
             exists (select 1 from public.task_admin_protokoll a where a.task_id = t.id
                      and a.aktion = 'rueckfrage_freigeben' and a.von = c_rasit) prot_ok,
             t.reviewed_by = c_rasit rev_ok
        from public.tasks t where t.id = any(c_ab)
    loop
      if not (coalesce(r.antwort_ok, false) and r.prot_ok and coalesce(r.rev_ok, false)) then
        raise exception 'P5 % antwort % / protokoll % / reviewed_by %', r.id, r.antwort_ok, r.prot_ok, r.rev_ok;
      end if;
    end loop;
    raise notice 'P5 ok: A/B ready, Antwort und Protokoll von Rasit; C bleibt rueckfrage';
  else
    raise exception 'P5 gemischter Stand: % ready, % rueckfrage', v_ready, v_n;
  end if;
end $p$;
