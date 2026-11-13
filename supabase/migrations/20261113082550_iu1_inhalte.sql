-- IU-1 · U1 (13.11.2026): Inhalte-Übersicht. Prüfziele, Stand je Thema und Session-Reihe, Prüfziel in Lenas Liste.
-- Auftrag und Belege: docs/inhalte/iu1/ist-analyse.md (U0).
--
-- Neu (alles lesend, stable, security definer mit festem search_path; Rechte: Admins, pruef_ziel_liste und
-- pruef_ziel_stand zusätzlich darf_pruefen):
--   - pruefziele, pruefziel_skills, pruefziel_ausschluss (Daten: Migration iu1_pruefziel_msa)
--   - inhalte_lsa_themen, inhalte_lsa_thema, inhalte_lsa_pruefziel, inhalte_session_reihen, inhalte_session_reihe,
--     inhalte_themen_ohne_reihe, pruef_ziel_stand
--   - Zwischenspeicher je Skill und Prüfziel (inhalte_skill_cache) ähnlich FR-2: Anweisungs-Trigger zählen eine Sequenz
--     hoch (ohne Zeilensperre), inhalte_auffrischen() (Admins) rechnet beim Laden der Seite neu; nicht frisch → live.
-- Geändert (keine geschützte Funktion; Aufrufer laut pg_proc in der PR):
--   - lsa_skill_bereit_roh, pruef_ziel_roh: Parameter p_ohne (Aufgaben, die nicht als Beleg zählen und nicht
--     vorgeschlagen werden). Ohne Parameter gleiche Ausgabe.
--   - pruef_ziel_liste: Parameter p_pruefziel, p_skill. Ohne sie gleiche Ausgabe.
--   - lsa_paket_cache_auffrischen, lsa_paket_cache_trigger: DELETE/UPDATE mit WHERE (safeupdate, offen.md O1).
-- Themenraum je Thema wie Fall A (raum_a in lsa_paket_skills_roh) über thema_einstieg, skill_kante, lsa_abschluss.
-- Unverändert: lsa_select_next_core, lsa_freie_aufgabe, lsa_im_pool, pruef_entscheiden, task_status_set,
-- aufgabe_ziehen, aufgabe_werten, bauform_pruefen, bauform_pruefung_senden, Sammelfreigaben.
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261113082550_iu1_inhalte.sql

-- ── Prüfziele ───────────────────────────────────────────────────────────────────────────────────────────────────
create table public.pruefziele (
  key          text primary key check (key ~ '^[a-z][a-z0-9_]*$'),
  titel        text not null check (btrim(titel) <> ''),
  beschreibung text
);
create table public.pruefziel_skills (
  pruefziel text not null references public.pruefziele (key) on delete cascade,
  skill_key text not null references public.skills (skill_key) on update cascade on delete cascade,
  bereich   text not null check (bereich ~ '^[a-z][a-z0-9_]*$'),
  primary key (pruefziel, skill_key)
);
-- zu_schwer: zählt für dieses Ziel nicht als Beleg und wird nicht vorgeschlagen; zu_leicht: zählt, wird markiert.
create table public.pruefziel_ausschluss (
  pruefziel text not null references public.pruefziele (key) on delete cascade,
  task_id   uuid not null references public.tasks (id) on delete cascade,
  grund     text not null check (grund in ('zu_schwer', 'zu_leicht')),
  primary key (pruefziel, task_id)
);
create index pruefziel_ausschluss_task on public.pruefziel_ausschluss (task_id);
alter table public.pruefziele enable row level security;
alter table public.pruefziel_skills enable row level security;
alter table public.pruefziel_ausschluss enable row level security;
-- Lesen: Admins und darf_pruefen. Schreiben nur per Migration (keine Policy).
create policy pruefziele_lesen on public.pruefziele for select using (public.darf_pruefen());
create policy pruefziel_skills_lesen on public.pruefziel_skills for select using (public.darf_pruefen());
create policy pruefziel_ausschluss_lesen on public.pruefziel_ausschluss for select using (public.darf_pruefen());
revoke all on public.pruefziele, public.pruefziel_skills, public.pruefziel_ausschluss from anon;

-- Aufgaben, die für ein Prüfziel nicht als Beleg zählen (leer ohne Ziel).
create function public.pruefziel_ohne(p_pruefziel text)
returns uuid[]
language sql stable security definer set search_path = public, pg_temp
as $$
  select coalesce(array_agg(a.task_id order by a.task_id), '{}')
    from public.pruefziel_ausschluss a where a.pruefziel = p_pruefziel and a.grund = 'zu_schwer'
$$;

-- ── Regel je Skill und Prüfliste mit Ausschluss ───────────────────────────────────────────────────────────────────
-- Neue Signatur (Parameter hinzu) ersetzt die alte, damit kein Aufruf mehrdeutig wird. Körper wie bisher, dazu
-- „not t.id = any (p_ohne)“.
drop function public.pruef_ziel_roh();
drop function public.lsa_skill_bereit_roh(text);

create function public.lsa_skill_bereit_roh(p_skill text default null, p_ohne uuid[] default '{}')
returns table(skill_key text, texte_im_pool integer, ohne_mc_im_pool integer, erfuellt boolean, fehlende_texte integer,
              fehlende_ohne_mc integer, schluessel text[])
