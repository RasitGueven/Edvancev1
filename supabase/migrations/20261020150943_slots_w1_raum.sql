-- Slots W1: Stammplatz am Raum, Planung je Raum, Lese- und Schreibwege für den Wochenplan (W2–W4).
--
-- Bauauftrag docs/slots/Bauauftrag-Slots-Wochenplan-v2.md, Abschnitt W1 (Gründer-Gespräch 18.10.2026):
--   1  stammplaetze.raum_id (null = Altbestand, System verteilt wie bisher). Neue und geänderte Stammplätze
--      brauchen einen Raum (22023, hint raum_fehlt).
--   2  Termine aus einem Stammplatz mit Raum entstehen fest in diesem Raum (raum_id, raum_fest), nur wenn der
--      Raum offen ist und dort weniger als fünf Kinder sitzen; sonst übersprungen. slot_zuteilung lässt einen
--      festen Termin in einem vollen oder geschlossenen Raum ohne Raum stehen (grund raum_voll / raum_zu),
--      statt ihn still in einen anderen Raum zu setzen.
--   3  stammplatz_vergeben: raum_id je Zeile; slots_stammplatz_gruende prüft SL002/SL001 je Raum.
--   4  stammplatz_aendern und zusatztermin_buchen mit p_raum_id am Ende (DROP + CREATE, Grants wie vorher).
--   5  stammplatz_vorschau, 6 slots_kandidaten_alle, 7 slots_woche erweitert,
--   8  stammschicht_block_anlegen, 9 stammschicht_raum_wechseln.
--  10  Admin-only, SECURITY DEFINER, search_path public, pg_temp; EXECUTE nur authenticated.
-- Dazu, damit W2–W4 ohne Änderung an lib und Schema auskommen (additiv, kein Feld entfernt):
--   slots_termin und slots_tag führen Räume mit Kindern ohne Coach; slots_stammplatz_json nennt Raum und Coach
--   der Schicht; slots_coaches zählt je Stammschicht die Kinder mit Stammplatz dort.
-- S4 (Raum zählt auch ohne Coach) ist nicht freigegeben: ein Raum ohne Coach bleibt gesperrt (SL002).
-- Ersetzte Funktionen: Signatur, SECURITY, search_path und Rechte unverändert außer bei 4.

begin;

-- ============================================================================
-- 1  Spalte
-- ============================================================================

alter table public.stammplaetze add column raum_id uuid references public.raeume(id) on delete restrict;
create index stammplaetze_raum_idx on public.stammplaetze (raum_id, wochentag, slot_zeit_id) where raum_id is not null;

-- ============================================================================
-- Hilfen (intern)
-- ============================================================================

CREATE FUNCTION public.slots_raum_pflicht()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
begin
  -- W1 (Entscheidung 1): Jeder neue oder geänderte Stammplatz braucht einen Raum. Die Tests für Stammplätze
  -- ohne Raum (Altbestand) ersetzen diese Funktion in ihrer eigenen Transaktion.
  return true;
end;
$function$;

