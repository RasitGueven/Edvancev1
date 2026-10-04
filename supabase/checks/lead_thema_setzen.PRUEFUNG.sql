-- PRUEFUNG: lead_thema_setzen und lead_mail_protokollieren
-- (Migrationen 20261004001333, 20261004001351).
--
-- Laeuft in begin … rollback, legt die Testdaten selbst an (Praefix ZZ_).
-- Claims MIT Rolle — ohne 'role' gilt der Aufruf als Systemaufruf.
--
--     ~/bin/dbread -f supabase/checks/lead_thema_setzen.PRUEFUNG.sql
--
-- Unter dbread (read-only) laufen nur die Teile 1 und 2 (Katalog); Teil 3
-- schreibt Testzeilen und meldet sich dort als uebersprungen. Voll laeuft das
-- Skript in einer Wegwerf-DB oder mit psql gegen eine beschreibbare Sitzung.
--
-- Signaturen gegen den Schema-Abzug abgeglichen:
--   lead_thema_setzen(uuid, text, text, text) -> void
--   lead_mail_protokollieren(uuid, text, text, timestamptz, text) -> uuid

begin;

-- ==========================================================================
-- 1. Funktionen existieren, security definer, fester search_path
-- ==========================================================================
do $$
declare
  v_n integer;
begin
  select count(*) into v_n
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.oid in ('public.lead_thema_setzen(uuid, text, text, text)'::regprocedure,
                   'public.lead_mail_protokollieren(uuid, text, text, timestamptz, text)'::regprocedure)
     and p.prosecdef
     and p.proconfig @> array['search_path=public, pg_temp'];
  assert v_n = 2, 'Funktionen fehlen oder sind nicht security definer mit search_path';

  -- Keine Ueberladung daneben.
  select count(*) into v_n
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in ('lead_thema_setzen', 'lead_mail_protokollieren');
  assert v_n = 2, 'Ueberladung vorhanden';
  raise notice '1  ok  Funktionen da, security definer, keine Ueberladung';
end $$;

-- ==========================================================================
-- 2. Rechte: authenticated ja, anon und public nein; Tabelle mit RLS
-- ==========================================================================
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.lead_thema_setzen(uuid, text, text, text)',
    'public.lead_mail_protokollieren(uuid, text, text, timestamptz, text)'
  ] loop
    assert has_function_privilege('authenticated', f, 'execute'), 'authenticated fehlt: ' || f;
    assert not has_function_privilege('anon', f, 'execute'), 'anon darf: ' || f;
    assert not exists (
      select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
       where p.oid = f::regprocedure and a.grantee = 0 and a.privilege_type = 'EXECUTE'
    ), 'PUBLIC darf: ' || f;
  end loop;

  assert (select relrowsecurity from pg_class where oid = 'public.lead_mail_versand'::regclass),
    'lead_mail_versand ohne RLS';
  raise notice '2  ok  Rechte: nur authenticated, RLS auf lead_mail_versand';
end $$;

-- ==========================================================================
-- 3. Verhalten (nur in beschreibbarer Sitzung)
-- ==========================================================================
do $$
declare
  v_admin  uuid;
  v_lead   uuid;
  v_fremd  uuid := gen_random_uuid();
  v_t1     text;
  v_t2     text;
  v_t3     text;
  v_n      integer;
  v_ok     boolean;
  v_id     uuid;
