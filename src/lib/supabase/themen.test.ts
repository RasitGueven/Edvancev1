import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * setAktuellesThema geht in EINEM Aufruf an die Datenbank (RPC
 * lead_thema_setzen). Frueher waren es zwei — loeschen, dann schreiben — und
 * ein Abbruch dazwischen liess den Lead ohne Thema. Der Client ist gemockt;
 * geprueft wird, dass kein Tabellenzugriff mehr daneben laeuft.
 */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const { setAktuellesThema } = await import('@/lib/supabase/themen')

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
  rpc.mockResolvedValue({ data: null, error: null })
})

describe('setAktuellesThema', () => {
  it('setzt das Thema ueber die RPC, ohne Tabellenzugriff', async () => {
    const res = await setAktuellesThema('ZZ_lead', 'mathematik', 'zufallsexperimente')
    expect(res).toEqual({ data: null, error: null })
    expect(rpc).toHaveBeenCalledTimes(1)
    expect(rpc).toHaveBeenCalledWith('lead_thema_setzen', {
      p_lead_id: 'ZZ_lead',
      p_fach: 'mathematik',
      p_thema_key: 'zufallsexperimente',
      p_quelle: 'gespraech',
    })
    expect(from).not.toHaveBeenCalled()
  })

  it('entfernt das Thema mit null', async () => {
    await setAktuellesThema('ZZ_lead', 'mathematik', null)
    expect(rpc).toHaveBeenCalledWith(
      'lead_thema_setzen',
      expect.objectContaining({ p_thema_key: null }),
    )
  })

  it('gibt die Meldung der Datenbank weiter', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'lead_thema_setzen: nur Admin' } })
    const res = await setAktuellesThema('ZZ_lead', 'mathematik', 'zufallsexperimente')
    expect(res).toEqual({ data: null, error: 'lead_thema_setzen: nur Admin' })
  })
})
