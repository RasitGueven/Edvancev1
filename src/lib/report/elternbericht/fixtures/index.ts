// Alle Fälle des Eltern-Berichts R7 für Vorschau und Druck-Test.
//
// Nur von Tests und der Vorschau importiert; kein Modul hier lädt den
// Supabase-Client. Neue Fälle hier eintragen, dann gehen Vorschau und
// Druck-Test sie automatisch durch.

import * as a from '@/lib/report/elternbericht/fixtures/abgestuft'
import * as af from '@/lib/report/elternbericht/fixtures/ansatzFaelle'
import * as g from '@/lib/report/elternbericht/fixtures/grenzfaelle'
import * as lw from '@/lib/report/elternbericht/fixtures/lernwegFaelle'
import * as v4 from '@/lib/report/elternbericht/fixtures/batuV4'
import * as fp from '@/lib/report/elternbericht/fixtures/fahrplanFaelle'
import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import { NOTIZEN, NOTIZEN_LANG, NOTIZEN_ZIELE, TIERS } from '@/lib/report/elternbericht/fixtures/notizen'
import * as s from '@/lib/report/elternbericht/fixtures/synthetisch'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

export type ElternberichtFall = {
  data: ReportData
  notes: ReportNotes | null
  tiers: TierPlan[]
}

const mitNotizen = (data: ReportData, notes = NOTIZEN): ElternberichtFall => ({ data, notes, tiers: TIERS })

/** Das Zielbild des Musters mit einem anderen Namen (die Notiz ist Freitext des Coachs). */
const zielMit = (name: string): ReportNotes => ({ ...NOTIZEN, zielbild: NOTIZEN.zielbild.replace('Ilkay', name) })

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
  // Grenzfälle für den Druck (R7-5)
  mitFazit: mitNotizen(g.mitFazit),
  fazitLang: mitNotizen(g.fazitLang, NOTIZEN_LANG),
  langerName: mitNotizen(g.langerName, zielMit(g.LANGER_NAME)),
  zuLangerName: mitNotizen(g.zuLangerName, zielMit('Ihr Kind')),
  breiterName: mitNotizen(g.breiterName, zielMit('Ihr Kind')),
  weitereBereiche: mitNotizen(g.weitereBereiche),
  vieleAnliegen: mitNotizen(g.vieleAnliegen),
  keinSchwerpunktMitZiel: mitNotizen(g.keinSchwerpunktMitZiel),
  // Abgestufte LSA mit Thema: Thema-Satz auf Seite 1 (R7-6)
  abgestuft: mitNotizen(a.abgestuft),
  abgestuftMitOffen: mitNotizen(a.abgestuftMitOffen),
  // Längster rechter Text auf Seite 2 bei abgeleiteten Bereichen (R7-8)
  abgestuftLang: mitNotizen(a.abgestuftLang),
  // Lernweg (R7-9)
  ohneKanten: mitNotizen(lw.ohneKanten),
  planOhneThema: mitNotizen(lw.planOhneThema),
  vieleKanten: mitNotizen(lw.vieleKanten),
  langeLabels: mitNotizen(lw.langeLabels),
  // 60 geprüfte Bereiche, fast alle mit Übungsbedarf: Lernweg kürzt (R7-12)
  sehrViele: mitNotizen(lw.sehrViele),
  // Erster Ansatz am Thema, Anliegen mit Antwort (R7-11)
  abgestuftThemaSicher: mitNotizen(af.abgestuftThemaSicher),
  abgestuftPlanrang: mitNotizen(af.abgestuftPlanrang),
  anliegenGemischt: mitNotizen(af.anliegenGemischt),
  anliegenNurUeberfach: mitNotizen(af.anliegenNurUeberfach),
  // Bericht v4: Klassenarbeiten als roter Faden (Bauauftrag V4, V4-1 Entscheidung 7); Ziele bestätigt (Seite 5, Station 04)
  batuV4: mitNotizen(v4.batuV4, NOTIZEN_ZIELE),
  batuBevorstehend: mitNotizen(v4.batuBevorstehend, NOTIZEN_ZIELE),
  batuOhneStatus: mitNotizen(v4.batuOhneStatus, NOTIZEN_ZIELE),
  batuMitNote: mitNotizen(v4.batuMitNote, NOTIZEN_ZIELE),
  fahrplanKlp: mitNotizen(fp.fahrplanKlp, NOTIZEN_ZIELE),
  fahrplanHalbjahr: mitNotizen(fp.fahrplanHalbjahr, NOTIZEN_ZIELE),
  fahrplanLang: mitNotizen(fp.fahrplanLang, NOTIZEN_ZIELE),
  fahrplanAuffuellen: mitNotizen(fp.fahrplanAuffuellen, NOTIZEN_ZIELE),
  allesErfuellt: mitNotizen(fp.allesErfuellt, NOTIZEN_ZIELE),
  ohnePlan: mitNotizen(fp.ohnePlan),
}

export { ilkay, NOTIZEN, NOTIZEN_LANG, NOTIZEN_ZIELE, TIERS }
