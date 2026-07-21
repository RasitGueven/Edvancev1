-- ============================================================================
-- S10 (Slot-System): Wochen-Zeitraster, Favoriten und feste Zuweisung.
--
--   1. slots            — das Wochenraster (Wochentag × Uhrzeit × Raum), mit
--                         Kapazitaet. Deaktivierbar statt loeschbar.
--   2. slot_wishes      — bis zu 3 Favoriten je Lead (Rang 1–3), erhoben im
--                         Erstgespraech (S8). Unverbindlich.
--   3. slot_assignments — die EINE feste Zuweisung. Aktiv = released_at null.
--   4. slot_assign / slot_release — die beiden Tore. Nur coach/admin.
--
-- ============================================================================
-- DER ARCHITEKTUR-BRANCHPOINT — und warum die Slot-Tabellen an `leads` haengen
--
--   Alle drei Tabellen referenzieren leads(id), NICHT students(id) — obwohl
--   students existiert. Der Grund ist zeitlich: Der Slot wird im Erstgespraech
--   vergeben, also VOR Vertragsabschluss. Zu diesem Zeitpunkt existiert der
--   Lead, aber noch kein Kind. Ein students-FK haette entweder eine
--   provisorische Schueler-Zeile erzwungen (die A1-Leitplanke sagt nein) oder
--   die Zuweisung ans Gespraechsende verschoben (fachlich falsch — der Platz
--   ist das Ergebnis des Gespraechs, nicht seine Nachbereitung).
--
--   OFFENE FRAGE (bewusst NICHT hier entschieden): Was passiert mit einer
--   Slot-Zuweisung, wenn der Lead ueber lead_convert() zum Studenten wird?
--   Wandert sie mit? Bleibt sie am Lead und wird ueber
--   leads.converted_student_id aufgeloest? Das ist eine Datenmodell-Frage fuer
--   die Gruenderrunde, keine Implementierungsdetail-Frage — und sie ist Teil
--   eines groesseren Musters: auch der Kindname faellt heute nach der
--   Konvertierung weg (unabhaengig im Report-Kontext aufgeschlagen). Die
--   Migration legt sich bewusst NICHT fest; sie macht den Zustand nur
--   nachvollziehbar (released_at statt delete, siehe unten).
-- ============================================================================
-- DIE KAPAZITAETS-GARANTIE — warum das Zaehlen in slot_assign() liegt
--
--   Ein naives "erst zaehlen, dann einfuegen" ueberbucht unter Nebenlaeufigkeit:
--   zwei gleichzeitige Zuweisungen lesen beide belegt=4 bei capacity=5 und
--   fuegen beide ein → 6. Deshalb sperrt slot_assign() ZUERST die slots-Zeile
--   (select … for update) und zaehlt erst danach. Die zweite Transaktion
--   wartet am Lock und sieht den Stand NACH der ersten. Der Lock liegt auf dem
--   Slot, nicht auf der Zuweisungstabelle — nur Zuweisungen in DENSELBEN Slot
--   serialisieren, alles andere laeuft parallel.
--
--   Zweite Verteidigungslinie, unabhaengig von der RPC: der partielle
--   Unique-Index slot_assignments_active_lead_unique. Selbst wenn jemand an
--   der RPC vorbei schreibt, kann ein Lead nie zwei aktive Zuweisungen halten.
--
--   Das Frontend zeigt die Auslastung nur AN — es entscheidet sie nicht
--   (src/lib/supabase/slots.ts, Kopfkommentar). Es gibt genau eine Wahrheit.
-- ============================================================================

begin;

-- ============================================================================
-- 1. slots — das Wochenraster
-- ============================================================================

create table if not exists slots (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  -- 0 = Montag … 6 = Sonntag. Bewusst NICHT Postgres' extract(dow) (0=Sonntag):
  -- die Woche beginnt in der Anzeige montags, und das Frontend soll nicht
  -- umrechnen muessen (src/types/slots.ts, type Weekday).
  weekday    smallint not null check (weekday between 0 and 6),
  start_time time not null,
  room       text not null check (length(btrim(room)) > 0),
  -- max. 5 ist die Produktzusage (Praesenz-Kleingruppen), nicht nur ein
  -- Defaultwert — deshalb als CHECK und nicht als Konvention.
  capacity   integer not null default 5 check (capacity between 1 and 5),
  active     boolean not null default true
);

