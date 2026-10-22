// Station 03 · Lernweg — Maß und Fahrt der waagrechten Bühne (R7-9,
// Entscheidungen 20 und 24; Nachbesserung, Entscheidungen 1, 2, 4 und 5).
// Referenz: Prototyp Version 7 (fahrt, zeichne, zeigeBis, unterbrechen).
//
// Je Bild nur Refs (scrollLeft, style.setProperty, Attribute, Klassen); kein
// setState während der Fahrt (PF-1, Entscheidung 3). Was sichtbar ist, regelt
// useLernwegSicht: Inseln und Zonen erscheinen, sobald die Kamera sie zeigt.

import { useCallback, useEffect, useLayoutEffect, useRef, useState, type RefObject } from 'react'

import { messeLernweg } from '@/components/edvance/elternbericht/LernwegLinien'
import { fuehreLinien, type LinienPfad } from '@/lib/report/elternbericht/lernwegLinien'
import { fahrtDauer, fahrtStand, sichtGrenze, type FahrtGeometrie } from '@/lib/report/praesentation/lernwegFahrt'
import { packeSpalten } from '@/lib/report/praesentation/lernwegSpalten'
import type { Lernweg } from '@/types'

import { ruhig, useLernwegBedienung, type Bedienung } from './useLernwegBedienung'
import { useLernwegSicht } from './useLernwegSicht'
import { useLinienZeichnen } from './useLinienZeichnen'

/** Feste Entwurfshöhe der Spur (Prototyp); höher nur für eine Insel, die allein nicht passt. */
export const ENTWURF_HOEHE = 510
/** Lesbarkeit hat Vorrang: kleiner wird die Spur nie (Nachbesserung, Entscheidung 1). */
export const S_MIN = 0.85
const S_MAX = 1.35
/** Lücke zwischen zwei Inseln einer Spalte (station3-weg.css). */
const INSEL_LUECKE = 16

/** Je Gruppe (Zone, „kommt-jahr“, „kommt-naechste“) die Spalten als Indizes ihrer Inseln. */
export type Packungen = Record<string, number[][]>

export type Fahrt = Bedienung & {
  scrollerRef: RefObject<HTMLDivElement>
  aussenRef: RefObject<HTMLDivElement>
  spurRef: RefObject<HTMLDivElement>
  pfade: LinienPfad[]
  packungen: Packungen | null
  /** Rastpunkte in px der Fläche (Anfang jeder Zone und der Spalte der nächsten Klasse). */
  rast: number[]
  /** null = alles sichtbar. */
  sicht: Set<string> | null
  hier: boolean
  hierRef: RefObject<HTMLParagraphElement>
  frei: boolean
  pfadRef: (key: string, art: 'linie' | 'spitze') => (el: SVGPathElement | null) => void
  abspielen: () => void
  unterbrechen: () => void
}

/** Layout-x eines Elements in der Spur (ohne Transforms, ohne Skala). */
function xIn(el: Element, spur: HTMLElement): number {
  let x = 0
  for (let e = el as HTMLElement | null; e && e !== spur; e = e.offsetParent as HTMLElement | null) x += e.offsetLeft
  return x
}

