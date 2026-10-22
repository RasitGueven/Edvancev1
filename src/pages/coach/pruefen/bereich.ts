// Bereiche im Lena-Board: "Fuer die LSA" und "Fuer die Session". Die Zuordnung kommt aus pruef_board().anlaesse
// (aktive pruef_soll-Anlaesse des Knotens); eine Aufgabe mit beiden Anlaessen steht in beiden Bereichen.
// Aufgaben ohne passenden Anlass erscheinen in keinem Bereich. Hinweise sind nur im Session-Bereich sichtbar.
// Zur LSA gehoeren Batus Liste (batu_lsa) und die Vorschau-Kandidaten aus LSA-V (lsa_vorschau, P3).

import type { PruefBoardZeile, PruefSollZeile } from '@/types'

export type Bereich = 'lsa' | 'session'

export const BEREICHE: Bereich[] = ['lsa', 'session']

export const ANLASS: Record<Bereich, string[]> = { lsa: ['batu_lsa', 'lsa_vorschau'], session: ['batu_session'] }

export const imBereich = (z: PruefBoardZeile, b: Bereich): boolean => ANLASS[b].some((a) => z.anlaesse.includes(a))

/**
 * Sollzahlen der Anlaesse eines Bereichs zusammengefuehrt, nach pruef_soll.sort (je Anlass ein pruef_board_soll).
 * Traegt ein Knoten mehrere Anlaesse des Bereichs, zaehlt er einmal: die Zeile mit dem kleineren sort.
 */
export function sollDesBereichs(jeAnlass: PruefSollZeile[][]): PruefSollZeile[] {
  const sortiert = jeAnlass.flat().sort((a, b) => a.sort - b.sort || a.skill_key.localeCompare(b.skill_key))
  return sortiert.filter((z, i) => sortiert.findIndex((y) => y.skill_key === z.skill_key) === i)
}

export const bereichsBoard = (board: PruefBoardZeile[], b: Bereich): PruefBoardZeile[] =>
  board.filter((z) => imBereich(z, b))

/** Der jeweils andere Bereich, wenn die Aufgabe auch dort steht ("auch Session" / "auch LSA"). */
export function auchIn(z: PruefBoardZeile, b: Bereich): Bereich | null {
  const anderer: Bereich = b === 'lsa' ? 'session' : 'lsa'
  return imBereich(z, b) && imBereich(z, anderer) ? anderer : null
}

/** ?bereich= aus der URL; alles andere zaehlt als nicht gesetzt. */
export function leseBereich(params: URLSearchParams): Bereich | null {
  const b = params.get('bereich')
  return b === 'lsa' || b === 'session' ? b : null
}

/** Bereich fuer eine Aufgabe, die ohne ?bereich= geoeffnet wird: LSA vor Session, ohne Anlass LSA (keine Hinweise). */
export const bereichDerAufgabe = (z: PruefBoardZeile | undefined): Bereich =>
  z && !imBereich(z, 'lsa') && imBereich(z, 'session') ? 'session' : 'lsa'

export const ohneBereich = (board: PruefBoardZeile[]): number =>
  board.filter((z) => !BEREICHE.some((b) => imBereich(z, b))).length
