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
--   E3 Warm-up-Reihenfolge (Rasit 08.10.): Fokus, Voraussetzung, dann (1) bekannter Stand, (2) noch nicht sicher,
--        (3) geringster Abstand zum ersten offenen Ziel-Skill, (4) alphabetisch. Kandidatenmenge unveraendert.
--   6  B4 Platzhalter-Erklaersequenz zu gleichung_quadr_faktor (Migration 20261011140400): startet im Testlauf,
--        ausserhalb nicht (Status entwurf, Entscheidung 27).
--   R  Rechte und Tablet unveraendert: Konto ohne Profil 42501, das Tablet sieht die neuen Felder nicht.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(29);

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

-- ── E3) Warm-up-Reihenfolge ───────────────────────────────────────────────
-- Eigene Kette z -> c -> b -> a (Einstieg z): Abstand zu z (erster offener Ziel-Skill) c = 1, b = 2, a = 3. Sicher
-- sind a und b, beide Voraussetzungen des Ziels, gleich lange nicht geuebt. Alphabetisch kaeme a, mit Regel (3) b.
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('zz_f1_a', 'ZZ F1 Grundrechnen', 5, 1), ('zz_f1_b', 'ZZ F1 Bruchrechnen', 6, 2),
  ('zz_f1_c', 'ZZ F1 Terme', 7, 3), ('zz_f1_z', 'ZZ F1 Gleichungen', 8, 4);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zz_f1_z', 'zz_f1_c'), ('zz_f1_c', 'zz_f1_b'), ('zz_f1_b', 'zz_f1_a');
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_f1_thema', 'mathematik', 8, 'erste', 'ZZ F1 Gleichungen', 9301);
insert into thema_einstieg (thema_key, skill_key) values ('zz_f1_thema', 'zz_f1_z');
insert into skill_thema (skill_key, thema_key) values
  ('zz_f1_a', 'zz_a2_basis'), ('zz_f1_b', 'zz_a2_basis'), ('zz_f1_c', 'zz_a2_basis'), ('zz_f1_z', 'zz_f1_thema');
select pg_temp.aufgaben('zz_f1_a', 6), pg_temp.aufgaben('zz_f1_b', 6), pg_temp.aufgaben('zz_f1_z', 6);
select pg_temp.kind_mit('ZZ Ole F1', 'zz_f1_thema', '{zz_f1_a,zz_f1_b}') as k_o \gset
select pg_temp.neue_session(array[:'k_o']::uuid[], 6) as s4 \gset
select pg_temp.checkin(:'s4', 1);
select pg_temp.schritt(:'s4', 1) as w1 \gset
select is(:'w1'::jsonb ->> 'skill_key', 'zz_f1_b', 'E3 (3) geringerer Abstand zum Ziel-Skill vor alphabetisch');
select is(:'w1'::jsonb ->> 'grund_code', 'warmup_voraussetzung', 'E3 Voraussetzung des Ziels');
select pg_temp.antwort(:'s4', 1, true);
select is(pg_temp.schritt(:'s4', 1) ->> 'skill_key', 'zz_f1_b', 'E3 Fokus: das Warm-up bleibt beim Skill der vorigen Aufgabe (F9)');

-- (4) Gleicher Abstand: alphabetisch. Sicher v1 und v2 (beide Abstand 1 zu s1): v1 vor v2.
select pg_temp.kind_mit('ZZ Pia F1', 'zz_a2_terme', '{zz_a2_v2,zz_a2_v1}') as k_p \gset
select pg_temp.neue_session(array[:'k_p']::uuid[], 6) as s5 \gset
select pg_temp.checkin(:'s5', 1);
select is(pg_temp.schritt(:'s5', 1) ->> 'skill_key', 'zz_a2_v1', 'E3 (4) gleicher Abstand: alphabetisch');

-- ── 6) B4 Platzhalter-Sequenz ─────────────────────────────────────────────
-- Im Neuaufbau haben die Bestandsaufgaben keinen Cluster (offene-punkte-a2d 1 b): fuer den Test setzen.
update tasks set cluster_id = (select id from skill_clusters where name = 'ZZ A2 Cluster')
 where skill_key = 'gleichung_quadr_faktor';
-- Wie Batu: Wurzel ziehen sicher, Thema Quadratische Gleichungen; spaet (Minute 20), damit es gleich in die Kernarbeit geht.
select pg_temp.kind_mit('ZZ Batu F1', 'quadratische_gleichungen', '{zahl_wurzel_quadrat}', '{}', true) as k_b \gset
select pg_temp.neue_session(array[:'k_b']::uuid[], 20, true) as s6 \gset
select pg_temp.checkin(:'s6', 1);
select pg_temp.schritt(:'s6', 1) as b1 \gset
select is(:'b1'::jsonb ->> 'skill_key', 'gleichung_quadr_faktor', '6 erster offener Ziel-Skill: gleichung_quadr_faktor');
select is(:'b1'::jsonb ->> 'art', 'erklaerung', '6 im Testlauf kommt die Erklaersequenz');
select pg_temp.act_as(pg_temp.tablet(1));
select erklaer_start(:'s6', null, 'gleichung_quadr_faktor') as e1 \gset
select ok(:'e1'::jsonb -> 'kernidee' ->> 'titel' like 'Platzhalter:%', '6 die Kernidee ist als Platzhalter erkennbar');
select is(:'e1'::jsonb -> 'check' ->> 'task_id', 'a368a0d0-25fd-4cc9-a873-541afbb9e864', '6 mit dem Platzhalter-Check');

-- Ausserhalb eines Testlaufs: eine Aufgabe ready, damit der Pool nicht leer ist; die Sequenz (Entwurf) kommt nicht.
update tasks set status = 'ready'
 where id = (select id from tasks where skill_key = 'gleichung_quadr_faktor' and source <> 'edvance_f1_platzhalter'
              and 'session' = any (einsatz) order by source_ref limit 1);
select pg_temp.kind_mit('ZZ Echt Batu F1', 'quadratische_gleichungen', '{zahl_wurzel_quadrat}') as k_eb \gset
select pg_temp.neue_session(array[:'k_eb']::uuid[], 20) as s7 \gset
select pg_temp.checkin(:'s7', 1);
select ok((select x ->> 'skill_key' = 'gleichung_quadr_faktor' and x ->> 'art' in ('beispiel', 'aufgabe')
             from (select pg_temp.schritt(:'s7', 1) as x) y),
          '6 ausserhalb des Testlaufs keine Erklaersequenz (Entwurf)');

-- ── R) Rechte und Tablet ───────────────────────────────────────────────────
select pg_temp.act_as(:'ohne');
select throws_ok(format('select coach_raum_live(%L)', :'s1'), '42501', null, 'R Konto ohne Profil: 42501');
select pg_temp.act_as(pg_temp.tablet(1));
select ok(not (tablet_stand() ?| array['phase_seit', 'warmup_entfallen', 'heute_sicher']), 'R Tablet sieht die neuen Felder nicht');

select * from finish();
rollback;
