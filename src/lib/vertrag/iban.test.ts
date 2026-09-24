import { describe, expect, it } from 'vitest'
import { formatIban, isValidIban, maskIban, normalizeIban } from './iban'

describe('isValidIban', () => {
  it('akzeptiert eine gueltige deutsche IBAN, auch mit Leerzeichen', () => {
    expect(isValidIban('DE89 3704 0044 0532 0130 00')).toBe(true)
    expect(isValidIban('de89370400440532013000')).toBe(true)
  })

  it('akzeptiert gueltige auslaendische IBAN', () => {
    expect(isValidIban('AT611904300234573201')).toBe(true)
    expect(isValidIban('NL91ABNA0417164300')).toBe(true)
  })

  it('lehnt eine falsche Pruefsumme ab', () => {
    expect(isValidIban('DE89370400440532013001')).toBe(false)
  })

  it('lehnt deutsche IBAN mit falscher Laenge ab', () => {
    expect(isValidIban('DE8937040044053201300')).toBe(false)
  })

  it('lehnt Unsinn ab', () => {
    expect(isValidIban('')).toBe(false)
    expect(isValidIban('1234')).toBe(false)
  })
})

describe('Anzeige', () => {
  it('normalisiert, maskiert und gruppiert', () => {
    expect(normalizeIban(' de89-3704 0044 0532 0130 00 ')).toBe('DE89370400440532013000')
    expect(maskIban('DE89370400440532013000')).toBe('DE** **** 3000')
    expect(formatIban('DE89370400440532013000')).toBe('DE89 3704 0044 0532 0130 00')
  })
})
