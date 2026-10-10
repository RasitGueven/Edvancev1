import { useCallback, useEffect, useRef, useState } from 'react'
import { ladeRaumLive, LIVE_ABFRAGE_MS } from '@/lib/session/coachLive'
import type { CoachLiveRaum } from '@/types/coachLive'

/**
 * Coach-Live-Sicht: fragt die Datenquelle im Takt LIVE_ABFRAGE_MS ab (Entscheidung 17,
 * kein Realtime). `kindId` ist das Kind mit offener Schublade: nur dessen Detail wird
 * mitgeladen (C2). `neuLaden` holt sofort nach einer Aktion. `fehler` ist ein Fehler-Code
 * der Seite (coachLive:fehler.<code>).
 *
 * F1 (Trockenlauf 08.10., Befund A5): Die naechste Runde startet erst LIVE_ABFRAGE_MS nach dem
 * Ende der vorigen, nie ueberlappend. Jede Abfrage bekommt eine Nummer; kommt eine Antwort an,
 * nachdem eine neuere Abfrage gestartet wurde (z. B. `neuLaden` nach einer Aktion), wird sie
 * verworfen, damit eine aeltere Antwort nie eine neuere ueberschreibt.
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
  const letzte = useRef(0)

  const neuLaden = useCallback(async () => {
    if (!sessionId) return
    const nr = ++letzte.current
    const res = await ladeRaumLive(sessionId, kindId)
    if (nr !== letzte.current) return
    if (res.error !== null) setFehler(res.error)
    else {
      setFehler(null)
      setRaum(res.data)
    }
    setLaedt(false)
  }, [sessionId, kindId])

  useEffect(() => {
    // Je Effekt eine eigene Schleife: nach dem Aufraeumen (anderes Kind, Seite verlassen) plant sie nichts mehr.
    let lebt = true
    let uhr: ReturnType<typeof setTimeout> | undefined
    const runde = async (): Promise<void> => {
      try {
        await neuLaden()
      } finally {
        if (lebt) uhr = setTimeout(() => void runde(), LIVE_ABFRAGE_MS)
      }
    }
    void runde()
    return () => {
      lebt = false
      // Antworten, die noch unterwegs sind, gehoeren zum alten Stand.
      letzte.current += 1
      clearTimeout(uhr)
    }
  }, [neuLaden])

  return { raum, fehler, laedt, neuLaden }
}
