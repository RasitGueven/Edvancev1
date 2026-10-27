// Bericht v4: Ziele in Elternsprache (Bauauftrag V4, V4-1, Entscheidung 7).
import { describe, expect, it } from 'vitest'

import { fehlermusterAus, type Fehlermuster } from '@/lib/report/elternbericht/fehlermuster'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { bericht } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { zieleV4 } from '@/lib/report/elternbericht/zielbild'

const SORGFALT: Fehlermuster = { sorgfalt: true, aufgaben: 11, sorgfaltAufgaben: 6, haeufigste: null }
const OHNE_SORGFALT: Fehlermuster = { ...SORGFALT, sorgfalt: false }
const arg = (name: string) => ({
  fahrplan: bericht(name).fahrplan ?? null,
  muster: fehlermusterAus(FAELLE[name].data.fehlbilder),
  name: FAELLE[name].data.firstName,
})
const schluessel = (z: ReturnType<typeof zieleV4>) => z.map((x) => x.schluessel)

describe('zieleV4', () => {
  it('batuV4: vier Ziele — vorbereitet, später mit zwei Themen, Sorgfalt, übrige Lücken', () => {
    const { fahrplan, muster, name } = arg('batuV4')
    expect(muster?.sorgfalt).toBe(true)
    const z = zieleV4({ fahrplan, muster, name, spaeterLuecken: 5 })
    expect(schluessel(z)).toEqual([
      'v4.s5.ziele.vorbereitetThema',
      'v4.s5.ziele.spaeterZwei',
      'v4.s5.ziele.sorgfalt',
      'v4.s5.ziele.weitere',
    ])
    expect(z[0].werte).toMatchObject({ thema: 'Quadratische Funktionen', name })
    expect(z[1].werte).toMatchObject({
      a: 'Kreise, Prismen und Zylinder',
      b: 'Der Satz des Pythagoras und Berechnungen in Körpern',
    })
    expect(z[3].werte).toEqual({})
  })

  it('ohne Sorgfalt-Muster: drei Ziele', () => {
    const { fahrplan, name } = arg('batuV4')
    for (const muster of [null, OHNE_SORGFALT]) {
      expect(schluessel(zieleV4({ fahrplan, muster, name, spaeterLuecken: 5 }))).toEqual([
        'v4.s5.ziele.vorbereitetThema',
        'v4.s5.ziele.spaeterZwei',
        'v4.s5.ziele.weitere',
      ])
    }
  })

  it('ohne übrige Lücken kein „weitere“; nie mehr als vier', () => {
    const { fahrplan, muster, name } = arg('batuV4')
    expect(schluessel(zieleV4({ fahrplan, muster, name, spaeterLuecken: 0 }))).toEqual([
      'v4.s5.ziele.vorbereitetThema',
      'v4.s5.ziele.spaeterZwei',
      'v4.s5.ziele.sorgfalt',
    ])
    for (const f of Object.keys(FAELLE).filter((n) => n !== 'ohneKatalog')) {
      const a = arg(f)
      expect(zieleV4({ ...a, muster: SORGFALT, spaeterLuecken: 3 }).length, f).toBeLessThanOrEqual(4)
    }
  })

  it('genau eine weitere Station mit Übungsbedarf: spaeterEins', () => {
    const { fahrplan, name } = arg('fahrplanKlp')
    const nur = fahrplan!.stationen.map((s, i) => (i === 4 ? { ...s, signal: 'ohne' as const } : s))
    const z = zieleV4({ fahrplan: { ...fahrplan!, stationen: nur }, muster: null, name, spaeterLuecken: 0 })
    expect(schluessel(z)).toEqual(['v4.s5.ziele.vorbereitetThema', 'v4.s5.ziele.spaeterEins'])
    expect(z[1].werte).toHaveProperty('a')
  })

  it('allesErfuellt (L5 Teil D): kein Übungsbedarf vor einem kommenden Thema → „baut auf dem auf …“, nie leer', () => {
    const { fahrplan, name } = arg('allesErfuellt')
    expect(schluessel(zieleV4({ fahrplan, muster: SORGFALT, name, spaeterLuecken: 2 }))).toEqual([
      'v4.s5.ziele.aufbauen',
      'v4.s5.ziele.sorgfalt',
      'v4.s5.ziele.weitere',
    ])
    expect(schluessel(zieleV4({ fahrplan, muster: null, name, spaeterLuecken: 0 }))).toEqual(['v4.s5.ziele.aufbauen'])
  })

  it('L5 Teil D: Folge bekannt → „in Klassenarbeit n zu …“ mit der echten Nummer', () => {
    const { fahrplan, muster, name } = arg('batuEigen')
    const z = zieleV4({ fahrplan, muster, name, spaeterLuecken: 0 })
    expect(z[0]).toEqual({ schluessel: 'v4.s5.ziele.vorbereitetKa', werte: { n: '2', thema: 'Quadratische Funktionen', name } })
  })

  it('ohne Fahrplan: nur Sorgfalt und übrige Lücken', () => {
    expect(schluessel(zieleV4({ fahrplan: null, muster: SORGFALT, name: 'Batu', spaeterLuecken: 1 }))).toEqual([
      'v4.s5.ziele.sorgfalt',
      'v4.s5.ziele.weitere',
    ])
  })

  it('ohne Namen: Schlüssel mit „OhneName“, kein name in den Werten; „weitere“ bleibt', () => {
    const { fahrplan, muster } = arg('batuV4')
    const z = zieleV4({ fahrplan, muster, name: null, spaeterLuecken: 5 })
    expect(schluessel(z)).toEqual([
      'v4.s5.ziele.vorbereitetThemaOhneName',
      'v4.s5.ziele.spaeterZweiOhneName',
      'v4.s5.ziele.sorgfaltOhneName',
      'v4.s5.ziele.weitere',
    ])
    for (const x of z) expect(x.werte).not.toHaveProperty('name')
    expect(z[0].werte).toEqual({ thema: 'Quadratische Funktionen' })
  })
})
