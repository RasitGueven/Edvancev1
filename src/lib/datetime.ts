// UTC in DB -> Anzeige Europe/Berlin (CLAUDE.md §10).
export function formatSessionDate(iso: string): string {
  return new Date(iso).toLocaleString('de-DE', {
    timeZone: 'Europe/Berlin',
    weekday: 'long',
    day: '2-digit',
    month: 'long',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Zerlegt einen ISO-Timestamp in Jahr/Monat/Tag der Berliner Zeitzone. */
export function berlinYMD(iso: string): { y: number; m: number; d: number } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(iso))
  const get = (t: string): number =>
    Number(parts.find((x) => x.type === t)?.value)
  return { y: get('year'), m: get('month'), d: get('day') }
}

/** ISO-Kalenderwoche (ISO 8601) aus Jahr/Monat/Tag. */
export function isoWeek(y: number, m: number, d: number): { year: number; week: number } {
  const date = new Date(Date.UTC(y, m - 1, d))
  const day = (date.getUTCDay() + 6) % 7
  date.setUTCDate(date.getUTCDate() - day + 3)
  const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4))
  const fday = (firstThursday.getUTCDay() + 6) % 7
  firstThursday.setUTCDate(firstThursday.getUTCDate() - fday + 3)
  const week =
    1 + Math.round((date.getTime() - firstThursday.getTime()) / (7 * 864e5))
  return { year: date.getUTCFullYear(), week }
}

/** Datum + Uhrzeit (YYYY-MM-DD, HH:mm) einer Berliner Ortszeit als ISO-String in UTC. */
export function berlinLocalToIso(date: string, time: string): string {
  const [y, m, d] = date.split('-').map(Number)
  const [hh, mm] = time.split(':').map(Number)
  const wanted = Date.UTC(y, m - 1, d, hh, mm)
  // Zweimal ausgleichen: die erste Schaetzung kann an der Sommerzeitgrenze
  // auf der falschen Seite liegen.
  let guess = wanted
  for (let i = 0; i < 2; i += 1) {
    const p = berlinLocalParts(new Date(guess).toISOString())
    const [py, pm, pd] = p.date.split('-').map(Number)
    const [ph, pmin] = p.time.split(':').map(Number)
    guess += wanted - Date.UTC(py, pm - 1, pd, ph, pmin)
  }
  return new Date(guess).toISOString()
}

/** Zerlegt einen ISO-Timestamp in Berliner Datum (YYYY-MM-DD) und Uhrzeit (HH:mm). */
export function berlinLocalParts(iso: string): { date: string; time: string } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date(iso))
  const get = (t: string): string => parts.find((x) => x.type === t)?.value ?? ''
  return {
    date: `${get('year')}-${get('month')}-${get('day')}`,
    time: `${get('hour')}:${get('minute')}`,
  }
}

/** Heutiges Datum in Berlin als YYYY-MM-DD (fuer date-Inputs). */
export function berlinToday(now: Date = new Date()): string {
  return berlinLocalParts(now.toISOString()).date
}

/** Datum + Uhrzeit fuer Karten, Berliner Zeit, in der UI-Sprache. */
export function formatBerlinDateTime(iso: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, {
    timeZone: 'Europe/Berlin',
    weekday: 'short',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}

/** Reines Datum (YYYY-MM-DD aus einer date-Spalte) in der UI-Sprache. */
export function formatDateOnly(ymd: string, locale: string): string {
  const [y, m, d] = ymd.split('-').map(Number)
  return new Intl.DateTimeFormat(locale, {
    timeZone: 'UTC',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(Date.UTC(y, m - 1, d)))
}
