// BEISPIELDATEN, NUR FUER TESTS (Mock, CLAUDE.md §6): Kernarbeit und Warm-up der fuenf Kinder.
// Kind im Warm-up und in der Kernarbeit (Dummy: LIVE, DET, QW, QK). Inhalte wie
// Aufgabentexte, Musterloesungen und Fehlbilder stehen fuer Datenbank-Inhalte.

import type {
  ErgebnisMarke,
  GrundLetzterSchritt,
  HeuteZeile,
  KachelMeta,
  Kernidee,
  LiveAufgabeDetail,
  LiveErklaersequenz,
  LiveEingreifen,
  LiveInfo,
  LiveSignal,
  LiveVersuch,
  Taetigkeit,
} from '@/types/coachLive'
import { uhr } from './coachLiveBeispiel'

export type BeispielLive = {
  taetigkeit: Taetigkeit
  skill: string
  ergebnisfolge: ErgebnisMarke[]
  sequenzBalken: Kernidee['stand'][] | null
  aufgabeNr: number | null
  meta: KachelMeta | null
  signale: LiveSignal[]
  aufgabe: LiveAufgabeDetail | null
  versuche: LiveVersuch[]
  hinweise: { stufe: number; text: string }[]
  erklaersequenz: LiveErklaersequenz | null
  info: LiveInfo | null
  empfohlen: LiveEingreifen['empfohlen']
  fehlbild: LiveEingreifen['fehlbild']
  heute: HeuteZeile[]
  grund: GrundLetzterSchritt | null
}

const folge = (s: string): ErgebnisMarke[] =>
  [...s].map((c) => (c === 'r' ? 'richtig' : c === 'w' ? 'falsch' : c === 'h' ? 'hinweis' : 'aktuell'))

const heute = (abschnitt: HeuteZeile['abschnitt'], h: Partial<HeuteZeile> = {}): HeuteZeile => ({
  abschnitt, skill: null, richtig: null, von: null, hinweise: null, zusatz: null, kernideen: null, zeit: null, ...h,
})

const signal = (kindId: string, art: LiveSignal['art'], grund: LiveSignal['grund'], seit: string, s: Partial<LiveSignal> = {}): LiveSignal => ({
  kindId, art, grund, seit, wert: null, skill: null, aufgabeNr: null, ...s,
})

const leer = {
  sequenzBalken: null, aufgabeNr: null, meta: null, signale: [], aufgabe: null, versuche: [], hinweise: [],
  erklaersequenz: null, info: null, empfohlen: 0, fehlbild: null, heute: [], grund: null,
} satisfies Partial<BeispielLive>

const FB_MINUS = { slug: 'minus_klammer_erster_summand', klartext: 'Vorzeichenfehler bei Minus vor der Klammer' }

