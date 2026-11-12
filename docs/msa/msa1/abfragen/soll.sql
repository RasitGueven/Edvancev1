-- soll.sql · Auswahlregel „notwendig“ (an msa_basis.sql anzuhängen). Skill-Menge = alle Skills der Pakete Kl. 8–10
-- (lsa_paket_skills_basis, Schuljahr 2026/27) ∪ MSA-Skills. Je Variante N (2, 3, 4 Texte) je Skill N verschiedene
-- Textschlüssel + 1 Reserve, davon mindestens einer ohne MC unter den N.
-- Rang je Aufgabe: 1 im Pool (ready), 2 Lenas letzte Entscheidung „passt“ (noch nicht im Pool), 3 gültige Lösung ohne
-- Lena-Entscheidung, 4 gültig mit Lenas „unsicher“ o. Ä.; ungültige Lösung oder Status außerhalb draft/review/ready: nie notwendig.
-- Innerhalb des Rangs: ohne MC vor MC, dann sondierrang, dann id. Je Textschlüssel nur der beste Vertreter.
, menge as (
  select skill_key from public.lsa_paket_skills_basis('2026/27') where klasse between 8 and 10
  union select skill_key from msa where msa),
kand as (
  select l.*, t.sondierrang,
         case when l.im_pool then 1 when l.gueltig and l.lena_letzte = 'passt' and l.status in ('draft','review') then 2
              when l.gueltig and l.status in ('draft','review') and l.lena_letzte is null then 3
              when l.gueltig and l.status in ('draft','review') then 4 end rang
    from lt l join tasks t on t.id = l.id
   where l.skill_key in (select skill_key from menge)),
vertreter as (            -- bester Vertreter je Skill und Textschlüssel
  select distinct on (k.skill_key, k.ts) k.*
    from kand k where k.rang is not null
   order by k.skill_key, k.ts, k.rang, k.ohne_mc desc, k.sondierrang nulls last, k.id),
geordnet as (
  select v.*, row_number() over (partition by v.skill_key order by v.rang, v.ohne_mc desc, v.sondierrang nulls last, v.id) nr,
         min(case when v.ohne_mc then 0 end) over (partition by v.skill_key) hat_ohne_mc
    from vertreter v),
erster_ohne_mc as (
  select distinct on (skill_key) skill_key, id from geordnet where ohne_mc
   order by skill_key, rang, sondierrang nulls last, id),
var(n) as (values (2), (3), (4)),
wahl0 as (                -- erste N Schlüssel; enthält keiner ein Nicht-MC, ersetzt der beste Nicht-MC-Schlüssel den N-ten
  select v.n, g.skill_key, g.id, g.rang, g.ohne_mc,
         case when g.nr <= v.n then 'regel' when g.nr = v.n + 1 then 'reserve' end rolle0,
         g.nr
    from var v cross join geordnet g),
tausch as (
  select w.n, w.skill_key from wahl0 w
   group by 1, 2 having not bool_or(w.ohne_mc and w.rolle0 = 'regel')),
wahl as (
  select w.n, w.skill_key, w.id, w.rang,
         case when t.skill_key is null then w.rolle0
              when w.id = (select e.id from erster_ohne_mc e where e.skill_key = w.skill_key) then 'regel'
              when w.nr = w.n and exists (select 1 from erster_ohne_mc e where e.skill_key = w.skill_key) then 'reserve'
              when w.nr = w.n + 1 and exists (select 1 from erster_ohne_mc e where e.skill_key = w.skill_key) then null
              else w.rolle0 end rolle
    from wahl0 w left join tausch t on t.n = w.n and t.skill_key = w.skill_key),
notwendig as (select * from wahl where rolle is not null),
je_skill as (
  select v.n, m.skill_key,
         (select count(*) from geordnet g where g.skill_key = m.skill_key) texte_moeglich,
         (select count(*) from geordnet g where g.skill_key = m.skill_key and g.ohne_mc) texte_ohne_mc
    from var v cross join menge m)
