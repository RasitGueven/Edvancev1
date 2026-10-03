// Stichwortsuche im Themenkatalog fuer das Erstgespraech. Rein, ohne Supabase:
// der Katalog wird einmal geladen und hier durchsucht.
import type { Stufe, Thema } from '@/types'

export const MAX_VORSCHLAEGE = 6

export const STUFEN: readonly Stufe[] = ['erprobung', 'erste', 'zweite']

/** Kleinschreibung, Umlaute und ß gefaltet: "Ähnlichkeit" = "aehnlichkeit". */
export function falten(text: string): string {
  return text
    .toLowerCase()
    .replace(/ä/g, 'ae')
    .replace(/ö/g, 'oe')
    .replace(/ü/g, 'ue')
    .replace(/ß/g, 'ss')
}

export function woerter(text: string): string[] {
  return falten(text)
    .split(/[^a-z0-9π]+/)
    .filter((w) => w !== '')
}

// 0 = jedes Suchwort steht als ganzes Wort im Text, 1 = mindestens eins nur
// als Praefix, null = mindestens ein Suchwort passt nicht.
function passung(suchwoerter: string[], textwoerter: string[]): 0 | 1 | null {
  let genau = true
  for (const s of suchwoerter) {
    if (textwoerter.includes(s)) continue
    if (!textwoerter.some((w) => w.startsWith(s))) return null
    genau = false
  }
  return genau ? 0 : 1
}

/**
 * Hoechstens `limit` Themen zur Eingabe. Rang: Treffer im Label vor Treffer in
 * den Schlagworten, innerhalb davon ganzes Wort vor Praefix, dann
 * Katalog-Reihenfolge. Leere Eingabe liefert nichts.
 */
export function sucheThemen(katalog: Thema[], eingabe: string, limit = MAX_VORSCHLAEGE): Thema[] {
  const such = woerter(eingabe)
  if (such.length === 0) return []
  const treffer: { thema: Thema; rang: number }[] = []
  for (const thema of katalog) {
    const imLabel = passung(such, woerter(thema.label))
    if (imLabel !== null) {
      treffer.push({ thema, rang: imLabel })
      continue
    }
    const imSchlagwort = passung(such, thema.schlagworte.flatMap(woerter))
    if (imSchlagwort !== null) treffer.push({ thema, rang: 2 + imSchlagwort })
  }
  return treffer
    .sort((a, b) => a.rang - b.rang || (a.thema.sort ?? 0) - (b.thema.sort ?? 0))
    .slice(0, limit)
    .map((t) => t.thema)
}

/**
 * Schulen zur Eingabe: jedes Suchwort ist Praefix eines Worts aus Name oder
 * Stadtteil. Leere Eingabe liefert nichts.
 */
export function sucheSchulen<T extends { name: string; stadtteil: string | null }>(
  schulen: T[],
  eingabe: string,
  limit = MAX_VORSCHLAEGE,
): T[] {
  const such = woerter(eingabe)
  if (such.length === 0) return []
  return schulen
    .filter((s) => {
      const text = woerter(`${s.name} ${s.stadtteil ?? ''}`)
      return such.every((w) => text.some((t) => t.startsWith(w)))
    })
    .slice(0, limit)
}

/** Stufe zur Klasse: 5/6 Erprobung, 7/8 Erste, ab 9 Zweite. */
export function stufeFuerKlasse(klasse: number | null): Stufe | null {
  if (klasse === null) return null
  if (klasse <= 6) return 'erprobung'
  if (klasse <= 8) return 'erste'
  return 'zweite'
}

/** Klassen, die zu einer Stufe gehoeren. */
export function klassenDerStufe(stufe: Stufe): [number, number] {
  if (stufe === 'erprobung') return [5, 6]
  if (stufe === 'erste') return [7, 8]
  return [9, 10]
}

/** Die Stufe darunter; die Erprobungsstufe hat keine. */
export function stufeDarunter(stufe: Stufe): Stufe | null {
  const i = STUFEN.indexOf(stufe)
  return i > 0 ? STUFEN[i - 1] : null
}

/** Treffer aufgeteilt: die Stufe des Kindes zuerst, der Rest als "andere". */
export function nachStufe(
  treffer: Thema[],
  stufe: Stufe | null,
): { eigene: Thema[]; andere: Thema[] } {
  if (stufe === null) return { eigene: treffer, andere: [] }
  return {
    eigene: treffer.filter((t) => t.stufe === stufe),
    andere: treffer.filter((t) => t.stufe !== stufe),
  }
}
