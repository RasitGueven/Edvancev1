-- Slots um Laufzeit und Klassenstufen erweitern.
--
-- Der Slot ist das Zeitraster einer wiederkehrenden Praesenz-Session:
-- Wochentag, Uhrzeit, Raum, Kapazitaet. Er traegt bewusst KEIN Fach und
-- KEINEN Coach. In einer Kleingruppe arbeitet jeder Schueler an seinem
-- eigenen Pfad; Fachgleichheit ist kein Kriterium. Das Fach steht am Lead
-- (leads.subjects), der Coach am Einzeltermin.
--
-- Neu:
--   valid_from       ab wann der Slot im Kalender gilt
--   valid_until      bis wann; null = laeuft weiter
--   class_level_min  optionale Eingrenzung der Klassenstufe (5..13)
--   class_level_max
--
-- Slots werden nicht umgeschrieben: aendert sich etwas dauerhaft, wird der
-- alte Slot mit valid_until beendet und ein neuer angelegt. Sonst faelscht
-- eine Aenderung rueckwirkend die Historie, und die traegt den Eltern-Report.
--
-- Wochentagskonvention bleibt 0 = Montag bis 6 = Sonntag
-- (siehe src/types/slots.ts, CHECK slots_weekday_check).
-- Zeitzone ist fest Europe/Berlin.

alter table public.slots
  add column if not exists valid_from      date not null default current_date,
  add column if not exists valid_until     date,
  add column if not exists class_level_min smallint,
  add column if not exists class_level_max smallint;

alter table public.slots
  drop constraint if exists slots_laufzeit_check,
  add  constraint slots_laufzeit_check
    check (valid_until is null or valid_until >= valid_from);

alter table public.slots
  drop constraint if exists slots_klassenstufe_check,
  add  constraint slots_klassenstufe_check
    check (class_level_max is null or class_level_min is null
           or class_level_max >= class_level_min);

-- Wertebereich wie an skill_clusters (CHECK 5..13), damit dieselbe
-- Klassenstufe ueberall dasselbe bedeutet.
alter table public.slots
  drop constraint if exists slots_class_level_min_check,
  add  constraint slots_class_level_min_check
    check (class_level_min is null
           or (class_level_min >= 5 and class_level_min <= 13));

alter table public.slots
  drop constraint if exists slots_class_level_max_check,
  add  constraint slots_class_level_max_check
    check (class_level_max is null
           or (class_level_max >= 5 and class_level_max <= 13));

comment on column public.slots.valid_from is
  'Ab wann der Slot im Kalender gilt.';
comment on column public.slots.valid_until is
  'Bis wann der Slot gilt; null = laeuft weiter. Slots werden beendet, nicht umgeschrieben.';
