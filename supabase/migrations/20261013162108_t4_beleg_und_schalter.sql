-- T4.4 lernpfad_beleg schreibt im Testlauf nichts; T4.5 testlauf nach dem Start auch direkt nicht aenderbar
-- (Entscheidungen Rasit 12.10.2026, Paket T4; offene-punkte-t2 Punkte 2 und 3).
--
-- lernpfad_beleg_core: Pruefungen wie bisher (Ergebnis, Hinweis, Skill, anwesend), dann im Testlauf
-- (coaching_sessions.testlauf) keine Zeile in lernpfad_belege oder lernpfad; zurueck kommt der unveraenderte
-- Systemzustand (ohne Zeile 'offen', wie ziel_fertigkeiten). Der Coach-RPC lernpfad_beleg ruft den Kern;
-- antwort_abgeben prueft testlauf schon selbst und ruft ihn im Testlauf nicht.
--
-- coaching_sessions_testlauf_pruefen (Trigger auf UPDATE OF testlauf): Aendert sich testlauf an einer gestarteten
-- Session (gestartet_am gesetzt oder Status nicht upcoming, vorher oder nachher), 55000 wie session_testlauf_setzen.
-- Reihenfolge wie dort: erst das Admin-Tor (42501), dann der Start (55000), dann die Testkonten (22023).

CREATE OR REPLACE FUNCTION public.lernpfad_beleg_core(p_student_id uuid, p_skill_key text, p_session_id uuid, p_ergebnis text, p_hinweis_genutzt boolean)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_abstand  numeric := public.lernpfad_stellschraube('mastery_abstand_sessions', p_session_id);
  v_n        numeric := public.lernpfad_stellschraube('mastery_richtig_ohne_hinweis', p_session_id);
  v_alt      text;
  v_neu      text;
  v_kandidat boolean;
  v_heute    record;
  v_belege   jsonb;
begin
  if p_ergebnis is null or p_ergebnis not in ('richtig', 'teilweise', 'falsch') then
    raise exception 'lernpfad_beleg: ergebnis muss richtig, teilweise oder falsch sein' using errcode = '22023';
  end if;
  if p_hinweis_genutzt is null then
    raise exception 'lernpfad_beleg: hinweis_genutzt ist Pflicht' using errcode = '22023';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'lernpfad_beleg: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;
  -- Nur Sessions vor Ort, in denen das Kind gebucht und anwesend ist
  -- (Entscheidung 4; R1 setzt 'present' bei der Tablet-Zuweisung).
  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance = 'present') then
    raise exception 'lernpfad_beleg: Kind ist in dieser Session nicht anwesend' using errcode = 'P0001';
  end if;
  -- T4: im Testlauf keine Zeile in lernpfad_belege oder lernpfad (Entscheidung 27).
  if coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false) then
    return coalesce((select l.stand_system from public.lernpfad l
                      where l.student_id = p_student_id and l.skill_key = p_skill_key), 'offen');
  end if;

  insert into public.lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
  values (p_student_id, p_skill_key, p_session_id, p_ergebnis, p_hinweis_genutzt);

  insert into public.lernpfad (student_id, skill_key, quelle)
  values (p_student_id, p_skill_key, 'session')
  on conflict (student_id, skill_key) do nothing;

  select stand_system into v_alt
    from public.lernpfad
   where student_id = p_student_id and skill_key = p_skill_key
   for update;

  with je_session as (
    select b.session_id,
           cs.scheduled_at,
           min(b.zeit) as am,
           count(*)::int as gesamt,
           count(*) filter (where b.ergebnis = 'richtig' and not b.hinweis_genutzt)::int as ohne_hinweis,
           count(*) filter (where b.ergebnis = 'richtig')::int as richtig,
           count(*) filter (where b.ergebnis = 'falsch')::int as falsch
      from public.lernpfad_belege b
      join public.coaching_sessions cs on cs.id = b.session_id
     where b.student_id = p_student_id and b.skill_key = p_skill_key
     group by b.session_id, cs.scheduled_at
  ),
  nummeriert as (
    select *, row_number() over (order by scheduled_at, session_id) as nr
      from je_session
  )
  select bool_or(nr > v_abstand and ohne_hinweis >= v_n),
         jsonb_agg(jsonb_build_object('session_id', session_id, 'am', am, 'gesamt', gesamt,
                                      'richtig_ohne_hinweis', ohne_hinweis) order by nr)
    into v_kandidat, v_belege
    from nummeriert;

  select count(*) filter (where ergebnis = 'richtig' and not hinweis_genutzt) as ohne_hinweis,
         count(*) filter (where ergebnis = 'richtig') as richtig,
         count(*) filter (where ergebnis = 'falsch') as falsch
    into v_heute
    from public.lernpfad_belege
   where student_id = p_student_id and skill_key = p_skill_key and session_id = p_session_id;

  v_neu := case
             when v_kandidat then 'kandidat'
             when v_heute.ohne_hinweis >= v_n then 'sicher'
             when v_alt = 'sicher' and v_heute.falsch > v_heute.richtig then 'noch_nicht_sicher'
             when v_alt = 'sicher' then 'sicher'
             else 'aktiv'
           end;

  update public.lernpfad
     set stand_system      = v_neu,
         stand_system_seit = case when v_neu is distinct from v_alt then now() else stand_system_seit end,
         letzte_uebung_am  = now(),
         letzte_session_id = p_session_id,
         belege            = coalesce(v_belege, '[]'::jsonb),
         aktualisiert      = now()
   where student_id = p_student_id and skill_key = p_skill_key;

  return v_neu;
end;
$function$;

CREATE OR REPLACE FUNCTION public.coaching_sessions_testlauf_pruefen()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if (tg_op = 'INSERT' and new.testlauf)
     or (tg_op = 'UPDATE' and new.testlauf is distinct from old.testlauf) then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    -- T4: nach dem Start nicht mehr, auch nicht ueber direkte Zeilenrechte (wie session_testlauf_setzen).
    if tg_op = 'UPDATE'
       and (old.gestartet_am is not null or old.status is distinct from 'upcoming'
            or new.gestartet_am is not null or new.status is distinct from 'upcoming') then
      raise exception 'Testlauf: Session ist schon gestartet' using errcode = '55000', hint = 'session_gestartet';
    end if;
    if new.testlauf and exists (
      select 1 from public.session_students ss
        join public.students s on s.id = ss.student_id
       where ss.session_id = new.id and not s.ist_test
    ) then
      raise exception 'Testlauf: nur mit Testkonten' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$function$;
