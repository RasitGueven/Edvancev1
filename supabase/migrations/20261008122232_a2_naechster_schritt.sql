-- A2.2 Session-Engine: der naechste Schritt eines Kindes (Entscheidung A2 A).
--
--   session_schritt_planen     liest nur: offener Schritt (Aufgabe ohne Antwort, Termin) oder der
--                              naechste nach Uhr und Stand (Warm-up, Kernarbeit, Check-out).
--   session_naechster_schritt  oeffentlich. Vom Tablet des Kindes (Zuordnung ueber session_tablets)
--                              bucht er: Phasenwechsel, Schritt mit Grund, Ausgabe der Aufgabe,
--                              Signale, Exit-Ergebnis. Coach der Session und Admin bekommen eine
--                              Vorschau, die nichts bucht. Alle anderen: 42501.
-- Die Antwort enthaelt nie eine Loesung, ausser den Loesungsweg bei art = beispiel.

create function public.session_schritt_planen(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s        public.coaching_sessions;
  v_letzt  public.session_schritte;
  v_uhr    text;
  f        record;
  v_ziel   text[];
  v_akt    text;
  v_vert   boolean := false;
  v_label  text;
  v_kand   jsonb;
  v_kern   jsonb;
  r        jsonb;
begin
  select * into s from public.coaching_sessions where id = p_session_id;
  if s.status = 'done' then
    return public.session_schritt('fertig', 'checkout', null, null, null, false, null,
      'Session abgeschlossen', 'session_abgeschlossen');
  elsif s.status is distinct from 'active' then
    return public.session_schritt('warten', 'checkin', null, null, null, false, null,
      'Session ist noch nicht gestartet', 'session_nicht_gestartet');
  end if;
  if not exists (select 1 from public.session_tablets t where t.session_id = p_session_id
                  and t.student_id = p_student_id and t.geloest_am is null) then
    return public.session_schritt('warten', 'checkin', null, null, null, false, null,
      'Kind hat noch kein Tablet', 'kein_tablet');
  end if;
  if not exists (select 1 from public.session_checkin c where c.session_id = p_session_id
                  and c.student_id = p_student_id and c.kind_am is not null) then
    return public.session_schritt('warten', 'checkin', null, null, null, false, null,
      'Check-in am Tablet läuft', 'checkin_laeuft');
  end if;

  select * into v_letzt from public.session_schritte x
   where x.session_id = p_session_id and x.student_id = p_student_id order by x.id desc limit 1;

  -- Offene Schritte kommen unveraendert wieder (kein neuer Eintrag).
  if (v_letzt.art in ('aufgabe', 'exit')
      and not coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, v_letzt.task_id)).erledigt, false))
     or v_letzt.art = 'fertig'
     or (v_letzt.art = 'termin' and not exists (select 1 from public.session_kind_abschluss k
            where k.session_id = p_session_id and k.student_id = p_student_id and k.quest_termin is not null)) then
    return public.session_schritt(v_letzt.art, v_letzt.phase, v_letzt.skill_key, v_letzt.task_id, v_letzt.modus,
      v_letzt.eingemischt, v_letzt.schwierigkeit, v_letzt.grund, v_letzt.grund_code,
      jsonb_build_object('offen', true, 'nach_beispiel', v_letzt.nach_beispiel));
  end if;

  v_uhr := public.session_uhr_phase(p_session_id);
  v_kand := public.session_kandidat_signale(p_session_id, p_student_id);
  f := public.session_fall(p_session_id, p_student_id);
  v_label := (select th.label from public.themen th where th.thema_key = f.thema_key);

  select array_agg(z.skill_key order by z.reihenfolge),
         (array_agg(z.skill_key order by z.reihenfolge) filter (where z.offen))[1]
    into v_ziel, v_akt
    from public.session_zielliste(p_session_id, p_student_id) z;
  if v_akt is null and cardinality(v_ziel) > 0 then
    v_akt := v_ziel[cardinality(v_ziel)];
    v_vert := true;
  end if;

  if v_uhr = 'checkout' or v_letzt.phase = 'checkout' then
    r := public.session_plan_checkout(p_session_id, p_student_id, s.testlauf, v_akt);
  else
    if v_uhr in ('checkin', 'warmup') then
      r := public.session_plan_warmup(p_session_id, p_student_id, s.testlauf, v_uhr, v_akt,
                                      coalesce(v_ziel, '{}'), v_label);
    end if;
    if r ->> 'art' is null then
      if v_akt is null then
        r := public.session_schritt('warten', 'kern', null, null, null, false, null,
          'Kein Ziel: kein Thema gewählt und keine Lücke im Lernpfad', 'kein_ziel',
          jsonb_build_object('signale', coalesce(r -> 'signale', '[]')));
      else
        v_kern := public.session_plan_kern(p_session_id, p_student_id, s.testlauf, v_akt, v_vert,
                                           coalesce(v_ziel, '{}'), v_label, f.fall, f.thema_key, v_letzt);
        r := v_kern || jsonb_build_object('signale', coalesce(r -> 'signale', '[]') || (v_kern -> 'signale'));
      end if;
    end if;
  end if;

  return r || jsonb_build_object('signale', coalesce(r -> 'signale', '[]') || v_kand,
                                 'fall', f.fall, 'fall_gewaehlt', f.fall_gewaehlt, 'ziel_thema_key', f.thema_key);
