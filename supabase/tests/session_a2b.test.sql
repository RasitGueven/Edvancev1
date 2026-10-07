-- ============================================================================
-- A2b: Tablet-Daten, XP in der Session, Pruefrage aufs Tablet (Bauauftrag Session-P1, Entscheidungen 29-36).
--
-- Zusagen (Nummern wie im Auftrag):
--   1) session_kind_kontext, session_ziel_kind, session_abschluss_kind: fremdes Tablet, Schuelerkonto, Coach,
--      Konto ohne Profil -> 42501.
--   2) pruefung_aufs_tablet: Tablet und fremder Coach -> 42501; ohne freigegebene Pruefung und ausserhalb der
--      Zeitbindung -> Fehler.
--   3) tablet_stand.pruefung: nur Label und Frage; nach pruefung_vom_tablet oder mastery_entscheiden null;
--      eine neue ersetzt die alte.
--   4) tablet_stand.bestaetigt: gemeistert in dieser Session ja; vertagt nein; andere Session nein.
--   5) Ziel: hoechstens drei ab dem aktuellen Skill, neu; Lernpfad ein Skill; vor der Wahl fall = null; kein Stand.
--   6) Kontext: Schulthema; quest_termine null bzw. Quest A zwei Tage, Quest B Tag vor der naechsten Session.
--   7) XP: genau einmal Anzahl mal Wert; Abschluss bucht fuer anwesende Kinder; Testlauf und 0 Aufgaben nie;
--      Beispiele und Checks zaehlen nicht; Wert aus dem Snapshot.
--   8) Abschluss: xp = Buchung; naechste Session; eingemischte Skills fehlen.
--   9) X0b-Waechter: laeuft in session_x0b.test.sql ueber alle Funktionen (auch die neuen).
--   R) Regeln: Exit neutral (29), Hinweise nur in der Kernarbeit (32).
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(65);

\ir session_a2_fixture.sql

insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_a2_fb', 'ZZ A2 Fehlbild', now());
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('zz_a2_v1', 'ZZ-FRAGE-V1: Erklaer mir das Minus vor der Klammer.', 'ZZ-ERWARTUNG-V1', 'ZZ-KRITERIUM-V1', 'freigegeben', 'mensch'),
  ('zz_a2_v2', 'ZZ-FRAGE-V2: Wie rechnest du proportional?', 'ZZ-ERWARTUNG-V2', 'ZZ-KRITERIUM-V2', 'freigegeben', 'mensch'),
  ('zz_a2_s2', 'ZZ-FRAGE-ENTWURF', 'x', 'y', 'entwurf', 'ki');

