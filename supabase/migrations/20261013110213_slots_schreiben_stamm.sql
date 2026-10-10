-- Slots SL1, Teil 4a: Schreibfunktionen für Stammdaten und Stammplätze.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 10, 16, 17, 20–24; Anforderung B 7–8, E 28–33, H 47–52.
--
-- Jede Funktion: Rollenprüfung (Admin oder Systemaufruf, sonst 42501), zuerst die Sperre
-- (Entscheidung 16), dann die Regeln mit SL-Codes (Entscheidung 23), am Ende termine_planen für alle
-- betroffenen Kinder. p_jetzt nur für Tests (Entscheidung 17).
--
-- Inhalt:
--   1. Hilfen: slots_fehler, slots_planen_slot, slots_naechste_termine_frei, slots_stammplatz_gruende
--   2. raum_anlegen, raum_deaktivieren, slot_zeit_anlegen, slot_zeit_deaktivieren
--   3. stammschicht_anlegen, stammschicht_beenden
--   4. stammplatz_vergeben, stammplatz_aendern, stammplatz_beenden, stammplaetze_weiterfuehren

begin;

-- ============================================================================
-- 1. Hilfen
-- ============================================================================

create function public.slots_fehler(p_code text, p_text text, p_hint text default null)
returns void
language plpgsql volatile
as $$
begin
  raise exception '%', p_text using errcode = p_code, hint = coalesce(p_hint, p_code);
end;
$$;

-- Alle Kinder neu planen, deren aktiver Stammplatz auf Wochentag und Uhrzeit liegt (NULL = alle).
create function public.slots_planen_slot(p_wochentag integer, p_slot_zeit_id uuid, p_jetzt timestamptz)
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_st uuid;
begin
  for v_st in
    select distinct s.student_id from public.stammplaetze s
     where (p_wochentag is null or s.wochentag = p_wochentag)
       and (p_slot_zeit_id is null or s.slot_zeit_id = p_slot_zeit_id)
       and coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_berlin_tag(p_jetzt)
  loop
    perform public.termine_planen(v_st, p_jetzt);
  end loop;
end;
$$;

-- Die nächsten sechs Termine eines Musters ab p_ab mit Kapazität und Belegung (ohne das Kind selbst).
-- Gleiche Regel wie die Übersicht freier Plätze (Entscheidung 16).
create function public.slots_naechste_termine_frei(p_wochentag integer, p_slot_zeit_id uuid, p_takt text,
                                                   p_ab date, p_ohne_student uuid default null)
returns table(datum date, kapazitaet integer, belegt integer)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select d.d, public.slot_kapazitaet(d.d, p_slot_zeit_id), public.slot_belegt(d.d, p_slot_zeit_id, p_ohne_student)
    from (
      select g::date as d from generate_series(p_ab, p_ab + 7 * 60, interval '1 day') g
       where extract(isodow from g) = p_wochentag
         and public.slots_takt_passt(p_takt, g::date)
         and g::date <= public.slots_planungsgrenze()
         and public.betriebstag(g::date)
       order by g
       limit 6
    ) d;
$$;

-- Sperrgründe für Stammplatz-Zeilen ab p_ab (Anforderung E 30): jsonb-Array {code, zeile}.
-- zeile = Index in p_zeilen (0-basiert) oder NULL für den ganzen Vorgang.
-- p_ausser: Stammplätze, die mit diesem Vorgang enden (Ändern), zählen für SL008 nicht mit.
create function public.slots_stammplatz_gruende(p_student_id uuid, p_zeilen jsonb, p_ab date, p_heute date,
                                                p_ausser uuid[] default '{}')
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_vertrag uuid := public.slots_vertrag_am(p_student_id, p_ab);
  v_out     jsonb := '[]';
  z         record;
  y         record;
  f         record;
