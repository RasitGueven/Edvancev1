// Station 03 · Lernweg — Maß, Fahrt und Bedienung der waagrechten Bühne
// (R7-9, Entscheidungen 20, 22–24). Referenz: Prototyp Version 7 (fahrt,
// zeichne, zeigeBis, gleite, unterbrechen).
//
// Je Bild nur Refs (scrollLeft, style.setProperty, Attribute); setState nur,
// wenn eine Schwelle überschritten wird (Zone oder Insel sichtbar).

import { useCallback, useEffect, useLayoutEffect, useRef, useState, type RefObject } from 'react'

import { messeLernweg } from '@/components/edvance/elternbericht/LernwegLinien'
import { fuehreLinien, type LinienPfad } from '@/lib/report/elternbericht/lernwegLinien'
import { fahrtDauer, fahrtStand, type FahrtGeometrie } from '@/lib/report/praesentation/lernwegFahrt'
import type { Lernweg } from '@/types'

import { useLinienZeichnen } from './useLinienZeichnen'

/** Entwurfshöhe der Spur (Prototyp). */
export const ENTWURF_HOEHE = 510
const S_MIN = 0.55
const S_MAX = 1.35
/** Zonen erscheinen so viele Entwurfs-px vor der Spitze, Inseln so viele. */
const VOR_ZONE = 30
const VOR_INSEL = 20
/** Maus: ab hier ist es Ziehen; ab hier rastet die nächste Zone ein. */
const ZIEHEN_AB = 5
const WECHSEL_AB = 60

const ruhig = (): boolean =>
  typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches

export type Fahrt = {
  scrollerRef: RefObject<HTMLDivElement>
  aussenRef: RefObject<HTMLDivElement>
  spurRef: RefObject<HTMLDivElement>
  pfade: LinienPfad[]
  /** Rastpunkte in px der Fläche (Anfang jeder Zone und der Spalte der nächsten Klasse). */
  rast: number[]
  /** null = alles sichtbar. */
  sicht: Set<string> | null
  hier: boolean
  zone: number
  frei: boolean
  zieht: boolean
  pfadRef: (key: string, art: 'linie' | 'spitze') => (el: SVGPathElement | null) => void
  abspielen: () => void
  unterbrechen: () => void
  /** Nach einem Ziehen kein Antippen. */
  unterdrueckt: () => boolean
  handler: {
    onScroll: () => void
    onWheel: (e: React.WheelEvent) => void
    onPointerDown: (e: React.PointerEvent) => void
    onPointerMove: (e: React.PointerEvent) => void
    onPointerUp: () => void
    onTouchStart: () => void
  }
}

