-- S01 · M0.2: Streichliste auf dem heutigen Stand (Regel 2 + 1 Reserve, Auswahl genau wie docs/msa/abfragen/soll.sql;
--       Entscheidung Rasit 12.11.2026: keine Gruppe zu-schwer).
--       CSV: id, skill, status, textschluessel (md5 wie lsa_text_schluessel), gruppe, grund
-- braucht: msa_basis.sql soll.sql
\set QUIET on
\pset format csv
select l.id, l.skill_key skill, l.status, l.ts textschluessel,
       case when w.rolle = 'regel' then 'notwendig-regel' when w.rolle = 'reserve' then 'notwendig-reserve'
            else 'nicht-notwendig' end gruppe,
       case when w.rolle is not null then
              case k.rang when 1 then 'schon im Pool' when 2 then 'Lena passt, Freigabe fehlt'
                          when 3 then 'Entwurf, Lena muss prüfen' else 'Entwurf, Lena unsicher, neu prüfen' end
            when l.status not in ('draft','review','ready') then 'Status ' || l.status
            when not l.gueltig then 'keine gültige Lösung oder inaktiv'
            when exists (select 1 from vertreter x where x.skill_key = l.skill_key and x.ts = l.ts and x.id <> l.id)
              then 'gleicher Text wie eine bessere Aufgabe'
            else 'über Soll (mehr Texte als Regel + Reserve)' end grund
  from lt l left join kand k on k.id = l.id left join notwendig w on w.n = 2 and w.id = l.id
 order by l.skill_key, gruppe, l.id;
