// Station 03 · Lernweg — die Linien wachsen mit der Spitze (R7-9, Entscheidung 24).
//
// Je Pfad eine Tabelle x → Länge aus getPointAtLength (alle 4 Entwurfs-px). Der
// Fortschritt folgt der x-Lage, nicht dem Längenanteil: Stücke, die sich decken
// (gemeinsamer Stamm), wachsen so gleich schnell. Die Spitze einer Linie
// erscheint erst, wenn die Linie fertig ist.

import { useCallback, useRef } from 'react'

type Tabelle = { el: SVGPathElement; laenge: number; punkte: { x: number; l: number }[] }

export function useLinienZeichnen(): {
  pfadRef: (key: string, art: 'linie' | 'spitze') => (el: SVGPathElement | null) => void
  zeichne: (x: number) => void
} {
  const tabellen = useRef(new Map<string, Tabelle>())
  const spitzen = useRef(new Map<string, SVGPathElement>())
  const stand = useRef(Infinity)

  const zeichne = useCallback((x: number): void => {
    stand.current = x
    for (const [key, t] of tabellen.current) {
      let l = 0
      for (const p of t.punkte) {
        if (p.x > x + 0.5) break
        l = p.l
      }
      const fertig = l >= t.laenge - 0.5
      t.el.style.setProperty('stroke-dasharray', `${t.laenge} ${t.laenge}`)
      t.el.style.setProperty('stroke-dashoffset', String(fertig ? 0 : t.laenge - l))
      spitzen.current.get(key)?.classList.toggle('tp-s3-an', fertig)
    }
  }, [])

  const pfadRef = useCallback(
    (key: string, art: 'linie' | 'spitze') =>
      (el: SVGPathElement | null): void => {
        if (art === 'spitze') {
          if (el) {
            spitzen.current.set(key, el)
            el.classList.toggle('tp-s3-an', stand.current === Infinity)
          } else spitzen.current.delete(key)
          return
        }
        if (!el) {
          tabellen.current.delete(key)
          return
        }
        // Ohne SVG-Geometrie (jsdom) wird nichts vermessen; die Linie steht dann einfach da.
        const messbar = typeof el.getTotalLength === 'function' && typeof el.getPointAtLength === 'function'
        const laenge = messbar ? el.getTotalLength() : 0
        const punkte: { x: number; l: number }[] = []
        if (messbar) for (let l = 0; l <= laenge; l += 4) punkte.push({ x: el.getPointAtLength(l).x, l })
        if (laenge > 0) punkte.push({ x: el.getPointAtLength(laenge).x, l: laenge })
        tabellen.current.set(key, { el, laenge, punkte })
        // Neu gezeichnete Pfade (nach dem Messen) stehen gleich auf dem aktuellen Stand.
        zeichne(stand.current)
      },
    [zeichne],
  )

  return { pfadRef, zeichne }
}
