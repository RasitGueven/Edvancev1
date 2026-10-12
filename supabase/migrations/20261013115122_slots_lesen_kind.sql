-- Slots SL1, Teil 5b: Lesefunktionen Kinder, Kind, freie Plätze, Vorschau, Ziele, Kandidaten.
--
-- Bauauftrag Slots (Fassung 1), Datenvertrag; vollständig beschrieben in docs/api/DATENVERTRAG.md,
-- Abschnitt 10. Nur Admin (oder Systemaufruf), sonst 42501. Was gebucht werden darf, entscheidet
-- dieselbe Prüfung wie beim Speichern (slots_zusatz_code, slots_stammplatz_gruende).

begin;

-- ============================================================================
-- Hilfen
-- ============================================================================

create function public.slots_stammplatz_json(p_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object('id', s.id, 'wochentag', s.wochentag, 'zeit_id', s.slot_zeit_id,
                            'beginn', public.slots_hhmm(z.beginn), 'takt', s.takt,
                            'gueltig_ab', s.gueltig_ab, 'gueltig_bis', s.gueltig_bis, 'vorgaenger_id', s.vorgaenger_id)
    from public.stammplaetze s join public.slot_zeiten z on z.id = s.slot_zeit_id
   where s.id = p_id;
$$;

-- Vertragsauszug und Rhythmus (Anforderung J 58–59, nur Ansicht).
create function public.slots_vertrag_json(p_vertrag_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
           'vertrag_id', v.id, 'paket', t.name, 'laufzeit_monate', v.laufzeit_monate, 'einheiten', v.einheiten,
           'beginn', v.vertragsbeginn, 'stichtag', v.vertrag_ende, 'gekuendigt_zum', v.gekuendigt_zum,
           'rhythmus', (select jsonb_build_object('woechentlich', r.woechentlich, 'vierzehntaeglich', r.vierzehntaeglich)
                          from public.slot_rhythmus r where r.tier_id = v.tier_id and r.laufzeit_monate = v.laufzeit_monate))
    from public.vertraege v left join public.tiers t on t.id = v.tier_id
   where v.id = p_vertrag_id;
$$;

-- Aktive Stammplätze eines Vertrags ab heute (inkl. künftiger).
create function public.slots_stammplaetze_aktiv(p_vertrag_id uuid, p_heute date)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(public.slots_stammplatz_json(s.id) order by s.wochentag, z.beginn), '[]')
    from public.stammplaetze s join public.slot_zeiten z on z.id = s.slot_zeit_id
   where s.vertrag_id = p_vertrag_id
     and least(coalesce(s.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(p_vertrag_id))
         >= greatest(p_heute, s.gueltig_ab);
$$;

-- Bewegliche Termine ab heute und Einheiten ohne Termin: offen = E - feste Belegung - bewegliche.
create function public.slots_offen(p_vertrag_id uuid, p_heute date, p_ausser uuid default null)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  select v.einheiten - public.slots_fest_belegt(v.id, p_heute, p_ausser)
         - (select count(*)::int from public.kind_termine kt
             where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
               and kt.session_id is null and kt.datum >= p_heute and kt.id is distinct from p_ausser)
    from public.vertraege v where v.id = p_vertrag_id;
$$;

-- Datum, das ein weiterer Termin verdrängen würde (Anforderung G 45): der letzte bewegliche
-- Stammplatz-Termin, wenn keine Einheit ohne Termin mehr da ist. p_ausser: wird rechtzeitig abgesagt
-- (zählt nicht). p_alt: wird zu spät abgesagt (belegt weiter, kann aber nicht selbst verdrängt werden).
create function public.slots_verdraengt(p_vertrag_id uuid, p_heute date, p_ausser uuid default null,
                                        p_alt uuid default null)
returns date
language sql stable security definer
set search_path = public, pg_temp
as $$
  select case when public.slots_offen(p_vertrag_id, p_heute, p_ausser) < 1 then
           (select max(kt.datum) from public.kind_termine kt
             where kt.vertrag_id = p_vertrag_id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
               and kt.session_id is null and kt.datum >= p_heute
               and kt.id is distinct from coalesce(p_ausser, p_alt)) end;
$$;

-- ============================================================================
-- slots_kinder()
-- ============================================================================

create function public.slots_kinder(p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
begin
  perform public.slots_admin_pruefen('slots_kinder');
  return coalesce((
    select jsonb_agg(x.j order by x.name)
      from (
        select k ->> 'name' as name,
               k || public.slots_vertrag_json(b.vertrag_id) || jsonb_build_object(
                 'vertrag_id', b.vertrag_id, 'vertrag_laeuft', b.laeuft, 'ohne_stammplatz', b.ohne_stammplatz,
                 'stammplaetze', public.slots_stammplaetze_aktiv(b.vertrag_id, v_heute),
                 'verbraucht', pb -> 'verbraucht', 'geplant', pb -> 'geplant',
                 'planbilanz', pb - 'uebersprungen',
                 'folgevertrag_ab', (select min(f.vertragsbeginn) from public.vertraege f
                                      where f.student_id = b.student_id and f.status = 'abgeschlossen'
                                        and f.widerrufen_am is null and f.vertragsbeginn > b.stichtag),
                 'weiterfuehren', public.slots_weiterfuehren_vorschlag(b.student_id, v_heute)) as j
          from public.slots_kinder_basis(v_heute) b
          cross join lateral public.slots_kind_info(b.student_id, b.vertrag_id) k
          cross join lateral public.slots_planbilanz(b.vertrag_id, v_heute) pb
      ) x), '[]');
end;
$$;

-- ============================================================================
-- slots_kind(p_student_id)
-- ============================================================================

create function public.slots_kind(p_student_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt   timestamptz := public.slots_jetzt(p_jetzt);
  v_heute   date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vertrag uuid;
  v_pb      jsonb;
begin
  perform public.slots_admin_pruefen('slots_kind');
  if not exists (select 1 from public.students s where s.id = p_student_id) then
    perform public.slots_fehler('P0002', 'slots_kind: Kind nicht gefunden');
  end if;
  v_vertrag := public.slots_vertrag(p_student_id, v_heute);
  v_pb := case when v_vertrag is not null then public.slots_planbilanz(v_vertrag, v_heute) end;

  return jsonb_build_object(
    'kind', public.slots_kind_info(p_student_id, coalesce(v_vertrag, (
              select v.id from public.vertraege v where v.student_id = p_student_id and v.status = 'abgeschlossen'
               order by v.vertragsbeginn desc nulls last limit 1))),
    'zugelassen', public.slots_kind_zugelassen(p_student_id),
    'vertrag', public.slots_vertrag_json(v_vertrag),
    'vertrag_laeuft', (select v.vertragsbeginn <= v_heute from public.vertraege v where v.id = v_vertrag),
    'stammplaetze', public.slots_stammplaetze_aktiv(v_vertrag, v_heute),
    'fruehere_stammplaetze', coalesce((
      select jsonb_agg(public.slots_stammplatz_json(s.id) order by s.gueltig_ab desc, s.wochentag)
        from public.stammplaetze s
       where s.student_id = p_student_id
         and least(coalesce(s.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(s.vertrag_id))
             < greatest(v_heute, s.gueltig_ab)
         and s.gueltig_bis is distinct from s.gueltig_ab - 1), '[]'),
    'naechste', coalesce((
      select jsonb_agg(jsonb_build_object(
               'termin_id', kt.id, 'datum', kt.datum, 'zeit_id', kt.slot_zeit_id, 'beginn', public.slots_hhmm(z.beginn),
               'ende', public.slots_hhmm(z.ende), 'zustand', kt.zustand, 'herkunft', kt.herkunft,
               'umgebucht_von', (select a.datum from public.kind_termine a where a.id = kt.umgebucht_von),
               'absage_eingang', kt.absage_eingang, 'festgeschrieben', kt.session_id is not null)
             order by kt.datum, z.beginn)
        from public.kind_termine kt join public.slot_zeiten z on z.id = kt.slot_zeit_id
       where kt.student_id = p_student_id and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > v_jetzt), '[]'),
    'letzte', coalesce((
      select jsonb_agg(x.j order by x.t desc) from (
        select public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) as t, jsonb_build_object(
                 'termin_id', kt.id, 'datum', kt.datum, 'beginn', public.slots_hhmm(z.beginn), 'zustand', kt.zustand,
                 'herkunft', kt.herkunft, 'session_id', kt.session_id) as j
          from public.kind_termine kt join public.slot_zeiten z on z.id = kt.slot_zeit_id
         where kt.student_id = p_student_id and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) <= v_jetzt
        union all
        select e.beginn, jsonb_build_object('termin_id', null, 'datum', e.datum,
                 'beginn', to_char(e.beginn at time zone 'Europe/Berlin', 'HH24:MI'), 'zustand', e.attendance,
                 'herkunft', 'einzel', 'session_id', e.session_id)
          from public.slots_einzelbuchungen(p_student_id) e where e.beginn <= v_jetzt
      ) x), '[]'),
    'einheiten', case when v_pb is not null then jsonb_build_object(
                   'gesamt', v_pb -> 'einheiten', 'verbraucht', v_pb -> 'verbraucht', 'geplant', v_pb -> 'geplant') end,
    'planbilanz', v_pb,
    'weiterfuehren', public.slots_weiterfuehren_vorschlag(p_student_id, v_heute));
end;
$$;

-- ============================================================================
-- slots_frei(p_takt, p_ab) — Raster freier Plätze für den Stammplatz-Dialog
-- ============================================================================

create function public.slots_frei(p_takt text, p_ab date, p_student_id uuid default null,
                                  p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
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
               'voll', f.kap_min > 0 and f.frei <= 0, 'termine', f.n)
             order by w, z.beginn)
        from generate_series(1, 5) w
        cross join public.slot_zeiten z
        cross join lateral (
          select min(x.kapazitaet - x.belegt) as frei, min(x.kapazitaet) as kap_min, count(*) as n
            from public.slots_naechste_termine_frei(w, z.id, p_takt, v_ab, p_student_id) x
        ) f
       where public.slots_zeit_aktiv(z.id, v_ab)), '[]'));
