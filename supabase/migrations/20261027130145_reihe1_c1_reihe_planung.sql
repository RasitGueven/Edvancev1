-- Reihe 1 · C1 Reihenplanung, Teil 2: Planung, Lesen, Coach-Änderungen, Neu planen nach der Session
-- (Bauauftrag C1.2–C1.4, Konzept §2.1–2.3 und §9). Setzt 20261027130023_reihe1_c1_reihe_schema voraus.
--
-- Planung (reihe_plan_rechnen, rein lesend):
--   1. Skills = Kern-Skills der Klassenarbeitsthemen (skill_thema) plus alles, was sie laut skill_kante brauchen,
--      soweit es Kernideen im Katalog hat (zieht gleichung_quadr_formel über fkt_quadr_nullstellen hinein).
--   2. Je Kernidee ein Zeitbedarf aus den Stellschrauben: neu 12, schon gesehen 6, sicher 0 (nicht geplant).
--      Voraussetzungen ohne Kernidee kosten keine Kernarbeitszeit (Warm-up, C2).
--   3. Reihenfolge = Katalog (reihe_kernideen.nr). Mit Datum: Termine bis zum Tag vor der Arbeit, die letzte
--      ist die Generalprobe, davor der eigene Transferblock. Verteilt wird gleichmäßig: das Ende jeder Kernidee
--      entscheidet die Session, der Rest wandert nach hinten; keine Session über Kapazität × (1 + Spielraum).
--   4. Passt es nicht: erst „kann entfallen“ (skill_kann_entfallen von A, sonst reihe_kann_entfallen), dann der
--      Transferblock, dann gesehen 4 statt 6 Minuten, dann von hinten. Alles Entfallene steht in plan.warnung.
--   5. Ohne Datum: rollierend reihe_rollierend_sessions Sessions, ohne Generalprobe, ohne Transferblock.
--   Termine: kind_termine (planned) und danach wöchentlich am Wochentag der Stammplätze bzw. des Starts;
--   Ferien und Feiertage über slots_anlass, wie im Slot-Kalender.
-- Systemvorschlag (reihe_plan_versionen) und Coach-Änderungen (reihe_coach_aenderungen) bleiben getrennt;
-- reihe_plan_wirksam legt gültige Änderungen über den jüngsten Vorschlag.
-- Rollback: supabase/rollback/20261027130145_reihe1_c1_reihe_planung.sql.

create function public.reihe_wert(p_schluessel text)
returns numeric
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.session_wert_zahl(null, p_schluessel)
$$;

create function public.reihe_heute()
returns date
language sql
stable
set search_path = public, pg_temp
as $$
  select (now() at time zone 'Europe/Berlin')::date
$$;

-- „Kann entfallen“: Funktion von Auftrag A, solange sie fehlt die Rückfall-Liste (späte Bindung, Konzept §9).
create function public.reihe_kann_entfallen_pruefen(p_skill_key text)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v boolean;
begin
  if to_regprocedure('public.skill_kann_entfallen(text)') is not null then
    execute 'select public.skill_kann_entfallen($1)' into v using p_skill_key;
    return coalesce(v, false);
  end if;
  return exists (select 1 from public.reihe_kann_entfallen k where k.skill_key = p_skill_key);
end;
$$;

