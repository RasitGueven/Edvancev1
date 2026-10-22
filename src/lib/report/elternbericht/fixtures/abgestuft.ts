// Abgestufte LSAs mit Thema für den Eltern-Bericht R7 (R7-6): Seite 1 nennt,
// wie das Thema abgedeckt ist. Nur von Tests und der Vorschau importiert.
//
// Synthetisch, aber in der Form zweier echter Sitzungen (dbread, 20.10.2026):
// Urteile, Zustände und abgeleitete Schlüssel wörtlich aus lsa_skill_urteil,
// Label, Tiefe und klasse_herkunft aus skills, der Raum aus result_summary
// (beim Abschluss gespeichert). Ersetzt: Sitzungs-IDs durch Platzhalter, der
// Rufname bleibt der des Musters. Ein direktes Urteil nicht_angesetzt ist
// weggelassen (Befund: 12 direkt).

import { datenAus, u, type SitzungRoh } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH } from '@/lib/report/elternbericht/fixtures/ilkay'
import { FWG_NAME, FWG_PLAN } from '@/lib/report/elternbericht/fixtures/plaene'
import { schulPlan } from '@/lib/report/elternbericht/plan'
import { themenraumFuer } from '@/lib/report/themenraum'
import type { ReportData, SucheSkill } from '@/types'

/** Themenraum „Reelle Zahlen“: 3 Einstiege, 11 darunter. */
const RAUM = themenraumFuer({
  themaKey: 'reelle_zahlen',
  gespeichert: {
    stand: '2026-10-18T13:53:32.507171+00:00',
    thema_key: 'reelle_zahlen',
    einstieg: ['zahl_wurzel_irrational', 'zahl_wurzel_naeherung', 'zahl_wurzel_teilweise'],
    darunter: [
      'bruch_dezimal',
      'bruch_kuerzen',
      'dezimal_add_sub',
      'dezimal_div',
      'dezimal_mult',
      'potenzen',
      'runden_ueberschlag',
      'vorzeichen_add_sub',
      'vorzeichen_mult_div',
      'zahl_wurzel_gesetze',
      'zahl_wurzel_quadrat',
    ],
  },
  einstieg: [],
  kanten: [],
})

/** Eine Sitzung wie Batu (Klasse 9, Thema Reelle Zahlen, FWG-Plan); auch für die Fälle aus R7-11. */
export const fall = (id: string, aenderung: Partial<SitzungRoh>): ReportData =>
  datenAus({
    ...ILKAY_ROH,
    sessionId: `00000000-0000-4000-8000-0000000000${id}`,
    grade: 9,
    aufgaben: 24,
    naechstesThema: null,
    themaLabel: 'Reelle Zahlen',
    raum: RAUM,
    modus: 'adaptiv',
    // R7-9: Schule über den Lead (Befund 20.10.2026), FWG-Plan Klasse 9 und 10.
    plan: schulPlan(FWG_PLAN, 9, FWG_NAME),
    ...aenderung,
  })

/** Die zwölf direkten Urteile von 6220b7e8 (Batu). */
export const ABGESTUFT_URTEILE: readonly SucheSkill[] = [
  u('bruch_dezimal', 'Bruch in Dezimalzahl', 4, 6, 'traegt', 1, false),
  u('geo_flaeche_drachen_raute', 'Flächeninhalt von Drachen und Raute', 5, 8, 'traegt_nicht', 2, false),
  u('geo_flaeche_term', 'Terme für Flächeninhalte', 6, 8, 'traegt_teilweise', 2, false),
  u('geo_winkel_thales', 'Satz des Thales (Winkel berechnen)', 5, 8, 'traegt_nicht', 2, false),
  u('gleichung_lgs_addition', 'Additionsverfahren', 8, 8, 'traegt_nicht', 2, false),
  u('gleichung_lgs_einsetzen', 'Einsetzungsverfahren', 7, 8, 'traegt', 1, false),
  u('gleichung_lgs_grafisch', 'LGS grafisch lösen (Schnittpunkt)', 8, 8, 'traegt', 1, false),
  u('stoch_pfad_summe', 'Mehrstufige Zufallsexperimente: Summenregel', 7, 8, 'traegt_nicht', 2, false),
  u('zahl_wurzel_gesetze', 'Wurzelgesetze für Produkt und Quotient', 6, 9, 'traegt_teilweise', 2, false),
  u('zahl_wurzel_irrational', 'Rationale und irrationale Zahlen', 6, 9, 'traegt_nicht', 2, false),
  u('zahl_wurzel_naeherung', 'Wurzeln abschätzen und Näherungswerte', 6, 9, 'traegt', 1, false),
  u('zahl_wurzel_teilweise', 'Teilweise die Wurzel ziehen', 7, 9, 'traegt_nicht', 2, false),
]