end;
$$;

-- Was das Tablet bzw. die Vorschau sieht: ohne interne Felder; Aufgabe ohne Loesung
-- (lsa_question_payload), beim Beispiel zusaetzlich der Loesungsweg.
create function public.session_schritt_oeffentlich(p_schritt jsonb)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
           'art', p_schritt ->> 'art', 'phase', p_schritt ->> 'phase', 'skill_key', p_schritt ->> 'skill_key',
           'skill_label', case when p_schritt ->> 'skill_key' is not null
                               then public.session_label(p_schritt ->> 'skill_key') end,
           'task_id', p_schritt ->> 'task_id', 'modus', p_schritt ->> 'modus',
           'eingemischt', coalesce((p_schritt ->> 'eingemischt')::boolean, false),
           'schwierigkeit', (p_schritt ->> 'schwierigkeit')::int,
           'grund', p_schritt ->> 'grund', 'grund_code', p_schritt ->> 'grund_code',
           'hinweise_erlaubt', p_schritt ->> 'art' = 'aufgabe',
           'aufgabe', case when p_schritt ->> 'art' in ('aufgabe', 'exit', 'beispiel')
                           then public.lsa_question_payload((p_schritt ->> 'task_id')::uuid) end)
         || case when p_schritt ->> 'art' = 'beispiel' then jsonb_build_object('loesungsweg',
              (select ts.solution from public.task_solutions ts where ts.task_id = (p_schritt ->> 'task_id')::uuid))
            else '{}'::jsonb end
         || case when p_schritt ? 'erklaerung_weg' then jsonb_build_object('erklaerung_weg', p_schritt ->> 'erklaerung_weg')
            else '{}'::jsonb end
$$;

create function public.session_naechster_schritt(p_session_id uuid, p_student_id uuid default null)
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
    return public.session_schritt_oeffentlich(public.session_schritt_planen(p_session_id, p_student_id))
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
  -- Wiederholtes Warten mit demselben Grund wird nicht erneut eingetragen.
  if not (v ->> 'art' = 'warten' and v_letzt.art = 'warten' and v_letzt.grund_code = v ->> 'grund_code'
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

comment on function public.session_naechster_schritt(uuid, uuid) is
  'A2: naechster Schritt eines Kindes (art, phase, skill_key, task_id, modus, eingemischt, grund). Vom Tablet gebucht; Coach der Session und Admin: Vorschau ohne Buchung.';

revoke all on function
  public.session_schritt_planen(uuid, uuid), public.session_schritt_oeffentlich(jsonb),
  public.session_naechster_schritt(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.session_naechster_schritt(uuid, uuid) to authenticated;
