-- ============================================================================
-- A2c: Erklaersequenz vom Tablet ohne student_id, hinweis_abrufen mit 'weitere'
-- (Migrationen 20261010100426, 20261010100731, 20261010100855; Datenvertrag Abschnitt 8.2).
--
-- Zusagen (Nummern wie im Auftrag):
--   1) Tablet ohne p_student_id: erklaer_start, erklaer_check_abgeben, erklaer_nachlesen laufen fuer das
--      eigene Kind (und nur dafuer).
--   2) Fremdes Tablet, fremdes Kind, Schuelerkonto in fremder Session, Coach ohne Kind, Konto ohne Profil,
--      geloester Platz -> 42501.
--   3) Schuelerkonto zuhause (erklaer_nachlesen mit eigener id), Tablet mit eigener id und Coach-Vorschau
--      unveraendert.
--   4) X0b-Waechter: laeuft in session_x0b.test.sql.
--   H) hinweis_abrufen: 'weitere' bis hinweisstufen, danach 22023 mit hint stufe_gesperrt.
--   T) Nachtrag R2, tablet_stand ohne Zuweisung: Platz-Konto bekommt seine Nummer (Geraet ohne Nummer null);
--      Schuelerkonto, Coach, Konto ohne Profil keine; ein zugewiesenes Tablet wie bisher.
-- Inhalte der Sequenz: Fixture aus session_e1 (fkt_linear_steigung, drei Kernideen, Varianten A und B).
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(52);

\ir session_a2_fixture.sql
\ir session_e1_fixture.sql

-- SQLSTATE und Hint eines Aufrufs ("kein Fehler", sonst "<state>:<hint>").
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text; h text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate, h = pg_exception_hint;
  return s || ':' || coalesce(h, '');
end $$;

select pg_temp.kind_mit('ZZ Lina A2c', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k1,
       pg_temp.kind_mit('ZZ Ben A2c', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k2
\gset
select pg_temp.neue_session(array[:'k1', :'k2']::uuid[], 1) as s \gset
select pg_temp.checkin(:'s', 1), pg_temp.checkin(:'s', 2);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s', :'k1', 'schulthema'), checkin_coach_setzen(:'s', :'k2', 'schulthema');
select pg_temp.uhr(:'s', 20);

-- ── H) hinweis_abrufen: weitere ────────────────────────────────────────────
select pg_temp.schritt_tablet(:'s', 1) as h1 \gset
select is(:'h1'::jsonb ->> 'hinweise_erlaubt', 'true', 'H Aufgabe der Kernarbeit, Hinweise erlaubt');
select is(hinweis_abrufen(:'s', (:'h1'::jsonb ->> 'task_id')::uuid, 1) - 'text',
          '{"stufe":1,"verfuegbar":true,"weitere":true}'::jsonb, 'H Stufe 1: geliefert, weitere = true');
select is(hinweis_abrufen(:'s', (:'h1'::jsonb ->> 'task_id')::uuid, 2) ->> 'weitere', 'true',
          'H Stufe 2 von 3 (ohne Text): weitere = true');
select is(hinweis_abrufen(:'s', (:'h1'::jsonb ->> 'task_id')::uuid, 3) ->> 'weitere', 'false',
          'H Stufe 3 = hinweisstufen: weitere = false');
select is(pg_temp.fehler(format('select hinweis_abrufen(%L, %L, 4)', :'s', :'h1'::jsonb ->> 'task_id')),
          '22023:stufe_gesperrt', 'H Stufe 4: 22023 mit hint stufe_gesperrt');

-- ── 1) Tablet ohne p_student_id ────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select erklaer_start(:'s', null, 'fkt_linear_steigung') as st \gset
select is(:'st'::jsonb ->> 'aktion', 'start', '1 erklaer_start ohne Kind: aktion start');
select is(:'st'::jsonb -> 'check' ->> 'task_id', :'check1', '1 erklaer_start: Check der Kernidee 1');
select is((select array_agg(distinct student_id) from erklaer_fortschritt where session_id = :'s'),
          array[:'k1'::uuid], '1 erklaer_start schreibt fuer das Kind von Tablet 1');
select is(erklaer_start(:'s', null, 'fkt_linear_steigung') -> 'check', :'st'::jsonb -> 'check',
          '1 zweiter Start ohne Kind nimmt dieselbe Stelle wieder auf');
select is(pg_temp.fehler(format($$select erklaer_check_abgeben(%L, null, %L, '{"text":"2"}')$$, :'s', :'check2')),
          'P0001:', '1 erklaer_check_abgeben ohne Kind: fremder Check -> P0001 (normale Pruefung greift)');
