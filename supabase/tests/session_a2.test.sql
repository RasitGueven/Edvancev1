-- ============================================================================
-- A2: Session-Engine (Bauauftrag Session-Rahmen P1, Paket A2).
--
-- Zusagen (Nummern wie im Auftrag):
--    1) Fremdes Tablet, fremder Coach, Schuelerkonto, Konto ohne Profil -> 42501.
--    2) Phasen an den Grenzen des Snapshots; ein spaetes Kind beginnt mit der Kernarbeit.
--    3) Schulthema -> ziel_fertigkeiten; Lernpfad -> naechste_luecke.
--    4) Warm-up: warmup_aufgaben aus sicheren Skills, eine Stufe leichter; zwei Fehler -> Entscheidung.
--    5) Neuer Skill mit Sequenz -> erklaerung; ohne -> beispiel "keine Erklaerung vorhanden".
--    6) Beispiel-Item nie als Aufgabe; keine Aufgabe zweimal in einer Session.
--    7) Steuerung: 5x richtig +1; 5x falsch -1; auf 1 weiter falsch -> "haengt".
--    8) Mischen: 0,3 -> von 10 genau 3; Klassenarbeit nur aus ihrem Thema.
--    9) Pool: ohne 'session' oder nicht ready nie; Testlauf nimmt draft ohne pruef_ausschluss.
--   10) Check-out: Exit ohne Hinweise, Ergebnis im Abschluss, danach fertig bzw. termin.
--   11) Belege: Kernarbeit bucht, Check der Sequenz nicht, Testlauf nie.
--   12) Kandidaten: hoechstens mastery_kandidaten_je_raum.
--   13) Stellschrauben: Aenderung nach session_starten aendert die Session nicht.
--   14) Vorschau durch Coach und Admin bucht nichts.
--   15) Laufzeit mit 2.000 Aufgaben im Pool unter 200 ms.
--   X)  Befunde X0b: erklaer_nachlesen, erklaer_zugang, lernpfad_coach_der_session NULL-sicher.
--   V)  Verdrahtung: Stufe 4 -> pfad_tiefer, Live-Sicht, Abschluss im Testlauf, Tablet-Wege.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(118);

\ir session_a2_fixture.sql

-- Pool-Fixtures (9): eigenes Thema nur mit ungeprueften Aufgaben, dazu Aufgaben ausserhalb des Pools.
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_a2_d1', 'ZZ Nur Entwurf', 8, 1);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_a2_entwurf', 'mathematik', 8, 'erste', 'ZZ Entwurf', 9205);
insert into thema_einstieg (thema_key, skill_key) values ('zz_a2_entwurf', 'zz_a2_d1');
insert into skill_thema (skill_key, thema_key) values ('zz_a2_d1', 'zz_a2_entwurf');
select pg_temp.aufgaben('zz_a2_d1', 3, 'draft', '{lsa,session}', 'a2-draft');
select pg_temp.aufgaben('zz_a2_d1', 1, 'draft', '{lsa,session}', 'a2-hand');
select pg_temp.aufgaben('zz_a2_d1', 1, 'ready', '{lsa}', 'a2-nurlsa');
insert into task_pruef_ausschluss (task_id, grund) select id, 'A2-Test' from tasks where source_ref = 'a2-hand-1';
select (select id from tasks where source_ref = 'a2-draft-1') as t_draft, (select id from tasks where source_ref = 'a2-hand-1') as t_hand,
       (select id from tasks where source_ref = 'a2-nurlsa-1') as t_nurlsa,
       (select id from tasks where source_ref = 'a2-zz_a2_s1-1') as t_ready
\gset
update tasks set is_active = false where source_ref = 'a2-zz_a2_s1-30';
select id as t_inaktiv from tasks where source_ref = 'a2-zz_a2_s1-30' \gset

