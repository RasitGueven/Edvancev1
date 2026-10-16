// Bereiche im Lena-Board: "Fuer die LSA" und "Fuer die Session". Die Zuordnung kommt aus pruef_board().anlaesse
// (aktive pruef_soll-Anlaesse des Knotens); eine Aufgabe mit beiden Anlaessen steht in beiden Bereichen.
// Aufgaben ohne passenden Anlass erscheinen in keinem Bereich. Hinweise sind nur im Session-Bereich sichtbar.

import type { PruefBoardZeile } from '@/types'

export type Bereich = 'lsa' | 'session'

export const BEREICHE: Bereich[] = ['lsa', 'session']

export const ANLASS: Record<Bereich, string> = { lsa: 'batu_lsa', session: 'batu_session' }

export const imBereich = (z: PruefBoardZeile, b: Bereich): boolean => z.anlaesse.includes(ANLASS[b])

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
