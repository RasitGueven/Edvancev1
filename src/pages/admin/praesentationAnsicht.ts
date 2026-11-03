import { useCallback } from 'react'
import type { SetURLSearchParams } from 'react-router-dom'

import { vollbildStarten } from '@/components/edvance/praesentation/useBuehnenZoom'

/**
 * Präsentation an und aus über ?ansicht=praesentation. Beim Öffnen per Klick
 * startet zugleich das Vollbild (TP-L1, Entscheidung 4): im Klick-Handler
 * selbst, sonst fehlt die Nutzergeste. Ohne Vollbild-Möglichkeit oder als
 * Web-App vom Home-Bildschirm passiert dabei nichts weiter.
 */
export function usePraesentationAnsicht(setSuche: SetURLSearchParams): {
  oeffne: () => void
  schliesse: () => void
} {
  const setze = useCallback(
    (an: boolean) =>
      setSuche((alt) => {
        const neu = new URLSearchParams(alt)
        if (an) neu.set('ansicht', 'praesentation')
        else neu.delete('ansicht')
        return neu
      }),
    [setSuche],
  )
  const oeffne = useCallback(() => {
    vollbildStarten()
    setze(true)
  }, [setze])
  const schliesse = useCallback(() => setze(false), [setze])
  return { oeffne, schliesse }
}
