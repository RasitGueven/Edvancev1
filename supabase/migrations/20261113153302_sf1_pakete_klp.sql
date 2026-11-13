-- ============================================================================
-- SF-1 · S2 Pakete für Schulen ohne eigenen Plan (Quelle 'klp') und ohne gesperrte Skills der Schulform
-- ============================================================================
-- Erweiterung, kein Nachbau: Der Rumpf ist der Stand aus schema-erwartet.sql (origin/dev @ de3cf9ec), die
-- SF-1-Stellen sind kommentiert.
-- 1. lsa_paket_cache.quelle: zusätzlich 'klp'.
-- 2. lsa_pakete_roh: Eine Schule mit Schulform, aber ohne schul_themenplan (Mathe) bekommt Pakete aus
--    klp_themenplan, Quelle 'klp'. Bestätigte Klassenarbeiten gehen wie bisher vor. Für Klasse + 1 (spaeter)
--    zuerst der Schulplan, dann klp_themenplan (Folgejahr), dann wie bisher lsa_klp_themen. hat_einstieg zählt nur
--    Einstiege, die die Schulform verlangt. Schulen mit Plan ohne Sperren (alle Gymnasien): unverändert.
-- 3. lsa_paket_skills_roh: Skills mit Sperre in skill_schulform (Kurs 'alle' oder 'E', Fassung der Klasse) fallen weg.
-- 4. Speicher veraltet auch bei Änderungen an schulen (Schulform), klp_themenplan und skill_schulform.
-- Aufrufer (pg_proc-Scan 13.11.2026): lsa_pakete_roh ← lsa_paket_skills_roh, lsa_pakete_basis,
-- lsa_paket_cache_auffrischen; lsa_paket_skills_roh ← lsa_paket_skills_basis, lsa_paket_cache_auffrischen.
-- Rollback: supabase/rollback/20261113153302_sf1_pakete_klp.sql
-- ============================================================================

