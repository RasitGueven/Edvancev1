-- PRUEFUNG: Datenbank hinter dem Menue "Vertraege" (Migration 20260925181700).
--
-- Laeuft komplett in einer Transaktion und rollt am Ende zurueck. Testdaten
-- tragen das Praefix ZZ_. Claims MIT Rolle — ohne 'role' gilt der Aufruf als
-- Systemaufruf und get_my_role() liefert nicht, was man erwartet.
--
--     psql "$DATABASE_URL" -f supabase/checks/vertraege_menue.PRUEFUNG.sql
--
-- Die Vertraege werden direkt eingefuegt statt ueber die Abschlussstrecke: hier
-- wird die ABLEITUNG geprueft, nicht der Weg dorthin. Den prueft
-- vertrag_abschluss.PRUEFUNG.sql.

begin;

-- Ein Vertrag in einem bestimmten Zustand, ohne jedes Mal zwanzig Spalten.
create function pg_temp.mach_vertrag(
  p_name        text,
  p_student     uuid,
  p_tier        uuid,
  p_laufzeit    integer,
  p_beginn      date,
  p_ende        date,
  p_widerruf    date,
  p_status      text,
  p_code        text,
  p_widerrufen  date default null,
  p_gekuendigt  date default null,
  p_vorgaenger  uuid default null
) returns uuid language plpgsql as $f$
declare v_lead uuid; v_id uuid;
begin
  insert into leads (full_name, status) values (p_name, 'vertrag') returning id into v_lead;
  insert into vertraege (
    lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
    unterschrieben_am, student_id, tier_id, laufzeit_monate, preis_cents, einheiten,
    vertragsbeginn, vertrag_ende, widerruf_bis, widerrufen_am, gekuendigt_zum,
    kuendigung_grund, zugangscode, zugangscode_erzeugt_am, vorgaenger_id
  ) values (
    v_lead, 'abgeschlossen', p_status, now(), p_beginn, 'vor_ort',
    p_beginn, p_student, p_tier, p_laufzeit, 38990, 38,
    p_beginn, p_ende, p_widerruf, p_widerrufen, p_gekuendigt,
    case when p_gekuendigt is not null then 'ZZ_Sonderfall' end,
    p_code, p_beginn, p_vorgaenger
  ) returning id into v_id;
  return v_id;
end $f$;

create function pg_temp.kind(p_klasse integer) returns uuid language plpgsql as $f$
declare v uuid;
begin
  insert into students (profile_id, class_level, is_provisional, lead_id)
  values (null, p_klasse, false, null) returning id into v;
  return v;
end $f$;

