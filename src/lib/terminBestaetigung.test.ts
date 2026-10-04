import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import { terminMail } from './terminBestaetigung'

// Die Vorschau der Terminbestaetigung. Die Vorlage ist die echte aus
// de/vertraege.json — dieselbe, die die Edge Function verschickt.

const t = (k: string, v?: Record<string, string>): string => i18n.t(k, { ns: 'vertraege', ...v })

const lead = {
  full_name: 'ZZ_Tim Beispiel',
  first_name: 'ZZ_Tim',
  // 14:00 UTC = 16:00 in Koeln (Sommerzeit bis 25.10.)
  erstgespraech_at: '2026-10-08T14:00:00.000Z',
}
const ORT = 'ZZ_Musterweg 1, 50667 Köln'

describe('terminMail', () => {
  it('nennt Termin in Berliner Zeit, Ort, Kind, Dauer und den Mitbring-Hinweis', () => {
    const m = terminMail(lead, ORT, t)
    expect(m).not.toBeNull()
    expect(m?.betreff).toBe('Ihr Erstgespräch bei Edvance am Donnerstag, 8. Oktober 2026')
    expect(m?.text).toContain('Termin: Donnerstag, 8. Oktober 2026, 16:00 Uhr')
    expect(m?.text).toContain(`Ort: ${ORT}`)
    expect(m?.text).toContain('mit ZZ_Tim:')
    expect(m?.text).toContain(
      'Dauer: etwa 60 Minuten – Gespräch und eine 20-minütige Lernstandsanalyse am Tablet',
    )
    expect(m?.text).toContain(
      'Bitte bringen Sie mit: das Mathe-Heft (Schulheft), das Hausaufgabenheft und – falls vorhanden – die letzte Klassenarbeit.',
    )
    expect(m?.text).toMatch(/^Guten Tag,/)
    expect(m?.text).not.toContain('{{')
  })

  it('setzt den Ort getrimmt ein', () => {
    expect(terminMail(lead, `  ${ORT}  `, t)?.text).toContain(`Ort: ${ORT}\n`)
  })

  it('faellt ohne Rufnamen auf den vollen Namen zurueck', () => {
    expect(terminMail({ ...lead, first_name: null }, ORT, t)?.text).toContain('mit ZZ_Tim Beispiel:')
  })

  it('liefert ohne Termin nichts', () => {
    expect(terminMail({ ...lead, erstgespraech_at: null }, ORT, t)).toBeNull()
  })
})
