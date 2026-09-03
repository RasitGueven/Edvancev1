-- Serienbezug fuer coaching_sessions.
--
-- Die Terminebene existiert bereits vollstaendig: coaching_sessions ist der
-- Einzeltermin, session_students die Anwesenheit, interventions die
-- Coach-Notiz. Was fehlte, ist der Bezug zur Serie -- welcher Slot diesen
-- Termin erzeugt hat.
--
-- Damit gilt:
--   slots              Serie: Wochentag, Uhrzeit, Raum, Kapazitaet, Laufzeit
--   slot_assignments   Lead an der Serie
--   coaching_sessions  konkreter Termin, jetzt mit slot_id
--   session_students   Anwesenheit pro Termin und Schueler
--
-- Abweichungen brauchen keine eigene Tabelle: session_students.attendance
-- deckt 'absent' ab, und ein zusaetzlicher Schueler ist einfach eine weitere
-- Zeile in session_students -- auch ohne Zuordnung an der Serie.
--
-- slot_id ist nullable: Einzeltermine ohne Serie bleiben moeglich
-- (Nachholtermin, Probestunde).
--
-- Der Unique-Index verhindert zwei Termine derselben Serie am selben Tag und
-- macht die Materialisierung idempotent. Er rechnet mit "at time zone
-- Europe/Berlin", weil ein blanker ::date auf timestamptz nur STABLE und im
-- Index nicht erlaubt ist. Zeitzone ist fest Europe/Berlin.

alter table public.coaching_sessions
  add column if not exists slot_id uuid references public.slots(id) on delete set null;

create unique index if not exists coaching_sessions_slot_datum_unique
  on public.coaching_sessions (slot_id, ((scheduled_at at time zone 'Europe/Berlin')::date))
  where slot_id is not null;

create index if not exists coaching_sessions_slot_idx
  on public.coaching_sessions (slot_id)
  where slot_id is not null;

comment on column public.coaching_sessions.slot_id is
  'Serie, aus der dieser Termin stammt. Null = Einzeltermin ohne Serie.';
