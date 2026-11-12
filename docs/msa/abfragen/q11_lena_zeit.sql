-- Q11 · Abschnitt 3f/4d: Lenas gemessene Prüfdauer je LSA-Entscheidung (task_pruefungen.dauer_sek, Ausreißer > 30 Min nicht
--       gekappt) und Passt-Quote (letzte Entscheidung je Aufgabe, ohne „zurueckgenommen“)
\set QUIET on
with lena as (select id from profiles where full_name = 'Lena Klever'),
p as (select p.* from task_pruefungen p join tasks t on t.id = p.task_id
       where p.geprueft_von in (select id from lena) and 'lsa' = any (t.einsatz)),
letzte as (select distinct on (task_id) task_id, entscheidung from p where entscheidung <> 'zurueckgenommen'
            order by task_id, geprueft_am desc)
select (select count(*) from p) entscheidungen, (select count(*) from p where dauer_sek is not null) mit_dauer,
       (select percentile_cont(0.5) within group (order by dauer_sek) from p) median_sek,
       (select round(avg(dauer_sek), 1) from p) mittel_sek,
       (select count(*) from letzte) aufgaben,
       (select count(*) from letzte where entscheidung = 'passt') passt,
       (select round(100.0 * count(*) filter (where entscheidung = 'passt') / count(*), 1) from letzte) passt_quote,
       (select max(geprueft_am)::date from p) letzte_pruefung;
