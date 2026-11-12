-- Q16 · Abschnitt 6b: Wie oft hat Lena LSA-Aufgaben beim Prüfen selbst geändert? task_pruefungen.aenderungen (Entwurf aus
--       pruef_speichern, beim Entscheiden übernommen) nicht leer, nach Entscheidung; dazu die geänderten Felder
\set QUIET on
with lena as (select id from profiles where full_name = 'Lena Klever'),
p as (select p.* from task_pruefungen p join tasks t on t.id = p.task_id
       where p.geprueft_von in (select id from lena) and 'lsa' = any (t.einsatz))
select p.entscheidung, count(*) entscheidungen,
       count(*) filter (where p.aenderungen is not null and p.aenderungen not in ('{}'::jsonb, '[]'::jsonb, 'null'::jsonb)) mit_aenderung,
       count(distinct p.task_id) filter (where p.aenderungen is not null and p.aenderungen not in ('{}'::jsonb, '[]'::jsonb, 'null'::jsonb)) aufgaben,
       count(*) filter (where p.aenderung_grund is not null) mit_grund,
       (select string_agg(k || ':' || n, ', ' order by n desc) from (
          select e ->> 'feld' k, count(*) n
            from p p2, jsonb_array_elements(case when jsonb_typeof(p2.aenderungen) = 'array' then p2.aenderungen else '[]' end) e
           where p.entscheidung is null or p2.entscheidung = p.entscheidung group by 1) x) felder
  from p group by rollup (p.entscheidung) order by 1;