-- Kinder (Namen wie im Dummy).
select pg_temp.kind_mit('ZZ Emir A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_emir,
       pg_temp.kind_mit('ZZ Deniz A2', null, '{zz_a2_v1}') as k_deniz,
       pg_temp.kind_mit('ZZ Jonas A2', 'zz_a2_linear', '{zz_a2_v2}') as k_jonas,
       pg_temp.kind_mit('ZZ Ole A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}') as k_ole,
       pg_temp.kind_mit('ZZ Lea A2', null, '{zz_a2_k2,zz_a2_v1}', '{zz_a2_k1}') as k_lea,
       pg_temp.kind_mit('ZZ Mila A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_mila,
       pg_temp.kind_mit('ZZ Paul A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_paul,
       pg_temp.kind_mit('ZZ Tim A2', 'zz_a2_entwurf', '{}', '{}', true) as k_tim,
       pg_temp.kind_mit('ZZ Kai A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_kai,
       pg_temp.kind_mit('ZZ Ida A2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_ida
\gset
-- Deniz: Luecke aus der LSA im Lernpfad.
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'k_deniz', 'zz_a2_s1', 'noch_nicht_sicher', 'lsa');

-- ── 1) Rechte ──────────────────────────────────────────────────────────────
select pg_temp.neue_session(array[:'k_emir', :'k_deniz']::uuid[], 0) as s1 \gset
select pg_temp.act_as(pg_temp.tablet(2));
select throws_ok(format('select session_naechster_schritt(%L, %L)', :'s1', :'k_emir'), '42501', null, '1 fremdes Tablet');
select pg_temp.act_as(pg_temp.tablet(5));
select throws_ok(format('select session_naechster_schritt(%L, %L)', :'s1', :'k_emir'), '42501', null, '1 Tablet ohne Platz');
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select session_naechster_schritt(%L, %L)', :'s1', :'k_emir'), '42501', null, '1 fremder Coach');
select pg_temp.act_as(:'schueler');
select throws_ok(format('select session_naechster_schritt(%L, %L)', :'s1', :'k_emir'), '42501', null, '1 Schuelerkonto');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select session_naechster_schritt(%L, %L)', :'s1', :'k_emir'), '42501', null, '1 Konto ohne Profil');
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'vorschau', 'true', '1 Coach der Session: Vorschau');
select ok(pg_temp.vorschau(:'s1', :'k_emir') ? 'grund', '1 Vorschau zeigt dem Coach den Grund');
select pg_temp.act_as(:'admin');
select is((session_naechster_schritt(:'s1', :'k_emir')) ->> 'vorschau', 'true', '1 Admin: Vorschau');

-- ── 2) Phasen und 14) Vorschau ────────────────────────────────────────────
select is(pg_temp.schritt(:'s1', 1) ->> 'grund_code', 'checkin_laeuft', '2 vor dem Check-in: warten');
select pg_temp.checkin(:'s1', 1);
select pg_temp.uhr(:'s1', 6);
select ok(not (pg_temp.schritt_tablet(:'s1', 1) ?| array['grund', 'schwierigkeit']),
          '1 Tablet bekommt weder Grund noch Stufe (kein Richtig/Falsch-Feedback, CLAUDE.md §6)');
select pg_temp.antwort(:'s1', 1, true);
create temp table zaehler as
  select (select count(*) from session_schritte) a, (select count(*) from session_ausgegeben) b,
         (select count(*) from session_ereignisse) c, (select count(*) from lernpfad_belege) d;
select pg_temp.uhr(:'s1', 4.99);
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'phase', 'warmup', '2 Check-in fertig bei 4:59 -> Warm-up beginnt sofort');
select pg_temp.uhr(:'s1', 14.99);
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'phase', 'warmup', '2 14:59 noch Warm-up');
select pg_temp.uhr(:'s1', 15);
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'phase', 'kern', '2 15:00 Kernarbeit (5 + 10 aus dem Snapshot)');
select pg_temp.uhr(:'s1', 54.99);
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'phase', 'kern', '2 54:59 noch Kernarbeit');
select pg_temp.uhr(:'s1', 55);
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'phase', 'checkout', '2 55:00 Check-out (60 - 5)');
select pg_temp.act_as(:'admin');
select session_naechster_schritt(:'s1', :'k_emir');
select results_eq('select (select count(*) from session_schritte), (select count(*) from session_ausgegeben),
                          (select count(*) from session_ereignisse), (select count(*) from lernpfad_belege)',
                  'select a, b, c, d from zaehler', '14 Vorschau von Coach und Admin bucht nichts');

-- Spaetes Kind: Tablet erst nach dem Warm-up.
select pg_temp.uhr(:'s1', 20);
select pg_temp.checkin(:'s1', 2);
select is(pg_temp.schritt(:'s1', 2) ->> 'phase', 'kern', '2 spaetes Kind beginnt mit der Kernarbeit');

-- ── 3) Ziel ───────────────────────────────────────────────────────────────
select is(array(select skill_key from session_zielliste(:'s1', :'k_emir') order by reihenfolge),
          array['zz_a2_v1', 'zz_a2_v2', 'zz_a2_s1', 'zz_a2_s2'], '3 Schulthema: Liste aus ziel_fertigkeiten (Voraussetzungen zuerst)');
select is(pg_temp.vorschau(:'s1', :'k_emir') ->> 'skill_key', 'zz_a2_s1', '3 Schulthema: aktueller Skill = erster offener');
select is((select fall_vorschlag from session_checkin where session_id = :'s1' and student_id = :'k_deniz'), 'lernpfad',
          '3 Deniz: Fall Lernpfad');
select is(array(select skill_key || ':' || rolle from session_zielliste(:'s1', :'k_deniz')), array['zz_a2_s1:luecke'],
          '3 Lernpfad: Ziel aus naechste_luecke');
select is((select skill_key from session_schritte where session_id = :'s1' and student_id = :'k_deniz' order by id limit 1),
          'zz_a2_s1', '3 Lernpfad: erster Schritt auf der Luecke');
select is((select ziel_thema_key from session_checkin where session_id = :'s1' and student_id = :'k_deniz'), 'zz_a2_terme',
          '3 Lernpfad: ziel_thema_key = Thema der Luecke (Anzeige)');

