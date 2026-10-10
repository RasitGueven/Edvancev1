-- Slots SL1, Teil 2: Planung.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 11, 12, 17, 18, 21, 22.
--
-- Inhalt:
--   1. Hilfen: Zeit (Berlin, p_jetzt), Rechte, Sperre, Planungsgrenze, Toleranz, A-/B-Woche, Vertrag
--   2. slots_plan_rechnen   — Kandidaten-Termine eines Vertrags und was aus ihnen wird
--   3. termine_planen       — Abgleich der gespeicherten Termine mit dem Plan (Entscheidung 11)
--   4. slots_planbilanz     — Planbilanz, gerechnet, nicht gespeichert (Entscheidung 12)
--   5. Trigger auf vertraege — Widerruf, Kündigung, Abschluss (Entscheidung 22)
--
-- Die Kapazität (slot_kapazitaet, slot_belegt) kommt aus Teil 3. PL/pgSQL bindet erst beim Aufruf.
-- Alle Funktionen hier sind intern: kein EXECUTE für anon und authenticated.

begin;

-- ============================================================================
-- 1. Hilfen
-- ============================================================================

-- Entscheidung 8: Testkonten kommen in den Slots nicht vor. Die eine Stelle, die das entscheidet.
create function public.slots_kind_zugelassen(p_student_id uuid)
returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce((select not s.ist_test from public.students s where s.id = p_student_id), false);
$$;

-- Entscheidung 17: p_jetzt nur für Admin und Systemaufruf, sonst immer now().
create function public.slots_jetzt(p_jetzt timestamptz)
returns timestamptz
language sql stable security definer
set search_path = public, pg_temp
as $$
  select case when public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin'
              then coalesce(p_jetzt, now()) else now() end;
$$;

create function public.slots_berlin_tag(p_zeit timestamptz)
returns date
language sql immutable
as $$
  select (p_zeit at time zone 'Europe/Berlin')::date;
$$;

-- Beginn eines Termins als Zeitpunkt: Datum und Uhrzeit sind Berliner Ortszeit.
create function public.slots_termin_beginn(p_datum date, p_slot_zeit_id uuid)
returns timestamptz
language sql stable security definer
set search_path = public, pg_temp
as $$
  select ((p_datum + z.beginn)::timestamp at time zone 'Europe/Berlin')
    from public.slot_zeiten z where z.id = p_slot_zeit_id;
$$;

create function public.slots_admin_pruefen(p_wer text)
returns void
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  if not public.ist_systemaufruf() and coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception '%: nur Admin', p_wer using errcode = '42501';
  end if;
end;
$$;

-- Entscheidung 16: jede schreibende Slot-Funktion nimmt zuerst diese Sperre.
create function public.slots_sperren()
returns void
language sql volatile
as $$
  select pg_advisory_xact_lock(hashtext('slots'));
$$;

-- Entscheidung 21: geplant wird höchstens bis zum Ende der Ferientabelle.
create function public.slots_planungsgrenze()
returns date
language sql stable security definer
set search_path = public, pg_temp
as $$
  select max(f.bis) from public.ferien_nrw f;
$$;

-- Entscheidung 4: Toleranz der Planbilanz, Stellschraube (wirkt sofort).
create function public.slots_toleranz()
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce((select (e.wert #>> '{}')::integer from public.session_einstellungen e
                    where e.schluessel = 'slots_planbilanz_toleranz'), 2);
$$;

-- Entscheidung 18: ISO-Kalenderwoche, ungerade = A-Woche.
create function public.slots_takt_passt(p_takt text, p_datum date)
returns boolean
language sql immutable
as $$
  select case p_takt
           when 'woechentlich' then true
           when 'a_woche' then extract(week from p_datum)::int % 2 = 1
           when 'b_woche' then extract(week from p_datum)::int % 2 = 0
           else false
         end;
$$;

create function public.slots_zeit_aktiv(p_slot_zeit_id uuid, p_datum date)
returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.slot_zeiten z
                  where z.id = p_slot_zeit_id and z.aktiv_ab <= p_datum
                    and (z.inaktiv_ab is null or p_datum < z.inaktiv_ab));
$$;

-- Letzter Tag, an dem aus einem Vertrag Termine entstehen (Entscheidung 22):
-- Widerruf -> Vortag des Widerrufs, Kündigung -> Vortag von gekuendigt_zum, sonst der Stichtag.
create function public.slots_vertrag_planende(p_vertrag_id uuid)
returns date
language sql stable security definer
set search_path = public, pg_temp
as $$
  select case when v.widerrufen_am is not null then v.widerrufen_am - 1
              else least(v.vertrag_ende, v.gekuendigt_zum - 1) end
    from public.vertraege v where v.id = p_vertrag_id;
