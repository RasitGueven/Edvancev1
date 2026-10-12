// Slots SL2, Tests 2–4: Absage (10-Uhr-Vorschau, gesendet wird der Eingang), Umbuchen (nur Ziele aus
// slots_ziele, Abnahmefall 5/6), Stammplatz-Dialog (Speichern gesperrt mit Gründen, Abnahmefall 9; Tippen ins
// Raster übernimmt den Slot).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import '@/i18n'
import { berlinLocalToIso } from '@/lib/datetime'

const sp = vi.hoisted(() => ({
  terminAbsagen: vi.fn(),
  terminUmbuchen: vi.fn(),
  ladeZiele: vi.fn(),
  ladeFrei: vi.fn(),
  ladePlanbilanzVorschau: vi.fn(),
  stammplatzVergeben: vi.fn(),
  stammplatzAendern: vi.fn(),
}))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { AbsageDialog } = await import('./AbsageDialog')
const { StammplatzDialog } = await import('./StammplatzDialog')

const termin = { termin_id: 't1', student_id: 'k1', name: 'Lena Hoffmann', datum: '2028-03-16', beginn: '16:00', ende: '17:00' }

beforeEach(() => {
  Object.values(sp).forEach((f) => f.mockReset())
  sp.terminAbsagen.mockResolvedValue({ data: { termin_id: 't1', zustand: 'cancelled', rechtzeitig: true }, error: null })
  sp.terminUmbuchen.mockResolvedValue({ data: { termin_id: 't2' }, error: null })
})

describe('Absage-Dialog (Test 2, K 61)', () => {
  it('Vorschau wechselt zwischen 09:59 und 10:00; gesendet wird der Eingang', async () => {
    const gespeichert = vi.fn()
    render(<AbsageDialog termin={termin} umbuchen={false} onClose={() => undefined} onGespeichert={gespeichert} />)
    fireEvent.change(screen.getByLabelText('Datum des Eingangs'), { target: { value: '2028-03-16' } })
    fireEvent.change(screen.getByLabelText('Uhrzeit des Eingangs'), { target: { value: '09:59' } })
    expect(screen.getByRole('status').textContent).toBe('Rechtzeitig, die Einheit bleibt offen.')
    fireEvent.change(screen.getByLabelText('Uhrzeit des Eingangs'), { target: { value: '10:00' } })
    expect(screen.getByRole('status').textContent).toBe('Nach 10:00 Uhr: unentschuldigt, die Einheit ist verbraucht.')

    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Absage speichern' })))
    expect(sp.terminAbsagen).toHaveBeenCalledWith('t1', berlinLocalToIso('2028-03-16', '10:00'))
    expect(sp.terminAbsagen.mock.calls[0]).toHaveLength(2)
    expect(gespeichert).toHaveBeenCalled()
  })

  it('zeigt einen SL-Code als ruhigen Satz', async () => {
    sp.terminAbsagen.mockResolvedValue({ data: null, error: 'termin_absagen: …', code: 'SL011', hint: 'SL011' })
    render(<AbsageDialog termin={termin} umbuchen={false} onClose={() => undefined} onGespeichert={() => undefined} />)
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Absage speichern' })))
    expect(screen.getByRole('alert').textContent).toBe('Der Termin ist vergangen oder hat begonnen und lässt sich nur noch ansehen.')
  })
})

describe('Umbuchen (Test 4, Abnahmefall 5 und 6)', () => {
  it('zeigt nur die Ziele aus slots_ziele und bucht das gewählte', async () => {
    sp.ladeZiele.mockResolvedValue({
      data: {
        ab: '2028-03-13', wochen: 4, alt_verbraucht: false, kein_budget: false,
        ziele: [
          { datum: '2028-03-15', zeit_id: 'z15', beginn: '15:00', ende: '16:00', frei: 3, verdraengt: null },
          { datum: '2028-03-22', zeit_id: 'z17', beginn: '17:00', ende: '18:00', frei: 1, verdraengt: '2028-06-13' },
        ],
      },
      error: null,
    })
    render(<AbsageDialog termin={termin} umbuchen onClose={() => undefined} onGespeichert={() => undefined} />)
    const gruppe = await screen.findByRole('group', { name: 'Mögliche Termine' })
    const chips = within(gruppe).getAllByRole('button')
    expect(chips).toHaveLength(2)
    expect(sp.ladeZiele.mock.calls[0][1]).toBe('t1')

    expect((screen.getByRole('button', { name: 'Umbuchen' }) as HTMLButtonElement).disabled).toBe(true)
    expect(screen.getByText('Wähle einen Termin.')).toBeTruthy()
    fireEvent.click(chips[1])
    expect(screen.getByText(/Dafür fällt der Stammplatz-Termin am Di 13.06. weg/)).toBeTruthy()
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Umbuchen' })))
    expect(sp.terminUmbuchen).toHaveBeenCalledWith('t1', expect.any(String), '2028-03-22', 'z17')
  })

  it('ohne passendes Ziel ein ruhiger Satz statt eines leeren Rasters', async () => {
    sp.ladeZiele.mockResolvedValue({ data: { ab: '2028-03-13', wochen: 4, alt_verbraucht: false, kein_budget: false, ziele: [] }, error: null })
    render(<AbsageDialog termin={termin} umbuchen onClose={() => undefined} onGespeichert={() => undefined} />)
    expect(await screen.findByText('In den nächsten vier Wochen gibt es keinen passenden freien Termin.')).toBeTruthy()
  })
})

