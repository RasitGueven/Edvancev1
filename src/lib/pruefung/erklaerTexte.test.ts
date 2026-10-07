import { describe, expect, it } from 'vitest'
import { erklaerFehlerSchluessel } from './erklaerTexte'

const f = (code: string, hint: string | null = null) => ({ code, hint, message: 'x', fehlt: null })

describe('erklaerFehlerSchluessel', () => {
  it('unterscheidet „freigegeben nur Admin“ vom fehlenden Recht', () => {
    expect(erklaerFehlerSchluessel(f('42501', 'freigegeben_nur_admin'))).toBe('fehlermeldung.freigegeben_nur_admin')
    expect(erklaerFehlerSchluessel(f('42501'))).toBe('fehlermeldung.kein_recht')
  })
  it('kennt die ED422-Schluessel, sonst Eingabe', () => {
    expect(erklaerFehlerSchluessel(f('ED422', 'veraltet'))).toBe('fehlermeldung.veraltet')
    expect(erklaerFehlerSchluessel(f('ED422', 'quatsch'))).toBe('fehlermeldung.eingabe')
    expect(erklaerFehlerSchluessel(null)).toBe('fehlermeldung.allgemein')
  })
})
