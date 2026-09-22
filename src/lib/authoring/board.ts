// Das Freigabe-Board der Item-Pflege: Bereich › Klasse › Fach › Themengebiet.
//
// Festlegungen (Klaerung 22.09.2026):
//   * Bereich: alles zaehlt als Lernstandsanalyse; "Sessions" ist sichtbar,
//     aber leer — es gibt noch kein Merkmal, das eine Session-Aufgabe kennzeichnet.
//   * Klasse 8 = class_level <= 8 oder leer (so zieht lsa_start). 9 und 10 sind
//     ausgegraut, bis es fuer sie eigene Aufgaben gibt.
//   * Fach kommt ueber den Cluster (skill_clusters.subject_id). Ohne Cluster gibt
//     es kein Fach — solange der Bestand reines Mathe ist, faellt eine Aufgabe
//     ohne Cluster unter FACH_OHNE_CLUSTER und landet dort in "Ohne Themengebiet".
//   * Themengebiet = Cluster.
//   * Vier Zustaende: Offen (draft), Zur Freigabe (review), Freigegeben (ready),
//     Zurueckgewiesen (beanstandet). Gepruefter Fortschritt = review + ready.
//
// Reine Funktionen, kein React, kein Supabase — testbar (board.test.ts).

import type { AuthoringTask, TaskStatus } from '@/types'

export type BoardCluster = { id: string; name: string; subject_name: string }

/** Filter des Arbeitsbildschirms — je einer pro Status. */
export type BoardFilter = 'offen' | 'zurFreigabe' | 'freigegeben' | 'zurueckgewiesen'

export const BOARD_FILTER: BoardFilter[] = ['offen', 'zurFreigabe', 'freigegeben', 'zurueckgewiesen']

const STATUS_JE_FILTER: Record<BoardFilter, TaskStatus> = {
  offen: 'draft',
  zurFreigabe: 'review',
  freigegeben: 'ready',
  zurueckgewiesen: 'beanstandet',
}

export const KLASSEN = [8, 9, 10] as const
/** Klassen, fuer die es heute Aufgaben gibt. */
export const AKTIVE_KLASSEN: readonly number[] = [8]
export const FAECHER = ['Mathematik', 'Deutsch', 'Englisch'] as const
export const FACH_OHNE_CLUSTER = 'Mathematik'

export function passtZuFilter(task: AuthoringTask, filter: BoardFilter): boolean {
  return task.status === STATUS_JE_FILTER[filter]
}

export function inKlasse(task: AuthoringTask, klasse: number): boolean {
  if (!AKTIVE_KLASSEN.includes(klasse)) return false
  return task.class_level == null || task.class_level <= klasse
}

export function fachVon(task: AuthoringTask, clusters: Map<string, BoardCluster>): string {
  const cluster = task.cluster_id ? clusters.get(task.cluster_id) : undefined
  return cluster?.subject_name || FACH_OHNE_CLUSTER
}

export type Stand = {
  total: number
  offen: number
  zurFreigabe: number
  freigegeben: number
  zurueckgewiesen: number
  /** Gepruefter Fortschritt: zur Freigabe + freigegeben. */
  geprueft: number
}

export function standVon(tasks: AuthoringTask[]): Stand {
  const s: Stand = { total: tasks.length, offen: 0, zurFreigabe: 0, freigegeben: 0, zurueckgewiesen: 0, geprueft: 0 }
  for (const task of tasks) {
    for (const f of BOARD_FILTER) if (passtZuFilter(task, f)) s[f] += 1
  }
  s.geprueft = s.zurFreigabe + s.freigegeben
  return s
}

export type Thema = {
  /** Cluster-ID oder null fuer "Ohne Themengebiet". */
  id: string | null
  name: string | null
  tasks: AuthoringTask[]
  stand: Stand
}

/**
 * Themengebiete eines Fachs, stabil sortiert: nach Cluster-Name, "Ohne
 * Themengebiet" zuletzt; darin die Aufgaben nach Titel. Dieselbe Reihenfolge
 * speist die Warteschlange — ein zweiter Start ergibt dieselbe Folge.
 */
export function themenVon(tasks: AuthoringTask[], clusters: Map<string, BoardCluster>): Thema[] {
  const gruppen = new Map<string | null, AuthoringTask[]>()
  for (const task of tasks) {
    const key = task.cluster_id && clusters.has(task.cluster_id) ? task.cluster_id : null
    const liste = gruppen.get(key)
    if (liste) liste.push(task)
    else gruppen.set(key, [task])
  }
  const themen: Thema[] = [...gruppen.entries()].map(([id, liste]) => ({
    id,
    name: id ? (clusters.get(id)?.name ?? null) : null,
    tasks: [...liste].sort(nachTitel),
    stand: standVon(liste),
  }))
  return themen.sort((a, b) => {
    if (a.id === null) return 1
    if (b.id === null) return -1
    return (a.name ?? '').localeCompare(b.name ?? '', 'de')
  })
}

function nachTitel(a: AuthoringTask, b: AuthoringTask): number {
  return (a.title ?? '').localeCompare(b.title ?? '', 'de') || a.id.localeCompare(b.id)
}

/** Die IDs einer Warteschlange: Aufgaben der Themen, die zum Filter passen. */
export function warteschlange(themen: Thema[], filter: BoardFilter): string[] {
  return themen.flatMap((th) => th.tasks.filter((t) => passtZuFilter(t, filter)).map((t) => t.id))
}

/**
 * Einstieg ueber eine einzelne Aufgabe: sie zuerst, dahinter die uebrigen
 * Aufgaben desselben Themas im selben Zustand wie der Filter (Standard: offen).
 */
export function warteschlangeAb(thema: Thema, taskId: string, filter: BoardFilter): string[] {
  const rest = thema.tasks.filter((t) => t.id !== taskId && passtZuFilter(t, filter)).map((t) => t.id)
  return [taskId, ...rest]
}
