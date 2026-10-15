import { beforeEach, describe, expect, it, vi } from 'vitest'
import de from '@/i18n/locales/de/slots.json'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'

/**
 * Slots S1: Sofort-Session und Buchbarkeit. Der Client ist gemockt; geprüft werden Funktionsname,
 * Parameternamen, dass p_jetzt nie mitgeht, und die Weitergabe von SQLSTATE, Hinweis und Detail
 * samt Abbildung auf einen Text.
 */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const s = await import('@/lib/supabase/stundenplan')

const text = (schluessel: string): unknown =>
  schluessel.split('.').reduce<unknown>((o, k) => (o as Record<string, unknown> | undefined)?.[k], de)

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
  rpc.mockResolvedValue({ data: null, error: null })
})

describe('Stundenplan-Funktionen', () => {
  it('rufen je eine RPC mit den Parameternamen der Datenbank, nie p_jetzt', async () => {
    await s.ladeKinderBuchbar('2027-11-07')
    expect(rpc).toHaveBeenLastCalledWith('kinder_buchbar', { p_datum: '2027-11-07', p_session_id: null })
    await s.ladeKinderBuchbar('2027-11-07', 'ZZ_s')
    expect(rpc).toHaveBeenLastCalledWith('kinder_buchbar', { p_datum: '2027-11-07', p_session_id: 'ZZ_s' })
    await s.sofortSessionAnlegen('ZZ_c', 'ZZ_r', ['ZZ_k1', 'ZZ_k2'])
    expect(rpc).toHaveBeenLastCalledWith('sofort_session_anlegen',
      { p_coach_id: 'ZZ_c', p_raum_id: 'ZZ_r', p_student_ids: ['ZZ_k1', 'ZZ_k2'] })
    await s.ladeSessionLeitung()
    expect(rpc).toHaveBeenLastCalledWith('session_leitung', {})
    await s.ladeStundenplanWoche('2027-11-03')
    expect(rpc).toHaveBeenLastCalledWith('stundenplan_woche', { p_montag: '2027-11-03' })
    for (const [, args] of rpc.mock.calls) expect(args).not.toHaveProperty('p_jetzt')
    expect(from).not.toHaveBeenCalled()
  })

  it('reichen die Daten durch', async () => {
    const ergebnis = { session_id: 'ZZ_s', testlauf: true }
    rpc.mockResolvedValue({ data: ergebnis, error: null })
    expect(await s.sofortSessionAnlegen('ZZ_c', 'ZZ_r', ['ZZ_k'])).toEqual({ data: ergebnis, error: null })
  })
})

describe('Fehlerabbildung', () => {
  it('gibt Code, Hinweis und Detail (das Kind) weiter', async () => {
    rpc.mockResolvedValue({
      data: null,
      error: { message: 'sofort_session_anlegen: Kind nicht buchbar (vertrag_ab)', code: '22023', hint: 'vertrag_ab', details: 'ZZ_k' },
    })
    const res = await s.sofortSessionAnlegen('ZZ_c', 'ZZ_r', ['ZZ_k'])
    expect(res).toMatchObject({ data: null, code: '22023', hint: 'vertrag_ab', detail: 'ZZ_k' })
    expect(slotsFehlerSchluessel(res)).toBe('fehler.vertragAb')
  })

  it('lässt das Detail weg, wenn die Datenbank keins liefert', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'x', code: '42501', hint: null } })
    const res = await s.ladeStundenplanWoche('2027-11-03')
    expect(res).toEqual({ data: null, error: 'x', code: '42501' })
    expect(slotsFehlerSchluessel(res)).toBe('fehler.keinRecht')
  })

  it('hat für jeden Hinweis der Sofort-Session einen eigenen Text', () => {
    const hinweise = ['keine_kinder', 'zu_viele', 'kein_kind', 'raum_inaktiv', 'art_konflikt', 'kein_coach', 'kein_vertrag', 'widerrufen',
      'vertrag_ab', 'vertrag_beendet', 'keine_einheit', 'schon_termin', 'datum_session']
    for (const hint of hinweise) {
      const k = slotsFehlerSchluessel({ code: '22023', hint })
      expect(k).not.toBe('fehler.eingabe')
      expect(typeof text(k)).toBe('string')
    }
  })

  it('hat für jeden Grund aus kinder_buchbar einen Text', () => {
    for (const code of ['ok', 'kein_vertrag', 'widerrufen', 'vertrag_ab', 'vertrag_beendet', 'keine_einheit', 'schon_termin', 'art_konflikt']) {
      expect(typeof text(`buchbar.${code}`)).toBe('string')
    }
  })
})
