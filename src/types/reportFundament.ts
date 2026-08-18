// Eltern-Report — das Fundament unter dem aktuellen Thema (R4).
//
// Eigene Datei neben report.ts, weil hier eine andere Frage beantwortet wird:
// report.ts beschreibt, WAS in der Sitzung passiert ist (Themen, Fehlbilder,
// Skill-Befunde). Hier steht, wie das Geprüfte GESCHICHTET ist — und daraus
// leitet der Report seine Erzählung ab.
//
// ----------------------------------------------------------------------------
// fundament_tiefe ist KEINE Klassenstufe
// ----------------------------------------------------------------------------
// skills.fundament_tiefe ist die Position im Voraussetzungsgraphen: 8 liegt am
// weitesten oben, 1 am weitesten unten. Ein Skill mit Tiefe 4 kann aus Klasse 5
// stammen oder aus Klasse 7 — die Spalte klasse_herkunft sagt das, die Tiefe
// nicht. Kein Text im Report darf einer Ebene eine Klassenstufe zuschreiben.

/** Ein direkt geprüfter Skill mit seinem Urteil. Rohstoff aller Ableitungen. */
export type FundamentSkill = {
  skillKey: string
  label: string
  fundamentTiefe: number
  /** lsa_skill_urteil.zustand, wörtlich. */
  zustand: string
  /**
   * lsa_skill_urteil.proben_anzahl — wie viele Aufgaben zu diesem Skill
   * gestellt wurden.
   *
   * Die Grundgesamtheit, auf der ein entlastender Satz steht. Gegen die echten
   * Sitzungen geprüft: proben_anzahl deckt sich mit der Zahl verschiedener
   * task_id, die den Skill getragen haben.
   */
  proben: number
}

/**
 * Eine Ebene des Abstiegs.
 *
 * `delta` ist der Abstand zur Einstiegstiefe: 0 = aktuelles Thema, 1 = eine
 * Ebene tiefer. Der Report beschriftet ausschließlich über `delta`, nie über
 * `tiefe` — die absolute Zahl ist eine interne Graphposition und für Eltern
 * ohne Bedeutung.
 */
export type FundamentEbene = {
  tiefe: number
  delta: number
  geprueft: number
  traegt: number
  /**
   * Die Labels der Skills dieser Ebene, für den Untertitel der Ebenenzeile.
   *
   * Höchstens drei; liegen mehr auf der Ebene, ist `weitere` > 0 und der
   * Renderer hängt „u. a." an. Die Auswahl ist stabil sortiert, damit dieselbe
   * Sitzung immer dieselben drei nennt.
   */
  labels: string[]
  weitere: number
}

/**
 * Wie das Geprüfte geschichtet ist — die Grundlage für Slot 1 und Slot 2.
 */
export type Fundament = {
  /** Höchste Fundamenttiefe unter den direkt geprüften Skills. */
  einstiegTiefe: number
  /** Absteigend nach Tiefe: aktuelles Thema zuerst. */
  ebenen: FundamentEbene[]
  geprueft: number
  traegt: number
  /** Alle direkt geprüften Skills, die nicht tragen. Tiefste zuerst. */
  luecken: FundamentSkill[]
  /** Alle direkt geprüften Skills, die tragen. Höchste Ebene zuerst. */
  tragend: FundamentSkill[]
  /** Trägt jeder geprüfte Skill der Einstiegsebene? */
  einstiegTraegt: boolean
  /**
   * Wurde überhaupt eine Ebene unterhalb des Einstiegs geprüft?
   *
   * Getrennt von `fundamentTraegt`, weil „nichts geprüft" und „geprüft, trägt
   * nicht" zwei verschiedene Dinge sind. Ohne diese Unterscheidung würde eine
   * Sitzung, die gar nicht abgestiegen ist, als „Lücken darunter" erzählt.
   */
  fundamentGeprueft: boolean
  /**
   * Trägt jeder geprüfte Skill unterhalb der Einstiegsebene?
   *
   * false auch dann, wenn nichts darunter geprüft wurde — erst zusammen mit
   * `fundamentGeprueft` ist die Aussage eindeutig.
   */
  fundamentTraegt: boolean
  /**
   * Die Ebene mit dem größten Einbruch, oder null wenn es keinen gibt.
   *
   * „Größter Einbruch" heißt: kleinster Anteil tragender Bereiche. Bei
   * Gleichstand gewinnt die Ebene mit mehr geprüften Bereichen (breitere
   * Grundlage), danach die höher gelegene (näher am aktuellen Thema — dort
   * merkt es das Kind zuerst).
   *
   * null, wenn keine Ebene einen Einbruch zeigt.
   */
  einbruch: FundamentEbene | null
  /** Die unterste geprüfte Ebene — trägt sie vollständig, ist das eine Aussage. */
  bodenTraegt: boolean
}

/** In welche Richtung ein von den Eltern genannter Bereich beantwortet wird. */
export type RueckbezugRichtung = 'bestaetigend' | 'entlastend'

/**
 * Ein Aufgriff der Eltern-Einschätzung im Fazit.
 *
 * `belege` ist die Grundgesamtheit, auf der ein entlastender Satz steht — die
 * Zahl der Aufgaben bzw. geprüften Skills, die den Bereich abgedeckt haben. Sie
 * wird im Satz genannt: auf zwei Aufgaben lässt sich kein Freispruch bauen, und
 * der Text soll das selbst sagen statt es zu verschweigen.
 */
export type Rueckbezug = {
  /** Wörtlich der Wert aus lead_assessments.weak_topics. Nur zur Zuordnung. */
  thema: string
  /** Der Fall-Schlüssel für report_bausteine (slot 'rueckbezug'). */
  fall: string
  richtung: RueckbezugRichtung
  belege: number
}

/** Eine Zeile aus report_anlass_zuordnung. */
export type AnlassZuordnung = {
  thema: string
  skillKeys: string[]
  fehlbildFamilien: string[]
  strukturell: boolean
}

/** Ein abgenommener Erzählbaustein aus report_bausteine. */
export type ReportBaustein = {
  schluessel: string
  slot: string
  fall: string
  variante: string
  text: string
}

/**
 * Wer die Analyse durchgeführt hat — Fußzeile des Dokuments.
 *
 * Abgeleitet aus platz_assignments.created_by der Sitzung: das ist die Person,
 * die den Platz vergeben und die Analyse begleitet hat. Fehlt die Zuordnung,
 * bleiben beide Felder null und die Fußzeile entfällt — ein erfundener
 * Ansprechpartner wäre schlimmer als keiner.
 */
export type ReportAnsprechpartner = {
  name: string | null
  email: string | null
}
