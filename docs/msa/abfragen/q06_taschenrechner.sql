-- Q06 · Abschnitt 2: LSA-Aufgaben mit Rechner-Kennzeichen (tasks.taschenrechner) nach Status und Skill; Hilfsmittel-Einstellung
\set QUIET on
select t.status, t.taschenrechner, count(*) from tasks t where 'lsa' = any (t.einsatz) group by 1, 2 order by 1, 2;
select t.skill_key, t.status, left(regexp_replace(t.question, '\s+', ' ', 'g'), 90) frage, t.id
  from tasks t where 'lsa' = any (t.einsatz) and t.taschenrechner order by 1, 2;
select hilfsmittel, nur_pilot from pruef_einstellungen;
