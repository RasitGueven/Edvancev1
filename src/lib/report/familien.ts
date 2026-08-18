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
// und Einheiten". Sie zu trennen ergäbe eine siebte Achse, die in den
// Pilotsitzungen je zwei bis vier geprüfte Skills trüge — zu dünn für eine
// eigene Achse (siehe MIN_GEPRUEFT_ACHSE).

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
 * Ab so vielen geprüften Skills trägt eine Achse eine Aussage.
 *
 * Eine volle Achse auf Basis eines einzigen Skills liest sich wie eine
 * Bestnote — und beruht auf ein bis zwei Aufgaben. Zwei ist die Untergrenze,
 * ab der überhaupt zwei Beobachtungen zusammenkommen; darunter zeichnet das
 * Diagramm keine Fläche und die Beschriftung sagt, warum.
 */
export const MIN_GEPRUEFT_ACHSE = 2

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

/** Eine Achse des Profils: Zähler, Nenner und ob sie überhaupt etwas sagt. */
export type FamilienBefund = {
  key: FamilienKey
  label: string
  zeilen: readonly string[]
  geprueft: number
  traegt: number
  /**
   * Anteil tragender an geprüften Skills, oder null wenn die Achse zu dünn ist.
   *
   * null heißt „keine Aussage" — und wird im Diagramm anders dargestellt als
   * ein echter Anteil von 0. Beides an den Mittelpunkt zu zeichnen, ohne es zu
   * unterscheiden, hieße: nicht geprüft sieht aus wie nichts gekonnt.
   */
  anteil: number | null
  /** Warum die Achse nichts sagt — für die Beschriftung. */
  grund: 'nicht_geprueft' | 'zu_wenig' | null
}

/**
 * Rechnet die sechs Achsen aus den direkt geprüften Skills.
 *
 * Gibt IMMER sechs Einträge zurück, in der Reihenfolge von FAMILIEN.
 */
export function familienBefunde(
  skills: readonly { skillKey: string; zustand: string }[],
): FamilienBefund[] {
  return FAMILIEN.map((f) => {
    const drauf = skills.filter((s) => familieVon(s.skillKey) === f.key)
    const traegt = drauf.filter((s) => s.zustand === 'traegt').length
    const geprueft = drauf.length
    const grund =
      geprueft === 0
        ? ('nicht_geprueft' as const)
        : geprueft < MIN_GEPRUEFT_ACHSE
          ? ('zu_wenig' as const)
          : null
    return {
      key: f.key,
      label: f.label,
      zeilen: f.zeilen,
      geprueft,
      traegt,
      anteil: grund === null ? traegt / geprueft : null,
      grund,
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
