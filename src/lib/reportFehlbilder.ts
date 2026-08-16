// Eltern-Report — Bündelung der Fehlbilder auf Familienebene (AF4/AF5/R2).
//
// Fünf Fehlbilder derselben Familie sind für Eltern EINE Information, nicht
// fünf. Der Coach sieht weiterhin jeden Einzelbefund über lsa_fehlbild_report;
// gebündelt wird ausschließlich die Elternsicht.
//
// ----------------------------------------------------------------------------
// R2: erst bündeln, dann die Schwelle — nicht umgekehrt
// ----------------------------------------------------------------------------
// Bis R2 filterte lsaReport.loadFehlbilder auf einstufung='befund' und BÜNDELTE
// erst danach. Das verliert genau den Fall, für den die Bündelung gebaut wurde:
// in der Simulation verletzte das Kind zweimal die Rechenreihenfolge, in zwei
// verschiedenen Aufgaben — aber unter zwei verschiedenen Slugs
// (mult_add_verwechslung, vorrang_ignoriert). Jeder einzeln unter der Schwelle,
// die ganze Familie verschwand.
//
// Jetzt kommen ALLE Fehlbilder herein, werden je Familie summiert, und die
// Schwelle greift auf der Familie. Inhaltlich unverändert: mindestens zwei
// Vorkommen in mindestens zwei Aufgaben.
//
// Die Vorfilterung auf einstufung entfällt damit in lsaReport.loadFehlbilder.

import type { ReportFehlbild } from '@/types'

/** Mindestens so viele Vorkommen, sonst ist es ein Einzeltreffer. */
const MIN_ANZAHL = 2
/** Mindestens so viele verschiedene Aufgaben, sonst ist es eine Aufgabe. */
const MIN_AUFGABEN = 2

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
   * disjunkt.
   */
  anzahl: number
  /**
   * UNTERGRENZE der verschiedenen Aufgaben, in denen die Familie auftrat.
   *
   * Nicht die Summe von `aufgaben` über die Slugs: zwei Slugs derselben
   * Familie können DIESELBE Aufgabe treffen — bei einem MULTI_PART-Item trägt
   * jede Teilaufgabe ihren eigenen Slug, und beide können in derselben Familie
   * liegen. Die Summe würde dann doppelt zählen und die Schwelle zu früh
   * reißen. Wie die Untergrenze entsteht, steht bei `aufgabenUntergrenze`.
   */
  aufgaben: number
}

/**
 * Untergrenze der verschiedenen Aufgaben einer Familie.
 *
 * lsa_fehlbild_auswertung liefert KEINE Aufgaben-IDs — nur `aufgaben` (Anzahl
 * verschiedener Aufgaben je Slug) und `skills` (die Skills, in denen der Slug
 * auftrat). Daraus lässt sich die exakte Zahl nicht bilden, eine belastbare
 * Untergrenze aber schon, ohne zu schätzen:
 *
 *   Eine Aufgabe hat GENAU EINEN skill_key. Haben zwei Slugs disjunkte
 *   Skill-Mengen, können sie unmöglich dieselbe Aufgabe getroffen haben.
 *
 * Also: Slugs, die sich einen Skill teilen, zu Gruppen zusammenlegen; innerhalb
 * einer Gruppe das Maximum nehmen (Überlappung möglich), über Gruppen hinweg
 * summieren (Überlappung ausgeschlossen). Das Ergebnis überschätzt nie.
 *
 * Trägt ein Slug gar keinen Skill (Aufgabe ohne skill_key), ist über ihn nichts
 * beweisbar — dann fällt die ganze Familie auf das Maximum zurück. Lieber eine
 * zu strenge Schwelle als ein Befund, den die Daten nicht hergeben.
 */
export function aufgabenUntergrenze(fehlbilder: readonly ReportFehlbild[]): number {
  if (fehlbilder.length === 0) return 0
  if (fehlbilder.some((f) => f.skills.length === 0)) {
    return Math.max(...fehlbilder.map((f) => f.aufgaben))
  }

  type Gruppe = { skills: Set<string>; max: number }
  const gruppen: Gruppe[] = []

  for (const fb of fehlbilder) {
    const eigene = new Set(fb.skills)
    const verwandt = gruppen.filter((g) => [...g.skills].some((s) => eigene.has(s)))
    if (verwandt.length === 0) {
      gruppen.push({ skills: eigene, max: fb.aufgaben })
      continue
    }
    // Alle berührten Gruppen verschmelzen — ein Slug kann zwei bisher getrennte
    // Gruppen über einen gemeinsamen Skill verbinden (skill_uebergreifend).
    const verschmolzen: Gruppe = { skills: eigene, max: fb.aufgaben }
    for (const g of verwandt) {
      g.skills.forEach((s) => verschmolzen.skills.add(s))
      verschmolzen.max = Math.max(verschmolzen.max, g.max)
      gruppen.splice(gruppen.indexOf(g), 1)
    }
    gruppen.push(verschmolzen)
  }

  return gruppen.reduce((summe, g) => summe + g.max, 0)
}

/**
 * Bündelt die Befunde einer Sitzung auf ihre Familien und wendet DANACH die
 * Schwelle an.
 *
 * Weggelassen wird still — ohne Platzhalter, ohne Hinweis:
 *   - Fehlbilder ohne Familienzuordnung. Sie sind für den Coach ein Befund,
 *     für Eltern ohne Bündelsatz keine Aussage.
 *   - Familien ohne abgenommenen Elterntext (fehlbild_familien.freigegeben_am
 *     ist null). Ein unabgenommener Satz über das Denken eines Kindes darf die
 *     Elternfläche nicht erreichen; ein Platzhalter an seiner Stelle würde
 *     genau die Behauptung aufstellen, die die Abnahme verhindern soll.
 *   - Familien unter der Schwelle: weniger als zwei Vorkommen oder weniger als
 *     zwei verschiedene Aufgaben. Ein Einzeltreffer wäre eine Behauptung über
 *     das Denken eines Kindes auf Basis einer einzigen Aufgabe.
 *
 * Sortierung: Vorkommen absteigend, bei Gleichstand nach Familienschlüssel —
 * damit die Reihenfolge stabil ist und nicht von der Zeilenreihenfolge der RPC
 * abhängt.
 */
export function gruppiereFehlbilderNachFamilie(
  fehlbilder: readonly ReportFehlbild[],
): ReportFehlbildFamilie[] {
  const nachFamilie = new Map<string, ReportFehlbild[]>()

  for (const fb of fehlbilder) {
    const familie = fb.familie?.trim()
    const elterntext = fb.familieElterntext?.trim()
    if (!familie || !elterntext) continue
    const liste = nachFamilie.get(familie)
    if (liste) liste.push(fb)
    else nachFamilie.set(familie, [fb])
  }

  const blocks: ReportFehlbildFamilie[] = []
  for (const [familie, liste] of nachFamilie) {
    const anzahl = liste.reduce((summe, fb) => summe + fb.anzahl, 0)
    const aufgaben = aufgabenUntergrenze(liste)
    if (anzahl < MIN_ANZAHL || aufgaben < MIN_AUFGABEN) continue
    blocks.push({
      familie,
      // Alle Slugs einer Familie tragen denselben Satz — er hängt an der
      // Familie, nicht am Slug.
      elterntext: liste[0].familieElterntext!.trim(),
      anzahl,
      aufgaben,
    })
  }

  return blocks.sort(
    (a, b) => b.anzahl - a.anzahl || a.familie.localeCompare(b.familie, 'de'),
  )
}
