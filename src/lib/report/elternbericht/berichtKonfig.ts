// Eltern-Bericht v2 — alle Regeln und Schwellen an einer Stelle.
//
// Die Sätze selbst stehen in i18n (elternbericht.json, Abschnitte `ursache`,
// `s1.stufen`, `s4.grund`, `s5.grund`). Hier steht nur, WANN welcher Satz
// gilt. Wer eine Schwelle ändert, ändert sie hier und nirgends sonst.
//
// Alle Ausgaben des Berichts sind Vorschläge: Der Paketvorschlag ist als
// „Vorschlag“ gekennzeichnet, bis der Coach ihn bestätigt (paketBestaetigt).

/**
 * Kontakt auf Seite 5. Telefon: Noch ist keine Nummer hinterlegt. Solange
 * `telefon` null ist, entfällt die Zeile im PDF (kein Platzhalter auf Papier).
 */
export const KONTAKT: { telefon: string | null } = {
  telefon: null,
}

/**
 * Kurzsatz je Klassenstufe auf Seite 1 („Auf einen Blick“).
 *
 * Regel, der Reihe nach:
 *   1. Die Stufe mit dem meisten Übungsbedarf bekommt „hier liegen die Lücken“,
 *      wenn dort mindestens `lueckenAnteil` der geprüften Bereiche Übungsbedarf
 *      zeigen (Gleichstand: die tiefere Stufe).
 *   2. Sonst alles sicher → „sicher“.
 *   3. Sonst mindestens `weitgehendAnteil` sicher → „sitzen weitgehend“ (bei der
 *      aktuellen Klasse „fast sicher“).
 *   4. Sonst mindestens `gemischtAnteil` sicher → „teils, teils“.
 *   5. Sonst → „hier liegen Lücken“.
 */
export const STUFEN_REGEL = {
  lueckenAnteil: 0.5,
  weitgehendAnteil: 0.75,
  gemischtAnteil: 0.5,
} as const

/**
 * Seite 1, „wo die Lücken liegen“: die Themenfelder mit dem meisten
 * Übungsbedarf, ab `minUebung` Bereichen, höchstens `max`.
 */
export const LUECKEN_FELDER = { minUebung: 2, max: 2 } as const

/**
 * Fehlermuster „eher Sorgfalt als fehlendes Verständnis“ (Seite 1 und 4).
 *
 * Die Familien, deren Elterntext sagt, dass der Weg stimmte und nur ein Detail
 * verloren ging (Vorzeichen, ausgelassener Schritt, falsche Strecke in einer
 * sonst richtigen Figur). Die Kernaussage steht nur, wenn mindestens
 * `minAufgaben` Fehlbild-Aufgaben aus diesen Familien stammen UND sie
 * mindestens `minAnteil` aller Fehlbild-Aufgaben ausmachen.
 */
export const SORGFALT = {
  familien: ['vorzeichen', 'schritt_vergessen', 'figuren'],
  minAufgaben: 3,
  minAnteil: 0.5,
} as const

/**
 * Antwort auf die vermutete Ursache (Seite 1). Schlüssel = der Wert aus
 * lead_assessments.weak_topics (intakeConstants.PARENT_WEAK_TOPICS), Wert = die
 * Regel. Die Belege für Textverständnis und Rechenwege spiegeln
 * report_anlass_zuordnung (Stand 24.10.2026).
 */
export type UrsachenRegel =
  | { art: 'grundlagen' }
  | { art: 'belege'; skills: readonly string[]; familien: readonly string[] }
  | { art: 'sorgfalt' }
  | { art: 'nichtMessbar' }

export const URSACHEN: Readonly<Record<string, { key: string; regel: UrsachenRegel }>> = {
  'Grundlagen fehlen': { key: 'grundlagen', regel: { art: 'grundlagen' } },
  Textverständnis: {
    key: 'textverstaendnis',
    regel: { art: 'belege', skills: ['gleichung_modellieren'], familien: ['sachaufgaben'] },
  },
  Rechenwege: {
    key: 'rechenwege',
    regel: { art: 'belege', skills: [], familien: ['gleichungen_umformen', 'rechenreihenfolge'] },
  },
  Konzentration: { key: 'konzentration', regel: { art: 'sorgfalt' } },
  Prüfungsangst: { key: 'pruefungsangst', regel: { art: 'nichtMessbar' } },
  Zeiteinteilung: { key: 'zeiteinteilung', regel: { art: 'nichtMessbar' } },
}

/**
 * Seite 2, „den meisten Übungsbedarf zeigte …“: das Themenfeld mit dem höchsten
 * Anteil Übungsbedarf unter seinen geprüften Bereichen, nur Felder mit
 * mindestens `minGeprueft` geprüften Bereichen.
 */
export const DEUTUNG = { minGeprueft: 2 } as const

/**
 * Paketvorschlag (Seite 5) — ein Vorschlag des Systems, kein Urteil.
 *
 *   Premium:  Anteil Übungsbedarf ≥ premium.minAnteil UND
 *             mindestens premium.minSchwerpunkte Schwerpunkte.
 *   Basic:    nur in Ausnahmefällen: Anteil ≤ basic.maxAnteil UND
 *             höchstens basic.maxSchwerpunkte Schwerpunkt.
 *   Standard: alles dazwischen.
 *
 * Schwerpunkte = die Schwerpunkte auf Seite 4 (höchstens vier, ohne „danach“).
 */
export const PAKET_REGEL = {
  premium: { minAnteil: 0.5, minSchwerpunkte: 3 },
  basic: { maxAnteil: 0.15, maxSchwerpunkte: 1 },
} as const

/** Reihenfolge der Pakete unter den aktiven Tarifen (nach sort_order). */
export const PAKET_POSITION = { basis: 0, standard: 1, premium: 2 } as const
