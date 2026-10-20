// Slots W3, Entscheidungen 3–6: Stammplatz-Dialog mit Raum-Karten (gesperrt bei voll und ohne Coach, mit Grund),
// „Die nächsten Termine“ mit jedem Grund als Satz, A/B-Hinweis mit der KW des ersten Termins, Speichern mit raum_id
// (vergeben und ändern; beim Ändern geht `ersetzt` an die Vorschau). Erfundene Daten, Wrapper gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import '@/i18n'
import type { Stammplatz, StammplatzVorschauZeile } from '@/types/slotplan'

const sp = vi.hoisted(() => ({
  ladeEinstellungen: vi.fn(),
  ladeStammplatzVorschau: vi.fn(),
  ladePlanbilanzVorschau: vi.fn(),
  stammplatzVergeben: vi.fn(),
  stammplatzAendern: vi.fn(),
}))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { StammplatzDialog, abStandard } = await import('./StammplatzDialog')

// 2030-11-04 ist ein Montag in KW 45 (A-Woche); das Kind beginnt dort, damit „gültig ab“ nicht vom heutigen Tag abhängt.
const kindStamm = { student_id: 'k1', name: 'Jonas Köhler', beginn: '2030-11-04', vertrag_laeuft: false, rhythmus: { woechentlich: 1, vierzehntaeglich: 0 } }
const RAEUME = [
  { id: 'r-a1', name: 'A1', aktiv_ab: '2026-01-01', inaktiv_ab: null, stammschichten: 4 },
  { id: 'r-b1', name: 'B1', aktiv_ab: '2026-01-01', inaktiv_ab: null, stammschichten: 4 },
  { id: 'r-c1', name: 'C1', aktiv_ab: '2026-01-01', inaktiv_ab: null, stammschichten: 0 },
  { id: 'r-alt', name: 'Alt', aktiv_ab: '2026-01-01', inaktiv_ab: '2027-01-01', stammschichten: 0 },
]
const ZEITEN = [{ id: 'z16', beginn: '16:00', ende: '17:00', aktiv_ab: '2026-01-01', inaktiv_ab: null }]

const zeile = (datum: string, ergebnis: StammplatzVorschauZeile['ergebnis'], teil: Partial<StammplatzVorschauZeile> = {}): StammplatzVorschauZeile => ({
  datum, ergebnis, anlass: null, belegt: null, coach_id: null, coach_name: null, ...teil,
})
const jana = { coach_id: 'c1', coach_name: 'Jana Berg' }
const VORSCHAU: Record<string, StammplatzVorschauZeile[]> = {
  'r-a1': [
    zeile('2030-11-05', 'termin', { belegt: 2, ...jana }),
    zeile('2030-11-12', 'ferien', { anlass: 'Herbstferien' }),
    zeile('2030-11-19', 'feiertag', { anlass: 'Buß- und Bettag' }),
    zeile('2030-11-26', 'voll', { belegt: 5, ...jana }),
    zeile('2030-12-03', 'ohne_coach', { belegt: 1 }),
    zeile('2030-12-10', 'ohne_budget', { belegt: 3, ...jana }),
  ],
  'r-b1': [zeile('2030-11-05', 'voll', { belegt: 5, coach_id: 'c2', coach_name: 'Timo Rau' })],
  'r-c1': [zeile('2030-11-05', 'ohne_coach', { belegt: 0 })],
}

beforeEach(() => {
  Object.values(sp).forEach((f) => f.mockReset())
  sp.ladeEinstellungen.mockResolvedValue({
    data: { heute: '2026-10-20', schuljahr_bis: '2031-07-31', planungsgrenze: '2031-07-31', raeume: RAEUME, zeiten: ZEITEN, ferien: [], feiertage: [] },
    error: null,
  })
  sp.ladeStammplatzVorschau.mockImplementation((_s: string, _w: number, _z: string, raumId: string) =>
    Promise.resolve({ data: VORSCHAU[raumId] ?? [], error: null }))
  sp.ladePlanbilanzVorschau.mockResolvedValue({ data: { planbilanz: null, terminzahl: null, letzter_termin: null, uebersprungen: [], gruende: [] }, error: null })
  sp.stammplatzVergeben.mockResolvedValue({ data: { stammplatz_ids: ['s9'], planbilanz: null }, error: null })
  sp.stammplatzAendern.mockResolvedValue({ data: { stammplatz_id: 's9', planbilanz: null }, error: null })
})

