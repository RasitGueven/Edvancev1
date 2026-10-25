// Bericht v4 — Fälle für den Fahrplan der Klassenarbeiten (Bauauftrag V4, V4-1
// Entscheidung 7). Alle auf der Analyse aus batuV4.ts bzw. der synthetischen
// Klasse 7, nur Plan, Datum oder Urteile geändert. Nur Tests und Vorschau.

import { batuMit, URTEILE } from '@/lib/report/elternbericht/fixtures/batuV4'
import { datenAus } from '@/lib/report/elternbericht/fixtures/basis'
import { HEIMAT, KANTEN } from '@/lib/report/elternbericht/fixtures/graph'
import { ILKAY_ROH } from '@/lib/report/elternbericht/fixtures/ilkay'
import { FWG_NAME, FWG_PLAN, THEMEN } from '@/lib/report/elternbericht/fixtures/plaene'
import { klasse7 } from '@/lib/report/elternbericht/fixtures/synthetisch'
import { klpPlan, schulPlan, type SchulplanZeile } from '@/lib/report/elternbericht/plan'
import type { LernPlan, ReportData } from '@/types'

const mitPlan = (data: ReportData, plan: LernPlan | null): ReportData => ({
  ...data,
  erzaehlung: { ...data.erzaehlung, plan },
})

/** Ohne Schulplan: Kernlehrplan NRW 9/10 (viele kommende Themen). */
export const fahrplanKlp = mitPlan(batuMit('geschrieben', null, '446'), klpPlan(THEMEN, 9))

/** FWG-Plan mit künstlichen Halbjahren: 1–3 im ersten, 4–6 im zweiten. */
export const fahrplanHalbjahr = mitPlan(
  batuMit('geschrieben', null, '447'),
  schulPlan(
    FWG_PLAN.map((z) => (z.klasse === 9 ? { ...z, halbjahr: z.position <= 3 ? (1 as const) : (2 as const) } : z)),
    9,
    FWG_NAME,
  ),
)

/** FWG-Plan Klasse 9 um drei Themen verlängert: mehr als vier kommende. */
const LANG: SchulplanZeile[] = [
  ...FWG_PLAN,
  { klasse: 9, position: 7, themaKey: 'aehnlichkeit', titel: 'Ähnlichkeit', halbjahr: null },
  { klasse: 9, position: 8, themaKey: 'trigonometrie', titel: 'Trigonometrie', halbjahr: null },
  { klasse: 9, position: 9, themaKey: 'exponentialfunktionen', titel: 'Exponentialfunktionen', halbjahr: null },
]
export const fahrplanLang = mitPlan(batuMit('geschrieben', null, '448'), schulPlan(LANG, 9, FWG_NAME))

/** Klasse 7 im 2. Halbjahr: zwei kommende Themen, dann zwei aus dem Plan der Klasse 8. */
const K78: SchulplanZeile[] = [
  { klasse: 7, position: 1, themaKey: 'rationale_zahlen', titel: 'Rationale Zahlen', halbjahr: 1 },
  { klasse: 7, position: 2, themaKey: 'zuordnungen', titel: 'Zuordnungen', halbjahr: 1 },
  { klasse: 7, position: 3, themaKey: 'zinsrechnung', titel: 'Prozent- und Zinsrechnung', halbjahr: 1 },
  { klasse: 7, position: 4, themaKey: 'terme_gleichungen', titel: 'Terme und Gleichungen', halbjahr: 2 },
  { klasse: 7, position: 5, themaKey: 'winkel_dreiecke', titel: 'Winkel und Dreiecke', halbjahr: 2 },
  { klasse: 7, position: 6, themaKey: 'zufallsexperimente', titel: 'Zufall und Wahrscheinlichkeit', halbjahr: 2 },
  { klasse: 8, position: 1, themaKey: 'lineare_funktionen', titel: 'Lineare Funktionen', halbjahr: 1 },
  { klasse: 8, position: 2, themaKey: 'terme_binomische_formeln', titel: 'Binomische Formeln', halbjahr: 1 },
  { klasse: 8, position: 3, themaKey: 'flaechen_vielecke', titel: 'Flächen von Vielecken', halbjahr: 2 },
]
export const fahrplanAuffuellen: ReportData = {
  ...klasse7,
  sessionId: '00000000-0000-4000-8000-000000000449',
  analysedAt: '2027-02-15T09:00:00.000Z',
  erzaehlung: {
    ...klasse7.erzaehlung,
    kanten: [...KANTEN],
    heimatThemen: [...HEIMAT],
    plan: schulPlan(K78, 7, 'Gesamtschule Musterstadt'),
  },
}

/** Wie batuV4, nur die Bereiche ohne kommendes Thema behalten Übungsbedarf. */
const OHNE_THEMA = new Set([
  'gleichung_lgs_addition',
  'gleichung_lgs_grafisch',
  'geo_flaeche_trapez',
  'geo_flaeche_drachen_raute',
  'stoch_pfad_summe',
])
const basis = batuMit('geschrieben')
export const allesErfuellt: ReportData = {
  ...datenAus({
    ...ILKAY_ROH,
    sessionId: '00000000-0000-4000-8000-000000000442',
    grade: 9,
    analysedAt: basis.analysedAt!,
    aufgaben: 34,
    testlauf: false,
    schulform: 'Gymnasium',
    naechstesThema: null,
    weakTopics: ['Grundlagen fehlen'],
    urteile: URTEILE.map((k) => (OHNE_THEMA.has(k.skillKey) ? k : { ...k, zustand: 'traegt' })),
    fehlbilder: [],
    themaLabel: 'Reelle Zahlen und Wurzeln',
    raum: basis.erzaehlung.raum,
    modus: 'adaptiv',
    abgeleitet: basis.erzaehlung.abgeleitet,
    kanten: basis.erzaehlung.kanten,
    heimatThemen: basis.erzaehlung.heimatThemen,
    plan: basis.erzaehlung.plan,
  }),
  erstgespraech: basis.erstgespraech,
}

/** Ohne Plan: kein Fahrplan, die Seiten fallen auf v3 zurück. */
export const ohnePlan = mitPlan(batuMit('geschrieben', null, '450'), null)