do $$
declare
  v_admin uuid;
  v_tier  uuid;
  m0      date := date_trunc('month', current_date)::date;
  v_aktiv uuid; v_widerruf uuid; v_alt uuid; v_gek uuid; v_wr uuid;
  v_brueckeAlt uuid; v_brueckeNeu uuid;
  k1 uuid; k2 uuid; k3 uuid; k4 uuid; k5 uuid; k6 uuid;
  v_text text; v_n integer; v_b integer; v_ok boolean; v_code text; v_vorher integer;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden — Pruefung braucht eines';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  select id into v_tier from tiers where name = 'Premium';

  k1 := pg_temp.kind(8); k2 := pg_temp.kind(9);  k3 := pg_temp.kind(10);
  k4 := pg_temp.kind(8); k5 := pg_temp.kind(9);  k6 := pg_temp.kind(10);

  -- Halbjahr, im 8. Laufzeitmonat: laeuft noch, kostet aber nichts mehr.
  v_aktiv := pg_temp.mach_vertrag('ZZ_Aktiv', k1, v_tier, 6,
    (m0 - interval '7 months')::date, current_date + 30, (m0 - interval '7 months')::date + 29,
    'aktiv', 'EDV-AAAA-AAA2');
  -- Erster Monat, Frist laeuft noch.
  v_widerruf := pg_temp.mach_vertrag('ZZ_ImWiderruf', k2, v_tier, 12,
    m0, current_date + 300, current_date + 10, 'im_widerruf', 'EDV-BBBB-BBB3');
  v_alt := pg_temp.mach_vertrag('ZZ_Ausgelaufen', k3, v_tier, 6,
    (m0 - interval '9 months')::date, current_date - 5, (m0 - interval '9 months')::date + 29,
    'aktiv', 'EDV-CCCC-CCC4');
  v_gek := pg_temp.mach_vertrag('ZZ_Gekuendigt', k4, v_tier, 12,
    (m0 - interval '3 months')::date, current_date + 100, (m0 - interval '3 months')::date + 29,
    'aktiv', 'EDV-DDDD-DDD5', null, current_date - 1);
  v_wr := pg_temp.mach_vertrag('ZZ_Widerrufen', k5, v_tier, 12,
    m0, current_date + 300, current_date + 10, 'im_widerruf', 'EDV-EEEE-EEE6', current_date - 1);

  -- ========================================================================
  -- 1. wirksamer_status in allen fuenf Zustaenden
  -- ========================================================================
  select string_agg(a.wirksamer_status, '|' order by a.id::text) into v_text
    from vertraege_aktuell a where a.id = v_aktiv;
  assert v_text = 'aktiv', 'aktiv: ' || coalesce(v_text, 'null');
  select wirksamer_status into v_text from vertraege_aktuell where id = v_widerruf;
  assert v_text = 'im_widerruf', 'im_widerruf: ' || coalesce(v_text, 'null');
  select wirksamer_status into v_text from vertraege_aktuell where id = v_alt;
  assert v_text = 'ausgelaufen', 'ausgelaufen: ' || coalesce(v_text, 'null');
  select wirksamer_status into v_text from vertraege_aktuell where id = v_gek;
  assert v_text = 'gekuendigt', 'gekuendigt: ' || coalesce(v_text, 'null');
  select wirksamer_status into v_text from vertraege_aktuell where id = v_wr;
  assert v_text = 'widerrufen', 'widerrufen: ' || coalesce(v_text, 'null');
  raise notice '1  ok  wirksamer_status in allen fuenf Zustaenden';

  -- Vorrang: ein widerrufener Vertrag bleibt widerrufen, auch wenn sein Ende
  -- laengst vorbei waere.
  assert public.vertrag_wirksamer_status(current_date - 400, null, current_date - 300,
                                         current_date - 380) = 'widerrufen',
    'Widerruf schlaegt Auslaufen nicht';
  assert public.vertrag_wirksamer_status(null, current_date - 1, current_date - 1,
                                         current_date + 5) = 'gekuendigt',
    'Kuendigung schlaegt Auslaufen nicht';
  raise notice '2  ok  Vorrangregel';

  -- ========================================================================
  -- 3. Halbjahr im 8. Monat: aktiv, aber beitragsfrei
  -- ========================================================================
  select laufzeit_monat, beitrag_diesen_monat_cents into v_n, v_b
    from vertraege_aktuell where id = v_aktiv;
  assert v_n = 8, 'Laufzeitmonat: ' || coalesce(v_n::text, 'null');
  assert v_b = 0, 'Halbjahr im 8. Monat kostet noch: ' || coalesce(v_b::text, 'null');
  select beitrag_diesen_monat_cents into v_b from vertraege_aktuell where id = v_widerruf;
  assert v_b = 38990, 'Erster Monat kostet nicht: ' || coalesce(v_b::text, 'null');
  raise notice '3  ok  beitrag_diesen_monat_cents: 8. Monat 0, erster Monat voll';

  -- ========================================================================
  -- 4. hat_zugang
  -- ========================================================================
  assert public.hat_zugang(k1), 'aktives Kind hat keinen Zugang';
  assert not public.hat_zugang(k3), 'ausgelaufen ohne Folgevertrag hat Zugang';

  -- Bruecke: alter Vertrag vorbei, Folgevertrag unterschrieben, Beginn spaeter.
  v_brueckeAlt := pg_temp.mach_vertrag('ZZ_BrueckeAlt', k6, v_tier, 6,
    (m0 - interval '9 months')::date, current_date - 5,
    (m0 - interval '9 months')::date + 29, 'ausgelaufen', 'EDV-FFFF-FFF7');
  v_brueckeNeu := pg_temp.mach_vertrag('ZZ_BrueckeNeu', k6, v_tier, 12,
    (m0 + interval '2 months')::date, current_date + 400,
    (m0 + interval '2 months')::date + 29, 'im_widerruf', 'EDV-GGGG-GGG8',
    null, null, v_brueckeAlt);
  assert public.hat_zugang(k6), 'Bruecke zum Folgevertrag traegt nicht';
  assert not public.hat_zugang(k6, current_date + 500),
    'Zugang gilt auch noch nach dem Ende des Folgevertrags';
  raise notice '4  ok  hat_zugang inklusive Bruecke (Entscheidung 11)';

  -- ========================================================================
  -- 5. Widerruf
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_widerruf_erfassen(v_widerruf, current_date + 11);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Widerruf nach Fristende war moeglich';

  perform public.vertrag_widerruf_erfassen(v_widerruf, current_date);
  select (widerrufen_am is not null)::text || '|' || (zugangscode_gesperrt_am is not null)::text
    into v_text from vertraege where id = v_widerruf;
  assert v_text = 'true|true', 'Widerruf unvollstaendig: ' || v_text;
  select wirksamer_status || '|' || zugangscode_gueltig::text into v_text
    from vertraege_aktuell where id = v_widerruf;
  assert v_text = 'widerrufen|false', 'nach Widerruf: ' || v_text;
  raise notice '5  ok  Widerruf nur in der Frist, danach Code gesperrt';

  -- ========================================================================
  -- 6. Zahlungsstatus: eine Stufe, nicht zwei
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_zahlungsstatus_setzen(v_aktiv, 'mahnung_2', 38990);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Sprung von in_ordnung auf mahnung_2 war moeglich';

  perform public.vertrag_zahlungsstatus_setzen(v_aktiv, 'zahlung_offen', 38990);
  perform public.vertrag_zahlungsstatus_setzen(v_aktiv, 'mahnung_1', 38990);
  perform public.vertrag_zahlungsstatus_setzen(v_aktiv, 'mahnung_2', 38990);
  select zahlungsstatus || '|' || zahlungsstatus_seit || '|' || offener_betrag_cents
    into v_text from vertraege where id = v_aktiv;
  assert v_text = 'mahnung_2|' || current_date || '|38990', 'Mahnstufe: ' || v_text;

  perform public.vertrag_zahlungsstatus_setzen(v_aktiv, 'in_ordnung');
  select zahlungsstatus || '|' || coalesce(offener_betrag_cents::text, 'null')
    into v_text from vertraege where id = v_aktiv;
  assert v_text = 'in_ordnung|null', 'Rueckweg: ' || v_text;
  raise notice '6  ok  Zahlungsstatus stufenweise, Rueckweg jederzeit';

  -- ========================================================================
  -- 7. Verlaengerung
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_verlaengerung_setzen(v_aktiv, 'keine_verlaengerung');
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'keine_verlaengerung ohne Grund war moeglich';

  v_ok := false;
  begin
    perform public.vertrag_verlaengerung_setzen(v_aktiv, 'verlaengert');
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'verlaengert liess sich von Hand setzen';

  perform public.vertrag_verlaengerung_setzen(v_aktiv, 'kontaktiert', null, current_date + 7);
  select verlaengerung_status || '|' || wiedervorlage_am into v_text
    from vertraege where id = v_aktiv;
  assert v_text = 'kontaktiert|' || (current_date + 7), 'Verlaengerung: ' || v_text;
  raise notice '7  ok  Verlaengerung mit Grundpflicht, verlaengert nur aus dem Abschluss';

  -- ========================================================================
  -- 8. Zugangscode neu — nur solange er gilt
  -- ========================================================================
  v_code := public.vertrag_zugangscode_neu(v_aktiv);
  assert v_code ~ '^EDV-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$',
    'Neuer Code hat die falsche Form: ' || coalesce(v_code, 'null');
  assert v_code <> 'EDV-AAAA-AAA2', 'Der Code wurde nicht ersetzt';

  v_ok := false;
  begin
    perform public.vertrag_zugangscode_neu(v_widerruf);   -- widerrufen
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Code eines widerrufenen Vertrags liess sich neu erzeugen';
  raise notice '8  ok  Zugangscode nur fuer einen gueltigen Zugang neu';

  -- ========================================================================
  -- 9. Sonderkuendigung
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_sonderkuendigung_erfassen(v_aktiv, current_date + 30, '  ');
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Kuendigung ohne Grund war moeglich';

  perform public.vertrag_sonderkuendigung_erfassen(v_aktiv, current_date - 2, 'ZZ_Umzug');
  select wirksamer_status into v_text from vertraege_aktuell where id = v_aktiv;
  assert v_text = 'gekuendigt', 'nach Kuendigung: ' || v_text;
  raise notice '9  ok  Sonderkuendigung mit Grundpflicht';

  -- ========================================================================
  -- 10. IBAN anzeigen schreibt genau einen Protokolleintrag
  -- ========================================================================
  insert into vertrag_bankdaten (vertrag_id, iban) values (v_alt, 'DE89370400440532013000');
  select count(*) into v_vorher from audit_log where objekt_id = v_alt;
  v_text := public.vertrag_iban_anzeigen(v_alt);
  assert v_text = 'DE89370400440532013000', 'IBAN falsch: ' || coalesce(v_text, 'null');
  select count(*) into v_n from audit_log
   where objekt_id = v_alt and aktion = 'iban_angezeigt' and objekt_typ = 'vertrag'
     and actor = v_admin;
  assert v_n = v_vorher + 1, 'Protokolleintraege: ' || v_n;
  raise notice '10 ok  vertrag_iban_anzeigen protokolliert den Zugriff';

  -- ========================================================================
  -- 11. ist_aktueller_vertrag
  -- ========================================================================
  select string_agg(ist_aktueller_vertrag::text, '|' order by vertragsbeginn) into v_text
    from vertraege_aktuell where student_id = k6;
  assert v_text = 'false|true', 'aktueller Vertrag je Kind: ' || coalesce(v_text, 'null');
  raise notice '11 ok  ist_aktueller_vertrag zeigt auf den juengsten';

  -- ========================================================================
  -- 12. Nur Admin
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_widerruf_erfassen(v_alt, current_date);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'vertrag_widerruf_erfassen ohne Admin moeglich';
  v_ok := false;
  begin
    perform public.vertrag_iban_anzeigen(v_alt);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'vertrag_iban_anzeigen ohne Admin moeglich';
  raise notice '12 ok  RPCs nur fuer Admin';

  raise notice '';
  raise notice '== Menue Vertraege: alle Pruefungen bestanden ==';
end $$;

-- ============================================================================
-- 13. Rechte: anon darf keine der neuen Funktionen, authenticated schon
-- ============================================================================
select f.sig as funktion,
       has_function_privilege('anon',          f.sig::regprocedure::oid, 'execute') as anon,
       has_function_privilege('authenticated', f.sig::regprocedure::oid, 'execute') as authenticated,
       case when not has_function_privilege('anon', f.sig::regprocedure::oid, 'execute')
             and has_function_privilege('authenticated', f.sig::regprocedure::oid, 'execute')
            then 'OK' else 'FEHLER' end as ergebnis
  from (values
    ('public.hat_zugang(uuid,date)'),
    ('public.vertrag_wirksamer_status(date,date,date,date,date)'),
    ('public.vertrag_widerruf_erfassen(uuid,date)'),
    ('public.vertrag_sonderkuendigung_erfassen(uuid,date,text)'),
    ('public.vertrag_zahlungsstatus_setzen(uuid,text,integer)'),
    ('public.vertrag_verlaengerung_setzen(uuid,text,text,date)'),
    ('public.vertrag_zugangscode_neu(uuid)'),
    ('public.vertrag_iban_anzeigen(uuid)')
  ) as f(sig)
 order by f.sig;

rollback;
