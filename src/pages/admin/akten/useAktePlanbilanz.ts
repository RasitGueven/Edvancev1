import { useEffect, useState } from 'react'
import { ladeKind } from '@/lib/supabase/slotplan'
import type { Planbilanz } from '@/types/slotplan'

export type AktePlanbilanz = { pb: Planbilanz; vertragLaeuft: boolean }

/**
 * Planbilanz aus slots_kind für die Einheiten-Kachel (Slots SL3), nur für Admins — ein Coach ruft
 * slots_kind gar nicht erst auf (Anforderung I 54). Ohne Vertrag, bei Testkonten oder im Fehlerfall
 * bleibt sie null; die Kachel zeigt dann einfach kein Abzeichen.
 */
export function useAktePlanbilanz(studentId: string, istAdmin: boolean): AktePlanbilanz | null {
  const [wert, setWert] = useState<AktePlanbilanz | null>(null)

  useEffect(() => {
    setWert(null)
    if (!istAdmin || !studentId) return undefined
    let aktiv = true
    void ladeKind(studentId).then((res) => {
      if (!aktiv || res.error !== null || !res.data?.planbilanz) return
      setWert({ pb: res.data.planbilanz, vertragLaeuft: res.data.vertrag_laeuft === true })
    })
    return () => {
      aktiv = false
    }
  }, [studentId, istAdmin])

  return wert
}
