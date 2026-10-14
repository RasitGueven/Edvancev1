-- V5: Pilotvereinbarung als zweite Vertragsart.
--
-- Entscheidungen Rasit 14.10.2026 (Paket V5):
--   1  vertraege.vertragsart ('regulaer' | 'pilot'), Bestand bleibt 'regulaer'.
--   2  Pilot: kein Paket, keine Laufzeit, kein Widerruf, Preis 0, keine IBAN, kein SEPA-Mandat.
--   3  Pilot: Beginn ist ein Monatserster, das Ende gibt der Admin vor und liegt nicht in den Ferien.
--      Keine Ferienverlängerung. Vorschlag: letzter Schultag vor den Sommerferien (vertrag_pilot_vorschlag).
--   4  Pilot: Einheiten gibt der Admin vor (> 0). Vorschlag: Schulwochen zwischen Beginn und Ende.
--   5  Pilot: vertrag_status direkt 'aktiv'. vertrag_wirksamer_status und vertraege_aktuell liefern mit
--      widerruf_bis = null schon 'aktiv' bzw. 'ausgelaufen' — dort keine Änderung an der Logik.
--   8  Kein Umsatz: Beitrag in vertraege_aktuell ausdrücklich 0, Pilot steht nie im Zahlungsverzug.
--   9  Ein Folgevertrag erbt die Vertragsart nicht (vertrag_folgevertrag_starten setzt sie nicht → 'regulaer').
--  11  slots_vertrag_am / slots_kinder_basis / slots_kind_zugelassen bleiben unverändert.
--
-- Ersetzte Funktionen aus der Prod-Definition. Signatur, SECURITY, search_path und Rechte unverändert,
-- außer vertrag_starten (neuer optionaler Parameter p_vertragsart — alte Fassung wird ersetzt, nicht
-- überladen, damit vertrag_starten(p_lead_id) eindeutig bleibt).

begin;

-- ------------------------------------------------------------------ Spalte und Regeln
alter table public.vertraege
  add column vertragsart text not null default 'regulaer'
    constraint vertraege_vertragsart_check check (vertragsart in ('regulaer', 'pilot'));

comment on column public.vertraege.vertragsart is
  'V5: regulaer = Paket + Laufzeit + SEPA; pilot = 0 €, feste Einheiten und festes Ende, kein Widerruf.';

-- Pilot trägt nie Tarif, Laufzeit, Widerrufsfrist, Ferienverlängerung oder einen Preis ≠ 0.
alter table public.vertraege add constraint vertraege_pilot_ohne_tarif check (
  vertragsart <> 'pilot'
  or (tier_id is null and laufzeit_monate is null and widerruf_bis is null and ferientage is null
      and preis_cents = 0)
);
-- Einheiten, falls gesetzt, sind positiv; ab dem Versand stehen Beginn, Ende und Einheiten fest.
alter table public.vertraege add constraint vertraege_pilot_konditionen check (
  vertragsart <> 'pilot'
  or ((einheiten is null or einheiten > 0)
      and (status in ('in_vorbereitung', 'abgelehnt')
           or (einheiten is not null and vertragsbeginn is not null and vertrag_ende is not null)))
);
-- Pilot hat keine Zahlung — also auch keinen Verzug.
alter table public.vertraege add constraint vertraege_pilot_ohne_zahlung check (
  vertragsart <> 'pilot' or (zahlungsstatus = 'in_ordnung' and offener_betrag_cents is null)
);

-- ------------------------------------------------------------------ Dokumente je Vertragsart
-- Entscheidung 10: eigene Vorlage "pilotvereinbarung". Pilot hat kein SEPA-Mandat und keinen Widerruf;
-- welches Dokument zu welcher Vertragsart gehört, steht am Dokument. Bestand gilt für 'regulaer'.
alter table public.vertrag_dokumente
  add column vertragsarten text[] not null default array['regulaer']::text[]
    constraint vertrag_dokumente_vertragsarten_check
      check (cardinality(vertragsarten) > 0 and vertragsarten <@ array['regulaer', 'pilot']::text[]);

comment on column public.vertrag_dokumente.vertragsarten is
  'V5: für welche Vertragsarten das Dokument zum Bündel gehört (Pflichtprüfung, Versand, Unterlagen).';

-- Datenschutz und Fotos gelten auch beim Pilot (Entscheidung 6). AGB bleibt vorerst regulär — offener Punkt.
update public.vertrag_dokumente
   set vertragsarten = array['regulaer', 'pilot']
 where schluessel in ('datenschutz_vertrag', 'einwilligung_fotos');

