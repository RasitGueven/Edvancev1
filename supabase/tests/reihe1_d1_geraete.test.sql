-- ============================================================================
-- Reihe 1 · D1 Anmeldung mit Zugangscode und Geräte (Bauauftrag D, D1.3; Zweitprüfung D1).
--
--   1) richtiger Code (auch klein, ohne EDV und Bindestriche) → Gerät, Session eingetragen, Status aktiv
--   2) falscher Code → falsch, im Protokoll ohne Klartext
--   3) abgelaufener Vertrag, gesperrter Code, Code eines Altvertrags trotz laufendem Folgevertrag → kein_vertrag
--   4) viertes Gerät → zu_viele_geraete; dieselbe Installation ersetzt ihr Gerät erst mit neuer Session;
--      eine Zeile ohne Session älter als 2 Minuten belegt keinen Platz
--   5) abgemeldetes Gerät → Status abgemeldet, Auth-Session gelöscht
--   6) fünf Fehlversuche je Installation oder je IP (auch mit wechselnden Installationen) → 15 Minuten gesperrt,
--      auch mit richtigem Code; danach frei; Protokoll älter als 30 Tage wird gelöscht
--   7) Rechte: einlösen nur service_role (nicht authenticated, nicht anon); Admin-Funktionen nur Admin;
--      ein Kind sieht nie Geräte, auch nicht die eigenen, und nie das Protokoll
--   8) Freischalten nur, wenn dieser Vertrag läuft; neuer Code über vertrag_zugangscode_neu macht den alten ungültig
--   9) tote Auth-Session gibt den Platz frei; das Kind meldet sich selbst ab; systemweite Bremse
--
-- now() ist in der Testtransaktion konstant; die Zeitfälle verschieben deshalb die Zeitstempel der Zeilen.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set admin  'dddddddd-d100-4000-8000-000000000001'
\set k1     'dddddddd-d100-4000-8000-000000000002'
\set k2     'dddddddd-d100-4000-8000-000000000003'
\set k3     'dddddddd-d100-4000-8000-000000000004'
\set coach  'dddddddd-d100-4000-8000-000000000005'
\set k4     'dddddddd-d100-4000-8000-000000000006'
\set sess1  'aaaaaaaa-0000-4000-8000-000000000001'
\set sess4  'aaaaaaaa-0000-4000-8000-000000000004'
\set sess1b 'aaaaaaaa-0000-4000-8000-000000000011'

-- Im Neuaufbau gibt es auth.sessions nicht; für den Löschpfad legt der Test eine schlanke Fassung an.
create table if not exists auth.sessions (id uuid primary key, user_id uuid);

insert into auth.users (id, email, instance_id, aud, role)
select u, 'd1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'k1', 'k1'), (:'k2', 'k2'), (:'k3', 'k3'), (:'coach', 'coach'), (:'k4', 'k4')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'd1-admin@test.local', 'admin', 'ZZ Admin'),
  (:'coach', 'd1-coach@test.local', 'coach', 'ZZ Coach'),
  (:'k1', 'd1-k1@test.local', 'student', 'Batu Test'),
  (:'k2', 'd1-k2@test.local', 'student', 'Mira Test'),
  (:'k3', 'd1-k3@test.local', 'student', 'Elif Test'),
  (:'k4', 'd1-k4@test.local', 'student', 'Noah Test');
insert into auth.sessions (id, user_id) values (:'sess1', :'k1'), (:'sess4', :'k1'), (:'sess1b', :'k1');

create or replace function pg_temp.als(uid uuid, sess uuid default null) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated', 'session_id', sess)::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;
create or replace function pg_temp.h(t text) returns text language sql as $$ select encode(sha256(t::bytea), 'hex') $$;

-- Kind mit abgeschlossenem Vertrag; ende in der Vergangenheit heißt: abgelaufen. p_student für Folgeverträge.
create or replace function pg_temp.kind(p_profil uuid, p_code text, p_beginn date, p_ende date, p_student uuid default null)
returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid := p_student;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Kind', 'ZZ', 'vertrag', 9) returning id into v_lead;
  if v_st is null then
    insert into students (class_level, profile_id) values (9, p_profil) returning id into v_st;
  end if;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname, zugangscode, zugangscode_erzeugt_am)
  select v_lead, 'abgeschlossen', case when p_ende < current_date then 'ausgelaufen' else 'aktiv' end, now(), p_beginn - 30,
         'vor_ort', v_st, p_beginn, p_ende, p_beginn + 13,
         t.id, 12, tl.einheiten, 'Mathematik', 9, 'ZZ', 'Kind', p_code, p_beginn - 30
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = 12
   where t.name = 'Basic';
  return v_st;
