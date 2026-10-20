import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * Slots SL1: Die Wrapper gehen nur über RPCs (Entscheidung 24). Der Client ist gemockt; geprüft werden
 * Funktionsname, Parameternamen, dass p_jetzt nie mitgeht (Entscheidung 17), und die Weitergabe von
 * SQLSTATE und Hinweis für die Übersetzung der SL-Codes.
 */

const rpc = vi.fn()
const from = vi.fn()

vi.mock('@/lib/supabase/client', () => ({ supabase: { rpc, from } }))

const s = await import('@/lib/supabase/slotplan')

beforeEach(() => {
  rpc.mockReset()
  from.mockReset()
  rpc.mockResolvedValue({ data: null, error: null })
})

describe('Slots-Lesefunktionen', () => {
  it('rufen je Bildschirm genau eine Funktion mit den Parameternamen der Datenbank', async () => {
    await s.ladeWoche('2028-03-13')
    expect(rpc).toHaveBeenLastCalledWith('slots_woche', { p_montag: '2028-03-13' })
    await s.ladeTermin('2028-03-16', 'ZZ_z')
    expect(rpc).toHaveBeenLastCalledWith('slots_termin', { p_datum: '2028-03-16', p_zeit_id: 'ZZ_z' })
    await s.ladeTag('2028-03-16')
    expect(rpc).toHaveBeenLastCalledWith('slots_tag', { p_datum: '2028-03-16' })
    await s.ladeZaehler()
    expect(rpc).toHaveBeenLastCalledWith('slots_zaehler', {})
    await s.ladeKinder()
    expect(rpc).toHaveBeenLastCalledWith('slots_kinder', {})
    await s.ladeKind('ZZ_k')
    expect(rpc).toHaveBeenLastCalledWith('slots_kind', { p_student_id: 'ZZ_k' })
    await s.ladeCoaches('2028-03-13')
    expect(rpc).toHaveBeenLastCalledWith('slots_coaches', { p_montag: '2028-03-13' })
    await s.ladeEinstellungen()
    expect(rpc).toHaveBeenLastCalledWith('slots_einstellungen', {})
    await s.ladeMeineEinsaetze('2028-03-13')
    expect(rpc).toHaveBeenLastCalledWith('meine_einsaetze', { p_montag: '2028-03-13' })
    await s.ladeNaechsteTermine('ZZ_k')
    expect(rpc).toHaveBeenLastCalledWith('naechste_termine', { p_student_id: 'ZZ_k', p_anzahl: 3 })
    expect(from).not.toHaveBeenCalled()
  })

  it('schicken für die Dialoge die Zeilen, den Eingang und die Defaults mit', async () => {
    const zeilen = [{ wochentag: 2, slot_zeit_id: 'ZZ_z', takt: 'woechentlich' as const }]
    await s.ladePlanbilanzVorschau('ZZ_k', zeilen, '2028-03-14')
    expect(rpc).toHaveBeenLastCalledWith('slots_planbilanz_vorschau',
      { p_student_id: 'ZZ_k', p_zeilen: zeilen, p_ab: '2028-03-14', p_ersetzt: null })
    await s.ladeFrei('a_woche', '2028-03-14')
    expect(rpc).toHaveBeenLastCalledWith('slots_frei', { p_takt: 'a_woche', p_ab: '2028-03-14', p_student_id: null })
    await s.ladeZiele('ZZ_k', 'ZZ_t', '2028-03-13T08:00:00.000Z', '2028-03-13')
    expect(rpc).toHaveBeenLastCalledWith('slots_ziele', {
      p_student_id: 'ZZ_k', p_ausser_termin_id: 'ZZ_t', p_eingang: '2028-03-13T08:00:00.000Z', p_ab: '2028-03-13', p_wochen: 4,
    })
    await s.ladeKandidaten('2028-03-16', 'ZZ_z')
    expect(rpc).toHaveBeenLastCalledWith('slots_kandidaten', { p_datum: '2028-03-16', p_zeit_id: 'ZZ_z' })
  })
})

