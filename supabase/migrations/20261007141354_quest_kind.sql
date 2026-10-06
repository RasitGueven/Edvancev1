-- Q1 Home Quests — Termin, Inhalt, Erledigt (Entscheidung 21).
--
--   quest_termin_setzen  Coach der Session, Admin oder das Konto des Kindes (Tablet im
--                        Check-out; die Tablet-Zuordnung baut R1, offener Punkt).
--   quest_inhalt         Aufgaben MIT Loesungsweg zur Selbstkontrolle, nur fuer das Konto
--                        des Kindes und erst ab faellig_ab. Bewusste Ausnahme zu INV-6:
--                        die Selbstkontrolle braucht den Loesungsweg (Consensus-Check im PR).
--   quest_erledigt       Status erledigt, XP genau einmal, Wochenserie. Nimmt keine
--                        Antworten an und speichert kein richtig oder falsch.
--
-- Keine dieser Funktionen schreibt in lsa_*, session_antworten, lernpfad,
-- student_task_progress, behavior_snapshots oder Reports (FernUSG, Test 5).

create function public.quest_termin_setzen(p_quest_id uuid, p_termin timestamptz)
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
    raise exception 'quest_termin_setzen: Quest unbekannt' using errcode = '22023';
  end if;
  select cs.coach_id into v_coach from public.coaching_sessions cs where cs.id = v_quest.session_id;

  -- coalesce: ein null-Vergleich (kein Profil, kein Schuelerkonto) darf nie durchlassen.
  if not coalesce(public.get_my_role() = 'admin'
                  or (public.get_my_role() = 'coach' and v_coach = auth.uid())
                  or public.get_my_student_id() = v_quest.student_id, false) then
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

comment on function public.quest_termin_setzen(uuid, timestamptz) is
  'Setzt den Termin einer offenen Quest (frühestens faellig_ab). Coach der Session, Admin oder das Kind.';

create function public.quest_inhalt(p_quest_id uuid)
returns table (
  reihenfolge     smallint,
  task_id         uuid,
  titel           text,
  aufgabe         jsonb,
  loesungsweg     text,
  dauer_sec       integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_quest public.quests%rowtype;
begin
  select q.* into v_quest from public.quests q where q.id = p_quest_id;
  if not found then
    raise exception 'quest_inhalt: Quest unbekannt' using errcode = '22023';
  end if;
  -- Nur das Konto des Kindes. Die Anmeldung zuhause mit Zugangscode kommt mit der
  -- Schueler-App (offener Punkt); Coach, Eltern und Admin bekommen hier nichts.
  if public.get_my_student_id() is distinct from v_quest.student_id then
    raise exception 'quest_inhalt: nur fuer das Kind dieser Quest' using errcode = '42501';
  end if;
  if v_quest.status = 'verfallen' then
    raise exception 'quest_inhalt: Quest ist verfallen' using errcode = '55000';
  end if;
  if v_quest.faellig_ab > (now() at time zone 'Europe/Berlin')::date then
    raise exception 'quest_inhalt: Quest ist erst ab % abrufbar', v_quest.faellig_ab using errcode = '55000';
  end if;

  return query
    select qa.reihenfolge, t.id, t.title, public.lsa_question_payload(t.id), s.solution, t.est_duration_sec
      from public.quest_aufgaben qa
      join public.tasks t           on t.id = qa.task_id
      join public.task_solutions s  on s.task_id = t.id
     where qa.quest_id = p_quest_id
     order by qa.reihenfolge;
end;
$$;

comment on function public.quest_inhalt(uuid) is
  'Aufgaben einer Quest mit Loesungsweg zur Selbstkontrolle. Nur das Konto des Kindes, ab faellig_ab.';

create function public.quest_erledigt(p_quest_id uuid)
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
    raise exception 'quest_erledigt: Quest unbekannt' using errcode = '22023';
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

  -- XP fuers Bearbeiten, nie fuers Richtig-Haben. Bis X0 xp_buchen liefert, bucht diese
  -- Funktion als Definer direkt in xp_events (Trigger apply_xp_event summiert).
  v_xp := greatest(public.quest_einstellung_zahl('quest_xp', 50)::integer, 0);

  update public.quests
     set status = 'erledigt', erledigt_am = now(), xp_gebucht = v_xp
   where id = p_quest_id;

  if v_xp > 0 then
    insert into public.xp_events (student_id, task_id, xp, reason)
    values (v_quest.student_id, null, v_xp, 'home_quest');
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

comment on function public.quest_erledigt(uuid) is
  'Markiert eine Quest als erledigt, bucht quest_xp genau einmal und fuehrt die Wochenserie (pausiert, setzt nie zurueck). Speichert keine Antworten.';

revoke all on function public.quest_termin_setzen(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.quest_inhalt(uuid)                     from public, anon, authenticated;
revoke all on function public.quest_erledigt(uuid)                   from public, anon, authenticated;
grant execute on function public.quest_termin_setzen(uuid, timestamptz) to authenticated;
grant execute on function public.quest_inhalt(uuid)                     to authenticated;
grant execute on function public.quest_erledigt(uuid)                   to authenticated;
