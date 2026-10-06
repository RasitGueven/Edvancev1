-- A2.1 Session-Engine: Ziel der Stunde (Entscheidung A2 D) und Kerne der A1-Lesefunktionen.
--
-- ziel_fertigkeiten_core, naechste_luecke_core, mastery_vorschlaege_core: Rumpf unveraendert aus
-- 20261007120415/120414/120416 (Prod identisch, pg_get_functiondef 06.10.), nur ohne
-- Rechtepruefung. Nicht fuer authenticated; die Engine ruft sie unter dem Geraetekonto.
-- ziel_fertigkeiten, naechste_luecke, mastery_vorschlaege pruefen wie bisher und rufen den Kern.

create function public.ziel_fertigkeiten_core(p_student_id uuid, p_thema_key text)
returns table (
  reihenfolge     int,
  skill_key       text,
  label           text,
  klasse_herkunft int,
  rolle           text,
  stand_system    text,
  stand_coach     text,
  stand           text,
  pruefung_faellig boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not exists (select 1 from public.themen t where t.thema_key = p_thema_key) then
    raise exception 'ziel_fertigkeiten: Thema % unbekannt', p_thema_key using errcode = 'P0002';
  end if;

  return query
    with thema as (
      select te.skill_key, 'einstieg'::text as rolle
        from public.thema_einstieg te where te.thema_key = p_thema_key
      union
      select st.skill_key, 'thema'
        from public.skill_thema st
       where st.thema_key = p_thema_key
         and st.skill_key not in (select te.skill_key from public.thema_einstieg te
                                   where te.thema_key = p_thema_key)
    ),
    darunter as (
      select distinct a.skill_key
        from thema t cross join lateral public.lsa_abschluss(t.skill_key) a
       where a.skill_key not in (select skill_key from thema)
    ),
    direkt as (
      select distinct k.voraussetzt_skill_key as skill_key
        from public.skill_kante k
       where k.skill_key in (select skill_key from thema)
         and k.voraussetzt_skill_key not in (select skill_key from thema)
    ),
    voraus as (
      select d.skill_key,
             case when l.stand_coach = 'gemeistert' or l.stand_system in ('sicher', 'kandidat')
                  then 'voraussetzung_sicher' else 'voraussetzung' end as rolle
        from darunter d
        join public.lernpfad l on l.student_id = p_student_id and l.skill_key = d.skill_key
       where (l.stand_system in ('offen', 'aktiv', 'noch_nicht_sicher') and l.stand_coach is distinct from 'gemeistert')
          or d.skill_key in (select skill_key from direkt)
    ),
    liste as (
      select skill_key, rolle from thema
      union all
      select skill_key, rolle from voraus
    )
    select (row_number() over (
              order by (select count(*) from public.lsa_abschluss(li.skill_key) a
                         where a.skill_key in (select skill_key from liste)),
                       s.klasse_herkunft, s.fundament_tiefe, li.skill_key))::int,
           li.skill_key, s.label, s.klasse_herkunft, li.rolle,
           l.stand_system, l.stand_coach,
           case when l.stand_coach = 'gemeistert' then 'gemeistert'
                else coalesce(l.stand_system, 'offen') end,
           public.lernpfad_pruefung_faellig(p_student_id, li.skill_key)
      from liste li
      join public.skills s on s.skill_key = li.skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = li.skill_key
     order by 1;
end;
$$;

create function public.naechste_luecke_core(p_student_id uuid)
returns table (skill_key text, label text, thema_key text, stand_system text, quelle text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin

  return query
    select l.skill_key, s.label, st.thema_key, l.stand_system,
           case when l.quelle = 'lsa' and l.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
      left join public.skill_thema st on st.skill_key = l.skill_key
     where l.student_id = p_student_id
       and l.stand_system = 'aktiv'
       and l.stand_coach is distinct from 'gemeistert'
     order by l.stand_system_seit desc, l.skill_key
     limit 1;
  if found then
    return;
  end if;

  return query
    with luecke as (
      select l.skill_key, l.stand_system, l.quelle, l.belege
        from public.lernpfad l
       where l.student_id = p_student_id
         and l.stand_system = 'noch_nicht_sicher'
         and l.stand_coach is distinct from 'gemeistert'
    )
    select g.skill_key, s.label, st.thema_key, g.stand_system,
           case when g.quelle = 'lsa' and g.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from luecke g
      join public.skills s on s.skill_key = g.skill_key
      left join public.skill_thema st on st.skill_key = g.skill_key
     order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                where a.skill_key in (select skill_key from luecke)),
              s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
     limit 1;
  if found then
    return;
  end if;

  -- Erste Session nach der LSA, Lernpfad noch nicht uebernommen.
  if not exists (select 1 from public.lernpfad l where l.student_id = p_student_id) then
    return query
      with luecke as (
        select u.skill_key from public.lernpfad_lsa_urteile(p_student_id) u where u.zustand <> 'traegt'
      )
      select g.skill_key, s.label, st.thema_key, 'noch_nicht_sicher'::text, 'lsa'::text
        from luecke g
        join public.skills s on s.skill_key = g.skill_key
        left join public.skill_thema st on st.skill_key = g.skill_key
       order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                  where a.skill_key in (select skill_key from luecke)),
                s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
       limit 1;
  end if;
