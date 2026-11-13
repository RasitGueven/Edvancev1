-- Rollback zu 20261113153302_sf1_pakete_klp: alter Stand der beiden Funktionen, Trigger und CHECK.
-- Vorprüfung: Beide Funktionen sind noch genau die SF-1-Fassung (md5 von prosrc), und keine andere Funktion liest
-- die Quelle 'klp'. Sonst Abbruch — dann Rasit fragen, nicht erzwingen.
-- Reihenfolge: Funktionen zurück, Speicher neu (danach keine 'klp'-Zeilen), dann der CHECK.
-- Den Eintrag in supabase_migrations.schema_migrations danach von Hand entfernen.
do $$
begin
  if (select md5(prosrc) from pg_proc where oid = 'public.lsa_pakete_roh(text)'::regprocedure)
       is distinct from '750be487f4a3527c6232ba93000e1328'
     or (select md5(prosrc) from pg_proc where oid = 'public.lsa_paket_skills_roh(text)'::regprocedure)
       is distinct from '01c0bd150afa03c45f95d8834d7a780c' then
    raise exception 'Rollback abgebrochen: lsa_pakete_roh oder lsa_paket_skills_roh ist nicht mehr die SF-1-Fassung';
  end if;
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname not in ('lsa_pakete_roh', 'lsa_paket_skills_roh')
                and p.prosrc ~ '''klp''') then
    raise exception 'Rollback abgebrochen: eine andere Funktion liest die Paket-Quelle klp';
  end if;
end $$;

drop trigger lsa_paket_cache_schulen on public.schulen;
drop trigger lsa_paket_cache_klp_themenplan on public.klp_themenplan;
drop trigger lsa_paket_cache_skill_schulform on public.skill_schulform;

