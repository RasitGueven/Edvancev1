-- Q15 · Abschnitt 5a/5d: Schulform und Schulname an Leads und Kindern (Freitext, school_type), getrennt nach Testdaten
\set QUIET on
select 'lead' art, coalesce(school_type, '(leer)') schulform, ist_test, count(*) n,
       count(*) filter (where school_name ~* 'holweide') holweide, count(*) filter (where school_name ~* 'kerpen') kerpen,
       count(*) filter (where schule_id is not null) mit_schule_id
  from leads group by 1, 2, 3
union all
select 'kind', coalesce(school_type, '(leer)'), ist_test, count(*),
       count(*) filter (where school_name ~* 'holweide'), count(*) filter (where school_name ~* 'kerpen'),
       count(*) filter (where schule_id is not null)
  from students group by 1, 2, 3 order by 1, 2, 3;
