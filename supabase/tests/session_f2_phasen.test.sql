-- ============================================================================
-- F2: Phasen folgen den Kindern, nicht der Uhr (Trockenlauf 10.10.2026, offene-punkte-f2).
--
-- Beweis ohne Migration: Die Engine wechselt die Phase eines Kindes, sobald sie fuer das Kind abgeschlossen ist.
-- now() steht in der Transaktion still; pg_temp.uhr legt fest, was session_uhr_phase zeigt.
--
--   C  Check-in am Tablet gespeichert -> der naechste Schritt kommt sofort, obwohl die Uhr noch Check-in zeigt.
--   W  Nach warmup_aufgaben Aufgaben im Warm-up -> Kernarbeit, obwohl die Uhr noch Check-in bzw. Warm-up zeigt.
--   O  Ohne Warm-up-Stoff -> sofort Kernarbeit (Uhr Check-in).
--   T  Nachgestellt 10.10.: Testkonto, kein Testlauf, nur Entwuerfe -> warten/pool_leer in der Kernarbeit,
--      sofort nach dem Check-in. Dieselbe Lage im Testlauf -> Kernarbeit mit Stoff.
--   K  Coach-Sicht: coach_raum_live meldet je Kind seine Phase, unabhaengig von der Uhr.
-- Nur Session-Aufrufe wie in den bestehenden Tests; keine Funktion wird geaendert.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(23);

\ir session_a2_fixture.sql

select pg_temp.stell('phase_checkin_min', '5');
select pg_temp.stell('phase_warmup_min', '10');
select pg_temp.stell('warmup_aufgaben', '3');

-- ── C, W: Testlauf mit Stoff, Uhr bei 0 Minuten (Check-in) ─────────────────
select pg_temp.kind_mit('ZZ Eva F2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{}', true) as k_e \gset
select pg_temp.neue_session(array[:'k_e']::uuid[], 0, true) as s1 \gset

select is(session_uhr_phase(:'s1'), 'checkin', 'C Uhr zeigt Check-in');
select is(pg_temp.schritt(:'s1', 1) ->> 'grund_code', 'checkin_laeuft', 'C vor dem Speichern: Check-in laeuft');
select pg_temp.checkin(:'s1', 1);
select pg_temp.schritt(:'s1', 1) as c1 \gset
select is(:'c1'::jsonb ->> 'art', 'aufgabe', 'C nach dem Speichern sofort eine Aufgabe');
select is(:'c1'::jsonb ->> 'phase', 'warmup', 'C sofort Warm-up, nicht erst nach 5 Minuten');
select is(session_uhr_phase(:'s1'), 'checkin', 'C die Uhr zeigt dabei weiter Check-in');

select pg_temp.antwort(:'s1', 1, true);
select pg_temp.loese(:'s1', 1, true);
select pg_temp.loese(:'s1', 1, true);
select is((select count(*)::int from session_schritte where session_id = :'s1' and phase = 'warmup' and art = 'aufgabe'),
          session_wert_zahl(:'s1', 'warmup_aufgaben')::int, 'W warmup_aufgaben Warm-up-Aufgaben ausgegeben');
select pg_temp.schritt(:'s1', 1) as w1 \gset
select is(:'w1'::jsonb ->> 'phase', 'kern', 'W danach Kernarbeit');
select isnt(:'w1'::jsonb ->> 'art', 'warten', 'W Kernarbeit mit Stoff, kein Warten');
select is(session_uhr_phase(:'s1'), 'checkin', 'W die Uhr zeigt dabei noch Check-in');

select pg_temp.act_as(:'coach_a');
select is((select k ->> 'phase' from jsonb_array_elements(coach_raum_live(:'s1') -> 'kinder') k), 'kern',
          'K coach_raum_live: Kind in der Kernarbeit, Uhr Check-in');

