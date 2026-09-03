-- slots.active abschaffen: die Laufzeit ist die einzige Wahrheit.
--
-- Bisher trug slots.active die Aussage "gilt" und der Unique-Index
-- slots_active_coord_unique haengte daran. Mit valid_from/valid_until aus
-- 20260903120000 gab es die Aussage zweimal: einen Slot beenden hiess
-- valid_until setzen UND active auf false. Zwei Spalten, dieselbe
-- Information, garantierte Drift.
--
-- Ab hier gilt: ein Slot ist aktiv, solange valid_until null ist. Der
-- Unique-Index auf Wochentag/Uhrzeit/Raum greift nur fuer laufende Slots --
-- damit laesst sich ein Slot beenden und mit denselben Koordinaten neu
-- anlegen, was das Modell aus 20260903120000 voraussetzt.
--
-- Der Index bleibt ein partieller Unique-Index und keine Exclusion-Constraint
-- ueber daterange: bei einem Standort und wenigen Slots reicht "hoechstens ein
-- laufender Slot pro Koordinate". Ueberlappende Laufzeiten in der
-- Vergangenheit sind damit moeglich, aber ohne praktische Folge.
--
-- Die Tabelle ist leer, deshalb ist der drop column folgenlos.

drop index if exists public.slots_active_coord_unique;

alter table public.slots drop column if exists active;

create unique index if not exists slots_laufend_coord_unique
  on public.slots (weekday, start_time, room)
  where valid_until is null;

comment on index public.slots_laufend_coord_unique is
  'Hoechstens ein laufender Slot pro Wochentag/Uhrzeit/Raum. Laufend = valid_until is null.';
