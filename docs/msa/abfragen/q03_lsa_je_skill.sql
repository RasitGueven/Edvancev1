-- Q03 · Abschnitt 2: je MSA-Skill LSA-Aufgaben nach Status, im Pool (lsa_im_pool), Textschlüssel im Pool, ohne MC im Pool,
--       Regel (2 Texte, davon 1 ohne MC — Stellschrauben lsa_regel), fehlende Texte, von Lena geprüft,
--       Freigabewelle der ready-Aufgaben (reviewed_at), FR-2-Neuaufgaben (Migration 20261109130736), Gruppe
-- braucht: msa_basis.sql
\set QUIET on
\pset format unaligned
\pset fieldsep '|'
, fr2(id) as (values ('6b363dac-a30c-4a2f-8fa0-b7814353d1f2'::uuid), ('b65bad4b-a8dd-4cee-8b9e-7716f5c786c0'),
       ('3b64f242-c2ab-4f18-8af4-a72dc185cf10'), ('fa8c52a4-161c-4bd4-9174-b98091ceb608'),
       ('300b2a89-6f7f-4022-8a61-9a9d040fadd3'), ('ab6509f0-c7c8-4c7b-b2f7-b65d12b23a8a'),
       ('dc412552-d604-4f43-b7f5-3f991a7b740e')),
je as (
  select m.skill_key,
         count(l.id) filter (where l.status = 'draft') draft,
         count(l.id) filter (where l.status = 'review') review,
         count(l.id) filter (where l.status = 'ready') ready,
         count(l.id) filter (where l.status not in ('draft','review','ready')) sonst,
         count(l.id) filter (where l.im_pool) im_pool,
         count(distinct l.ts) filter (where l.im_pool) texte_pool,
         count(l.id) filter (where l.im_pool and l.ohne_mc) ohne_mc_pool,
         count(distinct l.ts) filter (where l.gueltig and l.status in ('draft','review','ready')) texte_moeglich,
         count(l.id) filter (where l.lena_letzte is not null) lena_geprueft,
         count(l.id) filter (where l.lena_letzte = 'passt') lena_passt,
         count(l.id) filter (where l.status = 'ready' and l.reviewed_at::date between '2026-10-19' and '2026-10-21') w1_1910,
         count(l.id) filter (where l.status = 'ready' and l.reviewed_at::date = '2026-10-25') w2_2510,
         count(l.id) filter (where l.status = 'ready' and l.reviewed_at::date = '2026-10-29') w3_2910,
         count(l.id) filter (where l.id in (select id from fr2)) fr2_neu,
         count(l.id) filter (where l.taschenrechner) rechner
    from msa m left join lt l on l.skill_key = m.skill_key
   where m.msa group by 1)
select je.*, g.texte regel_texte,
       greatest(g.texte - je.texte_pool, g.ohne_mc - je.ohne_mc_pool, 0) fehlende_texte,
       case when je.texte_pool >= g.texte and je.ohne_mc_pool >= g.ohne_mc then 'bereit'
            when je.im_pool > 0 then 'teilweise' else 'offen' end gruppe,
       s.klasse_herkunft herk
  from je cross join public.lsa_regel() g join skills s using (skill_key)
 order by gruppe, s.klasse_herkunft, je.skill_key;
