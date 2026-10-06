import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * Lernpfad (Paket A1): Schreiben laeuft nur ueber RPCs, nie ueber einen
 * Tabellenzugriff. Der Client ist gemockt.
 */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const { lernpfadBeleg, masteryEntscheiden, naechsteLuecke, pfadTiefer } = await import(
  '@/lib/supabase/lernpfad'
)

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
})

describe('masteryEntscheiden', () => {
  it('ruft mastery_entscheiden mit allen Parametern, ohne Tabellenzugriff', async () => {
    const antwort = { ok: true, skill_key: 'zz', stand_system: 'kandidat', stand_coach: 'vertagt' }
    rpc.mockResolvedValue({ data: antwort, error: null })
    const res = await masteryEntscheiden({
      studentId: 'kind', skillKey: 'zz', entscheidung: 'vertagt', grund: 'Heute nicht pruefbar', sessionId: 's2',
    })
    expect(res).toEqual({ data: antwort, error: null })
    expect(rpc).toHaveBeenCalledWith('mastery_entscheiden', {
      p_student_id: 'kind', p_skill_key: 'zz', p_entscheidung: 'vertagt',
      p_grund: 'Heute nicht pruefbar', p_session_id: 's2',
    })
    expect(from).not.toHaveBeenCalled()
  })

  it('gibt die Meldung der Datenbank weiter', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'mastery_entscheiden: nur Coach der Session oder Admin' } })
    const res = await masteryEntscheiden({
      studentId: 'kind', skillKey: 'zz', entscheidung: 'gemeistert', grund: null, sessionId: null,
    })
    expect(res).toEqual({ data: null, error: 'mastery_entscheiden: nur Coach der Session oder Admin' })
  })
})

describe('lernpfadBeleg und pfadTiefer', () => {
  it('bucht einen Beleg ueber die RPC', async () => {
    rpc.mockResolvedValue({ data: 'kandidat', error: null })
    const res = await lernpfadBeleg({
      studentId: 'kind', skillKey: 'zz', sessionId: 's2', ergebnis: 'richtig', hinweisGenutzt: false,
    })
    expect(res).toEqual({ data: 'kandidat', error: null })
    expect(rpc).toHaveBeenCalledWith('lernpfad_beleg', {
      p_student_id: 'kind', p_skill_key: 'zz', p_session_id: 's2', p_ergebnis: 'richtig', p_hinweis_genutzt: false,
    })
  })

  it('pfadTiefer schickt ohne Voraussetzung null', async () => {
    rpc.mockResolvedValue({ data: 'zz_vor', error: null })
    await pfadTiefer({ studentId: 'kind', skillKey: 'zz', sessionId: 's1' })
    expect(rpc).toHaveBeenCalledWith('pfad_tiefer', {
      p_student_id: 'kind', p_skill_key: 'zz', p_session_id: 's1', p_voraussetzung: null,
    })
  })

  it('faengt einen geworfenen Fehler ab', async () => {
    rpc.mockRejectedValue(new Error('Netz weg'))
    const res = await pfadTiefer({ studentId: 'kind', skillKey: 'zz', sessionId: null })
    expect(res).toEqual({ data: null, error: 'Netz weg' })
  })
})

describe('naechsteLuecke', () => {
  it('liefert die erste Zeile oder null', async () => {
    const zeile = { skill_key: 'zz', label: 'ZZ', thema_key: 't', stand_system: 'noch_nicht_sicher', quelle: 'lsa' }
    rpc.mockResolvedValue({ data: [zeile], error: null })
    expect(await naechsteLuecke('kind')).toEqual({ data: zeile, error: null })
    rpc.mockResolvedValue({ data: [], error: null })
    expect(await naechsteLuecke('kind')).toEqual({ data: null, error: null })
  })
})
