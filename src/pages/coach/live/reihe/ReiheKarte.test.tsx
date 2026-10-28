import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { ReiheCoach } from '@/types/reihe'

const lesen = vi.fn()
const bestaetigen = vi.fn()
vi.mock('@/lib/supabase/reihe', () => ({
  reiheCoachLesen: (...a: unknown[]) => lesen(...a),
  reiheBestaetigen: (...a: unknown[]) => bestaetigen(...a),
  reiheVerschieben: vi.fn(),
  reiheKaSetzen: vi.fn(),
}))
const { ReiheKarte } = await import('./ReiheKarte')

const plan = {
  modus: 'klassenarbeit' as const, ka_datum: '2099-03-02', sessions_bisher: 0,
  sessions: [
    { nr: 1, datum: '2099-01-11', art: 'normal' as const, kernideen: [], skills: ['fkt_quadr_parabel'], transfer: false, minuten: 24 },
    { nr: 2, datum: '2099-01-18', art: 'generalprobe' as const, kernideen: [], skills: [], transfer: true, minuten: 0 },
  ],
  warnung: { passt: false, sessions: 2, entfallen: [{ art: 'kernidee' as const, skill_key: 'fkt_quadr_extrem', kernidee_key: 'K1' }] },
  bestaetigt: false,
}
const r: ReiheCoach = { reihe_id: 'r1', thema_keys: ['q'], ka_datum: '2099-03-02', plan, system: plan, vorher: null, sessions_gesamt: 2,
  labels: { fkt_quadr_parabel: 'Normalparabel', fkt_quadr_extrem: 'Extremwerte' }, kernideen: {} }

afterEach(() => { cleanup(); lesen.mockReset(); bestaetigen.mockReset() })

describe('ReiheKarte', () => {
  it('zeigt Session n von N, Warnung und bestätigt den Plan', async () => {
    lesen.mockResolvedValue({ data: r, error: null })
    bestaetigen.mockResolvedValue({ data: { ...r, plan: { ...plan, bestaetigt: true } }, error: null })
    render(<ReiheKarte studentId="k1" />)
    expect(await screen.findByText('Session 1 von 2')).toBeTruthy()
    expect(screen.getByRole('alert').textContent).toBe('Die Reihe passt nicht in 2 Sessions: Extremwerte fällt weg.')
    expect(screen.getByText('Normalparabel')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Plan bestätigen' }))
    await waitFor(() => expect(screen.getByText('Plan bestätigt')).toBeTruthy())
    expect(bestaetigen).toHaveBeenCalledWith('r1')
  })
  it('ohne Reihe einladender Leerzustand, kompakt nichts', async () => {
    lesen.mockResolvedValue({ data: null, error: null })
    const { container, unmount } = render(<ReiheKarte studentId="k1" kompakt />)
    await waitFor(() => expect(lesen).toHaveBeenCalled())
    await waitFor(() => expect(container.textContent).toBe(''))
    unmount()
    render(<ReiheKarte studentId="k1" />)
    expect(await screen.findByText('Noch keine Reihe')).toBeTruthy()
  })
})
