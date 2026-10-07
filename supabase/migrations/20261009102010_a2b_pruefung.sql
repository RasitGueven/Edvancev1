-- A2b.3 Pruefrage aufs Tablet (Entscheidung 31): Der Coach legt die Frage der Mastery-Pruefung per Knopf
-- auf das Tablet des Kindes. Erwartung und Kriterium sieht nur der Coach (skill_pruefung_lesen).
--   session_ereignisse.typ  neu 'pruefung', payload {skill_key, aktion: start | ende}.
--   pruefung_aufs_tablet    Coach der Session oder Admin, Zeitbindung wie mastery_entscheiden (a1-15),
--                           nur mit freigegebener skill_pruefung, nur mit aktivem Tablet. Eine neue ersetzt die alte.
--   pruefung_vom_tablet     nimmt die aktive Frage zurueck.
--   session_kind_live       je Kind pruefung_auf_tablet {skill_key, seit} oder null (coach_raum_live,
--                           coach_kind_detail). Grundlage: Prod-Definition (07.10., identisch mit A2).

alter table public.session_ereignisse drop constraint session_ereignisse_typ_check;
alter table public.session_ereignisse add constraint session_ereignisse_typ_check
  check (typ in ('phase_wechsel', 'hinweis', 'erklaerschritt', 'check', 'signal', 'signal_erledigt', 'eingriff',
                 'entscheidung_pfad', 'pruefung'));

-- Coach-Recht fuer die Pruefung: Coach der Session oder Admin, Kind gebucht, Coach in der Zeitbindung.
create function public.session_pruefung_recht(p_session_id uuid, p_student_id uuid, p_wer text)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, p_wer);
  if coalesce(public.get_my_role(), '') <> 'admin'
     and not coalesce(public.lernpfad_coach_der_session(p_session_id, p_student_id), false) then
    raise exception '%: nur in der laufenden Session (bis 30 Minuten nach dem geplanten Ende) oder am selben Tag nach dem Abschluss', p_wer
      using errcode = '42501';
  end if;
end;
$$;

create function public.pruefung_aufs_tablet(p_session_id uuid, p_student_id uuid, p_skill_key text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_pruefung_recht(p_session_id, p_student_id, 'pruefung_aufs_tablet');
  if public.session_pruefung_frage(p_skill_key) is null then
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
$$;

create function public.pruefung_vom_tablet(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  pa record;
begin
  perform public.session_pruefung_recht(p_session_id, p_student_id, 'pruefung_vom_tablet');
  select * into pa from public.session_pruefung_aktiv(p_session_id, p_student_id);
  if pa.skill_key is null then
    raise exception 'pruefung_vom_tablet: keine Pruefrage auf dem Tablet' using errcode = 'P0002', hint = 'keine_aktive_pruefung';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'pruefung',
                                  jsonb_build_object('skill_key', pa.skill_key, 'aktion', 'ende'));
  return jsonb_build_object('skill_key', pa.skill_key, 'aktiv', false);
end;
$$;

revoke all on function public.session_pruefung_recht(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.pruefung_aufs_tablet(uuid, uuid, text), public.pruefung_vom_tablet(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.pruefung_aufs_tablet(uuid, uuid, text), public.pruefung_vom_tablet(uuid, uuid)
  to authenticated;

create or replace function public.session_kind_live(p_session_id uuid, p_student_id uuid)
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
    'mastery_kandidat', (
       select jsonb_build_object('skill_key', e.payload ->> 'skill_key',
                'label', public.session_label(e.payload ->> 'skill_key'), 'seit', e.zeit,
                'stand_coach', l.stand_coach,
                'pruefung_vorhanden', exists (select 1 from public.skill_pruefung p
                                               where p.skill_key = e.payload ->> 'skill_key' and p.status = 'freigegeben'))
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
$$;
