-- lsa-weiter-messung.sql — Laufzeit von lsa_submit / lsa_select_next_core je „Weiter“ (Diagnose LSA-D, 22.10.2026).
--
-- NUR gegen eine Wegwerf-DB (CI-Neuaufbau + Inhalts-Fixture), nie gegen Prod: schreibt Sessions, Antworten, Urteile.
-- Aufruf: psql postgresql:///<db> -v pool=true -v richtig=0.1 -f tools/lsa-weiter-messung.sql
--   pool    = true  → Testkonto/Testlauf (Testlauf-Pool, wie Tolunays Test), false → echtes Kind (nur 'ready')
--   richtig = Anteil richtiger Antworten (Tolunays Session 30091a4d: 14 von 147)
--   ka      = optional, leads.klassenarbeit_status (LSA-L3)
-- Ablauf wie in der App: lsa_start, dann je Aufgabe lsa_submit mit p_jetzt = Start + 8 s je Aufgabe, bis next = null.
-- Gemessen je Schritt: lsa_submit gesamt, lsa_select_next_core allein (im zurückgerollten Block, vor dem Submit),
-- lsa_question_payload allein (das, was platz_next danach noch einmal rechnet).
\set ON_ERROR_STOP 1
\pset format aligned
set jit = off;  -- wie Prod (show jit → off)

insert into auth.users (id, email) values ('d1a90000-0000-4000-8000-000000000001', 'diag-admin@edvance.invalid')
  on conflict do nothing;
insert into public.profiles (id, email, role, full_name)
  values ('d1a90000-0000-4000-8000-000000000001', 'diag-admin@edvance.invalid', 'admin', 'Diag Admin')
  on conflict do nothing;
select set_config('request.jwt.claims',
  '{"sub":"d1a90000-0000-4000-8000-000000000001","role":"authenticated"}', false);

-- Kind wie in Tolunays Test: Klasse 8, Thema reelle_zahlen aktuell, 15 Themen behandelt.
insert into leads (full_name, first_name, status, class_level) values ('Diag Kind', 'Diag', 'vertrag', 8)
  returning id as lead \gset
insert into students (class_level, ist_test) values (8, :pool) returning id as st \gset
update leads set converted_student_id = :'st' where id = :'lead';
-- LSA-L3: -v ka=geschrieben misst den Modus 'vorschau_zuerst' (ohne: Status unbekannt, 'thema_zuerst').
\if :{?ka}
update leads set klassenarbeit_status = :'ka' where id = :'lead';
\endif
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select :'lead', 'mathematik', k, case when k = 'reelle_zahlen' then 'aktuell' else 'behandelt' end, 'gespraech'
  from unnest(array['brueche','daten_streumasse','flaeche_umfang','ganze_zahlen_groessen','koerper_quader',
                    'natuerliche_zahlen','rationale_zahlen','rechnen_brueche_dezimalzahlen','rechnen_natuerliche_zahlen',
                    'reelle_zahlen','symmetrie','terme_gleichungen','winkel','winkel_dreiecke','zinsrechnung','zuordnungen']) k
 where exists (select 1 from themen th where th.thema_key = k);

-- psql setzt :'var' nicht in Dollar-Quotes ein → über Einstellungen in den DO-Block.
select set_config('diag.st', :'st', false), set_config('diag.pool', :'pool', false),
       set_config('diag.richtig', :'richtig', false) \gset

create temp table messung (nr int, submit_ms numeric, core_ms numeric, payload_ms numeric, urteile int, typ text);

do $$
declare
  v_t0   timestamptz := now();
  v_res  jsonb;
  v_sess uuid;
  v_task uuid;
  v_typ  text;
  v_resp jsonb;
  v_sol  jsonb;
  v_nr   int := 0;
  t      timestamptz;
  v_core numeric;
  v_sub  numeric;
  v_pay  numeric;