end $$;

select pg_temp.kind(:'k1', 'EDV-K7M2-QX9A', date_trunc('month', current_date)::date, (current_date + 300)) as s1 \gset
select pg_temp.kind(:'k2', 'EDV-M3R8-TT4B', date_trunc('month', current_date)::date, (current_date + 300)) as s2 \gset
select pg_temp.kind(:'k3', 'EDV-AXT9-ZZ2C', date '2025-01-01', date '2025-06-30') as s3 \gset
select pg_temp.kind(:'k4', 'EDV-ATTV-ERT2', date '2025-01-01', date '2025-06-30') as s4 \gset
select pg_temp.kind(:'k4', 'EDV-NEUV-ERT3', date_trunc('month', current_date)::date, (current_date + 300), :'s4') as s4b \gset
select id as v1 from vertraege where student_id = :'s1' \gset
select id as v2 from vertraege where student_id = :'s2' \gset
select id as v3 from vertraege where student_id = :'s3' \gset
select id as v4alt from vertraege where zugangscode = 'EDV-ATTV-ERT2' \gset

select ok(hat_zugang(:'s1'), 'Grundlage: Vertrag von Kind 1 läuft');
select ok(not hat_zugang(:'s3'), 'Grundlage: Vertrag von Kind 3 ist abgelaufen');
select ok(hat_zugang(:'s4'), 'Grundlage: Kind 4 hat einen laufenden Folgevertrag');

-- ── 1) richtiger Code ───────────────────────────────────────────────────────
select is(zugangscode_normalisieren(' k7m2 qx9a '), 'EDV-K7M2-QX9A', '1 Normalisieren: klein, mit Leerzeichen, ohne EDV');
select is(zugangscode_normalisieren('edv-k7m2-qx9a'), 'EDV-K7M2-QX9A', '1 Normalisieren: Anzeigeform klein');
select is(zugangscode_normalisieren('K7M2'), null::text, '1 Normalisieren: zu kurz ergibt null');

set local role service_role;
select * from geraet_einloesen('k7m2qx9a', 'Batus iPhone', 'ios', pg_temp.h('inst-1'), pg_temp.h('ip-1')) \gset e1_
select lives_ok(format('select geraet_session_setzen(%L, %L)', :'e1_geraet_id', :'sess1'), '1 service_role trägt die Session ein');
reset role;
select is(:'e1_ergebnis'::text, 'ok', '1 richtiger Code als service_role: ok');
select is(:'e1_student_id'::uuid, :'s1'::uuid, '1 liefert das Kind');
select is(:'e1_auth_user_id'::uuid, :'k1'::uuid, '1 liefert das Auth-Konto des Kindes');
select is(:'e1_email'::text, 'd1-k1@test.local', '1 liefert die E-Mail des Kontos für den Magic-Link');
select throws_ok(format('select geraet_session_setzen(%L, %L)', :'e1_geraet_id', gen_random_uuid()),
                 '55000', null, '1 Session lässt sich nicht überschreiben');
select throws_ok($$select * from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', repeat('a', 64), null)$$, '22023', null,
                 '1 ohne IP-Hash kein Einlösen');

select pg_temp.als(:'k1', :'sess1');
select is(geraet_status(), 'aktiv', '1 geraet_status: aktiv');
select ok(not geraet_abgemeldet(), '1 geraet_abgemeldet: false');
select ok(geraet_session(), '1 geraet_session: true');
select pg_temp.als(:'k1', null);
select is(geraet_status(), 'ohne_geraet', '1 Passwort-Session ohne Gerät: ohne_geraet');
select ok(not geraet_session(), '1 Passwort-Session ist keine Gerätesitzung');

-- ── 2) falscher Code ────────────────────────────────────────────────────────
select is((select ergebnis from geraet_einloesen('EDV-XXXX-YYYY', 'Tablet', 'android', pg_temp.h('inst-2'), pg_temp.h('ip-2'))),
          'falsch', '2 falscher Code: falsch');
select is((select ergebnis from geraet_einloesen('quatsch', 'Tablet', 'android', pg_temp.h('inst-2'), pg_temp.h('ip-2'))),
          'falsch', '2 unlesbarer Code: falsch');
select is((select count(*)::int from zugangscode_versuche where installation_hash = pg_temp.h('inst-2') and ergebnis = 'falsch'),
          2, '2 beide Fehlversuche stehen im Protokoll');