alter table public.lsa_paket_cache drop constraint lsa_paket_cache_quelle_check;
alter table public.lsa_paket_cache add constraint lsa_paket_cache_quelle_check
  check (quelle = any (array['bestaetigt', 'geschaetzt', 'klp']));

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
  -- SF-1: Schulen mit Schulform, aber ohne eigenen Mathe-Plan: Themen aus klp_themenplan (Kurs E als Standard).
  -- Fassung nach Klasse und Schuljahr: klp_fassung (ist-analyse §5). Doppeljahrgang linear über zwei Jahre,
  -- 1 Thema = 1 Arbeit; Gymnasien (g9) je Klasse. versatz 1 = dieselbe Klasse im Folgejahr: daraus „spaeter“ für
  -- Klasse − 1, damit die eigene Kohorte (und ihre Fassung) zählt, nicht die ältere.
  ohne as (
    select s.id schule_id, s.schulform from public.schulen s
     where s.schulform is not null
       and not exists (select 1 from public.schul_themenplan p where p.schule_id = s.id and lower(p.fach) = 'mathematik')),
  kz as (
    select o.schule_id, o.schulform, k.klasse, v.versatz,
           public.klp_fassung((left(p_schuljahr, 4)::int + v.versatz)::text, k.klasse, o.schulform) fassung,
           case when o.schulform = 'Gymnasium' then k.klasse::text when k.klasse <= 8 then '7/8' else '9/10' end dj,
           case when o.schulform = 'Gymnasium' then null else (k.klasse + 1) % 2 end jahr
      from ohne o cross join generate_series(7, 10) k(klasse) cross join (values (0), (1)) v(versatz)),
  kliste as (
    select kz.schule_id, kz.klasse, kz.versatz, kz.jahr, t.thema_key,
           (row_number() over (partition by kz.schule_id, kz.klasse, kz.versatz order by t.position, t.thema_key) - 0.5)::numeric
             / count(*) over (partition by kz.schule_id, kz.klasse, kz.versatz) g
      from kz cross join lateral (
        select distinct on (k.thema_key) k.thema_key, k.position from public.klp_themenplan k
         where k.fach = 'mathematik' and k.schulform = kz.schulform and k.klp_fassung = kz.fassung
           and k.doppeljahrgang = kz.dj and k.kurs = any (array['alle', 'E'])
         order by k.thema_key, k.position) t),
  kplan as (
    select l.schule_id, l.klasse, l.versatz, l.thema_key, case when l.jahr is null then l.g else 2 * l.g - l.jahr end lage
      from kliste l
     where l.jahr is null or (l.jahr = 0 and l.g < 0.5) or (l.jahr = 1 and l.g >= 0.5)),
  kuv as (
    select k.schule_id, k.klasse, k.thema_key, k.lage,
           row_number() over (partition by k.schule_id, k.klasse order by k.lage, k.thema_key)::int nr
      from kplan k
     where k.versatz = 0
       and not exists (select 1 from best b where b.schule_id = k.schule_id and b.klasse = k.klasse)),
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
      from best b cross join jahr j
    union all
    select k.schule_id, k.klasse, k.nr, array[k.thema_key], 'klp', null::date, k.lage,
           array(select k2.thema_key from kuv k2 where k2.schule_id = k.schule_id and k2.klasse = k.klasse and k2.nr >= k.nr)
      from kuv k)
  select pk.schule_id, pk.klasse, pk.nr, pk.thema_keys, pk.quelle,
         coalesce(pk.datum, j.beginn + round(pk.lage * (j.ende - j.beginn))::int),
         1 + least(3, floor(pk.lage * 4))::int, round(pk.lage, 4),
         -- SF-1: Ein Einstieg zählt nur, wenn ihn die Schulform verlangt (Kurs E, Fassung der Klasse).
         (select bool_and(exists (select 1 from public.thema_einstieg te where te.thema_key = x
                                    and not exists (select 1 from public.skill_schulform ss join public.schulen sc on sc.schulform = ss.schulform
                                    where sc.id = pk.schule_id and ss.skill_key = te.skill_key and not ss.zulaessig
                                      and ss.kurs = any (array['alle', 'E'])
                                      and ss.klp_fassung = any (array['alle', public.klp_fassung(p_schuljahr, pk.klasse, sc.schulform)]))))
            from unnest(pk.thema_keys) x),
         array(select distinct x from unnest(pk.ab_hier || coalesce(
                   -- Klasse + 1 aus dem Schulplan (:9142) …
                   nullif(array(select distinct p.thema_key from public.schul_themenplan p
                                 where p.schule_id = pk.schule_id and lower(p.fach) = 'mathematik'
                                   and p.klasse = pk.klasse + 1 and p.thema_key is not null), '{}'),
                   -- … SF-1: sonst Kernlehrplan der Schulform im Folgejahr (nur Schulen ohne eigenen Plan) …
                   nullif(array(select distinct k.thema_key from kplan k
                                 where k.schule_id = pk.schule_id and k.versatz = 1 and k.klasse = pk.klasse + 1), '{}'),
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
   where not exists (select 1 from public.skill_schulform ss join public.schulen sc on sc.schulform = ss.schulform
                      where sc.id = pk.schule_id and ss.skill_key = a.skill_key and not ss.zulaessig
                        and ss.kurs = any (array['alle', 'E'])
                        and ss.klp_fassung = any (array['alle', public.klp_fassung(p_schuljahr, pk.klasse, sc.schulform)])) -- SF-1: ohne gesperrte Skills der Schulform
   group by pk.id, pk.schule_id, pk.klasse, pk.paket_nr, a.skill_key
  union all
  select pk.schule_id, pk.klasse, pk.paket_nr, x.sk, 'B', x.teil, x.teil = 'rand'
    from (select rand.pk, rand.sk, 'rand' teil from rand
          union all select rand_tief.pk, rand_tief.sk, 'rand_tiefe' from rand_tief) x
    join pk on pk.id = x.pk
    join public.skills s on s.skill_key = x.sk and s.klasse_herkunft <= pk.klasse
   where not exists (select 1 from public.skill_schulform ss join public.schulen sc on sc.schulform = ss.schulform
                      where sc.id = pk.schule_id and ss.skill_key = x.sk and not ss.zulaessig
                        and ss.kurs = any (array['alle', 'E'])
                        and ss.klp_fassung = any (array['alle', public.klp_fassung(p_schuljahr, pk.klasse, sc.schulform)])) -- SF-1: ohne gesperrte Skills der Schulform
$$;

create trigger lsa_paket_cache_schulen after insert or delete or update of schulform or truncate on public.schulen
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_klp_themenplan after insert or delete or update or truncate on public.klp_themenplan
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_skill_schulform after insert or delete or update or truncate on public.skill_schulform
  for each statement execute function public.lsa_paket_cache_trigger();

-- Speicher neu rechnen (in Prod steht er seit dem 11.11. auf veraltet).
select public.lsa_paket_cache_auffrischen();