-- Kern-Skills der Reihe: Themen-Skills plus Graph-Abschluss, beschränkt auf Skills mit Kernideen.
create function public.reihe_skills(p_thema_keys text[])
returns table (skill_key text, nr int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with recursive h(sk) as (
    select st.skill_key from public.skill_thema st where st.thema_key = any (p_thema_keys)
    union
    select k.voraussetzt_skill_key from public.skill_kante k join h on k.skill_key = h.sk
  )
  select k.skill_key, min(k.nr) from public.reihe_kernideen k where k.skill_key in (select sk from h)
   group by k.skill_key order by 2
$$;

-- Termine der Reihe ab p_von (einschliesslich) vor p_bis (ausschliesslich), höchstens p_max.
create function public.reihe_termine(p_student_id uuid, p_start date, p_takt int, p_von date, p_bis date, p_max int)
returns setof date
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_tage   int[];
  v_letzt  date;
  v_n      int := 0;
  d        date;
begin
  for d in
    select distinct kt.datum from public.kind_termine kt
     where kt.student_id = p_student_id and kt.zustand = 'planned' and kt.datum >= p_von
       and (p_bis is null or kt.datum < p_bis)
     order by 1
  loop
    exit when v_n >= p_max;
    v_n := v_n + 1;
    v_letzt := d;
    return next d;
  end loop;

  select array_agg(x.wt order by x.wt) into v_tage from (
    select distinct s.wochentag::int as wt from public.stammplaetze s
     where s.student_id = p_student_id and s.beendet_am is null
       and coalesce(s.gueltig_bis, 'infinity'::date) >= p_von) x;
  v_tage := (coalesce(v_tage, array[extract(isodow from p_start)::int]))[1:greatest(p_takt, 1)];

  d := greatest(p_von, coalesce(v_letzt + 1, p_von));
  while v_n < p_max and (p_bis is null or d < p_bis) and d < p_von + 730 loop
    if extract(isodow from d)::int = any (v_tage) and public.slots_anlass(d) is null then
      v_n := v_n + 1;
      return next d;
    end if;
    d := d + 1;
  end loop;
end;
$$;

-- Verteilt Kosten auf p_n Sessions: Index 1..p_n je Posten oder null, wenn es nicht passt.
create function public.reihe_verteilen(p_kosten numeric[], p_n int, p_cap numeric)
returns int[]
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_t    numeric := coalesce((select sum(x) from unnest(p_kosten) x), 0);
  v_l    numeric;
  v_cum  numeric := 0;
  v_idx  int[] := '{}';
  v_sum  numeric[];
  v_k    int := 1;
  v_s    numeric := 0;
  i      int;
begin
  if coalesce(cardinality(p_kosten), 0) = 0 then return '{}'; end if;
  if p_n < 1 or v_t > p_n * p_cap then return null; end if;
  -- Zweitprüfung 1: L mindestens der teuerste Posten, sonst blieben vorne Sessions leer.
  v_l := greatest(v_t / p_n, (select max(x) from unnest(p_kosten) x));
  v_sum := array_fill(0::numeric, array[p_n]);
  for i in 1 .. cardinality(p_kosten) loop
    v_cum := v_cum + p_kosten[i];
    v_idx := v_idx || least(p_n, floor((v_cum - 0.000001) / v_l)::int + 1);
    v_sum[v_idx[i]] := v_sum[v_idx[i]] + p_kosten[i];
  end loop;
  if (select max(x) from unnest(v_sum) x) <= p_cap then return v_idx; end if;
  -- Rückfall: vorwärts auffüllen.
  v_idx := '{}';
  for i in 1 .. cardinality(p_kosten) loop
    if p_kosten[i] > p_cap then return null; end if;
    if v_s + p_kosten[i] > p_cap then v_k := v_k + 1; v_s := 0; end if;
    if v_k > p_n then return null; end if;
    v_idx := v_idx || v_k;
    v_s := v_s + p_kosten[i];
  end loop;
  return v_idx;
end;
$$;

-- Stand einer Kernidee für die Planung: sicher | gesehen | neu.
create function public.reihe_kernidee_stand(p_reihe_id uuid, p_student_id uuid, p_skill_key text, p_kernidee text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when l.stand_system in ('sicher', 'kandidat') or l.stand_coach = 'gemeistert' then 'sicher'
    when l.skill_key is null and exists (select 1 from public.lernpfad_lsa_urteile(p_student_id) u
                                          where u.skill_key = p_skill_key and u.zustand = 'traegt') then 'sicher'
    when exists (select 1 from public.lernpfad_belege b where b.student_id = p_student_id and b.skill_key = p_skill_key)
      or exists (select 1 from public.reihe_ist i join public.reihen r on r.id = i.reihe_id
                  cross join lateral jsonb_array_elements(i.kernideen) e
                  where r.student_id = p_student_id and e ->> 'skill_key' = p_skill_key and e ->> 'kernidee_key' = p_kernidee)
      then 'gesehen'
    else 'neu'
  end
    from (select 1) d
    left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = p_skill_key
$$;

-- Systemvorschlag einer Reihe ab p_heute (rein lesend).
create function public.reihe_plan_rechnen(p_reihe_id uuid, p_heute date default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  r          public.reihen;
  v_heute    date := coalesce(p_heute, public.reihe_heute());
  v_cap      numeric := public.reihe_wert('reihe_kapazitaet_min') * (1 + public.reihe_wert('reihe_spielraum'));
  v_neu      numeric := public.reihe_wert('reihe_min_neu');
  v_ges      numeric := public.reihe_wert('reihe_min_gesehen');
  v_knapp    numeric := public.reihe_wert('reihe_min_gesehen_knapp');
  v_trans    numeric := public.reihe_wert('reihe_transfer_min');
  v_roll     int := public.reihe_wert('reihe_rollierend_sessions')::int;
  v_bisher   int;
  v_erledigt date[];
  v_termine  date[];
  v_items    jsonb := '[]';
  v_weg      jsonb := '[]';
  v_kosten   numeric[];
  v_idx      int[];
  v_n        int;
  v_sess     jsonb := '[]';
  v_teil     jsonb;
  v_skills   jsonb;
  v_schritt  int := 0;
  k          record;
  i          int;
  v_ka       boolean;
  v_knapp_an boolean := false;
begin
  select * into r from public.reihen where id = p_reihe_id;
  if not found then
    raise exception 'reihe_plan_rechnen: Reihe nicht gefunden' using errcode = 'P0002';
  end if;
  v_ka := r.ka_datum is not null;

  select coalesce(array_agg(distinct (cs.scheduled_at at time zone 'Europe/Berlin')::date), '{}')
    into v_erledigt
    from public.coaching_sessions cs join public.session_students ss on ss.session_id = cs.id
   where ss.student_id = r.student_id and ss.attendance = 'present' and cs.status = 'done'
     and not coalesce(cs.testlauf, false) and (cs.scheduled_at at time zone 'Europe/Berlin')::date >= r.start;
  v_bisher := cardinality(v_erledigt);

  select coalesce(array_agg(t order by t), '{}') into v_termine
    from public.reihe_termine(r.student_id, r.start, r.takt, greatest(v_heute, r.start), r.ka_datum,
                              case when v_ka then 1000 else v_roll + cardinality(v_erledigt) end) t
   where not (t = any (v_erledigt));
  if not v_ka then v_termine := v_termine[1:v_roll]; end if;
  v_n := cardinality(v_termine);

  for k in
    select ki.skill_key, ki.kernidee_key, ki.nr, ki.titel,
           public.reihe_kernidee_stand(r.id, r.student_id, ki.skill_key, ki.kernidee_key) as stand
      from public.reihe_kernideen ki
     where ki.skill_key in (select s.skill_key from public.reihe_skills(r.thema_keys) s)
     order by ki.nr
  loop
    continue when k.stand = 'sicher';
    v_items := v_items || jsonb_build_object('art', 'kernidee', 'skill_key', k.skill_key, 'kernidee_key', k.kernidee_key,
      'stand', k.stand, 'minuten', case k.stand when 'neu' then v_neu else v_ges end);
  end loop;

  if v_ka then
    if v_trans > 0 then
      v_items := v_items || jsonb_build_object('art', 'transfer', 'minuten', v_trans);
    end if;
    -- Kürzen nach Regel 5, bis es in die Sessions vor der Generalprobe passt.
    loop
      select coalesce(array_agg((e ->> 'minuten')::numeric order by o), '{}') into v_kosten
        from jsonb_array_elements(v_items) with ordinality x(e, o);
      v_idx := public.reihe_verteilen(v_kosten, v_n - 1, v_cap);
      exit when v_idx is not null or jsonb_array_length(v_items) = 0;
      v_schritt := v_schritt + 1;
      if v_schritt = 1 then
        select coalesce(jsonb_agg(e order by o) filter (where e ->> 'art' = 'kernidee'
                 and public.reihe_kann_entfallen_pruefen(e ->> 'skill_key')), '[]'),
               coalesce(jsonb_agg(e order by o) filter (where not (e ->> 'art' = 'kernidee'
                 and public.reihe_kann_entfallen_pruefen(e ->> 'skill_key'))), '[]')
          into v_teil, v_items
          from jsonb_array_elements(v_items) with ordinality x(e, o);
        v_weg := v_weg || v_teil;
      elsif v_schritt = 2 then
        select coalesce(jsonb_agg(e order by o) filter (where e ->> 'art' = 'transfer'), '[]'),
               coalesce(jsonb_agg(e order by o) filter (where e ->> 'art' <> 'transfer'), '[]')
          into v_teil, v_items
          from jsonb_array_elements(v_items) with ordinality x(e, o);
        v_weg := v_weg || v_teil;
      elsif v_schritt = 3 then
        v_knapp_an := true;
        select coalesce(jsonb_agg(case when e ->> 'stand' = 'gesehen'
                                       then e || jsonb_build_object('minuten', v_knapp) else e end order by o), '[]')
          into v_items
          from jsonb_array_elements(v_items) with ordinality x(e, o);
      else
        v_weg := v_weg || jsonb_build_array(v_items -> (jsonb_array_length(v_items) - 1));
        v_items := v_items - (jsonb_array_length(v_items) - 1);
      end if;
    end loop;
    v_idx := coalesce(v_idx, '{}');
  else
    -- Rollierend: vorwärts auffüllen, was nicht mehr hineinpasst, kommt bei der nächsten Planung.
    v_idx := '{}';
    declare
      v_k int := 1;
      v_s numeric := 0;
      c   numeric;
    begin
      for i in 0 .. jsonb_array_length(v_items) - 1 loop
        c := (v_items -> i ->> 'minuten')::numeric;
        if v_s + c > v_cap then v_k := v_k + 1; v_s := 0; end if;
        exit when v_k > v_n;
        v_idx := v_idx || v_k;
        v_s := v_s + c;
      end loop;
    end;
  end if;

  for i in 1 .. (case when v_ka then v_n - 1 else v_n end) loop
    select coalesce(jsonb_agg(v_items -> (o - 1) order by o) filter (where v_idx[o] = i), '[]') into v_teil
      from generate_series(1, coalesce(cardinality(v_idx), 0)) o;
    select coalesce(jsonb_agg(distinct e ->> 'skill_key'), '[]') into v_skills
      from jsonb_array_elements(v_teil) e where e ->> 'art' = 'kernidee';
    v_sess := v_sess || jsonb_build_object(
      'nr', v_bisher + i, 'datum', v_termine[i], 'art', 'normal',
      'kernideen', coalesce((select jsonb_agg(e - 'art' order by o) from jsonb_array_elements(v_teil) with ordinality x(e, o)
                              where e ->> 'art' = 'kernidee'), '[]'),
      'skills', (select coalesce(jsonb_agg(s order by (select min(ki.nr) from public.reihe_kernideen ki where ki.skill_key = s)), '[]')
                   from jsonb_array_elements_text(v_skills) s),
      'transfer', exists (select 1 from jsonb_array_elements(v_teil) e where e ->> 'art' = 'transfer'),
      'minuten', coalesce((select sum((e ->> 'minuten')::numeric) from jsonb_array_elements(v_teil) e), 0));
  end loop;
  if v_ka and v_n >= 1 then
    v_sess := v_sess || jsonb_build_object(
      'nr', v_bisher + v_n, 'datum', v_termine[v_n], 'art', 'generalprobe', 'kernideen', '[]'::jsonb,
      'skills', (select coalesce(jsonb_agg(s.skill_key order by s.nr), '[]') from public.reihe_skills(r.thema_keys) s
                  where not (public.reihe_kann_entfallen_pruefen(s.skill_key)
                             and exists (select 1 from jsonb_array_elements(v_weg) w where w ->> 'skill_key' = s.skill_key))),
      'transfer', true, 'minuten', 0);
  end if;

  return jsonb_build_object(
    'modus', case when v_ka then 'klassenarbeit' else 'rollierend' end,
    'heute', v_heute, 'ka_datum', r.ka_datum, 'sessions_bisher', v_bisher,
    'sessions', v_sess,
    'warnung', jsonb_build_object('passt', jsonb_array_length(v_weg) = 0 and (not v_ka or v_n >= 1),
                                  'sessions', v_n, 'entfallen', v_weg, 'gesehen_knapp', v_knapp_an),
    'stellschrauben', jsonb_build_object('kapazitaet', public.reihe_wert('reihe_kapazitaet_min'),
      'spielraum', public.reihe_wert('reihe_spielraum'), 'neu', v_neu, 'gesehen', v_ges, 'gesehen_knapp', v_knapp,
      'transfer', v_trans, 'rollierend', v_roll));
end;
$$;

-- Neue Version des Systemvorschlags (nur anhängen).
create function public.reihe_planen(p_reihe_id uuid, p_anlass text, p_grund text, p_session_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  perform pg_advisory_xact_lock(hashtext('reihe_planen:' || p_reihe_id::text));
  insert into public.reihe_plan_versionen (reihe_id, version, anlass, grund, session_id, plan, erstellt_von)
  values (p_reihe_id,
          coalesce((select max(v.version) from public.reihe_plan_versionen v where v.reihe_id = p_reihe_id), 0) + 1,
          p_anlass, p_grund, p_session_id, public.reihe_plan_rechnen(p_reihe_id), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- Wirksamer Plan: jüngster Systemvorschlag plus gültige Coach-Änderungen. Gültig ist ein Verschieben, solange der
-- Zieltermin heute oder später als normale Session im Plan steht und der Skill noch Kernideen im Plan hat.
create function public.reihe_plan_wirksam(p_reihe_id uuid, p_heute date default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := coalesce(p_heute, public.reihe_heute());
  v       public.reihe_plan_versionen;
  v_plan  jsonb;
  v_sess  jsonb;
  v_ae    jsonb := '[]';
  a       record;
  v_ziel  int;
  v_mit   jsonb;
  v_ok    boolean;
begin
  select * into v from public.reihe_plan_versionen x where x.reihe_id = p_reihe_id order by x.version desc limit 1;
  if not found then return null; end if;
  v_plan := v.plan;
  v_sess := coalesce((select jsonb_agg(s || jsonb_build_object('kernideen',
              coalesce((select jsonb_agg(e || '{"coach": false}'::jsonb) from jsonb_array_elements(s -> 'kernideen') e), '[]'))
              order by o)
             from jsonb_array_elements(v_plan -> 'sessions') with ordinality x(s, o)
            where (s ->> 'datum')::date >= v_heute), '[]');

  for a in select * from public.reihe_coach_aenderungen c where c.reihe_id = p_reihe_id order by c.am, c.id loop
    v_ok := false;
    if a.aktion = 'verschieben' and a.ziel_datum >= v_heute then
      select o - 1 into v_ziel from jsonb_array_elements(v_sess) with ordinality x(s, o)
       where (s ->> 'datum')::date = a.ziel_datum and s ->> 'art' = 'normal';
      select coalesce(jsonb_agg(e || '{"coach": true}'::jsonb order by (e ->> 'kernidee_key')), '[]') into v_mit
        from jsonb_array_elements(v_sess) s, jsonb_array_elements(s -> 'kernideen') e
       where e ->> 'skill_key' = a.skill_key;
      if v_ziel is not null and jsonb_array_length(v_mit) > 0 then
        v_ok := true;
        select jsonb_agg(case when o - 1 = v_ziel
                 then s || jsonb_build_object('kernideen', coalesce((select jsonb_agg(e) from jsonb_array_elements(s -> 'kernideen') e
                                                                     where e ->> 'skill_key' <> a.skill_key), '[]') || v_mit)
                 else s || jsonb_build_object('kernideen', coalesce((select jsonb_agg(e) from jsonb_array_elements(s -> 'kernideen') e
                                                                     where e ->> 'skill_key' <> a.skill_key), '[]')) end
                 order by o)
          into v_sess from jsonb_array_elements(v_sess) with ordinality x(s, o);
      end if;
    elsif a.aktion = 'bestaetigen' then
      v_ok := a.version_id = v.id;
    end if;
    v_ae := v_ae || jsonb_build_object('id', a.id, 'aktion', a.aktion, 'skill_key', a.skill_key, 'ziel_datum', a.ziel_datum,
                                       'grund', a.grund, 'am', a.am, 'gueltig', v_ok);
  end loop;

  -- Skills und Minuten je Session nach den Änderungen neu ablesen (Generalprobe behält ihre Skills).
  select coalesce(jsonb_agg(case when s ->> 'art' = 'generalprobe' then s else s || jsonb_build_object(
           'skills', coalesce((select jsonb_agg(sk order by (select min(ki.nr) from public.reihe_kernideen ki where ki.skill_key = sk))
                                 from (select distinct e ->> 'skill_key' as sk from jsonb_array_elements(s -> 'kernideen') e) d), '[]'),
           'minuten', coalesce((select sum((e ->> 'minuten')::numeric) from jsonb_array_elements(s -> 'kernideen') e), 0)
                      + case when (s ->> 'transfer')::boolean then (v_plan #>> '{stellschrauben,transfer}')::numeric else 0 end)
           end order by o), '[]')
    into v_sess from jsonb_array_elements(v_sess) with ordinality x(s, o);

  return v_plan || jsonb_build_object('sessions', v_sess, 'version', v.version, 'version_id', v.id,
    'erstellt_am', v.erstellt_am, 'anlass', v.anlass, 'grund', v.grund, 'aenderungen', v_ae,
    'bestaetigt', exists (select 1 from jsonb_array_elements(v_ae) e where e ->> 'aktion' = 'bestaetigen' and (e ->> 'gueltig')::boolean));
end;
$$;

create function public.reihe_aktiv(p_student_id uuid, p_fach text default 'mathematik')
returns public.reihen
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select * from public.reihen r where r.student_id = p_student_id and r.fach = p_fach and r.status = 'aktiv'
$$;

-- Konzept §9: Lesefunktion für Auftrag D. Kind selbst, Coach mit laufendem Vertrag, Admin.
create function public.reihenplan_kind(p_kind uuid)
returns table (session_nr int, datum date, kernideen text[], skills text[], art text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  r public.reihen;
begin
  if not (public.lernpfad_darf_lesen(p_kind) or public.get_my_student_id() is not distinct from p_kind and p_kind is not null) then
    raise exception 'reihenplan_kind: kein Zugriff' using errcode = '42501';
  end if;
  r := public.reihe_aktiv(p_kind);
  if r.id is null then return; end if;
  return query
    select (s ->> 'nr')::int, (s ->> 'datum')::date,
           coalesce(array(select (e ->> 'skill_key') || '.' || (e ->> 'kernidee_key') from jsonb_array_elements(s -> 'kernideen') e), '{}'),
           coalesce(array(select jsonb_array_elements_text(s -> 'skills')), '{}'),
           s ->> 'art'
      from jsonb_array_elements(public.reihe_plan_wirksam(r.id) -> 'sessions') s
     order by 1;
end;
$$;

-- Coach-Sicht: Karte „Reihe“ (Vorher-Briefing, Kind-Detail, Danach). null ohne aktive Reihe.
create function public.reihe_coach_lesen(p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  r      public.reihen;
  v_w    jsonb;
  v_vor  public.reihe_plan_versionen;
begin
  if not public.lernpfad_darf_lesen(p_student_id) then
    raise exception 'reihe_coach_lesen: kein Zugriff' using errcode = '42501';
  end if;
  r := public.reihe_aktiv(p_student_id);
  if r.id is null then return null; end if;
  v_w := public.reihe_plan_wirksam(r.id);
  select * into v_vor from public.reihe_plan_versionen x where x.reihe_id = r.id and x.version = (v_w ->> 'version')::int - 1;
  return jsonb_build_object(
    'reihe_id', r.id, 'thema_keys', to_jsonb(r.thema_keys), 'ka_datum', r.ka_datum, 'takt', r.takt, 'start', r.start,
    'plan', v_w,
    'system', (select x.plan from public.reihe_plan_versionen x where x.id = (v_w ->> 'version_id')::uuid),
    'vorher', v_vor.plan,
    'sessions_gesamt', (v_w ->> 'sessions_bisher')::int + jsonb_array_length(v_w -> 'sessions'),
    'labels', (select jsonb_object_agg(s.skill_key, public.session_label(s.skill_key)) from public.reihe_skills(r.thema_keys) s),
    'kernideen', (select jsonb_object_agg(ki.skill_key || '.' || ki.kernidee_key, ki.titel) from public.reihe_kernideen ki
                   where ki.skill_key in (select s.skill_key from public.reihe_skills(r.thema_keys) s)));
end;
$$;

-- Reihe anlegen (beendet eine aktive Reihe desselben Fachs) und erste Version planen. Admin oder Coach.
create function public.reihe_anlegen(p_student_id uuid, p_thema_keys text[], p_ka_datum date default null,
                                     p_takt int default 1, p_start date default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') or not public.lernpfad_darf_lesen(p_student_id) then
    raise exception 'reihe_anlegen: nur Coach mit laufendem Vertrag oder Admin' using errcode = '42501';
  end if;
  if exists (select 1 from unnest(p_thema_keys) t where not exists (select 1 from public.themen th where th.thema_key = t)) then
    raise exception 'reihe_anlegen: unbekanntes Thema' using errcode = '22023';
  end if;
  update public.reihen set status = 'beendet' where student_id = p_student_id and fach = 'mathematik' and status = 'aktiv';
  insert into public.reihen (student_id, thema_keys, ka_datum, takt, start, angelegt_von)
  values (p_student_id, p_thema_keys, p_ka_datum, p_takt, coalesce(p_start, public.reihe_heute()), auth.uid())
  returning id into v_id;
  perform public.reihe_planen(v_id, 'start', 'Reihe angelegt');
  return public.reihe_coach_lesen(p_student_id);
end;
$$;

-- Check-in: Klassenarbeitsdatum erfassen bzw. bestätigen (Coach der Session oder Admin). Ohne Reihe legt es eine an;
-- Themen aus p_thema_keys, sonst aus dem Check-in bzw. dem aktuellen Schulthema. Plant neu.
create function public.reihe_ka_setzen(p_session_id uuid, p_student_id uuid, p_ka_datum date,
                                       p_thema_keys text[] default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  s        public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'reihe_ka_setzen');
  r        public.reihen;
  v_themen text[];
  v_tag    date;
begin
  if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
    raise exception 'reihe_ka_setzen: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
  end if;
  v_tag := (s.scheduled_at at time zone 'Europe/Berlin')::date;
  if p_ka_datum is not null and p_ka_datum <= v_tag then
    raise exception 'reihe_ka_setzen: Klassenarbeit muss nach der Session liegen' using errcode = '22023';
  end if;
  r := public.reihe_aktiv(p_student_id);
  v_themen := coalesce(p_thema_keys, r.thema_keys,
    (select array[coalesce(c.ziel_thema_key, c.klassenarbeit_thema_key)] from public.session_checkin c
      where c.session_id = p_session_id and c.student_id = p_student_id
        and coalesce(c.ziel_thema_key, c.klassenarbeit_thema_key) is not null),
    (select array[public.session_schulthema(p_student_id)] where public.session_schulthema(p_student_id) is not null));
  if v_themen is null then
    raise exception 'reihe_ka_setzen: kein Thema für die Reihe' using errcode = '22023', hint = 'kein_thema';
  end if;
  if exists (select 1 from unnest(v_themen) t where not exists (select 1 from public.themen th where th.thema_key = t)) then
    raise exception 'reihe_ka_setzen: unbekanntes Thema' using errcode = '22023';
  end if;
  if r.id is null then
    insert into public.reihen (student_id, thema_keys, ka_datum, start, angelegt_von)
    values (p_student_id, v_themen, p_ka_datum, v_tag, auth.uid()) returning * into r;
    perform public.reihe_planen(r.id, 'start', 'Reihe im Check-in angelegt', p_session_id);
  else
    update public.reihen set ka_datum = p_ka_datum, thema_keys = v_themen, start = least(start, v_tag) where id = r.id;
    perform public.reihe_planen(r.id, 'daten', 'Klassenarbeitsdatum im Check-in gesetzt', p_session_id);
  end if;
  return public.reihe_coach_lesen(p_student_id);
end;
$$;

-- Coach verschiebt einen Skill auf einen Termin oder bestätigt den Plan (bzw. einen Skill).
create function public.reihe_coach_aendern(p_reihe_id uuid, p_aktion text, p_skill_key text default null,
                                           p_ziel_datum date default null, p_grund text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r      public.reihen;
  v_w    jsonb;
begin
  select * into r from public.reihen where id = p_reihe_id and status = 'aktiv';
  if not found then
    raise exception 'reihe_coach_aendern: keine aktive Reihe' using errcode = 'P0002';
  end if;
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') or not public.lernpfad_darf_lesen(r.student_id) then
    raise exception 'reihe_coach_aendern: nur Coach mit laufendem Vertrag oder Admin' using errcode = '42501';
  end if;
  if p_aktion not in ('verschieben', 'bestaetigen') then
    raise exception 'reihe_coach_aendern: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  v_w := public.reihe_plan_wirksam(p_reihe_id);
  if p_aktion = 'verschieben' and not exists (
       select 1 from jsonb_array_elements(v_w -> 'sessions') s
        where (s ->> 'datum')::date = p_ziel_datum and s ->> 'art' = 'normal') then
    raise exception 'reihe_coach_aendern: kein normaler Termin der Reihe am %', p_ziel_datum using errcode = '22023';
  end if;
  if p_aktion = 'verschieben' and not exists (
       select 1 from jsonb_array_elements(v_w -> 'sessions') s, jsonb_array_elements(s -> 'kernideen') e
        where e ->> 'skill_key' = p_skill_key) then
    raise exception 'reihe_coach_aendern: Skill % ist nicht im Plan', p_skill_key using errcode = '22023';
  end if;
  insert into public.reihe_coach_aenderungen (reihe_id, aktion, skill_key, ziel_datum, version_id, grund, von)
  values (p_reihe_id, p_aktion, p_skill_key, p_ziel_datum, (v_w ->> 'version_id')::uuid, nullif(btrim(p_grund), ''), auth.uid());
  return public.reihe_coach_lesen(r.student_id);
end;
$$;

-- Neu planen beim Abschluss einer Session (C1.3): Ist-Zeile je anwesendes Kind mit aktiver Reihe, dann neue Version.
-- Ein Fehler hier hält den Abschluss nicht auf (Warnung im Log).
create function public.reihe_nach_session()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  k      record;
  v_tag  date := (new.scheduled_at at time zone 'Europe/Berlin')::date;
  v_w    jsonb;
begin
  for k in
    select r.id as reihe_id from public.session_students ss
      join public.reihen r on r.student_id = ss.student_id and r.status = 'aktiv'
     where ss.session_id = new.id and ss.attendance = 'present'
  loop
    begin
      -- Zweitprüfung 4: die nächste geplante Session, auch wenn sie an einem anderen Tag stattfand.
      v_w := public.reihe_plan_wirksam(k.reihe_id, '1900-01-01');
      insert into public.reihe_ist (reihe_id, session_id, datum, kernideen)
      values (k.reihe_id, new.id, v_tag,
              coalesce((select s -> 'kernideen' from jsonb_array_elements(v_w -> 'sessions') s
                         where s ->> 'art' = 'normal' order by (s ->> 'datum')::date limit 1), '[]'))
      on conflict do nothing;
      perform public.reihe_planen(k.reihe_id, 'session', 'Neu geplant nach der Session vom ' || to_char(v_tag, 'DD.MM.YYYY'), new.id);
    exception when others then
      raise warning 'reihe_nach_session: Reihe % nicht neu geplant: %', k.reihe_id, sqlerrm;
    end;
  end loop;
  return null;
end;
$$;

create trigger coaching_sessions_reihe_neu_planen
  after update of status on public.coaching_sessions
  for each row when (new.status = 'done' and old.status is distinct from 'done' and not coalesce(new.testlauf, false))
  execute function public.reihe_nach_session();

revoke all on function public.reihe_wert(text), public.reihe_heute(), public.reihe_kann_entfallen_pruefen(text),
  public.reihe_skills(text[]), public.reihe_termine(uuid, date, int, date, date, int), public.reihe_verteilen(numeric[], int, numeric),
  public.reihe_kernidee_stand(uuid, uuid, text, text), public.reihe_plan_rechnen(uuid, date),
  public.reihe_planen(uuid, text, text, uuid), public.reihe_plan_wirksam(uuid, date), public.reihe_aktiv(uuid, text),
  public.reihe_nach_session(), public.reihe_nur_anhaengen(),
  public.reihenplan_kind(uuid), public.reihe_coach_lesen(uuid), public.reihe_anlegen(uuid, text[], date, int, date),
  public.reihe_ka_setzen(uuid, uuid, date, text[]), public.reihe_coach_aendern(uuid, text, text, date, text)
  from public, anon, authenticated;
grant execute on function public.reihenplan_kind(uuid), public.reihe_coach_lesen(uuid),
  public.reihe_anlegen(uuid, text[], date, int, date), public.reihe_ka_setzen(uuid, uuid, date, text[]),
  public.reihe_coach_aendern(uuid, text, text, date, text) to authenticated;

comment on function public.reihenplan_kind(uuid) is 'reihe1 fertig';
comment on function public.reihe_coach_lesen(uuid) is
  'Reihe 1 C1: Karte „Reihe“ für den Coach (wirksamer Plan, Systemvorschlag, Vorversion, Warnung). Coach mit laufendem Vertrag oder Admin.';
comment on function public.reihe_ka_setzen(uuid, uuid, date, text[]) is
  'Reihe 1 C1: Klassenarbeitsdatum im Check-in erfassen bzw. bestätigen; legt die Reihe an oder plant neu. Coach der Session oder Admin.';
comment on function public.reihe_coach_aendern(uuid, text, text, date, text) is
  'Reihe 1 C1: Coach verschiebt einen Skill oder bestätigt den Plan; getrennt vom Systemvorschlag gespeichert.';
