import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * Die Session-Wrapper aus R1 gehen nur ueber RPCs (die Tabellen sind fuer
 * Clients gesperrt). Der Client ist gemockt; geprueft werden Funktionsname,
 * Parameternamen und die Weitergabe der Datenbank-Meldung.
 */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const { tabletZuweisen, eingriffNotieren, abschlussSetzen, raumLive } = await import('@/lib/supabase/sessionCoach')
const { antwortAbgeben, questTerminSetzen } = await import('@/lib/supabase/sessionTablet')
const { stellschraubeSetzen } = await import('@/lib/supabase/sessionEinstellungen')

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
  rpc.mockResolvedValue({ data: null, error: null })
})

describe('Session-RPCs', () => {
  it('weist ein Tablet ueber die RPC zu, ohne Tabellenzugriff', async () => {
    rpc.mockResolvedValue({ data: 'ZZ_platz', error: null })
    const res = await tabletZuweisen('ZZ_s', 'ZZ_k', 3)
    expect(res).toEqual({ data: 'ZZ_platz', error: null })
    expect(rpc).toHaveBeenCalledWith('tablet_zuweisen', { p_session_id: 'ZZ_s', p_student_id: 'ZZ_k', p_tablet_nr: 3 })
    expect(from).not.toHaveBeenCalled()
  })

  it('schickt beim Eingriff ohne Fehlbild null', async () => {
    await eingriffNotieren('ZZ_s', 'ZZ_k', 2)
    expect(rpc).toHaveBeenCalledWith('eingriff_notieren',
      { p_session_id: 'ZZ_s', p_student_id: 'ZZ_k', p_stufe: 2, p_fehlbild_slug: null })
  })

  it('laesst nicht gesetzte Check-out-Felder als null (= unveraendert)', async () => {
    await abschlussSetzen('ZZ_s', 'ZZ_k', { notiz: 'ZZ Notiz', flagEltern: true })
    expect(rpc).toHaveBeenCalledWith('abschluss_setzen', {
      p_session_id: 'ZZ_s', p_student_id: 'ZZ_k', p_satz_text: null, p_satz_gesagt: null,
      p_notiz: 'ZZ Notiz', p_flag_eltern: true, p_flag_pfad: null, p_exit_ergebnis: null,
    })
  })

  it('setzt den Quest-Termin vom Tablet ohne Kind (der Server kennt den Platz)', async () => {
    await questTerminSetzen('ZZ_s', '2026-10-08T15:00:00.000Z')
    expect(rpc).toHaveBeenCalledWith('quest_termin_setzen',
      { p_session_id: 'ZZ_s', p_student_id: null, p_termin: '2026-10-08T15:00:00.000Z' })
  })

  it('gibt Antwort und Stellschraube mit den Parameternamen der Datenbank weiter', async () => {
    await antwortAbgeben('ZZ_s', 'ZZ_t', null, { text: '10' }, 4200)
    expect(rpc).toHaveBeenCalledWith('antwort_abgeben',
      { p_session_id: 'ZZ_s', p_task_id: 'ZZ_t', p_teil: null, p_eingabe: { text: '10' }, p_dauer_ms: 4200 })
    await stellschraubeSetzen('ka_tage', 10, 'Pilot')
    expect(rpc).toHaveBeenLastCalledWith('einstellung_setzen', { p_schluessel: 'ka_tage', p_wert: 10, p_grund: 'Pilot' })
  })

  it('gibt die Meldung der Datenbank weiter', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'coach_raum_live: nur der Coach der Session oder ein Admin' } })
    const res = await raumLive('ZZ_s')
    expect(res).toEqual({ data: null, error: 'coach_raum_live: nur der Coach der Session oder ein Admin' })
  })

  it('faengt einen geworfenen Fehler ab', async () => {
    rpc.mockRejectedValue(new Error('ZZ Netz weg'))
    const res = await raumLive('ZZ_s')
    expect(res).toEqual({ data: null, error: 'ZZ Netz weg' })
  })
})
