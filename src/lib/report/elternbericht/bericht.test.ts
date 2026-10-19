import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import {
  allesSicher,
  nichtsSicher,
  ohneKatalog,
} from '@/lib/report/elternbericht/fixtures/synthetisch'
import type { ReportData } from '@/types'

const bericht = (d: ReportData) =>
  baueElternbericht({ kompetenzen: d.erzaehlung.kompetenzen, katalog: d.erzaehlung.katalog, klasse: d.grade })

describe('baueElternbericht', () => {
  it('null ohne Kompetenzen oder ohne Katalog', () => {
    expect(bericht(ohneKatalog)).toBeNull()
    expect(baueElternbericht({ kompetenzen: [], katalog: ilkay.erzaehlung.katalog, klasse: 10 })).toBeNull()
  })

  it('ilkay: alles beisammen und in sich stimmig', () => {
    const b = bericht(ilkay)!
    expect(b.kopfFall).toBe('gemischt')
    expect(b.sicherListe).toHaveLength(b.zaehlung.sicher)
    expect(b.uebungListe).toHaveLength(b.zaehlung.uebung)
    // Die Pyramide zeigt dieselben Bereiche wie die Listen auf Seite 1.
    const inPyramide = b.pyramide.flatMap((e) => e.gruppen.flatMap((g) => g.eintraege.map((x) => x.skillKey)))
    const inListen = [...b.sicherListe, ...b.uebungListe].map((x) => x.skillKey)
    expect([...inPyramide].sort()).toEqual([...inListen].sort())
    expect(b.schwerpunkte[0].feld).toBe('geometrie')
  })

  it('kopfFall für alle drei Fälle', () => {
    expect(bericht(allesSicher)!.kopfFall).toBe('sicher')
    expect(bericht(nichtsSicher)!.kopfFall).toBe('uebung')
    expect(bericht(ilkay)!.kopfFall).toBe('gemischt')
  })

  it('jeder Fall außer ohneKatalog ergibt einen Bericht', () => {
    for (const [name, { data }] of Object.entries(FAELLE)) {
      expect(bericht(data) === null, name).toBe(name === 'ohneKatalog')
    }
  })
})
