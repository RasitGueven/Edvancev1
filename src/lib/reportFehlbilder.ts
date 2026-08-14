// Eltern-Report — Bündelung der Fehlbilder auf Familienebene (AF4/AF5).
//
// Fünf Fehlbilder derselben Familie sind für Eltern EINE Information, nicht
// fünf. Der Coach sieht weiterhin jeden Einzelbefund über lsa_fehlbild_report;
// gebündelt wird ausschließlich die Elternsicht.
//
// Warum die Gruppierung hier liegt und nicht in der Komponente: sie ist eine
// Entscheidung darüber, WAS Eltern zu sehen bekommen — welche Befunde
// wegfallen, welche zusammenfallen, in welcher Reihenfolge. Das ist Logik mit
// Regeln, keine Darstellung. Hier ist sie ohne React prüfbar, und die
// Komponente bekommt eine fertige Liste, die sie nur noch ausgibt. Ein
// `filter` in der Komponente wäre eine Auslieferungsregel an einer Stelle, an
// der niemand sie sucht.
//
// Die Vorfilterung auf einstufung='befund' passiert davor in
// lsaReport.loadFehlbilder und bleibt dort.

import type { ReportFehlbild } from '@/types'

/**
 * Ein Block der Elternsicht: eine Familie, ein Satz.
 *
 * `familie` ist der interne Bündelschlüssel und dient ausschließlich als
 * React-key — er wird NIE gerendert (INV-4.3, snake_case ist kein Satz für
 * Eltern). Angezeigt wird `elterntext`, wörtlich wie er aus der Datenbank
 * kommt.
 */
export type ReportFehlbildFamilie = {
  familie: string
  /** Der abgenommene Satz aus fehlbild_familien.elterntext. Nie leer. */
  elterntext: string
  /**
   * Summe der Vorkommen über alle Slugs der Familie.
   *
   * Exakt: jede Antwortzeile trägt genau einen Slug, die Mengen sind also
   * disjunkt. Bewusst wird NICHT `aufgaben` aufsummiert — zwei Slugs können
   * auf derselben Aufgabe auftreten, die Summe würde Aufgaben doppelt zählen
   * und Eltern eine zu große Zahl zeigen.
   */
  anzahl: number
}

/**
 * Bündelt die Befunde einer Sitzung auf ihre Familien.
 *
 * Weggelassen wird still — ohne Platzhalter, ohne Hinweis:
 *   - Fehlbilder ohne Familienzuordnung (53 der 73 Registry-Slugs). Sie sind
 *     für den Coach ein Befund, für Eltern ohne Bündelsatz keine Aussage.
 *   - Familien ohne abgenommenen Elterntext (fehlbild_familien.freigegeben_am
 *     ist null). Ein unabgenommener Satz über das Denken eines Kindes darf die
 *     Elternfläche nicht erreichen; ein Platzhalter an seiner Stelle würde
 *     genau die Behauptung aufstellen, die die Abnahme verhindern soll.
 *
 * Sortierung: Summe der Vorkommen absteigend, bei Gleichstand nach
 * Familienschlüssel — damit die Reihenfolge bei gleicher Häufigkeit stabil ist
 * und nicht von der Zeilenreihenfolge der RPC abhängt.
 */
export function gruppiereFehlbilderNachFamilie(
  fehlbilder: readonly ReportFehlbild[],
): ReportFehlbildFamilie[] {
  const blocks = new Map<string, ReportFehlbildFamilie>()

  for (const fb of fehlbilder) {
    const familie = fb.familie?.trim()
    const elterntext = fb.familieElterntext?.trim()
    if (!familie || !elterntext) continue

    const vorhanden = blocks.get(familie)
    if (vorhanden) {
      vorhanden.anzahl += fb.anzahl
    } else {
      blocks.set(familie, { familie, elterntext, anzahl: fb.anzahl })
    }
  }

  return [...blocks.values()].sort(
    (a, b) => b.anzahl - a.anzahl || a.familie.localeCompare(b.familie, 'de'),
  )
}
