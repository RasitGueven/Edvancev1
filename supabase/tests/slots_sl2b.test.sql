-- ============================================================================
-- Slots SL2b — Testkonten in den Slots (Entscheidungen Rasit 12.10.2026, Tests 1–5 des Pakets).
--
--   1) Testkonto mit Vertrag bekommt Stammplatz und Termine, echtes Kind unverändert; Kennzeichen ist_test.
--   2) Kennzahlen ohne Testkonten; ein belegter Platz bleibt belegt (SL001 auch durch Testkonten).
--   3) Testkonto und echtes Kind im selben Termin: SL013 in beiden Reihenfolgen (Stammplatz, Zusatztermin,
--      Absage-Rücknahme), Planung überspringt, Raster und Kandidaten zeigen es vorher.
--   4) Festschreiben nur mit Testkonten -> testlauf = true; mit echtem Kind false; Coach -> 42501.
--   5) tools/slots-testkonten-raeumen.sql: trocken ändert nichts; danach keine Stammplätze und keine künftigen
--      offenen Termine von Testkonten, Termine echter Kinder unberührt.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2027-11-01 08:00 Europe/Berlin'''

create or replace function pg_temp.testkind(p_name text) returns uuid language plpgsql as $$
declare v uuid := pg_temp.kind(p_name, 'Basic', 12, '2027-09-01', '2028-08-31');
begin
  update public.students set ist_test = true where id = v;
  return v;
end $$;

select pg_temp.kind('Rita Real', 'Basic', 12, '2027-09-01', '2028-08-31') as r1 \gset
select pg_temp.kind('Rolf Real', 'Basic', 12, '2027-09-01', '2028-08-31') as r2 \gset
select pg_temp.kind('Rosa Zusatz', 'Basic', 12, '2027-09-01', '2028-08-31') as rz \gset
select pg_temp.testkind('Tina Test') as t1 \gset
select pg_temp.testkind('Tom Test') as t2 \gset
select pg_temp.testkind('Tilo Test') as t3 \gset
select pg_temp.testkind('Toni Test') as t11 \gset

-- ── 3) Planung überspringt einen Termin mit echtem Kind ─────────────────────────────────────────
-- Rosa (echt) hat am Mo 17.01.2028 15 Uhr einen Zusatztermin, bevor Tina ihren Stammplatz Mo 15 bekommt.
select ok(public.betriebstag('2028-01-17'), '3 Mo 17.01.2028 ist ein Betriebstag');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2028-01-17', %L, %L)$f$, :'rz', pg_temp.zeit(15), :jetzt),
                '3 echtes Kind: Zusatztermin Mo 17.01. 15 Uhr');

-- ── 1) Testkonto bekommt Stammplatz und Termine ────────────────────────────────────────────────
select ok(public.slots_kind_zugelassen(:'t1'), '1 slots_kind_zugelassen: Testkonto ist zugelassen');
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', %L)$f$, :'t1', pg_temp.zeilen('1:15:woechentlich'), :jetzt),
                '1 Testkonto: Stammplatz Mo 15 Uhr');
select ok((select count(*) from kind_termine where student_id = :'t1' and herkunft = 'stammplatz') > 0,
          '1 Testkonto hat Stammplatz-Termine');
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', %L)$f$, :'r1', pg_temp.zeilen('2:16:woechentlich'), :jetzt),
                '1 echtes Kind: Stammplatz Di 16 Uhr wie bisher');
select ok((select count(*) from kind_termine where student_id = :'r1' and herkunft = 'stammplatz') > 0,
          '1 echtes Kind hat Stammplatz-Termine');
select is((select count(*)::int from kind_termine where student_id = :'t1' and datum = '2028-01-17'), 0,
          '3 Planung: kein Termin für das Testkonto am Mo 17.01. (echtes Kind dort)');
select ok((slots_kind(:'t1', :jetzt) -> 'planbilanz' -> 'uebersprungen') ? '2028-01-17',
          '3 Planbilanz nennt den 17.01. als übersprungen');

-- Kennzeichen (Entscheidung 2)
select is((slots_kind(:'t1', :jetzt) -> 'kind' ->> 'ist_test')::boolean, true, '1 slots_kind: kind.ist_test für das Testkonto');
select is((slots_kind(:'t1', :jetzt) ->> 'zugelassen')::boolean, true, '1 slots_kind: zugelassen');
select is((slots_kind(:'r1', :jetzt) -> 'kind' ->> 'ist_test')::boolean, false, '1 slots_kind: echtes Kind ohne Kennzeichen');
select is((select (k ->> 'ist_test')::boolean from jsonb_array_elements(slots_kinder(:jetzt)) k where k ->> 'student_id' = :'t1'),
          true, '1 slots_kinder: Testkonto steht in der Liste, gekennzeichnet');
select is((select (k ->> 'ist_test')::boolean from jsonb_array_elements(slots_kinder(:jetzt)) k where k ->> 'student_id' = :'r1'),
          false, '1 slots_kinder: echtes Kind ohne Kennzeichen');
select is((select (k ->> 'ist_test')::boolean
             from jsonb_array_elements(slots_termin('2027-11-08', pg_temp.zeit(15), :jetzt) -> 'raeume') r,
                  jsonb_array_elements(r -> 'kinder') k where k ->> 'student_id' = :'t1'),
          true, '1 slots_termin: Kind im Raum gekennzeichnet');
select is((select (z ->> 'test')::int from jsonb_array_elements(slots_woche('2027-11-08', :jetzt) -> 'zellen') z
            where z ->> 'datum' = '2027-11-08' and z ->> 'zeit_id' = pg_temp.zeit(15)::text),
          1, '1 slots_woche: Zelle zählt das Testkonto in test');

-- ── 2) Belegt bleibt belegt ──────────────────────────────────────────────────────────────────
-- Zehn Testkonten Do 18 Uhr füllen Raum 1 und Raum 2.
create temp table do18 as select n, pg_temp.testkind('Do' || n || ' Test') as student from generate_series(1, 10) n;
select is((select count(*)::int from do18, lateral stammplatz_vergeben(student, pg_temp.zeilen('4:18:woechentlich'), '2027-11-01', :jetzt) x),
          10, '2 zehn Testkonten: Stammplatz Do 18 Uhr');
select is(slot_belegt('2027-11-11', pg_temp.zeit(18)), 10, '2 slot_belegt zählt die Testkonten');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-11-11', %L, %L)$f$, :'t11', pg_temp.zeit(18), :jetzt),
                 'SL001', null, '2 elftes Testkonto: Slot voll (SL001)');

-- Kennzahlen der Woche 08.–12.11.: echt ist nur Rita (Di 16); Tina (Mo 15) und zehn (Do 18) sind Testkonten.
select slots_woche('2027-11-08', :jetzt) as w \gset
select is((:'w'::jsonb -> 'kopf' ->> 'belegt')::int, 1, '2 Kopf belegt: nur echte Kinder');
select is((select sum((z ->> 'belegt')::int)::int from jsonb_array_elements(:'w'::jsonb -> 'zellen') z), 12,
          '2 Zellen belegt: Testkonten belegen ihre Plätze');
select is((select sum((z ->> 'test')::int)::int from jsonb_array_elements(:'w'::jsonb -> 'zellen') z), 11,
          '2 Zellen test: elf Testkonten');
select is((:'w'::jsonb -> 'kopf' ->> 'auslastung')::numeric,
          round(1::numeric / (:'w'::jsonb -> 'kopf' ->> 'plaetze')::int, 3), '2 Auslastung ohne Testkonten');
select is((:'w'::jsonb -> 'kopf' ->> 'ohne_raum')::int, 0, '2 Kopf ohne Raum: 0');
-- Raum 2 fällt Do 18.11. 18 Uhr aus: fünf Testkonten stehen ohne Raum, der Kopf zählt sie nicht.
select lives_ok(format($f$select termin_coach_setzen('2027-11-18', %L, %L, null, %L)$f$, pg_temp.zeit(18), pg_temp.raum('Raum 2'), :jetzt),
                '2 Raum 2 fällt Do 18.11. 18 Uhr aus');
select slots_woche('2027-11-15', :jetzt) as w2 \gset
select is((select (z ->> 'test_ohne_raum')::int from jsonb_array_elements(:'w2'::jsonb -> 'zellen') z
            where z ->> 'datum' = '2027-11-18' and z ->> 'zeit_id' = pg_temp.zeit(18)::text), 5, '2 Zelle: fünf Testkonten ohne Raum');
select is((:'w2'::jsonb -> 'kopf' ->> 'ohne_raum')::int, 0, '2 Kopf ohne Raum zählt Testkonten nicht');
select is(:'w2'::jsonb -> 'kopf' -> 'erster_ohne_raum', 'null'::jsonb, '2 kein Sprungziel für Testkonten ohne Raum');
select is((slots_zaehler(:jetzt) ->> 'ohne_raum')::int, 0, '2 slots_zaehler: ohne Raum ohne Testkonten');
-- Ohne Stammplatz: echt Rolf und Rosa; Testkonten (Tom, Tilo, Toni) zählen nicht.
select is((:'w'::jsonb -> 'kopf' ->> 'ohne_stammplatz')::int, 2, '2 Kopf ohne Stammplatz: nur echte Kinder');
select is((slots_zaehler(:jetzt) ->> 'ohne_stammplatz')::int, 2, '2 slots_zaehler: Testkonten zählen nicht');
select is((select (k ->> 'ohne_stammplatz')::boolean from jsonb_array_elements(slots_kinder(:jetzt)) k where k ->> 'student_id' = :'t2'),
          true, '2 slots_kinder: Testkonto ohne Stammplatz steht trotzdem in der Liste');

-- ── 3) Nie im selben Termin, beide Reihenfolgen ────────────────────────────────────────────────
-- a) Testkonto zuerst (Tina Mo 15), dann echtes Kind
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-11-15', %L, %L)$f$, :'r2', pg_temp.zeit(15), :jetzt),
                 'SL013', null, '3a echtes Kind: Zusatztermin zum Testkonto -> SL013');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', %L)$f$, :'r2', pg_temp.zeilen('1:15:woechentlich'), :jetzt),
                 'SL013', null, '3a echtes Kind: Stammplatz zum Testkonto -> SL013');
select is(slots_zusatz_code(:'r2', '2027-11-15', pg_temp.zeit(15), :jetzt), 'SL013', '3a slots_zusatz_code liefert SL013');
select is((select (c ->> 'art_konflikt')::boolean from jsonb_array_elements(slots_frei('woechentlich', '2027-11-01', :'r2', :jetzt) -> 'zellen') c
            where (c ->> 'wochentag')::int = 1 and c ->> 'zeit_id' = pg_temp.zeit(15)::text),
          true, '3a slots_frei: Zelle Mo 15 für das echte Kind mit art_konflikt');
select is((select (c ->> 'art_konflikt')::boolean from jsonb_array_elements(slots_frei('woechentlich', '2027-11-01', :'t2', :jetzt) -> 'zellen') c
            where (c ->> 'wochentag')::int = 1 and c ->> 'zeit_id' = pg_temp.zeit(15)::text),
          false, '3a slots_frei: dieselbe Zelle für ein Testkonto ohne Konflikt');
select ok(not exists (select 1 from jsonb_array_elements(slots_kandidaten('2027-11-22', pg_temp.zeit(15), :jetzt)) k
                       where not (k ->> 'ist_test')::boolean), '3a slots_kandidaten: kein echtes Kind für den Testtermin');
select ok(exists (select 1 from jsonb_array_elements(slots_kandidaten('2027-11-22', pg_temp.zeit(15), :jetzt)) k
                   where k ->> 'student_id' = :'t2'), '3a slots_kandidaten: ein Testkonto schon');
-- b) Echtes Kind zuerst (Rita Di 16), dann Testkonto
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-11-16', %L, %L)$f$, :'t2', pg_temp.zeit(16), :jetzt),
                 'SL013', null, '3b Testkonto: Zusatztermin zum echten Kind -> SL013');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', %L)$f$, :'t2', pg_temp.zeilen('2:16:woechentlich'), :jetzt),
                 'SL013', null, '3b Testkonto: Stammplatz zum echten Kind -> SL013');
select is(slots_planbilanz_vorschau(:'t2', pg_temp.zeilen('2:16:woechentlich'), '2027-11-01', null, :jetzt) -> 'gruende' -> 0 ->> 'code',
          'SL013', '3b Vorschau nennt SL013 als Sperrgrund');
select throws_ok(format($f$select stammplatz_aendern(%L, '2027-11-08', 1, %L, 'woechentlich', %L)$f$,
                        (select id from stammplaetze where student_id = :'r1'), pg_temp.zeit(15), :jetzt),
                 'SL013', null, '3b echtes Kind: Stammplatz ändern auf den Testtermin -> SL013');
select throws_ok(format($f$select termin_umbuchen(%L, %L, '2027-11-15', %L, %L)$f$,
                        pg_temp.termin(:'r1', '2027-11-09'), :jetzt, pg_temp.zeit(15), :jetzt),
                 'SL013', null, '3b echtes Kind: Umbuchung zum Testkonto -> SL013');
-- c) Umbuchen in einen Termin der anderen Art
select throws_ok(format($f$select termin_umbuchen(%L, %L, '2027-11-16', %L, %L)$f$,
                        pg_temp.termin(:'t1', '2027-11-15'), :jetzt, pg_temp.zeit(16), :jetzt),
                 'SL013', null, '3c Testkonto: Umbuchung zum echten Kind -> SL013');
-- d) Absage zurücknehmen, wenn inzwischen ein Kind der anderen Art dort sitzt
select lives_ok(format($f$select zusatztermin_buchen(%L, '2027-11-17', %L, %L)$f$, :'t3', pg_temp.zeit(17), :jetzt),
                '3d Testkonto: Zusatztermin Mi 17.11. 17 Uhr');
select lives_ok(format($f$select termin_absagen(%L, %L, %L)$f$, pg_temp.termin(:'t3', '2027-11-17'), :jetzt, :jetzt),
                '3d Testkonto sagt rechtzeitig ab');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2027-11-17', %L, %L)$f$, :'r2', pg_temp.zeit(17), :jetzt),
                '3d echtes Kind bucht den frei gewordenen Termin');
select throws_ok(format($f$select absage_zuruecknehmen(%L, %L)$f$, pg_temp.termin(:'t3', '2027-11-17'), :jetzt),
                 'SL013', null, '3d Rücknahme der Absage -> SL013');

-- ── 4) Festschreiben ─────────────────────────────────────────────────────────────────────────
select (termin_session_anlegen('2027-11-15', pg_temp.zeit(15), pg_temp.raum('Raum 1'), '2027-11-15 12:00 Europe/Berlin') ->> 'session_id') as s_test \gset
select is((select testlauf from coaching_sessions where id = :'s_test'), true, '4 nur Testkonten -> Session als Testlauf');
select is((select count(*)::int from session_students where session_id = :'s_test' and student_id = :'t1'), 1,
          '4 das Testkonto ist in der Testlauf-Session gebucht');
select (termin_session_anlegen('2027-11-16', pg_temp.zeit(16), pg_temp.raum('Raum 1'), '2027-11-16 12:00 Europe/Berlin') ->> 'session_id') as s_echt \gset
select is((select testlauf from coaching_sessions where id = :'s_echt'), false, '4 mit echtem Kind -> kein Testlauf (unverändert)');
select (termin_session_anlegen('2027-11-11', pg_temp.zeit(18), pg_temp.raum('Raum 2'), '2027-11-11 12:00 Europe/Berlin') ->> 'session_id') as s_do \gset
select is((select testlauf from coaching_sessions where id = :'s_do'), true, '4 Raum 2 mit fünf Testkonten -> Testlauf');
-- Auch nach der Absage aller Testkonten nimmt der Testtermin kein echtes Kind (Session zählt).
select lives_ok(format($f$select termin_absagen(%L, '2027-11-15 11:00 Europe/Berlin', '2027-11-15 12:00 Europe/Berlin')$f$,
                       pg_temp.termin(:'t1', '2027-11-15')), '4 Testkonto sagt den Testtermin ab');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-11-15', %L, '2027-11-15 12:00 Europe/Berlin')$f$, :'rz', pg_temp.zeit(15)),
                 'SL013', null, '4 echtes Kind in einen Termin mit Testlauf-Session -> SL013');
-- Raum 2 ohne Kinder: Die Session richtet sich nach der Testlauf-Session in Raum 1.
select (termin_session_anlegen('2027-11-15', pg_temp.zeit(15), pg_temp.raum('Raum 2'), '2027-11-15 12:00 Europe/Berlin') ->> 'session_id') as s_leer \gset
select is((select testlauf from coaching_sessions where id = :'s_leer'), true, '4 leerer Raum im Testtermin -> ebenfalls Testlauf');
-- Systemaufruf (fester Tag über p_jetzt): Der Trigger lässt testlauf beim Anlegen nur dem Admin, die Funktion meldet es.
select pg_temp.als_system();
select throws_ok(format($f$select termin_session_anlegen('2027-11-11', %L, %L, '2027-11-11 12:00 Europe/Berlin')$f$,
                        pg_temp.zeit(18), pg_temp.raum('Raum 1')),
                 '42501', 'termin_session_anlegen: Testtermin, nur Admin', '4 Systemaufruf: Testtermin festschreiben -> 42501 testlauf_nur_admin');
select pg_temp.als(:'admin');
-- Coach am Tag: Seit T5 legt der eingeteilte Coach den Testtermin selbst als Testlauf an (Systemweg im Trigger;
-- vorher 42501 testlauf_nur_admin). Nur an Betriebstagen prüfbar; weitere Fälle in session_t5.test.sql.
select pg_temp.kind('Tag Test', 'Basic', 12, date_trunc('month', current_date)::date,
                     (date_trunc('month', current_date) + interval '12 months' - interval '1 day')::date) as ttag \gset
update students set ist_test = true where id = :'ttag';
insert into kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft)
select :'ttag', pg_temp.vertrag(:'ttag'), public.slots_berlin_tag(now()), pg_temp.zeit(19), 'zusatz'
 where public.betriebstag(public.slots_berlin_tag(now()));
select pg_temp.als(:'coach_a');
select case when public.betriebstag(public.slots_berlin_tag(now()))
            then lives_ok(format('select termin_session_anlegen(%L, %L, %L)', public.slots_berlin_tag(now()), pg_temp.zeit(19),
                                 pg_temp.raum('Raum 1')),
                          '4 Coach: Testtermin festschreiben -> Testlauf (T5, vorher 42501 testlauf_nur_admin)')
            else skip('heute kein Betriebstag', 1) end;
select pg_temp.als(:'admin');

-- ── 5) Werkzeug ──────────────────────────────────────────────────────────────────────────────
-- Ausgangslage: Testkonten mit Stammplätzen (Tina, zehn Do 18) und einem Zusatztermin (Tilo ist abgesagt,
-- Toni bekommt einen); Rita, Rolf, Rosa sind echt.
select lives_ok(format($f$select zusatztermin_buchen(%L, '2027-12-01', %L, %L)$f$, :'t11', pg_temp.zeit(14), :jetzt),
                '5 Testkonto: Zusatztermin Mi 01.12. 14 Uhr');
create temp table vorher_echt as
select id, zustand, datum, slot_zeit_id from kind_termine kt
 where not exists (select 1 from students s where s.id = kt.student_id and s.ist_test);
create temp table vorher_alle as select * from kind_termine;
create temp table vorher_sp as select * from stammplaetze;

\set trocken on
\ir ../../tools/slots-testkonten-raeumen.sql
select is((select count(*)::int from (select * from kind_termine except select * from vorher_alle) x), 0,
          '5 trocken: kind_termine unverändert');
select is((select count(*)::int from (select * from stammplaetze except select * from vorher_sp) x), 0,
          '5 trocken: stammplaetze unverändert');

\set trocken off
\set als_system 1
\ir ../../tools/slots-testkonten-raeumen.sql
select is((select count(*)::int from stammplaetze s join students st on st.id = s.student_id and st.ist_test
            where coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_berlin_tag(now())
              and s.gueltig_bis is distinct from s.gueltig_ab - 1), 0, '5 keine laufenden Stammplätze von Testkonten');
select is((select count(*)::int from kind_termine kt join students st on st.id = kt.student_id and st.ist_test
            where kt.zustand = 'planned' and kt.session_id is null
              and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > now()), 0,
          '5 keine künftigen offenen Termine von Testkonten');
select is((select zustand from kind_termine where id = pg_temp.termin(:'t11', '2027-12-01')), 'cancelled_by_us',
          '5 Zusatztermin eines Testkontos: ausgefallen durch uns');
select is((select count(*)::int from kind_termine where student_id = :'t1' and herkunft = 'stammplatz' and zustand = 'planned'
             and session_id is null and public.slots_termin_beginn(datum, slot_zeit_id) > now()), 0,
          '5 bewegliche Stammplatz-Termine des Testkontos sind entfernt');
select is((select count(*)::int from kind_termine where session_id = :'s_test'), 1,
          '5 festgeschriebener Testtermin bleibt');
select set_eq('select id, zustand, datum, slot_zeit_id from kind_termine kt
                where not exists (select 1 from students s where s.id = kt.student_id and s.ist_test)',
              'select id, zustand, datum, slot_zeit_id from vorher_echt',
              '5 Termine echter Kinder unberührt');

select * from finish();
rollback;
