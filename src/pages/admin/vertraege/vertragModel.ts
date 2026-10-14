// Board- und Formularlogik der Vertragsansicht. Reine Funktionen ohne React.

import type { Vertrag, Vertragsart, VertragMitLead, VertragStatus } from '@/types'
import { daysWaiting, followUpDays, type AgeDisplay, type LeadFilters } from '../leads/boardModel'
import { einheitenGueltig, type VertragFormState } from './vertragForm'

export type VertragColumnKey = 'vorbereitung' | 'ausstehend' | 'abgeschlossen' | 'archiv'

export type VertragColumn = { key: VertragColumnKey; status: VertragStatus }

export const VERTRAG_COLUMNS: VertragColumn[] = [
  { key: 'vorbereitung', status: 'in_vorbereitung' },
  { key: 'ausstehend', status: 'unterschrift_ausstehend' },
  { key: 'abgeschlossen', status: 'abgeschlossen' },
]

export const VERTRAG_ARCHIV: VertragColumn = { key: 'archiv', status: 'abgelehnt' }

/** Zeitpunkt, seit dem der Vertrag im aktuellen Status steht. */
export function vertragStateTimestamp(v: Vertrag): string | null {
  switch (v.status) {
    case 'in_vorbereitung':
      return v.in_vorbereitung_at
    case 'unterschrift_ausstehend':
      return v.unterschrift_ausstehend_at
    case 'abgeschlossen':
      return v.abgeschlossen_at
    case 'abgelehnt':
      return v.abgelehnt_at
  }
}

/** Zeitzeile der Karte: Tage im Status, neutral — die Farbe traegt der Nachfass-Hinweis. */
export function vertragAge(v: Vertrag, now: Date = new Date()): AgeDisplay {
  const since = vertragStateTimestamp(v) ?? v.created_at
  return { kind: 'since', days: daysWaiting(since, now), accent: false, bold: false, createdDays: null }
}

/** Nachfass-Hinweis nur in "Unterschrift ausstehend", ab 7 Tagen. */
export function vertragFollowUp(v: Vertrag, now: Date = new Date()): number | null {
  if (v.status !== 'unterschrift_ausstehend') return null
  return followUpDays(v.unterschrift_ausstehend_at, now)
}

/** Name des Kindes aus dem Vertrag, sonst der Name des Leads. */
export function kindName(v: VertragMitLead): string {
  const name = [v.kind_vorname, v.kind_nachname].filter(Boolean).join(' ').trim()
  return name !== '' ? name : v.lead.full_name
}

export function elternName(v: Vertrag): string | null {
  const name = [v.eltern_vorname, v.eltern_nachname].filter(Boolean).join(' ').trim()
  return name !== '' ? name : null
}

export function matchesVertragFilters(v: VertragMitLead, filters: LeadFilters): boolean {
  const query = filters.query.trim().toLowerCase()
  if (query !== '') {
    const haystack = [kindName(v), elternName(v) ?? '', v.lead.full_name].join(' ').toLowerCase()
    if (!haystack.includes(query)) return false
  }
  if (filters.subject !== null) {
    const subjects = v.fach ? [v.fach] : v.lead.subjects
    if (!subjects.includes(filters.subject)) return false
  }
  if (filters.classLevel !== null && (v.klasse ?? v.lead.class_level) !== filters.classLevel) {
    return false
  }
  return true
}

/** Vertraege einer Spalte, gefiltert, laengste Wartezeit zuoberst. */
export function vertraegeForColumn(
  vertraege: VertragMitLead[],
  column: VertragColumn,
  filters: LeadFilters,
): VertragMitLead[] {
  const since = (v: Vertrag): number => new Date(vertragStateTimestamp(v) ?? v.created_at).getTime()
  return vertraege
    .filter((v) => v.status === column.status && matchesVertragFilters(v, filters))
    .sort((a, b) => since(a) - since(b))
}

/**
 * Pflichtangaben der Strecke. Alles ist Pflicht ausser dem Telefon der Eltern
 * und der Schule des Kindes — die beiden fehlen im Alltag oft und halten sonst
 * einen Vertrag auf, der sonst vollstaendig ist.
 *
 * Die IBAN steht nicht in der Liste, weil sie nicht am Vertrag haengt, sondern
 * in vertrag_bankdaten; fehlendeAngaben() haengt sie separat an.
 */
export const PFLICHTFELDER = [
  'eltern_vorname',
  'eltern_nachname',
  'strasse',
  'hausnummer',
  'plz',
  'ort',
  'eltern_email',
  'kind_vorname',
  'kind_nachname',
  'kind_geburtsdatum',
  'klasse',
  'fach',
  'laufzeit_monate',
  'tier_id',
  'vertragsbeginn',
  'kontoinhaber',
] as const satisfies readonly (keyof Vertrag)[]

/**
 * V5: Pflichtangaben einer Pilotvereinbarung. Ohne Paket, Laufzeit und
 * Bankdaten; dafuer Vertragsende und Einheiten, die der Admin vorgibt.
 */
const NUR_REGULAER = ['laufzeit_monate', 'tier_id', 'kontoinhaber'] as const
export const PFLICHTFELDER_PILOT = [
  ...PFLICHTFELDER.filter((f) => !(NUR_REGULAER as readonly string[]).includes(f)),
  'vertrag_ende',
  'einheiten',
] as const satisfies readonly (keyof Vertrag)[]

export type Pflichtfeld =
  | (typeof PFLICHTFELDER)[number]
  | (typeof PFLICHTFELDER_PILOT)[number]
  | 'iban'

export function pflichtfelder(art: Vertragsart): readonly Pflichtfeld[] {
  return art === 'pilot' ? PFLICHTFELDER_PILOT : PFLICHTFELDER
}

/** Was vor Unterschrift oder Versand noch fehlt. Leer = vollstaendig. */
export function fehlendeAngaben(v: Vertrag, hatIban: boolean): Pflichtfeld[] {
  const pilot = v.vertragsart === 'pilot'
  const fehlt: Pflichtfeld[] = pflichtfelder(v.vertragsart).filter((feld) => {
    const wert = v[feld as keyof Vertrag]
    return wert === null || (typeof wert === 'string' && wert.trim() === '')
  })
  if (!hatIban && !pilot) fehlt.push('iban')
  return fehlt
}

/**
 * Dasselbe auf dem, was gerade im Formular steht.
 *
 * Getrennt von fehlendeAngaben(), weil "Daten speichern" pruefen muss, was der
 * Admin eingetippt hat — nicht, was zuletzt gespeichert wurde. Sonst meldet der
 * Knopf ein Feld als fehlend, das direkt daneben ausgefuellt dasteht.
 *
 * `hatIban` deckt die schon hinterlegte IBAN ab; eine neu eingetippte steht in
 * form.iban und zaehlt genauso.
 */
export function fehlendeFormAngaben(form: VertragFormState, hatIban: boolean): Pflichtfeld[] {
  const pilot = form.vertragsart === 'pilot'
  const fehlt: Pflichtfeld[] = pflichtfelder(form.vertragsart).filter(
    (feld) => form[feld as keyof VertragFormState].trim() === '',
  )
  // Pilot: Einheiten sind eine ganze Zahl > 0 — sonst gelten sie als fehlend.
  if (pilot && form.einheiten.trim() !== '' && !einheitenGueltig(form.einheiten)) fehlt.push('einheiten')
  if (!hatIban && !pilot && form.iban.trim() === '') fehlt.push('iban')
  return fehlt
}
