// Bericht v4 — die echte Analyse des Testlaufs vom 24.10.2026 (Klasse 9, Thema Reelle Zahlen,
// FWG-Plan), als Fixture festgeschrieben (Bauauftrag V4, V4-1 Entscheidung 7). dbread nur lesend:
//   lsa_skill_urteil (belegt_direkt), skills, result_summary.themenraum, lsa_fehlbild_auswertung,
//   leads (Erstgespräch). Ersetzt: Sitzungs-ID durch einen Platzhalter, der Rufname ist der des
//   Musters (keine echten Namen im Repo). Graph wie Prod plus die zwei Kanten aus der Migration
//   20261024143626_graph_wurzel_faktorisieren. Nur von Tests und der Vorschau importiert.

import { datenAus, u } from '@/lib/report/elternbericht/fixtures/basis'
import { HEIMAT, KANTEN } from '@/lib/report/elternbericht/fixtures/graph'
import { ILKAY_ROH } from '@/lib/report/elternbericht/fixtures/ilkay'
import { FWG_NAME, FWG_PLAN } from '@/lib/report/elternbericht/fixtures/plaene'
import { schulPlan } from '@/lib/report/elternbericht/plan'
import type { KlassenarbeitStatus, ReportData, ReportFehlbild, ReportKlassenarbeit, SucheSkill } from '@/types'

