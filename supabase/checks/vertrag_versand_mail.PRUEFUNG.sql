-- PRUEFUNG: Versandprotokoll (Migration 20260928210000).
--
-- Laeuft in begin … rollback, legt die Testdaten selbst an (Praefix ZZ_).
-- Claims MIT Rolle — ohne 'role' gilt der Aufruf als Systemaufruf.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/vertrag_versand_mail.PRUEFUNG.sql
--
-- Signaturen gegen den Schema-Abzug abgeglichen:
--   vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text) -> uuid
--   vertrag_versenden(uuid, text, text, date) -> jsonb

begin;

do $$
declare
  v_admin   uuid;
  v_tier    uuid;
  v_lead    uuid;
  v_lead2   uuid;
  v_lead3   uuid;
  v_vertrag uuid;
  v_vertrag2 uuid;
  v_vertrag3 uuid;
  v_id      uuid;
  v_n       integer;
  v_text    text;
  v_ok      boolean;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  select id into v_tier from tiers where name = 'Premium';

  insert into leads (full_name, status) values ('ZZ_Versand Kind', 'vertrag') returning id into v_lead;
  insert into vertraege (
    lead_id, status, tier_id, laufzeit_monate, preis_cents, einheiten, vertragsbeginn,
    eltern_vorname, eltern_nachname, eltern_email, kind_vorname, kind_nachname, kontoinhaber
  ) values (
    v_lead, 'in_vorbereitung', v_tier, 6, 38990, 24, date '2026-11-01',
    'ZZ_Anna', 'Versand', 'zz_versand@edvance.invalid', 'ZZ_Tim', 'Versand', 'ZZ_Anna Versand'
  ) returning id into v_vertrag;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v_vertrag, 'DE89370400440532013000');

  -- ========================================================================
  -- 1. Nur Admin darf protokollieren
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_versand_protokollieren(v_vertrag, 'email', 'bestaetigung');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Protokoll ohne Admin moeglich';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  raise notice '1  ok  nur Admin';

  -- ========================================================================
  -- 2. Geglueckter Versand: Anhaenge drin, fehler leer
  -- ========================================================================
  v_id := public.vertrag_versand_protokollieren(
    v_vertrag, 'email', 'bestaetigung', 'zz_versand@edvance.invalid',
    '["vertrag.pdf","sepa_mandat.pdf","platzhalter-v1.pdf"]'::jsonb, null);
  select count(*) into v_n from vertrag_versand
   where id = v_id and fehler is null and erfolgt_von = v_admin
     and jsonb_array_length(anhaenge) = 3;
  assert v_n = 1, 'Anhaenge oder Urheber fehlen';
  raise notice '2  ok  Anhaenge und Urheber festgehalten';

  -- ========================================================================
  -- 3. Gescheiterter Versand wird AUCH festgehalten
  -- ========================================================================
  -- Das ist der wichtigere der beiden Faelle: ein Protokoll, das nur die
  -- geglueckten Versuche kennt, beantwortet die Frage nicht, wegen der man
  -- hineinschaut.
  v_id := public.vertrag_versand_protokollieren(
    v_vertrag, 'email', 'bestaetigung', 'zz_versand@edvance.invalid',
    '["vertrag.pdf"]'::jsonb, 'Graph sendMail 403: Zugriff verweigert');
  select fehler into v_text from vertrag_versand where id = v_id;
  assert v_text like 'Graph sendMail 403%', 'Fehlertext nicht gespeichert';
  select count(*) into v_n from vertrag_versand where vertrag_id = v_vertrag;
  assert v_n = 2, 'gescheiterter Versuch nicht als eigene Zeile: ' || v_n;
  raise notice '3  ok  auch der gescheiterte Versuch steht drin';

  -- Leerer Fehlertext ist kein Fehler.
  v_id := public.vertrag_versand_protokollieren(
    v_vertrag, 'email', 'zugangscode', 'zz_versand@edvance.invalid', null, '   ');
  select fehler into v_text from vertrag_versand where id = v_id;
  assert v_text is null, 'Leerstring als Fehler gespeichert';
  raise notice '4  ok  leerer Fehlertext zaehlt als zugestellt';

  -- ========================================================================
  -- 5. Der Zugangscode ist ein erlaubter Anlass
  -- ========================================================================
  select count(*) into v_n from vertrag_versand
   where vertrag_id = v_vertrag and anlass = 'zugangscode';
  assert v_n = 1, 'Anlass zugangscode nicht angekommen';
  v_ok := false;
  begin
    perform public.vertrag_versand_protokollieren(v_vertrag, 'email', 'irgendwas');
  exception when check_violation then v_ok := true; end;
  assert v_ok, 'unbekannter Anlass angenommen';
  raise notice '5  ok  drei Anlaesse, kein vierter';

  -- ========================================================================
  -- 6. vertrag_versenden protokolliert den Mailweg NICHT mehr selbst
  -- ========================================================================
  -- Sonst staende jeder Versand zweimal drin — einmal von der RPC, einmal von
  -- mail_senden, und die Zeile der RPC wuesste nichts von Anhaengen.
  delete from vertrag_versand where vertrag_id = v_vertrag;
  perform public.vertrag_versenden(v_vertrag, 'email', 'zz_versand@edvance.invalid', current_date + 14);
  select count(*) into v_n from vertrag_versand where vertrag_id = v_vertrag;
  assert v_n = 0, 'vertrag_versenden hat den Mailweg protokolliert: ' || v_n;

  select count(*) into v_n from vertrag_zustimmungen where vertrag_id = v_vertrag;
  assert v_n > 0, 'Zustimmungen nicht festgehalten';
  select status into v_text from vertraege where id = v_vertrag;
  assert v_text = 'unterschrift_ausstehend', 'Status nicht gesetzt: ' || v_text;
  raise notice '6  ok  Mailweg ohne Doppeleintrag, Status und Fassungen stehen';

  -- ========================================================================
  -- 7. Der Druckweg protokolliert weiter selbst
  -- ========================================================================
  -- Dort IST das Auslegen der Vorgang; es gibt keine Maschine, die danach
  -- noch etwas zu melden haette.
  -- Zweiter Vertrag statt Status zuruecksetzen: vertraege_guard laesst
  -- Statusaenderungen nur ueber die vertrag_*-RPCs zu, und das ist richtig so.
  insert into leads (full_name, status) values ('ZZ_Druck Kind', 'vertrag') returning id into v_lead2;
  insert into vertraege (
    lead_id, status, tier_id, laufzeit_monate, preis_cents, einheiten, vertragsbeginn,
    eltern_vorname, eltern_nachname, eltern_email, kind_vorname, kind_nachname, kontoinhaber
  ) values (
    v_lead2, 'in_vorbereitung', v_tier, 6, 38990, 24, date '2026-11-01',
    'ZZ_Bea', 'Druck', 'zz_druck@edvance.invalid', 'ZZ_Ben', 'Druck', 'ZZ_Bea Druck'
  ) returning id into v_vertrag2;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v_vertrag2, 'DE89370400440532013000');

  perform public.vertrag_versenden(v_vertrag2, 'druck', null, current_date + 14);
  select count(*) into v_n from vertrag_versand
   where vertrag_id = v_vertrag2 and weg = 'druck' and anlass = 'unterlagen';
  assert v_n = 1, 'Druckweg nicht protokolliert: ' || v_n;
  raise notice '7  ok  Druckweg unveraendert';

  -- ========================================================================
  -- 7b. Der Statuswechsel aus der alten Fassung ist noch da
  -- ========================================================================
  -- Der Druckknopf in VertragPage ruft die RPC direkt; verliert sie den
  -- Wechsel, bliebe der Antrag auf "in_vorbereitung" stehen, obwohl die
  -- Unterlagen draussen sind.
  insert into leads (full_name, status) values ('ZZ_Direkt Kind', 'vertrag') returning id into v_lead3;
  insert into vertraege (lead_id, status) values (v_lead3, 'in_vorbereitung') returning id into v_vertrag3;
  perform public.vertrag_versand_protokollieren(v_vertrag3, 'druck', 'unterlagen');
  select status into v_text from vertraege where id = v_vertrag3;
  assert v_text = 'unterschrift_ausstehend', 'Statuswechsel verloren: ' || v_text;
  raise notice '7b ok  Statuswechsel des Druckwegs erhalten';

  -- ========================================================================
  -- 8. Kein direktes Schreiben an der RPC vorbei
  -- ========================================================================
  set local role authenticated;
  v_ok := false;
  begin
    insert into public.vertrag_versand (vertrag_id, weg, anlass)
    values (v_vertrag, 'email', 'bestaetigung');
  exception when insufficient_privilege then v_ok := true; end;
  reset role;
  assert v_ok, 'direkter Insert unter RLS moeglich';
  raise notice '8  ok  Schreiben nur ueber die RPC';

  raise notice '';
  raise notice '== Versandprotokoll: alle Pruefungen bestanden ==';
end $$;

-- Rechte
select 'public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)' as funktion,
       has_function_privilege('anon',
         'public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)'::regprocedure::oid,
         'execute') as anon,
       has_function_privilege('authenticated',
         'public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)'::regprocedure::oid,
         'execute') as authenticated,
       case when not has_function_privilege('anon',
              'public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)'::regprocedure::oid, 'execute')
             and has_function_privilege('authenticated',
              'public.vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text)'::regprocedure::oid, 'execute')
            then 'OK' else 'FEHLER' end as ergebnis;

rollback;
