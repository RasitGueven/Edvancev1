// Die Mail zum LSA-Report als Vorschau (Bauauftrag LR-2, Entscheidung 7) —
// derselbe Text, den die Edge Function mail_senden (lsa_report.ts) verschickt.
//
// Beide Seiten lesen die Vorlage aus de/vertraege.json → mail.lsaReport* (die
// Edge Function über das erzeugte texte.ts, vorlagenGleich.test.ts hält beide
// gleich) und setzen dieselben Werte ein: Rufname vom Lead, LSA-Datum als
// TT.MM.JJJJ in Europe/Berlin. Die Mail geht immer auf Deutsch raus, deshalb
// fest 'de-DE' statt der UI-Sprache: die Vorschau zeigt, was die Eltern bekommen.
//
// Der Dateiname des Anhangs ist der Drucktitel des Bogens mit .pdf
// (Entscheidung 2); ReportPage druckt mit demselben Schlüssel.

import type { Lead } from '@/types'

const DATUM = new Intl.DateTimeFormat('de-DE', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
  timeZone: 'Europe/Berlin',
})

type Uebersetzer = (key: string, werte?: Record<string, string>) => string

export type LsaReportMail = { betreff: string; text: string; datei: string }

export type LsaReportEmpfaenger = Pick<Lead, 'full_name' | 'first_name' | 'contact_email'>

/** Wie lsa_report.ts: Rufname, sonst der volle Name. */
export function rufname(lead: Pick<Lead, 'full_name' | 'first_name'>): string {
  return (lead.first_name ?? '').trim() || lead.full_name
}

export function lsaReportMail(
  lead: Pick<Lead, 'full_name' | 'first_name'>,
  lsaDatum: string | null,
  testlauf: boolean,
  t: Uebersetzer,
): LsaReportMail {
  // Ohne Datum wie einsetzen() in der Edge Function: „—“ (kommt nicht vor, created_at ist Pflicht).
  const werte = { kind: rufname(lead), datum: lsaDatum ? DATUM.format(new Date(lsaDatum)) : '—' }
  return {
    betreff: (testlauf ? t('mail.lsaReportTestPraefix') : '') + t('mail.lsaReportBetreff', werte),
    text: t('mail.lsaReportText', werte),
    datei: `${t('mail.lsaReportDatei', werte)}.pdf`,
  }
}
