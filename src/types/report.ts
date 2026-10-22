// Eltern-Report (R1). Reine Lese-Sicht auf eine abgeschlossene LSA-Session.
//
// BEWERTUNG: `correct` stammt aus lsa_responses.correct — das schreibt
// lsa_submit serverseitig über lsa_is_correct(). Die Lösungen selbst
// (task_solutions) werden NIE clientseitig gelesen; `correct` ist ein Urteil
// über die Antwort des Kindes, keine Lösung, und liegt für coach/admin ohnehin
// schon per RLS offen. Kein neuer Grant, keine zweite Bewertungswahrheit.

import type {
  FamilienBefund,
} from '@/lib/report/familien'
import type {
  Fundament,
  ReportAnsprechpartner,
  ReportBaustein,
  Rueckbezug,
} from '@/types/reportFundament'
import type { HeimatThema, KatalogSkill, LernPlan, LwKante } from '@/types/elternbericht'
import type { SucheSkill, Suchweg, Themenraum } from '@/types/reportSuche'

export type LsaSessionState = 'in_progress' | 'completed' | 'aborted'

/**
 * Durchklicken (LSA-R2): der Stand aus lsa_durchklick_stand. Eine Antwort ist
 * eine Aufgabe; „schnell falsch“ = unter schwellen.schnell_ms und falsch.
 * Gespeichert als lsa_sessions.nicht_auswertbar_grund und
 * result_summary.durchklick.
 */
export type DurchklickStand = {
  antworten: number
  schnell_falsch: number
  /** 0–1, zwei Nachkommastellen. */
  anteil_schnell_falsch: number
  folge_schnell_falsch_max: number
  /** Schnelle Abgaben am Ende, richtig oder falsch, ohne „Weiß ich nicht“. */
  folge_schnell_aktuell: number
  nicht_auswertbar: boolean
  grund: 'folge' | 'anteil' | null
  schwellen?: {
    schnell_ms: number
    folge: number
    anteil: number
    min_antworten: number
    hinweis_folge: number
  }
}

// Ein Eintrag der Fertig-Liste (heutige Analysen).
export type LsaSessionListItem = {
  session_id: string
  first_name: string | null
  grade: number
  subject: string
  status: LsaSessionState
  started_at: string | null
  completed_at: string | null
  answered: number
  planned: number
  /**
   * LSA-R2: nur laufende Sitzungen — nicht auswertbar oder gerade schnell
   * (lsa_durchklick_stand). Fehlt, solange die Funktion nicht eingespielt ist.
   */
  schnell?: boolean
}

// Eine Zeile der Liste „LSA-Reports“ (LR-1): nur abgeschlossene Sitzungen.
// Testläufe und Testkonten bleiben drin und werden gekennzeichnet.
export type LsaReportListItem = {
  session_id: string
  first_name: string | null
  grade: number
  subject: string
  completed_at: string
  testlauf: boolean
  ist_test: boolean
  modus: string | null
  thema_key: string | null
  /** themen.label über thema_key; null, wenn es fehlt. */
  thema_label: string | null
  /** LSA-R2. Fehlt (vor der Migration) = auswertbar. */
  auswertbar?: boolean
  nicht_auswertbar_grund?: DurchklickStand | null
}

// Die beim Lead erfasste Eltern-Einschätzung (lead_assessments, source='parent').
export type ParentAssessment = {
  note: string | null
  weakTopics: string[]
}

// Ein wiederkehrender Denkschritt aus lsa_fehlbild_auswertung (AF2/AF3/AF4/AF5).
//
// `slug` und `familie` sind interne Schlüssel und dürfen NIE gerendert werden —
// beide sind snake_case und keine Sätze für Eltern (INV-4.3). Angezeigt wird
// ausschließlich `familieElterntext`, und nur wenn er da ist.
//
// Kein `klartext` mehr: das war bis AF3 der Elternsatz zum einzelnen Slug, ab
// AF4 der Coach-Satz — den die RPC des Eltern-Pfads nicht mehr herausgibt. Mit
// der Bündelung (AF5) trägt der Elternsatz die Familie, nicht den Slug; das
// Feld wäre dauerhaft null und die einzige Frage daran, wann es doch jemand
// rendert.
export type ReportFehlbild = {
  slug: string
  /**
   * Bündelschlüssel (fehlbild_familien.schluessel), null wenn der Slug keiner
   * Familie zugeordnet ist. Zum Gruppieren, nicht zum Anzeigen.
   */
  familie: string | null
  /**
   * Der eine Satz, den der Report für die ganze Familie vorliest. null, solange
   * fehlbild_familien.freigegeben_am null ist (AF4-Abnahme-Schranke) oder der
   * Slug keine Familie hat.
   */
  familieElterntext: string | null
  anzahl: number
  aufgaben: number
  /**
   * Die Skills, in denen dieser Slug auftrat.
   *
   * Ab R2 nicht mehr nur Zierde: eine Aufgabe hat genau EINEN skill_key, also
   * beweisen disjunkte Skill-Mengen zweier Slugs, dass sie verschiedene
   * Aufgaben getroffen haben. Darauf ruht die Untergrenze der Aufgabenzahl in
   * `aufgabenUntergrenze` — die RPC liefert keine Aufgaben-IDs.
   */
  skills: string[]
  skillUebergreifend: boolean
  /**
   * Einstufung des EINZELNEN Slugs. Ab R2 nur noch Information: die Schwelle
   * entscheidet nicht mehr hier, sondern nach der Bündelung auf Familienebene
   * (src/lib/reportFehlbilder.ts).
   */
  einstufung: 'befund' | 'beobachtung'
}

