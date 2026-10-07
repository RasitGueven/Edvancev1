-- A2b.1 Was das Tablet liest (Bauauftrag Session-P1, Entscheidungen 29 bis 36; Paket A2b).
--
--   session_pruefung_aktiv  intern: aktive Pruefrage eines Kindes (letztes pruefung-Ereignis = start, danach
--                           kein mastery_entscheiden zum Skill). Das Ereignis schreibt pruefung_aufs_tablet (A2b.3).
--   tablet_stand            ergaenzt um pruefung {skill_label, frage} (nie Erwartung oder Kriterium) und
--                           bestaetigt [{skill_key, skill_label, am}] (in dieser Session gemeistert).
--                           Grundlage: Prod-Definition (pg_get_functiondef 07.10., identisch mit R1).
--   session_kind_kontext    Vornamen, aktuelles Schulthema, moegliche Quest-Termine.
--   session_ziel_kind       Ziel der Stunde fuers Kind: hoechstens drei Fertigkeiten ohne Stand (Entscheidung 35).
--   session_abschluss_kind  geuebte Skills, XP der Session, naechste Session.
-- Die drei neuen Funktionen sind nur fuer das Tablet: das Kind ergibt sich aus session_tablet_platz
-- (42501 fuer jedes andere Konto, auch Coach, Admin und Konto ohne Profil).