end;
$$;

create function public.mastery_vorschlaege_core(p_student_id uuid)
returns table (skill_key text, label text, stand_coach text, coach_grund text, letzte_uebung_am timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  return query
    select l.skill_key, s.label, l.stand_coach, l.coach_grund, l.letzte_uebung_am
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = p_student_id
       and public.lernpfad_pruefung_faellig(l.student_id, l.skill_key)
     order by l.stand_system_seit, l.skill_key;
end;
$$;

create or replace function public.ziel_fertigkeiten(p_student_id uuid, p_thema_key text)
returns table (reihenfolge int, skill_key text, label text, klasse_herkunft int, rolle text,
               stand_system text, stand_coach text, stand text, pruefung_faellig boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.lernpfad_darf_lesen(p_student_id), false)) then
    raise exception 'ziel_fertigkeiten: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  return query select * from public.ziel_fertigkeiten_core(p_student_id, p_thema_key);
end;
$$;

create or replace function public.naechste_luecke(p_student_id uuid)
returns table (skill_key text, label text, thema_key text, stand_system text, quelle text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.lernpfad_darf_lesen(p_student_id), false)) then
    raise exception 'naechste_luecke: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  return query select * from public.naechste_luecke_core(p_student_id);
end;
$$;

create or replace function public.mastery_vorschlaege(p_student_id uuid)
returns table (skill_key text, label text, stand_coach text, coach_grund text, letzte_uebung_am timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.lernpfad_darf_lesen(p_student_id), false)) then
    raise exception 'mastery_vorschlaege: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  return query select * from public.mastery_vorschlaege_core(p_student_id);
end;
$$;

