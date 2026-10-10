-- Slots SL1, Teil 5a: Lesefunktionen Wochenplan, Termin, Heute, Zähler, Coaches, Einstellungen.
--
-- Bauauftrag Slots (Fassung 1), Datenvertrag; vollständig beschrieben in docs/api/DATENVERTRAG.md,
-- Abschnitt 10. Jede Funktion liefert fertiges jsonb für genau einen Bildschirm, damit die Oberfläche
-- nichts nachrechnet. Nur Admin (oder Systemaufruf), sonst 42501.

begin;

-- ============================================================================
-- Hilfen
-- ============================================================================

create function public.slots_hhmm(p_zeit time)
returns text
language sql immutable
as $$
  select to_char(p_zeit, 'HH24:MI');
$$;

-- Anlass eines Tages ohne Betrieb (Feiertag vor Ferien), sonst NULL.
create function public.slots_anlass(p_datum date)
returns text
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce((select f.name from public.feiertage_nrw f where f.datum = p_datum),
                  (select f.name from public.ferien_nrw f where p_datum between f.von and f.bis order by f.von limit 1));
$$;

-- Name, Klasse, Fach eines Kindes (Fach aus dem Vertrag des Termins bzw. dem laufenden Vertrag).
create function public.slots_kind_info(p_student_id uuid, p_vertrag_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
           'student_id', s.id,
           'name', coalesce(nullif(btrim(p.full_name), ''), nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')),
           'klasse', coalesce(s.class_level, v.klasse),
           'fach', nullif(btrim(v.fach), ''))
    from public.students s
    left join public.profiles p on p.id = s.profile_id
    left join public.vertraege v on v.id = p_vertrag_id
   where s.id = p_student_id;
$$;

-- Kinder in den Slots (Entscheidung 8): kein Testkonto, laufender oder kommender Vertrag.
-- ohne_stammplatz: kein aktiver Stammplatz und noch Einheiten ohne feste Belegung.
create function public.slots_kinder_basis(p_heute date)
returns table(student_id uuid, vertrag_id uuid, beginn date, stichtag date, laeuft boolean, ohne_stammplatz boolean)
language sql stable security definer
set search_path = public, pg_temp
as $$
  with v as (
    select distinct on (x.student_id) x.student_id, x.id, x.vertragsbeginn, x.vertrag_ende, x.einheiten
      from public.vertraege x
      join public.students s on s.id = x.student_id and not s.ist_test
     where x.status = 'abgeschlossen'
       and x.einheiten is not null and x.vertragsbeginn is not null and x.vertrag_ende is not null
       and x.vertrag_ende >= p_heute
       and public.vertrag_wirksamer_status(x.widerrufen_am, x.gekuendigt_zum, x.vertrag_ende, x.widerruf_bis, p_heute)
           in ('aktiv', 'im_widerruf')
     order by x.student_id, (x.vertragsbeginn <= p_heute) desc, x.vertragsbeginn
  )
  select v.student_id, v.id, v.vertragsbeginn, v.vertrag_ende, v.vertragsbeginn <= p_heute,
         not exists (select 1 from public.stammplaetze sp
                      where sp.vertrag_id = v.id
                        and least(coalesce(sp.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(v.id))
                            >= greatest(p_heute, sp.gueltig_ab))
         and v.einheiten - public.slots_fest_belegt(v.id, p_heute) > 0
    from v;
$$;

-- Ein Raum-Termin mit Zuteilung: Räume mit Kindern, ohne Raum, Fach-Mix (für Woche, Termin, Tag).
create function public.slots_zelle(p_datum date, p_zeit_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  with r as (select * from public.slot_raeume(p_datum, p_datum) x where x.slot_zeit_id = p_zeit_id),
  t as (
    select t.*, kt.vertrag_id from public.slot_zuteilung(p_datum, p_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
  )
  select jsonb_build_object(
    'kapazitaet', 5 * (select count(*) from r where r.offen),
    'belegt', (select count(*) from t),
    'ohne_raum', (select count(*) from t where t.raum_id is null),
    'coach_fehlt', (select count(*) from r where r.art = 'faellt_aus' and r.stamm_coach_id is not null),
    'raeume', coalesce((select jsonb_agg(jsonb_build_object(
                 'raum_id', r.raum_id, 'name', r.raum_name, 'offen', r.offen, 'art', r.art,
                 'coach_id', r.coach_id, 'belegt', (select count(*) from t where t.raum_id = r.raum_id))
               order by r.raum_name) from r), '[]'),
    'faecher', coalesce((select jsonb_agg(jsonb_build_object('fach', f.fach, 'zahl', f.n) order by f.n desc, f.fach)
                           from (select t.fach, count(*) as n from t group by t.fach) f), '[]'));
$$;

-- ============================================================================
-- slots_woche(p_montag)
-- ============================================================================

create function public.slots_woche(p_montag date, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
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

  select jsonb_build_object('ohne_stammplatz', count(*) filter (where b.ohne_stammplatz),
                            'ohne_stammplatz_laufend', count(*) filter (where b.ohne_stammplatz and b.laeuft))
    into v_kinder
    from public.slots_kinder_basis(v_heute) b;

  return jsonb_build_object(
    'montag', v_mo, 'kw', extract(week from v_mo)::int, 'a_woche', extract(week from v_mo)::int % 2 = 1,
    'heute', v_heute,
    'tage', v_tage, 'zeiten', v_zeiten, 'zellen', v_zellen,
    'kopf', jsonb_build_object(
      'plaetze', (select coalesce(sum((c ->> 'kapazitaet')::int), 0) from jsonb_array_elements(v_zellen) c),
      'belegt', (select coalesce(sum((c ->> 'belegt')::int), 0) from jsonb_array_elements(v_zellen) c),
      'auslastung', (select case when sum((c ->> 'kapazitaet')::int) > 0
                                 then round(sum((c ->> 'belegt')::int)::numeric / sum((c ->> 'kapazitaet')::int), 3) end
                       from jsonb_array_elements(v_zellen) c),
      'ohne_raum', (select coalesce(sum((c ->> 'ohne_raum')::int), 0) from jsonb_array_elements(v_zellen) c),
      'erster_ohne_raum', (select jsonb_build_object('datum', c -> 'datum', 'zeit_id', c -> 'zeit_id')
                             from jsonb_array_elements(v_zellen) with ordinality x(c, o)
                            where (c ->> 'ohne_raum')::int > 0 order by o limit 1),
      'ohne_stammplatz', v_kinder -> 'ohne_stammplatz',
      'ohne_stammplatz_laufend', v_kinder -> 'ohne_stammplatz_laufend'));
end;
$$;

-- ============================================================================
-- slots_termin(p_datum, p_zeit_id)
-- ============================================================================

create function public.slots_termin(p_datum date, p_zeit_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt  timestamptz := public.slots_jetzt(p_jetzt);
  v_heute  date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  z        public.slot_zeiten;
  v_beginn timestamptz;
  v_raeume jsonb;
  v_ohne   jsonb;
  v_nicht  jsonb;
begin
  perform public.slots_admin_pruefen('slots_termin');
  select * into z from public.slot_zeiten where id = p_zeit_id;
  if not found then
    perform public.slots_fehler('P0002', 'slots_termin: Uhrzeit nicht gefunden');
  end if;
  v_beginn := public.slots_termin_beginn(p_datum, p_zeit_id);

  with t as (
    select t.termin_id, t.raum_id, t.grund,
           public.slots_kind_info(kt.student_id, kt.vertrag_id) || jsonb_build_object(
             'termin_id', kt.id, 'herkunft', kt.herkunft, 'zustand', kt.zustand, 'raum_fest', kt.raum_fest,
             'session_id', kt.session_id,
             'umgebucht_von', (select jsonb_build_object('termin_id', a.id, 'datum', a.datum,
                                                         'beginn', public.slots_hhmm(az.beginn))
                                 from public.kind_termine a join public.slot_zeiten az on az.id = a.slot_zeit_id
                                where a.id = kt.umgebucht_von)) as kind
      from public.slot_zuteilung(p_datum, p_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
  ),
  r as (select * from public.slot_raeume(p_datum, p_datum) x where x.slot_zeit_id = p_zeit_id)
  select coalesce(jsonb_agg(jsonb_build_object(
           'raum_id', r.raum_id, 'name', r.raum_name, 'offen', r.offen, 'art', r.art,
           'coach_id', r.coach_id, 'coach_name', (select p.full_name from public.profiles p where p.id = r.coach_id),
           'stamm_coach_id', r.stamm_coach_id,
           'stamm_coach_name', (select p.full_name from public.profiles p where p.id = r.stamm_coach_id),
           'vertretung', r.art = 'vertretung',
           'session_id', s.id, 'gestartet', s.gestartet_am is not null,
           'gemischt', (select count(distinct coalesce(t.kind ->> 'fach', '')) from t where t.raum_id = r.raum_id) > 1,
           'kinder', coalesce((select jsonb_agg(t.kind order by t.kind ->> 'name') from t where t.raum_id = r.raum_id), '[]'))
         order by r.raum_name), '[]'),
         coalesce((select jsonb_agg(t.kind order by t.kind ->> 'name') from t where t.raum_id is null), '[]')
    into v_raeume, v_ohne
    from r
    left join lateral (select * from public.slots_session(p_datum, p_zeit_id, r.raum_id)) s on true;

  select coalesce(jsonb_agg(public.slots_kind_info(kt.student_id, kt.vertrag_id) || jsonb_build_object(
           'termin_id', kt.id, 'zustand', kt.zustand, 'herkunft', kt.herkunft,
           'absage_eingang', kt.absage_eingang,
           'rechtzeitig', case when kt.absage_eingang is not null then kt.zustand = 'cancelled' end,
           'zuruecknehmbar', kt.absage_eingang is not null and v_beginn > v_jetzt
                             and not exists (select 1 from public.coaching_sessions cs
                                              where cs.id = kt.session_id and cs.gestartet_am is not null))
         order by kt.absage_eingang nulls last, kt.id), '[]')
    into v_nicht
    from public.kind_termine kt
   where kt.datum = p_datum and kt.slot_zeit_id = p_zeit_id
     and kt.zustand in ('cancelled', 'unexcused', 'cancelled_by_us');

  return jsonb_build_object(
    'datum', p_datum, 'kw', extract(week from p_datum)::int,
    'zeit', jsonb_build_object('id', z.id, 'beginn', public.slots_hhmm(z.beginn), 'ende', public.slots_hhmm(z.ende)),
    'betrieb', public.betriebstag(p_datum), 'anlass', public.slots_anlass(p_datum),
    'heute', p_datum = v_heute, 'vergangen', p_datum < v_heute, 'begonnen', v_beginn <= v_jetzt,
    'festgeschrieben', exists (select 1 from public.coaching_sessions cs
                                where cs.slot_zeit_id = p_zeit_id and cs.scheduled_at = v_beginn),
    'kapazitaet', public.slot_kapazitaet(p_datum, p_zeit_id),
    'belegt', public.slot_belegt(p_datum, p_zeit_id),
    'raeume', v_raeume, 'ohne_raum', v_ohne, 'nicht_dabei', v_nicht,
    'anwesenheit_fehlt', p_datum < v_heute and exists (select 1 from public.kind_termine kt
                                                        where kt.datum = p_datum and kt.slot_zeit_id = p_zeit_id
                                                          and kt.zustand = 'planned'),
    'raeume_schliessbar', coalesce((select jsonb_agg(jsonb_build_object('raum_id', x.id, 'name', x.name) order by x.name)
                             from public.raeume x
                            where x.aktiv_ab <= p_datum and (x.inaktiv_ab is null or p_datum < x.inaktiv_ab)
                              and not exists (select 1 from public.slot_raeume(p_datum, p_datum) y
                                               where y.slot_zeit_id = p_zeit_id and y.raum_id = x.id and y.offen)), '[]'),
    'coaches', coalesce((select jsonb_agg(jsonb_build_object(
                 'id', p.id, 'name', p.full_name,
                 'raum_id', (select y.raum_id from public.slot_raeume(p_datum, p_datum) y
                              where y.slot_zeit_id = p_zeit_id and y.coach_id = p.id limit 1))
               order by p.full_name) from public.profiles p where p.role = 'coach'), '[]'));
end;
$$;

-- ============================================================================
-- slots_tag(p_datum) — für "Heute im Betrieb" und "Absagen heute"
-- ============================================================================

create function public.slots_tag(p_datum date, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  perform public.slots_admin_pruefen('slots_tag');
  return jsonb_build_object(
    'datum', p_datum,
    'betrieb', public.betriebstag(p_datum), 'anlass', public.slots_anlass(p_datum),
    'raum_termine', coalesce((
      select jsonb_agg(jsonb_build_object(
               'zeit_id', r.slot_zeit_id, 'beginn', public.slots_hhmm(z.beginn), 'ende', public.slots_hhmm(z.ende),
               'raum_id', r.raum_id, 'raum_name', r.raum_name,
               'coach_id', r.coach_id, 'coach_name', (select p.full_name from public.profiles p where p.id = r.coach_id),
               'art', r.art, 'kapazitaet', 5,
               'belegt', (select count(*) from public.slot_zuteilung(p_datum, r.slot_zeit_id) t where t.raum_id = r.raum_id),
               'session_id', s.id, 'gestartet', s.gestartet_am is not null, 'status', s.status)
             order by z.beginn, r.raum_name)
        from public.slot_raeume(p_datum, p_datum) r
        join public.slot_zeiten z on z.id = r.slot_zeit_id
        left join lateral (select * from public.slots_session(p_datum, r.slot_zeit_id, r.raum_id)) s on true
       where r.offen or s.id is not null), '[]'),
    -- Sessions ohne Raum-Termin: Einzel-Sessions und Testläufe, jede genau einmal.
    'sessions_ohne_raum', coalesce((
      select jsonb_agg(jsonb_build_object(
               'session_id', cs.id, 'scheduled_at', cs.scheduled_at, 'room', cs.room, 'status', cs.status,
               'coach_id', cs.coach_id, 'coach_name', (select p.full_name from public.profiles p where p.id = cs.coach_id),
               'testlauf', cs.testlauf, 'gestartet', cs.gestartet_am is not null,
               'kinder', (select count(*) from public.session_students ss
                           where ss.session_id = cs.id and ss.attendance not in ('cancelled', 'cancelled_by_us')))
             order by cs.scheduled_at, cs.room)
        from public.coaching_sessions cs
       where cs.raum_id is null and public.slots_berlin_tag(cs.scheduled_at) = p_datum), '[]'),
    'absagen', coalesce((
      select jsonb_agg(public.slots_kind_info(kt.student_id, kt.vertrag_id) || jsonb_build_object(
               'termin_id', kt.id, 'beginn', public.slots_hhmm(z.beginn), 'zustand', kt.zustand,
               'absage_eingang', kt.absage_eingang, 'rechtzeitig', kt.zustand = 'cancelled')
             order by z.beginn, kt.absage_eingang)
        from public.kind_termine kt join public.slot_zeiten z on z.id = kt.slot_zeit_id
       where kt.datum = p_datum and kt.absage_eingang is not null and kt.zustand in ('cancelled', 'unexcused')), '[]'));
end;
$$;

-- ============================================================================
-- slots_zaehler() — Zähler für die Leiste
-- ============================================================================

create function public.slots_zaehler(p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_ohne_st integer;
  v_ohne_r  integer;
begin
  perform public.slots_admin_pruefen('slots_zaehler');
  select count(*) into v_ohne_st from public.slots_kinder_basis(v_heute) b
   where b.ohne_stammplatz and b.beginn <= v_heute + 14;
  select coalesce(sum(x.n), 0) into v_ohne_r
    from (select (select count(*) from public.slot_zuteilung(g::date, z.id) t where t.raum_id is null) as n
            from generate_series(v_heute, v_heute + 6, interval '1 day') g
            join public.slot_zeiten z on z.aktiv_ab <= g::date and (z.inaktiv_ab is null or g::date < z.inaktiv_ab)
           where public.betriebstag(g::date)
             and exists (select 1 from public.kind_termine kt where kt.datum = g::date and kt.slot_zeit_id = z.id)) x;
  return jsonb_build_object('ohne_stammplatz', v_ohne_st, 'ohne_raum', v_ohne_r, 'gesamt', v_ohne_st + v_ohne_r);
end;
$$;

-- ============================================================================
-- slots_coaches(p_montag)
-- ============================================================================

create function public.slots_coaches(p_montag date, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_mo date := p_montag - (extract(isodow from p_montag)::int - 1);
begin
  perform public.slots_admin_pruefen('slots_coaches');
  return jsonb_build_object(
    'montag', v_mo, 'kw', extract(week from v_mo)::int,
    'coaches', coalesce((select jsonb_agg(c.j order by c.name) from (
      select p.full_name as name, jsonb_build_object(
        'id', p.id, 'name', p.full_name,
        'stammschichten', coalesce((select jsonb_agg(jsonb_build_object(
              'id', s.id, 'wochentag', s.wochentag, 'zeit_id', s.slot_zeit_id, 'beginn', public.slots_hhmm(z.beginn),
              'raum_id', s.raum_id, 'raum_name', r.name, 'gueltig_ab', s.gueltig_ab, 'gueltig_bis', s.gueltig_bis)
            order by s.wochentag, z.beginn)
            from public.stammschichten s
            join public.slot_zeiten z on z.id = s.slot_zeit_id join public.raeume r on r.id = s.raum_id
           where s.coach_id = p.id and coalesce(s.gueltig_bis, 'infinity'::date) >= v_mo
             and s.gueltig_bis is distinct from s.gueltig_ab - 1), '[]'),
        'stunden_pro_woche', (select count(*) from public.stammschichten s
                               where s.coach_id = p.id and s.gueltig_ab <= v_mo + 4
                                 and coalesce(s.gueltig_bis, 'infinity'::date) >= v_mo),
        'abweichungen', coalesce((select jsonb_agg(jsonb_build_object(
              'datum', r.datum, 'zeit_id', r.slot_zeit_id, 'beginn', public.slots_hhmm(z.beginn),
              'raum_id', r.raum_id, 'raum_name', r.raum_name, 'art', r.art)
            order by r.datum, z.beginn)
            from public.slot_raeume(v_mo, v_mo + 4) r join public.slot_zeiten z on z.id = r.slot_zeit_id
           where r.art <> 'stamm' and (r.coach_id = p.id or r.stamm_coach_id = p.id)), '[]')) as j
        from public.profiles p where p.role = 'coach') c), '[]'),
    'raeume', coalesce((select jsonb_agg(jsonb_build_object('id', r.id, 'name', r.name) order by r.name)
                          from public.raeume r where r.inaktiv_ab is null or r.inaktiv_ab > v_mo), '[]'),
    'zeiten', coalesce((select jsonb_agg(jsonb_build_object('id', z.id, 'beginn', public.slots_hhmm(z.beginn),
                                                            'ende', public.slots_hhmm(z.ende)) order by z.beginn)
                          from public.slot_zeiten z
                         where z.aktiv_ab <= v_mo + 4 and (z.inaktiv_ab is null or z.inaktiv_ab > v_mo)), '[]'));
end;
$$;

-- ============================================================================
-- slots_einstellungen()
-- ============================================================================

create function public.slots_einstellungen(p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  -- Ende des Schuljahrs: Ende der nächsten Sommerferien (bzw. der laufenden).
  v_bis   date := coalesce((select min(f.bis) from public.ferien_nrw f where f.art = 'sommer' and f.bis >= v_heute),
                           public.slots_planungsgrenze());
begin
  perform public.slots_admin_pruefen('slots_einstellungen');
  return jsonb_build_object(
    'heute', v_heute, 'schuljahr_bis', v_bis, 'planungsgrenze', public.slots_planungsgrenze(),
    'raeume', coalesce((select jsonb_agg(jsonb_build_object(
                 'id', r.id, 'name', r.name, 'aktiv_ab', r.aktiv_ab, 'inaktiv_ab', r.inaktiv_ab,
                 'stammschichten', (select count(*) from public.stammschichten s
                                     where s.raum_id = r.id and coalesce(s.gueltig_bis, 'infinity'::date) >= v_heute))
               order by r.name) from public.raeume r), '[]'),
    'zeiten', coalesce((select jsonb_agg(jsonb_build_object(
                 'id', z.id, 'beginn', public.slots_hhmm(z.beginn), 'ende', public.slots_hhmm(z.ende),
                 'aktiv_ab', z.aktiv_ab, 'inaktiv_ab', z.inaktiv_ab) order by z.beginn, z.aktiv_ab)
               from public.slot_zeiten z), '[]'),
    'ferien', coalesce((select jsonb_agg(jsonb_build_object('art', f.art, 'name', f.name, 'von', f.von, 'bis', f.bis)
                                         order by f.von)
                          from public.ferien_nrw f where f.bis >= v_heute and f.von <= v_bis), '[]'),
    'feiertage', coalesce((select jsonb_agg(jsonb_build_object('datum', f.datum, 'name', f.name, 'art', f.art)
                                            order by f.datum)
                             from public.feiertage_nrw f
                            where f.datum between v_heute and v_bis and extract(isodow from f.datum) between 1 and 5
                              and not exists (select 1 from public.ferien_nrw x where f.datum between x.von and x.bis)), '[]'));
end;
$$;

-- ============================================================================
-- Rechte
-- ============================================================================

revoke all on function public.slots_hhmm(time) from public, anon, authenticated;
revoke all on function public.slots_anlass(date) from public, anon, authenticated;
revoke all on function public.slots_kind_info(uuid, uuid) from public, anon, authenticated;
revoke all on function public.slots_kinder_basis(date) from public, anon, authenticated;
revoke all on function public.slots_zelle(date, uuid) from public, anon, authenticated;

revoke all on function public.slots_woche(date, timestamptz) from public, anon;
revoke all on function public.slots_termin(date, uuid, timestamptz) from public, anon;
revoke all on function public.slots_tag(date, timestamptz) from public, anon;
revoke all on function public.slots_zaehler(timestamptz) from public, anon;
revoke all on function public.slots_coaches(date, timestamptz) from public, anon;
revoke all on function public.slots_einstellungen(timestamptz) from public, anon;
grant execute on function public.slots_woche(date, timestamptz) to authenticated;
grant execute on function public.slots_termin(date, uuid, timestamptz) to authenticated;
grant execute on function public.slots_tag(date, timestamptz) to authenticated;
grant execute on function public.slots_zaehler(timestamptz) to authenticated;
grant execute on function public.slots_coaches(date, timestamptz) to authenticated;
grant execute on function public.slots_einstellungen(timestamptz) to authenticated;

commit;
