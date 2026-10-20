// Slots W2, Entscheidung 7: Dialog „Kind in <Raum>“. „Nur an diesem Termin“ bucht einen Zusatztermin in genau diesem
// Raum, „Jede Woche“ vergibt einen Stammplatz an Wochentag, Uhrzeit und Raum ab dem Termindatum. Nicht buchbare
// Kinder stehen ausgegraut mit ihrem Satz da, nie mit dem Rohcode. Supabase gemockt, erfundene Daten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import '@/i18n'
import type { KandidatCode, SlotsKandidatAlle, SlotsTermin, TerminRaum } from '@/types/slotplan'

const sp = vi.hoisted(() => ({ ladeKandidatenAlle: vi.fn(), zusatzterminBuchen: vi.fn(), stammplatzVergeben: vi.fn() }))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { KindInRaumDialog } = await import('./KindInRaumDialog')

const RAUM: TerminRaum = {
  raum_id: 'rB1', name: 'B1', offen: true, art: 'stamm', coach_id: 'c1', coach_name: 'Jonas Brandt', stamm_coach_id: 'c1',
  stamm_coach_name: 'Jonas Brandt', vertretung: false, gemischt: false, session_id: null, gestartet: false, kinder: [],
}
// Montag, 2. November 2026, 15:00
const TERMIN = {
  datum: '2026-11-02', kw: 45, zeit: { id: 'z15', beginn: '15:00', ende: '16:00' }, raeume: [RAUM],
} as unknown as SlotsTermin

const kandidat = (id: string, name: string, code: KandidatCode | null, teil: Partial<SlotsKandidatAlle> = {}): SlotsKandidatAlle => ({
  student_id: id, name, klasse: 9, fach: 'Mathematik', ist_test: false, stammplatz_kurz: null, stammplaetze: [], code, datum: null, ...teil,
})

async function zeige(liste: SlotsKandidatAlle[], onGespeichert = vi.fn()): Promise<void> {
  sp.ladeKandidatenAlle.mockResolvedValue({ data: liste, error: null })
  render(<KindInRaumDialog termin={TERMIN} raum={RAUM} onClose={vi.fn()} onGespeichert={onGespeichert} />)
  await act(async () => {})
}

const zeile = (name: string): HTMLElement => screen.getByText(name).closest('button') as HTMLElement

beforeEach(() => {
  for (const f of Object.values(sp)) f.mockReset()
})

