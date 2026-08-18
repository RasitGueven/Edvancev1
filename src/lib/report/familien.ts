// Eltern-Report — die Themenfamilien (R5).
//
// EINE Taxonomie für alles, was im Report nach Themen gruppiert: das
// Profil-Diagramm in Abschnitt 03 und die Fazit-Bausteine, die eine Aussage
// über die Verteilung der Lücken machen.
//
// Zwei Definitionen nebeneinander wären der sichere Weg zurück in genau den
// Fehler, den R5 behebt: Der Empfehlungstext behauptete „die Bereiche liegen
// dicht beieinander", während sie über mehrere Familien streuten. Wer die
// Verteilung behauptet, muss sie mit demselben Maßstab zählen, den das
// Diagramm daneben zeichnet.
//
// ----------------------------------------------------------------------------
// Geometrie und Größen liegen zusammen
// ----------------------------------------------------------------------------
// Maßstab (geo_massstab) und Flächeneinheiten (groessen_flaechen) sind
// fachlich zwei Dinge, im Elterngespräch aber eines: „das Rechnen mit Figuren
// und Einheiten". Zusammen tragen sie zwölf Skills im Bestand — die breiteste
// Familie. Getrennt ergäbe das zwei Achsen mit fünf und sieben, und der Report
// spräche über einen Unterschied, den Eltern an dieser Stelle nicht brauchen.

/** Der interne Schlüssel einer Familie. Wird nie gerendert (INV-4.3). */
export type FamilienKey =
  | 'bruch'
  | 'prozent'
  | 'gleichung'
  | 'term'
  | 'geo'
  | 'vorzeichen'

export type Familie = {
  key: FamilienKey
  /** Anzeigename, einzeilig. */
  label: string
  /** Derselbe Name für das Diagramm, auf zwei Zeilen umgebrochen. */
  zeilen: readonly string[]
}

/**
 * Die feste Achsenmenge — für JEDEN Report dieselbe, in dieser Reihenfolge.
 *
 * Bis R4 zeichnete das Diagramm nur die Familien, die in der jeweiligen Sitzung
 * geprüft wurden: fünf Achsen bei der einen, sechs bei der anderen. Zwei
 * Reports nebeneinander waren dadurch nicht vergleichbar — dieselbe Form
 * bedeutete zweimal etwas anderes. Deshalb steht die Menge jetzt fest, und
 * nicht Geprüftes wird als solches ausgewiesen statt weggelassen.
 */
export const FAMILIEN: readonly Familie[] = [
  { key: 'bruch', label: 'Brüche & Dezimal', zeilen: ['Brüche', '& Dezimal'] },
  { key: 'prozent', label: 'Prozent & Anteile', zeilen: ['Prozent', '& Anteile'] },
  { key: 'gleichung', label: 'Gleichungen', zeilen: ['Gleichungen'] },
  { key: 'term', label: 'Terme', zeilen: ['Terme'] },
  { key: 'geo', label: 'Geometrie & Größen', zeilen: ['Geometrie', '& Größen'] },
  { key: 'vorzeichen', label: 'Vorzeichen', zeilen: ['Vorzeichen'] },
]

/**
 * Die Familie eines Skills, oder null.
 *
 * null ist kein Fehler: `potenzen` und `runden_ueberschlag` gehören in keine
 * der sechs Familien. Sie erscheinen weiterhin in den Skill-Listen des
 * Befunds — nur eben nicht auf einer Achse und nicht in der Familienzählung.
 */
export function familieVon(skillKey: string): FamilienKey | null {
  if (skillKey.startsWith('gleichung_')) return 'gleichung'
  if (skillKey.startsWith('term_')) return 'term'
  if (skillKey.startsWith('vorzeichen_')) return 'vorzeichen'
  if (skillKey.startsWith('bruch_') || skillKey.startsWith('dezimal_')) return 'bruch'
  if (skillKey.startsWith('prozent_') || skillKey === 'proportionalitaet') return 'prozent'
  if (skillKey.startsWith('geo_') || skillKey.startsWith('groessen_')) return 'geo'
  return null
}

/**
 * Eine Achse des Profils — zwei Werte auf DEMSELBEN Nenner.
 *
 * ----------------------------------------------------------------------------
 * Warum der Nenner der Bestand ist und nicht die Stichprobe
 * ----------------------------------------------------------------------------
 * Bis zu dieser Korrektur zeigte die Achse `traegt / geprueft`. Das verzerrt in
 * genau die falsche Richtung: „2 von 2" ergab eine volle Achse, obwohl in der
 * Familie nur zwei von acht vorhandenen Bereichen überhaupt angesehen wurden.
 * Je weniger geprüft, desto besser sah die Familie aus.
 *
 * Jetzt teilen sich beide Werte den Nenner `vorhanden` — alle Skills der
 * Familie im Bestand. Damit wird die Achse zu einer Aussage über den
 * tatsächlichen Stoff, nicht über die Auswahl:
 *
 *   anteilGeprueft   wie viel der Familie diese Analyse angesehen hat
 *   anteilTraegt     wie viel der Familie nachweislich trägt
 *
 * `anteilTraegt` ist nie größer als `anteilGeprueft` — ein Skill kann nicht
 * tragen, ohne geprüft worden zu sein. Die beiden Polygone liegen also
 * ineinander, und ihr Abstand ist die eigentliche Information: dicht beisammen
 * heißt „das Geprüfte trägt", weit auseinander heißt „gründlich geprüft, trägt
 * wenig".
 */
