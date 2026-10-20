// Synthetische Fälle für den Eltern-Bericht R7, klein und aus Ilkays Analyse
// abgeleitet. Nur von Tests und der Vorschau importiert. Neue Skills mit
// Label, Tiefe und klasse_herkunft wie in Prod (Stand 19.10.2026).

import { THEMEN } from '@/lib/report/elternbericht/fixtures/plaene'
import { klpPlan } from '@/lib/report/elternbericht/plan'
import { datenAus, u, type SitzungRoh } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH, ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import type { ReportData, SucheSkill } from '@/types'

const nach = new Map(ILKAY_URTEILE.map((s) => [s.skillKey, s]))

/** Skills aus Ilkays Analyse, unverändert. */
function aus(...keys: string[]): SucheSkill[] {
  return keys.map((k) => {
    const s = nach.get(k)
    if (!s) throw new Error(`fixture: ${k} nicht in Ilkays Analyse`)
    return s
  })
}

const alle = (zustand: string): SucheSkill[] =>
  ILKAY_URTEILE.map((s) => ({ ...s, zustand }))

// Skills über Ilkays Analyse hinaus (Werte aus skills).
const NEU = {
  fktLinear: u('fkt_linear_steigung', 'Steigung einer linearen Funktion', 5, 8, 'traegt_nicht', 2, false),
  laplace: u('stoch_laplace', 'Laplace-Wahrscheinlichkeit', 5, 8, 'traegt_nicht', 2, false),
  scheitel: u('fkt_quadr_scheitel', 'Scheitelpunkt aus der Scheitelpunktform', 7, 9, 'traegt', 1, false),
  pythagoras: u('geo_pythagoras_hypotenuse', 'Hypotenuse mit dem Satz des Pythagoras', 6, 9, 'traegt_nicht', 2, false),
  quadrFormel: u('gleichung_quadr_formel', 'Lösungsformel (p-q- bzw. abc-Formel)', 8, 9, 'traegt_teilweise', 2, false),
  wachstum: u('fkt_exp_wachstum', 'Lineares und exponentielles Wachstum, Wachstumsfaktor', 10, 10, 'traegt', 1, false),
  wurzel: u('zahl_wurzel_quadrat', 'Quadratwurzel als Umkehrung des Quadrierens', 5, 9, 'traegt_nicht', 2, false),
}

const fall = (id: string, aenderung: Partial<SitzungRoh>): ReportData =>
  datenAus({ ...ILKAY_ROH, sessionId: `00000000-0000-4000-8000-0000000000${id}`, ...aenderung })

const KLASSE7 = aus(
  'bruch_kuerzen',
  'bruch_add',
  'groessen_laengen',
  'geo_umfang',
  'prozent_prozentwert',
  'prozent_grundwert',
  'gleichung_neg_koeffizient',
  'term_minusklammer',
)

const SECHS_FELDER = aus(
  'bruch_kuerzen',
  'bruch_add',
  'prozent_grundwert',
  'term_ausklammern',
  'geo_umfang',
  'groessen_flaechen',
  'vorzeichen_vorrang',
)

export const testlauf = fall('01', { testlauf: true })

/** Klasse 10 nach dem Katalogausbau: Bereiche aus 5/6, 7/8 und 9/10. */
export const klasse10neu = fall('02', {
  urteile: [
    ...aus('bruch_kuerzen', 'bruch_add', 'prozent_prozentwert', 'prozent_grundwert', 'term_ausklammern'),
    NEU.scheitel,
    NEU.pythagoras,
    NEU.quadrFormel,
    NEU.wachstum,
  ],
})

/** Klasse 7: zwei Ebenen (7/8 aktuell, 5/6 Grundlagen). */
export const klasse7 = fall('03', { grade: 7, urteile: KLASSE7, plan: klpPlan(THEMEN, 7) })

/** Klasse 7 mit einem Bereich aus 9/10: oberste Ebene „Stoff späterer Klassen". */
export const spaeter = fall('04', { grade: 7, urteile: [...KLASSE7, NEU.wurzel], plan: klpPlan(THEMEN, 7) })

export const allesSicher = fall('05', { urteile: alle('traegt') })

export const nichtsSicher = fall('06', { urteile: alle('traegt_nicht') })

/** Sechs Themenfelder mit Übungsbedarf: vier Schwerpunkte, zwei danach. */
export const sechsFelderMitUebung = fall('07', { urteile: SECHS_FELDER })

/** Alle acht Themenfelder mit Übungsbedarf. */
export const alleFelder = fall('08', { urteile: [...SECHS_FELDER, NEU.fktLinear, NEU.laplace] })

export const ohneName = fall('09', { firstName: null })

/** Vier genannte Punkte — vier Rückbezüge auf Seite 1. */
export const vieleRueckbezuege = fall('10', {
  weakTopics: ['Konzentration', 'Prüfungsangst', 'Zeiteinteilung', 'Rechenwege'],
})

/** Ilkays Daten; die Coach-Notizen fehlen (siehe FAELLE). */
export const ohneNotizen = fall('11', {})

/** Der Katalog konnte nicht geladen werden — kein Bogen. */
export const ohneKatalog = fall('12', { katalog: [] })
