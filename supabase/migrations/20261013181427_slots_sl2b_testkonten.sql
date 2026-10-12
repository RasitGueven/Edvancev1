-- Slots SL2b, Teil 1: Testkonten in den Slots (Abnahme vor dem ersten echten Kind).
--
-- Entscheidungen Rasit 12.10.2026 (Paket SL2b), ändern Entscheidung 8 des Bauauftrags Slots:
--   1  Testkonten (ist_test) mit laufendem Vertrag bekommen Stammplätze und Termine.
--      slots_kind_zugelassen bleibt die eine Stelle; slots_kinder_basis fragt sie jetzt, statt selbst
--      ist_test zu filtern.
--   4  Testkonto und echtes Kind sitzen nie im selben Termin (Datum + Uhrzeit, alle Räume):
--      neue Hilfe slots_art_konflikt; SL013 in Stammplatz-Prüfung, Zusatztermin/Umbuchung und
--      Absage-Rücknahme; die Planung überspringt solche Daten (wie einen vollen Slot).
--   5  termin_session_anlegen legt die Session als Testlauf an, wenn im Termin nur Testkonten sitzen.
--      Der Trigger coaching_sessions_testlauf_pruefen (T4) bleibt unberührt und entscheidet, wer
--      testlauf = true beim Anlegen setzen darf (heute nur der Admin). Lehnt er ab (42501), meldet die
--      Funktion das mit Hinweis testlauf_nur_admin (offene-punkte-sl2b.md).
-- Belegung und Kapazität (slot_belegt) zählen Testkonten weiter mit: ein belegter Platz ist belegt.
-- Alle ersetzten Funktionen aus der Prod-Definition; Signatur, SECURITY, search_path und Rechte unverändert.

begin;

-- ============================================================================
-- Entscheidung 1: Zulassung
-- ============================================================================

