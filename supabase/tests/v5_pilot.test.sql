-- ============================================================================
-- V5 — Pilotvereinbarung als zweite Vertragsart (Entscheidungen Rasit 14.10.2026).
--
--   1) Vorschlag: Ende = letzter Schultag vor den Sommerferien, Einheiten = Schulwochen; nur Admin.
--   2) Pilot anlegen: vertrag_starten(…, 'pilot'), Guard hält Tarif leer und Preis 0, Einheiten frei.
--   3) Regeln: Preis ≠ 0, Paket gesetzt, Ende in den Ferien, Einheiten 0 → Fehler.
--   4) Abschluss vor Ort: ohne SEPA, Status 'aktiv', kein Widerruf, Schülerkonto + Zugangscode, kein Abo.
--   5) Abschluss Papier: Versand ohne IBAN, Bündel ohne SEPA/Widerruf/AGB, Abschluss mit Scan.
--   6) Status und Kennzahlen: vertraege_aktuell 'aktiv', Beitrag 0, nach dem Ende 'ausgelaufen'; kein Verzug.
--   7) Slots ohne Sonderfall: slots_vertrag_am im Zeitraum ja, danach nein; Stammplatz vergeben geht.
--   8) Folgevertrag aus dem Pilot ist 'regulaer'.
--   9) Regulärer Abschluss unverändert: SEPA-Unterschrift und reguläres Bündel bleiben Pflicht.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2027-11-01 08:00 Europe/Berlin'''

\set kind_vo  'eeeeeeee-5500-4000-8000-000000000001'
\set kind_pa  'eeeeeeee-5500-4000-8000-000000000002'
\set kind_reg 'eeeeeeee-5500-4000-8000-000000000003'
insert into auth.users (id, email, instance_id, aud, role)
select u, 'v5-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'kind_vo'::uuid, 'vo'), (:'kind_pa', 'pa'), (:'kind_reg', 'reg')) v(u, n);

create or replace function pg_temp.lead(p_name text) returns uuid language sql as $$
  insert into public.leads (full_name, first_name, status, class_level, subjects, contact_email, consent_dsgvo_at)
  values (p_name, split_part(p_name, ' ', 1), 'lsa_fertig', 8, array['Mathematik'], 'v5-eltern@test.local', now())
  returning id
$$;
create or replace function pg_temp.zust(variadic p text[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('schluessel', d.schluessel, 'version', d.version))
    from public.vertrag_dokumente d where d.aktiv and d.schluessel = any(p)
$$;

-- ── 1) Vorschlag ───────────────────────────────────────────────────────────────────────────────
-- Batu: Beginn 01.11.2026, Sommerferien ab Mo 19.07.2027 → Fr 16.07.2027. 37 Wochen ab 02.11.2026,
-- ohne die volle Weihnachtswoche (28.12.) und die zwei Osterwochen (22.03., 29.03.) → 34.
select is((select row(ende, einheiten)::text from vertrag_pilot_vorschlag('2026-11-01')),
          row(date '2027-07-16', 34)::text, '1 Vorschlag ab 01.11.2026: 16.07.2027, 34 Einheiten');
select is((select ende from vertrag_pilot_vorschlag('2027-11-01')), date '2028-07-07',
          '1 Vorschlag ab 01.11.2027: Fr 07.07.2028 vor Sommerferien 10.07.2028');
select throws_ok($$select * from vertrag_pilot_vorschlag('2026-11-15')$$, '22023', null,
                 '1 Vorschlag: Beginn muss Monatserster sein');
select pg_temp.als(:'coach_a');
select throws_ok($$select * from vertrag_pilot_vorschlag('2026-11-01')$$, '42501', null, '1 Vorschlag: nur Admin');
select pg_temp.als(:'admin');

-- ── 2) Pilot anlegen ───────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Paula Vorort'), 'pilot') as pv \gset
select is((select row(vertragsart, preis_cents, tier_id)::text from vertraege where id = :'pv'),
          row('pilot', 0, null::uuid)::text, '2 vertrag_starten pilot: Vertragsart pilot, Preis 0, kein Paket');
select throws_ok(format($f$select vertrag_starten(%L, 'probe')$f$, pg_temp.lead('Xaver Falsch')), '22023', null,
                 '2 vertrag_starten: unbekannte Vertragsart');
select vertrag_starten(pg_temp.lead('Rudi Standard')) as rs \gset
select is((select vertragsart from vertraege where id = :'rs'), 'regulaer', '2 vertrag_starten ohne Vertragsart bleibt regulaer');

-- Formular speichert: das Paket verwirft der Guard, Einheiten und Ende bleiben stehen.
update vertraege
   set tier_id = (select id from tiers where name = 'Basic'), laufzeit_monate = 12,
       vertragsbeginn = '2027-11-01', vertrag_ende = '2028-07-07', einheiten = 30,
       eltern_vorname = 'Eva', eltern_nachname = 'Vorort', kind_vorname = 'Paula', kind_nachname = 'Vorort',
       klasse = 8, fach = 'Mathematik'
 where id = :'pv';
select is((select row(tier_id, laufzeit_monate, preis_cents, einheiten, vertrag_ende)::text from vertraege where id = :'pv'),
          row(null::uuid, null::int, 0, 30, date '2028-07-07')::text,
          '2 Guard: Pilot ohne Paket und Laufzeit, Preis 0, Einheiten und Ende aus dem Formular');

-- ── 3) Regeln ──────────────────────────────────────────────────────────────────────────────────
select throws_ok(format($f$insert into vertraege (lead_id, vertragsart, preis_cents) values (%L, 'pilot', 4900)$f$,
                        pg_temp.lead('Preis Falsch')), '23514', null, '3 Pilot mit Preis ≠ 0 → Fehler');
select throws_ok(format($f$insert into vertraege (lead_id, vertragsart, preis_cents, tier_id) values (%L, 'pilot', 0, %L)$f$,
                        pg_temp.lead('Paket Falsch'), (select id from tiers where name = 'Basic')),
                 '23514', null, '3 Pilot mit Paket → Fehler');
select throws_ok(format($f$update vertraege set einheiten = 0 where id = %L$f$, :'pv'), '23514', null,
                 '3 Pilot mit 0 Einheiten → Fehler');
select throws_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', null, p_tier_id => (select id from tiers where name = 'Basic'), p_student_uid => %L)$f$,
                        :'pv', pg_temp.zust('pilotvereinbarung', 'datenschutz_vertrag'), :'kind_vo'),
                 'P0001', 'vertrag_abschliessen: eine Pilotvereinbarung hat kein Paket und keine Laufzeit',
                 '3 Abschluss mit Paket → Fehler');
update vertraege set vertrag_ende = '2027-12-28' where id = :'pv';
select throws_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', p_student_uid => %L)$f$,
                        :'pv', pg_temp.zust('pilotvereinbarung', 'datenschutz_vertrag'), :'kind_vo'),
                 'P0001', 'vertrag_pilot: Vertragsende 2027-12-28 liegt in den Ferien (Weihnachten 2027/28)',
                 '3 Ende in den Ferien → Fehler');
update vertraege set vertrag_ende = '2028-07-07' where id = :'pv';
select throws_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', p_student_uid => %L)$f$,
                        :'pv', pg_temp.zust('datenschutz_vertrag'), :'kind_vo'),
                 'P0001', 'vertrag_abschliessen: Zustimmung fehlt fuer pilotvereinbarung',
                 '3 Pilotvereinbarung ist Pflichtdokument');

-- ── 4) Abschluss vor Ort ───────────────────────────────────────────────────────────────────────
select lives_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig-vertrag', p_student_uid => %L, p_student_email => 'v5-vo@test.local')$f$,
                       :'pv', pg_temp.zust('pilotvereinbarung', 'datenschutz_vertrag'), :'kind_vo'),
                '4 Abschluss vor Ort ohne SEPA-Unterschrift und ohne IBAN');
select is((select row(status, vertrag_status, widerruf_bis, ferientage, preis_cents, einheiten, vertrag_ende)::text
             from vertraege where id = :'pv'),
          row('abgeschlossen', 'aktiv', null::date, null::int, 0, 30, date '2028-07-07')::text,
          '4 Status aktiv, kein Widerruf, keine Ferienverlängerung, Preis 0');
select ok((select zugangscode is not null and student_id is not null from vertraege where id = :'pv'),
          '4 Zugangscode und Schüler gesetzt');
select is((select role from profiles where id = :'kind_vo'), 'student', '4 Schülerkonto angelegt');
select is((select count(*)::int from student_subscriptions s join vertraege v on v.student_id = s.student_id
            where v.id = :'pv'), 0, '4 kein Abo für den Pilot');
select is((select array_agg(art order by art) from vertrag_unterschriften where vertrag_id = :'pv'), array['vertrag'],
          '4 nur die Vertragsunterschrift, kein SEPA-Mandat');
select is((select vertrag_abschliessen(:'pv', 'vor_ort') ->> 'bereits_abgeschlossen'), 'true', '4 zweiter Aufruf idempotent');

-- ── 5) Abschluss Papier ────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Piet Papier'), 'pilot') as pp \gset
update vertraege set vertragsbeginn = '2027-11-01', vertrag_ende = '2028-03-17', einheiten = 16,
                     kind_vorname = 'Piet', kind_nachname = 'Papier', klasse = 8
 where id = :'pp';
select lives_ok(format($f$select vertrag_versenden(%L, 'druck')$f$, :'pp'), '5 Versand ohne Paket und ohne IBAN');
select is((select array_agg(dokument_schluessel order by dokument_schluessel) from vertrag_zustimmungen where vertrag_id = :'pp'),
          array['datenschutz_vertrag', 'einwilligung_fotos', 'pilotvereinbarung'],
          '5 Bündel des Pilots: ohne SEPA, Widerruf, AGB und regulären Vertrag');
select lives_ok(format($f$select vertrag_abschliessen(%L, 'papier', p_unterschrieben_am => '2027-10-20', p_eingang_datum => '2027-10-22', p_scan_pfad => 'v5/scan.pdf', p_student_uid => %L, p_student_email => 'v5-pa@test.local')$f$,
                       :'pp', :'kind_pa'), '5 Abschluss Papier mit Scan');
select is((select vertrag_status from vertraege where id = :'pp'), 'aktiv', '5 Papier: Status aktiv');

-- ── 6) Status und Kennzahlen ───────────────────────────────────────────────────────────────────
select is((select row(wirksamer_status, beitrag_diesen_monat_cents, vertragsart)::text from vertraege_aktuell where id = :'pv'),
          row('aktiv', 0, 'pilot')::text, '6 vertraege_aktuell: aktiv, Beitrag 0, Kennzeichen pilot');
select is(vertrag_wirksamer_status(null, null, '2028-07-07', null, '2028-07-08'), 'ausgelaufen',
          '6 nach dem Ende ausgelaufen');
select throws_ok(format($f$select vertrag_zahlungsstatus_setzen(%L, 'zahlung_offen', 100)$f$, :'pv'), '23514', null,
                 '6 Pilot kommt nie in den Zahlungsverzug');

-- ── 7) Slots ohne Sonderfall ───────────────────────────────────────────────────────────────────
select student_id as spv from vertraege where id = :'pv' \gset
select is(slots_vertrag_am(:'spv', '2028-03-01'), :'pv'::uuid, '7 slots_vertrag_am findet den Pilot im Zeitraum');
select is(slots_vertrag_am(:'spv', '2028-07-10'), null, '7 slots_vertrag_am: nach dem Ende kein Vertrag');
select ok((select vertrag_id = :'pv'::uuid from slots_kinder_basis('2027-11-01') where student_id = :'spv'),
          '7 slots_kinder_basis führt das Pilotkind');
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', %L)$f$, :'spv', pg_temp.zeilen('1:15:woechentlich'), :jetzt),
                '7 Stammplatz für das Pilotkind');
select is((select count(*)::int from stammplaetze where vertrag_id = :'pv'), 1, '7 Stammplatz hängt am Pilotvertrag');
select is((slots_vertrag_json(:'pv') -> 'rhythmus' ->> 'woechentlich'), '1', '7 Rhythmus des Pilots: ein Termin je Woche');

-- ── 8) Folgevertrag ────────────────────────────────────────────────────────────────────────────
select vertrag_folgevertrag_starten(:'pv') as fv \gset
select is((select row(vertragsart, tier_id, preis_cents, vorgaenger_id)::text from vertraege where id = :'fv'),
          row('regulaer', null::uuid, null::int, :'pv'::uuid)::text, '8 Folgevertrag ist regulär, ohne Paket vorbelegt');

-- ── 9) Regulärer Abschluss unverändert ─────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Rita Regel')) as rv \gset
update vertraege set tier_id = (select id from tiers where name = 'Basic'), laufzeit_monate = 12,
                     vertragsbeginn = '2027-11-01', kind_vorname = 'Rita', kind_nachname = 'Regel', klasse = 8
 where id = :'rv';
insert into vertrag_bankdaten (vertrag_id, iban) values (:'rv', 'DE89370400440532013000');
select throws_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', null, p_student_uid => %L, p_student_email => 'v5-reg@test.local')$f$,
                        :'rv', pg_temp.zust('vertrag', 'sepa_mandat', 'agb', 'widerruf', 'datenschutz_vertrag'), :'kind_reg'),
                 'P0001', 'vertrag_abschliessen: Unterschrift fehlt', '9 regulär: SEPA-Unterschrift bleibt Pflicht');
select throws_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', 'sepa', p_student_uid => %L, p_student_email => 'v5-reg@test.local')$f$,
                        :'rv', pg_temp.zust('vertrag', 'agb', 'widerruf', 'datenschutz_vertrag'), :'kind_reg'),
                 'P0001', 'vertrag_abschliessen: Zustimmung fehlt fuer sepa_mandat', '9 regulär: SEPA-Mandat bleibt Pflicht');
select lives_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', 'sepa', p_student_uid => %L, p_student_email => 'v5-reg@test.local')$f$,
                       :'rv', pg_temp.zust('vertrag', 'sepa_mandat', 'agb', 'widerruf', 'datenschutz_vertrag', 'pilotvereinbarung'), :'kind_reg'),
                '9 regulär: Abschluss ohne Pilotvereinbarung');
select is((select count(*)::int from vertrag_zustimmungen where vertrag_id = :'rv' and dokument_schluessel = 'pilotvereinbarung'), 0,
          '9 regulär: eine mitgeschickte Pilotvereinbarung wird nicht als Zustimmung festgehalten');
select is((select row(vertragsart, vertrag_status, widerruf_bis)::text from vertraege where id = :'rv'),
          row('regulaer', 'im_widerruf', date '2027-11-30')::text, '9 regulär: im Widerruf bis Beginn + 29');
select is((select count(*)::int from student_subscriptions s join vertraege v on v.student_id = s.student_id
            where v.id = :'rv'), 1, '9 regulär: Abo angelegt');

select * from finish();
rollback;
