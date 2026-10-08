-- A2c: Erklaersequenz vom Tablet im Testlauf. Ein Kind, Aufruf fuer Aufruf so, wie das Tablet sie macht
-- (p_student_id = null). Erzeugt die Beispiele im Abschnitt „Erklärsequenz im Testlauf“ von
-- docs/session/a2b-tablet-beispiele.md.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen + supabase/seed.sql), nie gegen Produktion. Laeuft in
-- begin … rollback und legt alle Daten selbst an. Inhalte der Erklaersequenz: Fixture aus session_e1
-- („Steigung aus dem Graphen“, drei Kernideen, je Variante A und B, Formeln und Bild). Aufruf aus dem
-- Repo-Wurzelverzeichnis:
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 -d <wegwerf-db> \
--     -f docs/session/a2c-tablet-erklaer.sql
--
-- Ausgabe: Zeilen "### <Titel>" gefolgt vom JSON des Aufrufs.
\set QUIET on
begin;
\ir ../../supabase/tests/session_a2_fixture.sql
\ir ../../supabase/tests/session_e1_fixture.sql

create temp table aus (nr serial, titel text, j jsonb);
create function pg_temp.zeig(p_titel text, p_j jsonb) returns void language sql as $$
  insert into aus (titel, j) values (p_titel, p_j) $$;

-- Testkonto mit Schulthema „Lineare Funktionen“; die Voraussetzungen der Steigung sind sicher, die Steigung
-- selbst ist neu. Testlauf: die Aufgaben zur Steigung stehen im Bestand noch als draft.
select pg_temp.kind_mit('Jonas Beispiel', 'lineare_funktionen',
                        '{geo_koordinaten,vorzeichen_mult_div,bruch_kuerzen,proportionalitaet}', '{}', true) as k \gset
-- Die Bestandsaufgaben zur Steigung haben in der Wegwerf-DB keinen Cluster (Freigabe-Gate: nicht im Pool; in Prod
-- haben sie einen). Deshalb 15 ZZ-Aufgaben zur Steigung, ready, mit Loesungsweg (offene-punkte-a2d 1).
select pg_temp.aufgaben('fkt_linear_steigung', 15);
select pg_temp.neue_session(array[:'k']::uuid[], 1, true) as s \gset
select pg_temp.checkin(:'s', 1);
select pg_temp.act_as(:'coach_a');
select public.checkin_coach_setzen(:'s', :'k', 'schulthema') is not null;
select pg_temp.uhr(:'s', 20);

select pg_temp.act_as(pg_temp.tablet(1));
select pg_temp.zeig('session_naechster_schritt(session_id, null) — Erklärsequenz vorgeschaltet',
  public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('erklaer_start(session_id, null, ''fkt_linear_steigung'')',
  public.erklaer_start(:'s', null, 'fkt_linear_steigung'));
select pg_temp.zeig('session_naechster_schritt — Sequenz läuft (App lädt neu)', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('erklaer_check_abgeben(session_id, null, check_task_id, ''{"text":"7"}'') — falsch',
  public.erklaer_check_abgeben(:'s', null, :'check1', '{"text":"7"}'));
select pg_temp.zeig('erklaer_check_abgeben(…, ''{"text":"2"}'') — richtig, nächste Kernidee',
  public.erklaer_check_abgeben(:'s', null, :'check1', '{"text":"2"}'));
select pg_temp.zeig('erklaer_check_abgeben(…, ''{"text":"0,5"}'') — richtig, nächste Kernidee',
  public.erklaer_check_abgeben(:'s', null, :'check2', '{"text":"0,5"}'));
select pg_temp.zeig('erklaer_check_abgeben(…, ''{"text":"-2"}'') — richtig, Sequenz durch',
  public.erklaer_check_abgeben(:'s', null, :'check3', '{"text":"-2"}'));
select pg_temp.zeig('session_naechster_schritt — Übergang ins Üben', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('session_naechster_schritt — nach Weiter: Aufgabe zur Steigung', public.session_naechster_schritt(:'s', null));
select pg_temp.zeig('hinweis_abrufen(session_id, task_id, 1) — mit weitere (A2c)',
  public.hinweis_abrufen(:'s', (select j ->> 'task_id' from aus order by nr desc limit 1)::uuid, 1));
select pg_temp.zeig('erklaer_nachlesen(null, ''fkt_linear_steigung'')',
  public.erklaer_nachlesen(null, 'fkt_linear_steigung'));

select pg_temp.act_as(pg_temp.tablet(2));
select set_config('a2c.s', :'s', true);
do $$
begin
  perform public.erklaer_start(current_setting('a2c.s')::uuid, null, 'fkt_linear_steigung');
exception when others then
  perform pg_temp.zeig('Fehler: erklaer_start von einem Tablet ohne Platz in dieser Session',
                       jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
end $$;

\unset QUIET
select '### ' || titel || E'\n' || jsonb_pretty(j) from aus order by nr;
rollback;
