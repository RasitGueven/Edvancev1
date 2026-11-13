import { describe, expect, it } from 'vitest'
import { EMPTY_INTAKE, intakeToLeadInput } from './formState'

describe('intakeToLeadInput · Kurs und Abschlussziel (SF-1)', () => {
  const basis = { ...EMPTY_INTAKE, full_name: 'Mia Beispiel', kurs_mathe: 'E' as const, abschlussziel: 'MSA' as const }

  it('speichert Kurs und Ziel bei Gesamt- und Sekundarschule', () => {
    for (const school_type of ['Gesamtschule', 'Sekundarschule'] as const) {
      const input = intakeToLeadInput({ ...basis, school_type })
      expect([input.kurs_mathe, input.abschlussziel]).toEqual(['E', 'MSA'])
    }
  })

  it('verwirft Kurs und Ziel bei anderen Schulformen und ohne Schulform', () => {
    for (const school_type of ['Gymnasium', 'Realschule', 'Hauptschule', null] as const) {
      const input = intakeToLeadInput({ ...basis, school_type })
      expect([input.kurs_mathe, input.abschlussziel]).toEqual([null, null])
    }
  })
})
