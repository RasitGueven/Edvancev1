import { describe, expect, it } from 'vitest'

import { UEBERSPRUNGEN_ANZEIGE } from '@/lib/report/praesentation/einstellungen'

describe('Einstellungen der Präsentation', () => {
  it('zählt „übersprungen" standardmäßig zum Übungsbedarf (wie der Druckbogen)', () => {
    expect(UEBERSPRUNGEN_ANZEIGE).toBe('kombiniert')
  })
})