select is((select count(*)::int from information_schema.columns
            where table_schema = 'public' and table_name = 'zugangscode_versuche' and column_name ilike '%code%'),
          0, '2 das Protokoll hat keine Spalte für den Code');
select is((select count(*)::int from zugangscode_versuche z where z::text ilike '%XXXX%' or z::text ilike '%K7M2%'),
          0, '2 kein Klartext-Code im Protokoll');

-- ── 3) abgelaufen, gesperrt, Altvertrag ─────────────────────────────────────
select is((select ergebnis from geraet_einloesen('EDV-AXT9-ZZ2C', 'Handy', 'android', pg_temp.h('inst-3'), pg_temp.h('ip-3'))),
          'kein_vertrag', '3 abgelaufener Vertrag: kein_vertrag');
update vertraege set zugangscode_gesperrt_am = current_date where id = :'v2';
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Handy', 'android', pg_temp.h('inst-3'), pg_temp.h('ip-3'))),
          'kein_vertrag', '3 gesperrter Code: kein_vertrag');
update vertraege set zugangscode_gesperrt_am = null where id = :'v2';
select is((select ergebnis from geraet_einloesen('EDV-ATTV-ERT2', 'Handy', 'android', pg_temp.h('inst-3b'), pg_temp.h('ip-3b'))),
          'kein_vertrag', '3 Code des abgelaufenen Altvertrags gilt nicht, auch wenn ein Folgevertrag läuft');
select is((select ergebnis from geraet_einloesen('EDV-NEUV-ERT3', 'Handy', 'android', pg_temp.h('inst-3b'), pg_temp.h('ip-3b'))),
          'ok', '3 der Code des laufenden Folgevertrags gilt');

-- ── 4) viertes Gerät, gleiche Installation, verwaiste Zeile ─────────────────
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'iPad', 'ios', pg_temp.h('inst-4'), pg_temp.h('ip-4'))),
          'ok', '4 zweites Gerät: ok');
select id as g4 from kind_geraete where installation_hash = pg_temp.h('inst-4') \gset
select geraet_session_setzen(:'g4', :'sess4');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Laptop', 'web', pg_temp.h('inst-5'), pg_temp.h('ip-4'))),
          'ok', '4 drittes Gerät: ok (noch ohne Session)');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Viertes', 'android', pg_temp.h('inst-6'), pg_temp.h('ip-4'))),
          'zu_viele_geraete', '4 viertes Gerät: zu_viele_geraete');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Batus iPhone neu', 'ios', pg_temp.h('inst-1'), pg_temp.h('ip-1'))),
          'ok', '4 dieselbe Installation darf sich auch bei drei Geräten neu anmelden');
select is((select abgemeldet_am from kind_geraete where id = :'e1_geraet_id'), null::timestamptz,
          '4 … das alte Gerät bleibt bis zur neuen Session angemeldet');
select id as g1b from kind_geraete where installation_hash = pg_temp.h('inst-1') and auth_session_id is null \gset
select geraet_session_setzen(:'g1b', :'sess1b');
select is((select abmelde_grund from kind_geraete where id = :'e1_geraet_id'), 'neu_angemeldet',
          '4 mit der neuen Session ist das alte Gerät abgemeldet');
select is((select count(*)::int from auth.sessions where id = :'sess1'), 0, '4 … und seine Auth-Session gelöscht');
update kind_geraete set angemeldet_am = now() - interval '3 minutes' where installation_hash = pg_temp.h('inst-5');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Viertes', 'android', pg_temp.h('inst-6'), pg_temp.h('ip-4'))),
          'ok', '4 eine Zeile ohne Session älter als 2 Minuten belegt keinen Platz');
select is((select abmelde_grund from kind_geraete where installation_hash = pg_temp.h('inst-5')), 'abbruch',
          '4 … sie ist als Abbruch abgemeldet');

-- ── 5) abgemeldetes Gerät ───────────────────────────────────────────────────
select pg_temp.als(:'k1', :'sess1');
select is(geraet_status(), 'abgemeldet', '5 alte Session des ersetzten Geräts: abgemeldet');
select ok(geraet_abgemeldet(), '5 geraet_abgemeldet: true');
select pg_temp.als(:'admin');
select lives_ok(format('select kind_geraet_abmelden(%L)', :'g4'), '5 Admin meldet das iPad ab');
select throws_ok(format('select kind_geraet_abmelden(%L)', :'g4'), '55000', null, '5 zweites Abmelden: nicht angemeldet');
select is((select count(*)::int from auth.sessions where id = :'sess4'), 0, '5 die Auth-Session des iPads ist gelöscht');
select is((select abgemeldet_von from kind_geraete where id = :'g4'), :'admin'::uuid, '5 abgemeldet_von ist der Admin');
select pg_temp.als(:'k1', :'sess4');
select is(geraet_status(), 'abgemeldet', '5 abgemeldetes iPad: abgemeldet');
select pg_temp.als(:'k1', :'sess1b');
select is(geraet_status(), 'aktiv', '5 das neue iPhone bleibt aktiv');