insert into public.vertrag_dokumente (schluessel, version, titel, pflicht, aktiv, sort_order, vertragsarten)
values ('pilotvereinbarung', 'platzhalter-v1', 'Pilotvereinbarung', true, true, 1, array['pilot']);

-- ------------------------------------------------------------------ Prüfung Ende und Einheiten
-- Gemeinsame Prüfung für Versand und Abschluss. Intern, nur aus den vertrag_*-RPCs.
create function public.vertrag_pilot_pruefen(p_beginn date, p_ende date, p_einheiten integer)
returns void
language plpgsql
stable security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_ferien  text;
  v_letzter date;
begin
  if p_beginn is null or p_ende is null or p_einheiten is null then
    raise exception 'vertrag_pilot: Vertragsbeginn, Vertragsende und Einheiten sind Pflicht'
      using errcode = 'P0001';
  end if;
  if extract(day from p_beginn) <> 1 then
    raise exception 'vertrag_pilot: Vertragsbeginn ist immer der Monatserste (% ist es nicht)', p_beginn
      using errcode = 'P0001';
  end if;
  if p_ende <= p_beginn then
    raise exception 'vertrag_pilot: Vertragsende % liegt nicht nach dem Beginn %', p_ende, p_beginn
      using errcode = 'P0001';
  end if;
  if p_einheiten <= 0 then
    raise exception 'vertrag_pilot: Einheiten muessen groesser als 0 sein' using errcode = 'P0001';
  end if;

  select max(f.bis) into v_letzter from public.ferien_nrw f;
  if v_letzter is null or p_ende > v_letzter then
    raise exception 'vertrag_pilot: Ende % liegt nach dem letzten gepflegten Ferientag (%) — Ferien in ferien_nrw ergaenzen', p_ende, v_letzter
      using errcode = 'P0001';
  end if;

  select f.name into v_ferien from public.ferien_nrw f where p_ende between f.von and f.bis limit 1;
  if v_ferien is not null then
    raise exception 'vertrag_pilot: Vertragsende % liegt in den Ferien (%)', p_ende, v_ferien
      using errcode = 'P0001';
  end if;
end;
$function$;

revoke all on function public.vertrag_pilot_pruefen(date, date, integer) from public, anon, authenticated;

-- ------------------------------------------------------------------ Vorschlag fürs Formular
-- Ende: letzter Schultag (Mo–Fr, nicht in Ferien) vor den nächsten Sommerferien nach dem Beginn.
-- Einheiten: Wochen zwischen Beginn und Ende mit mindestens einem Schultag — ein Termin je Woche.
create function public.vertrag_pilot_vorschlag(p_beginn date)
returns table(ende date, einheiten integer)
language plpgsql
stable security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_sommer date;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_pilot_vorschlag: nur Admin' using errcode = '42501';
  end if;
  if p_beginn is null or extract(day from p_beginn) <> 1 then
    raise exception 'vertrag_pilot_vorschlag: Vertragsbeginn ist immer der Monatserste (% ist es nicht)', p_beginn
      using errcode = '22023';
  end if;

  select min(f.von) into v_sommer
    from public.ferien_nrw f
   where f.art = 'sommer' and f.von > p_beginn;
  if v_sommer is null then
    raise exception 'vertrag_pilot_vorschlag: nach % sind keine Sommerferien gepflegt', p_beginn
      using errcode = 'P0001';
  end if;

  with schultage as (
    select d::date as tag
      from generate_series(p_beginn, v_sommer - 1, interval '1 day') d
     where extract(isodow from d) <= 5
       and not exists (select 1 from public.ferien_nrw f where d::date between f.von and f.bis)
  )
  select max(s.tag), count(distinct date_trunc('week', s.tag))::integer
    into ende, einheiten
    from schultage s;

  if ende is null then
    raise exception 'vertrag_pilot_vorschlag: zwischen % und den Sommerferien liegt kein Schultag', p_beginn
      using errcode = 'P0001';
  end if;
  return next;
end;
$function$;

revoke all on function public.vertrag_pilot_vorschlag(date) from public, anon;
grant execute on function public.vertrag_pilot_vorschlag(date) to authenticated;