begin
  if p_ab is null or p_ab < p_heute then
    v_out := v_out || jsonb_build_object('code', 'SL007', 'zeile', null);
  end if;
  if v_vertrag is null then
    v_out := v_out || jsonb_build_object('code', 'SL006', 'zeile', null);
  end if;
  if p_ab > public.slots_planungsgrenze() then
    v_out := v_out || jsonb_build_object('code', 'SL012', 'zeile', null);
  end if;

  for z in
    select (x.o - 1)::int as i, (x.v ->> 'wochentag')::int as w, (x.v ->> 'slot_zeit_id')::uuid as sz, x.v ->> 'takt' as t
      from jsonb_array_elements(coalesce(p_zeilen, '[]')) with ordinality x(v, o)
  loop
    if z.w is null or z.w not between 1 and 5 or z.t is null or z.t not in ('woechentlich', 'a_woche', 'b_woche')
       or z.sz is null or not public.slots_zeit_aktiv(z.sz, coalesce(p_ab, p_heute)) then
      perform public.slots_fehler('22023', 'Stammplatz: Zeile ' || (z.i + 1) || ' ist unvollständig oder die Uhrzeit ist nicht aktiv');
    end if;

    -- SL008: zwei Stammplätze, die auf denselben Tag fallen können (gleicher Wochentag, Takte überlappen).
    for y in
      select (x.o - 1)::int as i, (x.v ->> 'wochentag')::int as w, x.v ->> 'takt' as t
        from jsonb_array_elements(p_zeilen) with ordinality x(v, o)
       where (x.o - 1) < z.i
      union all
      select null, s.wochentag, s.takt from public.stammplaetze s
       where s.student_id = p_student_id and not s.id = any (coalesce(p_ausser, '{}'))
         and least(coalesce(s.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(s.vertrag_id)) >= p_ab
    loop
      if y.w = z.w and (y.t = 'woechentlich' or z.t = 'woechentlich' or y.t = z.t) then
        v_out := v_out || jsonb_build_object('code', 'SL008', 'zeile', z.i);
        exit;
      end if;
    end loop;

    -- SL002 / SL001: einer der nächsten sechs Termine ab "gültig ab" ohne Raum oder voll.
    for f in
      select * from public.slots_naechste_termine_frei(z.w, z.sz, z.t, greatest(p_ab, p_heute), p_student_id)
       order by datum
    loop
      if f.kapazitaet = 0 then
        v_out := v_out || jsonb_build_object('code', 'SL002', 'zeile', z.i, 'datum', f.datum);
        exit;
      elsif f.belegt >= f.kapazitaet then
        v_out := v_out || jsonb_build_object('code', 'SL001', 'zeile', z.i, 'datum', f.datum);
        exit;
      end if;
    end loop;
  end loop;
  return v_out;
end;
$$;

-- Ersten Sperrgrund als Fehler werfen.
create function public.slots_gruende_werfen(p_gruende jsonb)
returns void
language plpgsql volatile
as $$
declare
  g jsonb := p_gruende -> 0;
begin
  if g is null then
    return;
  end if;
  perform public.slots_fehler(g ->> 'code',
    case g ->> 'code'
      when 'SL001' then 'Slot voll'
      when 'SL002' then 'kein Raum mit Coach'
      when 'SL006' then 'außerhalb des Vertrags'
      when 'SL007' then 'gültig ab liegt in der Vergangenheit'
      when 'SL008' then 'zwei Stammplätze am selben Tag'
      when 'SL012' then 'jenseits der Ferientabelle'
      else 'Stammplatz nicht möglich' end,
    g::text);
end;
$$;

-- ============================================================================
-- 2. Räume und Uhrzeiten (Anforderung B 7–8)
-- ============================================================================

create function public.raum_anlegen(p_name text, p_aktiv_ab date default null, p_jetzt timestamptz default now())
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('raum_anlegen');
  perform public.slots_sperren();
  if nullif(btrim(coalesce(p_name, '')), '') is null then
    perform public.slots_fehler('22023', 'raum_anlegen: Name fehlt');
  end if;
  if exists (select 1 from public.raeume r where lower(r.name) = lower(btrim(p_name))) then
    perform public.slots_fehler('22023', 'raum_anlegen: Name gibt es schon', 'name_doppelt');
  end if;
  if coalesce(p_aktiv_ab, v_heute) < v_heute then
    perform public.slots_fehler('SL007', 'raum_anlegen: aktiv ab liegt in der Vergangenheit');
  end if;
  insert into public.raeume (name, aktiv_ab, angelegt_von)
  values (btrim(p_name), coalesce(p_aktiv_ab, v_heute), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

create function public.raum_deaktivieren(p_id uuid, p_ab date, p_jetzt timestamptz default now())
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  r       public.raeume;
begin
  perform public.slots_admin_pruefen('raum_deaktivieren');
  perform public.slots_sperren();
  select * into r from public.raeume where id = p_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'raum_deaktivieren: Raum nicht gefunden');
  end if;
  if p_ab is null or p_ab < v_heute then
    perform public.slots_fehler('SL007', 'raum_deaktivieren: Datum liegt in der Vergangenheit');
  end if;
  update public.raeume set inaktiv_ab = greatest(p_ab, r.aktiv_ab) where id = p_id;
  -- Kapazität sinkt ab dann (Anforderung H 52); betroffene Kinder erscheinen "ohne Raum".
  perform public.slots_planen_slot(null, null, public.slots_jetzt(p_jetzt));
end;
$$;

create function public.slot_zeit_anlegen(p_beginn time, p_aktiv_ab date default null, p_jetzt timestamptz default now())
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('slot_zeit_anlegen');
  perform public.slots_sperren();
  if p_beginn is null or p_beginn < time '06:00' or p_beginn > time '22:00' then
    perform public.slots_fehler('22023', 'slot_zeit_anlegen: Beginn zwischen 06:00 und 22:00');
  end if;
  if exists (select 1 from public.slot_zeiten z where z.beginn = p_beginn and z.inaktiv_ab is null) then
    perform public.slots_fehler('22023', 'slot_zeit_anlegen: Uhrzeit gibt es schon', 'zeit_doppelt');
  end if;
  if coalesce(p_aktiv_ab, v_heute) < v_heute then
    perform public.slots_fehler('SL007', 'slot_zeit_anlegen: aktiv ab liegt in der Vergangenheit');
  end if;
  insert into public.slot_zeiten (beginn, aktiv_ab, angelegt_von)
  values (p_beginn, coalesce(p_aktiv_ab, v_heute), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

create function public.slot_zeit_deaktivieren(p_id uuid, p_ab date, p_jetzt timestamptz default now())
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  z       public.slot_zeiten;
begin
  perform public.slots_admin_pruefen('slot_zeit_deaktivieren');
  perform public.slots_sperren();
  select * into z from public.slot_zeiten where id = p_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'slot_zeit_deaktivieren: Uhrzeit nicht gefunden');
  end if;
  if p_ab is null or p_ab < v_heute then
    perform public.slots_fehler('SL007', 'slot_zeit_deaktivieren: Datum liegt in der Vergangenheit');
  end if;
  update public.slot_zeiten set inaktiv_ab = greatest(p_ab, z.aktiv_ab) where id = p_id;
  perform public.slots_planen_slot(null, p_id, public.slots_jetzt(p_jetzt));
end;
$$;

-- ============================================================================
-- 3. Stammschichten (Anforderung H 47, 48, 51; Abnahmefall 13)
-- ============================================================================

create function public.stammschicht_anlegen(p_coach_id uuid, p_wochentag integer, p_slot_zeit_id uuid, p_raum_id uuid,
                                            p_gueltig_ab date default null, p_jetzt timestamptz default now())
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_ab    date := coalesce(p_gueltig_ab, public.slots_berlin_tag(public.slots_jetzt(p_jetzt)));
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('stammschicht_anlegen');
  perform public.slots_sperren();
  if not exists (select 1 from public.profiles p where p.id = p_coach_id and p.role = 'coach') then
    perform public.slots_fehler('22023', 'stammschicht_anlegen: kein Coach', 'kein_coach');
  end if;
  if p_wochentag is null or p_wochentag not between 1 and 5 then
    perform public.slots_fehler('22023', 'stammschicht_anlegen: Wochentag 1–5');
  end if;
  if v_ab < public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('SL007', 'stammschicht_anlegen: gültig ab liegt in der Vergangenheit');
  end if;
  if not public.slots_zeit_aktiv(p_slot_zeit_id, v_ab)
     or not exists (select 1 from public.raeume r where r.id = p_raum_id
                     and (r.inaktiv_ab is null or v_ab < r.inaktiv_ab)) then
    perform public.slots_fehler('22023', 'stammschicht_anlegen: Uhrzeit oder Raum nicht aktiv');
  end if;
  if exists (select 1 from public.stammschichten s
              where s.wochentag = p_wochentag and s.slot_zeit_id = p_slot_zeit_id
                and (s.raum_id = p_raum_id or s.coach_id = p_coach_id)
                and coalesce(s.gueltig_bis, 'infinity'::date) >= v_ab) then
    perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach)');
  end if;
  insert into public.stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab, angelegt_von)
  values (p_coach_id, p_wochentag, p_slot_zeit_id, p_raum_id, v_ab, auth.uid())
  returning id into v_id;
  perform public.slots_planen_slot(p_wochentag, p_slot_zeit_id, v_jetzt);
  return v_id;