-- ── 4) Warm-up, 13) Stellschrauben, 11) Belege ────────────────────────────
select pg_temp.neue_session(array[:'k_mila']::uuid[], 6) as s4 \gset
select pg_temp.stell('warmup_aufgaben', '1');
select is((select einstellungen ->> 'warmup_aufgaben' from coaching_sessions where id = :'s4'), '3', '13 Snapshot bleibt 3');
select pg_temp.checkin(:'s4', 1);
create temp table w4 as select n, pg_temp.loese(:'s4', 1, n = 2) as x from generate_series(1, 4) n;
select pg_temp.stell('warmup_aufgaben', '3');
select is((select count(*)::int from w4 where x ->> 'phase' = 'warmup' and x ->> 'art' = 'aufgabe'), 3,
          '4/13 drei Warm-up-Aufgaben (Snapshot), nicht eine (Live-Tabelle)');
select ok((select bool_and(x ->> 'skill_key' in ('zz_a2_v1', 'zz_a2_v2')) from w4 where n <= 3), '4 Warm-up aus sicheren Skills');
select ok((select bool_and((x ->> 'schwierigkeit')::int = 1 and x ->> 'grund' like '%eine Stufe leichter%') from w4 where n <= 3),
          '4 eine Stufe leichter (Niveau 2 - 1)');
select is((select x ->> 'grund_code' from w4 where n = 4), 'warten_entscheidung', '4 nach dem Warm-up: warten auf Entscheidung');
select pg_temp.act_as(:'coach_a');
select is((select count(*)::int from raum_signale(:'s4') where art = 'entscheidung' and grund like 'Entscheidung: eine Stufe tiefer?%'), 1,
          '4 zwei Fehlversuche auf einer Voraussetzung -> Entscheidungssignal');
select is((select count(*)::int from lernpfad_belege where session_id = :'s4'), 3, '11 jede Warm-up-Antwort bucht einen Beleg');
select lives_ok(format($$select pfad_entscheiden(%L, %L, 'tiefer')$$, :'s4', :'k_mila'), '4 Coach bestaetigt eine Stufe tiefer');
select is((select anlass || ':' || skill_key from lernpfad_protokoll where session_id = :'s4' and aktion = 'pfad_tiefer'),
          'warmup:zz_a2_v1', '4 pfad_tiefer(anlass = warmup) auf die Voraussetzung');
select is(pg_temp.schritt(:'s4', 1) ->> 'skill_key', 'zz_a2_v1', '4 Kernarbeit beginnt eine Stufe tiefer');

