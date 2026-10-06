import { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import type { Zaehlerwerte } from '@/components/edvance/shell/navTypes'
import { useAuth } from '@/hooks/useAuth'
import { amSelbenBerlinerTag } from '@/lib/coachKennzahlen'
import { getPruefBoard } from '@/lib/supabase/pruefung'
import { listSessionsForCoach } from '@/lib/supabase/sessions'

/**
 * Zähler der Coach-Leiste: eigene Sessions am heutigen Berliner Tag und — nur
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
      darfPruefen ? getPruefBoard() : Promise.resolve(null),
    ]).then(([sessions, board]) => {
      if (!aktiv) return
      setWerte({
        heute: sessions.data?.filter((s) => amSelbenBerlinerTag(s.scheduled_at, jetztIso)).length,
        pruefen: board?.data?.filter((z) => z.lena_status === 'offen').length,
      })
    })
    return () => {
      aktiv = false
    }
  }, [pathname, userId, darfPruefen])

  return werte
}
