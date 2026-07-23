-- Testharness fuer A15 — laeuft im selben begin/…/rollback wie die Migration.
-- Simuliert Submits durch direkte lsa_responses-Inserts (der item_ids-Gate von
-- lsa_submit ist mit adaptiver Auswahl nicht vereinbar — das ist der im PR
-- benannte Nachzieher). Getestet wird die ENGINE (die *_core-Funktionen).

create function pg_temp.sim(p_session uuid, p_task uuid, p_art text) returns text as $$
declare v_it text; v_canon text; v_resp jsonb; v_art text; v_correct boolean;
begin
  select input_type into v_it from tasks where id = p_task;
  if p_art = 'weiss_nicht' then
    v_resp := '{"dont_know":true}'::jsonb; v_art := 'weiss_nicht'; v_correct := null;
  elsif v_it = 'MC' then
    v_resp := '{"selected":["a"]}'::jsonb; v_art := 'antwort'; v_correct := (p_art = 'voll');
  else
    if p_art = 'voll' then
      -- Die erste akzeptierte Antwort — traegt bei NUMERIC UND TERM (TERM hat
      -- kein acceptance.canonical, aber correct_answers).
      select correct_answers ->> 0 into v_canon from task_solutions where task_id = p_task;
      v_resp := jsonb_build_object('value', v_canon); v_correct := true;
    else
      v_resp := '{"value":"-987654"}'::jsonb; v_correct := false;
    end if;
    v_art := 'antwort';
  end if;
  insert into lsa_responses (session_id, task_id, part_nr, response, abgabeart, correct)
    values (p_session, p_task, null, v_resp, v_art, v_correct);
  return public.lsa_urteil_buchen_core(p_session, p_task);
end;
$$ language plpgsql;

create function pg_temp.mk(p_subj text) returns uuid as $$
  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status)
    values ((select id from students limit 1), p_subj, 8, '{}', now(), 'in_progress')
    returning id;
$$ language sql;

do $$
declare
  v_student uuid;
  sA uuid; sB uuid; sC uuid; sD uuid; sE uuid;
  v_t uuid; v_t2 uuid; v_t3 uuid;
  v_probes int; v_hit int;
  v_n int; v_txt text; v_ctrl boolean;
  v_dep text;