-- ── 5) Neuer Skill, 6) Beispiel, 11) Check bucht nicht ────────────────────
select pg_temp.neue_session(array[:'k_jonas', :'k_ole']::uuid[], 20) as s5 \gset
select pg_temp.checkin(:'s5', 1), pg_temp.checkin(:'s5', 2);
select pg_temp.schritt(:'s5', 1) as j1 \gset
select is(:'j1'::jsonb ->> 'art', 'erklaerung', '5 neuer Skill mit freigegebener Sequenz -> erklaerung');
select is(:'j1'::jsonb ->> 'grund', 'Neuer Skill ZZ Steigung: Erklärsequenz vorgeschaltet', '5 Grund fuer den Coach');
select is(pg_temp.schritt(:'s5', 1) ->> 'art', 'erklaerung', '5 ohne Fortschritt bleibt es bei erklaerung');
select pg_temp.act_as(pg_temp.tablet(1));
select (erklaer_start(:'s5', :'k_jonas', 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk \gset
select is(pg_temp.schritt(:'s5', 1) ->> 'grund_code', 'erklaerung_laeuft', '5 laufende Sequenz -> erklaerung');
select pg_temp.act_as(pg_temp.tablet(1));
select is((erklaer_check_abgeben(:'s5', :'k_jonas', :'chk', '{"text":"7"}')) ->> 'uebergang', 'ueben', '5 Check vom Tablet richtig -> ueben');
select is((select count(*)::int from lernpfad_belege where session_id = :'s5'), 0, '11 Check der Sequenz bucht keinen Beleg');
select is((select count(*)::int from session_ereignisse where session_id = :'s5' and typ = 'check'), 1, 'V Check schreibt Ereignis fuer raum_signale');
select pg_temp.schritt(:'s5', 1) as j2 \gset
select is(:'j2'::jsonb ->> 'art', 'beispiel', '5 nach der Sequenz: Loesungsbeispiel');
select ok(:'j2'::jsonb ->> 'loesungsweg' like 'ZZ-LOESUNGSWEG%', '5 nur beim Beispiel: Loesungsweg');
select pg_temp.schritt(:'s5', 1) as j3 \gset
select is(:'j3'::jsonb ->> 'grund_code', 'neu_aehnliche_aufgabe', '5 danach aehnliche Aufgabe');
select ok(not (:'j3'::jsonb ? 'loesungsweg') and :'j3'::jsonb::text not like '%LOESUNGSWEG%', '5 Aufgabe ohne Loesung');
select pg_temp.schritt(:'s5', 2) as o1 \gset
select is(:'o1'::jsonb ->> 'art', 'beispiel', '5 ohne Sequenz: direkt Beispiel');
select ok(:'o1'::jsonb ->> 'grund' like '%keine Erklärung vorhanden%', '5 Grund nennt "keine Erklärung vorhanden"');
select count(*) from pg_temp.lauf(:'s5', 2, 14, true);
select is((select count(*)::int from session_ausgegeben a join session_schritte b on b.task_id = a.task_id and b.art = 'beispiel' and b.student_id = a.student_id
            where a.student_id = :'k_ole'), 0, '6 ein Beispiel-Item kommt nie als Aufgabe');
select is((select count(*) - count(distinct task_id) from session_schritte where session_id = :'s5' and student_id = :'k_ole'
            and task_id is not null)::int, 0, '6 keine Aufgabe zweimal in einer Session');

-- ── 7) Steuerung ──────────────────────────────────────────────────────────
select pg_temp.stell('mastery_richtig_ohne_hinweis', '6'), pg_temp.stell('mischanteil', '0');
select pg_temp.neue_session(array[:'k_paul']::uuid[], 20) as s7 \gset
select pg_temp.stell('mastery_richtig_ohne_hinweis', '2'), pg_temp.stell('mischanteil', '0.30');
select pg_temp.checkin(:'s7', 1);
create temp table st7 as
  select n, pg_temp.loese(:'s7', 1, n <= 5) as x from generate_series(1, 21) n;
select is((select (x ->> 'schwierigkeit')::int from st7 where n = 1), 2, '7 Startniveau ohne fruehere richtige Aufgabe: 2');
select is((select (x ->> 'schwierigkeit')::int from st7 where n = 6), 3, '7 fuenfmal richtig -> +1');
select ok((select x ->> 'grund' like '%eine Stufe schwerer (5 von 5%' from st7 where n = 6), '7 Grund nennt die Quote');
select is((select (x ->> 'schwierigkeit')::int from st7 where n = 11), 2, '7 fuenfmal falsch -> -1');
select is((select (x ->> 'schwierigkeit')::int from st7 where n = 16), 1, '7 nochmal fuenfmal falsch -> Stufe 1');
select is((select count(*)::int from session_ereignisse where session_id = :'s7' and typ = 'signal'
            and payload ->> 'grund_code' = 'haengt_niveau'), 1, '7 auf 1 und weiter falsch -> Signal haengt');

-- ── 8) Mischen ────────────────────────────────────────────────────────────
select pg_temp.stell('mastery_richtig_ohne_hinweis', '6');
select pg_temp.neue_session(array[:'k_kai', :'k_lea']::uuid[], 20) as s8 \gset
select pg_temp.stell('mastery_richtig_ohne_hinweis', '2');
select pg_temp.checkin(:'s8', 1), pg_temp.checkin(:'s8', 2, current_date + 2, 'zz_a2_quad');
-- mit Hinweis: der Skill wird heute nicht sicher, die Liste bleibt beim aktuellen Skill.
select count(*) from pg_temp.lauf(:'s8', 1, 10, true, true);
select count(*) from pg_temp.lauf(:'s8', 2, 10, true, true);
select is((select count(*) filter (where eingemischt)::int from (select eingemischt from session_schritte
            where session_id = :'s8' and student_id = :'k_kai' and phase = 'kern' and art = 'aufgabe' and not nach_beispiel
            order by id limit 10) x), 3, '8 mischanteil 0,3: von 10 Aufgaben genau 3 eingemischt');
select is(array(select row_number from (select row_number() over (order by id), eingemischt from session_schritte
            where session_id = :'s8' and student_id = :'k_kai' and art = 'aufgabe') x where eingemischt)::int[],
          array[4, 7, 10], '8 deterministisch: die 4., 7. und 10. Aufgabe');
select is((select fall_vorschlag from session_checkin where session_id = :'s8' and student_id = :'k_lea'), 'klassenarbeit', '8 Lea: Klassenarbeit');
select ok((select count(*) > 0 and bool_and(skill_key = 'zz_a2_k2') from session_schritte
            where session_id = :'s8' and student_id = :'k_lea' and eingemischt), '8 Klassenarbeit: nur aus ihrem Thema (nie zz_a2_v1)');

