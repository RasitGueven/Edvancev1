// Session-Rahmen C1: Ansichtsmodell der Coach-Live-Sicht, abgeleitet aus
// docs/session/coach-live-dummy.html. Die Seite kennt nur dieses Modell; woher
// die Felder kommen (Beispieldaten in C1, R1/A1/E1/Q1 ab C2), entscheidet allein
// src/lib/session/coachLive.ts. Texte, die ein Mensch liest, sind Inhalte (Namen,
// Skill-Labels, Aufgaben, Bausteine); alles andere sind Werte, die die Seite ueber
// i18n in Saetze bringt.

import type { ZielStand } from './lernpfad'
import type { AntwortErgebnis, EingriffStufe, SessionFall, SessionPhase, SignalArt, Stimmung, StellschraubeWert } from './sessionLive'
import type { Stufe } from './themen'

/** Die sechs Zeitpunkte des Dummys: vier Phasen plus davor und danach. */
export type LiveZeitpunkt = 'vorher' | SessionPhase | 'danach'

export type ZeitleistenSegment = { phase: SessionPhase; minuten: number }

// ── Signale und Warteschlange ─────────────────────────────────────────────

/** Warum ein Signal entstand (Entscheidung 15) bzw. was der Coach tun soll. */
export type LiveSignalGrund = 'kandidat' | 'warmup_luecke' | 'fehlversuche' | 'ohne_eingabe' | 'erklaerrunden' | 'stimmung'

export type LiveSignal = {
  kindId: string
  art: SignalArt
  grund: LiveSignalGrund
  /** ISO-Zeitpunkt, seit dem das Signal offen ist (aelteste zuerst). */
  seit: string
  /** Zahl zum Grund: Fehlversuche, Minuten ohne Eingabe, Erklaerrunden, Warm-up richtig. */
  wert: number | null
  /** Skill-Label, falls das Signal an einem Skill haengt (Kandidat, Luecke). */
  skill: string | null
  aufgabeNr: number | null
}

// ── Kachel ────────────────────────────────────────────────────────────────

/** Statusfarbe der Kachel: nur aus Zustaenden, Gruen erst nach Coach-Bestaetigung. */
export type KachelStatus = 'laeuft' | SignalArt | 'gemeistert'

export type ErgebnisMarke = 'richtig' | 'falsch' | 'hinweis' | 'aktuell'

/** Was das Kind gerade tut (Zeile unter dem Namen). */
export type Taetigkeit =
  | { art: 'checkin' }
  | { art: 'warmup'; nr: number; von: number }
  | { art: 'warmupFertig' }
  | { art: 'ueben' }
  | { art: 'erklaerung'; kernidee: number; von: number }
  | { art: 'tiefer' }

export type KachelMeta =
  | { art: 'ohneHinweis'; anzahl: number }
  | { art: 'richtig'; richtig: number; von: number; ueberZiel: number | null }
  | { art: 'hinweise'; anzahl: number }
  | { art: 'extrarunde'; variante: string }
  | { art: 'pausiert' }
  | { art: 'lsaWarmup' }
  | { art: 'pfadTiefer'; von: string }
  | { art: 'kernTiefer' }
  | { art: 'kernPlan' }
  | { art: 'signalErledigt' }
  | { art: 'angesprochen' }
  | { art: 'vertagt' }

// ── Schublade ─────────────────────────────────────────────────────────────

export type LiveZiel = {
  fallVorschlag: SessionFall | null
  fallCoach: SessionFall | null
  themaKey: string | null
  themaLabel: string | null
  klassenarbeit: { datum: string | null; themaLabel: string | null } | null
  /** Fall Lernpfad: naechste Luecke (in der ersten Session aus dem LSA-Report). */
  lsaLuecke: string | null
}

export type ZielNotiz =
  | { art: 'voraussetzung' }
  | { art: 'heute'; richtig: number; von: number }
  | { art: 'warmup'; richtig: number; von: number }
  | { art: 'pruefungFaellig' }
  | { art: 'alsNaechstes' }
  | { art: 'erklaerung'; kernidee: number; von: number }
  | { art: 'am'; datum: string }
  | { art: 'inLsa' }
  | { art: 'bisKlassenarbeit' }
  | { art: 'tieferGesetzt' }
  | { art: 'danach' }
  | { art: 'bestaetigt'; zeit: string }
  | { art: 'vertagt' }

