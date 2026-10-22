// Fälle für „Unser erster Ansatz“ und „Ihr Anliegen“ (R7-11, Testfälle im
// Bauauftrag). Abgeleitet aus abgestuft (Batu) und Ilkay; nur von Tests und
// der Vorschau importiert.

import { ABGESTUFT_URTEILE, fall } from '@/lib/report/elternbericht/fixtures/abgestuft'
import { datenAus, u } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH } from '@/lib/report/elternbericht/fixtures/ilkay'
import type { ReportData } from '@/types'

const IM_RAUM = new Set([
  'bruch_dezimal',
  'zahl_wurzel_gesetze',
  'zahl_wurzel_irrational',
  'zahl_wurzel_naeherung',
  'zahl_wurzel_teilweise',
])

/** Wie Batu, aber im Thema ist alles sicher: Ansatz ansatzThemaSicher, Breite ab Schwerpunkt 2. */
export const abgestuftThemaSicher = fall('50', {
  analysedAt: '2026-10-18T14:05:00.000Z',
  urteile: ABGESTUFT_URTEILE.map((s) => (IM_RAUM.has(s.skillKey) ? { ...s, zustand: 'traegt', proben: 1 } : s)),
  abgeleitet: [],
})

/**
 * Wie Batu im Thema; in der Breite zwei Felder. Terme & Gleichungen ist
 * gemischt und stünde nach der alten Regel vorn. Geometrie hat nur „Umfang von
 * Rechteck und Dreieck“ — darauf baut „Kreisumfang“ auf, Heimat-Thema „kreis“,
 * im FWG-Plan das zweite Thema nach Reelle Zahlen. Geometrie kommt deshalb zuerst.
 */
export const abgestuftPlanrang = fall('51', {
  analysedAt: '2026-10-18T14:05:00.000Z',
  urteile: [
    ...ABGESTUFT_URTEILE.filter((s) => IM_RAUM.has(s.skillKey) || s.skillKey.startsWith('gleichung_lgs_')),
    u('geo_umfang', 'Umfang von Rechteck und Dreieck', 3, 5, 'traegt_nicht', 2, false),
  ],
  abgeleitet: [],
})

/** Ilkay mit „Noten“ (fachlich) und „Konzentration“ (überfachlich): nur Noten, mit Antwortsatz. */
export const anliegenGemischt: ReportData = datenAus({
  ...ILKAY_ROH,
  sessionId: '00000000-0000-4000-8000-000000000052',
  weakTopics: ['Noten', 'Konzentration'],
})

/** Ohne Thema, nur überfachliche Anliegen, ohne nächstes Thema: Der Kasten entfällt. */
export const anliegenNurUeberfach: ReportData = datenAus({
  ...ILKAY_ROH,
  sessionId: '00000000-0000-4000-8000-000000000053',
  naechstesThema: null,
  weakTopics: ['Konzentration', 'Prüfungsangst', 'Zeiteinteilung'],
})