export type FamilienBefund = {
  key: FamilienKey
  label: string
  zeilen: readonly string[]
  /** Alle Skills dieser Familie im Bestand — der gemeinsame Nenner. */
  vorhanden: number
  geprueft: number
  traegt: number
  /** geprueft / vorhanden, oder null wenn die Familie gar keinen Skill hat. */
  anteilGeprueft: number | null
  /** traegt / vorhanden, oder null wenn die Familie gar keinen Skill hat. */
  anteilTraegt: number | null
  /**
   * Warum die Achse nichts sagt — für die Beschriftung.
   *
   * Nur noch ein Grund: nichts geprüft. Die frühere Markierung „zu wenig
   * geprüft" ist entfallen, weil sie mit dem alten Nenner nötig war (eine volle
   * Achse aus einem Skill). Mit dem Bestand als Nenner zeigt derselbe Fall von
   * sich aus eine kleine Fläche — die Warnung ist in die Zahl gewandert.
   */
  grund: 'nicht_geprueft' | null
}

/**
 * Zählt je Familie, wie viele Skills überhaupt im Bestand stehen.
 *
 * Erwartet die skill_keys der Tabelle `skills`. Skills ohne Familie
 * (`potenzen`, `runden_ueberschlag`) zählen nirgends mit.
 */
export function familienBestand(
  alleSkillKeys: readonly string[],
): Record<FamilienKey, number> {
  const bestand = Object.fromEntries(FAMILIEN.map((f) => [f.key, 0])) as Record<
    FamilienKey,
    number
  >
  for (const key of alleSkillKeys) {
    const f = familieVon(key)
    if (f) bestand[f] += 1
  }
  return bestand
}

/**
 * Rechnet die sechs Achsen aus den direkt geprüften Skills und dem Bestand.
 *
 * Gibt IMMER sechs Einträge zurück, in der Reihenfolge von FAMILIEN.
 */
export function familienBefunde(
  skills: readonly { skillKey: string; zustand: string }[],
  bestand: Readonly<Record<FamilienKey, number>>,
): FamilienBefund[] {
  return FAMILIEN.map((f) => {
    const drauf = skills.filter((s) => familieVon(s.skillKey) === f.key)
    const traegt = drauf.filter((s) => s.zustand === 'traegt').length
    const geprueft = drauf.length
    const vorhanden = bestand[f.key] ?? 0
    return {
      key: f.key,
      label: f.label,
      zeilen: f.zeilen,
      vorhanden,
      geprueft,
      traegt,
      anteilGeprueft: vorhanden > 0 ? geprueft / vorhanden : null,
      anteilTraegt: vorhanden > 0 ? traegt / vorhanden : null,
      grund: geprueft === 0 || vorhanden === 0 ? 'nicht_geprueft' : null,
    }
  })
}

/**
 * Die Familien, in denen mindestens eine Lücke liegt.
 *
 * Grundlage für die Fazit-Bausteine: „dicht beieinander" darf nur stehen, wenn
 * die Lücken tatsächlich in EINER Familie liegen. Skills ohne Familie zählen
 * nicht mit — über sie lässt sich keine Verteilungsaussage treffen — werden
 * aber getrennt zurückgegeben, damit der Aufrufer sie nicht übersieht.
 */
export function lueckenFamilien(
  luecken: readonly { skillKey: string }[],
): { familien: FamilienKey[]; ohneFamilie: number } {
  const gefunden = new Set<FamilienKey>()
  let ohneFamilie = 0
  for (const l of luecken) {
    const f = familieVon(l.skillKey)
    if (f) gefunden.add(f)
    else ohneFamilie++
  }
  return {
    familien: FAMILIEN.map((f) => f.key).filter((k) => gefunden.has(k)),
    ohneFamilie,
  }
}

/**
 * Der Fall-Schlüssel für Fazit und Empfehlung.
 *
 * Bis R5 war der Text allein an das Paket gehängt und behauptete eine
 * Verteilung, die niemand geprüft hatte („Die Bereiche liegen dicht
 * beieinander" — bei Lücken in zwei Familien). Jetzt trägt der Fall die
 * Zahl der betroffenen Familien, und die Bausteine sagen nur, was dazu passt.
 */
export function verteilungsFall(anzahlFamilien: number): 'eine' | 'zwei' | 'mehrere' {
  if (anzahlFamilien <= 1) return 'eine'
  if (anzahlFamilien === 2) return 'zwei'
  return 'mehrere'
}