-- ------------------------------------------------------------------ Guard
-- Neu: beim Pilot gibt das Formular Einheiten vor, Preis ist 0, Tarif und Laufzeit sind leer.
-- Wechsel Pilot → Regulär rechnet Preis und Einheiten wie bisher aus dem Tarif und leert das Ende.
CREATE OR REPLACE FUNCTION public.vertraege_guard()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();

  -- Innerhalb einer vertrag_*-RPC gilt, was die RPC schreibt.
  if coalesce(current_setting('edvance.vertrag_rpc', true), '') = '1' then
    return new;
  end if;

  if new.status is distinct from old.status then
    raise exception 'vertraege: Status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;
  if new.vertrag_status is distinct from old.vertrag_status then
    raise exception 'vertraege: vertrag_status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;
  if new.vertragsart is distinct from old.vertragsart and new.status <> 'in_vorbereitung' then
    raise exception 'vertraege: Vertragsart nur in der Vorbereitung aendern' using errcode = '42501';
  end if;

  -- V5: Pilot — Einheiten und Ende gibt der Admin vor, ohne Tarif und ohne Preis.
  if new.status = 'in_vorbereitung' and new.vertragsart = 'pilot' then
    new.tier_id         := null;
    new.laufzeit_monate := null;
    new.preis_cents     := 0;
    return new;
  end if;

  -- Preis und Einheiten folgen aus (Paket, Laufzeit) — nie aus dem Formular.
  if new.status = 'in_vorbereitung'
     and (new.tier_id is distinct from old.tier_id
          or new.laufzeit_monate is distinct from old.laufzeit_monate
          or new.vertragsart is distinct from old.vertragsart) then
    new.preis_cents := null;
    new.einheiten   := null;
    select tl.preis_cents, tl.einheiten
      into new.preis_cents, new.einheiten
      from public.tier_laufzeiten tl
     where tl.tier_id = new.tier_id
       and tl.laufzeit_monate = new.laufzeit_monate;
    -- Das Ende eines regulären Vertrags rechnet der Abschluss; ein Pilot-Ende gilt nicht weiter.
    if old.vertragsart = 'pilot' then
      new.vertrag_ende := null;
    end if;
  else
    new.preis_cents := old.preis_cents;
    new.einheiten   := old.einheiten;
  end if;

  return new;
end;
$function$;

-- ------------------------------------------------------------------ vertrag_starten
drop function public.vertrag_starten(uuid);

CREATE FUNCTION public.vertrag_starten(p_lead_id uuid, p_vertragsart text DEFAULT 'regulaer')
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_lead     leads%rowtype;
  v_id       uuid;
  v_schule   uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_starten: nur Admin' using errcode = '42501';
  end if;
  if p_vertragsart is null or p_vertragsart not in ('regulaer', 'pilot') then
    raise exception 'vertrag_starten: unbekannte Vertragsart %', p_vertragsart using errcode = '22023';
  end if;

  select * into v_lead from public.leads where id = p_lead_id for update;
  if not found then
    raise exception 'vertrag_starten: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  select id into v_id from public.vertraege
   where lead_id = p_lead_id and status <> 'abgelehnt';
  if v_id is not null then
    return v_id;   -- idempotent: der Knopf darf zweimal gedrueckt werden
  end if;

  if v_lead.status <> 'lsa_fertig' then
    raise exception 'vertrag_starten: Lead steht nicht auf "Analyse abgeschlossen"'
      using errcode = 'P0001';
  end if;

  select s.id into v_schule
    from public.schulen s
   where lower(s.name) = lower(btrim(coalesce(v_lead.school_name, '')))
   limit 1;

  insert into public.vertraege (
    created_by, lead_id, eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach, schule, schule_id,
    vertragsart, preis_cents
  ) values (
    auth.uid(), p_lead_id, v_lead.contact_phone, v_lead.contact_email,
    coalesce(v_lead.first_name, split_part(v_lead.full_name, ' ', 1)),
    nullif(regexp_replace(v_lead.full_name, '^\S+\s*', ''), ''),
    v_lead.birth_date, v_lead.class_level, v_lead.subjects[1], v_lead.school_name, v_schule,
    p_vertragsart, case when p_vertragsart = 'pilot' then 0 end
  )
  returning id into v_id;

  update public.leads set status = 'vertrag' where id = p_lead_id;
  return v_id;
end;
$function$;

revoke all on function public.vertrag_starten(uuid, text) from public, anon;
grant execute on function public.vertrag_starten(uuid, text) to authenticated, service_role;

