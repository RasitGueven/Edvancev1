\timing on
with recursive
par as (select '2026/27'::text sj, 2 soll_texte, 1 soll_ohne_mc),
best as (
  select k.schule_id, k.klasse, k.nr paket_nr, k.thema_keys, k.datum,
         count(*) over w n, row_number() over (w order by k.nr) i
    from schul_klassenarbeiten k, par
   where k.bestaetigt and lower(k.fach) = 'mathematik' and k.schuljahr = par.sj
  window w as (partition by k.schule_id, k.klasse)),
plan as (
  select p.* from schul_themenplan p
   where lower(p.fach) = 'mathematik' and p.thema_key is not null
     and not exists (select 1 from best b where b.schule_id = p.schule_id and b.klasse = p.klasse)),
uv as (
  select p.schule_id, p.klasse, p.position, p.thema_key,
         row_number() over (w order by p.position)::int paket_nr,
         case when bool_and(p.halbjahr is not null) over w then
                (p.halbjahr - 1) * 0.5 + 0.5 * (row_number() over (partition by p.schule_id, p.klasse, p.halbjahr order by p.position) - 0.5)
                                           / count(*) over (partition by p.schule_id, p.klasse, p.halbjahr)
              when count(p.stunden) over w = count(*) over w then
                (sum(p.stunden) over (w order by p.position) - p.stunden / 2.0)::numeric / sum(p.stunden) over w
              else (row_number() over (w order by p.position) - 0.5)::numeric / count(*) over w end as lage
    from plan p
  window w as (partition by p.schule_id, p.klasse)),
pk0 as (
  select u.schule_id, u.klasse, u.paket_nr, array[u.thema_key] thema_keys, 'geschaetzt'::text quelle, u.lage::numeric lage,
         array(select distinct p.thema_key from plan p where p.schule_id = u.schule_id and p.klasse = u.klasse
                and p.position >= u.position) ab_hier
    from uv u
  union all
  select b.schule_id, b.klasse, b.paket_nr, b.thema_keys, 'bestaetigt',
         coalesce(least(1, greatest(0, (b.datum - make_date(left(par.sj, 4)::int, 9, 1))::numeric
                         / (make_date(left(par.sj, 4)::int + 1, 6, 30) - make_date(left(par.sj, 4)::int, 9, 1)))),
                  (b.i - 0.5) / b.n),
         array(select distinct x from best b2, unnest(b2.thema_keys) x
                where b2.schule_id = b.schule_id and b2.klasse = b.klasse and b2.paket_nr >= b.paket_nr)
    from best b, par),
pk as (
  select row_number() over (order by schule_id, klasse, paket_nr)::int id, pk0.*,
         pk0.ab_hier || coalesce(
           nullif(array(select distinct p.thema_key from schul_themenplan p where p.schule_id = pk0.schule_id
                         and lower(p.fach) = 'mathematik' and p.klasse = pk0.klasse + 1 and p.thema_key is not null), '{}'),
           public.lsa_klp_themen('mathematik', pk0.klasse + 1), '{}') spaeter
    from pk0),
-- Fall A je Thema
ein as (select thema_key, skill_key from thema_einstieg),
raum_a as (
  select thema_key, skill_key, min(r) r from (
    select e.thema_key, e.skill_key, 1 r from ein e
    union all
    select e.thema_key, k.voraussetzt_skill_key, 2 from ein e join skill_kante k on k.skill_key = e.skill_key
    union all
    select e.thema_key, a.skill_key, 3 from ein e cross join lateral public.lsa_abschluss(e.skill_key) a) x
  group by 1, 2),
