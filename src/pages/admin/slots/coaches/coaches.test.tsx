// Slots W4: Reiter Coaches mit Schichten als Blöcke. Block anlegen (von/bis), Konfliktsatz, Raum ändern mit und ohne
// Kinder, gesperrter Zielraum mit Grund, Entfernen über den Dialog. Supabase gemockt, erfundene Daten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { SlotsCoaches, Stammschicht } from '@/types/slotplan'
import type { Geladen } from '../useSlotsLaden'

const sp = vi.hoisted(() => ({ stammschichtBlockAnlegen: vi.fn(), stammschichtRaumWechseln: vi.fn(), stammschichtBeenden: vi.fn() }))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { CoachesReiter } = await import('./CoachesReiter')
const { naechsterMontag } = await import('./coaches.model')

const ZEITEN = [
  { id: 'z14', beginn: '14:00', ende: '15:00' },
  { id: 'z15', beginn: '15:00', ende: '16:00' },
  { id: 'z16', beginn: '16:00', ende: '17:00' },
  { id: 'z17', beginn: '17:00', ende: '18:00' },
]
const s = (id: string, wochentag: number, zeit: string, raum: string, kinder = 0): Stammschicht => ({
  id, wochentag, zeit_id: zeit, beginn: ZEITEN.find((z) => z.id === zeit)!.beginn, raum_id: `r${raum}`, raum_name: raum,
  gueltig_ab: '2026-09-01', gueltig_bis: null, kinder,
})

// Woche ab Montag, 2. November 2026. Sara: Do 16–18 in B1 (3 + 2 Stammplätze). Jonas: Do 17–18 in A1.
const DATEN: SlotsCoaches = {
  montag: '2026-11-02', kw: 45,
  coaches: [
    { id: 'c1', name: 'Sara Kühn', stunden_pro_woche: 2, abweichungen: [], stammschichten: [s('s16', 4, 'z16', 'B1', 3), s('s17', 4, 'z17', 'B1', 2)] },
    { id: 'c2', name: 'Jonas Brandt', stunden_pro_woche: 1, abweichungen: [], stammschichten: [s('j17', 4, 'z17', 'A1', 1)] },
  ],
  raeume: [{ id: 'rA1', name: 'A1' }, { id: 'rB1', name: 'B1' }, { id: 'rC1', name: 'C1' }],
  zeiten: ZEITEN,
}

let neuLaden = vi.fn()
function zeige(daten: SlotsCoaches = DATEN): void {
  neuLaden = vi.fn()
  const geladen: Geladen<SlotsCoaches> = { daten, laedt: false, fehler: null, neuLaden }
  render(<MemoryRouter><CoachesReiter coaches={geladen} montag={daten.montag} onWoche={vi.fn()} /></MemoryRouter>)
}

const feld = (name: string): HTMLSelectElement => screen.getByLabelText(name) as HTMLSelectElement
const dialog = (): HTMLElement => screen.getByRole('dialog')

beforeEach(() => {
  for (const f of Object.values(sp)) f.mockReset()
})

describe('Reiter Coaches · Blöcke', () => {
  it('zeigt je Coach eine Karte mit dem Block „Do 16:00–18:00“, Raum und Stammplätzen', () => {
    zeige()
    const block = screen.getByRole('listitem', { name: 'Sara Kühn, Do 16:00–18:00, Raum B1' })
    expect(within(block).getByText('Do 16:00–18:00')).toBeTruthy()
    expect(within(block).getByText('Raum B1')).toBeTruthy()
    expect(within(block).getByText('5 Kinder mit Stammplatz')).toBeTruthy()
    expect(screen.getByText('2 Std. pro Woche')).toBeTruthy()
  })
})

