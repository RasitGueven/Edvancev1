-- PRUEFUNG: Abschlussstrecke (Migration 20260925140000).
--
-- Laeuft komplett in einer Transaktion und rollt am Ende zurueck. Testdaten
-- tragen das Praefix ZZ_. Claims MIT Rolle — ohne 'role' gilt der Aufruf als
-- Systemaufruf und get_my_role() liefert nicht, was man erwartet.
--
-- Gegen Produktion ausfuehren, nachdem die Migration eingespielt ist:
--     psql "$DATABASE_URL" -f supabase/checks/vertrag_abschluss.PRUEFUNG.sql
--
-- Diese Datei deckt die Abnahmefaelle 1-8 aus
-- docs/vertraege/Anforderung-Vertragsabschluss.md ab, mit den Abweichungen aus
-- docs/vertraege/entscheidungen.md (Widerruf = Beginn + 29 Tage).
--
-- Die Oberflaeche prueft sie NICHT. Was hier gruen ist, ist die Mechanik
-- darunter: Gates, Berechnung, Kontouebernahme, Vorgaengerkette.

begin;

do $$
declare
  v_admin    uuid;
  v_kind1    uuid := gen_random_uuid();
  v_kind2    uuid := gen_random_uuid();
  v_lead1    uuid;
  v_lead2    uuid;
  v_lead3    uuid;
  v1         uuid;
  v2         uuid;
  v3         uuid;
  v_prov     uuid;       -- provisorischer Schueler aus der LSA
  v_session  uuid;
  v_premium  uuid;
  v_basic    uuid;
  v_alle     jsonb;
  v_ergebnis jsonb;
  v_text     text;
  v_n        integer;
  v_d        date;
  v_ok       boolean;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden — Pruefung braucht eines';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select id into v_premium from tiers where name = 'Premium';
  select id into v_basic   from tiers where name = 'Basic';

  -- Auth-Konten. Im Betrieb legt sie die Edge Function an; hier von Hand.
  insert into auth.users (id, email, instance_id, aud, role) values
    (v_kind1, 'zz_kind1@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_kind2, 'zz_kind2@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  -- ==========================================================================
  -- 1. Antrag aus dem Lead, mit provisorischem Schueler und LSA-Spur
  -- ==========================================================================
  insert into leads (full_name, first_name, status, contact_email, contact_phone,
                     class_level, subjects, consent_dsgvo_at)
  values ('ZZ_Erst Kind', 'ZZ_Erst', 'lsa_fertig', 'zz_eltern1@edvance.invalid',
          '0221 111111', 8, array['Mathematik'], now())
  returning id into v_lead1;

  -- So legt lead_lsa_freigeben den provisorischen Schueler an.
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (profile_id, class_level, is_provisional, lead_id)
  values (null, 8, true, v_lead1) returning id into v_prov;
  perform set_config('edvance.allow_provisional', '', true);

  insert into lsa_sessions (student_id, subject, grade, status)
  values (v_prov, 'Mathematik', 8, 'completed') returning id into v_session;

  v1 := public.vertrag_starten(v_lead1);
  assert v1 is not null, 'vertrag_starten liefert keine ID';
  select status into v_text from leads where id = v_lead1;
  assert v_text = 'vertrag', 'Lead verlaesst das Board nicht: ' || v_text;
  raise notice '1  ok  Antrag angelegt, Lead vom Board';

  -- ==========================================================================
  -- 2. Abnahmefall 1: Halbjahr ab 01.11.2027
  -- ==========================================================================
  update vertraege
     set tier_id = v_premium, laufzeit_monate = 6, vertragsbeginn = date '2027-11-01',
         eltern_vorname = 'ZZ_Anna', eltern_nachname = 'Kind',
         strasse = 'Teststr', hausnummer = '1', plz = '50667', ort = 'Koeln',
         eltern_telefon = '0221 111111', eltern_email = 'zz_eltern1@edvance.invalid',
         kind_vorname = 'ZZ_Erst', kind_nachname = 'Kind',
         kind_geburtsdatum = date '2012-05-04', klasse = 8, fach = 'Mathematik'
   where id = v1;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v1, 'DE89370400440532013000');

  select preis_cents into v_n from vertraege where id = v1;
  assert v_n = 38990, 'Premium Halbjahr ist nicht 389,90 EUR: ' || v_n;
  raise notice '2  ok  Premium Halbjahr 389,90 EUR aus tier_laufzeiten';

  -- Abnahmefall 4: ohne Zustimmungen kein Abschluss.
  v_ok := false;
  begin
    perform public.vertrag_abschliessen(v1, 'vor_ort', '[]'::jsonb, 'data:a', 'data:b',
                                        p_student_uid => v_kind1);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Abnahmefall 4: Abschluss ohne Zustimmungen war moeglich';

  -- ... und ohne Unterschrift auch nicht.
  select jsonb_agg(jsonb_build_object('schluessel', schluessel, 'version', version,
                                      'akzeptiert_at', now()))
    into v_alle from vertrag_dokumente where aktiv and pflicht;
  v_ok := false;
  begin
    perform public.vertrag_abschliessen(v1, 'vor_ort', v_alle, null, null,
                                        p_student_uid => v_kind1);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Abnahmefall 4: Abschluss ohne Unterschrift war moeglich';
  raise notice '4  ok  Abnahmefall 4: Gate vor dem Abschluss';

  -- Abnahmefall 5: vor Ort abschliessen.
  v_ergebnis := public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                            p_student_uid => v_kind1);

  select status || '|' || vertrag_status || '|' || vertrag_ende || '|' || ferientage
         || '|' || widerruf_bis
    into v_text from vertraege where id = v1;
  assert v_text = 'abgeschlossen|im_widerruf|2028-06-15|35|2027-11-30',
    'Abnahmefall 1/5 falsch: ' || coalesce(v_text, 'null');
  raise notice '5  ok  Abnahmefall 1: Ende 15.06.2028, 35 Ferientage, Widerruf bis 30.11.2027';

  -- Zugangscode: Form und Zeitpunkt.
  select zugangscode into v_text from vertraege where id = v1;
  assert v_text ~ '^EDV-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$',
    'Zugangscode hat die falsche Form: ' || coalesce(v_text, 'null');
  select zugangscode_erzeugt_am into v_d from vertraege where id = v1;
  assert v_d is not null, 'Zugangscode ohne Erzeugungsdatum';
  raise notice '6  ok  Abnahmefall 5: Zugangscode erzeugt (' || v_text || ')';

  -- ==========================================================================
  -- 3. Das Konto haengt am PROVISORISCHEN Schueler, nicht an einem zweiten
  -- ==========================================================================
  select student_id into v_text from vertraege where id = v1;
  assert v_text::uuid = v_prov,
    'Der Vertrag zeigt nicht auf den Schueler aus der LSA';
  select count(*) into v_n from students where profile_id = v_kind1;
  assert v_n = 1, 'Es gibt ' || v_n || ' Schuelerzeilen statt einer';
  select (is_provisional::text) || '|' || (lead_id is null)::text
    into v_text from students where id = v_prov;
  assert v_text = 'false|true', 'Schueler nicht geflippt: ' || v_text;
  select count(*) into v_n from lsa_sessions where student_id = v_prov and id = v_session;
  assert v_n = 1, 'Die LSA-Sitzung haengt nicht mehr am Schueler';
  raise notice '7  ok  Provisorischer Schueler uebernommen, LSA-Historie bleibt';

  select count(*) into v_n from student_subscriptions
   where student_id = v_prov and tier_id = v_premium and status = 'active';
  assert v_n = 1, 'Abo nicht angelegt: ' || v_n;
  select status into v_text from leads where id = v_lead1;
  assert v_text = 'converted', 'Lead nicht converted: ' || v_text;
  raise notice '8  ok  Abo angelegt, Lead converted';

  -- Idempotenz: ein zweiter Aufruf aendert nichts.
  v_ergebnis := public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                            p_student_uid => v_kind1);
  assert (v_ergebnis ->> 'bereits_abgeschlossen')::boolean,
    'Zweiter Abschluss meldet sich nicht als idempotent';
  select count(*) into v_n from student_subscriptions where student_id = v_prov;
  assert v_n = 1, 'Zweiter Abschluss hat ein zweites Abo angelegt';
  raise notice '9  ok  Abschluss idempotent';

  -- ==========================================================================
  -- 4. Abnahmefall 6: Papierweg erzeugt KEINEN Vertrag
  -- ==========================================================================
  insert into leads (full_name, first_name, status, contact_email, class_level,
                     subjects, consent_dsgvo_at)
  values ('ZZ_Zweit Kind', 'ZZ_Zweit', 'lsa_fertig', 'zz_eltern2@edvance.invalid',
          9, array['Mathematik'], now())
  returning id into v_lead2;
  v2 := public.vertrag_starten(v_lead2);

  update vertraege
     set tier_id = v_premium, laufzeit_monate = 6, vertragsbeginn = date '2027-11-01',
         eltern_vorname = 'ZZ_Bea', eltern_nachname = 'Kind',
         strasse = 'Teststr', hausnummer = '2', plz = '50667', ort = 'Koeln',
         eltern_telefon = '0221 222222', eltern_email = 'zz_eltern2@edvance.invalid',
         kind_vorname = 'ZZ_Zweit', kind_nachname = 'Kind',
         kind_geburtsdatum = date '2011-03-03', klasse = 9, fach = 'Mathematik'
   where id = v2;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v2, 'DE89370400440532013000');

  v_ergebnis := public.vertrag_versenden(v2, 'email', 'zz_eltern2@edvance.invalid');
  select status into v_text from vertraege where id = v2;
  assert v_text = 'unterschrift_ausstehend', 'Status nach Versand: ' || v_text;
  select vertrag_status into v_text from vertraege where id = v2;
  assert v_text is null, 'Der Papierweg hat einen Vertrag erzeugt';
  select zugangscode into v_text from vertraege where id = v2;
  assert v_text is null, 'Der Papierweg hat einen Zugangscode erzeugt';
  select rueckmeldung_bis into v_d from vertraege where id = v2;
  assert v_d = (now() at time zone 'Europe/Berlin')::date + 14,
    'Rueckmeldefrist nicht heute+14: ' || coalesce(v_d::text, 'null');
  select count(*) into v_n from vertrag_zustimmungen where vertrag_id = v2;
  assert v_n = (select count(*) from vertrag_dokumente where aktiv),
    'Nicht alle Fassungen festgehalten: ' || v_n;
  raise notice '10 ok  Abnahmefall 6: versendet, kein Vertrag, Fassungen festgehalten';

  -- ==========================================================================
  -- 5. Abnahmefaelle 7 und 8: Einpflegen
  -- ==========================================================================
  -- Abnahmefall 8: ohne Scan kein Abschluss.
  v_ok := false;
  begin
    perform public.vertrag_abschliessen(
      v2, 'papier',
      p_unterschrieben_am => date '2027-10-20',
      p_eingang_datum     => date '2027-10-25',
      p_student_uid       => v_kind2);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Abnahmefall 8: Abschluss ohne Scan war moeglich';
  raise notice '11 ok  Abnahmefall 8: ohne Scan kein Abschluss';

  -- Abnahmefall 7: abweichendes Paket ohne Vermerk wird abgewiesen.
  v_ok := false;
  begin
    perform public.vertrag_abschliessen(
      v2, 'papier',
      p_unterschrieben_am => date '2027-10-20',
      p_eingang_datum     => date '2027-10-25',
      p_scan_pfad         => v2::text || '/ruecklauf.pdf',
      p_tier_id           => v_basic,
      p_student_uid       => v_kind2);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Abnahmefall 7: Abweichung ohne Vermerk war moeglich';

  -- ... mit Vermerk gilt das Papier.
  v_ergebnis := public.vertrag_abschliessen(
    v2, 'papier',
    p_unterschrieben_am  => date '2027-10-20',
    p_eingang_datum      => date '2027-10-25',
    p_scan_pfad          => v2::text || '/ruecklauf.pdf',
    p_abweichung_vermerk => 'ZZ_Eltern haben auf Basic geaendert',
    p_tier_id            => v_basic,
    p_student_uid        => v_kind2);

  select (tier_id = v_basic)::text || '|' || preis_cents || '|' || einheiten
         || '|' || unterschrieben_am || '|' || eingang_datum || '|' || abschluss_weg
    into v_text from vertraege where id = v2;
  assert v_text = 'true|21990|19|2027-10-20|2027-10-25|papier',
    'Abnahmefall 7: Papierwerte gelten nicht: ' || coalesce(v_text, 'null');
  select vertrag_ende || '|' || ferientage into v_text from vertraege where id = v2;
  assert v_text = '2028-06-15|35', 'Ende aus dem Papier-Beginn falsch: ' || v_text;
  raise notice '12 ok  Abnahmefall 7: Vermerk erzwungen, es gilt das Papier';

  -- ==========================================================================
  -- 6. Folgevertrag: Vorgaengerkette und Verlaengerung
  -- ==========================================================================
  insert into leads (full_name, first_name, status, contact_email, class_level,
                     subjects, consent_dsgvo_at)
  values ('ZZ_Erst Kind Folge', 'ZZ_Erst', 'lsa_fertig', 'zz_eltern1@edvance.invalid',
          9, array['Mathematik'], now())
  returning id into v_lead3;
  v3 := public.vertrag_starten(v_lead3);

  update vertraege
     set tier_id = v_premium, laufzeit_monate = 12, vertragsbeginn = date '2028-07-01',
         student_id = v_prov,
         eltern_vorname = 'ZZ_Anna', eltern_nachname = 'Kind',
         strasse = 'Teststr', hausnummer = '1', plz = '50667', ort = 'Koeln',
         eltern_telefon = '0221 111111', eltern_email = 'zz_eltern1@edvance.invalid',
         kind_vorname = 'ZZ_Erst', kind_nachname = 'Kind',
         kind_geburtsdatum = date '2012-05-04', klasse = 9, fach = 'Mathematik'
   where id = v3;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v3, 'DE89370400440532013000');

  v_ergebnis := public.vertrag_abschliessen(v3, 'vor_ort', v_alle, 'data:a', 'data:b');

  select vorgaenger_id into v_text from vertraege where id = v3;
  assert v_text::uuid = v1, 'Vorgaenger nicht gesetzt: ' || coalesce(v_text, 'null');
  select verlaengerung_status into v_text from vertraege where id = v1;
  assert v_text = 'verlaengert', 'Vorgaenger nicht als verlaengert markiert: '
    || coalesce(v_text, 'null');
  select count(*) into v_n from vertraege where id = v1 and vertrag_status = 'im_widerruf';
  assert v_n = 1, 'Der alte Vertrag ist verschwunden statt stehen zu bleiben';
  select vertrag_ende into v_d from vertraege where id = v3;
  assert v_d = date '2029-06-30', 'Jahresvertrag-Ende falsch: ' || v_d;
  raise notice '13 ok  Folgevertrag: Vorgaenger verlaengert und erhalten, Jahresende 30.06.2029';

  -- ==========================================================================
  -- 7. Rechte
  -- ==========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_versenden(v2, 'druck');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'vertrag_versenden ohne Admin moeglich';

  v_ok := false;
  begin
    perform public.vertrag_abschliessen(v2, 'vor_ort', v_alle, 'data:a', 'data:b');
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'vertrag_abschliessen ohne Admin moeglich';
  raise notice '14 ok  Beide RPCs nur fuer Admin';

  raise notice '';
  raise notice '== Abschlussstrecke: alle Pruefungen bestanden ==';
end $$;

rollback;
