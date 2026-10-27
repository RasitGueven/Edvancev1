-- Reihe 1 · C2 Phasen und Auswahl, Teil 2: Planer der Session (Bauauftrag C2, Konzept Sessionreihe 1 §2.4–2.5, §9,
-- Konzept Session-Ablauf §1–4). Setzt 20261027133007_reihe1_c2_bausteine und C1 voraus.
--
--   session_plan_warmup      Abruf nach Fälligkeit plus Voraussetzungen des heutigen Ziels, ohne Hinweise
--   session_plan_checkout    Recap statt Exit, keine Termin-Wahl (Entscheidung 27.10.), dann fertig
--   session_plan_gp          Generalprobe mit „sicher / noch üben“, session_gp_waehlen fürs Tablet
--   session_schritt_planen   Ziel aus dem Reihenplan, Recap-Fenster, „Zeig's mir“, Generalprobe
--   session_plan_kern        Ziehen mit Rolle (beispiel, uebung, transfer), Zwilling nach falscher Antwort,
--                            Transfer ab sicherer Stufe 3 (Hinweise nur Stufe 1)
--   session_naechster_schritt speichert Rolle und Hinweisgrenze, meldet Gezeigtes an aufgabe_gezeigt (A)
--   session_schritt_oeffentlich Rolle, Hinweisgrenze, Rückmeldung, gp_ergebnis; Payload über aufgabe_payload (A)
--   antwort_abgeben          Wertung über aufgabe_werten (A), Recap ohne Beleg, Generalprobe ohne Rückmeldung
--   hinweis_abrufen          Recap/Generalprobe/„Zeig's mir“ ohne, Transfer nur Stufe 1
-- Fremde Funktionen (A, D) nur über to_regprocedure + execute (späte Bindung, Konzept §9). Solange sie fehlen, läuft die
-- Session wie bisher weiter (Pool session_aufgabe_waehlen); Transfer und Generalprobe brauchen die Instanzen von A.
-- Gleiche Signaturen wie bisher, Grants bleiben. Rollback: supabase/rollback/20261027133413_reihe1_c2_phasen_auswahl.sql.