select pg_temp.kind_mit('ZZ Emir A2b', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_emir,
       pg_temp.kind_mit('ZZ Deniz A2b', null, '{zz_a2_v1}') as k_deniz,
       pg_temp.kind_mit('ZZ Jonas A2b', 'zz_a2_linear', '{zz_a2_v2}') as k_jonas,
       pg_temp.kind_mit('ZZ Ida A2b', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_ida,
       pg_temp.kind_mit('ZZ Tim A2b', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_tim
\gset
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'k_deniz', 'zz_a2_s1', 'noch_nicht_sicher', 'lsa');
-- Emir: v1 und v2 sind Mastery-Kandidaten (Pruefung moeglich).
update lernpfad set stand_system = 'kandidat' where student_id = :'k_emir' and skill_key in ('zz_a2_v1', 'zz_a2_v2');

-- Naechste gebuchte Session fuer Emir in drei Tagen (Quest B, naechste_session).
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at)
values (:'coach_a', 'ZZ A2b naechste', date_trunc('day', now()) + interval '3 days 16 hours') returning id as s_next \gset
insert into session_students (session_id, student_id) values (:'s_next', :'k_emir');
select set_config('request.jwt.claims', '', true);

select pg_temp.stell('home_quests_aktiv', 'true');
select pg_temp.neue_session(array[:'k_emir', :'k_deniz']::uuid[], 20) as s \gset
select pg_temp.stell('home_quests_aktiv', 'false');

-- ── 1) Rechte ──────────────────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(5));
select throws_ok(format('select session_kind_kontext(%L)', :'s'), '42501', null, '1 kontext: fremdes Tablet');
select throws_ok(format('select session_ziel_kind(%L)', :'s'), '42501', null, '1 ziel: fremdes Tablet');
select throws_ok(format('select session_abschluss_kind(%L)', :'s'), '42501', null, '1 abschluss: fremdes Tablet');
select pg_temp.act_as(:'schueler');
select throws_ok(format('select session_kind_kontext(%L)', :'s'), '42501', null, '1 kontext: Schuelerkonto');
select throws_ok(format('select session_ziel_kind(%L)', :'s'), '42501', null, '1 ziel: Schuelerkonto');
select throws_ok(format('select session_abschluss_kind(%L)', :'s'), '42501', null, '1 abschluss: Schuelerkonto');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('select session_kind_kontext(%L)', :'s'), '42501', null, '1 kontext: Coach der Session');
select throws_ok(format('select session_ziel_kind(%L)', :'s'), '42501', null, '1 ziel: Coach der Session');
select throws_ok(format('select session_abschluss_kind(%L)', :'s'), '42501', null, '1 abschluss: Coach der Session');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select session_kind_kontext(%L)', :'s'), '42501', null, '1 kontext: Konto ohne Profil');
select throws_ok(format('select session_ziel_kind(%L)', :'s'), '42501', null, '1 ziel: Konto ohne Profil');
select throws_ok(format('select session_abschluss_kind(%L)', :'s'), '42501', null, '1 abschluss: Konto ohne Profil');

-- ── 6) Kontext ────────────────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select session_kind_kontext(:'s') as kx \gset
select is(:'kx'::jsonb -> 'schulthema' ->> 'label', 'ZZ Terme', '6 aktuelles Schulthema mit Label');
select is(:'kx'::jsonb ->> 'vorname', 'ZZ', '6 Vorname des Kindes');
select is(:'kx'::jsonb -> 'quest_termine' -> 'quest_a',
          jsonb_build_array(current_date + 2, current_date + 3), '6 Quest A: zwei Tage nach quest_a_abstand_tage (2)');
select is(:'kx'::jsonb -> 'quest_termine' ->> 'quest_b', (current_date + 2)::text, '6 Quest B: Tag vor der naechsten Session');
select pg_temp.act_as(pg_temp.tablet(2));
select is((session_kind_kontext(:'s')) -> 'schulthema', 'null'::jsonb, '6 ohne Schulthema: null');

-- ── 5) Ziel ───────────────────────────────────────────────────────────────
select pg_temp.checkin(:'s', 1), pg_temp.checkin(:'s', 2);
select pg_temp.act_as(pg_temp.tablet(1));
select is((session_ziel_kind(:'s')) ->> 'fall', null, '5 vor der Wahl des Coaches: fall = null');
select is(jsonb_array_length((session_ziel_kind(:'s')) -> 'fertigkeiten'), 0, '5 vor der Wahl: keine Fertigkeiten');
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s', :'k_emir', 'schulthema'), checkin_coach_setzen(:'s', :'k_deniz', 'lernpfad');
select pg_temp.act_as(pg_temp.tablet(1));
select session_ziel_kind(:'s') as zk \gset
select is(:'zk'::jsonb ->> 'fall', 'schulthema', '5 Schulthema nach der Wahl');
select is(:'zk'::jsonb ->> 'thema_label', 'ZZ Terme', '5 Thema-Label');
select is((select array_agg(f ->> 'label' order by o) from jsonb_array_elements(:'zk'::jsonb -> 'fertigkeiten') with ordinality x(f, o)),
          array['ZZ Klammern ausmultiplizieren', 'ZZ Ausklammern'], '5 ab dem aktuellen Skill, sichere Voraussetzungen davor fehlen');
