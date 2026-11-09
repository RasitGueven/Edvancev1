-- FR-2 · F1 (09.11.2026): Pakete je Klassenarbeit, LSA-Abdeckung als Ampel, gezielte Prüfliste für Lena.
-- Auftrag: docs/freigabe/fr2 (ist-analyse.md), Zahlen und Annahmen: docs/freigabe/bestandsaufnahme.md §2–3.
--
-- Nur lesende Funktionen (stable) für Admins und darf_pruefen, dazu:
--   - schule_fokus: Fokus-Schulen (schreiben nur Admins, lesen Admins und darf_pruefen)
--   - drei Stellschrauben in session_einstellungen: lsa_regel_texte (2), lsa_regel_ohne_mc (1), lsa_fokus_quartal (3)
--   - Zwischenspeicher für die Paket-Struktur (lsa_paket_cache*, F0 §6): hängt nur an Plan, Klassenarbeiten,
--     Graph und Einstiegen; Statement-Trigger auf diesen Tabellen markieren ihn als veraltet, lsa_abdeckung_auffrischen
--     rechnet neu. Der Pool-Stand je Skill wird
--     immer live gelesen. Ist der Speicher veraltet oder für ein anderes Schuljahr, rechnen die Funktionen live.
-- Unverändert: lsa_select_next_core, lsa_freie_aufgabe, lsa_im_pool, pruef_entscheiden, task_status_set. Kein neuer
-- Weg zu ready: die Sammelfreigabe läuft über pruef_sammel('freigeben', …) mit Gate (F0 §3).
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261109114850_fr2_lsa_pakete.sql

-- ── Stellschrauben ──────────────────────────────────────────────────────────────────────────────────────────────
insert into public.session_einstellungen (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, einheit)
values
  ('lsa_regel_texte',
   'LSA-Abdeckung: So viele verschiedene Aufgabentexte braucht ein Skill im LSA-Pool, damit er als abgedeckt gilt.',
   'zahl', '2', '2', 1, 4, true, 'anzahl'),
  ('lsa_regel_ohne_mc',
   'LSA-Abdeckung: So viele Aufgaben ohne Multiple Choice braucht ein Skill im LSA-Pool mindestens.',
   'zahl', '1', '1', 0, 2, true, 'anzahl'),
  ('lsa_fokus_quartal',
   'LSA-Abdeckung: Quartal des nächsten LSA-Fensters (Schuljahr 1.9.–30.6. linear geviertelt: 1 = bis Mitte Nov., 2 = bis Ende Jan., 3 = Feb. bis Mitte Apr., 4 = bis Ende Juni). Standard der Übersicht und Vorrang der Fokus-Schulen in der Prüfliste.',
   'zahl', '3', '3', 1, 4, true, null)
on conflict (schluessel) do nothing;

