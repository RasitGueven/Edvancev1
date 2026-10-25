-- PRUEFUNG zu L1 vom 25.10.2026 (Lenas Rückfragen): 20261025143853_lena_rueckmeldungen_1025 und die elf Antworten
-- über pruef_rueckfrage_klaeren. Auswertung: docs/lsa/lena-rueckmeldungen-2026-10-25.md
--
--   ~/bin/dbread -f supabase/checks/l1b_rueckfragen.PRUEFUNG.sql
--
-- Nur Lesezugriffe, ein do-Block, jede Abweichung ist ein raise exception. Nach der Migration aufrufen. Der Teil zu
-- den Antworten richtet sich nach dem Stand: alle elf 'rueckfrage' → Antworten stehen aus (Hinweis), alle elf
-- geklärt → wird geprüft, gemischt → Fehler.

do $p$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  r    record;
  x    text;
  v_n  integer;
  v_rf integer;
begin
  -- ── 1. known_errors: genau der erwartete Stand ──────────────────────────────
  for r in
    select e.id, e.soll, s.acceptance -> 'known_errors' as ist
      from (values
        ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24'::uuid,
         '{"2": "vorrang_ignoriert", "-14": "plus_minus_vertauscht", "-11": "plus_minus_vertauscht", "11": "vorzeichen_ignoriert"}'::jsonb),
        ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f'::uuid,
         '{"0,34": "ziffern_gelesen", "1,3": "umgekehrt_geteilt", "1,33": "umgekehrt_geteilt", "1,333": "umgekehrt_geteilt", "4/3": "umgekehrt_geteilt"}')
      ) e(id, soll)
      left join public.task_solutions s on s.task_id = e.id
  loop
    if r.ist is distinct from r.soll then raise exception 'P1 known_errors % ist %, erwartet %', r.id, r.ist, r.soll; end if;
  end loop;
  raise notice 'P1 ok: known_errors in a394b2eb und 6ef85b4a wie erwartet';

  -- ── 2. Wertung direkt: richtig bleibt voll, jeder Fehlerwert trifft sein Fehlbild ──
  for r in
    select t.id, t.input_type, s.correct_answers ca, s.acceptance acc
      from public.tasks t join public.task_solutions s on s.task_id = t.id
     where t.id in ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', '6ef85b4a-1f14-49b4-acf6-05aa01567e4f',
                    '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', 'e8348c89-67cb-4650-be91-235e69321776',
                    '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992')
  loop
    for x in select jsonb_array_elements_text(r.ca) loop
      if public.lsa_grade(r.input_type, r.acc, r.ca, jsonb_build_object('text', x)) <> 'voll'
         or not public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x))
         or public.lsa_fehlbild_match(r.input_type, r.acc -> 'known_errors', jsonb_build_object('text', x)) is not null then
        raise exception 'P2 % richtige Antwort „%“ nicht voll oder mit Fehlbild', r.id, x;
      end if;
    end loop;
    for x in select k from jsonb_object_keys(r.acc -> 'known_errors') k loop
      if public.lsa_grade(r.input_type, r.acc, r.ca, jsonb_build_object('text', x)) = 'voll'
         or public.lsa_is_correct(r.input_type, r.ca, jsonb_build_object('text', x))
         or public.lsa_fehlbild_match(r.input_type, r.acc -> 'known_errors', jsonb_build_object('text', x))
            is distinct from r.acc -> 'known_errors' ->> x then
        raise exception 'P2 % Fehlerwert „%“ wird voll gewertet oder trifft nicht %', r.id, x, r.acc -> 'known_errors' ->> x;
      end if;
    end loop;
  end loop;
  -- Gegenbeispiele ohne Fehlbild bleiben falsch und ohne Fehlbild.
  for r in
    select * from (values
      ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24'::uuid, '-7'), ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', '14'),
      ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', '0,7'),('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', '1,34'),
      ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', '75')) g(id, wert)
  loop
    select count(*) into v_n from public.tasks t join public.task_solutions s on s.task_id = t.id
     where t.id = r.id and not public.lsa_is_correct(t.input_type, s.correct_answers, jsonb_build_object('text', r.wert))
       and public.lsa_fehlbild_match(t.input_type, s.acceptance -> 'known_errors', jsonb_build_object('text', r.wert)) is null;
    if v_n <> 1 then raise exception 'P2 Gegenbeispiel % „%“ richtig oder mit Fehlbild', r.id, r.wert; end if;
  end loop;
  raise notice 'P2 ok: richtige Antworten voll, sieben neue Fehlerwerte mit Fehlbild, Gegenbeispiele ohne';

  -- ── 3. TERM: Hinweise da, acceptance weiter leer, Wertung unverändert ──────
  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.input_type = 'TERM' and s.acceptance is null
     and ((t.id = '1527a939-6199-4d8c-9163-6f34b0cd0e13' and jsonb_array_length(s.typical_errors) = 1
           and s.typical_errors -> 0 ->> 'error' like '%3x + 2 statt 3x + 6%'
           and public.lsa_is_correct('TERM', s.correct_answers, '{"text": "3x+6"}')
           and not public.lsa_is_correct('TERM', s.correct_answers, '{"text": "3x+2"}'))
       or (t.id = '10a764bc-9657-4a5a-b11d-64b2a0014b05' and jsonb_array_length(s.typical_errors) = 2
           and s.typical_errors::text like '%−3x + 2 statt%' and s.typical_errors::text like '%−3x + 6 statt%'
           and t.question like 'Multipliziere aus. Gib das Ergebnis in der Form ax + b an.%'
           and public.lsa_is_correct('TERM', s.correct_answers, '{"text": "-3x-6"}')
           and not public.lsa_is_correct('TERM', s.correct_answers, '{"text": "-3x+2"}')
           and not public.lsa_is_correct('TERM', s.correct_answers, '{"text": "-3x+6"}')))
     and not exists (select 1 from jsonb_array_elements(s.typical_errors) e where e ? 'fehlbild');
  if v_n <> 2 then raise exception 'P3 TERM-Hinweise: % von 2 wie erwartet', v_n; end if;
  raise notice 'P3 ok: TERM-Hinweise ohne Slug, Wertung unverändert';

  -- ── 4. Texte ────────────────────────────────────────────────────────────────
  select count(*) into v_n from public.tasks t
   where (t.id = '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'
          and t.question = E'Berechne geschickt mit Hilfe einer binomischen Formel.\n\n49² = ?'
          and t.question_payload ->> 'prompt' = t.question)
      or (t.id = 'e8348c89-67cb-4650-be91-235e69321776' and t.question = E'Löse die Gleichung.\n\n2x + 4 = 20'
          and t.question_payload ->> 'prompt' = t.question)
      or (t.id = '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992' and t.question = E'Löse die Gleichung.\n\n3x + 6 = 24'
          and t.question_payload ->> 'prompt' = t.question)
      or (t.id = '4f0b933d-3ead-4042-adb9-a1369ba28f39'
          and t.parts -> 1 ->> 'prompt' = 'Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?'
          and t.parts -> 0 ->> 'prompt' = 'Welche Gleichung passt zu dieser Situation?'
          and t.question = 'Ein Handytarif kostet 10 € Grundgebühr im Monat. Jedes Gigabyte kostet zusätzlich 5 €. Die Rechnung beträgt 45 €.'
          and jsonb_array_length(t.parts) = 2);
  if v_n <> 4 then raise exception 'P4 Texte: % von 4 wie erwartet', v_n; end if;
  raise notice 'P4 ok: vier Aufgabentexte';

  -- ── 5. Antworten an Lena ────────────────────────────────────────────────────
  create temp table l1b_soll (id uuid primary key, status text not null) on commit drop;
  insert into l1b_soll values
    ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', 'ready'), ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'ready'),
    ('19ba5f42-6cd4-4191-afe0-fd8a09c4ac35', 'ready'), ('1527a939-6199-4d8c-9163-6f34b0cd0e13', 'ready'),
    ('10a764bc-9657-4a5a-b11d-64b2a0014b05', 'ready'), ('df219b8c-887d-43c2-b544-ca2df4f32e66', 'ready'),
    ('650eed2a-79e5-4a6f-9ed2-a51053fe75c8', 'ready'),
    ('3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', 'draft'), ('4f0b933d-3ead-4042-adb9-a1369ba28f39', 'draft'),
    ('e8348c89-67cb-4650-be91-235e69321776', 'draft'), ('7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992', 'draft');
  select count(*) filter (where t.status = 'rueckfrage') into v_rf from l1b_soll z join public.tasks t on t.id = z.id;
  if v_rf = 11 then
    raise notice 'P5 Antworten stehen aus: alle elf Rückfragen offen';
  else
    select count(*) into v_n
      from l1b_soll z join public.tasks t on t.id = z.id
      join lateral (select * from public.task_pruefungen p where p.task_id = t.id order by p.geprueft_am desc limit 1) p on true
     where t.status = z.status and p.entscheidung = 'unsicher' and p.geprueft_am::date = '2026-10-25'
       and p.beantwortet_von = c_rasit and p.beantwortet_am is not null and length(p.antwort) > 20
       and (z.status = 'ready') = exists (select 1 from public.task_pruefung_ausgang a where a.task_id = t.id)
       and (z.status <> 'ready' or public.freigabe_gate_fehler(t.id) is null);
    if v_n <> 11 then raise exception 'P5 nur % von 11 Rückfragen wie erwartet geklärt (gemischt: % offen)', v_n, v_rf; end if;
    raise notice 'P5 ok: 7 freigegeben (Ausgangsfassung bleibt), 4 an Lena (Ausgangsfassung weg), elf Antworten von Rasit';
  end if;
end $p$;