-- ── Fall und Ziel (D) ─────────────────────────────────────────────────────
-- Fall aus dem Check-in: Entscheidung des Coaches, sonst Vorschlag. Klassenarbeit oder
-- Schulthema ohne Thema faellt auf den Lernpfad zurueck (grund nennt das).
create function public.session_fall(p_session_id uuid, p_student_id uuid,
                                    out fall text, out thema_key text, out fall_gewaehlt text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case when coalesce(c.fall_coach, c.fall_vorschlag) in ('klassenarbeit', 'schulthema')
                   and c.ziel_thema_key is not null
              then coalesce(c.fall_coach, c.fall_vorschlag) else 'lernpfad' end,
         case when coalesce(c.fall_coach, c.fall_vorschlag) in ('klassenarbeit', 'schulthema')
              then c.ziel_thema_key end,
         coalesce(c.fall_coach, c.fall_vorschlag)
    from (select 1) d
    left join public.session_checkin c on c.session_id = p_session_id and c.student_id = p_student_id
$$;

-- Heute (in dieser Session) sicher: so viele richtige Antworten ohne Hinweis wie fuer
-- "sicher" im Lernpfad (lernpfad_beleg_core, Regel 2). Gilt auch im Testlauf, der keine
-- Belege bucht.
create function public.session_heute_sicher(p_session_id uuid, p_student_id uuid, p_skill_key text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  -- je Aufgabe, nicht je Teil (Consensus-Check Befund 2: MULTI_PART)
  select count(distinct a.task_id) >= public.lernpfad_stellschraube('mastery_richtig_ohne_hinweis', p_session_id)
    from public.session_antworten a
    join public.tasks t on t.id = a.task_id
   where a.session_id = p_session_id and a.student_id = p_student_id and t.skill_key = p_skill_key
     and a.ergebnis = 'richtig' and a.hinweisstufe_max = 0
$$;

-- Ziel der Stunde als Liste in der Reihenfolge von ziel_fertigkeiten (Voraussetzungen zuerst).
-- offen = weder sicher noch gemeistert (auch nicht heute sicher). Der aktuelle Skill ist die
-- erste offene Zeile. Eine Voraussetzung, deren Stand sich erst in dieser Session geaendert hat
-- (Warm-up-Belege machen sie noch_nicht_sicher bzw. aktiv), bleibt zurueckgestellt, bis der Coach
-- in dieser Session "eine Stufe tiefer" entscheidet (Entscheidung 10: das System schlaegt vor,
-- der Coach entscheidet; pfad_tiefer protokolliert das in lernpfad_protokoll).
create function public.session_zielliste(p_session_id uuid, p_student_id uuid)
returns table (reihenfolge int, skill_key text, label text, rolle text, stand text, offen boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  f       record := public.session_fall(p_session_id, p_student_id);
  v_start timestamptz := (select gestartet_am from public.coaching_sessions where id = p_session_id);
begin
  if f.fall in ('klassenarbeit', 'schulthema') then
    return query
      select z.reihenfolge, z.skill_key, z.label, z.rolle, z.stand,
             not coalesce(z.stand in ('sicher', 'kandidat', 'gemeistert')
                  or (z.rolle like 'voraussetzung%' and z.stand in ('noch_nicht_sicher', 'aktiv')
                      and l.stand_system_seit >= v_start
                      and not exists (select 1 from public.lernpfad_protokoll p
                                       where p.student_id = p_student_id and p.skill_key = z.skill_key
                                         and p.aktion = 'pfad_tiefer' and p.session_id = p_session_id))
                  or public.session_heute_sicher(p_session_id, p_student_id, z.skill_key), false)
        from public.ziel_fertigkeiten_core(p_student_id, f.thema_key) z
        left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = z.skill_key
       order by z.reihenfolge;
  else
    return query
      select 1, n.skill_key, n.label, 'luecke'::text, coalesce(n.stand_system, 'noch_nicht_sicher'),
             not public.session_heute_sicher(p_session_id, p_student_id, n.skill_key)
        from public.naechste_luecke_core(p_student_id) n;
  end if;
end;
$$;

comment on function public.session_zielliste(uuid, uuid) is
  'A2 Ziel der Stunde (D): ziel_fertigkeiten (Klassenarbeit, Schulthema) bzw. naechste_luecke (Lernpfad), mit offen = weder sicher noch gemeistert.';

revoke all on function
  public.session_im_pool(uuid, boolean), public.session_uhr_phase(uuid),
  public.ziel_fertigkeiten_core(uuid, text), public.naechste_luecke_core(uuid), public.mastery_vorschlaege_core(uuid),
  public.session_fall(uuid, uuid), public.session_heute_sicher(uuid, uuid, text), public.session_zielliste(uuid, uuid)
  from public, anon, authenticated;
