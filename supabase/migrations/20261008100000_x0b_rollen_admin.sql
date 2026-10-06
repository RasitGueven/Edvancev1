-- X0b.2 Rollenpruefungen NULL-sicher (Bauauftrag Session-Rahmen P1, Paket X0b).
--
-- get_my_role() liefert NULL, wenn der Angemeldete keine Zeile in profiles hat
-- (docs/jwt-identitaet-befund.md). "if get_my_role() <> 'admin' ... then raise" wird
-- dann NULL, der raise-Zweig feuert nicht: Das Tor stand fuer solche Konten offen.
--
-- Grundlage ist je Funktion die Prod-Definition (pg_get_functiondef, 06.10.2026).
-- Geaendert ist nur die Rollenbedingung: coalesce(..., '') statt nacktem
-- get_my_role(). Kein Systemweg ruft diese Funktionen (Bestandsaufnahme im PR),
-- deshalb kein "or public.ist_systemaufruf()". Rechte und Signaturen bleiben,
-- create or replace behaelt die Grants.

-- ── audit_log_schreiben(text,text,uuid) ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.audit_log_schreiben(p_aktion text, p_objekt_typ text, p_objekt_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'audit_log_schreiben: kein angemeldeter Aufrufer' using errcode = '42501';
  end if;
  -- SECURITY DEFINER haengt an dieser Zeile: ohne sie duerfte jeder Angemeldete
  -- beliebige Eintraege ins Protokoll schreiben und es damit unbrauchbar machen.
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'audit_log_schreiben: nur Admin' using errcode = '42501';
  end if;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), p_aktion, p_objekt_typ, p_objekt_id)
  returning id into v_id;

  return v_id;
end;
$function$;

-- ── lead_delete(uuid) ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.lead_delete(p_lead_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_lead leads%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'lead_delete: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_delete: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- Aufbewahrungspflicht: ein konvertierter Lead wird nicht über diesen Weg
  -- gelöscht.
  if v_lead.status = 'converted' then
    raise exception 'lead_delete: konvertierter Lead — Aufbewahrungspflicht'
      using errcode = 'P0001';
  end if;

  -- Kaskade (S7): leads → lead_assessments (A3) UND
  -- leads → students(lead_id) → lsa_sessions → lsa_responses (A1 Option 1).
  -- Der provisorische Schüler und seine LSA-Daten fallen restlos mit.
  delete from leads where id = p_lead_id;

  return jsonb_build_object('ok', true, 'lead_id', p_lead_id);
end;
$function$;

-- ── platz_assign(uuid,uuid) ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.platz_assign(p_platz_profile_id uuid, p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
  v_id      uuid;
  v_expires timestamptz;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'platz_assign: nur Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from platz_devices where profile_id = p_platz_profile_id) then
    raise exception 'platz_assign: kein Platz-Konto (platz_devices)'
      using errcode = 'P0002';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'platz_assign: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'platz_assign: Session ist nicht in Durchfuehrung (status=%)',
      v_session.status using errcode = 'P0001';
  end if;

  -- Aktive Zuweisung → verweigern (bewusste Entscheidung am Empfang noetig).
  if exists (
    select 1 from platz_assignments
     where platz_profile_id = p_platz_profile_id
       and released_at is null
       and expires_at > now()
  ) then
    raise exception 'platz_assign: Platz hat bereits eine aktive Zuweisung'
      using errcode = 'P0001';
  end if;

  -- Abgelaufene, nie freigegebene Zeile aufraeumen — sonst blockierte der
  -- Partial-Unique-Index den Platz dauerhaft (siehe Kommentar am Index).
  update platz_assignments
     set released_at = now()
   where platz_profile_id = p_platz_profile_id
     and released_at is null;

  insert into platz_assignments (platz_profile_id, session_id, created_by)
  values (p_platz_profile_id, p_session_id, auth.uid())
  returning id, expires_at into v_id, v_expires;

  return jsonb_build_object('ok', true, 'assignment_id', v_id, 'expires_at', v_expires);
end;
$function$;

-- ── platz_release(uuid) ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.platz_release(p_assignment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'platz_release: nur Admin' using errcode = '42501';
  end if;

  update platz_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from platz_assignments where id = p_assignment_id
  ) then
    raise exception 'platz_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  return jsonb_build_object('ok', true, 'released', v_count = 1);
end;
$function$;
