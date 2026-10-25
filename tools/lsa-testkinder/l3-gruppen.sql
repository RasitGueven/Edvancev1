-- LSA-L3: die Bereiche, die die LSA für ein Kind prüfen soll, je Gruppe — wie l2-gruppen.sql, aber für jedes Kind
-- (Schulplan oder Kernlehrplan) und mit dem Auffüllen aus Klasse + 1 (Entscheidung 4). Eine Abfrage ohne Semikolon,
-- gelesen von l3-auswertung.sql mit \set l3_gruppen `cat …` und als Unterabfrage eingesetzt (:l3_gruppen).
-- Liest nur Plan, Themen und Graph; läuft „vorher“ wie „nachher“ gleich (keine Funktion aus der L3-Migration).
-- Einstellungen: l3.schule (Name oder leer), l3.klasse, l3.thema, l3.behandelt (Komma-Liste).
-- Spalten: skill_key, klasse, feld, gruppe (erste Gruppe), alle_gruppen, ka (Ränge 2..4: KA2 = erstes kommendes Thema),
-- bericht_ka (Ränge, für die der Skill Bericht-Voraussetzung ist), kommend (die kommenden Themen, für die Kopfzeile).
-- LSA-L4: Gruppe „Kommend“ = Skills aus Themen, die laut Plan noch kommen, außerhalb des Themenraums (darf nie kommen).
with recursive
par as (
  select current_setting('l3.klasse')::int as kl, current_setting('l3.thema') as th,
         (select sc.id from schulen sc where sc.name = nullif(current_setting('l3.schule'), '')) as schule
), plan as (
  select p.klasse, p.position, p.thema_key
    from schul_themenplan p, par where p.schule_id = par.schule and lower(p.fach) = 'mathematik' and p.thema_key is not null
), klp_roh as (  -- Kernlehrplan je Klasse wie lsa_klp_themen
  select g.kl, th.thema_key, th.sort
    from (select kl from par union all select kl + 1 from par) g
    join themen th on lower(th.fach) = 'mathematik'
     and th.stufe = case when g.kl <= 6 then 'erprobung' when g.kl <= 8 then 'erste' else 'zweite' end
), klp as (
  select r.* from klp_roh r
   where not exists (select 1 from klp_roh x join themen th using (thema_key) where x.kl = r.kl and th.klasse >= r.kl)
      or exists (select 1 from themen th where th.thema_key = r.thema_key and th.klasse >= r.kl)
), mitplan as (
  select exists (select 1 from plan, par where plan.klasse = par.kl) as ja
), akt as (
  select coalesce((select min(position) from plan, par where plan.klasse = par.kl and plan.thema_key = par.th), 0) as pos
), eigen as (  -- kommende Themen der eigenen Klasse, Rang 1..3
  select x.thema_key, x.o from (
    select p.thema_key, p.position as o from plan p, par, akt, mitplan
     where mitplan.ja and p.klasse = par.kl and p.position > akt.pos and p.thema_key <> par.th
    union all
    select k.thema_key, k.sort from klp k, par, mitplan
     where not mitplan.ja and k.kl = par.kl
       and k.sort > coalesce((select k2.sort from klp k2 where k2.kl = par.kl and k2.thema_key = par.th), -1)) x
  order by x.o limit 3
), fuell as (  -- Klasse + 1: Schulplan, sonst Kernlehrplan ohne die Themen bis zur eigenen Klasse
  select y.thema_key, y.o from (
    select p.thema_key, min(p.position) as o from plan p, par
     where p.klasse = par.kl + 1 group by p.thema_key
    union all
    select k.thema_key, k.sort from klp k, par
     where k.kl = par.kl + 1 and not exists (select 1 from plan p where p.klasse = par.kl + 1)
       and k.thema_key not in (select p.thema_key from plan p, mitplan where mitplan.ja and p.klasse <= par.kl
                               union all select k3.thema_key from klp k3, mitplan where not mitplan.ja and k3.kl = par.kl)) y
), kommend as (
  select z.thema_key, row_number() over (order by z.a, z.o)::int as rang from (
    select thema_key, 0 as a, o from eigen
    union all
    select f.thema_key, 1, f.o from fuell f, par
     where f.thema_key <> par.th and f.thema_key not in (select thema_key from eigen)) z
  order by z.a, z.o limit 3
), spaeter as (
  select thema_key from plan, par, akt, mitplan
   where mitplan.ja and thema_key <> par.th and ((klasse = par.kl and position > akt.pos) or klasse = par.kl + 1)
  union select th.thema_key from themen th, par, mitplan
   where not mitplan.ja and lower(th.fach) = 'mathematik' and th.thema_key <> par.th
     and th.sort > coalesce((select k2.sort from klp k2 where k2.kl = par.kl and k2.thema_key = par.th), 0)
  union select thema_key from fuell, par where (select count(*) from eigen) < 3 and thema_key <> par.th
), r(rang, sk, pfad) as (
  select u.rang, k.voraussetzt_skill_key, array[k.voraussetzt_skill_key]
    from kommend u join skill_thema st on st.thema_key = u.thema_key
    join skill_kante k on k.skill_key = st.skill_key
   where not exists (select 1 from skill_thema x where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
  union
  select r.rang, k.voraussetzt_skill_key, r.pfad || k.voraussetzt_skill_key
    from r join skill_thema x on x.skill_key = r.sk and x.thema_key in (select thema_key from spaeter)
    join skill_kante k on k.skill_key = r.sk
   where not k.voraussetzt_skill_key = any (r.pfad)
), rand as (
  select distinct rang, sk from r
   where not exists (select 1 from skill_thema x where x.skill_key = r.sk
                        and x.thema_key in (select thema_key from spaeter union select thema_key from kommend))
), tief as (
  select distinct x.rang, a.skill_key as sk
    from rand x cross join lateral public.lsa_abschluss(x.sk) a
   where not exists (select 1 from rand y where y.sk = a.skill_key)
     and not exists (select 1 from skill_thema st where st.skill_key = a.skill_key
                        and st.thema_key in (select thema_key from spaeter union select thema_key from kommend))
), bericht as (  -- Voraussetzungen, die der Bericht für sein Signal nutzt (skill_kante s → g, s im Thema, g nicht)
  select distinct u.rang, k.voraussetzt_skill_key as sk
    from kommend u join skill_thema st on st.thema_key = u.thema_key
    join skill_kante k on k.skill_key = st.skill_key
   where not exists (select 1 from skill_thema x where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
), raum as (
  select te.skill_key as sk from thema_einstieg te, par where te.thema_key = par.th
  union
  select a.skill_key from thema_einstieg te cross join par cross join lateral public.lsa_abschluss(te.skill_key) a
   where te.thema_key = par.th
), rueck as (
  select distinct te.skill_key as sk from thema_einstieg te join skills s using (skill_key), par
   where te.thema_key = any (string_to_array(current_setting('l3.behandelt'), ',')) and s.klasse_herkunft <= par.kl
), ausblick as (  -- Einstiege der kommenden Themen (darf nie gezogen werden)
  select distinct te.skill_key as sk from kommend u join thema_einstieg te on te.thema_key = u.thema_key
   where te.skill_key not in (select sk from raum)
), kommend_sk as (  -- LSA-L4: Skills aus Themen, die laut Plan noch kommen (ausser dem Themenraum)
  select distinct st.skill_key as sk from skill_thema st
   where st.thema_key in (select thema_key from spaeter union select thema_key from kommend)
     and st.skill_key not in (select sk from raum)
), mitglied as (
  select sk, 1 as ord, 'Thema' as gruppe, null::text as art from raum join skills s on s.skill_key = raum.sk, par
   where s.klasse_herkunft >= par.kl
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'Rand' from rand
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'tiefer' from tief
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'Bericht' from bericht
  union all select sk, 5, 'Grundlage', null from raum join skills s on s.skill_key = raum.sk, par
   where s.klasse_herkunft < par.kl
  union all select sk, 6, 'Rückblick', null from rueck
  union all select sk, 7, 'Ausblick', null from ausblick
  union all select sk, 8, 'Kommend', null from kommend_sk
)
select m.sk as skill_key, s.klasse_herkunft as klasse, public.lsa_themenfeld(m.sk) as feld,
       (array_agg(m.gruppe order by m.ord))[1] as gruppe,
       string_agg(distinct m.gruppe || coalesce(' ' || m.art, ''), ', ') as alle_gruppen,
       array_agg(distinct m.ord) filter (where m.ord between 2 and 4) as ka,
       array_agg(distinct m.ord) filter (where m.ord between 2 and 4 and m.art = 'Bericht') as bericht_ka,
       (select string_agg(thema_key, ' · ' order by rang) from kommend) as kommend
  from mitglied m join skills s on s.skill_key = m.sk
 group by m.sk, s.klasse_herkunft