export const BEISPIEL_WARMUP: Record<string, BeispielLive> = {
  mila: {
    ...leer,
    taetigkeit: { art: 'warmup', nr: 2, von: 3 },
    skill: 'Hypotenuse berechnen',
    ergebnisfolge: folge('rrn'),
    meta: { art: 'ohneHinweis', anzahl: 2 },
    signale: [signal('mila', 'kandidat', 'kandidat', uhr('16:41'), { wert: 7, skill: 'Hypotenuse berechnen' })],
    aufgabe: {
      kopf: { art: 'warmup', nr: 2, von: 3 }, skill: 'Hypotenuse',
      text: 'Ein rechtwinkliges Dreieck hat die Katheten 6 cm und 8 cm. Wie lang ist die Hypotenuse?',
      musterloesung: ['c² = 6² + 8² = 36 + 64 = 100', 'c = 10 cm'],
      letzteEingabe: { eingabe: '10 cm', ergebnis: 'richtig', nachHinweis: null }, ohneEingabeMin: null,
    },
    heute: [heute('warmup', { skill: 'Hypotenuse berechnen', richtig: 2, von: 2, hinweise: 0 })],
  },
  emir: {
    ...leer,
    taetigkeit: { art: 'warmupFertig' },
    skill: 'Minus vor der Klammer (Kl. 7)',
    ergebnisfolge: folge('wrw'),
    meta: { art: 'richtig', richtig: 1, von: 3, ueberZiel: null },
    signale: [signal('emir', 'entscheidung', 'warmup_luecke', uhr('16:40'), { wert: 1, skill: 'Minus vor der Klammer' })],
    aufgabe: {
      kopf: { art: 'warmup', nr: 3, von: 3 }, skill: 'Minus vor der Klammer',
      text: 'Löse die Klammer auf: −(3a − 2b)',
      musterloesung: ['Minus vor der Klammer ändert jedes Vorzeichen in der Klammer', '−3a + 2b'],
      letzteEingabe: { eingabe: '−3a − 2b', ergebnis: 'falsch', nachHinweis: null }, ohneEingabeMin: null,
    },
    versuche: [
      { kopf: { art: 'warmup', nr: 1 }, eingabe: '−x − 4', fehlbild: 'Nur das erste Vorzeichen geändert' },
      { kopf: { art: 'warmup', nr: 3 }, eingabe: '−3a − 2b', fehlbild: 'Nur das erste Vorzeichen geändert' },
    ],
    fehlbild: FB_MINUS,
    heute: [heute('warmup', { skill: 'Minus vor der Klammer', richtig: 1, von: 3 })],
  },
  jonas: {
    ...leer,
    taetigkeit: { art: 'warmup', nr: 2, von: 3 },
    skill: 'Proportionale Zuordnungen',
    ergebnisfolge: folge('rhn'),
    meta: { art: 'hinweise', anzahl: 1 },
    aufgabe: {
      kopf: { art: 'warmup', nr: 2, von: 3 }, skill: 'Proportionale Zuordnungen',
      text: '3 Hefte kosten 4,50 €. Was kosten 7 Hefte?',
      musterloesung: ['1 Heft kostet 4,50 € : 3 = 1,50 €', '7 Hefte kosten 7 · 1,50 € = 10,50 €'],
      letzteEingabe: { eingabe: '10,50 €', ergebnis: 'richtig', nachHinweis: 1 }, ohneEingabeMin: null,
    },
    hinweise: [{ stufe: 1, text: 'Was kostet ein Heft?' }],
    heute: [heute('warmup', { skill: 'Proportionale Zuordnungen', richtig: 2, von: 2, hinweise: 1 })],
  },
  lea: {
    ...leer,
    taetigkeit: { art: 'warmupFertig' },
    skill: 'Binomische Formeln',
    ergebnisfolge: folge('rrr'),
    meta: { art: 'richtig', richtig: 3, von: 3, ueberZiel: null },
    signale: [signal('lea', 'hinweis', 'stimmung', uhr('16:33'))],
    info: { art: 'stimmung' },
    aufgabe: {
      kopf: { art: 'warmup', nr: 3, von: 3 }, skill: 'Binomische Formeln',
      text: 'Schreibe als Summe: (x − 3)²',
      musterloesung: ['(x − 3)² = x² − 2 · 3 · x + 3²', 'x² − 6x + 9'],
      letzteEingabe: { eingabe: 'x² − 6x + 9', ergebnis: 'richtig', nachHinweis: null }, ohneEingabeMin: null,
    },
    heute: [heute('warmup', { skill: 'Binomische Formeln', richtig: 3, von: 3 })],
  },
  deniz: {
    ...leer,
    taetigkeit: { art: 'checkin' },
    skill: '',
    ergebnisfolge: [],
    meta: { art: 'lsaWarmup' },
    info: { art: 'spaet', ankunft: uhr('16:36') },
    heute: [heute('ankommen', { zeit: uhr('16:36') })],
  },
}

