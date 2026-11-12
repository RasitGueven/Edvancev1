-- Q19 · Abschnitt 4a/4d: Stand der Bauformen (Status, Formate) und gemessene Prüfzeiten aus SP-1 (bauform_pruefungen.dauer_sek)
\set QUIET on
select (select count(*) from bauformen) bauformen,
       (select string_agg(status || ':' || n, ', ') from (select status, count(*) n from bauformen group by 1) x) status,
       (select string_agg(format || ':' || n, ', ' order by n desc) from (select format, count(*) n from bauformen group by 1) x) formate,
       (select count(distinct skill_key) from bauformen) skills,
       (select count(*) from bauform_pruefungen) pruefungen,
       (select percentile_cont(0.5) within group (order by dauer_sek) from bauform_pruefungen) median_sek,
       (select string_agg(distinct generator, ', ') from task_figures) figurengeneratoren;