-- ── 6) Sperre ───────────────────────────────────────────────────────────────
select count(*) from generate_series(1, 5) n, geraet_einloesen('EDV-FALS-CH00', 'x' || n, 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7'));
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7b'))),
          'gesperrt', '6 sechster Versuch derselben Installation ist gesperrt, auch mit richtigem Code');
select ok((select warte_sek between 890 and 900 from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7b'))),
          '6 Wartezeit rund 15 Minuten');
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-8'), pg_temp.h('ip-7'))),
          'gesperrt', '6 andere Installation, gleiche IP: gesperrt');
select count(*) from generate_series(1, 5) n, geraet_einloesen('EDV-FALS-CH00', 'y', 'ios', pg_temp.h('wechsel-' || n), pg_temp.h('ip-9'));
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('wechsel-neu'), pg_temp.h('ip-9'))),
          'gesperrt', '6 fünf Fehlversuche mit wechselnden Installationen sperren die IP');
select is((select count(*)::int from kind_geraete where student_id = :'s2'), 0, '6 gesperrt legt kein Gerät an');
update zugangscode_versuche set am = am - interval '16 minutes' where installation_hash = pg_temp.h('inst-7') or ip_hash = pg_temp.h('ip-7');
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7'))),
          'ok', '6 nach 15 Minuten wieder frei');
select is((select count(*)::int from generate_series(1, 4) n, geraet_einloesen('EDV-FALS-CH00', 'x' || n, 'ios', pg_temp.h('inst-9'), pg_temp.h('ip-10')) e
            where e.ergebnis = 'falsch'), 4, '6 vier Fehlversuche …');
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'x', 'android', pg_temp.h('inst-9'), pg_temp.h('ip-10'))),
          'ok', '6 … sperren noch nicht');
insert into zugangscode_versuche (am, installation_hash, ip_hash, ergebnis) values (now() - interval '31 days', pg_temp.h('alt'), pg_temp.h('alt'), 'falsch');
select geraet_einloesen('EDV-FALS-CH00', 'z', 'ios', pg_temp.h('inst-11'), pg_temp.h('ip-11'));
select is((select count(*)::int from zugangscode_versuche where installation_hash = pg_temp.h('alt')), 0,
          '6 Protokollzeilen älter als 30 Tage sind gelöscht');

-- ── 7) Rechte ───────────────────────────────────────────────────────────────
select pg_temp.als(:'k1', :'sess1b');
set local role authenticated;
select throws_ok($$select * from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', repeat('a', 64), repeat('b', 64))$$, '42501', null,
                 '7 authenticated darf nicht einlösen');
select throws_ok(format('select geraet_session_setzen(%L, %L)', :'g4', gen_random_uuid()), '42501', null,
                 '7 authenticated darf keine Session eintragen');
select throws_ok(format('select geraet_auth_session_loeschen(%L)', :'sess1b'), '42501', null,
                 '7 authenticated löscht keine Auth-Session');
select is((select count(*)::int from kind_geraete), 0, '7 Kind liest kind_geraete nicht direkt');
select is((select count(*)::int from zugangscode_versuche), 0, '7 Kind liest das Protokoll nicht');
select throws_ok($$insert into kind_geraete (student_id, name, plattform, installation_hash) values (gen_random_uuid(), 'x', 'ios', repeat('a', 64))$$,
                 '42501', null, '7 Kind schreibt nicht in kind_geraete');
select throws_ok(format('select * from kind_geraete_liste(%L)', :'s1'), '42501', null, '7 Kind liest keine Geräteliste, auch nicht die eigene');
select throws_ok(format('select kind_geraet_abmelden(%L)', :'g4'), '42501', null, '7 Kind meldet kein Gerät ab');
reset role;
set local role anon;
select throws_ok($$select geraet_status()$$, '42501', null, '7 anon: geraet_status gesperrt');
select throws_ok($$select * from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', repeat('a', 64), repeat('b', 64))$$, '42501', null,
                 '7 anon darf nicht einlösen');
