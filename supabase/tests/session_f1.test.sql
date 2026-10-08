-- ============================================================================
-- F1: Coach-Sicht aus dem Trockenlauf (08.10.2026) und Platzhalter-Erklaersequenz fuer das Szenario Batu
-- (Migrationen 20261011140000, 20261011140100; offene-punkte-f1).
--
-- Zusagen (Nummern wie im Auftrag):
--   1  A1 Thema waehlen ohne Schulthema (checkin_coach_setzen mit Fall Schulthema) setzt Fall und Ziel; der naechste
--        Schritt kommt aus dem neuen Thema. Wechsel mitten in der Session: die offene Aufgabe bleibt, das neue Thema
--        gilt ab der naechsten.
--   3  A4 coach_raum_live: phase_seit und warmup_entfallen (kein_stoff, zeit, null mit Warm-up).
--   6' A6 coach_kind_detail.heute_sicher: der Skill, bei dem die Engine weitergerueckt ist.
--   R  Rechte und Tablet unveraendert: Konto ohne Profil 42501, das Tablet sieht die neuen Felder nicht.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(20);

\ir session_a2_fixture.sql

-- ── 1) A1: Thema waehlen ohne Schulthema ───────────────────────────────────
select pg_temp.kind_mit('ZZ Ida F1', null, '{}') as k_i \gset
select pg_temp.neue_session(array[:'k_i']::uuid[], 6) as s1 \gset
select pg_temp.checkin(:'s1', 1);
select is(pg_temp.schritt(:'s1', 1) ->> 'grund_code', 'kein_ziel', '1 ohne Thema und ohne Luecke: kein_ziel');

select pg_temp.act_as(:'coach_a');
select is(checkin_coach_setzen(:'s1', :'k_i', 'schulthema', 'zz_a2_terme') ->> 'ziel_thema_key', 'zz_a2_terme',
          '1 Thema waehlen setzt das Ziel');
select is((select fall_coach || '/' || ziel_thema_key from session_checkin where session_id = :'s1' and student_id = :'k_i'),
          'schulthema/zz_a2_terme', '1 Fall Schulthema und Ziel stehen im Check-in');
select is((select k ->> 'fall' from jsonb_array_elements(coach_raum_live(:'s1') -> 'kinder') k), 'schulthema',
          '1 Coach-Sicht zeigt den Fall');
select is((select lt.status from lead_themen lt join leads l on l.id = lt.lead_id
            where l.converted_student_id = :'k_i' and lt.thema_key = 'zz_a2_terme'), 'aktuell', '1 Thema ist das aktuelle Schulthema');

select pg_temp.schritt(:'s1', 1) as n1 \gset
select is(:'n1'::jsonb ->> 'skill_key', 'zz_a2_s1', '1 naechster Schritt aus dem neuen Thema (Einstieg)');
select isnt(:'n1'::jsonb ->> 'grund_code', 'kein_ziel', '1 kein Warten mehr');

-- Wechsel mitten in der Session: Aufgabe offen, Coach waehlt ein anderes Thema.
create temp table f1_lauf as select n, pg_temp.schritt(:'s1', 1) as x from generate_series(1, 1) n;
select is((select x ->> 'art' from f1_lauf), 'aufgabe', '1 nach dem Beispiel eine offene Aufgabe');
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s1', :'k_i', 'schulthema', 'zz_a2_quad');
select is(pg_temp.schritt(:'s1', 1) ->> 'task_id', (select x ->> 'task_id' from f1_lauf),
          '1 Wechsel: die offene Aufgabe kommt unveraendert wieder');
select pg_temp.antwort(:'s1', 1, true);
select ok(pg_temp.schritt(:'s1', 1) ->> 'skill_key' in ('zz_a2_k1', 'zz_a2_k2'),
          '1 Wechsel: ab der naechsten Aufgabe gilt das neue Thema');

-- ── 3) A4: Phase und Warm-up entfallen ─────────────────────────────────────
select pg_temp.act_as(:'coach_a');
select coach_raum_live(:'s1') -> 'kinder' -> 0 as r1 \gset
select is(:'r1'::jsonb ->> 'phase', 'kern', '3 Kind ohne Warm-up-Stoff steht in der Kernarbeit');
select is(:'r1'::jsonb ->> 'warmup_entfallen', 'kein_stoff', '3 Grund: kein Warm-up-Stoff');
select is((:'r1'::jsonb ->> 'phase_seit')::timestamptz,
          (select max(zeit) from session_ereignisse where session_id = :'s1' and student_id = :'k_i' and typ = 'phase_wechsel'),
          '3 phase_seit = juengster Phasenwechsel');

-- Kind mit Warm-up-Stoff (sichere Voraussetzungen): Warm-up laeuft, nichts entfallen.
select pg_temp.kind_mit('ZZ Mats F1', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}') as k_m \gset
select pg_temp.neue_session(array[:'k_m']::uuid[], 6) as s2 \gset
select pg_temp.checkin(:'s2', 1);
select pg_temp.loese(:'s2', 1, true);
select pg_temp.act_as(:'coach_a');
select is((select k ->> 'phase' || '/' || coalesce(k ->> 'warmup_entfallen', '-') from jsonb_array_elements(coach_raum_live(:'s2') -> 'kinder') k),
          'warmup/-', '3 mit Warm-up: Phase warmup, nichts entfallen');

-- ── 6') A6: heute sicher ───────────────────────────────────────────────────
-- Kind Mats: Warm-up fertig machen, dann in der Kernarbeit zwei Aufgaben zu s1 richtig ohne Hinweis.
create temp table f1_m as select n, pg_temp.loese(:'s2', 1, true) as x from generate_series(1, 8) n;
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s2', :'k_m') as d2 \gset
select ok((:'d2'::jsonb -> 'heute_sicher') ? 'zz_a2_s1', '6 s1 ist heute sicher (mastery_richtig_ohne_hinweis)');
select is((select x ->> 'skill_key' from f1_m where x ->> 'phase' = 'kern' order by n desc limit 1), 'zz_a2_s2',
          '6 die Engine ist zu s2 weitergerueckt');
select ok((select bool_and(z.skill_key in (select skill_key from session_zielliste(:'s2', :'k_m')))
             from jsonb_array_elements_text(:'d2'::jsonb -> 'heute_sicher') z(skill_key)),
          '6 heute_sicher nennt nur Skills der Zielliste');

-- Spaetes Kind: Uhr schon in der Kernarbeit (Minute 20), Warm-up-Stoff waere da.
select pg_temp.kind_mit('ZZ Nele F1', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}') as k_n \gset
select pg_temp.neue_session(array[:'k_n']::uuid[], 20) as s3 \gset
select pg_temp.checkin(:'s3', 1);
select pg_temp.schritt(:'s3', 1);
select pg_temp.act_as(:'coach_a');
select is((select k ->> 'warmup_entfallen' from jsonb_array_elements(coach_raum_live(:'s3') -> 'kinder') k), 'zeit',
          '3 spaet: Warm-up-Zeit vorbei');

-- ── R) Rechte und Tablet ───────────────────────────────────────────────────
select pg_temp.act_as(:'ohne');
select throws_ok(format('select coach_raum_live(%L)', :'s1'), '42501', null, 'R Konto ohne Profil: 42501');
select pg_temp.act_as(pg_temp.tablet(1));
select ok(not (tablet_stand() ?| array['phase_seit', 'warmup_entfallen', 'heute_sicher']), 'R Tablet sieht die neuen Felder nicht');

select * from finish();
rollback;
