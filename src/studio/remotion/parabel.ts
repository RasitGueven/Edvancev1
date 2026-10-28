/**
 * Mathematik der Parabel-Bausteine (B7), rein und getestet: y = a·(x − d)² + e als [a, d, e].
 * Rechnet nur, was das Bild zeigt (Scheitel, Nullstellen, Schnitt mit y = c) — Zahlen kommen aus dem Skelett.
 */
export type Parabel = readonly [number, number, number]

export const NORMALPARABEL: Parabel = [1, 0, 0]

export function parabelY([a, d, e]: Parabel, x: number): number {
  return a * (x - d) ** 2 + e
}

export function scheitel([, d, e]: Parabel): [number, number] {
  return [d, e]
}

/** x-Werte mit a·(x − d)² + e = c, aufsteigend (0, 1 oder 2). */
export function schnitt([a, d, e]: Parabel, c: number): number[] {
  if (a === 0) return []
  const r = (c - e) / a
  if (r < -1e-12) return []
  if (Math.abs(r) < 1e-12) return [d]
  const w = Math.sqrt(r)
  return [d - w, d + w]
}

export const nullstellen = (p: Parabel): number[] => schnitt(p, 0)

/** Übergang zwischen zwei Parametersätzen (t von 0 bis 1). */
export function mischen(p: Parabel, q: Parabel, t: number): Parabel {
  const u = Math.min(1, Math.max(0, t))
  return [p[0] + (q[0] - p[0]) * u, p[1] + (q[1] - p[1]) * u, p[2] + (q[2] - p[2]) * u]
}

/** Abbildung Koordinaten → Pixel für ein Feld der Größe breite × hoehe. */
export function abbildung(xb: readonly [number, number], yb: readonly [number, number], breite: number, hoehe: number) {
  const sx = breite / (xb[1] - xb[0])
  const sy = hoehe / (yb[1] - yb[0])
  return { x: (x: number) => (x - xb[0]) * sx, y: (y: number) => hoehe - (y - yb[0]) * sy }
}

/** SVG-Pfad der Parabel im sichtbaren Bereich (Stützstellen, Linie). */
export function parabelPfad(p: Parabel, xb: readonly [number, number], yb: readonly [number, number], breite: number, hoehe: number, schritte = 160): string {
  const m = abbildung(xb, yb, breite, hoehe)
  const rand = (yb[1] - yb[0]) * 2
  const teile: string[] = []
  for (let i = 0; i <= schritte; i++) {
    const x = xb[0] + ((xb[1] - xb[0]) * i) / schritte
    const y = Math.max(yb[0] - rand, Math.min(yb[1] + rand, parabelY(p, x)))
    teile.push(`${i === 0 ? 'M' : 'L'}${m.x(x).toFixed(1)},${m.y(y).toFixed(1)}`)
  }
  return teile.join(' ')
}

/** Zahl für die Anzeige im Bild: ganze Zahlen ohne Komma, sonst höchstens zwei Stellen (deutsches Komma). */
export function zahlText(z: number): string {
  const r = Math.round(z * 100) / 100
  return (Object.is(r, -0) ? 0 : r).toLocaleString('de-DE', { maximumFractionDigits: 2 }).replace('-', '−')
}
