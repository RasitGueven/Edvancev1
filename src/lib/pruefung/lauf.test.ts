import { describe, expect, it } from 'vitest'
import type { LenaStatus, PruefBoardZeile, PruefSollZeile, Stufe } from '@/types'
import { ersteNoetigeImThema, knotenOhneAufgabe, nachrechnen, naechsteNoetige, restImThema } from './lauf'
import { naechsteOffene } from './reihenfolge'

function zeile(id: string, reihenfolge: number, skill: string, thema = 'kreis', stufe: Stufe = 'zweite', status: LenaStatus = 'offen'): PruefBoardZeile {
  return {
    task_id: id, stufe, thema_key: thema, thema_label: thema, thema_sort: 10, skill_key: skill, skill_label: skill,
    kurztitel: id, reihenfolge, lena_status: status, geaendert: false, letzte_dauer_sek: null, anlaesse: ['batu_lsa'],
    hat_hinweise: false,
  }
}

function soll(skill: string, sort: number, rest: number, thema = 'kreis', stufe: Stufe = 'zweite', over: Partial<PruefSollZeile> = {}): PruefSollZeile {
  return {
    skill_key: skill, skill_label: skill, thema_key: thema, thema_label: thema, thema_sort: 10, stufe, sort,
    anlaesse: ['batu_lsa'], soll: 3, min_ohne_mc: 1, im_board: 3, gezaehlt: 3 - rest, gezaehlt_ohne_mc: 3 - rest,
    rest, reicht: rest === 0, ...over,
  }
}

describe('naechsteNoetige (P4)', () => {
  // Board-Reihenfolge: dreieck vor kreis; Soll-Reihenfolge: kreis vor dreieck.
  const board = [
    zeile('d1', 1, 'k_dreieck', 'dreieck'),
    zeile('k1', 2, 'k_umfang'),
    zeile('k2', 3, 'k_flaeche'),
    zeile('k3', 4, 'k_umfang'),
    zeile('x1', 5, 'k_ohne'),
  ]
  const s = [soll('k_umfang', 100, 2), soll('k_flaeche', 110, 1), soll('k_dreieck', 200, 1, 'dreieck')]

  it('Start: erstes Thema nach sortiereThemen, nicht nach Board', () => {
    expect(naechsteNoetige(board, s, null)).toEqual({ taskId: 'k1', grund: 'gleiches_thema' })
  })

  it('bleibt im Thema, auch wenn die naechste noetige Aufgabe im Board weiter vorn liegt', () => {
    expect(naechsteNoetige(board, s, 'k3')).toEqual({ taskId: 'k1', grund: 'gleiches_thema' })
  })

  it('Knoten im Thema nach sort: erst alle des ersten Knotens', () => {
    expect(naechsteNoetige(board, s, 'k2').taskId).toBe('k1')
    expect(naechsteNoetige(board, s, 'k1').taskId).toBe('k3')
  })

  it('ueberspringt Knoten mit erfuelltem Soll und Knoten ohne Soll', () => {
    const erfuellt = [soll('k_umfang', 100, 0), soll('k_flaeche', 110, 1), soll('k_dreieck', 200, 1, 'dreieck')]
    expect(naechsteNoetige(board, erfuellt, null).taskId).toBe('k2')
    const b = board.map((z) => (z.task_id === 'k2' ? { ...z, lena_status: 'passt' as const } : z))
    const fertigKreis = [soll('k_umfang', 100, 0), soll('k_flaeche', 110, 0), soll('k_dreieck', 200, 1, 'dreieck')]
    expect(naechsteNoetige(b, fertigKreis, 'k2')).toEqual({ taskId: 'd1', grund: 'themenwechsel' })
  })

  it('Themenwechsel erst, wenn das Thema nichts Noetiges mehr hat', () => {
    const b = board.map((z) => (['k1', 'k3'].includes(z.task_id) ? { ...z, lena_status: 'passt' as const } : z))
    const s2 = [soll('k_umfang', 100, 0), soll('k_flaeche', 110, 1), soll('k_dreieck', 200, 1, 'dreieck')]
    expect(naechsteNoetige(b, s2, 'k3')).toEqual({ taskId: 'k2', grund: 'gleiches_thema' })
  })

  it('Stufenwechsel erst, wenn die Stufe nichts Noetiges mehr hat', () => {
    const b = [
      zeile('a1', 1, 'k_a', 'thema_a', 'erste'),
      zeile('b1', 2, 'k_b', 'thema_b', 'erste'),
      zeile('c1', 3, 'k_c', 'thema_c', 'zweite'),
    ]
    const s3 = [soll('k_a', 10, 1, 'thema_a', 'erste'), soll('k_b', 20, 1, 'thema_b', 'erste'), soll('k_c', 5, 1, 'thema_c', 'zweite')]
    expect(naechsteNoetige(b, s3, 'a1')).toEqual({ taskId: 'b1', grund: 'themenwechsel' })
    const ohneB = [s3[0], { ...s3[1], rest: 0 }, s3[2]]
    expect(naechsteNoetige(b, ohneB, 'a1')).toEqual({ taskId: 'c1', grund: 'stufenwechsel' })
  })

  it('Start im gewaehlten Reiter, sonst im ersten Reiter mit Bedarf', () => {
    const b = [zeile('e1', 1, 'k_e', 'thema_e', 'erste'), zeile('p1', 2, 'k_p', 'thema_p', 'erprobung')]
    const s4 = [soll('k_e', 10, 1, 'thema_e', 'erste'), soll('k_p', 5, 1, 'thema_p', 'erprobung')]
    expect(naechsteNoetige(b, s4, null).taskId).toBe('e1')
    expect(naechsteNoetige(b, s4, null, [], { start: 'erprobung' }).taskId).toBe('p1')
    expect(naechsteNoetige(b, [s4[1], { ...s4[0], rest: 0 }], null).taskId).toBe('p1')
  })

  it('Session ohne Reiter: kein Stufenwechsel, nur Themenwechsel', () => {
    const b = [zeile('a1', 1, 'k_a', 'thema_a', 'erste'), zeile('c1', 2, 'k_c', 'thema_c', 'zweite')]
    const s5 = [soll('k_a', 10, 1, 'thema_a', 'erste'), soll('k_c', 5, 1, 'thema_c', 'zweite')]
    expect(naechsteNoetige(b, s5, 'a1', [], { stufen: false })).toEqual({ taskId: 'c1', grund: 'themenwechsel' })
  })

  it('uebersprungene ans Ende des Themas, vor dem naechsten Thema', () => {
    expect(naechsteNoetige(board, s, 'k1', ['k1'])).toEqual({ taskId: 'k3', grund: 'gleiches_thema' })
    expect(naechsteNoetige(board, s, 'k3', ['k1', 'k3'])).toEqual({ taskId: 'k2', grund: 'gleiches_thema' })
    expect(naechsteNoetige(board, s, 'k2', ['k1', 'k3', 'k2'])).toEqual({ taskId: 'k1', grund: 'gleiches_thema' })
  })

  it("'fertig', wenn nichts Noetiges mehr offen ist", () => {
    const fertig = s.map((x) => ({ ...x, rest: 0 }))
    expect(naechsteNoetige(board, fertig, 'k1')).toEqual({ taskId: null, grund: 'fertig' })
  })

  it('ohne Soll (oder nach "Weitere ohne Soll") gilt der alte Weg', () => {
    expect(naechsteNoetige(board, [], 'k3')).toEqual({ taskId: naechsteOffene(board, 'k3'), grund: 'ohne_soll' })
    expect(naechsteNoetige(board, null, null)).toEqual({ taskId: 'd1', grund: 'ohne_soll' })
    expect(naechsteNoetige(board, s, 'k1', [], { ohneSoll: true })).toEqual({ taskId: 'k2', grund: 'ohne_soll' })
  })

  it('Reihenfolge der Themen wie sortiereThemen: Themen ohne Soll zuletzt', () => {
    const b = [zeile('o1', 1, 'k_o', 'ohne'), zeile('z1', 2, 'k_z', 'zwei'), zeile('e1', 3, 'k_e', 'eins')]
    const s6 = [soll('k_e', 10, 1, 'eins'), soll('k_z', 20, 1, 'zwei')]
    expect(naechsteNoetige(b, s6, null).taskId).toBe('e1')
    expect(naechsteNoetige(b, s6, 'e1')).toEqual({ taskId: 'z1', grund: 'themenwechsel' })
    expect(naechsteNoetige(b, s6, 'z1').taskId).toBe('e1')
  })
})

