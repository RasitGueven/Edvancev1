// BEISPIELDATEN (Mock, CLAUDE.md §6) der Coach-Live-Sicht: die fuenf Kinder aus
// docs/session/coach-live-dummy.html, ausserhalb der Arbeitsphasen. Alle Texte
// hier stehen fuer Datenbank-Inhalte (Namen, Skill-Labels, Notizen, Bausteine)
// und gehoeren deshalb nicht in i18n. Nur ueber src/lib/session/coachLive.ts lesen.

import type {
  BlickPunkt,
  LiveBriefing,
  LiveCheckin,
  LiveCheckout,
  LiveMasteryKandidat,
  LiveZeitpunkt,
  PfadVorschlag,
  ZielZeile,
} from '@/types/coachLive'
import type { SessionFall, StellschraubeWert } from '@/types/sessionLive'
import type { Stufe, Thema } from '@/types/themen'

/** Uhrzeit am Sessiontag (06.10.2026, Berlin = UTC+2) als ISO. */
export const uhr = (hm: string, tag = 6): string => {
  const [h, m] = hm.split(':').map(Number)
  return new Date(Date.UTC(2026, 9, tag, h - 2, m)).toISOString()
}

export const BEISPIEL_SESSION = {
  beginn: uhr('16:30'),
  raum: 'Raum 1',
  coachName: 'Sara Özdemir',
  coachVorname: 'Sara',
  fach: 'Mathematik',
  klassen: [8, 10] as [number, number],
  plaetze: 5,
}

/** Uhrzeit je Zeitpunkt (Dummy: STEPS). */
export const BEISPIEL_ZEIT: Record<LiveZeitpunkt, string> = {
  vorher: uhr('16:20'),
  checkin: uhr('16:32'),
  warmup: uhr('16:41'),
  kern: uhr('17:02'),
  checkout: uhr('17:27'),
  danach: uhr('17:34'),
}

/** Snapshot der Stellschrauben beim Start (Startwerte aus dem Bauauftrag). */
export const BEISPIEL_EINSTELLUNGEN: Record<string, StellschraubeWert> = {
  phase_checkin_min: 5,
  phase_warmup_min: 10,
  phase_checkout_min: 5,
  warmup_aufgaben: 3,
  warmup_leichter_stufen: 1,
  ziel_erfolgsquote: 0.8,
  mischanteil: 0.3,
  ka_tage: 7,
  hinweisstufen: 3,
  signal_fehlversuche: 2,
  signal_minuten_ohne_fortschritt: 3,
  mikro_erklaerung_min: 2,
  kernideen_max: 3,
  check_aufgaben_je_kernidee: 1,
  erklaerrunden_bis_signal: 2,
  erklaerung_bei_neuem_skill: 'vorgeschaltet',
  loesungsbeispiele_vor_aufgabe: 1,
  erklaerung_anbieten_nach_fehlversuchen: 2,
  mastery_abstand_sessions: 1,
  mastery_richtig_ohne_hinweis: 2,
  mastery_kandidaten_je_raum: 3,
  exit_aufgaben: 2,
  thema_alt_tage: 21,
  quests_pro_woche: 2,
  quest_minuten: 10,
  quest_a_abstand_tage: 2,
  quest_xp: 50,
  home_quests_aktiv: false,
}

export type BeispielKindBasis = { id: string; name: string; vorname: string; klasse: number; stufe: Stufe }

export const BEISPIEL_KINDER: BeispielKindBasis[] = [
  { id: 'mila', name: 'Mila Krämer', vorname: 'Mila', klasse: 9, stufe: 'zweite' },
  { id: 'emir', name: 'Emir Şahin', vorname: 'Emir', klasse: 8, stufe: 'erste' },
  { id: 'jonas', name: 'Jonas Vogt', vorname: 'Jonas', klasse: 8, stufe: 'erste' },
  { id: 'lea', name: 'Lea Schulz', vorname: 'Lea', klasse: 10, stufe: 'zweite' },
  { id: 'deniz', name: 'Deniz Arslan', vorname: 'Deniz', klasse: 9, stufe: 'zweite' },
]

