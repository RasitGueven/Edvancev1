// Die Vorschau der LSA-Report-Mail (LR-2) — derselbe Text wie in
// supabase/functions/mail_senden/lsa_report_test.ts.
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import { lsaReportMail, rufname } from './lsaReportMail'

const t = (k: string, v?: Record<string, string>): string => i18n.t(k, { ns: 'vertraege', ...v })
const LEAD = { full_name: 'ZZ_Ilkay Beispiel', first_name: 'ZZ_Ilkay' }

describe('lsaReportMail', () => {
  it('Betreff, Text und Dateiname wie die Edge Function', () => {
    const m = lsaReportMail(LEAD, '2026-10-24T08:30:00.000Z', false, t)
    expect(m.betreff).toBe('Lernstandsanalyse von ZZ_Ilkay – Ihr Bericht')
    expect(m.text).toContain('Anbei finden Sie den Bericht zur Lernstandsanalyse von ZZ_Ilkay vom 24.10.2026.')
    expect(m.text).toContain('was ZZ_Ilkay schon sicher kann, wo es noch hakt und wo wir ansetzen würden.')
    expect(m.text.endsWith('Herzliche Grüße\nIhr Edvance-Team')).toBe(true)
    expect(m.datei).toBe('Edvance LSA-Report ZZ_Ilkay 24.10.2026.pdf')
  })

  it('Datum in Europe/Berlin: kurz vor Mitternacht UTC ist schon der nächste Tag', () => {
    expect(lsaReportMail(LEAD, '2026-10-24T22:30:00.000Z', false, t).datei).toBe('Edvance LSA-Report ZZ_Ilkay 25.10.2026.pdf')
  })

  it('Testlauf: [Test] vor dem Betreff', () => {
    expect(lsaReportMail(LEAD, '2026-10-24T08:30:00.000Z', true, t).betreff).toBe('[Test] Lernstandsanalyse von ZZ_Ilkay – Ihr Bericht')
  })

  it('ohne Rufname der volle Name', () => {
    expect(rufname({ full_name: 'ZZ_Ilkay Beispiel', first_name: '  ' })).toBe('ZZ_Ilkay Beispiel')
  })
})
