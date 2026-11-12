-- S02 · M0.2/Haltepunkt: Gruppen je Status; Skills, die die Regel heute erfüllen (lsa_skill_bereit_roh) und sie mit dem
--       Pool ohne die zu archivierenden Aufgaben (nicht-notwendig) nicht mehr erfüllen würden
-- braucht: msa_basis.sql soll.sql
\set QUIET on
, gruppe as (
  select l.id, l.skill_key, l.status, l.ts, l.im_pool, l.ohne_mc,
         case when w.rolle is not null then 'notwendig-' || w.rolle else 'nicht-notwendig' end g
    from lt l left join notwendig w on w.n = 2 and w.id = l.id),
nachher as (
  select s.skill_key,
         count(distinct g.ts) filter (where g.im_pool and g.g like 'notwendig%') texte,
         count(*) filter (where g.im_pool and g.ohne_mc and g.g like 'notwendig%') ohne_mc
    from skills s left join gruppe g using (skill_key) group by 1)
select 'gruppe' art, g || ' / ' || status schluessel, count(*)::text wert from gruppe group by 1, 2
union all
select 'bricht', r.skill_key, r.texte_im_pool || '→' || n.texte || ' Texte, ' || r.ohne_mc_im_pool || '→' || n.ohne_mc || ' ohne MC'
  from public.lsa_skill_bereit_roh(null) r join nachher n using (skill_key) cross join public.lsa_regel() x
 where r.erfuellt and not (n.texte >= x.texte and n.ohne_mc >= x.ohne_mc)
order by 1, 2;
