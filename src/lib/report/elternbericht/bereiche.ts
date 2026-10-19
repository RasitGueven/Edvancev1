// Eltern-Bericht R7 — die untersuchten Bereiche und die Listen für Seite 1.
//
// „Bereich" heißt im Bericht ein direkt geprüfter Skill (Entscheidung 3).
// Gezählt werden alle mit Label, auch die ohne Themenfamilie. `traegt` ist
// sicher, alles andere Übungsbedarf — wie R6 seit #189.

import { feldPosition, feldVon } from '@/lib/report/elternbericht/themenfelder'
import type { EbBereich, KopfFall, SucheSkill } from '@/types'

/** Nur dieser Zustand ist „sicher". */
const SICHER = 'traegt'

/** Je Schlüssel ein Bereich (bei Doppeln gilt der letzte) — sonst kippt die Zählung. */
export function bereicheAus(kompetenzen: readonly SucheSkill[]): EbBereich[] {
  const einmal = [...new Map(kompetenzen.map((k) => [k.skillKey, k])).values()]
  return einmal.map((k) => ({
    skillKey: k.skillKey,
    label: k.label,
    feld: feldVon(k.skillKey),
    klasse: k.klasseHerkunft,
    sicher: k.zustand === SICHER,
  }))
}

/** Nach Themenfeld, dann Herkunftsklasse, dann Label. */
export const nachFeldKlasseLabel = (a: EbBereich, b: EbBereich): number =>
  feldPosition(a.feld) - feldPosition(b.feld) ||
  a.klasse - b.klasse ||
  a.label.localeCompare(b.label, 'de')

export function sicherListe(bereiche: readonly EbBereich[]): EbBereich[] {
  return bereiche.filter((b) => b.sicher).sort(nachFeldKlasseLabel)
}

export function uebungListe(bereiche: readonly EbBereich[]): EbBereich[] {
  return bereiche.filter((b) => !b.sicher).sort(nachFeldKlasseLabel)
}

/**
 * Fall der Überschrift. Ohne untersuchten Bereich gibt es keinen Bogen
 * (baueElternbericht liefert null), der Fall `sicher` bei 0/0 ist deshalb nie
 * sichtbar.
 */
export function kopfFall(sicher: number, uebung: number): KopfFall {
  if (uebung === 0) return 'sicher'
  if (sicher === 0) return 'uebung'
  return 'gemischt'
}
