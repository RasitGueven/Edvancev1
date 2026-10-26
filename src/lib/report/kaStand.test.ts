import { describe, expect, it } from 'vitest'

import type { ReportErstgespraech } from '@/types'

import { klassenarbeitDerSitzung } from './kaStand'

const lead = (klassenarbeit: ReportErstgespraech['klassenarbeit'], letzteNote: number | null = null): ReportErstgespraech => ({
  note: null,
  trend: null,
  seit: null,
  ziele: null,
  klassenarbeit,
  klassenarbeitDatum: null,
  letzteNote,
})

describe('klassenarbeitDerSitzung (LSA-L4, Entscheidung 13)', () => {
  it('ohne Modus (Sitzung vor L3) gilt der Lead', () => {
    const r = klassenarbeitDerSitzung(lead('geschrieben', 3), null, null)
    expect(r.erstgespraech?.klassenarbeit).toBe('geschrieben')
    expect(r.abweichung).toBeNull()
  })

  it('vorschau_zuerst: geschrieben mit der Note der Sitzung', () => {
    const r = klassenarbeitDerSitzung(lead('geschrieben', 4), 'vorschau_zuerst', 4)
    expect(r.erstgespraech).toMatchObject({ klassenarbeit: 'geschrieben', letzteNote: 4 })
    expect(r.abweichung).toBeNull()
  })

  it('Lead später geändert: Bericht zeigt die Sitzung, Abweichung nur als Hinweis', () => {
    const r = klassenarbeitDerSitzung(lead('geschrieben', 2), 'vorschau_zuerst', null)
    expect(r.erstgespraech).toMatchObject({ klassenarbeit: 'geschrieben', letzteNote: null })
    expect(r.abweichung).toEqual({ sitzung: { status: 'geschrieben', note: null }, lead: { status: 'geschrieben', note: 2 } })
  })

  it('thema_zuerst: bevorstehend bleibt, ein heutiges „geschrieben“ war beim Start nicht so', () => {
    expect(klassenarbeitDerSitzung(lead('bevorstehend'), 'thema_zuerst', null).erstgespraech?.klassenarbeit).toBe('bevorstehend')
    const r = klassenarbeitDerSitzung(lead('geschrieben', 3), 'thema_zuerst', null)
    expect(r.erstgespraech).toMatchObject({ klassenarbeit: null, letzteNote: null })
    expect(r.abweichung?.lead).toEqual({ status: 'geschrieben', note: 3 })
  })

  it('ohne Erstgespräch (Coach) nichts', () => {
    expect(klassenarbeitDerSitzung(null, 'vorschau_zuerst', 2)).toEqual({ erstgespraech: null, abweichung: null })
  })
})