reset role;
select pg_temp.als(:'k2', :'sess1b');
select is(geraet_status(), 'abgemeldet', '7 eine fremde Session gilt für ein anderes Kind nie als aktiv');
select pg_temp.als(:'coach');
set local role authenticated;
select throws_ok(format('select * from kind_geraete_liste(%L)', :'s1'), '42501', null, '7 Coach liest keine Geräteliste');
select throws_ok(format('select zugangscode_freischalten(%L)', :'v1'), '42501', null, '7 Coach schaltet keinen Code frei');
select throws_ok('select geraet_status()', '42501', null, '7 geraet_status nur für Kinderkonten');
reset role;
select pg_temp.als(:'admin');
set local role authenticated;
select is((select count(*)::int from kind_geraete_liste(:'s1')), 3, '7 Admin sieht die Geräte von Kind 1 mit Session');
select is((select count(*)::int from kind_geraete_liste(:'s1') where abgemeldet_am is null), 1, '7 … davon eins aktiv');
reset role;

-- ── 8) neuer Code, Freischalten ─────────────────────────────────────────────
select pg_temp.als(:'admin');
select vertrag_zugangscode_neu(:'v2') as neu2 \gset
reset role;
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira 2', 'ios', pg_temp.h('inst-12'), pg_temp.h('ip-12'))),
          'falsch', '8 der alte Code ist nach vertrag_zugangscode_neu ungültig');
select is((select ergebnis from geraet_einloesen(:'neu2', 'Mira 2', 'ios', pg_temp.h('inst-12'), pg_temp.h('ip-12'))),
          'ok', '8 der neue Code gilt');
update vertraege set zugangscode_gesperrt_am = current_date where id = :'v2';
select pg_temp.als(:'admin');
select lives_ok(format('select zugangscode_freischalten(%L)', :'v2'), '8 Freischalten bei laufendem Vertrag');
select is((select zugangscode_gesperrt_am from vertraege where id = :'v2'), null::date, '8 Sperre aufgehoben');
select throws_ok(format('select zugangscode_freischalten(%L)', :'v2'), '55000', null, '8 nicht gesperrt: Fehler');
update vertraege set zugangscode_gesperrt_am = current_date where id in (:'v3', :'v4alt');
select throws_ok(format('select zugangscode_freischalten(%L)', :'v3'), '55000', null, '8 abgelaufener Vertrag: kein Freischalten');
select throws_ok(format('select zugangscode_freischalten(%L)', :'v4alt'), '55000', null,
                 '8 Altvertrag: kein Freischalten, auch wenn ein Folgevertrag läuft');
reset role;

-- ── 9) tote Session, Selbst-Abmelden, Bremse ───────────────────────────────
-- Die Session des neuen iPhones verschwindet in auth (abgelaufen/gelöscht): beim nächsten Einlösen wird die Zeile frei.
delete from auth.sessions where id = :'sess1b';
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Tablet neu', 'android', pg_temp.h('inst-13'), pg_temp.h('ip-13'))),
          'ok', '9 Einlösen nach toter Session');
select is((select abmelde_grund from kind_geraete where auth_session_id = :'sess1b'), 'verwaist',
          '9 die Zeile mit toter Session ist als verwaist abgemeldet');
select id as g13 from kind_geraete where installation_hash = pg_temp.h('inst-13') \gset
insert into auth.sessions (id, user_id) values ('aaaaaaaa-0000-4000-8000-000000000013', :'k1');
select geraet_session_setzen(:'g13', 'aaaaaaaa-0000-4000-8000-000000000013');
select pg_temp.als(:'k1', 'aaaaaaaa-0000-4000-8000-000000000013');
select lives_ok('select geraet_abmelden_selbst()', '9 das Kind meldet das eigene Gerät ab');
select is(geraet_status(), 'abgemeldet', '9 danach abgemeldet');
reset role;
select is((select abmelde_grund from kind_geraete where id = :'g13'), 'selbst', '9 Grund selbst');
select is((select count(*)::int from auth.sessions where id = 'aaaaaaaa-0000-4000-8000-000000000013'), 0, '9 Session gelöscht');
insert into zugangscode_versuche (installation_hash, ip_hash, ergebnis)
select pg_temp.h('flut-' || n), pg_temp.h('flutip-' || n), 'falsch' from generate_series(1, 2000) n;
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', pg_temp.h('inst-14'), pg_temp.h('ip-14'))),
          'gesperrt', '9 2000 Fehlversuche systemweit: Bremse, auch für einen richtigen Code');
select ok((select warte_sek <= 60 from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', pg_temp.h('inst-14'), pg_temp.h('ip-14'))),
          '9 die Bremse dauert höchstens eine Minute');

select * from finish();
rollback;
