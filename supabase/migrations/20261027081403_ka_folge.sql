-- L5 Teil A (docs/report/Bauauftrag-L5.md, Entscheidungen 1–5): Klassenarbeiten statt Themen-Nummern.
--
-- Welche Themen in welche Mathearbeit kommen, steht in keinem öffentlichen Plan. Diese Migration speichert, was
-- Familie, Kind und Admin dazu sagen, und leitet daraus je Schule und Klasse eine Folge ab:
--
--   1. ka_schuljahr(date): Schuljahr eines Datums nach NRW-Zählung (ab 1. August), Text '2026/27'.
--   2. lead_klassenarbeiten: eine Zeile je Mathearbeit eines Kindes in einem Schuljahr. nr = Nummer im Schuljahr,
--      null wenn unbekannt. Status 'geschrieben' wird nur gespeichert, wenn die Familie es sagt; eine Arbeit mit
--      vergangenem Datum gilt im Bericht als geschrieben (berechnet, nicht gespeichert).
--   3. leads.ka_anzahl_schuljahr: „Wie viele Mathearbeiten schreibt ihr dieses Schuljahr?“ (1–8, null = unbekannt).
--   4. schul_klassenarbeiten: vom Admin bestätigte Arbeiten je Schule, Klasse und Schuljahr.
--   5. Trigger auf session_checkin: Datum + Thema der Klassenarbeit im Check-in legen eine Zeile an (quelle
--      'checkin') bzw. ergänzen die Zeile desselben Kindes mit demselben Datum um das Thema.
--   6. ka_folge_schule: die abgeleitete Folge einer Schule/Klasse. Gruppiert wird nach Nummer, ohne Nummer nach
--      Datum. Ein Wert gilt erst, wenn mindestens zwei Kinder übereinstimmen (und mehr als jede andere Angabe zur
--      selben Arbeit) oder ein Admin ihn bestätigt hat. Nur Admin.
--   7. ka_folge_lead: was der Bericht eines Kindes nutzt. Eigene Angaben gehen vor: Eine gültige Arbeit der Schule
--      entfällt, wenn eine eigene Arbeit mit Nummer dieselbe Nummer oder ein gemeinsames Thema hat. Von anderen
--      Kindern kommt nur die abgeleitete Folge zurück, keine Zeile eines Kindes. Nur Admin.
--   8. ka_erstgespraech_speichern: Anzahl und die eine Arbeit aus dem Erstgespräch (quelle 'erstgespraech').
--
-- Nichts wird vorbelegt (Entscheidung 5): keine Arbeiten für irgendeine Schule, keine Schätzung.
-- RLS: beide Tabellen nur Admin (wie leads und lead_themen); anon ohne Rechte. Coaches lesen nichts davon direkt.
-- Rollback: supabase/rollback/20261027081403_ka_folge.sql.

-- ============================================================================
-- 1. Schuljahr eines Datums
-- ============================================================================

create function public.ka_schuljahr(p_datum date)
returns text
language sql
immutable
parallel safe
set search_path = pg_catalog
as $$
  select case when extract(month from p_datum) >= 8
    then extract(year from p_datum)::int::text || '/' || lpad(((extract(year from p_datum)::int + 1) % 100)::text, 2, '0')
    else (extract(year from p_datum)::int - 1)::text || '/' || lpad((extract(year from p_datum)::int % 100)::text, 2, '0')
  end
$$;

comment on function public.ka_schuljahr(date) is
  'L5: Schuljahr eines Datums (NRW, ab 1. August), z. B. 2026-10-27 -> 2026/27';

-- Themen einer Arbeit: jedes einmal, alle im Katalog.
create function public.ka_themen_pruefen()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from unnest(new.thema_keys) k group by k having count(*) > 1) then
    raise exception '%: Thema doppelt in thema_keys', tg_table_name using errcode = '23514';
  end if;
  if exists (select 1 from unnest(new.thema_keys) k where not exists (select 1 from public.themen t where t.thema_key = k)) then
    raise exception '%: unbekanntes Thema in thema_keys', tg_table_name using errcode = '23503';
  end if;
  return new;
