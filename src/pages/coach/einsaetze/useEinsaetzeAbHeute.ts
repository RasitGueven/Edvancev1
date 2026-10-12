import { useEffect, useState } from 'react'
import { dieseWoche, wocheVerschieben } from '@/components/edvance/wochenNavigation.model'
import { ladeMeineEinsaetze } from '@/lib/supabase/slotplan'
import type { MeinEinsatz } from '@/types/slotplan'

/**
 * Einsätze dieser und der nächsten Woche für „Heute“ beim Coach: die von heute mit „Session öffnen“
 * und der nächste Einsatz für die Kennzahl (auch freitags abends steht so der Montag da). Ein Fehler
 * lässt die Liste leer; die festgeschriebenen Sessions zeigt das Dashboard trotzdem.
 */
export function useEinsaetzeAbHeute(aktiv: boolean, schluessel = ''): MeinEinsatz[] {
  const [einsaetze, setEinsaetze] = useState<MeinEinsatz[]>([])

  useEffect(() => {
    if (!aktiv) return undefined
    let laeuft = true
    const montag = dieseWoche()
    void Promise.all([ladeMeineEinsaetze(montag), ladeMeineEinsaetze(wocheVerschieben(montag, 1))]).then(([diese, naechste]) => {
      if (!laeuft) return
      setEinsaetze([...(diese.data?.einsaetze ?? []), ...(naechste.data?.einsaetze ?? [])])
    })
    return () => {
      laeuft = false
    }
  }, [aktiv, schluessel])

  return einsaetze
}
