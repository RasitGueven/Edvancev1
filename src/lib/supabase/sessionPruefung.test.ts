import { beforeEach, describe, expect, it, vi } from 'vitest'

/** A2b: Pruefrage aufs Tablet nur ueber die RPCs, Parameternamen wie in der Datenbank. */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const { pruefungAufsTablet, pruefungVomTablet } = await import('@/lib/supabase/sessionPruefung')

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
})

describe('Pruefrage aufs Tablet', () => {
  it('legt die Frage ueber die RPC aufs Tablet', async () => {
    rpc.mockResolvedValue({ data: { skill_key: 'ZZ_sk', aktiv: true }, error: null })
    const res = await pruefungAufsTablet('ZZ_s', 'ZZ_k', 'ZZ_sk')
    expect(rpc).toHaveBeenCalledWith('pruefung_aufs_tablet', { p_session_id: 'ZZ_s', p_student_id: 'ZZ_k', p_skill_key: 'ZZ_sk' })
    expect(res.data?.aktiv).toBe(true)
    expect(from).not.toHaveBeenCalled()
  })

  it('nimmt sie zurueck und reicht Fehler der Datenbank durch', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'pruefung_vom_tablet: keine Pruefrage auf dem Tablet' } })
    const res = await pruefungVomTablet('ZZ_s', 'ZZ_k')
    expect(rpc).toHaveBeenCalledWith('pruefung_vom_tablet', { p_session_id: 'ZZ_s', p_student_id: 'ZZ_k' })
    expect(res).toEqual({ data: null, error: 'pruefung_vom_tablet: keine Pruefrage auf dem Tablet' })
  })
})