export const BEISPIEL_KERN: Record<string, BeispielLive> = {
  mila: {
    ...leer,
    taetigkeit: { art: 'ueben' },
    skill: 'Kathete berechnen',
    ergebnisfolge: folge('rrhrrn'),
    aufgabeNr: 6,
    meta: { art: 'richtig', richtig: 5, von: 5, ueberZiel: 0.8 },
    signale: [signal('mila', 'kandidat', 'kandidat', uhr('16:42'), { wert: 7, skill: 'Hypotenuse berechnen' })],
    aufgabe: {
      kopf: { art: 'aufgabe', nr: 6 }, skill: 'Kathete berechnen',
      text: 'Ein Rechteck ist 12 cm lang, seine Diagonale misst 13 cm. Wie breit ist es?',
      musterloesung: ['Die Diagonale ist die Hypotenuse: 13² = 12² + b²', 'b² = 169 − 144 = 25', 'b = 5 cm'],
      letzteEingabe: null, ohneEingabeMin: null,
    },
    grund: { art: 'ueberQuote', quote: 0.8, richtig: 5, von: 5 },
    heute: [
      heute('warmup', { skill: 'Hypotenuse berechnen', richtig: 2, von: 2, hinweise: 0 }),
      heute('kern', { skill: 'Kathete berechnen', richtig: 4, von: 4, hinweise: 1 }),
      heute('eingemischt', { skill: 'Lineare Gleichungen (Kl. 8)', richtig: 1, von: 1, zusatz: 'mischanteil' }),
    ],
  },
  emir: {
    ...leer,
    taetigkeit: { art: 'ueben' },
    skill: 'Klammern ausmultiplizieren',
    ergebnisfolge: folge('rhwwn'),
    aufgabeNr: 5,
    meta: { art: 'hinweise', anzahl: 2 },
    signale: [signal('emir', 'haengt', 'fehlversuche', uhr('17:01'), { wert: 2, aufgabeNr: 5 })],
    aufgabe: {
      kopf: { art: 'aufgabe', nr: 5 }, skill: 'Klammern ausmultiplizieren',
      text: 'Multipliziere aus: −3(2x − 5)',
      musterloesung: ['−3 · 2x = −6x', '−3 · (−5) = +15', 'Ergebnis: −6x + 15'],
      letzteEingabe: { eingabe: '6x + 15', ergebnis: 'falsch', nachHinweis: null }, ohneEingabeMin: null,
    },
    versuche: [
      { kopf: { art: 'versuch', nr: 1 }, eingabe: '−6x − 15', fehlbild: 'Minus nur auf den ersten Summanden angewendet' },
      { kopf: { art: 'versuch', nr: 2 }, eingabe: '6x + 15', fehlbild: 'Vorzeichen des Faktors verloren' },
    ],
    hinweise: [
      { stufe: 1, text: 'Womit multiplizierst du jeden Summanden in der Klammer?' },
      { stufe: 2, text: 'Rechne zuerst −3 · 2x. Was ergibt dann −3 · (−5)?' },
    ],
    empfohlen: 2,
    fehlbild: FB_MINUS,
    heute: [
      heute('warmup', { skill: 'Minus vor der Klammer', richtig: 1, von: 3 }),
      heute('kern', { skill: 'Klammern ausmultiplizieren', richtig: 2, von: 4 }),
    ],
  },
  jonas: {
    ...leer,
    taetigkeit: { art: 'erklaerung', kernidee: 2, von: 3 },
    skill: 'Steigung aus dem Graphen',
    ergebnisfolge: [],
    sequenzBalken: ['sicher', 'laeuft', 'offen'],
    meta: { art: 'extrarunde', variante: 'B' },
    erklaersequenz: {
      kernideen: [
        { text: 'Steigung: wie viel es pro Schritt nach rechts hoch- oder runtergeht', stand: 'sicher', runde: 1, fehlbild: null, variante: null },
        { text: 'Steigungsdreieck: Δy durch Δx', stand: 'laeuft', runde: 2, fehlbild: 'Δx und Δy vertauscht', variante: 'B' },
        { text: 'Negative Steigung: Der Graph fällt', stand: 'offen', runde: 0, fehlbild: null, variante: null },
      ],
      aktuell: 2,
      variante: 'B · Treppenbild',
      siehtGerade:
        'Geh vom linken Punkt nach rechts, bis du unter dem rechten Punkt stehst. Das ist Δx. Dann geh hoch bis zum Punkt. Das ist Δy. Die Steigung ist Δy geteilt durch Δx.',
    },
    aufgabe: {
      kopf: { art: 'check', kernidee: 2, runde: 2 }, skill: 'Steigung aus dem Graphen',
      text: 'Die Gerade geht durch (0|1) und (4|3). Bestimme die Steigung mit dem Steigungsdreieck.',
      musterloesung: ['Δx = 4 − 0 = 4', 'Δy = 3 − 1 = 2', 'm = Δy : Δx = 2 : 4 = 0,5'],
      letzteEingabe: null, ohneEingabeMin: null,
    },
    versuche: [{ kopf: { art: 'runde', nr: 1 }, eingabe: '2', fehlbild: 'Δx und Δy vertauscht (4 : 2 statt 2 : 4)' }],
    fehlbild: { slug: 'steigung_dx_dy_vertauscht', klartext: 'Δx und Δy vertauscht' },
    heute: [
      heute('warmup', { skill: 'Proportionale Zuordnungen', richtig: 2, von: 3, hinweise: 1 }),
      heute('erklaerung', { kernideen: { sicher: 1, aktuell: 2, runde: 2 } }),
    ],
  },
  lea: {
    ...leer,
    taetigkeit: { art: 'ueben' },
    skill: 'p-q-Formel anwenden',
    ergebnisfolge: folge('rrwrrrn'),
    aufgabeNr: 7,
    meta: { art: 'pausiert' },
    info: { art: 'klassenarbeit', datum: '2026-10-08', tage: 2 },
    aufgabe: {
      kopf: { art: 'aufgabe', nr: 7 }, skill: 'p-q-Formel',
      text: 'Löse: x² + 4x − 12 = 0',
      musterloesung: ['p = 4, q = −12', 'x = −2 ± √(4 + 12) = −2 ± 4', 'x₁ = 2, x₂ = −6'],
      letzteEingabe: null, ohneEingabeMin: null,
    },
    heute: [
      heute('warmup', { skill: 'Binomische Formeln', richtig: 3, von: 3 }),
      heute('kern', { skill: 'p-q-Formel', richtig: 5, von: 6 }),
    ],
  },
  deniz: {
    ...leer,
    taetigkeit: { art: 'ueben' },
    skill: 'Grundwert berechnen',
    ergebnisfolge: folge('rwn'),
    aufgabeNr: 3,
    meta: { art: 'hinweise', anzahl: 0 },
    signale: [signal('deniz', 'haengt', 'ohne_eingabe', uhr('17:01'), { wert: 4, aufgabeNr: 3 })],
    aufgabe: {
      kopf: { art: 'aufgabe', nr: 3 }, skill: 'Grundwert berechnen',
      text: '30 % eines Betrags sind 12 €. Wie groß ist der ganze Betrag?',
      musterloesung: ['12 € entsprechen 30 %', '1 % sind 12 € : 30 = 0,40 €', '100 % sind 40 €'],
      letzteEingabe: null, ohneEingabeMin: 4,
    },
    versuche: [{ kopf: { art: 'aufgabe', nr: 2 }, eingabe: '3,60 €', fehlbild: 'Prozentwert statt Grundwert gerechnet (30 % von 12 €)' }],
    empfohlen: 1,
    fehlbild: { slug: 'prozentwert_statt_grundwert', klartext: 'Prozentwert statt Grundwert gerechnet' },
    heute: [
      heute('warmup', { skill: 'Prozentwert', richtig: 3, von: 3, zusatz: 'lsaSicher' }),
      heute('kern', { skill: 'Grundwert', richtig: 1, von: 2 }),
    ],
  },
}

