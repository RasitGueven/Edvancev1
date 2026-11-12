-- Q09 · Abschnitt 3b: nicht notwendige LSA-Aufgaben je Variante nach Status und Grund
--       Gründe: gleicher_text (Schlüssel schon durch einen besseren Vertreter belegt), ueber_soll (Schlüssel jenseits N+1),
--       ungueltig (keine gültige Lösung oder nicht aktiv/kein exercise), status (rueckfrage/beanstandet)
-- braucht: msa_basis.sql soll.sql
\set QUIET on
select v.n, l.status,
       case when w.id is not null then 'notwendig'
            when l.status not in ('draft','review','ready') then 'status'
            when not l.gueltig then 'ungueltig'
            when exists (select 1 from vertreter x where x.skill_key = l.skill_key and x.ts = l.ts and x.id <> l.id) then 'gleicher_text'
            else 'ueber_soll' end grund,
       count(*)
  from var v cross join lt l left join notwendig w on w.n = v.n and w.id = l.id
 group by 1, 2, 3 order by 1, 3, 2;