-- Bisherige Fassungen (A2/F1) unter neuem Namen: gelten für Kinder ohne aktive Reihe unverändert weiter.
CREATE OR REPLACE FUNCTION public.session_plan_warmup_a2(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_uhr text, p_aktuell text, p_ziel_skills text[], p_ziel_label text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  -- A2d: je Skill auch die Zahl der Warm-up-Aufgaben und davon richtig (alle Teile richtig) fuer den Coach.
  for c in
    select x.skill_key, sum(x.fehl)::int as fehl, count(*)::int as aufgaben,
           (count(*) filter (where x.alle_richtig))::int as richtig
      from (select t.skill_key, a.task_id, count(*) filter (where a.ergebnis <> 'richtig') as fehl,
                   bool_and(a.ergebnis = 'richtig') as alle_richtig
              from public.session_antworten a join public.tasks t on t.id = a.task_id
             where a.session_id = p_session_id and a.student_id = p_student_id and a.phase = 'warmup'
             group by t.skill_key, a.task_id) x
     group by x.skill_key
  loop
    if c.fehl >= v_fehl and p_aktuell is not null
       and c.skill_key in (select a.skill_key from public.lsa_abschluss(p_aktuell) a)
       and not exists (select 1 from public.session_ereignisse e
                        where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
                          and e.payload ->> 'art' = 'entscheidung' and e.payload ->> 'skill_key' = c.skill_key) then
      v_sig := v_sig || jsonb_build_object('art', 'entscheidung', 'skill_key', c.skill_key, 'ziel_skill_key', p_aktuell,
        'grund', 'Entscheidung: eine Stufe tiefer? ' || c.fehl || ' Fehlversuche bei ' || public.session_label(c.skill_key)
                 || ' im Warm-up', 'grund_code', 'entscheidung_tiefer',
        -- A2d (aus C2): Zahlen fuer den Coach. Nur im Signal (session_ereignisse -> raum_signale,
        -- coach_raum_live), nie am Tablet: session_schritt_oeffentlich gibt keine Signale weiter.
        'voraussetzung_skill_key', c.skill_key, 'voraussetzung_label', public.session_label(c.skill_key),
        'warmup_aufgaben', c.aufgaben, 'warmup_richtig', c.richtig);
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
  -- F1 (E3, Rasit 08.10.2026; offene-punkte-a2 F17): Reihenfolge Fokus (Skill der vorigen Warm-up-Aufgabe, F9),
  -- Voraussetzung des Ziels, dann (1) bekannter Stand (Lernpfad oder LSA-Urteil) vor unbekanntem, (2) noch nicht
  -- sicher vor sicher, (3) geringster Abstand im Graphen zum ersten offenen Ziel-Skill (p_aktuell), (4) skill_key.
  -- Die Kandidatenmenge bleibt unveraendert.
  for c in
    with recursive abstand(sk, n) as (
      select p_aktuell, 0 where p_aktuell is not null
      union
      select k.voraussetzt_skill_key, a.n + 1
        from public.skill_kante k join abstand a on k.skill_key = a.sk
       where a.n < 20
    ),
    lsa as (select u.skill_key, u.zustand from public.lernpfad_lsa_urteile(p_student_id) u)
    select s.skill_key, s.quelle, s.zuletzt, s.skill_key = any (v_voraus) as voraus
      from (select distinct on (u.skill_key) u.* from (
              select ss.skill_key, ss.quelle, ss.zuletzt from public.session_sichere_skills(p_student_id) ss
              union all
              select x.skill_key, 'lernpfad', null from public.session_schritte x
               where x.session_id = p_session_id and x.student_id = p_student_id and x.phase = 'warmup'
                 and x.art = 'aufgabe') u
            order by u.skill_key, u.zuletzt nulls last) s
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = s.skill_key
      left join lsa on lsa.skill_key = s.skill_key
     where s.skill_key is distinct from p_aktuell
     order by (s.skill_key = v_letzt) desc, (s.skill_key = any (v_voraus)) desc,
              (l.skill_key is not null or lsa.skill_key is not null) desc,
              (case when l.skill_key is not null
                    then l.stand_system in ('offen', 'aktiv', 'noch_nicht_sicher')
                         and l.stand_coach is distinct from 'gemeistert'
                    else coalesce(lsa.zustand <> 'traegt', false) end) desc,
              (select min(a.n) from abstand a where a.sk = s.skill_key) nulls last,
              s.skill_key
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
$function$;

CREATE OR REPLACE FUNCTION public.session_plan_checkout_a2(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_aktuell text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_n      int := public.session_wert_zahl(p_session_id, 'exit_aufgaben')::int;
  v_e      int;
  v_r      int;
  v_erg    jsonb := '{}';
  c        record;
  w        record;
  v_niv    int;
begin
  select count(*), count(*) filter (where (public.session_aufgabe_stand(p_session_id, p_student_id, s.task_id)).richtig)
    into v_e, v_r
    from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.art = 'exit';

  if v_e < v_n then
    for c in
      select x.skill_key from (
        select s.skill_key, max(s.id) as zuletzt, 0 as rang from public.session_schritte s
         where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'kern'
           and s.art = 'aufgabe' and not s.eingemischt and s.skill_key is not null
         group by s.skill_key
        union all
        select p_aktuell, 0, 1 where p_aktuell is not null
      ) x
      order by x.rang, x.zuletzt desc
    loop
      v_niv := (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau;
      select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, c.skill_key, v_niv, p_testlauf);
      if w.task_id is not null then
        return public.session_schritt('exit', 'checkout', c.skill_key, w.task_id, 'selbststaendig', false, v_niv,
          'Check-out: Exit-Aufgabe ' || (v_e + 1) || ' von ' || v_n || ' zu ' || public.session_label(c.skill_key)
            || ', Stufe ' || v_niv || ', ohne Hinweise', 'exit');
      end if;
    end loop;
  end if;

  if v_e > 0 then
    v_erg := jsonb_build_object('exit_ergebnis', jsonb_build_object('richtig', v_r, 'gesamt', v_e));
  end if;
  -- Reihe 1 C2: keine Termin-Wahl mehr (Entscheidung 27.10.), auch ohne Reihe.
  return public.session_schritt('fertig', 'checkout', null, null, null, false, null,
    'Fertig für heute' || case when v_e > 0 then ': Exit ' || v_r || ' von ' || v_e || ' richtig'
                               else ' (keine Exit-Aufgabe im Pool)' end, 'fertig', v_erg);
end;
$function$;

-- Warm-up (Konzept §2.4): 1–2 fällige Abrufe (am längsten überfällig zuerst) plus 1–2 Voraussetzungen des heutigen
-- Ziels, zusammen warmup_aufgaben, ohne Hinweise, jeder Skill einmal. Stufe eine unter der zuletzt sicheren, mindestens 1
-- (dort keine Instanz: darunter, dann darüber; session_ziehen). Das Signal „eine Stufe tiefer?“ nach zwei Fehlern auf
-- einer Voraussetzung bleibt wie bisher.
create or replace function public.session_plan_warmup(p_session_id uuid, p_student_id uuid, p_testlauf boolean,
                                                      p_uhr text, p_aktuell text, p_ziel_skills text[], p_ziel_label text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_n       int := public.session_wert_zahl(p_session_id, 'warmup_aufgaben')::int;
  v_abr_max int := public.session_wert_zahl(p_session_id, 'warmup_abruf_max')::int;
  v_vor_max int := public.session_wert_zahl(p_session_id, 'warmup_voraus_max')::int;
  v_fehl    int := public.session_wert_zahl(p_session_id, 'signal_fehlversuche')::int;
  v_sig     jsonb := '[]';
  v_fertig  int;
  v_abr     int;
  v_vor     int;
  c         record;
  w         record;
begin
  -- Ohne aktive Reihe: Warm-up wie bisher (A2/F1).
  if (public.reihe_aktiv(p_student_id)).id is null then
    return public.session_plan_warmup_a2(p_session_id, p_student_id, p_testlauf, p_uhr, p_aktuell, p_ziel_skills, p_ziel_label);
  end if;
  -- Signal: Fehlversuche auf einer Voraussetzung des aktuellen Skills (unverändert aus F1/A2d).
  for c in
    select x.skill_key, sum(x.fehl)::int as fehl, count(*)::int as aufgaben,
           (count(*) filter (where x.alle_richtig))::int as richtig
      from (select t.skill_key, a.task_id, count(*) filter (where a.ergebnis <> 'richtig') as fehl,
                   bool_and(a.ergebnis = 'richtig') as alle_richtig
              from public.session_antworten a join public.tasks t on t.id = a.task_id
             where a.session_id = p_session_id and a.student_id = p_student_id and a.phase = 'warmup'
             group by t.skill_key, a.task_id) x
     group by x.skill_key
  loop
    if c.fehl >= v_fehl and p_aktuell is not null
       and c.skill_key in (select a.skill_key from public.lsa_abschluss(p_aktuell) a
                           union select k.voraussetzt_skill_key from public.skill_kante k where k.skill_key = any (p_ziel_skills))
       and not exists (select 1 from public.session_ereignisse e
                        where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
                          and e.payload ->> 'art' = 'entscheidung' and e.payload ->> 'skill_key' = c.skill_key) then
      v_sig := v_sig || jsonb_build_object('art', 'entscheidung', 'skill_key', c.skill_key, 'ziel_skill_key', p_aktuell,
        'grund', 'Entscheidung: eine Stufe tiefer? ' || c.fehl || ' Fehlversuche bei ' || public.session_label(c.skill_key)
                 || ' im Warm-up', 'grund_code', 'entscheidung_tiefer',
        'voraussetzung_skill_key', c.skill_key, 'voraussetzung_label', public.session_label(c.skill_key),
        'warmup_aufgaben', c.aufgaben, 'warmup_richtig', c.richtig);
    end if;
  end loop;

  select count(*), count(*) filter (where s.grund_code = 'warmup_abruf'), count(*) filter (where s.grund_code = 'warmup_voraussetzung')
    into v_fertig, v_abr, v_vor
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

  -- Kandidaten: erst Abrufe bis warmup_abruf_max, dann Voraussetzungen bis warmup_voraus_max, dann auffüllen.
  for c in
    with heute as (
      select s.skill_key from public.session_schritte s
       where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'warmup' and s.art = 'aufgabe'),
    abruf as (
      select f.skill_key, f.stufe, 'abruf'::text as art, row_number() over (order by f.ueberfaellig desc, f.skill_key) as nr
        from public.session_abruf_faellig(p_session_id, p_student_id) f),
    voraus as (
      select v.skill_key, greatest(1, coalesce(public.session_stufe_sicher(p_student_id, v.skill_key), 2) - 1) as stufe,
             'voraussetzung'::text as art,
             row_number() over (order by (l.stand_system in ('sicher', 'kandidat') or l.stand_coach = 'gemeistert') nulls first,
                                         v.skill_key) as nr
        from (select distinct k.voraussetzt_skill_key as skill_key from public.skill_kante k
               where k.skill_key = any (p_ziel_skills) and not (k.voraussetzt_skill_key = any (p_ziel_skills))) v
        left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = v.skill_key
       where v.skill_key not in (select a.skill_key from abruf a))
    select x.* from (select * from abruf union all select * from voraus) x
     where x.skill_key not in (select h.skill_key from heute h where h.skill_key is not null)
     order by case when x.art = 'abruf' and v_abr < v_abr_max then 0
                   when x.art = 'voraussetzung' and v_vor < v_vor_max then 1
                   when x.art = 'abruf' then 2 else 3 end, x.nr
  loop
    select * into w from public.session_ziehen(p_session_id, p_student_id, c.skill_key, 'warmup', c.stufe, p_testlauf);
    if w.task_id is not null then
      return public.session_schritt('aufgabe', 'warmup', c.skill_key, w.task_id,
        public.session_modus(p_student_id, c.skill_key), false, coalesce(w.difficulty, c.stufe),
        'Warm-up ' || (v_fertig + 1) || ' von ' || v_n || ': '
          || case when c.art = 'abruf' then 'Abruf ' || public.session_label(c.skill_key) || ' (fällig)'
                  else 'Voraussetzung von ' || coalesce(p_ziel_label, public.session_label(p_aktuell)) || ': '
                       || public.session_label(c.skill_key) end
          || ', Stufe ' || coalesce(w.difficulty, c.stufe) || ', ohne Hinweise',
        case when c.art = 'abruf' then 'warmup_abruf' else 'warmup_voraussetzung' end,
        jsonb_build_object('signale', v_sig, 'rolle', 'warmup', 'hinweise_max', 0));
    end if;
  end loop;

  -- Kein Abruf und keine Voraussetzung mit Aufgabe: das Warm-up entfällt bzw. endet.
  return jsonb_build_object('signale', v_sig, 'ohne_warmup', true);
end;
$$;

-- Recap (Ablauf §3): in den letzten recap_min Minuten vor dem Check-out recap_aufgaben Aufgaben zu den Skills der
-- Stunde, ohne Hinweise, kein Beleg (antwort_abgeben), Ergebnis als Hinweis an den Coach (exit_ergebnis). Danach fertig.
-- Keine Termin-Wahl mehr (Entscheidung 27.10.).
create or replace function public.session_plan_checkout(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_aktuell text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_n      int := public.session_wert_zahl(p_session_id, 'recap_aufgaben')::int;
  v_e      int;
  v_r      int;
  v_erg    jsonb := '{}';
  v_skills text[];
  v_sk     text;
  i        int;
  w        record;
begin
  -- Ohne aktive Reihe: Exit-Aufgaben wie bisher, aber ohne Termin-Wahl.
  if (public.reihe_aktiv(p_student_id)).id is null then
    return public.session_plan_checkout_a2(p_session_id, p_student_id, p_testlauf, p_aktuell);
  end if;
  select count(*), count(*) filter (where (public.session_aufgabe_stand(p_session_id, p_student_id, s.task_id)).richtig)
    into v_e, v_r
    from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.art = 'recap';

  select array_agg(x.skill_key order by x.zuletzt desc) into v_skills from (
    select s.skill_key, max(s.id) as zuletzt from public.session_schritte s
     where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'kern'
       and s.art in ('aufgabe', 'beispiel', 'erklaerung') and not s.eingemischt and s.skill_key is not null
     group by s.skill_key
    union all select p_aktuell, 0 where p_aktuell is not null
      and not exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                       and s.student_id = p_student_id and s.phase = 'kern' and s.skill_key = p_aktuell)) x;

  if v_e < v_n and coalesce(cardinality(v_skills), 0) > 0 then
    for i in 0 .. cardinality(v_skills) - 1 loop
      v_sk := v_skills[1 + (v_e + i) % cardinality(v_skills)];
      select * into w from public.session_ziehen(p_session_id, p_student_id, v_sk, 'recap',
             (public.session_niveau(p_session_id, p_student_id, v_sk)).niveau, p_testlauf);
      if w.task_id is not null then
        return public.session_schritt('recap', 'checkout', v_sk, w.task_id, 'selbststaendig', false, w.difficulty,
          'Recap ' || (v_e + 1) || ' von ' || v_n || ' zu ' || public.session_label(v_sk) || ', ohne Hinweise, kein Beleg',
          'recap', jsonb_build_object('rolle', 'recap', 'hinweise_max', 0));
      end if;
    end loop;
  end if;

  if v_e > 0 then
    v_erg := jsonb_build_object('exit_ergebnis', jsonb_build_object('richtig', v_r, 'gesamt', v_e, 'art', 'recap'));
  end if;
  return public.session_schritt('fertig', 'checkout', null, null, null, false, null,
    'Fertig für heute' || case when v_e > 0 then ': Recap ' || v_r || ' von ' || v_e || ' richtig'
                               else ' (keine Recap-Aufgabe im Pool)' end, 'fertig', v_erg);
end;
$$;

-- Generalprobe (Konzept §2.5): höchstens gp_skills_max Kern-Skills, schwächste Befunde zuerst, je eine ungesehene
-- Instanz der Rolle generalprobe auf gp_stufe (eine höher, wenn dort schon sicher), dazu gp_transfer Transferaufgaben,
-- ohne Hinweise, ohne Rückmeldung bis zum Ende. Danach „sicher / noch üben“ je Skill (gp_ergebnis); „noch üben“
-- (session_gp_waehlen) startet gp_ueben_aufgaben Übungsaufgaben zu genau diesem Skill. null = Block vorbei.
create function public.session_plan_gp(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_skills text[])
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_max    int := public.session_wert_zahl(p_session_id, 'gp_skills_max')::int;
  v_stufe  int := public.session_wert_zahl(p_session_id, 'gp_stufe')::int;
  v_tr     int := public.session_wert_zahl(p_session_id, 'gp_transfer')::int;
  v_ueb    int := public.session_wert_zahl(p_session_id, 'gp_ueben_aufgaben')::int;
  v_wahl   public.session_ereignisse;
  v_n      int;
  v_erg    jsonb;
  c        record;
  w        record;
  v_s      int;
begin
  select count(*) into v_n from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.art = 'generalprobe';

  for c in
    select x.skill_key, x.gp_gehabt from (
      select sk.skill_key, sk.o,
             exists (select 1 from public.session_schritte s where s.session_id = p_session_id and s.student_id = p_student_id
                      and s.art = 'generalprobe' and s.rolle = 'generalprobe' and s.skill_key = sk.skill_key) as gp_gehabt,
             case when l.stand_coach = 'gemeistert' then 3 when l.stand_system in ('sicher', 'kandidat') then 2
                  when l.skill_key is null then 0 else 1 end as rang,
             (select count(*) from public.lernpfad_belege b where b.student_id = p_student_id and b.skill_key = sk.skill_key) as belege
        from unnest(p_skills) with ordinality sk(skill_key, o)
        left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = sk.skill_key) x
     order by x.rang, x.belege, x.o
     limit v_max
  loop
    continue when c.gp_gehabt;
    v_s := case when coalesce(public.session_stufe_sicher(p_student_id, c.skill_key), 0) >= v_stufe
                then least(5, v_stufe + 1) else v_stufe end;
    select * into w from public.session_ziehen(p_session_id, p_student_id, c.skill_key, 'generalprobe', v_s, p_testlauf, true);
    if w.task_id is not null then
      return public.session_schritt('generalprobe', 'kern', c.skill_key, w.task_id, 'selbststaendig', false, w.difficulty,
        'Generalprobe ' || (v_n + 1) || ': ' || public.session_label(c.skill_key) || ', Stufe ' || w.difficulty
          || ', ohne Hinweise, Rückmeldung am Ende', 'generalprobe',
        jsonb_build_object('rolle', 'generalprobe', 'hinweise_max', 0, 'rueckmeldung', false));
    end if;
  end loop;

  if (select count(*) from public.session_schritte s where s.session_id = p_session_id and s.student_id = p_student_id
       and s.art = 'generalprobe' and s.rolle = 'transfer') < v_tr then
    for c in select s.skill_key from public.session_schritte s where s.session_id = p_session_id
               and s.student_id = p_student_id and s.art = 'generalprobe' and s.rolle = 'generalprobe' order by s.id loop
      continue when exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                             and s.student_id = p_student_id and s.art = 'generalprobe' and s.rolle = 'transfer'
                             and s.skill_key = c.skill_key);
      select * into w from public.session_ziehen(p_session_id, p_student_id, c.skill_key, 'transfer', null, p_testlauf, true);
      if w.task_id is not null then
        return public.session_schritt('generalprobe', 'kern', c.skill_key, w.task_id, 'selbststaendig', false, w.difficulty,
          'Generalprobe: Transfer zu ' || public.session_label(c.skill_key) || ', ohne Hinweise', 'generalprobe_transfer',
          jsonb_build_object('rolle', 'transfer', 'hinweise_max', 0, 'rueckmeldung', false));
      end if;
    end loop;
  end if;

  if not exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                  and s.student_id = p_student_id and s.art = 'generalprobe') then
    return null;
  end if;

  select * into v_wahl from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = p_student_id
     and e.typ = 'gp_ueben' order by e.id desc limit 1;
  if v_wahl.id is not null and v_wahl.payload ->> 'skill_key' is null then
    return null;
  end if;
  if v_wahl.id is not null and (select count(*) from public.session_schritte s where s.session_id = p_session_id
        and s.student_id = p_student_id and s.grund_code = 'gp_ueben' and s.zeit > v_wahl.zeit) < v_ueb then
    select * into w from public.session_ziehen(p_session_id, p_student_id, v_wahl.payload ->> 'skill_key', 'uebung',
           (public.session_niveau(p_session_id, p_student_id, v_wahl.payload ->> 'skill_key')).niveau, p_testlauf);
    if w.task_id is not null then
      return public.session_schritt('aufgabe', 'kern', v_wahl.payload ->> 'skill_key', w.task_id,
        public.session_modus(p_student_id, v_wahl.payload ->> 'skill_key'), false, w.difficulty,
        'Nach der Generalprobe: noch üben ' || public.session_label(v_wahl.payload ->> 'skill_key'), 'gp_ueben',
        jsonb_build_object('rolle', 'uebung'));
    end if;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('skill_key', x.skill_key, 'label', public.session_label(x.skill_key),
           'sicher', x.sicher) order by x.erst), '[]')
    into v_erg
    from (select s.skill_key, min(s.id) as erst,
                 bool_and(coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, s.task_id)).erfolg, false)) as sicher
            from public.session_schritte s where s.session_id = p_session_id and s.student_id = p_student_id
             and s.art = 'generalprobe' group by s.skill_key) x;
  return public.session_schritt('gp_ergebnis', 'kern', null, null, null, false, null,
    'Generalprobe fertig: ' || (select count(*) from jsonb_array_elements(v_erg) e where (e ->> 'sicher')::boolean)
      || ' von ' || jsonb_array_length(v_erg) || ' Skills sicher', 'gp_ergebnis', jsonb_build_object('gp_ergebnis', v_erg));
