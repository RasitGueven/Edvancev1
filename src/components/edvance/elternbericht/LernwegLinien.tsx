import { useLayoutEffect, useRef, useState } from 'react'

import { fuehreLinien, type LinienEingabe, type LinienPfad, type Rechteck } from '@/lib/report/elternbericht/lernwegLinien'
import type { LwLinie } from '@/types'

/** Der Bereich des Lernwegs ist so breit wie der Inhalt der Seite (507 pt). */
const BREITE = 507
/** Abstand einer Linie zu den Inseln, in pt: passt in den Gang zwischen zwei Inseln (11 pt). */
const ABSTAND = 4

type Bild = { hoehe: number; pfade: LinienPfad[] }

/**
 * Die Lage aller Inseln, Einträge und Spalten im Bereich, in pt. Gemessen wie
 * Kurve.tsx: Verhältnis zur Breite des Bereichs, deshalb skalenfest (R7-7).
 */
export function messeLernweg(bereich: HTMLElement, linien: readonly LwLinie[], breite: number): LinienEingabe & { hoehe: number } {
  const r = bereich.getBoundingClientRect()
  const pt = breite / (r.width || 1)
  const rel = (el: Element): Rechteck => {
    const q = el.getBoundingClientRect()
    return { x: (q.left - r.left) * pt, y: (q.top - r.top) * pt, b: q.width * pt, h: q.height * pt }
  }
  const spaltenEl = [...bereich.querySelectorAll('[data-spalte]')]
  const spalten = spaltenEl.map((s) => {
    const q = rel(s.querySelector('[data-inseln]') ?? s)
    return { x0: q.x, x1: q.x + q.b }
  })
  const inseln = [...bereich.querySelectorAll<HTMLElement>('[data-insel]')].map((el) => ({
    id: el.dataset.insel!,
    spalte: spaltenEl.findIndex((s) => s.contains(el)),
    rect: rel(el),
  }))
  const eintraege = [...bereich.querySelectorAll<HTMLElement>('[data-eintrag]')].map((el) => ({
    id: el.dataset.eintrag!,
    insel: el.closest<HTMLElement>('[data-insel]')?.dataset.insel ?? '',
    // Angesetzt wird auf Höhe der ersten Zeile (Punkt bzw. ↳), nicht der Mitte.
    rect: rel(el.querySelector(':scope > [data-anker], :scope > .eb-s3-zeile > [data-anker], [data-anker]') ?? el),
  }))
  const kopf = Math.max(0, ...[...bereich.querySelectorAll('[data-kopf]')].map((k) => rel(k).y + rel(k).h))
  const hoehe = r.height * pt
  return { spalten, inseln, eintraege, linien, oben: kopf + 2, unten: hoehe - 2, hoehe, abstand: ABSTAND }
}

const gleich = (a: Bild | null, b: Bild): boolean =>
  a !== null && a.hoehe === b.hoehe && a.pfade.map((p) => p.d).join() === b.pfade.map((p) => p.d).join()

/**
 * Seite 3 · die goldenen Linien über der Fläche (Entscheidung 16): ein SVG,
 * aria-hidden, nach dem Layout gemessen (auch nach dem Laden der Schriften und
 * bei jeder Größenänderung), geführt nach lernwegLinien.ts.
 */
export function LernwegLinien({ linien }: { linien: readonly LwLinie[] }): JSX.Element {
  const svg = useRef<SVGSVGElement>(null)
  const [bild, setBild] = useState<Bild | null>(null)

  useLayoutEffect(() => {
    const bereich = svg.current?.parentElement
    if (!bereich) return
    let aktiv = true
    const messen = (): void => {
      if (!aktiv) return
      const m = messeLernweg(bereich, linien, BREITE)
      // Höhe auf ¼ pt, damit kleine Schwankungen nicht neu zeichnen.
      const neu = { hoehe: Math.round(m.hoehe * 4) / 4, pfade: m.inseln.length ? fuehreLinien(m) : [] }
      setBild((alt) => (gleich(alt, neu) ? alt : neu))
    }
    messen()
    void document.fonts?.ready.then(messen)
    const beobachter = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(messen)
    beobachter?.observe(bereich)
    return () => {
      aktiv = false
      beobachter?.disconnect()
    }
  }, [linien])

  return (
    <svg
      ref={svg}
      className="eb-s3-linien"
      viewBox={`0 0 ${BREITE} ${bild?.hoehe ?? 1}`}
      preserveAspectRatio="none"
      aria-hidden="true"
      focusable="false"
      data-testid="eb-s3-linien"
    >
      {bild?.pfade.map((p) => (
        <g key={`${p.von}-${p.zu}`} data-linie={`${p.von}-${p.zu}`}>
          <path className="eb-s3-linie" d={p.d} />
          <path className="eb-s3-spitze" d={p.spitzeD} />
        </g>
      ))}
    </svg>
  )
}