select is((select array_agg((f ->> 'aktuell') || '/' || (f ->> 'neu') order by o)
             from jsonb_array_elements(:'zk'::jsonb -> 'fertigkeiten') with ordinality x(f, o)),
          array['true/false', 'false/true'], '5 aktuell und neu richtig (s1 hat Belege, s2 nicht)');
select ok((select bool_and((select array_agg(k order by k) from jsonb_object_keys(f) k) = array['aktuell', 'label', 'neu'])
             from jsonb_array_elements(:'zk'::jsonb -> 'fertigkeiten') f), '5 je Fertigkeit nur label, aktuell, neu (kein Stand, kein Prozent)');
select ok(jsonb_array_length(:'zk'::jsonb -> 'fertigkeiten') <= 3, '5 hoechstens drei');
select pg_temp.act_as(pg_temp.tablet(2));
select is(jsonb_array_length((session_ziel_kind(:'s')) -> 'fertigkeiten'), 1, '5 Lernpfad: ein Skill');

-- ── 2) und 3) Pruefrage ───────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_v1')$$, :'s', :'k_emir'), '42501', null, '2 Tablet -> 42501');
select pg_temp.act_as(:'coach_b');
select throws_ok(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_v1')$$, :'s', :'k_emir'), '42501', null, '2 fremder Coach -> 42501');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_s2')$$, :'s', :'k_emir'), 'P0002', null,
                 '2 ohne freigegebene Pruefung (nur Entwurf) -> Fehler');
select is((pruefung_aufs_tablet(:'s', :'k_emir', 'zz_a2_v1')) ->> 'aktiv', 'true', '2 Coach legt die Frage aufs Tablet');
select pg_temp.act_as(pg_temp.tablet(1));
select tablet_stand() as ts \gset
select is((select array_agg(k order by k) from jsonb_object_keys(:'ts'::jsonb -> 'pruefung') k), array['frage', 'skill_label'],
          '3 tablet_stand.pruefung: nur skill_label und frage');
select ok(:'ts' like '%ZZ-FRAGE-V1%' and :'ts' not like '%ERWARTUNG%' and :'ts' not like '%KRITERIUM%',
          '3 Frage ja, Erwartung und Kriterium nie');
select pg_temp.act_as(:'coach_a');
select is((coach_raum_live(:'s') -> 'kinder' -> 0 -> 'pruefung_auf_tablet' ->> 'skill_key'), 'zz_a2_v1',
          '3 coach_raum_live zeigt pruefung_auf_tablet');
select pruefung_aufs_tablet(:'s', :'k_emir', 'zz_a2_v2');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung' ->> 'skill_label', 'ZZ Proportionale Zuordnung', '3 eine neue Frage ersetzt die alte');
select pg_temp.act_as(:'coach_a');
select pruefung_vom_tablet(:'s', :'k_emir');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung', 'null'::jsonb, '3 nach pruefung_vom_tablet: null');
select pg_temp.act_as(:'coach_a');
select pruefung_aufs_tablet(:'s', :'k_emir', 'zz_a2_v1');
select mastery_entscheiden(:'k_emir', 'zz_a2_v1', 'gemeistert', null, :'s');
select mastery_entscheiden(:'k_emir', 'zz_a2_v2', 'vertagt', 'ZZ ging nur mit Hilfe', :'s');
select pg_temp.act_as(pg_temp.tablet(1));
select tablet_stand() as ts2 \gset
select is(:'ts2'::jsonb -> 'pruefung', 'null'::jsonb, '3 nach mastery_entscheiden: null');

-- ── 4) bestaetigt ─────────────────────────────────────────────────────────
select is((select array_agg(b ->> 'skill_key') from jsonb_array_elements(:'ts2'::jsonb -> 'bestaetigt') b), array['zz_a2_v1'],
          '4 gemeistert in dieser Session erscheint, vertagt nicht');
select is((:'ts2'::jsonb -> 'bestaetigt' -> 0 ->> 'skill_label'), 'ZZ Minus vor der Klammer', '4 mit Label');
update lernpfad set stand_coach = 'gemeistert', coach_am = now(), coach_session_id = :'s_alt'
 where student_id = :'k_deniz' and skill_key = 'zz_a2_v1';