create or replace function public.lsa_pakete_roh(p_schuljahr text) RETURNS TABLE(schule_id uuid, klasse integer, paket_nr integer, thema_keys text[], quelle text, datum date, quartal integer, lage numeric, hat_einstieg boolean, spaeter text[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with recursive
  jahr as (select make_date(left(p_schuljahr, 4)::int, 9, 1) beginn, make_date(left(p_schuljahr, 4)::int + 1, 6, 30) ende),
  best as (
    select k.schule_id, k.klasse, k.nr, k.thema_keys, k.datum,
           count(*) over w n, row_number() over (w order by k.nr) i
      from public.schul_klassenarbeiten k
     where k.bestaetigt and lower(k.fach) = 'mathematik' and k.schuljahr = p_schuljahr
    window w as (partition by k.schule_id, k.klasse)),
  plan as (
    select p.* from public.schul_themenplan p
     where lower(p.fach) = 'mathematik' and p.thema_key is not null
       and not exists (select 1 from best b where b.schule_id = p.schule_id and b.klasse = p.klasse)),
  uv as (
    select p.schule_id, p.klasse, p.position, p.thema_key,
           row_number() over (w order by p.position, p.thema_key)::int nr,
           case when bool_and(p.halbjahr is not null) over w then
                  (p.halbjahr - 1) * 0.5
                  + 0.5 * (row_number() over (partition by p.schule_id, p.klasse, p.halbjahr order by p.position) - 0.5)
                        / count(*) over (partition by p.schule_id, p.klasse, p.halbjahr)
                when count(p.stunden) over w = count(*) over w then
                  (sum(p.stunden) over (w order by p.position rows between unbounded preceding and current row)
                   - p.stunden / 2.0)::numeric / sum(p.stunden) over w
                else (row_number() over (w order by p.position, p.thema_key) - 0.5)::numeric / count(*) over w
           end lage
      from plan p
    window w as (partition by p.schule_id, p.klasse)),
  pk as (
    select u.schule_id, u.klasse, u.nr, array[u.thema_key] thema_keys, 'geschaetzt'::text quelle, null::date datum,
           u.lage::numeric lage,
           array(select distinct p.thema_key from plan p
                  where p.schule_id = u.schule_id and p.klasse = u.klasse and p.position >= u.position) ab_hier
      from uv u
    union all
    select b.schule_id, b.klasse, b.nr, b.thema_keys, 'bestaetigt', b.datum,
           coalesce(least(1, greatest(0, (b.datum - j.beginn)::numeric / (j.ende - j.beginn))), (b.i - 0.5) / b.n),
           array(select distinct x from best b2 cross join unnest(b2.thema_keys) x
                  where b2.schule_id = b.schule_id and b2.klasse = b.klasse and b2.nr >= b.nr)
      from best b cross join jahr j)
  select pk.schule_id, pk.klasse, pk.nr, pk.thema_keys, pk.quelle,
         coalesce(pk.datum, j.beginn + round(pk.lage * (j.ende - j.beginn))::int),
         1 + least(3, floor(pk.lage * 4))::int, round(pk.lage, 4),
         (select bool_and(exists (select 1 from public.thema_einstieg te where te.thema_key = x))
            from unnest(pk.thema_keys) x),
         array(select distinct x from unnest(pk.ab_hier || coalesce(
                   -- Klasse + 1 aus dem Schulplan (:9142) …
                   nullif(array(select distinct p.thema_key from public.schul_themenplan p
                                 where p.schule_id = pk.schule_id and lower(p.fach) = 'mathematik'
                                   and p.klasse = pk.klasse + 1 and p.thema_key is not null), '{}'),
                   -- … sonst Kernlehrplan der Klasse + 1 ohne das, was bis zur eigenen Klasse im Plan (bzw. im
                   -- Kernlehrplan der Klasse) steht, wie v_fuell :9188–9207.
                   array(select f.x from unnest(public.lsa_klp_themen('mathematik', pk.klasse + 1)) f(x)
                          where not f.x = any (
                                  case when exists (select 1 from public.schul_themenplan p
                                                     where p.schule_id = pk.schule_id and lower(p.fach) = 'mathematik'
                                                       and p.klasse = pk.klasse)
                                       then array(select p.thema_key from public.schul_themenplan p
                                                   where p.schule_id = pk.schule_id and lower(p.fach) = 'mathematik'
                                                     and p.klasse <= pk.klasse and p.thema_key is not null)
                                       else public.lsa_klp_themen('mathematik', pk.klasse) end)))) x
                -- array_remove(v_spaeter, Thema der Sitzung) :9209 — hier die Themen der Arbeit davor.
                where x = any (pk.thema_keys) or not x = any (coalesce((select v.thema_keys from pk v where v.schule_id = pk.schule_id
                                               and v.klasse = pk.klasse and v.nr = pk.nr - 1), '{}')))
    from pk cross join jahr j
$$;

create or replace function public.lsa_paket_skills_roh(p_schuljahr text) RETURNS TABLE(schule_id uuid, klasse integer, paket_nr integer, skill_key text, fall text, teil text, pflicht boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with recursive
  pk as (select row_number() over ()::int id, p.* from public.lsa_pakete_roh(p_schuljahr) p),
  ein as (select te.thema_key, te.skill_key from public.thema_einstieg te),
  raum_a as (
    select x.thema_key, x.skill_key, min(x.r) r from (
      select e.thema_key, e.skill_key, 1 r from ein e
      union all
      select e.thema_key, k.voraussetzt_skill_key, 2 from ein e join public.skill_kante k on k.skill_key = e.skill_key
      union all
      select e.thema_key, a.skill_key, 3 from ein e cross join lateral public.lsa_abschluss(e.skill_key) a) x
    group by 1, 2),
  r(pk, sk, pfad) as (
    select pk.id, k.voraussetzt_skill_key, array[k.voraussetzt_skill_key]
      from pk cross join unnest(pk.thema_keys) u(thema_key)
      join public.skill_thema st on st.thema_key = u.thema_key
      join public.skill_kante k on k.skill_key = st.skill_key
     where not exists (select 1 from public.skill_thema x
                        where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
    union
    select r.pk, k.voraussetzt_skill_key, r.pfad || k.voraussetzt_skill_key
      from r join pk on pk.id = r.pk
      join public.skill_thema x on x.skill_key = r.sk and x.thema_key = any (pk.spaeter)
      join public.skill_kante k on k.skill_key = r.sk
     where not k.voraussetzt_skill_key = any (r.pfad)),
  rand as (
    select distinct r.pk, r.sk from r join pk on pk.id = r.pk
     where not exists (select 1 from public.skill_thema x where x.skill_key = r.sk
                        and (x.thema_key = any (pk.spaeter) or x.thema_key = any (pk.thema_keys)))),
  rand_tief as (
    select distinct rd.pk, a.skill_key sk from rand rd join pk on pk.id = rd.pk
     cross join lateral public.lsa_abschluss(rd.sk) a
     where not exists (select 1 from rand x where x.pk = rd.pk and x.sk = a.skill_key)
       and not exists (select 1 from public.skill_thema st where st.skill_key = a.skill_key
                        and (st.thema_key = any (pk.spaeter) or st.thema_key = any (pk.thema_keys))))
  select pk.schule_id, pk.klasse, pk.paket_nr, a.skill_key, 'A',
         (array['einstieg', 'voraussetzung', 'tiefe'])[min(a.r)], min(a.r) <= 2
    from pk cross join unnest(pk.thema_keys) u(thema_key) join raum_a a on a.thema_key = u.thema_key
   group by pk.id, pk.schule_id, pk.klasse, pk.paket_nr, a.skill_key
  union all
  select pk.schule_id, pk.klasse, pk.paket_nr, x.sk, 'B', x.teil, x.teil = 'rand'
    from (select rand.pk, rand.sk, 'rand' teil from rand
          union all select rand_tief.pk, rand_tief.sk, 'rand_tiefe' from rand_tief) x
    join pk on pk.id = x.pk
    join public.skills s on s.skill_key = x.sk and s.klasse_herkunft <= pk.klasse
$$;

select public.lsa_paket_cache_auffrischen();

alter table public.lsa_paket_cache drop constraint lsa_paket_cache_quelle_check;
alter table public.lsa_paket_cache add constraint lsa_paket_cache_quelle_check
  check (quelle = any (array['bestaetigt', 'geschaetzt']));
