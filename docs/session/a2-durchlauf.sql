-- A2-Durchlauf: eine Testlauf-Session mit drei Kindern wie im Coach-Live-Dummy, von session_starten bis
-- session_abschliessen, mit festgelegten Antworten. Grundlage fuer das Gespraech mit Fatih.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen), nie gegen Produktion. Laeuft in begin … rollback und legt
-- alle Daten selbst an (ZZ). Aufruf aus dem Repo-Wurzelverzeichnis:
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -v ON_ERROR_STOP=1 -d <wegwerf-db> -f docs/session/a2-durchlauf.sql
--
-- Kinder (alle Testkonten, die Session ist ein Testlauf, es entstehen keine Lernpfad-Belege):
--   Tablet 1  Lea    Klassenarbeit in zwei Tagen, Thema "Quadratische Gleichungen"; Binomische Formeln sicher.
--   Tablet 2  Jonas  Schulthema "Lineare Funktionen"; Steigung ist neu und hat eine freigegebene Erklaersequenz.
--   Tablet 3  Deniz  kein Thema, erste Session nach der LSA: Proportionale Zuordnung sicher, Klammern noch nicht.
--                    Kommt sechs Minuten zu spaet; zwei Fehler im Warm-up -> Entscheidung, Coach bleibt beim Plan;
--                    zwei Fehlversuche in Folge in der Kernarbeit -> "haengt".
\pset footer off
\set QUIET on
begin;
\ir ../../supabase/tests/session_a2_fixture.sql

select pg_temp.kind_mit('Lea', null, '{zz_a2_k2,zz_a2_v1}', '{zz_a2_k1}', true) as lea,
       pg_temp.kind_mit('Jonas', 'zz_a2_linear', '{zz_a2_v2}', '{}', true) as jonas,
       pg_temp.kind_mit('Deniz', null, '{}', '{}', true) as deniz
\gset
-- Deniz: abgeschlossene LSA (kein Testlauf) mit Urteilen; noch keine Lernpfad-Zeilen.
insert into lsa_sessions (student_id, subject, grade, status, completed_at, modus)
values (:'deniz', 'mathematik', 8, 'completed', now() - interval '14 days', 'adaptiv') returning id as lsa \gset
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl) values
  (:'lsa', 'zz_a2_v2', 'traegt', true, false, 2), (:'lsa', 'zz_a2_s1', 'traegt_nicht', true, false, 3);

-- Session (Testlauf) mit Lea und Jonas auf Tablet 1 und 2; Deniz ist gebucht, bekommt sein Tablet spaeter.
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at)
values (:'coach_a', 'Raum 1', date_trunc('day', now()) + interval '16 hours 30 minutes') returning id as s \gset
insert into session_students (session_id, student_id) values (:'s', :'lea'), (:'s', :'jonas'), (:'s', :'deniz');
select public.session_testlauf_setzen(:'s', true);
select pg_temp.act_as(:'coach_a');
select public.session_starten(:'s') is not null as gestartet;
select public.tablet_zuweisen(:'s', :'lea', 1), public.tablet_zuweisen(:'s', :'jonas', 2);

create temp table protokoll (nr serial, minute numeric, kind text, j jsonb);
create temp table signale (minute numeric, kind text, art text, grund text);
-- Momentaufnahme der Warteschlange, wie der Coach sie sieht (raum_signale rechnet aus Antworten,
-- Ereignissen und Stellschrauben).
create function pg_temp.warteschlange(p_s uuid, p_min numeric) returns void language plpgsql as $$
begin
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  insert into signale select p_min, (select case t.tablet_nr when 1 then 'Lea' when 2 then 'Jonas' else 'Deniz' end
                                       from session_tablets t where t.session_id = p_s and t.student_id = r.student_id
                                        and t.geloest_am is null), r.art, r.grund
    from public.raum_signale(p_s) r;
end $$;
create function pg_temp.name(p_tablet int) returns text language sql as $$
  select case p_tablet when 1 then 'Lea' when 2 then 'Jonas' else 'Deniz' end $$;
-- Ein Schritt um Minute p_min: Uhr stellen, Schritt holen, protokollieren, Aufgabe beantworten.
create function pg_temp.dl(p_s uuid, p_min numeric, p_tablet int, p_richtig boolean default true, p_hinweis boolean default false)
returns void language plpgsql as $$
declare v jsonb;
begin
  perform pg_temp.uhr(p_s, p_min);
  v := pg_temp.schritt(p_s, p_tablet);
  insert into protokoll (minute, kind, j) values (p_min, pg_temp.name(p_tablet), v);
  if v ->> 'art' in ('aufgabe', 'exit') then perform pg_temp.antwort(p_s, p_tablet, p_richtig, p_hinweis); end if;
end $$;

-- 16:31 Check-in am Tablet (Lea: Klassenarbeit uebermorgen).
select pg_temp.uhr(:'s', 1);
select pg_temp.checkin(:'s', 1, current_date + 2, 'zz_a2_quad'), pg_temp.checkin(:'s', 2);

-- 16:32 bis 16:40 Warm-up. Deniz bekommt um 16:36 sein Tablet.
select pg_temp.dl(:'s', 2, 1), pg_temp.dl(:'s', 2, 2);
select pg_temp.dl(:'s', 4, 1), pg_temp.dl(:'s', 4, 2, true, true);
select pg_temp.act_as(:'coach_a');
select public.tablet_zuweisen(:'s', :'deniz', 3);
select pg_temp.uhr(:'s', 6);
select pg_temp.checkin(:'s', 3);
select pg_temp.dl(:'s', 6, 1), pg_temp.dl(:'s', 6, 2), pg_temp.dl(:'s', 7, 3);
select pg_temp.dl(:'s', 8, 1), pg_temp.dl(:'s', 8, 2), pg_temp.dl(:'s', 9, 3, false);
select pg_temp.dl(:'s', 10, 3, false), pg_temp.dl(:'s', 11, 1), pg_temp.dl(:'s', 11, 2);
select pg_temp.dl(:'s', 12, 3);
select pg_temp.warteschlange(:'s', 12);
-- 16:43 Coach Sara entscheidet bei Deniz: beim Plan bleiben (nicht eine Stufe tiefer).
select pg_temp.act_as(:'coach_a');
select public.pfad_entscheiden(:'s', :'deniz', 'plan');
select pg_temp.dl(:'s', 13, 3);