describe('Hilfen zum Lauf', () => {
  it('ersteNoetigeImThema: erst die noetige, sonst wie ersteImThema', () => {
    const b = [zeile('k1', 1, 'k_ohne'), zeile('k2', 2, 'k_umfang')]
    expect(ersteNoetigeImThema(b, [soll('k_umfang', 1, 2)], 'kreis')).toBe('k2')
    expect(ersteNoetigeImThema(b, [], 'kreis')).toBe('k1')
  })

  it('restImThema und knotenOhneAufgabe', () => {
    const s = [soll('k_umfang', 1, 2), soll('k_flaeche', 2, 1), soll('k_fehlt', 3, 0)]
    expect(restImThema(s, 'kreis')).toBe(3)
    expect(restImThema(s, 'anderes')).toBeNull()
    const b = [zeile('k1', 1, 'k_umfang'), zeile('k2', 2, 'k_flaeche', 'kreis', 'zweite', 'passt')]
    expect(knotenOhneAufgabe(b, s).map((x) => x.skill_key)).toEqual(['k_flaeche'])
  })
})

describe('nachrechnen (lokal wie pruef_board_soll)', () => {
  const s = [soll('k', 1, 3, 'kreis', 'zweite', { soll: 3, min_ohne_mc: 1, gezaehlt: 0, gezaehlt_ohne_mc: 0 })]

  it('passt zaehlt', () => {
    expect(nachrechnen(s, 'k', 'offen', 'passt', false)[0]).toMatchObject({ gezaehlt: 1, gezaehlt_ohne_mc: 1, rest: 2, reicht: false })
  })

  it('passt bei MC zaehlt nicht fuer min_ohne_mc', () => {
    const drei = [{ ...s[0], gezaehlt: 2, gezaehlt_ohne_mc: 0, rest: 1 }]
    expect(nachrechnen(drei, 'k', 'offen', 'passt', true)[0]).toMatchObject({ gezaehlt: 3, gezaehlt_ohne_mc: 0, rest: 1, reicht: false })
    expect(nachrechnen(drei, 'k', 'offen', 'passt', false)[0]).toMatchObject({ gezaehlt: 3, gezaehlt_ohne_mc: 1, rest: 0, reicht: true })
  })

  it('passt_nicht und unsicher zaehlen nicht', () => {
    expect(nachrechnen(s, 'k', 'offen', 'passt_nicht', false)).toBe(s)
    expect(nachrechnen(s, 'k', 'offen', 'unsicher', false)).toBe(s)
  })

  it('Rueckgaengig rechnet zurueck', () => {
    const nach = nachrechnen(s, 'k', 'offen', 'passt', false)
    expect(nachrechnen(nach, 'k', 'passt', 'offen', false)[0]).toMatchObject({ gezaehlt: 0, gezaehlt_ohne_mc: 0, rest: 3 })
  })
})
