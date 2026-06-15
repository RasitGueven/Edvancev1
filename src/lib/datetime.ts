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
