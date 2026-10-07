-- A2d (aus C2): Das Entscheidungssignal "eine Stufe tiefer?" bringt dem Coach Zahlen mit.
-- Payload zusaetzlich: voraussetzung_skill_key, voraussetzung_label, warmup_aufgaben (Warm-up-Aufgaben auf
-- dieser Voraussetzung), warmup_richtig (davon richtig, bei MULTI_PART alle Teile). Die bisherigen Felder bleiben.
-- Das Signal geht nur an den Coach (session_ereignisse -> session_signale_intern.details -> raum_signale,
-- coach_raum_live); Datenvertrag Abschnitt 8 (Tablet) bleibt unveraendert.
-- Grundlage: Prod-Definition (pg_get_functiondef, 07.10.2026) aus 20261008122231_a2_warmup_kern.
-- Signatur und Rechte bleiben (create or replace).

CREATE OR REPLACE FUNCTION public.session_plan_warmup(p_session_id uuid, p_student_id uuid, p_testlauf boolean, p_uhr text, p_aktuell text, p_ziel_skills text[], p_ziel_label text)
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
$function$;
