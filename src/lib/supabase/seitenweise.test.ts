// M1: listAuthoringTasks und getPruefAdminListe laden ueber die 1000er-Grenze von PostgREST hinaus und lassen
// Muster-Instanzen (bauform_id gesetzt) weg. Echter supabase-js-Client, nur fetch ist ein kleiner Server, der
// offset/limit und den bauform_id-Filter so auswertet wie PostgREST (hoechstens 1000 Zeilen je Antwort).

import { beforeEach, describe, expect, it, vi } from 'vitest'

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

import { listAuthoringTasks, resetAuthoringSchemaCache } from './taskAuthoring'
import { getPruefAdminListe } from './pruefung'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

type Zeile = { id: string; bauform_id: string | null }
const einzeln: Zeile[] = Array.from({ length: 1500 }, (_, i) => ({ id: `t${i}`, bauform_id: null }))
const instanzen: Zeile[] = Array.from({ length: 700 }, (_, i) => ({ id: `m${i}`, bauform_id: 'b1' }))

function server(tasks: Zeile[], admin: { task_id: string }[]): void {
  fetchMock.mockImplementation(async (input) => {
    const url = new URL(String(input instanceof Request ? input.url : input))
    const offset = Number(url.searchParams.get('offset') ?? 0)
    const limit = Math.min(Number(url.searchParams.get('limit') ?? 1000), 1000)
    if (url.pathname === '/rest/v1/tasks') {
      // probeAuthoringSchema fragt mit limit=1 und ohne Filter
      if (url.searchParams.get('limit') === '1' && !url.searchParams.has('offset')) return json([])
      const gefiltert = url.searchParams.get('bauform_id') === 'is.null' ? tasks.filter((z) => z.bauform_id === null) : tasks
      return json(gefiltert.slice(offset, offset + limit))
    }
    if (url.pathname === '/rest/v1/rpc/pruef_admin_liste') return json(admin.slice(offset, offset + limit))
    return json({ code: 'PGRST202', message: 'fehlt' }, 404)
  })
}

const listenAufrufe = (pfad: string) =>
  fetchMock.mock.calls
    .map(([input]) => new URL(String(input instanceof Request ? input.url : input)))
    .filter((u) => u.pathname === pfad && u.searchParams.has('offset'))

beforeEach(() => {
  fetchMock.mockReset()
  resetAuthoringSchemaCache()
})

describe('listAuthoringTasks seitenweise', () => {
  it('liefert alle 1500 Einzelaufgaben in zwei Bloecken', async () => {
    server(einzeln, [])
    const res = await listAuthoringTasks()
    expect(res.error).toBeNull()
    expect(res.data).toHaveLength(1500)
    expect(new Set(res.data?.map((t) => t.id)).size).toBe(1500)
    expect(listenAufrufe('/rest/v1/tasks').map((u) => u.searchParams.get('offset'))).toEqual(['0', '1000'])
  })

  it('laesst Muster-Instanzen weg (bauform_id gesetzt)', async () => {
    server([...instanzen, ...einzeln], [])
    const res = await listAuthoringTasks()
    expect(res.data).toHaveLength(1500)
    expect(res.data?.some((t) => t.id.startsWith('m'))).toBe(false)
    expect(listenAufrufe('/rest/v1/tasks')[0].searchParams.get('bauform_id')).toBe('is.null')
  })

  it('stoppt nach einem vollen und einem leeren Block bei genau 1000', async () => {
    server(einzeln.slice(0, 1000), [])
    const res = await listAuthoringTasks()
    expect(res.data).toHaveLength(1000)
    expect(listenAufrufe('/rest/v1/tasks')).toHaveLength(2)
  })
})

describe('getPruefAdminListe seitenweise', () => {
  it('liefert alle Zeilen ueber 1000 hinaus, sortiert nach task_id', async () => {
    server([], Array.from({ length: 3317 }, (_, i) => ({ task_id: `t${i}` })))
    const res = await getPruefAdminListe()
    expect(res.data).toHaveLength(3317)
    const aufrufe = listenAufrufe('/rest/v1/rpc/pruef_admin_liste')
    expect(aufrufe.map((u) => u.searchParams.get('offset'))).toEqual(['0', '1000', '2000', '3000'])
    expect(aufrufe[0].searchParams.get('order')).toBe('task_id.asc')
  })

  it('meldet den Fehler eines Blocks', async () => {
    fetchMock.mockResolvedValue(json({ code: '42501', message: 'nur admin' }, 403))
    const res = await getPruefAdminListe()
    expect(res.data).toBeNull()
    expect(res.error?.code).toBe('42501')
  })
})
