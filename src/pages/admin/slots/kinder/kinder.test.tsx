// Slots W3, Entscheidungen 1, 2 und 7: Kinderliste mit Raum und Coach je Stammplatz, „keine Schicht“, „Raum: automatisch“
// mit „Raum festlegen“, Filter (Alle · Ohne Stammplatz · Testkonten zeigen, Standard an), ohne Stammplatz oben.
// Erfundene Daten; die Slot-Wrapper sind gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { SlotsKind, SlotsKinderZeile, Stammplatz } from '@/types/slotplan'

const sp = vi.hoisted(() => ({
  ladeKinder: vi.fn(),
  ladeKind: vi.fn(),
  ladeEinstellungen: vi.fn(),
  ladeStammplatzVorschau: vi.fn(),
  ladePlanbilanzVorschau: vi.fn(),
  stammplaetzeWeiterfuehren: vi.fn(),
}))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { KinderReiter } = await import('./KinderReiter')
const { KindPage } = await import('../kind/KindPage')

const stamm = (id: string, teil: Partial<Stammplatz>): Stammplatz => ({
  id, wochentag: 1, zeit_id: 'z14', beginn: '14:00', takt: 'woechentlich', gueltig_ab: '2026-09-01', gueltig_bis: null,
  vorgaenger_id: null, raum_id: 'r-a1', raum_name: 'A1', coach_id: 'c1', coach_name: 'Jana Berg', ...teil,
})

const planbilanz = {
  art: 'passt', einheiten: 40, verbraucht: 4, geplant: 30, ohne_termin: 0, ohne_einheit: 0, terminzahl: 34,
  letzter_termin: '2027-06-28', datum: null, zahl: null, abweichung: null, jenseits_ferientabelle: false, hinweis: null, toleranz: 2,
} as const

const kind = (id: string, name: string, teil: Partial<SlotsKinderZeile> = {}): SlotsKinderZeile => ({
  student_id: id, name, klasse: 7, fach: 'Mathematik', ist_test: false, vertrag_id: `v-${id}`, paket: 'Standard',
  laufzeit_monate: 12, einheiten: 40, beginn: '2026-09-01', stichtag: '2027-08-31', gekuendigt_zum: null,
  rhythmus: { woechentlich: 1, vierzehntaeglich: 0 }, vertrag_laeuft: true, ohne_stammplatz: false, stammplaetze: [],
  verbraucht: 4, geplant: 30, planbilanz, folgevertrag_ab: null, weiterfuehren: null, ...teil,
})

const ohne = { ohne_stammplatz: true, planbilanz: { ...planbilanz, art: 'kein_stammplatz' as const } }
const KINDER: SlotsKinderZeile[] = [
  kind('k1', 'Anna Weber', { stammplaetze: [stamm('s1', { takt: 'a_woche' })] }),
  kind('k2', 'Ben Krause', { stammplaetze: [stamm('s2', { wochentag: 3, beginn: '16:00', raum_id: 'r-b1', raum_name: 'B1', coach_id: null, coach_name: null })] }),
  kind('k3', 'Cem Aydin', { stammplaetze: [stamm('s3', { wochentag: 2, raum_id: null, raum_name: null, coach_id: null, coach_name: null })] }),
  kind('k4', 'Dora Lenz', ohne),
  kind('k5', 'Emil Probe', { ...ohne, ist_test: true }),
]

async function zeige(pfad = '/admin/slots?reiter=kinder'): Promise<void> {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path="/admin/slots" element={<KinderReiter />} />
        <Route path="/admin/slots/kind/:studentId" element={<KindPage />} />
      </Routes>
    </MemoryRouter>,
  )
  await act(async () => {})
}

const namen = (): string[] => within(screen.getByRole('table')).getAllByRole('link').map((a) => a.textContent ?? '')
const zeile = (name: string): HTMLElement => within(screen.getByRole('table')).getByRole('link', { name }).closest('tr') as HTMLElement