-- ── 9) Pool ───────────────────────────────────────────────────────────────
select ok(session_im_pool(:'t_ready', false), '9 ready mit session im Pool');
select ok(not session_im_pool(:'t_nurlsa', false), '9 ohne session im Einsatz nie');
select ok(not session_im_pool(:'t_draft', false), '9 draft ausserhalb des Testlaufs nie');
select ok(not session_im_pool(:'t_inaktiv', false), '9 inaktiv nie');
select ok(session_im_pool(:'t_draft', true), '9 Testlauf: draft mit leerem pruef_ausschluss');
select ok(not session_im_pool(:'t_hand', true), '9 Testlauf: draft mit pruef_ausschluss nie');
select pg_temp.neue_session(array[:'k_tim']::uuid[], 20, true) as s9 \gset
select pg_temp.checkin(:'s9', 1);
create temp table p9 as select n, pg_temp.loese(:'s9', 1, true) as x from generate_series(1, 4) n where n > 0;
select is((select count(*)::int from p9 where x ->> 'art' in ('beispiel', 'aufgabe')
             and (select status from tasks where id = (x ->> 'task_id')::uuid) = 'draft'), 3,
          '9 Testlauf: die drei geprueften Entwuerfe kommen dran (neuer Skill: Beispiel + 2 Aufgaben)');
select is((select x ->> 'grund_code' from p9 where n = 4), 'pool_leer', '9 danach Pool erschoepft (Hand-Ausschluss und nur-LSA nie)');
select is((select count(*)::int from lernpfad_belege where session_id = :'s9'), 0, '11 Testlauf bucht nie Belege');
select ok((select bool_and(session_im_pool(task_id, false)) from session_ausgegeben a join coaching_sessions cs on cs.id = a.session_id
            where not cs.testlauf), '9 ausserhalb des Testlaufs nur Aufgaben aus dem Pool');

-- ── 10) Check-out ─────────────────────────────────────────────────────────
select pg_temp.neue_session(array[:'k_ida']::uuid[], 56) as s10 \gset
select pg_temp.checkin(:'s10', 1);
select pg_temp.schritt(:'s10', 1) as e1 \gset
select is(:'e1'::jsonb ->> 'art', 'exit', '10 Check-out beginnt mit einer Exit-Aufgabe');
select is(:'e1'::jsonb ->> 'hinweise_erlaubt', 'false', '10 Exit: hinweise_erlaubt = false');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select hinweis_abrufen(%L, %L, 1)', :'s10', :'e1'::jsonb ->> 'task_id'), '22023', null,
                 '10 Exit-Aufgaben ohne Hinweise');
select pg_temp.antwort(:'s10', 1, true);
select pg_temp.loese(:'s10', 1, false);
select is(pg_temp.schritt(:'s10', 1) ->> 'art', 'fertig', '10 nach exit_aufgaben: fertig (Home Quests aus)');
select is((select exit_ergebnis from session_kind_abschluss where session_id = :'s10' and student_id = :'k_ida'),
          '{"richtig": 1, "gesamt": 2}'::jsonb, '10 Ergebnis in session_kind_abschluss.exit_ergebnis');
select is((select count(*)::int from session_schritte where session_id = :'s10' and art = 'exit'), 2, '10 genau exit_aufgaben Exit-Aufgaben');

-- ── 12) Kandidaten ────────────────────────────────────────────────────────
update lernpfad set stand_system = 'kandidat' where student_id in (:'k_kai', :'k_ida') and skill_key in ('zz_a2_v1', 'zz_a2_v2');
insert into lernpfad (student_id, skill_key, stand_system, quelle) values
  (:'k_kai', 'zz_a2_k2', 'kandidat', 'session'), (:'k_kai', 'zz_a2_n1', 'kandidat', 'session');
select pg_temp.neue_session(array[:'k_kai', :'k_ida']::uuid[], 20) as s12 \gset
select pg_temp.checkin(:'s12', 1), pg_temp.checkin(:'s12', 2);
select pg_temp.schritt(:'s12', 1), pg_temp.schritt(:'s12', 2);
select is((select count(*)::int from session_ereignisse where session_id = :'s12' and typ = 'signal' and payload ->> 'art' = 'kandidat'), 3,
          '12 hoechstens mastery_kandidaten_je_raum (3) Kandidaten-Signale je Raum');
select pg_temp.act_as(:'coach_a');
select ok((select count(*) <= 3 from raum_signale(:'s12') where art = 'kandidat'), '12 raum_signale: hoechstens 3 Kandidaten');
select is((coach_raum_live(:'s12') -> 'kinder' -> 0 -> 'mastery_kandidat' ->> 'skill_key') is not null, true,
          'V coach_raum_live: Mastery-Kandidat gefuellt');
select ok((coach_raum_live(:'s12') -> 'kinder' -> 0 -> 'schritt' ->> 'grund') is not null, 'V coach_raum_live: Grund des letzten Schritts');

