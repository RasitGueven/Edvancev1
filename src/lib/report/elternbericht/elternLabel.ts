// Eltern-Bericht R7-9 — Elternbezeichnungen für Skill-Labels (Entscheidung 4).
//
// skills.label ist für Coaches geschrieben und enthält Fachkürzel („LGS“), die
// Eltern nicht kennen. Bis es je Skill eine eigene Elternbezeichnung in der
// Datenbank gibt (Migration durch Rasit), löst diese Liste sie auf. Angewandt
// an EINER Stelle: in bereicheAus und für nicht geprüfte Bereiche im Lernweg —
// so zeigen alle Seiten und die Präsentation dieselben Wörter.

/** Ersetzungen auf ganze Wörter; neue Einträge hier ergänzen (mit Test). */
export const ELTERN_WOERTER: readonly (readonly [string, string])[] = [
  ['LGS', 'Gleichungssysteme'],
  ['Sachsituationen', 'Sachaufgaben'],
  ['Sachsituation', 'Sachaufgabe'],
]

const MUSTER = ELTERN_WOERTER.map(
  ([kurz, lang]) => [new RegExp(`(?<![\\p{L}\\d])${kurz}(?![\\p{L}\\d])`, 'gu'), lang] as const,
)

/** Das Label, wie Eltern es lesen: Fachkürzel aufgelöst, sonst unverändert. */
export function elternLabel(label: string): string {
  return MUSTER.reduce((text, [muster, lang]) => text.replace(muster, lang), label)
}