end;
$$;

-- Tablet: nach der Generalprobe „noch üben“ zu einem Skill (p_skill_key) oder weiter (null).
create function public.session_gp_waehlen(p_session_id uuid, p_skill_key text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets := public.session_tablet_platz(p_session_id, 'session_gp_waehlen');
begin
  if not exists (select 1 from public.session_schritte s where s.session_id = p_session_id and s.student_id = t.student_id
                  and s.art = 'generalprobe' and (p_skill_key is null or s.skill_key = p_skill_key)) then
    raise exception 'session_gp_waehlen: Skill war nicht in der Generalprobe' using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, t.student_id, 'gp_ueben', jsonb_build_object('skill_key', p_skill_key));
  return jsonb_build_object('ok', true);
end;
$$;

-- Payload fürs Tablet: aufgabe_payload (Auftrag A) für Bauform-Instanzen, sonst wie bisher lsa_question_payload.
create function public.session_payload(p_task_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v jsonb;
begin
  if to_regprocedure('public.aufgabe_payload(uuid)') is not null
     and (select to_jsonb(t) ->> 'bauform_id' from public.tasks t where t.id = p_task_id) is not null then
    execute 'select public.aufgabe_payload($1)' into v using p_task_id;
    return v;
  end if;
  return public.lsa_question_payload(p_task_id);
end;
$$;

-- Wertung: aufgabe_werten (Auftrag A, rein) für Bauform-Instanzen, sonst session_bewerten.
create function public.session_werten(p_task_id uuid, p_teil int, p_eingabe jsonb, out ergebnis text, out fehlbild_slug text,
                                       out rueckmeldung text)
returns record
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_r boolean;
begin
  if to_regprocedure('public.aufgabe_werten(uuid,jsonb)') is not null
     and (select to_jsonb(t) ->> 'bauform_id' from public.tasks t where t.id = p_task_id) is not null then
    execute 'select richtig, fehlbild_key, rueckmeldung from public.aufgabe_werten($1, $2)' into v_r, fehlbild_slug, rueckmeldung
      using p_task_id, p_eingabe;
    ergebnis := case when v_r then 'richtig' else 'falsch' end;
    return;
  end if;
  select b.ergebnis, b.fehlbild_slug into ergebnis, fehlbild_slug from public.session_bewerten(p_task_id, p_teil, p_eingabe) b;
end;
$$;


CREATE OR REPLACE FUNCTION public.session_schritt_planen(p_session_id uuid, p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  v_alt    text;
  v_alt_r  jsonb;
  r        jsonb;
  -- Reihe 1 C2
  v_reihe  public.reihen;
  v_rs     jsonb;
  v_gp     boolean := false;
  v_zm     text;
  v_rz     jsonb;
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
  if (v_letzt.art in ('aufgabe', 'exit', 'recap', 'generalprobe')
      and not coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, v_letzt.task_id)).erledigt, false))
     or v_letzt.art = 'fertig'
     or (v_letzt.art = 'termin' and not public.session_termin_gewaehlt(p_session_id, p_student_id)) then
    return public.session_schritt(v_letzt.art, v_letzt.phase, v_letzt.skill_key, v_letzt.task_id, v_letzt.modus,
      v_letzt.eingemischt, v_letzt.schwierigkeit, v_letzt.grund, v_letzt.grund_code,
      jsonb_build_object('offen', true, 'nach_beispiel', v_letzt.nach_beispiel, 'rolle', v_letzt.rolle,
                         'hinweise_max', v_letzt.hinweise_max)
      || case when v_letzt.art = 'generalprobe' then '{"rueckmeldung": false}'::jsonb else '{}'::jsonb end);
  end if;

  v_uhr := public.session_uhr_phase(p_session_id);
  v_kand := public.session_kandidat_signale(p_session_id, p_student_id);
  f := public.session_fall(p_session_id, p_student_id);
  v_label := (select th.label from public.themen th where th.thema_key = f.thema_key);

  select array_agg(z.skill_key order by z.reihenfolge),
         (array_agg(z.skill_key order by z.reihenfolge) filter (where z.offen))[1]
    into v_ziel, v_akt
    from public.session_zielliste(p_session_id, p_student_id) z;
  -- Reihe 1 C2: Mit aktiver Reihe (und ohne ausdrückliche Coach-Wahl „Lernpfad“) kommt das Ziel aus dem Reihenplan:
  -- die Skills der heutigen Plan-Session, danach die der folgenden („sitzt ein Skill, folgt der nächste“).
  v_reihe := public.reihe_aktiv(p_student_id);
  if v_reihe.id is not null and (select c.fall_coach from public.session_checkin c
                                  where c.session_id = p_session_id and c.student_id = p_student_id) is distinct from 'lernpfad' then
    v_rz := public.reihe_plan_wirksam(v_reihe.id, (s.scheduled_at at time zone 'Europe/Berlin')::date) -> 'sessions';
    v_rs := v_rz -> 0;
    v_gp := v_rs ->> 'art' = 'generalprobe';
    select array_agg(x.sk order by x.o) into v_ziel from (
      select sk, min(so * 100 + ko) as o
        from jsonb_array_elements(v_rz) with ordinality a(e, so), jsonb_array_elements_text(e -> 'skills') with ordinality b(sk, ko)
       group by sk) x;
    v_akt := (select z from unnest(v_ziel) with ordinality u(z, o)
               where not public.session_heute_sicher(p_session_id, p_student_id, z)
                 and not exists (select 1 from public.lernpfad l where l.student_id = p_student_id and l.skill_key = z
                                  and (l.stand_system in ('sicher', 'kandidat') or l.stand_coach = 'gemeistert'))
               order by o limit 1);
    v_vert := false;
  end if;
  if v_akt is null and cardinality(v_ziel) > 0 then
    v_akt := v_ziel[cardinality(v_ziel)];
    v_vert := true;
  end if;
  -- Recap in den letzten recap_min Minuten vor dem Check-out (Ablauf §3).
  if v_reihe.id is not null and v_uhr = 'kern' and now() >= s.gestartet_am + (60 - public.session_wert_zahl(p_session_id, 'phase_checkout_min')
                                                     - public.session_wert_zahl(p_session_id, 'recap_min')) * interval '1 minute' then
    v_uhr := 'checkout';
  end if;

  if v_uhr = 'checkout' or v_letzt.phase = 'checkout' then
    r := public.session_plan_checkout(p_session_id, p_student_id, s.testlauf, v_akt);
  else
    if v_uhr in ('checkin', 'warmup') then
      -- Reihe 1 C2: Voraussetzungen des HEUTIGEN Ziels (Plan-Session), ohne Reihe wie bisher die Zielliste.
      r := public.session_plan_warmup(p_session_id, p_student_id, s.testlauf, v_uhr, v_akt,
                                      coalesce(case when v_rs is not null
                                                    then array(select jsonb_array_elements_text(v_rs -> 'skills')) end,
                                               v_ziel, '{}'), v_label);
    end if;
    -- Reihe 1 C2, Konzept §9: „Zeig's mir“ übernommen → erste Aufgabe der Kernarbeit zu diesem Skill, Rolle uebung,
    -- zuletzt sichere Stufe (sonst 1), ohne Hinweis-Knopf. Nur einmal, nur vor jeder anderen Kernarbeit.
    if r ->> 'art' is null and to_regprocedure('public.zeigs_mir_offen(uuid,uuid)') is not null
       and not exists (select 1 from public.session_schritte x where x.session_id = p_session_id
                        and x.student_id = p_student_id and x.phase = 'kern'
                        and x.art in ('aufgabe', 'beispiel', 'erklaerung', 'generalprobe')) then
      execute 'select z.skill_key from public.zeigs_mir_offen($1, $2) z where z.entscheidung in (''uebernehmen'', ''übernehmen'') limit 1'
        into v_zm using p_student_id, p_session_id;
      if v_zm is not null then
        declare w record; v_st int := coalesce(public.session_stufe_sicher(p_student_id, v_zm), 1);
        begin
          select * into w from public.session_ziehen(p_session_id, p_student_id, v_zm, 'uebung', v_st, s.testlauf);
          if w.task_id is not null then
            r := public.session_schritt('aufgabe', 'kern', v_zm, w.task_id, public.session_modus(p_student_id, v_zm), false,
              coalesce(w.difficulty, v_st), 'Zeig''s mir: ' || public.session_label(v_zm) || ', Stufe ' || coalesce(w.difficulty, v_st)
                || ', ohne Hinweise (Coach hat übernommen)', 'zeigs_mir',
              jsonb_build_object('signale', coalesce(r -> 'signale', '[]'), 'rolle', 'uebung', 'hinweise_max', 0));
          end if;
        end;
      end if;
    end if;
    -- Generalprobe in der Plan-Session mit Art generalprobe (Konzept §2.5).
    if r ->> 'art' is null and v_gp then
      v_kern := public.session_plan_gp(p_session_id, p_student_id, s.testlauf,
                  coalesce(array(select jsonb_array_elements_text(v_rs -> 'skills')), '{}'));
      if v_kern is not null then
        r := v_kern || jsonb_build_object('signale', coalesce(r -> 'signale', '[]'));
      end if;
    end if;
    if r ->> 'art' is null then
      if v_akt is null then
        r := public.session_schritt('warten', 'kern', null, null, null, false, null,
          'Kein Ziel: kein Thema gewählt und keine Lücke im Lernpfad', 'kein_ziel',
          jsonb_build_object('signale', coalesce(r -> 'signale', '[]')));
      else
        v_kern := public.session_plan_kern(p_session_id, p_student_id, s.testlauf, v_akt, v_vert,
                                           coalesce(v_ziel, '{}'), v_label, f.fall, f.thema_key, v_letzt);
        -- Consensus-Check Befund 3: Pool des aktuellen Skills leer -> naechster offener Skill des Ziels.
        if v_kern ->> 'grund_code' = 'pool_leer' then
          for v_alt in select z.skill_key from public.session_zielliste(p_session_id, p_student_id) z
                        where z.offen and z.skill_key <> v_akt order by z.reihenfolge loop
            v_alt_r := public.session_plan_kern(p_session_id, p_student_id, s.testlauf, v_alt, false,
                         coalesce(v_ziel, '{}'), v_label, f.fall, f.thema_key, v_letzt);
            if v_alt_r ->> 'grund_code' <> 'pool_leer' then
              v_kern := v_alt_r || jsonb_build_object('grund', (v_alt_r ->> 'grund') || ' (keine Aufgabe mehr zu '
                                                               || public.session_label(v_akt) || ')');
              exit;
            end if;
          end loop;
        end if;
        r := v_kern || jsonb_build_object('signale', coalesce(r -> 'signale', '[]') || (v_kern -> 'signale'));
      end if;
    end if;
  end if;

  return r || jsonb_build_object('signale', coalesce(r -> 'signale', '[]') || v_kand,
                                 'fall', f.fall, 'fall_gewaehlt', f.fall_gewaehlt, 'ziel_thema_key', f.thema_key);
