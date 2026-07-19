// Slot-System (S10): Frontend-Wrapper um Zeitraster, Favoriten und Zuweisung.
//
// Die Kapazitaetsgrenze (max. capacity aktive Zuweisungen je Slot) liegt in der
// DB — slot_assign() sperrt die Slot-Zeile und verweigert bei Ueberbuchung. Das
// Frontend zeigt die Auslastung nur an; es entscheidet sie nicht.

import { supabase } from '@/lib/supabase/client'
import type {
  Slot,
  SlotAssignment,
  SlotInput,
  SlotWish,
  SlotWithLoad,
  SupabaseResult,
} from '@/types'

// Alle Slots inkl. Auslastung. Die Zaehlung laeuft ueber die aktiven
// Zuweisungen (released_at is null) — beide Tabellen sind per RLS lesbar.
export async function listSlotsWithLoad(
  opts: { onlyActive?: boolean } = {},
): Promise<SupabaseResult<SlotWithLoad[]>> {
  try {
    let slotQuery = supabase
      .from('slots')
      .select('*')
      .order('weekday')
      .order('start_time')
      .order('room')
    if (opts.onlyActive) slotQuery = slotQuery.eq('active', true)

    const [slotRes, assignRes] = await Promise.all([
      slotQuery,
      supabase.from('slot_assignments').select('slot_id').is('released_at', null),
    ])
    if (slotRes.error) return { data: null, error: slotRes.error.message }
    if (assignRes.error) return { data: null, error: assignRes.error.message }

    const belegtBySlot = new Map<string, number>()
    for (const row of assignRes.data ?? []) {
      const id = row.slot_id as string
      belegtBySlot.set(id, (belegtBySlot.get(id) ?? 0) + 1)
    }

    const slots = (slotRes.data ?? []).map((slot) => ({
      ...(slot as Slot),
      belegt: belegtBySlot.get((slot as Slot).id) ?? 0,
    }))
    return { data: slots, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Slots konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function createSlot(input: SlotInput): Promise<SupabaseResult<Slot>> {
  try {
    const { data, error } = await supabase
      .from('slots')
      .insert({
        weekday: input.weekday,
        start_time: input.start_time,
        room: input.room,
        capacity: input.capacity ?? 5,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Slot, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Slot konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

// Deaktivieren statt loeschen — bestehende Zuweisungen bleiben nachvollziehbar.
export async function setSlotActive(
  id: string,
  active: boolean,
): Promise<SupabaseResult<Slot>> {
  try {
    const { data, error } = await supabase
      .from('slots')
      .update({ active })
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Slot, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Slot konnte nicht geaendert werden'
    return { data: null, error: message }
  }
}

export async function listWishesForLead(
  leadId: string,
): Promise<SupabaseResult<SlotWish[]>> {
  try {
    const { data, error } = await supabase
      .from('slot_wishes')
      .select('*')
      .eq('lead_id', leadId)
      .order('rang')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SlotWish[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Favoriten konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Favoriten sind als Ganzes gedacht: die Liste im Gespraech wird komplett neu
// gesetzt (loeschen + einfuegen), damit Raenge nie luecken- oder doppelt sind.
export async function setWishesForLead(
  leadId: string,
  slotIds: string[],
): Promise<SupabaseResult<SlotWish[]>> {
  try {
    const { error: delError } = await supabase
      .from('slot_wishes')
      .delete()
      .eq('lead_id', leadId)
    if (delError) return { data: null, error: delError.message }

    if (slotIds.length === 0) return { data: [], error: null }

    const rows = slotIds.slice(0, 3).map((slotId, index) => ({
      lead_id: leadId,
      slot_id: slotId,
      rang: index + 1,
    }))
    const { data, error } = await supabase.from('slot_wishes').insert(rows).select('*')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SlotWish[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Favoriten konnten nicht gespeichert werden'
    return { data: null, error: message }
  }
}

// Aktive Zuweisung eines Leads — die Auswahl-Ansicht zeigt sie als Status.
export async function getActiveAssignment(
  leadId: string,
): Promise<SupabaseResult<SlotAssignment | null>> {
  try {
    const { data, error } = await supabase
      .from('slot_assignments')
      .select('*')
      .eq('lead_id', leadId)
      .is('released_at', null)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as SlotAssignment | null) ?? null, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Zuweisung konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Feste Zuweisung. Die RPC verweigert bei ausgebuchtem Slot (P0001) — die
// Fehlermeldung der DB wird unveraendert durchgereicht.
export async function assignSlot(
  slotId: string,
  leadId: string,
): Promise<SupabaseResult<{ assignment_id: string; belegt: number; capacity: number }>> {
  try {
    const { data, error } = await supabase.rpc('slot_assign', {
      p_slot_id: slotId,
      p_lead_id: leadId,
    })
    if (error) return { data: null, error: error.message }
    return {
      data: data as { assignment_id: string; belegt: number; capacity: number },
      error: null,
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Zuweisung fehlgeschlagen'
    return { data: null, error: message }
  }
}

export async function releaseSlot(
  assignmentId: string,
): Promise<SupabaseResult<{ assignment_id: string }>> {
  try {
    const { data, error } = await supabase.rpc('slot_release', {
      p_assignment_id: assignmentId,
    })
    if (error) return { data: null, error: error.message }
    return { data: data as { assignment_id: string }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Zuweisung konnte nicht geloest werden'
    return { data: null, error: message }
  }
}