-- ── 15) Laufzeit ──────────────────────────────────────────────────────────
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_a2_g1', 'ZZ Gross', 8, 2);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_a2_gross', 'mathematik', 8, 'erste', 'ZZ Gross', 9206);
insert into thema_einstieg (thema_key, skill_key) values ('zz_a2_gross', 'zz_a2_g1');
insert into skill_thema (skill_key, thema_key) values ('zz_a2_g1', 'zz_a2_gross');
select pg_temp.aufgaben('zz_a2_g1', 2000);
select pg_temp.kind_mit('ZZ Gross A2', 'zz_a2_gross', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_g1}') as k_gross \gset
select pg_temp.neue_session(array[:'k_gross']::uuid[], 20) as s15 \gset
select pg_temp.checkin(:'s15', 1);
select pg_temp.loese(:'s15', 1, true);
-- Gemessen wird nur session_naechster_schritt, wie das Tablet ihn ruft (Rolle des Geraets, ohne Kind).
-- Ein Aufwaermaufruf zaehlt nicht, danach fuenf Messungen mit clock_timestamp(). Jeder Aufruf laeuft in
-- einem Unterblock, der per Ausnahme zurueckgerollt wird: alle starten vom selben Stand, obwohl der
-- Aufruf vom Tablet bucht (session_schritte, session_ausgegeben, Ereignisse).
select set_config('a2.s15', :'s15', true);
select (select count(*) from session_schritte where session_id = :'s15') as n15_schritte,
       (select count(*) from session_ausgegeben where session_id = :'s15') as n15_ausgegeben \gset
select pg_temp.act_as(pg_temp.tablet(1));
create temp table t15 (nr int, ms numeric);
do $$
declare
  v_s  uuid := current_setting('a2.s15')::uuid;
  t0   timestamptz;
  v_ms numeric;
  i    int;
begin
  for i in 0 .. 5 loop
    begin
      t0 := clock_timestamp();
      perform public.session_naechster_schritt(v_s, null);
      v_ms := extract(epoch from clock_timestamp() - t0) * 1000;
      raise exception using errcode = 'P0099';
    exception when sqlstate 'P0099' then
      if i > 0 then insert into t15 values (i, v_ms); end if;
    end;
  end loop;
end $$;
select set_config('request.jwt.claims', '', true);
select is((select count(*)::int from t15), 5, '15 fuenf gemessene Aufrufe (nach einem Aufwaermaufruf)');
select cmp_ok((select percentile_cont(0.5) within group (order by ms) from t15)::numeric, '<', 200::numeric,
              '15 Median von session_naechster_schritt (Tablet, 2.000 Aufgaben im Pool) unter 200 ms');
select diag('15 Median session_naechster_schritt: '
            || round((select percentile_cont(0.5) within group (order by ms) from t15)::numeric, 1) || ' ms (Einzelwerte: '
            || (select string_agg(round(ms, 1)::text, ', ' order by nr) from t15) || ')');
select is(array[(select count(*) from session_schritte where session_id = :'s15'),
                (select count(*) from session_ausgegeben where session_id = :'s15')]::int[],
          array[:n15_schritte, :n15_ausgegeben]::int[], '15 jeder Messaufruf startet vom selben Stand (zurueckgerollt)');

-- ── X) Befunde X0b ────────────────────────────────────────────────────────
select pg_temp.act_as(:'ohne');
select throws_ok(format($$select erklaer_nachlesen(%L, 'zz_a2_n1')$$, :'k_jonas'), '42501', null, 'X erklaer_nachlesen: Konto ohne Profil');
select throws_ok(format($$select erklaer_start(%L, %L, 'zz_a2_n1')$$, :'s5', :'k_jonas'), '42501', null, 'X erklaer_zugang: Konto ohne Profil');
select throws_ok(format($$select mastery_entscheiden(%L, 'zz_a2_v1', 'gemeistert', null, %L)$$, :'k_kai', :'s12'), '42501', null,
                 'X lernpfad_coach_der_session: Konto ohne Profil');
select pg_temp.act_as(:'coach_b');
select throws_ok(format($$select erklaer_nachlesen(%L, 'zz_a2_n1')$$, :'k_jonas'), '42501', null, 'X erklaer_nachlesen: fremder Coach');
select throws_ok(format($$select erklaer_start(%L, %L, 'zz_a2_n1')$$, :'s5', :'k_jonas'), '42501', null, 'X erklaer_zugang: fremder Coach');
select throws_ok(format($$select mastery_entscheiden(%L, 'zz_a2_v1', 'gemeistert', null, %L)$$, :'k_kai', :'s12'), '42501', null,
                 'X lernpfad_coach_der_session: fremder Coach');
select is(lernpfad_coach_der_session(:'s12', :'k_kai'), false, 'X lernpfad_coach_der_session liefert nie NULL (fremder Coach)');
select pg_temp.act_as(:'ohne');
select is(lernpfad_coach_der_session(:'s12', :'k_kai'), false, 'X lernpfad_coach_der_session liefert nie NULL (ohne Profil)');

-- ── V) Verdrahtung ────────────────────────────────────────────────────────
-- Stufe 4 setzt den Pfad tiefer (pfad_tiefer, anlass eingriff).
select pg_temp.act_as(:'coach_a');
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_a2_fb', 'ZZ A2 Fehlbild', now());
-- Gross arbeitet an g1 (Kernarbeit); g1 setzt v2 voraus, v2 ist noch nicht sicher.
insert into skill_kante (skill_key, voraussetzt_skill_key) values ('zz_a2_g1', 'zz_a2_v2');
update lernpfad set stand_system = 'noch_nicht_sicher' where student_id = :'k_gross' and skill_key = 'zz_a2_v2';
select pg_temp.act_as(:'coach_a');
select lives_ok(format($$select eingriff_notieren(%L, %L, 4, 'zz_a2_fb')$$, :'s15', :'k_gross'), 'V Stufe 4 notiert');
select is((select anlass || ':' || skill_key from lernpfad_protokoll where session_id = :'s15' and student_id = :'k_gross'
            and aktion = 'pfad_tiefer'), 'eingriff:zz_a2_v2', 'V Stufe 4 ruft pfad_tiefer(anlass = eingriff)');