async function waehleSlot(wochentag = '2'): Promise<void> {
  fireEvent.change(await screen.findByLabelText('Wochentag'), { target: { value: wochentag } })
  fireEvent.change(screen.getByLabelText('Uhrzeit'), { target: { value: 'z16' } })
  await screen.findByRole('group', { name: 'Raum' })
}
const raum = (name: string): HTMLButtonElement =>
  within(screen.getByRole('group', { name: 'Raum' })).getAllByRole('button').find((b) => b.textContent?.startsWith(name)) as HTMLButtonElement

describe('Raum-Karten (W3, Entscheidung 3)', () => {
  it('je aktivem Raum Coach und freie Plätze am ersten Termin; voll und ohne Coach gesperrt mit Grund', async () => {
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    expect(within(screen.getByRole('group', { name: 'Raum' })).getAllByRole('button')).toHaveLength(3)
    expect(sp.ladeStammplatzVorschau).toHaveBeenCalledWith('k1', 2, 'z16', 'r-a1', 'woechentlich', '2030-11-04', null)

    expect(raum('A1').disabled).toBe(false)
    expect(raum('A1').textContent).toContain('Jana Berg')
    expect(raum('A1').textContent).toContain('3 von 5 frei am Di 05.11.')

    expect(raum('B1').disabled).toBe(true)
    expect(raum('B1').textContent).toContain('B1 ist am Di 05.11. voll (5 von 5). Anderen Raum oder andere Uhrzeit wählen.')

    expect(raum('C1').disabled).toBe(true)
    expect(raum('C1').textContent).toContain('kein Coach eingeteilt')
    expect(raum('C1').textContent).toContain('C1 hat am Di 05.11. um 16:00 keinen Coach.')
    expect(raum('C1').title).toContain('keinen Coach')
  })
})

describe('Die nächsten Termine (W3, Entscheidung 5)', () => {
  it('zeigt jedes Ergebnis mit Kennzeichen und Grund als Satz', async () => {
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    fireEvent.click(raum('A1'))
    const liste = await screen.findByRole('list', { name: 'Die nächsten Termine' })
    const zeilen = within(liste).getAllByRole('listitem').map((li) => li.textContent)
    expect(zeilen).toEqual([
      'Di 05.11.geplantTermin in A1 bei Jana Berg, dann 3 von 5 Plätzen belegt.',
      'Di 12.11.kein BetriebKein Betrieb: Herbstferien.',
      'Di 19.11.kein BetriebKein Betrieb, Feiertag: Buß- und Bettag.',
      'Di 26.11.entfälltA1 ist an diesem Tag voll (5 von 5), kein Termin.',
      'Di 03.12.entfälltA1 hat an diesem Tag keinen Coach, kein Termin.',
      'Di 10.12.entfälltKeine Einheit mehr frei, kein Termin.',
    ])
  })

  it('andere Woche und kein Platz (voll mit weniger als fünf: Termin voll oder andere Art)', async () => {
    sp.ladeStammplatzVorschau.mockResolvedValue({
      data: [zeile('2030-11-05', 'termin', { belegt: 0, ...jana }), zeile('2030-11-12', 'andere_woche'), zeile('2030-11-19', 'voll', { belegt: 2, ...jana })],
      error: null,
    })
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    fireEvent.change(screen.getByLabelText('Takt'), { target: { value: 'a_woche' } })
    await screen.findByRole('group', { name: 'Raum' })
    fireEvent.click(raum('A1'))
    const liste = await screen.findByRole('list', { name: 'Die nächsten Termine' })
    expect(within(liste).getAllByRole('listitem').map((li) => li.textContent).slice(1)).toEqual([
      'Di 12.11.andere WocheB-Woche (KW 46): Der Stammplatz gilt in der A-Woche, hier kein Termin.',
      'Di 19.11.entfälltA1: an diesem Tag ist in diesem Termin kein Platz mehr frei, kein Termin.',
    ])
  })
})