end;
$$;

create function public.stammschicht_beenden(p_id uuid, p_ab date, p_jetzt timestamptz default now())
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  s       public.stammschichten;
begin
  perform public.slots_admin_pruefen('stammschicht_beenden');
  perform public.slots_sperren();
  select * into s from public.stammschichten where id = p_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'stammschicht_beenden: Stammschicht nicht gefunden');
  end if;
  if p_ab is null or p_ab < public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('SL007', 'stammschicht_beenden: Datum liegt in der Vergangenheit');
  end if;
  update public.stammschichten
     set gueltig_bis = greatest(s.gueltig_ab - 1, least(coalesce(s.gueltig_bis, 'infinity'::date), p_ab - 1)),
         beendet_am = now(), beendet_von = auth.uid()
   where id = p_id;
  perform public.slots_planen_slot(s.wochentag, s.slot_zeit_id, v_jetzt);
end;
$$;

-- ============================================================================
-- 4. Stammplätze (Anforderung E 28–33)
-- ============================================================================

create function public.stammplatz_vergeben(p_student_id uuid, p_zeilen jsonb, p_ab date,
                                           p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vertrag uuid;
  v_ids   uuid[];
begin
  perform public.slots_admin_pruefen('stammplatz_vergeben');
  perform public.slots_sperren();
  if not public.slots_kind_zugelassen(p_student_id) then
    perform public.slots_fehler('22023', 'stammplatz_vergeben: Testkonten kommen in den Slots nicht vor', 'testkonto');
  end if;
  if jsonb_typeof(p_zeilen) is distinct from 'array' or jsonb_array_length(p_zeilen) = 0 then
    perform public.slots_fehler('22023', 'stammplatz_vergeben: keine Zeilen');
  end if;
  perform public.slots_gruende_werfen(public.slots_stammplatz_gruende(p_student_id, p_zeilen, p_ab, v_heute));
  v_vertrag := public.slots_vertrag_am(p_student_id, p_ab);

  with neu as (
    insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, angelegt_von)
    select p_student_id, v_vertrag, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid, x ->> 'takt', p_ab, auth.uid()
      from jsonb_array_elements(p_zeilen) x
    returning id
  )
  select array_agg(id) into v_ids from neu;

  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('stammplatz_ids', to_jsonb(v_ids),
                            'planbilanz', public.slots_planbilanz(v_vertrag, v_heute));
