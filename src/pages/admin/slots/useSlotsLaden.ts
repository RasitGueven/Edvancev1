import { useCallback, useEffect, useState } from 'react'
import type { SlotsResult } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'

export type Geladen<T> = {
  daten: T | null
  laedt: boolean
  /** i18n-Schlüssel im Namespace slots (fehler.*), nie Rohtext der Datenbank. */
  fehler: string | null
  neuLaden: () => void
}

/**
 * Lädt eine Slots-Lesefunktion, solange `schluessel` gleich bleibt, und verwirft veraltete Antworten.
 * Beim Neuladen bleiben die alten Daten stehen (kein Flackern nach dem Speichern).
 */
export function useSlotsLaden<T>(laden: () => Promise<SlotsResult<T>>, schluessel: string): Geladen<T> {
  const [daten, setDaten] = useState<T | null>(null)
  const [laedt, setLaedt] = useState(true)
  const [fehler, setFehler] = useState<string | null>(null)
  const [runde, setRunde] = useState(0)

  useEffect(() => {
    let aktiv = true
    setLaedt(true)
    void laden().then((res) => {
      if (!aktiv) return
      if (res.error !== null) {
        setFehler(slotsFehlerSchluessel(res))
      } else {
        setFehler(null)
        setDaten(res.data)
      }
      setLaedt(false)
    })
    return () => {
      aktiv = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- `laden` wechselt je Render; maßgeblich ist `schluessel`.
  }, [schluessel, runde])

  const neuLaden = useCallback(() => setRunde((r) => r + 1), [])
  return { daten, laedt, fehler, neuLaden }
}
