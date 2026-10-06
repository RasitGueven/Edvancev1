-- A2.4 Verdrahtung Q1 (Entscheidung A2 B; offene-punkte-q1 1, 5).
--
-- Grundlage: Definitionen in Prod (pg_get_functiondef 06.10., identisch mit den Migrationen).
--   quest_einstellung, quest_einstellung_zahl, home_quests_aktiv  lesen mit Session den Snapshot
--       (coaching_sessions.einstellungen), ohne Session wie bisher die Tabelle, dann den Startwert.
--       Interne Funktionen ohne EXECUTE fuer authenticated; ersetzt (drop/create), nicht ueberladen.
--   quest_erzeugen, quest_aufgaben_waehlen, quest_erledigt  geben ihre Session mit.
--   quest_termin_setzen(quest, termin)  auch vom Tablet des Kindes in der Session der Quest.

drop function public.home_quests_aktiv();
drop function public.quest_einstellung_zahl(text, numeric);

drop function public.quest_einstellung(text);

create function public.quest_einstellung(p_schluessel text, p_session_id uuid default null)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_wert text;
begin
  -- A2 (B): mit Session aus dem Snapshot.
  if p_session_id is not null then
    select cs.einstellungen ->> p_schluessel into v_wert from public.coaching_sessions cs where cs.id = p_session_id;
  end if;
  if v_wert is null and to_regclass('public.session_einstellungen') is not null then
    begin
      execute 'select wert::text from public.session_einstellungen where schluessel = $1'
         into v_wert using p_schluessel;
    exception when undefined_column or undefined_table then
      v_wert := null;
    end;
  end if;

  v_wert := nullif(btrim(v_wert, ' "'), '');
  return coalesce(v_wert, case p_schluessel
    when 'quests_pro_woche'     then '2'
    when 'quest_minuten'        then '10'
    when 'quest_a_abstand_tage' then '2'
    when 'quest_xp'             then '50'
    when 'mischanteil'          then '0.30'
    when 'home_quests_aktiv'    then 'aus'
  end);
end;
$$;

create function public.quest_einstellung_zahl(p_schluessel text, p_rueckfall numeric, p_session_id uuid default null)
returns numeric
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  return coalesce(public.quest_einstellung(p_schluessel, p_session_id)::numeric, p_rueckfall);
exception when invalid_text_representation then
  return p_rueckfall;
end;
$$;