-- Die Regel je Skill an einer Stelle (Stellschrauben oben; Rückfall 2 / 1 / 3).
create or replace function public.lsa_regel(out texte integer, out ohne_mc integer, out fokus_quartal integer)
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  select coalesce((select (e.wert #>> '{}')::numeric::int from public.session_einstellungen e
                    where e.schluessel = 'lsa_regel_texte'), 2),
         coalesce((select (e.wert #>> '{}')::numeric::int from public.session_einstellungen e
                    where e.schluessel = 'lsa_regel_ohne_mc'), 1),
         coalesce((select (e.wert #>> '{}')::numeric::int from public.session_einstellungen e
                    where e.schluessel = 'lsa_fokus_quartal'), 3)
$$;

-- ── Fokus-Schulen ───────────────────────────────────────────────────────────────────────────────────────────────
create table public.schule_fokus (
  schule_id   uuid primary key references public.schulen (id) on delete cascade,
  gesetzt_von uuid references public.profiles (id) on delete set null default auth.uid(),
  gesetzt_am  timestamptz not null default now()
);
alter table public.schule_fokus enable row level security;
create policy schule_fokus_lesen on public.schule_fokus for select using (public.darf_pruefen());
create policy schule_fokus_admin_anlegen on public.schule_fokus for insert
  with check (public.get_my_role() = 'admin');
create policy schule_fokus_admin_loeschen on public.schule_fokus for delete
  using (public.get_my_role() = 'admin');

-- ── Pakete (roh, ohne Rechteprüfung, nicht aufrufbar für Clients) ───────────────────────────────────────────────
-- Klassenarbeit = bestätigte Folge aus schul_klassenarbeiten (bestaetigt, Schuljahr), wo es sie für Schule × Klasse
-- gibt; sonst geschätzt: 1 Unterrichtsvorhaben (schul_themenplan mit Thema) = 1 Arbeit (Bericht A1). Lage im Schuljahr
-- = Mitte des Vorhabens aus halbjahr, sonst kumulierten stunden, sonst position (A2); bestätigt aus datum, sonst aus der
-- Nummer. Schuljahr linear 1.9.–30.6., Quartal = Viertel nach der Mitte (A3).
-- spaeter = Themen dieser und der folgenden Arbeiten der Klasse, dazu Klasse + 1 (Schulplan, sonst Kernlehrplan) —
-- wie v_spaeter in lsa_select_next_core (schema-erwartet.sql:9142, :9188–9209). Kommend ist nur die Arbeit selbst
-- (weniger als drei Themen), deshalb füllt der Kernlehrplan der Klasse + 1 immer auf, wenn es keinen Plan dafür gibt.
create or replace function public.lsa_pakete_roh(p_schuljahr text)
  returns table (schule_id uuid, klasse integer, paket_nr integer, thema_keys text[], quelle text, datum date,
                 quartal integer, lage numeric, hat_einstieg boolean, spaeter text[])
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
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

-- Skills je Paket.
--   Fall A (Arbeit noch nicht geschrieben): Themenraum wie lsa_select_next_core :9075–9088 = thema_einstieg ∪
--     lsa_abschluss(Einstieg). Pflicht: einstieg und voraussetzung (eine Kante über skill_kante); Rest tiefe.
--   Fall B (Arbeit davor geschrieben): Vorschau-Rand wie lsa_select_next_core :9215–9252 mit kommend = Themen der
--     Arbeit; rand (Pflicht) und rand_tiefe = lsa_abschluss(Rand) ohne Rand und ohne Skills kommender/späterer
--     Themen; beide nur klasse_herkunft ≤ Klasse (:9404). Der Rand ist dort inline und kann nicht aufgerufen werden
--     (docs/freigabe/fr2/offen.md O1) — Änderungen dort hier nachziehen.
create or replace function public.lsa_paket_skills_roh(p_schuljahr text)
  returns table (schule_id uuid, klasse integer, paket_nr integer, skill_key text, fall text, teil text, pflicht boolean)
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
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

-- ── Zwischenspeicher der Paket-Struktur ─────────────────────────────────────────────────────────────────────────
create table public.lsa_paket_cache (
  schuljahr    text not null,
  schule_id    uuid not null,
  klasse       integer not null,
  paket_nr     integer not null,
  thema_keys   text[] not null,
  quelle       text not null check (quelle in ('bestaetigt', 'geschaetzt')),
  datum        date,
  quartal      integer not null check (quartal between 1 and 4),
  lage         numeric not null,
  hat_einstieg boolean not null,
  primary key (schuljahr, schule_id, klasse, paket_nr)
);
create table public.lsa_paket_skill_cache (
  schuljahr text not null,
  schule_id uuid not null,
  klasse    integer not null,
  paket_nr  integer not null,
  skill_key text not null,
  fall      text not null check (fall in ('A', 'B')),
  teil      text not null check (teil in ('einstieg', 'voraussetzung', 'tiefe', 'rand', 'rand_tiefe')),
  pflicht   boolean not null,
  primary key (schuljahr, schule_id, klasse, paket_nr, skill_key, fall),
  foreign key (schuljahr, schule_id, klasse, paket_nr)
    references public.lsa_paket_cache (schuljahr, schule_id, klasse, paket_nr) on delete cascade
);
create index lsa_paket_skill_cache_skill on public.lsa_paket_skill_cache (skill_key);
create table public.lsa_paket_cache_stand (
  id           boolean primary key default true check (id),
  schuljahr    text not null,
  berechnet_am timestamptz not null default now(),
  veraltet     boolean not null default false,
  -- Jede Änderung an Plan, Graph usw. zählt hoch; eine Neuberechnung gilt nur, wenn während ihr nichts kam.
  gen          bigint not null default 0,
  fehler       text
);
-- Schreiben nur die Funktionen unten (security definer); lesen dürfen Admins und darf_pruefen.
alter table public.lsa_paket_cache enable row level security;
alter table public.lsa_paket_skill_cache enable row level security;
alter table public.lsa_paket_cache_stand enable row level security;
create policy lsa_paket_cache_lesen on public.lsa_paket_cache for select using (public.darf_pruefen());
create policy lsa_paket_skill_cache_lesen on public.lsa_paket_skill_cache for select using (public.darf_pruefen());
create policy lsa_paket_cache_stand_lesen on public.lsa_paket_cache_stand for select using (public.darf_pruefen());

create or replace function public.lsa_paket_cache_auffrischen()
  returns void
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_sj  text := public.ka_schuljahr((now() at time zone 'Europe/Berlin')::date);
  v_gen bigint;
begin
  -- Zwei gleichzeitige Neuberechnungen warten aufeinander statt an 23505 zu scheitern.
  perform pg_advisory_xact_lock(hashtext('lsa_paket_cache'));
  -- Stand vor der Rechnung; schreibt währenddessen jemand, ist gen danach größer und der Speicher bleibt veraltet.
  select s.gen into v_gen from public.lsa_paket_cache_stand s;
  delete from public.lsa_paket_cache;
  insert into public.lsa_paket_cache (schuljahr, schule_id, klasse, paket_nr, thema_keys, quelle, datum, quartal, lage,
                                      hat_einstieg)
  select v_sj, p.schule_id, p.klasse, p.paket_nr, p.thema_keys, p.quelle, p.datum, p.quartal, p.lage,
         coalesce(p.hat_einstieg, false)
    from public.lsa_pakete_roh(v_sj) p;
  insert into public.lsa_paket_skill_cache (schuljahr, schule_id, klasse, paket_nr, skill_key, fall, teil, pflicht)
  select v_sj, s.schule_id, s.klasse, s.paket_nr, s.skill_key, s.fall, s.teil, s.pflicht
    from public.lsa_paket_skills_roh(v_sj) s;
  insert into public.lsa_paket_cache_stand (id, schuljahr, berechnet_am, fehler) values (true, v_sj, now(), null)
  on conflict (id) do update set schuljahr = excluded.schuljahr, berechnet_am = excluded.berechnet_am, fehler = null,
                                 veraltet = public.lsa_paket_cache_stand.gen is distinct from coalesce(v_gen, 0);
end;
$$;

-- Statement-Trigger: setzen nur „veraltet“ (billig, bricht keinen Schreibweg, auch nicht in langen Migrationen).
-- Bis zur nächsten Neuberechnung (lsa_abdeckung_auffrischen beim Laden der Seiten) rechnen die Funktionen live —
-- gleiches Ergebnis, nur langsamer.
create or replace function public.lsa_paket_cache_trigger()
  returns trigger
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
begin
  update public.lsa_paket_cache_stand set veraltet = true, gen = gen + 1;
  return null;
end;
$$;

-- Neu rechnen, wenn nötig (veraltet, Fehler oder neues Schuljahr). Für Admins und darf_pruefen; die Seiten rufen es
-- vor dem Lesen. Scheitert die Rechnung, bleibt der Fehler im Stand und die Funktionen rechnen live.
create or replace function public.lsa_abdeckung_auffrischen()
  returns boolean
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  m text;
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_abdeckung_auffrischen: kein Pruefrecht' using errcode = '42501';
  end if;
  if exists (select 1 from public.lsa_paket_cache_stand s
              where s.schuljahr = public.ka_schuljahr((now() at time zone 'Europe/Berlin')::date)
                and not s.veraltet and s.fehler is null) then
    return false;
  end if;
  -- Nach einem Fehler höchstens alle 10 Minuten neu versuchen (sonst rechnet jeder Seitenaufruf vergeblich).
  if exists (select 1 from public.lsa_paket_cache_stand s
              where s.fehler is not null and s.berechnet_am > now() - interval '10 minutes') then
    return false;
  end if;
  begin
    perform public.lsa_paket_cache_auffrischen();
  exception when others then
    get stacked diagnostics m = message_text;
    raise warning 'lsa_paket_cache: Neuberechnung gescheitert (%), Funktionen rechnen live', m;
    insert into public.lsa_paket_cache_stand (id, schuljahr, berechnet_am, fehler) values (true, '-', now(), m)
    on conflict (id) do update set fehler = excluded.fehler, berechnet_am = excluded.berechnet_am;
  end;
  return true;
end;
$$;

create trigger lsa_paket_cache_schul_themenplan after insert or update or delete or truncate on public.schul_themenplan
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_schul_klassenarbeiten after insert or update or delete or truncate
  on public.schul_klassenarbeiten for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_thema_einstieg after insert or update or delete or truncate on public.thema_einstieg
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_skill_kante after insert or update or delete or truncate on public.skill_kante
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_skill_thema after insert or update or delete or truncate on public.skill_thema
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_skills after insert or update or delete or truncate on public.skills
  for each statement execute function public.lsa_paket_cache_trigger();
create trigger lsa_paket_cache_themen after insert or update or delete or truncate on public.themen
  for each statement execute function public.lsa_paket_cache_trigger();

-- Pakete und Skills: aus dem Speicher, wenn er für das Schuljahr gilt, sonst live (gleiches Ergebnis).
create or replace function public.lsa_pakete_basis(p_schuljahr text)
  returns setof public.lsa_paket_cache
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if exists (select 1 from public.lsa_paket_cache_stand s where s.schuljahr = p_schuljahr and s.fehler is null
                and not s.veraltet) then
    return query select * from public.lsa_paket_cache c where c.schuljahr = p_schuljahr;
  else
    return query select p_schuljahr, p.schule_id, p.klasse, p.paket_nr, p.thema_keys, p.quelle, p.datum, p.quartal,
                        p.lage, coalesce(p.hat_einstieg, false)
                   from public.lsa_pakete_roh(p_schuljahr) p;
  end if;
end;
$$;

create or replace function public.lsa_paket_skills_basis(p_schuljahr text)
  returns setof public.lsa_paket_skill_cache
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if exists (select 1 from public.lsa_paket_cache_stand s where s.schuljahr = p_schuljahr and s.fehler is null
                and not s.veraltet) then
    return query select * from public.lsa_paket_skill_cache c where c.schuljahr = p_schuljahr;
  else
    return query select p_schuljahr, s.schule_id, s.klasse, s.paket_nr, s.skill_key, s.fall, s.teil, s.pflicht
                   from public.lsa_paket_skills_roh(p_schuljahr) s;
  end if;
end;
$$;

-- ── Stand je Skill (immer live) ─────────────────────────────────────────────────────────────────────────────────
-- Regel: mindestens lsa_regel().texte verschiedene lsa_text_schluessel unter den Aufgaben mit lsa_im_pool (wie
-- lsa_freie_aufgabe: Echt-Pool, ein leerer Schlüssel zählt als eigener Text), davon mindestens lsa_regel().ohne_mc
-- ohne MC. p_skill null = alle Skills.
create or replace function public.lsa_skill_bereit_roh(p_skill text default null)
  returns table (skill_key text, texte_im_pool integer, ohne_mc_im_pool integer, erfuellt boolean,
                 fehlende_texte integer, fehlende_ohne_mc integer, schluessel text[])
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  with pool as (
    select t.skill_key, t.input_type, coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
     where 'lsa' = any (t.einsatz) and (p_skill is null or t.skill_key = p_skill)
       and public.lsa_im_pool(t.id, false)),
  je as (
    select s.skill_key, count(distinct p.ts)::int texte, (count(p.ts) filter (where p.input_type <> 'MC'))::int ohne_mc,
           coalesce(array_agg(distinct p.ts) filter (where p.ts is not null), '{}') schluessel
      from public.skills s left join pool p on p.skill_key = s.skill_key
     where p_skill is null or s.skill_key = p_skill
     group by s.skill_key)
  select je.skill_key, je.texte, je.ohne_mc, je.texte >= g.texte and je.ohne_mc >= g.ohne_mc,
         greatest(g.texte - je.texte, 0), greatest(g.ohne_mc - je.ohne_mc, 0), je.schluessel
    from je cross join public.lsa_regel() g
$$;

-- ── Status je Paket (roh) ───────────────────────────────────────────────────────────────────────────────────────
-- Ampel: gruen = jeder Skill erfüllt die Regel und jedes Thema hat Einstiegsknoten; gelb = Einstiegsknoten vorhanden
-- und alle Pflicht-Skills erfüllt; rot sonst. p_annahme: Skills, die als erfüllt gelten (für lsa_wirkung).
-- fehlende_texte = Summe der Texte, die den fehlenden Skills bis zur Regel fehlen (Bericht Q36).
create or replace function public.lsa_status_roh(p_schuljahr text, p_annahme text[] default '{}')
  returns table (schule_id uuid, klasse integer, paket_nr integer, ampel text, fehlende_pflicht_skills integer,
                 fehlende_skills integer, fehlende_texte integer, hat_einstieg boolean, skills integer)
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  with b as (
    select r.skill_key, r.erfuellt or r.skill_key = any (coalesce(p_annahme, '{}')) ok,
           greatest(r.fehlende_texte, r.fehlende_ohne_mc) bedarf
      from public.lsa_skill_bereit_roh(null) r),
  ps as (
    select s.schule_id, s.klasse, s.paket_nr, s.skill_key, bool_or(s.pflicht) pflicht
      from public.lsa_paket_skills_basis(p_schuljahr) s group by 1, 2, 3, 4),
  je as (
    select p.schule_id, p.klasse, p.paket_nr, p.hat_einstieg,
           count(ps.skill_key)::int n,
           (count(*) filter (where ps.pflicht and not b.ok))::int fehl_pflicht,
           (count(*) filter (where not b.ok))::int fehl,
           coalesce(sum(b.bedarf) filter (where not b.ok), 0)::int fehl_texte
      from public.lsa_pakete_basis(p_schuljahr) p
      left join ps on ps.schule_id = p.schule_id and ps.klasse = p.klasse and ps.paket_nr = p.paket_nr
      left join b on b.skill_key = ps.skill_key
     group by 1, 2, 3, 4)
  select je.schule_id, je.klasse, je.paket_nr,
         case when je.hat_einstieg and je.fehl = 0 then 'gruen'
              when je.hat_einstieg and je.fehl_pflicht = 0 then 'gelb' else 'rot' end,
         je.fehl_pflicht, je.fehl, je.fehl_texte, je.hat_einstieg, je.n
    from je
$$;

-- ── Vorschläge je Skill (roh) ───────────────────────────────────────────────────────────────────────────────────
-- Für jeden Skill, der die Regel nicht erfüllt: Aufgaben des LSA-Pools mit gültiger Lösung (aktiv, Übung, kein
-- Tutorial, lsa_has_answers, lsa_eingabeformat_eindeutig), die in Lenas Board stehen (pruef_ausschluss null) und
-- einen Textschlüssel bringen, der im Pool fehlt. Je neuem Schlüssel genau eine Aufgabe.
--   freigabe_ids: schon „passt“ (review, pruef_freigabe_erlaubt) — warten nur auf die Admin-Freigabe, höchstens bedarf.
--   task_ids: Entwürfe für Lena, Nicht-MC zuerst, dann im Pilot, dann sondierrang; höchstens rest + 1 (Reserve für
--     „passt nicht“). pilot_fehlt: die davon, die Lena erst sieht, wenn ein Admin sie in den Pilot nimmt
--     (pruef_einstellungen.nur_pilot, pruef_sammel('pilot_an', …)).
create or replace function public.pruef_ziel_roh()
  returns table (skill_key text, bedarf integer, rest integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  with g as (select * from public.lsa_regel()),
  fehlt as (select r.* from public.lsa_skill_bereit_roh(null) r where not r.erfuellt),
  kand0 as materialized (
    select t.id, t.skill_key, t.status, t.input_type <> 'MC' ohne_mc, t.sondierrang, public.pruef_im_pilot(t) pilot,
           coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
      join fehlt f on f.skill_key = t.skill_key
      join public.task_solutions s on s.task_id = t.id
     where 'lsa' = any (t.einsatz) and t.status in ('draft', 'review')
       and coalesce(t.is_active, false) and not coalesce(t.is_tutorial, false) and t.content_type = 'exercise'
       and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
       and public.lsa_eingabeformat_eindeutig(t.input_type, t.bruch, t.unit, t.parts, s.correct_answers)
       and not coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) = any (f.schluessel)
       -- Fehlt nur der Beleg ohne MC, bringt eine MC-Aufgabe nichts.
       and (t.input_type <> 'MC' or f.fehlende_texte > 0)),
  kand as materialized (
    select k.* from kand0 k
     where public.pruef_ausschluss(k.id) is null
       and (k.status = 'draft' or public.pruef_freigabe_erlaubt(k.id))),
  je_schluessel as (   -- ein Vertreter je neuem Schlüssel: Geprüftes vor Entwurf, Nicht-MC, sondierrang
    select distinct on (k.skill_key, k.ts) k.*
      from kand k
     order by k.skill_key, k.ts, (k.status = 'review') desc, k.ohne_mc desc, k.pilot desc, k.sondierrang nulls last,
              k.id),
  geprueft as (
    select f.skill_key, greatest(f.fehlende_texte, f.fehlende_ohne_mc) bedarf,
           coalesce(array_agg(j.id order by j.ohne_mc desc, j.sondierrang nulls last, j.id)
                    filter (where j.status = 'review'), '{}') ids,
           (count(*) filter (where j.status = 'review'))::int n,
           (count(*) filter (where j.status = 'review' and j.ohne_mc))::int n_ohne
      from fehlt f left join je_schluessel j on j.skill_key = f.skill_key
     group by f.skill_key, f.fehlende_texte, f.fehlende_ohne_mc),
  rest as (
    select gp.skill_key, gp.bedarf, gp.ids[1:gp.bedarf] freigabe_ids,
           greatest(f.fehlende_texte - gp.n, f.fehlende_ohne_mc - gp.n_ohne, 0) rest
      from geprueft gp join fehlt f on f.skill_key = gp.skill_key),
  vorschlag as (
    select r.skill_key, x.id, x.pilot, x.rn
      from rest r
      cross join lateral (
        select j.id, j.pilot,
               row_number() over (order by j.ohne_mc desc, j.pilot desc, j.sondierrang nulls last, j.id) rn
          from je_schluessel j where j.skill_key = r.skill_key and j.status = 'draft') x
     where r.rest > 0 and x.rn <= r.rest + 1)
  select r.skill_key, r.bedarf, r.rest,
         coalesce((select array_agg(v.id order by v.rn) from vorschlag v where v.skill_key = r.skill_key), '{}'),
         coalesce(r.freigabe_ids, '{}'),
         coalesce((select array_agg(v.id order by v.rn) from vorschlag v where v.skill_key = r.skill_key and not v.pilot),
                  '{}')
    from rest r
$$;

-- ── Öffentliche Funktionen (Admins und darf_pruefen) ────────────────────────────────────────────────────────────
create or replace function public.lsa_schuljahr_heute()
  returns text language sql stable
  set search_path to 'public', 'pg_temp'
as $$ select public.ka_schuljahr((now() at time zone 'Europe/Berlin')::date) $$;

create or replace function public.lsa_pakete(p_klasse integer default null, p_schuljahr text default null)
  returns table (schule_id uuid, schule text, klasse integer, paket_nr integer, thema_keys text[], quelle text,
                 datum date, quartal integer, lage numeric)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_pakete: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select p.schule_id, s.name, p.klasse, p.paket_nr, p.thema_keys, p.quelle, p.datum, p.quartal, p.lage
    from public.lsa_pakete_basis(coalesce(p_schuljahr, public.lsa_schuljahr_heute())) p
    join public.schulen s on s.id = p.schule_id
   where p_klasse is null or p.klasse = p_klasse
   order by s.name, p.klasse, p.paket_nr;
end;
$$;

create or replace function public.lsa_skill_bereit(p_skill text)
  returns table (texte_im_pool integer, ohne_mc_im_pool integer, erfuellt boolean, fehlende_texte integer,
                 fehlende_ohne_mc integer)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_skill_bereit: kein Pruefrecht' using errcode = '42501';
  end if;
  return query select r.texte_im_pool, r.ohne_mc_im_pool, r.erfuellt, r.fehlende_texte, r.fehlende_ohne_mc
                 from public.lsa_skill_bereit_roh(p_skill) r;
end;
$$;

-- Skills eines Pakets mit Stand und Prüfbedarf (vorschlaege = Aufgaben, die Lena dafür noch prüft, ohne Reserve).
create or replace function public.lsa_paket_skills(p_schule uuid, p_klasse integer, p_paket_nr integer,
                                                   p_schuljahr text default null)
  returns table (skill_key text, skill_label text, thema_label text, fall text, teil text, pflicht boolean,
                 erfuellt boolean, texte_im_pool integer, fehlende_texte integer, vorschlaege integer)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_paket_skills: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with ps as (
    select s.* from public.lsa_paket_skills_basis(coalesce(p_schuljahr, public.lsa_schuljahr_heute())) s
     where s.schule_id = p_schule and s.klasse = p_klasse and s.paket_nr = p_paket_nr),
  b as (select r.* from public.lsa_skill_bereit_roh(null) r where r.skill_key in (select ps.skill_key from ps)),
  z as (select z.* from public.pruef_ziel_roh() z where z.skill_key in (select ps.skill_key from ps))
  select ps.skill_key, k.label,
         (select th.label from public.skill_thema st join public.themen th on th.thema_key = st.thema_key
           where st.skill_key = ps.skill_key order by th.sort nulls last, th.thema_key limit 1),
         ps.fall, ps.teil, ps.pflicht, b.erfuellt, b.texte_im_pool,
         greatest(b.fehlende_texte, b.fehlende_ohne_mc),
         coalesce(least(z.rest, cardinality(z.task_ids)), 0)
    from ps join public.skills k on k.skill_key = ps.skill_key
    join b on b.skill_key = ps.skill_key
    left join z on z.skill_key = ps.skill_key
   order by ps.fall, array_position(array['einstieg', 'voraussetzung', 'rand', 'tiefe', 'rand_tiefe'], ps.teil),
            ps.skill_key;
end;
$$;

create or replace function public.lsa_paket_status(p_schule uuid, p_klasse integer, p_paket_nr integer,
                                                   p_schuljahr text default null)
  returns table (ampel text, fehlende_pflicht_skills integer, fehlende_skills integer, fehlende_texte integer,
                 hat_einstieg boolean)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_paket_status: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select s.ampel, s.fehlende_pflicht_skills, s.fehlende_skills, s.fehlende_texte, s.hat_einstieg
    from public.lsa_status_roh(coalesce(p_schuljahr, public.lsa_schuljahr_heute())) s
   where s.schule_id = p_schule and s.klasse = p_klasse and s.paket_nr = p_paket_nr;
end;
$$;

-- Übersicht in einem Aufruf: je Schule und Paket die Ampel.
create or replace function public.lsa_abdeckung(p_klasse integer default null, p_quartal integer default null,
                                                p_nur_fokus boolean default false, p_schuljahr text default null)
  returns table (schule_id uuid, schule text, fokus boolean, klasse integer, paket_nr integer, thema_keys text[],
                 thema_labels text[], quelle text, datum date, quartal integer, lage numeric, ampel text,
                 fehlende_pflicht_skills integer, fehlende_skills integer, fehlende_texte integer, hat_einstieg boolean)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
declare
  v_sj text := coalesce(p_schuljahr, public.lsa_schuljahr_heute());
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_abdeckung: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select p.schule_id, sc.name, f.schule_id is not null, p.klasse, p.paket_nr, p.thema_keys,
         array(select coalesce(th.label, x) from unnest(p.thema_keys) with ordinality u(x, i)
                 left join public.themen th on th.thema_key = u.x order by u.i),
         p.quelle, p.datum, p.quartal, p.lage, st.ampel, st.fehlende_pflicht_skills, st.fehlende_skills,
         st.fehlende_texte, st.hat_einstieg
    from public.lsa_pakete_basis(v_sj) p
    join public.lsa_status_roh(v_sj) st
      on st.schule_id = p.schule_id and st.klasse = p.klasse and st.paket_nr = p.paket_nr
    join public.schulen sc on sc.id = p.schule_id
    left join public.schule_fokus f on f.schule_id = p.schule_id
   where (p_klasse is null or p.klasse = p_klasse)
     and (p_quartal is null or p.quartal = p_quartal)
     and (not coalesce(p_nur_fokus, false) or f.schule_id is not null)
   order by (f.schule_id is null), sc.name, p.klasse, p.paket_nr;
end;
$$;

-- Wirkung: Pakete, deren Ampel sich ändert, wenn p_skill (und p_auch) die Regel erfüllen. schule_neu = die Schule
-- hatte im Filter noch kein gelbes oder grünes Paket und hat danach eines.
create or replace function public.lsa_wirkung(p_skill text, p_auch text[] default '{}', p_quartal integer default null,
                                              p_schuljahr text default null)
  returns table (schule_id uuid, schule text, klasse integer, paket_nr integer, thema_keys text[], ampel_vorher text,
                 ampel_nachher text, schule_neu boolean)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
declare
  v_sj text := coalesce(p_schuljahr, public.lsa_schuljahr_heute());
begin
  if not public.darf_pruefen() then
    raise exception 'lsa_wirkung: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with p as (select * from public.lsa_pakete_basis(v_sj) x where p_quartal is null or x.quartal = p_quartal),
  vor as (select s.* from public.lsa_status_roh(v_sj) s join p using (schule_id, klasse, paket_nr)),
  nach as (select s.* from public.lsa_status_roh(v_sj, array_remove(array[p_skill] || coalesce(p_auch, '{}'), null)) s
             join p using (schule_id, klasse, paket_nr)),
  schule_vor as (select v.schule_id, bool_or(v.ampel <> 'rot') ok from vor v group by 1),
  schule_nach as (select n.schule_id, bool_or(n.ampel <> 'rot') ok from nach n group by 1)
  select v.schule_id, sc.name, v.klasse, v.paket_nr, p.thema_keys, v.ampel, n.ampel,
         not sv.ok and sn.ok
    from vor v
    join nach n using (schule_id, klasse, paket_nr)
    join p using (schule_id, klasse, paket_nr)
    join public.schulen sc on sc.id = v.schule_id
    join schule_vor sv on sv.schule_id = v.schule_id
    join schule_nach sn on sn.schule_id = v.schule_id
   where v.ampel <> n.ampel
   order by sc.name, v.klasse, v.paket_nr;
end;
$$;

-- Gezielte Prüfliste für Lena (abschnitt 'gezielt') und die ready-Aufgaben ohne Lenas letztes „passt“ (abschnitt
-- 'nachpruefen', Bericht Q04; Status bleibt). hebel_* zählen die Pakete im Filter, in denen der Skill liegt;
-- fokus_treffer die Pakete an Fokus-Schulen im Quartal p_quartal (sonst Stellschraube lsa_fokus_quartal).
-- Sortierung: fokus_treffer, hebel_schulen, hebel_pakete.
create or replace function public.pruef_ziel_liste(p_nur_fokus boolean default false, p_quartal integer default null,
                                                   p_schuljahr text default null)
  returns table (abschnitt text, skill_key text, skill_label text, thema_key text, thema_label text,
                 fehlende_texte integer, rest integer, hebel_pakete integer, hebel_schulen integer,
                 fokus_treffer integer, sort integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
declare
  v_sj text := coalesce(p_schuljahr, public.lsa_schuljahr_heute());
  v_q  integer := coalesce(p_quartal, (select g.fokus_quartal from public.lsa_regel() g));
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_ziel_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with p as (
    select x.*, f.schule_id is not null fokus from public.lsa_pakete_basis(v_sj) x
      left join public.schule_fokus f on f.schule_id = x.schule_id
     where (not coalesce(p_nur_fokus, false) or f.schule_id is not null)
       and (p_quartal is null or x.quartal = p_quartal)),
  ps as (
    select distinct s.schule_id, s.klasse, s.paket_nr, s.skill_key, p.fokus, p.quartal
      from public.lsa_paket_skills_basis(v_sj) s join p using (schule_id, klasse, paket_nr)),
  hebel as (
    select ps.skill_key, count(*)::int pakete, count(distinct ps.schule_id)::int schulen,
           (count(*) filter (where ps.fokus and ps.quartal = v_q))::int fokus
      from ps group by 1),
  thema as (
    select distinct on (st.skill_key) st.skill_key, th.thema_key, th.label
      from public.skill_thema st join public.themen th on th.thema_key = st.thema_key
     order by st.skill_key, th.sort nulls last, th.thema_key),
  nach as (
    select t.skill_key, array_agg(t.id order by t.sondierrang nulls last, t.id) ids
      from public.tasks t
     where 'lsa' = any (t.einsatz) and t.status = 'ready'
       and coalesce((select p2.entscheidung from public.task_pruefungen p2 where p2.task_id = t.id
                      order by p2.geprueft_am desc limit 1), '') <> 'passt'
     group by t.skill_key),
  zeilen as (
    select 'gezielt'::text ab, z.skill_key sk, z.bedarf, z.rest r, h.pakete, h.schulen, h.fokus, z.task_ids ids,
           z.freigabe_ids fids, z.pilot_fehlt pf
      from public.pruef_ziel_roh() z join hebel h on h.skill_key = z.skill_key
     where cardinality(z.task_ids) > 0 or cardinality(z.freigabe_ids) > 0
    union all
    select 'nachpruefen', n.skill_key, 0, 0, coalesce(h.pakete, 0), coalesce(h.schulen, 0), coalesce(h.fokus, 0),
           n.ids, '{}'::uuid[], '{}'::uuid[]
      from nach n left join hebel h on h.skill_key = n.skill_key)
  select zl.ab, zl.sk, k.label, th.thema_key, th.label, zl.bedarf, zl.r, zl.pakete, zl.schulen, zl.fokus,
         (row_number() over (partition by zl.ab order by zl.fokus desc, zl.schulen desc, zl.pakete desc, zl.sk))::int,
         zl.ids, zl.fids, zl.pf
    from zeilen zl
    join public.skills k on k.skill_key = zl.sk
    left join thema th on th.skill_key = zl.sk
   order by zl.ab, 11;
end;
$$;

-- ── Rechte ──────────────────────────────────────────────────────────────────────────────────────────────────────
revoke all on function public.lsa_regel() from public, anon, authenticated;
revoke all on function public.lsa_pakete_roh(text) from public, anon, authenticated;
revoke all on function public.lsa_paket_skills_roh(text) from public, anon, authenticated;
revoke all on function public.lsa_paket_cache_auffrischen() from public, anon, authenticated;
revoke all on function public.lsa_paket_cache_trigger() from public, anon, authenticated;
revoke all on function public.lsa_abdeckung_auffrischen() from public, anon;
grant execute on function public.lsa_abdeckung_auffrischen() to authenticated;
revoke all on function public.lsa_pakete_basis(text) from public, anon, authenticated;
revoke all on function public.lsa_paket_skills_basis(text) from public, anon, authenticated;
revoke all on function public.lsa_skill_bereit_roh(text) from public, anon, authenticated;
revoke all on function public.lsa_status_roh(text, text[]) from public, anon, authenticated;
revoke all on function public.pruef_ziel_roh() from public, anon, authenticated;

revoke all on function public.lsa_pakete(integer, text) from public, anon;
revoke all on function public.lsa_skill_bereit(text) from public, anon;
revoke all on function public.lsa_paket_skills(uuid, integer, integer, text) from public, anon;
revoke all on function public.lsa_paket_status(uuid, integer, integer, text) from public, anon;
revoke all on function public.lsa_abdeckung(integer, integer, boolean, text) from public, anon;
revoke all on function public.lsa_wirkung(text, text[], integer, text) from public, anon;
revoke all on function public.pruef_ziel_liste(boolean, integer, text) from public, anon;
grant execute on function public.lsa_pakete(integer, text) to authenticated;
grant execute on function public.lsa_skill_bereit(text) to authenticated;
grant execute on function public.lsa_paket_skills(uuid, integer, integer, text) to authenticated;
grant execute on function public.lsa_paket_status(uuid, integer, integer, text) to authenticated;
grant execute on function public.lsa_abdeckung(integer, integer, boolean, text) to authenticated;
grant execute on function public.lsa_wirkung(text, text[], integer, text) to authenticated;
grant execute on function public.pruef_ziel_liste(boolean, integer, text) to authenticated;

-- Erste Füllung des Zwischenspeichers.
select public.lsa_paket_cache_auffrischen();