create function public.session_pruefung_aktiv(p_session_id uuid, p_student_id uuid,
                                              out skill_key text, out seit timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select e.payload ->> 'skill_key', e.zeit
    from (select x.* from public.session_ereignisse x
           where x.session_id = p_session_id and x.student_id = p_student_id and x.typ = 'pruefung'
           order by x.zeit desc, x.id desc limit 1) e
   where e.payload ->> 'aktion' = 'start'
     and not exists (select 1 from public.lernpfad_protokoll p
                      where p.student_id = p_student_id and p.skill_key = e.payload ->> 'skill_key'
                        and p.aktion = 'mastery' and p.am > e.zeit)
$$;

-- Die Frage, die auf dem Tablet steht: die erste freigegebene Pruefung des Skills (Reihenfolge wie
-- skill_pruefung_lesen, die der Coach sieht).
create function public.session_pruefung_frage(p_skill_key text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.frage from public.skill_pruefung p
   where p.skill_key = p_skill_key and p.status = 'freigegeben'
   order by p.angelegt, p.id limit 1
$$;

create or replace function public.tablet_stand()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets;
  a public.session_ausgegeben;
  pa record;
begin
  select st.* into t from public.session_tablets st
    join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
   where st.geraet_id = auth.uid() and st.geloest_am is null;
  if not found then
    return jsonb_build_object('zugewiesen', false);
  end if;
  a := public.session_aktuelle_ausgabe(t.session_id, t.student_id);
  select * into pa from public.session_pruefung_aktiv(t.session_id, t.student_id);
  return jsonb_build_object(
    'zugewiesen', true,
    'session_id', t.session_id,
    'tablet_nr', t.tablet_nr,
    'vorname', (select coalesce(l.first_name, split_part(l.full_name, ' ', 1)) from public.leads l
                 where l.id = public.session_lead_von_kind(t.student_id)),
    'phase', public.session_phase(t.session_id, t.student_id),
    'checkin_fertig', exists (select 1 from public.session_checkin c where c.session_id = t.session_id
                               and c.student_id = t.student_id and c.kind_am is not null),
    'aufgabe', case when a.id is null then null else public.lsa_question_payload(a.task_id) end,
    -- A2b (Entscheidung 31): nur Label und Frage, nie Erwartung oder Kriterium.
    'pruefung', case when pa.skill_key is null then null else jsonb_build_object(
        'skill_label', public.session_label(pa.skill_key),
        'frage', public.session_pruefung_frage(pa.skill_key)) end,
    -- A2b (Entscheidung 34): gemeistert erst nach der Bestaetigung des Coaches in dieser Session.
    'bestaetigt', coalesce((select jsonb_agg(jsonb_build_object('skill_key', l.skill_key,
                    'skill_label', public.session_label(l.skill_key), 'am', l.coach_am) order by l.coach_am)
                  from public.lernpfad l
                 where l.student_id = t.student_id and l.coach_session_id = t.session_id
                   and l.stand_coach = 'gemeistert'), '[]'::jsonb));
end;
$$;

create function public.session_kind_kontext(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'session_kind_kontext');
  s      public.coaching_sessions;
  v_tag  date;
  v_ab   int;
  v_th   text := public.session_schulthema(t.student_id);
begin
  select * into s from public.coaching_sessions where id = p_session_id;
  v_tag := (s.scheduled_at at time zone 'Europe/Berlin')::date;
  v_ab := public.quest_einstellung_zahl('quest_a_abstand_tage', 2, p_session_id)::int;
  return jsonb_build_object(
    'vorname', (select coalesce(l.first_name, split_part(l.full_name, ' ', 1)) from public.leads l
                 where l.id = public.session_lead_von_kind(t.student_id)),
    'coach_vorname', (select split_part(p.full_name, ' ', 1) from public.profiles p where p.id = s.coach_id),
    'schulthema', case when v_th is null then null else jsonb_build_object(
        'thema_key', v_th, 'label', (select th.label from public.themen th where th.thema_key = v_th)) end,
    -- Entscheidung 21: Quest A zwei bis drei Tage nach der Session, Quest B am Tag vor der naechsten.
    'quest_termine', case when not coalesce(public.home_quests_aktiv(p_session_id), false) then null
      else jsonb_build_object(
        'quest_a', jsonb_build_array(v_tag + v_ab, v_tag + v_ab + 1),
        'quest_b', (select (min(cs.scheduled_at) at time zone 'Europe/Berlin')::date - 1
                      from public.session_students ss join public.coaching_sessions cs on cs.id = ss.session_id
                     where ss.student_id = t.student_id and ss.attendance = 'planned'
                       and cs.scheduled_at > s.scheduled_at)) end);
end;
$$;

create function public.session_ziel_kind(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'session_ziel_kind');
  c      public.session_checkin;
  v_ab   int;
begin
  select * into c from public.session_checkin where session_id = p_session_id and student_id = t.student_id;
  -- Entscheidung 3/35: das Ziel zeigt das Tablet erst, wenn der Coach den Fall gewaehlt hat.
  if c.fall_coach is null then
    return jsonb_build_object('fall', null, 'thema_label', null, 'klassenarbeit_datum', c.klassenarbeit_datum,
                              'fertigkeiten', '[]'::jsonb);
  end if;
  -- ab dem aktuellen Skill (erste offene Zeile), ohne offene: der letzte (Vertiefung)
  select coalesce(min(z.reihenfolge) filter (where z.offen), max(z.reihenfolge)) into v_ab
    from public.session_zielliste(p_session_id, t.student_id) z;
  return jsonb_build_object(
    'fall', c.fall_coach,
    'thema_label', (select th.label from public.themen th where th.thema_key = c.ziel_thema_key),
    'klassenarbeit_datum', c.klassenarbeit_datum,
    -- Entscheidung 35: hoechstens drei, ohne Stand, Prozent oder Farbe.
    'fertigkeiten', coalesce((select jsonb_agg(jsonb_build_object('label', z.label, 'aktuell', z.reihenfolge = v_ab,
                       'neu', not exists (select 1 from public.lernpfad_belege b
                                           where b.student_id = t.student_id and b.skill_key = z.skill_key)
                              and not exists (select 1 from public.session_antworten a join public.tasks tk on tk.id = a.task_id
                                               where a.student_id = t.student_id and tk.skill_key = z.skill_key))
                       order by z.reihenfolge)
                     from (select * from public.session_zielliste(p_session_id, t.student_id) z0
                            where z0.reihenfolge >= v_ab order by z0.reihenfolge limit 3) z), '[]'::jsonb));
end;
$$;

create function public.session_abschluss_kind(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets := public.session_tablet_platz(p_session_id, 'session_abschluss_kind');
begin
  return jsonb_build_object(
    'geuebt', coalesce((select jsonb_agg(public.session_label(g.skill_key) order by g.erst)
                          from (select x.skill_key, min(x.id) as erst from public.session_schritte x
                                 where x.session_id = p_session_id and x.student_id = t.student_id and x.phase = 'kern'
                                   and x.art = 'aufgabe' and not x.eingemischt and x.skill_key is not null
                                 group by x.skill_key order by min(x.id) limit 3) g), '[]'::jsonb),
    'xp', coalesce((select sum(e.xp) from public.xp_events e
                     where e.student_id = t.student_id and e.buchungs_schluessel = 'session:' || p_session_id), 0),
    'naechste_session', (select min(cs.scheduled_at)
                           from public.session_students ss join public.coaching_sessions cs on cs.id = ss.session_id
                          where ss.student_id = t.student_id and ss.attendance = 'planned'
                            and cs.scheduled_at > (select scheduled_at from public.coaching_sessions where id = p_session_id)));
end;
$$;

revoke all on function
  public.session_pruefung_aktiv(uuid, uuid), public.session_pruefung_frage(text),
  public.session_kind_kontext(uuid), public.session_ziel_kind(uuid), public.session_abschluss_kind(uuid)
  from public, anon, authenticated;
grant execute on function
  public.session_kind_kontext(uuid), public.session_ziel_kind(uuid), public.session_abschluss_kind(uuid)
  to authenticated;
