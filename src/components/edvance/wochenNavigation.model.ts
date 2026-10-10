// Reine Datumslogik der WochenNavigation: Montage als ISO-Tage ('YYYY-MM-DD'), Berlin.
// Gerechnet wird über UTC-Mitternacht, damit Zeitumstellungen nichts verschieben.

import { berlinToday, isoWeek } from '@/lib/datetime'

function alsUtc(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(Date.UTC(y, m - 1, d))
}

function alsIso(datum: Date): string {
  return datum.toISOString().slice(0, 10)
}

/** Montag der Woche, in der `iso` liegt. */
export function montagVon(iso: string): string {
  const d = alsUtc(iso)
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7))
  return alsIso(d)
}

/** Montag `wochen` Wochen vor (negativ) oder nach `montag`. */
export function wocheVerschieben(montag: string, wochen: number): string {
  const d = alsUtc(montagVon(montag))
  d.setUTCDate(d.getUTCDate() + 7 * wochen)
  return alsIso(d)
}

/** Montag der aktuellen Woche in Berlin. */
export function dieseWoche(jetzt: Date = new Date()): string {
  return montagVon(berlinToday(jetzt))
}

/** ISO-Kalenderwoche eines Montags. */
export function kalenderwoche(montag: string): number {
  const [y, m, d] = montagVon(montag).split('-').map(Number)
  return isoWeek(y, m, d).week
}

/** "13.–17. März 2028" (Montag bis Freitag) in der UI-Sprache. */
export function wochenSpanne(montag: string, sprache: string): string {
  const von = alsUtc(montagVon(montag))
  const bis = alsUtc(wocheVerschieben(montag, 0))
  bis.setUTCDate(bis.getUTCDate() + 4)
  const format = new Intl.DateTimeFormat(sprache, { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })
  return typeof format.formatRange === 'function'
    ? format.formatRange(von, bis)
    : `${format.format(von)} – ${format.format(bis)}`
}
