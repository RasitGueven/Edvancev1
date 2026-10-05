// Eine geoeffnete Aufgabe in der Pruefansicht: laden, Bearbeitung halten, gesammelt speichern
// (entprellt ~600 ms, vor jeder Entscheidung und bei Pause), Version weiterfuehren, ED409 melden
// (Entscheidung 33). Die Zeit laeuft vom Oeffnen bis zur Entscheidung (37).

import { useCallback, useEffect, useRef, useState } from 'react'
import { ausgangAus, bearbeitungAus, zuEntwurf, type Bearbeitung } from '@/lib/pruefung/entwurf'
import { getPruefAufgabe, pruefSpeichern } from '@/lib/supabase/pruefung'
import type { PruefAufgabe, PruefAuffaelligkeit, PruefFehlerInfo } from '@/types'

const ENTPRELLEN_MS = 600

export type Sitzung = {
  aufgabe: PruefAufgabe | null
  laedt: boolean
  ladeFehler: PruefFehlerInfo | null
  b: Bearbeitung | null
  ausgang: Bearbeitung | null
  version: number
  auffaelligkeiten: PruefAuffaelligkeit[]
  speichert: boolean
  konflikt: boolean
  fehler: PruefFehlerInfo | null
  aendern: (b: Bearbeitung) => void
  /** Wartet, bis alles gespeichert ist. false = Speichern ging schief (Konflikt oder Fehler). */
  sichern: () => Promise<boolean>
  neuLaden: () => void
  setVersion: (v: number) => void
  /** Die zuletzt bekannte Version (auch direkt nach sichern(), vor dem naechsten Render). */
  versionJetzt: () => number
  dauerSek: () => number
}

export function usePruefSitzung(taskId: string | undefined): Sitzung {
  const [aufgabe, setAufgabe] = useState<PruefAufgabe | null>(null)
  const [laedt, setLaedt] = useState(true)
  const [ladeFehler, setLadeFehler] = useState<PruefFehlerInfo | null>(null)
  const [b, setB] = useState<Bearbeitung | null>(null)
  const [ausgang, setAusgang] = useState<Bearbeitung | null>(null)
  const [auffaelligkeiten, setAuffaelligkeiten] = useState<PruefAuffaelligkeit[]>([])
  const [speichert, setSpeichert] = useState(false)
  const [konflikt, setKonflikt] = useState(false)
  const [fehler, setFehler] = useState<PruefFehlerInfo | null>(null)
  const [version, setVersionState] = useState(0)

  const versionRef = useRef(0)
  const offen = useRef<Bearbeitung | null>(null)
  const laeuft = useRef<Promise<boolean> | null>(null)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const start = useRef(Date.now())
  const [ladeZaehler, setLadeZaehler] = useState(0)

  const setVersion = useCallback((v: number) => {
    versionRef.current = v
    setVersionState(v)
  }, [])

  useEffect(() => {
    if (!taskId) return
    let aktiv = true
    setLaedt(true)
    setKonflikt(false)
    setFehler(null)
    offen.current = null
    void getPruefAufgabe(taskId).then((res) => {
      if (!aktiv) return
      setLaedt(false)
      if (res.error || !res.data) {
        setLadeFehler(res.error)
        setAufgabe(null)
        return
      }
      setLadeFehler(null)
      setAufgabe(res.data)
      setB(bearbeitungAus({ ...res.data, skill_key: res.data.fertigkeit?.key ?? null }))
      setAusgang(ausgangAus(res.data))
      setAuffaelligkeiten(res.data.auffaelligkeiten)
      setVersion(res.data.aufgabe.pruef_version)
      start.current = Date.now()
    })
    return () => {
      aktiv = false
    }
  }, [taskId, ladeZaehler, setVersion])

  const schreiben = useCallback(async (): Promise<boolean> => {
    if (!taskId) return false
    while (offen.current) {
      const stand = offen.current
      offen.current = null
      setSpeichert(true)
      const res = await pruefSpeichern(taskId, versionRef.current, zuEntwurf(stand))
      setSpeichert(false)
      if (res.error || !res.data) {
        if (res.error?.code === 'ED409') setKonflikt(true)
        setFehler(res.error)
        return false
      }
      setFehler(null)
      setVersion(res.data.pruef_version)
      setAuffaelligkeiten(res.data.auffaelligkeiten)
      // Einordnung geaendert: Thema, Klasse und "Baut auf" der neuen Fertigkeit nachladen.
      if (stand.skill_key !== aufgabe?.fertigkeit?.key) {
        const neu = await getPruefAufgabe(taskId)
        if (neu.data) {
          const fertigkeit = neu.data.fertigkeit
          setAufgabe((a) => (a ? { ...a, fertigkeit } : a))
          setVersion(neu.data.aufgabe.pruef_version)
        }
      }
    }
    return true
  }, [taskId, aufgabe?.fertigkeit?.key, setVersion])

  const sichern = useCallback(async (): Promise<boolean> => {
    if (timer.current) clearTimeout(timer.current)
    timer.current = null
    if (laeuft.current) await laeuft.current
    if (!offen.current) return !konflikt
    laeuft.current = schreiben()
    const ok = await laeuft.current
    laeuft.current = null
    return ok
  }, [schreiben, konflikt])

  const aendern = useCallback((neu: Bearbeitung) => {
    setB(neu)
    offen.current = neu
    if (timer.current) clearTimeout(timer.current)
    timer.current = setTimeout(() => void sichern(), ENTPRELLEN_MS)
  }, [sichern])

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current)
  }, [])

  return {
    aufgabe, laedt, ladeFehler, b, ausgang, version, auffaelligkeiten, speichert, konflikt, fehler,
    aendern, sichern, setVersion,
    versionJetzt: () => versionRef.current,
    neuLaden: () => setLadeZaehler((n) => n + 1),
    dauerSek: () => Math.max(1, Math.round((Date.now() - start.current) / 1000)),
  }
}
