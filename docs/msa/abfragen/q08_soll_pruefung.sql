-- Q08 · Abschnitt 3: Selbstprüfung der Auswahl je Variante (Regel-Satz ohne Nicht-MC, obwohl möglich; doppelte Textschlüssel)
--       und Skills mit zu wenig Texten je Variante (verfügbare Texte / davon ohne MC / Herkunftsklasse / MSA)
-- braucht: msa_basis.sql soll.sql
\set QUIET on
select v.n,
       (select count(*) from (select w.skill_key from notwendig w join lt l on l.id = w.id
                               where w.n = v.n and w.rolle = 'regel' group by 1 having not bool_or(l.ohne_mc)) x
         where exists (select 1 from geordnet g where g.skill_key = x.skill_key and g.ohne_mc)) regel_ohne_nicht_mc,
       (select count(*) - count(distinct (w.skill_key, l.ts)) from notwendig w join lt l on l.id = w.id where w.n = v.n) doppelt,
       (select string_agg(j.skill_key || ' (' || j.texte_moeglich || case when coalesce(m.msa, false) then ', MSA' else ', G9' end || ')',
                          ', ' order by j.texte_moeglich, j.skill_key)
          from je_skill j left join msa m using (skill_key) where j.n = v.n and j.texte_moeglich < v.n) zu_wenig
  from var v order by 1;
