-- S05 · M5.2: Aufgaben für Lena unter „Gezielt prüfen“, getrennt nach Regel und Reserve. pruef_ziel_roh schlägt je Skill
--       rest + 1 Entwürfe vor (rest = fehlende Texte bis zur Regel); Regel = die ersten rest, Reserve = der +1.
--       Die Liste (pruef_ziel_liste) nimmt nur Skills, die in einem Paket Kl. 8–10 liegen (Inner Join hebel).
\set QUIET on
with z as (select z.*, z.skill_key in (select skill_key from public.lsa_paket_skills_basis('2026/27')) im_paket
             from public.pruef_ziel_roh() z)
select case when im_paket then 'in der Liste (Skill in einem Paket)' else 'nicht in der Liste (kein Paket, nur MSA)' end teil,
       count(*) skills, sum(least(rest, cardinality(task_ids))) regel, sum(greatest(cardinality(task_ids) - rest, 0)) reserve,
       sum(cardinality(task_ids)) gesamt, sum(cardinality(freigabe_ids)) nur_freigabe
  from z group by rollup (1) order by 1 nulls last;
