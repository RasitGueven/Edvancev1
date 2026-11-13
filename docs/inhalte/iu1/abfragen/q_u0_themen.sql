-- U0.1: Fall A je Thema aus lsa_paket_skills_basis (nur Pakete mit genau einem Thema), Regel aus lsa_skill_bereit_roh.
with p as (select * from lsa_pakete_basis(lsa_schuljahr_heute()) where klasse between 8 and 10),
ps as (select s.*, p.thema_keys[1] thema_key from lsa_paket_skills_basis(lsa_schuljahr_heute()) s
        join p using (schule_id, klasse, paket_nr) where s.fall = 'A' and cardinality(p.thema_keys) = 1),
gleich as (select thema_key, count(distinct (select string_agg(x.skill_key||x.teil, ',' order by x.skill_key)
             from ps x where x.schule_id=ps.schule_id and x.klasse=ps.klasse and x.paket_nr=ps.paket_nr)) varianten
             from ps group by 1),
raum as (select distinct thema_key, skill_key, teil, pflicht from ps),
b as (select * from lsa_skill_bereit_roh(null))
select r.thema_key, g.varianten,
  count(*) n, count(*) filter (where b.erfuellt) bereit, count(*) filter (where not b.erfuellt and b.texte_im_pool>0) teil,
  count(*) filter (where b.texte_im_pool=0) offen,
  count(*) filter (where r.pflicht) pflicht, count(*) filter (where r.pflicht and b.erfuellt) pflicht_bereit,
  count(*) filter (where r.teil='einstieg') einstiege
from raum r join b using (skill_key) join gleich g using (thema_key) group by 1,2 order by 1;
