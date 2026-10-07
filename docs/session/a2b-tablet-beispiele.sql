-- A2b: Tablet-Beispiele. Ein Kind in einer Session, Aufruf fuer Aufruf so, wie das Tablet sie macht.
-- Erzeugt die JSON-Beispiele in docs/session/a2b-tablet-beispiele.md.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen + supabase/seed.sql), nie gegen Produktion. Laeuft in
-- begin … rollback und legt alle Daten selbst an (ZZ). Aufruf aus dem Repo-Wurzelverzeichnis:
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 -d <wegwerf-db> \
--     -f docs/session/a2b-tablet-beispiele.sql
--
-- Ausgabe: Zeilen "### <Titel>" gefolgt vom JSON des Aufrufs.
\set QUIET on
begin;
\ir ../../supabase/tests/session_a2_fixture.sql
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('zz_a2_v2', '3 Hefte kosten 4,50 €. Erklär mir, wie du den Preis für 7 Hefte findest.', 'nur Coach', 'nur Coach', 'freigegeben', 'mensch');
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_a2_vz', 'Nur das erste Vorzeichen geändert', now());
select pg_temp.kind_mit('Emir Beispiel', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k \gset
-- v2 ist Mastery-Kandidat aus frueheren Sessions; das Warm-up bleibt bei v1.
update lernpfad set stand_system = 'kandidat' where student_id = :'k' and skill_key = 'zz_a2_v2';
-- Falsche Antwort "0" mit Fehlbild fuer alle Aufgaben von s1 (damit das Beispiel einen Klartext zeigt).
update task_solutions set acceptance = '{"canonical":"7","known_errors":{"0":"zz_a2_vz"}}'
 where task_id in (select id from tasks where skill_key in ('zz_a2_s1', 'zz_a2_v1', 'zz_a2_v2'));

create temp table aus (nr serial, titel text, j jsonb);
create function pg_temp.zeig(p_titel text, p_j jsonb) returns void language sql as $$
  insert into aus (titel, j) values (p_titel, p_j) $$;

-- Session (kein Testlauf), Home Quests eingeschaltet, Tablet 1 noch nicht zugewiesen.
select pg_temp.stell('home_quests_aktiv', 'true');
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at)
values (:'coach_a', 'Raum 1', now()) returning id as s \gset
insert into session_students (session_id, student_id) values (:'s', :'k');
insert into coaching_sessions (coach_id, room, scheduled_at)
values (:'coach_a', 'Raum 1', date_trunc('day', now()) + interval '7 days 16 hours 30 minutes') returning id as s_next \gset
insert into session_students (session_id, student_id) values (:'s_next', :'k');
select pg_temp.act_as(:'coach_a');
select public.session_starten(:'s') is not null;
select pg_temp.stell('home_quests_aktiv', 'false');

select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('tablet_stand() — Tablet ohne Zuweisung', public.tablet_stand());

select pg_temp.act_as(:'coach_a');
select public.tablet_zuweisen(:'s', :'k', 1) is not null;
select pg_temp.uhr(:'s', 1);
select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('tablet_stand() — zugewiesen, Check-in offen', public.tablet_stand());
select pg_temp.zeig('session_kind_kontext(session_id)', public.session_kind_kontext(:'s'));
select pg_temp.zeig('session_naechster_schritt(session_id, null) — vor dem Check-in', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('checkin_kind_speichern(session_id, ''gut'', null, null, ''noch_dran'')',
  public.checkin_kind_speichern(:'s', 'gut', null, null, 'noch_dran'));
select pg_temp.zeig('session_naechster_schritt — Warm-up-Aufgabe', public.session_naechster_schritt(:'s', null)) ;
select pg_temp.zeig('antwort_abgeben(session_id, task_id, null, ''"7"'') — richtig',
  public.antwort_abgeben(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, null, '"7"'));
select pg_temp.zeig('session_naechster_schritt — nächste Warm-up-Aufgabe', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('antwort_abgeben(…, ''"0"'') — falsch, mit Fehlbild-Klartext',
  public.antwort_abgeben(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, null, '"0"'));

-- Coach waehlt den Fall; die Uhr steht in der Kernarbeit.
select pg_temp.act_as(:'coach_a');
select public.checkin_coach_setzen(:'s', :'k', 'schulthema') is not null;
select pg_temp.uhr(:'s', 20);
select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('session_ziel_kind(session_id)', public.session_ziel_kind(:'s'));
select pg_temp.zeig('session_naechster_schritt — Aufgabe in der Kernarbeit', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('hinweis_abrufen(session_id, task_id, 1)',
  public.hinweis_abrufen(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, 1));
select pg_temp.zeig('antwort_abgeben — richtig nach Hinweis',
  public.antwort_abgeben(:'s', (select j ->> 'task_id' from aus where titel like 'session_naechster_schritt — Aufgabe in der Kern%')::uuid, null, '"7"'));

select pg_temp.act_as(:'coach_a');
select public.pruefung_aufs_tablet(:'s', :'k', 'zz_a2_v2') is not null;
select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('tablet_stand() — Prüffrage liegt auf dem Tablet', public.tablet_stand());
select pg_temp.act_as(:'coach_a');
select public.mastery_entscheiden(:'k', 'zz_a2_v2', 'gemeistert', null, :'s') is not null;
select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('tablet_stand() — nach „gemeistert“ durch den Coach', public.tablet_stand());

-- Check-out.
select pg_temp.uhr(:'s', 56);
select pg_temp.zeig('session_naechster_schritt — Exit-Aufgabe', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('antwort_abgeben — Exit (neutral)',
  public.antwort_abgeben(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, null, '"0"'));
select pg_temp.zeig('session_naechster_schritt — zweite Exit-Aufgabe', public.session_naechster_schritt(:'s', null));
select public.antwort_abgeben(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, null, '"7"') is not null;
select pg_temp.zeig('session_naechster_schritt — Termin wählen (Home Quests an)', public.session_naechster_schritt(:'s', null));
select public.quest_termin_setzen(:'s', null, ((current_date + 2) + time '17:00') at time zone 'Europe/Berlin');
select pg_temp.zeig('quest_termin_setzen(session_id, null, termin) — R1-Fassung, Quest A (liefert void)', 'null'::jsonb);
select pg_temp.zeig('session_naechster_schritt — fertig', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('session_abschluss_kind(session_id)', public.session_abschluss_kind(:'s'));

select pg_temp.act_as(pg_temp.tablet(2));
select set_config('a2b.s', :'s', true);
do $$
begin
  perform public.session_ziel_kind(current_setting('a2b.s')::uuid);
exception when others then
  perform pg_temp.zeig('Fehler: session_ziel_kind von einem Tablet ohne Platz in dieser Session',
                       jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
end $$;

\unset QUIET
select '### ' || titel || E'\n' || jsonb_pretty(j) from aus order by nr;
rollback;
