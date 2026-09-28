-- PRUEFUNG: Dokumentfassungen (Migration 20260928190000).
--
-- Laeuft in begin … rollback. Claims MIT Rolle — ohne 'role' gilt der Aufruf
-- als Systemaufruf.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/dokument_fassungen.PRUEFUNG.sql
--
-- Signatur gegen den Schema-Abzug abgeglichen:
--   dokument_fassung_eintragen(text, text, text, text, integer) -> void

begin;

do $$
declare
  v_admin   uuid;
  v_fassung text;
  v_hash    text := repeat('c', 64);
  v_hash2   text := repeat('d', 64);
  v_n       integer;
  v_text    text;
  v_ok      boolean;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select version into v_fassung from vertrag_dokumente where schluessel = 'agb' limit 1;
  assert v_fassung is not null, 'Keine AGB-Fassung im Katalog';

  -- ========================================================================
  -- 1. Nur Admin darf eintragen
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.dokument_fassung_eintragen(
      'agb', v_fassung, 'fassungen/agb/' || v_fassung || '.pdf', v_hash, 100);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Eintrag ohne Admin moeglich';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  raise notice '1  ok  nur Admin';

  -- ========================================================================
  -- 2. Eintrag mit Pfad, Pruefsumme und Urheber
  -- ========================================================================
  perform public.dokument_fassung_eintragen(
    'agb', v_fassung, 'fassungen/agb/' || v_fassung || '.pdf', upper(v_hash), 1234);
  select sha256 into v_text from dokument_fassungen where art = 'agb' and fassung = v_fassung;
  -- Gross geliefert, klein gespeichert: ein Hash wird verglichen, nicht gelesen.
  assert v_text = v_hash, 'Pruefsumme nicht kleingeschrieben: ' || v_text;
  select count(*) into v_n from dokument_fassungen
   where art = 'agb' and fassung = v_fassung and erzeugt_von = v_admin and bytes = 1234;
  assert v_n = 1, 'Urheber oder Groesse fehlen';
  raise notice '2  ok  Pfad, Pruefsumme, Urheber';

  -- ========================================================================
  -- 3. Zweiter Aufruf aendert nichts — einmal erzeugt, bleibt es
  -- ========================================================================
  perform public.dokument_fassung_eintragen(
    'agb', v_fassung, 'fassungen/agb/' || v_fassung || '.pdf', v_hash2, 9999);
  select sha256 into v_text from dokument_fassungen where art = 'agb' and fassung = v_fassung;
  assert v_text = v_hash, 'zweiter Aufruf hat die Pruefsumme ueberschrieben';
  select count(*) into v_n from dokument_fassungen where art = 'agb';
  assert v_n = 1, 'zweite Zeile fuer dieselbe Fassung: ' || v_n;
  raise notice '3  ok  idempotent, ueberschreibt nicht';

  -- ========================================================================
  -- 4. Der Pfad ist vorgeschrieben
  -- ========================================================================
  v_ok := false;
  begin
    perform public.dokument_fassung_eintragen(
      'widerruf', v_fassung, 'irgendwo/anders.pdf', v_hash2, 10);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'freier Pfad angenommen';
  raise notice '4  ok  Pfad ist vorgeschrieben';

  -- ========================================================================
  -- 5. Nur Fassungen, die im Katalog stehen
  -- ========================================================================
  v_ok := false;
  begin
    perform public.dokument_fassung_eintragen(
      'agb', 'gibt-es-nicht', 'fassungen/agb/gibt-es-nicht.pdf', v_hash2, 10);
  exception when sqlstate 'P0002' then v_ok := true; end;
  assert v_ok, 'Fassung ohne Katalogeintrag angenommen';

  -- Vertrag und SEPA-Mandat gehoeren hier nicht her: die tragen Werte und
  -- liegen je Vertrag in vertrag_dateien.
  v_ok := false;
  begin
    perform public.dokument_fassung_eintragen(
      'vertrag', v_fassung, 'fassungen/vertrag/' || v_fassung || '.pdf', v_hash2, 10);
  exception when check_violation then v_ok := true;
             when sqlstate 'P0002' then v_ok := true; end;
  assert v_ok, 'Vertrag als Fassung angenommen';
  raise notice '5  ok  nur vertragsfreie Arten aus dem Katalog';

  -- ========================================================================
  -- 6. Pruefsumme muss vollstaendig sein
  -- ========================================================================
  v_ok := false;
  begin
    perform public.dokument_fassung_eintragen(
      'widerruf', v_fassung, 'fassungen/widerruf/' || v_fassung || '.pdf', 'kurz', 10);
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'unvollstaendige Pruefsumme angenommen';
  raise notice '6  ok  Pruefsumme wird geprueft';

  -- ========================================================================
  -- 7. Lesen darf jede angemeldete Person, schreiben nur die RPC
  -- ========================================================================
  set local role authenticated;
  v_ok := false;
  begin
    insert into public.dokument_fassungen (art, fassung, pfad, sha256)
    values ('widerruf', v_fassung, 'fassungen/widerruf/direkt.pdf', v_hash2);
  exception when insufficient_privilege then v_ok := true; end;
  reset role;
  assert v_ok, 'direkter Insert unter RLS moeglich';
  raise notice '7  ok  Schreiben nur ueber die RPC';

  raise notice '';
  raise notice '== Dokumentfassungen: alle Pruefungen bestanden ==';
end $$;

-- Rechte
select 'public.dokument_fassung_eintragen(text, text, text, text, integer)' as funktion,
       has_function_privilege('anon',
         'public.dokument_fassung_eintragen(text, text, text, text, integer)'::regprocedure::oid,
         'execute') as anon,
       has_function_privilege('authenticated',
         'public.dokument_fassung_eintragen(text, text, text, text, integer)'::regprocedure::oid,
         'execute') as authenticated,
       case when not has_function_privilege('anon',
              'public.dokument_fassung_eintragen(text, text, text, text, integer)'::regprocedure::oid, 'execute')
             and has_function_privilege('authenticated',
              'public.dokument_fassung_eintragen(text, text, text, text, integer)'::regprocedure::oid, 'execute')
            then 'OK' else 'FEHLER' end as ergebnis;

rollback;
