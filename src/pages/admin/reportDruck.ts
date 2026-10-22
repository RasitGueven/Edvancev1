/**
 * Druck des Bogens mit sprechendem Dokumenttitel (Bauauftrag LR-1,
 * Entscheidung 5). Chrome und Safari schlagen den Titel beim „Als PDF
 * sichern“ als Dateinamen vor. Nach dem Druck (auch nach Abbrechen) kommt der
 * alte Titel zurück; `danach` läuft im selben Moment.
 */
export function druckeMitTitel(titel: string, danach?: () => void): void {
  const alt = document.title
  window.addEventListener(
    'afterprint',
    () => {
      document.title = alt
      danach?.()
    },
    { once: true },
  )
  document.title = titel
  window.print()
}

/** TT.MM.JJJJ in Europe/Berlin, über Intl statt von Hand. */
export function druckDatum(iso: string, sprache: string): string {
  return new Intl.DateTimeFormat(sprache, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Europe/Berlin',
  }).format(new Date(iso))
}

/** Wartet auf die Schriften und zwei Frames, damit der Bogen steht. */
export async function bogenBereit(): Promise<void> {
  await (document.fonts?.ready ?? Promise.resolve())
  await new Promise<void>((fertig) =>
    requestAnimationFrame(() => requestAnimationFrame(() => fertig())),
  )
}
