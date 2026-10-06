-- Session-Rahmen P1, Paket A1 — Durchlauf in einer Wegwerf-DB
--
-- Weg: LSA → Lernpfad → Belege aus zwei Sessions → Kandidat → gemeistert.
-- Ein Testkind wie Deniz im Coach-Live-Dummy: in der LSA Prozentwert sicher,
-- Grundwert noch nicht sicher. Echte Skills aus dem Katalog (prozent_*).
--
-- NUR in einer Wegwerf-DB aus allen Migrationen ausfuehren, nie gegen
-- Produktion. Alles laeuft in einer Transaktion und wird am Ende verworfen.
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -v ON_ERROR_STOP=1 \
--     -h localhost -p 55433 -U postgres -d <wegwerf-db> -f docs/session/a1-durchlauf.sql

\pset pager off
\pset footer off
begin;

\set admin_uid 'a1d0d0d0-0001-4000-8000-000000000001'
\set coach_uid 'a1d0d0d0-0001-4000-8000-000000000002'
\set kind_uid  'a1d0d0d0-0001-4000-8000-000000000003'
\set lead_id   'a1d0d0d0-0002-4000-8000-000000000001'
\set kind      'a1d0d0d0-0003-4000-8000-000000000001'
\set lsa       'a1d0d0d0-0004-4000-8000-000000000001'
\set s1        'a1d0d0d0-0005-4000-8000-000000000001'
\set s2        'a1d0d0d0-0005-4000-8000-000000000002'

\echo '== Aufbau: Coach, Testkind mit laufendem Vertrag, zwei gebuchte Sessions, eine LSA'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'a1d-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'a1d-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'a1d-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'a1d-admin@test.local', 'admin',   'Durchlauf Admin'),
  (:'coach_uid', 'a1d-coach@test.local', 'coach',   'Sara Durchlauf'),
  (:'kind_uid',  'a1d-kind@test.local',  'student', 'Deniz Durchlauf');

-- Vertrag und Buchung ohne Trigger, damit der Durchlauf nicht vom Vertragsablauf abhaengt.
set local session_replication_role = replica;
insert into leads (id, full_name, class_level, subjects, status)
values (:'lead_id', 'Deniz Durchlauf', 9, '{Mathematik}', 'contacted');
insert into students (id, profile_id, class_level, is_provisional, lead_id)
values (:'kind', :'kind_uid', 9, true, :'lead_id');
insert into vertraege (lead_id, student_id, status, vertrag_status, abgeschlossen_am,
                       vertragsbeginn, vertrag_ende, widerruf_bis)
values (:'lead_id', :'kind', 'abgeschlossen', 'aktiv',
        (date_trunc('month', current_date) - interval '2 months')::date,
        (date_trunc('month', current_date) - interval '1 month')::date,
        (date_trunc('month', current_date) + interval '11 months')::date - 1,
        (date_trunc('month', current_date) - interval '1 month')::date + 14);
insert into coaching_sessions (id, coach_id, scheduled_at, status) values
  (:'s1', :'coach_uid', now() - interval '7 days', 'done'),
  (:'s2', :'coach_uid', now(), 'upcoming');
insert into session_students (session_id, student_id, attendance) values
  (:'s1', :'kind', 'present'), (:'s2', :'kind', 'present');
set local session_replication_role = origin;

insert into lsa_sessions (id, student_id, subject, grade, status, completed_at, modus, thema_key)
values (:'lsa', :'kind', 'mathematik', 9, 'completed', now() - interval '14 days', 'adaptiv', 'zinsrechnung');
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl) values
  (:'lsa', 'prozent_prozentwert',    'traegt',           true,  false, 2),
  (:'lsa', 'prozent_grundwert',      'traegt_nicht',     true,  false, 2),
  (:'lsa', 'proportionalitaet',      'traegt',           false, false, 0),
  (:'lsa', 'dezimal_mult',           'traegt',           true,  false, 1),
  (:'lsa', 'gleichung_einschrittig', 'traegt',           true,  false, 1),
  (:'lsa', 'prozent_prozentsatz',    'ungeprueft',       false, false, 0);

