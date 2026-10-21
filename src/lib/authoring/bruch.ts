// Die Bruch-Angabe (tasks.bruch / tasks.parts[i].bruch, LSA-Erlebnis L1, Punkt 1).
// Reine Funktionen, kein React, kein Supabase.
//
// Spiegelt die Regel aus der Migration 20261021082756_lsa_eingabeformat (lsa_format_vorschlag,
// lsa_loesung_ist_zahl, lsa_input_hint):
//   JEDE Loesung hat die Form -?\d+/\d+                         → Bruch
//   JEDE Loesung ist eine Zahl (Vorzeichen auch „+“/„−“, Komma/Punkt, Tausender mit Leerzeichen,
//   dahinter hoechstens die Einheit, die das Feld selbst zeigt)  → Zahl
//   sonst (gemischt, Text, fremde Einheit, leer)                 → kein Hinweis (Pruefliste)
// Die Regel ist bewusst woertlich: „+1/3“ ist kein Bruch.

export type InputHint = 'number' | 'fraction' | 'term'

const BRUCH = /^-?\d+\/\d+$/
const ZAHL = /^-?(?:\d{1,3}(?: \d{3})+|\d+)(?:\.\d+)?(.*)$/

/** Wie lsa_normalize_number: trimmen, Leerraum zusammenfassen, erstes Komma → Punkt, klein, Minus-Varianten. */
function normZahl(raw: string): string {
  return raw
    .trim()
    .replace(/\s+/g, ' ')
    .replace(',', '.')
    .toLowerCase()
    .replace(/[−–—]/g, '-')
    .replace(/^\+ ?(?=\d)/, '')
    .replace(/^- (?=\d)/, '-')
    .trim()
}

export function istZahlLoesung(loesung: string, unit?: string | null): boolean {
  const m = ZAHL.exec(normZahl(loesung))
  if (!m) return false
  const rest = m[1].trim()
  if (rest === '') return true
  const feld = (unit ?? '').trim()
  return feld !== '' && rest.replace(/ /g, '') === feld.toLowerCase().replace(/ /g, '')
}

/** 'fraction' · 'number' · null (nicht eindeutig → Pruefliste). */
export function formatVorschlag(answers: string[], unit?: string | null): 'fraction' | 'number' | null {
  if (answers.length === 0) return null
  if (answers.every((a) => BRUCH.test(a.trim()))) return 'fraction'
  if (answers.every((a) => istZahlLoesung(a, unit))) return 'number'
  return null
}

/** Was beim Kind ankommt: die Angabe, sonst der Vorschlag; null = nicht im LSA-Pool. */
export function eingabeFormat(
  bruch: boolean | null | undefined,
  answers: string[],
  unit?: string | null,
  term = false,
): InputHint | null {
  if (term) return 'term'
  if (bruch === true) return 'fraction'
  if (bruch === false) return 'number'
  return formatVorschlag(answers, unit)
}
