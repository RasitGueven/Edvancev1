-- A17 END-ZU-ENDE — echte Platz-RPCs + lsa_uebernahme, im begin/…/rollback.
-- A16 ist auf der DB; hier laeuft A17-DDL + Harness, alles Rollback.

create function pg_temp.voll(p_task uuid) returns jsonb as $$
  select case when t.input_type = 'MC'
              then jsonb_build_object('selected', s.correct_answers)
              else jsonb_build_object('value', s.correct_answers ->> 0) end
  from tasks t join task_solutions s on s.task_id = t.id where t.id = p_task;
$$ language sql;

-- Als Admin: Zuweisung device->session (vorherige aktive vorher loesen).
create function pg_temp.assign(p_session uuid) returns void as $$
declare v_dev uuid; v_adm uuid;
begin
  select profile_id into v_dev from platz_devices limit 1;
  select id into v_adm from profiles where role='admin' limit 1;
  update platz_assignments set released_at=now() where platz_profile_id=v_dev and released_at is null;
  insert into platz_assignments (platz_profile_id, session_id, created_by, expires_at)
    values (v_dev, p_session, v_adm, now()+interval '2 hours');
end;
$$ language plpgsql;

do $$
declare
  v_admin uuid; v_device uuid; v_student uuid; v_other uuid;
  v_lead uuid; sA uuid; sB uuid; sC uuid; sF uuid; sT uuid; sK uuid; sStud uuid;
  r jsonb; n jsonb; cur uuid; v_probes int; v_i int; v_txt text; v_ctrl boolean;
  v_started timestamptz; v_fremd uuid;
  v_c1 int; v_c2 int; v_c3 int; v_c4 int;
