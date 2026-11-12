-- Q18 · Abschnitt 5b: je Mathe-Thema der Klassen 7–10 (themen.stufe erste/zweite) die Klasse in den hinterlegten
--       Gymnasial-Plänen (schul_themenplan): Zahl der Schulen je Klasse 7/8/9/10, dazu themen.klasse und KLP-Kürzel
\set QUIET on
select t.thema_key, t.stufe, t.klasse edvance_kl,
       count(distinct p.schule_id) filter (where p.klasse = 7) kl7, count(distinct p.schule_id) filter (where p.klasse = 8) kl8,
       count(distinct p.schule_id) filter (where p.klasse = 9) kl9, count(distinct p.schule_id) filter (where p.klasse = 10) kl10,
       count(distinct p.schule_id) schulen
  from themen t left join schul_themenplan p on p.thema_key = t.thema_key and lower(p.fach) = 'mathematik'
 where lower(t.fach) = 'mathematik' and t.stufe in ('erste', 'zweite')
 group by t.thema_key, t.stufe, t.klasse, t.sort order by t.sort;
