import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * LSA-R2: Lesezugriff auf Durchklicken. Geprüft wird die Regel „schnell“ und
 * dass eine fehlende Migration (Spalte oder Funktion unbekannt) nichts bricht.
 * Der Client ist gemockt.
 */

const antwort = vi.hoisted(() => ({
  rpc: vi.fn(),
  zeilen: { data: null as unknown, error: null as unknown },
  filter: [] as [string, unknown][],
}))

vi.mock('@/lib/supabase/client', () => {
  const q = {
    select: () => q,
    eq: (s: string, w: unknown) => (antwort.filter.push([s, w]), q),
    in: (s: string, w: unknown) => (antwort.filter.push([s, w]), q),
    then: (fertig: (v: unknown) => unknown) => Promise.resolve(antwort.zeilen).then(fertig),
  }
  return { supabase: { from: () => q, rpc: antwort.rpc } }
})

const { istSchnell, loadNichtAuswertbar, loadSchnelleSitzungen } = await import('@/lib/supabase/lsaDurchklick')
import type { DurchklickStand } from '@/types'

const stand = (extra: Partial<DurchklickStand> = {}): DurchklickStand => ({
  antworten: 4,
  schnell_falsch: 0,
  anteil_schnell_falsch: 0,
  folge_schnell_falsch_max: 0,
  folge_schnell_aktuell: 0,
  nicht_auswertbar: false,
  grund: null,
  schwellen: { schnell_ms: 5000, folge: 5, anteil: 0.4, min_antworten: 10, hinweis_folge: 3 },
  ...extra,
})

beforeEach(() => {
  antwort.rpc.mockReset()
  antwort.zeilen = { data: null, error: null }
  antwort.filter = []
  vi.spyOn(console, 'warn').mockImplementation(() => {})
})

describe('istSchnell', () => {
  it('nicht auswertbar oder Hinweis-Folge erreicht (Schwelle aus der Datenbank)', () => {
    expect(istSchnell(stand())).toBe(false)
    expect(istSchnell(stand({ folge_schnell_aktuell: 2 }))).toBe(false)
    expect(istSchnell(stand({ folge_schnell_aktuell: 3 }))).toBe(true)
    expect(istSchnell(stand({ nicht_auswertbar: true, grund: 'anteil' }))).toBe(true)
  })
})

describe('loadSchnelleSitzungen', () => {
  it('liefert nur die schnellen Sitzungen', async () => {
    antwort.rpc.mockImplementation((_n: string, a: { p_session_id: string }) =>
      Promise.resolve({ data: stand({ folge_schnell_aktuell: a.p_session_id === 'ZZ_a' ? 3 : 1 }), error: null }),
    )
    expect([...(await loadSchnelleSitzungen(['ZZ_a', 'ZZ_b']))]).toEqual(['ZZ_a'])
  })

  it('ohne Migration (Funktion unbekannt): keine schnell, kein Fehler', async () => {
    antwort.rpc.mockResolvedValue({ data: null, error: { message: 'Could not find the function' } })
    expect((await loadSchnelleSitzungen(['ZZ_a'])).size).toBe(0)
  })
})

describe('loadNichtAuswertbar', () => {
  it('fragt nur auswertbar = false ab, mit Grund', async () => {
    antwort.zeilen = { data: [{ id: 'ZZ_k', nicht_auswertbar_grund: stand({ grund: 'folge' }) }], error: null }
    const karte = await loadNichtAuswertbar(['ZZ_k'])
    expect(antwort.filter).toEqual([['auswertbar', false], ['id', ['ZZ_k']]])
    expect(karte.get('ZZ_k')?.grund).toBe('folge')
  })

  it('ohne Migration (Spalte unbekannt): leer, also alles auswertbar', async () => {
    antwort.zeilen = { data: null, error: { message: 'column lsa_sessions.auswertbar does not exist' } }
    expect((await loadNichtAuswertbar()).size).toBe(0)
  })
})
