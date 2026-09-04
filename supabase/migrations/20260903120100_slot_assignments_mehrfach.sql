-- Ein Lead darf mehreren Slots zugeordnet sein.
--
-- Bisher verhinderte slot_assignments_active_lead_unique jede zweite
-- aktive Zuordnung. Das Angebot sind zwei Praesenz-Sessions pro Woche,
-- also braucht ein Lead mehr als einen Slot.
--
-- Die Obergrenze steht bewusst NICHT in der Datenbank: wie viele Sessions
-- ein Lead bekommt, ist ein Paketmerkmal und aendert sich. Die Oberflaeche
-- warnt, das Schema erlaubt.
--
-- Eindeutig bleibt die Kombination: derselbe Lead nicht zweimal aktiv im
-- selben Slot.

drop index if exists public.slot_assignments_active_lead_unique;

create unique index if not exists slot_assignments_active_lead_slot_unique
  on public.slot_assignments (lead_id, slot_id)
  where released_at is null;
