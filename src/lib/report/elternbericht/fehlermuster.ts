// Eltern-Bericht v2 — das Fehlermuster für Seite 1 und 4.
//
// Gezählt werden Fehlbild-Aufgaben (ReportFehlbild.aufgaben) je Familie. Die
// Kernaussage „eher Sorgfalt als fehlendes Verständnis“ steht nur, wenn die
// Daten sie tragen (SORGFALT in berichtKonfig.ts). Sonst nennt der Bericht die
// häufigste Familie mit ihrem abgenommenen Elterntext — oder nichts.

import { SORGFALT } from '@/lib/report/elternbericht/berichtKonfig'
import type { ReportFehlbild } from '@/types'

export type Fehlermuster = {
  /** Die Kernaussage „eher Sorgfalt“ ist gedeckt. */
  sorgfalt: boolean
  /** Fehlbild-Aufgaben insgesamt und aus den Sorgfalt-Familien. */
  aufgaben: number
  sorgfaltAufgaben: number
  /**
   * Ohne Kernaussage: der Elterntext der häufigsten Familie (mindestens zwei
   * Aufgaben, Text abgenommen); sonst null.
   */
  haeufigste: string | null
}

export function fehlermusterAus(fehlbilder: readonly ReportFehlbild[]): Fehlermuster | null {
  const jeFamilie = new Map<string, { aufgaben: number; text: string | null }>()
  for (const f of fehlbilder) {
    if (!f.familie) continue
    const alt = jeFamilie.get(f.familie) ?? { aufgaben: 0, text: null }
    jeFamilie.set(f.familie, { aufgaben: alt.aufgaben + f.aufgaben, text: alt.text ?? f.familieElterntext })
  }
  if (jeFamilie.size === 0) return null

  const familien = SORGFALT.familien as readonly string[]
  let aufgaben = 0
  let sorgfaltAufgaben = 0
  for (const [familie, f] of jeFamilie) {
    aufgaben += f.aufgaben
    if (familien.includes(familie)) sorgfaltAufgaben += f.aufgaben
  }
  const sorgfalt = sorgfaltAufgaben >= SORGFALT.minAufgaben && sorgfaltAufgaben / aufgaben >= SORGFALT.minAnteil

  const [erste, zweite] = [...jeFamilie.values()].sort((a, b) => b.aufgaben - a.aufgaben)
  const eindeutig = erste.aufgaben >= 2 && (!zweite || erste.aufgaben > zweite.aufgaben)
  return { sorgfalt, aufgaben, sorgfaltAufgaben, haeufigste: !sorgfalt && eindeutig ? erste.text : null }
}
