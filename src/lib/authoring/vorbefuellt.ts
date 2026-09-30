// Vorbefuellt-Kennzeichen (tasks.vorbefuellt): was ein Agent vorbefuellt hat und
// noch kein Mensch bestaetigt hat. Reine Funktionen, kein React, kein Supabase.
//
// Bestaetigt ist ein Feld, sobald Lena es speichert:
//   * Editor  — zeigt jedes Feld; Speichern bestaetigt alle Aufgaben-Spalten,
//               die Loesungsfelder nach dem erfolgreichen Loesungs-Speichern.
//   * Strecke — zeigt je Schritt nur einen Ausschnitt, speichert aber technisch
//               den ganzen Patch. Bestaetigt sind dort nur Felder, die Lena
//               tatsaechlich geaendert hat — sonst verschwaende das Kennzeichen
//               fuer Felder, die sie in diesem Schritt nie gesehen hat.

import type { AuthoringTaskPatch, Vorbefuellt, VorbefuelltEintrag } from '@/types'

/** Liegen in task_solutions; ihr Kennzeichen steht trotzdem in tasks.vorbefuellt. */
export const LOESUNGS_FELDER = ['correct_answers', 'solution', 'hints', 'typical_errors', 'coach_hints']

/** Die Spalte hinter einem Schluessel: 'parts.2.afb' → 'parts', 'correct_answers.1' → 'correct_answers'. */
export function spalteVon(schluessel: string): string {
  return schluessel.split('.')[0]
}

export function eintragFuer(m: Vorbefuellt | undefined, schluessel: string): VorbefuelltEintrag | null {
  return m?.[schluessel] ?? null
}

export function hatEintraege(m: Vorbefuellt | undefined, spalten?: string[]): boolean {
  const keys = Object.keys(m ?? {})
  return spalten ? keys.some((k) => spalten.includes(spalteVon(k))) : keys.length > 0
}

/** Das Kennzeichen ohne die Eintraege der gespeicherten Spalten. */
export function ohneSpalten(m: Vorbefuellt | undefined, spalten: Iterable<string>): Vorbefuellt {
  const weg = new Set(spalten)
  return Object.fromEntries(Object.entries(m ?? {}).filter(([k]) => !weg.has(spalteVon(k))))
}

/** Spalten, deren Wert sich zwischen zwei Patches unterscheidet. */
export function geaenderteSpalten(vorher: AuthoringTaskPatch, nachher: AuthoringTaskPatch): string[] {
  const keys = new Set([...Object.keys(vorher), ...Object.keys(nachher)]) as Set<keyof AuthoringTaskPatch>
  return [...keys].filter((k) => JSON.stringify(vorher[k] ?? null) !== JSON.stringify(nachher[k] ?? null))
}