-- 16:45 bis 17:24 Kernarbeit.
select pg_temp.dl(:'s', 15, 1), pg_temp.dl(:'s', 15, 2), pg_temp.dl(:'s', 15, 3, false);
-- Jonas: Erklaersequenz am Tablet (erklaer_start, ein Check richtig).
select pg_temp.act_as(pg_temp.tablet(2));
select (public.erklaer_start(:'s', :'jonas', 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk \gset
select pg_temp.dl(:'s', 18, 2);
select pg_temp.act_as(pg_temp.tablet(2));
select public.erklaer_check_abgeben(:'s', :'jonas', :'chk', '{"text":"7"}') ->> 'aktion' as check_aktion;
select pg_temp.dl(:'s', 17, 1), pg_temp.dl(:'s', 18, 3, false);
select pg_temp.dl(:'s', 20, 1), pg_temp.dl(:'s', 21, 2), pg_temp.dl(:'s', 21, 3, false);
select pg_temp.warteschlange(:'s', 22);
select pg_temp.dl(:'s', 23, 1, false), pg_temp.dl(:'s', 24, 2), pg_temp.dl(:'s', 24, 3, true, true);
select pg_temp.dl(:'s', 26, 1), pg_temp.dl(:'s', 27, 2), pg_temp.dl(:'s', 27, 3);
select pg_temp.dl(:'s', 29, 1), pg_temp.dl(:'s', 30, 2), pg_temp.dl(:'s', 30, 3);
select pg_temp.dl(:'s', 32, 1), pg_temp.dl(:'s', 33, 2, false), pg_temp.dl(:'s', 33, 3);
select pg_temp.dl(:'s', 35, 1), pg_temp.dl(:'s', 36, 2), pg_temp.dl(:'s', 36, 3);
select pg_temp.dl(:'s', 38, 1), pg_temp.dl(:'s', 39, 2), pg_temp.dl(:'s', 39, 3);
select pg_temp.dl(:'s', 41, 1), pg_temp.dl(:'s', 42, 2), pg_temp.dl(:'s', 42, 3);
select pg_temp.dl(:'s', 44, 1), pg_temp.dl(:'s', 45, 2), pg_temp.dl(:'s', 45, 3);
select pg_temp.dl(:'s', 47, 1), pg_temp.dl(:'s', 48, 2), pg_temp.dl(:'s', 48, 3);
select pg_temp.dl(:'s', 50, 1), pg_temp.dl(:'s', 51, 2), pg_temp.dl(:'s', 51, 3);
select pg_temp.warteschlange(:'s', 52);

-- 17:25 bis 17:30 Check-out: je zwei Exit-Aufgaben, danach fertig (Home Quests aus).
select pg_temp.dl(:'s', 55, 1), pg_temp.dl(:'s', 55, 2), pg_temp.dl(:'s', 55, 3);
select pg_temp.dl(:'s', 56, 1), pg_temp.dl(:'s', 56, 2, false), pg_temp.dl(:'s', 56, 3);
select pg_temp.dl(:'s', 58, 1), pg_temp.dl(:'s', 58, 2), pg_temp.dl(:'s', 58, 3);

select pg_temp.act_as(:'coach_a');
select public.session_abschliessen(:'s') as abschluss;

\unset QUIET
\echo
\echo '== Durchlauf: was die Engine jedem Kind gab und warum =='
select to_char(cs.scheduled_at + p.minute * interval '1 minute', 'HH24:MI') as "Uhrzeit",
       p.kind as "Kind",
       case p.j ->> 'phase' when 'checkin' then 'Check-in' when 'warmup' then 'Warm-up'
                            when 'kern' then 'Kernarbeit' else 'Check-out' end as "Phase",
       p.j ->> 'art' as "art",
       coalesce(p.j ->> 'skill_label', '') as "Skill",
       coalesce(p.j ->> 'schwierigkeit', '') as "Schwierigkeit",
       case when (p.j ->> 'eingemischt')::boolean then 'ja' else '' end as "eingemischt",
       p.j ->> 'grund' as "grund"
  from protokoll p, coaching_sessions cs
 where cs.id = :'s'
 order by p.minute, p.nr;

\echo '== Warteschlange des Coaches (Momentaufnahmen) =='
select to_char(cs.scheduled_at + g.minute * interval '1 minute', 'HH24:MI') as "Uhrzeit", g.kind as "Kind", g.art, g.grund
  from signale g, coaching_sessions cs where cs.id = :'s' order by g.minute, g.kind;

\echo '== Abschluss je Kind =='
select pg_temp.name(t.tablet_nr) as "Kind", a.exit_ergebnis, a.zusammenfassung ->> 'aufgaben' as aufgaben,
       a.zusammenfassung ->> 'richtig' as richtig, a.in_akte_am is null as "nicht in der Akte (Testlauf)",
       (select count(*) from lernpfad_belege b where b.session_id = :'s' and b.student_id = a.student_id) as belege
  from session_kind_abschluss a join session_tablets t on t.session_id = a.session_id and t.student_id = a.student_id
 where a.session_id = :'s' order by t.tablet_nr;

rollback;