create function public.home_quests_aktiv(p_session_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select lower(coalesce(public.quest_einstellung('home_quests_aktiv', p_session_id), 'aus')) in ('an', 'true', '1', 'ja');
$$;

revoke all on function public.quest_einstellung(text, uuid) from public, anon, authenticated;
revoke all on function public.quest_einstellung_zahl(text, numeric, uuid) from public, anon, authenticated;
revoke all on function public.home_quests_aktiv(uuid) from public, anon, authenticated;

create or replace function public.quest_aufgaben_waehlen(
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
  v_budget   integer := (public.quest_einstellung_zahl('quest_minuten', 10,
                  (select q.session_id from public.quests q where q.id = p_quest_id)) * 60)::integer;
  v_anteil   numeric := least(greatest(public.quest_einstellung_zahl('mischanteil', 0.30,
                  (select q.session_id from public.quests q where q.id = p_quest_id)), 0), 1);
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
         and 'quest' = any (t.einsatz)
         and not (t.einsatz && array['lsa', 'session']::text[])
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

create or replace function public.quest_erzeugen(
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
  v_anzahl    integer := public.quest_einstellung_zahl('quests_pro_woche', 2, p_session_id)::integer;
  v_abstand   integer := public.quest_einstellung_zahl('quest_a_abstand_tage', 2, p_session_id)::integer;
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
    -- Nur Admin und System erfahren, dass es die Session nicht gibt (kein Existenz-Orakel).
    if coalesce(public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin', false) then
      raise exception 'quest_erzeugen: Session unbekannt' using errcode = '22023';
    end if;
    raise exception 'quest_erzeugen: kein Zugriff' using errcode = '42501';
  end if;

  -- coalesce: ohne Profil liefert get_my_role() null, und "not null" liesse durch.
  if not coalesce(public.ist_systemaufruf()
                  or coalesce(public.get_my_role(), '') = 'admin'
                  or (coalesce(public.get_my_role(), '') = 'coach' and v_session.coach_id = auth.uid()
                      and public.hat_zugang(p_student_id)), false) then
    raise exception 'quest_erzeugen: nur Coach der Session (bei laufendem Vertrag), Admin oder Systemaufruf' using errcode = '42501';
  end if;

  -- FernUSG: solange die Clinic prueft, bleibt home_quests_aktiv aus. Dann legt nur ein
  -- Systemaufruf (Test, Durchlauf) Quests an, nie ein Coach aus dem Check-out.
  if not public.home_quests_aktiv(p_session_id) and not public.ist_systemaufruf() then
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

  -- Parallele Aufrufe fuer dasselbe Kind und dieselbe Session nacheinander.
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text || p_student_id::text, 0));

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

create or replace function public.quest_erledigt(p_quest_id uuid)
returns table (status text, xp_neu integer, wochenserie integer)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_quest  public.quests%rowtype;
  v_xp     integer;
  v_woche  date := date_trunc('week', now() at time zone 'Europe/Berlin')::date;
  v_serie  integer;
begin
  select q.* into v_quest from public.quests q where q.id = p_quest_id for update;
  if not found then
    raise exception 'quest_erledigt: kein Zugriff' using errcode = '42501';
  end if;
  if public.get_my_student_id() is distinct from v_quest.student_id then
    raise exception 'quest_erledigt: nur fuer das Kind dieser Quest' using errcode = '42501';
  end if;

  if v_quest.status = 'erledigt' then
    -- Zweiter Aufruf: nichts buchen.
    select sp.home_streak_sessions into v_serie from public.student_progress sp where sp.student_id = v_quest.student_id;
    status := 'erledigt'; xp_neu := 0; wochenserie := coalesce(v_serie, 0);
    return next;
    return;
  end if;
  if v_quest.status = 'verfallen' then
    raise exception 'quest_erledigt: Quest ist verfallen' using errcode = '55000';
  end if;
  if v_quest.faellig_ab > (now() at time zone 'Europe/Berlin')::date then
    raise exception 'quest_erledigt: Quest ist erst ab % abrufbar', v_quest.faellig_ab using errcode = '55000';
  end if;

  -- XP fuers Bearbeiten, nie fuers Richtig-Haben. Gebucht wird ueber den Kern von xp_buchen
  -- (X0); der Schluessel quest:<id> bucht je Quest genau einmal, auch neben xp_gebucht.
  v_xp := least(greatest(public.quest_einstellung_zahl('quest_xp', 50, v_quest.session_id)::integer, 0), 1000);

  update public.quests
     set status = 'erledigt', erledigt_am = now(), xp_gebucht = v_xp
   where id = p_quest_id;

  if v_xp > 0 and not public.xp_buchen_intern(v_quest.student_id, v_xp, 'home_quest', 'quest:' || p_quest_id) then
    -- Schluessel schon gebucht (darf bei xp_gebucht = null nicht vorkommen): nichts doppelt.
    v_xp := 0;
    update public.quests set xp_gebucht = 0 where id = p_quest_id;
  end if;

  -- Wochenserie: jede Kalenderwoche (Europe/Berlin) mit mindestens einer erledigten
  -- Quest zaehlt einmal. Eine Woche ohne Quest pausiert die Serie; sie wird nie zurueckgesetzt.
  insert into public.student_progress as sp (student_id, home_streak_sessions, home_streak_last_completed_at)
  values (v_quest.student_id, 1, now())
  on conflict (student_id) do update
     set home_streak_sessions = sp.home_streak_sessions
           + case when sp.home_streak_last_completed_at is null
                    or date_trunc('week', sp.home_streak_last_completed_at at time zone 'Europe/Berlin')::date < v_woche
                  then 1 else 0 end,
         home_streak_last_completed_at = now()
  returning sp.home_streak_sessions into v_serie;

  status := 'erledigt'; xp_neu := v_xp; wochenserie := v_serie;
  return next;
end;
$$;

create or replace function public.quest_termin_setzen(p_quest_id uuid, p_termin timestamptz)
returns timestamptz
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_quest public.quests%rowtype;
  v_coach uuid;
begin
  select q.* into v_quest from public.quests q where q.id = p_quest_id for update;
  if not found then
    raise exception 'quest_termin_setzen: kein Zugriff' using errcode = '42501';
  end if;
  select cs.coach_id into v_coach from public.coaching_sessions cs where cs.id = v_quest.session_id;

  -- coalesce: ein null-Vergleich (kein Profil, kein Schuelerkonto) darf nie durchlassen.
  if not coalesce(coalesce(public.get_my_role(), '') = 'admin'
                  or (coalesce(public.get_my_role(), '') = 'coach' and v_coach = auth.uid()
                      and public.hat_zugang(v_quest.student_id))
                  or public.get_my_student_id() = v_quest.student_id
                  -- A2: das Tablet des Kindes in der laufenden Session der Quest (offene-punkte-q1 5).
                  or exists (select 1 from public.session_tablets st
                               join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                              where st.session_id = v_quest.session_id and st.student_id = v_quest.student_id
                                and st.geraet_id = auth.uid() and st.geloest_am is null), false) then
    raise exception 'quest_termin_setzen: nur Coach der Session, Admin oder das Kind' using errcode = '42501';
  end if;

  if v_quest.status <> 'offen' then
    raise exception 'quest_termin_setzen: Quest ist nicht offen' using errcode = '55000';
  end if;
  if p_termin is null or (p_termin at time zone 'Europe/Berlin')::date < v_quest.faellig_ab then
    raise exception 'quest_termin_setzen: Termin frühestens am %', v_quest.faellig_ab using errcode = '22023';
  end if;

  update public.quests set termin = p_termin where id = p_quest_id;
  return p_termin;
end;
$$;
