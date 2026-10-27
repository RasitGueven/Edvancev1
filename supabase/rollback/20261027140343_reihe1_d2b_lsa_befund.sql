-- Rollback zu reihe1_d2b_lsa_befund: beide Funktionen in der Fassung aus 20261027134914, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen.
create or replace function public.kompetenz_offen_roh(p_kind uuid)
returns table (skill_key text, zustand text, grund text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_klasse integer;
begin
  select s.class_level into v_klasse from public.students s where s.id = p_kind;

  return query
  with recursive
  leads_kind as (
    select l.id from public.leads l where l.converted_student_id = p_kind
    union select s.lead_id from public.students s where s.id = p_kind and s.lead_id is not null
  ),
  -- Regel 2: Schulthema „aktuell“ oder Thema einer angekündigten Klassenarbeit.
  aktuelle_themen as (
    select t.thema_key from public.lead_themen t where t.lead_id in (select id from leads_kind) and t.status = 'aktuell'
    union
    select unnest(k.thema_keys) from public.lead_klassenarbeiten k
     where k.lead_id in (select id from leads_kind) and k.status = 'bevorstehend'
       and (k.datum is null or k.datum >= (now() at time zone 'Europe/Berlin')::date)
  ),
  aktuell as (select distinct st.skill_key from public.skill_thema st where st.thema_key in (select thema_key from aktuelle_themen)),
  -- Regel 3: Voraussetzungen des aktuellen Stoffs, über mehrere Stufen.
  grundlage as (
    select k.voraussetzt_skill_key as skill_key from public.skill_kante k where k.skill_key in (select skill_key from aktuell)
    union
    select k.voraussetzt_skill_key from public.skill_kante k join grundlage g on g.skill_key = k.skill_key
  ),
  -- Befund vor Ort; vom Coach gemeistert gilt als sicher.
  befund as (
    select lp.skill_key, case when lp.stand_coach = 'gemeistert' then 'sicher' else lp.stand_system end as stand_system
      from public.lernpfad lp
     where lp.student_id = p_kind and (lp.stand_system in ('sicher', 'noch_nicht_sicher') or lp.stand_coach = 'gemeistert')
  ),
  voraus as (
    select s.skill_key,
           count(k.voraussetzt_skill_key) as n,
           count(k.voraussetzt_skill_key) filter (where b.stand_system = 'sicher') as sicher
      from public.skills s
      left join public.skill_kante k on k.skill_key = s.skill_key
      left join befund b on b.skill_key = k.voraussetzt_skill_key
     group by s.skill_key
  )
  select s.skill_key,
         case
           when b.stand_system = 'sicher' then 'sicher'
           when b.stand_system = 'noch_nicht_sicher' then 'noch_nicht_sicher'
           when g.grund is not null then 'nicht_angeschaut'
           else 'gesperrt'
         end,
         g.grund
    from public.skills s
    join voraus v on v.skill_key = s.skill_key
    left join befund b on b.skill_key = s.skill_key
    cross join lateral (select case
           when b.skill_key is not null then 'befund'                                         -- Regel 4
           when s.skill_key in (select skill_key from aktuell) then 'aktuell'                  -- Regel 2
           when s.skill_key in (select skill_key from grundlage) then 'grundlage'              -- Regel 3
           when v.n > 0 and v.sicher = v.n then 'voraussetzungen'                              -- Regel 1
           when v_klasse is not null and s.klasse_herkunft < v_klasse then 'frueher'           -- Regel 5
           when v.n = 0 then 'start'                                                           -- ohne Voraussetzung
           else (select o.grund from public.schueler_kompetenz_offen o                         -- Regel 6
                  where o.student_id = p_kind and o.skill_key = s.skill_key)
         end as grund) g
   order by s.skill_key;
end;
$$;

create or replace function public.zeigs_mir_offen(p_kind uuid, p_session uuid)
returns table (skill_key text, vorschlag_am timestamptz, entscheidung text, entschieden_von uuid)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_beginn timestamptz;
begin
  if not public.zeigs_mir_darf(p_kind, p_session) then
    raise exception 'zeigs_mir_offen: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.zeigs_mir z where z.student_id = p_kind and z.session_id = p_session)
     and exists (select 1 from public.coaching_sessions cs
                  where cs.id = p_session and cs.beendet_am is null and not coalesce(cs.testlauf, false)) then
    select coalesce(cs.gestartet_am, cs.scheduled_at, now()) into v_beginn
      from public.coaching_sessions cs where cs.id = p_session;
    -- Entscheidung 5: Skill mit mindestens zwei Quests seit der letzten Session, noch nicht sicher; der meistgeübte.
    insert into public.zeigs_mir (student_id, session_id, skill_key, quests)
    select p_kind, p_session, h.skill_key, count(*)::integer
      from public.home_uebung h
     where h.student_id = p_kind
       and h.am > coalesce(public.home_letzte_session(p_kind, v_beginn), '-infinity'::timestamptz)
       and h.am <= v_beginn
       and not exists (select 1 from public.lernpfad lp
                        where lp.student_id = p_kind and lp.skill_key = h.skill_key and lp.stand_system = 'sicher')
     group by h.skill_key
    having count(*) >= 2
     order by count(*) desc, max(h.am) desc
     limit 1
    on conflict (student_id, session_id) do nothing;
  end if;
  return query
    select z.skill_key, z.vorschlag_am, z.entscheidung, z.entschieden_von
      from public.zeigs_mir z where z.student_id = p_kind and z.session_id = p_session;
end;
$$;

delete from supabase_migrations.schema_migrations where version = '20261027140343';
