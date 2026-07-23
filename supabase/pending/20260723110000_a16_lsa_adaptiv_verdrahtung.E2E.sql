-- A16 END-ZU-ENDE — ueber lsa_start / lsa_submit, im selben begin/…/rollback wie
-- die Migration. Impersoniert einen Admin (GUC) und macht die Fundament-Aufgaben
-- transaktionslokal 'ready', damit der adaptive Pool zieht. Alles Rollback.

-- Eine korrekte ('voll') Antwort zu einer Aufgabe bauen.
create function pg_temp.voll(p_task uuid) returns jsonb as $$
  select case when t.input_type = 'MC'
              then jsonb_build_object('selected', s.correct_answers)
              else jsonb_build_object('value', s.correct_answers ->> 0) end
  from tasks t join task_solutions s on s.task_id = t.id where t.id = p_task;
$$ language sql;

do $$
declare
  v_admin uuid;
  v_student uuid;
  r jsonb; r2 jsonb;
  sid uuid; cur uuid; nxt jsonb;
  v_probes int; v_n int; v_txt text; v_ctrl boolean;
  v_started timestamptz;
  v_fremd uuid; v_t1 uuid; v_t2 uuid; v_t3 uuid; v_items uuid[];
begin
  select id into v_admin from profiles where role='admin' limit 1;
  select id into v_student from students limit 1;

  -- Als Admin handeln (lsa_may_act_for -> true).
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

  -- Fundament freigeben (nur in dieser Transaktion).
  update tasks set status='ready' where source='edvance_fundament';

  -- ---- 1. Vollstaendige adaptive Sitzung, alles korrekt -------------------
  r := public.lsa_start(v_student, 13, 'A16-1', 'adaptiv', now());
  if r ? 'total_items' then raise exception 'P1 lsa_start(adaptiv) enthaelt total_items'; end if;
  if not (r ? 'session_id' and r ? 'item') then raise exception 'P1 Rueckgabe unvollstaendig'; end if;
  sid := (r ->> 'session_id')::uuid;
  cur := (r -> 'item' ->> 'task_id')::uuid;
  v_probes := 0;
  loop
    r2 := public.lsa_submit(sid, cur, pg_temp.voll(cur), 100, now());
    v_probes := v_probes + 1;
    nxt := r2 -> 'next';
    exit when nxt is null or nxt = 'null'::jsonb;
    cur := (nxt ->> 'task_id')::uuid;
    exit when v_probes >= 40;
  end loop;
  if v_probes < 2 then raise exception 'P1 nur % Aufgabe(n) — adaptiv soll nachladen', v_probes; end if;
  select count(*) into v_n from lsa_skill_urteil where session_id=sid;
  if v_n = 0 then raise exception 'P1 keine Urteile gebucht'; end if;
  select count(*) into v_n from lsa_responses r
    where r.session_id=sid and not exists (
      select 1 from lsa_ausgegeben a where a.session_id=sid and a.task_id=r.task_id);
  if v_n <> 0 then raise exception 'P1 % beantwortete Aufgaben ohne Ausgabe-Zeile', v_n; end if;
  raise notice 'P1 ok: % Aufgaben, Urteile gebucht, jede Antwort war ausgegeben', v_probes;

  -- ---- 2. Fremde task_id -> abgewiesen (Sicherheitsprobe) -----------------
  r := public.lsa_start(v_student, 13, 'A16-2', 'adaptiv', now());
  sid := (r ->> 'session_id')::uuid;
  select id into v_fremd from tasks
    where source='edvance_fundament' and id <> (r->'item'->>'task_id')::uuid
      and id not in (select task_id from lsa_ausgegeben where session_id=sid) limit 1;
  v_ctrl := false;
  begin
    perform public.lsa_submit(sid, v_fremd, '{"value":"1"}'::jsonb, 100, now());
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P2 fremde task_id wurde NICHT abgewiesen'; end if;
  raise notice 'P2 ok: nie ausgegebene task_id abgewiesen';

  -- ---- 3. Keine Wiederholung, auch bei Abbruch ----------------------------
  r := public.lsa_start(v_student, 13, 'A16-3', 'adaptiv', now());
  sid := (r ->> 'session_id')::uuid;
  v_t1 := (r -> 'item' ->> 'task_id')::uuid;               -- ausgegeben, NICHT beantwortet
  v_t2 := public.lsa_select_next_core(sid, array['ready'], now());
  if v_t2 = v_t1 then raise exception 'P3 gleiche Aufgabe trotz Ausgabe erneut gezogen'; end if;
  insert into lsa_ausgegeben(session_id, task_id) values (sid, v_t2);
  v_t3 := public.lsa_select_next_core(sid, array['ready'], now());
  if v_t3 in (v_t1, v_t2) then raise exception 'P3 dritte Ziehung wiederholt eine ausgegebene'; end if;
  raise notice 'P3 ok: keine ausgegebene Aufgabe wird erneut gezogen';

  -- ---- 4. Zeitende ueber die Uhr ------------------------------------------
  r := public.lsa_start(v_student, 13, 'A16-4', 'adaptiv', now());
  sid := (r ->> 'session_id')::uuid;
  cur := (r -> 'item' ->> 'task_id')::uuid;
  select started_at into v_started from lsa_sessions where id=sid;
  r2 := public.lsa_submit(sid, cur, pg_temp.voll(cur), 100, v_started + interval '20 minutes');
  if not (r2 -> 'next' is null or r2 -> 'next' = 'null'::jsonb) then
    raise exception 'P4 next nicht null nach Zeitablauf';
  end if;
  select count(distinct skill_key) into v_n from lsa_skill_urteil where session_id=sid;
  if v_n >= 32 then raise exception 'P4 alles gedeckt — Zeitende nicht aussagekraeftig'; end if;
  raise notice 'P4 ok: next null nach 20 min, obwohl nur % Skills gedeckt', v_n;

  -- ---- 5. Modus 'fest' unveraendert ---------------------------------------
  -- Der echte Test-Student kann eine bestehende Mathematik-Sitzung haben; der
  -- fest-Pool braucht subject='Mathematik'. Vorbestehende transaktionslokal
  -- schliessen (Rollback macht es rueckgaengig).
  update lsa_sessions set status='aborted'
    where student_id=v_student and subject='Mathematik' and status='in_progress';
  r := public.lsa_start(v_student, 13, 'Mathematik', 'fest', now());
  if not (r ? 'total_items') then raise exception 'P5 fest ohne total_items'; end if;
  sid := (r ->> 'session_id')::uuid;
  select modus into v_txt from lsa_sessions where id=sid;
  if v_txt <> 'fest' then raise exception 'P5 modus=%, erwartet fest', v_txt; end if;
  select coalesce(array_length(item_ids,1),0) into v_n from lsa_sessions where id=sid;
  if v_n = 0 then raise exception 'P5 fest ohne item_ids'; end if;
  -- item_ids-Gate aktiv: eine Aufgabe ausserhalb der Liste wird abgewiesen.
  select item_ids into v_items from lsa_sessions where id=sid;
  select id into v_fremd from tasks where source='edvance_fundament'
    and not (id = any(v_items)) limit 1;
  v_ctrl := false;
  begin perform public.lsa_submit(sid, v_fremd, '{"value":"1"}'::jsonb, 100, now());
  exception when others then v_ctrl := true; end;
  if not v_ctrl then raise exception 'P5 item_ids-Gate im fest-Modus inaktiv'; end if;
  raise notice 'P5 ok: fest unveraendert (total_items, item_ids-Gate)';

  -- ---- 6. Kein Zaehler in der adaptiven Rueckgabe -------------------------
  r := public.lsa_start(v_student, 13, 'A16-6', 'adaptiv', now());
  if r ? 'total_items' or r ? 'total' or r ? 'count' then
    raise exception 'P6 adaptive Rueckgabe traegt eine Aufgabenzahl';
  end if;
  raise notice 'P6 ok: adaptive Rueckgabe ohne Aufgabenzahl';

  -- ---- 7. Kein Leak in start/submit ---------------------------------------
  r := public.lsa_start(v_student, 13, 'A16-7', 'adaptiv', now());
  sid := (r ->> 'session_id')::uuid;
  cur := (r -> 'item' ->> 'task_id')::uuid;
  r2 := public.lsa_submit(sid, cur, pg_temp.voll(cur), 100, now());
  if (r::text || r2::text) ~ '"(correct|accepted|canonical|acceptance|skill_key|known_errors|zustand)"\s*:' then
    raise exception 'P7 verbotener Schluessel in der Schueler-Rueckgabe';
  end if;
  raise notice 'P7 ok: keine Loesungs-/Urteilsschluessel in start/submit';

  -- ---- 8. weiss_nicht ueber den echten Pfad -------------------------------
  r := public.lsa_start(v_student, 13, 'A16-8', 'adaptiv', now());
  sid := (r ->> 'session_id')::uuid;
  cur := (r -> 'item' ->> 'task_id')::uuid;
  perform public.lsa_submit(sid, cur, '{"dont_know":true}'::jsonb, 100, now());
  select abgabeart into v_txt from lsa_responses where session_id=sid and task_id=cur;
  if v_txt <> 'weiss_nicht' then raise exception 'P8 abgabeart=%, erwartet weiss_nicht', v_txt; end if;
  select count(*) into v_n from lsa_responses where session_id=sid and task_id=cur and correct is not null;
  if v_n <> 0 then raise exception 'P8 correct nicht NULL bei weiss_nicht'; end if;
  -- Das Urteil zaehlt es NICHT als falsch: provisorisch nicht_angesetzt, nicht traegt_nicht.
  select zustand into v_txt from lsa_skill_urteil u join tasks t on t.skill_key=u.skill_key
    where u.session_id=sid and t.id=cur limit 1;
  if v_txt = 'traegt_nicht' then raise exception 'P8 weiss_nicht als falsch gewertet (traegt_nicht)'; end if;
  raise notice 'P8 ok: weiss_nicht -> abgabeart weiss_nicht, correct NULL, nicht als falsch';

  -- ---- 9. Negativkontrolle ------------------------------------------------
  v_ctrl := false;
  begin
    if (select count(*) from lsa_sessions) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P9 Negativkontrolle hat NICHT ausgeloest'; end if;
  raise notice 'P9 ok: Negativkontrolle greift';

  raise notice 'ALLE 9 PRUEFUNGEN BESTANDEN';
end;
$$;
