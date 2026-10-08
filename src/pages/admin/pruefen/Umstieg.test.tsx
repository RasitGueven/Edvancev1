// Umstieg von der Pflege-Strecke (Bauauftrag A 2, F 19): /admin/pflege leitet in die Expertenliste um (mit Hinweis),
// und in Lenas Pruefansicht fuehrt der Admin-Link auf /admin/pruefen/:id. Die echte App-Routentabelle; Auth und
// Supabase-Wrapper sind gemockt.

import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router-dom'
import '@/i18n'

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'admin', email: 'admin@edvance.de' }, role: 'admin', loading: false, signOut: vi.fn() }),
}))
vi.mock('@/pages/admin/AuthoringItemsPage', () => ({
  AuthoringItemsPage: () => {
    const { pathname, search } = useLocation()
    return <p>Expertenliste {pathname}{search}</p>
  },
}))
vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefAufgabe: vi.fn().mockResolvedValue({
    data: {
      task_id: 't1',
      kopf: { kurztitel: 'Umfang', stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis', hilfsmittel: 'Taschenrechner' },
      aufgabe: { input_type: 'NUMERIC', unit: null, status: 'draft', lena_status: 'offen', pruef_version: 1, ausschluss: null,
        pilot: true, team_beanstandet: false, parts: [], optionen: [], bild_vorhanden: false },
      werte: [{ teil: null, werte: [{ wert: '5', schreibweisen: ['5'] }] }], mc: null, regel: null, fehler: [], weitere_hinweise: [],
      flach_regel: false, ohne_erkennung: true, loesungsweg: null, fertigkeit: null, fertigkeit_optionen: [], afb: 'I',
      afb_sicher: null, ausgang: null, aenderungen: [], letzte_pruefung: null, auffaelligkeiten: [],
    },
    error: null,
  }),
  getPruefBoard: vi.fn().mockResolvedValue({ data: [], error: null }),
  getFehlbilder: vi.fn().mockResolvedValue({ data: [], error: null }),
  getPruefEinstellungen: vi.fn().mockResolvedValue({ data: null, error: null }),
  pruefSpeichern: vi.fn(),
  pruefEntscheiden: vi.fn(),
  pruefRueckgaengig: vi.fn(),
  pruefWertungTesten: vi.fn(),
}))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn().mockResolvedValue({ data: true, error: null }) }))
vi.mock('@/lib/supabase/taskPreview', () => ({
  getTaskPreview: vi.fn().mockResolvedValue({ data: null, error: null }),
  PREVIEW_RPC_MISSING: 'missing',
}))

import App from '@/App'

const zeige = (url: string) => render(<MemoryRouter initialEntries={[url]}><App /></MemoryRouter>)

describe('Umstieg auf die Admin-Pruefansicht', () => {
  it('/admin/pflege leitet in die Expertenliste um, mit dem Hinweis', async () => {
    zeige('/admin/pflege')
    expect(await screen.findByText('Expertenliste /admin/authoring/liste?hinweis=pflege')).toBeTruthy()
  })

  it('Lenas Pruefansicht: der Admin-Link heisst „In Admin-Prüfansicht öffnen“ und zeigt auf /admin/pruefen/:id', async () => {
    zeige('/coach/pruefen/t1')
    // Erst auf das Ereignis warten (Text da), dann einmal nach Rolle fragen: findByRole
    // berechnet bei jedem Versuch die Namen der ganzen App und schafft unter Last in 1 s kaum einen.
    await screen.findByText('In Admin-Prüfansicht öffnen')
    const link = screen.getByRole('link', { name: 'In Admin-Prüfansicht öffnen' })
    expect(link.getAttribute('href')).toBe('/admin/pruefen/t1')
  })
})
