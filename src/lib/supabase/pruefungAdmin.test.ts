// Admin-Pruefansicht, Lib: Aufrufe ueber den echten supabase-js-Client (nur fetch gemockt, wie
// freigabe.test.ts — ein gemockter Client faengt einen this-Verlust nicht), dazu die Gruppierung der
// Team-Beanstandung.

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

import { getAdminPruefKontext, pruefAnLena, pruefSammel, setzePilot, teamBeanstandung } from './pruefungAdmin'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

const aufrufe = () =>
  fetchMock.mock.calls.map(([input, init]) => ({
    url: new URL(String(input instanceof Request ? input.url : input)),
    body: init?.body ? JSON.parse(String(init.body)) : null,
  }))

beforeEach(() => {
  fetchMock.mockReset()
})

describe('Admin-RPCs mit echtem supabase-js', () => {
  it('pruefSammel schickt Aktion, IDs, Werte und Vorschau an /rpc/pruef_sammel', async () => {
    fetchMock.mockResolvedValue(json({ betrifft: ['a'], ausgelassen: [{ task_id: 'b', grund: 'geaendert', text: null }] }))
    const res = await pruefSammel('freigeben', ['a', 'b'], {}, true)
    expect(res.data?.betrifft).toEqual(['a'])
    const [c] = aufrufe()
    expect(c.url.pathname).toBe('/rest/v1/rpc/pruef_sammel')
    expect(c.body).toEqual({ p_aktion: 'freigeben', p_task_ids: ['a', 'b'], p_werte: {}, p_nur_vorschau: true })
  })

  it('pruefAnLena schickt eine leere Nachricht als null', async () => {
    fetchMock.mockResolvedValue(json({ status: 'draft' }))
    await pruefAnLena('t1', '   ')
    expect(aufrufe()[0].body).toEqual({ p_task_id: 't1', p_nachricht: null })
  })

  it('behaelt SQLSTATE und HINT eines Fehlers', async () => {
    fetchMock.mockResolvedValue(json({ code: 'ED422', hint: 'erst_an_lena', message: 'erst zurueck an Lena' }, 400))
    const res = await pruefAnLena('t1')
    expect(res.error).toMatchObject({ code: 'ED422', hint: 'erst_an_lena' })
  })

  it('setzePilot laeuft ueber pruef_sammel mit einer ID und meldet einen echten Auslass-Grund als Fehler', async () => {
    fetchMock.mockResolvedValueOnce(json({ betrifft: ['t1'], ausgelassen: [] }))
    expect(await setzePilot('t1', true)).toEqual({ data: true, error: null })
    expect(aufrufe()[0].body).toMatchObject({ p_aktion: 'pilot_an', p_task_ids: ['t1'], p_nur_vorschau: false })
    fetchMock.mockResolvedValueOnce(json({ betrifft: [], ausgelassen: [{ task_id: 't1', grund: 'nicht_bei_lena', text: 'vera8' }] }))
    expect((await setzePilot('t1', true)).error?.hint).toBe('nicht_bei_lena')
  })

  it('getAdminPruefKontext liest Tabellen und setzt Namen ein', async () => {
    fetchMock.mockImplementation(async (input) => {
      const url = new URL(String(input instanceof Request ? input.url : input))
      const tabelle = url.pathname.replace('/rest/v1/', '')
      if (tabelle === 'task_pruefungen') {
        return json([{ entscheidung: 'unsicher', gruende: [], notiz: 'Ist 22,61 auch richtig?', aenderungen: [],
          aenderung_grund: null, dauer_sek: 96, geprueft_von: 'lena', geprueft_am: '2026-10-05T08:14:00Z',
          antwort: null, beantwortet_von: null, beantwortet_am: null }])
      }
      if (tabelle === 'task_admin_protokoll') {
        return json([{ id: 'p1', aktion: 'pilot_an', aenderungen: [], grund: null, sammel: true, von: 'rasit', am: '2026-10-05T09:00:00Z' }])
      }
      if (tabelle === 'profiles') {
        return json([{ id: 'lena', full_name: 'Lena Beispiel', email: null, role: 'coach' },
          { id: 'rasit', full_name: 'Rasit Beispiel', email: null, role: 'admin' }])
      }
      return json([])
    })
    const res = await getAdminPruefKontext('t1')
    expect(res.error).toBeNull()
    expect(res.data?.lena?.geprueft_von).toBe('Lena Beispiel')
    expect(res.data?.protokoll[0].von).toBe('Rasit Beispiel')
    expect(res.data?.team).toBeNull()
    expect(res.data?.freigabe).toBeNull()
  })
})

describe('teamBeanstandung', () => {
  const rolle = (id: string | null): string | null => (id === 'admin' ? 'admin' : 'coach')
  const z = (kategorie: string, von: string | null, notiz: string | null, am: string) =>
    ({ kategorie, notiz, geprueft_von: von, geprueft_am: am })

  it('fasst die juengsten Zeilen desselben Admins mit derselben Notiz zusammen', () => {
    const t = teamBeanstandung([
      z('didaktisch', 'admin', 'Bitte mit x', '3'), z('formulierung', 'admin', 'Bitte mit x', '2'), z('sonstiges', 'lena', 'alt', '1'),
    ], rolle)
    expect(t).toEqual({ gruende: ['formulierung', 'didaktisch'], notiz: 'Bitte mit x', von: 'admin', am: '3' })
  })

  it('ist leer, wenn die juengste Beanstandung von Lena kommt', () => {
    expect(teamBeanstandung([z('sonstiges', 'lena', null, '1')], rolle)).toBeNull()
    expect(teamBeanstandung([], rolle)).toBeNull()
  })
})