/** Wie 6220b7e8: 5 direkt im Raum, 7 außerhalb, 9 abgeleitet im Raum, offen 0. */
export const abgestuft = fall('30', {
  analysedAt: '2026-10-18T14:05:00.000Z',
  urteile: ABGESTUFT_URTEILE,
  abgeleitet: [
    // im Raum (9)
    'bruch_kuerzen',
    'dezimal_add_sub',
    'dezimal_div',
    'dezimal_mult',
    'potenzen',
    'runden_ueberschlag',
    'vorzeichen_add_sub',
    'vorzeichen_mult_div',
    'zahl_wurzel_quadrat',
    // außerhalb (12) — zählen nicht
    'fkt_linear_graph',
    'fkt_linear_steigung',
    'fkt_linear_yabschnitt',
    'geo_koordinaten',
    'gleichung_einschrittig',
    'gleichung_zweischrittig',
    'proportionalitaet',
    'term_ausmultiplizieren',
    'term_einsetzen',
    'term_minusklammer',
    'term_zusammenfassen',
    'vorzeichen_vorrang',
  ],
})

/** Wie 09cf8baa: 6 direkt im Raum, 5 abgeleitet, 3 offen. */
export const abgestuftMitOffen = fall('31', {
  analysedAt: '2026-10-12T07:30:00.000Z',
  urteile: [
    u('runden_ueberschlag', 'Runden und Überschlag', 2, 5, 'traegt_nicht', 2, false),
    u('zahl_wurzel_gesetze', 'Wurzelgesetze für Produkt und Quotient', 6, 9, 'traegt_teilweise', 2, false),
    u('zahl_wurzel_irrational', 'Rationale und irrationale Zahlen', 6, 9, 'traegt_teilweise', 2, false),
    u('zahl_wurzel_naeherung', 'Wurzeln abschätzen und Näherungswerte', 6, 9, 'traegt_nicht', 2, false),
    u('zahl_wurzel_quadrat', 'Quadratwurzel als Umkehrung des Quadrierens', 5, 9, 'traegt', 1, false),
    u('zahl_wurzel_teilweise', 'Teilweise die Wurzel ziehen', 7, 9, 'traegt_nicht', 2, false),
  ],
  abgeleitet: ['dezimal_add_sub', 'dezimal_mult', 'potenzen', 'vorzeichen_add_sub', 'vorzeichen_mult_div'],
})

/** 12 direkt geprüfte und 14 abgeleitete Bereiche in einem Feld (Zahlen & Rechnen). */
const LANG_DIREKT = Array.from({ length: 12 }, (_, i) => `zahl_r7_8_d${i + 1}`)
const LANG_ABGELEITET = Array.from({ length: 14 }, (_, i) => `zahl_r7_8_a${i + 1}`)

/**
 * Synthetisch (R7-8): der längste rechte Text auf Seite 2, „12 geprüft · 14
 * abgeleitet“, in der längsten Zeile (26 Kästchen). Prüft, dass die Spur mit
 * abgeleiteten Bereichen (206 pt) vor dem Text endet.
 */
export const abgestuftLang = fall('32', {
  analysedAt: '2026-10-20T09:00:00.000Z',
  raum: themenraumFuer({
    themaKey: 'reelle_zahlen',
    gespeichert: {
      stand: '2026-10-20T08:55:00.000+00:00',
      thema_key: 'reelle_zahlen',
      einstieg: LANG_DIREKT,
      darunter: LANG_ABGELEITET,
    },
    einstieg: [],
    kanten: [],
  }),
  urteile: LANG_DIREKT.map((k, i) =>
    u(k, `Zahlbereich ${i + 1}`, 3, 5 + (i % 5), i % 3 === 0 ? 'traegt' : 'traegt_nicht', 2, false),
  ),
  abgeleitet: LANG_ABGELEITET,
})