describe('Slots-Schreibfunktionen', () => {
  it('senden den Eingang der Absage, nicht das Ergebnis der 10-Uhr-Regel', async () => {
    await s.terminAbsagen('ZZ_t', '2028-03-16T08:59:00.000Z')
    expect(rpc).toHaveBeenLastCalledWith('termin_absagen', { p_termin_id: 'ZZ_t', p_eingang: '2028-03-16T08:59:00.000Z' })
    await s.terminUmbuchen('ZZ_t', '2028-03-16T08:59:00.000Z', '2028-03-22', 'ZZ_z')
    expect(rpc).toHaveBeenLastCalledWith('termin_umbuchen', {
      p_termin_id: 'ZZ_t', p_eingang: '2028-03-16T08:59:00.000Z', p_ziel_datum: '2028-03-22', p_ziel_zeit_id: 'ZZ_z',
    })
  })

  it('übergeben nie p_jetzt', async () => {
    const zeile = { wochentag: 4, slot_zeit_id: 'ZZ_z', takt: 'woechentlich' as const }
    await s.stammplatzVergeben('ZZ_k', [zeile], '2028-03-14')
    await s.stammplatzAendern('ZZ_sp', '2028-04-25', zeile)
    await s.stammplatzBeenden('ZZ_sp', '2028-04-25')
    await s.stammplaetzeWeiterfuehren('ZZ_k')
    await s.absageZuruecknehmen('ZZ_t')
    await s.zusatzterminBuchen('ZZ_k', '2028-03-15', 'ZZ_z')
    await s.terminAusgefallen('ZZ_t')
    await s.terminFaelltAus('2028-03-16', 'ZZ_z')
    await s.terminRaumSetzen('ZZ_t', null)
    await s.terminCoachSetzen('2028-03-16', 'ZZ_z', 'ZZ_r', null)
    await s.terminRaumOeffnen('2028-03-16', 'ZZ_z', 'ZZ_r', 'ZZ_c')
    await s.terminSessionAnlegen('2028-03-16', 'ZZ_z', 'ZZ_r')
    await s.stammschichtAnlegen('ZZ_c', 2, 'ZZ_z', 'ZZ_r')
    await s.stammschichtBeenden('ZZ_st', '2028-04-01')
    await s.raumAnlegen('Raum 4')
    await s.raumDeaktivieren('ZZ_r', '2028-04-01')
    await s.slotZeitAnlegen('20:00')
    await s.slotZeitDeaktivieren('ZZ_z', '2028-04-01')
    await s.stammschichtBlockAnlegen('ZZ_c', 4, 'ZZ_z14', 'ZZ_z17', 'ZZ_r')
    await s.stammschichtRaumWechseln(['ZZ_st'], 'ZZ_r2', '2028-04-03', true)
    await s.ladeKandidatenAlle('2028-03-16', 'ZZ_z', 'ZZ_r')
    await s.ladeStammplatzVorschau('ZZ_k', 4, 'ZZ_z', 'ZZ_r', 'a_woche', '2028-03-16')
    expect(rpc).toHaveBeenCalledTimes(22)
    for (const [, args] of rpc.mock.calls) expect(args).not.toHaveProperty('p_jetzt')
    expect(rpc).toHaveBeenCalledWith('stammplatz_aendern',
      { p_id: 'ZZ_sp', p_ab: '2028-04-25', p_wochentag: 4, p_slot_zeit_id: 'ZZ_z', p_takt: 'woechentlich', p_raum_id: null })
    expect(rpc).toHaveBeenCalledWith('zusatztermin_buchen',
      { p_student_id: 'ZZ_k', p_datum: '2028-03-15', p_zeit_id: 'ZZ_z', p_raum_id: null })
    expect(rpc).toHaveBeenCalledWith('termin_coach_setzen',
      { p_datum: '2028-03-16', p_zeit_id: 'ZZ_z', p_raum_id: 'ZZ_r', p_coach_id: null })
    expect(from).not.toHaveBeenCalled()
  })

  it('W1: übergeben den Raum und die Blockgrenzen mit den Namen der Datenbank', async () => {
    await s.stammplatzVergeben('ZZ_k', [{ wochentag: 1, slot_zeit_id: 'ZZ_z', takt: 'woechentlich', raum_id: 'ZZ_r' }], '2028-03-13')
    expect(rpc).toHaveBeenLastCalledWith('stammplatz_vergeben', {
      p_student_id: 'ZZ_k', p_zeilen: [{ wochentag: 1, slot_zeit_id: 'ZZ_z', takt: 'woechentlich', raum_id: 'ZZ_r' }], p_ab: '2028-03-13',
    })
    await s.stammplatzAendern('ZZ_sp', '2028-04-25', { wochentag: 2, slot_zeit_id: 'ZZ_z', takt: 'b_woche', raum_id: 'ZZ_r2' })
    expect(rpc).toHaveBeenLastCalledWith('stammplatz_aendern',
      { p_id: 'ZZ_sp', p_ab: '2028-04-25', p_wochentag: 2, p_slot_zeit_id: 'ZZ_z', p_takt: 'b_woche', p_raum_id: 'ZZ_r2' })
    await s.zusatzterminBuchen('ZZ_k', '2028-03-15', 'ZZ_z', 'ZZ_r')
    expect(rpc).toHaveBeenLastCalledWith('zusatztermin_buchen',
      { p_student_id: 'ZZ_k', p_datum: '2028-03-15', p_zeit_id: 'ZZ_z', p_raum_id: 'ZZ_r' })
    await s.ladeKandidatenAlle('2028-03-16', 'ZZ_z', 'ZZ_r')
    expect(rpc).toHaveBeenLastCalledWith('slots_kandidaten_alle', { p_datum: '2028-03-16', p_zeit_id: 'ZZ_z', p_raum_id: 'ZZ_r' })
    await s.ladeStammplatzVorschau('ZZ_k', 4, 'ZZ_z', 'ZZ_r', 'a_woche', '2028-03-16')
    expect(rpc).toHaveBeenLastCalledWith('stammplatz_vorschau', {
      p_student_id: 'ZZ_k', p_wochentag: 4, p_slot_zeit_id: 'ZZ_z', p_raum_id: 'ZZ_r', p_takt: 'a_woche', p_ab: '2028-03-16',
      p_ersetzt: null,
    })
    await s.stammschichtBlockAnlegen('ZZ_c', 4, 'ZZ_z14', 'ZZ_z17', 'ZZ_r')
    expect(rpc).toHaveBeenLastCalledWith('stammschicht_block_anlegen', {
      p_coach_id: 'ZZ_c', p_wochentag: 4, p_von_zeit_id: 'ZZ_z14', p_bis_zeit_id: 'ZZ_z17', p_raum_id: 'ZZ_r', p_gueltig_ab: null,
    })
    await s.stammschichtRaumWechseln(['ZZ_st'], 'ZZ_r2', '2028-04-03', false)
    expect(rpc).toHaveBeenLastCalledWith('stammschicht_raum_wechseln',
      { p_ids: ['ZZ_st'], p_raum_id: 'ZZ_r2', p_ab: '2028-04-03', p_kinder_mitnehmen: false })
    expect(from).not.toHaveBeenCalled()
  })

  it('geben SQLSTATE und Hinweis weiter (SL-Code)', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'zusatztermin_buchen: Slot voll', code: 'SL001', hint: 'SL001' } })
    const res = await s.zusatzterminBuchen('ZZ_k', '2028-03-15', 'ZZ_z')
    expect(res).toEqual({ data: null, error: 'zusatztermin_buchen: Slot voll', code: 'SL001', hint: 'SL001' })
  })

  it('fängt einen geworfenen Fehler ab', async () => {
    rpc.mockRejectedValue(new Error('Netz weg'))
    const res = await s.ladeWoche('2028-03-13')
    expect(res).toEqual({ data: null, error: 'Netz weg' })
  })
})