/** Tablets ab dem Warm-up (Dummy: DEFSEAT); im Check-in sitzen erst drei. */
export const BEISPIEL_TABLET: Record<string, number> = { mila: 1, emir: 2, jonas: 3, lea: 4, deniz: 5 }
export const BEISPIEL_TABLET_CHECKIN: Record<string, number | null> = { mila: 1, emir: 2, jonas: 3, lea: null, deniz: null }
/** Ankunft = Tablet-Zuweisung. */
export const BEISPIEL_ANKUNFT: Record<string, string> = {
  mila: uhr('16:27'), emir: uhr('16:28'), jonas: uhr('16:29'), lea: uhr('16:33'), deniz: uhr('16:36'),
}

const thema = (thema_key: string, stufe: Stufe, sort: number, label: string, schlagworte: string[]): Thema => ({
  thema_key, fach: 'mathematik', stufe, sort, label, schlagworte,
})

/** Themenkatalog wie in der Suche des Erstgespraechs (Dummy: THEMEN). */
export const BEISPIEL_KATALOG: Thema[] = [
  thema('terme', 'erste', 10, 'Terme und Gleichungen', ['klammer', 'ausmultiplizieren', 'ausklammern', 'term', 'vereinfachen']),
  thema('linfkt', 'erste', 20, 'Lineare Funktionen', ['steigung', 'gerade', 'funktion', 'achsenabschnitt', 'graph']),
  thema('lgs', 'erste', 30, 'Lineare Gleichungssysteme', ['gleichungssystem', 'einsetzungsverfahren', 'additionsverfahren']),
  thema('prozent', 'erste', 40, 'Prozent- und Zinsrechnung', ['prozent', 'zinsen', 'grundwert', 'prozentsatz', 'rabatt']),
  thema('propzu', 'erste', 50, 'Proportionale Zuordnungen', ['dreisatz', 'proportional', 'antiproportional', 'zuordnung']),
  thema('pyth', 'zweite', 60, 'Satz des Pythagoras', ['pythagoras', 'hypotenuse', 'kathete', 'rechtwinklig']),
  thema('kreis', 'zweite', 70, 'Kreis: Umfang und Fläche', ['pi', 'kreis', 'radius', 'durchmesser', 'umfang']),
  thema('koerper', 'zweite', 80, 'Zylinder, Kegel und Kugel', ['pi', 'zylinder', 'kegel', 'kugel', 'volumen']),
  thema('quad', 'zweite', 90, 'Quadratische Gleichungen', ['p-q-formel', 'pq', 'quadratisch', 'nullstelle']),
  thema('parabel', 'zweite', 100, 'Quadratische Funktionen', ['parabel', 'scheitelpunkt']),
  thema('trigo', 'zweite', 110, 'Trigonometrie', ['sinus', 'cosinus', 'tangens', 'winkel', 'pi', 'bogenmaß']),
]

export const themaLabel = (key: string | null): string | null =>
  key === null ? null : (BEISPIEL_KATALOG.find((t) => t.thema_key === key)?.label ?? null)

/** Check-in am Tablet. Deniz kommt spaeter und ist erst ab der Kernarbeit fertig. */
export const BEISPIEL_CHECKIN: Record<string, LiveCheckin> = {
  mila: { fertig: true, stimmung: 'gut', klassenarbeit: null, themaAntwort: 'noch_dran', stichwort: null, themaBisher: 'pyth' },
  emir: {
    fertig: true, stimmung: 'geht_so', klassenarbeit: { datum: '2026-10-27', themaLabel: 'Terme und Gleichungen' },
    themaAntwort: 'noch_dran', stichwort: null, themaBisher: 'terme',
  },
  jonas: { fertig: true, stimmung: 'gut', klassenarbeit: null, themaAntwort: 'neu', stichwort: 'Steigung', themaBisher: 'propzu' },
  lea: {
    fertig: true, stimmung: 'angespannt', klassenarbeit: { datum: '2026-10-08', themaLabel: 'Quadratische Gleichungen' },
    themaAntwort: 'noch_dran', stichwort: null, themaBisher: 'quad',
  },
  deniz: { fertig: true, stimmung: 'geht_so', klassenarbeit: null, themaAntwort: null, stichwort: null, themaBisher: 'kreis' },
}

/** Fall-Vorschlag des Systems (fall_vorschlag, Entscheidung 9). */
export const BEISPIEL_FALL: Record<string, SessionFall> = {
  mila: 'schulthema', emir: 'schulthema', jonas: 'schulthema', lea: 'klassenarbeit', deniz: 'lernpfad',
}
export const BEISPIEL_LSA_LUECKE: Record<string, string | null> = {
  mila: null, emir: null, jonas: null, lea: null, deniz: 'Prozentrechnung: Grundwert',
}
/** Schulthema, falls Jonas’ neues Thema noch nicht gewaehlt ist (Dummy: themaLive). */
export const BEISPIEL_THEMA_LIVE = 'linfkt'