end;
$$;

-- ============================================================================
-- 2. lead_klassenarbeiten
-- ============================================================================

create table public.lead_klassenarbeiten (
  id         uuid primary key default gen_random_uuid(),
  lead_id    uuid not null references public.leads (id) on delete cascade,
  fach       text not null default 'mathematik',
  schuljahr  text not null check (schuljahr ~ '^[0-9]{4}/[0-9]{2}$'),
  nr         int check (nr is null or nr >= 1),
  datum      date,
  thema_keys text[] not null check (cardinality(thema_keys) >= 1 and array_position(thema_keys, null) is null),
  status     text not null default 'bevorstehend' check (status in ('bevorstehend', 'geschrieben')),
  note       smallint check (note between 1 and 6),
  quelle     text not null check (quelle in ('erstgespraech', 'checkin', 'admin')),
  erfasst_am timestamptz not null default now(),
  constraint lead_klassenarbeiten_note_nur_geschrieben check (note is null or status = 'geschrieben'),
  constraint lead_klassenarbeiten_datum_im_schuljahr check (datum is null or public.ka_schuljahr(datum) = schuljahr),
  -- gleiches Kind, gleiches Datum = dieselbe Arbeit (Check-in ergänzt, Entscheidung 3)
  constraint lead_klassenarbeiten_ein_datum unique (lead_id, fach, datum)
);

comment on table public.lead_klassenarbeiten is
  'L5: Mathearbeiten eines Kindes je Schuljahr (Erstgespraech, Check-in, Admin). nr null = Nummer unbekannt.';

create unique index lead_klassenarbeiten_eine_nr
  on public.lead_klassenarbeiten (lead_id, fach, schuljahr, nr) where nr is not null;
create unique index lead_klassenarbeiten_ein_erstgespraech
  on public.lead_klassenarbeiten (lead_id, fach, schuljahr) where quelle = 'erstgespraech';

create trigger lead_klassenarbeiten_themen
  before insert or update of thema_keys on public.lead_klassenarbeiten
  for each row execute function public.ka_themen_pruefen();

alter table public.lead_klassenarbeiten enable row level security;
revoke all on public.lead_klassenarbeiten from anon;

create policy lead_klassenarbeiten_admin_all on public.lead_klassenarbeiten
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 3. leads.ka_anzahl_schuljahr
-- ============================================================================

alter table public.leads
  add column ka_anzahl_schuljahr smallint
  constraint leads_ka_anzahl_schuljahr_check check (ka_anzahl_schuljahr between 1 and 8);

comment on column public.leads.ka_anzahl_schuljahr is
  'L5: Zahl der Mathearbeiten in diesem Schuljahr laut Erstgespraech (1–8); null = unbekannt.';

-- ============================================================================
-- 4. schul_klassenarbeiten — bestätigte Arbeiten je Schule und Klasse
-- ============================================================================

create table public.schul_klassenarbeiten (
  schule_id      uuid not null references public.schulen (id) on delete cascade,
  fach           text not null default 'mathematik',
  klasse         int  not null check (klasse between 5 and 13),
  schuljahr      text not null check (schuljahr ~ '^[0-9]{4}/[0-9]{2}$'),
  nr             int  not null check (nr >= 1),
  thema_keys     text[] not null check (cardinality(thema_keys) >= 1 and array_position(thema_keys, null) is null),
  datum          date,
  bestaetigt     boolean not null default true,
  bestaetigt_von uuid references public.profiles (id) on delete set null,
  bestaetigt_am  timestamptz not null default now(),
  primary key (schule_id, fach, klasse, schuljahr, nr),
  constraint schul_klassenarbeiten_datum_im_schuljahr check (datum is null or public.ka_schuljahr(datum) = schuljahr)
);

