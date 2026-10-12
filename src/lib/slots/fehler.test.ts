import { describe, expect, it } from 'vitest'
import de from '@/i18n/locales/de/slots.json'
import { SLOTS_CODES, istSlotsCode, slotsFehlerSchluessel } from './fehler'

/** Slots SL1, Entscheidung 23: jeder SL-Code hat einen Text, Rohtexte der Datenbank erscheinen nie. */

const text = (schluessel: string): unknown =>
  schluessel.split('.').reduce<unknown>((o, k) => (o as Record<string, unknown> | undefined)?.[k], de)

describe('slotsFehlerSchluessel', () => {
  it('bildet jeden SL-Code auf einen eigenen Text ab', () => {
    for (const code of SLOTS_CODES) {
      const k = slotsFehlerSchluessel({ code, hint: code })
      expect(k).toBe(`fehler.${code}`)
      expect(typeof text(k)).toBe('string')
    }
  })

  it('nimmt den Hinweis vor dem SQLSTATE', () => {
    expect(slotsFehlerSchluessel({ code: '22023', hint: 'nur_am_tag' })).toBe('fehler.nurAmTag')
    expect(slotsFehlerSchluessel({ code: '22023', hint: 'zustand:cancelled' })).toBe('fehler.zustand')
    expect(slotsFehlerSchluessel({ code: '22023', hint: null })).toBe('fehler.eingabe')
  })

  it('kennt Rechte, Nicht-gefunden und Unbekanntes', () => {
    expect(slotsFehlerSchluessel({ code: '42501' })).toBe('fehler.keinRecht')
    expect(slotsFehlerSchluessel({ code: 'P0002' })).toBe('fehler.nichtGefunden')
    expect(slotsFehlerSchluessel({ code: 'XX000' })).toBe('fehler.allgemein')
    expect(slotsFehlerSchluessel(null)).toBe('fehler.allgemein')
  })

  it('hat für jeden möglichen Schlüssel einen Text', () => {
    const hinweise = ['nur_am_tag', 'testkonto', 'eingang', 'zustand', 'name_doppelt', 'zeit_doppelt', 'kein_coach', 'kein_vorschlag']
    const codes = ['42501', 'P0002', '22023', 'ZG001', 'XX000']
    for (const h of hinweise) expect(typeof text(slotsFehlerSchluessel({ code: '22023', hint: h }))).toBe('string')
    for (const c of codes) expect(typeof text(slotsFehlerSchluessel({ code: c }))).toBe('string')
  })

  it('erkennt SL-Codes', () => {
    expect(istSlotsCode('SL012')).toBe(true)
    expect(istSlotsCode('SL013')).toBe(false)
    expect(istSlotsCode(undefined)).toBe(false)
  })
})
