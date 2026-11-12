-- Q02 · Abschnitt 1: Zählung MSA-Skills nach Herkunftsklasse und Prüfungsteil; Skills nur G9
-- braucht: msa_basis.sql
select msa, count(*) skills,
       count(*) filter (where s.klasse_herkunft <= 6) kl5_6, count(*) filter (where s.klasse_herkunft between 7 and 8) kl7_8,
       count(*) filter (where s.klasse_herkunft >= 9) kl9_10,
       count(*) filter (where m.teil like '%1%') teil1_belegt, count(*) filter (where m.teil = '2') nur_teil2
  from msa m join skills s using (skill_key) group by rollup (msa) order by 1;
