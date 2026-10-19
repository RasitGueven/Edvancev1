// Tablet-Präsentation — welche Station gerade zu sehen ist, und die Zustände
// der Bewegung (T2, Entscheidungen 5 und 6). Logik wie im Skript des Dummys V7
// (selectStage, measureStage, jumpTo, retireIntro), nur in React.
//
// Index 0 ist das Intro, 1 … 4 sind die Stationen. Die Indizes bleiben gleich,
// wenn das Intro den Fluss verlassen hat.

import { useCallback, useEffect, useLayoutEffect, useRef, useState, type RefObject } from 'react'

const ANZAHL = 4
/** So lange nach einem Sprung zählt das Scrollen nicht als Wechsel (Dummy: 750 ms). */
const SPERRE_MS = 750
/** Ruhe nach dem letzten Scroll-Ereignis, bevor das Intro gehen darf (Dummy: 280 ms). */
const RUHE_MS = 280
/** Ab diesem Anteil im Bild gilt eine Station als betreten (Dummy: 0,56). */
const BETRETEN_AB = 0.56

const ruhig = (): boolean =>
  typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches

const markiere = (liste: boolean[], i: number): boolean[] =>
  liste[i] ? liste : liste.map((v, k) => v || k === i)

export type Stationen = {
  /** 0 = Intro, 1 … 4 = Station. */
  aktuell: number
  /** Je Station: schon betreten (erster Besuch, Bewegung läuft). */
  betreten: boolean[]
  /** Je Station: einmal verlassen — danach still. */
  fertig: boolean[]
  /** Das Intro hat den Fluss verlassen (einmal je Öffnen). */
  introWeg: boolean
  springe: (station: number) => void
  flussRef: RefObject<HTMLDivElement>
  introRef: RefObject<HTMLElement>
  stationRef: (station: number) => (el: HTMLElement | null) => void
}

