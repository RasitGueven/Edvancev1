// Alle Fälle der Tablet-Präsentation für Tests und Vorschau.
//
// Die Fälle des Druckbogens R7 (FAELLE) plus Fälle, die nur die Präsentation
// braucht — jeweils aus Ilkays Analyse abgeleitet, mit eigener Platzhalter-
// Sitzungs-ID und Notizen und Paketen wie FAELLE. Kein Modul hier lädt den
// Supabase-Client. Neue Fälle hier eintragen, dann gehen Vorschau und
// Ansichtstests sie automatisch durch.

import { datenAus } from '@/lib/report/elternbericht/fixtures/basis'
import {
  FAELLE,
  NOTIZEN,
  TIERS,
  type ElternberichtFall,
} from '@/lib/report/elternbericht/fixtures'
import { ILKAY_ROH, ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import type { ReportData, SucheSkill } from '@/types'

const fall = (id: string, urteile: readonly SucheSkill[]): ReportData =>
  datenAus({ ...ILKAY_ROH, sessionId: `00000000-0000-4000-8000-0000000000${id}`, urteile })

const mitNotizen = (data: ReportData): ElternberichtFall => ({ data, notes: NOTIZEN, tiers: TIERS })

/** Prozentsatz, Ausklammern und Winkelsummen auf „übersprungen" (Anhang C). */
const UEBERSPRUNGEN_KEYS = new Set(['prozent_prozentsatz', 'term_ausklammern', 'geo_winkel_summe'])

const mitPraefix = (...praefixe: string[]): SucheSkill[] =>
  ILKAY_URTEILE.filter((s) => praefixe.some((p) => s.skillKey.startsWith(p)))

export const uebersprungen = fall(
  'a1',
  ILKAY_URTEILE.map((s) =>
    UEBERSPRUNGEN_KEYS.has(s.skillKey) ? { ...s, zustand: 'nicht_angesetzt', proben: 2, offen: false } : s,
  ),
)

export const einSchwerpunkt = fall('a2', mitPraefix('groessen_'))

export const zweiSchwerpunkte = fall('a3', mitPraefix('groessen_', 'bruch_'))

export const dreiSchwerpunkte = fall('a4', mitPraefix('groessen_', 'bruch_', 'prozent_'))

export const laeuftNoch: ReportData = { ...fall('a5', ILKAY_URTEILE), status: 'in_progress' }

export const PRAESENTATION_FAELLE: Readonly<Record<string, ElternberichtFall>> = {
  ...FAELLE,
  uebersprungen: mitNotizen(uebersprungen),
  einSchwerpunkt: mitNotizen(einSchwerpunkt),
  zweiSchwerpunkte: mitNotizen(zweiSchwerpunkte),
  dreiSchwerpunkte: mitNotizen(dreiSchwerpunkte),
  laeuftNoch: mitNotizen(laeuftNoch),
}