CREATE OR REPLACE FUNCTION public.slots_kind_zugelassen(p_student_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  -- SL2b (Entscheidung 1): Testkonten sind zugelassen. Ob ein Kind eingeplant wird, entscheidet der Vertrag
  -- (slots_vertrag_am, slots_kinder_basis); hier zählt nur noch, dass es das Kind gibt.
  select exists (select 1 from public.students s where s.id = p_student_id);
$function$;

CREATE OR REPLACE FUNCTION public.slots_kinder_basis(p_heute date)
 RETURNS TABLE(student_id uuid, vertrag_id uuid, beginn date, stichtag date, laeuft boolean, ohne_stammplatz boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with v as (
    select distinct on (x.student_id) x.student_id, x.id, x.vertragsbeginn, x.vertrag_ende, x.einheiten
      from public.vertraege x
      join public.students s on s.id = x.student_id and public.slots_kind_zugelassen(s.id)
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
$function$;

-- ============================================================================
-- Entscheidung 4: Testkonto und echtes Kind nie im selben Termin
-- ============================================================================

-- Konflikt für p_student_id im Termin (Datum + Uhrzeit, alle Räume): Ein anderes Kind der anderen Art belegt
-- dort einen Platz (planned/present, wie slot_belegt), oder eine Session des Termins hat die andere Art
-- (testlauf <> ist_test). Die Session zählt auch leer, weil die Zuteilung später Kinder in sie legt.
create function public.slots_art_konflikt(p_student_id uuid, p_datum date, p_slot_zeit_id uuid)
returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  with ich as (
    select coalesce((select s.ist_test from public.students s where s.id = p_student_id), false) as test
  )
  select exists (select 1 from public.kind_termine kt
                   join public.students s on s.id = kt.student_id
                  where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id
                    and kt.zustand in ('planned', 'present')
                    and kt.student_id <> p_student_id
                    and s.ist_test <> (select ich.test from ich))
      or exists (select 1 from public.coaching_sessions cs
                  where cs.slot_zeit_id = p_slot_zeit_id
                    and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_slot_zeit_id)
                    and cs.testlauf <> (select ich.test from ich));
$$;

comment on function public.slots_art_konflikt(uuid, date, uuid) is
  'SL2b Entscheidung 4: true, wenn im Termin schon ein Kind bzw. eine Session der anderen Art (Testkonto/echt) ist.';

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
  end loop;
  return v_out;
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_gruende_werfen(p_gruende jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
      when 'SL013' then 'Testkonto und echtes Kind im selben Termin'
      else 'Stammplatz nicht möglich' end,
    g::text);
end;
$function$;

CREATE OR REPLACE FUNCTION public.slots_zusatz_code(p_student_id uuid, p_datum date, p_slot_zeit_id uuid, p_jetzt timestamp with time zone, p_ausser uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  -- SL2b (Entscheidung 4): Testkonto und echtes Kind nie im selben Termin.
  if public.slots_art_konflikt(p_student_id, p_datum, p_slot_zeit_id) then
    return 'SL013';
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
$function$;

CREATE OR REPLACE FUNCTION public.slots_code_werfen(p_code text, p_wer text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
    when 'SL013' then 'Testkonto und echtes Kind im selben Termin'
    else p_code end);
end;
$function$;

CREATE OR REPLACE FUNCTION public.absage_zuruecknehmen(p_termin_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
      -- Festgeschrieben: nicht löschen (Entscheidung 10), sondern ausfallen lassen (Consensus-Befund 4).
      update public.kind_termine set zustand = 'cancelled_by_us' where id = neu.id;
      perform public.slots_buchung_setzen(neu.id);
    else
      delete from public.kind_termine where id = neu.id;
    end if;
  end if;

  -- SL2b (Entscheidung 4): Inzwischen sitzt dort ein Kind der anderen Art (Testkonto/echt).
  if public.slots_art_konflikt(kt.student_id, kt.datum, kt.slot_zeit_id) then
    perform public.slots_code_werfen('SL013', 'absage_zuruecknehmen');
  end if;
  -- Platz inzwischen vergeben oder schon ein anderer Termin an dem Tag: keine Rücknahme.
  if public.slot_belegt(kt.datum, kt.slot_zeit_id, kt.student_id) >= public.slot_kapazitaet(kt.datum, kt.slot_zeit_id)
     or exists (select 1 from public.kind_termine x
                 where x.student_id = kt.student_id and x.datum = kt.datum and x.id <> kt.id
                   and x.zustand in ('planned', 'present', 'unexcused')
                   and not (x.herkunft = 'stammplatz' and x.session_id is null))
     -- Nachbesserung (Consensus-Befund 2): Einzel-Session am Tag, Wochengrenze, Budget.
     or exists (select 1 from public.slots_einzelbuchungen(kt.student_id) e
                 where e.datum = kt.datum and e.attendance in ('planned', 'present', 'unexcused'))
     or public.slots_woche_aktiv(kt.student_id, kt.datum, kt.id) + 1 > public.slots_wochengrenze(kt.student_id, kt.datum)
     or (select v.einheiten from public.vertraege v where v.id = kt.vertrag_id)
        - public.slots_fest_belegt(kt.vertrag_id, public.slots_berlin_tag(v_jetzt), kt.id) < 1 then
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
$function$;

-- ============================================================================
-- Entscheidung 5: Festschreiben nur mit Testkonten -> Testlauf
-- ============================================================================

CREATE OR REPLACE FUNCTION public.termin_session_anlegen(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_rolle text := coalesce(public.get_my_role(), '');
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  r       record;
  v_sess  public.coaching_sessions;
  v_neu   boolean := false;
  v_aus   jsonb;
  v_x     jsonb;
  v_test  boolean;
begin
  if not public.ist_systemaufruf() and v_rolle not in ('admin', 'coach') then
    raise exception 'termin_session_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  perform public.slots_sperren();

  select * into r from public.slot_raeume(p_datum, p_datum) x
   where x.slot_zeit_id = p_zeit_id and x.raum_id = p_raum_id;
  -- Coach: nur der eingeteilte Coach dieses Raums (Entscheidung 20), auch über die direkte Adresse.
  if v_rolle = 'coach' and not public.ist_systemaufruf()
     and (r.raum_id is null or r.coach_id is distinct from auth.uid()) then
    raise exception 'termin_session_anlegen: nur der eingeteilte Coach dieses Raums' using errcode = '42501';
  end if;
  if p_datum <> public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('22023', 'termin_session_anlegen: nur am Tag des Termins', 'nur_am_tag');
  end if;

  v_sess := public.slots_session(p_datum, p_zeit_id, p_raum_id);
  if v_sess.id is null then
    if r.raum_id is null or not r.offen then
      perform public.slots_fehler('SL002', 'termin_session_anlegen: kein Raum mit Coach');
    end if;
    -- SL2b (Entscheidung 5): Sitzen im Termin nur Testkonten, entsteht die Session als Testlauf (beim Anlegen,
    -- also vor dem Start). Ohne Kinder richtet sie sich nach den übrigen Sessions des Termins.
    select bool_and(s.ist_test) into v_test
      from public.slot_zuteilung(p_datum, p_zeit_id) t join public.students s on s.id = t.student_id;
    if v_test is null then
      select bool_and(cs.testlauf) into v_test from public.coaching_sessions cs
       where cs.slot_zeit_id = p_zeit_id and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_zeit_id);
    end if;
    v_test := coalesce(v_test, false);
    begin
      insert into public.coaching_sessions (coach_id, room, scheduled_at, status, raum_id, slot_zeit_id, testlauf)
      values (r.coach_id, r.raum_name, public.slots_termin_beginn(p_datum, p_zeit_id), 'upcoming', p_raum_id, p_zeit_id,
              v_test)
      returning * into v_sess;
    exception when insufficient_privilege then
      -- Wer testlauf beim Anlegen setzen darf, entscheidet der Trigger coaching_sessions_testlauf_pruefen (T4);
      -- hier bekommt seine Ablehnung nur einen Hinweis, den die Oberfläche übersetzt.
      if not v_test then
        raise;
      end if;
      raise exception 'termin_session_anlegen: Testtermin, nur Admin' using errcode = '42501', hint = 'testlauf_nur_admin';
    end;
    v_neu := true;
  end if;

  v_aus := public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  for v_x in select * from jsonb_array_elements(v_aus) loop
    perform public.termine_planen((v_x ->> 'student_id')::uuid, v_jetzt);
  end loop;

  return jsonb_build_object(
    'session_id', v_sess.id, 'neu', v_neu,
    'ausgelassen', coalesce((select jsonb_agg(x || public.slots_kind_info((x ->> 'student_id')::uuid,
                                                (select kt.vertrag_id from public.kind_termine kt
                                                  where kt.id = (x ->> 'termin_id')::uuid)))
                               from jsonb_array_elements(v_aus) x), '[]'));
end;
$function$;

revoke all on function public.slots_art_konflikt(uuid, date, uuid) from public, anon, authenticated;

commit;
