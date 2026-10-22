// Eltern-Bericht R7 · Seite 1 — die Sätze für „Unser erster Ansatz“ mit Thema
// und für „Ihr Anliegen“ (Bauauftrag R7-11, Entscheidungen 8 und 12). Reine
// Funktionen über t wie themaSatz.ts, damit Seite 1 und Station 01 dieselben
// Sätze zeigen und die Zusammensetzung ohne Rendern prüfbar ist.

import type { TFunction } from 'i18next'

import type { EbAnliegen, EbSchwerpunkt } from '@/types'

import { schwerpunktTitel, type Liste } from './liste'

/**
 * Der Ansatz für den Thema-Schwerpunkt: was sicher ist, wo es Übung braucht,
 * wo wir beginnen. Ohne Übungsbedarf im Thema der Satz `ansatzThemaSicher`.
 */
export function ansatzThemaSaetze(
  t: TFunction<'elternbericht'>,
  s: EbSchwerpunkt,
  name: string | null,
  liste: Liste,
): string[] {
  if (s.uebung.length === 0) return [t('s1.blick.ansatzThemaSicher', { thema: s.thema })]
  const uebung = liste(s.uebung)
  return [
    ...(s.sicher.length > 0
      ? [t('s1.blick.ansatzThema.sicher', { liste: liste(s.sicher), count: s.sicher.length })]
      : []),
    name
      ? t('s1.blick.ansatzThema.uebung', { name, liste: uebung })
      : t('s1.blick.ansatzThema.uebungOhneName', { liste: uebung }),
    t('s1.blick.ansatzThema.start', { start: s.start, count: s.uebung.length }),
  ]
}

/**
 * „Ihr Anliegen“ als Frage und Antwort. Die Rückbezüge hängt der Aufrufer an;
 * sie kommen aus der Datenbank, nicht aus i18n.
 */
export function anliegenSaetze(
  t: TFunction<'elternbericht'>,
  a: EbAnliegen,
  wessen: string | null,
  liste: Liste,
  sprache: string,
): string[] {
  const saetze: string[] = []
  if (a.thema) {
    saetze.push(t('s1.anliegen.thema', { thema: a.thema }))
    saetze.push(
      a.themaUebung.length > 0
        ? t('s1.anliegen.antwort', { liste: liste(a.themaUebung) })
        : t('s1.anliegen.antwortSicher'),
    )
  }
  if (a.punkte.length > 0) {
    // Die Anliegen selbst vollständig, wie bisher (keine Kürzung auf drei).
    const punkte = new Intl.ListFormat(sprache, { style: 'long', type: 'conjunction' }).format(a.punkte)
    saetze.push(
      wessen
        ? t('s1.anliegen.genannt', { wessen, punkte })
        : t('s1.anliegen.genanntOhneName', { punkte, count: a.punkte.length }),
    )
  }
  if (a.schwerpunkt) {
    saetze.push(t('s1.anliegen.antwortSchwerpunkt', { schwerpunkt: schwerpunktTitel(t, a.schwerpunkt) }))
  }
  if (a.naechstesThema) saetze.push(t('s1.anliegen.naechstesThema', { thema: a.naechstesThema }))
  return saetze
}
