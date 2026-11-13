import { describe, expect, it } from 'vitest'
import type { PruefZielStandZeile, PruefZielZeile } from '@/types'
import { zielAnteil, zielBereiche } from './gezielt'

const zeile = (skill_key: string, sort: number, abschnitt: PruefZielZeile['abschnitt'] = 'gezielt'): PruefZielZeile => ({
  abschnitt, skill_key, skill_label: skill_key, thema_key: null, thema_label: null, fehlende_texte: 1, rest: 1,
  hebel_pakete: 0, hebel_schulen: 0, fokus_treffer: 0, sort, task_ids: ['t'], freigabe_ids: [], pilot_fehlt: [],
})
const stand = (skill_key: string, bereich: string, texte: number): PruefZielStandZeile => ({
  skill_key, skill_label: skill_key, bereich, texte, erfuellt: texte >= 2, zu_leicht: 0,
})

describe('IU-1 Prüfziel in Lenas Liste', () => {
  it('gruppiert nach Bereich: offen (Listenreihenfolge), erledigt, ohne Vorschlag; Nachprüfen zählt nicht', () => {
    const g = zielBereiche(
      [zeile('b', 2), zeile('a', 1), zeile('n', 3, 'nachpruefen')],
      [stand('a', 'algebra', 1), stand('b', 'algebra', 0), stand('c', 'algebra', 2), stand('n', 'geometrie', 0)],
    )
    expect(g.map((x) => x.bereich)).toEqual(['algebra', 'geometrie'])
    expect(g[0].offen.map((o) => [o.zeile.skill_key, o.texte])).toEqual([['a', 1], ['b', 0]])
    expect(g[0].erledigt.map((s) => s.skill_key)).toEqual(['c'])
    expect(g[1].ohneVorschlag.map((s) => s.skill_key)).toEqual(['n'])
  })

  it('Fortschritt zählt erledigte mit und kappt bei der Regel', () => {
    expect(zielAnteil([stand('a', 'x', 2), stand('b', 'x', 1), stand('c', 'x', 0), stand('d', 'x', 3)])).toBe(63)
    expect(zielAnteil([])).toBe(100)
  })
})
