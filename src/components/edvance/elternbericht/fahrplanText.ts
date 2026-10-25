// Eltern-Bericht v4 — Texte und Farbton einer Station des Fahrplans.
// Reine Funktionen über t; Leiste, Seite 1, Seite 3 und Seite 5 teilen sie.

import type { TFunction } from 'i18next'

import type { EbFahrplan, EbStation } from '@/types'

type T = TFunction<'elternbericht'>

/** Farbton einer Station: das Signal, bei der aktuellen ihr Stand. */
export type Ton = 'fehlt' | 'erfuellt' | 'ohne' | 'geschrieben' | 'naechste' | 'aktuell'

export function tonVon(s: EbStation): Ton {
  if (s.signal) return s.signal
  return s.stand === 'geschrieben' ? 'geschrieben' : s.stand === 'naechste' ? 'naechste' : 'aktuell'
}

/** „nächste Arbeit · 2. Halbjahr“, „geschrieben · Note 4“; Halbjahr und Note nur, wenn bekannt. */
export function standZeile(t: T, s: EbStation): string {
  return [
    t(`v4.stand.${s.stand}`),
    s.stand === 'geschrieben' && s.note !== null ? t('v4.stand.note', { note: s.note }) : null,
    s.halbjahr ? t('v4.stand.halbjahr', { halbjahr: s.halbjahr }) : null,
  ]
    .filter((x): x is string => Boolean(x))
    .join(t('s2.profil.trenner'))
}

/** „Voraussetzungen fehlen noch“ usw.; null bei der aktuellen Station. */
export const signalText = (t: T, s: EbStation): string | null => (s.signal ? t(`v4.signal.${s.signal}`) : null)

/** Vorlesetext einer Station: „Klassenarbeit 2: Quadratische Funktionen, nächste Arbeit“. */
export const stationAria = (t: T, s: EbStation): string =>
  t('v4.leiste.aria', { n: s.nummer, thema: s.titel, stand: standZeile(t, s) })

/**
 * Trenner vor Station i: „Klasse k“ beim Wechsel ins nächste Schuljahr,
 * „Halbjahreszeugnis“ beim Wechsel vom 1. ins 2. Halbjahr (nur wenn der Plan
 * Halbjahre liefert).
 */
export function trennerVor(f: EbFahrplan, i: number): 'klasse' | 'halbjahr' | null {
  const s = f.stationen[i]
  const vorher = f.stationen.slice(0, i)
  if (i === 0 || !s) return null
  if (s.schuljahr === 'naechstes') {
    return vorher[vorher.length - 1]?.schuljahr === 'dieses' && f.klassenTrenner !== null ? 'klasse' : null
  }
  const letztes = [...vorher].reverse().find((x) => x.halbjahr !== null)?.halbjahr
  return f.halbjahrTrenner && s.halbjahr === 2 && letztes === 1 ? 'halbjahr' : null
}

export const trennerText = (t: T, f: EbFahrplan, art: 'klasse' | 'halbjahr'): string =>
  art === 'klasse' ? t('v4.stand.klasse', { klasse: f.klassenTrenner }) : t('v4.stand.zeugnis')
