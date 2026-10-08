-- C3.1 Grund des letzten Schritts mit Zahl (Session-Rahmen C3, Umfang 3; offene-punkte-c2 4).
-- Entscheidung Rasit (08.10.2026): Die Engine legt die Zahlen in p_extra unter 'details', session_naechster_schritt
-- schreibt sie in die neue Spalte session_schritte.details. Sonst aendert sich kein Verhalten der Engine.
--   session_schritte.details   jsonb, Standard '{}' (alte Zeilen: Grund weiter grob aus grund_code)
--   session_plan_kern          Fenster ausgewertet (Kernarbeit/Vertiefung): richtig, von, ziel, aenderung;
--                              eingemischt: mischanteil. Auswahl, grund und grund_code unveraendert.
--   session_naechster_schritt  schreibt v -> 'details' mit; sonst unveraendert.
-- Nur Coach: session_schritte bleibt ohne Rechte fuer anon/authenticated (kein Grant), die Append-only-Sperre
-- (session_schritte_nur_anhaengen) bleibt, session_schritt_oeffentlich (Whitelist) bleibt unveraendert, also
-- erreicht details weder session_naechster_schritt noch tablet_stand (Datenvertrag 8 unveraendert).
-- Grundlage: Prod-Definitionen (pg_get_functiondef, md5 gleich dem Neuaufbau, dbread 08.10.2026) aus
-- 20261010101318_a2d_plan_kern_pool und 20261009101205_a2b_session_xp. create or replace behaelt Rechte.

alter table public.session_schritte
  add column details jsonb not null default '{}'::jsonb
  constraint session_schritte_details_check check (jsonb_typeof(details) = 'object');

comment on column public.session_schritte.details is
  'C3: Zahlen zum Grund fuer den Coach (Fenster: richtig, von, ziel, aenderung; eingemischt: mischanteil). Nie am Tablet.';

CREATE OR REPLACE FUNCTION public.session_plan_kern(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_aktuell text, p_vertiefung boolean, p_ziel_skills text[], p_ziel_label text, p_fall text, p_thema text, p_letzt session_schritte)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_lab    text := public.session_label(p_aktuell);
  v_modus  text := public.session_modus(p_student_id, p_aktuell);
  v_l      int := public.session_wert_zahl(p_session_id, 'loesungsbeispiele_vor_aufgabe')::int;
  v_angeb  int := public.session_wert_zahl(p_session_id, 'erklaerung_anbieten_nach_fehlversuchen')::int;
  v_misch  numeric := public.session_wert_zahl(p_session_id, 'mischanteil');
  -- C3: Ziel-Erfolgsquote fuer details (nur Coach).
  v_ziel   numeric := public.session_wert_zahl(p_session_id, 'ziel_erfolgsquote');
  v_vorg   boolean := public.session_wert(p_session_id, 'erklaerung_bei_neuem_skill') #>> '{}' = 'vorgeschaltet';
  v_seq    boolean := (public.erklaer_naechste_kernidee(p_aktuell, 0, p_testlauf)).id is not null;
  e        record;
  niv      record := public.session_niveau(p_session_id, p_student_id, p_aktuell);
  v_sig    jsonb := '[]';
  v_b      int;
  v_a      int;
  v_bsp    record;
  v_seit   timestamptz;
  v_fehl   int;
  v_n      int;
  c        record;
  w        record;
  v_grund  text;