-- ── W: Uhr zeigt Warm-up (Minute 6) ────────────────────────────────────────
select pg_temp.kind_mit('ZZ Finn F2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{}', true) as k_f \gset
select pg_temp.neue_session(array[:'k_f']::uuid[], 6, true) as s2 \gset
select is(session_uhr_phase(:'s2'), 'warmup', 'W Uhr zeigt Warm-up');
select pg_temp.checkin(:'s2', 1);
select is(pg_temp.loese(:'s2', 1, true) ->> 'phase', 'warmup', 'W erste Aufgabe im Warm-up');
select pg_temp.loese(:'s2', 1, true);
select pg_temp.loese(:'s2', 1, true);
select is(pg_temp.schritt(:'s2', 1) ->> 'phase', 'kern', 'W nach drei Aufgaben Kernarbeit');
select is(session_uhr_phase(:'s2'), 'warmup', 'W die Uhr zeigt dabei noch Warm-up');

-- ── O: ohne Warm-up-Stoff (keine sicheren Skills) ──────────────────────────
select pg_temp.kind_mit('ZZ Ole F2', 'zz_a2_terme', '{}', '{}', true) as k_o \gset
select pg_temp.neue_session(array[:'k_o']::uuid[], 0, true) as s3 \gset
select pg_temp.checkin(:'s3', 1);
select pg_temp.schritt(:'s3', 1) as o1 \gset
select is(:'o1'::jsonb ->> 'phase', 'kern', 'O ohne Stoff sofort Kernarbeit');
select isnt(:'o1'::jsonb ->> 'art', 'warten', 'O Kernarbeit mit Stoff');
select is((select count(*)::int from session_schritte where session_id = :'s3' and phase = 'warmup'), 0,
          'O kein Warm-up-Schritt');
select is(session_uhr_phase(:'s3'), 'checkin', 'O die Uhr zeigt dabei Check-in');
select pg_temp.act_as(:'coach_a');
select is((select k ->> 'phase' || '/' || (k ->> 'warmup_entfallen')
             from jsonb_array_elements(coach_raum_live(:'s3') -> 'kinder') k), 'kern/kein_stoff',
          'K coach_raum_live: Kernarbeit, Warm-up entfallen (kein Stoff)');

-- ── T: Lage vom 10.10. — Testkonto, nur Entwuerfe ──────────────────────────
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_f2_d', 'ZZ Prozentwert', 7, 1);
insert into themen (thema_key, fach, klasse, stufe, label, sort)
values ('zz_f2_entwurf', 'mathematik', 7, 'erste', 'ZZ Prozentrechnung', 9301);
insert into thema_einstieg (thema_key, skill_key) values ('zz_f2_entwurf', 'zz_f2_d');
insert into skill_thema (skill_key, thema_key) values ('zz_f2_d', 'zz_f2_entwurf');
select pg_temp.aufgaben('zz_f2_d', 6, 'draft');

select pg_temp.kind_mit('ZZ Tom F2', 'zz_f2_entwurf', '{}', '{}', true) as k_t \gset
select pg_temp.neue_session(array[:'k_t']::uuid[], 0, false) as s4 \gset
select pg_temp.checkin(:'s4', 1);
select pg_temp.schritt(:'s4', 1) as t1 \gset
select is(:'t1'::jsonb ->> 'art' || '/' || (:'t1'::jsonb ->> 'phase') || '/' || (:'t1'::jsonb ->> 'grund_code'),
          'warten/kern/pool_leer', 'T kein Testlauf: sofort Kernarbeit, aber warten (pool_leer)');
select is(session_uhr_phase(:'s4'), 'checkin', 'T die Uhr zeigt dabei Check-in');

select pg_temp.kind_mit('ZZ Uta F2', 'zz_f2_entwurf', '{}', '{}', true) as k_u \gset
select pg_temp.neue_session(array[:'k_u']::uuid[], 0, true) as s5 \gset
select pg_temp.checkin(:'s5', 1);
select pg_temp.schritt(:'s5', 1) as t2 \gset
select is(:'t2'::jsonb ->> 'phase', 'kern', 'T Testlauf: Kernarbeit');
select isnt(:'t2'::jsonb ->> 'grund_code', 'pool_leer', 'T Testlauf: Entwuerfe im Pool, kein Warten');

select * from finish();
rollback;