describe('Schicht eintragen', () => {
  it('ruft stammschicht_block_anlegen mit Coach, Wochentag, von, bis und Raum', async () => {
    sp.stammschichtBlockAnlegen.mockResolvedValue({ data: { stammschicht_ids: ['n1', 'n2'], stunden: 2 }, error: null })
    zeige()
    fireEvent.change(feld('Coach'), { target: { value: 'c2' } })
    fireEvent.change(feld('Wochentag'), { target: { value: '2' } })
    fireEvent.change(feld('Raum'), { target: { value: 'rC1' } })
    fireEvent.change(feld('von'), { target: { value: 'z15' } })
    fireEvent.change(feld('bis'), { target: { value: 'z16' } })
    fireEvent.click(screen.getByRole('button', { name: 'Schicht eintragen' }))
    await waitFor(() => expect(screen.getByText('Schicht eingetragen: Jonas Brandt, Di 15:00–17:00, Raum C1.')).toBeTruthy())
    expect(sp.stammschichtBlockAnlegen).toHaveBeenCalledWith('c2', 2, 'z15', 'z16', 'rC1', null)
    expect(neuLaden).toHaveBeenCalled()
  })

  it('„bis“ vor „von“: gesperrt mit Grund', () => {
    zeige()
    fireEvent.change(feld('von'), { target: { value: 'z17' } })
    fireEvent.change(feld('bis'), { target: { value: 'z14' } })
    const knopf = screen.getByRole('button', { name: 'Schicht eintragen' }) as HTMLButtonElement
    expect(knopf.disabled).toBe(true)
    expect(knopf.title).toBe('„bis“ liegt vor „von“.')
  })

  it('Konflikt als Satz mit Uhrzeit: Raum besetzt (mit Coach) und Coach schon in einem anderen Raum', async () => {
    sp.stammschichtBlockAnlegen.mockResolvedValue({ data: null, error: 'x', code: 'SL009', hint: 'raum:16:00' })
    zeige()
    fireEvent.change(feld('Coach'), { target: { value: 'c2' } })
    fireEvent.change(feld('Wochentag'), { target: { value: '4' } })
    fireEvent.change(feld('Raum'), { target: { value: 'rB1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Schicht eintragen' }))
    expect((await screen.findByRole('alert')).textContent).toBe('Raum B1 ist Do 16:00 schon mit Sara Kühn besetzt.')

    sp.stammschichtBlockAnlegen.mockResolvedValue({ data: null, error: 'x', code: 'SL009', hint: 'coach:17:00' })
    fireEvent.change(feld('Raum'), { target: { value: 'rC1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Schicht eintragen' }))
    await waitFor(() => expect(screen.getByRole('alert').textContent).toBe('Jonas Brandt ist Do 17:00 schon in Raum A1.'))
  })

  it('andere Fehler als Satz aus fehler.*, nie Rohtext', async () => {
    sp.stammschichtBlockAnlegen.mockResolvedValue({ data: null, error: 'roh', code: 'SL007', hint: null })
    zeige()
    fireEvent.click(screen.getByRole('button', { name: 'Schicht eintragen' }))
    expect((await screen.findByRole('alert')).textContent).toBe('Das Datum liegt in der Vergangenheit.')
  })
})