comment on table public.schul_klassenarbeiten is
  'L5: vom Admin bestaetigte bzw. korrigierte Mathearbeiten je Schule, Klasse, Schuljahr. Keine Vorbelegung.';

create trigger schul_klassenarbeiten_themen
  before insert or update of thema_keys on public.schul_klassenarbeiten
  for each row execute function public.ka_themen_pruefen();

alter table public.schul_klassenarbeiten enable row level security;
revoke all on public.schul_klassenarbeiten from anon;

create policy schul_klassenarbeiten_admin_all on public.schul_klassenarbeiten
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 5. Check-in speist ein
-- ============================================================================

create function public.ka_aus_checkin()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_lead uuid;
begin
  if new.klassenarbeit_datum is null or new.klassenarbeit_thema_key is null then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and old.klassenarbeit_datum is not distinct from new.klassenarbeit_datum
     and old.klassenarbeit_thema_key is not distinct from new.klassenarbeit_thema_key then
    return new;
  end if;
  v_lead := public.session_lead_von_kind(new.student_id);
  if v_lead is null then
    return new;
  end if;
  insert into public.lead_klassenarbeiten as k (lead_id, schuljahr, datum, thema_keys, status, quelle)
  values (v_lead, public.ka_schuljahr(new.klassenarbeit_datum), new.klassenarbeit_datum,
          array[new.klassenarbeit_thema_key], 'bevorstehend', 'checkin')
  on conflict (lead_id, fach, datum) do update
     set thema_keys = case when excluded.thema_keys[1] = any (k.thema_keys) then k.thema_keys
                           else k.thema_keys || excluded.thema_keys end;
  return new;
end;
$$;

create trigger session_checkin_klassenarbeit
  after insert or update of klassenarbeit_datum, klassenarbeit_thema_key on public.session_checkin
  for each row execute function public.ka_aus_checkin();

revoke all on function public.ka_aus_checkin() from public, anon, authenticated;

-- ============================================================================
-- 6. Folge einer Schule und Klasse
-- ============================================================================

-- Ohne Rechteprüfung; nur für die beiden Funktionen darunter.
create function public.ka_folge_schule_roh(p_schule_id uuid, p_klasse int, p_schuljahr text, p_fach text)
returns table (nr int, thema_keys text[], datum date, kinder int, bestaetigt boolean, gueltig boolean)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with angaben as (
    -- Schlüssel einer Arbeit: Nummer, sonst Datum. Zeilen ohne beides tragen nichts bei.
    select k.lead_id, k.nr, k.datum,
           coalesce('n' || k.nr::text, 'd' || k.datum::text) as schluessel,
           (select array_agg(distinct x order by x) from unnest(k.thema_keys) x) as themen
      from public.lead_klassenarbeiten k
      join public.leads l on l.id = k.lead_id
     where l.schule_id = p_schule_id and l.class_level = p_klasse
       and k.schuljahr = p_schuljahr and k.fach = p_fach
       and (k.nr is not null or k.datum is not null)
  ), varianten as (
    select a.schluessel, min(a.nr) as nr, a.themen, count(distinct a.lead_id)::int as kinder
      from angaben a group by a.schluessel, a.themen
  ), rangiert as (
    select v.*, row_number() over w as rang, coalesce(lead(v.kinder) over w, 0) as zweite
      from varianten v
    window w as (partition by v.schluessel order by v.kinder desc, v.themen)
  ), abgeleitet as (
    select r.schluessel, r.nr, r.themen, r.kinder, (r.kinder >= 2 and r.kinder > r.zweite) as einig,
           (select a.datum from angaben a
             where a.schluessel = r.schluessel and a.themen = r.themen and a.datum is not null
             group by a.datum having count(distinct a.lead_id) >= 2
             order by count(distinct a.lead_id) desc, a.datum limit 1) as datum
      from rangiert r where r.rang = 1
  ), bestaetigt as (
    select s.nr, (select array_agg(distinct x order by x) from unnest(s.thema_keys) x) as themen, s.datum
      from public.schul_klassenarbeiten s
     where s.schule_id = p_schule_id and s.klasse = p_klasse and s.schuljahr = p_schuljahr and s.fach = p_fach
       and s.bestaetigt
  ), offen as (
    -- Abgeleitete Arbeiten, die keine Bestätigung abdeckt (gleiche Nummer bzw. gleiche Themen ohne Nummer).
    select a.* from abgeleitet a
     where not exists (select 1 from bestaetigt b where b.nr = a.nr or (a.nr is null and b.themen = a.themen))
  )
  select b.nr, b.themen, b.datum,
         coalesce((select v.kinder from varianten v where v.schluessel = 'n' || b.nr::text and v.themen = b.themen), 0),
         true, true
    from bestaetigt b
  union all
  select o.nr, o.themen, o.datum, o.kinder, false, o.einig
    from offen o
   order by 1 nulls last, 3 nulls last