export const BEISPIEL_BRIEFING: Record<string, LiveBriefing> = {
  mila: {
    tags: [{ art: 'mastery' }],
    thema: { label: 'Satz des Pythagoras', quelle: 'schulthema', seit: '2026-09-15' },
    plan: { skill: 'Kathete berechnen', art: 'neu' },
    imBlick: 'Hypotenuse berechnen saß am 29.09. ohne Hinweis. Heute prüfen, ob es hält.',
    notiz: { text: 'Arbeitet zügig und erklärt gern laut, was sie rechnet.', von: 'Sara', am: '2026-09-29' },
    quests: { erledigt: 2, von: 2 },
  },
  emir: {
    tags: [{ art: 'signale', anzahl: 3, am: '2026-09-29' }],
    thema: { label: 'Terme und Gleichungen', quelle: 'schulthema', seit: '2026-09-22' },
    plan: { skill: 'Klammern ausmultiplizieren', art: 'weiter' },
    imBlick: 'Zweimal dasselbe Fehlbild: Minus vor der Klammer nur beim ersten Summanden.',
    notiz: { text: 'Beim Vorzeichen braucht er einen Moment. Nicht vorrechnen.', von: 'Sara', am: '2026-09-29' },
    quests: { erledigt: 1, von: 2 },
  },
  jonas: {
    tags: [],
    thema: { label: 'Proportionale Zuordnungen', quelle: 'erstgespraech', seit: '2026-09-08' },
    plan: { skill: 'Proportionale Zuordnungen', art: 'festigen' },
    imBlick: 'Das Schulthema ist seit dem Erstgespräch nicht bestätigt. Im Check-in nachfragen.',
    notiz: { text: 'Liest Aufgaben schnell, manchmal zu schnell.', von: 'Sara', am: '2026-09-29' },
    quests: { erledigt: 2, von: 2 },
  },
  lea: {
    tags: [{ art: 'klassenarbeit', datum: '2026-10-08' }],
    thema: { label: 'Quadratische Gleichungen', quelle: 'klassenarbeit', seit: null },
    plan: { skill: 'p-q-Formel', art: 'vorbereitung' },
    imBlick: 'Von Lea am 29.09. angekündigt.',
    notiz: { text: 'Wird vor Arbeiten nervös. Erfolge laut benennen.', von: 'Sara', am: '2026-09-29' },
    quests: { erledigt: 2, von: 2 },
  },
  deniz: {
    tags: [{ art: 'ersteNachLsa' }],
    thema: { label: 'Prozentrechnung', quelle: 'lsa', seit: null },
    plan: { skill: 'Grundwert berechnen', art: null },
    imBlick: 'LSA am 22.09.: Prozentwert sicher, Grundwert noch nicht sicher. Ziel aus dem Report unter „Wie es weitergeht“.',
    notiz: null,
    quests: null,
  },
}

export const BEISPIEL_IM_BLICK: BlickPunkt[] = [
  { art: 'mastery', kindId: 'mila', datum: null, detail: 'Hypotenuse berechnen · saß am 29.09. ohne Hinweis, Abstand 7 Tage' },
  {
    art: 'klassenarbeit', kindId: 'lea', datum: '2026-10-08',
    detail: 'Quadratische Gleichungen · Fall Klassenarbeit, ältere Themen pausieren (Klassenarbeit in 2 Tagen)',
  },
  { art: 'fehlbild', kindId: 'emir', datum: null, detail: 'Minus vor der Klammer nur beim ersten Summanden · am 29.09. zweimal' },
  { art: 'lsa', kindId: 'deniz', datum: null, detail: 'LSA vom 22.09.: Prozentwert sicher, Grundwert noch nicht sicher' },
]

const z = (skillKey: string, label: string, stand: ZielZeile['stand'], notizen: ZielZeile['notizen'] = []): ZielZeile => ({
  skillKey, label, stand, notizen,
})

