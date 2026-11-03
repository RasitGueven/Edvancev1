-- PRUEFUNG: LSA-Report per Mail (Migration 20261103090129, Bauauftrag LR-2).
--
-- Laeuft in begin … rollback, legt die Testdaten selbst an (Praefix ZZ_). Braucht
-- ein Admin-Profil und eine beliebige lsa_sessions-Zeile (nur als Verweis).
-- Claims MIT Rolle — ohne 'role' gilt der Aufruf als Systemaufruf.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/lsa_report_mailversand.PRUEFUNG.sql
--
-- Signatur gegen die Migration abgeglichen:
--   lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text) -> uuid

begin;

do $$
declare
  v_admin   uuid;
  v_lead    uuid;
  v_session uuid;
  v_id      uuid;
  v_n       integer;
  v_text    text;
  v_ok      boolean;
  v_sha     text := repeat('ab', 32);
  v_pfad    text;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  select id into v_session from lsa_sessions limit 1;
  assert v_session is not null, 'Keine LSA-Sitzung vorhanden';
  v_pfad := v_session || '/20261103-101500.pdf';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  insert into leads (full_name, status, contact_email)
    values ('ZZ_Report Kind', 'contacted', 'zz_report@edvance.invalid') returning id into v_lead;

  -- ========================================================================
  -- 1. Nur Admin darf protokollieren
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(p_lead_id => v_lead, p_anlass => 'lsa_report',
      p_empfaenger => 'zz_report@edvance.invalid', p_lsa_session_id => v_session, p_anhang_pfad => v_pfad);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Protokoll ohne Admin moeglich';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  raise notice '1  ok  nur Admin';

  -- ========================================================================
  -- 2. Die Terminbestaetigung mit genau den Parametern der deployten Fassung
  -- ========================================================================
  -- Rueckwaertsvertraeglichkeit: termin.ts ruft so auf, zwischen Einspielen und Deploy.
  v_id := public.lead_mail_protokollieren(
    p_lead_id    => v_lead,
    p_anlass     => 'terminbestaetigung',
    p_empfaenger => 'zz_report@edvance.invalid',
    p_ort        => '  ZZ_Musterweg 1  ',
    p_termin_at  => timestamptz '2026-11-10 15:00+00',
    p_fehler     => null);
  select ort into v_text from lead_mail_versand
   where id = v_id and lsa_session_id is null and anhang_pfad is null and erfolgt_von = v_admin;
  assert v_text = 'ZZ_Musterweg 1', 'Terminbestaetigung nicht wie bisher: ' || coalesce(v_text, '∅');
  raise notice '2  ok  Terminbestaetigung mit alten Parametern';

  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(p_lead_id => v_lead, p_anlass => 'terminbestaetigung',
      p_empfaenger => 'zz_report@edvance.invalid', p_ort => null);
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'Terminbestaetigung ohne Ort angenommen';
  raise notice '3  ok  Terminbestaetigung braucht weiter einen Ort';

  -- ========================================================================
  -- 4. lsa_report: Sitzung, Pfad, Pruefsumme, kein Ort
  -- ========================================================================
  v_id := public.lead_mail_protokollieren(
    p_lead_id => v_lead, p_anlass => 'lsa_report', p_empfaenger => 'zz_report@edvance.invalid',
    p_lsa_session_id => v_session, p_anhang_pfad => v_pfad, p_anhang_sha256 => v_sha);
  select count(*) into v_n from lead_mail_versand
   where id = v_id and anlass = 'lsa_report' and ort is null and lsa_session_id = v_session
     and anhang_pfad = v_pfad and anhang_sha256 = v_sha and fehler is null;
  assert v_n = 1, 'lsa_report nicht vollstaendig protokolliert';

  -- Auch der gescheiterte Versuch steht drin, ohne Pruefsumme (Datei nicht geladen).
  v_id := public.lead_mail_protokollieren(
    p_lead_id => v_lead, p_anlass => 'lsa_report', p_empfaenger => 'zz_report@edvance.invalid',
    p_lsa_session_id => v_session, p_anhang_pfad => v_pfad, p_fehler => 'Graph sendMail 403');
  select fehler into v_text from lead_mail_versand where id = v_id and anhang_sha256 is null;
  assert v_text = 'Graph sendMail 403', 'gescheiterter lsa_report fehlt';
  raise notice '4  ok  lsa_report mit Sitzung, Pfad und SHA-256, auch gescheitert';

  -- ========================================================================
  -- 5. Pflichtangaben und Formate
  -- ========================================================================
  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(p_lead_id => v_lead, p_anlass => 'lsa_report',
      p_empfaenger => 'zz_report@edvance.invalid', p_lsa_session_id => v_session);
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'lsa_report ohne Pfad angenommen';

  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(p_lead_id => v_lead, p_anlass => 'lsa_report',
      p_empfaenger => 'zz_report@edvance.invalid', p_anhang_pfad => v_pfad, p_anhang_sha256 => 'XYZ');
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'ungueltige Pruefsumme angenommen';

  v_ok := false;
  begin
    perform public.lead_mail_protokollieren(p_lead_id => v_lead, p_anlass => 'irgendwas',
      p_empfaenger => 'zz_report@edvance.invalid', p_ort => 'x');
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'unbekannter Anlass angenommen';
  raise notice '5  ok  Pfad Pflicht, SHA-256 hex, zwei Anlaesse';

  -- ========================================================================
  -- 6. Kein direktes Schreiben an der RPC vorbei
  -- ========================================================================
  set local role authenticated;
  v_ok := false;
  begin
    insert into public.lead_mail_versand (lead_id, anlass, empfaenger, anhang_pfad)
    values (v_lead, 'lsa_report', 'zz@edvance.invalid', v_pfad);
  exception when insufficient_privilege then v_ok := true; end;
  reset role;
  assert v_ok, 'direkter Insert unter RLS moeglich';
  raise notice '6  ok  Schreiben nur ueber die RPC';

  -- ========================================================================
  -- 7. Bucket: privat, nur PDF bis 3 MB (wo Storage die Spalten kennt)
  -- ========================================================================
  select count(*) into v_n from storage.buckets where id = 'lsa_reports' and public = false;
  assert v_n = 1, 'Bucket lsa_reports fehlt oder ist oeffentlich';
  if exists (select 1 from information_schema.columns
              where table_schema = 'storage' and table_name = 'buckets' and column_name = 'allowed_mime_types') then
    execute $q$select count(*) from storage.buckets
      where id = 'lsa_reports' and file_size_limit = 3145728 and allowed_mime_types = array['application/pdf']$q$ into v_n;
    assert v_n = 1, 'Grenzen des Buckets nicht gesetzt';
  end if;
  raise notice '7  ok  Bucket privat, nur PDF, 3 MB';

  -- ========================================================================
  -- 8. Storage: Admin laedt hoch und liest; Nicht-Admin nicht; nichts ueberschreiben oder loeschen
  -- ========================================================================
  -- Die CI-Grundlage gibt authenticated keine Rechte am Schema storage; dort nur die Policies zaehlen.
  if not has_schema_privilege('authenticated', 'storage', 'usage') then
    select count(*) into v_n from pg_policies
     where schemaname = 'storage' and tablename = 'objects' and policyname like 'lsa_reports_storage_%';
    assert v_n = 2, 'Storage-Policies fehlen: ' || v_n;
    raise notice '8  ok  zwei Storage-Policies (ohne Storage-Rechte nur gezaehlt)';
    raise notice '';
    raise notice '== LSA-Report per Mail: alle Pruefungen bestanden ==';
    return;
  end if;
  set local role authenticated;
  insert into storage.objects (bucket_id, name) values ('lsa_reports', v_pfad);
  select count(*) into v_n from storage.objects where bucket_id = 'lsa_reports' and name = v_pfad;
  assert v_n = 1, 'Admin sieht die hochgeladene Datei nicht';

  v_ok := false;
  begin
    insert into storage.objects (bucket_id, name) values ('lsa_reports', 'fremd/../x.pdf');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Pfad ausserhalb des Musters angenommen';

  update storage.objects set name = v_session || '/20261103-101501.pdf'
   where bucket_id = 'lsa_reports' and name = v_pfad;
  get diagnostics v_n = row_count;
  assert v_n = 0, 'Admin kann eine versendete Fassung umbenennen';
  delete from storage.objects where bucket_id = 'lsa_reports' and name = v_pfad;
  get diagnostics v_n = row_count;
  assert v_n = 0, 'Admin kann eine versendete Fassung loeschen';

  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  select count(*) into v_n from storage.objects where bucket_id = 'lsa_reports';
  assert v_n = 0, 'Nicht-Admin sieht Reports';
  v_ok := false;
  begin
    insert into storage.objects (bucket_id, name) values ('lsa_reports', v_session || '/20261103-101502.pdf');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Nicht-Admin darf hochladen';
  reset role;
  raise notice '8  ok  Storage nur Admin, ohne Update und Delete';

  raise notice '';
  raise notice '== LSA-Report per Mail: alle Pruefungen bestanden ==';
end $$;

-- Rechte
select 'public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text)' as funktion,
       case when not has_function_privilege('anon',
              'public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text)'::regprocedure, 'execute')
             and has_function_privilege('authenticated',
              'public.lead_mail_protokollieren(uuid, text, text, text, timestamptz, text, uuid, text, text)'::regprocedure, 'execute')
             and (select count(*) from pg_proc where proname = 'lead_mail_protokollieren') = 1
            then 'OK' else 'FEHLER' end as ergebnis;

rollback;
