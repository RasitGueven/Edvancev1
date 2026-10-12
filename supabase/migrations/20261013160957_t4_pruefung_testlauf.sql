-- T4.2 Pruefragen im Testlauf wie freigegeben (Entscheidung Rasit 12.10.2026, Paket T4; offene-punkte-t3 Punkt 3).
--
-- Bisher kam eine Pruefrage (skill_pruefung) nur mit Status 'freigegeben' aufs Tablet, auch im Testlauf. Jetzt gilt in
-- einer Testlauf-Session (coaching_sessions.testlauf) jede Pruefrage des Skills als freigegeben: Pruefragen sind keine
-- Aufgaben, das Lena-Board prueft sie nicht, und es gibt bei ihnen keinen Ausschluss (Status nur entwurf, geprueft,
-- freigegeben). Das ist die Regel aus T3 (testlauf_inhalt_sichtbar) uebertragen: alles, was nicht ausgeschlossen
-- ist. Eine freigegebene Frage geht vor, dann eine gepruefte, dann die aelteste.
-- Ohne Testlauf bleibt es bei 'freigegeben' (dieselbe Reihenfolge wie session_pruefung_frage, die unveraendert bleibt).
--
-- Hilfe, nur intern: session_pruefung_frage_sitzung(session, skill). Ob die Regel gilt, liest sie in der Session.
-- Umgestellt: tablet_stand (pruefung.frage), pruefung_aufs_tablet (Vorbedingung), session_kind_live (pruefung_vorhanden).

create or replace function public.session_pruefung_frage_sitzung(p_session_id uuid, p_skill_key text)
 returns text
 language sql
 stable
 set search_path to 'public', 'pg_temp'
as $function$
  select p.frage from public.skill_pruefung p
   where p.skill_key = p_skill_key
     and (p.status = 'freigegeben'
          or coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false))
   order by (p.status = 'freigegeben') desc, (p.status = 'geprueft') desc, p.angelegt, p.id limit 1
$function$;

revoke all on function public.session_pruefung_frage_sitzung(uuid, text) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.tablet_stand()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t public.session_tablets;
  a public.session_ausgegeben;
  pa record;
begin
  select st.* into t from public.session_tablets st
    join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
   where st.geraet_id = auth.uid() and st.geloest_am is null;
  if not found then
    -- A2c (Nachtrag R2): ein Platz-Konto ohne Zuweisung bekommt die Nummer des eigenen Geraets fuer den
    -- Warte-Bildschirm (null, wenn das Geraet keine hat). Alle anderen Konten: nur zugewiesen = false.
    return jsonb_build_object('zugewiesen', false)
           || coalesce((select jsonb_build_object('tablet_nr', pd.tablet_nr)
                          from public.platz_devices pd where pd.profile_id = auth.uid()), '{}'::jsonb);
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
    -- T4: im Testlauf gilt jede Pruefrage wie freigegeben (session_pruefung_frage_sitzung).
    'pruefung', case when pa.skill_key is null then null else jsonb_build_object(
        'skill_label', public.session_label(pa.skill_key),
        'frage', public.session_pruefung_frage_sitzung(t.session_id, pa.skill_key)) end,
    -- A2b (Entscheidung 34): gemeistert erst nach der Bestaetigung des Coaches in dieser Session.
    'bestaetigt', coalesce((select jsonb_agg(jsonb_build_object('skill_key', l.skill_key,
                    'skill_label', public.session_label(l.skill_key), 'am', l.coach_am) order by l.coach_am)
                  from public.lernpfad l
                 where l.student_id = t.student_id and l.coach_session_id = t.session_id
                   and l.stand_coach = 'gemeistert'), '[]'::jsonb));
end;
$function$;

CREATE OR REPLACE FUNCTION public.pruefung_aufs_tablet(p_session_id uuid, p_student_id uuid, p_skill_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  perform public.session_pruefung_recht(p_session_id, p_student_id, 'pruefung_aufs_tablet');
  -- T4: im Testlauf gilt jede Pruefrage wie freigegeben.
  if public.session_pruefung_frage_sitzung(p_session_id, p_skill_key) is null then
    raise exception 'pruefung_aufs_tablet: keine freigegebene Pruefrage fuer %', p_skill_key
      using errcode = 'P0002', hint = 'keine_pruefung';
  end if;
  if not exists (select 1 from public.session_tablets st where st.session_id = p_session_id
                  and st.student_id = p_student_id and st.geloest_am is null) then
    raise exception 'pruefung_aufs_tablet: Kind hat kein Tablet' using errcode = 'P0001', hint = 'kein_tablet';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'pruefung',
                                  jsonb_build_object('skill_key', p_skill_key, 'aktion', 'start'));
  return jsonb_build_object('skill_key', p_skill_key, 'aktiv', true);
