-- Vertraege P3a — die Datenbank hinter dem Menue "Vertraege". Keine Oberflaeche.
--
-- Das Menue braucht vier Listen (Uebersicht, auslaufend, Zahlungsverzug, offene
-- Antraege) und eine Detailansicht. Alle vier lesen dieselben Zeilen, nur anders
-- gefiltert. Deshalb steht hier EINE Sicht und nicht vier.
--
-- Der Vertragsstatus wird ABGELEITET, nicht gespeichert. Ein Vertrag laeuft aus,
-- weil ein Datum vergeht — dafuer muss nachts kein Job laufen, der eine Spalte
-- umschreibt und dessen Ausfall niemand merkt. Gespeichert wird nur, was jemand
-- ENTSCHIEDEN hat: widerrufen_am, gekuendigt_zum. Der Rest faellt aus dem
-- Kalender.
--
-- Datumsarithmetik ausschliesslich ueber date.

begin;

-- ============================================================================
-- 1. Der wirksame Status — eine Regel, zwei Leser
-- ============================================================================
--
-- Die Sicht braucht ihn fuer heute, hat_zugang() fuer einen beliebigen Stichtag.
-- Zwei Kopien derselben Fallunterscheidung waeren zwei Wahrheiten, und die eine
-- wuerde irgendwann anders entscheiden als die andere. Deshalb ist die Regel
-- eine Funktion mit dem Datum als Parameter.
--
-- Die Reihenfolge ist Vorrang, nicht Geschmack: Ein widerrufener Vertrag ist
-- widerrufen, auch wenn sein Ende laengst vorbei waere. Eine Kuendigung schlaegt
-- das Auslaufen. Und "im Widerruf" gilt nur, solange die Frist laeuft.

create or replace function public.vertrag_wirksamer_status(
  p_widerrufen_am  date,
  p_gekuendigt_zum date,
  p_vertrag_ende   date,
  p_widerruf_bis   date,
  p_datum          date default current_date
)
returns text
language sql
stable
as $$
  select case
    when p_widerrufen_am  is not null                          then 'widerrufen'
    when p_gekuendigt_zum is not null and p_gekuendigt_zum <= p_datum then 'gekuendigt'
    when p_vertrag_ende   is not null and p_vertrag_ende   <  p_datum then 'ausgelaufen'
    when p_widerruf_bis   is not null and p_datum <= p_widerruf_bis   then 'im_widerruf'
    else 'aktiv'
  end;
$$;

comment on function public.vertrag_wirksamer_status(date, date, date, date, date) is
  'Vertragsstatus an einem Stichtag, abgeleitet aus Daten statt gespeichert. Vorrang: widerrufen > gekuendigt > ausgelaufen > im_widerruf > aktiv.';

-- Reine Rechnung ueber ihre Argumente, ohne Tabellenzugriff: SECURITY DEFINER
-- und Admin-Gate wuerden hier nichts schuetzen und haetten hat_zugang() fuer
-- Coaches (P5) gleich mit gesperrt. Die Rechte sind trotzdem eng.
revoke all on function public.vertrag_wirksamer_status(date, date, date, date, date)
  from public, anon, authenticated;
grant execute on function public.vertrag_wirksamer_status(date, date, date, date, date)
  to authenticated;

-- ============================================================================
-- 2. vertraege_aktuell — die Sicht hinter allen vier Listen
-- ============================================================================
--
-- security_invoker: die Sicht bringt keine eigenen Rechte mit, es gilt die RLS
-- auf vertraege. Damit sieht sie genau, wer auch die Tabelle sehen darf — heute
-- nur der Admin. Ohne das Flag liefe sie mit den Rechten des Eigentuemers und
-- waere ein Loch neben der Policy.
--
-- Nur status = 'abgeschlossen': ein Antrag ist kein Vertrag. Die offenen
-- Antraege holt das Menue weiter direkt aus vertraege.

