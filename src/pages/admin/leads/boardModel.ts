// Board-Modell der Lead-Pipeline: Spaltenzuordnung, Wartezeit, Filter.
// Reine Logik ohne React — hier liegt alles, was sich ohne DOM testen laesst.

import type { Lead, LeadStatus } from '@/types'

export type BoardColumnKey = 'neu' | 'gespraech' | 'analyse' | 'entscheidung' | 'archiv'

/** Ab wie vielen Tagen die Zeitangabe auffaellt bzw. zusaetzlich fett wird. */
export type AgeThresholds = { accent: number; bold: number }

const SLOW: AgeThresholds = { accent: 7, bold: 14 }
const FAST: AgeThresholds = { accent: 3, bold: 7 }

/** Rueckfall-Schwellen, wenn ein Zustand keinen eigenen Zeitstempel hat. */
export const CREATED_THRESHOLDS: AgeThresholds = SLOW

export type BoardColumn = {
  key: BoardColumnKey
  title: string
  statuses: LeadStatus[]
  /** Kurztext, wenn die Spalte leer bleibt — die Spalte selbst bleibt sichtbar. */
  emptyHint: string
  thresholds: AgeThresholds
}

// 'converted' und 'rejected' stehen bewusst nur im Archiv, das hinter dem
// Schalter "Archiv anzeigen" liegt.
export const BOARD_COLUMNS: BoardColumn[] = [
  {
    key: 'neu',
    title: 'Offene Leads',
    statuses: ['new'],
    emptyHint: 'Keine offenen Leads.',
    thresholds: SLOW,
  },
  {
    key: 'gespraech',
    title: 'Erstgespräch erfasst',
    statuses: ['contacted', 'onboarding_scheduled'],
    emptyHint: 'Noch kein Erstgespräch erfasst.',
    thresholds: SLOW,
  },
  {
    key: 'analyse',
    title: 'Analyse',
    statuses: ['lsa_freigegeben'],
    emptyHint: 'Keine Analyse unterwegs.',
    thresholds: FAST,
  },
  {
    key: 'entscheidung',
    title: 'Analyse abgeschlossen',
    statuses: ['lsa_fertig'],
    emptyHint: 'Keine abgeschlossene Analyse.',
    thresholds: FAST,
  },
]

export const DONE_COLUMN: BoardColumn = {
  key: 'archiv',
  title: 'Archiv',
  statuses: ['converted', 'rejected'],
  emptyHint: 'Archiv ist leer.',
  thresholds: SLOW,
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

/** Ganze Tage seit einem Zeitpunkt. Heute ergibt 0. */
export function daysWaiting(since: string, now: Date = new Date()): number {
  const start = new Date(since).getTime()
  if (Number.isNaN(start)) return 0
  const days = Math.floor((now.getTime() - start) / 86_400_000)
  return days > 0 ? days : 0
}

/**
 * Zeitstempel des aktuellen Zustands, oder null wenn es keinen gibt.
 *
 * leads traegt nur created_at, contacted_at und onboarding_scheduled_at.
 * Fuer 'lsa_freigegeben' und 'lsa_fertig' existiert KEINE Spalte — diese
 * Zustaende fallen bewusst auf created_at zurueck, statt etwas aus updated_at
 * zu rechnen. Ebenso 'converted' und 'rejected' im Archiv.
 */
export function stateTimestamp(lead: Lead): string | null {
  switch (lead.status) {
    case 'new':
      return lead.created_at
    case 'contacted':
      return lead.contacted_at
    case 'onboarding_scheduled':
      return lead.onboarding_scheduled_at
    default:
      return null
  }
}

export type AgeDisplay = {
  /** Eingefaerbte Hauptzeile. */
  label: string
  accent: boolean
  bold: boolean
  /** Graue Nebenzeile, oder null wenn sie entfaellt. */
  createdLabel: string | null
}

function sinceLabel(days: number): string {
  if (days === 0) return 'seit heute'
  if (days === 1) return 'seit 1 Tag'
  return `seit ${days} Tagen`
}

function createdLabel(days: number): string {
  if (days === 0) return 'heute angelegt'
  if (days === 1) return 'angelegt vor 1 Tag'
  return `angelegt vor ${days} Tagen`
}

/**
 * Was auf der Karte an Zeit steht. Hat der Zustand einen eigenen Zeitstempel,
 * zaehlt die Hauptzeile die Zeit IM Zustand mit den Schwellen der Spalte, und
 * darunter steht grau das Anlagedatum. Fehlt der Zeitstempel, bleibt nur das
 * Anlagedatum als Hauptzeile — mit den Rueckfall-Schwellen 7/14.
 * In Spalte 1 sind beide Werte identisch, dort entfaellt die Nebenzeile.
 */
export function ageDisplay(
  lead: Lead,
  column: BoardColumn,
  now: Date = new Date(),
): AgeDisplay {
  const since = stateTimestamp(lead)
  const createdDays = daysWaiting(lead.created_at, now)

  if (since === null) {
    return {
      label: createdLabel(createdDays),
      accent: createdDays >= CREATED_THRESHOLDS.accent,
      bold: createdDays >= CREATED_THRESHOLDS.bold,
      createdLabel: null,
    }
  }

  const days = daysWaiting(since, now)
  return {
    label: sinceLabel(days),
    accent: days >= column.thresholds.accent,
    bold: days >= column.thresholds.bold,
    createdLabel: column.key === 'neu' ? null : createdLabel(createdDays),
  }
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