$$;

-- Laufender Vertrag am Tag p_heute, sonst der mit dem nächsten Beginn (Schülerakte, Entscheidung 3).
create function public.slots_vertrag(p_student_id uuid, p_heute date)
returns uuid
language sql stable security definer
set search_path = public, pg_temp
as $$
  select v.id
    from public.vertraege v
   where v.student_id = p_student_id
     and v.status = 'abgeschlossen'
     and v.einheiten is not null and v.vertragsbeginn is not null and v.vertrag_ende is not null
     and v.vertrag_ende >= p_heute
     and public.vertrag_wirksamer_status(v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_heute)
         in ('aktiv', 'im_widerruf')
   order by (v.vertragsbeginn <= p_heute) desc, v.vertragsbeginn
   limit 1;
$$;

-- Vertrag, aus dem an p_datum ein Termin entstehen darf (Zeitraum bis Planende).
create function public.slots_vertrag_am(p_student_id uuid, p_datum date)
returns uuid
language sql stable security definer
set search_path = public, pg_temp
as $$
  select v.id
    from public.vertraege v
   where v.student_id = p_student_id
     and v.status = 'abgeschlossen'
     and v.einheiten is not null and v.vertragsbeginn is not null and v.vertrag_ende is not null
     and p_datum between v.vertragsbeginn and public.slots_vertrag_planende(v.id)
   order by v.vertragsbeginn desc
   limit 1;
$$;

-- Buchungen in session_students ohne Kind-Termin (Einzel-Sessions, Übergang nach Entscheidung 9),
-- ohne Testläufe. Zählen für Budget, Tagessperre, Wochengrenze und Verbrauch.
create function public.slots_einzelbuchungen(p_student_id uuid)
returns table(session_id uuid, datum date, beginn timestamptz, attendance text)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select cs.id, public.slots_berlin_tag(cs.scheduled_at), cs.scheduled_at, ss.attendance
    from public.session_students ss
    join public.coaching_sessions cs on cs.id = ss.session_id
   where ss.student_id = p_student_id
     and not cs.testlauf
     and not exists (select 1 from public.kind_termine kt
                      where kt.session_id = ss.session_id and kt.student_id = ss.student_id);
$$;

-- ============================================================================
-- 2. slots_plan_rechnen
-- ============================================================================
--
-- Geht die Stammplatz-Termine eines Vertrags von max(Beginn, heute) bis zum Planende in zeitlicher
-- Reihenfolge durch (Entscheidung 11). Ergebnis je Datum:
--   vorhanden     — beweglicher Termin existiert schon und bekommt Budget (Zeile, id, Raum-Stift bleiben)
--   neu           — bekommt Budget und hat einen freien Platz
--   uebersprungen — hätte Budget, aber der Slot ist voll oder hat keinen geöffneten Raum
--   ohne_budget   — kein Budget mehr (zählt als U in der Planbilanz)
-- Beweglich = künftig (ab heute), Herkunft Stammplatz, Zustand planned, ohne Session. Alles andere ist fest:
-- feste Zeilen in planned/present/unexcused und Einzelbuchungen belegen zuerst eine Einheit; jede feste
-- Zeile sperrt ihren Tag. Hinter der Planungsgrenze wird nicht gerechnet (SL012 in der Planbilanz).
--
-- p_stammplaetze: NULL = die gespeicherten Stammplätze des Vertrags. Sonst jsonb-Array von Objekten
-- {stammplatz_id?, wochentag, slot_zeit_id, takt, gueltig_ab, gueltig_bis?} (Vorschau, Entscheidung 16).

create function public.slots_plan_rechnen(p_vertrag_id uuid, p_heute date, p_stammplaetze jsonb default null)
returns table(datum date, slot_zeit_id uuid, stammplatz_id uuid, ergebnis text)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v       public.vertraege;
  v_ende  date;
  v_bis   date;
  v_von   date;
  v_rest  integer;
  c       record;
  v_tag   date := null;