describe('Raum ändern', () => {
  const oeffne = (): void => {
    fireEvent.click(screen.getByRole('button', { name: 'Raum ändern: Sara Kühn, Do 16:00–18:00, Raum B1' }))
  }

  it('ohne Kinder: Satz „Kinder hängen am Raum …“, Kästchen aus, Standard nächster Montag', async () => {
    sp.stammschichtRaumWechseln.mockResolvedValue({ data: { stammschicht_ids: ['n1', 'n2'], stammplatz_ids: [], kinder: 0 }, error: null })
    zeige()
    oeffne()
    expect(within(dialog()).getByText('Kinder hängen am Raum, nicht am Coach. Ohne Häkchen bleiben die 5 Kinder in Raum B1.')).toBeTruthy()
    fireEvent.change(within(dialog()).getByLabelText('Neuer Raum'), { target: { value: 'rC1' } })
    const kaestchen = within(dialog()).getByLabelText('5 Kinder mit in Raum C1 nehmen') as HTMLInputElement
    expect(kaestchen.checked).toBe(false)
    expect((within(dialog()).getByLabelText('gültig ab') as HTMLInputElement).value).toBe(naechsterMontag())
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Raum ändern' }))
    await waitFor(() => expect(sp.stammschichtRaumWechseln).toHaveBeenCalledWith(['s16', 's17'], 'rC1', naechsterMontag(), false))
    expect(await screen.findByText(/Sara Kühn ist ab .* in Raum C1\. Die Kinder bleiben in Raum B1\./)).toBeTruthy()
  })

  it('mit Kindern: Häkchen gesetzt → mitKindern true', async () => {
    sp.stammschichtRaumWechseln.mockResolvedValue({ data: { stammschicht_ids: ['n1', 'n2'], stammplatz_ids: ['p1'], kinder: 5 }, error: null })
    zeige()
    oeffne()
    fireEvent.change(within(dialog()).getByLabelText('Neuer Raum'), { target: { value: 'rC1' } })
    fireEvent.change(within(dialog()).getByLabelText('gültig ab'), { target: { value: '2026-12-07' } })
    fireEvent.click(within(dialog()).getByLabelText('5 Kinder mit in Raum C1 nehmen'))
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Raum ändern' }))
    await waitFor(() => expect(sp.stammschichtRaumWechseln).toHaveBeenCalledWith(['s16', 's17'], 'rC1', '2026-12-07', true))
    expect(await screen.findByText('Sara Kühn ist ab 07.12.2026 in Raum C1, 5 Kinder ziehen mit.')).toBeTruthy()
  })

  it('Zielraum zu einer der Zeiten besetzt: gesperrt mit Grund, kein Aufruf', () => {
    zeige()
    oeffne()
    // Erster anderer Raum ist A1; dort ist Jonas Do 17:00.
    expect((within(dialog()).getByLabelText('Neuer Raum') as HTMLSelectElement).value).toBe('rA1')
    expect(within(dialog()).getByRole('alert').textContent).toBe('Raum A1 ist dann schon besetzt: Do 17:00 Jonas Brandt.')
    const knopf = within(dialog()).getByRole('button', { name: 'Raum ändern' }) as HTMLButtonElement
    expect(knopf.disabled).toBe(true)
    expect(knopf.title).toBe('Erst die Schicht im Zielraum klären.')
    fireEvent.click(knopf)
    expect(sp.stammschichtRaumWechseln).not.toHaveBeenCalled()
  })

  it('Fehler mit Uhrzeit aus dem Server als Satz', async () => {
    sp.stammschichtRaumWechseln.mockResolvedValue({ data: null, error: 'x', code: 'SL001', hint: 'raum:16:00' })
    zeige()
    oeffne()
    fireEvent.change(within(dialog()).getByLabelText('Neuer Raum'), { target: { value: 'rC1' } })
    fireEvent.click(within(dialog()).getByLabelText('5 Kinder mit in Raum C1 nehmen'))
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Raum ändern' }))
    expect((await within(dialog()).findByRole('alert')).textContent).toBe('Mit den Kindern säßen in Raum C1 Do 16:00 mehr als fünf Kinder.')
  })
})

