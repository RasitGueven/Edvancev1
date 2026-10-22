// Station 03 · Lernweg — die Linien wachsen mit der Spitze (R7-9, Entscheidung
// 24; Nachbesserung, Entscheidung 4; PF-1, Entscheidungen 1 und 2).
//
// Je Pfad eine Tabelle Laufkoordinate w → Länge aus getPointAtLength (alle 4
// Entwurfs-px). w ist die Weglänge entlang der Linie ab ihrem Anfang (plus x
// des Anfangs): Senkrechte Stücke wachsen so stetig mit, und Stücke, die sich
// decken (gemeinsamer Stamm), wachsen gleich schnell. Die Spitze einer Linie
// erscheint erst, wenn die Linie fertig ist.
//
// Vermessen wird nur, wenn ein Pfad dazukommt oder sein d sich ändert: pfadRef
// liefert je (key, art) über Renders hinweg dieselbe Funktion, abgleichen()
// prüft nach dem Rendern die d. Front-Tabelle und Bereich entstehen einmal je
// Messung; je Bild wird nichts kopiert oder sortiert.

import { useCallback, useRef } from 'react'

import { frontTabelle, laufKoordinaten, type FrontTabelle } from '@/lib/report/praesentation/lernwegFahrt'

type Tabelle = {
  el: SVGPathElement
  d: string | null
  laenge: number
  punkte: { w: number; x: number; l: number }[]
  /** Zuletzt gesetzter dashoffset; nur Änderungen gehen ins DOM. */
  offset: number
}
type Bereich = { start: number; ende: number } | null
type PfadRef = (el: SVGPathElement | null) => void
type Messung = { d: string | null; laenge: number; punkte: Tabelle['punkte'] }
type Cache = { front: FrontTabelle; bereich: Bereich }

export function useLinienZeichnen(): {
  pfadRef: (key: string, art: 'linie' | 'spitze') => PfadRef
  /** Nach dem Rendern: Pfade mit neuem d neu vermessen. */
  abgleichen: () => void
  zeichne: (w: number) => void
  /** Anfang und Ende der Laufkoordinate über alle Linien; null ohne Linien. */
  bereich: () => Bereich
  /** w → größtes erreichtes x, über alle Linien. */
  front: () => FrontTabelle
} {
  const tabellen = useRef(new Map<string, Tabelle>())
  const spitzen = useRef(new Map<string, SVGPathElement>())
  const refs = useRef(new Map<string, PfadRef>())
  /** Letzte Messung je key mit ihrem d: Ein Pfad mit gleichem d wird nicht neu vermessen. */
  const messungen = useRef(new Map<string, Messung>())
  const stand = useRef(Infinity)
  const cache = useRef<Cache | null>(null)

  const zeichne = useCallback((w: number): void => {
    stand.current = w
    for (const [key, t] of tabellen.current) setzen(t, spitzen.current.get(key), w)
  }, [])

  const vermessen = useCallback((key: string, el: SVGPathElement): void => {
    const d = el.getAttribute('d')
    let m = messungen.current.get(key)
    if (!m || m.d !== d) {
      m = { d, ...messe(el) }
      messungen.current.set(key, m)
    }
    const t: Tabelle = { el, d, laenge: m.laenge, punkte: m.punkte, offset: NaN }
    el.style.setProperty('stroke-dasharray', `${m.laenge} ${m.laenge}`)
    tabellen.current.set(key, t)
    cache.current = null
    // Neu vermessene Pfade stehen gleich auf dem aktuellen Stand.
    setzen(t, spitzen.current.get(key), stand.current)
  }, [])

  const pfadRef = useCallback(
    (key: string, art: 'linie' | 'spitze'): PfadRef => {
      const id = `${art}:${key}`
      let ref = refs.current.get(id)
      if (ref) return ref
      ref =
        art === 'spitze'
          ? (el) => {
              if (el) {
                spitzen.current.set(key, el)
                el.classList.toggle('tp-s3-an', (tabellen.current.get(key)?.offset ?? (stand.current === Infinity ? 0 : 1)) === 0)
              } else spitzen.current.delete(key)
            }
          : (el) => {
              if (el) vermessen(key, el)
              else if (tabellen.current.delete(key)) cache.current = null
            }
      refs.current.set(id, ref)
      return ref
    },
    [vermessen],
  )

  const abgleichen = useCallback((): void => {
    for (const [key, t] of tabellen.current) if (t.el.getAttribute('d') !== t.d) vermessen(key, t.el)
  }, [vermessen])

  const gecacht = useCallback((): Cache => (cache.current ??= baueCache(tabellen.current.values())), [])

  const bereich = useCallback((): Bereich => gecacht().bereich, [gecacht])
  const front = useCallback((): FrontTabelle => gecacht().front, [gecacht])

  return { pfadRef, abgleichen, zeichne, bereich, front }
}

/** getPointAtLength alle 4 Entwurfs-px. Ohne SVG-Geometrie (jsdom) wird nichts vermessen; die Linie steht dann einfach da. */
function messe(el: SVGPathElement): Omit<Messung, 'd'> {
  const messbar = typeof el.getTotalLength === 'function' && typeof el.getPointAtLength === 'function'
  const laenge = messbar ? el.getTotalLength() : 0
  const proben: { x: number; y: number; l: number }[] = []
  if (messbar) {
    for (let l = 0; l < laenge; l += 4) proben.push({ ...xy(el.getPointAtLength(l)), l })
    proben.push({ ...xy(el.getPointAtLength(laenge)), l: laenge })
  }
  const w = laufKoordinaten(proben)
  return { laenge, punkte: proben.map((p, i) => ({ w: w[i], x: p.x, l: p.l })) }
}

/** Linie bis Laufkoordinate w zeichnen; ins DOM nur, was sich ändert. */
function setzen(t: Tabelle, spitze: SVGPathElement | undefined, w: number): void {
  let l = 0
  for (const p of t.punkte) {
    if (p.w > w + 0.5) break
    l = p.l
  }
  const fertig = l >= t.laenge - 0.5
  const offset = fertig ? 0 : t.laenge - l
  if (offset !== t.offset) {
    t.offset = offset
    t.el.style.setProperty('stroke-dashoffset', String(offset))
  }
  if (spitze && spitze.classList.contains('tp-s3-an') !== fertig) spitze.classList.toggle('tp-s3-an', fertig)
}

/** Front-Tabelle und Bereich über alle Linien, einmal je Messung. */
function baueCache(tabellen: Iterable<Tabelle>): Cache {
  const proben: { w: number; x: number }[] = []
  let start = Infinity
  let ende = -Infinity
  for (const t of tabellen) {
    if (t.punkte.length === 0) continue
    start = Math.min(start, t.punkte[0].w)
    ende = Math.max(ende, t.punkte[t.punkte.length - 1].w)
    for (const p of t.punkte) proben.push({ w: p.w, x: p.x })
  }
  return { front: frontTabelle(proben), bereich: start === Infinity ? null : { start, ende } }
}

const xy = (p: DOMPoint | { x: number; y: number }): { x: number; y: number } => ({ x: p.x, y: p.y })