select pg_temp.act_as(pg_temp.tablet(2));
select is(jsonb_array_length((tablet_stand()) -> 'bestaetigt'), 0, '4 gemeistert in einer anderen Session erscheint nicht');

-- Zeitbindung: laufende Session 31 Minuten nach dem geplanten Ende.
select pg_temp.als_system();
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach_a', 'ZZ A2b vorbei', now() - interval '91 minutes', 'active', now() - interval '91 minutes') returning id as s_vorbei \gset
insert into session_students (session_id, student_id, attendance) values (:'s_vorbei', :'k_ida', 'present');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_v1')$$, :'s_vorbei', :'k_ida'), '42501', null,
                 '2 ausserhalb der Zeitbindung -> Fehler');

-- ── R) Regeln und 7)/8) XP und Abschluss ──────────────────────────────────
-- Jonas: neuer Skill mit Erklaersequenz (Check, Beispiel), dann Kernarbeit, dann Check-out.
select pg_temp.stell('session_xp_je_aufgabe', '10');
select pg_temp.neue_session(array[:'k_jonas', :'k_ida']::uuid[], 6) as s7 \gset
select pg_temp.stell('session_xp_je_aufgabe', '30');
select is((select einstellungen ->> 'session_xp_je_aufgabe' from coaching_sessions where id = :'s7'), '10', '7 Snapshot: 10');
select pg_temp.checkin(:'s7', 1), pg_temp.checkin(:'s7', 2);
select pg_temp.schritt_tablet(:'s7', 1) as w1 \gset
select is(:'w1'::jsonb ->> 'phase', 'warmup', 'R Warm-up-Aufgabe');
select is(:'w1'::jsonb ->> 'hinweise_erlaubt', 'false', 'R im Warm-up: hinweise_erlaubt = false (Entscheidung 32)');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select hinweis_abrufen(%L, %L, 1)', :'s7', :'w1'::jsonb ->> 'task_id'), '22023', null,
                 'R im Warm-up liefert hinweis_abrufen keinen Hinweis');