-- Tablet: Phase nicht selbst setzen; eigener Lernpfad; Quest-Termin der eigenen Quest.
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select phase_setzen(%L, null, 'kern')$$, :'s15'), '42501', null, 'V Tablet setzt die Phase nicht selbst');
select ok((select count(*) > 0 from mein_lernpfad()), 'V mein_lernpfad vom Tablet');
select pg_temp.als_system();
insert into quests (student_id, session_id, art, faellig_ab, status)
values (:'k_gross', :'s15', 'A', current_date + 2, 'offen') returning id as q15 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select lives_ok(format($$select quest_termin_setzen(%L::uuid, (current_date + 3)::timestamptz)$$, :'q15'), 'V Quest-Termin vom Tablet');
select pg_temp.act_as(pg_temp.tablet(2));
select throws_ok(format($$select quest_termin_setzen(%L::uuid, (current_date + 3)::timestamptz)$$, :'q15'), '42501', null,
                 'V Quest-Termin: fremdes Tablet');
-- Q1 liest den Snapshot der Session.
select pg_temp.stell('quest_xp', '80');
select is(quest_einstellung_zahl('quest_xp', 50, :'s15'), 50::numeric, 'V Q1: Stellschraube aus dem Snapshot');
select is(quest_einstellung_zahl('quest_xp', 50), 80::numeric, 'V Q1: ohne Session die Tabelle');
-- Testlauf: Abschluss schreibt nichts in die Akte.
select pg_temp.act_as(:'coach_a');
select abschluss_setzen(:'s9', :'k_tim', p_notiz => 'ZZ Testlauf-Notiz', p_flag_eltern => true);
select session_abschliessen(:'s9');
select is((select count(*)::int from schueler_notizen where student_id = :'k_tim'), 0, 'V Testlauf: keine Notiz in der Akte');
select pg_temp.act_as(:'admin');
select is((select count(*)::int from session_flags_offen() where session_id = :'s9'), 0, 'V Testlauf: keine offenen Flags');

-- ── Entscheidungen Rasit 06.10. (Nachtrag) ───────────────────────────────
-- Coach-Entscheidungen nur in laufender Session oder am selben Tag nach dem Abschluss.
select pg_temp.als_system();
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am, beendet_am)
values (:'coach_a', 'ZZ A2 gestern', now() - interval '1 day', 'done', now() - interval '1 day', now() - interval '1 day')
returning id as s_gestern \gset
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am, beendet_am)
values (:'coach_a', 'ZZ A2 heute', now() - interval '2 hours', 'done', now() - interval '2 hours', now() - interval '1 hour')
returning id as s_heute \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ A2 morgen', now() + interval '1 day')
returning id as s_morgen \gset
-- Laufend, aber nicht abgeschlossen: geplanter Beginn vor 89 bzw. 91 Minuten (Ende + 30 = 90 Minuten).
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach_a', 'ZZ A2 im Fenster', now() - interval '89 minutes', 'active', now() - interval '89 minutes')
returning id as s_fenster \gset
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach_a', 'ZZ A2 nach dem Fenster', now() - interval '91 minutes', 'active', now() - interval '91 minutes')
returning id as s_vorbei \gset
insert into session_students (session_id, student_id, attendance)
select x, :'k_gross', 'present' from unnest(array[:'s_gestern', :'s_heute', :'s_morgen', :'s_fenster', :'s_vorbei']::uuid[]) x;
select set_config('request.jwt.claims', '', true);
select pg_temp.act_as(:'coach_a');
select ok(lernpfad_coach_der_session(:'s15', :'k_gross'), 'N laufende Session: Coach darf entscheiden');
select ok(lernpfad_coach_der_session(:'s_heute', :'k_gross'), 'N am selben Tag nach dem Abschluss: Coach darf entscheiden');
select ok(not lernpfad_coach_der_session(:'s_gestern', :'k_gross'), 'N Abschluss gestern: nicht mehr');
select ok(not lernpfad_coach_der_session(:'s_morgen', :'k_gross'), 'N geplante Session: noch nicht');
select ok(lernpfad_coach_der_session(:'s_fenster', :'k_gross'), 'N laufend, 29 Minuten nach dem geplanten Ende: noch im Fenster');
select ok(not lernpfad_coach_der_session(:'s_vorbei', :'k_gross'), 'N laufend, 31 Minuten nach dem geplanten Ende: nicht mehr');
select throws_ok(format($$select pfad_tiefer(%L, 'zz_a2_g1', %L)$$, :'k_gross', :'s_vorbei'), '42501', null,
                 'N pfad_tiefer in nicht abgeschlossener Session nach dem Fenster -> 42501');
