import { describe, expect, it } from 'vitest'

import { themaAbdeckung, type ThemaAbdeckungEingabe } from '@/lib/report/elternbericht/themaAbdeckung'
import type { Themenraum } from '@/types'

const RAUM: Themenraum = {
  themaKey: 'reelle_zahlen',
  einstieg: ['e1', 'e2'],
  darunter: ['d1', 'd2', 'd3', 'd4'],
  herkunft: 'abschluss',
}

const ein = (aenderung: Partial<ThemaAbdeckungEingabe>): ThemaAbdeckungEingabe => ({
  modus: 'adaptiv',
  raum: RAUM,
  themaLabel: 'Reelle Zahlen',
  direkt: ['e1', 'd1'],
  abgeleitet: ['d2', 'd3'],
  ...aenderung,
})

describe('themaAbdeckung', () => {
  it('null bei fester LSA oder ohne Modus', () => {
    expect(themaAbdeckung(ein({ modus: 'fest' }))).toBeNull()
    expect(themaAbdeckung(ein({ modus: null }))).toBeNull()
  })

  it('null ohne Raum, mit leerem Raum oder ohne Label', () => {
    expect(themaAbdeckung(ein({ raum: null }))).toBeNull()
    expect(themaAbdeckung(ein({ raum: { ...RAUM, einstieg: [], darunter: [] } }))).toBeNull()
    expect(themaAbdeckung(ein({ themaLabel: null }))).toBeNull()
  })

  it('nur ein Raum vom Abschluss zählt: nachgetragen und berechnet ergeben null', () => {
    expect(themaAbdeckung(ein({}))).not.toBeNull()
    expect(themaAbdeckung(ein({ raum: { ...RAUM, herkunft: 'nachgetragen' } }))).toBeNull()
    expect(themaAbdeckung(ein({ raum: { ...RAUM, herkunft: 'berechnet' } }))).toBeNull()
  })

  it('null, wenn im Raum nichts direkt geprüft wurde', () => {
    expect(themaAbdeckung(ein({ direkt: ['x1', 'x2'] }))).toBeNull()
  })

  it('offen 0: alles übrige ergibt sich', () => {
    expect(themaAbdeckung(ein({ abgeleitet: ['d2', 'd3', 'd4', 'e2'] }))).toEqual({
      thema: 'Reelle Zahlen',
      umfang: 6,
      direkt: 2,
      abgeleitet: 4,
      offen: 0,
    })
  })

  it('offen > 0', () => {
    expect(themaAbdeckung(ein({}))).toMatchObject({ umfang: 6, direkt: 2, abgeleitet: 2, offen: 2 })
  })

  it('abgeleitet 0', () => {
    expect(themaAbdeckung(ein({ abgeleitet: [] }))).toMatchObject({ direkt: 2, abgeleitet: 0, offen: 4 })
  })

  it('alle direkt', () => {
    expect(
      themaAbdeckung(ein({ direkt: ['e1', 'e2', 'd1', 'd2', 'd3', 'd4'], abgeleitet: ['d1'] })),
    ).toMatchObject({ umfang: 6, direkt: 6, abgeleitet: 0, offen: 0 })
  })

  it('zählt abgeleitete Schlüssel außerhalb des Raums und doppelte nicht', () => {
    expect(themaAbdeckung(ein({ abgeleitet: ['d2', 'x9', 'd2', 'e1'] }))).toMatchObject({
      direkt: 2,
      abgeleitet: 1,
      offen: 3,
    })
  })

  it('direkt außerhalb des Raums zählt nicht', () => {
    expect(themaAbdeckung(ein({ direkt: ['e1', 'x1', 'x2'] }))).toMatchObject({ direkt: 1 })
  })

  it('ein Schlüssel in einstieg und darunter zählt einmal', () => {
    expect(themaAbdeckung(ein({ raum: { ...RAUM, darunter: [...RAUM.darunter, 'e1'] } }))).toMatchObject({
      umfang: 6,
    })
  })
})
