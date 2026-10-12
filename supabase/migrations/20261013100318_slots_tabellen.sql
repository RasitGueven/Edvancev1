-- Slots SL1, Teil 1: Tabellen, Startinhalte, Indizes, RLS.
--
-- Bauauftrag Slots (Fassung 1), docs/slots/Bauauftrag-Slots.md. Die Nummern in den Kommentaren
-- ("Entscheidung 10") verweisen auf die maßgeblichen Entscheidungen dort.
--
-- Inhalt:
--   1. slot_zeiten           — pflegbare Uhrzeiten, Startinhalt 14–20 Uhr stündlich (Entscheidung 7)
--   2. raeume                — Räume mit aktiv ab / inaktiv ab
--   3. stammschichten        — Coach, Wochentag, Uhrzeit, Raum (H 47)
--   4. schicht_abweichungen  — Vertretung, fällt aus, Zusatz je Termin (H 49)
--   5. slot_rhythmus         — Rhythmus je Paket und Laufzeit (Entscheidung 2, Anforderung E 25)
--   6. stammplaetze          — Stammplatz eines Kindes (E 28)
--   7. kind_termine          — eine Zeile je Kind und Termin (Entscheidung 11)
--   8. coaching_sessions.raum_id / slot_zeit_id (Entscheidung 14)
--   9. Stellschraube slots_planbilanz_toleranz (Entscheidung 4)
--
-- Stammdaten werden nie gelöscht, sondern ab einem Datum beendet (Entscheidung 10). Rechte nach
-- Entscheidung 24: lesen nur Admin, schreiben niemand direkt — nur über die SECURITY-DEFINER-Funktionen
-- der folgenden Slots-Migrationen. Die Grundrechte aus 20260711120000_api_role_grants.sql (DEFAULT
-- PRIVILEGES) werden deshalb je Tabelle zurückgenommen.

begin;

-- ============================================================================
-- 1. slot_zeiten
-- ============================================================================

create table public.slot_zeiten (
  id           uuid primary key default gen_random_uuid(),
  beginn       time not null,
  ende         time generated always as (beginn + interval '60 minutes') stored,
  aktiv_ab     date not null,
  inaktiv_ab   date,
  angelegt_am  timestamptz not null default now(),
  angelegt_von uuid references public.profiles(id) on delete set null,
  constraint slot_zeiten_beginn_check check (beginn >= time '06:00' and beginn <= time '22:00'),
  constraint slot_zeiten_zeitraum_check check (inaktiv_ab is null or inaktiv_ab >= aktiv_ab)
);

create unique index slot_zeiten_beginn_aktiv_uniq on public.slot_zeiten (beginn) where inaktiv_ab is null;

comment on table public.slot_zeiten is
  'Uhrzeiten der Slots (60 Minuten). Nie löschen: inaktiv_ab setzen (slot_zeit_deaktivieren).';

insert into public.slot_zeiten (beginn, aktiv_ab)
select make_time(h, 0, 0), date '2026-01-01' from generate_series(14, 19) h;

-- ============================================================================
-- 2. raeume
-- ============================================================================

create table public.raeume (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  aktiv_ab     date not null,
  inaktiv_ab   date,
  angelegt_am  timestamptz not null default now(),
  angelegt_von uuid references public.profiles(id) on delete set null,
  constraint raeume_name_nicht_leer check (nullif(btrim(name), '') is not null),
  constraint raeume_name_eindeutig unique (name),
  constraint raeume_zeitraum_check check (inaktiv_ab is null or inaktiv_ab >= aktiv_ab)
);

comment on table public.raeume is
  'Räume am Standort. Nie löschen: inaktiv_ab setzen (raum_deaktivieren). Geöffnet ist ein Raum in einem Termin nur mit Coach.';

-- ============================================================================
-- 3. stammschichten
-- ============================================================================

create table public.stammschichten (
  id           uuid primary key default gen_random_uuid(),
  coach_id     uuid not null references public.profiles(id) on delete restrict,
  wochentag    smallint not null,
  slot_zeit_id uuid not null references public.slot_zeiten(id) on delete restrict,
  raum_id      uuid not null references public.raeume(id) on delete restrict,
  gueltig_ab   date not null,
  gueltig_bis  date,
  angelegt_am  timestamptz not null default now(),
  angelegt_von uuid references public.profiles(id) on delete set null,
  beendet_am   timestamptz,
  beendet_von  uuid references public.profiles(id) on delete set null,
  constraint stammschichten_wochentag_check check (wochentag between 1 and 5),
  -- gueltig_bis = gueltig_ab - 1: beendet, bevor sie begonnen hat (Rücknahme einer künftigen Schicht).
  constraint stammschichten_zeitraum_check check (gueltig_bis is null or gueltig_bis >= gueltig_ab - 1)
);

