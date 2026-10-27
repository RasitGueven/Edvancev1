-- ============================================================================
-- Reihe 1 · D1 Anmeldung mit Zugangscode und Geräte (Bauauftrag D, D1.3).
--
--   1) richtiger Code (auch klein, ohne EDV und Bindestriche) → Gerät angelegt, Session eingetragen
--   2) falscher Code → falsch, im Protokoll ohne Klartext
--   3) abgelaufener Vertrag und gesperrter Code → kein_vertrag
--   4) viertes Gerät → zu_viele_geraete; dieselbe Installation meldet sich neu an, ohne Platz zu belegen
--   5) abgemeldetes Gerät → geraet_status 'abgemeldet', geraet_abgemeldet() true
--   6) fünf Fehlversuche je Installation oder IP → 15 Minuten gesperrt, auch mit richtigem Code; danach wieder frei
--   7) Rechte: einlösen nur service_role; Admin-Funktionen nur Admin; ein Kind sieht nie Geräte eines anderen
--   8) Admin: neuer Code macht den alten ungültig, Freischalten nur bei laufendem Vertrag
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set admin  'dddddddd-d100-4000-8000-000000000001'
\set k1     'dddddddd-d100-4000-8000-000000000002'
\set k2     'dddddddd-d100-4000-8000-000000000003'
\set k3     'dddddddd-d100-4000-8000-000000000004'
\set coach  'dddddddd-d100-4000-8000-000000000005'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'd1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'k1', 'k1'), (:'k2', 'k2'), (:'k3', 'k3'), (:'coach', 'coach')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'd1-admin@test.local', 'admin', 'ZZ Admin'),
  (:'coach', 'd1-coach@test.local', 'coach', 'ZZ Coach'),
  (:'k1', 'd1-k1@test.local', 'student', 'Batu Test'),
  (:'k2', 'd1-k2@test.local', 'student', 'Mira Test'),
  (:'k3', 'd1-k3@test.local', 'student', 'Elif Test');

create or replace function pg_temp.als(uid uuid, sess uuid default null) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated', 'session_id', sess)::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;
create or replace function pg_temp.h(t text) returns text language sql as $$ select encode(sha256(t::bytea), 'hex') $$;

-- Kind mit abgeschlossenem Vertrag; ende in der Vergangenheit heißt: abgelaufen.
create or replace function pg_temp.kind(p_profil uuid, p_code text, p_beginn date, p_ende date) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Kind', 'ZZ', 'vertrag', 9) returning id into v_lead;
  insert into students (class_level, profile_id) values (9, p_profil) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname, zugangscode, zugangscode_erzeugt_am)
  select v_lead, 'abgeschlossen', 'aktiv', now(), p_beginn - 30, 'vor_ort', v_st, p_beginn, p_ende, p_beginn + 13,
         t.id, 12, tl.einheiten, 'Mathematik', 9, 'ZZ', 'Kind', p_code, p_beginn - 30
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = 12
   where t.name = 'Basic';
  return v_st;
end $$;

select pg_temp.kind(:'k1', 'EDV-K7M2-QX9A', date_trunc('month', current_date)::date, (current_date + 300)) as s1 \gset
select pg_temp.kind(:'k2', 'EDV-M3R8-TT4B', date_trunc('month', current_date)::date, (current_date + 300)) as s2 \gset
select pg_temp.kind(:'k3', 'EDV-AXT9-ZZ2C', date '2025-01-01', date '2025-06-30') as s3 \gset
select id as v1 from vertraege where student_id = :'s1' \gset
select id as v2 from vertraege where student_id = :'s2' \gset

select ok(hat_zugang(:'s1'), 'Grundlage: Vertrag von Kind 1 läuft');
select ok(not hat_zugang(:'s3'), 'Grundlage: Vertrag von Kind 3 ist abgelaufen');

-- ── 1) richtiger Code ───────────────────────────────────────────────────────
select is(zugangscode_normalisieren(' k7m2 qx9a '), 'EDV-K7M2-QX9A', '1 Normalisieren: klein, mit Leerzeichen, ohne EDV');
select is(zugangscode_normalisieren('edv-k7m2-qx9a'), 'EDV-K7M2-QX9A', '1 Normalisieren: Anzeigeform klein');
select is(zugangscode_normalisieren('K7M2'), null::text, '1 Normalisieren: zu kurz ergibt null');

select * from geraet_einloesen('k7m2qx9a', 'Batus iPhone', 'ios', pg_temp.h('inst-1'), pg_temp.h('ip-1')) \gset e1_
select is(:'e1_ergebnis'::text, 'ok', '1 richtiger Code: ok');
select is(:'e1_student_id'::uuid, :'s1'::uuid, '1 liefert das Kind');
select is(:'e1_auth_user_id'::uuid, :'k1'::uuid, '1 liefert das Auth-Konto des Kindes');
select is(:'e1_email'::text, 'd1-k1@test.local', '1 liefert die E-Mail des Kontos für den Magic-Link');
select lives_ok(format('select geraet_session_setzen(%L, %L)', :'e1_geraet_id', 'aaaaaaaa-0000-4000-8000-000000000001'),
                '1 Session am Gerät eintragen');
