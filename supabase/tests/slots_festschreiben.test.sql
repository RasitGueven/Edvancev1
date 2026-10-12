-- ============================================================================
-- Slots SL1 — Festschreiben und "nach dem Festschreiben" (Bauauftrag Slots, Tests 7, 14 und 9;
-- Entscheidung 14).
--
--   7) termin_session_anlegen: idempotent, nur am Tag, Coach nur eigener Raum. Absage nach dem
--      Festschreiben setzt beide Tabellen. "nicht erschienen" landet als unexcused in kind_termine.
--  14) Coach tauschen zieht coach_id nach, die Vertretung liest die Session. Raum setzen verschiebt die
--      Buchung zwischen zwei Sessions. Nach gestartet_am -> SL011 (Absage geht noch).
--   9) Ein gekündigtes Kind im Raum: die Session entsteht, nur dieses Kind wird ausgelassen.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set d '''2027-11-16'''
\set jetzt '''2027-11-16 12:00 Europe/Berlin'''

-- Sechs Kinder (Mathematik) Di 16 Uhr ab 01.11.2027: fünf in Raum 1, das sechste in Raum 2.
create temp table di16 as
select n, pg_temp.kind('Di' || n || ' Kind', 'Basic', 12, '2027-09-01', '2028-08-31') as student from generate_series(1, 6) n;
select count(*) from di16, lateral stammplatz_vergeben(student, pg_temp.zeilen('2:16:woechentlich'), '2027-11-01',
                                                       '2027-11-01 08:00 Europe/Berlin') x;
select student as k1 from di16 where n = 1 \gset
select student as k2 from di16 where n = 2 \gset
select student as k3 from di16 where n = 3 \gset

-- ── 7) idempotent, nur am Tag ────────────────────────────────────────────────
select termin_session_anlegen(:d, pg_temp.zeit(16), pg_temp.raum('Raum 1'), :jetzt) as f1 \gset
select is((:'f1'::jsonb ->> 'neu')::boolean, true, '7 erster Aufruf legt die Session an');
select is(termin_session_anlegen(:d, pg_temp.zeit(16), pg_temp.raum('Raum 1'), :jetzt) ->> 'session_id', :'f1'::jsonb ->> 'session_id',
          '7 zweiter Aufruf liefert dieselbe Session (idempotent)');
select (:'f1'::jsonb ->> 'session_id') as s1 \gset
select results_eq(format('select coach_id, room, scheduled_at from coaching_sessions where id = %L', :'s1'),
                  format($$values (%L::uuid, 'Raum 1'::text, timestamptz '2027-11-16 16:00 Europe/Berlin')$$, :'coach_a'),
                  '7 Session trägt Coach, Raumname und Beginn (Berlin)');
select is((select count(*)::int from session_students where session_id = :'s1'), 5, '7 die fünf Kinder des Raums sind gebucht');
select is((select count(*)::int from kind_termine where datum = :d and session_id = :'s1'), 5, '7 kind_termine.session_id ist gesetzt');
select throws_ok(format($f$select termin_session_anlegen(%L, %L, %L, '2027-11-15 12:00 Europe/Berlin')$f$, :d, pg_temp.zeit(16),
                        pg_temp.raum('Raum 2')), '22023', null, '7 nur am Tag des Termins (Admin, Vortag)');
select termin_session_anlegen(:d, pg_temp.zeit(16), pg_temp.raum('Raum 2'), :jetzt) ->> 'session_id' as s2 \gset
select is((select count(*)::int from session_students where session_id = :'s2'), 1, '7 Raum 2: das sechste Kind ist dort gebucht');

-- Coaches rechnen immer mit now(). Damit der Test an jedem Tag läuft, gelten heute und morgen (Berlin)
-- in dieser Transaktion als Betriebstag; Raum 3 ist dort per Abweichung mit Coach Cem geöffnet.
create or replace function public.betriebstag(p_datum date) returns boolean language sql stable security definer
set search_path = public, pg_temp as $$
  select p_datum between (now() at time zone 'Europe/Berlin')::date and (now() at time zone 'Europe/Berlin')::date + 1
      or (extract(isodow from p_datum) between 1 and 5
          and not exists (select 1 from public.feiertage_nrw f where f.datum = p_datum)
          and not exists (select 1 from public.ferien_nrw f where p_datum between f.von and f.bis));
$$;
select (now() at time zone 'Europe/Berlin')::date as heute \gset
select termin_raum_oeffnen(:'heute', pg_temp.zeit(19), pg_temp.raum('Raum 3'), :'coach_c') is not null;
select termin_raum_oeffnen((:'heute'::date + 1), pg_temp.zeit(19), pg_temp.raum('Raum 3'), :'coach_c') is not null;
select pg_temp.als(:'coach_b');
select throws_ok(format('select termin_session_anlegen(%L, %L, %L)', :'heute', pg_temp.zeit(19), pg_temp.raum('Raum 3')),
                 '42501', null, '7 Coach: fremder Raum -> 42501');
select pg_temp.als(:'coach_c');
select lives_ok(format('select termin_session_anlegen(%L, %L, %L)', :'heute', pg_temp.zeit(19), pg_temp.raum('Raum 3')),
                '7 Coach: eigener Raum am selben Tag -> Session');
select throws_ok(format('select termin_session_anlegen(%L, %L, %L, %L)', (:'heute'::date + 1), pg_temp.zeit(19), pg_temp.raum('Raum 3'),
                        ((:'heute'::date + 1) + time '12:00') at time zone 'Europe/Berlin'),
                 '22023', null, '7 Coach mit p_jetzt eines anderen Tages kann nicht festschreiben (p_jetzt gilt nicht)');
select pg_temp.als(:'admin');

