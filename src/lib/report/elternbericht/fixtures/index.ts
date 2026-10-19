// Alle Fälle des Eltern-Berichts R7 für Vorschau und Druck-Test.
//
// Nur von Tests und der Vorschau importiert; kein Modul hier lädt den
// Supabase-Client. Neue Fälle hier eintragen, dann gehen Vorschau und
// Druck-Test sie automatisch durch.

import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import { NOTIZEN, TIERS } from '@/lib/report/elternbericht/fixtures/notizen'
import * as s from '@/lib/report/elternbericht/fixtures/synthetisch'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

export type ElternberichtFall = {
  data: ReportData
  notes: ReportNotes | null
  tiers: TierPlan[]
}

const mitNotizen = (data: ReportData): ElternberichtFall => ({ data, notes: NOTIZEN, tiers: TIERS })

export const FAELLE: Readonly<Record<string, ElternberichtFall>> = {
  ilkay: mitNotizen(ilkay),
  testlauf: mitNotizen(s.testlauf),
  klasse10neu: mitNotizen(s.klasse10neu),
  klasse7: mitNotizen(s.klasse7),
  spaeter: mitNotizen(s.spaeter),
  allesSicher: mitNotizen(s.allesSicher),
  nichtsSicher: mitNotizen(s.nichtsSicher),
  sechsFelderMitUebung: mitNotizen(s.sechsFelderMitUebung),
  alleFelder: mitNotizen(s.alleFelder),
  ohneName: mitNotizen(s.ohneName),
  vieleRueckbezuege: mitNotizen(s.vieleRueckbezuege),
  ohneNotizen: { data: s.ohneNotizen, notes: null, tiers: TIERS },
  ohneKatalog: mitNotizen(s.ohneKatalog),
}

export { ilkay, NOTIZEN, TIERS }