end;
$function$;


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
  -- Reihe 1 C2
  v_zw     uuid;
  v_tr_ab  int := public.session_wert_zahl(p_session_id, 'transfer_ab_stufe')::int;
  v_sicher int := public.session_stufe_sicher(p_student_id, p_aktuell);
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
       and (public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'uebung', niv.niveau, p_testlauf)).task_id
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
          select * into w from public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'uebung', niv.niveau, p_testlauf);
          return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(w.difficulty, niv.niveau),
            'Neuer Skill ' || v_lab || ': nur eine Aufgabe im Pool, Lösungsbeispiel entfällt',
            'neu_aufgabe_ohne_beispiel', jsonb_build_object('signale', v_sig, 'nach_beispiel', true, 'rolle', 'uebung'));
        end if;
        select * into w from public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'beispiel', niv.niveau, p_testlauf);
        if w.task_id is not null then
          return public.session_schritt('beispiel', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(w.difficulty, niv.niveau),
            'Neuer Skill ' || v_lab || ': Lösungsbeispiel ' || (v_b + 1) || ' von ' || v_l
              || case when v_seq then '' else ' (keine Erklärung vorhanden)' end,
            case when v_seq then 'neu_beispiel' else 'neu_beispiel_ohne_erklaerung' end,
            jsonb_build_object('signale', v_sig, 'rolle', 'beispiel'));
        end if;
      else
        select public.session_schwierigkeit(t.difficulty, t.afb) as difficulty, s.schwierigkeit into v_bsp
          from public.session_schritte s left join public.tasks t on t.id = s.task_id
         where s.session_id = p_session_id and s.student_id = p_student_id and s.skill_key = p_aktuell
           and s.art = 'beispiel'
         order by s.id desc limit 1;
        select * into w from public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'uebung', coalesce(v_bsp.difficulty, v_bsp.schwierigkeit, niv.niveau), p_testlauf);
        if w.task_id is not null then
          return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, 'gefuehrt', false,
            coalesce(v_bsp.difficulty, v_bsp.schwierigkeit, niv.niveau),
            'Neuer Skill ' || v_lab || ': ähnliche Aufgabe zum Lösungsbeispiel', 'neu_aehnliche_aufgabe',
            jsonb_build_object('signale', v_sig, 'nach_beispiel', true, 'rolle', 'uebung'));
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

  -- Reihe 1 C2: nach einer falschen Antwort der Zwilling (dieselbe Bauform, Rolle und Stufe), Konzept §3.1.
  if p_letzt.art = 'aufgabe' and p_letzt.phase = 'kern' and p_letzt.skill_key = p_aktuell and p_letzt.task_id is not null
     and not coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, p_letzt.task_id)).richtig, false) then
    v_zw := public.session_zwilling(p_session_id, p_student_id, p_letzt.task_id, coalesce(p_letzt.rolle, 'uebung'));
    if v_zw is not null then
      return public.session_schritt('aufgabe', 'kern', p_aktuell, v_zw, coalesce(p_letzt.modus, v_modus), false,
        coalesce(public.session_stufe(v_zw), p_letzt.schwierigkeit),
        'Nach falscher Antwort: Zwilling zu ' || v_lab || ' (gleiche Bauform und Stufe)', 'zwilling',
        jsonb_build_object('signale', v_sig, 'rolle', coalesce(p_letzt.rolle, 'uebung'), 'hinweise_max', p_letzt.hinweise_max,
                           'nach_beispiel', p_letzt.nach_beispiel));
    end if;
  end if;

  -- Reihe 1 C2: Transfer erst ab sicherer Stufe transfer_ab_stufe, einmal je Skill und Session, Hinweise nur Stufe 1.
  if coalesce(v_sicher, 0) >= v_tr_ab and not exists (select 1 from public.session_schritte s
       where s.session_id = p_session_id and s.student_id = p_student_id and s.skill_key = p_aktuell and s.rolle = 'transfer') then
    select * into w from public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'transfer', least(5, v_sicher), p_testlauf);
    if w.task_id is not null then
      return public.session_schritt('aufgabe', 'kern', p_aktuell, w.task_id, v_modus, false, w.difficulty,
        'Transfer ' || v_lab || ': sicher auf Stufe ' || v_sicher, 'transfer',
        jsonb_build_object('signale', v_sig, 'rolle', 'transfer',
                           'hinweise_max', public.session_wert_zahl(p_session_id, 'transfer_hinweisstufen')::int));
    end if;
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
      select * into w from public.session_ziehen(p_session_id, p_student_id, c.skill_key, 'uebung', (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau, p_testlauf);
      if w.task_id is not null then
        return public.session_schritt('aufgabe', 'kern', c.skill_key, w.task_id,
          public.session_modus(p_student_id, c.skill_key), true,
          (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau,
          'Eingemischt: ' || public.session_label(c.skill_key)
            || case when c.zuletzt is null then ', noch nicht in einer Session geübt'
                    else ', länger nicht geübt' end
            || case when c.voraussetzung then ' (Voraussetzung von ' || coalesce(p_ziel_label, v_lab) || ')' else '' end,
          'gemischt', jsonb_build_object('signale', v_sig, 'rolle', 'uebung',
            -- C3: Mischanteil fuer den Coach (session_schritte.details, nie am Tablet).
            'details', jsonb_build_object('mischanteil', v_misch)));
      end if;
    end loop;
  end if;

  select * into w from public.session_ziehen(p_session_id, p_student_id, p_aktuell, 'uebung', niv.niveau, p_testlauf);
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
    jsonb_build_object('signale', v_sig, 'rolle', 'uebung')
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
  -- T4: ohne vorigen Schritt immer eintragen (sonst blieb der Vergleich bei skill_key null ohne Ergebnis).
  if v_letzt.id is null or not (v ->> 'art' in ('warten', 'erklaerung', 'gp_ergebnis') and v_letzt.art = v ->> 'art'
          and v_letzt.grund_code = v ->> 'grund_code'
          and v_letzt.skill_key is not distinct from v ->> 'skill_key') then
    insert into public.session_schritte (session_id, student_id, art, phase, skill_key, task_id, modus, eingemischt,
           nach_beispiel, schwierigkeit, grund, grund_code, details, rolle, hinweise_max)
    values (p_session_id, t.student_id, v ->> 'art', v ->> 'phase', v ->> 'skill_key', (v ->> 'task_id')::uuid,
            v ->> 'modus', coalesce((v ->> 'eingemischt')::boolean, false),
            coalesce((v ->> 'nach_beispiel')::boolean, false), (v ->> 'schwierigkeit')::int,
            v ->> 'grund', v ->> 'grund_code',
            -- C3: Zahlen zum Grund (nur Coach; session_schritt_oeffentlich gibt sie nicht weiter).
            coalesce(v -> 'details', '{}'::jsonb), v ->> 'rolle', (v ->> 'hinweise_max')::smallint);
    -- Reihe 1 C2 (Konzept §9): jede gezeigte Aufgabe und jedes Lösungsbeispiel an Auftrag A melden (späte Bindung).
    if v ->> 'art' in ('aufgabe', 'beispiel', 'recap', 'generalprobe') and v ->> 'task_id' is not null
       and to_regprocedure('public.aufgabe_gezeigt(uuid,uuid,uuid)') is not null then
      execute 'select public.aufgabe_gezeigt($1, $2, $3)' using t.student_id, (v ->> 'task_id')::uuid, p_session_id;
    end if;
  end if;

  if v ->> 'art' in ('aufgabe', 'exit', 'recap', 'generalprobe') then
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


CREATE OR REPLACE FUNCTION public.session_schritt_oeffentlich(p_schritt jsonb, p_coach boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select jsonb_build_object(
           'art', p_schritt ->> 'art', 'phase', p_schritt ->> 'phase', 'skill_key', p_schritt ->> 'skill_key',
           'skill_label', case when p_schritt ->> 'skill_key' is not null
                               then public.session_label(p_schritt ->> 'skill_key') end,
           'task_id', p_schritt ->> 'task_id', 'modus', p_schritt ->> 'modus',
           'eingemischt', coalesce((p_schritt ->> 'eingemischt')::boolean, false),
           'grund_code', p_schritt ->> 'grund_code',
           'hinweise_erlaubt', p_schritt ->> 'art' = 'aufgabe' and p_schritt ->> 'phase' = 'kern'
                               and coalesce((p_schritt ->> 'hinweise_max')::int, 1) > 0,
           -- Reihe 1 C2: Rolle, höchste Hinweisstufe, Rückmeldung (Generalprobe erst am Ende).
           'rolle', p_schritt ->> 'rolle', 'hinweise_max', (p_schritt ->> 'hinweise_max')::int,
           'rueckmeldung', coalesce((p_schritt ->> 'rueckmeldung')::boolean, p_schritt ->> 'art' <> 'generalprobe'),
           'aufgabe', case when p_schritt ->> 'art' in ('aufgabe', 'exit', 'beispiel', 'recap', 'generalprobe')
                           then public.session_payload((p_schritt ->> 'task_id')::uuid) end)
         || case when p_schritt ->> 'art' = 'gp_ergebnis' then jsonb_build_object('gp_ergebnis', p_schritt -> 'gp_ergebnis')
            else '{}'::jsonb end
         || case when p_schritt ->> 'art' = 'beispiel' then jsonb_build_object('loesungsweg',
              (select ts.solution from public.task_solutions ts where ts.task_id = (p_schritt ->> 'task_id')::uuid))
            else '{}'::jsonb end
         -- Grund und Stufe sind Coach-Wissen (Quoten, Fehlversuche, Exit-Ergebnis): nie ans Tablet
         -- (CLAUDE.md §6, Consensus-Check Befund 1).
         || case when p_coach then jsonb_build_object('grund', p_schritt ->> 'grund',
                                                      'schwierigkeit', (p_schritt ->> 'schwierigkeit')::int)
            else '{}'::jsonb end
         || case when p_schritt ? 'erklaerung_weg' then jsonb_build_object('erklaerung_weg', p_schritt ->> 'erklaerung_weg')
            else '{}'::jsonb end
$function$;


CREATE OR REPLACE FUNCTION public.antwort_abgeben(p_session_id uuid, p_task_id uuid, p_teil integer, p_eingabe jsonb, p_dauer_ms integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t     public.session_tablets := public.session_tablet_platz(p_session_id, 'antwort_abgeben');
  a     public.session_ausgegeben;
  b     record;
  v_nr  int;
  v_hin int;
  v_skill text;
begin
  select * into a from public.session_ausgegeben
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
   order by zeit desc limit 1;
  if not found then
    raise exception 'antwort_abgeben: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  if p_eingabe is null or jsonb_typeof(p_eingabe) = 'null' or btrim(p_eingabe #>> '{}') = '' then
    raise exception 'antwort_abgeben: leere Eingabe' using errcode = '22023';
  end if;
  -- A2b (Entscheidung 29): ein Versuch je Ausgabe und Teil, unabhaengig vom Ergebnis.
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id and r.student_id = t.student_id
              and r.task_id = p_task_id and r.teil is not distinct from p_teil and r.zeit >= a.zeit) then
    raise exception 'antwort_abgeben: zu dieser Aufgabe liegt schon eine Antwort vor' using errcode = 'P0001',
      hint = 'schon_beantwortet';
  end if;

  select * into b from public.session_werten(p_task_id, p_teil, p_eingabe);

  select count(*) + 1 into v_nr from public.session_antworten
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
     and teil is not distinct from p_teil;
  select coalesce(max((e.payload ->> 'stufe')::int), 0) into v_hin from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
     and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'geliefert')::boolean;

  insert into public.session_antworten (session_id, student_id, task_id, teil, versuch_nr, eingabe, ergebnis,
         fehlbild_slug, hinweisstufe_max, dauer_ms, phase, eingemischt, geraet_id, angemeldet_als)
  values (p_session_id, t.student_id, p_task_id, p_teil, v_nr, p_eingabe, b.ergebnis, b.fehlbild_slug, v_hin,
          p_dauer_ms, public.session_phase(p_session_id, t.student_id), a.eingemischt, t.geraet_id, auth.uid());

  -- A2 (L): jede Antwort aus Warm-up, Kernarbeit und Check-out bucht einen Lernpfad-Beleg mit
  -- Ergebnis und Hinweis-Nutzung. Testlaeufe buchen nie Belege (Entscheidung 27).
  select tk.skill_key into v_skill from public.tasks tk where tk.id = p_task_id;
  if v_skill is not null
     and not coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false)
     and public.session_phase(p_session_id, t.student_id) in ('warmup', 'kern', 'checkout')
     -- Reihe 1 C2: Recap zählt nicht als Beleg (Ablauf §3).
     and not exists (select 1 from public.session_schritte x where x.session_id = p_session_id
                      and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'recap') then
    perform public.lernpfad_beleg_core(t.student_id, v_skill, p_session_id, b.ergebnis, v_hin > 0);
  end if;

  -- A2b (Entscheidung 29): Exit-Aufgaben nur neutral. Reihe 1 C2: Generalprobe ebenso, Rückmeldung erst am Ende.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art in ('exit', 'generalprobe')) then
    return jsonb_build_object('gespeichert', true, 'versuch_nr', v_nr);
  end if;

  return jsonb_build_object(
    'gespeichert', true,
    'ergebnis', b.ergebnis,
    'versuch_nr', v_nr,
    -- Reihe 1 C2: Rückmeldesatz aus aufgabe_werten (Steckbrief) vor dem Katalog-Klartext.
    'fehlbild_klartext', coalesce(b.rueckmeldung, (select fl.klartext from public.fehlbild_labels fl
                           where fl.slug = b.fehlbild_slug
                             and (fl.freigegeben_am is not null
                                  -- T3: im Testlauf jeder Klartext, wenn die Aufgabe die Pruefung besteht.
                                  or (coalesce((select cs.testlauf from public.coaching_sessions cs
                                                 where cs.id = p_session_id), false)
                                      and nullif(btrim(fl.klartext), '') is not null
                                      and public.testlauf_inhalt_sichtbar(p_task_id))))));
