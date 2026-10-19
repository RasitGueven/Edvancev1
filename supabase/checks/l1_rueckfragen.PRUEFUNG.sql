-- PRUEFUNG zu L1 (Lenas Rückfragen vom 19.10.2026):
--   M1 20261019100100_l1_lena_fehlbilder, M2 20261019100200_l1_lena_rueckfragen_freigeben.
--
--   ~/bin/dbread -f supabase/checks/l1_rueckfragen.PRUEFUNG.sql
--
-- Nur Lesezugriffe (läuft in der read-only-Sitzung von dbread), ein do-Block, jede Abweichung ist ein
-- raise exception. Nach M1 aufrufen. Der M2-Teil richtet sich nach dem Stand der acht Rückfragen:
-- alle acht noch 'rueckfrage' → M2 steht aus (Hinweis), alle acht 'ready' → M2 wird geprüft, gemischt → Fehler.

do $p$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  c_frage constant text := E'Wie viele der Zahlen 1, 2, 3, …, 60 haben eine Quadratwurzel, die eine rationale Zahl ist?\n\nGib die Anzahl als ganze Zahl an.';
  r       record;
  v_n     integer;
  v_ready integer;
  v_rf    integer;
  v_m     text[];
begin
  -- ── 1. Neue Fehlbilder und Familien ─────────────────────────────────────────
  select count(*) into v_n
    from public.fehlbild_familien f
   where f.freigegeben_am is not null
     and (f.schluessel, f.elterntext) in (
       ('plus_minus_vertauscht', 'Beim Rechnen mit negativen Zahlen geht Ihr Kind auf dem Zahlenstrahl manchmal in die falsche Richtung: Aus einem Plus wird ein Minus oder umgekehrt.'),
       ('merksatz_als_addition', 'Ihr Kind kennt die Regel ‚Minus mal Minus ergibt Plus‘, wendet sie aber als Rechenanweisung an und addiert die Zahlen, statt sie zu multiplizieren.'));
  if v_n <> 2 then raise exception 'P1 Familien: % von 2 mit Elterntext und Freigabe', v_n; end if;

  select count(*) into v_n
    from public.fehlbild_labels l
   where l.freigegeben_am is not null
     and nullif(btrim(coalesce(l.erklaerung, '')), '') is not null
     and (l.slug, l.familie, l.klartext) in (
       ('plus_minus_vertauscht', 'plus_minus_vertauscht', 'Plus und Minus vertauscht, auf dem Zahlenstrahl in die falsche Richtung gegangen.'),
       ('merksatz_als_addition', 'merksatz_als_addition', '„Minus mal Minus gibt Plus“ als Rechenanweisung missverstanden und addiert.'));
  if v_n <> 2 then raise exception 'P1 Fehlbilder: % von 2 mit Klartext, Erklärung, Familie und Freigabe', v_n; end if;

  -- Der belegte Slug richtung_vertauscht (Maßstab) ist unverändert.
  if not exists (select 1 from public.fehlbild_labels where slug = 'richtung_vertauscht' and familie = 'einheiten_massstab') then
    raise exception 'P1 richtung_vertauscht (Maßstab) verändert';
  end if;
  raise notice 'P1 ok: zwei Familien und zwei Fehlbilder, freigegeben';

  -- ── 2. known_errors je Aufgabe, auch in der Ausgangsfassung ────────────────
  select count(*) into v_n from public.tasks where skill_key in ('vorzeichen_add_sub', 'vorzeichen_mult_div');
  if v_n <> 14 then raise exception 'P2 erwartet 14 Aufgaben in beiden Fertigkeiten, gefunden %', v_n; end if;

  for r in
    select e.id, e.soll, s.acceptance -> 'known_errors' as ist, a.ausgang -> 'acceptance' -> 'known_errors' as aus
      from (values
        ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid, '{"2": "plus_minus_vertauscht", "8": "betrag_fehler", "-2": "vorzeichen_ignoriert", "15": "mult_add_verwechslung"}'::jsonb),
        ('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid, '{"-5": "betrag_fehler", "13": "vorzeichen_ignoriert", "-13": "plus_minus_vertauscht", "-36": "mult_add_verwechslung"}'),
        ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, '{"4": "vorzeichen_ignoriert", "8": "betrag_fehler", "-4": "plus_minus_vertauscht", "12": "mult_add_verwechslung"}'),
        ('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0'::uuid, '{"3": "betrag_fehler", "11": "vorzeichen_ignoriert", "-11": "plus_minus_vertauscht", "-28": "mult_add_verwechslung"}'),
        ('3b44eada-3589-4bdb-a33b-2fb2ca0a1726'::uuid, '{"4": "betrag_fehler", "14": "vorzeichen_ignoriert", "-14": "plus_minus_vertauscht", "-45": "mult_add_verwechslung"}'),
        ('3e6fb055-111e-4888-9177-d2b17dd0fc54'::uuid, '{"7": "betrag_fehler", "11": "vorzeichen_ignoriert", "-18": "mult_add_verwechslung"}'),
        ('738de19f-d3c9-43a0-b5ce-af6e30752c75'::uuid, '{"5": "betrag_fehler", "11": "vorzeichen_ignoriert", "-24": "mult_add_verwechslung"}'),
        ('38aa9504-bb48-4b1c-98e7-85d38de70108'::uuid, '{"5": "vorzeichen_ignoriert", "-16": "mult_add_verwechslung"}'),
        ('0438a9f9-bdb4-4f29-ab59-adc7946ade36'::uuid, '{"2": "mult_add_verwechslung", "15": "vorzeichen_ignoriert"}'),
        ('7db70449-d6fa-47dd-9423-1e8c75ce8c8f'::uuid, '{"-6": "vorzeichen_ignoriert", "-42": "mult_add_verwechslung"}'),
        ('2e8ce53f-1357-48b2-8d76-0633ae836980'::uuid, '{"2": "merksatz_als_addition", "-10": "mult_add_verwechslung", "-24": "vorzeichen_ignoriert"}'),
        ('e58cb290-db86-40df-b60b-03aee393107b'::uuid, '{"-5": "merksatz_als_addition", "-11": "mult_add_verwechslung", "-24": "vorzeichen_ignoriert"}'),
        ('751f9c63-c295-4b9e-8202-6244c6fd8f05'::uuid, '{"6": "vorzeichen_ignoriert", "20": "mult_add_verwechslung"}'),
        ('ba0701ff-bac1-4ae6-a6f4-b5f610a35ee7'::uuid, '{"4": "mult_add_verwechslung", "21": "vorzeichen_ignoriert"}')
      ) e(id, soll)
      left join public.task_solutions s on s.task_id = e.id
      left join public.task_pruefung_ausgang a on a.task_id = e.id
  loop
    if r.ist is distinct from r.soll then
      raise exception 'P2 known_errors % ist %, erwartet %', r.id, r.ist, r.soll;
    end if;
    if r.aus is not null and r.aus is distinct from r.soll then
      raise exception 'P2 Ausgangsfassung % ist %, erwartet %', r.id, r.aus, r.soll;
    end if;
  end loop;
  raise notice 'P2 ok: known_errors der 14 Aufgaben wie erwartet, Ausgangsfassung gleich';

  -- ── 3. Regeln unabhängig von der Liste nachgerechnet ───────────────────────
  for r in
    select t.id, t.skill_key, t.question, s.correct_answers, s.acceptance,
           regexp_match(t.question, '^Berechne\.\s+(-?\d+) ([-+:·]) \(?(-?\d+)\)? = \?$') as m
      from public.tasks t join public.task_solutions s on s.task_id = t.id
     where t.skill_key in ('vorzeichen_add_sub', 'vorzeichen_mult_div')
  loop
    if r.m is null then raise exception 'P3 % Aufgabentext unerwartet: %', r.id, r.question; end if;
    -- betrag_fehler: gleicher Betrag, umgekehrtes Vorzeichen
    for v_m in select array[k.key] from jsonb_each_text(r.acceptance -> 'known_errors') k where k.value = 'betrag_fehler' loop
      if v_m[1]::numeric <> -(r.acceptance ->> 'canonical')::numeric then
        raise exception 'P3 % betrag_fehler „%“ passt nicht zu canonical %', r.id, v_m[1], r.acceptance ->> 'canonical';
      end if;
    end loop;
    -- keine Kollision mit canonical, equivalents, correct_answers
    select count(*) into v_n
      from jsonb_object_keys(r.acceptance -> 'known_errors') k
     where public.lsa_normalize_answer(k) = public.lsa_normalize_answer(r.acceptance ->> 'canonical')
        or public.lsa_normalize_answer(k) in (select public.lsa_normalize_answer(x) from jsonb_array_elements_text(coalesce(r.acceptance -> 'equivalents', '[]')) x)
        or public.lsa_normalize_answer(k) in (select public.lsa_normalize_answer(x) from jsonb_array_elements_text(coalesce(r.correct_answers, '[]')) x);
    if v_n > 0 then raise exception 'P3 % known_errors kollidiert mit einer richtigen Antwort', r.id; end if;
    -- Richtungsfehler: a ± b mit positivem b ohne Klammer → a ∓ b steht als Schlüssel (unter einem Fehlbild)
    if r.skill_key = 'vorzeichen_add_sub' and r.m[2] in ('+', '-') and r.question !~ '\(' then
      if not (r.acceptance -> 'known_errors') ? (case when r.m[2] = '+' then r.m[1]::int - r.m[3]::int
                                                       else r.m[1]::int + r.m[3]::int end)::text then
        raise exception 'P3 % Richtungsfehler fehlt', r.id;
      end if;
    end if;
    -- Merksatz: (−a) · (−b) → −a + b unter merksatz_als_addition; sonst nirgends
    if r.skill_key = 'vorzeichen_mult_div' and r.m[2] = '·' and r.m[1]::int < 0 and r.m[3]::int < 0 then
      if (r.acceptance -> 'known_errors' ->> (r.m[1]::int - r.m[3]::int)::text) is distinct from 'merksatz_als_addition' then
        raise exception 'P3 % Merksatz-Fehler fehlt', r.id;
      end if;
    elsif exists (select 1 from jsonb_each_text(r.acceptance -> 'known_errors') k where k.value = 'merksatz_als_addition') then
      raise exception 'P3 % trägt merksatz_als_addition ohne zwei negative Faktoren', r.id;
    end if;
  end loop;
  select count(*) into v_n
    from public.task_solutions s, jsonb_each_text(s.acceptance -> 'known_errors') k
   where k.value in ('plus_minus_vertauscht', 'merksatz_als_addition');
  if v_n <> 7 then raise exception 'P3 neue Fehlbilder % Mal eingetragen, erwartet 7', v_n; end if;
  raise notice 'P3 ok: betrag_fehler-Regel, keine Kollision, Richtungs- und Merksatzfehler nachgerechnet';

  -- ── 4. Aufgabentext 0b7e781c ────────────────────────────────────────────────
  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
     and t.question = c_frage and t.question_payload ->> 'prompt' = c_frage
     and t.afb = 'II' and t.est_duration_sec = 90
     and t.title = 'Irrational · rationale Wurzeln von 1 bis 60'
     and s.correct_answers = '["7", "+7"]'::jsonb and s.acceptance ->> 'canonical' = '7'
     and s.solution !~ '(^|[^[:alpha:]])n([^[:alpha:]]|$)'
     and s.solution like '%1, 4, 9, 16, 25, 36, 49%Anzahl: 7.';
  if v_n <> 1 then raise exception 'P4 Aufgabentext/Lösung 0b7e781c nicht wie erwartet'; end if;
  raise notice 'P4 ok: Aufgabentext ohne n, Lösung, Titel, AFB II und 90 s unverändert';

  -- ── 5. M2: die acht Rückfragen ──────────────────────────────────────────────
  select count(*) filter (where t.status = 'ready'), count(*) filter (where t.status = 'rueckfrage')
    into v_ready, v_rf
    from public.tasks t
   where t.id in ('17674b19-fe14-42ca-98db-6598fa8c5a3a', '27f51c08-6a47-4ceb-b189-f5f07cbcf1cf',
                  '3b44eada-3589-4bdb-a33b-2fb2ca0a1726', 'c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0',
                  '2e8ce53f-1357-48b2-8d76-0633ae836980', '7db70449-d6fa-47dd-9423-1e8c75ce8c8f',
                  'e58cb290-db86-40df-b60b-03aee393107b', '0b7e781c-60ae-4a93-afb8-2ee2b400b15a');
  if v_rf = 8 then
    raise notice 'P5 M2 steht aus: alle acht Rückfragen noch offen';
  elsif v_ready = 8 then
    select count(*) into v_n
      from public.tasks t
      join lateral (select * from public.task_pruefungen p where p.task_id = t.id order by p.geprueft_am desc limit 1) p on true
     where t.status = 'ready' and t.reviewed_by = c_rasit and t.reviewed_at is not null
       and p.beantwortet_von = c_rasit and p.beantwortet_am is not null
       and p.antwort = case
         when t.id in ('17674b19-fe14-42ca-98db-6598fa8c5a3a', '3b44eada-3589-4bdb-a33b-2fb2ca0a1726', 'c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0')
           then 'Danke, übernommen! Den Richtungsfehler (Plus und Minus vertauscht) haben wir als eigenes Fehlerbild angelegt und bei allen Aufgaben dieser Fertigkeit ergänzt.'
         when t.id = '27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'
           then 'Du hattest recht, die Zuordnung war falsch: Die 8 ist jetzt ‚Betrag richtig, Vorzeichen gekippt‘, die 4 ‚Vorzeichen der ersten Zahl übersehen‘. Die −4 haben wir als Richtungsfehler ergänzt, auch bei allen anderen Aufgaben dieser Fertigkeit.'
         when t.id in ('2e8ce53f-1357-48b2-8d76-0633ae836980', 'e58cb290-db86-40df-b60b-03aee393107b')
           then 'Danke, übernommen! ‚Minus mal Minus gibt Plus, dann addiert‘ ist jetzt ein eigenes Fehlerbild, ergänzt bei allen Multiplikationen mit zwei negativen Zahlen.'
         when t.id = '7db70449-d6fa-47dd-9423-1e8c75ce8c8f'
           then 'Danke für die Einordnung, sehen wir genauso. Bei der Division ergänzen wir den Fehler nicht.'
         when t.id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
           then 'Danke! Der Text ist jetzt ohne n formuliert, AFB II haben wir übernommen.'
       end
       and exists (select 1 from public.task_admin_protokoll x
                    where x.task_id = t.id and x.aktion = 'rueckfrage_freigeben' and x.von = c_rasit and x.grund = p.antwort)
       and not exists (select 1 from public.task_solutions s, jsonb_array_elements(coalesce(s.hints, '[]')) h
                        where s.task_id = t.id and coalesce(h ->> 'status', 'entwurf') <> 'geprueft')
       and public.freigabe_gate_fehler(t.id) is null
       and t.id in ('17674b19-fe14-42ca-98db-6598fa8c5a3a', '27f51c08-6a47-4ceb-b189-f5f07cbcf1cf',
                    '3b44eada-3589-4bdb-a33b-2fb2ca0a1726', 'c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0',
                    '2e8ce53f-1357-48b2-8d76-0633ae836980', '7db70449-d6fa-47dd-9423-1e8c75ce8c8f',
                    'e58cb290-db86-40df-b60b-03aee393107b', '0b7e781c-60ae-4a93-afb8-2ee2b400b15a');
    if v_n <> 8 then raise exception 'P5 nur % von 8 Rückfragen vollständig beantwortet und freigegeben', v_n; end if;
    raise notice 'P5 ok: acht Rückfragen ready, Antwort, beantwortet_von, Protokoll, Hinweise geprueft';
  else
    raise exception 'P5 gemischter Stand: % ready, % rueckfrage', v_ready, v_rf;
  end if;
end $p$;
