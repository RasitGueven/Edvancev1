import { afterEach, describe, expect, it } from 'vitest'
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
  erstgespraech_standort: 'koeln' as const,
}

const ORT = 'mail.terminOrt_koeln'
const original = i18n.t(ORT, { ns: 'vertraege' })

afterEach(() => {
  i18n.addResource('de', 'vertraege', ORT, original)
})

describe('terminMail', () => {
  it('nennt Termin in Berliner Zeit, Kind, Dauer und den Mitbring-Hinweis', () => {
    const m = terminMail(lead, t)
    expect(m).not.toBeNull()
    expect(m?.betreff).toBe('Ihr Erstgespräch bei Edvance am Donnerstag, 8. Oktober 2026')
    expect(m?.text).toContain('Termin: Donnerstag, 8. Oktober 2026, 16:00 Uhr')
    expect(m?.text).toContain('mit ZZ_Tim:')
    expect(m?.text).toContain('Dauer: etwa 60 Minuten')
    expect(m?.text).toContain(
      'Bitte bringen Sie mit: das Mathe-Heft (Schulheft), das Hausaufgabenheft und – falls vorhanden – die letzte Klassenarbeit.',
    )
    expect(m?.text).toMatch(/^Guten Tag,/)
    expect(m?.text).not.toContain('{{')
  })

  it('meldet den Platzhalter, solange die Adresse fehlt', () => {
    expect(terminMail(lead, t)?.platzhalter).toBe(true)
    i18n.addResource('de', 'vertraege', ORT, 'ZZ_Teststraße 1, 50667 Köln')
    const m = terminMail(lead, t)
    expect(m?.platzhalter).toBe(false)
    expect(m?.text).toContain('Ort: ZZ_Teststraße 1, 50667 Köln')
  })

  it('faellt ohne Rufnamen auf den vollen Namen zurueck', () => {
    expect(terminMail({ ...lead, first_name: null }, t)?.text).toContain('mit ZZ_Tim Beispiel:')
  })

  it('liefert ohne Termin nichts', () => {
    expect(terminMail({ ...lead, erstgespraech_at: null }, t)).toBeNull()
  })
})