/** Die 23 direkten Urteile (lsa_skill_urteil, belegt_direkt). */
export const URTEILE: readonly SucheSkill[] = [
  u('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 3, 5, 'traegt', 1, false),
  u('geo_umfang', 'Umfang von Rechteck und Dreieck', 3, 5, 'traegt', 1, false),
  u('groessen_laengen', 'Längen umrechnen', 3, 5, 'traegt', 1, false),
  u('geo_koordinaten', 'Punkte im Koordinatensystem', 2, 6, 'traegt', 1, false),
  u('groessen_flaechen', 'Flächeneinheiten', 5, 6, 'traegt_nicht', 2, false),
  u('geo_flaeche_dreieck', 'Fläche von Dreieck und Parallelogramm', 4, 7, 'traegt_teilweise', 2, false),
  u('proportionalitaet', 'Dreisatz, proportional und antiproportional', 4, 7, 'traegt', 1, false),
  u('term_einsetzen', 'Werte in Terme einsetzen', 5, 7, 'traegt_teilweise', 2, false),
  u('geo_flaeche_drachen_raute', 'Flächeninhalt von Drachen und Raute', 5, 8, 'traegt_nicht', 2, false),
  u('geo_flaeche_term', 'Terme für Flächeninhalte', 6, 8, 'traegt', 2, false),
  u('geo_flaeche_trapez', 'Flächeninhalt des Trapezes', 5, 8, 'nicht_angesetzt', 1, false),
  u('geo_winkel_thales', 'Satz des Thales (Winkel berechnen)', 5, 8, 'traegt', 1, false),
  u('gleichung_lgs_addition', 'Additionsverfahren', 8, 8, 'traegt_nicht', 2, false),
  u('gleichung_lgs_einsetzen', 'Einsetzungsverfahren', 7, 8, 'traegt', 1, false),
  u('gleichung_lgs_grafisch', 'LGS grafisch lösen (Schnittpunkt)', 8, 8, 'traegt_teilweise', 2, false),
  u('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)', 8, 8, 'traegt', 1, false),
  u('stoch_pfad_summe', 'Mehrstufige Zufallsexperimente: Summenregel', 7, 8, 'traegt_nicht', 2, false),
  u('term_binom_faktorisieren', 'Faktorisieren mit binomischer Formel', 8, 8, 'traegt_nicht', 2, false),
  u('term_binom_quadrat', 'Binomische Formeln (Quadrat einer Summe/Differenz)', 7, 8, 'traegt_teilweise', 2, false),
  u('zahl_wurzel_gesetze', 'Wurzelgesetze für Produkt und Quotient', 6, 9, 'traegt', 1, false),
  u('zahl_wurzel_irrational', 'Rationale und irrationale Zahlen', 6, 9, 'traegt', 1, false),
  u('zahl_wurzel_naeherung', 'Wurzeln abschätzen und Näherungswerte', 6, 9, 'traegt', 1, false),
  u('zahl_wurzel_teilweise', 'Teilweise die Wurzel ziehen', 7, 9, 'traegt_nicht', 2, false),
]

/** lsa_fehlbild_auswertung: je Slug eine Beobachtung. */
const FEHLBILDER: ReportFehlbild[] = [
  {
    slug: 'einheit_uebersprungen',
    familie: 'einheiten_massstab',
    familieElterntext: 'Ihr Kind erkennt, was gefragt ist, rechnet beim Umrechnen aber mit dem falschen Faktor, in die falsche Richtung oder gar nicht um.',
    anzahl: 1, aufgaben: 1, skills: ['groessen_flaechen'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'linearer_faktor',
    familie: 'einheiten_massstab',
    familieElterntext: 'Ihr Kind erkennt, was gefragt ist, rechnet beim Umrechnen aber mit dem falschen Faktor, in die falsche Richtung oder gar nicht um.',
    anzahl: 1, aufgaben: 1, skills: ['groessen_flaechen'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'falsche_hoehe',
    familie: 'figuren',
    familieElterntext: 'Ihr Kind geht bei Figuren den richtigen Weg, setzt aber eine falsche Strecke oder einen falschen Winkel ein oder lässt einen Teil der Figur weg, etwa die schräge Seite statt der Höhe.',
    anzahl: 1, aufgaben: 1, skills: ['geo_flaeche_dreieck'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'parallele_uebersehen',
    familie: 'geraden_schaubilder',
    familieElterntext: 'Ihr Kind arbeitet mit Geraden und Schaubildern, verwechselt dabei aber, welche Zahl wofür steht, etwa den Wert nach rechts mit dem nach oben, oder erkennt nicht richtig, ob und wo sich zwei Geraden schneiden.',
    anzahl: 1, aufgaben: 1, skills: ['gleichung_lgs_addition'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'faktor_ohne_wurzel',
    familie: 'potenzen_wurzeln',
    familieElterntext: 'Ihr Kind rechnet bei Hochzahlen und Wurzeln nach einer Regel, die dort nicht gilt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36, oder ordnet eine Zahl falsch ein, etwa √49 als Zahl, die sich nicht genau angeben lässt.',
    anzahl: 1, aufgaben: 1, skills: ['zahl_wurzel_teilweise'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'pfadregel_addiert',
    familie: 'rechenart_formel',
    familieElterntext: 'Ihr Kind rechnet sauber, nimmt aber eine andere Rechenart oder Formel, als die Aufgabe verlangt, etwa Plus statt Mal oder den Umfang statt der Fläche.',
    anzahl: 1, aufgaben: 1, skills: ['stoch_pfad_summe'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'faktorisierung_unvollstaendig',
    familie: 'schritt_vergessen',
    familieElterntext: 'Ihr Kind geht den richtigen Rechenweg, lässt aber einen Teil davon weg oder hört zu früh auf, etwa wenn es beim Dreieck das Halbieren vergisst oder einen Bruch nicht bis zum Ende kürzt.',
    anzahl: 1, aufgaben: 1, skills: ['term_binom_faktorisieren'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'halbieren_vergessen',
    familie: 'schritt_vergessen',
    familieElterntext: 'Ihr Kind geht den richtigen Rechenweg, lässt aber einen Teil davon weg oder hört zu früh auf, etwa wenn es beim Dreieck das Halbieren vergisst oder einen Bruch nicht bis zum Ende kürzt.',
    anzahl: 1, aufgaben: 1, skills: ['geo_flaeche_drachen_raute'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'falsches_vorzeichen_beim_zusammenfuehren',
    familie: 'vorzeichen',
    familieElterntext: 'Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.',
    anzahl: 1, aufgaben: 1, skills: ['term_binom_quadrat'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'koordinate_vorzeichen_verloren',
    familie: 'vorzeichen',
    familieElterntext: 'Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.',
    anzahl: 1, aufgaben: 1, skills: ['gleichung_lgs_grafisch'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
  {
    slug: 'vorzeichen_ignoriert',
    familie: 'vorzeichen',
    familieElterntext: 'Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.',
    anzahl: 1, aufgaben: 1, skills: ['term_einsetzen'],
    skillUebergreifend: false, einstufung: 'beobachtung',
  },
]

/** Abgeleitete Urteile (belegt_direkt = false), nur Schlüssel. */
const ABGELEITET = ['bruch_dezimal', 'bruch_kuerzen', 'dezimal_add_sub', 'dezimal_div', 'dezimal_mult', 'geo_winkel_dreieck', 'geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_summe', 'gleichung_beidseitig', 'gleichung_einschrittig', 'gleichung_zweischrittig', 'potenzen', 'runden_ueberschlag', 'term_ausmultiplizieren', 'term_minusklammer', 'term_zusammenfassen', 'vorzeichen_add_sub', 'vorzeichen_mult_div', 'vorzeichen_vorrang', 'zahl_wurzel_quadrat']

/** Die zwei Kanten aus der Migration 20261024143626 (Stand nach dem Einspielen). */
const KANTEN_V4 = [
  ...KANTEN,
  { skillKey: 'geo_pythagoras_anwendung', voraussetzt: 'zahl_wurzel_teilweise' },
  { skillKey: 'fkt_quadr_nullstellen', voraussetzt: 'term_binom_faktorisieren' },
]

const RAUM = {
  themaKey: 'reelle_zahlen',
  einstieg: ['zahl_wurzel_irrational', 'zahl_wurzel_naeherung', 'zahl_wurzel_teilweise'],
  darunter: ['bruch_dezimal', 'bruch_kuerzen', 'dezimal_add_sub', 'dezimal_div', 'dezimal_mult', 'potenzen', 'runden_ueberschlag', 'vorzeichen_add_sub', 'vorzeichen_mult_div', 'zahl_wurzel_gesetze', 'zahl_wurzel_quadrat'],
  herkunft: 'abschluss',
} as const

/**
 * Die Analyse mit einem Stand der Klassenarbeit und ggf. der Note der letzten Arbeit.
 * `id` = die letzten drei Ziffern der Platzhalter-Sitzung (je Fall eigene).
 * Das Testlauf-Kennzeichen bleibt aus (nur der Fall `testlauf` hat es).
 */
export function batuMit(
  klassenarbeit: KlassenarbeitStatus | null,
  letzteNote: number | null = null,
  id = '441',
  klassenarbeiten: ReportKlassenarbeit[] = [],
): ReportData {
  const data = datenAus({
    ...ILKAY_ROH,
    sessionId: `00000000-0000-4000-8000-000000000${id}`,
    grade: 9,
    analysedAt: '2026-10-24T11:07:58.091Z',
    aufgaben: 34,
    testlauf: false,
    schulform: 'Gymnasium',
    naechstesThema: null,
    weakTopics: ['Grundlagen fehlen'],
    urteile: URTEILE,
    fehlbilder: FEHLBILDER,
    themaLabel: 'Reelle Zahlen und Wurzeln',
    raum: { ...RAUM, einstieg: [...RAUM.einstieg], darunter: [...RAUM.darunter] },
    modus: 'adaptiv',
    abgeleitet: ABGELEITET,
    kanten: KANTEN_V4,
    heimatThemen: HEIMAT,
    plan: schulPlan(FWG_PLAN, 9, FWG_NAME),
  })
  return {
    ...data,
    // Summe der Antwortzeiten der Sitzung (dbread): rund 23 Minuten.
    dauerMinuten: 23,
    erstgespraech: {
      note: '4',
      trend: 'stabil',
      seit: 'laenger',
      ziele: null,
      klassenarbeit,
      klassenarbeitDatum: null,
      letzteNote,
      klassenarbeiten,
    },
  }
}

export const batuV4 = batuMit('geschrieben')
export const batuBevorstehend = batuMit('bevorstehend', null, '443')
export const batuOhneStatus = batuMit(null, null, '444')
export const batuMitNote = batuMit('geschrieben', 4, '445')

/**
 * L5 (Bauauftrag L5, Schritt 1): dieselbe Analyse mit bekannter Folge. NUR TESTDATEN — die Zuordnung ist erfunden
 * und gilt für keine echte Schule (auch nicht das FWG): Arbeit 1 = Reelle Zahlen (geschrieben), 2 = Quadratische
 * Funktionen, 3 = Kreise + Potenzen, 4 = Pythagoras + Daten.
 */
const ka = (
  nr: number,
  themaKeys: string[],
  herkunft: ReportKlassenarbeit['herkunft'],
  datum: string | null = null,
): ReportKlassenarbeit => ({
  nr,
  themaKeys,
  datum,
  status: nr === 1 && herkunft === 'eigen' ? 'geschrieben' : null,
  note: null,
  herkunft,
})

/** Eigene Angaben: vier Arbeiten mit Nummer. */
export const batuEigen = batuMit('geschrieben', null, '451', [
  ka(1, ['reelle_zahlen'], 'eigen', '2026-10-01'),
  ka(2, ['quadratische_funktionen'], 'eigen', '2026-11-26'),
  ka(3, ['kreis', 'potenzen'], 'eigen'),
  ka(4, ['pythagoras', 'bedingte_wahrscheinlichkeit'], 'eigen'),
])

/** Schulwert (zwei Kinder derselben Klasse stimmen überein), keine eigenen Angaben mit Nummer. */
export const batuSchule = batuMit('geschrieben', null, '452', [
  ka(1, ['reelle_zahlen'], 'schule'),
  ka(2, ['quadratische_funktionen'], 'schule'),
  ka(3, ['kreis', 'potenzen'], 'schule'),
  ka(4, ['pythagoras', 'bedingte_wahrscheinlichkeit'], 'schule'),
])
