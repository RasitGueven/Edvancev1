// L5 Teil C (docs/report/Bauauftrag-L5.md, Entscheidungen 8–10): die Klassenarbeiten eines Kindes für den Fahrplan.
//
// Quelle ist ka_folge_lead (eigene Angaben, dazu der gültige Schulwert, soweit eigene Angaben mit Nummer ihn nicht
// abdecken). Für die Stationen zählen nur Arbeiten mit Nummer: Ohne Nummer ist nicht bekannt, die wievielte Arbeit es
// ist, und erfunden wird nichts. Themen einer Arbeit, die nicht im Plan stehen, entfallen (es gibt keinen Titel).

import type { EbSignal, ReportKlassenarbeit } from '@/types'

/** Schuljahr eines Datums nach NRW-Zählung (ab 1. August), wie ka_schuljahr in SQL: '2026/27'. */
export function schuljahrVon(datum: string): string {
  const jahr = Number(datum.slice(0, 4))
  const monat = Number(datum.slice(5, 7))
  const beginn = monat >= 8 ? jahr : jahr - 1
  return `${beginn}/${String((beginn + 1) % 100).padStart(2, '0')}`
}

export type KaArbeit = {
  nr: number
  /** In Plan-Reihenfolge, nur Themen mit Plan-Titel. */
  themen: { themaKey: string; titel: string }[]
  datum: string | null
  /** Geschrieben laut Angabe oder weil das Datum vor dem Tag der Sitzung liegt (berechnet, nicht gespeichert). */
  geschrieben: boolean
  note: number | null
  herkunft: 'eigen' | 'schule'
}

/**
 * Die Arbeiten mit Nummer, nach Nummer sortiert, mit Titeln aus dem Plan.
 * @param titel Plan-Titel je Thema in Plan-Reihenfolge (aktuelle und nächste Klasse).
 * @param tag Tag der Sitzung (ISO), Bezug für „Datum vorbei“.
 */
export function nummerierteArbeiten(
  arbeiten: readonly ReportKlassenarbeit[],
  titel: ReadonlyMap<string, string>,
  tag: string | null,
): KaArbeit[] {
  const rang = new Map([...titel.keys()].map((k, i) => [k, i]))
  return arbeiten
    .filter((a): a is ReportKlassenarbeit & { nr: number } => a.nr !== null)
    .map((a) => ({
      nr: a.nr,
      themen: a.themaKeys
        .filter((k) => titel.has(k))
        .sort((x, y) => (rang.get(x) ?? 0) - (rang.get(y) ?? 0))
        .map((k) => ({ themaKey: k, titel: titel.get(k) ?? k })),
      datum: a.datum,
      geschrieben: a.status === 'geschrieben' || (a.datum !== null && tag !== null && a.datum < tag),
      note: a.status === 'geschrieben' ? a.note : null,
      herkunft: a.herkunft,
    }))
    .filter((a) => a.themen.length > 0)
    .sort((x, y) => x.nr - y.nr)
}

/** Signal einer Arbeit = schlechtestes Signal ihrer Themen: fehlt vor erfuellt vor ohne (Entscheidung 10). */
export function schlechtestes(signale: readonly EbSignal[]): EbSignal {
  if (signale.includes('fehlt')) return 'fehlt'
  return signale.includes('erfuellt') ? 'erfuellt' : 'ohne'
}
