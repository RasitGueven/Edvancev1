// Das Freigabe-Board der Item-Pflege: Bereich › Klasse › Fach › Themengebiet.
//
// Festlegungen (Klaerung 22.09.2026):
//   * Bereich: alles zaehlt als Lernstandsanalyse; "Sessions" ist sichtbar,
//     aber leer — es gibt noch kein Merkmal, das eine Session-Aufgabe kennzeichnet.
//   * Klasse k = class_level <= k oder leer (so zieht lsa_start). Aktiv ist eine
//     Klasse, sobald es eine Aufgabe mit genau diesem class_level gibt — aus den
//     Daten, nicht hart codiert (W4). Die uebrigen sind ausgegraut.
//   * Fach kommt ueber den Cluster (skill_clusters.subject_id). Ohne Cluster gibt
//     es kein Fach — solange der Bestand reines Mathe ist, faellt eine Aufgabe
//     ohne Cluster unter FACH_OHNE_CLUSTER.
//   * Themengebiet = Heimat-Thema des Skills (tasks.skill_key -> skill_thema ->
//     themen), seit W4 statt des Clusters. Ohne Skill oder ohne Zuordnung:
//     "Ohne Thema", immer zuletzt. Innerhalb einer Klasse nach Stufe gruppiert,
//     die Stufe der Klasse zuerst, darin nach themen.sort.
//   * Fuenf Zustaende: Offen (draft), Zur Freigabe (review), Rueckfrage (rueckfrage,
//     Lena-Board), Freigegeben (ready), Zurueckgewiesen (beanstandet). Gepruefter Fortschritt = review + ready.
//
// Reine Funktionen, kein React, kein Supabase — testbar (board.test.ts).

import type { AuthoringTask, SkillThema, Stufe, TaskStatus } from '@/types'
import { istVera8 } from './vera8'

export type BoardCluster = { id: string; name: string; subject_name: string }

/** Filter des Arbeitsbildschirms — je einer pro Status. */
export type BoardFilter = 'offen' | 'zurFreigabe' | 'rueckfrage' | 'freigegeben' | 'zurueckgewiesen'

export const BOARD_FILTER: BoardFilter[] = ['offen', 'zurFreigabe', 'rueckfrage', 'freigegeben', 'zurueckgewiesen']

const STATUS_JE_FILTER: Record<BoardFilter, TaskStatus> = {
  offen: 'draft',
  zurFreigabe: 'review',
  // Lena war unsicher (Lena-Board): das Team klaert die Rueckfrage.
  rueckfrage: 'rueckfrage',
  freigegeben: 'ready',
  zurueckgewiesen: 'beanstandet',
}

/** Klassen, die das Board immer zeigt — aktiv oder ausgegraut. */
export const KLASSEN: readonly number[] = [8, 9, 10]
export const FAECHER = ['Mathematik', 'Deutsch', 'Englisch'] as const
export const FACH_OHNE_CLUSTER = 'Mathematik'

/**
 * Der Bestand des Boards: alles ausser VERA8 (Entscheidung zu PR #176).
 * Einmal nach dem Laden angewandt — Zaehler, Klassen-/Fach-/Themenansichten
 * und die Warteschlange der Strecke sehen dadurch nur diesen Bestand.
 */
export function imBoard(task: Pick<AuthoringTask, 'source'>): boolean {
  return !istVera8(task)
}

export function boardBestand<T extends Pick<AuthoringTask, 'source'>>(tasks: T[]): T[] {
  return tasks.filter(imBoard)
}

export function passtZuFilter(task: AuthoringTask, filter: BoardFilter): boolean {
  return task.status === STATUS_JE_FILTER[filter]
}

/** Aktive Klassen: jedes class_level, das im Bestand vorkommt, aufsteigend. */
export function aktiveKlassen(tasks: Pick<AuthoringTask, 'class_level'>[]): number[] {
  const set = new Set<number>()
  for (const task of tasks) if (task.class_level != null) set.add(task.class_level)
  return [...set].sort((a, b) => a - b)
}

/** Die Klassenkacheln: KLASSEN plus jede weitere aktive Klasse, aufsteigend. */
export function boardKlassen(aktive: readonly number[]): number[] {
  return [...new Set([...KLASSEN, ...aktive])].sort((a, b) => a - b)
}

export function inKlasse(task: AuthoringTask, klasse: number, aktive: readonly number[]): boolean {
  if (!aktive.includes(klasse)) return false
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
  rueckfrage: number
  freigegeben: number
  zurueckgewiesen: number
  /** Gepruefter Fortschritt: zur Freigabe + freigegeben. */
  geprueft: number
}

