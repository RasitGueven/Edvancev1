// Eltern-Bericht R7 · Seite 1 — der Thema-Satz im Kasten „So haben wir geprüft“
// (Bauauftrag R7-6, Entscheidung 7). Reine Funktion über t, damit die
// Zusammensetzung ohne Rendern prüfbar ist.

import type { TFunction } from 'i18next'

import type { ThemaAbdeckung } from '@/lib/report/elternbericht/themaAbdeckung'

/**
 * Der Thema-Satz aus Teilsätzen, je Zahl mit Plural. Ist alles direkt geprüft,
 * folgt nur „Alle davon …“; sonst hängt an den direkten Teil, was sich ergibt,
 * und danach, was offen bleibt.
 */
export function themaSaetze(t: TFunction<'elternbericht'>, a: ThemaAbdeckung): string[] {
  const umfang = t('s1.thema.umfang', { thema: a.thema, count: a.umfang })
  if (a.direkt === a.umfang) return [umfang, t('s1.thema.alleDirekt')]

  const direkt = t('s1.thema.direkt', { count: a.direkt })
  const offen = a.offen > 0 ? [t('s1.thema.offen', { count: a.offen })] : []
  if (a.abgeleitet === 0) return [umfang, direkt + t('s1.thema.punkt'), ...offen]
  const art = a.offen > 0 ? 's1.thema.abgeleitetTeil' : 's1.thema.abgeleitetRest'
  return [umfang, direkt + t(art, { count: a.abgeleitet }), ...offen]
}