select throws_ok(format('select geraet_session_setzen(%L, %L)', :'e1_geraet_id', 'aaaaaaaa-0000-4000-8000-000000000009'),
                 '55000', null, '1 Session lässt sich nicht überschreiben');

select pg_temp.als(:'k1', 'aaaaaaaa-0000-4000-8000-000000000001');
select is(geraet_status(), 'aktiv', '1 geraet_status: aktiv');
select ok(not geraet_abgemeldet(), '1 geraet_abgemeldet: false');
select pg_temp.als(:'k1', null);
select is(geraet_status(), 'ohne_geraet', '1 Passwort-Session ohne Gerät: ohne_geraet');
reset role;

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

-- ── 3) abgelaufener Vertrag, gesperrter Code ────────────────────────────────
select is((select ergebnis from geraet_einloesen('EDV-AXT9-ZZ2C', 'Handy', 'android', pg_temp.h('inst-3'), null)),
          'kein_vertrag', '3 abgelaufener Vertrag: kein_vertrag');
update vertraege set zugangscode_gesperrt_am = current_date where id = :'v2';
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Handy', 'android', pg_temp.h('inst-3'), null)),
          'kein_vertrag', '3 gesperrter Code: kein_vertrag');
update vertraege set zugangscode_gesperrt_am = null where id = :'v2';

-- ── 4) viertes Gerät ────────────────────────────────────────────────────────
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'iPad', 'ios', pg_temp.h('inst-4'), pg_temp.h('ip-4'))),
          'ok', '4 zweites Gerät: ok');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Laptop', 'web', pg_temp.h('inst-5'), pg_temp.h('ip-4'))),
          'ok', '4 drittes Gerät: ok');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Viertes', 'android', pg_temp.h('inst-6'), pg_temp.h('ip-4'))),
          'zu_viele_geraete', '4 viertes Gerät: zu_viele_geraete');
select is((select count(*)::int from kind_geraete where student_id = :'s1' and abgemeldet_am is null), 3,
          '4 es bleiben drei aktive Geräte');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'Batus iPhone neu', 'ios', pg_temp.h('inst-1'), pg_temp.h('ip-1'))),
          'ok', '4 dieselbe Installation meldet sich neu an');
select is((select abmelde_grund from kind_geraete where id = :'e1_geraet_id'), 'neu_angemeldet',
          '4 das alte Gerät derselben Installation ist abgemeldet');
select is((select count(*)::int from kind_geraete where student_id = :'s1' and abgemeldet_am is null), 3,
          '4 weiter drei aktive Geräte');

-- ── 5) abgemeldetes Gerät ───────────────────────────────────────────────────
select pg_temp.als(:'k1', 'aaaaaaaa-0000-4000-8000-000000000001');
select is(geraet_status(), 'abgemeldet', '5 alte Session des neu angemeldeten Geräts: abgemeldet');
select ok(geraet_abgemeldet(), '5 geraet_abgemeldet: true');
reset role;
select id as g4 from kind_geraete where installation_hash = pg_temp.h('inst-4') \gset
select geraet_session_setzen(:'g4', 'aaaaaaaa-0000-4000-8000-000000000004');
select pg_temp.als(:'admin');
select lives_ok(format('select kind_geraet_abmelden(%L)', :'g4'), '5 Admin meldet das iPad ab');
select throws_ok(format('select kind_geraet_abmelden(%L)', :'g4'), '55000', null, '5 zweites Abmelden: nicht angemeldet');
select pg_temp.als(:'k1', 'aaaaaaaa-0000-4000-8000-000000000004');
select is(geraet_status(), 'abgemeldet', '5 abgemeldetes iPad: abgemeldet');
reset role;
select is((select abgemeldet_von from kind_geraete where id = :'g4'), :'admin'::uuid, '5 abgemeldet_von ist der Admin');

-- ── 6) Sperre nach fünf Fehlversuchen ───────────────────────────────────────
select count(*) from generate_series(1, 5) n, geraet_einloesen('EDV-FALS-CH00', 'x' || n, 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7'));
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7'))),
          'gesperrt', '6 sechster Versuch derselben Installation ist gesperrt, auch mit richtigem Code');
select ok((select warte_sek between 890 and 900 from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), null)),
          '6 Wartezeit rund 15 Minuten');
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-8'), pg_temp.h('ip-7'))),
          'gesperrt', '6 andere Installation, gleiche IP: gesperrt');