/**
 * Ein direkt geprüfter Skill, der nicht trägt (R2).
 *
 * `skillKey` ist ein interner Schlüssel und wird NIE gerendert — angezeigt wird
 * `label` aus `skills.label`. Erfunden wird dafür nichts: fehlt ein Label, fehlt
 * der Eintrag.
 */
export type ReportSkillbefund = {
  skillKey: string
  label: string
  fundamentTiefe: number
}

/**
 * Der Abschnitt „Was wir uns genauer ansehen".
 *
 * Ein BEFUND, kein Urteil: bei zwei Proben je Skill steht `offen = true` in den
 * Daten. Der Coach validiert ihn in den ersten Sitzungen — die Sprache des
 * Abschnitts muss diese Vorläufigkeit tragen.
 *
 * Enthalten sind ausschließlich DIREKT geprüfte Skills (`belegt_direkt`).
 * Mitbelegte Urteile sind abgeleitet, nicht geprüft, und erscheinen nicht.
 */
export type ReportSkillbefunde = {
  /** Nicht tragend, namentlich. Absteigend nach Fundamenttiefe. */
  nichtTragend: ReportSkillbefund[]
  /** Direkt geprüft und tragend — nur die Zahl, nie einzeln aufgezählt. */
  tragendAnzahl: number
  /**
   * true, wenn die nicht tragenden Skills über mehr als eine Fundamentstufe
   * streuen — die Analyse musste also hinter den Einstieg zurückgehen. Liegen
   * alle auf einer Stufe, entfällt die Aussage.
   */
  zurueckgegangen: boolean
}

/**
 * Die Empfehlung am Schluss des Reports (R3 — Gestaltung vorbereitet).
 *
 * `paket` ist der ANZEIGENAME der Stufe, kein Schlüssel. Die Begründung kommt
 * als Sätze, wörtlich aus abgenommenen Bausteinen — nicht zur Laufzeit
 * formuliert.
 */
export type ReportEmpfehlung = {
  paket: string
  begruendung: string[]
}

export type ReportData = {
  sessionId: string
  firstName: string | null
  grade: number
  subject: string
  status: LsaSessionState
  analysedAt: string | null
  parentAssessment: ParentAssessment | null
  /**
   * ALLE Fehlbilder der Sitzung, ungefiltert.
   *
   * Bis R2 stand hier nur 'befund'. Die Schwelle greift seitdem erst NACH der
   * Bündelung je Familie — sonst geht verloren, wofür die Bündelung gebaut
   * wurde: zwei Slugs derselben Familie, je unter der Schwelle, zusammen
   * darüber.
   */
  fehlbilder: ReportFehlbild[]
  /**
   * Die Skill-Ebene der Diagnose (R2). null, wenn kein Skill direkt geprüft
   * wurde — dann entfällt der Abschnitt vollständig.
   */
  skillbefunde: ReportSkillbefunde | null
  /**
   * Fazit als Sätze und Empfehlung — beides noch OHNE Datenquelle.
   *
   * Die Bausteine entstehen in einem eigenen PR; hier liegt nur die Gestaltung
   * bereit. Optional, damit der Lesepfad sie noch nicht setzen muss: fehlen
   * sie, rendert der Schluss nichts.
   */
  fazit?: string[] | null
  empfehlung?: ReportEmpfehlung | null
  /**
   * Die sechs Schritte der Erzählung (R4/R5, in der App seit R6).
   *
   * Fehlt sie, rendert der Report nur Kopf und Fehlbilder — jeder Abschnitt
   * prüft sein eigenes Datum und entfällt still, statt einen leeren Kasten zu
   * zeigen.
   */
  erzaehlung: ReportErzaehlung
  /** Aufgaben, nicht Antwortzeilen: zwei Teilaufgaben eines Items sind eine. */
  aufgaben: number
  /** LSA als Testlauf (Entscheidung 27) — der Report zeigt ein Banner. */
  testlauf: boolean
  /** leads.next_exam_topic — das Thema, an dem die Analyse angesetzt hat. */
  naechstesThema: string | null
  /**
   * students.school_type des Kindes der Sitzung (R7, Kopfdaten Seite 1).
   * null bei Fehler, RLS oder leerem Feld — dann entfällt die Schulform.
   */
  schulform: string | null
  /**
   * LSA-R2: false, wenn lsa_finish die Sitzung als durchgeklickt markiert hat.
   * Fehlt (vor der Migration) = auswertbar.
   */
  auswertbar?: boolean
  /** Der Stand beim Abschluss, nur bei auswertbar = false. */
  nichtAuswertbarGrund?: DurchklickStand | null
  /** Der Lead der Sitzung (lsa_lead_kontext) — Ziel von „LSA wiederholen“. */
  leadId?: string | null
}