end;
$$;

create function public.stammplatz_aendern(p_id uuid, p_ab date, p_wochentag integer, p_slot_zeit_id uuid, p_takt text,
                                          p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  s       public.stammplaetze;
  v_zeile jsonb := jsonb_build_array(jsonb_build_object('wochentag', p_wochentag, 'slot_zeit_id', p_slot_zeit_id, 'takt', p_takt));
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('stammplatz_aendern');
  perform public.slots_sperren();
  select * into s from public.stammplaetze where id = p_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'stammplatz_aendern: Stammplatz nicht gefunden');
  end if;
  if coalesce(s.gueltig_bis, 'infinity'::date) < p_ab then
    perform public.slots_fehler('22023', 'stammplatz_aendern: Stammplatz ist zu diesem Datum schon beendet');
  end if;
  perform public.slots_gruende_werfen(
    public.slots_stammplatz_gruende(s.student_id, v_zeile, p_ab, v_heute, array[p_id]));

  -- Der alte endet am Vortag (Anforderung E 31), der neue übernimmt sein Ende.
  update public.stammplaetze
     set gueltig_bis = greatest(s.gueltig_ab - 1, p_ab - 1), beendet_am = now(), beendet_von = auth.uid()
   where id = p_id;
  insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, gueltig_bis,
                                   vorgaenger_id, angelegt_von)
  values (s.student_id, coalesce(public.slots_vertrag_am(s.student_id, p_ab), s.vertrag_id), p_wochentag,
          p_slot_zeit_id, p_takt, p_ab, s.gueltig_bis, p_id, auth.uid())
  returning id into v_id;

  perform public.termine_planen(s.student_id, v_jetzt);
  return jsonb_build_object('stammplatz_id', v_id,
                            'planbilanz', public.slots_planbilanz(public.slots_vertrag(s.student_id, v_heute), v_heute));
