// Reihenfolge im Lena-Board (Entscheidungen 14, 29, 30). Das Board kommt schon sortiert aus
// pruef_board(); hier stehen nur die Ableitungen fuer Uebersicht und "Weiter pruefen".

import type { LenaStatus, PruefBoardZeile, Stufe } from '@/types'

/** Reiter-Reihenfolge: 7/8, 9/10, 5/6. */
export const STUFEN_REIHENFOLGE: Stufe[] = ['erste', 'zweite', 'erprobung']

const sortiere = (zeilen: PruefBoardZeile[]): PruefBoardZeile[] =>
  [...zeilen].sort((a, b) => a.reihenfolge - b.reihenfolge)

/**
 * Die naechste offene Aufgabe nach `aktuell`, in der festen Reihenfolge. Uebersprungene kommen ans
 * Ende: erst alle anderen offenen (nach der aktuellen, dann von vorn), danach die uebersprungenen in
 * der Reihenfolge, in der sie uebersprungen wurden. Die aktuelle Aufgabe selbst nie.
 */
export function naechsteOffene(
  zeilen: PruefBoardZeile[],
  aktuell: string | null,
  uebersprungen: string[] = [],
): string | null {
  const sortiert = sortiere(zeilen)
  const offen = sortiert.filter((z) => z.lena_status === 'offen' && z.task_id !== aktuell)
  const skip = new Set(uebersprungen)
  const pos = sortiert.find((z) => z.task_id === aktuell)?.reihenfolge ?? 0
  const danach = offen.find((z) => z.reihenfolge > pos && !skip.has(z.task_id))
  if (danach) return danach.task_id
  const vonVorn = offen.find((z) => !skip.has(z.task_id))
  if (vonVorn) return vonVorn.task_id
  const offenIds = new Set(offen.map((z) => z.task_id))
  return uebersprungen.find((id) => offenIds.has(id)) ?? null
}

/** "Pruefen" je Thema: die erste offene Aufgabe des Themas, sonst die erste (Anforderung B 11). */
export function ersteImThema(zeilen: PruefBoardZeile[], themaKey: string): string | null {
  const imThema = sortiere(zeilen).filter((z) => z.thema_key === themaKey)
  return (imThema.find((z) => z.lena_status === 'offen') ?? imThema[0])?.task_id ?? null
}

export type Stand = {
  gesamt: number
  geprueft: number
  offen: number
  passt: number
  geaendert: number
  unsicher: number
  passtNicht: number
  freigegeben: number
}

const zaehleStatus = (zeilen: PruefBoardZeile[], s: LenaStatus): number =>
  zeilen.filter((z) => z.lena_status === s).length

/** Kennzahlen fuer "Als Naechstes", Reiter und Abschluss. Freigegeben zaehlt als bewertet. */
export function stand(zeilen: PruefBoardZeile[]): Stand {
  const offen = zaehleStatus(zeilen, 'offen')
  return {
    gesamt: zeilen.length,
    geprueft: zeilen.length - offen,
    offen,
    passt: zaehleStatus(zeilen, 'passt'),
    geaendert: zeilen.filter((z) => z.lena_status === 'passt' && z.geaendert).length,
    unsicher: zaehleStatus(zeilen, 'unsicher'),
    passtNicht: zaehleStatus(zeilen, 'passt_nicht'),
    freigegeben: zaehleStatus(zeilen, 'freigegeben'),
  }
}

/** Nur Stufen mit Aufgaben, in Reiter-Reihenfolge. */
export function stufenMitAufgaben(zeilen: PruefBoardZeile[]): Stufe[] {
  return STUFEN_REIHENFOLGE.filter((s) => zeilen.some((z) => z.stufe === s))
}

export type ThemaGruppe = {
  thema_key: string
  label: string
  sort: number | null
  zeilen: PruefBoardZeile[]
}

/** Die Themen einer Stufe in Lehrplan-Reihenfolge, je mit ihren Aufgaben. */
export function themenDerStufe(zeilen: PruefBoardZeile[], stufe: Stufe): ThemaGruppe[] {
  const gruppen = new Map<string, ThemaGruppe>()
  for (const z of sortiere(zeilen)) {
    if (z.stufe !== stufe) continue
    const g = gruppen.get(z.thema_key) ?? { thema_key: z.thema_key, label: z.thema_label, sort: z.thema_sort, zeilen: [] }
    g.zeilen.push(z)
    gruppen.set(z.thema_key, g)
  }
  return [...gruppen.values()]
}

export type Position = { thema_key: string; thema_label: string; nr: number; anzahl: number; bewertet: number }

/** "Aufgabe x von y" und der Fortschritt im Thema. */
export function positionImThema(zeilen: PruefBoardZeile[], taskId: string): Position | null {
  const z = zeilen.find((x) => x.task_id === taskId)
  if (!z) return null
  const imThema = sortiere(zeilen).filter((x) => x.thema_key === z.thema_key)
  return {
    thema_key: z.thema_key,
    thema_label: z.thema_label,
    nr: imThema.findIndex((x) => x.task_id === taskId) + 1,
    anzahl: imThema.length,
    bewertet: imThema.filter((x) => x.lena_status !== 'offen').length,
  }
}

/** Die vorige Aufgabe in der Reihenfolge ("‹ Zurueck"), unabhaengig vom Status. */
export function vorige(zeilen: PruefBoardZeile[], taskId: string): string | null {
  const sortiert = sortiere(zeilen)
  const i = sortiert.findIndex((z) => z.task_id === taskId)
  return i > 0 ? sortiert[i - 1].task_id : null
}