describe('Kind in <Raum>', () => {
  it('lädt die Kandidaten für Datum, Uhrzeit und genau diesen Raum; Kopf mit Coach und Belegung', async () => {
    await zeige([kandidat('k1', 'Mia Ritter', null)])
    expect(sp.ladeKandidatenAlle).toHaveBeenCalledWith('2026-11-02', 'z15', 'rB1')
    expect(screen.getByRole('dialog', { name: 'Kind in B1' })).toBeTruthy()
    expect(screen.getByText('Montag, 2. November · 15:00 · Jonas Brandt · 0 von 5 belegt')).toBeTruthy()
  })

  it('„Nur an diesem Termin“: zusatztermin_buchen mit dem Raum', async () => {
    sp.zusatzterminBuchen.mockResolvedValue({ data: { termin_id: 't1', verdraengt: [] }, error: null })
    const onGespeichert = vi.fn()
    await zeige([kandidat('k1', 'Mia Ritter', null)], onGespeichert)
    fireEvent.click(zeile('Mia Ritter'))
    fireEvent.click(screen.getByRole('button', { name: 'Hinzufügen' }))
    await waitFor(() => expect(onGespeichert).toHaveBeenCalledWith('Mia Ritter ist an diesem Termin in B1.'))
    expect(sp.zusatzterminBuchen).toHaveBeenCalledWith('k1', '2026-11-02', 'z15', 'rB1')
    expect(sp.stammplatzVergeben).not.toHaveBeenCalled()
  })

  it('„Jede Woche“: stammplatz_vergeben mit einer Zeile (Montag, Uhrzeit, Raum, wöchentlich) ab dem Termindatum', async () => {
    sp.stammplatzVergeben.mockResolvedValue({ data: { stammplatz_ids: ['s1'], planbilanz: null }, error: null })
    const onGespeichert = vi.fn()
    await zeige([kandidat('k1', 'Mia Ritter', null)], onGespeichert)
    fireEvent.click(screen.getByRole('button', { name: 'Jede Woche (Stammplatz)' }))
    expect(screen.getByText(/Stammplatz Montag 15:00 in B1, gültig ab 02\.11\.2026\./)).toBeTruthy()
    fireEvent.click(zeile('Mia Ritter'))
    fireEvent.click(screen.getByRole('button', { name: 'Stammplatz vergeben' }))
    await waitFor(() => expect(onGespeichert).toHaveBeenCalledWith('Mia Ritter hat jetzt einen Stammplatz in B1.'))
    expect(sp.stammplatzVergeben).toHaveBeenCalledWith(
      'k1', [{ wochentag: 1, slot_zeit_id: 'z15', takt: 'woechentlich', raum_id: 'rB1' }], '2026-11-02',
    )
    expect(sp.zusatzterminBuchen).not.toHaveBeenCalled()
  })

  const FAELLE: [KandidatCode, string | null, string][] = [
    ['kein_vertrag', null, 'Kein Vertrag'],
    ['vertrag_ab', '2026-12-01', 'Vertrag beginnt am 01.12.2026'],
    ['SL001', null, 'Raum ist voll'],
    ['SL002', null, 'Raum hat zu der Zeit keinen Coach'],
    ['SL003', null, 'Hat an dem Tag schon einen Termin'],
    ['SL005', null, 'Keine offene Einheit mehr'],
    ['SL013', null, 'Testkind und echtes Kind nicht im selben Termin'],
    ['SL010', null, 'Die Absage lässt sich nicht mehr zurücknehmen: Der Platz ist vergeben oder der Termin hat begonnen.'],
  ]
  it.each(FAELLE)('%s: ausgegraut, nicht wählbar, Satz statt Code', async (code, datum, satz) => {
    await zeige([kandidat('k1', 'Kim Grund', code, { datum }), kandidat('k2', 'Anna Frei', null)])
    const knopf = zeile('Kim Grund') as HTMLButtonElement
    expect(knopf.disabled).toBe(true)
    expect(within(knopf).getByText(satz)).toBeTruthy()
    expect(within(knopf).queryByText(code)).toBeNull()
    // Buchbare stehen oben.
    const namen = screen.getAllByRole('button', { pressed: false }).map((b) => b.textContent ?? '')
    expect(namen.findIndex((n) => n.includes('Anna Frei'))).toBeLessThan(namen.findIndex((n) => n.includes('Kim Grund')))
  })

  it('zeigt den Stammplatz buchbarer Kinder, „Test“ und filtert über die Suche', async () => {
    await zeige([
      kandidat('k1', 'Mia Ritter', null, { stammplaetze: [{ wochentag: 3, zeit_id: 'z16', beginn: '16:00', takt: 'a_woche', raum_id: 'rA1', raum_name: 'A1' }] }),
      kandidat('k2', 'ZZ Test Lea', null, { ist_test: true }),
    ])
    expect(within(zeile('Mia Ritter')).getByText('Stammplatz Mi 16:00 · A1 (A-Woche)')).toBeTruthy()
    expect(within(zeile('ZZ Test Lea')).getByText('ohne Stammplatz')).toBeTruthy()
    expect(within(zeile('ZZ Test Lea')).getByText('Test')).toBeTruthy()
    fireEvent.change(screen.getByLabelText('Kind suchen'), { target: { value: 'lea' } })
    expect(screen.queryByText('Mia Ritter')).toBeNull()
  })

  it('Ablehnung der Datenbank als Satz, nie Rohtext', async () => {
    sp.zusatzterminBuchen.mockResolvedValue({ data: null, error: 'roh', code: 'SL001', hint: null })
    await zeige([kandidat('k1', 'Mia Ritter', null)])
    fireEvent.click(zeile('Mia Ritter'))
    fireEvent.click(screen.getByRole('button', { name: 'Hinzufügen' }))
    expect(await screen.findByText('Dieser Termin ist voll.')).toBeTruthy()
    expect(screen.queryByText('roh')).toBeNull()
  })
})