beforeEach(() => {
  Object.values(sp).forEach((f) => f.mockReset())
  sp.ladeKinder.mockResolvedValue({ data: KINDER, error: null })
  sp.ladeEinstellungen.mockResolvedValue({ data: { heute: '2026-10-20', schuljahr_bis: '2027-07-31', planungsgrenze: '2027-07-31', raeume: [], zeiten: [], ferien: [], feiertage: [] }, error: null })
  sp.ladePlanbilanzVorschau.mockResolvedValue({ data: null, error: null })
  sp.ladeStammplatzVorschau.mockResolvedValue({ data: [], error: null })
})

describe('Kinderliste (W3, Entscheidung 1)', () => {
  it('zeigt Stammplatz mit Raum und Takt, Coach aus der Schicht und „keine Schicht“', async () => {
    await zeige()
    expect(within(screen.getByRole('table')).getAllByRole('columnheader').map((h) => h.textContent))
      .toEqual(['Kind', 'Paket', 'Stammplatz', 'Coach', 'Planbilanz', 'Aktion'])
    expect(within(zeile('Anna Weber')).getByText('Mo 14:00 · A1 (A-Woche)')).toBeTruthy()
    expect(within(zeile('Anna Weber')).getByText('Jana Berg')).toBeTruthy()
    expect(within(zeile('Anna Weber')).getByRole('button', { name: 'Ändern' })).toBeTruthy()
    expect(within(zeile('Ben Krause')).getByText('Mi 16:00 · B1')).toBeTruthy()
    expect(within(zeile('Ben Krause')).getByText('keine Schicht')).toBeTruthy()
  })

  it('Altbestand ohne Raum: „Raum: automatisch“ und die Aktion „Raum festlegen“ öffnet den Dialog', async () => {
    await zeige()
    const cem = zeile('Cem Aydin')
    expect(within(cem).getByText('Di 14:00 · Raum: automatisch')).toBeTruthy()
    expect(within(cem).queryByText('keine Schicht')).toBeNull()
    await act(async () => fireEvent.click(within(cem).getByRole('button', { name: 'Raum festlegen' })))
    expect(screen.getByRole('dialog', { name: 'Raum festlegen' })).toBeTruthy()
  })

  it('Kinder ohne Stammplatz stehen oben, mit „Stammplatz vergeben“', async () => {
    await zeige()
    expect(namen().slice(0, 2).sort()).toEqual(['Dora Lenz', 'Emil Probe'])
    expect(within(zeile('Dora Lenz')).getByRole('button', { name: 'Stammplatz vergeben' })).toBeTruthy()
  })
})

describe('Filter (W3, Entscheidung 2)', () => {
  it('Ohne Stammplatz zeigt nur Kinder ohne Stammplatz; Testkonten zeigen ist Standard an und blendet sie aus', async () => {
    await zeige()
    const test = screen.getByRole('button', { name: /Testkonten zeigen/ })
    expect(test.getAttribute('aria-pressed')).toBe('true')
    expect(namen()).toHaveLength(5)

    fireEvent.click(screen.getByRole('button', { name: /Ohne Stammplatz/ }))
    expect(namen()).toEqual(['Dora Lenz', 'Emil Probe'])

    fireEvent.click(test)
    expect(screen.getByRole('button', { name: /Testkonten zeigen/ }).getAttribute('aria-pressed')).toBe('false')
    expect(namen()).toEqual(['Dora Lenz'])

    fireEvent.click(screen.getByRole('button', { name: /^Alle/ }))
    expect(namen()).not.toContain('Emil Probe')
    expect(namen()).toHaveLength(4)
  })

  it('der Link aus dem Wochenplan (?filter=kein_stammplatz) öffnet „Ohne Stammplatz“', async () => {
    await zeige('/admin/slots?reiter=kinder&filter=kein_stammplatz')
    expect(screen.getByRole('button', { name: /Ohne Stammplatz/ }).getAttribute('aria-pressed')).toBe('true')
    expect(namen()).toEqual(['Dora Lenz', 'Emil Probe'])
  })
})

