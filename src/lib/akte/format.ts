// Anzeigeformate der Schuelerakte. Nur Darstellung — gerechnet wird in der DB.

import { formatDateOnly } from '@/lib/datetime'

/** Zahl mit genau einer Nachkommastelle in der UI-Sprache. */
export function zahl1(wert: number, locale: string): string {
  return new Intl.NumberFormat(locale, { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(wert)
}

/** Datum (YYYY-MM-DD) oder Zeitpunkt (ISO) als Tagesdatum, Berliner Zeit. */
export function datum(wert: string, locale: string): string {
  if (/^\d{4}-\d{2}-\d{2}$/.test(wert)) return formatDateOnly(wert, locale)
  return new Intl.DateTimeFormat(locale, {
    timeZone: 'Europe/Berlin',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(wert))
}
