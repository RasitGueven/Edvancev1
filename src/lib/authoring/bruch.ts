// Die Bruch-Angabe (tasks.bruch / tasks.parts[i].bruch, LSA-Erlebnis L1, Punkt 1).
// Reine Funktionen, kein React, kein Supabase.
//
// Spiegelt die Regel aus der Migration 20261021082756_lsa_eingabeformat (lsa_bruch_vorschlag,
// lsa_input_hint): JEDE Loesung hat die Form -?\d+/\d+ → Bruch; KEINE → Zahl; gemischt oder leer → kein
// Hinweis (Pruefliste). Die Regel ist bewusst woertlich: „+1/3“ ist kein Bruch.

export type InputHint = 'number' | 'fraction' | 'term'

const BRUCH = /^-?\d+\/\d+$/

/** true: nur Brueche · false: keine · null: gemischt oder leer. */
export function bruchVorschlag(answers: string[]): boolean | null {
  const werte = answers.map((a) => a.trim()).filter((a) => a !== '')
  if (werte.length === 0) return null
  const brueche = werte.filter((a) => BRUCH.test(a)).length
  if (brueche === werte.length) return true
  // Ein Schraegstrich ohne Regel-Bruch („+1/3“, „−3/4“) ist nicht eindeutig: Pruefliste wie gemischt.
  return brueche === 0 && !werte.some((a) => a.includes('/')) ? false : null
}

/** Was beim Kind ankommt: die Angabe, sonst der Vorschlag; null = nicht im LSA-Pool. */
export function eingabeFormat(
  bruch: boolean | null | undefined,
  answers: string[],
  term = false,
): InputHint | null {
  if (term) return 'term'
  const wert = bruch ?? bruchVorschlag(answers)
  if (wert === null) return null
  return wert ? 'fraction' : 'number'
}
