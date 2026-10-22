// Sollzahlen fuer Lenas Prueflauf (P4): laedt pruef_board_soll fuer die Anlaesse des Bereichs wie die Uebersicht,
// rechnet nach einer Entscheidung den Knoten sofort lokal nach und gleicht im Hintergrund mit der Datenbank ab.
// Fehlen die Zahlen (Fehler oder keine Zeilen), bleibt soll leer und der Lauf nimmt den alten Weg.
// MC-Nachtrag: ladeMc holt die Aufgabentypen des Boards; bei einem Fehler null, dann ohne MC-Regel.

import { useCallback, useEffect, useState } from 'react'
import { nachrechnen } from '@/lib/pruefung/lauf'
import { getAufgabenTypen, getPruefSoll } from '@/lib/supabase/pruefung'
import type { LenaStatus, PruefBoardZeile, PruefSollZeile } from '@/types'
import { ANLASS, sollDesBereichs, type Bereich } from './bereich'

/** Sollzeilen eines Bereichs; null, wenn ein Anlass nicht geantwortet hat (dann stimmten die Summen nicht). */
export async function ladeSoll(b: Bereich): Promise<PruefSollZeile[] | null> {
  const rs = await Promise.all(ANLASS[b].map((a) => getPruefSoll(a)))
  const kaputt = rs.find((r) => r.error)
  if (kaputt?.error) {
    console.warn('pruef_board_soll failed', ANLASS[b], kaputt.error.message)
    return null
  }
  return sollDesBereichs(rs.map((r) => r.data ?? []))
}

/** Die task_ids mit MC unter den Aufgaben des Boards; null, wenn die Typen nicht geladen werden konnten. */
export async function ladeMc(board: PruefBoardZeile[]): Promise<Set<string> | null> {
  const r = await getAufgabenTypen(board.map((z) => z.task_id))
  if (r.error || !r.data) {
    console.warn('task input_type failed, MC rule off', r.error?.message)
    return null
  }
  return new Set(Object.entries(r.data).filter(([, typ]) => typ === 'MC').map(([id]) => id))
}

export type PruefLauf = {
  soll: PruefSollZeile[] | null
  /** Rechnet den Knoten um und gibt die neuen Zeilen zurueck (fuer die Wahl der naechsten Aufgabe). */
  verbuche: (skillKey: string | null, vorher: LenaStatus, nachher: LenaStatus, mc: boolean) => PruefSollZeile[] | null
}

export function usePruefLauf(bereich: Bereich): PruefLauf {
  const [soll, setSoll] = useState<PruefSollZeile[] | null>(null)

  const abgleichen = useCallback(() => {
    void ladeSoll(bereich).then((s) => s && setSoll(s))
  }, [bereich])

  useEffect(() => {
    let aktiv = true
    setSoll(null)
    void ladeSoll(bereich).then((s) => aktiv && setSoll(s))
    return () => {
      aktiv = false
    }
  }, [bereich])

  const verbuche = useCallback((skillKey: string | null, vorher: LenaStatus, nachher: LenaStatus, mc: boolean) => {
    if (!soll) return null
    const neu = nachrechnen(soll, skillKey, vorher, nachher, mc)
    setSoll(neu)
    abgleichen()
    return neu
  }, [soll, abgleichen])

  return { soll, verbuche }
}