/** Emir nach „eine Stufe tiefer“ (Warm-up-Entscheidung oder Stufe 4). */
export const BEISPIEL_KERN_TIEFER: Record<string, BeispielLive> = {
  emir: {
    ...leer,
    taetigkeit: { art: 'tiefer' },
    skill: 'Minus vor der Klammer (Kl. 7)',
    ergebnisfolge: folge('wrrn'),
    aufgabeNr: 4,
    meta: { art: 'pfadTiefer', von: 'Sara' },
    aufgabe: {
      kopf: { art: 'aufgabe', nr: 4 }, skill: 'Minus vor der Klammer',
      text: 'Löse die Klammer auf: −(4x − 7)',
      musterloesung: ['Minus vor der Klammer ändert jedes Vorzeichen in der Klammer', '−4x + 7'],
      letzteEingabe: null, ohneEingabeMin: null,
    },
    versuche: [{ kopf: { art: 'aufgabe', nr: 1 }, eingabe: '−2x − 5', fehlbild: 'Nur das erste Vorzeichen geändert' }],
    fehlbild: FB_MINUS,
    heute: [
      heute('warmup', { skill: 'Minus vor der Klammer', richtig: 1, von: 3 }),
      heute('kern', { skill: 'Minus vor der Klammer', richtig: 2, von: 3, zusatz: 'tiefer' }),
    ],
  },
}
