-- F1.1 Coach-Live-Sicht nach dem Trockenlauf (08.10.2026, Befund A4): Kopf und Kachel zeigen die Phase, in
-- der das Kind wirklich ist, und warum es ohne Warm-up in der Kernarbeit steht.
--
-- Grundlage ist die Definition aus 20261010110100_c2_raum_live (in Prod unveraendert seit C2). Neu je Kind,
-- sonst unveraendert:
--   kinder[].phase_seit        Zeitpunkt des juengsten Phasenwechsels (session_ereignisse phase_wechsel)
--   kinder[].warmup_entfallen  null | 'kein_stoff' | 'zeit' (Kind in Kernarbeit/Check-out ohne Warm-up-Schritt)
-- Die Engine bleibt unberuehrt: session_plan_warmup meldet ohne_warmup, schreibt es aber nicht; der Grund wird
-- hier aus Phasenwechsel und Uhr (wie session_uhr_phase) abgeleitet.
--
-- Rechte unveraendert (session_coach_pruefen); create or replace behaelt die Grants.

create or replace function public.coach_raum_live(p_session_id uuid)
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
  v_quests boolean := coalesce(public.home_quests_aktiv(p_session_id), false);
begin
  select coalesce(jsonb_agg(to_jsonb(x) order by x.rang, x.seit), '[]') into v_sig
    from public.session_signale_intern(p_session_id) x;

  select coalesce(jsonb_agg(k.j || jsonb_build_object(
           'status', coalesce((select case x.art when 'kandidat' then 'kandidat' when 'entscheidung' then 'entscheidung'
                                 when 'haengt' then 'haengt' else 'hinweis' end
                                 from jsonb_to_recordset(v_sig) as x(student_id uuid, art text, rang int, seit timestamptz)
                                where x.student_id = k.student_id order by x.rang, x.seit limit 1), 'laeuft'),
           'signale', coalesce((select jsonb_agg(z) from jsonb_array_elements(v_sig) z
                                 where (z ->> 'student_id')::uuid = k.student_id), '[]'),
           -- C2: Check-out je Kind. quest_von: 'kind' (Tablet) oder 'coach' (Coach oder Admin hat nachgetragen).
           'abschluss', (select jsonb_build_object(
                'satz_text', a.satz_text, 'satz_gesagt', a.satz_gesagt, 'notiz', a.notiz,
                'flag_eltern', a.flag_eltern, 'flag_pfad', a.flag_pfad, 'exit_ergebnis', a.exit_ergebnis,
                'quest_termin', a.quest_termin,
                'quest_von', case when a.quest_termin is null then null
                                  when exists (select 1 from public.profiles p where p.id = a.quest_termin_von
                                                and p.role in ('coach', 'admin')) then 'coach'
                                  else 'kind' end)
              from public.session_kind_abschluss a
             where a.session_id = p_session_id and a.student_id = k.student_id),
           -- C2: Quest B wie session_kind_kontext (Tag vor der naechsten gebuchten Session), nur mit Home Quests.
           'quest_b', case when v_quests then (
                select (min(cs.scheduled_at) at time zone 'Europe/Berlin')::date - 1
                  from public.session_students x join public.coaching_sessions cs on cs.id = x.session_id
                 where x.student_id = k.student_id and x.attendance = 'planned' and cs.scheduled_at > s.scheduled_at) end,
           'eingriffe', coalesce((select jsonb_agg(jsonb_build_object('stufe', (e.payload ->> 'stufe')::int, 'zeit', e.zeit)
                                          order by e.zeit)
                                    from public.session_ereignisse e
                                   where e.session_id = p_session_id and e.student_id = k.student_id
                                     and e.typ = 'eingriff'), '[]'),
           'pfad_entscheidung', (select jsonb_build_object('entscheidung', e.payload ->> 'entscheidung', 'zeit', e.zeit)
                                   from public.session_ereignisse e
                                  where e.session_id = p_session_id and e.student_id = k.student_id
                                    and e.typ = 'entscheidung_pfad'
                                  order by e.zeit desc limit 1),
           'mastery_heute', coalesce((select jsonb_agg(jsonb_build_object(
                                'skill_key', p.skill_key, 'label', public.session_label(p.skill_key),
                                'stand_coach', p.neu ->> 'stand_coach', 'grund', p.grund, 'am', p.am,
                                'von', (select pr.full_name from public.profiles pr where pr.id = p.von)) order by p.am)
                                       from public.lernpfad_protokoll p
                                      where p.session_id = p_session_id and p.student_id = k.student_id
                                        and p.aktion = 'mastery'), '[]'),
           -- F1 (A4): seit wann das Kind in seiner Phase ist (juengster Phasenwechsel) und ob das Warm-up
           -- entfallen ist: kein Warm-up-Schritt, aber schon Kernarbeit/Check-out. kein_stoff = Kernarbeit begann,
           -- solange die Uhr noch Check-in oder Warm-up zeigte (session_plan_warmup fand keinen Skill mit
           -- Aufgabe); zeit = Kernarbeit erst nach dem Warm-up laut Uhr (spaet angekommen). Fehlt ein Zeitpunkt: null.
           -- Ein Phasenwechsel durch den Coach (phase_setzen) zaehlt wie einer vom Tablet (offene-punkte-f1).
           'phase_seit', (select max(e.zeit) from public.session_ereignisse e
                           where e.session_id = p_session_id and e.student_id = k.student_id
                             and e.typ = 'phase_wechsel'),
           'warmup_entfallen', case
              when k.j ->> 'phase' in ('kern', 'checkout')
               and not exists (select 1 from public.session_schritte x
                                where x.session_id = p_session_id and x.student_id = k.student_id
                                  and x.phase = 'warmup')
              then (select case when x.kern_ab < x.warmup_ende then 'kein_stoff'
                                when x.kern_ab >= x.warmup_ende then 'zeit' end
                      from (select (select min(e.zeit) from public.session_ereignisse e
                                     where e.session_id = p_session_id and e.student_id = k.student_id
                                       and e.typ = 'phase_wechsel' and e.payload ->> 'phase' = 'kern') as kern_ab,
                                   s.gestartet_am + (public.session_wert_zahl(p_session_id, 'phase_checkin_min')
                                                     + public.session_wert_zahl(p_session_id, 'phase_warmup_min'))
                                                    * interval '1 minute' as warmup_ende) x) end)
           order by (k.j ->> 'tablet_nr')::int nulls last, k.j ->> 'name'), '[]')
    into v_kinder
    from (select ss.student_id, public.session_kind_live(p_session_id, ss.student_id) as j
            from public.session_students ss where ss.session_id = p_session_id) k;

  return jsonb_build_object(
    'session', jsonb_build_object(
      'id', s.id, 'status', s.status, 'scheduled_at', s.scheduled_at, 'gestartet_am', s.gestartet_am,
      'beendet_am', s.beendet_am, 'room', s.room, 'testlauf', s.testlauf,
      'coach_name', (select p.full_name from public.profiles p where p.id = s.coach_id),
      'einstellungen', coalesce(s.einstellungen,
                        (select jsonb_object_agg(e.schluessel, e.wert) from public.session_einstellungen e)),
      'mastery_bestaetigt', (select count(*) from public.lernpfad_protokoll p
                              where p.session_id = s.id and p.aktion = 'mastery'
                                and p.neu ->> 'stand_coach' = 'gemeistert')),
    'stand', clock_timestamp(),
    'kinder', v_kinder,
    'signale', v_sig);
end;
$$;

comment on function public.coach_raum_live(uuid) is
  'R1/A2/A2b/C2/F1: der ganze Raum in einer Abfrage (Coach der Session oder Admin). C2: testlauf, abschluss, quest_b, eingriffe, pfad_entscheidung, mastery_heute je Kind. F1: phase_seit, warmup_entfallen.';