begin
  select id into v_student from students limit 1;

  sA := pg_temp.mk('A15-A'); sB := pg_temp.mk('A15-B'); sC := pg_temp.mk('A15-C');
  sD := pg_temp.mk('A15-D'); sE := pg_temp.mk('A15-E');

  -- 1. Blaetter = 14
  select count(*) into v_n from skills s
   where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key = s.skill_key);
  if v_n <> 14 then raise exception 'P1 Blaetter=%, erwartet 14', v_n; end if;
  raise notice 'P1 ok: 14 Blaetter';

  -- 2. Abschluss(prozent_veraenderung) = 8
  select count(*) into v_n from public.lsa_abschluss('prozent_veraenderung');
  if v_n <> 8 then raise exception 'P2 abschluss=%, erwartet 8', v_n; end if;
  raise notice 'P2 ok: Abschluss 8';

  -- 3. Erster Zug leere Sitzung = prozent_veraenderung
  v_t := public.lsa_select_next_core(sA, array['draft'], now());
  select skill_key into v_txt from tasks where id = v_t;
  if v_txt <> 'prozent_veraenderung' then raise exception 'P3 erster Zug=%, erwartet prozent_veraenderung', v_txt; end if;
  raise notice 'P3 ok: erster Zug prozent_veraenderung';

  -- 4. Simulation A: alles voll.
  --    Die Vorlage-Zahlen (32 gedeckt, 14 direkt) setzen voraus, dass JEDES
  --    Blatt Aufgaben hat. Real haben 4 Blaetter (groessen_gemischt,
  --    groessen_massen, groessen_volumen, runden_ueberschlag) KEINE Aufgaben —
  --    sie werden korrekt 'ungeprueft' und belegen nichts mit. Zusaetzlich
  --    belegt Regel-3-Schritt-5 (Restzeit) erreichbare Nicht-Blaetter direkt.
  --    Deshalb pruefen wir hier ENGINE-INVARIANTEN statt fixer Zahlen und
  --    melden die echten Werte (siehe PR).
  v_probes := 0;
  loop
    v_t := public.lsa_select_next_core(sA, array['draft'], now());
    exit when v_t is null;
    perform pg_temp.sim(sA, v_t, 'voll');
    v_probes := v_probes + 1;
    exit when v_probes >= 60;  -- Schutz; real ~ Anzahl skills
  end loop;

  -- (a) Bei lauter 'voll' faellt niemand.
  select count(*) into v_n from lsa_skill_urteil where session_id = sA
    and zustand in ('traegt_nicht','nicht_angesetzt');
  if v_n <> 0 then raise exception 'P4a % negative Urteile bei lauter voll', v_n; end if;

  -- (b) Jedes Blatt MIT draft-Aufgabe -> traegt & direkt.
  select count(*) into v_n from skills s
   where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key=s.skill_key)
     and exists (select 1 from tasks t where t.skill_key=s.skill_key and t.status='draft')
     and not exists (select 1 from lsa_skill_urteil u
                      where u.session_id=sA and u.skill_key=s.skill_key
                        and u.zustand='traegt' and u.belegt_direkt);
  if v_n <> 0 then raise exception 'P4b % with-task-Blaetter nicht traegt/direkt', v_n; end if;

  -- (c) Jedes Blatt OHNE Aufgabe -> ungeprueft.
  select count(*) into v_n from skills s
   where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key=s.skill_key)
     and not exists (select 1 from tasks t where t.skill_key=s.skill_key and t.status='draft')
     and not exists (select 1 from lsa_skill_urteil u
                      where u.session_id=sA and u.skill_key=s.skill_key and u.zustand='ungeprueft');
  if v_n <> 0 then raise exception 'P4c % taskless-Blaetter nicht ungeprueft', v_n; end if;

  -- (d) belegt_direkt = genau die tatsaechlich gestellten Skills.
  select count(*) into v_n from lsa_skill_urteil where session_id=sA and belegt_direkt;
  select count(distinct skill_key) into v_hit from lsa_responses r join tasks t on t.id=r.task_id
    where r.session_id=sA;
  if v_n <> v_hit then raise exception 'P4d belegt_direkt=% <> gestellte skills=%', v_n, v_hit; end if;

  -- (e) Mit-Belegung vollstaendig: jeder Abschluss-Skill eines traegt hat eine Zeile.
  select count(*) into v_n from lsa_skill_urteil u
    cross join lateral public.lsa_abschluss(u.skill_key) a
    where u.session_id=sA and u.zustand='traegt'
      and not exists (select 1 from lsa_skill_urteil d where d.session_id=sA and d.skill_key=a.skill_key);
  if v_n <> 0 then raise exception 'P4e % Abschluss-Skills ohne Zeile', v_n; end if;

  select count(distinct skill_key) into v_n from lsa_skill_urteil where session_id=sA;
  raise notice 'P4 ok (Invarianten a-e): % gedeckt, % direkt, % Proben (Vorlage-32/14 galt nur ohne taskless-Blaetter)',
    v_n, (select count(*) from lsa_skill_urteil where session_id=sA and belegt_direkt), v_probes;

  -- 5. Simulation B: prozent_veraenderung zweimal nicht -> traegt_nicht, Abstieg auf grundwert
  v_t := public.lsa_select_next_core(sB, array['draft'], now());
  perform pg_temp.sim(sB, v_t, 'nicht');
  v_t2 := public.lsa_select_next_core(sB, array['draft'], now());
  perform pg_temp.sim(sB, v_t2, 'nicht');
  select zustand into v_txt from lsa_skill_urteil where session_id = sB and skill_key = 'prozent_veraenderung';
  if v_txt <> 'traegt_nicht' then raise exception 'P5 Zustand=%, erwartet traegt_nicht', v_txt; end if;
  v_t3 := public.lsa_select_next_core(sB, array['draft'], now());
  select skill_key into v_txt from tasks where id = v_t3;
  if v_txt <> 'prozent_grundwert' then raise exception 'P5 Abstieg auf %, erwartet prozent_grundwert', v_txt; end if;
  raise notice 'P5 ok: traegt_nicht, Abstieg auf prozent_grundwert (Tiefe 7)';

  -- 6. Simulation C: zweimal weiss_nicht -> nicht_angesetzt
  v_t := public.lsa_select_next_core(sC, array['draft'], now());
  perform pg_temp.sim(sC, v_t, 'weiss_nicht');
  v_t2 := public.lsa_select_next_core(sC, array['draft'], now());
  perform pg_temp.sim(sC, v_t2, 'weiss_nicht');
  select zustand into v_txt from lsa_skill_urteil where session_id = sC and skill_key = 'prozent_veraenderung';
  if v_txt <> 'nicht_angesetzt' then raise exception 'P6 Zustand=%, erwartet nicht_angesetzt', v_txt; end if;
  raise notice 'P6 ok: nicht_angesetzt (nicht traegt_nicht)';

  -- 7. Skill ohne Aufgaben -> ungeprueft, Sitzung laeuft weiter
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
    values (sD, 'groessen_flaechen', 'traegt_nicht', true, false, 2);
  perform public.lsa_select_next_core(sD, array['draft'], now());
  select zustand into v_txt from lsa_skill_urteil where session_id = sD and skill_key = 'groessen_laengen';
  if v_txt is distinct from 'ungeprueft' then raise exception 'P7 groessen_laengen=%, erwartet ungeprueft', coalesce(v_txt,'<keine Zeile>'); end if;
  select status into v_txt from lsa_sessions where id = sD;
  if v_txt <> 'in_progress' then raise exception 'P7 Sitzung nicht mehr aktiv'; end if;
  raise notice 'P7 ok: groessen_laengen ungeprueft, Sitzung laeuft';

  -- 8. Kein Ueberschreiben: direktes traegt_nicht bleibt trotz Mit-Belegung
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
    values (sE, 'dezimal_add_sub', 'traegt_nicht', true, false, 2);
  select id into v_t from tasks where skill_key = 'prozent_veraenderung' and status = 'draft' limit 1;
  perform pg_temp.sim(sE, v_t, 'voll');   -- prozent_veraenderung traegt -> Mit-Belegung ueber dezimal_add_sub
  select zustand into v_txt from lsa_skill_urteil where session_id = sE and skill_key = 'dezimal_add_sub';
  if v_txt <> 'traegt_nicht' then raise exception 'P8 dezimal_add_sub=%, erwartet traegt_nicht (nicht ueberschrieben)', v_txt; end if;
  raise notice 'P8 ok: direktes traegt_nicht nicht ueberschrieben';

  -- 9. Negativkontrolle: der Harness MUSS bei falscher Erwartung abbrechen.
  v_ctrl := false;
  begin
    if (select count(*) from skills) <> 999 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then
    v_ctrl := true;
  end;
  if not v_ctrl then
    raise exception 'P9 Negativkontrolle hat NICHT ausgeloest — der Harness prueft nichts';
  end if;
  raise notice 'P9 ok: Negativkontrolle greift';

  raise notice 'ALLE 9 PRUEFUNGEN BESTANDEN';
end;
$$;
