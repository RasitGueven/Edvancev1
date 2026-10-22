// Station 03 · Lernweg — Bedienung der waagrechten Bühne (R7-9, Entscheidungen
// 22 und 23; Nachbesserung, Entscheidung 5): Ziehen mit der Maus (mit
// Pointer-Capture), Rastpunkte, Pfeiltasten, Zone und Balken unten. Touch und
// Trackpad scrollen nativ mit scroll-snap; das Mausrad senkrecht bleibt beim
// Fluss der Stationen.

import { useCallback, useEffect, useRef, useState, type RefObject } from 'react'

/** Maus: ab hier ist es Ziehen; ab hier rastet die nächste Zone ein. */
const ZIEHEN_AB = 5
const WECHSEL_AB = 60

export const ruhig = (): boolean =>
  typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches

export type Bedienung = {
  zone: number
  zieht: boolean
  unterdrueckt: () => boolean
  handler: {
    onScroll: () => void
    onWheel: (e: React.WheelEvent) => void
    onPointerDown: (e: React.PointerEvent) => void
    onPointerMove: (e: React.PointerEvent) => void
    onPointerUp: (e: React.PointerEvent) => void
    onPointerCancel: (e: React.PointerEvent) => void
    onTouchStart: () => void
  }
}

export function useLernwegBedienung({
  scrollerRef,
  rast,
  unterbrechen,
  setFrei,
}: {
  scrollerRef: RefObject<HTMLDivElement>
  rast: number[]
  unterbrechen: () => void
  setFrei: (frei: boolean) => void
}): Bedienung {
  const [zone, setZone] = useState(0)
  const [zieht, setZieht] = useState(false)
  const raf = useRef<number | null>(null)
  const zug = useRef<{ x: number; links: number; start: number; bewegt: boolean; dx: number } | null>(null)
  const sperre = useRef(false)

  const punktLinks = useCallback((): number => {
    const el = scrollerRef.current
    if (!el) return 0
    let n = 0
    rast.forEach((x, i) => {
      if (x <= el.scrollLeft + 12) n = i
    })
    return n
  }, [rast, scrollerRef])

  const gleite = useCallback(
    (i: number, dauer = 700): void => {
      const el = scrollerRef.current
      if (!el) return
      const ziel = Math.min(el.scrollWidth - el.clientWidth, rast[Math.max(0, Math.min(rast.length - 1, i))] ?? 0)
      if (raf.current !== null) cancelAnimationFrame(raf.current)
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
    [rast, scrollerRef, setFrei],
  )

  useEffect(() => () => {
    if (raf.current !== null) cancelAnimationFrame(raf.current)
  }, [])

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
  }, [gleite, punktLinks, unterbrechen, scrollerRef])

  const loslassen = (e: React.PointerEvent): void => {
    const z = zug.current
    zug.current = null
    if (scrollerRef.current?.hasPointerCapture?.(e.pointerId)) scrollerRef.current.releasePointerCapture(e.pointerId)
    if (!z?.bewegt) return
    sperre.current = true
    window.setTimeout(() => (sperre.current = false), 0)
    setZieht(false)
    if (z.dx < -WECHSEL_AB) gleite(z.start + 1)
    else if (z.dx > WECHSEL_AB) gleite(z.links > (rast[z.start] ?? 0) + 4 ? z.start : z.start - 1)
    else gleite(z.start)
  }

  return {
    zone,
    zieht,
    unterdrueckt: () => sperre.current,
    handler: {
      onScroll: () => {
        const el = scrollerRef.current
        if (!el) return
        // Der Balken unten zeigt den sichtbaren Ausschnitt. Erst lesen, dann schreiben,
        // und die Variablen nur am Balken: am gemeinsamen Elternteil erbten sie alle
        // Inseln, und jedes Bild der Fahrt rechnete die Stile der ganzen Bühne neu (PF-1).
        const breite = el.scrollWidth || 1
        const links = el.scrollLeft / breite
        const sichtbar = Math.min(1, el.clientWidth / breite)
        const n = punktLinks()
        const balken = el.parentElement?.querySelector<HTMLElement>('.tp-s3-balken')
        balken?.style.setProperty('--tp-s3-balken-links', String(links))
        balken?.style.setProperty('--tp-s3-balken-breite', String(sichtbar))
        setZone((alt) => (alt === n ? alt : n))
      },
      onWheel: (e) => {
        // Waagrecht beendet die Fahrt und schiebt selbst (dann wieder mit Einrasten);
        // senkrecht bleibt beim Fluss der Stationen.
        if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) {
          unterbrechen()
          setFrei(false)
        }
      },
      onTouchStart: () => {
        unterbrechen()
        setFrei(false)
      },
      onPointerDown: (e) => {
        unterbrechen()
        const el = scrollerRef.current
        if (e.pointerType !== 'mouse' || !el) return
        zug.current = { x: e.clientX, links: el.scrollLeft, start: punktLinks(), bewegt: false, dx: 0 }
      },
      onPointerMove: (e) => {
        const z = zug.current
        const el = scrollerRef.current
        if (!z || !el) return
        const dx = e.clientX - z.x
        if (!z.bewegt && Math.abs(dx) > ZIEHEN_AB) {
          z.bewegt = true
          // Erst beim Ziehen fangen: ein Tippen bleibt ein Klick auf den Eintrag.
          el.setPointerCapture?.(e.pointerId)
          setZieht(true)
          setFrei(true)
        }
        if (z.bewegt) {
          z.dx = dx
          el.scrollLeft = z.links - dx
        }
      },
      onPointerUp: loslassen,
      onPointerCancel: loslassen,
    },
  }
}