export function useLernwegFahrt(lw: Lernweg): Fahrt {
  const scrollerRef = useRef<HTMLDivElement>(null)
  const aussenRef = useRef<HTMLDivElement>(null)
  const spurRef = useRef<HTMLDivElement>(null)
  const [pfade, setPfade] = useState<LinienPfad[]>([])
  const [packungen, setPackungen] = useState<Packungen | null>(null)
  const [rast, setRast] = useState<number[]>([0])
  const [frei, setFrei] = useState(false)
  const [gemessen, setGemessen] = useState(false)

  const s = useRef(1)
  /** Sichtbare Breite und größtes scrollLeft, beim Messen gemerkt: je Bild kein Lesen des Layouts. */
  const mass = useRef({ breite: 0, max: 0 })
  const raf = useRef<number | null>(null)
  const lauf = useRef<{ t0: number } | null>(null)
  const groesse = useRef('')
  const { pfadRef, abgleichen, zeichne, bereich, front } = useLinienZeichnen()
  const sichtbar = useLernwegSicht()

  /* ─── Fahrt: Stopp und Abbruch ────────────────────────────────────────── */

  const stopp = useCallback((): void => {
    if (raf.current !== null) cancelAnimationFrame(raf.current)
    raf.current = null
  }, [])

  const { leer, bis, alles: allesSichtbar, erfassen } = sichtbar
  const alles = useCallback((): void => {
    zeichne(Infinity)
    allesSichtbar()
  }, [zeichne, allesSichtbar])

  // Die Ansicht bleibt, wo sie ist: Einrasten bleibt aus, bis wieder jemand
  // selbst schiebt (Wischen, Rad, Ziehen, Pfeiltaste).
  const unterbrechen = useCallback((): void => {
    if (!lauf.current) return
    lauf.current = null
    stopp()
    alles()
    scrollerRef.current?.removeAttribute('data-spitze')
    scrollerRef.current?.setAttribute('data-phase', 'unterbrochen')
  }, [stopp, alles])

  /* ─── Maß ─────────────────────────────────────────────────────────────── */

  const messen = useCallback((): void => {
    const scroller = scrollerRef.current
    const spur = spurRef.current
    const aussen = aussenRef.current
    if (!scroller || !spur || !aussen) return
    // Ändert sich die Größe während der Fahrt (Drehung), steht alles fertig da.
    const neueGroesse = `${scroller.clientWidth}x${scroller.clientHeight}`
    if (lauf.current && groesse.current && groesse.current !== neueGroesse) unterbrechen()
    groesse.current = neueGroesse

    // Spalten: je Gruppe so viele, dass die Spur ihre Entwurfshöhe behält. Der
    // Platz zählt bei 510 — ist die Spur für eine zu hohe Insel schon höher,
    // ginge die Ausnahme sonst bei der nächsten Messung wieder verloren.
    const zusatz = Math.max(0, spur.offsetHeight - ENTWURF_HOEHE)
    const neu: Packungen = {}
    let ueber = 0
    for (const gruppe of spur.querySelectorAll<HTMLElement>('[data-gruppe]')) {
      const inseln = [...gruppe.querySelectorAll<HTMLElement>('[data-insel]')].sort(
        (a, b) => Number(a.dataset.index) - Number(b.dataset.index),
      )
      const platz = gruppe.clientHeight - zusatz
      const p = packeSpalten(inseln.map((i) => i.offsetHeight), platz, INSEL_LUECKE)
      if (p.zuHoch) ueber = Math.max(ueber, Math.max(...inseln.map((i) => i.offsetHeight)) - platz)
      neu[gruppe.dataset.gruppe!] = p.spalten
    }
    const hoehe = ENTWURF_HOEHE + ueber
    spur.style.setProperty('--tp-s3-entwurf', `${hoehe}px`)
    setPackungen((alt) => (JSON.stringify(alt) === JSON.stringify(neu) ? alt : neu))

    const skala = Math.max(S_MIN, Math.min(S_MAX, (scroller.clientHeight - 6) / hoehe))
    s.current = skala
    spur.style.setProperty('--tp-s3-s', String(skala))
    aussen.style.setProperty('--tp-s3-breite', `${spur.offsetWidth * skala}px`)
    aussen.style.setProperty('--tp-s3-hoehe', `${hoehe * skala}px`)
    // Trefferfläche der Einträge: körperlich mindestens 44 px (CLAUDE.md §11), mit
    // Spielraum gegen Rundung (Knopf ≥ 28 Entwurfs-px angenommen, +1 px).
    spur.style.setProperty('--tp-s3-treffer', `${Math.max(0, 22 / skala - 14, 22 - 14 * skala) + 1}px`)

    const kommt = spur.querySelector('[data-zone="kommt"]')
    erfassen(
      [...spur.querySelectorAll<HTMLElement>('[data-zone], [data-insel]')].map((el) => ({ el, x: xIn(el, spur) })),
      kommt ? xIn(kommt, spur) : Infinity,
    )
    const punkte = [...spur.querySelectorAll('[data-rast]')].map((el) => Math.round(xIn(el, spur) * skala))
    setRast((alt) => (alt.join() === punkte.join() ? alt : punkte))
    // Abstand 9: der Gang zwischen Zonenkopf und Inseln (22 px) hat die Linie mittig.
    const m = { ...messeLernweg(spur, lw.linien, spur.offsetWidth, 'layout'), abstand: 9 }
    const p = m.inseln.length ? fuehreLinien(m) : []
    setPfade((alt) => (alt.map((x) => x.d).join() === p.map((x) => x.d).join() ? alt : p))
    mass.current = { breite: scroller.clientWidth, max: scroller.scrollWidth - scroller.clientWidth }
    setGemessen(true)
  }, [lw, unterbrechen, erfassen])

  useLayoutEffect(() => {
    messen()
    void document.fonts?.ready.then(messen)
    const ro = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(messen)
    if (scrollerRef.current) ro?.observe(scrollerRef.current)
    return () => ro?.disconnect()
  }, [messen, packungen])

  // Neue d (nach dem Messen) neu vermessen; sonst bleiben die Tabellen.
  useLayoutEffect(abgleichen, [pfade, abgleichen])

  /* ─── Fahrt ───────────────────────────────────────────────────────────── */

  /** Die Geometrie je Bild aus dem Gemessenen: Ein spätes Messen (Schriften) gilt sofort. */
  const geometrie = useCallback((): FahrtGeometrie | null => {
    if (!scrollerRef.current) return null
    const b = bereich()
    return {
      start: b?.start ?? null,
      ende: b?.ende ?? null,
      front: front(),
      s: s.current,
      ...mass.current,
    }
  }, [bereich, front])

  const starten = useCallback((): void => {
    const scroller = scrollerRef.current
    const g0 = geometrie()
    if (!scroller || !g0) return
    stopp()
    lauf.current = { t0: performance.now() }
    setFrei(true)
    leer()
    scroller.scrollLeft = 0
    zeichne(g0.start ?? -Infinity)
    const schritt = (jetzt: number): void => {
      const l = lauf.current
      const el = scrollerRef.current
      const g = geometrie()
      if (!l || !el || !g) return
      const t = jetzt - l.t0
      const st = fahrtStand(t, g)
      el.scrollLeft = st.scrollLeft
      if (st.front !== null) el.setAttribute('data-spitze', String(st.front * g.s - st.scrollLeft))
      zeichne(st.phase === 'warten' || st.phase === 'schieben' ? (st.spitze ?? -Infinity) : Infinity)
      // Kästen vor Linie: alles, was die Kamera zeigt; „Sie sind hier“ mit der Front.
      bis(st.aufgedeckt === Infinity ? Infinity : Math.max(st.aufgedeckt, sichtGrenze(st.scrollLeft, g)), st.aufgedeckt)
      if (el.getAttribute('data-phase') !== st.phase) el.setAttribute('data-phase', st.phase)
      if (t >= fahrtDauer(g)) {
        lauf.current = null
        raf.current = null
        setFrei(false)
        el.removeAttribute('data-spitze')
        return
      }
      raf.current = requestAnimationFrame(schritt)
    }
    raf.current = requestAnimationFrame(schritt)
  }, [geometrie, stopp, zeichne, leer, bis])

  // Wann die Fahrt läuft: beim ersten Betreten (Klasse entered), nicht bei
  // motion-complete und nicht bei reduzierter Bewegung (dann fertiger Weg).
  const gestartet = useRef(false)
  useEffect(() => {
    const section = scrollerRef.current?.closest('.tp-station')
    const fertig = (): void => {
      alles()
      setFrei(false)
    }
    if (!section || ruhig() || section.classList.contains('motion-complete')) {
      fertig()
      return
    }
    const pruefen = (): void => {
      if (section.classList.contains('motion-complete')) {
        if (lauf.current) unterbrechen()
        else fertig()
      } else if (section.classList.contains('entered') && !gestartet.current && gemessen) {
        gestartet.current = true
        starten()
      }
    }
    // Vor dem ersten Betreten: nur, was links der Spitze liegt.
    if (!section.classList.contains('entered')) {
      leer()
      zeichne(-Infinity)
    }
    pruefen()
    const mo = new MutationObserver(pruefen)
    mo.observe(section, { attributes: true, attributeFilter: ['class'] })
    return () => mo.disconnect()
    // Erst nach dem Messen starten, damit die Spitze ihre Lage kennt.
  }, [gemessen, starten, unterbrechen, alles, leer, zeichne])

  useEffect(() => stopp, [stopp])

  const abspielen = useCallback((): void => {
    lauf.current = null
    starten()
  }, [starten])

  const bedienung = useLernwegBedienung({ scrollerRef, rast, unterbrechen, setFrei })

  return {
    ...bedienung,
    scrollerRef,
    aussenRef,
    spurRef,
    pfade,
    packungen,
    rast,
    sicht: sichtbar.sicht,
    hier: sichtbar.hier,
    hierRef: sichtbar.hierRef,
    frei,
    pfadRef,
    abspielen,
    unterbrechen,
  }
}