export type ZielZeile = { skillKey: string; label: string; stand: ZielStand; notizen: ZielNotiz[] }

export type AufgabenKopf =
  | { art: 'warmup'; nr: number; von: number }
  | { art: 'aufgabe'; nr: number }
  | { art: 'check'; kernidee: number; runde: number }

export type LiveAufgabeDetail = {
  kopf: AufgabenKopf
  skill: string
  /** Was das Kind sieht. */
  text: string
  /** Nur in der Schublade, nur fuer den Coach (Entscheidung 17). */
  musterloesung: string[]
  letzteEingabe: { eingabe: string; ergebnis: AntwortErgebnis; nachHinweis: number | null } | null
  /** Minuten ohne Eingabe, wenn das ein Signal ist. */
  ohneEingabeMin: number | null
}

export type VersuchKopf = { art: 'versuch' | 'runde' | 'aufgabe' | 'warmup'; nr: number }

/** Falsche Antwort mit Fehlbild-Klartext (nur Coach). */
export type LiveVersuch = { kopf: VersuchKopf; eingabe: string; fehlbild: string }

export type Kernidee = {
  text: string
  stand: 'sicher' | 'laeuft' | 'offen'
  runde: number
  /** Fehlbild der letzten falschen Check-Antwort. */
  fehlbild: string | null
  variante: string | null
}

export type LiveErklaersequenz = {
  kernideen: Kernidee[]
  aktuell: number
  variante: string
  siehtGerade: string
}

export type MasteryBeleg =
  | { art: 'session'; datum: string; richtig: number; von: number }
  | { art: 'warmupHeute'; richtig: number; von: number }
  | { art: 'abstand'; tage: number }

export type MasteryEntscheidungLive = { art: 'gemeistert' | 'vertagt'; grund: string | null; zeit: string; von: string }

export type LiveMasteryKandidat = {
  skillKey: string
  label: string
  themaLabel: string
  klasse: number
  belege: MasteryBeleg[]
  frage: string
  erwartung: string
  kriterium: string
  entscheidung: MasteryEntscheidungLive | null
}

export type PfadVorschlag = {
  skillPlan: string
  skillTiefer: string
  klasseTiefer: number
  warmupRichtig: number
  warmupVon: number
  fehlbild: string
  fehlbildAm: string | null
  themaLabel: string
  entscheidung: { art: 'tiefer' | 'plan'; zeit: string; von: string } | null
}

export type LiveInfo =
  | { art: 'stimmung' }
  | { art: 'spaet'; ankunft: string }
  | { art: 'klassenarbeit'; datum: string; tage: number }

export type LiveEingreifen = {
  /** 0 = kein Signal, nichts tun. */
  empfohlen: 0 | EingriffStufe
  /** Vorbelegt aus dem letzten Versuch; ohne Fehlbild gehen Stufe 3 und 4 nicht. */
  fehlbild: { slug: string; klartext: string } | null
  eingriffe: { stufe: EingriffStufe; zeit: string }[]
}

export type HeuteAbschnitt = 'ankommen' | 'warmup' | 'kern' | 'eingemischt' | 'erklaerung'

export type HeuteZeile = {
  abschnitt: HeuteAbschnitt
  skill: string | null
  richtig: number | null
  von: number | null
  hinweise: number | null
  zusatz: 'mischanteil' | 'lsaSicher' | 'tiefer' | null
  /** Erklaersequenz: Kernideen sicher und laufende Runde. */
  kernideen: { sicher: number; aktuell: number; runde: number } | null
  /** Ankommen: Zeitpunkt. */
  zeit: string | null
}

/** Warum die Auswahl den letzten Schritt gemacht hat (A1). */
export type GrundLetzterSchritt =
  | { art: 'ueberQuote'; quote: number }
  | { art: 'unterQuote'; quote: number }
  | { art: 'eingemischt'; anteil: number }
  | { art: 'tiefer' }

// ── Check-in, Check-out, Briefing ─────────────────────────────────────────

export type LiveCheckin = {
  fertig: boolean
  stimmung: Stimmung | null
  klassenarbeit: { datum: string | null; themaLabel: string | null } | null
  themaAntwort: 'noch_dran' | 'neu' | null
  stichwort: string | null
  /** Schulthema vor diesem Check-in (lead_themen „aktuell“). */
  themaBisher: string | null
}