describe('A/B-Hinweis (W3, Entscheidung 4)', () => {
  it('nennt die KW des ersten Termins: A-Woche KW 45, B-Woche KW 46', async () => {
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    expect(screen.queryByRole('note')).toBeNull()
    fireEvent.change(screen.getByLabelText('Takt'), { target: { value: 'a_woche' } })
    expect(screen.getByRole('note').textContent).toBe('A-Woche = ungerade KW, B-Woche = gerade. KW 45 ist eine A-Woche.')
    fireEvent.change(screen.getByLabelText('Takt'), { target: { value: 'b_woche' } })
    expect(screen.getByRole('note').textContent).toBe('A-Woche = ungerade KW, B-Woche = gerade. KW 46 ist eine B-Woche.')
  })
})

describe('Speichern (W3, Entscheidung 6)', () => {
  it('vergeben übergibt raum_id; ohne Raum ist Speichern gesperrt mit Grund', async () => {
    const gespeichert = vi.fn()
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={gespeichert} />)
    await waehleSlot()
    const speichern = screen.getByRole('button', { name: 'Speichern' }) as HTMLButtonElement
    expect(speichern.disabled).toBe(true)
    expect(within(screen.getByRole('list', { name: 'Warum Speichern noch nicht geht' })).getByText('Einen Raum wählen.')).toBeTruthy()

    fireEvent.click(raum('A1'))
    const erwartet = [{ wochentag: 2, slot_zeit_id: 'z16', takt: 'woechentlich', raum_id: 'r-a1' }]
    await waitFor(() => expect(sp.ladePlanbilanzVorschau).toHaveBeenCalledWith('k1', erwartet, '2030-11-04', null))
    await waitFor(() => expect(speichern.disabled).toBe(false))
    await act(async () => fireEvent.click(speichern))
    expect(sp.stammplatzVergeben).toHaveBeenCalledWith('k1', erwartet, '2030-11-04')
    expect(gespeichert).toHaveBeenCalled()
  })

  it('ändern übergibt raum_id und ersetzt an die Vorschau', async () => {
    const alt: Stammplatz = {
      id: 's1', wochentag: 2, zeit_id: 'z16', beginn: '16:00', takt: 'woechentlich', gueltig_ab: '2026-09-01', gueltig_bis: null,
      vorgaenger_id: null, raum_id: null, raum_name: null, coach_id: null, coach_name: null,
    }
    render(<StammplatzDialog kind={kindStamm} aendern={alt} onClose={() => undefined} onGespeichert={() => undefined} />)
    expect(screen.getByRole('dialog', { name: 'Raum festlegen' })).toBeTruthy()
    fireEvent.change(await screen.findByLabelText('Gültig ab'), { target: { value: '2030-11-04' } })
    await screen.findByRole('group', { name: 'Raum' })
    await waitFor(() => expect(sp.ladeStammplatzVorschau).toHaveBeenCalledWith('k1', 2, 'z16', 'r-a1', 'woechentlich', '2030-11-04', ['s1']))
    fireEvent.click(await waitFor(() => {
      const b = raum('A1')
      expect(b.disabled).toBe(false)
      return b
    }))
    const speichern = screen.getByRole('button', { name: 'Speichern' }) as HTMLButtonElement
    await waitFor(() => expect(speichern.disabled).toBe(false))
    await act(async () => fireEvent.click(speichern))
    expect(sp.stammplatzAendern).toHaveBeenCalledWith('s1', '2030-11-04', { wochentag: 2, slot_zeit_id: 'z16', takt: 'woechentlich', raum_id: 'r-a1' })
  })

  it('ein Fehler beim Speichern erscheint als Satz (raum_fehlt)', async () => {
    sp.stammplatzVergeben.mockResolvedValue({ data: null, error: 'stammplatz_vergeben: …', code: '22023', hint: 'raum_fehlt' })
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    fireEvent.click(raum('A1'))
    const speichern = screen.getByRole('button', { name: 'Speichern' }) as HTMLButtonElement
    await waitFor(() => expect(speichern.disabled).toBe(false))
    await act(async () => fireEvent.click(speichern))
    expect(screen.getByRole('alert').textContent).toBe('Wähle einen Raum für den Stammplatz.')
  })
})

