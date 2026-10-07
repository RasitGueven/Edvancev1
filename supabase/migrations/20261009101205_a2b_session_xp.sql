-- A2b.2 XP in der Session (Entscheidung 30): pauschal je bearbeitete Aufgabe, nie fuers Richtig-Haben;
-- gebucht und sichtbar erst am Ende; Testlauf nie.
--   session_xp_je_aufgabe   neue Stellschraube (xp, Startwert 10, Spanne 0 bis 30; 0 = keine Buchung),
--                           wirkt ueber den Snapshot (Entscheidung B).
--   session_xp_buchen       intern: erledigte Aufgaben (art aufgabe und exit, Antwort auf jeden Teil wie F4)
--                           mal Stellschraube, ueber xp_buchen_intern mit Schluessel session:<session_id>,
--                           Grund 'session' (Muster der Quest-Buchung 'home_quest'). Genau einmal je Kind.
--   session_naechster_schritt  bucht, wenn das Kind zum ersten Mal "fertig" bekommt.
--   session_abschliessen    bucht spaetestens dann fuer jedes anwesende Kind.
-- Grundlage der ersetzten Funktionen: Prod-Definitionen (pg_get_functiondef 07.10., identisch mit A2).

insert into public.session_einstellungen (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, einheit)
values ('session_xp_je_aufgabe', 'XP je bearbeitete Aufgabe in der Session (0 = keine Buchung)', 'zahl', '10', '10', 0, 30, true, 'xp');

create function public.session_xp_buchen(p_session_id uuid, p_student_id uuid)
returns int
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_wert int := coalesce(public.session_wert_zahl(p_session_id, 'session_xp_je_aufgabe'), 0)::int;
  v_n    int;
  v_xp   int;
begin
  if coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), true) or v_wert <= 0 then
    return 0;
  end if;
  select count(*) into v_n
    from public.session_schritte x
   where x.session_id = p_session_id and x.student_id = p_student_id and x.art in ('aufgabe', 'exit')
     and coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, x.task_id)).erledigt, false);
  if v_n = 0 then
    return 0;
  end if;
  v_xp := least(v_n * v_wert, 1000);
  if public.xp_buchen_intern(p_student_id, v_xp, 'session', 'session:' || p_session_id) then
    return v_xp;
  end if;
  return 0;
end;
$$;

revoke all on function public.session_xp_buchen(uuid, uuid) from public, anon, authenticated;

