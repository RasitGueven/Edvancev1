// Tablet-Präsentation R7-9 — die Fahrt durch den Lernweg in Station 03
// (Entscheidung 24). Reine Zeitrechnung: Zeit + Geometrie → Lage der
// Pfeilspitze, scrollLeft und Phase. Die Komponente setzt das je Bild über Refs.
//
// Die Spitze läuft auf der Laufkoordinate w (Nachbesserung R7-9, Entscheidung
// 4): w = x + alle senkrechten Wege bis zu diesem Punkt, also die Weglänge
// entlang der Linie (achsparallel). So wächst ein senkrechtes Stück stetig
// statt auf einen Schlag, und Stücke, die sich decken (gemeinsamer Stamm),
// haben dasselbe w. Die Kamera folgt dem größten x, das die Front erreicht hat
// (front), und hält es bei 62 % der Breite. Inseln und Zonen erscheinen, sobald
// sie ins Bild kommen (sichtGrenze, PF-1 Entscheidung 5): Die Linie läuft durch
// Kästen, die schon stehen. Danach fährt die Kamera allein bis zum Ende, wartet
// und gleitet zurück.

/** Je Laufkoordinate w das größte x, das die Front bis dahin erreicht hat (nach w sortiert). */
export type FrontTabelle = readonly { w: number; x: number }[]

/** Laufkoordinaten eines Linienzugs: w₀ = x₀, dann jede Strecke mit |Δx| + |Δy|. */
export function laufKoordinaten(punkte: readonly { x: number; y: number }[]): number[] {
  const w: number[] = []
  punkte.forEach((p, i) => {
    const q = punkte[i - 1]
    w.push(i === 0 ? p.x : w[i - 1] + Math.abs(p.x - q.x) + Math.abs(p.y - q.y))
  })
  return w
}

/** Front-Tabelle aus Stichproben aller Linien: nach w sortiert, x als laufendes Maximum. */
export function frontTabelle(proben: readonly { w: number; x: number }[]): FrontTabelle {
  let max = -Infinity
  return [...proben]
    .sort((a, b) => a.w - b.w)
    .map((p) => {
      max = Math.max(max, p.x)
      return { w: p.w, x: max }
    })
}

/** x der Front bei Laufkoordinate w; ohne Tabelle (keine Messung) gilt x = w. */
export function frontBei(w: number, tabelle: FrontTabelle | undefined): number {
  if (!tabelle || tabelle.length === 0) return w
  let x = tabelle[0].x
  for (const p of tabelle) {
    if (p.w > w) break
    x = p.x
  }
  return x
}

export type FahrtGeometrie = {
  /** Laufkoordinate der Spitze am Anfang und am Ende (Entwurfs-px); null ohne Linien (reine Kamerafahrt). */
  start: number | null
  ende: number | null
  /** w → x der Front; fehlt sie, gilt x = w. */
  front?: FrontTabelle
  /** Skala der Spur. */
  s: number
  /** Sichtbare Breite der Fläche in px. */
  breite: number
  /** Größtes scrollLeft in px. */
  max: number
}

export const FAHRT = {
  /** Nach dem ersten Betreten, bevor die Spitze losläuft. */
  warten: 600,
  /** Geschwindigkeit der Spitze in Entwurfs-px je Sekunde … */
  pxProSekunde: 240,
  /** … mit dieser Dauer höchstens und mindestens. */
  minDauer: 3500,
  maxDauer: 8000,
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
  /** Laufkoordinate der Spitze; null ohne Linien. */
  spitze: number | null
  /** Größtes x, das die Front erreicht hat (Kamera und Aufdecken); null ohne Linien. */
  front: number | null
  scrollLeft: number
  /** Bis hierhin (Entwurfs-px) ist alles sichtbar; Infinity = alles. */
  aufgedeckt: number
}

