// Slots W3: reine Logik des Reiters Kinder (ohne React). Filter nach Entscheidung 2 des Bauauftrags W3:
// Alle · Ohne Stammplatz · Testkonten zeigen (Standard an); Kinder ohne Stammplatz stehen oben.

import type { SlotsKinderZeile, Stammplatz } from '@/types/slotplan'
import { kinderSortiert } from '../slots.model'
import { wochentagName } from '../slotsFormat'

export const KINDER2_FILTER = ['alle', 'ohne'] as const
export type Kinder2Filter = (typeof KINDER2_FILTER)[number]

/**
 * ?filter=ohne; der Wochenplan verlinkt noch ?filter=kein_stammplatz (Kennzahl „Ohne Stammplatz“), das gilt mit.
 * Alte Planbilanz-Filter (reicht_nicht …) fallen auf „Alle“.
 */
export function filter2AusSuche(suche: URLSearchParams): Kinder2Filter {
  const f = suche.get('filter')
  return f === 'ohne' || f === 'kein_stammplatz' ? 'ohne' : 'alle'
}

/** ?test=aus blendet Testkonten aus; Standard: an. */
export function testkontenAusSuche(suche: URLSearchParams): boolean {
  return suche.get('test') !== 'aus'
}

/** Ohne Stammplatz zuerst, danach die bisherige Reihenfolge (Handlungsbedarf, laufender Vertrag, Beginn, Name). */
export function kinder2Sortiert(kinder: SlotsKinderZeile[]): SlotsKinderZeile[] {
  const sortiert = kinderSortiert(kinder)
  return [...sortiert.filter((k) => k.ohne_stammplatz), ...sortiert.filter((k) => !k.ohne_stammplatz)]
}

export function kinder2Gefiltert(
  kinder: SlotsKinderZeile[],
  { filter, testkonten, suche }: { filter: Kinder2Filter; testkonten: boolean; suche: string },
): SlotsKinderZeile[] {
  const q = suche.trim().toLocaleLowerCase('de')
  return kinder2Sortiert(kinder).filter(
    (k) =>
      (testkonten || !k.ist_test) &&
      (filter === 'alle' || k.ohne_stammplatz) &&
      (q === '' || (k.name ?? '').toLocaleLowerCase('de').includes(q)),
  )
}

/** Zahlen an den Filtern; „Alle“ und „Ohne Stammplatz“ folgen dem Schalter „Testkonten zeigen“. */
export function kinder2Anzahl(kinder: SlotsKinderZeile[], testkonten: boolean): { alle: number; ohne: number; test: number } {
  const sichtbar = kinder.filter((k) => testkonten || !k.ist_test)
  return {
    alle: sichtbar.length,
    ohne: sichtbar.filter((k) => k.ohne_stammplatz).length,
    test: kinder.filter((k) => k.ist_test).length,
  }
}

type T = (k: string, o?: Record<string, unknown>) => string

/** Altbestand ohne Raum (W1): das System verteilt je Termin. Fehlt das Feld (ältere Daten), gilt es als ohne Raum. */
export function ohneRaum(s: Pick<Stammplatz, 'raum_id'>): boolean {
  return s.raum_id == null
}

/** „Mo 14:00 · A1“, bei 14-täglich „Mo 14:00 · A1 (A-Woche)“, ohne Raum „Mo 14:00 · Raum: automatisch“. */
export function stammplatzKurz(
  s: Pick<Stammplatz, 'wochentag' | 'beginn' | 'takt' | 'raum_id' | 'raum_name'>,
  sprache: string,
  t: T,
): string {
  const raum = ohneRaum(s) ? t('kinder2.stamm.raumAuto') : (s.raum_name ?? '')
  const text = t('kinder2.stamm.kurz', { tag: wochentagName(s.wochentag, sprache), beginn: s.beginn, raum })
  return s.takt === 'woechentlich' ? text : t('kinder2.stamm.mitTakt', { text, takt: t(`takt.${s.takt}`) })
}
