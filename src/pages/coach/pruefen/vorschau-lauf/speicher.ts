// Vorschau „Lauf mit Prüfziel“ (IU-1b): Board und Listen aus den Prod-Daten der U3-Vorschau (dbread als Lena),
// Entscheidungen nur im Speicher.
import daten from '../vorschau-ziel/daten.json'
import type { PruefBoardZeile, PruefZielStandZeile, PruefZielZeile } from '@/types'

export const BOARD: PruefBoardZeile[] = (daten.board as PruefBoardZeile[]).map((z) => ({ ...z }))
export const LISTE = daten.liste as PruefZielZeile[]
export const LISTE_MSA = daten.liste_msa as PruefZielZeile[]
export const STAND_MSA = daten.stand_msa as PruefZielStandZeile[]
/** Entscheidungen in der Reihenfolge, für den Ansichtstest sichtbar gemacht. */
export const ENTSCHIEDEN: string[] = []
