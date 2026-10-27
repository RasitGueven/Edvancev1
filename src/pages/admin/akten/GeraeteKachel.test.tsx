// Kachel Geräte und Zugangscode (Reihe 1 · D1): Liste, Abmelden mit Inline-Bestätigung, neuer Code,
// Freischalten nur bei gesperrtem Code. Die Lib ist eine Attrappe.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { KindGeraet, KindZugang } from '@/lib/supabase/kindGeraete'

const lib = vi.hoisted(() => ({
  listKindGeraete: vi.fn(),
  getKindZugang: vi.fn(),
  kindGeraetAbmelden: vi.fn(),
  zugangscodeNeu: vi.fn(),
  zugangscodeFreischalten: vi.fn(),
}))
vi.mock('@/lib/supabase/kindGeraete', () => lib)

import { GeraeteKachel } from './GeraeteKachel'

const geraet = (id: string, name: string, abgemeldet: string | null = null): KindGeraet => ({
  id, name, plattform: 'ios', angemeldet_am: '2026-10-20T15:00:00Z', zuletzt_gesehen: '2026-10-26T17:00:00Z',
  abgemeldet_am: abgemeldet, abmelde_grund: abgemeldet ? 'admin' : null,
})
const zugang = (gesperrt: string | null = null): KindZugang => ({
  vertrag_id: 'v1', zugangscode: 'EDV-K7M2-QX9A', zugangscode_erzeugt_am: '2026-10-01', zugangscode_gesperrt_am: gesperrt,
})

beforeEach(() => {
  Object.values(lib).forEach((f) => f.mockReset())
  lib.kindGeraetAbmelden.mockResolvedValue({ data: null, error: null })
  lib.zugangscodeNeu.mockResolvedValue({ data: 'EDV-NEUU-CODE', error: null })
  lib.zugangscodeFreischalten.mockResolvedValue({ data: null, error: null })
})

describe('GeraeteKachel', () => {
  it('zeigt aktive Geräte, die Grenze und den maskierten Code', async () => {
    lib.listKindGeraete.mockResolvedValue({ data: [geraet('g1', 'Batus iPhone'), geraet('g2', 'Altes Handy', '2026-10-21T10:00:00Z')], error: null })
    lib.getKindZugang.mockResolvedValue({ data: zugang(), error: null })
    render(<GeraeteKachel studentId="s1" />)
    expect(await screen.findByText('Batus iPhone')).toBeTruthy()
    expect(screen.getByText('1 von 3 Geräten angemeldet.')).toBeTruthy()
    expect(screen.getByText(/Früher angemeldet: Altes Handy/)).toBeTruthy()
    expect(screen.getByTestId('zugangscode-wert').textContent).not.toContain('K7M2')
    expect(screen.queryByText('Code freischalten')).toBeNull()
  })

  it('ohne Gerät: einladender Leerzustand', async () => {
    lib.listKindGeraete.mockResolvedValue({ data: [], error: null })
    lib.getKindZugang.mockResolvedValue({ data: null, error: null })
    render(<GeraeteKachel studentId="s1" />)
    expect(await screen.findByText('Noch kein Gerät angemeldet')).toBeTruthy()
  })

  it('Abmelden erst nach Bestätigung, dann neu laden', async () => {
    lib.listKindGeraete.mockResolvedValue({ data: [geraet('g1', 'Batus iPhone')], error: null })
    lib.getKindZugang.mockResolvedValue({ data: zugang(), error: null })
    render(<GeraeteKachel studentId="s1" />)
    fireEvent.click(await screen.findByText('Gerät abmelden'))
    expect(lib.kindGeraetAbmelden).not.toHaveBeenCalled()
    fireEvent.click(screen.getByText('Ja, abmelden'))
    await waitFor(() => expect(lib.kindGeraetAbmelden).toHaveBeenCalledWith('g1'))
    await waitFor(() => expect(lib.listKindGeraete).toHaveBeenCalledTimes(2))
  })

  it('neuer Code nach Bestätigung; gesperrter Code lässt sich freischalten', async () => {
    lib.listKindGeraete.mockResolvedValue({ data: [], error: null })
    lib.getKindZugang.mockResolvedValue({ data: zugang('2026-10-22'), error: null })
    render(<GeraeteKachel studentId="s1" />)
    fireEvent.click(await screen.findByText('Code freischalten'))
    await waitFor(() => expect(lib.zugangscodeFreischalten).toHaveBeenCalledWith('v1'))
    fireEvent.click(await screen.findByRole('button', { name: 'Neuen Code erzeugen' }))
    fireEvent.click(screen.getAllByRole('button', { name: 'Neuen Code erzeugen' })[0])
    await waitFor(() => expect(lib.zugangscodeNeu).toHaveBeenCalledWith('v1'))
  })
})