create index stammschichten_slot_idx on public.stammschichten (wochentag, slot_zeit_id);
create index stammschichten_coach_idx on public.stammschichten (coach_id);

comment on table public.stammschichten is
  'Stammschicht: Coach in Raum zu Wochentag (ISO 1–5) und Uhrzeit, in jeder Betriebswoche von gueltig_ab bis gueltig_bis. Doppelte Belegung (Raum oder Coach) verhindert stammschicht_anlegen (SL009).';

-- ============================================================================
-- 4. schicht_abweichungen
-- ============================================================================

create table public.schicht_abweichungen (
  id           uuid primary key default gen_random_uuid(),
  datum        date not null,
  slot_zeit_id uuid not null references public.slot_zeiten(id) on delete restrict,
  raum_id      uuid not null references public.raeume(id) on delete restrict,
  art          text not null,
  coach_id     uuid references public.profiles(id) on delete restrict,
  erfasst_am   timestamptz not null default now(),
  erfasst_von  uuid references public.profiles(id) on delete set null,
  constraint schicht_abweichungen_art_check check (art in ('vertretung', 'faellt_aus', 'zusatz')),
  constraint schicht_abweichungen_coach_check check ((art = 'faellt_aus') = (coach_id is null)),
  constraint schicht_abweichungen_eindeutig unique (datum, slot_zeit_id, raum_id)
);

comment on table public.schicht_abweichungen is
  'Abweichung von der Stammschicht für genau einen Termin und Raum: Vertretung (anderer Coach), fällt aus (Raum geschlossen), Zusatz (Raum ohne Stammschicht geöffnet). Löschen nur über termin_coach_setzen (zurück zur Stammschicht).';

-- ============================================================================
-- 5. slot_rhythmus (Entscheidung 2)
-- ============================================================================

create table public.slot_rhythmus (
  tier_id          uuid not null references public.tiers(id) on delete restrict,
  laufzeit_monate  integer not null,
  woechentlich     smallint not null,
  vierzehntaeglich smallint not null,
  constraint slot_rhythmus_pkey primary key (tier_id, laufzeit_monate),
  constraint slot_rhythmus_laufzeit_check check (laufzeit_monate in (6, 12)),
  constraint slot_rhythmus_werte_check check (woechentlich >= 0 and vierzehntaeglich >= 0 and woechentlich + vierzehntaeglich > 0)
);

comment on table public.slot_rhythmus is
  'Rhythmus je Paket und Laufzeit (Anforderung E 25): Zahl wöchentlicher und 14-täglicher Stammplätze. Vorschlag beim Vergeben und Wochengrenze ohne Stammplatz.';

insert into public.slot_rhythmus (tier_id, laufzeit_monate, woechentlich, vierzehntaeglich)
select t.id, r.laufzeit, r.w, r.v
  from (values ('Basic', 12, 1, 0), ('Basic', 6, 1, 0),
               ('Standard', 12, 1, 1), ('Standard', 6, 1, 0),
               ('Premium', 12, 2, 0), ('Premium', 6, 1, 1)) r(name, laufzeit, w, v)
  join public.tiers t on t.name = r.name;

-- ============================================================================
-- 6. stammplaetze
-- ============================================================================

create table public.stammplaetze (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students(id) on delete cascade,
  vertrag_id    uuid not null references public.vertraege(id) on delete cascade,
  wochentag     smallint not null,
  slot_zeit_id  uuid not null references public.slot_zeiten(id) on delete restrict,
  takt          text not null,
  gueltig_ab    date not null,
  gueltig_bis   date,
  vorgaenger_id uuid references public.stammplaetze(id) on delete set null,
  angelegt_am   timestamptz not null default now(),
  angelegt_von  uuid references public.profiles(id) on delete set null,
  beendet_am    timestamptz,
  beendet_von   uuid references public.profiles(id) on delete set null,
  constraint stammplaetze_wochentag_check check (wochentag between 1 and 5),
  constraint stammplaetze_takt_check check (takt in ('woechentlich', 'a_woche', 'b_woche')),
  constraint stammplaetze_zeitraum_check check (gueltig_bis is null or gueltig_bis >= gueltig_ab - 1)
);

create index stammplaetze_student_idx on public.stammplaetze (student_id);
create index stammplaetze_vertrag_idx on public.stammplaetze (vertrag_id);
create index stammplaetze_slot_idx on public.stammplaetze (wochentag, slot_zeit_id);

comment on table public.stammplaetze is
  'Stammplatz: Wochentag, Uhrzeit, Takt (A-Woche = ungerade ISO-KW). gueltig_bis NULL = bis zum Stichtag des Vertrags. Ändern ab Datum = alter endet am Vortag, neuer mit vorgaenger_id.';

