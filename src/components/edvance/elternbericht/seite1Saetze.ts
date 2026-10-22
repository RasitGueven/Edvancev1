// Eltern-Bericht R7 · Seite 1 — die Sätze für „Unser erster Ansatz“ mit Thema
// und für „Ihr Anliegen“ (Bauauftrag R7-11, Entscheidungen 8 und 12). Reine
// Funktionen über t wie themaSatz.ts, damit Seite 1 und Station 01 dieselben
// Sätze zeigen und die Zusammensetzung ohne Rendern prüfbar ist.

import type { TFunction } from 'i18next'

import type { EbAnliegen, EbSchwerpunkt } from '@/types'

import { schwerpunktTitel, type Liste } from './liste'

/**
 * Der eine Satz unter der Startstelle (R7-11, Nachbesserung 1): was direkt
 * darauf aufbaut, sonst „Hier setzen wir zuerst an.“ Kein Bereichsname wird
 * gebeugt, er steht als Subjekt im Satz.
 */
export function ansatzThemaSatz(t: TFunction<'elternbericht'>, s: EbSchwerpunkt): string {
  return s.naechster
    ? t('s1.blick.ansatzThema.naechster', { naechster: s.naechster })
    : t('s1.blick.ansatzThema.zuerst')
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
