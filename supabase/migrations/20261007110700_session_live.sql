-- R1.4 Live-Sicht des Coaches (Entscheidung 17, C0 Abschnitt 2 und 4).
--
-- Eine Lesefunktion fuer den ganzen Raum (coach_raum_live), alle paar Sekunden
-- abgefragt (kein Realtime), und eine fuer die Schublade je Kind
-- (coach_kind_detail). Beide nur fuer den Coach der Session oder einen Admin;
-- jede andere Rolle (auch Schueler- und Tablet-Konten) bekommt 42501.
-- Musterloesung und Fehlbild liefert nur coach_kind_detail; coach_raum_live
-- liefert die aktuelle Aufgabe ohne Loesung (lsa_question_payload).
-- Platzhalter fuer P2: mastery_kandidat (A1), erklaersequenz (E1).

-- Je Kind: Stand fuer die Kachel. Ohne Rechtepruefung, nur intern.
create function public.session_kind_live(p_session_id uuid, p_student_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'student_id', ss.student_id,
    'name', public.session_kind_name(ss.student_id),
    'klasse', s.class_level,
    'anwesenheit', ss.attendance,
    'tablet_nr', st.tablet_nr,
    'tablet_seit', st.zugewiesen_am,
    'phase', public.session_phase(p_session_id, ss.student_id),
    'stimmung', c.stimmung,
    'klassenarbeit_datum', c.klassenarbeit_datum,
    'thema_antwort', c.thema_antwort,
    'thema_stichwort', c.thema_stichwort,
    'schulthema_key', public.session_schulthema(ss.student_id),
    'fall_vorschlag', c.fall_vorschlag,
    'fall_coach', c.fall_coach,
    'fall', coalesce(c.fall_coach, c.fall_vorschlag),
    'ziel_thema_key', c.ziel_thema_key,
    'ziel_thema_label', (select th.label from public.themen th where th.thema_key = c.ziel_thema_key),
    'checkin_fertig', c.kind_am is not null,
    'aufgabe', case when a.id is null then null else jsonb_build_object(
        'task_id', a.task_id, 'seit', a.zeit, 'eingemischt', a.eingemischt, 'phase', a.phase,
        'nr_in_phase', (select count(*) from public.session_ausgegeben x where x.session_id = p_session_id
                         and x.student_id = ss.student_id and x.phase is not distinct from a.phase),
        'skill_key', (select t.skill_key from public.tasks t where t.id = a.task_id),
        'payload', public.lsa_question_payload(a.task_id)) end,
    'ergebnisfolge', coalesce((select jsonb_agg(jsonb_build_object('task_id', r.task_id, 'teil', r.teil,
         'versuch_nr', r.versuch_nr, 'ergebnis', r.ergebnis, 'hinweisstufe_max', r.hinweisstufe_max,
         'phase', r.phase, 'eingemischt', r.eingemischt, 'zeit', r.zeit) order by r.zeit)
       from public.session_antworten r where r.session_id = p_session_id and r.student_id = ss.student_id), '[]'),
    'hinweise_genutzt', (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
       and e.student_id = ss.student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean),
    'letzte_eingabe_am', (select max(r.zeit) from public.session_antworten r
       where r.session_id = p_session_id and r.student_id = ss.student_id),
    'mastery_kandidat', null,
    'erklaersequenz', null)
  from public.session_students ss
  join public.students s on s.id = ss.student_id
  left join public.session_tablets st on st.session_id = ss.session_id and st.student_id = ss.student_id
                                     and st.geloest_am is null
  left join public.session_checkin c on c.session_id = ss.session_id and c.student_id = ss.student_id
  left join lateral public.session_aktuelle_ausgabe(p_session_id, ss.student_id) a on true
  where ss.session_id = p_session_id and ss.student_id = p_student_id
$$;

create function public.coach_raum_live(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s        public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'coach_raum_live');
  v_sig    jsonb;
  v_kinder jsonb;
