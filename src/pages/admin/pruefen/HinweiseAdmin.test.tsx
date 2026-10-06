// Admin-Pruefansicht, „Hinweise bestätigen“ (L5): nur bei freigegebener Aufgabe mit ungeprueften Hinweisen;
// vor der Freigabe der Satz, dass die Freigabe sie prueft. Wrapper gemockt (CI ohne VITE_*-Variablen).

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { Bearbeitung } from '@/lib/pruefung/entwurf'
import type { KinderHinweis, PruefAufgabe } from '@/types'

vi.mock('@/lib/supabase/pruefungAdmin', () => ({ hinweiseBestaetigen: vi.fn() }))
import { hinweiseBestaetigen } from '@/lib/supabase/pruefungAdmin'
import { HinweiseAdmin } from './HinweiseAdmin'

const hinweise: KinderHinweis[] = [
  { stufe: 1, text: 'Was ist der Radius?', status: 'entwurf' },
  { stufe: 2, text: 'U = 2 · π · r', status: 'geprueft' },
]
const aufgabe = (status: string, h = hinweise): PruefAufgabe =>
  ({ task_id: 't1', hinweise: h, aufgabe: { status } } as unknown as PruefAufgabe)
const b: Bearbeitung = { werte: [], mc: null, regel: null, fehler: [], skill_key: null, afb: null, hinweise: hinweise.map((h) => h.text) }

describe('HinweiseAdmin', () => {
  it('freigegeben mit ungeprueftem Hinweis: Bestätigen ruft hinweise_bestaetigen', async () => {
    vi.mocked(hinweiseBestaetigen).mockResolvedValue({ data: { status: 'ready', aenderungen: [] }, error: null })
    const onBestaetigt = vi.fn()
    render(<HinweiseAdmin aufgabe={aufgabe('ready')} b={b} onBestaetigt={onBestaetigt} onFehler={vi.fn()} />)
    expect(screen.queryByRole('textbox')).toBeNull()
    expect(screen.getByRole('status')).toHaveTextContent('1 Hinweis ist ungeprüft')
    fireEvent.click(screen.getByRole('button', { name: 'Hinweise bestätigen' }))
    await waitFor(() => expect(onBestaetigt).toHaveBeenCalled())
    expect(hinweiseBestaetigen).toHaveBeenCalledWith('t1')
  })

  it('Fehler geht an onFehler', async () => {
    const err = { code: 'ED422', hint: 'keine_hinweise_offen', message: 'x' }
    vi.mocked(hinweiseBestaetigen).mockResolvedValue({ data: null, error: err })
    const onFehler = vi.fn()
    render(<HinweiseAdmin aufgabe={aufgabe('ready')} b={b} onBestaetigt={vi.fn()} onFehler={onFehler} />)
    fireEvent.click(screen.getByRole('button', { name: 'Hinweise bestätigen' }))
    await waitFor(() => expect(onFehler).toHaveBeenCalledWith(err))
  })

  it('vor der Freigabe kein Knopf, nur der Satz zur Freigabe', () => {
    render(<HinweiseAdmin aufgabe={aufgabe('review')} b={b} onBestaetigt={vi.fn()} onFehler={vi.fn()} />)
    expect(screen.queryByRole('button', { name: 'Hinweise bestätigen' })).toBeNull()
    expect(screen.getByRole('status')).toHaveTextContent('Mit der Freigabe gelten alle Hinweise als geprüft.')
  })

  it('alles geprueft: weder Knopf noch Satz', () => {
    const alle = hinweise.map((h) => ({ ...h, status: 'geprueft' as const }))
    render(<HinweiseAdmin aufgabe={aufgabe('ready', alle)} b={b} onBestaetigt={vi.fn()} onFehler={vi.fn()} />)
    expect(screen.queryByRole('button', { name: 'Hinweise bestätigen' })).toBeNull()
    expect(screen.queryByRole('status')).toBeNull()
  })
})
