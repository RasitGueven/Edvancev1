import { describe, expect, it } from 'vitest'
import type { PruefBoardZeile, PruefSollZeile } from '@/types'
import { bereichDerAufgabe, bereichsBoard, leseBereich, ohneBereich, sollDesBereichs } from './bereich'

const z = (id: string, anlaesse: string[]): PruefBoardZeile => ({
  task_id: id, stufe: 'erste', thema_key: 'a', thema_label: 'A', thema_sort: 1, skill_key: 's', skill_label: 'S',
  kurztitel: id, reihenfolge: 1, lena_status: 'offen', geaendert: false, letzte_dauer_sek: null, anlaesse, hat_hinweise: false,
})

const board = [z('l', ['batu_lsa']), z('s', ['batu_session']), z('b', ['batu_lsa', 'batu_session']), z('o', []), z('x', ['p2_test']),
  z('v', ['lsa_vorschau'])]

describe('Bereiche im Lena-Board', () => {
  it('filtert nach Anlass; beide Anlaesse stehen in beiden Bereichen', () => {
    expect(bereichsBoard(board, 'lsa').map((r) => r.task_id)).toEqual(['l', 'b', 'v'])
    expect(bereichsBoard(board, 'session').map((r) => r.task_id)).toEqual(['s', 'b'])
  })

  it('zaehlt Aufgaben ohne passenden Anlass', () => {
    expect(ohneBereich(board)).toBe(2)
  })

  it('liest ?bereich= und leitet sonst aus der Aufgabe ab (LSA vor Session, ohne Anlass LSA)', () => {
    expect(leseBereich(new URLSearchParams('bereich=session'))).toBe('session')
    expect(leseBereich(new URLSearchParams('bereich=quatsch'))).toBeNull()
    expect(bereichDerAufgabe(board[1])).toBe('session')
    expect(bereichDerAufgabe(board[2])).toBe('lsa')
    expect(bereichDerAufgabe(board[3])).toBe('lsa')
    expect(bereichDerAufgabe(undefined)).toBe('lsa')
  })

  it('fuehrt die Sollzahlen der Anlaesse eines Bereichs nach sort zusammen', () => {
    const s = (skill_key: string, sort: number) => ({ skill_key, sort }) as PruefSollZeile
    expect(sollDesBereichs([[s('b', 460), s('a', 210)], [s('c', 610)], []]).map((x) => x.skill_key)).toEqual(['a', 'b', 'c'])
  })

  it('zaehlt einen Knoten mit zwei Anlaessen des Bereichs nur einmal', () => {
    const s = (skill_key: string, sort: number) => ({ skill_key, sort }) as PruefSollZeile
    expect(sollDesBereichs([[s('a', 210)], [s('a', 610), s('c', 620)]]).map((x) => `${x.skill_key}${x.sort}`))
      .toEqual(['a210', 'c620'])
  })
})
