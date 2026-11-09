-- FR-2 F1 Regression gegen den Bericht (dbread auf Prod nach dem Einspielen, nur lesend).
-- Erwartung: R1 501 Pakete Kl. 8–10, 0 grün (Bericht Q12); R2 Kl. 10 49 Skills / 92 Texte (§3f, Q19, Q36),
-- Kl. 8–10 73 / 137 (Q20, Q36); R3 Top-6 wie §2d/§3e (dezimal_add_sub 501, dezimal_mult 476, dezimal_div 421,
-- bruch_kuerzen 246, bruch_dezimal 156, term_zusammenfassen 138).
\timing on
-- R1 Ampel je Klasse (8–10)
select klasse, count(*) pakete, count(*) filter (where ampel='gruen') gruen, count(*) filter (where ampel='gelb') gelb,
       count(*) filter (where ampel='rot') rot, count(*) filter (where not hat_einstieg) ohne_einstieg
  from lsa_status_roh(lsa_schuljahr_heute()) where klasse between 8 and 10 group by rollup(1) order by 1;
-- R2 Kl. 10: fehlende Skills (Vereinigung) und fehlende Texte (Q36)
with b as (select * from lsa_skill_bereit_roh(null)),
f as (select distinct s.skill_key from lsa_paket_skills_basis(lsa_schuljahr_heute()) s join b using (skill_key) where s.klasse = 10 and not b.erfuellt)
select count(*) skills_kl10, sum(greatest(b.fehlende_texte, b.fehlende_ohne_mc)) texte_kl10 from f join b using (skill_key);
with b as (select * from lsa_skill_bereit_roh(null)),
f as (select distinct s.skill_key from lsa_paket_skills_basis(lsa_schuljahr_heute()) s join b using (skill_key) where s.klasse between 8 and 10 and not b.erfuellt)
select count(*) skills_kl8_10, sum(greatest(b.fehlende_texte, b.fehlende_ohne_mc)) texte_kl8_10 from f join b using (skill_key);
-- R3 Top nach Hebel (Pakete Kl. 8–10, ohne Fokus)
with b as (select * from lsa_skill_bereit_roh(null)),
h as (select s.skill_key, count(distinct (s.schule_id, s.klasse, s.paket_nr)) pakete, count(distinct s.schule_id) schulen
        from lsa_paket_skills_basis(lsa_schuljahr_heute()) s where s.klasse between 8 and 10 group by 1)
select h.*, b.texte_im_pool, b.erfuellt from h join b using (skill_key) where not b.erfuellt order by schulen desc, pakete desc limit 8;
