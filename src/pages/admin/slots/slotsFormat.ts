// Slots SL2: Datum, Uhrzeit und Kürzel für die Anzeige. Über Intl in Europe/Berlin (Bauauftrag Slots,
// Entscheidung 29): kurz "Do 16.03.", lang "Donnerstag, 16. März". ISO-Tage ('YYYY-MM-DD') sind
// Kalendertage und werden über UTC gerechnet, damit keine Zeitzone sie verschiebt.

function utc(isoTag: string): Date {
  const [y, m, d] = isoTag.split('-').map(Number)
  return new Date(Date.UTC(y, m - 1, d))
}

function teile(datum: Date, sprache: string, optionen: Intl.DateTimeFormatOptions, zone = 'UTC'): Record<string, string> {
  const out: Record<string, string> = {}
  for (const p of new Intl.DateTimeFormat(sprache, { ...optionen, timeZone: zone }).formatToParts(datum)) out[p.type] = p.value
  return out
}

/** Kurzer Wochentag ohne Punkt: "Do". */
export function wochentagKurz(isoTag: string, sprache: string): string {
  return teile(utc(isoTag), sprache, { weekday: 'short' }).weekday.replace(/\.$/, '')
}

/** Kurzer Wochentag zu ISO-Wochentag 1–5 (Montag = 1). */
export function wochentagName(isoWochentag: number, sprache: string, lang = false): string {
  // 2024-01-01 ist ein Montag.
  const tag = `2024-01-0${isoWochentag}`
  return lang ? teile(utc(tag), sprache, { weekday: 'long' }).weekday : wochentagKurz(tag, sprache)
}

/** "Do 16.03." */
export function datumKurz(isoTag: string, sprache: string): string {
  const p = teile(utc(isoTag), sprache, { day: '2-digit', month: '2-digit' })
  return `${wochentagKurz(isoTag, sprache)} ${p.day}.${p.month}.`
}

/** "16.03.2028" */
export function datumVoll(isoTag: string, sprache: string): string {
  return new Intl.DateTimeFormat(sprache, { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: 'UTC' }).format(utc(isoTag))
}

/** "Donnerstag, 16. März" */
export function datumLang(isoTag: string, sprache: string): string {
  return new Intl.DateTimeFormat(sprache, { weekday: 'long', day: 'numeric', month: 'long', timeZone: 'UTC' }).format(utc(isoTag))
}

/** Zeitpunkt (ISO mit Zone) als "Mi 18:40" in Berlin. */
export function zeitpunktKurz(iso: string, sprache: string): string {
  const p = teile(new Date(iso), sprache, { weekday: 'short', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }, 'Europe/Berlin')
  return `${p.weekday.replace(/\.$/, '')} ${p.hour}:${p.minute}`
}

/** Uhrzeit eines Zeitpunkts in Berlin: "08:12". */
export function uhrzeit(iso: string, sprache: string): string {
  const p = teile(new Date(iso), sprache, { hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }, 'Europe/Berlin')
  return `${p.hour}:${p.minute}`
}

/** Fach-Kürzel in neutralen Chips (Entscheidung 28): "Mathematik" -> "M". Ohne Fach: "". */
export function fachKuerzel(fach: string | null | undefined): string {
  return fach ? fach.trim().charAt(0).toLocaleUpperCase('de') : ''
}

/** Zahl in der UI-Sprache (Prozent als Anteil 0–1). */
export function prozent(anteil: number, sprache: string): string {
  return new Intl.NumberFormat(sprache, { style: 'percent', maximumFractionDigits: 0 }).format(anteil)
}
