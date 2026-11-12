-- S04 · M0.3/M5.1: lsa_skill_bereit je Skill (CSV)
\set QUIET on
\pset format csv
select skill_key, texte_im_pool, ohne_mc_im_pool, erfuellt, fehlende_texte, fehlende_ohne_mc
  from public.lsa_skill_bereit_roh(null) order by 1;