/** Ziel der Stunde: Fertigkeiten des Themas mit Stand (ziel_fertigkeiten, A1). */
export const BEISPIEL_ZIEL: Record<string, ZielZeile[]> = {
  mila: [
    z('pyth_quadrieren', 'Quadrieren und Wurzelziehen', 'sicher', [{ art: 'voraussetzung' }]),
    z('pyth_hypotenuse', 'Hypotenuse berechnen', 'kandidat', [{ art: 'pruefungFaellig' }]),
    z('pyth_kathete', 'Kathete berechnen', 'aktiv', [{ art: 'heute', richtig: 5, von: 5 }]),
    z('pyth_figuren', 'Pythagoras in Figuren und Körpern', 'offen', [{ art: 'alsNaechstes' }]),
  ],
  emir: [
    z('terme_minus_klammer', 'Minus vor der Klammer (Kl. 7)', 'noch_nicht_sicher', [
      { art: 'voraussetzung' }, { art: 'warmup', richtig: 1, von: 3 },
    ]),
    z('terme_ausmultiplizieren', 'Klammern ausmultiplizieren', 'aktiv', [{ art: 'heute', richtig: 2, von: 4 }]),
    z('terme_ausklammern', 'Ausklammern', 'offen'),
    z('terme_binomisch', 'Binomische Formeln', 'offen'),
  ],
  jonas: [
    z('propzu_dreisatz', 'Proportionale Zuordnungen', 'sicher', [{ art: 'voraussetzung' }, { art: 'warmup', richtig: 2, von: 3 }]),
    z('linfkt_steigung', 'Steigung aus dem Graphen', 'aktiv', [{ art: 'erklaerung', kernidee: 2, von: 3 }]),
    z('linfkt_achsenabschnitt', 'y-Achsenabschnitt ablesen', 'offen'),
    z('linfkt_gleichung', 'Funktionsgleichung aufstellen', 'offen'),
  ],
  lea: [
    z('terme_binomisch', 'Binomische Formeln', 'sicher', [{ art: 'voraussetzung' }, { art: 'warmup', richtig: 3, von: 3 }]),
    z('quad_ergaenzung', 'Quadratische Ergänzung', 'sicher', [{ art: 'am', datum: '2026-09-29' }]),
    z('quad_pq', 'p-q-Formel anwenden', 'aktiv', [{ art: 'heute', richtig: 5, von: 6 }]),
    z('quad_text', 'Textaufgaben mit quadratischen Gleichungen', 'offen', [{ art: 'bisKlassenarbeit' }]),
  ],
  deniz: [
    z('prozent_prozentwert', 'Prozentwert berechnen', 'sicher', [{ art: 'inLsa' }]),
    z('prozent_grundwert', 'Grundwert berechnen', 'aktiv', [{ art: 'heute', richtig: 1, von: 2 }]),
    z('prozent_prozentsatz', 'Prozentsatz berechnen', 'offen'),
    z('prozent_vermehrt', 'Vermehrter und verminderter Grundwert', 'offen'),
  ],
}

/** Mastery-Kandidat mit Pruefgespraech (mastery_vorschlaege, skill_pruefung_lesen; A1). */
export const BEISPIEL_MASTERY: Record<string, Omit<LiveMasteryKandidat, 'entscheidung'>> = {
  mila: {
    skillKey: 'pyth_hypotenuse',
    label: 'Hypotenuse berechnen',
    themaLabel: 'Satz des Pythagoras',
    klasse: 9,
    belege: [
      { art: 'session', datum: '2026-09-29', richtig: 4, von: 4 },
      { art: 'warmupHeute', richtig: 2, von: 2 },
      { art: 'abstand', tage: 7 },
    ],
    frage:
      'Ein Schrank ist 2,40 m hoch und 0,80 m tief. Er liegt auf dem Rücken und soll aufgerichtet werden. Die Decke ist 2,50 m hoch. Klappt das? Erklär mir, wie du vorgehst.',
    erwartung:
      'Sieht das rechtwinklige Dreieck aus Höhe und Tiefe und nimmt die Diagonale als Hypotenuse: 2,40² + 0,80² = 6,40, also etwa 2,53 m. Antwort: Es klappt nicht, der Schrank stößt an.',
    kriterium: 'Richtig gelöst und den Weg ohne Hilfe erklärt.',
  },
}

/** Vorschlag „eine Stufe tiefer“ aus dem Warm-up (Entscheidung 10). */
export const BEISPIEL_PFAD: Record<string, Omit<PfadVorschlag, 'entscheidung'>> = {
  emir: {
    skillPlan: 'Klammern ausmultiplizieren',
    skillTiefer: 'Minus vor der Klammer',
    klasseTiefer: 7,
    warmupRichtig: 1,
    warmupVon: 3,
    fehlbild: 'nur das erste Vorzeichen geändert',
    fehlbildAm: '2026-09-29',
    themaLabel: 'Terme und Gleichungen',
  },
}