-- ------------------------------------------------------------------ vertrag_versenden
-- Neu: Pilot ohne Paket, Laufzeit und IBAN; stattdessen Ende und Einheiten geprüft.
CREATE OR REPLACE FUNCTION public.vertrag_versenden(p_vertrag_id uuid, p_weg text, p_empfaenger text DEFAULT NULL::text, p_rueckmeldung_bis date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v     vertraege%rowtype;
  v_bis date;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versenden: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('email', 'druck') then
    raise exception 'vertrag_versenden: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versenden: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_versenden: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;
  if v.status = 'abgeschlossen' then
    raise exception 'vertrag_versenden: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;
  if v.vertragsart = 'pilot' then
    perform public.vertrag_pilot_pruefen(v.vertragsbeginn, v.vertrag_ende, v.einheiten);
  else
    if v.tier_id is null or v.laufzeit_monate is null or v.vertragsbeginn is null then
      raise exception 'vertrag_versenden: Paket, Laufzeit oder Vertragsbeginn fehlt'
        using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_versenden: IBAN fehlt' using errcode = 'P0001';
    end if;
  end if;

  -- Fassungen festhalten: ALLE aktiven Dokumente, nicht nur die Pflichtstuecke.
  -- Rechtlich notwendig ist das Buendel, nicht die Auswahl daraus.
  insert into public.vertrag_zustimmungen
    (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
  select p_vertrag_id, d.schluessel, d.version, now(), auth.uid()
    from public.vertrag_dokumente d
   where d.aktiv
     and v.vertragsart = any(d.vertragsarten)   -- V5: nur das Bündel der eigenen Vertragsart
  on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

  if p_weg = 'druck' then
    insert into public.vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
    values (p_vertrag_id, p_weg, 'unterlagen', p_empfaenger, auth.uid());
  end if;

  v_bis := coalesce(p_rueckmeldung_bis,
                    v.rueckmeldung_bis,
                    (now() at time zone 'Europe/Berlin')::date + 14);

  perform set_config('edvance.vertrag_rpc', '1', true);
  update public.vertraege
     set status = 'unterschrift_ausstehend',
         unterschrift_ausstehend_at = coalesce(unterschrift_ausstehend_at, now()),
         abschluss_weg   = 'papier',
         rueckmeldung_bis = v_bis,
         glaeubiger_id   = coalesce(glaeubiger_id,
                             (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  return jsonb_build_object('ok', true, 'rueckmeldung_bis', v_bis);
end;
$function$;

-- ------------------------------------------------------------------ vertrag_abschliessen
-- Neu: Pilot-Zweig. Kein Tarif, keine IBAN, keine SEPA-Unterschrift, kein Abo, kein Widerruf;
-- Ende und Einheiten aus dem Vertrag, Status direkt 'aktiv'. Ergebnisform unverändert.
CREATE OR REPLACE FUNCTION public.vertrag_abschliessen(p_vertrag_id uuid, p_weg text, p_zustimmungen jsonb DEFAULT '[]'::jsonb, p_signatur_vertrag text DEFAULT NULL::text, p_signatur_sepa text DEFAULT NULL::text, p_unterschrieben_am date DEFAULT NULL::date, p_eingang_datum date DEFAULT NULL::date, p_scan_pfad text DEFAULT NULL::text, p_abweichung_vermerk text DEFAULT NULL::text, p_tier_id uuid DEFAULT NULL::uuid, p_laufzeit_monate integer DEFAULT NULL::integer, p_vertragsbeginn date DEFAULT NULL::date, p_student_uid uuid DEFAULT NULL::uuid, p_student_email text DEFAULT NULL::text, p_parent_uid uuid DEFAULT NULL::uuid, p_parent_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v            vertraege%rowtype;
  v_heute      date := (now() at time zone 'Europe/Berlin')::date;
  v_tier       uuid;
  v_laufzeit   integer;
  v_beginn     date;
  v_preis      integer;
  v_einheiten  integer;
  v_ende       record;
  v_widerruf   date;
  v_code       text;
  v_student    uuid;
  v_vorgaenger uuid;
  v_fehlt      text;
  v_abweichung boolean;
  v_kindname   text;
  v_subject    uuid;
  v_erstvertrag boolean;
  v_lsa        uuid;
  v_pilot      boolean;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_abschliessen: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('vor_ort', 'papier') then
    raise exception 'vertrag_abschliessen: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_abschliessen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  -- Idempotent: ein zweiter Aufruf liefert dasselbe Ergebnis, ohne etwas zu tun.
  if v.status = 'abgeschlossen' then
    return jsonb_build_object(
      'ok', true, 'bereits_abgeschlossen', true,
      'student_id', v.student_id, 'zugangscode', v.zugangscode,
      'vertrag_ende', v.vertrag_ende, 'widerruf_bis', v.widerruf_bis,
      'ferientage', v.ferientage);
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_abschliessen: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  v_pilot := v.vertragsart = 'pilot';

  -- -------------------------------------------------------- Konditionen
  -- Auf dem Papierweg gilt, was unterschrieben wurde, nicht was versendet war.
  v_beginn   := coalesce(p_vertragsbeginn,  v.vertragsbeginn);

  if v_pilot then
    -- V5: kein Paket, keine Laufzeit, Preis 0; Ende und Einheiten gibt der Admin vor.
    if p_tier_id is not null or p_laufzeit_monate is not null then
      raise exception 'vertrag_abschliessen: eine Pilotvereinbarung hat kein Paket und keine Laufzeit'
        using errcode = 'P0001';
    end if;
    perform public.vertrag_pilot_pruefen(v_beginn, v.vertrag_ende, v.einheiten);
    v_tier      := null;
    v_laufzeit  := null;
    v_preis     := 0;
    v_einheiten := v.einheiten;
  else
    v_tier     := coalesce(p_tier_id,         v.tier_id);
    v_laufzeit := coalesce(p_laufzeit_monate, v.laufzeit_monate);

    if v_tier is null or v_laufzeit is null or v_beginn is null then
      raise exception 'vertrag_abschliessen: Paket, Laufzeit oder Vertragsbeginn fehlt'
        using errcode = 'P0001';
    end if;

    select tl.preis_cents, tl.einheiten into v_preis, v_einheiten
      from public.tier_laufzeiten tl
     where tl.tier_id = v_tier and tl.laufzeit_monate = v_laufzeit;
    if v_preis is null then
      raise exception 'vertrag_abschliessen: kein Tarif fuer Paket und Laufzeit %', v_laufzeit
        using errcode = 'P0001';
    end if;
  end if;

  -- -------------------------------------------------------- Weg A: vor Ort
  if p_weg = 'vor_ort' then
    if v.status <> 'in_vorbereitung' then
      raise exception 'vertrag_abschliessen: vor Ort geht nur aus der Vorbereitung (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if not v_pilot
       and not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_abschliessen: IBAN fehlt' using errcode = 'P0001';
    end if;
    if nullif(p_signatur_vertrag, '') is null
       or (not v_pilot and nullif(p_signatur_sepa, '') is null) then
      raise exception 'vertrag_abschliessen: Unterschrift fehlt' using errcode = 'P0001';
    end if;

    select string_agg(d.schluessel, ', ') into v_fehlt
      from public.vertrag_dokumente d
     where d.aktiv and d.pflicht
       and v.vertragsart = any(d.vertragsarten)   -- V5: Pflicht je Vertragsart
       and not exists (
         select 1 from jsonb_array_elements(p_zustimmungen) z
          where z ->> 'schluessel' = d.schluessel and z ->> 'version' = d.version);
    if v_fehlt is not null then
      raise exception 'vertrag_abschliessen: Zustimmung fehlt fuer %', v_fehlt
        using errcode = 'P0001';
    end if;

    insert into public.vertrag_zustimmungen
      (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
    select p_vertrag_id, z ->> 'schluessel', z ->> 'version',
           coalesce((z ->> 'akzeptiert_at')::timestamptz, now()), auth.uid()
      from jsonb_array_elements(p_zustimmungen) z
     -- V5: Zustimmungen zu Dokumenten der anderen Vertragsart halten wir nicht fest
     -- (ein regulaerer Vertrag stimmt keiner Pilotvereinbarung zu). Unbekannte
     -- Dokumente scheitern weiter am Fremdschluessel.
     where not exists (select 1 from public.vertrag_dokumente d
                        where d.schluessel = z ->> 'schluessel' and d.version = z ->> 'version'
                          and not (v.vertragsart = any(d.vertragsarten)))
    on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

    insert into public.vertrag_unterschriften (vertrag_id, art, signatur) values
      (p_vertrag_id, 'vertrag', p_signatur_vertrag)
    on conflict (vertrag_id, art) do nothing;
    -- Pilot: kein SEPA-Mandat, also auch keine Mandatsunterschrift.
    if not v_pilot then
      insert into public.vertrag_unterschriften (vertrag_id, art, signatur) values
        (p_vertrag_id, 'sepa_mandat', p_signatur_sepa)
      on conflict (vertrag_id, art) do nothing;
    end if;

    p_unterschrieben_am := v_heute;
    v_abweichung := false;

  -- -------------------------------------------------------- Weg B/C: Papier
  else
    if v.status <> 'unterschrift_ausstehend' then
      raise exception 'vertrag_abschliessen: Einpflegen geht nur bei versendeten Unterlagen (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if nullif(btrim(coalesce(p_scan_pfad, '')), '') is null then
      raise exception 'vertrag_abschliessen: ohne hochgeladenen Scan kein Abschluss'
        using errcode = 'P0001';
    end if;
    if p_unterschrieben_am is null or p_eingang_datum is null then
      raise exception 'vertrag_abschliessen: Unterschriftsdatum und Eingangsdatum sind Pflicht'
        using errcode = 'P0001';
    end if;

    -- Abgleich Soll/Ist. Weicht etwas ab, ist der Vermerk Pflicht — es gilt das
    -- Papier, der Vermerk haelt fest, was die Eltern geaendert haben.
    v_abweichung := (v_tier     is distinct from v.tier_id)
                 or (v_laufzeit is distinct from v.laufzeit_monate)
                 or (v_beginn   is distinct from v.vertragsbeginn);
    if v_abweichung and nullif(btrim(coalesce(p_abweichung_vermerk, '')), '') is null then
      raise exception 'vertrag_abschliessen: Abweichung zum versendeten Stand braucht einen Vermerk'
        using errcode = 'P0001';
    end if;
  end if;

  -- -------------------------------------------------------- Ende und Frist
  if v_pilot then
    -- V5: festes Ende ohne Ferienverlaengerung, kein Widerrufszeitraum.
    select v.vertrag_ende as ende, null::integer as ferientage, array[]::text[] as ferien into v_ende;
    v_widerruf := null;
  else
    -- Einzige Quelle. Wirft, wenn die Rechnung ueber ferien_nrw hinauslaeuft.
    select * into v_ende from public.vertrag_ende_berechnen(v_beginn, v_laufzeit);
    v_widerruf := public.vertrag_widerruf_bis(v_beginn);
  end if;

  -- -------------------------------------------------------- Schuelerkonto
  v_erstvertrag := v.student_id is null;

  if v.student_id is not null then
    -- Folgevertrag: das Kind gibt es schon, es bekommt kein zweites Konto.
    v_student := v.student_id;

    select id into v_vorgaenger
      from public.vertraege
     where student_id = v_student
       and id <> p_vertrag_id
       and vertrag_status is not null
     order by vertrag_ende desc nulls last, abgeschlossen_am desc nulls last
     limit 1;
  else
    v_kindname := nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '');

    -- Der provisorische Schueler aus lead_lsa_freigeben traegt die LSA-Historie.
    select id into v_student from public.students where lead_id = v.lead_id;

    if p_student_uid is null then
      raise exception 'vertrag_abschliessen: p_student_uid fehlt — das Auth-Konto legt die Edge Function an'
        using errcode = '22023';
    end if;

    insert into public.profiles (id, email, role, full_name)
    values (p_student_uid, p_student_email, 'student', v_kindname)
    on conflict (id) do update
      set email = excluded.email, role = 'student', full_name = excluded.full_name;

    if p_parent_uid is not null then
      insert into public.profiles (id, email, role, full_name)
      values (p_parent_uid, p_parent_email, 'parent', null)
      on conflict (id) do update set email = excluded.email, role = 'parent';
      insert into public.parent_student (parent_id, student_id)
      values (p_parent_uid, p_student_uid)
      on conflict do nothing;
    end if;

    if v_student is null then
      -- Kein Lead-Schueler (Antrag ohne LSA): neue Zeile wie bisher.
      insert into public.students (profile_id, class_level, school_name)
      values (p_student_uid, v.klasse, v.schule)
      returning id into v_student;
    else
      -- Uebernahme: dieselbe Zeile, jetzt mit Konto. lead_id wird genullt,
      -- damit eine spaetere Lead-Loeschung den Schueler nicht mitreisst.
      update public.students
         set profile_id     = p_student_uid,
             is_provisional = false,
             lead_id        = null,
             class_level    = coalesce(v.klasse, class_level),
             school_name    = coalesce(v.schule, school_name)
       where id = v_student;
    end if;

    update public.leads
       set status = 'converted', converted_student_id = v_student
     where id = v.lead_id;
  end if;

  -- S1 (Entscheidung 11): Faecher auch beim Folgevertrag nachziehen.
  if v.fach is not null then
    select id into v_subject from public.subjects where name = v.fach;
    if v_subject is not null
       and not exists (select 1 from public.student_subjects
                        where student_id = v_student and subject_id = v_subject) then
      insert into public.student_subjects (student_id, subject_id) values (v_student, v_subject);
    end if;
  end if;

  -- S1: Schule der Akte aus dem Vertrag, solange die Akte keine hat. Eine in der
  -- Akte gepflegte Schule wird nicht ueberschrieben.
  if v.schule_id is not null then
    update public.students set schule_id = v.schule_id
     where id = v_student and schule_id is null;
  end if;

  -- Abo: eins je laufendem Vertrag. Der Guard verlangt, dass der Schueler
  -- vorher nicht mehr provisorisch ist — deshalb steht es hier unten.
  -- V5: ein Pilot hat kein Paket und damit kein Abo.
  if not v_pilot
     and not exists (select 1 from public.student_subscriptions
                      where student_id = v_student and tier_id = v_tier and status = 'active') then
    insert into public.student_subscriptions (student_id, tier_id) values (v_student, v_tier);
  end if;

  -- -------------------------------------------------------- Zugangscode
  v_code := coalesce(v.zugangscode, public.zugangscode_erzeugen());

  -- -------------------------------------------------------- Der Vertrag
  perform set_config('edvance.vertrag_rpc', '1', true);

  -- Zuerst der Vorgaenger: er ist verlaengert und faellt damit aus dem
  -- Partial-Unique-Index. Andersherum schluegen beide Vertraege gleichzeitig
  -- als "laufend" auf und der Index wuerde den Abschluss abweisen.
  if v_vorgaenger is not null then
    update public.vertraege
       set verlaengerung_status = 'verlaengert'
     where id = v_vorgaenger;
  end if;

  update public.vertraege
     set status                 = 'abgeschlossen',
         vertrag_status         = case when v_pilot then 'aktiv' else 'im_widerruf' end,
         abgeschlossen_at       = now(),
         abgeschlossen_am       = coalesce(p_unterschrieben_am, v_heute),
         abschluss_weg          = p_weg,
         unterschrieben_am      = p_unterschrieben_am,
         eingang_datum          = p_eingang_datum,
         scan_pfad              = coalesce(p_scan_pfad, scan_pfad),
         abweichung_vermerk     = coalesce(nullif(btrim(coalesce(p_abweichung_vermerk, '')), ''),
                                           abweichung_vermerk),
         tier_id                = v_tier,
         laufzeit_monate        = v_laufzeit,
         vertragsbeginn         = v_beginn,
         preis_cents            = v_preis,
         einheiten              = v_einheiten,
         vertrag_ende           = v_ende.ende,
         ferientage             = v_ende.ferientage,
         widerruf_bis           = v_widerruf,
         zugangscode            = v_code,
         zugangscode_erzeugt_am = coalesce(zugangscode_erzeugt_am, v_heute),
         student_id             = v_student,
         vorgaenger_id          = coalesce(vorgaenger_id, v_vorgaenger),
         glaeubiger_id          = coalesce(glaeubiger_id,
                                    (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;

  perform set_config('edvance.vertrag_rpc', '', true);

  -- S1 (Entscheidung 10): Report 1 = die LSA, beim ersten Vertrag des Kindes.
  -- Die letzte abgeschlossene LSA; ohne LSA kein Report 1.
  if v_erstvertrag then
    select l.id into v_lsa
      from public.lsa_sessions l
     where l.student_id = v_student and l.status = 'completed'
       and not l.testlauf
     order by l.completed_at desc nulls last
     limit 1;
    if v_lsa is not null
       and not exists (select 1 from public.eltern_reports where lsa_session_id = v_lsa) then
      perform public.eltern_report_eintragen(
        p_student_id     => v_student,
        p_art            => 'lernstandsanalyse',
        p_lsa_session_id => v_lsa);
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'student_id',   v_student,
    'zugangscode',  v_code,
    'vertrag_ende', v_ende.ende,
    'ferientage',   v_ende.ferientage,
    'ferien',       to_jsonb(v_ende.ferien),
    'widerruf_bis', v_widerruf,
    'abweichung',   coalesce(v_abweichung, false));
end;
$function$;

-- ------------------------------------------------------------------ vertraege_aktuell
-- Neu: Spalte vertragsart (am Ende) und Beitrag eines Pilots ausdrücklich 0.
CREATE OR REPLACE VIEW public.vertraege_aktuell WITH (security_invoker = true) AS
 WITH basis AS (
         SELECT v.id, v.created_at, v.updated_at, v.created_by, v.lead_id, v.status, v.in_vorbereitung_at,
            v.unterschrift_ausstehend_at, v.abgeschlossen_at, v.abgelehnt_at, v.abgelehnt_grund, v.abgelehnt_notiz,
            v.abschluss_weg, v.unterschrieben_am, v.eltern_vorname, v.eltern_nachname, v.strasse, v.hausnummer,
            v.plz, v.ort, v.eltern_telefon, v.eltern_email, v.kind_vorname, v.kind_nachname, v.kind_geburtsdatum,
            v.klasse, v.fach, v.schule, v.laufzeit_monate, v.tier_id, v.preis_cents, v.vertragsbeginn,
            v.kontoinhaber, v.iban_masked, v.mandatsreferenz, v.glaeubiger_id, v.einheiten, v.student_id,
            v.schule_id, v.vorgaenger_id, v.vertrag_status, v.abgeschlossen_am, v.eingang_datum, v.vertrag_ende,
            v.ferientage, v.widerruf_bis, v.widerrufen_am, v.gekuendigt_zum, v.kuendigung_grund, v.zahlungsstatus,
            v.zahlungsstatus_seit, v.offener_betrag_cents, v.verlaengerung_status, v.verlaengerung_grund,
            v.wiedervorlage_am, v.rueckmeldung_bis, v.abweichung_vermerk, v.zugangscode, v.zugangscode_erzeugt_am,
            v.zugangscode_gesperrt_am, v.scan_pfad, v.vertragsart,
            vertrag_wirksamer_status(v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis) AS wirksamer_status,
                CASE
                    WHEN v.vertragsbeginn IS NULL OR CURRENT_DATE < v.vertragsbeginn THEN NULL::integer
                    ELSE 1 + (EXTRACT(year FROM CURRENT_DATE)::integer * 12 + EXTRACT(month FROM CURRENT_DATE)::integer) - (EXTRACT(year FROM v.vertragsbeginn)::integer * 12 + EXTRACT(month FROM v.vertragsbeginn)::integer)
                END AS laufzeit_monat
           FROM vertraege v
          WHERE v.status = 'abgeschlossen'::text
        )
 SELECT id, created_at, updated_at, created_by, lead_id, status, in_vorbereitung_at, unterschrift_ausstehend_at,
    abgeschlossen_at, abgelehnt_at, abgelehnt_grund, abgelehnt_notiz, abschluss_weg, unterschrieben_am,
    eltern_vorname, eltern_nachname, strasse, hausnummer, plz, ort, eltern_telefon, eltern_email, kind_vorname,
    kind_nachname, kind_geburtsdatum, klasse, fach, schule, laufzeit_monate, tier_id, preis_cents, vertragsbeginn,
    kontoinhaber, iban_masked, mandatsreferenz, glaeubiger_id, einheiten, student_id, schule_id, vorgaenger_id,
    vertrag_status, abgeschlossen_am, eingang_datum, vertrag_ende, ferientage, widerruf_bis, widerrufen_am,
    gekuendigt_zum, kuendigung_grund, zahlungsstatus, zahlungsstatus_seit, offener_betrag_cents,
    verlaengerung_status, verlaengerung_grund, wiedervorlage_am, rueckmeldung_bis, abweichung_vermerk, zugangscode,
    zugangscode_erzeugt_am, zugangscode_gesperrt_am, scan_pfad, wirksamer_status, laufzeit_monat,
    row_number() OVER (PARTITION BY (COALESCE(student_id, id)) ORDER BY vertragsbeginn DESC NULLS LAST, abgeschlossen_am DESC NULLS LAST, created_at DESC) = 1 AS ist_aktueller_vertrag,
        CASE
            WHEN vertragsart = 'pilot'::text THEN 0
            WHEN preis_cents IS NULL OR laufzeit_monat IS NULL OR laufzeit_monate IS NULL THEN 0
            WHEN laufzeit_monat >= 1 AND laufzeit_monat <= laufzeit_monate THEN preis_cents
            ELSE 0
        END AS beitrag_diesen_monat_cents,
    zugangscode IS NOT NULL AND zugangscode_gesperrt_am IS NULL AND (wirksamer_status = ANY (ARRAY['im_widerruf'::text, 'aktiv'::text])) AS zugangscode_gueltig,
    vertrag_ende - CURRENT_DATE AS endet_in_tagen,
    vertragsart
   FROM basis b;

-- ------------------------------------------------------------------ slots_vertrag_json
-- Neu: vertragsart; ein Pilot hat kein Paket, sein Rhythmus ist ein Termin je Woche (Entscheidung 4).
CREATE OR REPLACE FUNCTION public.slots_vertrag_json(p_vertrag_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select jsonb_build_object(
           'vertrag_id', v.id, 'paket', t.name, 'laufzeit_monate', v.laufzeit_monate, 'einheiten', v.einheiten,
           'beginn', v.vertragsbeginn, 'stichtag', v.vertrag_ende, 'gekuendigt_zum', v.gekuendigt_zum,
           'rhythmus', case when v.vertragsart = 'pilot'
                            then jsonb_build_object('woechentlich', 1, 'vierzehntaeglich', 0)
                            else (select jsonb_build_object('woechentlich', r.woechentlich, 'vierzehntaeglich', r.vierzehntaeglich)
                                    from public.slot_rhythmus r where r.tier_id = v.tier_id and r.laufzeit_monate = v.laufzeit_monate)
                       end,
           'vertragsart', v.vertragsart)
    from public.vertraege v left join public.tiers t on t.id = v.tier_id
   where v.id = p_vertrag_id;
$function$;

commit;
