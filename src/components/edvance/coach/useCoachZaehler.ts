import { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import type { Zaehlerwerte } from '@/components/edvance/shell/navTypes'
import { useAuth } from '@/hooks/useAuth'
import { dieseWoche } from '@/components/edvance/wochenNavigation.model'
import { amSelbenBerlinerTag } from '@/lib/coachKennzahlen'
import { getPruefBoard } from '@/lib/supabase/pruefung'
import { listSessionsForCoach } from '@/lib/supabase/sessions'
import { ladeMeineEinsaetze } from '@/lib/supabase/slotplan'
import { heuteEintraege } from '@/pages/coach/einsaetze/einsaetze.model'

/**
 * Zähler der Coach-Leiste: eigene Sessions und Einsätze aus dem Plan am heutigen
 * Berliner Tag (jede Session-ID einmal, Slots SL3) und — nur
 * mit Prüfrecht — Aufgaben, die für Lena noch offen sind. Lädt bei jedem
 * Seitenwechsel neu wie die Admin-Leiste; ein Fehler lässt den Zähler weg.
 */
export function useCoachZaehler(darfPruefen: boolean): Zaehlerwerte {
  const { pathname } = useLocation()
  const { user } = useAuth()
  const userId = user?.id
  const [werte, setWerte] = useState<Zaehlerwerte>({})

  useEffect(() => {
    if (!userId) return
    let aktiv = true
    const jetztIso = new Date().toISOString()
    void Promise.all([
      listSessionsForCoach(userId),
      ladeMeineEinsaetze(dieseWoche()),
      darfPruefen ? getPruefBoard() : Promise.resolve(null),
    ]).then(([sessions, einsaetze, board]) => {
      if (!aktiv) return
      const heute = sessions.data?.filter((s) => amSelbenBerlinerTag(s.scheduled_at, jetztIso))
      setWerte({
        heute: heute && heuteEintraege(einsaetze.data?.einsaetze ?? [], heute).length,
        pruefen: board?.data?.filter((z) => z.lena_status === 'offen').length,
      })
    })
    return () => {
      aktiv = false
    }
  }, [pathname, userId, darfPruefen])

  return werte
}