describe('Zweitprüfung W3', () => {
  it('der Sperrsatz nennt den ersten Termin im Takt, wie die Karte (nicht ein Datum der anderen Woche)', async () => {
    const tage = ['2030-11-05', '2030-11-12', '2030-11-19']
    sp.ladeStammplatzVorschau.mockImplementation((_s: string, _w: number, _z: string, raumId: string) => Promise.resolve({
      data: raumId === 'r-a1' ? tage.map((d) => zeile(d, 'termin', { belegt: 1, ...jana })) : tage.map((d) => zeile(d, 'ohne_coach', { belegt: 0 })),
      error: null,
    }))
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    fireEvent.change(screen.getByLabelText('Takt'), { target: { value: 'b_woche' } })
    await screen.findByRole('group', { name: 'Raum' })
    expect(raum('A1').textContent).toContain('4 von 5 frei am Di 12.11.')
    expect(raum('C1').textContent).toContain('C1 hat am Di 12.11. um 16:00 keinen Coach.')
    expect(raum('C1').textContent).not.toContain('05.11.')
  })

  it('„voll“ mit weniger als fünf Kindern heißt auf der Karte nicht „5 von 5“', async () => {
    sp.ladeStammplatzVorschau.mockImplementation((_s: string, _w: number, _z: string, raumId: string) => Promise.resolve({
      data: raumId === 'r-b1' ? [zeile('2030-11-05', 'voll', { belegt: 3, ...jana })] : VORSCHAU[raumId], error: null,
    }))
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    expect(raum('B1').disabled).toBe(true)
    expect(raum('B1').textContent).toContain('B1: am Di 05.11. ist in diesem Termin kein Platz mehr frei.')
    expect(raum('B1').textContent).not.toContain('5 von 5')
  })

  it('ohne Termin in sechs Wochen: Satz statt „kein Coach eingeteilt“', async () => {
    sp.ladeStammplatzVorschau.mockResolvedValue({
      data: ['2030-11-05', '2030-11-12'].map((d) => zeile(d, 'ferien', { anlass: 'Herbstferien' })), error: null,
    })
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    expect(raum('A1').textContent).toContain('In den nächsten sechs Wochen kein Termin.')
    expect(raum('A1').textContent).not.toContain('kein Coach eingeteilt')
    expect(raum('A1').disabled).toBe(false)
  })

  it('scheitert die Vorschau eines Raums, ist seine Karte gesperrt mit Satz; beim nächsten Laden wieder offen', async () => {
    let kaputt = true
    sp.ladeStammplatzVorschau.mockImplementation((_s: string, _w: number, _z: string, raumId: string) => Promise.resolve(
      raumId === 'r-a1' && kaputt ? { data: null, error: 'x', code: '42501' } : { data: VORSCHAU[raumId], error: null },
    ))
    render(<StammplatzDialog kind={kindStamm} onClose={() => undefined} onGespeichert={() => undefined} />)
    await waehleSlot()
    expect(raum('A1').disabled).toBe(true)
    expect(raum('A1').textContent).toContain('A1: Die Vorschau konnte nicht geladen werden. Dafür fehlen dir die Rechte.')
    kaputt = false
    fireEvent.change(screen.getByLabelText('Takt'), { target: { value: 'a_woche' } })
    await waitFor(() => expect(raum('A1').disabled).toBe(false))
  })

  it('gültig ab beim Ändern: der spätere von nächstem Montag, Beginn des Stammplatzes und Vertragsbeginn', () => {
    expect(abStandard({ beginn: '2020-01-01' }, '2020-01-01', { gueltig_ab: '2099-03-02' })).toBe('2099-03-02')
    expect(abStandard({ beginn: '2099-05-04' }, '2020-01-01', { gueltig_ab: '2020-01-01' })).toBe('2099-05-04')
    const montag = abStandard({ beginn: '2020-01-01' }, '2020-01-01', { gueltig_ab: '2020-01-01' })
    expect(new Date(`${montag}T00:00:00Z`).getUTCDay()).toBe(1)
    expect(abStandard({ beginn: '2030-11-04' }, '2026-10-20')).toBe('2030-11-04')
  })
})