begin
  select * into e from public.session_erklaer_stand(p_session_id, p_student_id, p_aktuell);
  -- "haengt" (H): auf Stufe 1 und weiter unter der Zielquote, einmal je Auswertung.
  if niv.haengt_bei is not null and not exists (
       select 1 from public.session_ereignisse x where x.session_id = p_session_id and x.student_id = p_student_id
          and x.typ = 'signal' and x.payload ->> 'grund_code' = 'haengt_niveau' and x.zeit > niv.haengt_bei) then
    v_sig := jsonb_build_array(jsonb_build_object('art', 'haengt', 'skill_key', p_aktuell, 'grund_code', 'haengt_niveau',
      'grund', 'hängt: ' || v_lab || ' auf Stufe 1 unter der Zielquote (' || coalesce(niv.quote, '') || ')'));
  end if;

  -- Erklaersequenz (F, E1): laeuft -> weiter in der Sequenz; Signal -> warten auf den Coach.
  if e.stand = 'laeuft' or (e.stand is null and p_letzt.art = 'erklaerung' and p_letzt.skill_key = p_aktuell) then
    return public.session_schritt('erklaerung', 'kern', p_aktuell, null, 'gefuehrt', false, null,
      'Erklärsequenz ' || v_lab || coalesce(': Kernidee ' || e.kernidee_nr || ' von ' || e.kernideen
                                            || case when e.runde > 1 then ', Runde ' || e.runde || ' (Variante ' || e.variante || ')' else '' end,
                                            ': noch nicht am Tablet begonnen'),
      'erklaerung_laeuft', jsonb_build_object('signale', v_sig));
  end if;
  if e.stand = 'signal' then
    return public.session_schritt('warten', 'kern', p_aktuell, null, null, false, null,
      'Erklärsequenz ' || v_lab || ': Signal an den Coach nach ' || e.runde || ' Runden', 'warten_erklaersignal',
      jsonb_build_object('signale', v_sig));
  end if;

  -- Neuer Skill: keine Belege des Kindes ausserhalb dieser Session.
  if not p_vertiefung
     and not exists (select 1 from public.lernpfad_belege b where b.student_id = p_student_id
                      and b.skill_key = p_aktuell and b.session_id <> p_session_id)
     and not exists (select 1 from public.session_antworten a join public.tasks t on t.id = a.task_id
                      where a.student_id = p_student_id and a.session_id <> p_session_id and t.skill_key = p_aktuell) then
    -- A2d: Sequenz nur, wenn es danach etwas zu ueben gibt (eine Aufgabe im Pool). Sonst faellt der Skill
    -- unten auf pool_leer, und session_schritt_planen weicht auf den naechsten offenen Skill aus.
    if v_seq and not exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                              and s.student_id = p_student_id and s.skill_key = p_aktuell
                              and s.art in ('erklaerung', 'erklaerung_angebot'))
       and (public.session_aufgabe_waehlen(p_session_id, p_student_id, p_aktuell, niv.niveau, p_testlauf)).task_id
           is not null then
      return public.session_schritt(case when v_vorg then 'erklaerung' else 'erklaerung_angebot' end, 'kern',
        p_aktuell, null, 'gefuehrt', false, null,
        'Neuer Skill ' || v_lab || ': ' || case when v_vorg then 'Erklärsequenz vorgeschaltet' else 'Erklärung angeboten' end,
        case when v_vorg then 'neu_erklaerung' else 'neu_erklaerung_angebot' end,
        jsonb_build_object('signale', v_sig, 'erklaerung_weg', 'sequenz'));
    end if;
    select count(*) filter (where s.art = 'beispiel'), count(*) filter (where s.art = 'aufgabe' and s.nach_beispiel)
      into v_b, v_a
      from public.session_schritte s
     where s.session_id = p_session_id and s.student_id = p_student_id and s.skill_key = p_aktuell;
    if v_a < v_l then
      if v_b <= v_a then
        -- A2d (Rasit 07.10.): nur noch eine Aufgabe im Pool -> kein Loesungsbeispiel, sie kommt als Aufgabe.
        -- nach_beispiel = true: zaehlt als Einfuehrungsaufgabe (v_a), danach normale Kernarbeit.
        if public.session_pool_anzahl(p_session_id, p_student_id, p_aktuell, p_testlauf) = 1 then
          select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_aktuell, niv.niveau, p_testlauf);
          return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(w.difficulty, niv.niveau),
            'Neuer Skill ' || v_lab || ': nur eine Aufgabe im Pool, Lösungsbeispiel entfällt',
            'neu_aufgabe_ohne_beispiel', jsonb_build_object('signale', v_sig, 'nach_beispiel', true));
        end if;
        select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_aktuell, niv.niveau, p_testlauf, true);
        if w.task_id is not null then
          return public.session_schritt('beispiel', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(w.difficulty, niv.niveau),
            'Neuer Skill ' || v_lab || ': Lösungsbeispiel ' || (v_b + 1) || ' von ' || v_l
              || case when v_seq then '' else ' (keine Erklärung vorhanden)' end,
            case when v_seq then 'neu_beispiel' else 'neu_beispiel_ohne_erklaerung' end,
            jsonb_build_object('signale', v_sig));
        end if;
      else
        select public.session_schwierigkeit(t.difficulty, t.afb) as difficulty, s.schwierigkeit into v_bsp
          from public.session_schritte s left join public.tasks t on t.id = s.task_id
         where s.session_id = p_session_id and s.student_id = p_student_id and s.skill_key = p_aktuell
           and s.art = 'beispiel'
         order by s.id desc limit 1;
        select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_aktuell,
               coalesce(v_bsp.difficulty, v_bsp.schwierigkeit, niv.niveau), p_testlauf);
        if w.task_id is not null then
          return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(v_bsp.difficulty, v_bsp.schwierigkeit, niv.niveau),
            'Neuer Skill ' || v_lab || ': ähnliche Aufgabe zum Lösungsbeispiel', 'neu_aehnliche_aufgabe',
            jsonb_build_object('signale', v_sig, 'nach_beispiel', true));
        end if;
      end if;
    end if;
  end if;

  -- "Nochmal erklaeren" (G): Fehlversuche in Folge seit dem letzten Angebot bzw. der Erklaerung.
  select max(s.zeit) into v_seit from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.skill_key = p_aktuell
     and s.art in ('erklaerung', 'erklaerung_angebot');
  select count(*) into v_fehl
    from public.session_antworten a join public.tasks t on t.id = a.task_id
   where a.session_id = p_session_id and a.student_id = p_student_id and t.skill_key = p_aktuell
     and a.ergebnis <> 'richtig' and a.zeit > coalesce(v_seit, '-infinity')
     and a.zeit > coalesce((select max(r.zeit) from public.session_antworten r join public.tasks t2 on t2.id = r.task_id
                             where r.session_id = p_session_id and r.student_id = p_student_id
                               and t2.skill_key = p_aktuell and r.ergebnis = 'richtig'), '-infinity');
  if v_seq and v_fehl >= v_angeb and p_letzt.art is distinct from 'erklaerung_angebot' then
    return public.session_schritt('erklaerung_angebot', 'kern', p_aktuell, null, 'gefuehrt', false, null,
      v_fehl || ' Fehlversuche in Folge bei ' || v_lab || ': nochmal erklären angeboten', 'erklaerung_angebot',
      jsonb_build_object('signale', v_sig,
                         'erklaerung_weg', case when e.stand is null then 'sequenz' else 'nachlesen' end));
  end if;

  -- Mischen (I): die n-te Uebungsaufgabe der Kernarbeit wird gemischt, wenn
  -- floor((n+1)*m) > floor(n*m). Einfuehrungsaufgaben zaehlen nicht.
  select count(*) into v_n from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'kern'
     and s.art = 'aufgabe' and not s.nach_beispiel;
  if floor((v_n + 1) * v_misch) > floor(v_n * v_misch) then
    for c in
      select * from public.session_misch_kandidaten(p_session_id, p_student_id, p_aktuell, p_ziel_skills,
                                                    case when p_fall = 'klassenarbeit' then p_thema end)
    loop
      select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, c.skill_key,
             (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau, p_testlauf);
      if w.task_id is not null then
        return public.session_schritt('aufgabe', 'kern', c.skill_key, w.task_id,
          public.session_modus(p_student_id, c.skill_key), true,
          (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau,
          'Eingemischt: ' || public.session_label(c.skill_key)
            || case when c.zuletzt is null then ', noch nicht in einer Session geübt'
                    else ', länger nicht geübt' end
            || case when c.voraussetzung then ' (Voraussetzung von ' || coalesce(p_ziel_label, v_lab) || ')' else '' end,
          'gemischt', jsonb_build_object('signale', v_sig,
            -- C3: Mischanteil fuer den Coach (session_schritte.details, nie am Tablet).
            'details', jsonb_build_object('mischanteil', v_misch)));
      end if;
    end loop;
  end if;

  select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_aktuell, niv.niveau, p_testlauf);
  if w.task_id is null then
    return public.session_schritt('warten', 'kern', p_aktuell, null, null, false, niv.niveau,
      'Keine passende Aufgabe im Pool für ' || v_lab, 'pool_leer', jsonb_build_object('signale', v_sig));
  end if;
  v_grund := case when p_vertiefung then 'Ziel erreicht, Vertiefung: ' else 'Kernarbeit: ' end || v_lab
    || ', Stufe ' || niv.niveau
    || case niv.aenderung when 1 then ', eine Stufe schwerer (' || niv.quote || ' ohne Hinweis richtig)'
                          when -1 then ', eine Stufe leichter (' || niv.quote || ' ohne Hinweis richtig)'
                          when -2 then ', bleibt auf Stufe 1 (' || niv.quote || ' ohne Hinweis richtig)'
                          else '' end
    || ', ' || case v_modus when 'gefuehrt' then 'geführt' else 'selbstständig' end;
  return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, v_modus, false, niv.niveau, v_grund,
    case when p_vertiefung then 'vertiefung' else 'kern' end,
    jsonb_build_object('signale', v_sig)
    -- C3: Fenster gerade ausgewertet (niv.quote = 'n von 5', session_niveau): Zahlen fuer den Coach
    -- (session_schritte.details, nie am Tablet). aenderung 1 = schwerer, -1 = leichter, -2 = bleibt auf Stufe 1,
    -- 0 = im Zielbereich.
    || case when niv.quote is not null then jsonb_build_object('details', jsonb_build_object(
         'richtig', split_part(niv.quote, ' von ', 1)::int, 'von', split_part(niv.quote, ' von ', 2)::int,
         'ziel', v_ziel, 'aenderung', niv.aenderung)) else '{}'::jsonb end);
end;
$function$;

CREATE OR REPLACE FUNCTION public.session_naechster_schritt(p_session_id uuid, p_student_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
           nach_beispiel, schwierigkeit, grund, grund_code, details)
    values (p_session_id, t.student_id, v ->> 'art', v ->> 'phase', v ->> 'skill_key', (v ->> 'task_id')::uuid,
            v ->> 'modus', coalesce((v ->> 'eingemischt')::boolean, false),
            coalesce((v ->> 'nach_beispiel')::boolean, false), (v ->> 'schwierigkeit')::int,
            v ->> 'grund', v ->> 'grund_code',
            -- C3: Zahlen zum Grund (nur Coach; session_schritt_oeffentlich gibt sie nicht weiter).
            coalesce(v -> 'details', '{}'::jsonb));
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
$function$;