end;
$function$;

CREATE OR REPLACE FUNCTION public.session_kind_live(p_session_id uuid, p_student_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    'mastery_kandidat', (
       select jsonb_build_object('skill_key', e.payload ->> 'skill_key',
                'label', public.session_label(e.payload ->> 'skill_key'), 'seit', e.zeit,
                'stand_coach', l.stand_coach,
                -- T4: im Testlauf gilt jede Pruefrage wie freigegeben.
                'pruefung_vorhanden', public.session_pruefung_frage_sitzung(p_session_id, e.payload ->> 'skill_key') is not null)
         from public.session_ereignisse e
         left join public.lernpfad l on l.student_id = ss.student_id and l.skill_key = e.payload ->> 'skill_key'
        where e.session_id = p_session_id and e.student_id = ss.student_id and e.typ = 'signal'
          and e.payload ->> 'art' = 'kandidat'
          and public.lernpfad_pruefung_faellig(ss.student_id, e.payload ->> 'skill_key')
        order by e.zeit limit 1),
    'erklaersequenz', (
       select jsonb_build_object('skill_key', ek.skill_key, 'label', public.session_label(ek.skill_key),
                'kernidee_nr', ek.nr, 'kernidee_titel', ek.titel,
                'kernideen', (select count(*) from public.erklaer_kernidee k2
                               where k2.skill_key = ek.skill_key
                                 and public.erklaer_status_ok(k2.status, (select cs.testlauf from public.coaching_sessions cs
                                                                           where cs.id = p_session_id))),
                'kernideen_fertig', (select count(distinct f2.kernidee_id) from public.erklaer_fortschritt f2
                                      join public.erklaer_kernidee k3 on k3.id = f2.kernidee_id
                                     where f2.session_id = p_session_id and f2.student_id = ss.student_id
                                       and k3.skill_key = ek.skill_key and f2.ergebnis = 'richtig'),
                'runde', ef.runde, 'variante', ef.variante, 'stand', ef.ergebnis, 'zeit', ef.zeit,
                'fehlbild_slug', (select f4.fehlbild_slug from public.erklaer_fortschritt f4
                                   where f4.session_id = p_session_id and f4.student_id = ss.student_id
                                     and f4.kernidee_id = ef.kernidee_id and f4.ergebnis = 'falsch'
                                   order by f4.id desc limit 1))
         from public.erklaer_fortschritt ef
         join public.erklaer_kernidee ek on ek.id = ef.kernidee_id
        where ef.session_id = p_session_id and ef.student_id = ss.student_id
        order by ef.id desc limit 1),
    'pruefung_auf_tablet', (select case when pa.skill_key is null then null
                                   else jsonb_build_object('skill_key', pa.skill_key, 'seit', pa.seit) end
                              from public.session_pruefung_aktiv(p_session_id, ss.student_id) pa),
    'schritt', (
       select jsonb_build_object('art', x.art, 'phase', x.phase, 'skill_key', x.skill_key,
                'skill_label', case when x.skill_key is not null then public.session_label(x.skill_key) end,
                'task_id', x.task_id, 'modus', x.modus, 'eingemischt', x.eingemischt,
                'schwierigkeit', x.schwierigkeit, 'grund', x.grund, 'grund_code', x.grund_code, 'zeit', x.zeit)
         from public.session_schritte x
        where x.session_id = p_session_id and x.student_id = ss.student_id
        order by x.id desc limit 1))
  from public.session_students ss
  join public.students s on s.id = ss.student_id
  left join public.session_tablets st on st.session_id = ss.session_id and st.student_id = ss.student_id
                                     and st.geloest_am is null
  left join public.session_checkin c on c.session_id = ss.session_id and c.student_id = ss.student_id
  left join lateral public.session_aktuelle_ausgabe(p_session_id, ss.student_id) a on true
  where ss.session_id = p_session_id and ss.student_id = p_student_id
$function$;
