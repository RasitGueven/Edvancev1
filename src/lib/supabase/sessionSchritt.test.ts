import { beforeEach, describe, expect, it, vi } from 'vitest'

/** Session-Engine A2: nur ueber die RPC, Parameternamen wie in der Datenbank. */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const { naechsterSchritt, schrittVorschau } = await import('@/lib/supabase/sessionSchritt')

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
})

describe('session_naechster_schritt', () => {
  it('ruft vom Tablet ohne Kind auf (das Kind kommt aus dem Platz)', async () => {
    rpc.mockResolvedValue({ data: { art: 'aufgabe', grund: 'ZZ' }, error: null })
    const res = await naechsterSchritt('ZZ_s')
    expect(rpc).toHaveBeenCalledWith('session_naechster_schritt', { p_session_id: 'ZZ_s', p_student_id: null })
    expect(res.data?.art).toBe('aufgabe')
    expect(from).not.toHaveBeenCalled()
  })

  it('reicht fuer die Vorschau das Kind durch und gibt Fehler der Datenbank weiter', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'session_naechster_schritt: nur der eigene Platz' } })
    const res = await schrittVorschau('ZZ_s', 'ZZ_k')
    expect(rpc).toHaveBeenCalledWith('session_naechster_schritt', { p_session_id: 'ZZ_s', p_student_id: 'ZZ_k' })
    expect(res).toEqual({ data: null, error: 'session_naechster_schritt: nur der eigene Platz' })
  })
})
