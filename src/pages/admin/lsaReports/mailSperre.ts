/**
 * Warum „Per E-Mail senden“ gesperrt ist (Bauauftrag LR-2, Entscheidung 8) —
 * null heißt frei. Nur diese fünf Gründe; der Grund steht als Tooltip am Knopf.
 * Reihenfolge: zuerst, was sich nicht ändern lässt, zuletzt, was der Admin
 * selbst behebt.
 */
export type MailLage = {
  admin: boolean
  /** Bericht, Pakete oder Empfänger laden noch. */
  laedt: boolean
  nichtAuswertbar: boolean
  /** Eltern-Mail am Lead (getrimmt); leer oder ohne Lead = keine. */
  elternMail: string | null
  /** Der Ausblick hat Änderungen, die noch nicht gespeichert sind. */
  ungespeichert: boolean
}

export type MailSperre = 'rolle' | 'laedt' | 'nichtAuswertbar' | 'keineMail' | 'ungespeichert'

export function mailSperre(lage: MailLage): MailSperre | null {
  if (!lage.admin) return 'rolle'
  if (lage.laedt) return 'laedt'
  if (lage.nichtAuswertbar) return 'nichtAuswertbar'
  if ((lage.elternMail ?? '').trim() === '') return 'keineMail'
  if (lage.ungespeichert) return 'ungespeichert'
  return null
}