create or replace function public.session_naechster_schritt(p_session_id uuid, p_student_id uuid default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t       public.session_tablets;
  v       jsonb;
  v_letzt public.session_schritte;
  v_sig   jsonb;
begin
  -- Vorschau: Coach der Session oder Admin. Bucht nichts.
  if coalesce(public.session_ist_coach(p_session_id), false) then
    if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
      raise exception 'session_naechster_schritt: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
    end if;
    return public.session_schritt_oeffentlich(public.session_schritt_planen(p_session_id, p_student_id), true)
           || jsonb_build_object('vorschau', true);
  end if;

  -- Tablet: das Kind ergibt sich aus dem Platz (42501 ohne Platz, also auch fuer fremde
  -- Tablets, Schuelerkonten und Konten ohne Profil).
  t := public.session_tablet_platz(p_session_id, 'session_naechster_schritt');
  if p_student_id is not null and p_student_id <> t.student_id then
    raise exception 'session_naechster_schritt: nur der eigene Platz' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtext('session_schritt:' || p_session_id::text || ':' || t.student_id::text));

  v := public.session_schritt_planen(p_session_id, t.student_id);
  if coalesce((v ->> 'offen')::boolean, false) then
    return public.session_schritt_oeffentlich(v);
  end if;

  if v ->> 'phase' in ('warmup', 'kern', 'checkout')
     and public.session_phase(p_session_id, t.student_id) is distinct from v ->> 'phase' then
    perform public.session_ereignis(p_session_id, t.student_id, 'phase_wechsel',
                                    jsonb_build_object('phase', v ->> 'phase'));
  end if;

  select * into v_letzt from public.session_schritte x
   where x.session_id = p_session_id and x.student_id = t.student_id order by x.id desc limit 1;
  -- Wiederholtes Warten bzw. dieselbe laufende Erklaerung wird nicht erneut eingetragen.
  if not (v ->> 'art' in ('warten', 'erklaerung') and v_letzt.art = v ->> 'art'
          and v_letzt.grund_code = v ->> 'grund_code'
          and v_letzt.skill_key is not distinct from v ->> 'skill_key') then
    insert into public.session_schritte (session_id, student_id, art, phase, skill_key, task_id, modus, eingemischt,
           nach_beispiel, schwierigkeit, grund, grund_code)
    values (p_session_id, t.student_id, v ->> 'art', v ->> 'phase', v ->> 'skill_key', (v ->> 'task_id')::uuid,
            v ->> 'modus', coalesce((v ->> 'eingemischt')::boolean, false),
            coalesce((v ->> 'nach_beispiel')::boolean, false), (v ->> 'schwierigkeit')::int,
            v ->> 'grund', v ->> 'grund_code');
  end if;

  if v ->> 'art' in ('aufgabe', 'exit') then
    insert into public.session_ausgegeben (session_id, student_id, task_id, phase, eingemischt, von)
    values (p_session_id, t.student_id, (v ->> 'task_id')::uuid, v ->> 'phase',
            coalesce((v ->> 'eingemischt')::boolean, false), auth.uid());
  end if;

  for v_sig in select * from jsonb_array_elements(coalesce(v -> 'signale', '[]')) loop
    perform public.session_ereignis(p_session_id, t.student_id, 'signal', v_sig);
  end loop;

  -- A2b (Entscheidung 30): beim ersten "fertig" die XP der Session buchen (genau einmal je Kind).
  if v ->> 'art' = 'fertig' then
    perform public.session_xp_buchen(p_session_id, t.student_id);
  end if;

  if v ? 'exit_ergebnis' then
    insert into public.session_kind_abschluss as k (session_id, student_id, exit_ergebnis, aktualisiert_von)
    values (p_session_id, t.student_id, v -> 'exit_ergebnis', auth.uid())
    on conflict (session_id, student_id) do update
       set exit_ergebnis = excluded.exit_ergebnis, aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid()
     where k.exit_ergebnis is distinct from excluded.exit_ergebnis;
  end if;

  return public.session_schritt_oeffentlich(v);
end;
$$;

create or replace function public.session_abschliessen(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  s       public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'session_abschliessen');
  k       record;
  v_datum text;
  v_nid   uuid;
  v_n     int := 0;
  v_ohne  jsonb := '[]'::jsonb;
  v_text  text;