begin
  select * into v from public.vertraege where id = p_vertrag_id;
  if not found or v.einheiten is null or v.vertragsbeginn is null or v.vertrag_ende is null then
    return;
  end if;
  v_ende := public.slots_vertrag_planende(v.id);
  v_bis  := least(v_ende, public.slots_planungsgrenze());
  v_von  := greatest(v.vertragsbeginn, p_heute);

  v_rest := v.einheiten
    - (select count(*)::int from public.kind_termine kt
        where kt.vertrag_id = v.id
          and kt.zustand in ('planned', 'present', 'unexcused')
          and not (kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                   and kt.datum >= p_heute))
    - (select count(*)::int from public.slots_einzelbuchungen(v.student_id) e
        where e.datum between v.vertragsbeginn and v.vertrag_ende
          and e.attendance in ('planned', 'present', 'unexcused'));

  for c in
    with sp as (
      select s.id, s.wochentag, s.slot_zeit_id, s.takt, s.gueltig_ab, s.gueltig_bis
        from public.stammplaetze s
       where p_stammplaetze is null and s.vertrag_id = v.id
      union all
      select (x ->> 'stammplatz_id')::uuid, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid,
             x ->> 'takt', (x ->> 'gueltig_ab')::date, (x ->> 'gueltig_bis')::date
        from jsonb_array_elements(coalesce(p_stammplaetze, '[]'::jsonb)) x
    ),
    gesperrt as (
      select kt.datum from public.kind_termine kt
       where kt.student_id = v.student_id
         and not (kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                  and kt.datum >= p_heute)
      union
      select e.datum from public.slots_einzelbuchungen(v.student_id) e
       where e.attendance in ('planned', 'present', 'unexcused')
    ),
    kand as (
      select g::date as d, sp.slot_zeit_id as z, sp.id as sp_id, z.beginn
        from sp
        join public.slot_zeiten z on z.id = sp.slot_zeit_id
        cross join lateral generate_series(greatest(v_von, sp.gueltig_ab),
                                           least(v_bis, coalesce(sp.gueltig_bis, v_bis)), interval '1 day') g
       where extract(isodow from g) = sp.wochentag
         and public.slots_takt_passt(sp.takt, g::date)
         and public.betriebstag(g::date)
         and public.slots_zeit_aktiv(sp.slot_zeit_id, g::date)
         and g::date not in (select gesperrt.datum from gesperrt)
    )
    select k.d, k.z, k.sp_id,
           exists (select 1 from public.kind_termine kt
                    where kt.student_id = v.student_id and kt.datum = k.d and kt.slot_zeit_id = k.z
                      and kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                      and kt.datum >= p_heute) as da
      from kand k
     order by k.d, k.beginn
  loop
    continue when c.d = v_tag;          -- höchstens ein Termin pro Tag
    v_tag := c.d;
    datum := c.d; slot_zeit_id := c.z; stammplatz_id := c.sp_id;
    if v_rest <= 0 then
      ergebnis := 'ohne_budget';
    elsif c.da then
      ergebnis := 'vorhanden'; v_rest := v_rest - 1;
    elsif public.slot_kapazitaet(c.d, c.z) - public.slot_belegt(c.d, c.z, v.student_id) > 0 then
      ergebnis := 'neu'; v_rest := v_rest - 1;
    else
      ergebnis := 'uebersprungen';
    end if;
    return next;
  end loop;
end;
$$;

-- ============================================================================
-- 3. termine_planen (Entscheidung 11)
-- ============================================================================

create function public.termine_planen(p_student_id uuid, p_jetzt timestamptz default now())
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v       record;
begin
  perform public.slots_sperren();
  if not public.slots_kind_zugelassen(p_student_id) then
    return;
  end if;

  for v in
    select x.id, public.slots_vertrag_planende(x.id) as ende
      from public.vertraege x
     where x.student_id = p_student_id and x.status = 'abgeschlossen'
       and x.vertrag_ende is not null and x.vertrag_ende >= v_heute
  loop
    -- Künftige Termine hinter dem Planende (Widerruf, Kündigung): geplante ohne Session fallen weg,
    -- festgeschriebene werden "ausgefallen durch uns" (Entscheidung 22).
    delete from public.kind_termine kt
     where kt.vertrag_id = v.id and kt.datum >= v_heute and kt.datum > v.ende
       and kt.zustand = 'planned' and kt.session_id is null;
    with weg as (
      update public.kind_termine kt set zustand = 'cancelled_by_us'
       where kt.vertrag_id = v.id and kt.datum >= v_heute and kt.datum > v.ende
         and kt.zustand = 'planned' and kt.session_id is not null
      returning kt.session_id, kt.student_id
    )
    update public.session_students ss set attendance = 'cancelled_by_us'
      from weg where ss.session_id = weg.session_id and ss.student_id = weg.student_id;

    if to_regclass('pg_temp.slots_plan_tmp') is null then
      create temp table slots_plan_tmp (datum date, slot_zeit_id uuid, stammplatz_id uuid, ergebnis text) on commit drop;
    end if;
    truncate slots_plan_tmp;
    insert into slots_plan_tmp select * from public.slots_plan_rechnen(v.id, v_heute)
     where ergebnis in ('vorhanden', 'neu');

    -- Bewegliche Zeilen ohne Platz im Plan fallen weg; die übrigen behalten id und Raum-Stift.
    delete from public.kind_termine kt
     where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
       and kt.session_id is null and kt.datum >= v_heute
       and not exists (select 1 from slots_plan_tmp p where p.datum = kt.datum and p.slot_zeit_id = kt.slot_zeit_id);
    update public.kind_termine kt set stammplatz_id = p.stammplatz_id
      from slots_plan_tmp p
     where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
       and kt.session_id is null and kt.datum = p.datum and kt.slot_zeit_id = p.slot_zeit_id
       and kt.stammplatz_id is distinct from p.stammplatz_id;
    insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, stammplatz_id, angelegt_von)
    select p_student_id, v.id, p.datum, p.slot_zeit_id, 'stammplatz', p.stammplatz_id, auth.uid()
      from slots_plan_tmp p where p.ergebnis = 'neu';
  end loop;