export function standVon(tasks: AuthoringTask[]): Stand {
  const s: Stand = { total: tasks.length, offen: 0, zurFreigabe: 0, rueckfrage: 0, freigegeben: 0, zurueckgewiesen: 0, geprueft: 0 }
  for (const task of tasks) {
    for (const f of BOARD_FILTER) if (passtZuFilter(task, f)) s[f] += 1
  }
  s.geprueft = s.zurFreigabe + s.freigegeben
  return s
}

/** Die KLP-Stufen von unten nach oben. */
export const STUFEN: readonly Stufe[] = ['erprobung', 'erste', 'zweite']

export function stufeVonKlasse(klasse: number): Stufe {
  if (klasse <= 6) return 'erprobung'
  if (klasse <= 8) return 'erste'
  return 'zweite'
}

/**
 * Reihenfolge der Stufen in einer Klasse: die eigene zuerst, dann die darunter
 * absteigend ("Klasse 9/10", "7/8", "5/6"), Hoeheres zuletzt.
 */
export function stufenFolge(klasse: number): Stufe[] {
  const eigene = STUFEN.indexOf(stufeVonKlasse(klasse))
  return [
    ...STUFEN.slice(0, eigene + 1).reverse(),
    ...STUFEN.slice(eigene + 1),
  ]
}

/** Heimat-Themen je skill_key — die Zuordnung aus einem Abruf. */
export type Zuordnung = Map<string, SkillThema>

export function zuordnungAus(zeilen: SkillThema[]): Zuordnung {
  return new Map(zeilen.map((z) => [z.skill_key, z]))
}

export function themaVon(task: Pick<AuthoringTask, 'skill_key'>, zuordnung: Zuordnung): SkillThema | null {
  return (task.skill_key && zuordnung.get(task.skill_key)) || null
}

export type Thema = {
  /** thema_key oder null fuer "Ohne Thema". */
  id: string | null
  name: string | null
  stufe: Stufe | null
  sort: number | null
  tasks: AuthoringTask[]
  stand: Stand
}

/**
 * Themen einer Klasse, stabil sortiert: nach stufenFolge(klasse), darin nach
 * themen.sort (dann Name), "Ohne Thema" zuletzt; darin die Aufgaben nach
 * Titel. Dieselbe Reihenfolge speist die Warteschlange — ein zweiter Start
 * ergibt dieselbe Folge.
 */
export function themenVon(tasks: AuthoringTask[], zuordnung: Zuordnung, klasse: number): Thema[] {
  const gruppen = new Map<string | null, { info: SkillThema | null; tasks: AuthoringTask[] }>()
  for (const task of tasks) {
    const info = themaVon(task, zuordnung)
    const key = info?.thema_key ?? null
    const gruppe = gruppen.get(key)
    if (gruppe) gruppe.tasks.push(task)
    else gruppen.set(key, { info, tasks: [task] })
  }
  const folge = stufenFolge(klasse)
  const rang = (th: Thema): number => (th.stufe ? folge.indexOf(th.stufe) : folge.length)
  const themen: Thema[] = [...gruppen.entries()].map(([id, g]) => ({
    id,
    name: g.info?.label ?? null,
    stufe: g.info?.stufe ?? null,
    sort: g.info?.sort ?? null,
    tasks: [...g.tasks].sort(nachTitel),
    stand: standVon(g.tasks),
  }))
  return themen.sort(
    (a, b) =>
      rang(a) - rang(b) ||
      (a.sort ?? Number.MAX_SAFE_INTEGER) - (b.sort ?? Number.MAX_SAFE_INTEGER) ||
      (a.name ?? '').localeCompare(b.name ?? '', 'de'),
  )
}

export type StufenGruppe = {
  /** null fuer "Ohne Thema". */
  stufe: Stufe | null
  themen: Thema[]
}

/** Die sortierten Themen in Stufen-Abschnitte geschnitten, Reihenfolge bleibt. */
export function stufenGruppen(themen: Thema[]): StufenGruppe[] {
  const gruppen: StufenGruppe[] = []
  for (const th of themen) {
    const letzte = gruppen[gruppen.length - 1]
    if (letzte && letzte.stufe === th.stufe) letzte.themen.push(th)
    else gruppen.push({ stufe: th.stufe, themen: [th] })
  }
  return gruppen
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
