// Durchgeklickte LSA (LSA-R2) — Lesezugriff, nur admin/coach.
//
// Quellen (Migration 20261022131037_lsa_durchklicken):
//   lsa_sessions.auswertbar / nicht_auswertbar_grund — gesetzt von lsa_finish
//                                                     (per RLS für admin/coach lesbar)
//   lsa_durchklick_stand (RPC)                       — Stand einer laufenden Sitzung
//
// Fehlt die Migration (Spalte oder Funktion unbekannt), gilt jede Sitzung als
// auswertbar und keine als schnell. So bricht das Frontend nicht, und Merge und
// Einspielen gehen in beliebiger Reihenfolge.

import { supabase } from '@/lib/supabase/client'
import type { DurchklickStand } from '@/types'

type Row = {
  id: string
  nicht_auswertbar_grund: DurchklickStand | null
}

/**
 * Die nicht auswertbaren Sitzungen mit ihrem Grund (Stand beim Abschluss).
 * Ohne `nur` alle — das sind wenige, deshalb kein langer id-Filter für die
 * Liste. Jede Sitzung, die fehlt, ist auswertbar.
 */
export async function loadNichtAuswertbar(
  nur?: string[],
): Promise<Map<string, DurchklickStand | null>> {
  const karte = new Map<string, DurchklickStand | null>()
  if (nur?.length === 0) return karte
  try {
    let abfrage = supabase
      .from('lsa_sessions')
      .select('id, nicht_auswertbar_grund')
      .eq('auswertbar', false)
    if (nur) abfrage = abfrage.in('id', nur)
    const { data, error } = await abfrage
    if (error) {
      console.warn('lsa: auswertbar lookup failed', error.message)
      return karte
    }
    for (const r of (data ?? []) as Row[]) karte.set(r.id, r.nicht_auswertbar_grund)
  } catch (e) {
    console.warn('lsa: auswertbar lookup failed', e)
  }
  return karte
}

/**
 * „schnell“ in Admin „Heute“: nicht auswertbar oder gerade so viele schnelle
 * Abgaben in Folge wie für den Hinweis an das Kind. Die Schwelle kommt aus der
 * Datenbank (schwellen.hinweis_folge), nicht von hier.
 */
export function istSchnell(stand: DurchklickStand): boolean {
  if (stand.nicht_auswertbar) return true
  const hinweis = stand.schwellen?.hinweis_folge
  return hinweis !== undefined && stand.folge_schnell_aktuell >= hinweis
}

/** Die laufenden Sitzungen, die gerade „schnell“ sind. Einmal je Aufruf, kein Polling. */
export async function loadSchnelleSitzungen(sessionIds: string[]): Promise<Set<string>> {
  const staende = await Promise.all(
    sessionIds.map(async (id) => {
      try {
        const { data, error } = await supabase.rpc('lsa_durchklick_stand', { p_session_id: id })
        if (error || !data) return { id, stand: null, fehler: error?.message ?? null }
        return { id, stand: data as DurchklickStand, fehler: null }
      } catch (e) {
        return { id, stand: null, fehler: e instanceof Error ? e.message : String(e) }
      }
    }),
  )
  const fehler = staende.find((s) => s.fehler)?.fehler
  if (fehler) console.warn('lsa: lsa_durchklick_stand failed', fehler)
  return new Set(staende.filter((s) => s.stand && istSchnell(s.stand)).map((s) => s.id))
}