language sql stable security definer set search_path = public, pg_temp
as $$
  with pool as (
    select t.skill_key, t.input_type, coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
     where 'lsa' = any (t.einsatz) and (p_skill is null or t.skill_key = p_skill)
       and not t.id = any (coalesce(p_ohne, '{}'))
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

create function public.pruef_ziel_roh(p_ohne uuid[] default '{}')
returns table(skill_key text, bedarf integer, rest integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
language sql stable security definer set search_path = public, pg_temp
as $$
  with g as (select * from public.lsa_regel()),
  fehlt as (select r.* from public.lsa_skill_bereit_roh(null, p_ohne) r where not r.erfuellt),
  kand0 as materialized (
    select t.id, t.skill_key, t.status, t.input_type <> 'MC' ohne_mc, t.sondierrang, public.pruef_im_pilot(t) pilot,
           coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
      join fehlt f on f.skill_key = t.skill_key
      join public.task_solutions s on s.task_id = t.id
     where 'lsa' = any (t.einsatz) and t.status in ('draft', 'review')
       and not t.id = any (coalesce(p_ohne, '{}'))
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

-- ── FR-2-Speicher unter safeupdate (offen.md O1) ──────────────────────────────────────────────────────────────────
create or replace function public.lsa_paket_cache_auffrischen()
returns void
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_sj  text := public.ka_schuljahr((now() at time zone 'Europe/Berlin')::date);
  v_gen bigint;
begin
  -- Zwei gleichzeitige Neuberechnungen warten aufeinander statt an 23505 zu scheitern.
  perform pg_advisory_xact_lock(hashtext('lsa_paket_cache'));
  -- Stand vor der Rechnung; schreibt währenddessen jemand, ist gen danach größer und der Speicher bleibt veraltet.
  select s.gen into v_gen from public.lsa_paket_cache_stand s;
  -- IU-1: mit WHERE, sonst bricht safeupdate (Rolle authenticator) den Aufruf aus der App ab.
  delete from public.lsa_paket_cache where schuljahr is not null;
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

create or replace function public.lsa_paket_cache_trigger()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  -- IU-1: mit WHERE, sonst scheitert unter safeupdate jeder Schreibzugriff der App auf die Plan-Tabellen.
  update public.lsa_paket_cache_stand set veraltet = true, gen = gen + 1 where id;
  return null;
end;
$$;

-- ── Zwischenspeicher je Skill und Prüfziel ─────────────────────────────────────────────────────────────────────
-- pruefziel '' = ohne Ziel (alle Aufgaben zählen).
create table public.inhalte_skill_cache (
  pruefziel       text not null,
  skill_key       text not null,
  texte           integer not null,
  erfuellt        boolean not null,
  frei            integer not null,
  zur_freigabe    integer not null,
  zu_pruefen      integer not null,
  fehlen          integer not null,
  zu_leicht       integer not null,
  offene_task_ids uuid[] not null,
  primary key (pruefziel, skill_key)
);
-- Stand: gen = Stand der Sequenz inhalte_cache_gen bei der Rechnung. Schreiber zählen die Sequenz hoch (ohne Sperre,
-- anders als FR-2, weil tasks ständig beschrieben wird). Frisch = gleicher Stand, ohne Fehler, höchstens 15 Minuten alt
-- (deckt Schreiber ab, die während der Rechnung noch nicht committet waren).
create sequence public.inhalte_cache_gen;
create table public.inhalte_cache_stand (
  id           boolean primary key default true check (id),
  berechnet_am timestamptz,
  gen          bigint,
  fehler       text
);
insert into public.inhalte_cache_stand (id) values (true);
revoke all on sequence public.inhalte_cache_gen from public, anon, authenticated;

create function public.inhalte_cache_frisch()
returns boolean
language sql stable security definer set search_path = public, pg_temp
as $$
  select exists (select 1 from public.inhalte_cache_stand s, public.inhalte_cache_gen g
                  where s.fehler is null and s.gen = g.last_value and g.is_called
                    and s.berechnet_am > now() - interval '15 minutes')
$$;
alter table public.inhalte_skill_cache enable row level security;
alter table public.inhalte_cache_stand enable row level security;
create policy inhalte_skill_cache_lesen on public.inhalte_skill_cache for select
  using (coalesce(public.get_my_role(), '') = 'admin');
create policy inhalte_cache_stand_lesen on public.inhalte_cache_stand for select
  using (coalesce(public.get_my_role(), '') = 'admin');
revoke all on public.inhalte_skill_cache, public.inhalte_cache_stand from anon;

-- Stand je Skill für ein Prüfziel (null = ohne Ziel), live.
--   texte        belegte Texte nach der Regel, gekappt: Regel − Bedarf (2 von 2 ⇔ erfüllt)
--   frei         Aufgaben im Pool (ohne ausgeschlossene)
--   zur_freigabe von Lena geprüfte Aufgaben mit neuem Text, die ein Admin freigeben kann (pruef_ziel_roh.freigabe_ids)
--   zu_pruefen   Aufgaben, die Lena noch prüfen muss und für die es Vorschläge gibt (least(rest, Vorschläge))
--   fehlen       Aufgaben, für die es keinen Vorschlag gibt (rest − zu_pruefen)
--   zu_leicht    Aufgaben im Pool, die für das Ziel als zu leicht markiert sind
create function public.inhalte_skill_stand_roh(p_pruefziel text default null)
returns table(skill_key text, texte integer, erfuellt boolean, frei integer, zur_freigabe integer, zu_pruefen integer,
              fehlen integer, zu_leicht integer, offene_task_ids uuid[])
language sql stable security definer set search_path = public, pg_temp
as $$
  with ohne as (select public.pruefziel_ohne(p_pruefziel) ids),
  g as (select * from public.lsa_regel()),
  b as (select r.* from public.lsa_skill_bereit_roh(null, (select ids from ohne)) r),
  z as (select r.* from public.pruef_ziel_roh((select ids from ohne)) r),
  pool as (
    select t.skill_key, count(*)::int n,
           (count(*) filter (where exists (select 1 from public.pruefziel_ausschluss a
                                            where a.pruefziel = p_pruefziel and a.task_id = t.id
                                              and a.grund = 'zu_leicht')))::int leicht
      from public.tasks t cross join ohne o
     where 'lsa' = any (t.einsatz) and not t.id = any (o.ids)
       and public.lsa_im_pool(t.id, false)
     group by t.skill_key)
  select b.skill_key,
         greatest(g.texte - greatest(b.fehlende_texte, b.fehlende_ohne_mc), 0)::int,
         b.erfuellt,
         coalesce(pool.n, 0),
         coalesce(cardinality(z.freigabe_ids), 0),
         coalesce(least(z.rest, cardinality(z.task_ids)), 0),
         coalesce(z.rest - least(z.rest, cardinality(z.task_ids)), 0),
         coalesce(pool.leicht, 0),
         coalesce(z.task_ids, '{}')
    from b cross join g
    left join z on z.skill_key = b.skill_key
    left join pool on pool.skill_key = b.skill_key
$$;

-- Speicher, wenn frisch, sonst live.
create function public.inhalte_skill_stand(p_pruefziel text default null)
returns table(skill_key text, texte integer, erfuellt boolean, frei integer, zur_freigabe integer, zu_pruefen integer,
              fehlen integer, zu_leicht integer, offene_task_ids uuid[])
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if public.inhalte_cache_frisch() then
    return query select c.skill_key, c.texte, c.erfuellt, c.frei, c.zur_freigabe, c.zu_pruefen, c.fehlen, c.zu_leicht,
                        c.offene_task_ids
                   from public.inhalte_skill_cache c where c.pruefziel = coalesce(p_pruefziel, '');
  else
    return query select * from public.inhalte_skill_stand_roh(p_pruefziel);
  end if;
end;
$$;

create function public.inhalte_cache_trigger()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  perform nextval('public.inhalte_cache_gen');
  return null;
end;
$$;

create trigger inhalte_cache_tasks after insert or update or delete or truncate on public.tasks
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_solutions after insert or update or delete or truncate on public.task_solutions
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_pruefungen after insert or update or delete or truncate on public.task_pruefungen
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_session_einstellungen after insert or update or delete or truncate
  on public.session_einstellungen for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_skills after insert or update or delete or truncate on public.skills
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_pruef_ausschluss after insert or update or delete or truncate
  on public.task_pruef_ausschluss for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_pruefung_ausgang after insert or update or delete or truncate
  on public.task_pruefung_ausgang for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_reviews after insert or update or delete or truncate on public.task_reviews
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_task_figures after insert or update or delete or truncate on public.task_figures
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_pruef_einstellungen after insert or update or delete or truncate
  on public.pruef_einstellungen for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_skill_thema after insert or update or delete or truncate on public.skill_thema
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_pruefziele after insert or update or delete or truncate on public.pruefziele
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_pruefziel_skills after insert or update or delete or truncate on public.pruefziel_skills
  for each statement execute function public.inhalte_cache_trigger();
create trigger inhalte_cache_pruefziel_ausschluss after insert or update or delete or truncate
  on public.pruefziel_ausschluss for each statement execute function public.inhalte_cache_trigger();

create function public.inhalte_cache_neu()
returns void
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_gen bigint;
begin
  perform pg_advisory_xact_lock(hashtext('inhalte_skill_cache'));
  v_gen := nextval('public.inhalte_cache_gen');
  delete from public.inhalte_skill_cache where pruefziel is not null;
  insert into public.inhalte_skill_cache
  select '', r.* from public.inhalte_skill_stand_roh(null) r;
  insert into public.inhalte_skill_cache
  select z.key, r.* from public.pruefziele z cross join lateral public.inhalte_skill_stand_roh(z.key) r;
  update public.inhalte_cache_stand set berechnet_am = now(), fehler = null, gen = v_gen where id;
end;
$$;

-- Für Admins beim Laden der Seite: frischt den Paket-Speicher (FR-2) und diesen Speicher auf, wenn nötig.
create function public.inhalte_auffrischen()
returns boolean
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  m text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'inhalte_auffrischen: nur Admins' using errcode = '42501';
  end if;
  perform public.lsa_abdeckung_auffrischen();
  if public.inhalte_cache_frisch() then
    return false;
  end if;
  if exists (select 1 from public.inhalte_cache_stand s
              where s.fehler is not null and s.berechnet_am > now() - interval '10 minutes') then
    return false;
  end if;
  begin
    perform public.inhalte_cache_neu();
  exception when others then
    get stacked diagnostics m = message_text;
    raise warning 'inhalte_skill_cache: Neuberechnung gescheitert (%), Funktionen rechnen live', m;
    update public.inhalte_cache_stand set fehler = m, berechnet_am = now() where id;
  end;
  return true;
end;
$$;

-- ── Themen: Raum, Pakete, Zeitfenster ───────────────────────────────────────────────────────────────────────────
-- Fall A je Thema wie raum_a in lsa_paket_skills_roh (Einstieg r 1, direkte Voraussetzung r 2, lsa_abschluss r 3;
-- Pflicht = r ≤ 2), je Thema statt je Paket, damit auch Themen nur in Arbeiten mit mehreren Themen einen Raum haben.
-- pgTAP 1a sichert die Gleichheit mit Fall A der Pakete.
create function public.inhalte_thema_raum(p_schuljahr text)
returns table(thema_key text, skill_key text, teil text, pflicht boolean)
language sql stable security definer set search_path = public, pg_temp
as $$
  select x.thema_key, x.skill_key, (array['einstieg', 'voraussetzung', 'tiefe'])[min(x.r)], min(x.r) <= 2
    from (select e.thema_key, e.skill_key, 1 r from public.thema_einstieg e
          union all
          select e.thema_key, k.voraussetzt_skill_key, 2
            from public.thema_einstieg e join public.skill_kante k on k.skill_key = e.skill_key
          union all
          select e.thema_key, a.skill_key, 3
            from public.thema_einstieg e cross join lateral public.lsa_abschluss(e.skill_key) a) x
   group by x.thema_key, x.skill_key
$$;

-- Themen der Pläne Kl. 8–10 (bzw. p_klasse): Klasse mit den meisten Schulen, Quartal der meisten Pakete mit
-- Monaten (frühestes und spätestes Datum der Pakete in diesem Quartal), Schulen (davon bestätigt).
create function public.inhalte_themen_basis(p_schuljahr text, p_klasse integer default null)
returns table(thema_key text, klasse integer, quartal integer, von date, bis date, schulen integer,
              schulen_bestaetigt integer)
language sql stable security definer set search_path = public, pg_temp
as $$
  with pt as (
    select p.*, u.thema_key
      from public.lsa_pakete_basis(p_schuljahr) p cross join unnest(p.thema_keys) u(thema_key)
     where p.klasse between 8 and 10 and (p_klasse is null or p.klasse = p_klasse)),
  kl as (
    select distinct on (pt.thema_key) pt.thema_key, pt.klasse
      from (select thema_key, klasse, count(distinct schule_id) n from pt group by 1, 2) pt
     order by pt.thema_key, pt.n desc, pt.klasse),
  q as (   -- Zeitfenster aus den Paketen der Klasse des Themas; Schulen über alle Klassen der Auswahl
    select distinct on (x.thema_key) x.thema_key, x.quartal, x.von, x.bis
      from (select pt.thema_key, pt.quartal, count(*) n, min(pt.datum) von, max(pt.datum) bis
              from pt join kl on kl.thema_key = pt.thema_key and kl.klasse = pt.klasse group by 1, 2) x
     order by x.thema_key, x.n desc, x.quartal),
  sch as (
    select thema_key, count(distinct schule_id)::int schulen,
           (count(distinct schule_id) filter (where quelle = 'bestaetigt'))::int best
      from pt group by 1)
  select kl.thema_key, kl.klasse, q.quartal, q.von, q.bis, sch.schulen, sch.best
    from kl join q using (thema_key) join sch using (thema_key)
$$;

create function public.inhalte_admin_pruefen(p_name text)
returns void
language plpgsql stable security definer set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception '%: nur Admins', p_name using errcode = '42501';
  end if;
end;
$$;

-- ── Reiter Lernstandsanalyse ─────────────────────────────────────────────────────────────────────────────────────
-- Ampel: vollstaendig = Einstieg und alle Kompetenzen bereit; eingeschraenkt = Einstieg und alle Pflicht-Kompetenzen
-- bereit; sonst noch_nicht. alle_zu_pruefen: Aufgaben für Lena über alle Themen der Auswahl, je Skill einmal.
create function public.inhalte_lsa_themen(p_klasse integer default null)
returns table(thema_key text, titel text, klasse integer, quartal integer, von date, bis date,
              komp_bereit integer, komp_teil integer, komp_offen integer, pflicht_bereit integer, pflicht_gesamt integer,
              hat_einstieg boolean, aufgaben_frei integer, aufgaben_zur_freigabe integer, aufgaben_zu_pruefen integer,
              aufgaben_fehlen integer, ampel text, schulen integer, schulen_bestaetigt integer,
              alle_zu_pruefen integer)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_sj text := public.lsa_schuljahr_heute();
begin
  perform public.inhalte_admin_pruefen('inhalte_lsa_themen');
  return query
  with th as (select * from public.inhalte_themen_basis(v_sj, p_klasse)),
  raum as (select r.* from public.inhalte_thema_raum(v_sj) r where r.thema_key in (select th.thema_key from th)),
  st as (select * from public.inhalte_skill_stand(null)),
  je as (
    select r.thema_key,
           count(*) filter (where s.erfuellt) bereit,
           count(*) filter (where not s.erfuellt and s.texte > 0) teil,
           count(*) filter (where s.texte = 0) offen,
           count(*) filter (where r.pflicht and s.erfuellt) pfl_bereit,
           count(*) filter (where r.pflicht) pfl,
           sum(s.frei) frei, sum(s.zur_freigabe) zur, sum(s.zu_pruefen) zu, sum(s.fehlen) fehlen
      from raum r join st s on s.skill_key = r.skill_key group by 1),
  alle as (select coalesce(sum(s.zu_pruefen), 0)::int n from st s
            where s.skill_key in (select r.skill_key from raum r))
  select th.thema_key, coalesce(t.label, th.thema_key), th.klasse, th.quartal, th.von, th.bis,
         coalesce(je.bereit, 0)::int, coalesce(je.teil, 0)::int, coalesce(je.offen, 0)::int,
         coalesce(je.pfl_bereit, 0)::int, coalesce(je.pfl, 0)::int, e.hat,
         coalesce(je.frei, 0)::int, coalesce(je.zur, 0)::int, coalesce(je.zu, 0)::int, coalesce(je.fehlen, 0)::int,
         case when e.hat and je.bereit > 0 and je.teil + je.offen = 0 then 'vollstaendig'
              when e.hat and je.pfl > 0 and je.pfl_bereit = je.pfl then 'eingeschraenkt'
              else 'noch_nicht' end,
         th.schulen, th.schulen_bestaetigt, (select n from alle)
    from th
    left join public.themen t on t.thema_key = th.thema_key
    left join je on je.thema_key = th.thema_key
    cross join lateral (select exists (select 1 from public.thema_einstieg x where x.thema_key = th.thema_key) hat) e
   order by th.quartal, th.schulen desc, th.thema_key;
end;
$$;

-- Kompetenzen eines Themas: Pflicht (Einstieg, direkte Voraussetzung) vor Tiefe.
create function public.inhalte_lsa_thema(p_thema_key text)
returns table(skill_key text, label text, teil text, rolle text, texte integer, erfuellt boolean, zu_pruefen integer,
              fehlen integer, offene_task_ids uuid[])
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  perform public.inhalte_admin_pruefen('inhalte_lsa_thema');
  return query
  select r.skill_key, coalesce(k.label, r.skill_key), case when r.pflicht then 'pflicht' else 'tiefe' end, r.teil,
         s.texte, s.erfuellt, s.zu_pruefen, s.fehlen, s.offene_task_ids
    from public.inhalte_thema_raum(public.lsa_schuljahr_heute()) r
    join public.inhalte_skill_stand(null) s on s.skill_key = r.skill_key
    left join public.skills k on k.skill_key = r.skill_key
   where r.thema_key = p_thema_key
   order by not r.pflicht, array_position(array['einstieg', 'voraussetzung', 'tiefe'], r.teil), s.erfuellt desc,
            s.texte desc, k.label, r.skill_key;
end;
$$;

-- Prüfziel (z. B. msa_zp10): je Bereich und gesamt (bereich null). Ausgeschlossene Aufgaben zählen nicht.
create function public.inhalte_lsa_pruefziel(p_key text)
returns table(bereich text, titel text, komp_bereit integer, komp_teil integer, komp_offen integer,
              fehlende_texte integer, aufgaben_frei integer, aufgaben_zur_freigabe integer, aufgaben_zu_pruefen integer,
              aufgaben_fehlen integer, zu_leicht integer, ampel text)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_titel text;
begin
  perform public.inhalte_admin_pruefen('inhalte_lsa_pruefziel');
  select z.titel into v_titel from public.pruefziele z where z.key = p_key;
  if v_titel is null then
    raise exception 'inhalte_lsa_pruefziel: Prüfziel % unbekannt', p_key using errcode = 'P0002';
  end if;
  return query
  with g as (select * from public.lsa_regel()),
  x as (
    select ps.bereich, s.*
      from public.pruefziel_skills ps join public.inhalte_skill_stand(p_key) s on s.skill_key = ps.skill_key
     where ps.pruefziel = p_key)
  select x.bereich, v_titel,
         (count(*) filter (where x.erfuellt))::int, (count(*) filter (where not x.erfuellt and x.texte > 0))::int,
         (count(*) filter (where x.texte = 0))::int,
         coalesce(sum(case when x.erfuellt then 0 else (select g.texte from g) - x.texte end), 0)::int,
         coalesce(sum(x.frei), 0)::int, coalesce(sum(x.zur_freigabe), 0)::int, coalesce(sum(x.zu_pruefen), 0)::int,
         coalesce(sum(x.fehlen), 0)::int, coalesce(sum(x.zu_leicht), 0)::int,
         case when bool_and(x.erfuellt) then 'vollstaendig' else 'noch_nicht' end
    from x
   group by grouping sets ((x.bereich), ())
   order by x.bereich nulls first;
end;
$$;

-- Für Lenas Liste: Stand je Kompetenz eines Prüfziels (erledigte Kompetenzen und „1 von 2“).
create function public.pruef_ziel_stand(p_pruefziel text)
returns table(skill_key text, skill_label text, bereich text, texte integer, erfuellt boolean, zu_leicht integer)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_ziel_stand: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select ps.skill_key, coalesce(k.label, ps.skill_key), ps.bereich, s.texte, s.erfuellt, s.zu_leicht
    from public.pruefziel_skills ps
    join public.inhalte_skill_stand(p_pruefziel) s on s.skill_key = ps.skill_key
    left join public.skills k on k.skill_key = ps.skill_key
   where ps.pruefziel = p_pruefziel
   order by ps.bereich, k.label, ps.skill_key;
end;
$$;

-- ── Reiter Session-Reihen ────────────────────────────────────────────────────────────────────────────────────────
-- Eine Reihe = bauformen.reihe. Themen = Themen der Kernideen-Bauformen. Videos je Skill der Kernideen:
-- freigegeben (eine Sequenz freigegeben), in_pruefung (eine Sequenz in Prüfung), sonst fehlt.
create function public.inhalte_reihe_videos()
returns table(reihe text, skill_key text, status text)
language sql stable security definer set search_path = public, pg_temp
as $$
  select distinct on (b.reihe, b.skill_key) b.reihe, b.skill_key,
         case when exists (select 1 from public.studio_sequenz q where q.skill_key = b.skill_key and q.status = 'freigegeben')
                then 'freigegeben'
              when exists (select 1 from public.studio_sequenz q where q.skill_key = b.skill_key and q.status = 'in_pruefung')
                then 'in_pruefung'
              else 'fehlt' end
    from public.bauformen b where b.kernidee_key is not null
   order by b.reihe, b.skill_key
$$;

create function public.inhalte_reihe_themen()
returns table(reihe text, thema_key text)
language sql stable security definer set search_path = public, pg_temp
as $$
  select distinct b.reihe, st.thema_key
    from public.bauformen b join public.skill_thema st on st.skill_key = b.skill_key
   where b.kernidee_key is not null
$$;

create function public.inhalte_session_reihen(p_klasse integer default null)
returns table(reihe text, titel text, thema_keys text[], klasse integer, sessions integer, quartal integer, von date,
              bis date, bf_freigegeben integer, bf_zur_freigabe integer, bf_rueckfrage integer, bf_offen integer,
              bf_zu_pruefen integer, vid_freigegeben integer, vid_in_pruefung integer, vid_fehlt integer,
              vid_gesamt integer, ampel text, schulen integer, schulen_bestaetigt integer)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_sj text := public.lsa_schuljahr_heute();
begin
  perform public.inhalte_admin_pruefen('inhalte_session_reihen');
  return query
  with rt as (select * from public.inhalte_reihe_themen()),
  pt as (
    select rt.reihe, p.*
      from rt join (select x.*, u.thema_key from public.lsa_pakete_basis(v_sj) x
                     cross join unnest(x.thema_keys) u(thema_key) where x.klasse between 8 and 10) p
        on p.thema_key = rt.thema_key),
  kl as (
    select distinct on (y.reihe) y.reihe, y.klasse
      from (select reihe, klasse, count(distinct schule_id) n from pt group by 1, 2) y
     order by y.reihe, y.n desc, y.klasse),
  q as (
    select distinct on (y.reihe) y.reihe, y.quartal, y.von, y.bis
      from (select reihe, quartal, count(*) n, min(datum) von, max(datum) bis from pt group by 1, 2) y
     order by y.reihe, y.n desc, y.quartal),
  sch as (
    select reihe, count(distinct schule_id)::int n,
           (count(distinct schule_id) filter (where quelle = 'bestaetigt'))::int best
      from pt group by 1),
  bf as (
    select b.reihe,
           (count(*) filter (where b.status = 'freigegeben'))::int frei,
           (count(*) filter (where b.status = 'zur_freigabe'))::int zur,
           (count(*) filter (where b.status in ('rueckfrage', 'beanstandet')))::int rueck,
           (count(*) filter (where b.status in ('entwurf', 'zur_pruefung', 'pausiert')))::int offen,
           (count(*) filter (where b.status = 'zur_pruefung'))::int zu_pruefen
      from public.bauformen b group by 1),
  plan as (select distinct l.reihe, l.session_nr from public.bauform_pruef_plan(null) l where l.session_nr is not null),
  vid as (
    select v.reihe, (count(*) filter (where v.status = 'freigegeben'))::int frei,
           (count(*) filter (where v.status = 'in_pruefung'))::int pruef,
           (count(*) filter (where v.status = 'fehlt'))::int fehlt, count(*)::int n
      from public.inhalte_reihe_videos() v group by 1)
  select bf.reihe,
         (select string_agg(coalesce(t.label, x.thema_key), ' · ' order by t.sort nulls last, x.thema_key)
            from rt x left join public.themen t on t.thema_key = x.thema_key where x.reihe = bf.reihe),
         (select array_agg(x.thema_key order by x.thema_key) from rt x where x.reihe = bf.reihe),
         kl.klasse, (select count(*)::int from plan where plan.reihe = bf.reihe), q.quartal, q.von, q.bis,
         bf.frei, bf.zur, bf.rueck, bf.offen, bf.zu_pruefen,
         coalesce(vid.frei, 0), coalesce(vid.pruef, 0), coalesce(vid.fehlt, 0), coalesce(vid.n, 0),
         case when bf.zur + bf.rueck + bf.offen = 0 and coalesce(vid.frei, 0) = coalesce(vid.n, 0) then 'bereit'
              when bf.frei + bf.zur > 0 then 'in_arbeit'
              else 'nicht_bereit' end,
         coalesce(sch.n, 0), coalesce(sch.best, 0)
    from bf
    left join kl on kl.reihe = bf.reihe
    left join q on q.reihe = bf.reihe
    left join sch on sch.reihe = bf.reihe
    left join vid on vid.reihe = bf.reihe
   where p_klasse is null or kl.klasse = p_klasse
   order by q.quartal nulls last, bf.reihe;
end;
$$;

-- Sessions einer Reihe (Zuordnung wie die Muster-Ansicht: bauform_pruef_plan). Bauformen ohne Session: nr null.
-- naechster_schritt: lena_prueft | rueckfrage | entwurf | admin_gibt_frei | video | fertig
create function public.inhalte_session_reihe(p_reihe text)
returns table(nr integer, titel text, bauformen integer, geprueft integer, freigegeben integer, rueckfrage integer,
              zu_pruefen integer, zur_freigabe integer, video_status text, naechster_schritt text)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  perform public.inhalte_admin_pruefen('inhalte_session_reihe');
  return query
  with pl as (select l.bauform_id, l.session_nr, l.session_titel from public.bauform_pruef_plan(null) l
               where l.reihe = p_reihe),
  b as (
    select pl.session_nr nr, pl.session_titel, b.status, b.kernidee_key
      from public.bauformen b left join pl on pl.bauform_id = b.id where b.reihe = p_reihe),
  vid as (select v.skill_key, v.status from public.inhalte_reihe_videos() v where v.reihe = p_reihe),
  je as (
    select b.nr, max(b.session_titel) titel, count(*)::int n,
           (count(*) filter (where b.status in ('zur_freigabe', 'freigegeben')))::int gepr,
           (count(*) filter (where b.status = 'freigegeben'))::int frei,
           (count(*) filter (where b.status in ('rueckfrage', 'beanstandet')))::int rueck,
           (count(*) filter (where b.status = 'zur_pruefung'))::int zu,
           (count(*) filter (where b.status = 'zur_freigabe'))::int zur,
           (count(*) filter (where b.status in ('entwurf', 'pausiert')))::int entw,
           (select case when count(*) = 0 then null
                        when bool_and(v.status = 'freigegeben') then 'freigegeben'
                        when bool_or(v.status = 'fehlt') then 'fehlt' else 'in_pruefung' end
              from vid v where v.skill_key in (select split_part(x.kernidee_key, ':', 1) from b x
                                               where x.nr is not distinct from b.nr and x.kernidee_key is not null)) video
      from b group by b.nr)
  select je.nr, je.titel, je.n, je.gepr, je.frei, je.rueck, je.zu, je.zur, je.video,
         case when je.zu > 0 then 'lena_prueft'
              when je.rueck > 0 then 'rueckfrage'
              when je.entw > 0 then 'entwurf'
              when je.zur > 0 then 'admin_gibt_frei'
              when coalesce(je.video, 'freigegeben') <> 'freigegeben' then 'video'
              else 'fertig' end
    from je
   order by je.nr nulls last;
end;
$$;

-- Themen der Pläne ohne Reihe. Vorarbeit: bauformen = Bauformen (aller Reihen) mit Skill im Themenraum;
-- lsa = freigegebene LSA-Aufgaben im Themenraum, aber keine Bauform; keine.
create function public.inhalte_themen_ohne_reihe(p_klasse integer default null)
returns table(thema_key text, titel text, klasse integer, quartal integer, von date, bis date, schulen integer,
              schulen_bestaetigt integer, bauformen integer, lsa_frei integer, vorarbeit text)
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_sj text := public.lsa_schuljahr_heute();
begin
  perform public.inhalte_admin_pruefen('inhalte_themen_ohne_reihe');
  return query
  with th as (select * from public.inhalte_themen_basis(v_sj, p_klasse)
               where thema_key not in (select x.thema_key from public.inhalte_reihe_themen() x)),
  raum as (select r.* from public.inhalte_thema_raum(v_sj) r where r.thema_key in (select th.thema_key from th)),
  st as (select * from public.inhalte_skill_stand(null)),
  je as (
    select r.thema_key,
           (select count(*)::int from public.bauformen b where b.skill_key in
              (select r2.skill_key from raum r2 where r2.thema_key = r.thema_key)) bf,
           coalesce(sum(s.frei), 0)::int frei
      from raum r left join st s on s.skill_key = r.skill_key group by 1)
  select th.thema_key, coalesce(t.label, th.thema_key), th.klasse, th.quartal, th.von, th.bis, th.schulen,
         th.schulen_bestaetigt, coalesce(je.bf, 0), coalesce(je.frei, 0),
         case when coalesce(je.bf, 0) > 0 then 'bauformen' when coalesce(je.frei, 0) > 0 then 'lsa' else 'keine' end
    from th
    left join public.themen t on t.thema_key = th.thema_key
    left join je on je.thema_key = th.thema_key
   order by th.quartal, th.schulen desc, th.thema_key;
end;
$$;

-- ── Lenas Liste mit Prüfziel und Kompetenz ───────────────────────────────────────────────────────────────────────
-- Ohne p_pruefziel und p_skill: wie bisher (Skills ohne Paket fallen heraus). Mit p_pruefziel: alle Skills des Ziels,
-- auch ohne Paket (Hebel 0), ohne ausgeschlossene Aufgaben. Mit p_skill: nur diese Kompetenz.
drop function public.pruef_ziel_liste(boolean, integer, text);
create function public.pruef_ziel_liste(p_nur_fokus boolean default false, p_quartal integer default null,
                                        p_schuljahr text default null, p_pruefziel text default null,
                                        p_skill text default null)
returns table(abschnitt text, skill_key text, skill_label text, thema_key text, thema_label text,
              fehlende_texte integer, rest integer, hebel_pakete integer, hebel_schulen integer, fokus_treffer integer,
              sort integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
language plpgsql stable security definer set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_sj   text := coalesce(p_schuljahr, public.lsa_schuljahr_heute());
  v_q    integer := coalesce(p_quartal, (select g.fokus_quartal from public.lsa_regel() g));
  v_ohne uuid[] := '{}';
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_ziel_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_pruefziel is not null then
    if not exists (select 1 from public.pruefziele z where z.key = p_pruefziel) then
      raise exception 'pruef_ziel_liste: Prüfziel % unbekannt', p_pruefziel using errcode = 'P0002';
    end if;
    v_ohne := public.pruefziel_ohne(p_pruefziel);
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
  ziel as (select zs.skill_key from public.pruefziel_skills zs where zs.pruefziel = p_pruefziel),
  thema as (
    select distinct on (st.skill_key) st.skill_key, th.thema_key, th.label
      from public.skill_thema st join public.themen th on th.thema_key = st.thema_key
     order by st.skill_key, th.sort nulls last, th.thema_key),
  nach as (
    select t.skill_key, array_agg(t.id order by t.sondierrang nulls last, t.id) ids
      from public.tasks t
     where 'lsa' = any (t.einsatz) and t.status = 'ready'
       and t.archiviert_am is null   -- MSA-1 M1: archivierte Aufgaben nicht nachpruefen
       and not t.id = any (v_ohne)
       and coalesce((select p2.entscheidung from public.task_pruefungen p2 where p2.task_id = t.id
                      order by p2.geprueft_am desc limit 1), '') <> 'passt'
     group by t.skill_key),
  zeilen as (
    select 'gezielt'::text ab, z.skill_key sk, z.bedarf, z.rest r, coalesce(h.pakete, 0) pakete,
           coalesce(h.schulen, 0) schulen, coalesce(h.fokus, 0) fokus, z.task_ids ids, z.freigabe_ids fids,
           z.pilot_fehlt pf
      from public.pruef_ziel_roh(v_ohne) z left join hebel h on h.skill_key = z.skill_key
     where (cardinality(z.task_ids) > 0 or cardinality(z.freigabe_ids) > 0)
       and case when p_pruefziel is null then h.skill_key is not null
                else z.skill_key in (select ziel.skill_key from ziel) end
    union all
    select 'nachpruefen', n.skill_key, 0, 0, coalesce(h.pakete, 0), coalesce(h.schulen, 0), coalesce(h.fokus, 0),
           n.ids, '{}'::uuid[], '{}'::uuid[]
      from nach n left join hebel h on h.skill_key = n.skill_key
     where p_pruefziel is null or n.skill_key in (select ziel.skill_key from ziel)),
  sortiert as (
    select zl.ab, zl.sk, k.label, th.thema_key, th.label tl, zl.bedarf, zl.r, zl.pakete, zl.schulen, zl.fokus,
           (row_number() over (partition by zl.ab order by zl.fokus desc, zl.schulen desc, zl.pakete desc, zl.sk))::int
             s, zl.ids, zl.fids, zl.pf
      from zeilen zl
      join public.skills k on k.skill_key = zl.sk
      left join thema th on th.skill_key = zl.sk)
  select so.ab, so.sk, so.label, so.thema_key, so.tl, so.bedarf, so.r, so.pakete, so.schulen, so.fokus, so.s, so.ids,
         so.fids, so.pf
    from sortiert so
   where p_skill is null or so.sk = p_skill
   order by so.ab, so.s;
end;
$$;

-- ── Rechte ──────────────────────────────────────────────────────────────────────────────────────────────────────
revoke all on function public.pruefziel_ohne(text) from public, anon, authenticated;
revoke all on function public.lsa_skill_bereit_roh(text, uuid[]) from public, anon, authenticated;
revoke all on function public.pruef_ziel_roh(uuid[]) from public, anon, authenticated;
revoke all on function public.inhalte_skill_stand_roh(text) from public, anon, authenticated;
revoke all on function public.inhalte_skill_stand(text) from public, anon, authenticated;
revoke all on function public.inhalte_cache_trigger() from public, anon, authenticated;
revoke all on function public.inhalte_cache_frisch() from public, anon, authenticated;
revoke all on function public.inhalte_cache_neu() from public, anon, authenticated;
revoke all on function public.inhalte_thema_raum(text) from public, anon, authenticated;
revoke all on function public.inhalte_themen_basis(text, integer) from public, anon, authenticated;
revoke all on function public.inhalte_admin_pruefen(text) from public, anon, authenticated;
revoke all on function public.inhalte_reihe_videos() from public, anon, authenticated;
revoke all on function public.inhalte_reihe_themen() from public, anon, authenticated;
-- Aufrufbar für angemeldete Nutzer; die Funktionen prüfen selbst (Admin bzw. darf_pruefen).
revoke all on function public.inhalte_auffrischen() from public, anon;
revoke all on function public.inhalte_lsa_themen(integer) from public, anon;
revoke all on function public.inhalte_lsa_thema(text) from public, anon;
revoke all on function public.inhalte_lsa_pruefziel(text) from public, anon;
revoke all on function public.inhalte_session_reihen(integer) from public, anon;
revoke all on function public.inhalte_session_reihe(text) from public, anon;
revoke all on function public.inhalte_themen_ohne_reihe(integer) from public, anon;
revoke all on function public.pruef_ziel_stand(text) from public, anon;
revoke all on function public.pruef_ziel_liste(boolean, integer, text, text, text) from public, anon;
grant execute on function public.inhalte_auffrischen() to authenticated;
grant execute on function public.inhalte_lsa_themen(integer) to authenticated;
grant execute on function public.inhalte_lsa_thema(text) to authenticated;
grant execute on function public.inhalte_lsa_pruefziel(text) to authenticated;
grant execute on function public.inhalte_session_reihen(integer) to authenticated;
grant execute on function public.inhalte_session_reihe(text) to authenticated;
grant execute on function public.inhalte_themen_ohne_reihe(integer) to authenticated;
grant execute on function public.pruef_ziel_stand(text) to authenticated;
grant execute on function public.pruef_ziel_liste(boolean, integer, text, text, text) to authenticated;
