-- Aus der Migration A20 herausgelöst. Prüft gegen vorhandene Antwortdaten
-- und kann deshalb nicht Teil einer Migration sein.

do $$
declare
  v_admin   uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  v_skill   text; v_label text;
  v_soll    int; v_ist int; v_n int;
  v_task    uuid; v_alt_q text; v_status text;
  v_ready   uuid[]; v_ctrl boolean;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

  -- 1. status='beanstandet' angenommen, Altwerte weiter gueltig.
  select id into v_task from public.tasks where status = 'draft' limit 1;
  update public.tasks set status = 'beanstandet' where id = v_task;
  update public.tasks set status = 'draft' where id = v_task;   -- Altwert weiter gueltig
  update public.tasks set status = 'ready' where id = v_task;
  update public.tasks set status = 'review' where id = v_task;
  update public.tasks set status = 'draft' where id = v_task;
  raise notice 'P1 ok: beanstandet + draft/ready/review weiter gueltig';

  -- Ein Muster mit garantiert mehreren Treffern: Skill + Label mit >=2 Aufgaben.
  select t.skill_key, kv.value, count(*)
    into v_skill, v_label, v_soll
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    cross join lateral jsonb_each_text(
      case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
           then s.acceptance -> 'known_errors' else '{}'::jsonb end) as kv(key, value)
   where t.skill_key is not null
   group by t.skill_key, kv.value
   having count(*) >= 2
   order by count(*) desc
   limit 1;
  if v_skill is null then raise exception 'kein Muster mit >=2 Treffern gefunden'; end if;

  -- ready-Aufgaben VOR dem Muster festhalten (fuer P6).
  select array_agg(id) into v_ready from public.tasks where status = 'ready';

  -- 2. Muster trifft genau Skill UND Label; Rueckgabe == Anzahl.
  v_ist := public.lena_beanstande_muster(v_skill, v_label, 'fehlbild_falsch', 'Probe');
  if v_ist <> v_soll then
    raise exception 'P2 Rueckgabe %, erwartet % Treffer', v_ist, v_soll;
  end if;
  -- keine anderen: jede beanstandete Aufgabe MIT Review 'Probe' traegt Skill+Label.
  select count(*) into v_n
    from public.task_reviews r
    join public.tasks t on t.id = r.task_id
   where r.notiz = 'Probe'
     and (t.skill_key is distinct from v_skill
          or not exists (
            select 1 from public.task_solutions s
            cross join lateral jsonb_each_text(coalesce(s.acceptance -> 'known_errors','{}'::jsonb)) kv
             where s.task_id = t.id and kv.value = v_label));
  if v_n <> 0 then raise exception 'P2 % Beanstandungen ausserhalb Skill+Label', v_n; end if;
  raise notice 'P2 ok: Muster trifft genau %, Rueckgabe %', v_soll, v_ist;

  -- 3. Jede betroffene Aufgabe: genau eine task_reviews-Zeile (aus diesem Aufruf).
  select count(*) into v_n from (
    select r.task_id, count(*) c from public.task_reviews r
     where r.notiz = 'Probe' group by r.task_id having count(*) <> 1) x;
  if v_n <> 0 then raise exception 'P3 % Aufgaben mit != 1 Review-Zeile', v_n; end if;
  select count(*) into v_n from public.tasks
   where skill_key = v_skill and status = 'beanstandet';
  if v_n < v_soll then raise exception 'P3 nicht alle betroffenen beanstandet'; end if;
  raise notice 'P3 ok: je betroffene Aufgabe genau eine Review-Zeile';

  -- 4. Zahlenaenderung abgewiesen, Textaenderung geht durch.
  select id, question into v_task, v_alt_q from public.tasks
   where question ~ '\d' and status = 'draft' limit 1;
  v_ctrl := false;
  begin
    perform public.lena_text_aendern(v_task, v_alt_q || ' 999');   -- neue Zahl
    raise warning 'P4 Zahlenaenderung NICHT abgewiesen';
  exception when sqlstate '23514' then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P4 Zahlenaenderung ging durch'; end if;
  perform public.lena_text_aendern(v_task, v_alt_q || ' (bitte genau lesen)');  -- nur Text
  select question into v_status from public.tasks where id = v_task;
  if v_status <> v_alt_q || ' (bitte genau lesen)' then
    raise exception 'P4 Textaenderung nicht uebernommen';
  end if;
  raise notice 'P4 ok: Zahl abgewiesen, Text durch';

  -- 5. Textaenderung setzt status NICHT auf ready.
  select status into v_status from public.tasks where id = v_task;
  if v_status = 'ready' then raise exception 'P5 Textaenderung hat auf ready gesetzt'; end if;
  raise notice 'P5 ok: Text aendert Status nicht (%)', v_status;

  -- 6. Ein 'ready' ausserhalb des Filters bleibt unberuehrt.
  select count(*) into v_n from public.tasks
   where id = any (v_ready) and status <> 'ready'
     and (skill_key is distinct from v_skill
          or not exists (
            select 1 from public.task_solutions s
            cross join lateral jsonb_each_text(coalesce(s.acceptance -> 'known_errors','{}'::jsonb)) kv
             where s.task_id = tasks.id and kv.value = v_label));
  if v_n <> 0 then raise exception 'P6 % ready-Aufgaben ausserhalb Filter veraendert', v_n; end if;
  raise notice 'P6 ok: nicht passende ready-Aufgaben unberuehrt';

  -- 7. Negativkontrolle: der Harness MUSS bei falscher Erwartung abbrechen.
  v_ctrl := false;
  begin
    if (select count(*) from public.fehlbild_labels) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P7 Negativkontrolle hat nicht ausgeloest'; end if;
  raise notice 'P7 ok: Negativkontrolle greift';

  raise notice 'A20: ALLE 7 PRUEFUNGEN BESTANDEN';
end $$;
