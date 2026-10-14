// Sollzahlen je Knoten im Lena-Board (P2). Die Zahlen rechnet pruef_board_soll(); hier stehen nur die
// Ableitungen fuer Reiter, Thema und Knoten und die Reihenfolge nach pruef_soll.sort.

import type { PruefBoardZeile, PruefSollZeile, Stufe } from '@/types'
import type { ThemaGruppe } from './reihenfolge'

/** "noch X zu pruefen" im Reiter: Summe der Restbedarfe; null, wenn kein Knoten der Stufe ein Soll hat. */
export function restDerStufe(soll: PruefSollZeile[], stufe: Stufe): number | null {
  const z = soll.filter((s) => s.stufe === stufe)
  return z.length ? z.reduce((n, s) => n + s.rest, 0) : null
}

export type ThemaSoll = { gezaehlt: number; noetig: number; reicht: boolean }

/** "X von Y noetig" je Thema; ueber das Soll hinaus Gepruefte zaehlen nicht mit. null ohne Soll. */
export function sollDesThemas(soll: PruefSollZeile[], themaKey: string): ThemaSoll | null {
  const z = soll.filter((s) => s.thema_key === themaKey)
  if (!z.length) return null
  return {
    gezaehlt: z.reduce((n, s) => n + Math.min(s.gezaehlt, s.soll), 0),
    noetig: z.reduce((n, s) => n + s.soll, 0),
    reicht: z.every((s) => s.reicht),
  }
}

const ersterSort = (soll: PruefSollZeile[], themaKey: string): number =>
  Math.min(...soll.filter((s) => s.thema_key === themaKey).map((s) => s.sort), Number.POSITIVE_INFINITY)

/** Themen mit Soll zuerst, nach pruef_soll.sort; die uebrigen bleiben in Lehrplan-Reihenfolge dahinter. */
export function sortiereThemen(gruppen: ThemaGruppe[], soll: PruefSollZeile[]): ThemaGruppe[] {
  return gruppen
    .map((g, i) => ({ g, i, s: ersterSort(soll, g.thema_key) }))
    .sort((a, b) => (a.s === b.s ? a.i - b.i : a.s - b.s))
    .map((x) => x.g)
}

export type KnotenGruppe = {
  skill_key: string | null
  label: string
  soll: PruefSollZeile | null
  zeilen: PruefBoardZeile[]
}

/**
 * Die Knoten eines Themas: erst die mit Soll (nach sort, auch ohne Aufgabe im Board), dann die uebrigen in der
 * Reihenfolge ihrer ersten Aufgabe. Die Aufgaben je Knoten behalten die Board-Reihenfolge.
 */
export function knotenDesThemas(gruppe: ThemaGruppe, soll: PruefSollZeile[]): KnotenGruppe[] {
  const knoten = new Map<string | null, KnotenGruppe>()
  for (const s of soll) {
    if (s.thema_key === gruppe.thema_key) {
      knoten.set(s.skill_key, { skill_key: s.skill_key, label: s.skill_label, soll: s, zeilen: [] })
    }
  }
  for (const z of gruppe.zeilen) {
    const k = knoten.get(z.skill_key)
      ?? { skill_key: z.skill_key, label: z.skill_label ?? '', soll: soll.find((s) => s.skill_key === z.skill_key) ?? null, zeilen: [] }
    k.zeilen.push(z)
    knoten.set(z.skill_key, k)
  }
  const alle = [...knoten.values()]
  return [
    ...alle.filter((k) => k.soll).sort((a, b) => (a.soll as PruefSollZeile).sort - (b.soll as PruefSollZeile).sort),
    ...alle.filter((k) => !k.soll),
  ]
}