select throws_ok(format($$select eingriff_notieren(%L, %L, 4, 'zz_a2_fb')$$, :'s_vorbei', :'k_gross'), '42501', null,
                 'N Eingriff Stufe 4 nach dem Fenster -> 42501');
select throws_ok(format($$select mastery_entscheiden(%L, 'zz_a2_v1', 'gemeistert', null, %L)$$, :'k_gross', :'s_vorbei'), '42501', null,
                 'N mastery_entscheiden nach dem Fenster -> 42501');
select throws_ok(format($$select pfad_tiefer(%L, 'zz_a2_g1', %L)$$, :'k_gross', :'s_gestern'), '42501', null,
                 'N pfad_tiefer nach dem Tag des Abschlusses -> 42501');
select throws_ok(format($$select mastery_entscheiden(%L, 'zz_a2_v1', 'gemeistert', null, %L)$$, :'k_gross', :'s_morgen'), '42501', null,
                 'N mastery_entscheiden in einer geplanten Session -> 42501');
select throws_ok(format($$select eingriff_notieren(%L, %L, 4, 'zz_a2_fb')$$, :'s_gestern', :'k_gross'), '42501', null,
                 'N Eingriff Stufe 4 nach dem Tag des Abschlusses -> 42501');
select lives_ok(format($$select eingriff_notieren(%L, %L, 2)$$, :'s_gestern', :'k_gross'), 'N Stufe 1/2 notiert der Coach weiter');

-- Schwierigkeit fuer die Auswahl: difficulty, sonst AFB (I 2, II 3, III 4), sonst 2.
select is(array[session_schwierigkeit(null, 'I'), session_schwierigkeit(null, 'II'), session_schwierigkeit(null, 'III'),
                session_schwierigkeit(null, null), session_schwierigkeit(5, 'I')], array[2, 3, 4, 2, 5],
          'N Schwierigkeit: AFB-Rueckfall nur ohne difficulty');

-- Ungepruefte Erklaerinhalte nur im Testlauf.
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_a2_n2', 'ZZ Achsenabschnitt', 8, 1);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_a2_n2t', 'mathematik', 8, 'erste', 'ZZ Achsen', 9207);
insert into thema_einstieg (thema_key, skill_key) values ('zz_a2_n2t', 'zz_a2_n2');
insert into skill_thema (skill_key, thema_key) values ('zz_a2_n2', 'zz_a2_n2t');
select pg_temp.aufgaben('zz_a2_n2', 5);
select pg_temp.aufgaben('zz_a2_n2', 1, 'draft', '{check}', 'a2-check2');
select pg_temp.act_as(:'admin');
select erklaer_kernidee_speichern(null, 'zz_a2_n2', 1, 'ZZ Achsenabschnitt ablesen', 'ki') as kern_n2 \gset
select erklaer_schritt_speichern(:'kern_n2', 'A', 'erklaerung', 'ZZ A2 Entwurf', null, '{}');
select erklaer_check_setzen(:'kern_n2', (select id from tasks where source_ref = 'a2-check2-1'), 1);
select pg_temp.kind_mit('ZZ Test N2', 'zz_a2_n2t', '{}', '{}', true) as k_tn2,
       pg_temp.kind_mit('ZZ Echt N2', 'zz_a2_n2t', '{}', '{}') as k_en2
\gset
select pg_temp.neue_session(array[:'k_tn2']::uuid[], 20, true) as s_tn2 \gset
select pg_temp.checkin(:'s_tn2', 1);
select is(pg_temp.schritt(:'s_tn2', 1) ->> 'art', 'erklaerung', 'N Testlauf: Entwurf der Erklaersequenz laeuft');
select pg_temp.act_as(pg_temp.tablet(1));
select is((erklaer_start(:'s_tn2', :'k_tn2', 'zz_a2_n2')) ->> 'aktion', 'start', 'N Testlauf: erklaer_start liefert den Entwurf');
select pg_temp.neue_session(array[:'k_en2']::uuid[], 20) as s_en2 \gset
select pg_temp.checkin(:'s_en2', 1);
select ok(pg_temp.schritt(:'s_en2', 1) ->> 'grund' like '%keine Erklärung vorhanden%', 'N ohne Testlauf: Entwurf nie');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select erklaer_start(%L, %L, 'zz_a2_n2')$$, :'s_en2', :'k_en2'), 'P0002', null,
                 'N ohne Testlauf: erklaer_start liefert keinen Entwurf');

-- Beschreibung ka_tage nach Entscheidung I.
select is((select beschreibung from session_einstellungen where schluessel = 'ka_tage'),
          'Klassenarbeit zählt, wenn sie höchstens so viele Tage entfernt ist (einschließlich); gemischt wird dann nur im Thema der Klassenarbeit',
          'N ka_tage: Text passt zu Entscheidung I');

select * from finish();
rollback;
