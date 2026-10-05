import { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import type { Zaehlerwerte } from '@/components/edvance/shell/navTypes'
import { getAdminStats } from '@/lib/supabase/adminStats'
import { countAufgabenFuerAdmin } from '@/lib/supabase/heute'
import { listVertraege } from '@/lib/supabase/vertraege'

// Wie der Reiter "Offene Anträge" unter Verträge: alles vor der Unterschrift,
// abgelehnte nicht.
const OFFENER_ANTRAG = ['in_vorbereitung', 'unterschrift_ausstehend']

/**
 * Zähler der Admin-Leiste: neue Leads, offene Anträge, Aufgaben im Status
 * review oder rueckfrage (Lenas Rückfragen). Lädt bei jedem Seitenwechsel neu,
 * damit eine erledigte Aufgabe nicht bis zum Neuladen in der Leiste steht.
 * Ein Fehler lässt den Zähler weg.
 */
export function useAdminZaehler(): Zaehlerwerte {
  const { pathname } = useLocation()
  const [werte, setWerte] = useState<Zaehlerwerte>({})

  useEffect(() => {
    let aktiv = true
    void Promise.all([getAdminStats(), listVertraege(), countAufgabenFuerAdmin()]).then(([stats, vertraege, review]) => {
      if (!aktiv) return
      setWerte({
        leads: stats.data?.leadsNew,
        vertraege: vertraege.data?.filter((v) => OFFENER_ANTRAG.includes(v.status)).length,
        itemPflege: review.data ?? undefined,
      })
    })
    return () => {
      aktiv = false
    }
  }, [pathname])

  return werte
}