select erklaer_check_abgeben(:'s', null, :'check1', '{"text":"7"}') as c1 \gset
select is(:'c1'::jsonb ->> 'aktion', 'variante', '1 falscher Check ohne Kind -> variante');
select is(:'c1'::jsonb ->> 'variante', 'B', '1 falscher Check: Variante B');
select erklaer_check_abgeben(:'s', null, :'check1', '{"text":"2"}') as c2 \gset
select is(:'c2'::jsonb ->> 'aktion', 'weiter', '1 richtiger Check ohne Kind -> weiter');
select is(:'c2'::jsonb -> 'kernidee' ->> 'nr', '2', '1 richtiger Check: Kernidee 2');
select is((select array_agg(ergebnis order by id) from erklaer_fortschritt where session_id = :'s' and student_id = :'k1'),
          array['gezeigt', 'falsch', 'gezeigt', 'richtig', 'gezeigt'], '1 Fortschritt des Kindes von Tablet 1');
select is((select count(*)::int from session_ereignisse where session_id = :'s' and typ = 'check' and student_id = :'k1'), 2,
          '1 Check-Ereignisse fuer das Kind von Tablet 1');
select is(jsonb_array_length(erklaer_nachlesen(null, 'fkt_linear_steigung') -> 'kernideen'), 3,
          '1 erklaer_nachlesen ohne Kind: drei Kernideen');
select is(erklaer_nachlesen(null, 'fkt_linear_steigung'), erklaer_nachlesen(:'k1', 'fkt_linear_steigung'),
          '1 erklaer_nachlesen ohne Kind = mit dem Kind des Tablets');
select ok(erklaer_nachlesen(null, 'fkt_linear_steigung')::text !~ '"check"|LOESUNG-E1|ENTWURF-E1|Variante B',
          '1 erklaer_nachlesen ohne Kind: nur Variante A, keine Checks, kein Entwurf');
select pg_temp.act_as(pg_temp.tablet(2));
select is((erklaer_start(:'s', null, 'fkt_linear_steigung')) -> 'kernidee' ->> 'nr', '1',
          '1 Tablet 2 ohne Kind: eigene Sequenz ab Kernidee 1');
select is((select count(*)::int from erklaer_fortschritt where session_id = :'s' and student_id = :'k2'), 1,
          '1 Tablet 2 schreibt fuer sein eigenes Kind');

-- ── 2) 42501 ───────────────────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(5));
select throws_ok(format($$select erklaer_start(%L, null, 'fkt_linear_steigung')$$, :'s'), '42501', null,
                 '2 erklaer_start: Tablet ohne Platz');
select throws_ok(format($$select erklaer_check_abgeben(%L, null, %L, '{"text":"2"}')$$, :'s', :'check2'), '42501', null,
                 '2 erklaer_check_abgeben: Tablet ohne Platz');
select throws_ok($$select erklaer_nachlesen(null, 'fkt_linear_steigung')$$, '42501', null,
                 '2 erklaer_nachlesen: Tablet ohne Platz');
select pg_temp.act_as(pg_temp.tablet(2));
select throws_ok(format($$select erklaer_start(%L, %L, 'fkt_linear_steigung')$$, :'s', :'k1'), '42501', null,
                 '2 erklaer_start: Tablet 2 nennt das Kind von Tablet 1');
select throws_ok(format($$select erklaer_check_abgeben(%L, %L, %L, '{"text":"0,5"}')$$, :'s', :'k1', :'check2'), '42501', null,
                 '2 erklaer_check_abgeben: Tablet 2 nennt das Kind von Tablet 1');
select throws_ok(format($$select erklaer_nachlesen(%L, 'fkt_linear_steigung')$$, :'k1'), '42501', null,
                 '2 erklaer_nachlesen: Tablet 2 nennt das Kind von Tablet 1');
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($$select erklaer_start(%L, null, 'fkt_linear_steigung')$$, :'s'), '42501', null,
                 '2 erklaer_start: Schuelerkonto ohne Kind in fremder Session');
select throws_ok(format($$select erklaer_start(%L, %L, 'fkt_linear_steigung')$$, :'s', :'kind_id'), '42501', null,
                 '2 erklaer_start: Schuelerkonto mit eigener id in fremder Session');
select throws_ok(format($$select erklaer_check_abgeben(%L, null, %L, '{"text":"0,5"}')$$, :'s', :'check2'), '42501', null,
                 '2 erklaer_check_abgeben: Schuelerkonto ohne Kind in fremder Session');
select throws_ok($$select erklaer_nachlesen(null, 'fkt_linear_steigung')$$, '42501', null,
                 '2 erklaer_nachlesen: Schuelerkonto ohne Kind (kein Tablet)');
select pg_temp.act_as(:'ohne');
select throws_ok(format($$select erklaer_start(%L, null, 'fkt_linear_steigung')$$, :'s'), '42501', null,
                 '2 erklaer_start: Konto ohne Profil');
select throws_ok(format($$select erklaer_check_abgeben(%L, null, %L, '{"text":"0,5"}')$$, :'s', :'check2'), '42501', null,
                 '2 erklaer_check_abgeben: Konto ohne Profil');
