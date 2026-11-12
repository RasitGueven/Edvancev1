-- Q20 · Abschnitt 5a: Pakete Kl. 8–10 im Schuljahr 2026/27 nach Quelle (geschaetzt = aus schul_themenplan, bestaetigt =
--       aus schul_klassenarbeiten) und Schulform; Schulen ohne eigenen Plan haben keine Pakete
\set QUIET on
select coalesce(s.schulform, '(leer)') schulform, p.quelle, count(*) pakete, count(distinct p.schule_id) schulen
  from public.lsa_pakete_basis('2026/27') p join schulen s on s.id = p.schule_id
 where p.klasse between 8 and 10 group by 1, 2 order by 1, 2;