-- Fall B je Paket: Rand wie lsa_select_next_core (:9211–9244), kommend = Themen der Arbeit
r(pk, sk, pfad) as (
  select pk.id, k.voraussetzt_skill_key, array[k.voraussetzt_skill_key]
    from pk cross join unnest(pk.thema_keys) u(thema_key)
    join skill_thema st on st.thema_key = u.thema_key
    join skill_kante k on k.skill_key = st.skill_key
   where not exists (select 1 from skill_thema x where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
  union
  select r.pk, k.voraussetzt_skill_key, r.pfad || k.voraussetzt_skill_key
    from r join pk on pk.id = r.pk
    join skill_thema x on x.skill_key = r.sk and x.thema_key = any (pk.spaeter)
    join skill_kante k on k.skill_key = r.sk
   where not k.voraussetzt_skill_key = any (r.pfad)),
rand as (
  select distinct r.pk, r.sk from r join pk on pk.id = r.pk
   where not exists (select 1 from skill_thema x where x.skill_key = r.sk
                      and (x.thema_key = any (pk.spaeter) or x.thema_key = any (pk.thema_keys)))),
rand_tief as (
  select distinct rd.pk, a.skill_key sk from rand rd join pk on pk.id = rd.pk
   cross join lateral public.lsa_abschluss(rd.sk) a
   where not exists (select 1 from rand x where x.pk = rd.pk and x.sk = a.skill_key)
     and not exists (select 1 from skill_thema st where st.skill_key = a.skill_key
                      and (st.thema_key = any (pk.spaeter) or st.thema_key = any (pk.thema_keys)))),
ps as (
  select pk.id pk, ra.skill_key, 'A' fall, case ra.r when 1 then 'einstieg' when 2 then 'voraussetzung' else 'tiefe' end teil,
         ra.r <= 2 pflicht
    from pk cross join unnest(pk.thema_keys) u(thema_key) join raum_a ra on ra.thema_key = u.thema_key
  union all
  select x.pk, x.sk, 'B', x.teil, x.teil = 'rand' from (
    select pk, sk, 'rand' teil from rand union all select pk, sk, 'rand_tiefe' from rand_tief) x
    join pk on pk.id = x.pk join skills s on s.skill_key = x.sk and s.klasse_herkunft <= pk.klasse),
pool as (
  select t.skill_key, t.input_type, coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
    from tasks t where 'lsa' = any (t.einsatz) and public.lsa_im_pool(t.id, false)),
sb as (
  select s.skill_key, count(distinct p.ts)::int texte, (count(p.ts) filter (where p.input_type <> 'MC'))::int ohne_mc
    from skills s left join pool p using (skill_key) group by 1),
bereit as (
  select sb.*, sb.texte >= par.soll_texte and sb.ohne_mc >= par.soll_ohne_mc erfuellt,
         greatest(par.soll_texte - sb.texte, par.soll_ohne_mc - sb.ohne_mc, 0) bedarf
    from sb, par),
pss as (select pk, skill_key, bool_or(pflicht) pflicht from ps group by 1, 2),
st as (
  select pk.*,
         coalesce(bool_and(b.erfuellt), true) alle_ok,
         coalesce(bool_and(b.erfuellt) filter (where s.pflicht), true) pflicht_ok,
         count(*) filter (where s.pflicht and not b.erfuellt) fehl_pflicht,
         count(*) filter (where not b.erfuellt) fehl,
         coalesce(sum(b.bedarf) filter (where not b.erfuellt), 0) fehl_texte,
         (select bool_and(exists (select 1 from thema_einstieg te where te.thema_key = x)) from unnest(pk.thema_keys) x) hat_einstieg
    from pk left join pss s on s.pk = pk.id left join bereit b on b.skill_key = s.skill_key
   group by pk.id, pk.schule_id, pk.klasse, pk.paket_nr, pk.thema_keys, pk.quelle, pk.lage, pk.ab_hier, pk.spaeter)
select klasse, count(*) pakete,
       count(*) filter (where alle_ok and hat_einstieg) gruen,
       count(*) filter (where not (alle_ok and hat_einstieg) and pflicht_ok and hat_einstieg) gelb,
       count(*) filter (where pflicht_ok and not hat_einstieg) gelb_ohne_einstieg,
       round(avg(fehl), 1) fehl_avg, sum(fehl_texte) fehl_texte
  from st where klasse between 8 and 10 group by rollup (1) order by 1;
