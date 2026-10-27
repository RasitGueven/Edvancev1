import { describe, expect, it } from 'vitest'

import type { Elternbericht } from '@/types'

import { kaSatz, kaTeile } from './kaSatz'

/** Nur die Felder, die kaSatz liest. */
function bericht(
  sicher: string[],
  uebung: string[],
  fehltBei: Record<string, string[]> = {},
  bekannt = true,
): Elternbericht {
  const st = (nummer: number, themaKey: string, titel: string) => ({
    nummer,
    ka: bekannt ? nummer : null,
    themaKey,
    titel,
    themen: [{ themaKey, titel }],
  })
  return {
    thema: { titel: 'Reelle Zahlen', uebung, sicher },
    fahrplan: {
      folge: bekannt ? 'eigen' : 'unbekannt',
      stationen: [st(1, 'reelle_zahlen', 'Reelle Zahlen'), st(2, 'quadr', 'Quadratische Funktionen'), st(3, 'kreis', 'Kreis')],
    },
    signale: Object.entries(fehltBei).map(([themaKey, labels]) => ({
      themaKey,
      sitzt: [],
      fehlt: labels.map((label) => ({ label })),
    })),
  } as unknown as Elternbericht
}

describe('kaSatz (LSA-L4 Teil D)', () => {
  it('steht an und unbekannt: derselbe Fall ohne Bereiche', () => {
    expect(kaSatz(bericht(['A'], ['B']), 'bevorstehend', 3)).toMatchObject({ fall: 'steht', sicher: [], unsicher: [] })
    expect(kaSatz(bericht(['A'], ['B']), null, null)?.fall).toBe('steht')
  })

  it('geschrieben, Note offen: höchstens zwei Bereiche je Platzhalter', () => {
    const s = kaSatz(bericht(['A', 'B', 'C'], ['D', 'E', 'F']), 'geschrieben', null)!
    expect(s).toMatchObject({ fall: 'offen', sicher: ['A', 'B'], unsicher: ['D', 'E'], note: null })
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['analyse.xy', 'abgleich'])
    expect(kaTeile(s, 'de')[0].values).toMatchObject({ x: 'A und B', y: 'D und E', count: 2 })
  })

  it('Note offen ohne unsicheren Bereich: der Satzteil mit {Y} entfällt', () => {
    const s = kaSatz(bericht(['A'], []), 'geschrieben', null)!
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['analyse.x', 'abgleich'])
  })

  it('Note offen ohne geprüften Bereich im Thema: nur die Feststellung und der Abgleich', () => {
    const s = kaSatz(bericht([], []), 'geschrieben', null)!
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['geschrieben', 'abgleich'])
  })

  it('Note bekannt: k ist die erste kommende Arbeit, die {Y} braucht', () => {
    const s = kaSatz(bericht(['A'], ['D'], { kreis: ['D'], quadr: ['X'] }), 'geschrieben', 4)!
    expect(s).toMatchObject({ fall: 'note', note: 4, k: { ka: 3, thema: 'Kreis' } })
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['note', 'dazu', 'wieder'])
  })

  it('L5: Folge unbekannt — das Thema statt einer Nummer („wird bei „Kreis“ wieder gebraucht“)', () => {
    const s = kaSatz(bericht(['A'], ['D'], { kreis: ['D'] }, false), 'geschrieben', 4)!
    expect(s.k).toEqual({ ka: null, thema: 'Kreis' })
    const teile = kaTeile(s, 'de')
    expect(teile.map((t) => t.key)).toEqual(['note', 'dazu', 'wiederThema'])
    expect(teile[2].values).not.toHaveProperty('k')
  })

  it('Note bekannt ohne kommende Arbeit, die {Y} braucht: letzter Satz entfällt', () => {
    const s = kaSatz(bericht(['A'], ['D']), 'geschrieben', 2)!
    expect(s.k).toBeNull()
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['note', 'dazu'])
  })

  it('Note bekannt ohne unsicheren Bereich: nur der Satz zur Note', () => {
    const s = kaSatz(bericht(['A'], []), 'geschrieben', 1)!
    expect(kaTeile(s, 'de').map((t) => t.key)).toEqual(['note'])
  })

  it('eine Note außerhalb 1–6 zählt als offen', () => {
    expect(kaSatz(bericht(['A'], ['D']), 'geschrieben', 7)?.fall).toBe('offen')
  })

  it('ohne Thema kein Satz', () => {
    expect(kaSatz({ thema: null, fahrplan: null } as unknown as Elternbericht, 'geschrieben', 3)).toBeNull()
  })
})
