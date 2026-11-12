-- Q12 · Abschnitt 4a: Bauformen der Reihe 1 je Skill (Status, Format, Figurengenerator) mit MSA-Kompetenzzeilen
-- braucht: msa_basis.sql
\set QUIET on
select b.skill_key, m.kompetenzen, m.msa, count(*) bauformen, string_agg(b.schluessel, ',' order by b.schluessel) schluessel,
       string_agg(distinct b.status, ',') status
  from bauformen b left join msa m using (skill_key)
 group by 1, 2, 3 order by 2, 1;
