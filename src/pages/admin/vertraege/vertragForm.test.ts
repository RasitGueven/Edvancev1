import { describe, expect, it } from 'vitest'
import type { Vertrag } from '@/types'
import { isDirty, toFormState, toPatch } from './vertragForm'

const base = {
  eltern_vorname: 'ZZ_Anna',
  eltern_nachname: null,
  strasse: null,
  hausnummer: null,
  plz: null,
  ort: null,
  eltern_telefon: null,
  eltern_email: null,
  kind_vorname: 'ZZ_Mia',
  kind_nachname: null,
  kind_geburtsdatum: null,
  fach: null,
  schule: null,
  tier_id: null,
  vertragsbeginn: null,
  kontoinhaber: null,
  klasse: 8,
  laufzeit_monate: null,
} as unknown as Vertrag

describe('vertragForm', () => {
  it('uebersetzt hin und zurueck, leer wird null', () => {
    const form = toFormState(base)
    expect(form.klasse).toBe('8')
    expect(form.eltern_nachname).toBe('')
    const patch = toPatch({ ...form, laufzeit_monate: '12', plz: ' 50667 ', ort: '  ' })
    expect(patch.laufzeit_monate).toBe(12)
    expect(patch.plz).toBe('50667')
    expect(patch.ort).toBeNull()
    expect(patch.klasse).toBe(8)
  })

  it('erkennt Aenderungen, auch eine neu eingegebene IBAN', () => {
    const form = toFormState(base)
    expect(isDirty(form, base)).toBe(false)
    expect(isDirty({ ...form, ort: 'Köln' }, base)).toBe(true)
    expect(isDirty({ ...form, iban: 'DE89' }, base)).toBe(true)
  })
})
