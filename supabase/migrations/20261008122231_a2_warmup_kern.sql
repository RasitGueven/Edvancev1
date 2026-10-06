-- A2.2 Session-Engine: Warm-up und Kernarbeit (Entscheidungen A2 E bis I).
--
-- Beide Planer lesen nur und liefern einen Schritt als jsonb (art, phase, skill_key, task_id,
-- modus, eingemischt, schwierigkeit, grund, grund_code) plus "signale" (Signale, die
-- session_naechster_schritt beim Buchen in session_ereignisse schreibt). Ein Planer ohne art
-- heisst: diese Phase ist fuer das Kind vorbei.

create function public.session_schritt(
  p_art text, p_phase text, p_skill_key text, p_task_id uuid, p_modus text, p_eingemischt boolean,
  p_schwierigkeit int, p_grund text, p_grund_code text, p_extra jsonb default '{}'
)
returns jsonb
language sql
immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object('art', p_art, 'phase', p_phase, 'skill_key', p_skill_key, 'task_id', p_task_id,
                            'modus', p_modus, 'eingemischt', coalesce(p_eingemischt, false),
                            'schwierigkeit', p_schwierigkeit, 'grund', p_grund, 'grund_code', p_grund_code)
         || coalesce(p_extra, '{}'::jsonb)
$$;