begin
  select coalesce(jsonb_agg(to_jsonb(x) order by x.rang, x.seit), '[]') into v_sig
    from public.session_signale_intern(p_session_id) x;

  select coalesce(jsonb_agg(k.j || jsonb_build_object(
           'status', coalesce((select case x.art when 'kandidat' then 'kandidat' when 'entscheidung' then 'entscheidung'
                                 when 'haengt' then 'haengt' else 'hinweis' end
                                 from jsonb_to_recordset(v_sig) as x(student_id uuid, art text, rang int, seit timestamptz)
                                where x.student_id = k.student_id order by x.rang, x.seit limit 1), 'laeuft'),
           'signale', coalesce((select jsonb_agg(z) from jsonb_array_elements(v_sig) z
                                 where (z ->> 'student_id')::uuid = k.student_id), '[]'))
           order by (k.j ->> 'tablet_nr')::int nulls last, k.j ->> 'name'), '[]')
    into v_kinder
    from (select ss.student_id, public.session_kind_live(p_session_id, ss.student_id) as j
            from public.session_students ss where ss.session_id = p_session_id) k;

  return jsonb_build_object(
    'session', jsonb_build_object(
      'id', s.id, 'status', s.status, 'scheduled_at', s.scheduled_at, 'gestartet_am', s.gestartet_am,
      'beendet_am', s.beendet_am, 'room', s.room,
      'coach_name', (select p.full_name from public.profiles p where p.id = s.coach_id),
      'einstellungen', coalesce(s.einstellungen,
                        (select jsonb_object_agg(e.schluessel, e.wert) from public.session_einstellungen e)),
      'mastery_bestaetigt', 0),
    'stand', clock_timestamp(),
    'kinder', v_kinder,
    'signale', v_sig);
end;
$$;

create function public.coach_kind_detail(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  a public.session_ausgegeben;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'coach_kind_detail');
  a := public.session_aktuelle_ausgabe(p_session_id, p_student_id);

  return public.session_kind_live(p_session_id, p_student_id) || jsonb_build_object(
    'aufgabe_detail', case when a.id is null then null else (
      select jsonb_build_object('task_id', a.task_id, 'payload', public.lsa_question_payload(a.task_id),
               'musterloesung', ts.solution, 'correct_answers', ts.correct_answers,
               'letzte_eingabe', (select r.eingabe from public.session_antworten r where r.session_id = p_session_id
                                   and r.student_id = p_student_id and r.task_id = a.task_id
                                   order by r.zeit desc limit 1))
        from (select 1) d left join public.task_solutions ts on ts.task_id = a.task_id) end,
    'versuche', coalesce((select jsonb_agg(jsonb_build_object('task_id', r.task_id, 'teil', r.teil,
         'versuch_nr', r.versuch_nr, 'eingabe', r.eingabe, 'ergebnis', r.ergebnis, 'fehlbild_slug', r.fehlbild_slug,
         'fehlbild_klartext', fl.klartext, 'hinweisstufe_max', r.hinweisstufe_max, 'phase', r.phase,
         'dauer_ms', r.dauer_ms, 'zeit', r.zeit) order by r.zeit)
       from public.session_antworten r left join public.fehlbild_labels fl on fl.slug = r.fehlbild_slug
      where r.session_id = p_session_id and r.student_id = p_student_id), '[]'),
    'hinweise', coalesce((select jsonb_agg(jsonb_build_object('task_id', e.payload ->> 'task_id',
         'stufe', (e.payload ->> 'stufe')::int, 'zeit', e.zeit,
         'text', (select h ->> 'text' from public.task_solutions ts, jsonb_array_elements(ts.hints) h
                   where ts.task_id = (e.payload ->> 'task_id')::uuid
                     and (h ->> 'level')::int = (e.payload ->> 'stufe')::int limit 1)) order by e.zeit)
       from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = p_student_id
        and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean), '[]'),
    'eingriffe', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit, 'von', e.von,
         'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl where fl.slug = e.payload ->> 'fehlbild_slug'))
         order by e.zeit)
       from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = p_student_id
        and e.typ = 'eingriff'), '[]'),
    'entscheidungen', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit, 'von', e.von)
         order by e.zeit)
       from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = p_student_id
        and e.typ = 'entscheidung_pfad'), '[]'),
    'signale', coalesce((select jsonb_agg(to_jsonb(x) order by x.rang, x.seit)
       from public.session_signale_intern(p_session_id) x where x.student_id = p_student_id), '[]'));
end;
$$;

revoke all on function
  public.session_kind_live(uuid, uuid), public.coach_raum_live(uuid), public.coach_kind_detail(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.coach_raum_live(uuid), public.coach_kind_detail(uuid, uuid) to authenticated;