begin
  select * into s from public.coaching_sessions where id = p_session_id for update;
  if s.status <> 'active' then
    raise exception 'session_abschliessen: Session laeuft nicht (Status %)', s.status using errcode = 'P0001';
  end if;
  v_datum := to_char(s.scheduled_at at time zone 'Europe/Berlin', 'DD.MM.YYYY');

  -- Anwesenheit final: wer nie ein Tablet bekam und noch geplant ist, war nicht da.
  update public.session_students set attendance = 'unexcused'
   where session_id = p_session_id and attendance = 'planned';
  update public.session_tablets set geloest_am = clock_timestamp(), geloest_von = auth.uid()
   where session_id = p_session_id and geloest_am is null;

  for k in
    select ss.student_id, ss.attendance from public.session_students ss where ss.session_id = p_session_id
  loop
    insert into public.session_kind_abschluss (session_id, student_id, aktualisiert_von)
    values (p_session_id, k.student_id, auth.uid())
    on conflict (session_id, student_id) do nothing;

    -- Consensus-Check Befund 2: Notiz und Flags je Kind in eigenem Block. Hat ein
    -- Kind keine (aktive) Akte mehr, scheitert nicht der ganze Abschluss; das Kind
    -- steht dann in 'nicht_in_akte' und die Werte bleiben in session_kind_abschluss.
    v_nid := null;
    begin
      v_text := (select notiz from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id);
      -- A2: Testlaeufe schreiben nichts in die Akte (Entscheidung 27).
      if v_text is not null and not s.testlauf then
        v_nid := public.notiz_anlegen(k.student_id, 'lernen', v_text);
      end if;
      if not s.testlauf and (select flag_eltern from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'organisatorisch', 'Session ' || v_datum || ': Elternkontakt nötig');
      end if;
      if not s.testlauf and (select flag_pfad from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'lernen', 'Session ' || v_datum || ': Pfad passt nicht');
      end if;
    exception when insufficient_privilege or no_data_found then
      v_nid := null;
      v_ohne := v_ohne || to_jsonb(k.student_id);
    end;

    update public.session_kind_abschluss a
       set notiz_id = v_nid,
           in_akte_am = case when s.testlauf or v_ohne @> to_jsonb(k.student_id) then null else clock_timestamp() end,
           exit_ergebnis = coalesce(a.exit_ergebnis, (
             select jsonb_build_object('richtig', count(distinct r.task_id) filter (where r.ergebnis = 'richtig'),
                                       'gesamt', count(distinct r.task_id))
               from public.session_antworten r where r.session_id = p_session_id and r.student_id = k.student_id
                and r.phase = 'checkout' having count(*) > 0)),
           zusammenfassung = jsonb_build_object(
             'anwesenheit', (select attendance from public.session_students
                              where session_id = p_session_id and student_id = k.student_id),
             'aufgaben', (select count(distinct r.task_id) from public.session_antworten r
                           where r.session_id = p_session_id and r.student_id = k.student_id),
             'antworten', (select count(*) from public.session_antworten r
                            where r.session_id = p_session_id and r.student_id = k.student_id),
             'richtig', (select count(*) from public.session_antworten r where r.session_id = p_session_id
                          and r.student_id = k.student_id and r.ergebnis = 'richtig'),
             'hinweise', (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
                           and e.student_id = k.student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean),
             'eingriffe_ab_3', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'eingriff' and (e.payload ->> 'stufe')::int >= 3), '[]'),
             'entscheidungen_pfad', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'entscheidung_pfad'), '[]'),
             'mastery_entscheidungen', coalesce((select jsonb_agg(jsonb_build_object('skill_key', p.skill_key,
                  'entscheidung', p.neu ->> 'stand_coach', 'grund', p.grund, 'am', p.am) order by p.am)
                from public.lernpfad_protokoll p where p.session_id = p_session_id
                 and p.student_id = k.student_id and p.aktion = 'mastery'), '[]'::jsonb),
             'testlauf', s.testlauf),
           aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid()
     where a.session_id = p_session_id and a.student_id = k.student_id;
    -- A2b (Entscheidung 30): spaetestens jetzt XP fuer jedes anwesende Kind (Testlauf nie, nur einmal).
    if k.attendance = 'present' then
      perform public.session_xp_buchen(p_session_id, k.student_id);
    end if;
    v_n := v_n + 1;
  end loop;

  perform public.session_rpc_markieren();
  update public.coaching_sessions set status = 'done', beendet_am = now() where id = p_session_id;
  perform set_config('edvance.session_rpc', '', true);

  return jsonb_build_object(
    'kinder', v_n,
    'nicht_in_akte', v_ohne,
    'anwesend', (select count(*) from public.session_students where session_id = p_session_id and attendance = 'present'),
    'einheit_verbraucht', (select count(*) from public.session_students where session_id = p_session_id
                            and public.einheit_verbraucht(attendance)));
end;
$$;
