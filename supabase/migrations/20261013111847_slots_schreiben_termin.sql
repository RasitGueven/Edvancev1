-- Slots SL1, Teil 4b: Schreibfunktionen für Termine.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 11, 14 ("nach dem Festschreiben"), 16, 17, 19, 23;
-- Anforderung D 19–23, F 35–41, G 42–46, H 49–50.
--
-- Inhalt:
--   1. Hilfen: Session eines Raum-Termins, Festschreibung nachziehen, Wochengrenze, Budget, Zusatz-Prüfung
--   2. termin_absagen, termin_umbuchen, absage_zuruecknehmen, zusatztermin_buchen
--   3. termin_ausgefallen, termin_faellt_aus
--   4. termin_raum_setzen, termin_coach_setzen, termin_raum_oeffnen

begin;

-- ============================================================================
-- 1. Hilfen
-- ============================================================================

-- Festgeschriebene Session eines Raum-Termins (Entscheidung 14), sonst NULL.
create function public.slots_session(p_datum date, p_slot_zeit_id uuid, p_raum_id uuid)
returns public.coaching_sessions
language sql stable security definer
set search_path = public, pg_temp
as $$
  select cs.* from public.coaching_sessions cs
   where cs.raum_id = p_raum_id and cs.slot_zeit_id = p_slot_zeit_id
     and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_slot_zeit_id);
$$;

