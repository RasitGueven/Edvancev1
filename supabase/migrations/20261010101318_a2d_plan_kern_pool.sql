-- A2d: Planer nach der Erklaersequenz (offene-punkte-a2c 3, offene-punkte-a2d 1).
-- Befund: session_plan_kern schaltete einem neuen Skill die Erklaersequenz auch dann vor, wenn zu dem Skill
-- keine Aufgabe im Pool steht. Nach der Sequenz blieb nur pool_leer, und session_schritt_planen wich auf den
-- naechsten offenen Skill aus (im A2c-Beispiel fkt_linear_yabschnitt). Das Kind bekam also einen Skill
-- erklaert, den es danach nicht ueben konnte. Fehlende Schwierigkeit war nicht die Ursache:
-- session_schwierigkeit faellt auf den AFB zurück (Test D).
-- Fix: Die Sequenz kommt nur, wenn session_aufgabe_waehlen fuer den Skill eine Aufgabe findet. Eine laufende
-- Sequenz und das Angebot "nochmal erklaeren" bleiben unberuehrt.
--
-- Regel (Rasit, 07.10.2026): Steht zu einem neuen Skill nur noch eine Aufgabe im Pool, entfaellt das
-- Loesungsbeispiel, diese Aufgabe kommt als Aufgabe (grund_code neu_aufgabe_ohne_beispiel). Ab zwei Aufgaben
-- bleibt es bei Beispiel, dann Aufgabe. Gilt mit und ohne Erklaersequenz. Gezaehlt wird mit
-- session_pool_anzahl (neu, intern): dieselbe Pool- und "schon benutzt"-Regel wie session_aufgabe_waehlen.
-- Grundlage: Prod-Definition (pg_get_functiondef, 07.10.2026) aus 20261008122231_a2_warmup_kern.
-- Signatur und Rechte von session_plan_kern bleiben (create or replace).

-- Zahl der Aufgaben eines Skills, die session_aufgabe_waehlen fuer dieses Kind in dieser Session noch waehlen kann.
create function public.session_pool_anzahl(p_session_id uuid, p_student_id uuid, p_skill_key text, p_testlauf boolean)
returns int
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with benutzt as (
    select a.task_id from public.session_ausgegeben a
     where a.session_id = p_session_id and a.student_id = p_student_id
    union
    select s.task_id from public.session_schritte s
     where s.student_id = p_student_id and s.task_id is not null
       and (s.session_id = p_session_id or s.art = 'beispiel')
  )
  select count(*)::int
    from public.tasks t
   where t.skill_key = p_skill_key
     and t.id not in (select b.task_id from benutzt b)
     and public.session_im_pool(t.id, p_testlauf)
$$;
revoke all on function public.session_pool_anzahl(uuid, uuid, text, boolean) from public, anon, authenticated;

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
          'gemischt', jsonb_build_object('signale', v_sig));
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
    case when p_vertiefung then 'vertiefung' else 'kern' end, jsonb_build_object('signale', v_sig));
end;
$function$;