select throws_ok($$select erklaer_nachlesen(null, 'fkt_linear_steigung')$$, '42501', null,
                 '2 erklaer_nachlesen: Konto ohne Profil');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$select erklaer_start(%L, null, 'fkt_linear_steigung')$$, :'s'), '42501', null,
                 '2 erklaer_start: Coach ohne Kind (kein Tablet)');
select is((select count(*)::int from erklaer_fortschritt where session_id = :'s'), 6,
          '2 abgewiesene Aufrufe schreiben nichts');

-- ── 3) unveraendert ───────────────────────────────────────────────────────
select pg_temp.act_as(:'kind_uid');
select is(jsonb_array_length(erklaer_nachlesen(:'kind_id', 'fkt_linear_steigung') -> 'kernideen'), 3,
          '3 Schuelerkonto zuhause: erklaer_nachlesen mit eigener id');
select pg_temp.act_as(pg_temp.tablet(1));
select is((erklaer_start(:'s', :'k1', 'fkt_linear_steigung')) -> 'kernidee' ->> 'nr', '2',
          '3 Tablet mit eigener id: wie bisher (Wiederaufnahme Kernidee 2)');
select pg_temp.act_as(:'coach_a');
select is((session_naechster_schritt(:'s', :'k1')) ->> 'vorschau', 'true', '3 Coach-Vorschau session_naechster_schritt');
select is((erklaer_start(:'s', :'k2', 'fkt_linear_steigung')) -> 'kernidee' ->> 'nr', '1',
          '3 Coach der Session mit Kind: erklaer_start wie bisher');
select is(jsonb_array_length(erklaer_nachlesen(:'k1', 'fkt_linear_steigung') -> 'kernideen'), 3,
          '3 Coach der Session: erklaer_nachlesen mit Kind wie bisher');
select pg_temp.act_as(:'coach_uid');
select is((erklaer_start(:'session_id', :'kind_id', 'fkt_linear_steigung')) ->> 'aktion', 'start',
          '3 E1: Coach mit Kind in seiner Session wie bisher');

-- Platz geloest: das Tablet hat kein Kind mehr.
select pg_temp.act_as(:'coach_a');
select tablet_loesen(:'s', :'k1');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select erklaer_start(%L, null, 'fkt_linear_steigung')$$, :'s'), '42501', null,
                 '2 erklaer_start: Platz geloest');
select throws_ok($$select erklaer_nachlesen(null, 'fkt_linear_steigung')$$, '42501', null,
                 '2 erklaer_nachlesen: Platz geloest');
select pg_temp.act_as(pg_temp.tablet(2));
select is(jsonb_array_length(erklaer_nachlesen(null, 'fkt_linear_steigung') -> 'kernideen'), 3,
          '1 Tablet 2 behaelt seinen Platz und liest weiter nach');

-- ── T) tablet_stand ohne Zuweisung (Nachtrag R2) ───────────────────────────
insert into auth.users (id, email, instance_id, aud, role)
values ('a2c00000-0000-4000-8000-0000000000f0', 'a2c-ohne-nr@test.local', '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name)
values ('a2c00000-0000-4000-8000-0000000000f0', 'a2c-ohne-nr@test.local', 'student', 'A2c Geraet ohne Nummer');
insert into platz_devices (profile_id, label) values ('a2c00000-0000-4000-8000-0000000000f0', 'ZZ A2c ohne Nummer');
select pg_temp.act_as(pg_temp.tablet(5));
select is(tablet_stand(), '{"zugewiesen":false,"tablet_nr":5}'::jsonb, 'T Platz-Konto ohne Zuweisung: eigene Nummer');
select pg_temp.act_as(pg_temp.tablet(1));
select is(tablet_stand(), '{"zugewiesen":false,"tablet_nr":1}'::jsonb, 'T Platz geloest: wieder nur die eigene Nummer');
select pg_temp.act_as('a2c00000-0000-4000-8000-0000000000f0');
select is(tablet_stand(), '{"zugewiesen":false,"tablet_nr":null}'::jsonb, 'T Geraet ohne Nummer: tablet_nr null');
select pg_temp.act_as(:'kind_uid');
select is(tablet_stand(), '{"zugewiesen":false}'::jsonb, 'T Schuelerkonto: keine Nummer');
select pg_temp.act_as(:'coach_a');
select is(tablet_stand(), '{"zugewiesen":false}'::jsonb, 'T Coach: keine Nummer');
select pg_temp.act_as(:'ohne');
select is(tablet_stand(), '{"zugewiesen":false}'::jsonb, 'T Konto ohne Profil: keine Nummer');
select pg_temp.act_as(pg_temp.tablet(2));
select is((select array_agg(k order by k) from jsonb_object_keys(tablet_stand()) k)
            || array[tablet_stand() ->> 'session_id', tablet_stand() ->> 'tablet_nr'],
          array['aufgabe', 'bestaetigt', 'checkin_fertig', 'phase', 'pruefung', 'session_id', 'tablet_nr', 'vorname',
                'zugewiesen', :'s', '2'], 'T zugewiesenes Tablet wie bisher (Felder, Session, Nummer)');

select * from finish();
rollback;