-- ============================================================================
-- 7. kind_termine (Entscheidung 11)
-- ============================================================================

create table public.kind_termine (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students(id) on delete cascade,
  vertrag_id         uuid not null references public.vertraege(id) on delete cascade,
  datum              date not null,
  slot_zeit_id       uuid not null references public.slot_zeiten(id) on delete restrict,
  herkunft           text not null,
  stammplatz_id      uuid references public.stammplaetze(id) on delete cascade,
  umgebucht_von      uuid references public.kind_termine(id) on delete set null,
  zustand            text not null default 'planned',
  absage_eingang     timestamptz,
  absage_erfasst_von uuid references public.profiles(id) on delete set null,
  absage_erfasst_am  timestamptz,
  raum_id            uuid references public.raeume(id) on delete restrict,
  raum_fest          boolean not null default false,
  session_id         uuid references public.coaching_sessions(id) on delete set null,
  angelegt_am        timestamptz not null default clock_timestamp(),
  angelegt_von       uuid references public.profiles(id) on delete set null,
  constraint kind_termine_herkunft_check check (herkunft in ('stammplatz', 'zusatz')),
  constraint kind_termine_stammplatz_check check ((herkunft = 'stammplatz') = (stammplatz_id is not null)),
  constraint kind_termine_umgebucht_check check (umgebucht_von is null or herkunft = 'zusatz'),
  constraint kind_termine_zustand_check
    check (zustand in ('planned', 'present', 'cancelled', 'unexcused', 'cancelled_by_us')),
  constraint kind_termine_absage_check check (absage_eingang is null or zustand in ('cancelled', 'unexcused')),
  constraint kind_termine_raum_fest_check check (not raum_fest or raum_id is not null)
);

-- Entscheidung 19: höchstens ein aktiver Termin pro Kind und Tag.
create unique index kind_termine_ein_aktiver_je_tag on public.kind_termine (student_id, datum)
  where zustand in ('planned', 'present', 'unexcused');
create index kind_termine_slot_idx on public.kind_termine (datum, slot_zeit_id);
create index kind_termine_student_idx on public.kind_termine (student_id, datum);
create index kind_termine_vertrag_idx on public.kind_termine (vertrag_id);
create index kind_termine_stammplatz_idx on public.kind_termine (stammplatz_id) where stammplatz_id is not null;
create index kind_termine_session_idx on public.kind_termine (session_id) where session_id is not null;
create index kind_termine_umgebucht_idx on public.kind_termine (umgebucht_von) where umgebucht_von is not null;

comment on table public.kind_termine is
  'Ein Termin eines Kindes (Entscheidung 11). zustand mit denselben Codes wie session_students.attendance und die eine Wahrheit für geplant/abgesagt/ausgefallen; nach dem Festschreiben spiegelt ein Trigger die Anwesenheit hierher. raum_fest = Raum von Hand gesetzt.';

-- ============================================================================
-- 8. coaching_sessions: Raum-Termin (Entscheidung 14)
-- ============================================================================

alter table public.coaching_sessions
  add column raum_id uuid references public.raeume(id) on delete restrict,
  add column slot_zeit_id uuid references public.slot_zeiten(id) on delete restrict,
  add constraint coaching_sessions_raum_termin_check check ((raum_id is null) = (slot_zeit_id is null));

create unique index coaching_sessions_raum_termin_uniq on public.coaching_sessions (raum_id, scheduled_at)
  where raum_id is not null;

comment on column public.coaching_sessions.raum_id is
  'Gesetzt, wenn die Session aus einem Slot-Termin festgeschrieben wurde (termin_session_anlegen). Einzel-Sessions und Testläufe: NULL.';

-- ============================================================================
-- 9. Stellschraube Toleranz der Planbilanz (Entscheidung 4)
-- ============================================================================

insert into public.session_einstellungen (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, einheit)
values ('slots_planbilanz_toleranz',
        'Slots: Abweichung der Planbilanz in Einheiten, die noch als „passt“ gilt. Wirkt sofort auf die Planbilanz aller Kinder, nicht erst ab der nächsten Session.',
        'zahl', '2', '2', 0, 5, true, 'anzahl');

-- ============================================================================
-- RLS und Rechte (Entscheidung 24)
-- ============================================================================

do $$
declare
  t text;
begin
  foreach t in array array['slot_zeiten', 'raeume', 'stammschichten', 'schicht_abweichungen',
                           'slot_rhythmus', 'stammplaetze', 'kind_termine'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select using (coalesce(public.get_my_role(), %L) = %L)',
                   t || '_admin_read', t, '', 'admin');
    execute format('revoke all on public.%I from public, anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
  end loop;
end;
$$;

commit;