export function useLernwegFahrt(lw: Lernweg): Fahrt {
  const scrollerRef = useRef<HTMLDivElement>(null)
  const aussenRef = useRef<HTMLDivElement>(null)
  const spurRef = useRef<HTMLDivElement>(null)
  const [pfade, setPfade] = useState<LinienPfad[]>([])
  const [rast, setRast] = useState<number[]>([0])
  const [sicht, setSicht] = useState<Set<string> | null>(null)
  const [hier, setHier] = useState(true)
  const [zone, setZone] = useState(0)
  const [frei, setFrei] = useState(false)
  const [zieht, setZieht] = useState(false)
  const [gemessen, setGemessen] = useState(false)

  const s = useRef(1)
  const lagen = useRef<{ id: string; x: number }[]>([])
  const kommtX = useRef(Infinity)
  const raf = useRef<number | null>(null)
  const lauf = useRef<{ t0: number; g: FahrtGeometrie } | null>(null)
  const zug = useRef<{ x: number; links: number; start: number; bewegt: boolean; dx: number } | null>(null)
  const sperre = useRef(false)

  /* ─── Maß ─────────────────────────────────────────────────────────────── */

  const messen = useCallback((): void => {
    const scroller = scrollerRef.current
    const spur = spurRef.current
    const aussen = aussenRef.current
    if (!scroller || !spur || !aussen) return
    const hoehe = Math.max(ENTWURF_HOEHE, spur.offsetHeight)
    const neu = Math.max(S_MIN, Math.min(S_MAX, (scroller.clientHeight - 6) / hoehe))
    s.current = neu
    spur.style.setProperty('--tp-s3-s', String(neu))
    aussen.style.setProperty('--tp-s3-breite', `${spur.offsetWidth * neu}px`)
    aussen.style.setProperty('--tp-s3-hoehe', `${hoehe * neu}px`)
    // Trefferfläche der Einträge: körperlich mindestens 44 px (CLAUDE.md §11).
    spur.style.setProperty('--tp-s3-treffer', `${Math.max(0, 22 / neu - 15, 22 - 15 * neu)}px`)

    const breite = spur.offsetWidth
    const m = messeLernweg(spur, lw.linien, breite)
    const rel = (el: Element): number => ((el.getBoundingClientRect().left - spur.getBoundingClientRect().left) * breite) / (spur.getBoundingClientRect().width || 1)
    lagen.current = [
      ...[...spur.querySelectorAll('[data-zone]')].map((el) => ({ id: `z:${el.getAttribute('data-zone')}`, x: rel(el) - VOR_ZONE })),
      ...[...spur.querySelectorAll('[data-insel]')].map((el) => ({ id: el.getAttribute('data-insel')!, x: rel(el) - VOR_INSEL })),
    ]
    const kommt = spur.querySelector('[data-zone="kommt"]')
    kommtX.current = kommt ? rel(kommt) : Infinity
    const punkte = [...spur.querySelectorAll('[data-rast]')].map((el) => Math.round(rel(el) * neu))
    setRast((alt) => (alt.join() === punkte.join() ? alt : punkte))
    const p = m.inseln.length ? fuehreLinien(m) : []
    setPfade((alt) => (alt.map((x) => x.d).join() === p.map((x) => x.d).join() ? alt : p))
    setGemessen(true)
  }, [lw])

  useLayoutEffect(() => {
    messen()
    void document.fonts?.ready.then(messen)
    const ro = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(messen)
    if (scrollerRef.current) ro?.observe(scrollerRef.current)
    return () => ro?.disconnect()
  }, [messen])

  /* ─── Zeichnen ────────────────────────────────────────────────────────── */

  const { pfadRef, zeichne } = useLinienZeichnen()

  const zeigeBis = useCallback((x: number): void => {
    if (x === Infinity) {
      setSicht(null)
      setHier(true)
      return
    }
    setSicht((alt) => {
      const neu = new Set(alt ?? [])
      let geaendert = alt === null
      for (const l of lagen.current) {
        if (x >= l.x && !neu.has(l.id)) {
          neu.add(l.id)
          geaendert = true
        }
      }
      return geaendert ? neu : alt
    })
    setHier((alt) => alt || x >= kommtX.current)
  }, [])

  /* ─── Fahrt ───────────────────────────────────────────────────────────── */

  const stopp = useCallback((): void => {
    if (raf.current !== null) cancelAnimationFrame(raf.current)
    raf.current = null
  }, [])

  const alles = useCallback((): void => {
    zeichne(Infinity)
    zeigeBis(Infinity)
  }, [zeichne, zeigeBis])

  const unterbrechen = useCallback((): void => {
    if (!lauf.current) return
    lauf.current = null
    stopp()
    alles()
    setFrei(false)
    scrollerRef.current?.removeAttribute('data-spitze')
  }, [stopp, alles])

  const starten = useCallback((): void => {
    const scroller = scrollerRef.current
    if (!scroller) return
    stopp()
    const xs = pfade.map((p) => p.punkte[0].x)
    const enden = pfade.map((p) => p.punkte[p.punkte.length - 1].x)
    const g: FahrtGeometrie = {
      start: xs.length ? Math.min(...xs) : null,
      ende: enden.length ? Math.max(...enden) : null,
      s: s.current,
      breite: scroller.clientWidth,
      max: scroller.scrollWidth - scroller.clientWidth,
    }
    lauf.current = { t0: performance.now(), g }
    setFrei(true)
    setSicht(new Set())
    setHier(false)
    scroller.scrollLeft = 0
    zeichne(g.start ?? -Infinity)
    const ende = fahrtDauer(g)
    const schritt = (jetzt: number): void => {
      const l = lauf.current
      const el = scrollerRef.current
      if (!l || !el) return
      const t = jetzt - l.t0
      const st = fahrtStand(t, l.g)
      el.scrollLeft = st.scrollLeft
      if (st.spitze !== null) el.setAttribute('data-spitze', String(st.spitze * l.g.s - st.scrollLeft))
      zeichne(st.phase === 'warten' || st.phase === 'schieben' ? (st.spitze ?? -Infinity) : Infinity)
      zeigeBis(st.aufgedeckt)
      el.setAttribute('data-phase', st.phase)
      if (t >= ende) {
        lauf.current = null
        raf.current = null
        setFrei(false)
        el.removeAttribute('data-spitze')
        return
      }
      raf.current = requestAnimationFrame(schritt)
    }
    raf.current = requestAnimationFrame(schritt)
  }, [pfade, stopp, zeichne, zeigeBis])

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
      setSicht(new Set())
      setHier(false)
      zeichne(-Infinity)
    }
    pruefen()
    const mo = new MutationObserver(pruefen)
    mo.observe(section, { attributes: true, attributeFilter: ['class'] })
    return () => mo.disconnect()
    // Erst nach dem Messen starten, damit die Spitze ihre Lage kennt.
  }, [gemessen, starten, unterbrechen, alles, zeichne])

  useEffect(() => stopp, [stopp])

  const abspielen = useCallback((): void => {
    lauf.current = null
    starten()
  }, [starten])

  /* ─── Bedienung ───────────────────────────────────────────────────────── */

  const punktLinks = useCallback((): number => {
    const el = scrollerRef.current
    if (!el) return 0
    let n = 0
    rast.forEach((x, i) => {
      if (x <= el.scrollLeft + 12) n = i
    })
    return n
  }, [rast])

  const gleite = useCallback(
    (i: number, dauer = 700): void => {
      const el = scrollerRef.current
      if (!el) return
      const ziel = Math.min(el.scrollWidth - el.clientWidth, rast[Math.max(0, Math.min(rast.length - 1, i))] ?? 0)
      stopp()
      setFrei(true)
      if (ruhig()) {
        el.scrollLeft = ziel
        setFrei(false)
        return
      }
      const von = el.scrollLeft
      const t0 = performance.now()
      const schritt = (jetzt: number): void => {
        const t = Math.min(1, (jetzt - t0) / dauer)
        el.scrollLeft = von + (ziel - von) * (1 - (1 - t) ** 3)
        if (t < 1) raf.current = requestAnimationFrame(schritt)
        else {
          raf.current = null
          setFrei(false)
        }
      }
      raf.current = requestAnimationFrame(schritt)
    },
    [rast, stopp],
  )

  // ← → wechseln die Zone, solange Station 03 aktuell ist (im Bild).
  useEffect(() => {
    const section = scrollerRef.current?.closest('.tp-station')
    if (!section || typeof IntersectionObserver === 'undefined') return
    let aktiv = false
    const io = new IntersectionObserver(([e]) => (aktiv = e.intersectionRatio >= 0.56), { threshold: [0, 0.56, 1] })
    io.observe(section)
    const taste = (e: KeyboardEvent): void => {
      if (!aktiv || (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight')) return
      e.preventDefault()
      unterbrechen()
      gleite(punktLinks() + (e.key === 'ArrowRight' ? 1 : -1))
    }
    document.addEventListener('keydown', taste)
    return () => {
      io.disconnect()
      document.removeEventListener('keydown', taste)
    }
  }, [gleite, punktLinks, unterbrechen])

  const handler: Fahrt['handler'] = {
    onScroll: () => {
      const el = scrollerRef.current
      if (!el) return
      // Der Balken unten zeigt den sichtbaren Ausschnitt (Variablen am gemeinsamen Elternteil).
      const breite = el.scrollWidth || 1
      el.parentElement?.style.setProperty('--tp-s3-balken-links', String(el.scrollLeft / breite))
      el.parentElement?.style.setProperty('--tp-s3-balken-breite', String(Math.min(1, el.clientWidth / breite)))
      const n = punktLinks()
      setZone((alt) => (alt === n ? alt : n))
    },
    onWheel: (e) => {
      // Waagrecht beendet die Fahrt; senkrecht bleibt beim Fluss der Stationen.
      if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) unterbrechen()
    },
    onTouchStart: () => unterbrechen(),
    onPointerDown: (e) => {
      unterbrechen()
      if (e.pointerType !== 'mouse' || !scrollerRef.current) return
      zug.current = { x: e.clientX, links: scrollerRef.current.scrollLeft, start: punktLinks(), bewegt: false, dx: 0 }
    },
    onPointerMove: (e) => {
      const z = zug.current
      const el = scrollerRef.current
      if (!z || !el) return
      const dx = e.clientX - z.x
      if (!z.bewegt && Math.abs(dx) > ZIEHEN_AB) {
        z.bewegt = true
        setZieht(true)
        setFrei(true)
      }
      if (z.bewegt) {
        z.dx = dx
        el.scrollLeft = z.links - dx
      }
    },
    onPointerUp: () => {
      const z = zug.current
      zug.current = null
      if (!z?.bewegt) return
      sperre.current = true
      window.setTimeout(() => (sperre.current = false), 0)
      setZieht(false)
      if (z.dx < -WECHSEL_AB) gleite(z.start + 1)
      else if (z.dx > WECHSEL_AB) gleite(z.links > (rast[z.start] ?? 0) + 4 ? z.start : z.start - 1)
      else gleite(z.start)
    },
  }

  return {
    scrollerRef,
    aussenRef,
    spurRef,
    pfade,
    rast,
    sicht,
    hier,
    zone,
    frei,
    zieht,
    pfadRef,
    abspielen,
    unterbrechen,
    unterdrueckt: () => sperre.current,
    handler,
  }
}