comment on table slots is
  'Wochen-Zeitraster der Praesenzgruppen (Wochentag × Uhrzeit × Raum) mit '
  'Kapazitaet. weekday: 0=Montag … 6=Sonntag. Slots werden deaktiviert '
  '(active=false), nie geloescht — bestehende Zuweisungen bleiben '
  'nachvollziehbar.';
comment on column slots.capacity is
  'Maximale Belegung. CHECK 1..5 pinnt die Produktzusage „Kleingruppen max. 5". '
  'Durchgesetzt wird sie bei der Zuweisung in slot_assign() (Row-Lock).';

-- Ein Raum kann zu einer Zeit nur eine aktive Gruppe tragen. Partiell auf
-- active: ein deaktivierter Alt-Slot blockiert die Koordinate nicht dauerhaft.
create unique index if not exists slots_active_coord_unique
  on slots (weekday, start_time, room) where active;

create index if not exists slots_weekday_idx on slots (weekday, start_time);

alter table slots enable row level security;

revoke all on table slots from anon;

create policy "slots_coach_admin_all" on slots
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- ============================================================================
-- 2. slot_wishes — bis zu 3 Favoriten je Lead (Erstgespraech, unverbindlich)
-- ============================================================================

create table if not exists slot_wishes (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  lead_id    uuid not null references leads(id) on delete cascade,
  slot_id    uuid not null references slots(id) on delete cascade,
  rang       smallint not null check (rang between 1 and 3)
);

comment on table slot_wishes is
  'Bis zu 3 Slot-Favoriten je Lead (rang 1=liebster … 3), erhoben im '
  'Erstgespraech (S8). UNVERBINDLICH — ein Wunsch reserviert nichts und zaehlt '
  'nie gegen die Kapazitaet. Verbindlich ist ausschliesslich slot_assignments.';

-- Kein Rang doppelt und kein Slot doppelt je Lead. Das Frontend setzt die
-- Liste als Ganzes neu (delete + insert), damit Raenge nie Luecken haben —
-- diese Indizes sind die Absicherung darunter.
create unique index if not exists slot_wishes_lead_rang_unique
  on slot_wishes (lead_id, rang);
create unique index if not exists slot_wishes_lead_slot_unique
  on slot_wishes (lead_id, slot_id);

create index if not exists slot_wishes_slot_idx on slot_wishes (slot_id);

alter table slot_wishes enable row level security;

revoke all on table slot_wishes from anon;

create policy "slot_wishes_coach_admin_all" on slot_wishes
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- ============================================================================
-- 3. slot_assignments — die feste Zuweisung
-- ============================================================================

