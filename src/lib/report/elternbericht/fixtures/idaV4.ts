// V4-S — das Testkind Ida (tools/lsa-testkinder/v4s-kinder.sql): Klasse 9, Thema Ähnlichkeit und zentrische
// Streckung, Klassenarbeit dazu 'bevorstehend', Schulplan des Deutzer Gymnasiums Schaurtestraße. Die Urteile sind
// die der Sitzung vom 04.11.2026 (dbread nur lesend: lsa_skill_urteil, skills, result_summary.themenraum,
// lsa_sessions). Ersetzt: Sitzungs-ID durch einen Platzhalter. Fehlbilder lässt die Fixture weg (der Bericht
// zeigt davon nur den Sorgfalts-Satz). Graph wie Batu (Prod-Stand). Nur von Tests und der Vorschau importiert.

import { datenAus, u } from '@/lib/report/elternbericht/fixtures/basis'
import { KANTEN_V4 } from '@/lib/report/elternbericht/fixtures/batuV4'
import { HEIMAT } from '@/lib/report/elternbericht/fixtures/graph'
import { ILKAY_ROH } from '@/lib/report/elternbericht/fixtures/ilkay'
import { SCHAURTE_NAME, SCHAURTE_PLAN } from '@/lib/report/elternbericht/fixtures/plaene'
import { schulPlan } from '@/lib/report/elternbericht/plan'
import type { KlassenarbeitStatus, ReportData, SucheSkill } from '@/types'

/** Die 19 direkten Urteile (lsa_skill_urteil, belegt_direkt). */
export const IDA_URTEILE: readonly SucheSkill[] = [
  u('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 3, 5, 'traegt', 1, false),
  u('geo_umfang', 'Umfang von Rechteck und Dreieck', 3, 5, 'traegt', 1, false),
  u('runden_ueberschlag', 'Runden und Überschlag', 2, 5, 'traegt', 1, false),
  u('bruch_dezimal', 'Bruch in Dezimalzahl', 4, 6, 'traegt', 1, false),
  u('dezimal_div', 'Dezimalzahlen dividieren', 3, 6, 'traegt', 1, false),
  u('geo_koordinaten', 'Punkte im Koordinatensystem', 2, 6, 'traegt', 1, false),
  u('groessen_flaechen', 'Flächeneinheiten', 5, 6, 'traegt', 1, false),
  u('geo_flaeche_dreieck', 'Fläche von Dreieck und Parallelogramm', 4, 7, 'traegt', 1, false),
  u('gleichung_einschrittig', 'Einschrittige Gleichungen', 5, 7, 'traegt', 1, false),
  u('potenzen', 'Potenzen und Quadratzahlen', 4, 7, 'traegt_nicht', 2, false),
  u('proportionalitaet', 'Dreisatz, proportional und antiproportional', 4, 7, 'traegt', 1, false),
  u('term_einsetzen', 'Werte in Terme einsetzen', 5, 7, 'traegt', 1, false),
  u('vorzeichen_mult_div', 'Negative Zahlen multiplizieren/dividieren', 2, 7, 'traegt', 1, false),
  u('term_binom_faktorisieren', 'Faktorisieren mit binomischer Formel', 8, 8, 'traegt', 2, false),
  u('term_binom_gemischt', 'Binomische Formeln in Termumformungen', 8, 8, 'traegt', 2, false),
  u('geo_aehnlich_flaeche', 'Flächen und Volumen bei Ähnlichkeit', 7, 9, 'traegt_nicht', 2, false),
  u('geo_aehnlich_strahlen_abschnitt', 'Erster Strahlensatz', 7, 9, 'traegt_nicht', 2, false),
  u('geo_aehnlich_strahlen_parallel', 'Zweiter Strahlensatz', 8, 9, 'traegt_nicht', 2, false),
  u('geo_aehnlich_streckfaktor', 'Streckfaktor und zentrische Streckung', 6, 9, 'traegt', 1, false),
]

/** Abgeleitete Urteile (belegt_direkt = false), nur Schlüssel. */
const ABGELEITET = ['bruch_kuerzen', 'dezimal_add_sub', 'dezimal_mult', 'geo_massstab', 'groessen_laengen', 'term_ausklammern', 'term_ausmultiplizieren', 'term_binom_quadrat', 'term_binom_quadratdifferenz', 'term_minusklammer', 'term_zusammenfassen', 'vorzeichen_add_sub', 'vorzeichen_vorrang']

const RAUM = {
  themaKey: 'aehnlichkeit',
  einstieg: ['geo_aehnlich_flaeche', 'geo_aehnlich_strahlen_parallel'],
  darunter: ['dezimal_add_sub', 'dezimal_div', 'dezimal_mult', 'geo_aehnlich_strahlen_abschnitt', 'geo_aehnlich_streckfaktor', 'geo_massstab', 'gleichung_einschrittig', 'groessen_laengen', 'potenzen', 'proportionalitaet', 'vorzeichen_add_sub', 'vorzeichen_mult_div'],
  herkunft: 'abschluss',
} as const

/** Idas Analyse mit einem Stand der Klassenarbeit; `id` = die letzten drei Ziffern der Platzhalter-Sitzung. */
export function idaMit(klassenarbeit: KlassenarbeitStatus | null, id = '461'): ReportData {
  const data = datenAus({
    ...ILKAY_ROH,
    sessionId: `00000000-0000-4000-8000-000000000${id}`,
    firstName: 'Ida',
    grade: 9,
    analysedAt: '2026-11-04T14:45:45.694Z',
    aufgaben: 26,
    testlauf: false,
    schulform: 'Gymnasium',
    naechstesThema: null,
    weakTopics: ['Grundlagen fehlen'],
    urteile: IDA_URTEILE,
    fehlbilder: [],
    themaLabel: 'Ähnlichkeit und zentrische Streckung',
    raum: { ...RAUM, einstieg: [...RAUM.einstieg], darunter: [...RAUM.darunter] },
    modus: 'adaptiv',
    abgeleitet: ABGELEITET,
    kanten: KANTEN_V4,
    heimatThemen: HEIMAT,
    plan: schulPlan(SCHAURTE_PLAN, 9, SCHAURTE_NAME),
  })
  return {
    ...data,
    dauerMinuten: 20,
    erstgespraech: {
      note: '3',
      trend: 'stabil',
      seit: 'laenger',
      ziele: null,
      klassenarbeit,
      klassenarbeitDatum: null,
      letzteNote: null,
      klassenarbeiten: [],
    },
  }
}

export const idaBevorstehend = idaMit('bevorstehend')
