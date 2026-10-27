// Eltern-Bericht v4, Seite 2 — „Wichtig für“: je Themenfeld die Klassenarbeiten,
// für die ein geprüfter Bereich des Felds gebraucht wird (Bauauftrag V4, V4-2
// Entscheidung 3). Grundlage sind dieselben Signale wie auf Seite 1 und 3.

import type { EbFahrplan, EbThemaSignal, ThemenfeldKey } from '@/types'

/** nummer = Position im Fahrplan (Schlüssel); ka = Nummer der Klassenarbeit, null ohne bekannte Folge (L5). */
export type WichtigMarke = { nummer: number; ka: number | null; titel: string; naechste: boolean; unterricht: boolean }

/** Höchstens so viele Marken je Zeile. */
export const MARKEN_MAX = 2

/**
 * Die kommenden Stationen, die ein geprüfter Bereich des Felds betrifft,
 * höchstens zwei in Plan-Reihenfolge. Leer = kein Thema dieses Schuljahrs.
 */
export function wichtigFuer(
  feld: ThemenfeldKey,
  fahrplan: EbFahrplan,
  signale: readonly EbThemaSignal[],
): WichtigMarke[] {
  const betrifft = (themaKey: string): boolean =>
    signale.some((s) => s.themaKey === themaKey && [...s.sitzt, ...s.fehlt].some((b) => b.feld === feld))
  return fahrplan.stationen
    .filter((s) => s.nummer > 1 && s.themen.some((x) => betrifft(x.themaKey)))
    .slice(0, MARKEN_MAX)
    .map((s) => ({
      nummer: s.nummer,
      ka: s.ka,
      titel: s.ka !== null ? (s.themen.find((x) => betrifft(x.themaKey))?.titel ?? s.titel) : s.titel,
      naechste: s.stand === 'naechste',
      unterricht: s.stand === 'unterricht',
    }))
}