describe('Entfernen', () => {
  const oeffne = (): void => {
    fireEvent.click(screen.getByRole('button', { name: 'Entfernen: Sara Kühn, Do 16:00–18:00, Raum B1' }))
  }

  it('Bestätigung im Dialog mit Satz; beendet jede Stunde ab dem gewählten Datum', async () => {
    sp.stammschichtBeenden.mockResolvedValue({ data: null, error: null })
    zeige()
    oeffne()
    expect(within(dialog()).getByText('Raum B1 hat zu diesen Zeiten dann keinen Coach. Kinder mit Stammplatz dort bleiben eingeplant und erscheinen im Wochenplan als „kein Coach“.')).toBeTruthy()
    expect(sp.stammschichtBeenden).not.toHaveBeenCalled()
    fireEvent.change(within(dialog()).getByLabelText('entfernen ab'), { target: { value: '2026-11-16' } })
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Entfernen' }))
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
    expect(sp.stammschichtBeenden.mock.calls).toEqual([['s16', '2026-11-16'], ['s17', '2026-11-16']])
    expect(screen.getByText('Schicht entfernt: Sara Kühn, Do 16:00–18:00, Raum B1, ab 16.11.2026.')).toBeTruthy()
    expect(neuLaden).toHaveBeenCalled()
  })

  it('Abbrechen ruft nichts auf', () => {
    zeige()
    oeffne()
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Abbrechen' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(sp.stammschichtBeenden).not.toHaveBeenCalled()
  })

  it('scheitert eine Stunde: Fehler im Dialog und neu laden', async () => {
    sp.stammschichtBeenden.mockResolvedValueOnce({ data: null, error: null })
      .mockResolvedValueOnce({ data: null, error: 'x', code: 'SL007', hint: null })
    zeige()
    oeffne()
    await act(async () => { fireEvent.click(within(dialog()).getByRole('button', { name: 'Entfernen' })) })
    expect(within(dialog()).getByRole('alert').textContent)
      .toBe('Nicht alle Stunden wurden entfernt (1 von 2). Das Datum liegt in der Vergangenheit. Die Schichten sind neu geladen.')
    expect(neuLaden).toHaveBeenCalled()
  })
})

describe('Block, der vor dem Standarddatum endet', () => {
  const ENDET: SlotsCoaches = {
    ...DATEN,
    coaches: [{ ...DATEN.coaches[0], stammschichten: [{ ...s('e1', 4, 'z16', 'B1', 2), gueltig_bis: '2026-11-05' }] }],
  }

  it('bietet weder „Raum ändern“ noch „Entfernen“ an, sondern sagt, dass er ausläuft', () => {
    // Heute Mittwoch 4.11.: nächster Montag ist der 9.11., die Schicht endet am 5.11.
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-11-04T10:00:00Z'))
    zeige(ENDET)
    vi.useRealTimers()
    const block = screen.getByRole('listitem', { name: 'Sara Kühn, Do 16:00–17:00, Raum B1' })
    expect(within(block).getByText('läuft aus, nichts mehr zu ändern')).toBeTruthy()
    expect(within(block).queryByRole('button')).toBeNull()
  })

  it('Entfernen und Raum ändern mit Datum nach dem Ende: gesperrt mit Satz, kein Aufruf, kein Erfolg', () => {
    zeige({ ...DATEN, coaches: [{ ...DATEN.coaches[0], stammschichten: [{ ...s('e1', 4, 'z16', 'B1', 2), gueltig_bis: '2099-12-31' }] }] })
    fireEvent.click(screen.getByRole('button', { name: 'Entfernen: Sara Kühn, Do 16:00–17:00, Raum B1' }))
    fireEvent.change(within(dialog()).getByLabelText('entfernen ab'), { target: { value: '2100-01-04' } })
    const weg = within(dialog()).getByRole('button', { name: 'Entfernen' }) as HTMLButtonElement
    expect(weg.disabled).toBe(true)
    expect(within(dialog()).getByText('Die Schicht endet am 31.12.2099. Wähle ein Datum bis dahin.')).toBeTruthy()
    fireEvent.click(weg)
    expect(sp.stammschichtBeenden).not.toHaveBeenCalled()
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Abbrechen' }))

    fireEvent.click(screen.getByRole('button', { name: 'Raum ändern: Sara Kühn, Do 16:00–17:00, Raum B1' }))
    fireEvent.change(within(dialog()).getByLabelText('Neuer Raum'), { target: { value: 'rC1' } })
    fireEvent.change(within(dialog()).getByLabelText('gültig ab'), { target: { value: '2100-01-04' } })
    expect((within(dialog()).getByRole('button', { name: 'Raum ändern' }) as HTMLButtonElement).disabled).toBe(true)
    expect(sp.stammschichtRaumWechseln).not.toHaveBeenCalled()
  })
})
