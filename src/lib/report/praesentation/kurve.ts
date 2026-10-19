// Tablet-Präsentation — die Kurve in der Form des Logos (Station 04).
//
// Geometrie wörtlich aus dem Skript des Dummys V7 (docs/report/praesentation/
// dummy-v7.html, „04 Förderansatz"): zwei kubische Bézier-Segmente in einer
// viewBox von 460 × 340, die Bogenlänge über 160 Stützstellen je Segment.
// Lage der Punkte nach der Tabelle in Entscheidung 9 der Anforderung.

import type { TpKurvenPunkt, TpSeite } from '@/types'

type Punkt = readonly [number, number]
type Segment = readonly [Punkt, Punkt, Punkt, Punkt]

export const VIEWBOX = { w: 460, h: 340 } as const

export const SEGS: readonly Segment[] = [
  [[30, 180], [128, 320], [196, 282], [272, 182]],
  [[272, 182], [348, 82], [386, 46], [430, 32]],
]

const STUETZEN = 160

export const KURVE_START: Punkt = SEGS[0][0]
const ENDE: Punkt = SEGS[SEGS.length - 1][3]

/** SVG-Pfad der Kurve. */
export const KURVE_PFAD = `M${KURVE_START.join(' ')} ${SEGS.map(
  (s) => `C${s[1].join(' ')} ${s[2].join(' ')} ${s[3].join(' ')}`,
).join(' ')}`

/** SVG-Pfad der Pfeilspitze am Ende. */
export const KURVE_PFEIL = `M${ENDE[0] - 25} ${ENDE[1]} L${ENDE[0]} ${ENDE[1]} L${ENDE[0] - 8} ${ENDE[1] + 25}`

function bezier(s: Segment, t: number): Punkt {
  const v = 1 - t
  const at = (d: 0 | 1): number =>
    v * v * v * s[0][d] + 3 * v * v * t * s[1][d] + 3 * v * t * t * s[2][d] + t * t * t * s[3][d]
  return [at(0), at(1)]
}

const STUETZPUNKTE: Punkt[] = SEGS.flatMap((s, si) =>
  Array.from({ length: si ? STUETZEN : STUETZEN + 1 }, (_, i) => bezier(s, (si ? i + 1 : i) / STUETZEN)),
)

const LAENGEN: number[] = STUETZPUNKTE.reduce<number[]>((acc, p, k) => {
  const q = STUETZPUNKTE[k - 1]
  acc.push(k === 0 ? 0 : acc[k - 1] + Math.hypot(p[0] - q[0], p[1] - q[1]))
  return acc
}, [])

/** Punkt bei Anteil `f` der Bogenlänge, in viewBox-Koordinaten. */
export function punktBei(f: number): Punkt {
  const ziel = LAENGEN[LAENGEN.length - 1] * f
  let k = 1
  while (k < LAENGEN.length - 1 && LAENGEN[k] < ziel) k++
  const r = (ziel - LAENGEN[k - 1]) / (LAENGEN[k] - LAENGEN[k - 1] || 1)
  const [a, b] = [STUETZPUNKTE[k - 1], STUETZPUNKTE[k]]
  return [a[0] + (b[0] - a[0]) * r, a[1] + (b[1] - a[1]) * r]
}

/** Lage und Seite der Beschriftung je Anzahl der Punkte (Entscheidung 9). */
const LAGEN: Readonly<Record<number, readonly (readonly [number, TpSeite])[]>> = {
  0: [],
  1: [[0.3, 'unten']],
  2: [[0.3, 'unten'], [0.85, 'linksOben']],
  3: [[0.3, 'unten'], [0.6, 'links'], [0.9, 'linksOben']],
  4: [[0.3, 'unten'], [0.52, 'links'], [0.72, 'linksOben'], [0.9, 'linksOben']],
}

/** Die Punkte für n Schwerpunkte (0…4), Lage in Prozent der viewBox. */
export function kurvenPunkte(n: number): TpKurvenPunkt[] {
  const lagen = LAGEN[Math.max(0, Math.min(4, Math.floor(n)))]
  return lagen.map(([anteil, seite]) => {
    const [x, y] = punktBei(anteil)
    return { anteil, x: (x / VIEWBOX.w) * 100, y: (y / VIEWBOX.h) * 100, seite }
  })
}
