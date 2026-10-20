// Tablet-Präsentation R7-9 (Nachbesserung, Entscheidung 2): Die Spur hat eine
// feste Entwurfshöhe; die Inseln einer Zone brechen in weitere Spalten um,
// statt die Spur höher zu machen. Reihenfolge bleibt, Spalte für Spalte von
// oben nach unten. Die Lücken zwischen den Spalten bleiben Gassen für die Linien.

export type Packung = {
  /** Je Spalte die Indizes der Inseln, in ihrer Reihenfolge. */
  spalten: number[][]
  /** Höchste Spalte (mit Lücken). */
  hoehe: number
  /** Eine Insel ist allein höher als der Platz (Ausnahme: dann wird die Spur höher). */
  zuHoch: boolean
}

/** Füllt Spalte für Spalte bis `verfuegbar`; eine zu hohe Insel steht allein in ihrer Spalte. */
export function packeSpalten(hoehen: readonly number[], verfuegbar: number, luecke: number): Packung {
  const spalten: number[][] = []
  let jetzt: number[] = []
  let h = 0
  let hoehe = 0
  hoehen.forEach((hi, i) => {
    const neu = jetzt.length === 0 ? hi : h + luecke + hi
    if (jetzt.length > 0 && neu > verfuegbar) {
      spalten.push(jetzt)
      hoehe = Math.max(hoehe, h)
      jetzt = [i]
      h = hi
    } else {
      jetzt.push(i)
      h = neu
    }
  })
  if (jetzt.length > 0) {
    spalten.push(jetzt)
    hoehe = Math.max(hoehe, h)
  }
  return { spalten, hoehe, zuHoch: hoehen.some((hi) => hi > verfuegbar) }
}