-- Nach jeder Änderung an einem festgeschriebenen Termin: Kinder, die die Zuteilung in einen Raum mit
-- Session legt und die dort noch nicht gebucht sind, kommen in session_students (Entscheidung 14).
-- Ein Kind ohne Zugang an dem Tag (ZG001) wird ausgelassen und "ausgefallen durch uns".
create function public.slots_festschreibung_nachziehen(p_datum date, p_slot_zeit_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  z        record;
  v_sess   uuid;
  v_aus    jsonb := '[]';
begin
  if not exists (select 1 from public.coaching_sessions cs
                  where cs.slot_zeit_id = p_slot_zeit_id
                    and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_slot_zeit_id)) then
    return v_aus;
  end if;
  for z in
    select t.termin_id, t.student_id, t.raum_id from public.slot_zuteilung(p_datum, p_slot_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
     where t.raum_id is not null and kt.session_id is null
  loop
    v_sess := (public.slots_session(p_datum, p_slot_zeit_id, z.raum_id)).id;
    continue when v_sess is null;
    if public.session_platz_zugang(z.student_id, p_datum) then
      insert into public.session_students (session_id, student_id, attendance)
      values (v_sess, z.student_id, 'planned')
      on conflict (session_id, student_id) do update set attendance = 'planned';
      update public.kind_termine set session_id = v_sess where id = z.termin_id;
    else
      update public.kind_termine set zustand = 'cancelled_by_us' where id = z.termin_id;
      v_aus := v_aus || jsonb_build_object('termin_id', z.termin_id, 'student_id', z.student_id, 'grund', 'ZG001');
    end if;
  end loop;
  return v_aus;
end;
$$;

-- Anwesenheit einer festgeschriebenen Buchung nachziehen (Absage, Ausfall, Rücknahme).
create function public.slots_buchung_setzen(p_termin_id uuid)
returns void
language sql security definer
set search_path = public, pg_temp
as $$
  update public.session_students ss set attendance = kt.zustand
    from public.kind_termine kt
   where kt.id = p_termin_id and kt.session_id is not null
     and ss.session_id = kt.session_id and ss.student_id = kt.student_id
     and ss.attendance is distinct from kt.zustand;
$$;

-- Entscheidung 19: Grenze je Kalenderwoche = Rhythmus der Woche + 2.
create function public.slots_wochengrenze(p_student_id uuid, p_datum date)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  with woche as (
    select (p_datum - (extract(isodow from p_datum)::int - 1)) as mo
  ),
  stamm as (
    select count(*)::int as n
      from public.stammplaetze s, woche w
     where s.student_id = p_student_id
       and s.gueltig_ab <= w.mo + 4
       and least(coalesce(s.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(s.vertrag_id)) >= w.mo
       and public.slots_takt_passt(s.takt, w.mo)
  ),
  paket as (
    select r.woechentlich + case when extract(week from p_datum)::int % 2 = 1 then r.vierzehntaeglich else 0 end as n
      from public.vertraege v
      join public.slot_rhythmus r on r.tier_id = v.tier_id and r.laufzeit_monate = v.laufzeit_monate
     where v.id = public.slots_vertrag_am(p_student_id, p_datum)
  )
  select case when (select n from stamm) > 0 then (select n from stamm)
              else coalesce((select n from paket), 1) end + 2;
$$;

-- Aktive Termine (planned, present, unexcused und Einzelbuchungen) der Kalenderwoche von p_datum.
create function public.slots_woche_aktiv(p_student_id uuid, p_datum date, p_ausser uuid default null)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  with woche as (select (p_datum - (extract(isodow from p_datum)::int - 1)) as mo)
  select (select count(*)::int from public.kind_termine kt, woche w
           where kt.student_id = p_student_id and kt.datum between w.mo and w.mo + 6
             and kt.zustand in ('planned', 'present', 'unexcused') and kt.id is distinct from p_ausser)
       + (select count(*)::int from public.slots_einzelbuchungen(p_student_id) e, woche w
           where e.datum between w.mo and w.mo + 6 and e.attendance in ('planned', 'present', 'unexcused'));
$$;

-- Einheiten, die feste Zeilen und Einzelbuchungen eines Vertrags belegen (Entscheidung 11).
create function public.slots_fest_belegt(p_vertrag_id uuid, p_heute date, p_ausser uuid default null)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  select (select count(*)::int from public.kind_termine kt
           where kt.vertrag_id = p_vertrag_id and kt.zustand in ('planned', 'present', 'unexcused')
             and kt.id is distinct from p_ausser
             and not (kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                      and kt.datum >= p_heute))
       + (select count(*)::int from public.vertraege v, public.slots_einzelbuchungen(v.student_id) e
           where v.id = p_vertrag_id and e.datum between v.vertragsbeginn and v.vertrag_ende
             and e.attendance in ('planned', 'present', 'unexcused'));
$$;

-- Prüft einen Zusatztermin (Anforderung G 43–46) und liefert den ersten verletzten SL-Code oder NULL.
-- p_ausser: ein Termin, der vorher rechtzeitig abgesagt würde (Vorschau beim Umbuchen, slots_ziele);
-- er zählt dann weder für den Tag noch für die Woche noch fürs Budget.
create function public.slots_zusatz_code(p_student_id uuid, p_datum date, p_slot_zeit_id uuid, p_jetzt timestamptz,
                                         p_ausser uuid default null)
returns text
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_vertrag uuid := public.slots_vertrag_am(p_student_id, p_datum);
  v_kap     integer;
begin
  if v_vertrag is null or not public.slots_kind_zugelassen(p_student_id) then
    return 'SL006';
  end if;
  if p_datum > public.slots_planungsgrenze() then
    return 'SL012';
  end if;
  if public.slots_termin_beginn(p_datum, p_slot_zeit_id) <= p_jetzt then
    return 'SL007';
  end if;
  v_kap := public.slot_kapazitaet(p_datum, p_slot_zeit_id);
  if v_kap = 0 then
    return 'SL002';
  end if;
  if exists (select 1 from public.kind_termine kt
              where kt.student_id = p_student_id and kt.datum = p_datum and kt.id is distinct from p_ausser
                and kt.zustand in ('planned', 'present', 'unexcused'))
     or exists (select 1 from public.slots_einzelbuchungen(p_student_id) e
                 where e.datum = p_datum and e.attendance in ('planned', 'present', 'unexcused')) then
    return 'SL003';
  end if;
  if public.slots_woche_aktiv(p_student_id, p_datum, p_ausser) + 1 > public.slots_wochengrenze(p_student_id, p_datum) then
    return 'SL004';
  end if;
  if public.slot_belegt(p_datum, p_slot_zeit_id, p_student_id) >= v_kap then
    return 'SL001';
  end if;
  if (select v.einheiten from public.vertraege v where v.id = v_vertrag)
     - public.slots_fest_belegt(v_vertrag, public.slots_berlin_tag(p_jetzt), p_ausser) < 1 then
    return 'SL005';
  end if;
  return null;
end;
$$;

create function public.slots_code_werfen(p_code text, p_wer text)
returns void
language plpgsql volatile
as $$
begin
  if p_code is null then
    return;
  end if;
  perform public.slots_fehler(p_code, p_wer || ': ' || case p_code
    when 'SL001' then 'Slot voll'
    when 'SL002' then 'kein Raum mit Coach'
    when 'SL003' then 'schon ein Termin an dem Tag'
    when 'SL004' then 'Wochengrenze erreicht'
    when 'SL005' then 'keine offenen Einheiten'
    when 'SL006' then 'außerhalb des Vertrags'
    when 'SL007' then 'Vergangenheit'
    when 'SL010' then 'Rücknahme nicht möglich'
    when 'SL011' then 'Termin vergangen oder begonnen, nur Ansicht'
    when 'SL012' then 'jenseits der Ferientabelle'
    else p_code end);
end;
$$;

-- Absage nach der 10-Uhr-Regel (Anforderung F 37, Entscheidung 17). Ohne Sperre und Planung: die
-- aufrufende Funktion macht beides.
create function public.slots_absage_intern(p_termin_id uuid, p_eingang timestamptz, p_jetzt timestamptz, p_wer text)
returns public.kind_termine
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  kt public.kind_termine;
begin
  select * into kt from public.kind_termine where id = p_termin_id for update;
  if not found then
    perform public.slots_fehler('P0002', p_wer || ': Termin nicht gefunden');
  end if;
  if kt.datum < public.slots_berlin_tag(p_jetzt) then
    perform public.slots_code_werfen('SL011', p_wer);
  end if;
  if kt.zustand <> 'planned' then
    perform public.slots_fehler('22023', p_wer || ': Termin ist nicht geplant', 'zustand:' || kt.zustand);
  end if;
  if p_eingang is null or p_eingang > p_jetzt then
    perform public.slots_fehler('22023', p_wer || ': Eingang fehlt oder liegt in der Zukunft', 'eingang');
  end if;
  update public.kind_termine
     set zustand = case when (p_eingang at time zone 'Europe/Berlin') < (kt.datum + time '10:00')
                        then 'cancelled' else 'unexcused' end,
         absage_eingang = p_eingang, absage_erfasst_von = auth.uid(), absage_erfasst_am = now()
   where id = p_termin_id
  returning * into kt;
  perform public.slots_buchung_setzen(kt.id);
  return kt;
end;
$$;

-- Bewegliche Termine eines Kindes ab heute (für "verdrängt": vorher/nachher).
create function public.slots_beweglich(p_student_id uuid, p_heute date)
returns date[]
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(kt.datum order by kt.datum), '{}') from public.kind_termine kt
   where kt.student_id = p_student_id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
     and kt.session_id is null and kt.datum >= p_heute;
$$;

-- ============================================================================
-- 2. Absage, Umbuchen, Rücknahme, Zusatztermin
-- ============================================================================

create function public.termin_absagen(p_termin_id uuid, p_eingang timestamptz, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  kt      public.kind_termine;
begin
  perform public.slots_admin_pruefen('termin_absagen');
  perform public.slots_sperren();
  kt := public.slots_absage_intern(p_termin_id, p_eingang, v_jetzt, 'termin_absagen');
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', kt.id, 'zustand', kt.zustand, 'rechtzeitig', kt.zustand = 'cancelled');
end;
$$;

create function public.zusatztermin_buchen(p_student_id uuid, p_datum date, p_zeit_id uuid,
                                           p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vorher date[];
  v_id    uuid;
  v_aus   jsonb;
begin
  perform public.slots_admin_pruefen('zusatztermin_buchen');
  perform public.slots_sperren();
  perform public.slots_code_werfen(public.slots_zusatz_code(p_student_id, p_datum, p_zeit_id, v_jetzt),
                                   'zusatztermin_buchen');
  v_vorher := public.slots_beweglich(p_student_id, v_heute);
  insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, angelegt_von)
  values (p_student_id, public.slots_vertrag_am(p_student_id, p_datum), p_datum, p_zeit_id, 'zusatz', auth.uid())
  returning id into v_id;
  v_aus := public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('termin_id', v_id,
    'verdraengt', (select to_jsonb(coalesce(array_agg(d order by d), '{}')) from unnest(v_vorher) d
                    where d <> all (public.slots_beweglich(p_student_id, v_heute))),
    'ausgelassen', v_aus);
end;
$$;

-- Umbuchen = Absage plus Zusatztermin in einem Schritt (Anforderung G 42).
create function public.termin_umbuchen(p_termin_id uuid, p_eingang timestamptz, p_ziel_datum date, p_ziel_zeit_id uuid,
                                       p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  kt      public.kind_termine;
  v_vorher date[];
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('termin_umbuchen');
  perform public.slots_sperren();
  kt := public.slots_absage_intern(p_termin_id, p_eingang, v_jetzt, 'termin_umbuchen');
  perform public.slots_code_werfen(public.slots_zusatz_code(kt.student_id, p_ziel_datum, p_ziel_zeit_id, v_jetzt),
                                   'termin_umbuchen');
  v_vorher := public.slots_beweglich(kt.student_id, v_heute);
  insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, umgebucht_von, angelegt_von)
  values (kt.student_id, public.slots_vertrag_am(kt.student_id, p_ziel_datum), p_ziel_datum, p_ziel_zeit_id,
          'zusatz', kt.id, auth.uid())
  returning id into v_id;
  perform public.slots_festschreibung_nachziehen(p_ziel_datum, p_ziel_zeit_id);
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', v_id, 'alt_zustand', kt.zustand, 'rechtzeitig', kt.zustand = 'cancelled',
    'verdraengt', (select to_jsonb(coalesce(array_agg(d order by d), '{}')) from unnest(v_vorher) d
                    where d <> all (public.slots_beweglich(kt.student_id, v_heute))));
end;
$$;

-- Rücknahme bis zum Termin (Anforderung F 41, Abnahmefall 7). Gehörte die Absage zu einer Umbuchung,
-- fällt der neue Termin weg.
create function public.absage_zuruecknehmen(p_termin_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  kt      public.kind_termine;
  neu     public.kind_termine;
begin
  perform public.slots_admin_pruefen('absage_zuruecknehmen');
  perform public.slots_sperren();
  select * into kt from public.kind_termine where id = p_termin_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'absage_zuruecknehmen: Termin nicht gefunden');
  end if;
  if kt.absage_eingang is null or kt.zustand not in ('cancelled', 'unexcused')
     or public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) <= v_jetzt
     or exists (select 1 from public.coaching_sessions cs where cs.id = kt.session_id and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
  end if;

  select * into neu from public.kind_termine where umgebucht_von = kt.id for update;
  if found then
    if neu.zustand <> 'planned'
       or exists (select 1 from public.coaching_sessions cs where cs.id = neu.session_id and cs.gestartet_am is not null) then
      perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
    end if;
    if neu.session_id is not null then
      delete from public.session_students where session_id = neu.session_id and student_id = neu.student_id;
    end if;
    delete from public.kind_termine where id = neu.id;
  end if;

  -- Platz inzwischen vergeben oder schon ein anderer Termin an dem Tag: keine Rücknahme.
  if public.slot_belegt(kt.datum, kt.slot_zeit_id, kt.student_id) >= public.slot_kapazitaet(kt.datum, kt.slot_zeit_id)
     or exists (select 1 from public.kind_termine x
                 where x.student_id = kt.student_id and x.datum = kt.datum and x.id <> kt.id
                   and x.zustand in ('planned', 'present', 'unexcused')
                   and not (x.herkunft = 'stammplatz' and x.session_id is null)) then
    perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
  end if;
  -- Ein beweglicher Stammplatz-Termin, den die Planung inzwischen auf den Tag gelegt hat, weicht.
  delete from public.kind_termine x
   where x.student_id = kt.student_id and x.datum = kt.datum and x.id <> kt.id
     and x.herkunft = 'stammplatz' and x.zustand = 'planned' and x.session_id is null;

  update public.kind_termine
     set zustand = 'planned', absage_eingang = null, absage_erfasst_von = null, absage_erfasst_am = null
   where id = kt.id;
  perform public.slots_buchung_setzen(kt.id);
  perform public.slots_festschreibung_nachziehen(kt.datum, kt.slot_zeit_id);
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', kt.id, 'zustand', 'planned', 'umbuchung_entfernt', neu.id);
end;
$$;

-- ============================================================================
-- 3. Ausfall (Anforderung D 21, 23)
-- ============================================================================

create function public.termin_ausgefallen(p_termin_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  kt      public.kind_termine;
begin
  perform public.slots_admin_pruefen('termin_ausgefallen');
  perform public.slots_sperren();
  select * into kt from public.kind_termine where id = p_termin_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'termin_ausgefallen: Termin nicht gefunden');
  end if;
  if kt.datum < public.slots_berlin_tag(v_jetzt)
     or exists (select 1 from public.coaching_sessions cs where cs.id = kt.session_id and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL011', 'termin_ausgefallen');
  end if;
  if kt.zustand <> 'planned' then
    perform public.slots_fehler('22023', 'termin_ausgefallen: Termin ist nicht geplant', 'zustand:' || kt.zustand);
  end if;
  update public.kind_termine set zustand = 'cancelled_by_us' where id = kt.id;
  perform public.slots_buchung_setzen(kt.id);
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', kt.id, 'zustand', 'cancelled_by_us');
end;
$$;

-- Ganzer Termin fällt aus: alle geplanten Kinder "ausgefallen durch uns", Einheiten bleiben offen.
create function public.termin_faellt_aus(p_datum date, p_zeit_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_ids   uuid[];
  v_st    uuid;
begin
  perform public.slots_admin_pruefen('termin_faellt_aus');
  perform public.slots_sperren();
  if p_datum < public.slots_berlin_tag(v_jetzt)
     or exists (select 1 from public.coaching_sessions cs
                 where cs.slot_zeit_id = p_zeit_id and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_zeit_id)
                   and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL011', 'termin_faellt_aus');
  end if;
  with weg as (
    update public.kind_termine kt set zustand = 'cancelled_by_us'
     where kt.datum = p_datum and kt.slot_zeit_id = p_zeit_id and kt.zustand = 'planned'
    returning kt.id, kt.student_id
  )
  select array_agg(weg.id) into v_ids from weg;
  update public.session_students ss set attendance = 'cancelled_by_us'
    from public.kind_termine kt
   where kt.id = any (coalesce(v_ids, '{}')) and ss.session_id = kt.session_id and ss.student_id = kt.student_id;
  for v_st in select distinct kt.student_id from public.kind_termine kt where kt.id = any (coalesce(v_ids, '{}')) loop
    perform public.termine_planen(v_st, v_jetzt);
  end loop;
  return jsonb_build_object('betroffen', coalesce(cardinality(v_ids), 0));
end;
$$;

-- ============================================================================
-- 4. Raum und Coach je Termin (Anforderung D 19–20, H 49)
-- ============================================================================

create function public.termin_raum_setzen(p_termin_id uuid, p_raum_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  kt      public.kind_termine;
  v_ziel  public.coaching_sessions;
begin
  perform public.slots_admin_pruefen('termin_raum_setzen');
  perform public.slots_sperren();
  select * into kt from public.kind_termine where id = p_termin_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'termin_raum_setzen: Termin nicht gefunden');
  end if;
  if kt.datum < public.slots_berlin_tag(v_jetzt)
     or exists (select 1 from public.coaching_sessions cs where cs.id = kt.session_id and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL011', 'termin_raum_setzen');
  end if;
  if kt.zustand not in ('planned', 'present') then
    perform public.slots_fehler('22023', 'termin_raum_setzen: Termin ist nicht geplant', 'zustand:' || kt.zustand);
  end if;

  if p_raum_id is null then
    update public.kind_termine set raum_fest = false where id = kt.id;
  else
    if not exists (select 1 from public.slot_raeume(kt.datum, kt.datum) r
                    where r.slot_zeit_id = kt.slot_zeit_id and r.raum_id = p_raum_id and r.offen) then
      perform public.slots_code_werfen('SL002', 'termin_raum_setzen');
    end if;
    v_ziel := public.slots_session(kt.datum, kt.slot_zeit_id, p_raum_id);
    if v_ziel.gestartet_am is not null then
      perform public.slots_code_werfen('SL011', 'termin_raum_setzen');
    end if;
    if (select count(*) from public.slot_zuteilung(kt.datum, kt.slot_zeit_id) t
         where t.raum_id = p_raum_id and t.termin_id <> kt.id) >= 5 then
      perform public.slots_code_werfen('SL001', 'termin_raum_setzen');
    end if;
    -- Nach dem Festschreiben: Zeile in Session A löschen, in Session B anlegen (Entscheidung 14).
    if kt.session_id is not null and kt.session_id is distinct from v_ziel.id then
      delete from public.session_students where session_id = kt.session_id and student_id = kt.student_id;
      update public.kind_termine set session_id = null where id = kt.id;
    end if;
    update public.kind_termine set raum_id = p_raum_id, raum_fest = true where id = kt.id;
  end if;
  perform public.slots_festschreibung_nachziehen(kt.datum, kt.slot_zeit_id);
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', kt.id, 'raum_id', p_raum_id);
end;
$$;

-- Coach eines Raums nur für diesen Termin; NULL = fällt aus (Raum geschlossen).
create function public.termin_coach_setzen(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_coach_id uuid,
                                           p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_stamm uuid;
  v_sess  public.coaching_sessions;
  v_raum  public.raeume;
begin
  perform public.slots_admin_pruefen('termin_coach_setzen');
  perform public.slots_sperren();
  if p_datum < public.slots_berlin_tag(v_jetzt) then
    perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
  end if;
  select * into v_raum from public.raeume r
   where r.id = p_raum_id and r.aktiv_ab <= p_datum and (r.inaktiv_ab is null or p_datum < r.inaktiv_ab);
  if not found or not public.betriebstag(p_datum) or not public.slots_zeit_aktiv(p_zeit_id, p_datum) then
    perform public.slots_fehler('22023', 'termin_coach_setzen: Raum, Tag oder Uhrzeit nicht aktiv');
  end if;
  v_sess := public.slots_session(p_datum, p_zeit_id, p_raum_id);
  if v_sess.gestartet_am is not null then
    perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
  end if;
  if p_coach_id is not null then
    if not exists (select 1 from public.profiles p where p.id = p_coach_id and p.role = 'coach') then
      perform public.slots_fehler('22023', 'termin_coach_setzen: kein Coach', 'kein_coach');
    end if;
    if exists (select 1 from public.slot_raeume(p_datum, p_datum) r
                where r.slot_zeit_id = p_zeit_id and r.coach_id = p_coach_id and r.raum_id <> p_raum_id) then
      perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach)');
    end if;
  end if;

  select s.coach_id into v_stamm from public.stammschichten s
   where s.raum_id = p_raum_id and s.slot_zeit_id = p_zeit_id and s.wochentag = extract(isodow from p_datum)
     and s.gueltig_ab <= p_datum and (s.gueltig_bis is null or p_datum <= s.gueltig_bis)
   order by s.gueltig_ab desc limit 1;

  if p_coach_id is not distinct from v_stamm then
    delete from public.schicht_abweichungen where datum = p_datum and slot_zeit_id = p_zeit_id and raum_id = p_raum_id;
  else
    insert into public.schicht_abweichungen (datum, slot_zeit_id, raum_id, art, coach_id, erfasst_von)
    values (p_datum, p_zeit_id, p_raum_id,
            case when p_coach_id is null then 'faellt_aus' when v_stamm is null then 'zusatz' else 'vertretung' end,
            p_coach_id, auth.uid())
    on conflict (datum, slot_zeit_id, raum_id) do update
       set art = excluded.art, coach_id = excluded.coach_id, erfasst_von = excluded.erfasst_von, erfasst_am = now();
  end if;

  -- Nach dem Festschreiben (Entscheidung 14): coach_id nachziehen, bei "fällt aus" die Session löschen,
  -- solange sie keine Session-Daten hat; ihre Kinder gehen in die Zuteilung zurück.
  if v_sess.id is not null then
    if p_coach_id is not null then
      update public.coaching_sessions set coach_id = p_coach_id where id = v_sess.id;
    else
      begin
        update public.kind_termine set session_id = null where session_id = v_sess.id;
        delete from public.coaching_sessions where id = v_sess.id;
      exception when foreign_key_violation or restrict_violation then
        perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
      end;
    end if;
  end if;
  perform public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  perform public.slots_planen_slot(extract(isodow from p_datum)::int, p_zeit_id, v_jetzt);
  return jsonb_build_object('art', (select a.art from public.schicht_abweichungen a
                                     where a.datum = p_datum and a.slot_zeit_id = p_zeit_id and a.raum_id = p_raum_id));
end;
$$;

-- Raum zusätzlich öffnen (Anforderung D 23): Raum und Coach nur für diesen Termin.
create function public.termin_raum_oeffnen(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_coach_id uuid,
                                           p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  perform public.slots_admin_pruefen('termin_raum_oeffnen');
  perform public.slots_sperren();
  if p_coach_id is null then
    perform public.slots_fehler('22023', 'termin_raum_oeffnen: Coach fehlt');
  end if;
  if exists (select 1 from public.slot_raeume(p_datum, p_datum) r
              where r.slot_zeit_id = p_zeit_id and r.raum_id = p_raum_id and r.offen) then
    perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach)');
  end if;
  return public.termin_coach_setzen(p_datum, p_zeit_id, p_raum_id, p_coach_id, p_jetzt);
end;
$$;

-- ============================================================================
-- Rechte
-- ============================================================================

revoke all on function public.slots_session(date, uuid, uuid) from public, anon, authenticated;
revoke all on function public.slots_festschreibung_nachziehen(date, uuid) from public, anon, authenticated;
revoke all on function public.slots_buchung_setzen(uuid) from public, anon, authenticated;
revoke all on function public.slots_wochengrenze(uuid, date) from public, anon, authenticated;
revoke all on function public.slots_woche_aktiv(uuid, date, uuid) from public, anon, authenticated;
revoke all on function public.slots_fest_belegt(uuid, date, uuid) from public, anon, authenticated;
revoke all on function public.slots_zusatz_code(uuid, date, uuid, timestamptz, uuid) from public, anon, authenticated;
revoke all on function public.slots_code_werfen(text, text) from public, anon, authenticated;
revoke all on function public.slots_absage_intern(uuid, timestamptz, timestamptz, text) from public, anon, authenticated;
revoke all on function public.slots_beweglich(uuid, date) from public, anon, authenticated;

revoke all on function public.termin_absagen(uuid, timestamptz, timestamptz) from public, anon;
revoke all on function public.zusatztermin_buchen(uuid, date, uuid, timestamptz) from public, anon;
revoke all on function public.termin_umbuchen(uuid, timestamptz, date, uuid, timestamptz) from public, anon;
revoke all on function public.absage_zuruecknehmen(uuid, timestamptz) from public, anon;
revoke all on function public.termin_ausgefallen(uuid, timestamptz) from public, anon;
revoke all on function public.termin_faellt_aus(date, uuid, timestamptz) from public, anon;
revoke all on function public.termin_raum_setzen(uuid, uuid, timestamptz) from public, anon;
revoke all on function public.termin_coach_setzen(date, uuid, uuid, uuid, timestamptz) from public, anon;
revoke all on function public.termin_raum_oeffnen(date, uuid, uuid, uuid, timestamptz) from public, anon;

grant execute on function public.termin_absagen(uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.zusatztermin_buchen(uuid, date, uuid, timestamptz) to authenticated;
grant execute on function public.termin_umbuchen(uuid, timestamptz, date, uuid, timestamptz) to authenticated;
grant execute on function public.absage_zuruecknehmen(uuid, timestamptz) to authenticated;
grant execute on function public.termin_ausgefallen(uuid, timestamptz) to authenticated;
grant execute on function public.termin_faellt_aus(date, uuid, timestamptz) to authenticated;
grant execute on function public.termin_raum_setzen(uuid, uuid, timestamptz) to authenticated;
grant execute on function public.termin_coach_setzen(date, uuid, uuid, uuid, timestamptz) to authenticated;
grant execute on function public.termin_raum_oeffnen(date, uuid, uuid, uuid, timestamptz) to authenticated;

commit;
