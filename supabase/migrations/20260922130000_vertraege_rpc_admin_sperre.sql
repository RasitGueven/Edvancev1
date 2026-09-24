-- Vertrags-RPCs: Admin-Sperre auch fuer Aufrufer ohne Profilzeile.
--
-- Befund aus supabase/checks/vertraege_prozess.PRUEFUNG.sql: Ein eingeloggter
-- Nutzer ohne Zeile in profiles bekommt aus get_my_role() NULL. Die Pruefung
-- `get_my_role() <> 'admin'` ist dann NULL, das if greift nicht — die
-- security-definer-RPCs liefen durch. Die RLS-Policies (`= 'admin'`) waren
-- nicht betroffen: NULL ist dort false.
--
-- Die vier Funktionen sind unveraendert bis auf die Sperre
-- `coalesce(get_my_role(), '') <> 'admin'`. Grants bleiben bei create or
-- replace erhalten.
--
-- Kein begin/commit — mit --single-transaction einspielen.

-- Legt den Vertrag an (vorbelegt aus dem Lead) und nimmt den Lead vom Board.
-- Idempotent: gibt es schon einen offenen Vertrag, kommt dessen id zurueck.
create or replace function public.vertrag_starten(p_lead_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead leads%rowtype;
  v_id   uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id for update;
  if not found then
    raise exception 'vertrag_starten: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  select id into v_id from vertraege where lead_id = p_lead_id and status <> 'abgelehnt';
  if v_id is not null then
    return v_id;
  end if;

  if v_lead.status <> 'lsa_fertig' then
    raise exception 'vertrag_starten: Lead steht nicht auf "Analyse abgeschlossen"'
      using errcode = 'P0001';
  end if;

  insert into vertraege (
    created_by, lead_id, eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach, schule
  ) values (
    auth.uid(), p_lead_id, v_lead.contact_phone, v_lead.contact_email,
    coalesce(v_lead.first_name, split_part(v_lead.full_name, ' ', 1)),
    nullif(regexp_replace(v_lead.full_name, '^\S+\s*', ''), ''),
    v_lead.birth_date, v_lead.class_level, v_lead.subjects[1], v_lead.school_name
  )
  returning id into v_id;

  update leads set status = 'vertrag' where id = p_lead_id;
  return v_id;
end;
$$;

-- Protokolliert einen Versand. Unterlagen (Druck/E-Mail) schieben einen
-- Vertrag in Vorbereitung auf 'unterschrift_ausstehend'.
create or replace function public.vertrag_versand_protokollieren(
  p_vertrag_id uuid,
  p_weg        text,
  p_anlass     text,
  p_empfaenger text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versand_protokollieren: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versand_protokollieren: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_status = 'abgelehnt' then
    raise exception 'vertrag_versand_protokollieren: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  insert into vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
  values (p_vertrag_id, p_weg, p_anlass, p_empfaenger, auth.uid());

  if p_anlass = 'unterlagen' and v_status = 'in_vorbereitung' then
    perform set_config('edvance.vertrag_rpc', '1', true);
    update vertraege
       set status = 'unterschrift_ausstehend',
           unterschrift_ausstehend_at = now(),
           glaeubiger_id = coalesce(glaeubiger_id,
             (select glaeubiger_id from vertrag_einstellungen))
     where id = p_vertrag_id;
    perform set_config('edvance.vertrag_rpc', '', true);
  end if;
end;
$$;

-- Abschluss. 'vor_ort': alle aktiven Pflicht-Dokumente in ihrer aktuellen
-- Fassung angehakt, beide Unterschriften, IBAN hinterlegt. 'papier': nur das
-- Datum, an dem der unterschriebene Vertrag zurueckkam.
-- Idempotent: ein bereits abgeschlossener Vertrag bleibt unveraendert.
--
-- p_zustimmungen: [{"schluessel":"agb","version":"platzhalter-v1","akzeptiert_at":"<iso>"}, ...]
create or replace function public.vertrag_abschliessen(
  p_vertrag_id          uuid,
  p_weg                 text,
  p_zustimmungen        jsonb default '[]'::jsonb,
  p_signatur_vertrag    text  default null,
  p_signatur_sepa       text  default null,
  p_unterschrieben_am   date  default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vertrag vertraege%rowtype;
  v_fehlt   text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_abschliessen: nur Admin' using errcode = '42501';
  end if;

  select * into v_vertrag from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_abschliessen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_vertrag.status = 'abgeschlossen' then
    return;
  end if;
  if v_vertrag.status = 'abgelehnt' then
    raise exception 'vertrag_abschliessen: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;
  if v_vertrag.tier_id is null or v_vertrag.laufzeit_monate is null
     or v_vertrag.vertragsbeginn is null then
    raise exception 'vertrag_abschliessen: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;

  if p_weg = 'vor_ort' then
    if not exists (select 1 from vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_abschliessen: IBAN fehlt' using errcode = 'P0001';
    end if;
    if nullif(p_signatur_vertrag, '') is null or nullif(p_signatur_sepa, '') is null then
      raise exception 'vertrag_abschliessen: Unterschrift fehlt' using errcode = 'P0001';
    end if;

    select string_agg(d.schluessel, ', ') into v_fehlt
      from vertrag_dokumente d
     where d.aktiv and d.pflicht
       and not exists (
         select 1 from jsonb_array_elements(p_zustimmungen) z
          where z ->> 'schluessel' = d.schluessel and z ->> 'version' = d.version);
    if v_fehlt is not null then
      raise exception 'vertrag_abschliessen: Zustimmung fehlt fuer %', v_fehlt
        using errcode = 'P0001';
    end if;

    insert into vertrag_zustimmungen
      (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
    select p_vertrag_id, z ->> 'schluessel', z ->> 'version',
           coalesce((z ->> 'akzeptiert_at')::timestamptz, now()), auth.uid()
      from jsonb_array_elements(p_zustimmungen) z
    on conflict do nothing;

    insert into vertrag_unterschriften (vertrag_id, art, signatur) values
      (p_vertrag_id, 'vertrag',     p_signatur_vertrag),
      (p_vertrag_id, 'sepa_mandat', p_signatur_sepa)
    on conflict (vertrag_id, art) do nothing;
  elsif p_weg = 'papier' then
    if p_unterschrieben_am is null then
      raise exception 'vertrag_abschliessen: Abschlussdatum fehlt' using errcode = 'P0001';
    end if;
  else
    raise exception 'vertrag_abschliessen: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  perform set_config('edvance.vertrag_rpc', '1', true);
  update vertraege
     set status = 'abgeschlossen',
         abgeschlossen_at = now(),
         abschluss_weg = p_weg,
         unterschrieben_am = coalesce(p_unterschrieben_am,
                                      (now() at time zone 'Europe/Berlin')::date),
         glaeubiger_id = coalesce(glaeubiger_id,
           (select glaeubiger_id from vertrag_einstellungen))
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);
end;
$$;

-- "Doch abgelehnt": Vertrag und Lead gehen mit demselben Grund ins Archiv.
create or replace function public.vertrag_ablehnen(
  p_vertrag_id uuid,
  p_grund      text,
  p_notiz      text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vertrag vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_ablehnen: nur Admin' using errcode = '42501';
  end if;

  select * into v_vertrag from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_ablehnen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_vertrag.status = 'abgelehnt' then
    return;
  end if;
  if v_vertrag.status = 'abgeschlossen' then
    raise exception 'vertrag_ablehnen: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;

  perform set_config('edvance.vertrag_rpc', '1', true);
  update vertraege
     set status = 'abgelehnt', abgelehnt_at = now(),
         abgelehnt_grund = p_grund, abgelehnt_notiz = p_notiz
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  update leads
     set status = 'rejected', rejection_reason = p_grund, rejection_note = p_notiz
   where id = v_vertrag.lead_id;
end;
$$;