create table if not exists slot_assignments (
  id          uuid primary key default gen_random_uuid(),
  slot_id     uuid not null references slots(id) on delete cascade,
  lead_id     uuid not null references leads(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  -- Loesen heisst released_at setzen, nicht loeschen: die Historie „welches
  -- Kind sass wann in welcher Gruppe" bleibt lesbar (und der partielle Index
  -- unten macht genau eine Zeile je Lead „aktiv").
  released_at timestamptz,
  -- on delete set null: faellt das Konto des Zuweisenden, bleibt die Zuweisung
  -- bestehen — sie gehoert dem Lead, nicht dem Admin.
  created_by  uuid references profiles(id) on delete set null
);

comment on table slot_assignments is
  'Feste Zuweisung Lead → Slot. Aktiv = released_at is null. Angelegt '
  'ausschliesslich ueber slot_assign() (Kapazitaetspruefung unter Row-Lock), '
  'geloest ueber slot_release(). Append-only im Geiste: released_at statt '
  'delete, damit die Belegungshistorie nachvollziehbar bleibt.';

-- Die zweite Verteidigungslinie der Kapazitaets-Garantie (Header oben):
-- ein Lead haelt nie mehr als eine aktive Zuweisung — auch nicht an
-- slot_assign() vorbei.
create unique index if not exists slot_assignments_active_lead_unique
  on slot_assignments (lead_id) where released_at is null;

-- Traegt das Zaehlen der Auslastung (RPC wie Frontend-Liste).
create index if not exists slot_assignments_active_slot_idx
  on slot_assignments (slot_id) where released_at is null;

alter table slot_assignments enable row level security;

revoke all on table slot_assignments from anon;

create policy "slot_assignments_coach_admin_all" on slot_assignments
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- ============================================================================
-- 4. slot_assign — das Tor mit der Kapazitaets-Garantie
-- ============================================================================

create or replace function public.slot_assign(
  p_slot_id uuid,
  p_lead_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_slot   slots;
  v_belegt integer;
  v_id     uuid;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'slot_assign: nur Coach oder Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'slot_assign: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- DER LOCK (Header „Kapazitaets-Garantie"): sperrt die Slot-Zeile fuer die
  -- Dauer der Transaktion. Erst DANACH wird gezaehlt — eine zweite gleichzeitige
  -- Zuweisung in denselben Slot wartet hier und sieht den Stand nach uns.
  select * into v_slot from slots where id = p_slot_id for update;
  if not found then
    raise exception 'slot_assign: Slot nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_slot.active then
    raise exception 'slot_assign: Slot ist deaktiviert' using errcode = 'P0001';
  end if;

  -- Bestehende aktive Zuweisung des Leads loesen — ein Kind sitzt in genau
  -- einer Gruppe. Das laeuft VOR dem Zaehlen, damit ein Wechsel innerhalb
  -- desselben Slots (Re-Assign) sich nicht selbst als Ueberbuchung sieht.
  update slot_assignments
     set released_at = now()
   where lead_id = p_lead_id
     and released_at is null;

  select count(*)::int into v_belegt
    from slot_assignments
   where slot_id = p_slot_id
     and released_at is null;

  if v_belegt >= v_slot.capacity then
    raise exception 'slot_assign: Slot ist ausgebucht (%/%)',
      v_belegt, v_slot.capacity using errcode = 'P0001';
  end if;

  insert into slot_assignments (slot_id, lead_id, created_by)
  values (p_slot_id, p_lead_id, auth.uid())
  returning id into v_id;

  -- belegt inkl. der gerade angelegten Zeile — das Frontend zeigt den Stand
  -- unmittelbar an, ohne nachzuladen.
  return jsonb_build_object(
    'ok',            true,
    'assignment_id', v_id,
    'belegt',        v_belegt + 1,
    'capacity',      v_slot.capacity
  );
end;
$$;

comment on function public.slot_assign(uuid, uuid) is
  'Feste Zuweisung Lead → Slot. Nur coach/admin. Sperrt die slots-Zeile (for '
  'update) und zaehlt erst danach — das ist die Kapazitaets-Garantie gegen '
  'Doppelbuchung. Loest eine bestehende aktive Zuweisung des Leads. Fehler: '
  'P0002 (Lead/Slot unbekannt), P0001 (Slot deaktiviert oder ausgebucht). '
  'Rueckgabe {ok, assignment_id, belegt, capacity}.';

-- ============================================================================
-- 5. slot_release — Freigabe (idempotent)
-- ============================================================================

create or replace function public.slot_release(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'slot_release: nur Coach oder Admin' using errcode = '42501';
  end if;

  update slot_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from slot_assignments where id = p_assignment_id
  ) then
    raise exception 'slot_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  -- Muster wie platz_release (S9).
  return jsonb_build_object(
    'ok',            true,
    'assignment_id', p_assignment_id,
    'released',      v_count = 1
  );
end;
$$;

comment on function public.slot_release(uuid) is
  'Loest eine Slot-Zuweisung (released_at setzen, kein delete). Nur '
  'coach/admin. Idempotent bei bereits geloesten Zeilen; P0002 wenn die '
  'Zuweisung nicht existiert. Rueckgabe {ok, assignment_id, released}.';

-- ============================================================================
-- 6. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
--    erst wegnehmen, dann gezielt geben; analog P01 §7 / a02 / S7 / S9)
-- ============================================================================

revoke execute on function public.slot_assign(uuid, uuid) from public;
revoke execute on function public.slot_release(uuid)      from public;

grant execute on function public.slot_assign(uuid, uuid) to authenticated, service_role;
grant execute on function public.slot_release(uuid)      to authenticated, service_role;

commit;