CREATE FUNCTION public.slots_raum_pruefen(p_zeilen jsonb, p_wer text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
AS $function$
begin
  if public.slots_raum_pflicht()
     and exists (select 1 from jsonb_array_elements(coalesce(p_zeilen, '[]')) x where nullif(x ->> 'raum_id', '') is null) then
    perform public.slots_fehler('22023', p_wer || ': Raum fehlt', 'raum_fehlt');
  end if;
end;
$function$;

CREATE FUNCTION public.slots_raum_offen(p_datum date, p_slot_zeit_id uuid, p_raum_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (select 1 from public.slot_raeume(p_datum, p_datum) r
                  where r.slot_zeit_id = p_slot_zeit_id and r.raum_id = p_raum_id and r.offen);
$function$;

-- Kinder, die an diesem Termin fest in diesem Raum sitzen: Raum-Stift oder festgeschrieben in seiner Session.
CREATE FUNCTION public.slots_raum_belegt(p_datum date, p_slot_zeit_id uuid, p_raum_id uuid, p_ohne_student uuid DEFAULT NULL::uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select count(*)::int from public.kind_termine kt
    left join public.coaching_sessions cs on cs.id = kt.session_id
   where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id
     and kt.zustand in ('planned', 'present')
     and kt.student_id is distinct from p_ohne_student
     and coalesce(cs.raum_id, case when kt.raum_fest then kt.raum_id end) = p_raum_id;
$function$;

-- Platz im Raum: dort weniger als fünf feste Kinder UND im Termin insgesamt Platz. Die zweite Bedingung zählt die
-- beweglichen Kinder (ohne Raum-Stift), die die Zuteilung ebenfalls in Räume setzt; ohne sie würde der Termin überbucht.
CREATE FUNCTION public.slots_raum_platz(p_datum date, p_slot_zeit_id uuid, p_raum_id uuid, p_ohne_student uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select public.slots_raum_belegt(p_datum, p_slot_zeit_id, p_raum_id, p_ohne_student) < 5
     and public.slot_belegt(p_datum, p_slot_zeit_id, p_ohne_student) < public.slot_kapazitaet(p_datum, p_slot_zeit_id);
$function$;

-- Wie slots_zusatz_code, mit Raum: SL002 und SL001 gelten für den gewählten Raum (Reihenfolge unverändert).
CREATE FUNCTION public.slots_zusatz_code_raum(p_student_id uuid, p_datum date, p_slot_zeit_id uuid, p_jetzt timestamp with time zone, p_raum_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_vertrag uuid := public.slots_vertrag_am(p_student_id, p_datum);
begin
  if p_raum_id is null then
    return public.slots_zusatz_code(p_student_id, p_datum, p_slot_zeit_id, p_jetzt);
  end if;
  if v_vertrag is null or not public.slots_kind_zugelassen(p_student_id) then
    return 'SL006';
  end if;
  if p_datum > public.slots_planungsgrenze() then
    return 'SL012';
  end if;
  if public.slots_termin_beginn(p_datum, p_slot_zeit_id) <= p_jetzt then
    return 'SL007';
  end if;
  if not public.slots_raum_offen(p_datum, p_slot_zeit_id, p_raum_id) then
    return 'SL002';
  end if;
  if exists (select 1 from public.kind_termine kt
              where kt.student_id = p_student_id and kt.datum = p_datum
                and kt.zustand in ('planned', 'present', 'unexcused'))
     or exists (select 1 from public.slots_einzelbuchungen(p_student_id) e
                 where e.datum = p_datum and e.attendance in ('planned', 'present', 'unexcused')) then
    return 'SL003';
  end if;
  if public.slots_woche_aktiv(p_student_id, p_datum) + 1 > public.slots_wochengrenze(p_student_id, p_datum) then
    return 'SL004';
  end if;
  if public.slots_art_konflikt(p_student_id, p_datum, p_slot_zeit_id) then
    return 'SL013';
  end if;
  if not public.slots_raum_platz(p_datum, p_slot_zeit_id, p_raum_id, p_student_id) then
    return 'SL001';
  end if;
  if (select v.einheiten from public.vertraege v where v.id = v_vertrag)
     - public.slots_fest_belegt(v_vertrag, public.slots_berlin_tag(p_jetzt)) < 1 then
    return 'SL005';
  end if;
  return null;
end;
$function$;

-- ============================================================================
-- 2  Planung je Raum
-- ============================================================================

CREATE OR REPLACE FUNCTION public.slot_zuteilung(p_datum date, p_slot_zeit_id uuid)
 RETURNS TABLE(termin_id uuid, student_id uuid, raum_id uuid, fach text, grund text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  r_ids   uuid[] := '{}';
  r_zahl  int[]  := '{}';
  r_fach  text[] := '{}';
  k       record;
  i       int;
  v_wahl  int;
  v_fach  text;
begin
  select coalesce(array_agg(x.raum_id order by x.raum_name), '{}') into r_ids
    from public.slot_raeume(p_datum, p_datum) x
   where x.slot_zeit_id = p_slot_zeit_id and x.offen;
  r_zahl := array_fill(0, array[greatest(cardinality(r_ids), 1)]);
  r_fach := array_fill(''::text, array[greatest(cardinality(r_ids), 1)]);

  -- Festgeschriebene Räume kommen dazu, auch wenn sie inzwischen nicht mehr als geöffnet gelten.
  for k in
    select distinct cs.raum_id from public.kind_termine kt join public.coaching_sessions cs on cs.id = kt.session_id
     where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id and cs.raum_id is not null
       and not cs.raum_id = any (r_ids)
  loop
    r_ids := r_ids || k.raum_id; r_zahl := r_zahl || 0; r_fach := r_fach || ''::text;
  end loop;

  for k in
    select kt.id, kt.student_id, kt.raum_id as stift, kt.raum_fest, cs.raum_id as sess_raum,
           coalesce(nullif(btrim(v.fach), ''), '') as f,
           count(*) over (partition by coalesce(nullif(btrim(v.fach), ''), '')) as gruppe,
           kt.angelegt_am
      from public.kind_termine kt
      join public.vertraege v on v.id = kt.vertrag_id
      left join public.coaching_sessions cs on cs.id = kt.session_id
     where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id and kt.zustand in ('planned', 'present')
     order by (cs.raum_id is not null) desc, (kt.raum_fest and kt.raum_id = any (r_ids)) desc,
              count(*) over (partition by coalesce(nullif(btrim(v.fach), ''), '')) desc,
              coalesce(nullif(btrim(v.fach), ''), ''), kt.angelegt_am, kt.id
  loop
    v_wahl := null; grund := null;
    v_fach := '|' || k.f || '|';
    if k.sess_raum is not null then
      v_wahl := array_position(r_ids, k.sess_raum); grund := 'session';
    elsif k.raum_fest and k.stift = any (r_ids) and r_zahl[array_position(r_ids, k.stift)] < 5 then
      v_wahl := array_position(r_ids, k.stift); grund := 'stift';
    elsif k.raum_fest then
      -- W1 (Entscheidung 2): Ein fester Termin landet nie still in einem anderen Raum. Sein Raum ist voll
      -- oder hat keinen Coach: Er bleibt ohne Raum, bis jemand ihn von Hand verschiebt.
      grund := case when k.stift = any (r_ids) then 'raum_voll' else 'raum_zu' end;
    else
      for i in 1 .. cardinality(r_ids) loop
        if r_zahl[i] < 5 and strpos(r_fach[i], v_fach) > 0 then v_wahl := i; exit; end if;
      end loop;
      if v_wahl is null then
        for i in 1 .. cardinality(r_ids) loop
          if r_zahl[i] = 0 then v_wahl := i; exit; end if;
        end loop;
      end if;
      if v_wahl is null then
        for i in 1 .. cardinality(r_ids) loop
          if r_zahl[i] < 5 then v_wahl := i; exit; end if;
        end loop;
      end if;
    end if;

    termin_id := k.id; student_id := k.student_id; fach := nullif(k.f, '');
    if v_wahl is null then
      raum_id := null;
    else
      raum_id := r_ids[v_wahl];
      r_zahl[v_wahl] := r_zahl[v_wahl] + 1;
      if strpos(r_fach[v_wahl], v_fach) = 0 then r_fach[v_wahl] := r_fach[v_wahl] || v_fach; end if;
    end if;
    return next;
  end loop;
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_plan_rechnen(p_vertrag_id uuid, p_heute date, p_stammplaetze jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE(datum date, slot_zeit_id uuid, stammplatz_id uuid, ergebnis text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
      select s.id, s.wochentag, s.slot_zeit_id, s.takt, s.gueltig_ab, s.gueltig_bis, s.raum_id
        from public.stammplaetze s
       where p_stammplaetze is null and s.vertrag_id = v.id
      union all
      select (x ->> 'stammplatz_id')::uuid, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid,
             x ->> 'takt', (x ->> 'gueltig_ab')::date, (x ->> 'gueltig_bis')::date, nullif(x ->> 'raum_id', '')::uuid
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
      select g::date as d, sp.slot_zeit_id as z, sp.id as sp_id, sp.raum_id as r, z.beginn
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
    -- W1: Ein vorhandener Termin zählt für einen Stammplatz mit Raum nur, wenn er zu diesem Stammplatz gehört
    -- oder schon fest in dessen Raum sitzt; sonst wird er wie ein neuer Termin geprüft (Raum gewechselt).
    select k.d, k.z, k.sp_id, k.r,
           exists (select 1 from public.kind_termine kt
                    where kt.student_id = v.student_id and kt.datum = k.d and kt.slot_zeit_id = k.z
                      and kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null
                      and kt.datum >= p_heute
                      and (k.r is null or kt.stammplatz_id = k.sp_id or (kt.raum_fest and kt.raum_id = k.r))) as da
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
    elsif c.r is not null then
      -- W1 (Entscheidung 2): Stammplatz mit Raum nur in diesen Raum, wenn er offen ist und Platz hat.
      if public.slots_raum_offen(c.d, c.z, c.r)
         and public.slots_raum_platz(c.d, c.z, c.r, v.student_id)
         and not public.slots_art_konflikt(v.student_id, c.d, c.z) then
        ergebnis := 'neu'; v_rest := v_rest - 1;
      else
        ergebnis := 'uebersprungen';
      end if;
    -- SL2b (Entscheidung 4): ein Termin mit Kindern der anderen Art zählt wie ein voller Slot.
    elsif public.slot_kapazitaet(c.d, c.z) - public.slot_belegt(c.d, c.z, v.student_id) > 0
          and not public.slots_art_konflikt(v.student_id, c.d, c.z) then
      ergebnis := 'neu'; v_rest := v_rest - 1;
    else
      ergebnis := 'uebersprungen';
    end if;
    return next;
  end loop;
end;
$function$;

CREATE OR REPLACE FUNCTION public.termine_planen(p_student_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
       and x.vertrag_ende is not null
       -- Nachbesserung (Consensus-Befund 6): auch ein vorverlegter Stichtag räumt künftige Zeilen ab.
       and (x.vertrag_ende >= v_heute
            or exists (select 1 from public.kind_termine k where k.vertrag_id = x.id and k.datum >= v_heute))
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
    -- W1: Wechselt der Stammplatz (neuer Stammplatz mit Raum), zieht der Termin in dessen Raum.
    update public.kind_termine kt
       set stammplatz_id = p.stammplatz_id,
           raum_id = coalesce(s.raum_id, kt.raum_id),
           raum_fest = case when s.raum_id is not null then true else kt.raum_fest end
      from slots_plan_tmp p
      join public.stammplaetze s on s.id = p.stammplatz_id
     where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
       and kt.session_id is null and kt.datum = p.datum and kt.slot_zeit_id = p.slot_zeit_id
       and kt.stammplatz_id is distinct from p.stammplatz_id;
    -- W1 (Entscheidung 2): Termine aus einem Stammplatz mit Raum entstehen fest in diesem Raum.
    insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, stammplatz_id,
                                     raum_id, raum_fest, angelegt_von)
    select p_student_id, v.id, p.datum, p.slot_zeit_id, 'stammplatz', p.stammplatz_id,
           s.raum_id, s.raum_id is not null, auth.uid()
      from slots_plan_tmp p
      join public.stammplaetze s on s.id = p.stammplatz_id
     where p.ergebnis = 'neu'
       and not exists (select 1 from public.kind_termine kt
                        where kt.student_id = p_student_id and kt.datum = p.datum and kt.slot_zeit_id = p.slot_zeit_id
                          and kt.herkunft = 'stammplatz' and kt.zustand = 'planned' and kt.session_id is null);
  end loop;
end;
$function$;

-- ============================================================================
-- 3  Prüfung je Raum, Stammplatz vergeben
-- ============================================================================

CREATE OR REPLACE FUNCTION public.slots_stammplatz_gruende(p_student_id uuid, p_zeilen jsonb, p_ab date, p_heute date, p_ausser uuid[] DEFAULT '{}'::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    select (x.o - 1)::int as i, (x.v ->> 'wochentag')::int as w, (x.v ->> 'slot_zeit_id')::uuid as sz, x.v ->> 'takt' as t,
           nullif(x.v ->> 'raum_id', '')::uuid as r
      from jsonb_array_elements(coalesce(p_zeilen, '[]')) with ordinality x(v, o)
  loop
    if z.w is null or z.w not between 1 and 5 or z.t is null or z.t not in ('woechentlich', 'a_woche', 'b_woche')
       or z.sz is null or not public.slots_zeit_aktiv(z.sz, coalesce(p_ab, p_heute))
       or (z.r is not null and not exists (select 1 from public.raeume x
                                            where x.id = z.r and (x.inaktiv_ab is null or coalesce(p_ab, p_heute) < x.inaktiv_ab))) then
      perform public.slots_fehler('22023', 'Stammplatz: Zeile ' || (z.i + 1) || ' ist unvollständig oder Uhrzeit bzw. Raum ist nicht aktiv');
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

    if z.r is not null then
      -- W1 (Entscheidung 3): je Raum. SL002 = dieser Raum hat zu der Zeit keinen Coach, SL001 = dieser Raum ist voll.
      for f in
        select x.datum from public.slots_naechste_termine_frei(z.w, z.sz, z.t, greatest(p_ab, p_heute), p_student_id) x
         order by x.datum
      loop
        if not public.slots_raum_offen(f.datum, z.sz, z.r) then
          v_out := v_out || jsonb_build_object('code', 'SL002', 'zeile', z.i, 'datum', f.datum);
          exit;
        elsif public.slots_art_konflikt(p_student_id, f.datum, z.sz) then
          v_out := v_out || jsonb_build_object('code', 'SL013', 'zeile', z.i, 'datum', f.datum);
          exit;
        elsif not public.slots_raum_platz(f.datum, z.sz, z.r, p_student_id) then
          v_out := v_out || jsonb_build_object('code', 'SL001', 'zeile', z.i, 'datum', f.datum);
          exit;
        end if;
      end loop;
    else
      -- Ohne Raum (Altbestand, Vorschau ohne Raum): je Slot wie bisher.
      -- SL002 / SL001: einer der nächsten sechs Termine ab "gültig ab" ohne Raum oder voll.
      -- SL2b (Entscheidung 4): SL013, wenn dort schon ein Kind der anderen Art sitzt (vor SL001).
      for f in
        select * from public.slots_naechste_termine_frei(z.w, z.sz, z.t, greatest(p_ab, p_heute), p_student_id)
         order by datum
      loop
        if f.kapazitaet = 0 then
          v_out := v_out || jsonb_build_object('code', 'SL002', 'zeile', z.i, 'datum', f.datum);
          exit;
        elsif public.slots_art_konflikt(p_student_id, f.datum, z.sz) then
          v_out := v_out || jsonb_build_object('code', 'SL013', 'zeile', z.i, 'datum', f.datum);
          exit;
        elsif f.belegt >= f.kapazitaet then
          v_out := v_out || jsonb_build_object('code', 'SL001', 'zeile', z.i, 'datum', f.datum);
          exit;
        end if;
      end loop;
    end if;
  end loop;
  return v_out;
end;
$function$;

CREATE OR REPLACE FUNCTION public.stammplatz_vergeben(p_student_id uuid, p_zeilen jsonb, p_ab date, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  perform public.slots_raum_pruefen(p_zeilen, 'stammplatz_vergeben');
  perform public.slots_gruende_werfen(public.slots_stammplatz_gruende(p_student_id, p_zeilen, p_ab, v_heute));
  v_vertrag := public.slots_vertrag_am(p_student_id, p_ab);

  with neu as (
    insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, raum_id, angelegt_von)
    select p_student_id, v_vertrag, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid, x ->> 'takt', p_ab,
           nullif(x ->> 'raum_id', '')::uuid, auth.uid()
      from jsonb_array_elements(p_zeilen) x
    returning id
  )
  select array_agg(id) into v_ids from neu;

  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('stammplatz_ids', to_jsonb(v_ids),
                            'planbilanz', public.slots_planbilanz(v_vertrag, v_heute));
end;
$function$;

-- ============================================================================
-- 4  stammplatz_aendern und zusatztermin_buchen mit Raum (ersetzt, nicht überladen)
-- ============================================================================

drop function public.stammplatz_aendern(uuid, date, integer, uuid, text, timestamp with time zone);

CREATE FUNCTION public.stammplatz_aendern(p_id uuid, p_ab date, p_wochentag integer, p_slot_zeit_id uuid, p_takt text, p_jetzt timestamp with time zone DEFAULT now(), p_raum_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  s       public.stammplaetze;
  v_raum  uuid;
  v_zeile jsonb;
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
  -- W1: Ohne p_raum_id bleibt der Raum des bisherigen Stammplatzes; ohne beide fehlt der Raum.
  v_raum := coalesce(p_raum_id, s.raum_id);
  v_zeile := jsonb_build_array(jsonb_build_object('wochentag', p_wochentag, 'slot_zeit_id', p_slot_zeit_id,
                                                  'takt', p_takt, 'raum_id', v_raum));
  perform public.slots_raum_pruefen(v_zeile, 'stammplatz_aendern');
  perform public.slots_gruende_werfen(
    public.slots_stammplatz_gruende(s.student_id, v_zeile, p_ab, v_heute, array[p_id]));

  -- Der alte endet am Vortag (Anforderung E 31), der neue übernimmt sein Ende.
  update public.stammplaetze
     set gueltig_bis = greatest(s.gueltig_ab - 1, p_ab - 1), beendet_am = now(), beendet_von = auth.uid()
   where id = p_id;
  insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, gueltig_bis,
                                   vorgaenger_id, raum_id, angelegt_von)
  values (s.student_id, coalesce(public.slots_vertrag_am(s.student_id, p_ab), s.vertrag_id), p_wochentag,
          p_slot_zeit_id, p_takt, p_ab, s.gueltig_bis, p_id, v_raum, auth.uid())
  returning id into v_id;

  perform public.termine_planen(s.student_id, v_jetzt);
  return jsonb_build_object('stammplatz_id', v_id,
                            'planbilanz', public.slots_planbilanz(public.slots_vertrag(s.student_id, v_heute), v_heute));
end;
$function$;

revoke all on function public.stammplatz_aendern(uuid, date, integer, uuid, text, timestamp with time zone, uuid) from public, anon;
grant execute on function public.stammplatz_aendern(uuid, date, integer, uuid, text, timestamp with time zone, uuid) to authenticated;

drop function public.zusatztermin_buchen(uuid, date, uuid, timestamp with time zone);

CREATE FUNCTION public.zusatztermin_buchen(p_student_id uuid, p_datum date, p_zeit_id uuid, p_jetzt timestamp with time zone DEFAULT now(), p_raum_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_vorher date[];
  v_id    uuid;
  v_aus   jsonb;
begin
  perform public.slots_admin_pruefen('zusatztermin_buchen');
  perform public.slots_sperren();
  -- W1 (Entscheidung 4): mit Raum prüft SL002/SL001 diesen Raum, der Termin sitzt fest dort.
  perform public.slots_code_werfen(public.slots_zusatz_code_raum(p_student_id, p_datum, p_zeit_id, v_jetzt, p_raum_id),
                                   'zusatztermin_buchen');
  v_vorher := public.slots_beweglich(p_student_id, v_heute);
  insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, raum_id, raum_fest, angelegt_von)
  values (p_student_id, public.slots_vertrag_am(p_student_id, p_datum), p_datum, p_zeit_id, 'zusatz',
          p_raum_id, p_raum_id is not null, auth.uid())
  returning id into v_id;
  v_aus := public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('termin_id', v_id,
    'verdraengt', (select to_jsonb(coalesce(array_agg(d order by d), '{}')) from unnest(v_vorher) d
                    where d <> all (public.slots_beweglich(p_student_id, v_heute))),
    'ausgelassen', v_aus);
end;
$function$;

revoke all on function public.zusatztermin_buchen(uuid, date, uuid, timestamp with time zone, uuid) from public, anon;
grant execute on function public.zusatztermin_buchen(uuid, date, uuid, timestamp with time zone, uuid) to authenticated;

-- Weiterführen übernimmt den Raum des Vorgängers (ohne Raum: raum_fehlt wie bei jedem neuen Stammplatz).
CREATE OR REPLACE FUNCTION public.slots_weiterfuehren_vorschlag(p_student_id uuid, p_heute date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
                                                                    'beginn', z.beginn, 'raum_id', s.raum_id)
                                                order by s.wochentag, z.beginn)
                                 from public.stammplaetze s join public.slot_zeiten z on z.id = s.slot_zeit_id
                                where s.vertrag_id = n.vorgaenger_id
                                  and s.gueltig_ab <= public.slots_vertrag_planende(n.vorgaenger_id)
                                  and coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_vertrag_planende(n.vorgaenger_id)),
                              '[]'))
    from neu n;
$function$;

CREATE OR REPLACE FUNCTION public.stammplaetze_weiterfuehren(p_student_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  perform public.slots_raum_pruefen(v_vor -> 'zeilen', 'stammplaetze_weiterfuehren');
  perform public.slots_gruende_werfen(
    public.slots_stammplatz_gruende(p_student_id, v_vor -> 'zeilen', (v_vor ->> 'ab')::date, v_heute));

  with neu as (
    insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, vorgaenger_id,
                                     raum_id, angelegt_von)
    select p_student_id, (v_vor ->> 'vertrag_id')::uuid, (x ->> 'wochentag')::smallint, (x ->> 'slot_zeit_id')::uuid,
           x ->> 'takt', (v_vor ->> 'ab')::date, (x ->> 'vorgaenger_id')::uuid, nullif(x ->> 'raum_id', '')::uuid, auth.uid()
      from jsonb_array_elements(v_vor -> 'zeilen') x
    returning id
  )
  select array_agg(id) into v_ids from neu;

  perform public.termine_planen(p_student_id, v_jetzt);
  return jsonb_build_object('stammplatz_ids', to_jsonb(v_ids),
                            'planbilanz', public.slots_planbilanz((v_vor ->> 'vertrag_id')::uuid, v_heute));
end;
$function$;

-- Vorschau der Planbilanz mit Raum (die Planung prüft dann je Raum).
CREATE OR REPLACE FUNCTION public.slots_planbilanz_vorschau(p_student_id uuid, p_zeilen jsonb, p_ab date, p_ersetzt uuid[] DEFAULT NULL::uuid[], p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
           'gueltig_ab', s.gueltig_ab, 'raum_id', s.raum_id,
           'gueltig_bis', case when s.id = any (coalesce(v_ersetzt, '{}'))
                               then greatest(s.gueltig_ab - 1, p_ab - 1) else s.gueltig_bis end)), '[]')
    into v_sp
    from public.stammplaetze s where s.vertrag_id = v_vertrag;
  select v_sp || coalesce(jsonb_agg(jsonb_build_object(
           'stammplatz_id', null, 'wochentag', (x ->> 'wochentag')::int, 'slot_zeit_id', x ->> 'slot_zeit_id',
           'takt', x ->> 'takt', 'gueltig_ab', p_ab, 'gueltig_bis', null, 'raum_id', x ->> 'raum_id')), '[]')
    into v_sp
    from jsonb_array_elements(coalesce(p_zeilen, '[]')) x;

  v_pb := case when v_vertrag is not null then public.slots_planbilanz(v_vertrag, v_heute, v_sp) end;
  return jsonb_build_object(
    'planbilanz', v_pb,
    'terminzahl', v_pb -> 'terminzahl', 'letzter_termin', v_pb -> 'letzter_termin',
    'uebersprungen', coalesce(v_pb -> 'uebersprungen', '[]'),
    'gruende', public.slots_stammplatz_gruende(p_student_id, p_zeilen, p_ab, v_heute, coalesce(v_ersetzt, '{}')));
end;
$function$;

-- ============================================================================
-- 5  stammplatz_vorschau: die nächsten sechs Wochen mit Grund je Datum
-- ============================================================================

CREATE FUNCTION public.stammplatz_vorschau(p_student_id uuid, p_wochentag integer, p_slot_zeit_id uuid, p_raum_id uuid, p_takt text, p_ab date, p_ersetzt uuid[] DEFAULT NULL::uuid[], p_jetzt timestamp with time zone DEFAULT now())
 RETURNS TABLE(datum date, ergebnis text, anlass text, belegt integer, coach_id uuid, coach_name text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_heute   date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_ab      date := greatest(coalesce(p_ab, v_heute), v_heute);
  v_erster  date;
  v_vertrag uuid;
  v_sp      jsonb;
  v_plan    jsonb := '[]';
  v_coach   uuid;
  d         date;
  i         integer;
begin
  perform public.slots_admin_pruefen('stammplatz_vorschau');
  if p_wochentag is null or p_wochentag not between 1 and 5 or p_slot_zeit_id is null or p_raum_id is null
     or p_takt is null or p_takt not in ('woechentlich', 'a_woche', 'b_woche') then
    perform public.slots_fehler('22023', 'stammplatz_vorschau: Wochentag, Uhrzeit, Raum oder Takt fehlt');
  end if;
  v_erster := v_ab + (p_wochentag - extract(isodow from v_ab)::int + 7) % 7;
  v_vertrag := coalesce(public.slots_vertrag_am(p_student_id, v_erster), public.slots_vertrag(p_student_id, v_heute));

  -- Budget wie die Planung: bestehende Stammplätze des Vertrags plus dieser. Ab p_ab ersetzt sind p_ersetzt (Ändern),
  -- ohne Angabe die am selben Wochentag.
  if v_vertrag is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
             'stammplatz_id', s.id, 'wochentag', s.wochentag, 'slot_zeit_id', s.slot_zeit_id, 'takt', s.takt,
             'gueltig_ab', s.gueltig_ab, 'raum_id', s.raum_id,
             'gueltig_bis', case when (case when p_ersetzt is null then s.wochentag = p_wochentag else s.id = any (p_ersetzt) end)
                                      and coalesce(s.gueltig_bis, v_ab) >= v_ab
                                 then greatest(s.gueltig_ab - 1, v_ab - 1) else s.gueltig_bis end)), '[]')
      into v_sp
      from public.stammplaetze s where s.vertrag_id = v_vertrag;
    v_sp := v_sp || jsonb_build_array(jsonb_build_object(
              'stammplatz_id', null, 'wochentag', p_wochentag, 'slot_zeit_id', p_slot_zeit_id, 'takt', p_takt,
              'gueltig_ab', v_ab, 'gueltig_bis', null, 'raum_id', p_raum_id));
    select coalesce(jsonb_agg(jsonb_build_object('datum', r.datum, 'ergebnis', r.ergebnis)), '[]') into v_plan
      from public.slots_plan_rechnen(v_vertrag, v_heute, v_sp) r
     where r.stammplatz_id is null;
  end if;

  for i in 0 .. 5 loop
    d := v_erster + 7 * i;
    datum := d; anlass := null; belegt := null; coach_id := null; coach_name := null;
    if exists (select 1 from public.feiertage_nrw f where f.datum = d) then
      ergebnis := 'feiertag'; anlass := public.slots_anlass(d);
    elsif exists (select 1 from public.ferien_nrw f where d between f.von and f.bis) then
      ergebnis := 'ferien'; anlass := public.slots_anlass(d);
    elsif not public.slots_takt_passt(p_takt, d) then
      ergebnis := 'andere_woche';
    else
      select r.coach_id into v_coach from public.slot_raeume(d, d) r
       where r.slot_zeit_id = p_slot_zeit_id and r.raum_id = p_raum_id and r.offen;
      coach_id := v_coach;
      coach_name := (select p.full_name from public.profiles p where p.id = v_coach);
      belegt := public.slots_raum_belegt(d, p_slot_zeit_id, p_raum_id, p_student_id);
      if v_coach is null then
        ergebnis := 'ohne_coach';
      elsif not public.slots_raum_platz(d, p_slot_zeit_id, p_raum_id, p_student_id)
            or public.slots_art_konflikt(p_student_id, d, p_slot_zeit_id) then
        ergebnis := 'voll';
      elsif public.slots_vertrag_am(p_student_id, d) is null
            or exists (select 1 from jsonb_array_elements(v_plan) x
                        where (x ->> 'datum')::date = d and x ->> 'ergebnis' = 'ohne_budget') then
        ergebnis := 'ohne_budget';
      else
        ergebnis := 'termin';
      end if;
    end if;
    return next;
  end loop;
end;
$function$;

revoke all on function public.stammplatz_vorschau(uuid, integer, uuid, uuid, text, date, uuid[], timestamp with time zone) from public, anon;
grant execute on function public.stammplatz_vorschau(uuid, integer, uuid, uuid, text, date, uuid[], timestamp with time zone) to authenticated;

-- ============================================================================
-- 6  slots_kandidaten_alle: alle Kinder mit Grund statt Filter
-- ============================================================================

CREATE FUNCTION public.slots_kandidaten_alle(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS TABLE(student_id uuid, name text, klasse integer, fach text, ist_test boolean, stammplatz_kurz text, stammplaetze jsonb, code text, datum date)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
begin
  perform public.slots_admin_pruefen('slots_kandidaten_alle');
  if p_datum is null or p_zeit_id is null then
    perform public.slots_fehler('22023', 'slots_kandidaten_alle: Datum oder Uhrzeit fehlt');
  end if;
  return query
  with k as (
    select s.id,
           public.slots_vertrag_am(s.id, p_datum) as vam,
           (select v.id from public.vertraege v where v.student_id = s.id and v.status = 'abgeschlossen'
             order by v.vertragsbeginn desc nulls last limit 1) as vletzt,
           (select min(v.vertragsbeginn) from public.vertraege v
             where v.student_id = s.id and v.status = 'abgeschlossen' and v.widerrufen_am is null
               and v.vertragsbeginn > p_datum) as ab
      from public.students s
     where not s.is_provisional
       and (s.ist_test or exists (select 1 from public.vertraege v where v.student_id = s.id and v.status = 'abgeschlossen'))
  ),
  sp as (
    select x.student_id,
           string_agg((array['Mo', 'Di', 'Mi', 'Do', 'Fr'])[x.wochentag] || ' ' || public.slots_hhmm(z.beginn)
                        || coalesce(' · ' || r.name, '')
                        || case x.takt when 'a_woche' then ' (A-Woche)' when 'b_woche' then ' (B-Woche)' else '' end,
                      ', ' order by x.wochentag, z.beginn) as kurz,
           jsonb_agg(jsonb_build_object('wochentag', x.wochentag, 'zeit_id', x.slot_zeit_id,
                                        'beginn', public.slots_hhmm(z.beginn), 'takt', x.takt,
                                        'raum_id', x.raum_id, 'raum_name', r.name)
                     order by x.wochentag, z.beginn) as liste
      from public.stammplaetze x
      join public.slot_zeiten z on z.id = x.slot_zeit_id
      left join public.raeume r on r.id = x.raum_id
     where least(coalesce(x.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(x.vertrag_id))
           >= greatest(v_heute, x.gueltig_ab)
     group by x.student_id
  )
  select k.id, i ->> 'name', (i ->> 'klasse')::int, i ->> 'fach', coalesce((i ->> 'ist_test')::boolean, false),
         sp.kurz, coalesce(sp.liste, '[]'::jsonb),
         -- W1 (Entscheidung 6): dieselben Regeln wie zusatztermin_buchen, als Grund statt Filter.
         case when k.vam is not null then public.slots_zusatz_code_raum(k.id, p_datum, p_zeit_id, v_jetzt, p_raum_id)
              when k.vletzt is null then 'kein_vertrag'
              when k.ab is not null then 'vertrag_ab'
              else 'SL006' end,
         case when k.vam is null and k.vletzt is not null then k.ab end
    from k
    cross join lateral public.slots_kind_info(k.id, coalesce(k.vam, k.vletzt)) i
    left join sp on sp.student_id = k.id
   order by i ->> 'name', k.id;
end;
$function$;

revoke all on function public.slots_kandidaten_alle(date, uuid, uuid, timestamp with time zone) from public, anon;
grant execute on function public.slots_kandidaten_alle(date, uuid, uuid, timestamp with time zone) to authenticated;

-- ============================================================================
-- 7  Wochenplan, Termin, Tag: Räume mit Kindern ohne Coach, Kennzahlen mit Testkonten
-- ============================================================================

CREATE OR REPLACE FUNCTION public.slots_zelle(p_datum date, p_zeit_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with r0 as (select * from public.slot_raeume(p_datum, p_datum) x where x.slot_zeit_id = p_zeit_id),
  t as (
    select t.*, kt.vertrag_id, s.ist_test, case when t.grund = 'raum_zu' then kt.raum_id end as zu_raum
      from public.slot_zuteilung(p_datum, p_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
      join public.students s on s.id = t.student_id
  ),
  -- W1 (Entscheidung 7): Räume mit festen Kindern, aber ohne Coach, stehen mit offen = false in der Liste.
  r as (
    select r0.raum_id, r0.raum_name, r0.offen, r0.art, r0.coach_id, r0.stamm_coach_id from r0
    union all
    select x.id, x.name, false, 'ohne_schicht', null::uuid, null::uuid from public.raeume x
     where x.id in (select t.zu_raum from t) and not x.id in (select r0.raum_id from r0)
  )
  select jsonb_build_object(
    'kapazitaet', 5 * (select count(*) from r where r.offen),
    'belegt', (select count(*) from t),
    -- W1: Kinder im Raum ohne Coach zählen dort (raeume[].belegt), nicht zusätzlich als ohne Raum.
    'ohne_raum', (select count(*) from t where t.raum_id is null and t.zu_raum is null),
    -- SL2b (Entscheidungen 2 und 3): davon Testkonten. belegt zählt sie mit, der Platz ist belegt.
    'test', (select count(*) from t where t.ist_test),
    'test_ohne_raum', (select count(*) from t where t.ist_test and t.raum_id is null and t.zu_raum is null),
    'coach_fehlt', (select count(*) from r where r.art = 'faellt_aus' and r.stamm_coach_id is not null),
    'raeume', coalesce((select jsonb_agg(jsonb_build_object(
                 'raum_id', r.raum_id, 'name', r.raum_name, 'offen', r.offen, 'art', r.art,
                 'coach_id', r.coach_id, 'coach_name', (select p.full_name from public.profiles p where p.id = r.coach_id),
                 'belegt', (select count(*) from t where t.raum_id = r.raum_id or t.zu_raum = r.raum_id))
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
                                                  'vergangen', public.slots_termin_beginn(g::date, z.id) <= v_jetzt,
                                                  -- W1: Die Stunde läuft gerade (für „läuft gerade“ im Raster).
                                                  'laeuft', public.slots_termin_beginn(g::date, z.id) <= v_jetzt
                                                            and public.slots_termin_beginn(g::date, z.id) + interval '1 hour' > v_jetzt)
                            order by g, z.beginn), '[]')
    into v_zellen
    from generate_series(v_mo, v_mo + 4, interval '1 day') g
    join public.slot_zeiten z on z.aktiv_ab <= g::date and (z.inaktiv_ab is null or g::date < z.inaktiv_ab)
   where public.betriebstag(g::date);

  -- SL2b (Entscheidung 3): Die Kennzahlen zählen Testkonten nicht mit. W1 (Entscheidung 7): daneben stehen sie sichtbar.
  select jsonb_build_object('ohne_stammplatz', count(*) filter (where b.ohne_stammplatz and not s.ist_test),
                            'ohne_stammplatz_laufend', count(*) filter (where b.ohne_stammplatz and b.laeuft and not s.ist_test),
                            'ohne_stammplatz_test', count(*) filter (where b.ohne_stammplatz and s.ist_test))
    into v_kinder
    from public.slots_kinder_basis(v_heute) b
    join public.students s on s.id = b.student_id;

  return jsonb_build_object(
    'montag', v_mo, 'kw', extract(week from v_mo)::int, 'a_woche', extract(week from v_mo)::int % 2 = 1,
    'heute', v_heute,
    'tage', v_tage, 'zeiten', v_zeiten, 'zellen', v_zellen,
    'kopf', jsonb_build_object(
      'plaetze', (select coalesce(sum((c ->> 'kapazitaet')::int), 0) from jsonb_array_elements(v_zellen) c),
      'belegt', (select coalesce(sum((c ->> 'belegt')::int - (c ->> 'test')::int), 0) from jsonb_array_elements(v_zellen) c),
      'belegt_test', (select coalesce(sum((c ->> 'test')::int), 0) from jsonb_array_elements(v_zellen) c),
      'auslastung', (select case when sum((c ->> 'kapazitaet')::int) > 0
                                 then round(sum((c ->> 'belegt')::int - (c ->> 'test')::int)::numeric
                                            / sum((c ->> 'kapazitaet')::int), 3) end
                       from jsonb_array_elements(v_zellen) c),
      'auslastung_mit_test', (select case when sum((c ->> 'kapazitaet')::int) > 0
                                          then round(sum((c ->> 'belegt')::int)::numeric / sum((c ->> 'kapazitaet')::int), 3) end
                                from jsonb_array_elements(v_zellen) c),
      'raeume_ohne_coach', (select count(*) from jsonb_array_elements(v_zellen) c, jsonb_array_elements(c -> 'raeume') r
                             where not (r ->> 'offen')::boolean and (r ->> 'belegt')::int > 0),
      'ohne_raum', (select coalesce(sum((c ->> 'ohne_raum')::int - (c ->> 'test_ohne_raum')::int), 0)
                      from jsonb_array_elements(v_zellen) c),
      'erster_ohne_raum', (select jsonb_build_object('datum', c -> 'datum', 'zeit_id', c -> 'zeit_id')
                             from jsonb_array_elements(v_zellen) with ordinality x(c, o)
                            where (c ->> 'ohne_raum')::int - (c ->> 'test_ohne_raum')::int > 0 order by o limit 1),
      'ohne_stammplatz', v_kinder -> 'ohne_stammplatz',
      'ohne_stammplatz_laufend', v_kinder -> 'ohne_stammplatz_laufend',
      'ohne_stammplatz_test', v_kinder -> 'ohne_stammplatz_test'));
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_termin(p_datum date, p_zeit_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    select t.termin_id, t.raum_id, t.grund, case when t.grund = 'raum_zu' then kt.raum_id end as zu_raum,
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
  r0 as (select * from public.slot_raeume(p_datum, p_datum) x where x.slot_zeit_id = p_zeit_id),
  -- W1: Räume mit festen Kindern ohne Coach stehen mit ihren Kindern in der Liste (offen = false).
  r as (
    select r0.raum_id, r0.raum_name, r0.offen, r0.art, r0.coach_id, r0.stamm_coach_id from r0
    union all
    select x.id, x.name, false, 'ohne_schicht', null::uuid, null::uuid from public.raeume x
     where x.id in (select t.zu_raum from t) and not x.id in (select r0.raum_id from r0)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'raum_id', r.raum_id, 'name', r.raum_name, 'offen', r.offen, 'art', r.art,
           'coach_id', r.coach_id, 'coach_name', (select p.full_name from public.profiles p where p.id = r.coach_id),
           'stamm_coach_id', r.stamm_coach_id,
           'stamm_coach_name', (select p.full_name from public.profiles p where p.id = r.stamm_coach_id),
           'vertretung', r.art = 'vertretung',
           'session_id', s.id, 'gestartet', s.gestartet_am is not null,
           'gemischt', (select count(distinct coalesce(t.kind ->> 'fach', '')) from t
                         where t.raum_id = r.raum_id or t.zu_raum = r.raum_id) > 1,
           'kinder', coalesce((select jsonb_agg(t.kind order by t.kind ->> 'name') from t
                                where t.raum_id = r.raum_id or t.zu_raum = r.raum_id), '[]'))
         order by r.raum_name), '[]'),
         coalesce((select jsonb_agg(t.kind order by t.kind ->> 'name') from t where t.raum_id is null and t.zu_raum is null), '[]')
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
    'laeuft', v_beginn <= v_jetzt and v_beginn + interval '1 hour' > v_jetzt,
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
$function$;

CREATE OR REPLACE FUNCTION public.slots_tag(p_datum date, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
               'art', r.art, 'offen', r.offen, 'kapazitaet', 5,
               'belegt', b.belegt + b.zu,
               'session_id', s.id, 'gestartet', s.gestartet_am is not null, 'status', s.status)
             order by z.beginn, r.raum_name)
        from (
          select x.slot_zeit_id, x.raum_id, x.raum_name, x.coach_id, x.art, x.offen
            from public.slot_raeume(p_datum, p_datum) x
          union all
          -- W1: Räume mit festen Kindern, aber ohne Schicht und ohne Abweichung.
          select f.slot_zeit_id, y.id, y.name, null::uuid, 'ohne_schicht', false
            from (select distinct kt.slot_zeit_id, kt.raum_id from public.kind_termine kt
                   where kt.datum = p_datum and kt.raum_fest and kt.zustand in ('planned', 'present')) f
            join public.raeume y on y.id = f.raum_id
           where not exists (select 1 from public.slot_raeume(p_datum, p_datum) w
                              where w.slot_zeit_id = f.slot_zeit_id and w.raum_id = f.raum_id)
        ) r
        join public.slot_zeiten z on z.id = r.slot_zeit_id
        left join lateral (select * from public.slots_session(p_datum, r.slot_zeit_id, r.raum_id)) s on true
        cross join lateral (
          select count(*) filter (where t.raum_id = r.raum_id) as belegt,
                 count(*) filter (where t.grund = 'raum_zu' and kt.raum_id = r.raum_id) as zu
            from public.slot_zuteilung(p_datum, r.slot_zeit_id) t
            join public.kind_termine kt on kt.id = t.termin_id
        ) b
       where r.offen or s.id is not null or b.zu > 0), '[]'),
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
$function$;

-- Stammplatz mit Raum und Coach der Schicht (W3: Kinderliste und Kind-Seite).
CREATE OR REPLACE FUNCTION public.slots_stammplatz_json(p_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select jsonb_build_object('id', s.id, 'wochentag', s.wochentag, 'zeit_id', s.slot_zeit_id,
                            'beginn', public.slots_hhmm(z.beginn), 'takt', s.takt,
                            'gueltig_ab', s.gueltig_ab, 'gueltig_bis', s.gueltig_bis, 'vorgaenger_id', s.vorgaenger_id,
                            'raum_id', s.raum_id, 'raum_name', r.name, 'coach_id', c.coach_id, 'coach_name', p.full_name)
    from public.stammplaetze s
    join public.slot_zeiten z on z.id = s.slot_zeit_id
    left join public.raeume r on r.id = s.raum_id
    left join lateral (
      select x.coach_id from public.stammschichten x
       where x.raum_id = s.raum_id and x.wochentag = s.wochentag and x.slot_zeit_id = s.slot_zeit_id
         and x.gueltig_ab <= greatest(s.gueltig_ab, public.slots_berlin_tag(now()))
         and coalesce(x.gueltig_bis, 'infinity'::date) >= greatest(s.gueltig_ab, public.slots_berlin_tag(now()))
       order by x.gueltig_ab desc
       limit 1
    ) c on true
    left join public.profiles p on p.id = c.coach_id
   where s.id = p_id;
$function$;

-- Je Stammschicht die Kinder mit Stammplatz in diesem Raum zu dieser Zeit (W4: Blöcke, Raum ändern).
CREATE OR REPLACE FUNCTION public.slots_coaches(p_montag date, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
              'raum_id', s.raum_id, 'raum_name', r.name, 'gueltig_ab', s.gueltig_ab, 'gueltig_bis', s.gueltig_bis,
              'kinder', (select count(distinct sp.student_id) from public.stammplaetze sp
                          where sp.raum_id = s.raum_id and sp.wochentag = s.wochentag and sp.slot_zeit_id = s.slot_zeit_id
                            and least(coalesce(sp.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(sp.vertrag_id))
                                >= greatest(v_mo, sp.gueltig_ab)))
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
$function$;

-- ============================================================================
-- 8  stammschicht_block_anlegen: ein Block von–bis, alles oder nichts
-- ============================================================================

CREATE FUNCTION public.stammschicht_block_anlegen(p_coach_id uuid, p_wochentag integer, p_von_zeit_id uuid, p_bis_zeit_id uuid, p_raum_id uuid, p_gueltig_ab date DEFAULT NULL::date, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_ab    date := coalesce(p_gueltig_ab, public.slots_berlin_tag(public.slots_jetzt(p_jetzt)));
  v_von   time;
  v_bis   time;
  v_ids   uuid[] := '{}';
  v_id    uuid;
  v_raum  boolean;
  z       record;
begin
  perform public.slots_admin_pruefen('stammschicht_block_anlegen');
  perform public.slots_sperren();
  if not exists (select 1 from public.profiles p where p.id = p_coach_id and p.role = 'coach') then
    perform public.slots_fehler('22023', 'stammschicht_block_anlegen: kein Coach', 'kein_coach');
  end if;
  if p_wochentag is null or p_wochentag not between 1 and 5 then
    perform public.slots_fehler('22023', 'stammschicht_block_anlegen: Wochentag 1–5');
  end if;
  if v_ab < public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('SL007', 'stammschicht_block_anlegen: gültig ab liegt in der Vergangenheit');
  end if;
  select x.beginn into v_von from public.slot_zeiten x where x.id = p_von_zeit_id;
  select x.beginn into v_bis from public.slot_zeiten x where x.id = p_bis_zeit_id;
  if v_von is null or v_bis is null
     or not public.slots_zeit_aktiv(p_von_zeit_id, v_ab) or not public.slots_zeit_aktiv(p_bis_zeit_id, v_ab)
     or not exists (select 1 from public.raeume r where r.id = p_raum_id and (r.inaktiv_ab is null or v_ab < r.inaktiv_ab)) then
    perform public.slots_fehler('22023', 'stammschicht_block_anlegen: Uhrzeit oder Raum nicht aktiv');
  end if;
  if v_bis < v_von then
    perform public.slots_fehler('22023', 'stammschicht_block_anlegen: bis liegt vor von', 'von_bis');
  end if;

  -- Erst alle Stunden prüfen, dann anlegen: alles oder nichts (SL009, hint raum:HH:MM bzw. coach:HH:MM).
  for z in
    select x.id, x.beginn from public.slot_zeiten x
     where public.slots_zeit_aktiv(x.id, v_ab) and x.beginn between v_von and v_bis order by x.beginn
  loop
    select s.raum_id = p_raum_id into v_raum from public.stammschichten s
     where s.wochentag = p_wochentag and s.slot_zeit_id = z.id
       and (s.raum_id = p_raum_id or s.coach_id = p_coach_id)
       and coalesce(s.gueltig_bis, 'infinity'::date) >= v_ab
     order by (s.raum_id = p_raum_id) desc
     limit 1;
    if found then
      perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach) um ' || public.slots_hhmm(z.beginn),
                                  case when v_raum then 'raum:' else 'coach:' end || public.slots_hhmm(z.beginn));
    end if;
  end loop;

  for z in
    select x.id from public.slot_zeiten x
     where public.slots_zeit_aktiv(x.id, v_ab) and x.beginn between v_von and v_bis order by x.beginn
  loop
    insert into public.stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab, angelegt_von)
    values (p_coach_id, p_wochentag, z.id, p_raum_id, v_ab, auth.uid())
    returning id into v_id;
    v_ids := v_ids || v_id;
    perform public.slots_planen_slot(p_wochentag, z.id, v_jetzt);
  end loop;
  return jsonb_build_object('stammschicht_ids', to_jsonb(v_ids), 'stunden', cardinality(v_ids));
end;
$function$;

revoke all on function public.stammschicht_block_anlegen(uuid, integer, uuid, uuid, uuid, date, timestamp with time zone) from public, anon;
grant execute on function public.stammschicht_block_anlegen(uuid, integer, uuid, uuid, uuid, date, timestamp with time zone) to authenticated;

-- ============================================================================
-- 9  stammschicht_raum_wechseln: Schichten in einen anderen Raum, Kinder auf Wunsch mit
-- ============================================================================

CREATE FUNCTION public.stammschicht_raum_wechseln(p_ids uuid[], p_raum_id uuid, p_ab date, p_kinder_mitnehmen boolean DEFAULT false, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_jetzt   timestamptz := public.slots_jetzt(p_jetzt);
  v_heute   date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  s         record;
  sp        public.stammplaetze;
  v_id      uuid;
  v_schicht uuid[] := '{}';
  v_platz   uuid[] := '{}';
begin
  perform public.slots_admin_pruefen('stammschicht_raum_wechseln');
  perform public.slots_sperren();
  if p_ids is null or cardinality(p_ids) = 0 then
    perform public.slots_fehler('22023', 'stammschicht_raum_wechseln: keine Schichten');
  end if;
  if p_ab is null or p_ab < v_heute then
    perform public.slots_fehler('SL007', 'stammschicht_raum_wechseln: Datum liegt in der Vergangenheit');
  end if;
  if not exists (select 1 from public.raeume r where r.id = p_raum_id and r.aktiv_ab <= p_ab
                  and (r.inaktiv_ab is null or p_ab < r.inaktiv_ab)) then
    perform public.slots_fehler('22023', 'stammschicht_raum_wechseln: Raum nicht aktiv', 'raum_inaktiv');
  end if;
  perform 1 from public.stammschichten x where x.id = any (p_ids) for update;
  if (select count(*) from public.stammschichten x where x.id = any (p_ids))
     <> (select count(distinct u) from unnest(p_ids) u) then
    perform public.slots_fehler('P0002', 'stammschicht_raum_wechseln: Stammschicht nicht gefunden');
  end if;

  -- Erst alles prüfen (alles oder nichts).
  if exists (select 1 from public.stammschichten x where x.id = any (p_ids)
              group by x.wochentag, x.slot_zeit_id having count(*) > 1) then
    perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach): zwei Schichten derselben Stunde', 'doppelt');
  end if;
  for s in
    select x.*, z.beginn from public.stammschichten x join public.slot_zeiten z on z.id = x.slot_zeit_id
     where x.id = any (p_ids) order by x.wochentag, z.beginn
  loop
    if coalesce(s.gueltig_bis, 'infinity'::date) < p_ab then
      perform public.slots_fehler('22023', 'stammschicht_raum_wechseln: Schicht ist zu diesem Datum schon beendet');
    end if;
    if s.raum_id = p_raum_id then
      perform public.slots_fehler('22023', 'stammschicht_raum_wechseln: Schicht ist schon in diesem Raum', 'gleicher_raum');
    end if;
    if exists (select 1 from public.stammschichten y
                where y.raum_id = p_raum_id and y.wochentag = s.wochentag and y.slot_zeit_id = s.slot_zeit_id
                  and not y.id = any (p_ids) and coalesce(y.gueltig_bis, 'infinity'::date) >= p_ab) then
      perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach) um ' || public.slots_hhmm(s.beginn),
                                  'raum:' || public.slots_hhmm(s.beginn));
    end if;
    -- Mit Kindern: Im Zielraum sitzen danach höchstens fünf Kinder mit Stammplatz (SL001, hint raum:HH:MM).
    if coalesce(p_kinder_mitnehmen, false)
       and (select count(distinct x.student_id) from public.stammplaetze x
             where x.raum_id in (s.raum_id, p_raum_id) and x.wochentag = s.wochentag and x.slot_zeit_id = s.slot_zeit_id
               and least(coalesce(x.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(x.vertrag_id)) >= p_ab) > 5 then
      perform public.slots_fehler('SL001', 'Raum voll um ' || public.slots_hhmm(s.beginn), 'raum:' || public.slots_hhmm(s.beginn));
    end if;
  end loop;

  for s in
    select x.* from public.stammschichten x where x.id = any (p_ids)
  loop
    update public.stammschichten
       set gueltig_bis = greatest(s.gueltig_ab - 1, p_ab - 1), beendet_am = now(), beendet_von = auth.uid()
     where id = s.id;
    insert into public.stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab, gueltig_bis, angelegt_von)
    values (s.coach_id, s.wochentag, s.slot_zeit_id, p_raum_id, greatest(p_ab, s.gueltig_ab), s.gueltig_bis, auth.uid())
    returning id into v_id;
    v_schicht := v_schicht || v_id;

    -- Kinder hängen am Raum (Entscheidung 6). Nur auf Wunsch ziehen ihre Stammplätze mit, als Nachfolger.
    if coalesce(p_kinder_mitnehmen, false) then
      for sp in
        select * from public.stammplaetze x
         where x.raum_id = s.raum_id and x.wochentag = s.wochentag and x.slot_zeit_id = s.slot_zeit_id
           and least(coalesce(x.gueltig_bis, 'infinity'::date), public.slots_vertrag_planende(x.vertrag_id)) >= p_ab
         for update
      loop
        update public.stammplaetze
           set gueltig_bis = greatest(sp.gueltig_ab - 1, p_ab - 1), beendet_am = now(), beendet_von = auth.uid()
         where id = sp.id;
        insert into public.stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, gueltig_bis,
                                         vorgaenger_id, raum_id, angelegt_von)
        values (sp.student_id, coalesce(public.slots_vertrag_am(sp.student_id, greatest(p_ab, sp.gueltig_ab)), sp.vertrag_id),
                sp.wochentag, sp.slot_zeit_id, sp.takt, greatest(p_ab, sp.gueltig_ab), sp.gueltig_bis, sp.id, p_raum_id, auth.uid())
        returning id into v_id;
        v_platz := v_platz || v_id;
      end loop;
    end if;
  end loop;

  for s in
    select distinct x.wochentag, x.slot_zeit_id from public.stammschichten x where x.id = any (p_ids)
  loop
    perform public.slots_planen_slot(s.wochentag, s.slot_zeit_id, v_jetzt);
  end loop;
  return jsonb_build_object('stammschicht_ids', to_jsonb(v_schicht), 'stammplatz_ids', to_jsonb(v_platz),
                            'kinder', cardinality(v_platz));
end;
$function$;

revoke all on function public.stammschicht_raum_wechseln(uuid[], uuid, date, boolean, timestamp with time zone) from public, anon;
grant execute on function public.stammschicht_raum_wechseln(uuid[], uuid, date, boolean, timestamp with time zone) to authenticated;

-- ============================================================================
-- Rechte der internen Hilfen
-- ============================================================================

revoke all on function public.slots_raum_pflicht() from public, anon, authenticated;
revoke all on function public.slots_raum_pruefen(jsonb, text) from public, anon, authenticated;
revoke all on function public.slots_raum_offen(date, uuid, uuid) from public, anon, authenticated;
revoke all on function public.slots_raum_belegt(date, uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.slots_raum_platz(date, uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.slots_zusatz_code_raum(uuid, date, uuid, timestamp with time zone, uuid) from public, anon, authenticated;

commit;
