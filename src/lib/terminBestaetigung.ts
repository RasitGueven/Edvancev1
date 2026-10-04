// Die Terminbestaetigung zum Erstgespraech als Vorschau — derselbe Text, den
// die Edge Function mail_senden (termin.ts) verschickt.
//
// Beide Seiten lesen die Vorlage aus de/vertraege.json → mail.termin* (die
// Edge Function ueber das erzeugte texte.ts, vorlagenGleich.test.ts haelt beide
// gleich) und formatieren Datum und Uhrzeit mit denselben Intl-Optionen. Die
// Mail geht immer auf Deutsch raus, deshalb hier fest 'de-DE' statt der
// UI-Sprache: die Vorschau zeigt, was die Eltern bekommen.

import type { Lead } from '@/types'

const ZONE = 'Europe/Berlin'
const DATUM = new Intl.DateTimeFormat('de-DE', {
  weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: ZONE,
})
const UHRZEIT = new Intl.DateTimeFormat('de-DE', {
  hour: '2-digit', minute: '2-digit', timeZone: ZONE,
})

/** Ein Wert, der vor dem Echtbetrieb noch eingetragen werden muss. */
const PLATZHALTER = /\[[^\]]*FEHLT[^\]]*\]/

type Uebersetzer = (key: string, werte?: Record<string, string>) => string

export type TerminMail = {
  betreff: string
  text: string
  /** true = ein Wert fehlt noch (z. B. die Adresse); so nicht versenden. */
  platzhalter: boolean
}

export function terminMail(
  lead: Pick<Lead, 'full_name' | 'first_name' | 'erstgespraech_at' | 'erstgespraech_standort'>,
  t: Uebersetzer,
): TerminMail | null {
  if (!lead.erstgespraech_at) return null
  const termin = new Date(lead.erstgespraech_at)
  const werte = {
    kind: (lead.first_name ?? '').trim() || lead.full_name,
    datum: DATUM.format(termin),
    uhrzeit: UHRZEIT.format(termin),
    ort: t(`mail.terminOrt_${lead.erstgespraech_standort ?? 'koeln'}`),
    dauer: t('mail.terminDauer'),
  }
  const text = t('mail.terminText', werte)
  return { betreff: t('mail.terminBetreff', werte), text, platzhalter: PLATZHALTER.test(text) }
}
