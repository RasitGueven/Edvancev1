-- Q17 · Abschnitt 3c: Liste aller LSA-Aufgaben mit Rolle je Variante (regel | reserve | leer = nicht notwendig) und Grund
--       (Variante 2), als CSV für anhang/aufgabenliste.csv
-- braucht: msa_basis.sql soll.sql
\set QUIET on
\pset format csv
select l.id, l.skill_key skill, coalesce(m.msa, false) msa, l.status, l.input_type format,
       left(regexp_replace(l.ts, '\s+', ' ', 'g'), 90) textschluessel,
       k.rang,
       (select w.rolle from notwendig w where w.n = 2 and w.id = l.id) rolle_2,
       (select w.rolle from notwendig w where w.n = 3 and w.id = l.id) rolle_3,
       (select w.rolle from notwendig w where w.n = 4 and w.id = l.id) rolle_4,
       case when exists (select 1 from notwendig w where w.n = 2 and w.id = l.id)
              then case k.rang when 1 then 'schon im Pool' when 2 then 'Lena passt, Freigabe fehlt'
                                when 3 then 'Entwurf, Lena muss prüfen' else 'Entwurf, Lena unsicher, neu prüfen' end
            when l.status not in ('draft','review','ready') then 'Status ' || l.status
            when not l.gueltig then 'keine gültige Lösung oder inaktiv'
            when exists (select 1 from vertreter x where x.skill_key = l.skill_key and x.ts = l.ts and x.id <> l.id)
              then 'gleicher Text wie eine bessere Aufgabe'
            else 'über Soll (mehr Texte als Regel + Reserve)' end grund_2
  from lt l left join msa m using (skill_key) left join kand k on k.id = l.id
 order by l.skill_key, rolle_2 nulls last, k.rang nulls last, l.id;
