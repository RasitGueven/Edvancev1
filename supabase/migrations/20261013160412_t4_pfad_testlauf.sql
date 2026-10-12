-- T4.1 „Tiefer gehen“ im Testlauf wirkt auf den Plan der laufenden Session (Entscheidung Rasit 12.10.2026, Paket T4).
--
-- Seit T2 schreibt pfad_tiefer im Testlauf nichts in lernpfad/lernpfad_protokoll. Der Planer las die Entscheidung aber
-- nur dort (offene-punkte-t2 Punkt 1): ziel_fertigkeiten_core liest lernpfad.stand_system, session_zielliste dazu
-- lernpfad_protokoll (aktion pfad_tiefer, session_id). Im Testlauf blieb der Plan deshalb beim bisherigen Skill.
--
-- Jetzt liest der Planer im Testlauf eine Sicht auf den Lernpfad: die echten Zeilen, darauf in zeitlicher Reihenfolge
-- jede „tiefer“-Entscheidung dieser Session aus session_ereignisse (entscheidung_pfad), so wie pfad_tiefer sie in einer
-- echten Session schreiben wuerde (Voraussetzung -> aktiv, bisheriger Skill aktiv -> offen). Geschrieben wird nichts.
-- Ohne Testlauf ist die Sicht genau lernpfad; ziel_fertigkeiten_core und naechste_luecke_core rufen die neuen
-- Session-Varianten mit p_session_id = null und liefern dasselbe wie vorher.
--
-- ROWS-Schaetzungen der Hilfen: Ein Kind hat wenige Lernpfad-Zeilen; mit der Standardschaetzung (1000) lag der Plan des
-- Planers ueber jit_above_cost und kostete lokal (jit = on) rund 50 ms je Aufruf. Prod hat jit = off.
--
-- Hilfen, nur intern (kein Grant an Clients; alle Aufrufer sind SECURITY DEFINER):
--   session_tiefer_entscheidungen(session, kind) - Ziel und bisheriger Skill je „tiefer“ dieser Session
--   lernpfad_sicht(kind, session)                - lernpfad, im Testlauf mit diesen Entscheidungen
--   ziel_fertigkeiten_sitzung(kind, thema, session), naechste_luecke_sitzung(kind, session)
--                                                - Rumpf der bisherigen *_core, lernpfad durch die Sicht ersetzt

create or replace function public.session_tiefer_entscheidungen(p_session_id uuid, p_student_id uuid)
 returns table(zeit timestamp with time zone, ereignis_id bigint, ziel text, statt text)
 language sql
 stable
 rows 5
 set search_path to 'public', 'pg_temp'
as $function$
  -- pfad_entscheiden: skill_key = neues Ziel, statt = bisheriger Skill.
  -- eingriff_notieren: skill_key = bisheriger Skill, voraussetzung = neues Ziel (fehlt, wenn pfad_tiefer scheiterte).
  select x.zeit, x.id, x.ziel, x.statt
    from (select e.zeit, e.id,
                 case when e.payload ->> 'quelle' = 'eingriff' then e.payload ->> 'voraussetzung'
                      else e.payload ->> 'skill_key' end as ziel,
                 case when e.payload ->> 'quelle' = 'eingriff' then e.payload ->> 'skill_key'
                      else e.payload ->> 'statt' end as statt
            from public.session_ereignisse e
           where e.session_id = p_session_id and e.student_id = p_student_id
             and e.typ = 'entscheidung_pfad' and e.payload ->> 'entscheidung' = 'tiefer') x
   where x.ziel is not null
$function$;

create or replace function public.lernpfad_sicht(p_student_id uuid, p_session_id uuid)
 returns setof public.lernpfad
 language plpgsql
 stable
 rows 30
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v   jsonb;
  d   record;
  alt jsonb;
begin
  if p_session_id is null
     or not coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false) then
    return query select * from public.lernpfad l where l.student_id = p_student_id;
    return;
  end if;

  select coalesce(jsonb_object_agg(l.skill_key, to_jsonb(l)), '{}'::jsonb) into v
    from public.lernpfad l where l.student_id = p_student_id;

  -- Wie pfad_tiefer: Voraussetzung aktiv (seit bleibt, wenn sie schon aktiv war), bisheriger Skill aktiv -> offen.
  for d in select * from public.session_tiefer_entscheidungen(p_session_id, p_student_id) t
            order by t.zeit, t.ereignis_id loop
    alt := v -> d.ziel;
    v := v || jsonb_build_object(d.ziel, coalesce(alt, jsonb_build_object(
           'student_id', p_student_id, 'skill_key', d.ziel, 'quelle', 'coach', 'belege', '[]'::jsonb,
           'angelegt', d.zeit)) || jsonb_build_object(
           'stand_system', 'aktiv',
           'stand_system_seit', case when alt ->> 'stand_system' = 'aktiv' then alt -> 'stand_system_seit'
                                     else to_jsonb(d.zeit) end,
           'aktualisiert', d.zeit));
    if d.statt is not null then
      alt := v -> d.statt;
      if alt is null then
        v := v || jsonb_build_object(d.statt, jsonb_build_object(
               'student_id', p_student_id, 'skill_key', d.statt, 'quelle', 'coach', 'belege', '[]'::jsonb,
               'stand_system', 'offen', 'stand_system_seit', d.zeit, 'angelegt', d.zeit, 'aktualisiert', d.zeit));
      elsif alt ->> 'stand_system' = 'aktiv' then
        v := v || jsonb_build_object(d.statt, alt || jsonb_build_object(
               'stand_system', 'offen', 'stand_system_seit', d.zeit, 'aktualisiert', d.zeit));
      end if;
    end if;
  end loop;

  return query select (jsonb_populate_record(null::public.lernpfad, x.value)).* from jsonb_each(v) x;