create function public.session_label(p_skill_key text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((select s.label from public.skills s where s.skill_key = p_skill_key), p_skill_key)
$$;

-- ── Warm-up (E) ───────────────────────────────────────────────────────────
-- warmup_aufgaben Aufgaben aus sicheren Skills, bevorzugt Voraussetzungen des Ziels, um
-- warmup_leichter_stufen leichter als das Niveau des Kindes auf dem Skill. Bleibt beim Skill
-- der vorigen Warm-up-Aufgabe, solange er Aufgaben hat. signal_fehlversuche Fehlversuche auf
-- einer Voraussetzung -> Signal "Entscheidung: eine Stufe tiefer?" (einmal je Skill und Session).
-- Danach wartet das Kind auf die Entscheidung, laengstens bis die Uhr die Kernarbeit beginnt.
create function public.session_plan_warmup(p_session_id uuid, p_student_id uuid, p_testlauf boolean,
                                           p_uhr text, p_aktuell text, p_ziel_skills text[], p_ziel_label text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_n       int := public.session_wert_zahl(p_session_id, 'warmup_aufgaben')::int;
  v_leicht  int := public.session_wert_zahl(p_session_id, 'warmup_leichter_stufen')::int;
  v_fehl    int := public.session_wert_zahl(p_session_id, 'signal_fehlversuche')::int;
  v_sig     jsonb := '[]';
  v_fertig  int;
  v_letzt   text;
  v_voraus  text[];
  c         record;
  w         record;
  v_niv     int;
  v_grund   text;
begin
  v_voraus := array(select distinct a.skill_key from unnest(p_ziel_skills) z(sk)
                     cross join lateral public.lsa_abschluss(z.sk) a);

  -- Signal: Fehlversuche auf einer Voraussetzung des aktuellen Skills.
  for c in
    select t.skill_key, count(*) filter (where a.ergebnis <> 'richtig') as fehl
      from public.session_antworten a join public.tasks t on t.id = a.task_id
     where a.session_id = p_session_id and a.student_id = p_student_id and a.phase = 'warmup'
     group by t.skill_key
  loop
    if c.fehl >= v_fehl and p_aktuell is not null
       and c.skill_key in (select a.skill_key from public.lsa_abschluss(p_aktuell) a)
       and not exists (select 1 from public.session_ereignisse e
                        where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
                          and e.payload ->> 'art' = 'entscheidung' and e.payload ->> 'skill_key' = c.skill_key) then
      v_sig := v_sig || jsonb_build_object('art', 'entscheidung', 'skill_key', c.skill_key, 'ziel_skill_key', p_aktuell,
        'grund', 'Entscheidung: eine Stufe tiefer? ' || c.fehl || ' Fehlversuche bei ' || public.session_label(c.skill_key)
                 || ' im Warm-up', 'grund_code', 'entscheidung_tiefer');
    end if;
  end loop;

  select count(*), (array_agg(s.skill_key order by s.id desc))[1] into v_fertig, v_letzt
    from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'warmup' and s.art = 'aufgabe';

  if v_fertig >= v_n then
    if p_uhr in ('checkin', 'warmup')
       and (jsonb_array_length(v_sig) > 0
            or exists (select 1 from public.session_ereignisse e
                        where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
                          and e.payload ->> 'art' = 'entscheidung'
                          and not exists (select 1 from public.session_ereignisse x
                                           where x.session_id = p_session_id and x.student_id = p_student_id
                                             and x.typ = 'signal_erledigt' and x.payload ->> 'art' = 'entscheidung'
                                             and x.zeit > e.zeit))) then
      return public.session_schritt('warten', 'warmup', p_aktuell, null, null, false, null,
        'Warm-up fertig: Entscheidung des Coaches offen (eine Stufe tiefer?)', 'warten_entscheidung',
        jsonb_build_object('signale', v_sig));
    end if;
    return jsonb_build_object('signale', v_sig);
  end if;

  -- Kandidaten: sichere Skills und die Skills, die heute schon im Warm-up dran waren (ein Fehler im
  -- Warm-up macht einen Skill im Lernpfad unsicher; das Warm-up bleibt trotzdem bei ihm).
  for c in
    select s.skill_key, s.quelle, s.zuletzt, s.skill_key = any (v_voraus) as voraus
      from (select distinct on (u.skill_key) u.* from (
              select ss.skill_key, ss.quelle, ss.zuletzt from public.session_sichere_skills(p_student_id) ss
              union all
              select x.skill_key, 'lernpfad', null from public.session_schritte x
               where x.session_id = p_session_id and x.student_id = p_student_id and x.phase = 'warmup'
                 and x.art = 'aufgabe') u
            order by u.skill_key, u.zuletzt nulls last) s
     where s.skill_key is distinct from p_aktuell
     order by (s.skill_key = v_letzt) desc, (s.skill_key = any (v_voraus)) desc,
              exists (select 1 from public.skill_kante k where k.skill_key = p_aktuell
                       and k.voraussetzt_skill_key = s.skill_key) desc,
              s.zuletzt nulls first, s.skill_key
  loop
    v_niv := greatest(1, (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau - v_leicht);
    select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, c.skill_key, v_niv, p_testlauf);
    if w.task_id is not null then
      v_grund := 'Warm-up ' || (v_fertig + 1) || ' von ' || v_n || ': '
        || case when c.voraus then 'Voraussetzung von ' || coalesce(p_ziel_label, public.session_label(p_aktuell))
                when c.quelle = 'lsa' then public.session_label(c.skill_key) || ', sicher in der LSA'
                else public.session_label(c.skill_key) || ', sicher aus früheren Sessions' end
        || ', ' || case v_leicht when 0 then 'auf gleicher Stufe' when 1 then 'eine Stufe leichter'
                                 else v_leicht || ' Stufen leichter' end;
      return public.session_schritt('aufgabe', 'warmup', c.skill_key, w.task_id,
        public.session_modus(p_student_id, c.skill_key), false, v_niv, v_grund,
        case when c.voraus then 'warmup_voraussetzung' else 'warmup_sicher' end,
        jsonb_build_object('signale', v_sig));
    end if;
  end loop;

  -- Kein sicherer Skill mit Aufgaben: das Warm-up entfaellt.
  return jsonb_build_object('signale', v_sig, 'ohne_warmup', true);
end;
$$;

-- ── Kernarbeit (F, G, H, I) ───────────────────────────────────────────────
-- Reihenfolge: laufende Erklaersequenz -> Signal der Sequenz -> Einfuehrung eines neuen Skills
-- (Erklaerung bzw. Angebot, dann loesungsbeispiele_vor_aufgabe Mal Beispiel + aehnliche
-- Aufgabe) -> "Nochmal erklaeren" nach Fehlversuchen -> Mischen (deterministischer Zaehler)
-- -> Aufgabe des aktuellen Skills auf seinem Niveau.
create function public.session_plan_kern(p_session_id uuid, p_student_id uuid, p_testlauf boolean,
                                         p_aktuell text, p_vertiefung boolean, p_ziel_skills text[],
                                         p_ziel_label text, p_fall text, p_thema text, p_letzt public.session_schritte)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
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
    if v_seq and not exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                              and s.student_id = p_student_id and s.skill_key = p_aktuell
                              and s.art in ('erklaerung', 'erklaerung_angebot')) then
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
$$;

revoke all on function
  public.session_schritt(text, text, text, uuid, text, boolean, int, text, text, jsonb), public.session_label(text),
  public.session_plan_warmup(uuid, uuid, boolean, text, text, text[], text),
  public.session_plan_kern(uuid, uuid, boolean, text, boolean, text[], text, text, text, public.session_schritte)
  from public, anon, authenticated;
