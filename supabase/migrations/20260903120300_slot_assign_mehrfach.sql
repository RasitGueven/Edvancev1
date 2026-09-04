-- slot_assign an das neue Slot-Modell anpassen.
--
-- Zwei Aenderungen aus 20260903120050 und 20260903120100 waren in dieser
-- Funktion noch nicht abgebildet:
--
-- 1. slots.active existiert nicht mehr. Ein Slot laeuft, solange valid_until
--    null ist. Die Pruefung wird auf die Laufzeit umgestellt und prueft dabei
--    auch valid_from -- ein Slot, der erst naechsten Monat beginnt, nimmt
--    heute keine Zuweisung an.
--
-- 2. Ein Lead darf mehreren Slots zugeordnet sein (zwei Praesenz-Sessions pro
--    Woche). Bisher loeste die Funktion beim Zuweisen JEDE aktive Zuordnung
--    des Leads -- der zweite Slot haette den ersten geraeumt. Geloest wird
--    jetzt nur noch eine bestehende Zuordnung im SELBEN Slot, damit ein
--    Re-Assign sich nicht selbst als Ueberbuchung zaehlt.
--
-- Kapazitaets-Lock, Rollenpruefung, Rueckgabeformat und Fehlercodes bleiben
-- unveraendert.

create or replace function public.slot_assign(p_slot_id uuid, p_lead_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  -- Der Lock: sperrt die Slot-Zeile fuer die Dauer der Transaktion. Erst
  -- danach wird gezaehlt, eine zweite gleichzeitige Zuweisung wartet hier.
  select * into v_slot from slots where id = p_slot_id for update;
  if not found then
    raise exception 'slot_assign: Slot nicht gefunden' using errcode = 'P0002';
  end if;

  if v_slot.valid_until is not null then
    raise exception 'slot_assign: Slot ist beendet' using errcode = 'P0001';
  end if;

  if v_slot.valid_from > current_date then
    raise exception 'slot_assign: Slot beginnt erst am %', v_slot.valid_from
      using errcode = 'P0001';
  end if;

  -- Nur eine bestehende Zuordnung im selben Slot loesen. Zuordnungen zu
  -- anderen Slots bleiben: ein Lead darf mehrere Sessions pro Woche haben.
  update slot_assignments
     set released_at = now()
   where lead_id = p_lead_id
     and slot_id = p_slot_id
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

  return jsonb_build_object(
    'ok',            true,
    'assignment_id', v_id,
    'belegt',        v_belegt + 1,
    'capacity',      v_slot.capacity
  );
end;
$function$;