end;
$function$;

create or replace function public.ziel_fertigkeiten_sitzung(p_student_id uuid, p_thema_key text, p_session_id uuid)
 returns table(reihenfolge integer, skill_key text, label text, klasse_herkunft integer, rolle text, stand_system text, stand_coach text, stand text, pruefung_faellig boolean)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
begin
  if not exists (select 1 from public.themen t where t.thema_key = p_thema_key) then
    raise exception 'ziel_fertigkeiten: Thema % unbekannt', p_thema_key using errcode = 'P0002';
  end if;

  return query
    with lp as materialized (
      select * from public.lernpfad_sicht(p_student_id, p_session_id)
    ),
    thema as (
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
        join lp l on l.skill_key = d.skill_key
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
      left join lp l on l.skill_key = li.skill_key
     order by 1;
end;
$function$;

create or replace function public.ziel_fertigkeiten_core(p_student_id uuid, p_thema_key text)
 returns table(reihenfolge integer, skill_key text, label text, klasse_herkunft integer, rolle text, stand_system text, stand_coach text, stand text, pruefung_faellig boolean)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
begin
  -- T4: Rumpf in ziel_fertigkeiten_sitzung; ohne Session ist die Sicht genau lernpfad.
  return query select * from public.ziel_fertigkeiten_sitzung(p_student_id, p_thema_key, null);
end;
$function$;

create or replace function public.naechste_luecke_sitzung(p_student_id uuid, p_session_id uuid)
 returns table(skill_key text, label text, thema_key text, stand_system text, quelle text)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
begin

  return query
    select l.skill_key, s.label, st.thema_key, l.stand_system,
           case when l.quelle = 'lsa' and l.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from public.lernpfad_sicht(p_student_id, p_session_id) l
      join public.skills s on s.skill_key = l.skill_key
      left join public.skill_thema st on st.skill_key = l.skill_key
     where l.stand_system = 'aktiv'
       and l.stand_coach is distinct from 'gemeistert'
     order by l.stand_system_seit desc, l.skill_key
     limit 1;
  if found then
    return;
  end if;

  return query
    with luecke as (
      select l.skill_key, l.stand_system, l.quelle, l.belege
        from public.lernpfad_sicht(p_student_id, p_session_id) l
       where l.stand_system = 'noch_nicht_sicher'
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
  if not exists (select 1 from public.lernpfad_sicht(p_student_id, p_session_id) l) then
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
$function$;

create or replace function public.naechste_luecke_core(p_student_id uuid)
 returns table(skill_key text, label text, thema_key text, stand_system text, quelle text)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
begin
  -- T4: Rumpf in naechste_luecke_sitzung; ohne Session ist die Sicht genau lernpfad.
  return query select * from public.naechste_luecke_sitzung(p_student_id, null);
end;
$function$;

create or replace function public.session_zielliste(p_session_id uuid, p_student_id uuid)
 returns table(reihenfolge integer, skill_key text, label text, rolle text, stand text, offen boolean)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
declare
  f       record := public.session_fall(p_session_id, p_student_id);
  v_start timestamptz := (select gestartet_am from public.coaching_sessions where id = p_session_id);
  -- T4: im Testlauf liest der Plan „tiefer“ aus dieser Session (lernpfad_sicht), sonst lernpfad wie bisher.
  v_test  boolean := coalesce((select testlauf from public.coaching_sessions where id = p_session_id), false);
  v_sitz  uuid := case when v_test then p_session_id end;
begin
  if f.fall in ('klassenarbeit', 'schulthema') then
    return query
      select z.reihenfolge, z.skill_key, z.label, z.rolle, z.stand,
             not coalesce(z.stand in ('sicher', 'kandidat', 'gemeistert')
                  or (z.rolle like 'voraussetzung%' and z.stand in ('noch_nicht_sicher', 'aktiv')
                      and l.stand_system_seit >= v_start
                      and not exists (select 1 from public.lernpfad_protokoll p
                                       where p.student_id = p_student_id and p.skill_key = z.skill_key
                                         and p.aktion = 'pfad_tiefer' and p.session_id = p_session_id)
                      and not (v_test and exists (select 1 from public.session_tiefer_entscheidungen(p_session_id, p_student_id) t
                                                   where t.ziel = z.skill_key)))
                  or public.session_heute_sicher(p_session_id, p_student_id, z.skill_key), false)
        from public.ziel_fertigkeiten_sitzung(p_student_id, f.thema_key, v_sitz) z
        left join public.lernpfad_sicht(p_student_id, v_sitz) l on l.skill_key = z.skill_key
       order by z.reihenfolge;
  else
    return query
      select 1, n.skill_key, n.label, 'luecke'::text, coalesce(n.stand_system, 'noch_nicht_sicher'),
             not public.session_heute_sicher(p_session_id, p_student_id, n.skill_key)
        from public.naechste_luecke_sitzung(p_student_id, v_sitz) n;
  end if;
end;
$function$;

revoke all on function public.session_tiefer_entscheidungen(uuid, uuid), public.lernpfad_sicht(uuid, uuid),
                       public.ziel_fertigkeiten_sitzung(uuid, text, uuid), public.naechste_luecke_sitzung(uuid, uuid)
  from public, anon, authenticated;