describe('Stammplatz-Dialog (Test 3, Abnahmefall 9)', () => {
  const frei = {
    takt: 'woechentlich', ab: '2028-03-14',
    zeiten: [{ id: 'z16', beginn: '16:00', ende: '17:00' }],
    zellen: [
      { wochentag: 1, zeit_id: 'z16', frei: 0, raum: true, voll: true, termine: 6 },
      { wochentag: 2, zeit_id: 'z16', frei: 3, raum: true, voll: false, termine: 6 },
      { wochentag: 3, zeit_id: 'z16', frei: 0, raum: false, voll: false, termine: 6 },
    ],
  }
  const kindStamm = { student_id: 'k1', name: 'Jonas Köhler', beginn: '2028-02-01', vertrag_laeuft: true, rhythmus: { woechentlich: 1, vierzehntaeglich: 0 } }

  it('Tippen ins Raster übernimmt den Slot; Speichern gesperrt mit den Gründen der Vorschau', async () => {
    sp.ladeFrei.mockResolvedValue({ data: frei, error: null })
    sp.ladePlanbilanzVorschau.mockResolvedValue({
      data: { planbilanz: null, terminzahl: null, letzter_termin: null, uebersprungen: [], gruende: [{ code: 'SL001', zeile: 0 }] },
      error: null,
    })
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    const speichern = screen.getByRole('button', { name: 'Speichern' }) as HTMLButtonElement
    expect(speichern.disabled).toBe(true)
    expect(within(screen.getByRole('list', { name: 'Warum Speichern noch nicht geht' })).getByText('Zeile 1: Tag und Uhrzeit wählen.')).toBeTruthy()

    expect(await screen.findByText('voll')).toBeTruthy()
    expect(screen.queryByRole('button', { name: /Montag 16:00/ })).toBeNull()
    expect(screen.getAllByText('kein Raum').length).toBe(3)
    fireEvent.click(await screen.findByRole('button', { name: 'Dienstag 16:00: 3 Plätze frei' }))
    expect(screen.getByRole('button', { name: /Zeile 1/ }).textContent).toContain('Di 16:00')

    await waitFor(() => expect(sp.ladePlanbilanzVorschau).toHaveBeenCalledWith('k1', [{ wochentag: 2, slot_zeit_id: 'z16', takt: 'woechentlich' }], expect.any(String), null))
    expect(await screen.findByText('Zeile 1: Dieser Termin ist voll.')).toBeTruthy()
    expect(speichern.disabled).toBe(true)
    expect(sp.stammplatzVergeben).not.toHaveBeenCalled()
  })

  it('ohne Gründe speichert er die Zeilen', async () => {
    sp.ladeFrei.mockResolvedValue({ data: frei, error: null })
    sp.ladePlanbilanzVorschau.mockResolvedValue({ data: { planbilanz: null, terminzahl: null, letzter_termin: null, uebersprungen: [], gruende: [] }, error: null })
    sp.stammplatzVergeben.mockResolvedValue({ data: { stammplatz_ids: ['s1'], planbilanz: null }, error: null })
    const gespeichert = vi.fn()
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={gespeichert} />)
    fireEvent.click(await screen.findByRole('button', { name: 'Dienstag 16:00: 3 Plätze frei' }))
    await waitFor(() => expect((screen.getByRole('button', { name: 'Speichern' }) as HTMLButtonElement).disabled).toBe(false))
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Speichern' })))
    expect(sp.stammplatzVergeben).toHaveBeenCalledWith('k1', [{ wochentag: 2, slot_zeit_id: 'z16', takt: 'woechentlich' }], expect.any(String))
    expect(gespeichert).toHaveBeenCalled()
  })
})
