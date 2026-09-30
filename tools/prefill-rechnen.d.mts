// Typen fuer die exakte Nachrechnung der Vorbefuellung. Das Werkzeug bleibt .mjs,
// damit es ohne Bauschritt laeuft; der Test importiert es und braucht diese Beschreibung.

export class Q {
  constructor(n: bigint, d?: bigint)
  static von(text: string): Q
  eq(o: Q): boolean
  round(stellen: number): Q
  toString(): string
}

/** Wertet einen Term zu einer exakten Zahl aus (Variablen ausser x werden eingesetzt). */
export function zahl(text: string, vars?: Record<string, Q>): Q
/** Sind zwei Terme in x gleichwertig? */
export function gleichwertig(a: string, b: string): boolean
/** Anzahl der Faktoren auf oberster Ebene, Potenzen mitgezaehlt. */
export function faktoren(text: string): number