select is((select count(*)::int from kind_geraete where student_id = :'s2'), 0, '6 gesperrt legt kein Gerät an');
update zugangscode_versuche set am = am - interval '16 minutes' where installation_hash = pg_temp.h('inst-7');
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira', 'ios', pg_temp.h('inst-7'), pg_temp.h('ip-7'))),
          'ok', '6 nach 15 Minuten wieder frei');
select is((select count(*)::int from generate_series(1, 4) n, geraet_einloesen('EDV-FALS-CH00', 'x' || n, 'ios', pg_temp.h('inst-9'), null) e
            where e.ergebnis = 'falsch'), 4, '6 vier Fehlversuche …');
select is((select ergebnis from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'android', pg_temp.h('inst-9'), null)),
          'ok', '6 … sperren noch nicht (der fünfte Versuch mit richtigem Code geht durch)');

-- ── 7) Rechte ───────────────────────────────────────────────────────────────
select pg_temp.als(:'k1');
set local role authenticated;
select throws_ok($$select * from geraet_einloesen('EDV-K7M2-QX9A', 'x', 'ios', repeat('a', 64), null)$$, '42501', null,
                 '7 authenticated darf nicht einlösen');
select throws_ok(format('select geraet_session_setzen(%L, %L)', :'g4', gen_random_uuid()), '42501', null,
                 '7 authenticated darf keine Session eintragen');
select is((select count(*)::int from kind_geraete), 0, '7 Kind liest kind_geraete nicht direkt');
select is((select count(*)::int from zugangscode_versuche), 0, '7 Kind liest das Protokoll nicht');
select throws_ok(format('select * from kind_geraete_liste(%L)', :'s2'), '42501', null, '7 Kind liest keine Geräteliste');
select throws_ok(format('select * from kind_geraete_liste(%L)', :'s1'), '42501', null, '7 auch nicht die eigene');
select throws_ok(format('select kind_geraet_abmelden(%L)', :'g4'),
                 '42501', null, '7 Kind meldet kein Gerät ab');
reset role;
select pg_temp.als(:'k2', 'aaaaaaaa-0000-4000-8000-000000000004');
select is(geraet_status(), 'abgemeldet', '7 fremde Session gilt für ein anderes Kind nie als aktiv');
reset role;
select pg_temp.als(:'coach');
set local role authenticated;
select throws_ok(format('select * from kind_geraete_liste(%L)', :'s1'), '42501', null, '7 Coach liest keine Geräteliste');
select throws_ok(format('select zugangscode_neu(%L)', :'v1'), '42501', null, '7 Coach erzeugt keinen Code');
select throws_ok('select geraet_status()', '42501', null, '7 geraet_status nur für Kinderkonten');
reset role;
select pg_temp.als(:'admin');
set local role authenticated;
select is((select count(*)::int from kind_geraete_liste(:'s1')), 2, '7 Admin sieht die Geräte von Kind 1 mit Session');
select is((select count(*)::int from kind_geraete_liste(:'s1') where abgemeldet_am is null), 0,
          '7 … beide abgemeldet (altes iPhone neu angemeldet, iPad vom Admin)');
reset role;

-- ── 8) Admin: neuer Code, Freischalten ──────────────────────────────────────
select pg_temp.als(:'admin');
select zugangscode_neu(:'v2') as neu2 \gset
select ok(:'neu2' ~ '^EDV-[A-Z2-9]{4}-[A-Z2-9]{4}$' and :'neu2' <> 'EDV-M3R8-TT4B', '8 neuer Code in Anzeigeform');
reset role;
select is((select ergebnis from geraet_einloesen('EDV-M3R8-TT4B', 'Mira 2', 'ios', pg_temp.h('inst-10'), null)),
          'falsch', '8 der alte Code ist ungültig');
select is((select ergebnis from geraet_einloesen(:'neu2', 'Mira 2', 'ios', pg_temp.h('inst-10'), null)),
          'ok', '8 der neue Code gilt');
select is((select count(*)::int from kind_geraete where student_id = :'s2' and abgemeldet_am is null), 2,
          '8 das schon angemeldete Gerät bleibt angemeldet');
update vertraege set zugangscode_gesperrt_am = current_date where id = :'v2';
select pg_temp.als(:'admin');
select lives_ok(format('select zugangscode_freischalten(%L)', :'v2'), '8 Freischalten bei laufendem Vertrag');
select is((select zugangscode_gesperrt_am from vertraege where id = :'v2'), null::date, '8 Sperre aufgehoben');
select throws_ok(format('select zugangscode_freischalten(%L)', :'v2'), '55000', null, '8 nicht gesperrt: Fehler');
update vertraege set zugangscode_gesperrt_am = current_date where student_id = :'s3';
select throws_ok(format('select zugangscode_freischalten(id) from vertraege where student_id = %L', :'s3'), '55000', null,
                 '8 abgelaufener Vertrag: kein Freischalten');
reset role;

select * from finish();
rollback;