create view public.vertraege_aktuell
with (security_invoker = true) as
with basis as (
  select
    v.*,
    public.vertrag_wirksamer_status(
      v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis
    ) as wirksamer_status,
    -- 1 im Startmonat. Ueber Jahr und Monat gerechnet, nicht ueber Tage:
    -- ein Vertrag ab dem 1. Maerz ist am 1. September im 7. Monat, egal wie
    -- viele Tage dazwischenliegen.
    case
      when v.vertragsbeginn is null then null
      else 1
           + (extract(year  from current_date)::integer * 12
              + extract(month from current_date)::integer)
           - (extract(year  from v.vertragsbeginn)::integer * 12
              + extract(month from v.vertragsbeginn)::integer)
    end as laufzeit_monat
  from public.vertraege v
  where v.status = 'abgeschlossen'
)
select
  b.*,

  -- Der juengste abgeschlossene Vertrag je Kind. Die Uebersicht zeigt
  -- standardmaessig nur ihn; Vorgaenger liegen darunter in der Historie.
  -- coalesce auf die eigene id: ein Vertrag ohne student_id ist seine eigene
  -- Gruppe und damit immer der aktuelle, statt mit allen anderen zu kollidieren.
  row_number() over (
    partition by coalesce(b.student_id, b.id)
    order by b.vertragsbeginn desc nulls last,
             b.abgeschlossen_am desc nulls last,
             b.created_at desc
  ) = 1 as ist_aktueller_vertrag,

  -- Was in diesem Kalendermonat abgebucht wird. Beim Jahresvertrag sind das
  -- zwoelf Monate, beim Halbjahr sechs — danach laeuft der Vertrag weiter,
  -- aber beitragsfrei (Entscheidung 5). Eine Formel fuer beide, weil
  -- laufzeit_monate genau die Zahl der Beitraege ist.
  case
    when b.preis_cents is null or b.laufzeit_monat is null or b.laufzeit_monate is null
      then 0
    when b.laufzeit_monat between 1 and b.laufzeit_monate then b.preis_cents
    else 0
  end as beitrag_diesen_monat_cents,

  -- Der Code oeffnet nur, solange der Vertrag traegt. Gesperrt wird zusaetzlich
  -- von Hand (zugangscode_gesperrt_am), etwa nach einem Widerruf.
  (b.zugangscode is not null
   and b.zugangscode_gesperrt_am is null
   and b.wirksamer_status in ('im_widerruf', 'aktiv')) as zugangscode_gueltig,

  -- Negativ, sobald das Ende vorbei ist. Die Liste "Auslaufende Vertraege"
  -- filtert darauf (acht Wochen = 56).
  (b.vertrag_ende - current_date) as endet_in_tagen
from basis b;

comment on view public.vertraege_aktuell is
  'Abgeschlossene Vertraege mit abgeleitetem Status, Monatsbeitrag, Zugangscode-Gueltigkeit und Restlaufzeit. security_invoker — es gilt die RLS auf vertraege.';

revoke all on public.vertraege_aktuell from public, anon, authenticated;
grant select on public.vertraege_aktuell to authenticated;

-- ============================================================================
-- 3. hat_zugang — und die Bruecke zwischen zwei Vertraegen
-- ============================================================================
--
-- Entscheidung 11: Hat ein Kind einen unterschriebenen Folgevertrag, bleibt der
-- Zugang zwischen altem Ende und neuem Beginn offen. Sonst endet er am
-- Vertragsende. Ohne diese Bruecke waere ein Kind in den Sommerferien
-- ausgesperrt, obwohl beide Vertraege unterschrieben sind.
--
-- Kein Admin-Gate: P5 fragt das aus dem Coach-Kontext. Die Funktion gibt nur
-- ja/nein zurueck und verraet nichts ueber den Vertrag.

create or replace function public.hat_zugang(
  p_student_id uuid,
  p_datum      date default current_date
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.vertraege v
     where v.student_id = p_student_id
       and v.status = 'abgeschlossen'
       and public.vertrag_wirksamer_status(
             v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
           ) in ('im_widerruf', 'aktiv')
  )
  or exists (
    select 1
      from public.vertraege alt
      join public.vertraege neu on neu.vorgaenger_id = alt.id
     where alt.student_id = p_student_id
       and alt.status = 'abgeschlossen'
       and alt.vertrag_ende is not null
       and alt.vertrag_ende < p_datum
       and neu.status = 'abgeschlossen'
       and neu.vertragsbeginn is not null
       and neu.vertragsbeginn > p_datum
  );
$$;

comment on function public.hat_zugang(uuid, date) is
  'Hat das Kind am Stichtag Zugang? Laufender Vertrag ODER Bruecke zwischen ausgelaufenem Vertrag und unterschriebenem Folgevertrag (Entscheidung 11).';

revoke all on function public.hat_zugang(uuid, date) from public, anon, authenticated;
grant execute on function public.hat_zugang(uuid, date) to authenticated;

-- ============================================================================
-- 4. Die sechs Entscheidungen, die der Admin am Vertrag trifft
-- ============================================================================
--
-- Alle nach demselben Muster wie die vertrag_*-RPCs aus P2: SECURITY DEFINER,
-- Admin-Gate mit 42501, search_path gesetzt, Zeile fuer das Update gesperrt.
--
-- Sie alle schreiben an einem ABGESCHLOSSENEN Vertrag. Die RLS-Policy
-- vertraege_admin_update_vorbereitung erlaubt das nicht — deshalb laufen sie
-- als Eigentuemer. Das ist der Grund fuer SECURITY DEFINER, nicht Bequemlichkeit.
--
-- Keine von ihnen fasst vertrag_status an: den leitet die Sicht ab. Geschrieben
-- wird nur die Entscheidung selbst.

