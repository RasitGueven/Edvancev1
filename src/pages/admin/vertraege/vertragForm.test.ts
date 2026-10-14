import { describe, expect, it } from 'vitest'
import type { Vertrag } from '@/types'
import { einheitenGueltig, isDirty, pilotVorschlagFuellen, toFormState, toPatch } from './vertragForm'

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

// V5: Pilotvereinbarung im Formular.
describe('vertragForm: Pilot', () => {
  const pilot = {
    ...base,
    vertragsart: 'pilot',
    vertrag_ende: '2027-07-16',
    einheiten: 34,
  } as unknown as Vertrag

  it('ein Altbestand ohne Vertragsart ist regulaer, Ende und Einheiten bleiben aussen vor', () => {
    const form = toFormState({ ...base, vertrag_ende: '2027-04-30', einheiten: 24 } as Vertrag)
    expect(form.vertragsart).toBe('regulaer')
    expect(form.vertrag_ende).toBe('')
    const patch = toPatch(form)
    expect(patch.vertragsart).toBe('regulaer')
    expect('vertrag_ende' in patch).toBe(false)
    expect('einheiten' in patch).toBe(false)
  })

  it('schreibt beim Pilot Ende und Einheiten und leert Paket und Laufzeit', () => {
    const form = toFormState(pilot)
    expect(form.vertrag_ende).toBe('2027-07-16')
    expect(form.einheiten).toBe('34')
    const patch = toPatch({ ...form, tier_id: 't1', laufzeit_monate: '12' })
    expect(patch).toMatchObject({
      vertragsart: 'pilot',
      tier_id: null,
      laufzeit_monate: null,
      vertrag_ende: '2027-07-16',
      einheiten: 34,
    })
    expect(isDirty(form, pilot)).toBe(false)
  })

  it('der Vorschlag fuellt nur leere Felder eines Pilots', () => {
    const vorschlag = { ende: '2027-07-16', einheiten: 34 }
    const leer = { ...toFormState(base), vertragsart: 'pilot' as const }
    expect(pilotVorschlagFuellen(leer, vorschlag)).toEqual({ vertrag_ende: '2027-07-16', einheiten: '34' })
    expect(pilotVorschlagFuellen({ ...leer, einheiten: '20' }, vorschlag)).toBeNull()
    expect(pilotVorschlagFuellen({ ...leer, vertragsart: 'regulaer' }, vorschlag)).toBeNull()
    expect(pilotVorschlagFuellen(leer, null)).toBeNull()
  })

  it('Einheiten sind eine ganze Zahl groesser 0', () => {
    expect(einheitenGueltig('34')).toBe(true)
    expect(einheitenGueltig(' 7 ')).toBe(true)
    for (const falsch of ['0', '-3', '2.5', 'abc', '']) expect(einheitenGueltig(falsch)).toBe(false)
  })
})
