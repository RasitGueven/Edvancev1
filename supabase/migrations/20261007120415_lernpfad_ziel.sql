-- Session-Rahmen P1, Paket A1 — Ziel der Stunde und „eine Stufe tiefer“.
--
--   ziel_fertigkeiten  die Liste „Ziel der Stunde“ im Coach-Live-Dummy
--                      (Schublade je Kind): Fertigkeiten des Themas
--                      (skill_thema, thema_einstieg), darunter die fehlenden
--                      Voraussetzungen ueber skill_kante, dazu die direkten
--                      Voraussetzungen, die schon sicher sind (Warm-up,
--                      Entscheidung 10; im Dummy „sicher · Voraussetzung“).
--                      Stand aus dem Lernpfad; „gemeistert“ nur aus stand_coach.
--   pfad_tiefer        Warm-up-Entscheidung bzw. Interventionsstufe 4: die
--                      passende Voraussetzung wird aktiv, der bisherige Skill
--                      wartet („danach“). Eine Coach-Entscheidung, protokolliert.
--
-- Graph-Reihenfolge: Voraussetzungen vor dem, was auf ihnen aufbaut. Gerechnet
-- als Anzahl der Listen-Skills in der Voraussetzungs-Huelle (lsa_abschluss);
-- setzt A B voraus, liegt B damit sicher vor A.

create function public.ziel_fertigkeiten(p_student_id uuid, p_thema_key text)
returns table (
  reihenfolge     int,
  skill_key       text,
  label           text,
  klasse_herkunft int,
  rolle           text,
  stand_system    text,
  stand_coach     text,
  stand           text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'ziel_fertigkeiten: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
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
                else coalesce(l.stand_system, 'offen') end
      from liste li
      join public.skills s on s.skill_key = li.skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = li.skill_key
     order by 1;
end;
$$;

comment on function public.ziel_fertigkeiten(uuid, text) is
  'Ziel der Stunde: Fertigkeiten des Themas, fehlende Voraussetzungen (skill_kante) und sichere direkte Voraussetzungen, in Graph-Reihenfolge, mit Stand aus dem Lernpfad. Admin oder Coach bei laufendem Vertrag.';

create function public.pfad_tiefer(
  p_student_id    uuid,
  p_skill_key     text,
  p_session_id    uuid default null,
  p_voraussetzung text default null
)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ziel     text;
  v_alt      public.lernpfad;
begin
  if not (public.ist_systemaufruf()
          or coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'pfad_tiefer: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'pfad_tiefer: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;

  if p_voraussetzung is not null then
    if p_voraussetzung not in (select a.skill_key from public.lsa_abschluss(p_skill_key) a) then
      raise exception 'pfad_tiefer: % ist keine Voraussetzung von %', p_voraussetzung, p_skill_key
        using errcode = '22023';
    end if;
    v_ziel := p_voraussetzung;
  else
    -- Direkte Voraussetzung, die noch nicht sicher ist: zuerst belegte
    -- Luecken, dann aktive, dann unbekannte; bei Gleichstand die hoehere Klasse.
    select k.voraussetzt_skill_key into v_ziel
      from public.skill_kante k
      join public.skills s on s.skill_key = k.voraussetzt_skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = k.voraussetzt_skill_key
     where k.skill_key = p_skill_key
       and coalesce(l.stand_system, 'offen') not in ('sicher', 'kandidat')
       and l.stand_coach is distinct from 'gemeistert'
     order by case coalesce(l.stand_system, 'offen')
                when 'noch_nicht_sicher' then 0 when 'aktiv' then 1 else 2 end,
              s.klasse_herkunft desc, k.voraussetzt_skill_key
     limit 1;
    if v_ziel is null then
      raise exception 'pfad_tiefer: % hat keine offene Voraussetzung', p_skill_key using errcode = 'P0002';
    end if;
  end if;

  select * into v_alt from public.lernpfad
   where student_id = p_student_id and skill_key = v_ziel
   for update;
  if v_alt.stand_system = 'kandidat' or v_alt.stand_coach = 'gemeistert' then
    raise exception 'pfad_tiefer: % ist Mastery-Kandidat oder gemeistert', v_ziel using errcode = 'P0001';
  end if;

  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, v_ziel, 'aktiv', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'aktiv',
         stand_system_seit = case when public.lernpfad.stand_system = 'aktiv'
                                  then public.lernpfad.stand_system_seit else now() end,
         aktualisiert      = now();

  -- Der bisherige Skill wartet, bis die Voraussetzung sitzt.
  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, p_skill_key, 'offen', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'offen',
         stand_system_seit = now(),
         aktualisiert      = now()
   where public.lernpfad.stand_system = 'aktiv';

  insert into public.lernpfad_protokoll (student_id, skill_key, aktion, alt, neu, von, session_id)
  values (p_student_id, v_ziel, 'pfad_tiefer',
          jsonb_build_object('stand_system', v_alt.stand_system),
          jsonb_build_object('stand_system', 'aktiv', 'statt', p_skill_key),
          auth.uid(), p_session_id);

  return v_ziel;
end;
$$;

comment on function public.pfad_tiefer(uuid, text, uuid, text) is
  'Eine Stufe tiefer: setzt die passende (oder die genannte) Voraussetzung auf aktiv, der bisherige Skill wartet. Coach der Session oder Admin; protokolliert.';

revoke all on function public.ziel_fertigkeiten(uuid, text) from public, anon, authenticated;
revoke all on function public.pfad_tiefer(uuid, text, uuid, text) from public, anon, authenticated;
grant execute on function public.ziel_fertigkeiten(uuid, text) to authenticated;
grant execute on function public.pfad_tiefer(uuid, text, uuid, text) to authenticated;
