// Board-Modell der Lead-Pipeline: Spaltenzuordnung, Wartezeit, Filter.
// Reine Logik ohne React — hier liegt alles, was sich ohne DOM testen laesst.

import type { Lead, LeadStatus } from '@/types'

export type BoardColumnKey = 'neu' | 'gespraech' | 'analyse' | 'entscheidung' | 'abgeschlossen'

export type BoardColumn = {
  key: BoardColumnKey
  title: string
  statuses: LeadStatus[]
  /** Kurztext, wenn die Spalte leer bleibt — die Spalte selbst bleibt sichtbar. */
  emptyHint: string
}

// 'converted' und 'rejected' stehen bewusst nur in der letzten Spalte, die
// hinter dem Schalter "Abgeschlossene anzeigen" liegt.
export const BOARD_COLUMNS: BoardColumn[] = [
  {
    key: 'neu',
    title: 'Neu',
    statuses: ['new'],
    emptyHint: 'Keine neuen Leads.',
  },
  {
    key: 'gespraech',
    title: 'Im Gespräch',
    statuses: ['contacted', 'onboarding_scheduled'],
    emptyHint: 'Niemand im Gespräch.',
  },
  {
    key: 'analyse',
    title: 'Analyse',
    statuses: ['lsa_freigegeben'],
    emptyHint: 'Keine Analyse unterwegs.',
  },
  {
    key: 'entscheidung',
    title: 'Entscheidung',
    statuses: ['lsa_fertig'],
    emptyHint: 'Nichts zu entscheiden.',
  },
]

export const DONE_COLUMN: BoardColumn = {
  key: 'abgeschlossen',
  title: 'Abgeschlossen',
  statuses: ['converted', 'rejected'],
  emptyHint: 'Noch nichts abgeschlossen.',
}

export type LeadFilters = {
  /** Freitext auf Rufname und vollstaendigen Namen. */
  query: string
  subject: string | null
  classLevel: number | null
}

export const EMPTY_FILTERS: LeadFilters = {
  query: '',
  subject: null,
  classLevel: null,
}

/** Ganze Tage seit created_at. Heute angelegt ergibt 0. */
export function daysWaiting(createdAt: string, now: Date = new Date()): number {
  const created = new Date(createdAt).getTime()
  if (Number.isNaN(created)) return 0
  const days = Math.floor((now.getTime() - created) / 86_400_000)
  return days > 0 ? days : 0
}

export function matchesFilters(lead: Lead, filters: LeadFilters): boolean {
  const query = filters.query.trim().toLowerCase()
  if (query !== '') {
    const haystack = `${lead.first_name ?? ''} ${lead.full_name}`.toLowerCase()
    if (!haystack.includes(query)) return false
  }
  if (filters.subject !== null && !lead.subjects.includes(filters.subject)) return false
  if (filters.classLevel !== null && lead.class_level !== filters.classLevel) return false
  return true
}

/**
 * Leads einer Spalte: gefiltert und aeltester zuoberst — wer am laengsten
 * wartet, steht oben. Das ist die Umkehrung von listLeads(), das fuer die
 * uebrigen Aufrufer neueste-zuerst liefert.
 */
export function leadsForColumn(
  leads: Lead[],
  column: BoardColumn,
  filters: LeadFilters,
): Lead[] {
  return leads
    .filter((lead) => column.statuses.includes(lead.status) && matchesFilters(lead, filters))
    .sort(
      (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
    )
}
