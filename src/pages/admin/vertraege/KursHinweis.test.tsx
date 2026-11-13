import { beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { VertragMitLead } from '@/types'

const kindKursZumLead = vi.fn()
vi.mock('@/lib/supabase/kindKurs', () => ({ kindKursZumLead: (id: string) => kindKursZumLead(id) }))

const { KursHinweis } = await import('./KursHinweis')

const zeile = (kurs: 'E' | 'G' | null) => ({
  id: 'k1', fach: 'mathematik', kurs, abschlussziel: null, ab_datum: '2026-11-01', erfasst_am: '2026-11-01T10:00:00Z',
})
const vertrag = (over: Partial<VertragMitLead> = {}, kurs: 'E' | 'G' | null = 'E'): VertragMitLead =>
  ({
    id: 'v1', lead_id: 'l1', student_id: null, status: 'in_vorbereitung',
    lead: { id: 'l1', kurs_mathe: kurs, abschlussziel: null },
    ...over,
  }) as unknown as VertragMitLead

describe('KursHinweis (SF-1: Lead-Angabe verfällt beim Vertrag)', () => {
  beforeEach(() => kindKursZumLead.mockReset())

  it('zeigt den Hinweis, wenn die Akte schon einen anderen Kurs hat', async () => {
    kindKursZumLead.mockResolvedValue({ data: zeile('G'), error: null })
    render(<KursHinweis vertrag={vertrag()} />)
    const p = await screen.findByTestId('vertrag-kurs-hinweis')
    expect(p.textContent).toContain('E-Kurs')
    expect(p.textContent).toContain('G-Kurs')
  })

  it('schweigt bei gleichem Stand, ohne Akten-Zeile, beim Folgevertrag und ohne Lead-Angabe', async () => {
    kindKursZumLead.mockResolvedValue({ data: zeile('E'), error: null })
    const { rerender } = render(<KursHinweis vertrag={vertrag()} />)
    await waitFor(() => expect(kindKursZumLead).toHaveBeenCalledWith('l1'))
    expect(screen.queryByTestId('vertrag-kurs-hinweis')).toBeNull()

    kindKursZumLead.mockReset()
    rerender(<KursHinweis vertrag={vertrag({ student_id: 's1' })} />)
    rerender(<KursHinweis vertrag={vertrag({}, null)} />)
    rerender(<KursHinweis vertrag={vertrag({ status: 'abgeschlossen' })} />)
    expect(kindKursZumLead).not.toHaveBeenCalled()
    expect(screen.queryByTestId('vertrag-kurs-hinweis')).toBeNull()
  })
})
