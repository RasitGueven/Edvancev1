// Board-Modell der Lead-Pipeline: Spaltenzuordnung, Wartezeit, Filter.
// Reine Logik ohne React — hier liegt alles, was sich ohne DOM testen laesst.
// Texte stehen als i18n-Schluessel im Namespace 'leads'.

import type { Lead, LeadStatus } from '@/types'

export type BoardColumnKey = 'neu' | 'gespraech' | 'analyse' | 'entscheidung' | 'archiv'

/** Ab wie vielen Tagen die Zeitangabe auffaellt bzw. zusaetzlich fett wird. */
export type AgeThresholds = { accent: number; bold: number }

const SLOW: AgeThresholds = { accent: 7, bold: 14 }
const FAST: AgeThresholds = { accent: 3, bold: 7 }

/** Rueckfall-Schwellen, wenn ein Zustand keinen eigenen Zeitstempel hat. */
export const CREATED_THRESHOLDS: AgeThresholds = SLOW

/** Ab so vielen Tagen im Zustand erscheint "Seit X Tagen offen – nachhaken". */
export const FOLLOW_UP_DAYS = 7

export type BoardColumn = {
  key: BoardColumnKey
  statuses: LeadStatus[]
  thresholds: AgeThresholds
  /**
   * Spalte mit Nachfass-Hinweis: die Farbe traegt dann allein der Hinweis, die
   * Zeitzeile bleibt neutral — auch beim Rueckfall aufs Anlagedatum.
   */
  followUp?: boolean
}

// 'converted' und 'rejected' stehen bewusst nur im Archiv, das hinter dem
// Schalter "Archiv anzeigen" liegt. 'vertrag' lebt in der Ansicht "Vertraege".
export const BOARD_COLUMNS: BoardColumn[] = [
  { key: 'neu', statuses: ['new'], thresholds: SLOW },
  { key: 'gespraech', statuses: ['contacted', 'onboarding_scheduled'], thresholds: SLOW },
  { key: 'analyse', statuses: ['lsa_freigegeben'], thresholds: FAST },
  { key: 'entscheidung', statuses: ['lsa_fertig'], thresholds: FAST, followUp: true },
]

export const DONE_COLUMN: BoardColumn = {
  key: 'archiv',
  statuses: ['converted', 'rejected'],
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
 * Tage fuer den Nachfass-Hinweis, oder null wenn er entfaellt. Gezaehlt wird ab
 * dem Zeitstempel des Zustandswechsels — ohne Zeitstempel (Bestand) kein
 * Hinweis, nie ab dem Anlagedatum.
 */
export function followUpDays(
  since: string | null,
  now: Date = new Date(),
): number | null {
  if (since === null) return null
  const days = daysWaiting(since, now)
  return days >= FOLLOW_UP_DAYS ? days : null
}

/**
 * Zeitstempel des aktuellen Zustands, oder null wenn es keinen gibt.
 *
 * Jeder Zustand der vier Spalten hat seit Migration 20260904100000 eine eigene
 * Spalte auf leads: created_at, contacted_at, lsa_freigegeben_at,
 * lsa_fertig_at. Nichts wird aus updated_at gerechnet oder geschaetzt.
 *
 * 'rejected' hat seit 20260922120000 rejected_at. Null bleibt fuer
 * 'converted' und fuer Bestandsleads, deren Zeitstempel erst ab der jeweiligen
 * Migration geschrieben wird. ageDisplay faellt dann aufs Anlagedatum zurueck.
 */
export function stateTimestamp(lead: Lead): string | null {
  switch (lead.status) {
    case 'new':
      return lead.created_at
    case 'contacted':
      return lead.contacted_at
    case 'onboarding_scheduled':
      return lead.onboarding_scheduled_at
    case 'lsa_freigegeben':
      return lead.lsa_freigegeben_at
    case 'lsa_fertig':
      return lead.lsa_fertig_at
    case 'rejected':
      return lead.rejected_at
    default:
      return null
  }
}

export type AgeDisplay = {
  /** 'since' = Tage im Zustand, 'created' = Rueckfall aufs Anlagedatum. */
  kind: 'since' | 'created'
  days: number
  accent: boolean
  bold: boolean
  /** Tage seit Anlage fuer die graue Nebenzeile, oder null wenn sie entfaellt. */
  createdDays: number | null
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
  const colored = column.followUp !== true

  if (since === null) {
    return {
      kind: 'created',
      days: createdDays,
      accent: colored && createdDays >= CREATED_THRESHOLDS.accent,
      bold: colored && createdDays >= CREATED_THRESHOLDS.bold,
      createdDays: null,
    }
  }

  const days = daysWaiting(since, now)
  return {
    kind: 'since',
    days,
    accent: colored && days >= column.thresholds.accent,
    bold: colored && days >= column.thresholds.bold,
    createdDays: column.key === 'neu' ? null : createdDays,
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