$$;

revoke all on function public.ka_folge_schule_roh(uuid, int, text, text) from public, anon, authenticated;

create function public.ka_folge_schule(p_schule_id uuid, p_klasse int, p_schuljahr text, p_fach text default 'mathematik')
returns table (nr int, thema_keys text[], datum date, kinder int, bestaetigt boolean, gueltig boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'ka_folge_schule: nur Admin' using errcode = '42501';
  end if;
  return query select * from public.ka_folge_schule_roh(p_schule_id, p_klasse, p_schuljahr, p_fach);
end;
$$;

comment on function public.ka_folge_schule(uuid, int, text, text) is
  'L5: abgeleitete Folge der Mathearbeiten einer Schule/Klasse; gueltig ab zwei uebereinstimmenden Kindern oder Bestaetigung.';

-- Übersicht für den Admin: Schulen und Klassen, zu denen es Angaben oder Bestätigungen gibt.
create function public.ka_folge_uebersicht(p_schuljahr text, p_fach text default 'mathematik')
returns table (schule_id uuid, schulname text, klasse int, kinder int, bestaetigte int)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'ka_folge_uebersicht: nur Admin' using errcode = '42501';
  end if;
  return query
  with gruppen as (
    select l.schule_id, l.class_level as klasse, count(distinct k.lead_id)::int as kinder
      from public.lead_klassenarbeiten k join public.leads l on l.id = k.lead_id
     where k.schuljahr = p_schuljahr and k.fach = p_fach and l.schule_id is not null and l.class_level is not null
     group by 1, 2
  ), bestaetigt as (
    select s.schule_id, s.klasse, count(*)::int as bestaetigte
      from public.schul_klassenarbeiten s
     where s.schuljahr = p_schuljahr and s.fach = p_fach and s.bestaetigt
     group by 1, 2
  )
  select coalesce(g.schule_id, b.schule_id), sch.name, coalesce(g.klasse, b.klasse),
         coalesce(g.kinder, 0), coalesce(b.bestaetigte, 0)
    from gruppen g
    full join bestaetigt b on b.schule_id = g.schule_id and b.klasse = g.klasse
    join public.schulen sch on sch.id = coalesce(g.schule_id, b.schule_id)
   order by 2, 3;
end;
$$;

-- ============================================================================
-- 7. Was der Bericht eines Kindes nutzt
-- ============================================================================

create function public.ka_folge_lead(p_lead_id uuid, p_schuljahr text, p_fach text default 'mathematik')
returns table (nr int, thema_keys text[], datum date, status text, note smallint, herkunft text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_schule uuid;
  v_klasse int;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'ka_folge_lead: nur Admin' using errcode = '42501';
  end if;
  select l.schule_id, l.class_level into v_schule, v_klasse from public.leads l where l.id = p_lead_id;
  return query
  with eigene as (
    select k.nr, k.thema_keys, k.datum, k.status, k.note
      from public.lead_klassenarbeiten k
     where k.lead_id = p_lead_id and k.schuljahr = p_schuljahr and k.fach = p_fach
  ), schule as (
    select s.nr, s.thema_keys, s.datum
      from public.ka_folge_schule_roh(v_schule, v_klasse, p_schuljahr, p_fach) s
     where v_schule is not null and v_klasse is not null and s.gueltig and s.nr is not null
       and not exists (select 1 from eigene e
                        where e.nr is not null and (e.nr = s.nr or e.thema_keys && s.thema_keys))
  )
  select e.nr, e.thema_keys, e.datum, e.status, e.note, 'eigen'::text from eigene e
  union all
  select s.nr, s.thema_keys, s.datum, null::text, null::smallint, 'schule'::text from schule s
   order by 1 nulls last, 3 nulls last;
end;
$$;

comment on function public.ka_folge_lead(uuid, text, text) is
  'L5: Mathearbeiten fuer den Bericht eines Kindes: eigene Zeilen, dazu die gueltige Schulfolge, soweit eigene Angaben mit Nummer sie nicht abdecken.';

-- ============================================================================
-- 8. Erstgespräch
-- ============================================================================

-- Ersetzt die Zeile aus dem Erstgespräch (eine je Schuljahr). Ohne Stand oder ohne Themen: nur die Anzahl, die
-- Zeile entfällt. Hat eine Arbeit des Kindes schon dasselbe Datum (Check-in), wird sie um die Themen ergänzt.
create function public.ka_erstgespraech_speichern(
  p_lead_id    uuid,
  p_anzahl     int,
  p_status     text,
  p_datum      date,
  p_thema_keys text[],
  p_note       int
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_jahr text := public.ka_schuljahr(coalesce(p_datum, (now() at time zone 'Europe/Berlin')::date));
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'ka_erstgespraech_speichern: nur Admin' using errcode = '42501';
  end if;
  if p_status is not null and p_status not in ('bevorstehend', 'geschrieben') then
    raise exception 'ka_erstgespraech_speichern: unbekannter Stand %', p_status using errcode = '22023';
  end if;
  update public.leads set ka_anzahl_schuljahr = p_anzahl where id = p_lead_id;
  if not found then
    raise exception 'ka_erstgespraech_speichern: Lead fehlt' using errcode = 'P0002';
  end if;
  delete from public.lead_klassenarbeiten
   where lead_id = p_lead_id and fach = 'mathematik' and schuljahr = v_jahr and quelle = 'erstgespraech';
  if p_status is null or coalesce(cardinality(p_thema_keys), 0) = 0 then
    return;
  end if;
  insert into public.lead_klassenarbeiten as k (lead_id, schuljahr, datum, thema_keys, status, note, quelle)
  values (p_lead_id, v_jahr, case when p_status = 'bevorstehend' then p_datum end, p_thema_keys, p_status,
          case when p_status = 'geschrieben' then p_note end, 'erstgespraech')
  on conflict (lead_id, fach, datum) do update
     set thema_keys = k.thema_keys || array(select x from unnest(excluded.thema_keys) x where x <> all (k.thema_keys));
end;
$$;

revoke all on function public.ka_folge_schule(uuid, int, text, text) from public, anon;
revoke all on function public.ka_folge_uebersicht(text, text) from public, anon;
revoke all on function public.ka_folge_lead(uuid, text, text) from public, anon;
revoke all on function public.ka_erstgespraech_speichern(uuid, int, text, date, text[], int) from public, anon;
grant execute on function public.ka_folge_schule(uuid, int, text, text) to authenticated;
grant execute on function public.ka_folge_uebersicht(text, text) to authenticated;
grant execute on function public.ka_folge_lead(uuid, text, text) to authenticated;
grant execute on function public.ka_erstgespraech_speichern(uuid, int, text, date, text[], int) to authenticated;
