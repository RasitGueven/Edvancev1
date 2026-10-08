import { describe, expect, it } from 'vitest'
import type { ErklaerListenZeile } from '@/types/erklaerPruefung'
import {
  FORMEL_FEHLT,
  fehltText,
  filtereErklaer,
  formelAnzahl,
  mitFormelBildern,
  nachThema,
  naechsteOffeneKernidee,
  zaehleFilter,
} from './erklaerAnzeige'

function zeile(teil: Partial<ErklaerListenZeile>): ErklaerListenZeile {
  return {
    kernidee_id: 'k', skill_key: 's', skill_label: 'S', thema_key: 't', thema_label: 'T', klasse: 8, nr: 1,
    titel: 'Titel', status: 'entwurf', stand: 'offen', rueckfrage: false, bereit: false, varianten: 2,
    schritte: 4, schritte_offen: 4, checks: 1, checks_soll: 1, geaendert_am: '2026-10-07T10:00:00Z', ...teil,
  }
}

describe('mitFormelBildern', () => {
  it('setzt die i-te SVG an die Stelle der i-ten Formel', () => {
    const r = mitFormelBildern('Es gilt $m = \\frac{a}{b}$ und $b$.', ['https://x/1.svg', 'https://x/2.svg'])
    expect(r.markdown).toBe('Es gilt ![m = \\\\frac{a}{b}](https://x/1.svg) und ![b](https://x/2.svg).')
    expect(r.fehlen).toBe(0)
  })

  it('faellt ohne SVG auf den Quelltext zurueck und zaehlt die fehlenden', () => {
    const r = mitFormelBildern('Bei $y = mx + b$ und $x_1$', ['https://x/1.svg'])
    expect(r.markdown).toBe(`Bei ![y = mx + b](https://x/1.svg) und ![x_1](${FORMEL_FEHLT})`)
    expect(r.fehlen).toBe(1)
  })

  it('maskiert eckige Klammern im Alt-Text', () => {
    expect(mitFormelBildern('$[a]$', []).markdown).toBe(`![\\[a\\]](${FORMEL_FEHLT})`)
  })

  it('zaehlt Formeln wie erklaer_formel_anzahl', () => {
    expect(formelAnzahl('kein Geld $ hier')).toBe(0)
    expect(formelAnzahl('$a$ und $b$')).toBe(2)
  })
})

describe('Liste', () => {
  const zeilen = [
    zeile({ kernidee_id: 'a', thema_key: 't1', stand: 'offen' }),
    zeile({ kernidee_id: 'b', thema_key: 't2', stand: 'unsicher', rueckfrage: true }),
    zeile({ kernidee_id: 'c', thema_key: 't1', stand: 'passt', bereit: true, nr: 2 }),
    zeile({ kernidee_id: 'd', thema_key: null, skill_key: 'ohne', stand: 'offen' }),
  ]

  it('gruppiert nach Thema in der Reihenfolge des ersten Auftretens', () => {
    expect(nachThema(zeilen).map((g) => [g.key, g.zeilen.map((z) => z.kernidee_id)])).toEqual([
      ['t1', ['a', 'c']], ['t2', ['b']], ['skill:ohne', ['d']],
    ])
  })

  it('filtert fuer den Admin: bereit zur Freigabe und Rueckfragen', () => {
    expect(filtereErklaer(zeilen, 'bereit').map((z) => z.kernidee_id)).toEqual(['c'])
    expect(filtereErklaer(zeilen, 'rueckfragen').map((z) => z.kernidee_id)).toEqual(['b'])
    expect(filtereErklaer(zeilen, 'alle')).toHaveLength(4)
    expect(zaehleFilter(zeilen)).toEqual({ alle: 4, bereit: 1, rueckfragen: 1 })
  })

  it('findet die naechste offene Kernidee', () => {
    expect(naechsteOffeneKernidee(zeilen, 'a')).toBe('d')
    expect(naechsteOffeneKernidee(zeilen, 'd')).toBe('a')
    expect(naechsteOffeneKernidee(zeilen, null)).toBe('a')
    expect(naechsteOffeneKernidee([zeilen[0]], 'a')).toBeNull()
  })
})

describe('fehltText', () => {
  it('liefert Schluessel und Werte', () => {
    expect(fehltText({ was: 'checks', soll: 2, ist: 0 })).toEqual({ key: 'fehlt.checks', werte: { soll: 2, ist: 0, count: 2 } })
    expect(fehltText({ was: 'formeln_fehlen', variante: 'B', art: 'beispiel' }).werte).toEqual({ variante: 'B', art: 'beispiel' })
    expect(fehltText({ was: 'kernidee_ungeprueft' }).key).toBe('fehlt.kernidee_ungeprueft')
  })
})
