-- C2.2 Briefing („Vorher“) der Coach-Live-Sicht (Bauauftrag Session-P1, offene-punkte-r1 Nr. 19,
-- offene-punkte-c1 Nr. 8).
--
-- session_briefing(p_session_id): je gebuchtes Kind mit laufendem Vertrag (akte_aktiv, Entscheidung 26)
--   letzte_session      vorige abgeschlossene Session: Tag, Fall, Ziel, Exit-Ergebnis, Notiz, Coach
--   schulthema          aktuelles Schulthema mit Alter; nachfragen = aelter als thema_alt_tage
--   klassenarbeit       juengste angekuendigte Klassenarbeit ab heute (Check-in einer Session)
--   pruefungen_faellig  Mastery-Kandidaten, deren Pruefung faellig ist (lernpfad_pruefung_faellig)
--   flags_offen         offene Flags aus frueheren Check-outs
--   quests_woche        Home Quests der letzten sieben Tage, nur Zahlen erledigt/offen, nie Inhalte
--   naechste_luecke     Ziel fuer den Fall Lernpfad (A1)
--   erste_session       keine fruehere abgeschlossene Session
-- Kinder ohne laufenden Vertrag fehlen (auch fuer Admins: das Briefing ist Akten-Lesen).
-- Testlaeufe zaehlen nur in einem Testlauf (Entscheidung 27: nie in Akten echter Kinder).
--
-- Rechte: Coach der Session oder Admin ueber session_coach_pruefen (NULL-sicher, Konto ohne Profil 42501,
-- Schuelerkonto 42501). Muster SECURITY DEFINER wie 20261004001333_lead_thema_setzen.sql.

create function public.session_briefing(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s       public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'session_briefing');
  v_alt   int := coalesce(public.session_wert(p_session_id, 'thema_alt_tage') #>> '{}', '21')::int;
  v_heute date := (now() at time zone 'Europe/Berlin')::date;
begin
  return coalesce((
    select jsonb_agg(b.j order by b.j ->> 'name')
      from (
        select jsonb_build_object(
          'student_id', ss.student_id,
          'name', public.session_kind_name(ss.student_id),
          'klasse', st.class_level,
          'letzte_session', (
            select jsonb_build_object(
                     'session_id', cs.id, 'am', cs.scheduled_at,
                     'fall', coalesce(c.fall_coach, c.fall_vorschlag),
                     'ziel_thema_key', c.ziel_thema_key,
                     'ziel_thema_label', (select th.label from public.themen th where th.thema_key = c.ziel_thema_key),
                     'exit_ergebnis', a.exit_ergebnis,
                     'notiz', a.notiz,
                     'coach_name', (select p.full_name from public.profiles p where p.id = cs.coach_id),
                     'signale', (select count(*) from public.session_ereignisse e
                                  where e.session_id = cs.id and e.student_id = ss.student_id and e.typ = 'signal'))
              from public.session_students x
              join public.coaching_sessions cs on cs.id = x.session_id
              left join public.session_checkin c on c.session_id = cs.id and c.student_id = x.student_id
              left join public.session_kind_abschluss a on a.session_id = cs.id and a.student_id = x.student_id
             where x.student_id = ss.student_id and cs.id <> s.id and cs.status = 'done'
               and cs.scheduled_at < s.scheduled_at and (s.testlauf or not cs.testlauf)
             order by cs.scheduled_at desc limit 1),
          'schulthema', (
            select jsonb_build_object(
                     'thema_key', lt.thema_key,
                     'label', (select th.label from public.themen th where th.thema_key = lt.thema_key),
                     'seit', lt.angelegt,
                     'tage', v_heute - (lt.angelegt at time zone 'Europe/Berlin')::date,
                     'nachfragen', v_heute - (lt.angelegt at time zone 'Europe/Berlin')::date > v_alt)
              from public.lead_themen lt
             where lt.lead_id = public.session_lead_von_kind(ss.student_id) and lt.status = 'aktuell'
             order by lt.angelegt desc limit 1),
          'klassenarbeit', (
            select jsonb_build_object(
                     'datum', c.klassenarbeit_datum, 'thema_key', c.klassenarbeit_thema_key,
                     'label', (select th.label from public.themen th where th.thema_key = c.klassenarbeit_thema_key))
              from public.session_checkin c
              join public.coaching_sessions cs on cs.id = c.session_id
             where c.student_id = ss.student_id and c.klassenarbeit_datum >= v_heute
               and (s.testlauf or not cs.testlauf)
             order by c.kind_am desc nulls last, cs.scheduled_at desc limit 1),
          'pruefungen_faellig', coalesce((
            select jsonb_agg(jsonb_build_object('skill_key', l.skill_key, 'label', public.session_label(l.skill_key))
                             order by l.skill_key)
              from public.lernpfad l
             where l.student_id = ss.student_id and public.lernpfad_pruefung_faellig(ss.student_id, l.skill_key)), '[]'),
          'flags_offen', coalesce((
            select jsonb_agg(f.j order by f.am) from (
              select jsonb_build_object('flag', 'eltern', 'session_id', cs.id, 'am', cs.scheduled_at) j, cs.scheduled_at am
                from public.session_kind_abschluss a join public.coaching_sessions cs on cs.id = a.session_id
               where a.student_id = ss.student_id and a.flag_eltern and a.flag_eltern_erledigt_am is null
                 and cs.id <> s.id and (s.testlauf or not cs.testlauf)
              union all
              select jsonb_build_object('flag', 'pfad', 'session_id', cs.id, 'am', cs.scheduled_at), cs.scheduled_at
                from public.session_kind_abschluss a join public.coaching_sessions cs on cs.id = a.session_id
               where a.student_id = ss.student_id and a.flag_pfad and a.flag_pfad_erledigt_am is null
                 and cs.id <> s.id and (s.testlauf or not cs.testlauf)) f), '[]'),
          -- Nur Zahlen, nie Aufgaben oder Antworten (Entscheidung 4, FernUSG).
          'quests_woche', (
            select jsonb_build_object('erledigt', count(*) filter (where q.status = 'erledigt'),
                                      'offen', count(*) filter (where q.status <> 'erledigt'))
              from public.quests q
             where q.student_id = ss.student_id
               and coalesce(q.termin, q.faellig_ab::timestamptz) between now() - interval '7 days' and now()),
          'naechste_luecke', (
            select jsonb_build_object('skill_key', n.skill_key, 'label', n.label, 'quelle', n.quelle)
              from public.naechste_luecke_core(ss.student_id) n limit 1),
          'erste_session', not exists (
            select 1 from public.session_students x join public.coaching_sessions cs on cs.id = x.session_id
             where x.student_id = ss.student_id and cs.id <> s.id and cs.status = 'done'
               and (s.testlauf or not cs.testlauf))) as j
          from public.session_students ss
          join public.students st on st.id = ss.student_id
         where ss.session_id = p_session_id and public.akte_aktiv(ss.student_id)
      ) b), '[]'::jsonb);
end;
$$;

comment on function public.session_briefing(uuid) is
  'C2: Briefing je gebuchtes Kind mit laufendem Vertrag (Coach der Session oder Admin). Quests nur erledigt/offen.';

revoke all on function public.session_briefing(uuid) from public, anon, authenticated;
grant execute on function public.session_briefing(uuid) to authenticated;
