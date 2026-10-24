import { beforeEach, describe, expect, it } from 'vitest'
import { vi } from 'vitest'

/**
 * Bericht v3: getReportNotes lädt paket_bestaetigt und ziele_bestaetigt je in
 * einer eigenen Abfrage; fehlt eine Spalte (Migration noch nicht eingespielt),
 * gilt sie als „nicht bestätigt“. Der Client ist gemockt.
 */

type Antwort = { data: unknown; error: { code?: string; message: string } | null }

const mock = vi.hoisted(() => ({
  /** Antwort je ausgewählter Spalte (Schlüssel = select-String). */
  je: new Map<string, unknown>(),
  gewaehlt: [] as string[],
}))

vi.mock('@/lib/supabase/client', () => {
  const baue = (spalte: string) => {
    const q = {
      eq: () => q,
      maybeSingle: () => {
        const a = mock.je.get(spalte)
        if (a instanceof Error) return Promise.reject(a)
        return Promise.resolve(a ?? { data: null, error: null })
      },
    }
    return q
  }
  return {
    supabase: {
      from: () => ({
        select: (spalte: string) => {
          mock.gewaehlt.push(spalte)
          return baue(spalte)
        },
      }),
    },
  }
})

const { getReportNotes } = await import('@/lib/supabase/reportNotes')

const BASIS = 'zielbild, empfehlung, paket'
const ok = (data: unknown): Antwort => ({ data, error: null })
const fehlt = (spalte: string): Antwort => ({ data: null, error: { code: '42703', message: `column ${spalte} does not exist` } })

beforeEach(() => {
  mock.je = new Map()
  mock.gewaehlt = []
})

describe('getReportNotes — Bestätigungen des Coachs', () => {
  it('lädt Paket- und Ziele-Bestätigung aus je einer eigenen Abfrage', async () => {
    mock.je.set(BASIS, ok({ zielbild: 'Ziel', empfehlung: 'E', paket: 'standard' }))
    mock.je.set('paket_bestaetigt', ok({ paket_bestaetigt: true }))
    mock.je.set('ziele_bestaetigt', ok({ ziele_bestaetigt: true }))
    const r = await getReportNotes('s1')
    expect(r.error).toBeNull()
    expect(r.data).toEqual({
      zielbild: 'Ziel',
      empfehlung: 'E',
      paket: 'standard',
      paketBestaetigt: true,
      zieleBestaetigt: true,
    })
    expect(mock.gewaehlt).toEqual([BASIS, 'paket_bestaetigt', 'ziele_bestaetigt'])
  })

  it('beide Bestätigungen sind unabhängig voneinander', async () => {
    mock.je.set(BASIS, ok({ zielbild: null, empfehlung: null, paket: null }))
    mock.je.set('paket_bestaetigt', ok({ paket_bestaetigt: false }))
    mock.je.set('ziele_bestaetigt', ok({ ziele_bestaetigt: true }))
    const r = await getReportNotes('s1')
    expect(r.data).toMatchObject({ zielbild: '', empfehlung: '', paket: null, paketBestaetigt: false, zieleBestaetigt: true })
  })

  it('fehlt ziele_bestaetigt (Migration offen), gilt es als false; paket_bestaetigt bleibt erhalten', async () => {
    mock.je.set(BASIS, ok({ zielbild: 'Z', empfehlung: '', paket: 'basis' }))
    mock.je.set('paket_bestaetigt', ok({ paket_bestaetigt: true }))
    mock.je.set('ziele_bestaetigt', fehlt('ziele_bestaetigt'))
    const r = await getReportNotes('s1')
    expect(r.error).toBeNull()
    expect(r.unavailable).toBe(false)
    expect(r.data).toMatchObject({ paketBestaetigt: true, zieleBestaetigt: false })
  })

  it('fehlen beide Spalten oder wirft die Abfrage, bleibt der Rest nutzbar (beide false)', async () => {
    mock.je.set(BASIS, ok({ zielbild: 'Z', empfehlung: '', paket: 'premium' }))
    mock.je.set('paket_bestaetigt', fehlt('paket_bestaetigt'))
    mock.je.set('ziele_bestaetigt', new Error('Netz weg'))
    const r = await getReportNotes('s1')
    expect(r.error).toBeNull()
    expect(r.data).toMatchObject({ zielbild: 'Z', paket: 'premium', paketBestaetigt: false, zieleBestaetigt: false })
  })

  it('keine Zeile für die Sitzung: false, nicht undefined', async () => {
    mock.je.set(BASIS, ok(null))
    const r = await getReportNotes('s1')
    expect(r.data?.paketBestaetigt).toBe(false)
    expect(r.data?.zieleBestaetigt).toBe(false)
  })

  it('nur der Wert true zählt als bestätigt', async () => {
    mock.je.set(BASIS, ok({ zielbild: '', empfehlung: '', paket: null }))
    mock.je.set('paket_bestaetigt', ok({ paket_bestaetigt: 'true' }))
    mock.je.set('ziele_bestaetigt', ok({ ziele_bestaetigt: 1 }))
    const r = await getReportNotes('s1')
    expect(r.data).toMatchObject({ paketBestaetigt: false, zieleBestaetigt: false })
  })

  it('fehlende Tabelle: leere Notizen, unavailable, keine Bestätigungs-Abfragen', async () => {
    mock.je.set(BASIS, { data: null, error: { code: '42P01', message: 'relation does not exist' } })
    const r = await getReportNotes('s1')
    expect(r.unavailable).toBe(true)
    expect(r.data).toEqual({ zielbild: '', empfehlung: '', paket: null })
    expect(mock.gewaehlt).toEqual([BASIS])
  })

  it('anderer Fehler der Basisabfrage: Fehlermeldung, keine Daten', async () => {
    mock.je.set(BASIS, { data: null, error: { code: '500', message: 'kaputt' } })
    const r = await getReportNotes('s1')
    expect(r).toEqual({ data: null, error: 'kaputt', unavailable: false })
  })
})