select pg_temp.antwort(:'s7', 1, true);
select pg_temp.loese(:'s7', 1, true), pg_temp.loese(:'s7', 1, true);
select pg_temp.uhr(:'s7', 20);
select is(pg_temp.schritt(:'s7', 1) ->> 'art', 'erklaerung', '7 Kernarbeit beginnt mit der Erklaersequenz');
select pg_temp.act_as(pg_temp.tablet(1));
select (erklaer_start(:'s7', :'k_jonas', 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk \gset
select pg_temp.act_as(pg_temp.tablet(1));
select erklaer_check_abgeben(:'s7', :'k_jonas', :'chk', '{"text":"7"}');
select is(pg_temp.schritt(:'s7', 1) ->> 'art', 'beispiel', '7 danach ein Loesungsbeispiel');
select pg_temp.schritt_tablet(:'s7', 1) as k1 \gset
select is(:'k1'::jsonb ->> 'hinweise_erlaubt', 'true', 'R in der Kernarbeit: hinweise_erlaubt = true');
select pg_temp.antwort(:'s7', 1, true, true);
select pg_temp.loese(:'s7', 1, false), pg_temp.loese(:'s7', 1, true), pg_temp.loese(:'s7', 1, true), pg_temp.loese(:'s7', 1, true);
-- Ida beantwortet eine Aufgabe und bekommt nie "fertig".
select pg_temp.loese(:'s7', 2, true);
select pg_temp.uhr(:'s7', 56);
select pg_temp.schritt_tablet(:'s7', 1) as e1 \gset
select is(:'e1'::jsonb ->> 'art', 'exit', 'R Check-out: Exit-Aufgabe');
select is(:'e1'::jsonb ->> 'hinweise_erlaubt', 'false', 'R Exit: hinweise_erlaubt = false');
select pg_temp.antwort(:'s7', 1, false) as ea \gset
select is(:'ea'::jsonb, '{"gespeichert": true, "versuch_nr": 1}'::jsonb, 'R Exit: nur neutrale Rueckmeldung, kein Ergebnis, kein Fehlbild');
select pg_temp.loese(:'s7', 1, true);
select is((select count(*)::int from xp_events where student_id = :'k_jonas'), 0, '7 vor "fertig" nichts gebucht');
select is(pg_temp.schritt(:'s7', 1) ->> 'art', 'fertig', '7 fertig');
select (select count(*) from session_schritte x where x.session_id = :'s7' and x.student_id = :'k_jonas'
          and x.art in ('aufgabe', 'exit')) * 10 as xp_soll \gset
select results_eq(format($$select xp, reason, buchungs_schluessel from xp_events where student_id = %L$$, :'k_jonas'),
                  format($$values (%s, 'session'::text, %L::text)$$, :'xp_soll', 'session:' || :'s7'),
                  '7 fertig bucht Anzahl erledigter Aufgaben mal 10 (Snapshot) genau einmal');
select ok((select count(*) >= 1 from session_schritte where session_id = :'s7' and student_id = :'k_jonas' and art = 'beispiel')
          and (select count(*) >= 1 from session_ereignisse where session_id = :'s7' and student_id = :'k_jonas' and typ = 'check'),
          '7 Beispiel und Check gab es, sie zaehlen nicht mit (xp_soll zaehlt nur aufgabe und exit)');
select pg_temp.schritt(:'s7', 1);
select is((select count(*)::int from xp_events where student_id = :'k_jonas'), 1, '7 ein zweiter Aufruf bucht nicht');
select pg_temp.act_as(pg_temp.tablet(1));
select session_abschluss_kind(:'s7') as ak \gset
select is((:'ak'::jsonb ->> 'xp')::int, :xp_soll, '8 Abschluss: xp gleich der Buchung');
select ok((select count(*) = 1 from session_schritte where session_id = :'s7' and student_id = :'k_jonas' and phase = 'kern'
            and eingemischt and skill_key = 'zz_a2_v2'), '8 es gab eine eingemischte Aufgabe (zz_a2_v2) in der Kernarbeit');
select ok(not ((:'ak'::jsonb -> 'geuebt') ? 'ZZ Proportionale Zuordnung'), '8 Abschluss: eingemischte Skills fehlen');
select ok((:'ak'::jsonb -> 'geuebt') ? 'ZZ Steigung', '8 Abschluss: der geuebte Skill steht drin');
select is((:'ak'::jsonb ->> 'naechste_session') is null, true, '8 ohne weitere Buchung: naechste_session null');
select pg_temp.act_as(:'coach_a');
select session_abschliessen(:'s7');
select is((select xp from xp_events where student_id = :'k_ida'), 10, '7 session_abschliessen bucht fuer ein anwesendes Kind ohne fertig');
select is((select count(*)::int from xp_events where student_id = :'k_jonas'), 1, '7 session_abschliessen bucht kein zweites Mal');

-- Emir: naechste gebuchte Session (Abschluss-Sicht in der ersten Session).
select pg_temp.neue_session(array[:'k_emir']::uuid[], 20) as s8 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select is(((session_abschluss_kind(:'s8')) ->> 'naechste_session')::timestamptz,
          (select scheduled_at from coaching_sessions where id = :'s_next'), '8 naechste gebuchte Session');
select pg_temp.act_as(:'coach_a');
select session_abschliessen(:'s8');
select is((select count(*)::int from xp_events where student_id = :'k_emir'), 0, '7 anwesend, aber 0 Aufgaben: keine Buchung');

-- Testlauf bucht nie.
select pg_temp.neue_session(array[:'k_tim']::uuid[], 20, true) as s9 \gset
select pg_temp.checkin(:'s9', 1);
select pg_temp.loese(:'s9', 1, true), pg_temp.loese(:'s9', 1, true);
select pg_temp.act_as(:'coach_a');
select session_abschliessen(:'s9');
select is((select count(*)::int from xp_events where student_id = :'k_tim'), 0, '7 Testlauf bucht nie');

select * from finish();
rollback;