end;
$$;

-- ============================================================================
-- 4. slots_planbilanz (Entscheidung 12)
-- ============================================================================
--
-- E Einheiten, V verbraucht, G geplant (auch vergangene ohne Anwesenheit), O = E - V - G,
-- U Stammplatz-Termine bis zum Stichtag ohne Budget, terminzahl = gespeicherte Stammplatz-Termine + U.
-- Art in dieser Reihenfolge: kein_stammplatz, aufgebraucht, reicht_bis, ohne_termin, passt.

create function public.slots_planbilanz(p_vertrag_id uuid, p_heute date, p_stammplaetze jsonb default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v        public.vertraege;
  v_tol    integer := public.slots_toleranz();
  v_grenze date := public.slots_planungsgrenze();
  v_v      integer;  v_g integer;  v_o integer;  v_u integer;
  v_zahl   integer;  v_letzter date;  v_kuenftig boolean;  v_stamm boolean;
  v_ueber  jsonb;    v_art text;  v_abw jsonb := null;  v_plan jsonb;
begin
  select * into v from public.vertraege where id = p_vertrag_id;
  if not found then
    return null;
  end if;

  -- Einmal rechnen, als jsonb festhalten (STABLE: keine temporäre Tabelle).
  select coalesce(jsonb_agg(to_jsonb(r)), '[]') into v_plan
    from public.slots_plan_rechnen(v.id, p_heute, p_stammplaetze) r;

  -- Feste Zeilen und Einzelbuchungen des Vertrags; gewählte Plan-Termine kommen dazu.
  with plan as (
    select * from jsonb_to_recordset(v_plan) as x(datum date, slot_zeit_id uuid, stammplatz_id uuid, ergebnis text)
  ),
  fest as (
    select kt.datum, kt.zustand, kt.herkunft from public.kind_termine kt
     where kt.vertrag_id = v.id
       and not (kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                and kt.datum >= p_heute)
    union all
    select e.datum, e.attendance, 'einzel' from public.slots_einzelbuchungen(v.student_id) e
     where e.datum between v.vertragsbeginn and v.vertrag_ende
    union all
    select p.datum, 'planned', 'stammplatz' from plan p where p.ergebnis in ('vorhanden', 'neu')
  )
  select count(*) filter (where public.einheit_verbraucht(f.zustand)),
         count(*) filter (where f.zustand = 'planned'),
         count(*) filter (where f.herkunft = 'stammplatz'),
         max(f.datum) filter (where f.zustand in ('planned', 'present', 'unexcused')),
         coalesce(bool_or(f.zustand = 'planned' and f.datum >= p_heute), false),
         (select count(*) from plan p where p.ergebnis = 'ohne_budget'),
         (select coalesce(jsonb_agg(p.datum order by p.datum), '[]') from plan p where p.ergebnis = 'uebersprungen')
    into v_v, v_g, v_zahl, v_letzter, v_kuenftig, v_u, v_ueber
    from fest f;

  v_zahl := v_zahl + v_u;
  v_o := v.einheiten - v_v - v_g;

  if p_stammplaetze is null then
    select exists (select 1 from public.stammplaetze s
                    where s.vertrag_id = v.id
                      and coalesce(s.gueltig_bis, 'infinity'::date) >= greatest(p_heute, s.gueltig_ab))
      into v_stamm;
  else
    select exists (select 1 from jsonb_array_elements(p_stammplaetze) x
                    where coalesce((x ->> 'gueltig_bis')::date, 'infinity'::date)
                          >= greatest(p_heute, (x ->> 'gueltig_ab')::date))
      into v_stamm;
  end if;

  v_art := case
    when v_o > 0 and not v_stamm then 'kein_stammplatz'
    when not v_kuenftig and v_o <= 0 then 'aufgebraucht'
    when v_u > v_tol then 'reicht_bis'
    when v_o > v_tol then 'ohne_termin'
    else 'passt'
  end;
  if v_art = 'passt' and v_u between 1 and v_tol then
    v_abw := jsonb_build_object('art', 'ohne_einheit', 'zahl', v_u);
  elsif v_art = 'passt' and v_o between 1 and v_tol then
    v_abw := jsonb_build_object('art', 'ohne_termin', 'zahl', v_o);
  end if;

  return jsonb_build_object(
    'art', v_art,
    'einheiten', v.einheiten, 'verbraucht', v_v, 'geplant', v_g, 'ohne_termin', v_o, 'ohne_einheit', v_u,
    'terminzahl', v_zahl, 'letzter_termin', v_letzter,
    'datum', case when v_art = 'reicht_bis' then v_letzter end,
    'zahl', case v_art when 'ohne_termin' then v_o when 'reicht_bis' then v_u end,
    'abweichung', v_abw,
    'uebersprungen', v_ueber,
    'jenseits_ferientabelle', v.vertrag_ende > v_grenze,
    'hinweis', case when v.vertrag_ende > v_grenze then 'SL012' end,
    'toleranz', v_tol);
end;
$$;

-- ============================================================================
-- 5. Trigger auf vertraege (Entscheidung 22)
-- ============================================================================
--
-- Widerruf: Stammplätze enden am Widerrufstag. Kündigung: am Tag vor gekuendigt_zum. Danach gleicht
-- termine_planen ab (künftige geplante Termine fallen weg, festgeschriebene werden cancelled_by_us).
-- Auch beim Abschluss, damit ein Folgevertrag sofort im Plan steht.

create function public.slots_vertrag_geaendert()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_ende date;
begin
  if new.student_id is null then
    return null;
  end if;
  if new.widerrufen_am is not null then
    v_ende := new.widerrufen_am;
  elsif new.gekuendigt_zum is not null then
    v_ende := new.gekuendigt_zum - 1;
  end if;
  if v_ende is not null then
    update public.stammplaetze s
       set gueltig_bis = greatest(s.gueltig_ab - 1, v_ende),
           beendet_am = coalesce(s.beendet_am, now()), beendet_von = coalesce(s.beendet_von, auth.uid())
     where s.vertrag_id = new.id
       and coalesce(s.gueltig_bis, 'infinity'::date) > v_ende;
  end if;
  perform public.termine_planen(new.student_id);
  return null;
end;
$$;

create trigger vertraege_slots_trg
  after update of status, widerrufen_am, gekuendigt_zum, vertrag_ende, vertragsbeginn, einheiten
  on public.vertraege
  for each row execute function public.slots_vertrag_geaendert();

-- ============================================================================
-- Rechte: alles intern
-- ============================================================================

revoke all on function public.slots_kind_zugelassen(uuid) from public, anon, authenticated;
revoke all on function public.slots_jetzt(timestamptz) from public, anon, authenticated;
revoke all on function public.slots_berlin_tag(timestamptz) from public, anon, authenticated;
revoke all on function public.slots_termin_beginn(date, uuid) from public, anon, authenticated;
revoke all on function public.slots_admin_pruefen(text) from public, anon, authenticated;
revoke all on function public.slots_sperren() from public, anon, authenticated;
revoke all on function public.slots_planungsgrenze() from public, anon, authenticated;
revoke all on function public.slots_toleranz() from public, anon, authenticated;
revoke all on function public.slots_takt_passt(text, date) from public, anon, authenticated;
revoke all on function public.slots_zeit_aktiv(uuid, date) from public, anon, authenticated;
revoke all on function public.slots_vertrag_planende(uuid) from public, anon, authenticated;
revoke all on function public.slots_vertrag(uuid, date) from public, anon, authenticated;
revoke all on function public.slots_vertrag_am(uuid, date) from public, anon, authenticated;
revoke all on function public.slots_einzelbuchungen(uuid) from public, anon, authenticated;
revoke all on function public.slots_plan_rechnen(uuid, date, jsonb) from public, anon, authenticated;
revoke all on function public.termine_planen(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.slots_planbilanz(uuid, date, jsonb) from public, anon, authenticated;
revoke all on function public.slots_vertrag_geaendert() from public, anon, authenticated;

commit;
