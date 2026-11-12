-- Q13 · Abschnitt 4a/4b: je Thema (skill_thema, erstes Thema je Skill) MSA-Skills, davon mit Bauform; ohne Bauform getrennt
--       in Kern (Herkunft Kl. 9/10) und Grundlage (Kl. 5–8); Schätzung Bauformen: Maßstab Reihe 1 = 40 Kern-Bauformen für
--       9 Kern-Skills (≈ 4,4 je Kern-Skill) und 1 je Grundlagen-Skill; Variante „Wiederholung“ = 2 je Kern-Skill, 1 je Grundlage
-- braucht: msa_basis.sql
\set QUIET on
, th as (select distinct on (st.skill_key) st.skill_key, t.thema_key, t.label, t.sort
           from skill_thema st join themen t using (thema_key) order by st.skill_key, t.sort, t.thema_key),
x as (
  select th.thema_key, th.label, th.sort, m.skill_key, s.klasse_herkunft herk,
         exists (select 1 from bauformen b where b.skill_key = m.skill_key) mit_bf
    from msa m join skills s using (skill_key) join th using (skill_key) where m.msa)
select thema_key, label, count(*) msa_skills, count(*) filter (where mit_bf) mit_bauform,
       count(*) filter (where not mit_bf and herk >= 9) kern_ohne, count(*) filter (where not mit_bf and herk <= 8) grundl_ohne,
       round(count(*) filter (where not mit_bf and herk >= 9) * 40.0 / 9 + count(*) filter (where not mit_bf and herk <= 8), 0) bf_voll,
       count(*) filter (where not mit_bf and herk >= 9) * 2 + count(*) filter (where not mit_bf and herk <= 8) bf_wdh,
       string_agg(skill_key, ',' order by skill_key) filter (where not mit_bf) skills_ohne
  from x group by thema_key, label, sort order by sort;
