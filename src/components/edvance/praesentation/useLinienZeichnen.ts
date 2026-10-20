// Station 03 · Lernweg — die Linien wachsen mit der Spitze (R7-9, Entscheidung
// 24; Nachbesserung, Entscheidung 4).
//
// Je Pfad eine Tabelle Laufkoordinate w → Länge aus getPointAtLength (alle 4
// Entwurfs-px). w ist die Weglänge entlang der Linie ab ihrem Anfang (plus x
// des Anfangs): Senkrechte Stücke wachsen so stetig mit, und Stücke, die sich
// decken (gemeinsamer Stamm), wachsen gleich schnell. Die Spitze einer Linie
// erscheint erst, wenn die Linie fertig ist.

import { useCallback, useRef } from 'react'

import { frontTabelle, laufKoordinaten, type FrontTabelle } from '@/lib/report/praesentation/lernwegFahrt'

type Tabelle = { el: SVGPathElement; laenge: number; punkte: { w: number; x: number; l: number }[] }

export function useLinienZeichnen(): {
  pfadRef: (key: string, art: 'linie' | 'spitze') => (el: SVGPathElement | null) => void
  zeichne: (w: number) => void
  /** Anfang und Ende der Laufkoordinate über alle Linien; null ohne Linien. */
  bereich: () => { start: number; ende: number } | null
  /** w → größtes erreichtes x, über alle Linien. */
  front: () => FrontTabelle
} {
  const tabellen = useRef(new Map<string, Tabelle>())
  const spitzen = useRef(new Map<string, SVGPathElement>())
  const stand = useRef(Infinity)

  const zeichne = useCallback((w: number): void => {
    stand.current = w
    for (const [key, t] of tabellen.current) {
      let l = 0
      for (const p of t.punkte) {
        if (p.w > w + 0.5) break
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
        const proben: { x: number; y: number; l: number }[] = []
        if (messbar) {
          for (let l = 0; l < laenge; l += 4) proben.push({ ...xy(el.getPointAtLength(l)), l })
          proben.push({ ...xy(el.getPointAtLength(laenge)), l: laenge })
        }
        const w = laufKoordinaten(proben)
        tabellen.current.set(key, { el, laenge, punkte: proben.map((p, i) => ({ w: w[i], x: p.x, l: p.l })) })
        // Neu gezeichnete Pfade (nach dem Messen) stehen gleich auf dem aktuellen Stand.
        zeichne(stand.current)
      },
    [zeichne],
  )

  const bereich = useCallback((): { start: number; ende: number } | null => {
    const t = [...tabellen.current.values()].filter((x) => x.punkte.length > 0)
    if (t.length === 0) return null
    return {
      start: Math.min(...t.map((x) => x.punkte[0].w)),
      ende: Math.max(...t.map((x) => x.punkte[x.punkte.length - 1].w)),
    }
  }, [])

  const front = useCallback(
    (): FrontTabelle => frontTabelle([...tabellen.current.values()].flatMap((t) => t.punkte.map(({ w, x }) => ({ w, x })))),
    [],
  )

  return { pfadRef, zeichne, bereich, front }
}

const xy = (p: DOMPoint | { x: number; y: number }): { x: number; y: number } => ({ x: p.x, y: p.y })
