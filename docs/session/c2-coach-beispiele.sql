-- C2: Coach-Beispiele (echtes JSON) fuer die Vitest-Fixtures der Coach-Live-Sicht.
-- Erzeugt src/lib/session/coachLiveFixtures.json: ein Objekt {name: Antwort}.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen + supabase/seed.sql), nie gegen Produktion. Laeuft in
-- begin … rollback und legt alle Daten selbst an (ZZ). Aufruf aus dem Repo-Wurzelverzeichnis:
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 -d <wegwerf-db> \
--     -f docs/session/c2-coach-beispiele.sql | sed -n '/^{/,/^}$/p' > src/lib/session/coachLiveFixtures.json
\set QUIET on
begin;
\ir ../../supabase/tests/session_a2_fixture.sql
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('zz_a2_v2', '3 Hefte kosten 4,50 €. Erklär mir, wie du den Preis für 7 Hefte findest.',
   'Erst der Preis für ein Heft, dann mal 7.', 'Weg selbst erklärt, ohne Hilfe', 'freigegeben', 'mensch');
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_a2_vz', 'Nur das erste Vorzeichen geändert', now());
select pg_temp.kind_mit('Emir Beispiel', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k,
       pg_temp.kind_mit('Deniz Beispiel', 'zz_a2_linear', '{zz_a2_v1}') as k2,
       pg_temp.kind_mit('Tim Test', 'zz_a2_terme', '{zz_a2_v1}', '{}', true) as kt
\gset
update lernpfad set stand_system = 'kandidat' where student_id = :'k' and skill_key = 'zz_a2_v2';
update lead_themen set angelegt = now() - interval '30 days'
 where lead_id = (select id from leads where converted_student_id = :'k2');
update task_solutions set acceptance = '{"canonical":"7","known_errors":{"0":"zz_a2_vz"}}'
 where task_id in (select id from tasks where skill_key in ('zz_a2_s1', 'zz_a2_v1', 'zz_a2_v2'));

create temp table aus (name text primary key, j jsonb);
create function pg_temp.zeig(p_name text, p_j jsonb) returns void language sql as $$
  insert into aus (name, j) values (p_name, p_j) $$;

select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'Raum 1', now()) returning id as s \gset
insert into session_students (session_id, student_id) values (:'s', :'k'), (:'s', :'k2');
insert into coaching_sessions (coach_id, room, scheduled_at)
values (:'coach_a', 'Raum 1', date_trunc('day', now()) + interval '7 days 16 hours 30 minutes') returning id as s_next \gset
insert into session_students (session_id, student_id) values (:'s_next', :'k');
-- Eine vergessene Session von gestern (offen).
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'Raum 2', now() - interval '1 day');

select pg_temp.act_as(:'coach_a');
select pg_temp.zeig('briefing', public.session_briefing(:'s'));
select pg_temp.zeig('raum_vorher', public.coach_raum_live(:'s'));
select pg_temp.stell('home_quests_aktiv', 'true');
select pg_temp.act_as(:'coach_a');
select public.session_starten(:'s') is not null;
select pg_temp.stell('home_quests_aktiv', 'false');
select pg_temp.act_as(:'coach_a');
select public.tablet_zuweisen(:'s', :'k', 1) is not null;
select pg_temp.uhr(:'s', 1);
select pg_temp.act_as(pg_temp.tablet(1));
select public.checkin_kind_speichern(:'s', 'gut', null, null, 'noch_dran') is not null;
select pg_temp.act_as(:'coach_a');
select public.checkin_coach_setzen(:'s', :'k', 'schulthema') is not null;
select pg_temp.uhr(:'s', 20);
select pg_temp.loese(:'s', 1, false) is not null;
select pg_temp.loese(:'s', 1, true, true) is not null;
select pg_temp.schritt(:'s', 1) is not null;
select pg_temp.act_as(:'coach_a');
select public.eingriff_notieren(:'s', :'k', 3, 'zz_a2_vz') is not null;
select public.pruefung_aufs_tablet(:'s', :'k', 'zz_a2_v2') is not null;
select pg_temp.zeig('raum_kern', public.coach_raum_live(:'s'));
select pg_temp.zeig('detail_kern', public.coach_kind_detail(:'s', :'k'));
select pg_temp.zeig('ziel_kern', (select jsonb_agg(to_jsonb(x)) from public.ziel_fertigkeiten(:'k', 'zz_a2_terme') x));
select pg_temp.zeig('pruefung_v2', (select jsonb_agg(to_jsonb(x)) from public.skill_pruefung_lesen('zz_a2_v2') x));
select pg_temp.zeig('lernpfad_v2', (select to_jsonb(l) from lernpfad l where l.student_id = :'k' and l.skill_key = 'zz_a2_v2'));
select public.mastery_entscheiden(:'k', 'zz_a2_v2', 'gemeistert', null, :'s') is not null;
select pg_temp.zeig('raum_gemeistert', public.coach_raum_live(:'s'));

select pg_temp.uhr(:'s', 56);
select pg_temp.loese(:'s', 1, true) is not null;
select pg_temp.act_as(:'coach_a');
select public.abschluss_setzen(:'s', :'k', 'Du hast heute konzentriert gearbeitet.', true, 'Kam gut voran', false, true) is not null;
select pg_temp.zeig('raum_checkout', public.coach_raum_live(:'s'));
select pg_temp.zeig('satz', public.satz_vorschlaege(:'s', :'k'));

select pg_temp.neue_session(array[:'kt']::uuid[], 20, true) as st \gset
select pg_temp.act_as(:'coach_a');
select pg_temp.zeig('raum_testlauf', public.coach_raum_live(:'st'));
select pg_temp.act_as(:'admin');
select pg_temp.zeig('offen_admin', (select jsonb_agg(to_jsonb(o)) from public.sessions_offen() o));

-- Fehler, wie PostgREST sie meldet (code = SQLSTATE, hint = Hinweis-Code).
select pg_temp.act_as(:'coach_b');
do $$
declare v_s uuid := (select id from coaching_sessions where room = 'Raum 1' order by scheduled_at limit 1);
begin
  begin
    perform public.coach_raum_live(v_s);
  exception when others then
    perform pg_temp.zeig('fehler_fremder_coach', jsonb_build_object('code', sqlstate, 'message', sqlerrm, 'hint', null));
  end;
end $$;
select pg_temp.act_as(:'coach_a');
do $$
declare v_s uuid := (select id from coaching_sessions where room = 'Raum 1' order by scheduled_at limit 1);
        v_k uuid := (select student_id from session_students where session_id = v_s order by student_id limit 1);
        v_hint text;
begin
  begin
    perform public.tablet_zuweisen(v_s, (select student_id from session_students where session_id = v_s
                                          and student_id <> (select student_id from session_tablets where session_id = v_s
                                                              and geloest_am is null limit 1) limit 1), 1);
  exception when others then
    get stacked diagnostics v_hint = pg_exception_hint;
    perform pg_temp.zeig('fehler_nicht_gebucht', jsonb_build_object('code', sqlstate, 'message', sqlerrm, 'hint', v_hint));
  end;
end $$;

\unset QUIET
select jsonb_pretty(jsonb_object_agg(name, j)) from aus;
rollback;
