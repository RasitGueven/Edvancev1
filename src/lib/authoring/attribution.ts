// Der Standard-Attributionstext (CC BY 4.0) — DIE eine Stelle.
//
// CC BY 4.0 verlangt beim Zeigen des Materials eine Namensnennung: Titel, Autor,
// Quelle, Lizenz, soweit verfuegbar (TASL). Fuer die VERA-8-Abbildungen ist der
// Rechteinhaber das IQB; der Quellenbeleg (_grounding) traegt Titel und die
// IQB-URL, aus denen sich die Nennung bauen laesst. Was der Beleg nicht hergibt,
// faellt weg — die Mindestform (Autor + Werk + Lizenz + Lizenz-URL) bleibt
// immer stehen und ist fuer sich schon rechtssicher.
//
// WARUM zentral: die Formel ist eine RECHTLICHE Zusage, keine Formatierung.
// Schaerft die Rechtsberatung sie spaeter (anderer Wortlaut, Jahr, Bearbeitungs-
// hinweis nach CC-BY §3.a.1.B), wird sie hier geaendert — und nirgends sonst.
//
// WARUM nicht durch i18n (§12): der Text ist kein UI-String, sondern INHALT, der
// in tasks.licence_text gespeichert und spaeter mit dem Bild eingeblendet wird —
// wie ein Aufgaben-Prompt. Er nennt einen deutschen Rechteinhaber in dessen
// amtlichem Namen und darf sich nicht mit der Anzeigesprache aendern; eine
// uebersetzte Namensnennung waere eine andere Namensnennung. Die Labels und
// Hinweise, die der Pfleger DRUMHERUM liest, laufen sehr wohl ueber i18n.

import type { AuthoringTask, GroundingRecord } from '@/types'

/** Die Lizenz, unter der die VERA-8-Materialien stehen. */
export const CC_BY_40_URL = 'https://creativecommons.org/licenses/by/4.0/'
export const CC_BY_40_LABEL = 'CC BY 4.0'

/** Der Rechteinhaber, ausgeschrieben — eine Abkuerzung allein nennt niemanden. */
const IQB_NAME = 'Institut zur Qualitätsentwicklung im Bildungswesen (IQB)'

/** Nur fuer diese Quelle kennen wir Rechteinhaber und Lizenz sicher. */
const VERA8_SOURCE = 'VERA8_IQB'

/**
 * Das Fach aus dem IQB-Dateipfad (…/VERA-8_Mathematik/xyz_Aufgabe.docx).
 * Steht nirgends als eigenes Feld im Beleg — der Pfad ist die einzige Quelle,
 * die es real hergibt. Kein Treffer = das Fach bleibt einfach weg.
 */
function subjectFromUrls(urls: Record<string, string> | undefined): string | null {
  if (!urls) return null
  for (const url of Object.values(urls)) {
    const match = /VERA-8_([A-Za-zÄÖÜäöüß]+)/.exec(url)
    if (match) return match[1]
  }
  return null
}

/** Die Aufgaben-URL beim IQB — der nachpruefbare Ort der Quelle. */
function sourceUrl(urls: Record<string, string> | undefined): string | null {
  if (!urls) return null
  return urls.aufgabe ?? Object.values(urls)[0] ?? null
}

/**
 * Der Standard-Attributionstext zu einem Item, oder null.
 *
 * null heisst „fuer diese Quelle koennen wir keinen Text VERANTWORTEN" — bei den
 * Fundament-Eigenbauten (Bruchrechnung, Prozent …) gibt es keinen Rechteinhaber
 * ausser uns, und ein geratener Lizenztext ist schlimmer als keiner. Der Pfleger
 * schreibt dann von Hand.
 *
 * `record` darf null sein: fehlt der Beleg, greift die Mindestform ohne Titel
 * und ohne Fach. Sie nennt weiterhin Autor, Werk und Lizenz — das traegt.
 */
export function buildAttribution(
  task: Pick<AuthoringTask, 'source'>,
  record: GroundingRecord | null,
): string | null {
  if (task.source !== VERA8_SOURCE) return null

  const title = record?.titel?.trim()
  const subject = subjectFromUrls(record?.iqb_urls)
  const url = sourceUrl(record?.iqb_urls)

  // Werk: „VERA-8" plus Fach, wenn der Beleg es hergibt.
  const werk = subject ? `VERA-8 ${subject}` : 'VERA-8'

  // Der Titel steht als eigener Satz voran, wenn es einen gibt.
  const sentences = [
    ...(title ? [`„${title}“.`] : []),
    `Quelle: ${IQB_NAME}, ${werk}${url ? ` (${url})` : ''}.`,
    `Lizenz: ${CC_BY_40_LABEL} (${CC_BY_40_URL}).`,
  ]
  return sentences.join(' ')
}
