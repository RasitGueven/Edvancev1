import { describe, expect, it, vi } from 'vitest'

const aufrufe = vi.hoisted(() => ({ liste: [] as [string, unknown[]][] }))
vi.mock('@/lib/supabase/client', () => {
  const builder = {
    select: () => builder,
    eq: (c: string, v: unknown) => (aufrufe.liste.push([`eq:${c}`, [v]]), builder),
    in: (c: string, v: unknown[]) => (aufrufe.liste.push([`in:${c}`, v]), builder),
    then: (res: (v: unknown) => unknown) => Promise.resolve({ count: 5, error: null }).then(res),
  }
  return { supabase: { from: () => builder } }
})

import { berlinTagesGrenzen, countAufgabenFuerAdmin } from './heute'

describe('countAufgabenFuerAdmin', () => {
  it('zählt Übungen im Status review und rueckfrage (Zähler „Item-Pflege“)', async () => {
    expect(await countAufgabenFuerAdmin()).toEqual({ data: 5, error: null })
    expect(aufrufe.liste).toEqual([
      ['eq:content_type', ['exercise']],
      ['in:status', ['review', 'rueckfrage']],
    ])
  })
})

describe('berlinTagesGrenzen', () => {
  it('Sommerzeit: Berliner Mitternacht ist 22:00 UTC', () => {
    expect(berlinTagesGrenzen(new Date('2026-10-05T10:00:00Z'))).toEqual({
      von: '2026-10-04T22:00:00.000Z',
      bis: '2026-10-05T22:00:00.000Z',
    })
  })

  it('kurz nach Mitternacht zählt schon der neue Tag', () => {
    expect(berlinTagesGrenzen(new Date('2026-10-04T22:30:00Z')).von).toBe('2026-10-04T22:00:00.000Z')
  })

  it('Tag der Zeitumstellung hat 25 Stunden', () => {
    const { von, bis } = berlinTagesGrenzen(new Date('2026-10-25T12:00:00Z'))
    expect(von).toBe('2026-10-24T22:00:00.000Z')
    expect(bis).toBe('2026-10-25T23:00:00.000Z')
  })
})
