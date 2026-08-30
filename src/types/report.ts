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

export type LsaSessionState = 'in_progress' | 'completed' | 'aborted'

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
  /** leads.next_exam_topic — das Thema, an dem die Analyse angesetzt hat. */
  naechstesThema: string | null
}

/**
 * Die Erzählschicht: alles, was die sechs Schritte brauchen.
 *
 * Gerechnet wird sie mit den reinen Funktionen aus src/lib/report/ — denselben,
 * die der Entwurfs-Generator benutzt. Der Lesepfad steht in
 * src/lib/supabase/lsaReportErzaehlung.ts.
 */
export type ReportErzaehlung = {
  /** null, wenn kein Skill direkt geprüft wurde. Dann entfallen 02 und 03. */
  fundament: Fundament | null
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