/**
 * Die Erzählschicht: alles, was die sechs Schritte brauchen.
 *
 * Gerechnet wird sie mit den reinen Funktionen aus src/lib/report/ — denselben,
 * die der Entwurfs-Generator benutzt. Der Lesepfad steht in
 * src/lib/supabase/lsaReportErzaehlung.ts.
 */
export type ReportErzaehlung = {
  /** null, wenn kein Skill direkt geprüft wurde. Dann entfällt 03. */
  fundament: Fundament | null
  /** Schritt 02 nach Thema und Stufe. null, wenn nichts direkt geprüft wurde. */
  suche: Suchweg | null
  /** Der Themenraum der Sitzung (W5-d) — gespeichert oder berechnet; null ohne Thema. */
  raum: Themenraum | null
  /** Immer sechs Achsen — auch die ungeprüften, als solche gekennzeichnet. */
  profil: FamilienBefund[]
  /** Der Aufgriff der Eltern-Einschätzung im Schluss. */
  rueckbezuege: Rueckbezug[]
  /** Fall-Schlüssel für Fazit und Empfehlung: keine | eine | zwei | mehrere. */
  verteilung: string | null
  /** Die ABGENOMMENEN Bausteine. Fehlt einer, bleibt seine Stelle leer. */
  bausteine: ReportBaustein[]
  ansprechpartner: ReportAnsprechpartner
  /**
   * Die von den Eltern genannten Punkte als Substantivgruppen.
   *
   * weak_topics mischt einen Teilsatz („Grundlagen fehlen") mit Substantiven;
   * der Anzeigename aus report_anlass_zuordnung glättet die Aufzählung.
   */
  anlassNamen: string[]
  /**
   * Alle direkt geprüften Skills mit Label (R7) — dieselbe Liste, aus der
   * fundament, suche und profil gerechnet werden, unverändert.
   */
  kompetenzen: SucheSkill[]
  /**
   * Alle Skills des Katalogs mit Herkunftsklasse (R7, Nenner „bis Klasse k").
   * Leer, wenn der Katalog nicht geladen werden konnte.
   */
  katalog: KatalogSkill[]
  /**
   * lsa_sessions.modus: 'adaptiv' ist die abgestufte LSA. null bei alten
   * Sitzungen oder wenn die Sitzung nicht gelesen werden konnte.
   */
  modus: 'fest' | 'adaptiv' | null
  /**
   * Schlüssel der aus dem Voraussetzungsgraphen abgeleiteten Urteile
   * (belegt_direkt = false), ohne Zustand. Nur für den Thema-Satz des
   * R7-Bogens gezählt, nie als sicher/Übungsbedarf gezeigt (Gründer, 20.10.2026).
   */
  abgeleitet: string[]
  /** Alle Kanten aus skill_kante (R7-9, Lernweg). Leer bei Fehler. */
  kanten: LwKante[]
  /** skill_thema: das Heimat-Thema je Skill (R7-9). Leer bei Fehler. */
  heimatThemen: HeimatThema[]
  /** Schulplan der Schule des Kindes, sonst Kernlehrplan NRW (R7-9); null bei Fehler. */
  plan: LernPlan | null
}

// Die Pakete der Empfehlung. Bewusst eine Konstantenliste: die
// Empfehlungsregeln kommen später, in v1 wählt der Coach von Hand.
export const REPORT_PAKETE = ['basis', 'standard', 'premium'] as const
export type ReportPaket = (typeof REPORT_PAKETE)[number]

// Die zwei Coach-Freitexte + Paketwahl (Ausblick).
export type ReportNotes = {
  zielbild: string
  empfehlung: string
  paket: ReportPaket | null
}