end;
$$;

create function public.stammplatz_beenden(p_id uuid, p_ab date, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  s       public.stammplaetze;
begin
  perform public.slots_admin_pruefen('stammplatz_beenden');
  perform public.slots_sperren();
  select * into s from public.stammplaetze where id = p_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'stammplatz_beenden: Stammplatz nicht gefunden');
  end if;
  if p_ab is null or p_ab < v_heute then
    perform public.slots_fehler('SL007', 'stammplatz_beenden: Datum liegt in der Vergangenheit');
  end if;
  -- Ab p_ab entstehen keine Termine mehr (Anforderung E 32); offene Einheiten bleiben.
  update public.stammplaetze
     set gueltig_bis = greatest(s.gueltig_ab - 1, least(coalesce(s.gueltig_bis, 'infinity'::date), p_ab - 1)),
         beendet_am = now(), beendet_von = auth.uid()
   where id = p_id;
  perform public.termine_planen(s.student_id, v_jetzt);
  return jsonb_build_object('ok', true,
                            'planbilanz', public.slots_planbilanz(public.slots_vertrag(s.student_id, v_heute), v_heute));
end;
$$;

-- Vorschlag für den Folgevertrag (Entscheidung 22): Stammplätze, die am letzten Tag des Vorgängers
-- galten, ab Beginn des Folgevertrags (frühestens heute). Einheiten gehen nicht über.
create function public.slots_weiterfuehren_vorschlag(p_student_id uuid, p_heute date)
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  with neu as (
    select v.id, v.vorgaenger_id, greatest(v.vertragsbeginn, p_heute) as ab
      from public.vertraege v
     where v.student_id = p_student_id and v.status = 'abgeschlossen' and v.widerrufen_am is null
       and v.vorgaenger_id is not null and v.vertrag_ende >= p_heute
       and not exists (select 1 from public.stammplaetze s where s.vertrag_id = v.id)
     order by v.vertragsbeginn
     limit 1
  )
  select jsonb_build_object(
           'vertrag_id', n.id, 'ab', n.ab,
           'zeilen', coalesce((select jsonb_agg(jsonb_build_object('vorgaenger_id', s.id, 'wochentag', s.wochentag,
                                                                    'slot_zeit_id', s.slot_zeit_id, 'takt', s.takt,
                                                                    'beginn', z.beginn)
                                                order by s.wochentag, z.beginn)
                                 from public.stammplaetze s join public.slot_zeiten z on z.id = s.slot_zeit_id
                                where s.vertrag_id = n.vorgaenger_id
                                  and s.gueltig_ab <= public.slots_vertrag_planende(n.vorgaenger_id)
                                  and coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_vertrag_planende(n.vorgaenger_id)),
                              '[]'))
    from neu n;
$$;