export function useStationen(): Stationen {
  const flussRef = useRef<HTMLDivElement>(null)
  const introRef = useRef<HTMLElement>(null)
  const stationen = useRef<(HTMLElement | null)[]>([])
  const refSetter = useRef<((el: HTMLElement | null) => void)[]>([])

  const [aktuell, setAktuell] = useState(0)
  const [betreten, setBetreten] = useState<boolean[]>(() => Array(ANZAHL).fill(false))
  const [fertig, setFertig] = useState<boolean[]>(() => Array(ANZAHL).fill(false))
  const [introWeg, setIntroWeg] = useState(false)

  const aktuellRef = useRef(0)
  const sperreBis = useRef(0)
  const introWegRef = useRef(false)
  const korrektur = useRef<number | null>(null)
  const ruheTimer = useRef<number>()

  const stationRef = useCallback((station: number) => {
    refSetter.current[station] ??= (el) => {
      stationen.current[station] = el
    }
    return refSetter.current[station]
  }, [])

  /** Elemente des Flusses mit ihrem Index; das Intro nur, solange es da ist. */
  const elemente = useCallback((): [number, HTMLElement][] => {
    const liste: [number, HTMLElement][] = []
    if (!introWegRef.current && introRef.current) liste.push([0, introRef.current])
    for (let s = 1; s <= ANZAHL; s++) {
      const el = stationen.current[s]
      if (el) liste.push([s, el])
    }
    return liste
  }, [])

  const waehle = useCallback((i: number) => {
    const vorher = aktuellRef.current
    if (i === vorher) return
    if (vorher > 0) setFertig((f) => markiere(f, vorher - 1))
    aktuellRef.current = i
    setAktuell(i)
  }, [])

  /** Die Station, deren Mitte der Mitte des Bildes am nächsten liegt. */
  const messe = useCallback((): number => {
    const fluss = flussRef.current
    if (!fluss) return aktuellRef.current
    const mitte = fluss.scrollTop + fluss.clientHeight * 0.5
    let naechste = aktuellRef.current
    let abstand = Infinity
    for (const [i, el] of elemente()) {
      const d = Math.abs(mitte - (el.offsetTop + el.offsetHeight / 2))
      if (d < abstand) {
        abstand = d
        naechste = i
      }
    }
    return naechste
  }, [elemente])

  // Das Intro verlässt den Fluss, ohne dass die Ansicht springt: dieselbe
  // Station bleibt oben, der Versatz um die Höhe des Intros wird ausgeglichen.
  const verabschiedeIntro = useCallback(() => {
    const intro = introRef.current
    const fluss = flussRef.current
    if (introWegRef.current || !intro || !fluss) return
    introWegRef.current = true
    korrektur.current = Math.max(0, fluss.scrollTop - intro.offsetHeight)
    setIntroWeg(true)
  }, [])

  useLayoutEffect(() => {
    const fluss = flussRef.current
    if (!introWeg || korrektur.current === null || !fluss) return
    fluss.scrollTo?.({ top: korrektur.current, behavior: 'instant' })
    korrektur.current = null
  }, [introWeg])

  const zurRuhe = useCallback(() => {
    window.clearTimeout(ruheTimer.current)
    const warte = sperreBis.current - performance.now()
    if (warte > 0) {
      ruheTimer.current = window.setTimeout(zurRuhe, warte + 40)
      return
    }
    if (aktuellRef.current >= 1) verabschiedeIntro()
  }, [verabschiedeIntro])

  const springe = useCallback(
    (station: number) => {
      const el = stationen.current[station]
      const fluss = flussRef.current
      if (!el || !fluss) return
      const weit = Math.abs(station - messe()) > 2
      sperreBis.current = performance.now() + SPERRE_MS
      waehle(station)
      fluss.scrollTo?.({ top: el.offsetTop, behavior: ruhig() || weit ? 'instant' : 'smooth' })
      setBetreten((b) => markiere(b, station - 1))
      window.clearTimeout(ruheTimer.current)
      ruheTimer.current = window.setTimeout(zurRuhe, RUHE_MS)
    },
    [messe, waehle, zurRuhe],
  )

  // Scrollen: aktuelle Station messen (außer während eines Sprungs) und nach
  // der Ruhe das Intro verabschieden.
  useEffect(() => {
    const fluss = flussRef.current
    if (!fluss) return
    let geplant = 0
    const beimScrollen = (): void => {
      if (!geplant) {
        geplant = requestAnimationFrame(() => {
          geplant = 0
          if (performance.now() > sperreBis.current) waehle(messe())
        })
      }
      window.clearTimeout(ruheTimer.current)
      ruheTimer.current = window.setTimeout(zurRuhe, RUHE_MS)
    }
    fluss.addEventListener('scroll', beimScrollen, { passive: true })
    return () => {
      fluss.removeEventListener('scroll', beimScrollen)
      cancelAnimationFrame(geplant)
      window.clearTimeout(ruheTimer.current)
    }
  }, [messe, waehle, zurRuhe])

  // Erster Besuch: ab 56 % im Bild gilt eine Station als betreten.
  useEffect(() => {
    const fluss = flussRef.current
    if (!fluss || typeof IntersectionObserver === 'undefined') return
    const beobachter = new IntersectionObserver(
      (eintraege) => {
        for (const e of eintraege) {
          if (!e.isIntersecting || e.intersectionRatio < BETRETEN_AB) continue
          const i = stationen.current.indexOf(e.target as HTMLElement)
          if (i >= 1) setBetreten((b) => markiere(b, i - 1))
        }
      },
      { root: fluss, threshold: [0, 0.18, 0.36, 0.56, 0.74] },
    )
    for (let s = 1; s <= ANZAHL; s++) {
      const el = stationen.current[s]
      if (el) beobachter.observe(el)
    }
    return () => beobachter.disconnect()
  }, [])

  return { aktuell, betreten, fertig, introWeg, springe, flussRef, introRef, stationRef }
}
