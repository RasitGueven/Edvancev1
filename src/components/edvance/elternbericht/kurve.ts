// Eltern-Bericht R7 — die Kurve auf Seite 4 als reine Rechnung (Maßblatt E7,
// Teil 1 „Seite 4“). Eingabe sind gemessene Höhen in Seitenkoordinaten (pt),
// Ausgabe die d-Attribute der SVG-Pfade. Kein DOM, kein React.

/** x der Knotenmitten. */
export const KNOTEN_X = 61
/** So weit schwingt die Kurve zwischen zwei Knoten seitlich aus. */
const SCHWUNG = 12
/** Ziel des Auslaufs: links neben dem Kicker im Lernziel-Kasten. */
export const ZIEL_X = 84.5
const AUSLAUF_X = KNOTEN_X - 15
const SPITZE_KONTROLLE = { x: 59, dy: 7 }
const ARM_LAENGE = 7.2
const ARM_WINKEL = 0.6

export type KurvenPfade = {
  /** Die Stücke zwischen den Knoten; null bei weniger als zwei Knoten. */
  pfad: string | null
  /** Vom letzten Knoten ins Lernziel; null ohne Lernziel. */
  auslauf: string | null
  /** Die goldene Pfeilspitze am Ende des Auslaufs; null ohne Lernziel. */
  spitze: string | null
}

// Zahlen im d-Attribut: SVG-Syntax (Punkt, ohne Tausendertrenner), keine Anzeige.
const SVG_ZAHL = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2, useGrouping: false })
const zahl = (n: number): string => SVG_ZAHL.format(n)
const punkt = (x: number, y: number): string => `${zahl(x)} ${zahl(y)}`

/**
 * Pfade durch die Knoten bei `knotenY` (von oben nach unten) und, wenn es ein
 * Lernziel gibt, der Auslauf zu `zielY` (Mitte der Kicker-Zeile im Kasten).
 */
export function kurvenPfade(knotenY: readonly number[], zielY: number | null): KurvenPfade {
  if (knotenY.length === 0) return { pfad: null, auslauf: null, spitze: null }

  const stuecke = knotenY.slice(1).map((y1, i) => {
    const y0 = knotenY[i]
    const h = y1 - y0
    const x = KNOTEN_X + (i % 2 === 0 ? 1 : -1) * SCHWUNG
    return `C ${punkt(x, y0 + 0.25 * h)} ${punkt(x, y0 + 0.75 * h)} ${punkt(KNOTEN_X, y1)}`
  })
  const pfad = stuecke.length > 0 ? [`M ${punkt(KNOTEN_X, knotenY[0])}`, ...stuecke].join(' ') : null

  if (zielY === null) return { pfad, auslauf: null, spitze: null }

  const yLetzter = knotenY[knotenY.length - 1]
  const hoehe = zielY - yLetzter
  const kontrolle = { x: SPITZE_KONTROLLE.x, y: zielY + SPITZE_KONTROLLE.dy }
  const auslauf =
    `M ${punkt(KNOTEN_X, yLetzter)} ` +
    `C ${punkt(AUSLAUF_X, yLetzter + 0.55 * hoehe)} ${punkt(kontrolle.x, kontrolle.y)} ${punkt(ZIEL_X, zielY)}`

  return { pfad, auslauf, spitze: spitzeBei(kontrolle, { x: ZIEL_X, y: zielY }) }
}

/** Zwei Arme unter ±ARM_WINKEL um die Rückrichtung der Endtangente. */
function spitzeBei(von: { x: number; y: number }, ziel: { x: number; y: number }): string {
  const winkel = Math.atan2(ziel.y - von.y, ziel.x - von.x) + Math.PI
  const arm = (w: number): string =>
    punkt(ziel.x + ARM_LAENGE * Math.cos(winkel + w), ziel.y + ARM_LAENGE * Math.sin(winkel + w))
  return `M ${arm(ARM_WINKEL)} L ${punkt(ziel.x, ziel.y)} L ${arm(-ARM_WINKEL)}`
}
