// Eltern-Bericht R7 — die Schwerpunkte für Seite 1 und 4 (Entscheidung 7).
//
// Kandidaten sind Themenfelder mit mindestens einem Bereich mit Übungsbedarf.
// Reihenfolge:
//   1. gemischt zuerst (Sicheres und Übungsbedarf im selben Feld) — dort
//      „beginnen wir bei dem, was schon klappt",
//   2. dann die tiefste Stufe unter den Übungsbedarf-Bereichen (5/6 vor 7/8
//      vor 9/10),
//   3. dann mehr Übungsbedarf vor weniger,
//   4. dann die Reihenfolge der Themenfelder.
// Höchstens vier; die übrigen gehen in `danach`, in derselben Reihenfolge.
//
// Die Regel ist ein Vorschlag, die Gründer bestätigen sie in der Abnahme.

import { nachFeldKlasseLabel } from '@/lib/report/elternbericht/bereiche'
import { THEMENFELDER, feldPosition } from '@/lib/report/elternbericht/themenfelder'
import { stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import type { EbBereich, EbSchwerpunkt, Stufe, ThemenfeldKey } from '@/types'

export const MAX_SCHWERPUNKTE = 4

const STUFEN_RANG: Readonly<Record<Stufe, number>> = { erprobung: 0, erste: 1, zweite: 2 }

type Kandidat = EbSchwerpunkt & { tiefste: number }

function kandidat(feld: ThemenfeldKey, bereiche: readonly EbBereich[]): Kandidat | null {
  const drin = bereiche.filter((b) => b.feld === feld).sort(nachFeldKlasseLabel)
  const uebung = drin.filter((b) => !b.sicher)
  if (uebung.length === 0) return null
  const sicher = drin.filter((b) => b.sicher)
  return {
    feld,
    gemischt: sicher.length > 0,
    sicher: sicher.map((b) => b.label),
    uebung: uebung.map((b) => b.label),
    tiefste: Math.min(...uebung.map((b) => STUFEN_RANG[stufeAusKlasse(b.klasse)])),
  }
}

const nachRegel = (a: Kandidat, b: Kandidat): number =>
  Number(b.gemischt) - Number(a.gemischt) ||
  a.tiefste - b.tiefste ||
  b.uebung.length - a.uebung.length ||
  feldPosition(a.feld) - feldPosition(b.feld)

export function waehleSchwerpunkte(bereiche: readonly EbBereich[]): {
  schwerpunkte: EbSchwerpunkt[]
  danach: ThemenfeldKey[]
} {
  const reihe = THEMENFELDER.flatMap(({ key }) => kandidat(key, bereiche) ?? [])
    .sort(nachRegel)
    .map(({ tiefste: _tiefste, ...s }) => s)
  return {
    schwerpunkte: reihe.slice(0, MAX_SCHWERPUNKTE),
    danach: reihe.slice(MAX_SCHWERPUNKTE).map((s) => s.feld),
  }
}