-- Pruefgespraech fuer Grundwert (in P2 von Lena geprueft und vom Admin freigegeben).
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('prozent_grundwert',
   'Im Schlussverkauf kostet eine Jacke 42 €, das sind 70 % des alten Preises. Wie teuer war sie vorher? Erklär mir deinen Weg.',
   'Erkennt 42 € als Prozentwert zu 70 %, rechnet 1 % = 0,60 € und 100 % = 60 €.',
   'Richtig geloest und den Weg ohne Hilfe erklaert.', 'freigegeben', 'mensch'),
  ('prozent_grundwert', 'Entwurf, darf nicht erscheinen', 'E', 'K', 'entwurf', 'ki');

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

select pg_temp.als(:'coach_uid') \g /dev/null

\echo
\echo '== 1. Erste Session nach der LSA, Lernpfad noch leer: naechste_luecke kommt aus den Urteilen'
select * from public.naechste_luecke(:'kind');

\echo '== 2. Uebernahme LSA → Lernpfad (Coach)'
select public.lernpfad_aus_lsa(:'kind') as ergebnis;
select skill_key, stand_system, stand_coach, quelle from lernpfad where student_id = :'kind' order by skill_key;

\echo '== 3. Ziel der Stunde fuer das Thema Zinsrechnung'
select reihenfolge, skill_key, label, rolle, stand, pruefung_faellig from public.ziel_fertigkeiten(:'kind', 'zinsrechnung');

\echo '== 4. Session 1 (vor 7 Tagen): Grundwert 1× falsch, 1× richtig mit Hinweis, 2× richtig ohne Hinweis'
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s1', 'falsch',  false) as stand_nach_beleg;
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s1', 'richtig', true);
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s1', 'richtig', false);
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s1', 'richtig', false);

\echo '== 5. Session 2 (heute): Grundwert 2× richtig ohne Hinweis → Mastery-Kandidat'
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s2', 'richtig', false) as stand_nach_beleg;
select public.lernpfad_beleg(:'kind', 'prozent_grundwert', :'s2', 'richtig', false);
select skill_key, stand_system, stand_coach, belege from lernpfad
 where student_id = :'kind' and skill_key = 'prozent_grundwert';

\echo '== 6. Das Kind sieht den Kandidaten als „sicher“ (nie Meisterschaft ohne Coach)'
select pg_temp.als(:'kind_uid') \g /dev/null
select * from public.mein_lernpfad() where skill_key = 'prozent_grundwert';

\echo '== 7. Coach: Vorschlag, Pruefgespraech (nur freigegeben) und Entscheidung „gemeistert“'
select pg_temp.als(:'coach_uid') \g /dev/null
select skill_key, label, stand_coach from public.mastery_vorschlaege(:'kind');
select frage, kriterium from public.skill_pruefung_lesen('prozent_grundwert');
select public.mastery_entscheiden(:'kind', 'prozent_grundwert', 'gemeistert', null, :'s2') as ergebnis;
select skill_key, stand_system, stand_coach, coach_session_id = :'s2' as in_session_2 from lernpfad
 where student_id = :'kind' and skill_key = 'prozent_grundwert';
select aktion, anlass, skill_key, alt, neu from lernpfad_protokoll
 where student_id = :'kind' and aktion <> 'uebernahme' order by am;

\echo '== 8. Das Kind sieht jetzt „gemeistert“'
select pg_temp.als(:'kind_uid') \g /dev/null
select * from public.mein_lernpfad() where skill_key = 'prozent_grundwert';

\echo '== 9. Naechste Luecke nach der Bestaetigung'
select pg_temp.als(:'coach_uid') \g /dev/null
select * from public.naechste_luecke(:'kind');

rollback;