const begrenzt = (x: number, max: number): number => Math.max(0, Math.min(max, x))
/** Weich an- und auslaufend, mit dem Schwung des Prototyps; streng steigend. */
const schwung = (p: number): number => p - (Math.sin(2 * Math.PI * p) / (2 * Math.PI)) * 0.35
const weich = (p: number): number => (p < 0.5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2)

/** Was die Kamera bei scrollLeft zeigt, bis zur rechten Kante abzüglich des Vorlaufs (Entwurfs-px). */
export const sichtGrenze = (scrollLeft: number, g: FahrtGeometrie): number => (scrollLeft + g.breite) / g.s - FAHRT.vorlauf

/** Dauer der Schiebe-Phase in ms (0 ohne Linien). */
export function schiebeDauer(g: FahrtGeometrie): number {
  if (g.start === null || g.ende === null) return 0
  const roh = ((g.ende - g.start) / FAHRT.pxProSekunde) * 1000
  return Math.max(FAHRT.minDauer, Math.min(FAHRT.maxDauer, roh))
}

/** Gesamtdauer bis zum Ende der Rückfahrt. */
export const fahrtDauer = (g: FahrtGeometrie): number =>
  FAHRT.warten + schiebeDauer(g) + FAHRT.kamera + FAHRT.pause + FAHRT.zurueck

/** Die Kamera bei Front x: x · s − 0,62 · Breite, begrenzt auf den Scrollbereich. */
export const kameraFuer = (x: number, g: FahrtGeometrie): number => begrenzt(x * g.s - FAHRT.anteil * g.breite, g.max)

/**
 * Der Stand der Fahrt nach t ms. Mit `unterbrochenBei` steht ab da alles fertig
 * da, und scrollLeft bleibt, wo es zu diesem Zeitpunkt war.
 */
export function fahrtStand(t: number, g: FahrtGeometrie, unterbrochenBei: number | null = null): FahrtStand {
  const vorn = (w: number | null): number | null => (w === null ? null : frontBei(w, g.front))
  if (unterbrochenBei !== null && t >= unterbrochenBei) {
    const dort = fahrtStand(unterbrochenBei, g)
    return { phase: 'fertig', spitze: g.ende, front: vorn(g.ende), scrollLeft: dort.scrollLeft, aufgedeckt: Infinity }
  }
  const dauer = schiebeDauer(g)
  const sicht = (scroll: number): number => sichtGrenze(scroll, g)

  if (t < FAHRT.warten) {
    return { phase: 'warten', spitze: g.start, front: vorn(g.start), scrollLeft: 0, aufgedeckt: vorn(g.start) ?? sicht(0) }
  }
  let u = t - FAHRT.warten
  if (u < dauer && g.start !== null && g.ende !== null) {
    const spitze = g.start + (g.ende - g.start) * schwung(u / dauer)
    const front = frontBei(spitze, g.front)
    return { phase: 'schieben', spitze, front, scrollLeft: kameraFuer(front, g), aufgedeckt: front }
  }
  u -= dauer
  const frontEnde = vorn(g.ende)
  const kamEnde = frontEnde === null ? 0 : kameraFuer(frontEnde, g)
  const fertig = { spitze: g.ende, front: frontEnde }
  if (u < FAHRT.kamera) {
    const scrollLeft = kamEnde + (g.max - kamEnde) * weich(u / FAHRT.kamera)
    return { phase: 'kamera', ...fertig, scrollLeft, aufgedeckt: Math.max(frontEnde ?? 0, sicht(scrollLeft)) }
  }
  u -= FAHRT.kamera
  if (u < FAHRT.pause) return { phase: 'pause', ...fertig, scrollLeft: g.max, aufgedeckt: Infinity }
  u -= FAHRT.pause
  if (u < FAHRT.zurueck) {
    return { phase: 'zurueck', ...fertig, scrollLeft: g.max * (1 - weich(u / FAHRT.zurueck)), aufgedeckt: Infinity }
  }
  return { phase: 'fertig', ...fertig, scrollLeft: 0, aufgedeckt: Infinity }
}
