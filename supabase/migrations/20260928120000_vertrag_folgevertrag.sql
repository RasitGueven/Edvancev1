-- Folgevertrag: einen neuen Antrag aus einem bestehenden Vertrag starten.
--
-- Bis hierher entsteht ein Antrag nur aus einem Lead (vertrag_starten). Ein Kind,
-- das schon einen Vertrag hatte, hat aber keinen neuen Lead — es hat eine
-- Geschichte. Ohne diesen Weg blieb der Knopf "Neuer Vertrag" gesperrt, die
-- Vorgaengerkette ungenutzt und die Historie in der Detailansicht leer.
--
-- Zwei Dinge macht die Funktion, die vertrag_starten nicht kann: sie setzt
-- student_id und vorgaenger_id. Damit greift beim Abschluss der Folgevertrag-
-- Zweig in vertrag_abschliessen — Vorgaenger auf 'verlaengert', kein zweites
-- Schuelerkonto.

begin;

-- ============================================================================
-- 1. Ein OFFENER Antrag je Lead — nicht ein Vertrag je Lead
-- ============================================================================
--
-- Der Index aus P2 sperrte alles, was nicht abgelehnt ist. Gemeint war: zwei
-- offene Antraege zum selben Lead gleichzeitig sind ein Bedienfehler. Getroffen
-- hat er auch den Folgevertrag zwei Jahre spaeter, weil der alte Vertrag als
-- 'abgeschlossen' den Platz belegt.
--
-- Neu deckt er nur die beiden offenen Zustaende ab. Die Idempotenz von
-- vertrag_starten haengt nicht daran: die Funktion sucht selbst nach einem
-- bestehenden Vertrag, bevor sie einen anlegt.

drop index if exists public.vertraege_lead_offen_idx;

create unique index vertraege_lead_offen_idx
  on public.vertraege (lead_id)
  where status in ('in_vorbereitung', 'unterschrift_ausstehend');

comment on index public.vertraege_lead_offen_idx is
  'Hoechstens ein OFFENER Antrag je Lead. Abgeschlossene Vertraege blockieren keinen Folgevertrag.';

-- ============================================================================
-- 2. vertrag_folgevertrag_starten
-- ============================================================================
--
-- Vorbelegt wird alles, was am Kind und an der Familie haengt, samt Paket,
-- Laufzeit und Bankverbindung (Anforderung C.15: "vollstaendig vorausgefuellt").
--
-- NICHT vorbelegt wird der Vertragsbeginn. Er muss ein kuenftiger Monatserster
-- sein, und welcher, entscheidet der Empfang — das Ende des alten Vertrags ist
-- dafuer nur ein Anhaltspunkt, kein Automatismus.
--
-- Preis und Einheiten kommen frisch aus tier_laufzeiten, nicht aus dem alten
-- Vertrag: Tarife aendern sich, und der eingefrorene Preis des Vorgaengers waere
-- beim Folgevertrag schlicht der falsche.

create or replace function public.vertrag_folgevertrag_starten(p_vorgaenger_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_alt   vertraege%rowtype;
  v_id    uuid;
  v_preis integer;
  v_einh  integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_folgevertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_alt from public.vertraege where id = p_vorgaenger_id for update;
  if not found then
    raise exception 'vertrag_folgevertrag_starten: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_alt.status <> 'abgeschlossen' then
    raise exception 'vertrag_folgevertrag_starten: ein Folgevertrag entsteht nur aus einem abgeschlossenen Vertrag'
      using errcode = 'P0001';
  end if;
  if v_alt.student_id is null then
    raise exception 'vertrag_folgevertrag_starten: der Vorgaenger haengt an keinem Kind'
      using errcode = 'P0001';
  end if;

  -- Idempotent: der Knopf darf zweimal gedrueckt werden.
  select id into v_id
    from public.vertraege
   where vorgaenger_id = p_vorgaenger_id
     and status in ('in_vorbereitung', 'unterschrift_ausstehend');
  if v_id is not null then
    return v_id;
  end if;

  select tl.preis_cents, tl.einheiten into v_preis, v_einh
    from public.tier_laufzeiten tl
   where tl.tier_id = v_alt.tier_id
     and tl.laufzeit_monate = v_alt.laufzeit_monate;

  insert into public.vertraege (
    created_by, lead_id, student_id, vorgaenger_id,
    eltern_vorname, eltern_nachname, strasse, hausnummer, plz, ort,
    eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach,
    schule, schule_id, kontoinhaber,
    tier_id, laufzeit_monate, preis_cents, einheiten
  ) values (
    auth.uid(), v_alt.lead_id, v_alt.student_id, p_vorgaenger_id,
    v_alt.eltern_vorname, v_alt.eltern_nachname, v_alt.strasse, v_alt.hausnummer,
    v_alt.plz, v_alt.ort, v_alt.eltern_telefon, v_alt.eltern_email,
    v_alt.kind_vorname, v_alt.kind_nachname, v_alt.kind_geburtsdatum,
    v_alt.klasse, v_alt.fach,
    v_alt.schule, v_alt.schule_id, v_alt.kontoinhaber,
    v_alt.tier_id, v_alt.laufzeit_monate, v_preis, v_einh
  )
  returning id into v_id;

  -- Ein eigenes Mandat je Vertrag (Dokument 1), aber dieselbe Bankverbindung.
  -- Die Mandatsreferenz zieht der Default aus der Sequenz; die IBAN wird
  -- uebernommen und laesst sich in Schritt 1 aendern.
  insert into public.vertrag_bankdaten (vertrag_id, iban)
  select v_id, b.iban
    from public.vertrag_bankdaten b
   where b.vertrag_id = p_vorgaenger_id;

  return v_id;
end;
$$;

comment on function public.vertrag_folgevertrag_starten(uuid) is
  'Neuer Antrag aus einem abgeschlossenen Vertrag: uebernimmt Stammdaten, Paket und Bankverbindung, setzt student_id und vorgaenger_id. Beginn bleibt offen. Idempotent.';

-- Supabase vergibt EXECUTE per Default Privileges direkt an anon und
-- authenticated; "from public" allein entzieht das nicht (siehe P1).
revoke all on function public.vertrag_folgevertrag_starten(uuid)
  from public, anon, authenticated;
grant execute on function public.vertrag_folgevertrag_starten(uuid)
  to authenticated;

commit;
