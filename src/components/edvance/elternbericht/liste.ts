// Eltern-Bericht R7 — gemeinsame Text-Hilfen für Seiten und Präsentation.
//
// Die Aufzählung (bis drei Labels, darüber „… und n weitere“) stand bis R7-11
// nur in Seite4.tsx; Seite 1 und Station 01/04 brauchen sie jetzt auch.

import type { TFunction } from 'i18next'

import type { EbSchwerpunkt, TpSchwerpunkt } from '@/types'

/** Bis zu so vielen Labels als Aufzählung, darüber „… und n weitere“. */
export const LISTE_VOLL = 3

export type Liste = (labels: readonly string[]) => string

/** Die Aufzählung in der Sprache von i18n, mit dem Rest über `liste.weitere`. */
export function baueListe(t: TFunction<'elternbericht'>, sprache: string): Liste {
  const format = new Intl.ListFormat(sprache, { style: 'long', type: 'conjunction' })
  return (labels) =>
    labels.length <= LISTE_VOLL
      ? format.format(labels)
      : t('liste.weitere', {
          liste: labels.slice(0, LISTE_VOLL).join(', '),
          count: labels.length - LISTE_VOLL,
        })
}

/** Titel eines Schwerpunkts: das Thema der LSA oder der Name des Themenfelds. */
export function schwerpunktTitel(
  t: TFunction<'elternbericht'>,
  s: Pick<EbSchwerpunkt | TpSchwerpunkt, 'feld' | 'thema'>,
): string {
  return s.thema ?? t(`feld.${s.feld ?? 'weitere'}`)
}

/** Ein stabiler React-key je Schwerpunkt (ohne Schlüssel im Text, INV-4.3). */
export const schwerpunktKey = (s: Pick<EbSchwerpunkt, 'feld' | 'thema'>): string => s.feld ?? 'thema'