end;
$$;

-- ============================================================================
-- slots_planbilanz_vorschau(p_student_id, p_zeilen, p_ab) — ohne zu speichern
-- ============================================================================
--
-- p_zeilen: die Stammplätze ab p_ab ([{wochentag, slot_zeit_id, takt}]). p_ersetzt: Stammplätze, die
-- mit p_ab enden (Ändern); NULL = alle, die an p_ab noch gelten (Vergeben/Weiterführen ersetzen nichts,
-- weil es dann keine gibt).

create function public.slots_planbilanz_vorschau(p_student_id uuid, p_zeilen jsonb, p_ab date,
                                                 p_ersetzt uuid[] default null, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_heute   date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vertrag uuid := coalesce(public.slots_vertrag_am(p_student_id, p_ab), public.slots_vertrag(p_student_id, v_heute));
  v_ersetzt uuid[];
  v_sp      jsonb;
  v_pb      jsonb;
begin
  perform public.slots_admin_pruefen('slots_planbilanz_vorschau');
  select coalesce(p_ersetzt, array_agg(s.id)) into v_ersetzt
    from public.stammplaetze s
   where s.vertrag_id = v_vertrag
     and least(coalesce(s.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(v_vertrag)) >= p_ab;

  select coalesce(jsonb_agg(jsonb_build_object(
           'stammplatz_id', s.id, 'wochentag', s.wochentag, 'slot_zeit_id', s.slot_zeit_id, 'takt', s.takt,
           'gueltig_ab', s.gueltig_ab,
           'gueltig_bis', case when s.id = any (coalesce(v_ersetzt, '{}'))
                               then greatest(s.gueltig_ab - 1, p_ab - 1) else s.gueltig_bis end)), '[]')
    into v_sp
    from public.stammplaetze s where s.vertrag_id = v_vertrag;
  select v_sp || coalesce(jsonb_agg(jsonb_build_object(
           'stammplatz_id', null, 'wochentag', (x ->> 'wochentag')::int, 'slot_zeit_id', x ->> 'slot_zeit_id',
           'takt', x ->> 'takt', 'gueltig_ab', p_ab, 'gueltig_bis', null)), '[]')
    into v_sp
    from jsonb_array_elements(coalesce(p_zeilen, '[]')) x;

  v_pb := case when v_vertrag is not null then public.slots_planbilanz(v_vertrag, v_heute, v_sp) end;
  return jsonb_build_object(
    'planbilanz', v_pb,
    'terminzahl', v_pb -> 'terminzahl', 'letzter_termin', v_pb -> 'letzter_termin',
    'uebersprungen', coalesce(v_pb -> 'uebersprungen', '[]'),
    'gruende', public.slots_stammplatz_gruende(p_student_id, p_zeilen, p_ab, v_heute, coalesce(v_ersetzt, '{}')));
end;
$$;

-- ============================================================================
-- slots_ziele — gültige Ziele für Umbuchen und Zusatztermin
-- ============================================================================
--
-- p_ausser_termin_id: der Termin, der umgebucht wird (NULL beim Zusatztermin). p_eingang entscheidet nach
-- der 10-Uhr-Regel, ob seine Einheit verbraucht ist: rechtzeitig -> er zählt für Tag, Woche und Budget
-- nicht mehr; zu spät -> er bleibt "unentschuldigt" und belegt weiter (Entscheidung 19).

create function public.slots_ziele(p_student_id uuid, p_ausser_termin_id uuid, p_eingang timestamptz, p_ab date,
                                   p_wochen integer default 4, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt   timestamptz := public.slots_jetzt(p_jetzt);
  v_heute   date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_ab      date := greatest(coalesce(p_ab, v_heute), v_heute);
  v_alt     public.kind_termine;
  v_frei    uuid;
  v_spaet   boolean := false;
  v_extra   integer := 0;
  v_budget  integer;
begin
  perform public.slots_admin_pruefen('slots_ziele');
  if p_ausser_termin_id is not null then
    select * into v_alt from public.kind_termine where id = p_ausser_termin_id and student_id = p_student_id;
    if not found then
      perform public.slots_fehler('P0002', 'slots_ziele: Termin nicht gefunden');
    end if;
    v_spaet := p_eingang is not null and (p_eingang at time zone 'Europe/Berlin') >= (v_alt.datum + time '10:00');
    v_frei := case when v_spaet then null else v_alt.id end;
    -- Zu spät abgesagt: ein beweglicher alter Termin wird fest ("unentschuldigt") und belegt dann neben
    -- dem neuen Termin eine eigene Einheit (Anforderung G 42).
    if v_spaet and v_alt.herkunft = 'stammplatz' and v_alt.zustand = 'planned' and v_alt.session_id is null
       and v_alt.datum >= v_heute then
      v_extra := 1;
    end if;
  end if;
  select v.einheiten - public.slots_fest_belegt(v.id, v_heute, v_frei) - 1 - v_extra into v_budget
    from public.vertraege v where v.id = coalesce(v_alt.vertrag_id, public.slots_vertrag(p_student_id, v_heute));

  return jsonb_build_object(
    'ab', v_ab, 'wochen', coalesce(p_wochen, 4),
    'alt_verbraucht', v_spaet,
    'ziele', coalesce((
      select jsonb_agg(jsonb_build_object(
               'datum', g::date, 'zeit_id', z.id, 'beginn', public.slots_hhmm(z.beginn), 'ende', public.slots_hhmm(z.ende),
               'frei', public.slot_kapazitaet(g::date, z.id) - public.slot_belegt(g::date, z.id, p_student_id),
               'verdraengt', public.slots_verdraengt(public.slots_vertrag_am(p_student_id, g::date), v_heute,
                                                     v_frei, v_alt.id))
             order by g, z.beginn)
        from generate_series(v_ab, v_ab + 7 * coalesce(p_wochen, 4) - 1, interval '1 day') g
        join public.slot_zeiten z on z.aktiv_ab <= g::date and (z.inaktiv_ab is null or g::date < z.inaktiv_ab)
       where extract(isodow from g) between 1 and 5
         and (v_alt.id is null or not (g::date = v_alt.datum and z.id = v_alt.slot_zeit_id))
         and public.slots_zusatz_code(p_student_id, g::date, z.id, v_jetzt, v_frei) is null
         and (v_extra = 0 or coalesce(v_budget, -1) >= 0)), '[]'),
    'kein_budget', coalesce(v_budget, -1) < 0);
end;
$$;

-- ============================================================================
-- slots_kandidaten(p_datum, p_zeit_id) — Kinder, für die ein Zusatztermin hier alle Regeln erfüllt
-- ============================================================================

create function public.slots_kandidaten(p_datum date, p_zeit_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
begin
  perform public.slots_admin_pruefen('slots_kandidaten');
  return coalesce((
    select jsonb_agg(k.j order by k.j ->> 'name')
      from (
        select public.slots_kind_info(b.student_id, v.id) || jsonb_build_object(
                 'offen', greatest(public.slots_offen(v.id, v_heute), 0),
                 'verdraengt', public.slots_verdraengt(v.id, v_heute)) as j
          from public.slots_kinder_basis(v_heute) b
          join public.vertraege v on v.id = public.slots_vertrag_am(b.student_id, p_datum)
         where public.slots_zusatz_code(b.student_id, p_datum, p_zeit_id, v_jetzt) is null
      ) k), '[]');
end;
$$;

-- ============================================================================
-- Rechte
-- ============================================================================

revoke all on function public.slots_stammplatz_json(uuid) from public, anon, authenticated;
revoke all on function public.slots_vertrag_json(uuid) from public, anon, authenticated;
revoke all on function public.slots_stammplaetze_aktiv(uuid, date) from public, anon, authenticated;
revoke all on function public.slots_offen(uuid, date, uuid) from public, anon, authenticated;
revoke all on function public.slots_verdraengt(uuid, date, uuid, uuid) from public, anon, authenticated;

revoke all on function public.slots_kinder(timestamptz) from public, anon;
revoke all on function public.slots_kind(uuid, timestamptz) from public, anon;
revoke all on function public.slots_frei(text, date, uuid, timestamptz) from public, anon;
revoke all on function public.slots_planbilanz_vorschau(uuid, jsonb, date, uuid[], timestamptz) from public, anon;
revoke all on function public.slots_ziele(uuid, uuid, timestamptz, date, integer, timestamptz) from public, anon;
revoke all on function public.slots_kandidaten(date, uuid, timestamptz) from public, anon;
grant execute on function public.slots_kinder(timestamptz) to authenticated;
grant execute on function public.slots_kind(uuid, timestamptz) to authenticated;
grant execute on function public.slots_frei(text, date, uuid, timestamptz) to authenticated;
grant execute on function public.slots_planbilanz_vorschau(uuid, jsonb, date, uuid[], timestamptz) to authenticated;
grant execute on function public.slots_ziele(uuid, uuid, timestamptz, date, integer, timestamptz) to authenticated;
grant execute on function public.slots_kandidaten(date, uuid, timestamptz) to authenticated;

commit;
