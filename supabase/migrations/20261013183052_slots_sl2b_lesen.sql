-- Slots SL2b, Teil 2: Lesefunktionen kennzeichnen Testkonten, Kennzahlen zählen sie nicht.
--
-- Entscheidungen Rasit 12.10.2026 (Paket SL2b):
--   2  Testkonten sind überall in den Slots gekennzeichnet: slots_kind_info liefert ist_test (Termin, Kinder,
--      Kind, Absagen, Einsätze), slots_zelle die Zahl test (Wochenplan). Nur neue Felder, nichts entfällt.
--   3  Die Kennzahlen (Kopf von slots_woche, slots_zaehler) zählen Testkonten nicht mit. Die Zelle zählt sie
--      in belegt weiter, denn der Platz ist belegt; test und test_ohne_raum sagen, wie viele davon Testkonten sind.
--   4  slots_frei meldet je Zelle art_konflikt, wenn für das Kind einer der nächsten sechs Termine an einem
--      Kind der anderen Art scheitert (gleiche Regel wie das Speichern, SL013).
-- Alle ersetzten Funktionen aus der Prod-Definition; Signatur, SECURITY, search_path und Rechte unverändert.

begin;

CREATE OR REPLACE FUNCTION public.slots_kind_info(p_student_id uuid, p_vertrag_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select jsonb_build_object(
           'student_id', s.id,
           'name', coalesce(nullif(btrim(p.full_name), ''), nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')),
           'klasse', coalesce(s.class_level, v.klasse),
           'fach', nullif(btrim(v.fach), ''),
           -- SL2b (Entscheidung 2): Kennzeichen "Test" in allen Slot-Ansichten.
           'ist_test', s.ist_test)
    from public.students s
    left join public.profiles p on p.id = s.profile_id
    left join public.vertraege v on v.id = p_vertrag_id
   where s.id = p_student_id;
$function$;

CREATE OR REPLACE FUNCTION public.slots_zelle(p_datum date, p_zeit_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with r as (select * from public.slot_raeume(p_datum, p_datum) x where x.slot_zeit_id = p_zeit_id),
  t as (
    select t.*, kt.vertrag_id, s.ist_test from public.slot_zuteilung(p_datum, p_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
      join public.students s on s.id = t.student_id
  )
  select jsonb_build_object(
    'kapazitaet', 5 * (select count(*) from r where r.offen),
    'belegt', (select count(*) from t),
    'ohne_raum', (select count(*) from t where t.raum_id is null),
    -- SL2b (Entscheidungen 2 und 3): davon Testkonten. belegt zählt sie mit, der Platz ist belegt.
    'test', (select count(*) from t where t.ist_test),
    'test_ohne_raum', (select count(*) from t where t.ist_test and t.raum_id is null),
    'coach_fehlt', (select count(*) from r where r.art = 'faellt_aus' and r.stamm_coach_id is not null),
    'raeume', coalesce((select jsonb_agg(jsonb_build_object(
                 'raum_id', r.raum_id, 'name', r.raum_name, 'offen', r.offen, 'art', r.art,
                 'coach_id', r.coach_id, 'belegt', (select count(*) from t where t.raum_id = r.raum_id))
               order by r.raum_name) from r), '[]'),
    'faecher', coalesce((select jsonb_agg(jsonb_build_object('fach', f.fach, 'zahl', f.n) order by f.n desc, f.fach)
                           from (select t.fach, count(*) as n from t group by t.fach) f), '[]'));
$function$;

CREATE OR REPLACE FUNCTION public.slots_woche(p_montag date, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_mo    date := p_montag - (extract(isodow from p_montag)::int - 1);
  v_tage  jsonb;
  v_zeiten jsonb;
  v_zellen jsonb;
  v_kinder jsonb;
begin
  perform public.slots_admin_pruefen('slots_woche');

  select jsonb_agg(jsonb_build_object(
           'datum', g::date, 'wochentag', extract(isodow from g)::int, 'betrieb', public.betriebstag(g::date),
           'anlass', case when not public.betriebstag(g::date) then public.slots_anlass(g::date) end,
           'heute', g::date = v_heute, 'vergangen', g::date < v_heute) order by g)
    into v_tage
    from generate_series(v_mo, v_mo + 4, interval '1 day') g;

  select coalesce(jsonb_agg(jsonb_build_object('id', z.id, 'beginn', public.slots_hhmm(z.beginn),
                                               'ende', public.slots_hhmm(z.ende)) order by z.beginn), '[]')
    into v_zeiten
    from public.slot_zeiten z
   where z.aktiv_ab <= v_mo + 4 and (z.inaktiv_ab is null or z.inaktiv_ab > v_mo);

  select coalesce(jsonb_agg(public.slots_zelle(g::date, z.id)
                            || jsonb_build_object('datum', g::date, 'zeit_id', z.id,
                                                  'vergangen', public.slots_termin_beginn(g::date, z.id) <= v_jetzt)
                            order by g, z.beginn), '[]')
    into v_zellen
    from generate_series(v_mo, v_mo + 4, interval '1 day') g
    join public.slot_zeiten z on z.aktiv_ab <= g::date and (z.inaktiv_ab is null or g::date < z.inaktiv_ab)
   where public.betriebstag(g::date);

  -- SL2b (Entscheidung 3): Die Kennzahlen zählen Testkonten nicht mit.
  select jsonb_build_object('ohne_stammplatz', count(*) filter (where b.ohne_stammplatz),
                            'ohne_stammplatz_laufend', count(*) filter (where b.ohne_stammplatz and b.laeuft))
    into v_kinder
    from public.slots_kinder_basis(v_heute) b
    join public.students s on s.id = b.student_id and not s.ist_test;

  return jsonb_build_object(
    'montag', v_mo, 'kw', extract(week from v_mo)::int, 'a_woche', extract(week from v_mo)::int % 2 = 1,
    'heute', v_heute,
    'tage', v_tage, 'zeiten', v_zeiten, 'zellen', v_zellen,
    'kopf', jsonb_build_object(
      'plaetze', (select coalesce(sum((c ->> 'kapazitaet')::int), 0) from jsonb_array_elements(v_zellen) c),
      'belegt', (select coalesce(sum((c ->> 'belegt')::int - (c ->> 'test')::int), 0) from jsonb_array_elements(v_zellen) c),
      'auslastung', (select case when sum((c ->> 'kapazitaet')::int) > 0
                                 then round(sum((c ->> 'belegt')::int - (c ->> 'test')::int)::numeric
                                            / sum((c ->> 'kapazitaet')::int), 3) end
                       from jsonb_array_elements(v_zellen) c),
      'ohne_raum', (select coalesce(sum((c ->> 'ohne_raum')::int - (c ->> 'test_ohne_raum')::int), 0)
                      from jsonb_array_elements(v_zellen) c),
      'erster_ohne_raum', (select jsonb_build_object('datum', c -> 'datum', 'zeit_id', c -> 'zeit_id')
                             from jsonb_array_elements(v_zellen) with ordinality x(c, o)
                            where (c ->> 'ohne_raum')::int - (c ->> 'test_ohne_raum')::int > 0 order by o limit 1),
      'ohne_stammplatz', v_kinder -> 'ohne_stammplatz',
      'ohne_stammplatz_laufend', v_kinder -> 'ohne_stammplatz_laufend'));
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_zaehler(p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_ohne_st integer;
  v_ohne_r  integer;
begin
  perform public.slots_admin_pruefen('slots_zaehler');
  -- SL2b (Entscheidung 3): Testkonten zählen nicht mit.
  select count(*) into v_ohne_st from public.slots_kinder_basis(v_heute) b
    join public.students s on s.id = b.student_id and not s.ist_test
   where b.ohne_stammplatz and b.beginn <= v_heute + 14;
  select coalesce(sum(x.n), 0) into v_ohne_r
    from (select (select count(*) from public.slot_zuteilung(g::date, z.id) t
                    join public.students s on s.id = t.student_id and not s.ist_test
                   where t.raum_id is null) as n
            from generate_series(v_heute, v_heute + 6, interval '1 day') g
            join public.slot_zeiten z on z.aktiv_ab <= g::date and (z.inaktiv_ab is null or g::date < z.inaktiv_ab)
           where public.betriebstag(g::date)
             and exists (select 1 from public.kind_termine kt where kt.datum = g::date and kt.slot_zeit_id = z.id)) x;
  return jsonb_build_object('ohne_stammplatz', v_ohne_st, 'ohne_raum', v_ohne_r, 'gesamt', v_ohne_st + v_ohne_r);
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_frei(p_takt text, p_ab date, p_student_id uuid DEFAULT NULL::uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_ab date := greatest(p_ab, public.slots_berlin_tag(public.slots_jetzt(p_jetzt)));
begin
  perform public.slots_admin_pruefen('slots_frei');
  if p_takt not in ('woechentlich', 'a_woche', 'b_woche') then
    perform public.slots_fehler('22023', 'slots_frei: unbekannter Takt');
  end if;
  return jsonb_build_object(
    'takt', p_takt, 'ab', v_ab,
    'zeiten', coalesce((select jsonb_agg(jsonb_build_object('id', z.id, 'beginn', public.slots_hhmm(z.beginn),
                                                            'ende', public.slots_hhmm(z.ende)) order by z.beginn)
                          from public.slot_zeiten z where public.slots_zeit_aktiv(z.id, v_ab)), '[]'),
    'zellen', coalesce((
      select jsonb_agg(jsonb_build_object(
               'wochentag', w, 'zeit_id', z.id,
               'frei', greatest(f.frei, 0), 'raum', f.kap_min > 0,
               'voll', f.kap_min > 0 and f.frei <= 0, 'termine', f.n,
               -- SL2b (Entscheidung 4): dieselbe Regel wie SL013 in slots_stammplatz_gruende.
               'art_konflikt', coalesce(f.konflikt, false))
             order by w, z.beginn)
        from generate_series(1, 5) w
        cross join public.slot_zeiten z
        cross join lateral (
          select min(x.kapazitaet - x.belegt) as frei, min(x.kapazitaet) as kap_min, count(*) as n,
                 bool_or(public.slots_art_konflikt(p_student_id, x.datum, z.id)) filter (where p_student_id is not null)
                   as konflikt
            from public.slots_naechste_termine_frei(w, z.id, p_takt, v_ab, p_student_id) x
        ) f
       where public.slots_zeit_aktiv(z.id, v_ab)), '[]'));
end;
$function$;

commit;