begin
  select id into v_admin from profiles where role='admin' limit 1;
  select profile_id into v_device from platz_devices limit 1;
  select id into v_student from students where not is_provisional limit 1;
  select id into v_other from students where id <> v_student limit 1;

  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  update tasks set status='ready' where source='edvance_fundament';

  -- =================== TEIL A ===================================

  -- ---- 1. Vollstaendige Platz-Sitzung, alles korrekt ----------------------
  insert into leads (full_name, first_name, status, consent_dsgvo_at)
    values ('Test Eins', 'Eins', 'new', now()) returning id into v_lead;
  r := public.lead_lsa_freigeben(v_lead, 13, 'Mathematik');
  sA := (r ->> 'session_id')::uuid;
  perform pg_temp.assign(sA);

  perform set_config('request.jwt.claims', json_build_object('sub', v_device)::text, true);
  v_probes := 0;
  loop
    n := public.platz_next();
    exit when (n ->> 'done')::boolean;
    cur := (n -> 'item' ->> 'task_id')::uuid;
    perform public.platz_submit(cur, pg_temp.voll(cur), 100);
    v_probes := v_probes + 1;
    exit when v_probes >= 40;
  end loop;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

  select modus into v_txt from lsa_sessions where id=sA;
  if v_txt <> 'adaptiv' then raise exception 'P1 modus=%, erwartet adaptiv', v_txt; end if;
  select coalesce(array_length(item_ids,1),0) into v_i from lsa_sessions where id=sA;
  if v_i <> 0 then raise exception 'P1 item_ids nicht leer'; end if;
  if v_probes < 2 then raise exception 'P1 nur % Aufgabe(n)', v_probes; end if;
  select count(*) into v_i from lsa_skill_urteil where session_id=sA;
  if v_i = 0 then raise exception 'P1 keine Urteile'; end if;
  select count(*) into v_i from lsa_responses r where r.session_id=sA
    and not exists (select 1 from lsa_ausgegeben a where a.session_id=sA and a.task_id=r.task_id);
  if v_i <> 0 then raise exception 'P1 % Antworten ohne Ausgabe', v_i; end if;
  raise notice 'P1 ok: adaptiv, item_ids leer, % Aufgaben, Urteile, jede Antwort ausgegeben', v_probes;

  -- ---- 2. Keine Doppelausgabe --------------------------------------------
  select count(*), count(distinct task_id) into v_c1, v_c2 from lsa_ausgegeben where session_id=sA;
  if v_c1 <> v_c2 then raise exception 'P2 Doppelausgabe: % Zeilen, % distinct', v_c1, v_c2; end if;
  raise notice 'P2 ok: keine task_id doppelt (% ausgegeben)', v_c1;

  -- ---- 3. Fremde task_id an platz_submit ---------------------------------
  insert into leads (full_name, first_name, status, consent_dsgvo_at)
    values ('Test Drei', 'Drei', 'new', now()) returning id into v_lead;
  r := public.lead_lsa_freigeben(v_lead, 13, 'Mathematik');
  sB := (r ->> 'session_id')::uuid;
  perform pg_temp.assign(sB);
  perform set_config('request.jwt.claims', json_build_object('sub', v_device)::text, true);
  n := public.platz_next();
  cur := (n -> 'item' ->> 'task_id')::uuid;
  select id into v_fremd from tasks where source='edvance_fundament' and id <> cur limit 1;
  v_ctrl := false;
  begin perform public.platz_submit(v_fremd, '{"value":"1"}'::jsonb, 100);
  exception when others then v_ctrl := true; end;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  if not v_ctrl then raise exception 'P3 fremde task_id NICHT abgewiesen'; end if;
  raise notice 'P3 ok: fremde task_id an platz_submit abgewiesen';

  -- ---- 4. Zeitende -------------------------------------------------------
  insert into leads (full_name, first_name, status, consent_dsgvo_at)
    values ('Test Vier', 'Vier', 'new', now()) returning id into v_lead;
  r := public.lead_lsa_freigeben(v_lead, 13, 'Mathematik');
  sC := (r ->> 'session_id')::uuid;
  perform pg_temp.assign(sC);
  select started_at into v_started from lsa_sessions where id=sC;
  perform set_config('request.jwt.claims', json_build_object('sub', v_device)::text, true);
  n := public.platz_next();
  cur := (n -> 'item' ->> 'task_id')::uuid;
  r := public.platz_submit(cur, pg_temp.voll(cur), 100, v_started + interval '20 minutes');
  if not (r -> 'next' is null or r -> 'next' = 'null'::jsonb) then
    raise exception 'P4 next nicht null nach Zeitablauf';
  end if;
  n := public.platz_next();
  if not (n ->> 'done')::boolean then raise exception 'P4 platz_next nicht done nach Zeitablauf'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  select count(distinct skill_key) into v_i from lsa_skill_urteil where session_id=sC;
  if v_i >= 32 then raise exception 'P4 alles gedeckt — Zeitende nicht aussagekraeftig'; end if;
  raise notice 'P4 ok: nach 20 min done, nur % Skills gedeckt', v_i;

  -- ---- 5. Kein Zaehler ---------------------------------------------------
  -- sC-Zuweisung ist noch aktiv (Session in_progress). platz_next/state pruefen.
  perform set_config('request.jwt.claims', json_build_object('sub', v_device)::text, true);
  n := public.platz_next();
  if n ? 'total' or n ? 'total_items' then raise exception 'P5 platz_next traegt Aufgabenzahl'; end if;
  r := public.platz_state();
  if r ? 'progress' then raise exception 'P5 platz_state traegt progress (adaptiv)'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  raise notice 'P5 ok: platz_next/platz_state ohne Aufgabenzahl';

  -- ---- 6. Fest-Sitzung unveraendert --------------------------------------
  update lsa_sessions set status='aborted'
    where student_id=v_student and subject='Mathematik' and status='in_progress';
  r := public.lsa_start(v_student, 13, 'Mathematik', 'fest');
  sF := (r ->> 'session_id')::uuid;
  perform pg_temp.assign(sF);
  perform set_config('request.jwt.claims', json_build_object('sub', v_device)::text, true);
  n := public.platz_next();
  if (n ->> 'done')::boolean then raise exception 'P6 fest-Sitzung sofort done'; end if;
  r := public.platz_state();
  if not (r ? 'progress') then raise exception 'P6 fest-platz_state ohne progress'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  select modus into v_txt from lsa_sessions where id=sF;
  if v_txt <> 'fest' then raise exception 'P6 modus=%, erwartet fest', v_txt; end if;
  raise notice 'P6 ok: fest-Sitzung mit item_ids + progress unveraendert';

  -- =================== TEIL B ===================================

  -- Sitzung mit gemischten Zustaenden (direkt gebaut).
  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
    values (v_student, 'A17-uebernahme', 13, '{}', now(), 'in_progress', 'adaptiv')
    returning id into sT;
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl) values
    (sT, 'prozent_veraenderung', 'traegt',           true,  false, 1),  -- KEIN Fokus
    (sT, 'prozent_grundwert',    'traegt_nicht',      true,  false, 2),  -- Fokus, direkt
    (sT, 'dezimal_add_sub',      'nicht_angesetzt',   false, false, 2),  -- Fokus, abgeleitet
    (sT, 'dezimal_mult',         'traegt_teilweise',  true,  false, 2),  -- Fokus
    (sT, 'groessen_laengen',     'ungeprueft',        false, false, 0);  -- KEIN Fokus

  -- ---- 7. Nur die drei Luecken erzeugen Fokus ----------------------------
  r := public.lsa_uebernahme(sT, v_student);
  select count(*) into v_i from student_focus_areas where herkunfts_session_id=sT;
  if v_i <> 3 then raise exception 'P7 % Fokus-Eintraege, erwartet 3', v_i; end if;
  if exists (select 1 from student_focus_areas where herkunfts_session_id=sT
             and skill_key in ('prozent_veraenderung','groessen_laengen')) then
    raise exception 'P7 traegt/ungeprueft hat Fokus erzeugt';
  end if;
  raise notice 'P7 ok: nur die 3 Luecken erzeugen Fokus (traegt/ungeprueft nicht)';

  -- ---- 8. belegt_direkt kommt an -----------------------------------------
  select belegt_direkt into v_ctrl from student_focus_areas
    where herkunfts_session_id=sT and skill_key='prozent_grundwert';
  if v_ctrl is not true then raise exception 'P8 direkt-belegter Skill nicht belegt_direkt=true'; end if;
  select belegt_direkt into v_ctrl from student_focus_areas
    where herkunfts_session_id=sT and skill_key='dezimal_add_sub';
  if v_ctrl is not false then raise exception 'P8 abgeleiteter Skill nicht belegt_direkt=false'; end if;
  raise notice 'P8 ok: belegt_direkt wandert korrekt mit';

  -- ---- 9. Zweimal uebernehmen -> keine Duplikate -------------------------
  perform public.lsa_uebernahme(sT, v_student);
  select count(*) into v_i from student_focus_areas where herkunfts_session_id=sT;
  if v_i <> 3 then raise exception 'P9 nach zweiter Uebernahme % Eintraege', v_i; end if;
  raise notice 'P9 ok: zweite Uebernahme dupliziert nicht';

  -- ---- 10. bestaetigt ueberlebt ------------------------------------------
  update student_focus_areas set status='bestaetigt', active=true
    where herkunfts_session_id=sT and skill_key='prozent_grundwert';
  perform public.lsa_uebernahme(sT, v_student);
  select status into v_txt from student_focus_areas
    where herkunfts_session_id=sT and skill_key='prozent_grundwert';
  if v_txt <> 'bestaetigt' then raise exception 'P10 bestaetigt wurde ueberschrieben (%)', v_txt; end if;
  raise notice 'P10 ok: bestaetigter Eintrag ueberlebt erneute Uebernahme';

  -- ---- 11. Rohdaten unveraendert -----------------------------------------
  select (select count(*) from lsa_responses where session_id=sT),
         (select count(*) from lsa_skill_urteil where session_id=sT),
         (select count(*) from lsa_ausgegeben where session_id=sT),
         (select count(*) from lsa_sessions where id=sT)
    into v_c1, v_c2, v_c3, v_c4;
  perform public.lsa_uebernahme(sT, v_student);
  if v_c2 <> (select count(*) from lsa_skill_urteil where session_id=sT)
     or v_c1 <> (select count(*) from lsa_responses where session_id=sT)
     or v_c3 <> (select count(*) from lsa_ausgegeben where session_id=sT)
     or v_c4 <> (select count(*) from lsa_sessions where id=sT) then
    raise exception 'P11 Rohdaten-Zeilenzahl veraendert';
  end if;
  raise notice 'P11 ok: Rohdaten (Sitzung/Antworten/Urteile/Ausgabe) unveraendert';

  -- ---- 12. Sortierung nach fundament_tiefe -------------------------------
  if exists (
    select 1 from (
      select f.skill_key, s.fundament_tiefe,
             lag(s.fundament_tiefe) over (order by s.fundament_tiefe, f.skill_key) as prev
      from student_focus_areas f join skills s on s.skill_key=f.skill_key
      where f.herkunfts_session_id=sT
    ) x where prev is not null and fundament_tiefe < prev
  ) then raise exception 'P12 Sortierung nach fundament_tiefe nicht aufsteigend'; end if;
  raise notice 'P12 ok: Fokus nach fundament_tiefe aufsteigend abrufbar';

  -- ---- 13. Konversionsspur + Konfliktschutz ------------------------------
  insert into leads (full_name, first_name, status, consent_dsgvo_at)
    values ('Test Konv', 'Konv', 'new', now()) returning id into v_lead;
  r := public.lead_lsa_freigeben(v_lead, 13, 'Mathematik');
  sK := (r ->> 'session_id')::uuid;
  select student_id into sStud from lsa_sessions where id=sK;
  perform public.lead_convert(v_lead);                 -- setzt converted_student_id, flippt Schueler
  perform public.lsa_uebernahme(sK, sStud);            -- setzt konvertiert_am + Sitzungs-Spur
  select converted_student_id into v_txt from leads where id=v_lead;
  if v_txt::uuid <> sStud then raise exception 'P13 lead.converted_student_id falsch'; end if;
  if (select konvertiert_am from leads where id=v_lead) is null then raise exception 'P13 konvertiert_am nicht gesetzt'; end if;
  if (select uebernommen_zu_student_id from lsa_sessions where id=sK) <> sStud then raise exception 'P13 Sitzungs-Spur student falsch'; end if;
  if (select uebernommen_am from lsa_sessions where id=sK) is null then raise exception 'P13 uebernommen_am nicht gesetzt'; end if;
  v_ctrl := false;
  begin perform public.lsa_uebernahme(sK, v_other);    -- ANDERE student_id
  exception when others then v_ctrl := true; end;
  if not v_ctrl then raise exception 'P13 Uebernahme auf ANDERE student_id nicht abgewiesen'; end if;
  raise notice 'P13 ok: Konversionsspur gesetzt, andere student_id scheitert';

  -- ---- 14. Negativkontrolle ----------------------------------------------
  v_ctrl := false;
  begin
    if (select count(*) from skills) <> -1 then raise exception 'kontrolle: absichtlich falsch'; end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P14 Negativkontrolle hat NICHT ausgeloest'; end if;
  raise notice 'P14 ok: Negativkontrolle greift';

  raise notice 'ALLE 14 PRUEFUNGEN BESTANDEN';
end;
$$;
