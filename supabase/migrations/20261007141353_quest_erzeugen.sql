-- Q1 Home Quests — Aufgabenauswahl und quest_erzeugen (Entscheidung 21).
--
-- Quest A: quest_a_abstand_tage nach der Session, Abruf des Stundenziels (p_skill_keys),
--          gemischt mit Aelterem (Anteil mischanteil der Zeit).
-- Quest B: am Tag vor der naechsten gebuchten Session, ebenso gemischt.
-- KA:      Steht eine Klassenarbeit vor der naechsten Session an, ersetzt ein Paket zum
--          Thema der Klassenarbeit die Quest B (ohne Mischen, wie ka_tage in der Session).
--
-- Aufgaben: status ready, aktiv, kein Tutorial, Uebung, mit Loesungsweg
-- (task_solutions.solution), mit skill_key und est_duration_sec. Summe est_duration_sec
-- hoechstens quest_minuten * 60. "Aelteres" sind bis zum Lernpfad (A1) die Skills aus
-- frueheren Quests des Kindes (offener Punkt).
--
-- Schreibt nur quests und quest_aufgaben (FernUSG: nichts in lsa_*, Lernpfad, Report).

create function public.quest_aufgaben_waehlen(
  p_quest_id   uuid,
  p_student_id uuid,
  p_skill_keys text[],
  p_mischen    boolean
)
returns integer
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_budget   integer := (public.quest_einstellung_zahl('quest_minuten', 10) * 60)::integer;
  v_anteil   numeric := least(greatest(public.quest_einstellung_zahl('mischanteil', 0.30), 0), 1);
  v_alt_max  integer;
  v_summe    integer := 0;
  v_gewaehlt uuid[]  := '{}';
  v_alt      text[];
  r          record;
begin
  v_alt_max := case when p_mischen then floor(v_budget * v_anteil)::integer else 0 end;

  select coalesce(array_agg(distinct t.skill_key), '{}') into v_alt
    from public.quest_aufgaben qa
    join public.quests q on q.id = qa.quest_id
    join public.tasks  t on t.id = qa.task_id
   where q.student_id = p_student_id
     and q.id <> p_quest_id
     and t.skill_key is not null
     and not (t.skill_key = any (p_skill_keys));

  -- Drei Durchgaenge: Aelteres bis zum Mischanteil, dann das Neue, dann mit Aelterem
  -- auffuellen. Bereits in Quests des Kindes genutzte Aufgaben kommen zuletzt dran.
  for r in
    with pool as (
      select t.id, t.est_duration_sec as dauer, t.skill_key,
             exists (select 1 from public.quest_aufgaben qa join public.quests q on q.id = qa.quest_id
                      where qa.task_id = t.id and q.student_id = p_student_id) as genutzt
        from public.tasks t
        join public.task_solutions s on s.task_id = t.id
       where t.status = 'ready'
         and t.is_active
         and not t.is_tutorial
         and t.content_type = 'exercise'
         and t.skill_key is not null
         and t.est_duration_sec is not null
         and nullif(btrim(coalesce(s.solution, '')), '') is not null
    )
    select p.id, p.dauer, d.durchgang
      from (values (1), (2), (3)) as d(durchgang)
      join pool p
        on (d.durchgang in (1, 3) and p.skill_key = any (v_alt))
        or (d.durchgang = 2       and p.skill_key = any (p_skill_keys))
     where d.durchgang <> 1 or p_mischen
     order by d.durchgang, p.genutzt, md5(p_quest_id::text || p.id::text)
  loop
    continue when r.id = any (v_gewaehlt);
    continue when r.durchgang = 1 and v_summe + r.dauer > v_alt_max;
    continue when r.durchgang = 3 and not p_mischen;
    continue when v_summe + r.dauer > v_budget;
    v_gewaehlt := v_gewaehlt || r.id;
    v_summe    := v_summe + r.dauer;
  end loop;

  insert into public.quest_aufgaben (quest_id, task_id, reihenfolge)
  select p_quest_id, g.id, row_number() over (order by md5(p_quest_id::text || g.id::text))
    from unnest(v_gewaehlt) as g(id);

  return coalesce(array_length(v_gewaehlt, 1), 0);
end;
$$;

comment on function public.quest_aufgaben_waehlen(uuid, uuid, text[], boolean) is
  'Waehlt die Aufgaben einer Quest (freigegeben, aktiv, mit Loesungsweg, Summe est_duration_sec <= quest_minuten). Intern.';

revoke all on function public.quest_aufgaben_waehlen(uuid, uuid, text[], boolean) from public, anon, authenticated;

create function public.quest_erzeugen(
  p_session_id    uuid,
  p_student_id    uuid,
  p_skill_keys    text[],
  p_ka_thema_key  text default null,
  p_ka_datum      date default null
)
returns table (quest_id uuid, art text, faellig_ab date, aufgaben integer)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_session   public.coaching_sessions%rowtype;
  v_tag       date;
  v_naechste  date;
  v_anzahl    integer := public.quest_einstellung_zahl('quests_pro_woche', 2)::integer;
  v_abstand   integer := public.quest_einstellung_zahl('quest_a_abstand_tage', 2)::integer;
  v_a_tag     date;
  v_b_tag     date;
  v_ka        boolean;
  v_ka_skills text[];
  v_plan      record;
  v_id        uuid;
  v_n         integer;