export type LiveCheckout = {
  exit: { richtig: number; gesamt: number }
  aufgaben: number
  richtig: number
  eingriffe: number
  schwerpunkt: string
  /** Satzvorschlaege aus dem Bausteinkatalog; der Coach bestaetigt einen. */
  satzVorschlaege: string[]
  satz: string
  gesagt: boolean
  /** Quest A waehlt das Kind am Tablet; der Coach kann nachtragen. */
  questA: { termin: string | null; von: 'kind' | 'coach' | null }
  /** Quest B ist vorbelegt (kurz vor der naechsten Session). */
  questB: { termin: string; paketKlassenarbeit: boolean }
  notiz: string
  flags: { eltern: boolean; pfad: boolean }
}

export type BriefingTag =
  | { art: 'mastery' }
  | { art: 'signale'; anzahl: number; am: string }
  | { art: 'themaAlt'; wochen: number }
  | { art: 'klassenarbeit'; datum: string }
  | { art: 'ersteNachLsa' }

export type LiveBriefing = {
  tags: BriefingTag[]
  thema: { label: string; quelle: 'schulthema' | 'erstgespraech' | 'klassenarbeit' | 'lsa'; seit: string | null }
  plan: { skill: string; art: 'neu' | 'weiter' | 'festigen' | 'vorbereitung' | null }
  imBlick: string | null
  notiz: { text: string; von: string; am: string } | null
  quests: { erledigt: number; von: number } | null
}

export type BlickPunkt = { art: 'mastery' | 'klassenarbeit' | 'fehlbild' | 'lsa'; kindId: string; detail: string; datum: string | null }

// ── Kind und Raum ─────────────────────────────────────────────────────────

export type CoachLiveKind = {
  id: string
  name: string
  vorname: string
  klasse: number
  stufe: Stufe
  tablet: number | null
  /** Tablet-Zuweisung = Ankunft im Raum. */
  tabletSeit: string | null
  /** Coach hat bestaetigt: ohne Tablet = nicht erschienen. */
  nichtErschienen: boolean
  phase: SessionPhase | null
  status: KachelStatus
  taetigkeit: Taetigkeit
  skill: string
  ergebnisfolge: ErgebnisMarke[]
  /** Kernideen-Stand statt Punkten, wenn eine Erklaersequenz laeuft. */
  sequenzBalken: Kernidee['stand'][] | null
  aufgabeNr: number | null
  meta: KachelMeta | null
  signale: LiveSignal[]
  ziel: LiveZiel
  zielFertigkeiten: ZielZeile[]
  aufgabe: LiveAufgabeDetail | null
  versuche: LiveVersuch[]
  hinweise: { stufe: number; text: string }[]
  erklaersequenz: LiveErklaersequenz | null
  masteryKandidat: LiveMasteryKandidat | null
  pfadVorschlag: PfadVorschlag | null
  info: { inhalt: LiveInfo; quittierbar: boolean } | null
  eingreifen: LiveEingreifen
  heute: HeuteZeile[]
  grundLetzterSchritt: GrundLetzterSchritt | null
  checkin: LiveCheckin
  checkout: LiveCheckout
  briefing: LiveBriefing
}

export type CoachLiveSession = {
  id: string
  beginn: string
  /** Uhrzeit der Ansicht (im Betrieb: jetzt). */
  jetzt: string
  raum: string
  coachName: string
  fach: string
  klassen: [number, number]
  plaetze: number
  abgeschlossen: string | null
}

export type CoachLiveRaum = {
  /** true, solange die Datenquelle Beispieldaten liefert (Beispielleiste sichtbar). */
  beispiel: boolean
  zeitpunkt: LiveZeitpunkt
  session: CoachLiveSession
  einstellungen: Record<string, StellschraubeWert>
  zeitleiste: ZeitleistenSegment[]
  kinder: CoachLiveKind[]
  /** Offene Signale, unsortiert; die Seite sortiert mit sortiereWarteschlange. */
  signale: LiveSignal[]
  masteryEntschieden: number
  erklaersequenzenFertig: number
  imBlick: BlickPunkt[]
  stand: string
}
