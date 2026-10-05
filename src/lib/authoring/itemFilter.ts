// Filter und Sortierung der Expertenliste (ausgelagert aus AuthoringItemsPage, 400-Zeilen-Grenze).
// Reine Funktionen; dazu der Filter "Nicht bei Lena" (Lena-Board, Entscheidung 42).

import type { FilterState } from '@/components/edvance/authoring/AuthoringFilters'
import { THEMA_OHNE } from '@/components/edvance/authoring/AuthoringFilters'
import type { ItemRowData } from '@/components/edvance/authoring/ItemRow'
import type { ReviewMeta } from '@/lib/supabase/taskAuthoring'
import type { PruefAdminZeile, TaskStatus } from '@/types'
import { isGroundedSource } from './grounding'
import { themaVon, type Zuordnung } from './board'

export const STATUS_ORDER: Record<TaskStatus, number> = {
  beanstandet: 0,
  rueckfrage: 0,
  draft: 1,
  review: 2,
  ready: 3,
}

export type FilterKontext = {
  subjectOf: Map<string, string>
  meta: Map<string, ReviewMeta>
  zuordnung: Zuordnung
  /** Lenas Ergebnis je Aufgabe (pruef_admin_liste); leer, wenn nicht geladen. */
  lena: Map<string, PruefAdminZeile>
}

export function filtereUndSortiere(rows: ItemRowData[], filters: FilterState, k: FilterKontext): ItemRowData[] {
  const { subjectOf, meta, zuordnung, lena } = k
  const needle = filters.search.trim().toLowerCase()

  const filtered = rows.filter((row) => {
    const { task, flagCount, blockingCount } = row
    if (needle && !(task.title ?? '').toLowerCase().includes(needle)) return false
    if (filters.status !== 'all' && task.status !== filters.status) return false
    if (
      filters.subject !== 'all' &&
      subjectOf.get(task.cluster_id ?? '') !== filters.subject
    ) {
      return false
    }
    if (filters.competency !== 'all' && task.competency_content !== filters.competency) {
      return false
    }
    if (filters.afb !== 'all' && task.afb !== filters.afb) return false
    if (filters.source !== 'all') {
      const vera = isGroundedSource(task.source)
      if (filters.source === 'eigene' && vera) return false
      if (filters.source === 'vera' && !vera) return false
    }
    if (filters.skill !== 'all' && task.skill_key !== filters.skill) return false
    if (filters.thema !== 'all') {
      const themaKey = themaVon(task, zuordnung)?.thema_key ?? THEMA_OHNE
      if (themaKey !== filters.thema) return false
    }
    const rowMeta = meta.get(task.id)
    if (filters.fehlbild !== 'all' && !(rowMeta?.labels ?? []).includes(filters.fehlbild)) {
      return false
    }
    if (filters.labelIncomplete === 'yes' && !rowMeta?.hasIncomplete) return false
    if (filters.flags === 'blocking' && blockingCount === 0) return false
    if (filters.flags === 'any' && flagCount === 0) return false
    if (filters.flags === 'none' && flagCount > 0) return false
    if (filters.asset === 'yes' && task.assets.length === 0) return false
    if (filters.asset === 'no' && task.assets.length > 0) return false
    if (filters.table === 'yes' && !row.hasTable) return false
    if (filters.table === 'no' && row.hasTable) return false
    if (filters.lena === 'nicht' && !lena.get(task.id)?.ausschluss) return false
    return true
  })

  return [...filtered].sort((a, b) => {
    switch (filters.sort) {
      case 'title':
        return (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
      case 'status':
        return STATUS_ORDER[a.task.status] - STATUS_ORDER[b.task.status]
      case 'newest':
        return b.task.created_at.localeCompare(a.task.created_at)
      case 'skill':
        // Nach Skill gruppiert (Aufgaben eines Skills stammen aus demselben
        // Muster — Lena arbeitet sie am Stueck durch). Ohne Skill nach unten.
        return (
          (a.task.skill_key ?? '￿').localeCompare(b.task.skill_key ?? '￿', 'de') ||
          (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
        )
      case 'flags':
      default:
        // Blockierendes zuerst — das ist die Arbeit, die wirklich ansteht.
        return (
          b.blockingCount - a.blockingCount ||
          b.flagCount - a.flagCount ||
          (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
        )
    }
  })
}

/** Erhaelt die (bereits nach Skill sortierten) Zeilen als Gruppen [skill, rows]. */
export function groupBySkill(rows: ItemRowData[]): [string, ItemRowData[]][] {
  const groups = new Map<string, ItemRowData[]>()
  for (const row of rows) {
    const key = row.task.skill_key ?? '—'
    const group = groups.get(key)
    if (group) group.push(row)
    else groups.set(key, [row])
  }
  return [...groups.entries()]
}
