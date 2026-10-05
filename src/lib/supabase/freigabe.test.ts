// Regressionsschutz fuer die this-Bindung der RPC-Aufrufe.
//
// `const rpc = supabase.rpc as …; rpc('…')` verliert `this` — supabase-js wirft
// dann "Cannot read properties of undefined (reading 'rest')", noch bevor eine
// Anfrage rausgeht. Ein gemockter Client faengt das nicht (dessen rpc braucht
// kein `this`), deshalb laeuft hier der echte supabase-js-Client; nur fetch ist
// gemockt.

import { describe, expect, it, vi, beforeEach } from 'vitest'

const fetchMock = vi.hoisted(() => vi.fn<typeof fetch>())

vi.mock('./client', async () => {
  const { createClient } = await import('@supabase/supabase-js')
  return {
    supabase: createClient('http://supabase.test', 'test-anon-key', {
      global: { fetch: fetchMock },
      auth: { persistSession: false, autoRefreshToken: false },
    }),
  }
})

import { getDarfPruefen, listLetzteBeanstandungen } from './freigabe'
import { listReviewMeta } from './taskAuthoring'

const json = (body: unknown) =>
  new Response(JSON.stringify(body), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })

const aufrufe = () =>
  fetchMock.mock.calls.map(([input, init]) => ({
    url: new URL(String(input instanceof Request ? input.url : input)),
    method: init?.method ?? (input instanceof Request ? input.method : 'GET'),
  }))

beforeEach(() => {
  fetchMock.mockReset()
})

describe('RPC-Aufrufe mit echtem supabase-js', () => {
  it('getDarfPruefen schickt genau einen POST auf /rest/v1/rpc/darf_pruefen und liefert true', async () => {
    fetchMock.mockResolvedValue(json(true))

    const res = await getDarfPruefen()

    expect(res).toEqual({ data: true, error: null })
    const calls = aufrufe()
    expect(calls).toHaveLength(1)
    expect(calls[0].method).toBe('POST')
    expect(calls[0].url.pathname).toBe('/rest/v1/rpc/darf_pruefen')
  })

  it('listReviewMeta erreicht /rest/v1/rpc/authoring_review_meta', async () => {
    fetchMock.mockResolvedValue(json([{ task_id: 't-1', labels: ['x'], has_incomplete: true }]))

    const map = await listReviewMeta()

    expect(map.get('t-1')).toEqual({ labels: ['x'], hasIncomplete: true })
    expect(aufrufe().map((c) => c.url.pathname)).toEqual(['/rest/v1/rpc/authoring_review_meta'])
  })

  it('listLetzteBeanstandungen liest task_reviews ueber das gebundene from', async () => {
    fetchMock.mockResolvedValue(json([{ task_id: 't-1', kategorie: 'kontext', notiz: null }]))

    const res = await listLetzteBeanstandungen()

    expect(res.error).toBeNull()
    expect(res.data?.get('t-1')).toEqual({ kategorie: 'kontext', notiz: null })
    expect(aufrufe().map((c) => c.url.pathname)).toEqual(['/rest/v1/task_reviews'])
  })
})
