-- PRUEFUNG: Vertrags-PDF und Archiv (Migration 20260928160000).
--
-- Laeuft in begin … rollback, legt die Testdaten selbst an (Praefix ZZ_).
-- Claims MIT Rolle — ohne 'role' gilt der Aufruf als Systemaufruf.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/vertrag_pdf.PRUEFUNG.sql
--
-- Signatur gegen den Schema-Abzug abgeglichen:
--   vertrag_datei_eintragen(uuid, text, text, text, integer) -> uuid

begin;

do $$
declare
  v_admin   uuid;
  v_tier    uuid;
  v_lead    uuid;
  v_lead2   uuid;
  v_offen   uuid;
  v_vertrag uuid;
  v_datei   uuid;
  v_hash    text := repeat('a', 64);
  v_hash2   text := repeat('b', 64);
  v_n       integer;
  v_text    text;
  v_ok      boolean;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  select id into v_tier from tiers where name = 'Premium';

  insert into leads (full_name, status) values ('ZZ_Pdf Kind', 'vertrag') returning id into v_lead;
  insert into leads (full_name, status) values ('ZZ_Pdf Offen', 'vertrag') returning id into v_lead2;

  insert into vertraege (
    lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
    unterschrieben_am, tier_id, laufzeit_monate, preis_cents, einheiten,
    vertragsbeginn, vertrag_ende, ferientage, widerruf_bis,
    eltern_vorname, eltern_nachname, eltern_email, kind_vorname, kind_nachname,
    kind_geburtsdatum, klasse, fach, schule, kontoinhaber
  ) values (
    v_lead, 'abgeschlossen', 'aktiv', now(), date '2026-10-01', 'vor_ort',
    date '2026-09-24', v_tier, 6, 38990, 24,
    date '2026-10-01', date '2027-04-30', 35, date '2026-10-15',
    'ZZ_Miriam', 'Pdf', 'zz_pdf@edvance.invalid', 'ZZ_Jonas', 'Pdf',
    date '2012-04-08', 8, 'Mathematik', 'ZZ_Schule', 'ZZ_Miriam Pdf'
  ) returning id into v_vertrag;

  insert into vertraege (lead_id, status) values (v_lead2, 'in_vorbereitung')
  returning id into v_offen;

  -- ========================================================================
  -- 1. Nur Admin darf eintragen
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      v_vertrag, 'vertrag', v_vertrag::text || '/vertrag.pdf', v_hash, 1234);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Eintrag ohne Admin moeglich';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  raise notice '1  ok  nur Admin';

  -- ========================================================================
  -- 2. Der Eintrag traegt Pfad, Pruefsumme und Urheber
  -- ========================================================================
  v_datei := public.vertrag_datei_eintragen(
    v_vertrag, 'vertrag', v_vertrag::text || '/vertrag.pdf', upper(v_hash), 6886);
  assert v_datei is not null, 'kein Datensatz zurueckgekommen';
  select sha256 into v_text from vertrag_dateien where id = v_datei;
  -- Gross geliefert, klein gespeichert: ein Hash wird verglichen, nicht gelesen.
  assert v_text = v_hash, 'Pruefsumme nicht kleingeschrieben: ' || v_text;
  select count(*) into v_n from vertrag_dateien
   where id = v_datei and erzeugt_von = v_admin and bytes = 6886;
  assert v_n = 1, 'Urheber oder Groesse fehlen';
  raise notice '2  ok  Pfad, Pruefsumme, Urheber';

  -- ========================================================================
  -- 3. Kein zweites vertrag.pdf zu demselben Vertrag
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      v_vertrag, 'vertrag', v_vertrag::text || '/vertrag-2.pdf', v_hash2, 99);
  exception when unique_violation then v_ok := true; end;
  assert v_ok, 'zweites vertrag.pdf angenommen';
  select count(*) into v_n from vertrag_dateien where vertrag_id = v_vertrag and art = 'vertrag';
  assert v_n = 1, 'mehr als ein vertrag.pdf: ' || v_n;
  raise notice '3  ok  nur ein vertrag.pdf je Vertrag';

  -- ========================================================================
  -- 4. Eine andere Art daneben ist erlaubt
  -- ========================================================================
  perform public.vertrag_datei_eintragen(
    v_vertrag, 'unterschrift', v_vertrag::text || '/unterschrift.png', v_hash2, 412);
  select count(*) into v_n from vertrag_dateien where vertrag_id = v_vertrag;
  assert v_n = 2, 'Unterschrift nicht eingetragen: ' || v_n;
  raise notice '4  ok  Unterschrift als eigene Datei';

  -- ========================================================================
  -- 5. Pfad und Pruefsumme sind Pflicht und muessen stimmen
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      v_vertrag, 'sepa_mandat', v_vertrag::text || '/sepa.pdf', 'kein-hash', 10);
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'unvollstaendige Pruefsumme angenommen';

  -- Ein Pfad, der auf einen fremden Vertrag zeigt, ist kein Beleg.
  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      v_vertrag, 'sepa_mandat', v_offen::text || '/sepa.pdf', v_hash2, 10);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Pfad eines fremden Vertrags angenommen';
  raise notice '5  ok  Pruefsumme und Pfad werden geprueft';

  -- ========================================================================
  -- 6. Vor dem Abschluss gibt es kein Vertragsdokument
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      v_offen, 'vertrag', v_offen::text || '/vertrag.pdf', v_hash, 10);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'PDF zu einem offenen Antrag angenommen';

  v_ok := false;
  begin
    perform public.vertrag_datei_eintragen(
      gen_random_uuid(), 'vertrag', 'irgendwo/vertrag.pdf', v_hash, 10);
  exception when sqlstate 'P0002' then v_ok := true; end;
  assert v_ok, 'PDF zu einem nicht existierenden Vertrag angenommen';
  raise notice '6  ok  nur zu abgeschlossenen Vertraegen';

  -- ========================================================================
  -- 7. Ein Vertrag mit Archiveintrag laesst sich nicht loeschen
  -- ========================================================================
  v_ok := false;
  begin
    delete from vertraege where id = v_vertrag;
  -- restrict_violation (23001), nicht foreign_key_violation (23503): ON DELETE
  -- RESTRICT hat einen eigenen SQLSTATE.
  exception when restrict_violation then v_ok := true; end;
  assert v_ok, 'Vertrag mit Archiveintrag geloescht';
  raise notice '7  ok  Archiv haelt den Vertrag fest';

  -- ========================================================================
  -- 8. Kein direktes Schreiben an der RPC vorbei
  -- ========================================================================
  -- Es gibt keine INSERT-Policy; unter RLS muss der Insert scheitern.
  set local role authenticated;
  v_ok := false;
  begin
    insert into public.vertrag_dateien (vertrag_id, art, pfad, sha256)
    values (v_vertrag, 'sepa_mandat', v_vertrag::text || '/direkt.pdf', v_hash2);
  exception when insufficient_privilege then v_ok := true; end;
  reset role;
  assert v_ok, 'direkter Insert unter RLS moeglich';
  raise notice '8  ok  Schreiben nur ueber die RPC';

  raise notice '';
  raise notice '== Vertrags-PDF: alle Pruefungen bestanden ==';
end $$;

-- Rechte
select 'public.vertrag_datei_eintragen(uuid, text, text, text, integer)' as funktion,
       has_function_privilege('anon',
         'public.vertrag_datei_eintragen(uuid, text, text, text, integer)'::regprocedure::oid,
         'execute') as anon,
       has_function_privilege('authenticated',
         'public.vertrag_datei_eintragen(uuid, text, text, text, integer)'::regprocedure::oid,
         'execute') as authenticated,
       case when not has_function_privilege('anon',
              'public.vertrag_datei_eintragen(uuid, text, text, text, integer)'::regprocedure::oid, 'execute')
             and has_function_privilege('authenticated',
              'public.vertrag_datei_eintragen(uuid, text, text, text, integer)'::regprocedure::oid, 'execute')
            then 'OK' else 'FEHLER' end as ergebnis;

rollback;