-- 4.1 Widerruf ---------------------------------------------------------------
-- Nur innerhalb der Frist. Wer nach Ablauf widerrufen will, kuendigt (4.2) —
-- das ist ein anderer Vorgang mit anderen Folgen fuer das Geld.

create or replace function public.vertrag_widerruf_erfassen(
  p_vertrag_id uuid,
  p_datum      date default current_date
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_widerruf_erfassen: nur Admin' using errcode = '42501';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_widerruf_erfassen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status <> 'abgeschlossen' then
    raise exception 'vertrag_widerruf_erfassen: nur ein abgeschlossener Vertrag ist widerrufbar'
      using errcode = 'P0001';
  end if;
  if v.widerrufen_am is not null then
    return jsonb_build_object('ok', true, 'bereits_widerrufen', true,
                              'widerrufen_am', v.widerrufen_am);
  end if;
  if v.widerruf_bis is null or p_datum > v.widerruf_bis then
    raise exception 'vertrag_widerruf_erfassen: Widerrufsfrist endete am %', v.widerruf_bis
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set widerrufen_am           = p_datum,
         zugangscode_gesperrt_am = coalesce(zugangscode_gesperrt_am, p_datum)
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'widerrufen_am', p_datum);
end;
$$;

-- 4.2 Sonderkuendigung -------------------------------------------------------
-- Es gibt keine ordentliche Kuendigung (Entscheidung 7). Was es gibt, ist der
-- Einzelfall — und der braucht einen Grund, sonst steht spaeter niemand mehr
-- dafuer gerade.

create or replace function public.vertrag_sonderkuendigung_erfassen(
  p_vertrag_id uuid,
  p_zum        date,
  p_grund      text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_sonderkuendigung_erfassen: nur Admin' using errcode = '42501';
  end if;
  if p_zum is null then
    raise exception 'vertrag_sonderkuendigung_erfassen: Kuendigungsdatum fehlt' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'vertrag_sonderkuendigung_erfassen: Grund ist Pflicht' using errcode = 'P0001';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_sonderkuendigung_erfassen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status <> 'abgeschlossen' then
    raise exception 'vertrag_sonderkuendigung_erfassen: nur ein abgeschlossener Vertrag ist kuendbar'
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set gekuendigt_zum   = p_zum,
         kuendigung_grund = btrim(p_grund)
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'gekuendigt_zum', p_zum);
end;
$$;

-- 4.3 Zahlungsstatus ---------------------------------------------------------
-- Eine Stufe vorwaerts oder zurueck auf null. Der Sprung von "in Ordnung" auf
-- "2. Mahnung" waere kein Tippfehler, sondern eine uebersprungene Mahnung —
-- und die faellt spaeter dem auf die Fuesse, der sie verschickt haben soll.

create or replace function public.vertrag_zahlungsstatus_setzen(
  p_vertrag_id         uuid,
  p_status             text,
  p_offener_betrag_cents integer default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  c_stufen constant text[] := array['in_ordnung','zahlung_offen','mahnung_1','mahnung_2','inkasso'];
  v        vertraege%rowtype;
  v_alt    integer;
  v_neu    integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_zahlungsstatus_setzen: nur Admin' using errcode = '42501';
  end if;

  v_neu := array_position(c_stufen, p_status);
  if v_neu is null then
    raise exception 'vertrag_zahlungsstatus_setzen: unbekannte Stufe %', p_status using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_zahlungsstatus_setzen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  v_alt := array_position(c_stufen, v.zahlungsstatus);
  if p_status <> 'in_ordnung' and v_neu <> v_alt + 1 then
    raise exception 'vertrag_zahlungsstatus_setzen: von % geht es nur eine Stufe weiter oder zurueck auf in_ordnung', v.zahlungsstatus
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set zahlungsstatus       = p_status,
         zahlungsstatus_seit  = current_date,
         -- Zurueck auf in_ordnung heisst: nichts mehr offen.
         offener_betrag_cents = case when p_status = 'in_ordnung' then null
                                     else p_offener_betrag_cents end
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'zahlungsstatus', p_status, 'seit', current_date);
end;
$$;

-- 4.4 Verlaengerung ----------------------------------------------------------
-- 'verlaengert' ist hier bewusst nicht setzbar. Es entsteht, wenn ein
-- Folgevertrag zustande kommt (vertrag_abschliessen setzt es), und nur dann.
-- Von Hand gesetzt waere es eine Behauptung ohne Vertrag dahinter.