begin
  t := clock_timestamp();
  v_res := public.lsa_start(current_setting('diag.st')::uuid, 8, 'Mathematik', 'adaptiv', v_t0,
                            current_setting('diag.pool')::boolean);
  insert into messung values (0, round(extract(epoch from clock_timestamp() - t) * 1000, 1), null, null, 0, 'lsa_start');
  v_sess := (v_res ->> 'session_id')::uuid;
  v_task := (v_res -> 'item' ->> 'task_id')::uuid;

  while v_task is not null and v_nr < 200 loop
    v_nr := v_nr + 1;
    select t.input_type, s.correct_answers into v_typ, v_sol
      from tasks t left join task_solutions s on s.task_id = t.id where t.id = v_task;

    -- Antwort: mit Wahrscheinlichkeit :richtig die erste Musterlösung, sonst falsch.
    if random() < current_setting('diag.richtig')::numeric and jsonb_typeof(v_sol) = 'array' then
      v_resp := case when v_typ = 'MC' then jsonb_build_object('selected', jsonb_build_array(v_sol ->> 0))
                     else jsonb_build_object('text', v_sol ->> 0) end;
    elsif v_typ = 'MC' then
      v_resp := '{"selected":["zz"]}';
    elsif v_typ = 'MULTI_PART' then
      select jsonb_object_agg(p ->> 'nr', case when p ->> 'kind' = 'mc' then '{"selected":["zz"]}'::jsonb
                                               else '{"text":"999999"}'::jsonb end)
        into v_resp from tasks t, jsonb_array_elements(t.parts) p where t.id = v_task;
    else
      v_resp := '{"text":"999999"}';
    end if;

    -- lsa_select_next_core allein, im zurückgerollten Block (sie schreibt 'ungeprueft'-Urteile).
    -- Gemessen VOR der Antwort: die Auswahl nach der vorigen Aufgabe, gleicher Zustand wie im Submit davor.
    begin
      t := clock_timestamp();
      perform public.lsa_select_next_core(v_sess, array['ready'], v_t0 + (v_nr * interval '8 seconds'));
      v_core := round(extract(epoch from clock_timestamp() - t) * 1000, 1);
      raise exception using errcode = 'P0D1A';
    exception when sqlstate 'P0D1A' then null;
    end;

    t := clock_timestamp();
    v_res := public.lsa_submit(v_sess, v_task, v_resp, 8000, v_t0 + (v_nr * interval '8 seconds'));
    v_sub := round(extract(epoch from clock_timestamp() - t) * 1000, 1);

    v_task := (v_res -> 'next' ->> 'task_id')::uuid;
    v_pay := null;
    if v_task is not null then
      t := clock_timestamp();
      perform public.lsa_question_payload(v_task);
      v_pay := round(extract(epoch from clock_timestamp() - t) * 1000, 1);
    end if;

    insert into messung values (v_nr, v_sub, v_core, v_pay,
      (select count(*) from lsa_skill_urteil where session_id = v_sess), v_typ);
  end loop;
end $$;

select count(*) filter (where nr > 0) as abgaben,
       round(avg(submit_ms) filter (where nr > 0), 1) as submit_mittel_ms,
       percentile_cont(0.5) within group (order by submit_ms) filter (where nr > 0) as submit_median_ms,
       percentile_cont(0.9) within group (order by submit_ms) filter (where nr > 0) as submit_p90_ms,
       max(submit_ms) filter (where nr > 0) as submit_max_ms,
       round(avg(core_ms), 1) as core_mittel_ms,
       max(core_ms) as core_max_ms,
       round(avg(payload_ms), 2) as payload_mittel_ms,
       max(submit_ms) filter (where nr = 0) as start_ms
  from messung;

-- Verlauf in Zehnerblöcken: wächst die Zeit mit der Zahl der Urteile?
select (nr - 1) / 10 * 10 + 1 as ab_nr, round(avg(submit_ms), 1) as submit_mittel_ms, max(submit_ms) as submit_max_ms,
       round(avg(core_ms), 1) as core_mittel_ms, max(urteile) as urteile
  from messung where nr > 0 group by 1 order by 1;