begin
  select * into v_session from public.coaching_sessions where id = p_session_id;
  if not found then
    raise exception 'quest_erzeugen: Session unbekannt' using errcode = '22023';
  end if;

  -- coalesce: ohne Profil liefert get_my_role() null, und "not null" liesse durch.
  if not coalesce(public.ist_systemaufruf()
                  or public.get_my_role() = 'admin'
                  or (public.get_my_role() = 'coach' and v_session.coach_id = auth.uid()), false) then
    raise exception 'quest_erzeugen: nur Coach der Session, Admin oder Systemaufruf' using errcode = '42501';
  end if;

  -- FernUSG: solange die Clinic prueft, bleibt home_quests_aktiv aus. Dann legt nur ein
  -- Systemaufruf (Test, Durchlauf) Quests an, nie ein Coach aus dem Check-out.
  if not public.home_quests_aktiv() and not public.ist_systemaufruf() then
    raise exception 'quest_erzeugen: Home Quests sind ausgeschaltet (home_quests_aktiv)' using errcode = '55000';
  end if;

  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance not in ('cancelled', 'cancelled_by_us', 'unexcused')) then
    raise exception 'quest_erzeugen: Kind ist in dieser Session nicht gebucht' using errcode = '22023';
  end if;

  if coalesce(cardinality(p_skill_keys), 0) = 0 and p_ka_thema_key is null then
    raise exception 'quest_erzeugen: skill_keys oder ka_thema_key ist Pflicht' using errcode = '22023';
  end if;

  -- Schon erzeugt: bestehende Quests unveraendert zurueckgeben (wiederholbar).
  if exists (select 1 from public.quests q where q.session_id = p_session_id and q.student_id = p_student_id) then
    return query
      select q.id, q.art, q.faellig_ab, (select count(*)::integer from public.quest_aufgaben qa where qa.quest_id = q.id)
        from public.quests q
       where q.session_id = p_session_id and q.student_id = p_student_id
       order by q.faellig_ab, q.art;
    return;
  end if;

  v_tag := (v_session.scheduled_at at time zone 'Europe/Berlin')::date;

  select min((cs.scheduled_at at time zone 'Europe/Berlin')::date) into v_naechste
    from public.coaching_sessions cs
    join public.session_students ss on ss.session_id = cs.id
   where ss.student_id = p_student_id
     and cs.id <> p_session_id
     and cs.scheduled_at > v_session.scheduled_at
     and ss.attendance not in ('cancelled', 'cancelled_by_us');

  -- Ohne naechste Buchung gilt der Wochenrhythmus (offener Punkt).
  v_b_tag := coalesce(v_naechste, v_tag + 7) - 1;
  v_a_tag := greatest(v_tag + 1, least(v_tag + v_abstand, v_b_tag));

  v_ka := p_ka_thema_key is not null
          and (p_ka_datum is null or (p_ka_datum > v_tag and (v_naechste is null or p_ka_datum <= v_naechste)));
  if v_ka then
    select coalesce(array_agg(distinct k), '{}') into v_ka_skills
      from (select st.skill_key as k from public.skill_thema st where st.thema_key = p_ka_thema_key
            union
            select te.skill_key from public.thema_einstieg te where te.thema_key = p_ka_thema_key) s;
    v_b_tag := greatest(v_tag + 1, least(coalesce(p_ka_datum - 1, v_b_tag), v_b_tag));
  end if;

  -- Neue Quests loesen die offenen aus frueheren Sessions ab.
  update public.quests q
     set status = 'verfallen'
   where q.student_id = p_student_id and q.status = 'offen' and q.session_id <> p_session_id;

  for v_plan in
    select x.art, x.tag, x.skills, x.mischen
      from (values
              (1, 'A',  v_a_tag, p_skill_keys, true),
              (2, case when v_ka then 'KA' else 'B' end, v_b_tag,
                  case when v_ka then v_ka_skills else p_skill_keys end, not v_ka)
           ) as x(nr, art, tag, skills, mischen)
     where x.nr <= v_anzahl
       and coalesce(cardinality(x.skills), 0) > 0
       -- B nur, wenn sie nach A liegt; das KA-Paket immer.
       and (x.nr = 1 or x.art = 'KA' or x.tag > v_a_tag)
     order by x.nr
  loop
    insert into public.quests (student_id, session_id, art, ka_thema_key, faellig_ab)
    values (p_student_id, p_session_id, v_plan.art,
            case when v_plan.art = 'KA' then p_ka_thema_key end, v_plan.tag)
    returning id into v_id;

    v_n := public.quest_aufgaben_waehlen(v_id, p_student_id, v_plan.skills, v_plan.mischen);
    if v_n = 0 then
      -- Ohne passende Aufgabe keine leere Quest.
      delete from public.quests where id = v_id;
      raise notice 'quest_erzeugen: keine freigegebene Aufgabe fuer Quest %', v_plan.art;
      continue;
    end if;

    quest_id := v_id; art := v_plan.art; faellig_ab := v_plan.tag; aufgaben := v_n;
    return next;
  end loop;
end;
$$;

comment on function public.quest_erzeugen(uuid, uuid, text[], text, date) is
  'Legt die Home Quests eines Kindes aus dem Check-out an (A, B oder KA-Paket). Coach der Session, Admin oder System; bei home_quests_aktiv = aus nur System.';

revoke all on function public.quest_erzeugen(uuid, uuid, text[], text, date) from public, anon, authenticated;
grant execute on function public.quest_erzeugen(uuid, uuid, text[], text, date) to authenticated;
