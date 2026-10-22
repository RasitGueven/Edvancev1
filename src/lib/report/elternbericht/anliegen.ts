// Eltern-Bericht R7 — „Ihr Anliegen“ auf Seite 1 und in Station 01 (R7-11,
// Entscheidungen 9–13, Gründer 22.10.2026).
//
// Quelle der Anliegen: lead_assessments.weak_topics (source 'parent'), im
// Intake gewählt aus PARENT_WEAK_TOPICS (src/pages/admin/intake/intakeConstants.ts).
// Der Report zeigt sie als Anzeigenamen aus report_anlass_zuordnung
// (ReportErzaehlung.anlassNamen); die Rückbezüge tragen den Rohwert (thema).
//
// Ein Anliegen ist fachlich (Mathe-Stoff oder Leistung) oder überfachlich.
// Nur fachliche erscheinen: Auf ein überfachliches hat der Bericht keine
// Antwort, und ein Satz darüber, was die Analyse nicht sagen kann, verwirrt
// mehr, als er hilft. Die Daten bleiben unverändert in der Datenbank.

import type { EbAnliegen, EbSchwerpunkt, EbThema, Rueckbezug } from '@/types'

export type AnliegenArt = 'fachlich' | 'ueberfachlich'

/**
 * Die feste Zuordnung (klein geschrieben). Rohwerte aus dem Intake und ihre
 * Anzeigenamen stehen beide drin. Die Gründer bestätigen sie in der Abnahme.
 */
export const ANLIEGEN_ZUORDNUNG: Readonly<Record<string, AnliegenArt>> = {
  // Intake (PARENT_WEAK_TOPICS) und Anzeigenamen (report_anlass_zuordnung)
  'grundlagen fehlen': 'fachlich',
  'fehlende grundlagen': 'fachlich',
  rechenwege: 'fachlich',
  textverständnis: 'fachlich',
  konzentration: 'ueberfachlich',
  prüfungsangst: 'ueberfachlich',
  zeiteinteilung: 'ueberfachlich',
  // Weitere mögliche Werte (Freitext, spätere Intake-Optionen)
  noten: 'fachlich',
  lücken: 'fachlich',
  klassenarbeit: 'fachlich',
  klassenarbeiten: 'fachlich',
  thema: 'fachlich',
  motivation: 'ueberfachlich',
  hausaufgaben: 'ueberfachlich',
  selbstorganisation: 'ueberfachlich',
}

/** Ein unbekannter Wert gilt als überfachlich. */
export function anliegenArt(wert: string): AnliegenArt {
  return ANLIEGEN_ZUORDNUNG[wert.trim().toLocaleLowerCase('de')] ?? 'ueberfachlich'
}

export const istFachlich = (wert: string): boolean => anliegenArt(wert) === 'fachlich'

/**
 * Welche Rückbezüge Seite 1 noch zeigt: nur zu fachlichen Anliegen und nur
 * solche, die antworten (bestätigend oder entlastend, nicht die schmale
 * Fassung). Die Fassungen „offen“, „nicht messbar“ und „schmal“ sagen, was die
 * Analyse nicht sagen kann oder erst später klärt (R7-11, Entscheidung 14).
 */
export function rueckbezugZeigen(r: Pick<Rueckbezug, 'thema' | 'fall' | 'richtung'>): boolean {
  return (
    istFachlich(r.thema) &&
    (r.richtung === 'bestaetigend' || r.richtung === 'entlastend') &&
    !r.fall.endsWith('_schmal')
  )
}

/**
 * Frage und Antwort (Entscheidung 12). null, wenn der Kasten entfällt: ohne
 * Thema der LSA und ohne fachliches Anliegen.
 *
 * - Mit Thema: Thema und die Bereiche mit Übungsbedarf darin.
 * - Fachliche Anliegen: genannt, dazu Schwerpunkt 1 als Antwort — außer
 *   Schwerpunkt 1 ist das Thema, dann sagte der Satz dasselbe.
 * - Das nächste Thema aus dem Lead nur ohne Thema der LSA.
 */
export function anliegenAus({
  anlassNamen,
  naechstesThema,
  schwerpunkte,
  thema,
}: {
  anlassNamen: readonly string[]
  naechstesThema: string | null
  schwerpunkte: readonly EbSchwerpunkt[]
  /** Elternbericht.thema — auch ohne Übungsbedarf im Thema gesetzt. */
  thema: EbThema | null
}): EbAnliegen | null {
  const erster = schwerpunkte[0] ?? null
  const punkte = [...new Set(anlassNamen)].filter(istFachlich)
  if (!thema && punkte.length === 0) return null
  return {
    thema: thema?.titel ?? null,
    themaUebung: thema ? [...thema.uebung] : [],
    punkte,
    schwerpunkt: punkte.length > 0 && erster && !erster.thema ? erster : null,
    naechstesThema: thema ? null : naechstesThema,
  }
}
