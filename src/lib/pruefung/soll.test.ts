import { describe, expect, it } from 'vitest'
import type { LenaStatus, PruefBoardZeile, PruefSollZeile } from '@/types'
import { themenDerStufe } from './reihenfolge'
import { knotenDesThemas, restDerStufe, sollDesThemas, sortiereThemen } from './soll'

function zeile(id: string, reihenfolge: number, over: Partial<PruefBoardZeile> = {}, status: LenaStatus = 'offen'): PruefBoardZeile {
  return {
    task_id: id, stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis', thema_sort: 10, skill_key: 'k_umfang',
    skill_label: 'Umfang', kurztitel: id, reihenfolge, lena_status: status, geaendert: false, letzte_dauer_sek: null, ...over,
  }
}

function soll(skill: string, over: Partial<PruefSollZeile> = {}): PruefSollZeile {
  return {
    skill_key: skill, skill_label: skill, thema_key: 'kreis', thema_label: 'Kreis', thema_sort: 10, stufe: 'zweite',
    sort: 100, anlaesse: ['batu_lsa'], soll: 3, min_ohne_mc: 1, im_board: 3, gezaehlt: 0, gezaehlt_ohne_mc: 0,
    rest: 3, reicht: false, ...over,
  }
}

describe('Sollzahlen im Board (P2)', () => {
  it('Reiter: Summe der Restbedarfe je Stufe, null ohne Soll', () => {
    const s = [soll('a', { rest: 3 }), soll('b', { rest: 2 }), soll('c', { stufe: 'erste', rest: 7 })]
    expect(restDerStufe(s, 'zweite')).toBe(5)
    expect(restDerStufe(s, 'erste')).toBe(7)
    expect(restDerStufe(s, 'erprobung')).toBeNull()
  })

  it('Thema: X von Y noetig, Ueberschuss zaehlt nicht, reicht nur wenn alle Knoten reichen', () => {
    const s = [
      soll('a', { soll: 3, gezaehlt: 5, rest: 0, reicht: true }),
      soll('b', { soll: 2, gezaehlt: 1, rest: 1 }),
      soll('c', { thema_key: 'anderes' }),
    ]
    expect(sollDesThemas(s, 'kreis')).toEqual({ gezaehlt: 4, noetig: 5, reicht: false })
    expect(sollDesThemas([s[0]], 'kreis')).toEqual({ gezaehlt: 3, noetig: 3, reicht: true })
    expect(sollDesThemas(s, 'ohne')).toBeNull()
  })

  it('Themen mit Soll zuerst nach sort, die uebrigen in Lehrplan-Reihenfolge', () => {
    const board = [
      zeile('t1', 1, { thema_key: 'x', thema_label: 'X', skill_key: 'x1' }),
      zeile('t2', 2, { thema_key: 'y', thema_label: 'Y', skill_key: 'y1' }),
      zeile('t3', 3, { thema_key: 'z', thema_label: 'Z', skill_key: 'z1' }),
      zeile('t4', 4, { thema_key: 'w', thema_label: 'W', skill_key: 'w1' }),
    ]
    const s = [soll('z1', { thema_key: 'z', sort: 110 }), soll('y1', { thema_key: 'y', sort: 300 })]
    expect(sortiereThemen(themenDerStufe(board, 'zweite'), s).map((g) => g.thema_key)).toEqual(['z', 'y', 'x', 'w'])
    expect(sortiereThemen(themenDerStufe(board, 'zweite'), []).map((g) => g.thema_key)).toEqual(['x', 'y', 'z', 'w'])
  })

  it('Knoten: mit Soll nach sort (auch ohne Aufgabe), dann ohne Soll; Aufgaben in Board-Reihenfolge', () => {
    const board = [
      zeile('t1', 1, { skill_key: 'ohne', skill_label: 'Ohne Soll' }),
      zeile('t2', 2, { skill_key: 'spaet' }),
      zeile('t3', 3, { skill_key: 'frueh' }),
      zeile('t4', 4, { skill_key: 'spaet' }),
    ]
    const s = [soll('spaet', { sort: 200 }), soll('frueh', { sort: 100 }), soll('leer', { sort: 150 })]
    const k = knotenDesThemas(themenDerStufe(board, 'zweite')[0], s)
    expect(k.map((x) => x.skill_key)).toEqual(['frueh', 'leer', 'spaet', 'ohne'])
    expect(k[2].zeilen.map((z) => z.task_id)).toEqual(['t2', 't4'])
    expect(k[1].zeilen).toEqual([])
    expect(k[3].soll).toBeNull()
    expect(k[3].label).toBe('Ohne Soll')
  })
})
