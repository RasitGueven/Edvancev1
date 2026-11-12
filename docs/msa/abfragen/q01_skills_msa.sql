-- Q01 · Abschnitt 1: jeder Skill mit Herkunftsklasse, Thema (skill_thema), Kompetenzzeilen aus zuordnung.csv,
--       Prüfungsteil (1 = in Aufgabenbeispielen ohne Hilfsmittel belegt), MSA ja/nein, Kanten (Voraussetzungen)
-- braucht: msa_basis.sql
\set QUIET on
\pset format unaligned
\pset fieldsep '|'
select m.skill_key, s.klasse_herkunft herk, s.label,
       (select string_agg(st.thema_key, ',') from skill_thema st where st.skill_key = m.skill_key) thema,
       m.kompetenzen, m.teil, m.msa,
       (select count(*) from skill_kante k where k.skill_key = m.skill_key) n_voraus
  from msa m join skills s using (skill_key)
 order by m.msa desc, s.klasse_herkunft, m.skill_key;