-- Absage nach dem Festschreiben setzt beide Tabellen.
select termin_absagen(pg_temp.termin(:'k1', :d), '2027-11-16 09:00 Europe/Berlin', :jetzt) is not null;
select results_eq(format($$select kt.zustand, ss.attendance from kind_termine kt
                           join session_students ss on ss.session_id = kt.session_id and ss.student_id = kt.student_id
                          where kt.id = %L$$, pg_temp.termin(:'k1', :d)),
                  $$values ('cancelled'::text, 'cancelled'::text)$$, '7 Absage nach dem Festschreiben: beide Tabellen abgesagt');

-- "nicht erschienen" in der Session landet als unexcused in kind_termine.
select pg_temp.als(:'coach_a');
select anwesenheit_setzen(:'s1', :'k2', 'unexcused') is not null;
select pg_temp.als(:'admin');
select is((select zustand from kind_termine where id = pg_temp.termin(:'k2', :d)), 'unexcused',
          '7 "nicht erschienen" -> kind_termine unexcused');

-- ── 14) Nach dem Festschreiben ───────────────────────────────────────────────
select termin_coach_setzen(:d, pg_temp.zeit(16), pg_temp.raum('Raum 1'), :'coach_c', :jetzt) is not null;
select is((select coach_id from coaching_sessions where id = :'s1'), :'coach_c'::uuid, '14 Coach tauschen zieht coach_id nach');
select pg_temp.als(:'coach_c');
select is(session_ist_coach(:'s1'), true, '14 die Vertretung ist Coach der Session');
set local role authenticated;
select is((select count(*)::int from coaching_sessions where id = :'s1'), 1, '14 die Vertretung liest die Session (RLS)');
reset role;
select pg_temp.als(:'admin');

select termin_raum_setzen(pg_temp.termin(:'k3', :d), pg_temp.raum('Raum 2'), :jetzt) is not null;
select results_eq(format($$select (select count(*)::int from session_students where session_id = %L and student_id = %L),
                                  (select count(*)::int from session_students where session_id = %L and student_id = %L),
                                  (select session_id from kind_termine where id = %L)$$,
                         :'s1', :'k3', :'s2', :'k3', pg_temp.termin(:'k3', :d)),
                  format('values (0, 1, %L::uuid)', :'s2'), '14 Raum setzen: Buchung von Session A nach Session B');

select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set gestartet_am = '2027-11-16 16:01 Europe/Berlin', status = 'active' where id = :'s2';
select set_config('edvance.session_rpc', '', true);
select throws_ok(format($f$select termin_raum_setzen(%L, %L, %L)$f$, pg_temp.termin(:'k3', :d), pg_temp.raum('Raum 1'), :'jetzt'),
                 'SL011', null, '14 nach gestartet_am: Raum gesperrt (SL011)');
select throws_ok(format($f$select termin_coach_setzen(%L, %L, %L, %L, %L)$f$, :d, pg_temp.zeit(16), pg_temp.raum('Raum 2'),
                        :'coach_d', :'jetzt'), 'SL011', null, '14 nach gestartet_am: Coach gesperrt (SL011)');
select throws_ok(format($f$select termin_coach_setzen(%L, %L, %L, null, %L)$f$, :d, pg_temp.zeit(16), pg_temp.raum('Raum 2'), :'jetzt'),
                 'SL011', null, '14 nach gestartet_am: Ausfall gesperrt (SL011)');
select lives_ok(format($f$select termin_absagen(%L, '2027-11-16 11:00 Europe/Berlin', %L)$f$, pg_temp.termin(:'k3', :d), :'jetzt'),
                '14 nach gestartet_am: eine Absage geht noch');

-- "fällt aus" vor dem Start löscht die Session (ohne Session-Daten) und schickt die Kinder zurück.
select termin_coach_setzen(:d, pg_temp.zeit(16), pg_temp.raum('Raum 1'), null, :jetzt) is not null;
select is((select count(*)::int from coaching_sessions where id = :'s1'), 0, '14 fällt aus vor dem Start: Session gelöscht');
select is((select count(*)::int from kind_termine where datum = :d and session_id = :'s1'), 0,
          '14 fällt aus: die Kinder sind wieder ohne Session (zurück in der Zuteilung)');

-- ── 9) Gekündigtes Kind im Raum ──────────────────────────────────────────────
-- Kündigung ist erfasst, die Planung aber (noch) nicht nachgezogen: termin_session_anlegen prüft selbst.
alter table vertraege disable trigger vertraege_slots_trg;
update vertraege set gekuendigt_zum = '2027-11-23', kuendigung_grund = 'Umzug' where id = pg_temp.vertrag(:'k1');
alter table vertraege enable trigger vertraege_slots_trg;
select termin_session_anlegen('2027-11-23', pg_temp.zeit(16), pg_temp.raum('Raum 1'), '2027-11-23 12:00 Europe/Berlin') as f9 \gset
select ok((:'f9'::jsonb ->> 'session_id') is not null, '9 die Session wird trotzdem angelegt');
select is((select jsonb_agg(x ->> 'student_id') from jsonb_array_elements(:'f9'::jsonb -> 'ausgelassen') x), jsonb_build_array(:'k1'),
          '9 nur das gekündigte Kind wird ausgelassen (Rückgabe nennt es)');
select is((select zustand from kind_termine where id = pg_temp.termin(:'k1', '2027-11-23')), 'cancelled_by_us',
          '9 sein Termin ist "ausgefallen durch uns"');
select is((select count(*)::int from session_students where session_id = (:'f9'::jsonb ->> 'session_id')::uuid), 4,
          '9 die übrigen Kinder des Raums sind gebucht');

select * from finish();
rollback;
