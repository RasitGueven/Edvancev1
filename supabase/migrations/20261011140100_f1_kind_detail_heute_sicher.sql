-- F1.2 Schublade nach dem Trockenlauf (08.10.2026, Befund A6): Die Engine rueckt einen Skill weiter, sobald er
-- heute sicher ist (offene-punkte-a2 F7); die Schublade zeigte ihn trotzdem als „offen“ (Lernpfad-Stand, im
-- Testlauf ohne Belege). coach_kind_detail liefert deshalb, welche Skills des Ziels heute sicher sind.
--
-- Grundlage ist die Definition aus 20261011100200_c3_kind_detail (in Prod seit C3). Neu, sonst unveraendert:
--   heute_sicher   Skill-Keys der Zielliste (session_zielliste), fuer die session_heute_sicher gilt
--
-- Rechte unveraendert (session_kind_pruefen); create or replace behaelt die Grants.

create or replace function public.coach_kind_detail(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  a        public.session_ausgegeben;
  v_sig    public.session_ereignisse;
  v_vor    text;
  v_fb     record;
  v_pfad   jsonb;
  v_heute  jsonb;
  v_seq    jsonb;
  v_ef     record;
  v_test   boolean;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'coach_kind_detail');
  a := public.session_aktuelle_ausgabe(p_session_id, p_student_id);
  select cs.testlauf into v_test from public.coaching_sessions cs where cs.id = p_session_id;

  -- C3: Pfad-Vorschlag aus dem juengsten Entscheidungssignal.
  select * into v_sig from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
     and e.payload ->> 'art' = 'entscheidung'
   order by e.zeit desc, e.id desc limit 1;
  if v_sig.id is not null then
    v_vor := coalesce(v_sig.payload ->> 'voraussetzung_skill_key', v_sig.payload ->> 'skill_key');
    select r.fehlbild_slug as slug, fl.klartext, r.zeit into v_fb
      from public.session_antworten r
      join public.tasks t on t.id = r.task_id
      join public.fehlbild_labels fl on fl.slug = r.fehlbild_slug and nullif(btrim(fl.klartext), '') is not null
     where r.session_id = p_session_id and r.student_id = p_student_id and t.skill_key = v_vor
     order by r.zeit desc limit 1;
    v_pfad := jsonb_build_object(
      'seit', v_sig.zeit,
      'offen', not exists (select 1 from public.session_ereignisse x
                            where x.session_id = p_session_id and x.student_id = p_student_id
                              and x.typ = 'signal_erledigt' and x.payload ->> 'art' = 'entscheidung'
                              and x.zeit > v_sig.zeit),
      'skill_key', v_vor,
      'label', coalesce(v_sig.payload ->> 'voraussetzung_label', public.session_label(v_vor)),
      'klasse', (select s.klasse_herkunft from public.skills s where s.skill_key = v_vor),
      'ziel_skill_key', v_sig.payload ->> 'ziel_skill_key',
      'ziel_label', case when v_sig.payload ? 'ziel_skill_key'
                         then public.session_label(v_sig.payload ->> 'ziel_skill_key') end,
      'warmup_aufgaben', (v_sig.payload ->> 'warmup_aufgaben')::int,
      'warmup_richtig', (v_sig.payload ->> 'warmup_richtig')::int,
      'fehlbild', v_fb.klartext,
      'fehlbild_am', case when v_fb.slug is not null then (
          select max(r.zeit) from public.session_antworten r
           where r.student_id = p_student_id and r.session_id <> p_session_id and r.fehlbild_slug = v_fb.slug
             and r.zeit < v_fb.zeit) end,
      'thema_label', (select th.label from public.session_checkin c join public.themen th on th.thema_key = c.ziel_thema_key
                       where c.session_id = p_session_id and c.student_id = p_student_id));
  end if;

  -- C3: "Heute" je Abschnitt und Skill. Exit (checkout) gehoert zum Check-out, nicht hierher.
  with ausg as (
    select x.task_id, x.zeit, t.skill_key,
           case when x.phase = 'warmup' then 'warmup' when x.eingemischt then 'eingemischt' else 'kern' end as abschnitt,
           st.erledigt, st.erfolg,
           (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
               and e.student_id = p_student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean
               and e.payload ->> 'task_id' = x.task_id::text) as hinweise
      from public.session_ausgegeben x
      join public.tasks t on t.id = x.task_id
      cross join lateral public.session_aufgabe_stand(p_session_id, p_student_id, x.task_id) st
     where x.session_id = p_session_id and x.student_id = p_student_id and x.phase in ('warmup', 'kern')
  ),
  zeilen as (
    select 0 as rang, min(tb.zugewiesen_am) as ab,
           jsonb_build_object('abschnitt', 'ankommen', 'zeit', min(tb.zugewiesen_am)) as z
      from public.session_tablets tb
     where tb.session_id = p_session_id and tb.student_id = p_student_id
    having min(tb.zugewiesen_am) is not null
    union all
    select case when g.abschnitt = 'warmup' then 1 else 2 end, min(g.zeit), jsonb_build_object('abschnitt', g.abschnitt, 'skill_key', g.skill_key,
             'label', public.session_label(g.skill_key),
             'richtig', count(*) filter (where g.erledigt and g.erfolg), 'von', count(*) filter (where g.erledigt),
             'hinweise', sum(g.hinweise))
      from ausg g group by g.abschnitt, g.skill_key
    union all
    select 2, min(f.zeit), jsonb_build_object('abschnitt', 'erklaerung', 'skill_key', k.skill_key,
             'label', public.session_label(k.skill_key),
             'sicher', count(distinct f.kernidee_id) filter (where f.ergebnis = 'richtig'),
             'aktuell', (array_agg(k.nr order by f.id desc))[1],
             'runde', (array_agg(f.runde order by f.id desc))[1])
      from public.erklaer_fortschritt f join public.erklaer_kernidee k on k.id = f.kernidee_id
     where f.session_id = p_session_id and f.student_id = p_student_id
     group by k.skill_key
  )
  select coalesce(jsonb_agg(z.z order by z.rang, z.ab), '[]') into v_heute from zeilen z;

  -- C3: alle Kernideen der laufenden Erklaersequenz (Skill der juengsten Zeile in erklaer_fortschritt).
  select f.kernidee_id, k.skill_key into v_ef
    from public.erklaer_fortschritt f join public.erklaer_kernidee k on k.id = f.kernidee_id
   where f.session_id = p_session_id and f.student_id = p_student_id
   order by f.id desc limit 1;
  if v_ef.skill_key is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
             'nr', k.nr, 'titel', k.titel,
             'stand', case when exists (select 1 from public.erklaer_fortschritt f where f.session_id = p_session_id
                                          and f.student_id = p_student_id and f.kernidee_id = k.id
                                          and f.ergebnis = 'richtig') then 'sicher'
                           when k.id = v_ef.kernidee_id then 'laeuft' else 'offen' end,
             'runde', (select max(f.runde) from public.erklaer_fortschritt f where f.session_id = p_session_id
                        and f.student_id = p_student_id and f.kernidee_id = k.id),
             'variante', (select f.variante from public.erklaer_fortschritt f where f.session_id = p_session_id
                           and f.student_id = p_student_id and f.kernidee_id = k.id order by f.id desc limit 1),
             'fehlbild', (select fl.klartext from public.erklaer_fortschritt f
                            join public.fehlbild_labels fl on fl.slug = f.fehlbild_slug
                           where f.session_id = p_session_id and f.student_id = p_student_id
                             and f.kernidee_id = k.id and f.ergebnis = 'falsch'
                           order by f.id desc limit 1)) order by k.nr), '[]')
      into v_seq
      from public.erklaer_kernidee k
     where k.skill_key = v_ef.skill_key
       and (public.erklaer_status_ok(k.status, coalesce(v_test, false))
            or exists (select 1 from public.erklaer_fortschritt f where f.session_id = p_session_id
                        and f.student_id = p_student_id and f.kernidee_id = k.id));
  end if;

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
       from public.session_signale_intern(p_session_id) x where x.student_id = p_student_id), '[]'),
    -- C3
    'pfad_vorschlag', v_pfad,
    'heute', v_heute,
    'erklaer_kernideen', coalesce(v_seq, '[]'),
    'schritt_details', coalesce((select x.details from public.session_schritte x
                                  where x.session_id = p_session_id and x.student_id = p_student_id
                                  order by x.id desc limit 1), '{}'),
    -- F1 (A6): Skills des Ziels, die die Engine heute als sicher zaehlt (session_heute_sicher, offene-punkte-a2
    -- F7) und deshalb weitergerueckt ist. Der Lernpfad-Stand bleibt davon unberuehrt (im Testlauf ohne Belege).
    'heute_sicher', coalesce((select jsonb_agg(z.skill_key order by z.reihenfolge)
                                from public.session_zielliste(p_session_id, p_student_id) z
                               where public.session_heute_sicher(p_session_id, p_student_id, z.skill_key)), '[]'));
end;
$$;

comment on function public.coach_kind_detail(uuid, uuid) is
  'R1/C3/F1: Schublade je Kind (Coach der Session oder Admin). C3: pfad_vorschlag, heute, erklaer_kernideen, schritt_details. F1: heute_sicher.';
