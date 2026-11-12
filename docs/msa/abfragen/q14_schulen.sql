-- Q14 · Abschnitt 5a/5d: Schulen je Schulform, mit eigenem Mathe-Plan (schul_themenplan), Klassen 8–10 im Plan, Quelle/Stand;
--       Suche nach Holweide/Kerpen in schulen, leads, students; Schulformen an Leads und Kindern (mit Testkennzeichen)
\set QUIET on
select coalesce(s.schulform, '(leer)') schulform, count(*) schulen,
       count(*) filter (where exists (select 1 from schul_themenplan p where p.schule_id = s.id and lower(p.fach) = 'mathematik')) mit_plan,
       count(*) filter (where (select count(distinct p.klasse) from schul_themenplan p where p.schule_id = s.id
                                and lower(p.fach) = 'mathematik' and p.klasse between 8 and 10) = 3) plan_kl8_10_voll,
       count(*) filter (where exists (select 1 from schul_klassenarbeiten k where k.schule_id = s.id)) mit_ka_folge,
       count(*) filter (where s.name ~* '(holweide|kerpen)' or coalesce(s.ort, '') ~* 'kerpen') holweide_kerpen
  from schulen s group by rollup (1) order by 1;
