// Tablet-Präsentation R7-9 — die Fahrt durch den Lernweg in Station 03
// (Entscheidung 24). Reine Zeitrechnung: Zeit + Geometrie → Lage der
// Pfeilspitze, scrollLeft und Phase. Die Komponente setzt das je Bild über Refs.
//
// Die Spitze läuft von der rechten Kante der ersten sicheren Basis mit Linie
// bis zum Ende der längsten Linie; die Kamera hält sie bei 62 % der Breite und
// schiebt so die Fläche vor sich her. Danach fährt die Kamera allein bis zum
// Ende, wartet und gleitet zurück zu den Grundlagen.

export type FahrtGeometrie = {
  /** Spitze am Anfang und am Ende, in Entwurfs-px; null ohne Linien (reine Kamerafahrt). */
  start: number | null
  ende: number | null
  /** Skala der Spur. */
  s: number
  /** Sichtbare Breite der Fläche in px. */
  breite: number
  /** Größtes scrollLeft in px. */
  max: number
}

export const FAHRT = {
  /** Nach dem ersten Betreten, bevor die Spitze losläuft. */
  warten: 1500,
  /** Geschwindigkeit der Spitze in Entwurfs-px je Sekunde … */
  pxProSekunde: 115,
  /** … mit dieser Dauer höchstens und mindestens. */
  minDauer: 6000,
  maxDauer: 14000,
  /** Die Kamera allein bis zum Ende. */
  kamera: 2600,
  /** Pause am Ende, dann zurück zu den Grundlagen. */
  pause: 1400,
  zurueck: 2200,
  /** Lage der Spitze im Bild. */
  anteil: 0.62,
  /** Die Kamera deckt auf, was so weit vor der rechten Kante liegt (Entwurfs-px). */
  vorlauf: 120,
} as const

export type FahrtPhase = 'warten' | 'schieben' | 'kamera' | 'pause' | 'zurueck' | 'fertig'

export type FahrtStand = {
  phase: FahrtPhase
  /** Lage der Spitze in Entwurfs-px; null ohne Linien. */
  spitze: number | null
  scrollLeft: number
  /** Bis hierhin (Entwurfs-px) ist alles sichtbar; Infinity = alles. */
  aufgedeckt: number
}

const begrenzt = (x: number, max: number): number => Math.max(0, Math.min(max, x))
/** Weich an- und auslaufend, mit dem Schwung des Prototyps; streng steigend. */
const schwung = (p: number): number => p - (Math.sin(2 * Math.PI * p) / (2 * Math.PI)) * 0.35
const weich = (p: number): number => (p < 0.5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2)

/** Dauer der Schiebe-Phase in ms (0 ohne Linien). */
export function schiebeDauer(g: FahrtGeometrie): number {
  if (g.start === null || g.ende === null) return 0
  const roh = ((g.ende - g.start) / FAHRT.pxProSekunde) * 1000
  return Math.max(FAHRT.minDauer, Math.min(FAHRT.maxDauer, roh))
}

/** Gesamtdauer bis zum Ende der Rückfahrt. */
export const fahrtDauer = (g: FahrtGeometrie): number =>
  FAHRT.warten + schiebeDauer(g) + FAHRT.kamera + FAHRT.pause + FAHRT.zurueck

/** Die Kamera bei Spitze x: x · s − 0,62 · Breite, begrenzt auf den Scrollbereich. */
export const kameraFuer = (x: number, g: FahrtGeometrie): number => begrenzt(x * g.s - FAHRT.anteil * g.breite, g.max)

/**
 * Der Stand der Fahrt nach t ms. Mit `unterbrochenBei` steht ab da alles fertig
 * da, und scrollLeft bleibt, wo es zu diesem Zeitpunkt war.
 */
export function fahrtStand(t: number, g: FahrtGeometrie, unterbrochenBei: number | null = null): FahrtStand {
  if (unterbrochenBei !== null && t >= unterbrochenBei) {
    const dort = fahrtStand(unterbrochenBei, g)
    return { phase: 'fertig', spitze: g.ende, scrollLeft: dort.scrollLeft, aufgedeckt: Infinity }
  }
  const dauer = schiebeDauer(g)
  const sicht = (scroll: number): number => (scroll + g.breite) / g.s - FAHRT.vorlauf

  if (t < FAHRT.warten) {
    return { phase: 'warten', spitze: g.start, scrollLeft: 0, aufgedeckt: g.start ?? sicht(0) }
  }
  let u = t - FAHRT.warten
  if (u < dauer && g.start !== null && g.ende !== null) {
    const spitze = g.start + (g.ende - g.start) * schwung(u / dauer)
    return { phase: 'schieben', spitze, scrollLeft: kameraFuer(spitze, g), aufgedeckt: spitze }
  }
  u -= dauer
  const kamEnde = g.ende === null ? 0 : kameraFuer(g.ende, g)
  if (u < FAHRT.kamera) {
    const scrollLeft = kamEnde + (g.max - kamEnde) * weich(u / FAHRT.kamera)
    return { phase: 'kamera', spitze: g.ende, scrollLeft, aufgedeckt: Math.max(g.ende ?? 0, sicht(scrollLeft)) }
  }
  u -= FAHRT.kamera
  if (u < FAHRT.pause) return { phase: 'pause', spitze: g.ende, scrollLeft: g.max, aufgedeckt: Infinity }
  u -= FAHRT.pause
  if (u < FAHRT.zurueck) {
    return { phase: 'zurueck', spitze: g.ende, scrollLeft: g.max * (1 - weich(u / FAHRT.zurueck)), aufgedeckt: Infinity }
  }
  return { phase: 'fertig', spitze: g.ende, scrollLeft: 0, aufgedeckt: Infinity }
}