create or replace function public.vertrag_verlaengerung_setzen(
  p_vertrag_id      uuid,
  p_status          text,
  p_grund           text default null,
  p_wiedervorlage_am date default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_verlaengerung_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_status = 'verlaengert' then
    raise exception 'vertrag_verlaengerung_setzen: verlaengert entsteht nur aus einem Folgevertrag'
      using errcode = 'P0001';
  end if;
  if p_status not in ('offen','kontaktiert','gespraech_vereinbart','keine_verlaengerung') then
    raise exception 'vertrag_verlaengerung_setzen: unbekannter Status %', p_status using errcode = '22023';
  end if;
  if p_status = 'keine_verlaengerung'
     and nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'vertrag_verlaengerung_setzen: keine_verlaengerung braucht einen Grund'
      using errcode = 'P0001';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_verlaengerung_setzen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  update public.vertraege
     set verlaengerung_status = p_status,
         verlaengerung_grund  = nullif(btrim(coalesce(p_grund, '')), ''),
         wiedervorlage_am     = p_wiedervorlage_am
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'verlaengerung_status', p_status);
end;
$$;

-- 4.5 Zugangscode neu erzeugen -----------------------------------------------
-- Nur fuer einen Code, der noch gelten wuerde. Einen gesperrten oder zu einem
-- beendeten Vertrag gehoerenden Code neu zu erzeugen hiesse, einen Zugang
-- wieder zu oeffnen, den jemand absichtlich geschlossen hat.

create or replace function public.vertrag_zugangscode_neu(p_vertrag_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_gueltig boolean;
  v_code    text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_zugangscode_neu: nur Admin' using errcode = '42501';
  end if;

  select a.zugangscode_gueltig into v_gueltig
    from public.vertraege_aktuell a where a.id = p_vertrag_id;
  if v_gueltig is null then
    raise exception 'vertrag_zugangscode_neu: kein abgeschlossener Vertrag' using errcode = 'P0002';
  end if;
  if not v_gueltig then
    raise exception 'vertrag_zugangscode_neu: der Zugangscode dieses Vertrags gilt nicht mehr'
      using errcode = 'P0001';
  end if;

  v_code := public.zugangscode_erzeugen();
  update public.vertraege
     set zugangscode = v_code, zugangscode_erzeugt_am = current_date
   where id = p_vertrag_id;

  return v_code;
end;
$$;

-- 4.6 Volle IBAN anzeigen ----------------------------------------------------
-- Entscheidung 17. Das Protokoll wird VOR der Ausgabe geschrieben: schluege der
-- Eintrag fehl, gaebe es sonst eine aufgedeckte IBAN ohne Spur. In dieser
-- Reihenfolge nimmt dieselbe Transaktion beides zurueck.

create or replace function public.vertrag_iban_anzeigen(p_vertrag_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_iban text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_iban_anzeigen: nur Admin' using errcode = '42501';
  end if;

  select b.iban into v_iban
    from public.vertrag_bankdaten b where b.vertrag_id = p_vertrag_id;
  if v_iban is null then
    raise exception 'vertrag_iban_anzeigen: zu diesem Vertrag ist keine IBAN hinterlegt'
      using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('iban_angezeigt', 'vertrag', p_vertrag_id);
  return v_iban;
end;
$$;

-- ============================================================================
-- 5. Rechte
-- ============================================================================
--
-- Supabase vergibt EXECUTE per Default Privileges direkt an anon und
-- authenticated; "from public" allein entzieht das nicht (siehe P1).

revoke all on function public.vertrag_widerruf_erfassen(uuid, date)                     from public, anon, authenticated;
revoke all on function public.vertrag_sonderkuendigung_erfassen(uuid, date, text)       from public, anon, authenticated;
revoke all on function public.vertrag_zahlungsstatus_setzen(uuid, text, integer)        from public, anon, authenticated;
revoke all on function public.vertrag_verlaengerung_setzen(uuid, text, text, date)      from public, anon, authenticated;
revoke all on function public.vertrag_zugangscode_neu(uuid)                             from public, anon, authenticated;
revoke all on function public.vertrag_iban_anzeigen(uuid)                               from public, anon, authenticated;

grant execute on function public.vertrag_widerruf_erfassen(uuid, date)                  to authenticated;
grant execute on function public.vertrag_sonderkuendigung_erfassen(uuid, date, text)    to authenticated;
grant execute on function public.vertrag_zahlungsstatus_setzen(uuid, text, integer)     to authenticated;
grant execute on function public.vertrag_verlaengerung_setzen(uuid, text, text, date)   to authenticated;
grant execute on function public.vertrag_zugangscode_neu(uuid)                          to authenticated;
grant execute on function public.vertrag_iban_anzeigen(uuid)                            to authenticated;

commit;
