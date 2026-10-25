import { describe, expect, it } from 'vitest'
import type { LenaStatus, PruefBoardZeile, PruefSollZeile } from '@/types'
import { blockVon, freigabeStand } from './freigabelisteModel'

const soll = (skill_key: string, sort: number, over: Partial<PruefSollZeile> = {}): PruefSollZeile =>
  ({ skill_key, skill_label: skill_key, sort, soll: 2, min_ohne_mc: 1, gezaehlt: 0, gezaehlt_ohne_mc: 0, rest: 2,
     reicht: false, anlaesse: ['batu_lsa'], ...over }) as PruefSollZeile

const zeile = (task_id: string, skill_key: string, lena_status: LenaStatus, anlaesse = ['batu_lsa']): PruefBoardZeile =>
  ({ task_id, skill_key, lena_status, anlaesse }) as PruefBoardZeile

describe('freigabelisteModel', () => {
  it('Blöcke nach sort', () => {
    expect([150, 305, 340, 410, 570, 910].map(blockVon)).toEqual(
      ['grundlage', 'ka2', 'ka2', 'rueckblick', 'rueckblick', 'ausblick'])
  })

  it('nichts frei: je Bereich 2 offen, Lena muss alle prüfen', () => {
    const r = freigabeStand([soll('a', 310), soll('b', 410), soll('c', 420), soll('d', 910)], [])
    expect(r.fehlt).toBe(8)
    expect(r.bloecke.map((b) => [b.block, b.bereiche, b.fehlt, b.lena])).toEqual(
      [['ka2', 1, 2, 2], ['rueckblick', 2, 4, 4], ['ausblick', 1, 2, 2]])
  })

  it('Lena hat geprüft: zählt weiter als offen, bis der Admin freigibt; wartende in Listenreihenfolge', () => {
    const r = freigabeStand([soll('b', 410, { gezaehlt: 2, gezaehlt_ohne_mc: 1, rest: 0 }), soll('a', 310,
      { gezaehlt: 2, gezaehlt_ohne_mc: 1, rest: 0 })],
      [zeile('b1', 'b', 'passt'), zeile('a1', 'a', 'passt'), zeile('a2', 'a', 'freigegeben'), zeile('x', 'a', 'passt', [])])
    expect(r.wartend).toEqual(['a1', 'b1'])
    expect(r.bloecke.map((b) => [b.block, b.fehlt, b.lena])).toEqual([['ka2', 1, 0], ['rueckblick', 2, 0]])
  })

  it('erledigte Bereiche fallen weg; nur MC geprüft → „ohne MC fehlt“', () => {
    const r = freigabeStand([
      soll('fertig', 310, { gezaehlt: 2, gezaehlt_ohne_mc: 1, rest: 0, reicht: true }),
      soll('nurMc', 330, { gezaehlt: 2, gezaehlt_ohne_mc: 0, rest: 1 }),
    ], [zeile('f1', 'fertig', 'freigegeben'), zeile('f2', 'fertig', 'freigegeben'),
        zeile('m1', 'nurMc', 'freigegeben'), zeile('m2', 'nurMc', 'freigegeben')])
    expect(r.fehlt).toBe(1)
    expect(r.bloecke).toEqual([{ block: 'ka2', bereiche: 1, fehlt: 1, lena: 1, ohneMc: ['nurMc'] }])
  })
})
