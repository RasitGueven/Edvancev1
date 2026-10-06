import { createContext, useContext } from 'react'
import type { CoachLiveKind, CoachLiveRaum } from '@/types/coachLive'
import type { SupabaseResult } from '@/types/ui'

export type LiveKontextWert = {
  sessionId: string
  raum: CoachLiveRaum
  /** Fuehrt eine Aktion der Datenquelle aus, laedt neu und meldet Erfolg oder Fehler. */
  ausfuehren: (aktion: Promise<SupabaseResult<unknown>>, erfolg?: string) => Promise<boolean>
  oeffneKind: (id: string) => void
  kind: (id: string) => CoachLiveKind
}

export const LiveKontext = createContext<LiveKontextWert | null>(null)

export function useLive(): LiveKontextWert {
  const wert = useContext(LiveKontext)
  if (!wert) throw new Error('useLive outside LiveKontext')
  return wert
}