end;
$function$;


CREATE OR REPLACE FUNCTION public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'hinweis_abrufen');
  v_text text;
  -- T3: Testlauf nur aus der Session, nach der Platz-Pruefung oben.
  v_tl   boolean := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);
begin
  if not exists (select 1 from public.session_ausgegeben where session_id = p_session_id
                  and student_id = t.student_id and task_id = p_task_id) then
    raise exception 'hinweis_abrufen: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  -- A2b (Entscheidung 32): nur vor dem Abgeben; Hinweise haengen an der Aufgabe, also zaehlt jede Antwort
  -- auf irgendeinen Teil seit der juengsten Ausgabe.
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id and r.student_id = t.student_id
              and r.task_id = p_task_id
              and r.zeit >= (select max(x.zeit) from public.session_ausgegeben x where x.session_id = p_session_id
                              and x.student_id = t.student_id and x.task_id = p_task_id)) then
    raise exception 'hinweis_abrufen: zu dieser Aufgabe liegt schon eine Antwort vor' using errcode = 'P0001',
      hint = 'hinweis_nach_antwort';
  end if;
  -- A2 (K): Exit-Aufgaben im Check-out ohne Hinweise.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'exit') then
    raise exception 'hinweis_abrufen: Exit-Aufgaben ohne Hinweise' using errcode = '22023', hint = 'exit_ohne_hinweis';
  end if;
  -- A2b (Entscheidung 32): keine Hinweise im Warm-up.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.phase = 'warmup') then
    raise exception 'hinweis_abrufen: im Warm-up keine Hinweise' using errcode = '22023', hint = 'warmup_ohne_hinweis';
  end if;
  -- Reihe 1 C2: Recap, Generalprobe, „Zeig's mir“ ohne Hinweise, Transfer nur bis transfer_hinweisstufen.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id and x.student_id = t.student_id
              and x.task_id = p_task_id and (x.art in ('recap', 'generalprobe') or p_stufe > x.hinweise_max)) then
    raise exception 'hinweis_abrufen: für diese Aufgabe kein Hinweis auf Stufe %', p_stufe using errcode = '22023',
      hint = 'hinweis_gesperrt';
  end if;
  if p_stufe is null or p_stufe < 1 or p_stufe > public.session_wert_zahl(p_session_id, 'hinweisstufen') then
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023',
      hint = 'stufe_gesperrt';
  end if;
  -- Prinzip der minimalen Hilfe (Entscheidung 11): Stufe n erst nach Stufe n-1.
  if p_stufe > 1 and not exists (select 1 from public.session_ereignisse e
       where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
         and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'stufe')::int = p_stufe - 1) then
    raise exception 'hinweis_abrufen: erst Stufe %', p_stufe - 1 using errcode = '22023', hint = 'hinweis_reihenfolge';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and h ->> 'level' = p_stufe::text
     and (h ->> 'status' = 'geprueft'
          -- T3: im Testlauf jeder Hinweis mit Text, wenn die Aufgabe die Pruefung des Lena-Boards besteht.
          or (v_tl and nullif(btrim(h ->> 'text'), '') is not null and public.testlauf_inhalt_sichtbar(p_task_id)))
   order by coalesce(h ->> 'status' = 'geprueft', false) desc, h ->> 'text'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  -- A2c: weitere = es gibt eine naechste Stufe (hinweisstufen sieht das Tablet sonst nicht).
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null,
                            'weitere', p_stufe < public.session_wert_zahl(p_session_id, 'hinweisstufen'));
end;
$function$;

revoke all on function public.session_plan_gp(uuid, uuid, boolean, text[]), public.session_payload(uuid),
  public.session_plan_warmup_a2(uuid, uuid, boolean, text, text, text[], text),
  public.session_plan_checkout_a2(uuid, uuid, boolean, text),
  public.session_werten(uuid, int, jsonb) from public, anon, authenticated;
revoke all on function public.session_gp_waehlen(uuid, text) from public, anon;
grant execute on function public.session_gp_waehlen(uuid, text) to authenticated;
comment on function public.session_gp_waehlen(uuid, text) is
  'Reihe 1 C2: Tablet wählt nach der Generalprobe „noch üben“ zu einem Skill (oder null = weiter). Nur der eigene Platz.';
