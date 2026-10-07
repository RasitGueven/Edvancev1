import { useCallback, useEffect, useRef, useState } from 'react'
import { ladeRaumLive, LIVE_ABFRAGE_MS } from '@/lib/session/coachLive'
import type { CoachLiveRaum } from '@/types/coachLive'

/**
 * Coach-Live-Sicht: fragt die Datenquelle alle LIVE_ABFRAGE_MS ab (Entscheidung 17,
 * kein Realtime). `kindId` ist das Kind mit offener Schublade: nur dessen Detail wird
 * mitgeladen (C2). `neuLaden` holt sofort nach einer Aktion. `fehler` ist ein Fehler-Code
 * der Seite (coachLive:fehler.<code>).
 */
export function useRaumLive(sessionId: string | undefined, kindId: string | null = null): {
  raum: CoachLiveRaum | null
  fehler: string | null
  laedt: boolean
  neuLaden: () => Promise<void>
} {
  const [raum, setRaum] = useState<CoachLiveRaum | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [laedt, setLaedt] = useState(true)
  const aktiv = useRef(true)

  const neuLaden = useCallback(async () => {
    if (!sessionId) return
    const res = await ladeRaumLive(sessionId, kindId)
    if (!aktiv.current) return
    if (res.error !== null) setFehler(res.error)
    else {
      setFehler(null)
      setRaum(res.data)
    }
    setLaedt(false)
  }, [sessionId, kindId])

  useEffect(() => {
    aktiv.current = true
    void neuLaden()
    const id = setInterval(() => void neuLaden(), LIVE_ABFRAGE_MS)
    return () => {
      aktiv.current = false
      clearInterval(id)
    }
  }, [neuLaden])

  return { raum, fehler, laedt, neuLaden }
}
