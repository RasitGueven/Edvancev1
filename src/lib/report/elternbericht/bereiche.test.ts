import { describe, expect, it } from 'vitest'

import {
  bereicheAus,
  kopfFall,
  sicherListe,
  uebungListe,
} from '@/lib/report/elternbericht/bereiche'
import { ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import { feldPosition } from '@/lib/report/elternbericht/themenfelder'

describe('bereicheAus', () => {
  it('ein Bereich je direkt geprüftem Skill, traegt = sicher', () => {
    const b = bereicheAus(ILKAY_URTEILE)
    expect(b).toHaveLength(27)
    expect(b.filter((x) => x.sicher)).toHaveLength(11)
    // traegt_teilweise ist Übungsbedarf, nicht sicher.
    expect(b.find((x) => x.skillKey === 'prozent_veraenderung')?.sicher).toBe(false)
  })

  it('entdoppelt nach Schlüssel', () => {
    expect(bereicheAus([...ILKAY_URTEILE, ILKAY_URTEILE[0]])).toHaveLength(27)
  })
})

describe('sicherListe / uebungListe — Seite 1', () => {
  const b = bereicheAus(ILKAY_URTEILE)

  it('trennt sicher und Übungsbedarf vollständig', () => {
    expect(sicherListe(b).length + uebungListe(b).length).toBe(27)
    expect(sicherListe(b).every((x) => x.sicher)).toBe(true)
    expect(uebungListe(b).every((x) => !x.sicher)).toBe(true)
  })

  it('sortiert nach Themenfeld, dann Klasse, dann Label', () => {
    for (const liste of [sicherListe(b), uebungListe(b)]) {
      for (let i = 1; i < liste.length; i++) {
        const [a, c] = [liste[i - 1], liste[i]]
        const schluessel = (x: typeof a) => [feldPosition(x.feld), x.klasse] as const
        const [fa, ka] = schluessel(a)
        const [fc, kc] = schluessel(c)
        expect(fa < fc || (fa === fc && (ka < kc || (ka === kc && a.label.localeCompare(c.label, 'de') <= 0)))).toBe(true)
      }
    }
    expect(sicherListe(b).slice(0, 4).map((x) => x.label)).toEqual([
      'Bruch in Dezimalzahl',
      'Brüche kürzen',
      'Prozentwert berechnen',
      'Gleichungen mit negativem Koeffizienten',
    ])
  })
})

describe('kopfFall', () => {
  it('gemischt, sicher, uebung', () => {
    expect(kopfFall(11, 16)).toBe('gemischt')
    expect(kopfFall(27, 0)).toBe('sicher')
    expect(kopfFall(0, 27)).toBe('uebung')
  })
})
