import { useEffect, useState } from 'react'
import { testkontenLaden } from '@/lib/session/coachLive'
import type { CoachLiveRaum } from '@/types/coachLive'

/**
 * F2 (Trockenlauf 10.10.): Testkonto je Kind fuer den Hinweis „kein Testlauf“. Geladen wird nur, wenn er
 * ueberhaupt in Frage kommt: Session kein Testlauf und ein Kind wartet ohne Ziel oder ohne Aufgabe.
 * Liefert undefined fuer Kinder, die (noch) nicht geladen sind.
 */
export function useRaumLiveTestkonten(raum: CoachLiveRaum | null): (kindId: string) => boolean | undefined {
  const [stand, setStand] = useState<Map<string, boolean>>(() => new Map())
  const bedarf = raum !== null && !raum.session.testlauf && raum.kinder.some((k) => k.wartet !== null)
  const ids = raum ? raum.kinder.map((k) => k.id).join(',') : ''

  useEffect(() => {
    if (!bedarf || ids === '') return
    let lebt = true
    void testkontenLaden(ids.split(',')).then((m) => {
      if (lebt) setStand(m)
    })
    return () => {
      lebt = false
    }
  }, [bedarf, ids])

  return (kindId) => stand.get(kindId)
}
