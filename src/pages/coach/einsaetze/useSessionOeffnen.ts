import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { terminSessionAnlegen } from '@/lib/supabase/slotplan'
import type { EinsatzVM } from './einsaetze.model'

/**
 * „Session öffnen“ (Entscheidung 14): schreibt den Raum-Termin fest (idempotent, nur am Tag) und führt
 * in die Live-Sicht. Der Fehler ist ein i18n-Schlüssel im Namespace slots, nie der Rohtext.
 */
export function useSessionOeffnen(): {
  oeffnen: (e: Pick<EinsatzVM, 'key' | 'datum' | 'zeit_id' | 'raum_id'>) => Promise<void>
  laeuft: string | null
  fehler: string | null
} {
  const navigate = useNavigate()
  const [laeuft, setLaeuft] = useState<string | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)

  const oeffnen = async (e: Pick<EinsatzVM, 'key' | 'datum' | 'zeit_id' | 'raum_id'>): Promise<void> => {
    setLaeuft(e.key)
    setFehler(null)
    const res = await terminSessionAnlegen(e.datum, e.zeit_id, e.raum_id)
    setLaeuft(null)
    if (res.error !== null || !res.data) {
      setFehler(slotsFehlerSchluessel(res))
      return
    }
    navigate(`/coach/session/${res.data.session_id}/live`)
  }

  return { oeffnen, laeuft, fehler }
}
