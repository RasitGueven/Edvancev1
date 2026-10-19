import { describe, expect, it } from 'vitest'

import { bereicheAus } from '@/lib/report/elternbericht/bereiche'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { KATALOG } from '@/lib/report/elternbericht/fixtures/katalog'
import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import { klasse7, ohneKatalog, spaeter } from '@/lib/report/elternbericht/fixtures/synthetisch'
import { zaehle } from '@/lib/report/elternbericht/zaehlung'
import { familieVon } from '@/lib/report/familien'
import type { ReportData } from '@/types'

const z = (d: ReportData) =>
  zaehle(bereicheAus(d.erzaehlung.kompetenzen), d.erzaehlung.katalog, d.grade)

describe('zaehle — Nenner „von Y Bereichen des Katalogs"', () => {
  it('ilkay: Klasse 10 zählt den ganzen Katalog', () => {
    const { zaehlung } = z(ilkay)!
    expect(zaehlung).toEqual({
      untersucht: 27,
      sicher: 11,
      uebung: 16,
      katalog: 130,
      offen: 103,
      bisKlasse: 10,
    })
  })

  it.each(Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog'))(
    '%s: Profil = Katalog, sicher + uebung = untersucht, offen ≥ 0',
    (_name, { data }) => {
      const { zaehlung, profil } = z(data)!
      expect(profil.reduce((n, p) => n + p.vorhanden, 0)).toBe(zaehlung.katalog)
      expect(zaehlung.sicher + zaehlung.uebung).toBe(zaehlung.untersucht)
      expect(profil.reduce((n, p) => n + p.sicher, 0)).toBe(zaehlung.sicher)
      expect(profil.reduce((n, p) => n + p.uebung, 0)).toBe(zaehlung.uebung)
      expect(zaehlung.offen).toBe(zaehlung.katalog - zaehlung.untersucht)
      expect(zaehlung.offen).toBeGreaterThanOrEqual(0)
      for (const p of profil) {
        expect(p.vorhanden).toBeGreaterThan(0)
        expect(p.sicher + p.uebung).toBeLessThanOrEqual(p.vorhanden)
      }
    },
  )

  it('Skills ohne Familie zählen mit', () => {
    const ohneFamilie = ilkay.erzaehlung.kompetenzen.filter((k) => familieVon(k.skillKey) === null)
    expect(ohneFamilie.map((k) => k.skillKey).sort()).toEqual(['potenzen', 'runden_ueberschlag'])
    expect(z(ilkay)!.zaehlung.untersucht).toBe(ilkay.erzaehlung.kompetenzen.length)
    const zahlen = z(ilkay)!.profil.find((p) => p.feld === 'zahlen')!
    expect(zahlen.sicher).toBe(2)
  })

  it('Klasse 7: Katalog nur bis Klasse 7', () => {
    const { zaehlung } = z(klasse7)!
    expect(zaehlung.bisKlasse).toBe(7)
    expect(zaehlung.katalog).toBe(KATALOG.filter((k) => k.klasse <= 7).length)
  })

  it('ein geprüfter Skill über der Klasse erhöht den Katalog um eins', () => {
    const a = z(klasse7)!.zaehlung
    const b = z(spaeter)!.zaehlung
    expect(b.katalog).toBe(a.katalog + 1)
    expect(b.untersucht).toBe(a.untersucht + 1)
    expect(b.offen).toBe(a.offen)
  })

  it('k ist höchstens die höchste Klasse im Katalog', () => {
    const { zaehlung } = zaehle(bereicheAus(ilkay.erzaehlung.kompetenzen), KATALOG, 12)!
    expect(zaehlung.bisKlasse).toBe(10)
    expect(zaehlung.katalog).toBe(130)
  })

  it('ohneKatalog ergibt null', () => {
    expect(z(ohneKatalog)).toBeNull()
  })

  it('Profil nur für Felder mit Katalogbereichen, in Feld-Reihenfolge', () => {
    expect(z(klasse7)!.profil.map((p) => p.feld)).toEqual(
      ['brueche', 'prozent', 'terme', 'geometrie', 'groessen', 'zahlen'],
    )
  })
})