begin
  if current_setting('transaction_read_only') = 'on' then
    raise notice '3  --  Verhalten uebersprungen (read-only Sitzung)';
    return;
  end if;

  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  select thema_key into v_t1 from themen where fach = 'mathematik' order by sort, thema_key limit 1;
  select thema_key into v_t2 from themen where fach = 'mathematik' order by sort, thema_key offset 1 limit 1;
  select thema_key into v_t3 from themen where fach = 'mathematik' order by sort, thema_key offset 2 limit 1;
  assert v_t3 is not null, 'Themenkatalog hat weniger als drei Mathe-Themen';

  insert into leads (full_name, status) values ('ZZ_Thema Kind', 'contacted') returning id into v_lead;

  -- 3a. Fremde Rolle abgewiesen
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_fremd, 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.lead_thema_setzen(v_lead, 'mathematik', v_t1);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'lead_thema_setzen ohne Admin moeglich';
  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(v_lead, 'terminbestaetigung', 'zz@edvance.invalid');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'lead_mail_protokollieren ohne Admin moeglich';
  raise notice '3a ok  fremde Rolle abgewiesen';

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  -- 3b. Setzen
  perform public.lead_thema_setzen(v_lead, 'mathematik', v_t1);
  select count(*) into v_n from lead_themen
   where lead_id = v_lead and status = 'aktuell' and thema_key = v_t1 and quelle = 'gespraech';
  assert v_n = 1, 'Setzen: kein aktuelles Thema';
  raise notice '3b ok  setzen';

  -- 3c. Ersetzen: altes 'aktuell' faellt weg, ein 'behandelt' wird umgestellt
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  values (v_lead, 'mathematik', v_t2, 'behandelt', 'schulplan');
  perform public.lead_thema_setzen(v_lead, 'mathematik', v_t2);
  select count(*) into v_n from lead_themen where lead_id = v_lead and thema_key = v_t1;
  assert v_n = 0, 'Ersetzen: altes aktuell steht noch';
  select count(*) into v_n from lead_themen
   where lead_id = v_lead and thema_key = v_t2 and status = 'aktuell' and quelle = 'gespraech';
  assert v_n = 1, 'Ersetzen: behandelt nicht auf aktuell umgestellt';
  -- Gleiches Thema noch einmal: bleibt genau eine Zeile.
  perform public.lead_thema_setzen(v_lead, 'mathematik', v_t2);
  select count(*) into v_n from lead_themen where lead_id = v_lead and status = 'aktuell';
  assert v_n = 1, 'Gleiches Thema doppelt';
  raise notice '3c ok  ersetzen';

  -- 3d. Entfernen: 'aktuell' weg, 'behandelt' bleibt
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  values (v_lead, 'mathematik', v_t3, 'behandelt', 'gespraech');
  perform public.lead_thema_setzen(v_lead, 'mathematik', null);
  select count(*) into v_n from lead_themen where lead_id = v_lead and status = 'aktuell';
  assert v_n = 0, 'Entfernen: aktuell steht noch';
  select count(*) into v_n from lead_themen where lead_id = v_lead and status = 'behandelt';
  assert v_n = 1, 'Entfernen: behandelt mitgeloescht';
  raise notice '3d ok  entfernen';

  -- 3e. Atomar: scheitert das Schreiben, steht das alte Thema noch
  perform public.lead_thema_setzen(v_lead, 'mathematik', v_t1);
  v_ok := false;
  begin
    perform public.lead_thema_setzen(v_lead, 'mathematik', 'zz_gibt_es_nicht');
  exception when foreign_key_violation then v_ok := true; end;
  assert v_ok, 'Unbekanntes Thema nicht abgewiesen';
  select count(*) into v_n from lead_themen
   where lead_id = v_lead and status = 'aktuell' and thema_key = v_t1;
  assert v_n = 1, 'Nach Fehlschlag kein Thema mehr — nicht atomar';
  raise notice '3e ok  atomar: Fehlschlag laesst altes Thema stehen';

  -- 3f. Versandprotokoll: Urheber, Termin, Fehlerzeile
  v_id := public.lead_mail_protokollieren(v_lead, 'terminbestaetigung',
    'zz@edvance.invalid', timestamptz '2026-10-08 14:00+00', '  ');
  select count(*) into v_n from lead_mail_versand
   where id = v_id and erfolgt_von = v_admin and fehler is null and termin_at is not null;
  assert v_n = 1, 'Protokoll: Urheber/Termin fehlen oder Leerfehler nicht genullt';
  v_id := public.lead_mail_protokollieren(v_lead, 'terminbestaetigung',
    'zz@edvance.invalid', null, 'Graph 403');
  select count(*) into v_n from lead_mail_versand where id = v_id and fehler = 'Graph 403';
  assert v_n = 1, 'Protokoll: Fehlerzeile fehlt';
  raise notice '3f ok  Versandprotokoll';
end $$;

rollback;