type CheckoutBasis = Omit<LiveCheckout, 'satz' | 'gesagt' | 'flags' | 'questAVorschlaege'> & { satzNachMastery?: string[] }

/** Check-out: Exit, Zusammenfassung, Satzbausteine, Quests, Notiz (Dummy: CO). */
export const BEISPIEL_CHECKOUT: Record<string, CheckoutBasis> = {
  mila: {
    exit: { richtig: 2, gesamt: 2 }, aufgaben: 8, richtig: 7, eingriffe: 0, schwerpunkt: 'Kathete berechnen',
    satzVorschlaege: [
      'Du rechnest die Kathete schon fast allein. Nächstes Mal schauen wir, ob es ohne Hinweis sitzt.',
      'Du hast heute fünf von fünf Kathetenaufgaben gelöst. Als Nächstes kommen die schwereren.',
    ],
    satzNachMastery: [
      'Du hast heute gezeigt, dass du die Hypotenuse auch in einer neuen Aufgabe sicher berechnest. Das ist jetzt gemeistert.',
      'Die Schrank-Aufgabe hast du selbst durchschaut. Die Hypotenuse sitzt, das ist gemeistert.',
    ],
    questA: { termin: uhr('17:00', 8), von: 'kind' },
    questB: { termin: uhr('17:00', 12), paketKlassenarbeit: false },
    notiz: 'Arbeitet zügig, Kathete fast allein.',
  },
  emir: {
    exit: { richtig: 1, gesamt: 2 }, aufgaben: 6, richtig: 3, eingriffe: 2, schwerpunkt: 'Klammern ausmultiplizieren',
    satzVorschlaege: [
      'Beim Minus vor der Klammer hast du heute den Dreh gefunden: Jedes Vorzeichen in der Klammer ändert sich.',
      'Du hast heute zweimal selbst gemerkt, wo das Vorzeichen kippt. Daran arbeiten wir weiter.',
    ],
    questA: { termin: uhr('18:30', 7), von: 'kind' },
    questB: { termin: uhr('17:00', 12), paketKlassenarbeit: false },
    notiz: '',
  },
  jonas: {
    exit: { richtig: 2, gesamt: 2 }, aufgaben: 4, richtig: 4, eingriffe: 0, schwerpunkt: 'Steigung aus dem Graphen',
    satzVorschlaege: [
      'Du kannst jetzt die Steigung aus einem Graphen ablesen. Mit dem Treppenbild hat es geklappt.',
      'Erst Δx, dann Δy: Das Steigungsdreieck sitzt jetzt bei dir.',
    ],
    questA: { termin: uhr('16:00', 7), von: 'kind' },
    questB: { termin: uhr('17:00', 12), paketKlassenarbeit: false },
    notiz: 'Treppenbild (Variante B) hat geholfen.',
  },
  lea: {
    exit: { richtig: 2, gesamt: 2 }, aufgaben: 9, richtig: 8, eingriffe: 0, schwerpunkt: 'p-q-Formel anwenden',
    satzVorschlaege: [
      'Die p-q-Formel sitzt, auch mit negativem q. Das nimmst du mit in die Arbeit am Donnerstag.',
      'Acht von neun Gleichungen richtig, auch die schweren. Du bist vorbereitet.',
    ],
    questA: { termin: uhr('19:00', 7), von: 'kind' },
    questB: { termin: uhr('17:00', 7), paketKlassenarbeit: true },
    notiz: 'Vor der Arbeit angespannt, nach der Session ruhiger.',
  },
  deniz: {
    exit: { richtig: 1, gesamt: 2 }, aufgaben: 5, richtig: 3, eingriffe: 0, schwerpunkt: 'Grundwert berechnen',
    satzVorschlaege: [
      'Den Prozentwert rechnest du sicher. Beim Grundwert weißt du jetzt, wo du ansetzt: erst ein Prozent ausrechnen.',
      'Guter Start. Beim Grundwert hilft dir der Weg über ein Prozent.',
    ],
    questA: { termin: null, von: null },
    questB: { termin: uhr('17:00', 12), paketKlassenarbeit: false },
    notiz: '',
  },
}

/** Termin-Vorschlaege, falls ein Kind Quest A noch nicht gewaehlt hat. */
export const BEISPIEL_QUEST_TERMINE: string[] = [uhr('16:00', 8), uhr('17:00', 8), uhr('16:00', 9)]