create function public.stammplaetze_weiterfuehren(p_student_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vor   jsonb;
  v_ids   uuid[];
begin
  perform public.slots_admin_pruefen('stammplaetze_weiterfuehren');
  perform public.slots_sperren();
  v_vor := public.slots_weiterfuehren_vorschlag(p_student_id, v_heute);
  if v_vor is null or jsonb_array_length(v_vor -> 'zeilen') = 0 then
    perform public.slots_fehler('P0002', 'stammplaetze_weiterfuehren: kein Folgevertrag mit Vorschlag', 'kein_vorschlag');
  end if;
  perform public.slots_gruende_werfen(
    public.slots_stammplatz_gruende(p_student_id, v_vor -> 'zeilen', (v_vor ->> 'ab')::date, v_heute));

  with neu as (
    insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, vorgaenger_id, angelegt_von)
    select p_student_id, (v_vor ->> 'vertrag_id')::uuid, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid,
           x ->> 'takt', (v_vor ->> 'ab')::date, (x ->> 'vorgaenger_id')::uuid, auth.uid()
      from jsonb_array_elements(v_vor -> 'zeilen') x
    returning id
  )
  select array_agg(id) into v_ids from neu;

  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('stammplatz_ids', to_jsonb(v_ids),
                            'planbilanz', public.slots_planbilanz((v_vor ->> 'vertrag_id')::uuid, v_heute));
end;
$$;

-- ============================================================================
-- Rechte: Admin-Funktionen für authenticated (Rollenprüfung im Körper), Hilfen intern
-- ============================================================================

revoke all on function public.slots_fehler(text, text, text) from public, anon, authenticated;
revoke all on function public.slots_planen_slot(integer, uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.slots_naechste_termine_frei(integer, uuid, text, date, uuid) from public, anon, authenticated;
revoke all on function public.slots_stammplatz_gruende(uuid, jsonb, date, date, uuid[]) from public, anon, authenticated;
revoke all on function public.slots_gruende_werfen(jsonb) from public, anon, authenticated;
revoke all on function public.slots_weiterfuehren_vorschlag(uuid, date) from public, anon, authenticated;

revoke all on function public.raum_anlegen(text, date, timestamptz) from public, anon;
revoke all on function public.raum_deaktivieren(uuid, date, timestamptz) from public, anon;
revoke all on function public.slot_zeit_anlegen(time, date, timestamptz) from public, anon;
revoke all on function public.slot_zeit_deaktivieren(uuid, date, timestamptz) from public, anon;
revoke all on function public.stammschicht_anlegen(uuid, integer, uuid, uuid, date, timestamptz) from public, anon;
revoke all on function public.stammschicht_beenden(uuid, date, timestamptz) from public, anon;
revoke all on function public.stammplatz_vergeben(uuid, jsonb, date, timestamptz) from public, anon;
revoke all on function public.stammplatz_aendern(uuid, date, integer, uuid, text, timestamptz) from public, anon;
revoke all on function public.stammplatz_beenden(uuid, date, timestamptz) from public, anon;
revoke all on function public.stammplaetze_weiterfuehren(uuid, timestamptz) from public, anon;

grant execute on function public.raum_anlegen(text, date, timestamptz) to authenticated;
grant execute on function public.raum_deaktivieren(uuid, date, timestamptz) to authenticated;
grant execute on function public.slot_zeit_anlegen(time, date, timestamptz) to authenticated;
grant execute on function public.slot_zeit_deaktivieren(uuid, date, timestamptz) to authenticated;
grant execute on function public.stammschicht_anlegen(uuid, integer, uuid, uuid, date, timestamptz) to authenticated;
grant execute on function public.stammschicht_beenden(uuid, date, timestamptz) to authenticated;
grant execute on function public.stammplatz_vergeben(uuid, jsonb, date, timestamptz) to authenticated;
grant execute on function public.stammplatz_aendern(uuid, date, integer, uuid, text, timestamptz) to authenticated;
grant execute on function public.stammplatz_beenden(uuid, date, timestamptz) to authenticated;
grant execute on function public.stammplaetze_weiterfuehren(uuid, timestamptz) to authenticated;

commit;