describe('Kind-Seite (W3, Entscheidung 7)', () => {
  it('zeigt Raum und Coach je Stammplatz und beim Altbestand „Raum festlegen“', async () => {
    const k: SlotsKind = {
      kind: { student_id: 'k1', name: 'Anna Weber', klasse: 7, fach: 'Mathematik', ist_test: false },
      zugelassen: true,
      vertrag: { vertrag_id: 'v1', paket: 'Standard', laufzeit_monate: 12, einheiten: 40, beginn: '2026-09-01', stichtag: '2027-08-31', gekuendigt_zum: null, rhythmus: { woechentlich: 2, vierzehntaeglich: 0 } },
      vertrag_laeuft: true,
      stammplaetze: [stamm('s1', {}), stamm('s3', { wochentag: 2, raum_id: null, raum_name: null, coach_id: null, coach_name: null }), stamm('s4', { wochentag: 4, raum_name: 'B1', raum_id: 'r-b1', coach_name: null, coach_id: null })],
      fruehere_stammplaetze: [], naechste: [], letzte: [], einheiten: { gesamt: 40, verbraucht: 4, geplant: 30 },
      planbilanz: { ...planbilanz, uebersprungen: [] }, weiterfuehren: null,
    }
    sp.ladeKind.mockResolvedValue({ data: k, error: null })
    await zeige('/admin/slots/kind/k1')
    expect(screen.getByText('Mo 14:00 · A1')).toBeTruthy()
    expect(screen.getByText('Jana Berg')).toBeTruthy()
    expect(screen.getByText('Do 14:00 · B1')).toBeTruthy()
    expect(screen.getByText('keine Schicht')).toBeTruthy()
    expect(screen.getByText('Di 14:00 · Raum: automatisch')).toBeTruthy()
    expect(screen.getAllByRole('button', { name: 'Ändern ab …' })).toHaveLength(2)
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Raum festlegen' })))
    expect(screen.getByRole('dialog', { name: 'Raum festlegen' })).toBeTruthy()
  })
})

describe('Wie bisher weiterführen (W3, Zweitprüfung M3)', () => {
  const folge = (raumId: string | null) => ({
    vertrag_id: 'v2', ab: '2026-11-02',
    zeilen: [{ vorgaenger_id: 'alt1', wochentag: 1, slot_zeit_id: 'z14', takt: 'woechentlich' as const, beginn: '14:00', raum_id: raumId }],
  })

  it('mit Raum: Knopf nennt den Raum', async () => {
    sp.ladeKinder.mockResolvedValue({ data: [kind('k9', 'Ida Roth', { ...ohne, weiterfuehren: folge('r-a1') })], error: null })
    sp.ladeEinstellungen.mockResolvedValue({ data: { heute: '2026-10-20', schuljahr_bis: '2027-07-31', planungsgrenze: '2027-07-31', raeume: [{ id: 'r-a1', name: 'A1', aktiv_ab: '2026-01-01', inaktiv_ab: null, stammschichten: 1 }], zeiten: [], ferien: [], feiertage: [] }, error: null })
    await zeige()
    await act(async () => {})
    expect(within(zeile('Ida Roth')).getByRole('button', { name: 'Wie bisher weiterführen (Mo 14:00 · A1)' })).toBeTruthy()
  })

  it('Vorgänger ohne Raum: kein „wie bisher“, sondern „Stammplatz vergeben“ mit Tag und Uhrzeit vorbelegt', async () => {
    sp.ladeKinder.mockResolvedValue({ data: [kind('k9', 'Ida Roth', { ...ohne, weiterfuehren: folge(null) })], error: null })
    sp.ladeEinstellungen.mockResolvedValue({ data: { heute: '2026-10-20', schuljahr_bis: '2027-07-31', planungsgrenze: '2027-07-31', raeume: [], zeiten: [{ id: 'z14', beginn: '14:00', ende: '15:00', aktiv_ab: '2026-01-01', inaktiv_ab: null }], ferien: [], feiertage: [] }, error: null })
    await zeige()
    const ida = zeile('Ida Roth')
    expect(within(ida).queryByRole('button', { name: /Wie bisher/ })).toBeNull()
    await act(async () => fireEvent.click(within(ida).getByRole('button', { name: 'Stammplatz vergeben' })))
    expect(((await screen.findByLabelText('Wochentag')) as HTMLSelectElement).value).toBe('1')
    expect((screen.getByLabelText('Uhrzeit') as HTMLSelectElement).value).toBe('z14')
    expect(sp.stammplaetzeWeiterfuehren).not.toHaveBeenCalled()
  })
})
