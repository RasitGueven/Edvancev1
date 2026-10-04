// Terminbestaetigung: Ort ist Pflicht und erscheint in der Vorschau, Sperre
// ohne Ort/Mail, Versand ueber den (gemockten) Wrapper mit Ort, Hinweis und
// vorbelegter Ort beim erneuten Senden.
// Kein echter Versand: leadMail ist vollstaendig gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { Lead, LeadMailVersand } from '@/types'

let log: LeadMailVersand[] = []

vi.mock('@/lib/supabase/leadMail', () => ({
  listLeadMailVersand: vi.fn(() => Promise.resolve({ data: log, error: null })),
  terminBestaetigungSenden: vi.fn(() =>
    Promise.resolve({ data: { an: 'zz@example.org', anhaenge: [] }, error: null }),
  ),
}))

import { terminBestaetigungSenden } from '@/lib/supabase/leadMail'
import { TerminBestaetigungModal } from './TerminBestaetigungModal'

function lead(over: Partial<Lead> = {}): Lead {
  return {
    id: 'ZZ_lead',
    created_at: '2026-09-01T10:00:00.000Z',
    full_name: 'ZZ_Tim Beispiel',
    first_name: 'ZZ_Tim',
    contact_email: 'zz@example.org',
    contact_phone: null,
    class_level: 9,
    school_type: 'Gymnasium',
    school_name: null,
    schule_id: null,
    subjects: ['Mathematik'],
    goal: null,
    known_weak_topics: [],
    source: null,
    status: 'contacted',
    owner_id: null,
    notes: null,
    converted_student_id: null,
    contacted_at: null,
    onboarding_scheduled_at: null,
    lsa_freigegeben_at: null,
    lsa_fertig_at: null,
    birth_date: null,
    last_grade: null,
    grade_trend: null,
    struggling_since: null,
    tried_before: null,
    next_exam_date: null,
    next_exam_topic: null,
    current_topic_cluster_id: null,
    consent_dsgvo_at: null,
    consent_dsgvo_by: null,
    consent_dsgvo_signature: null,
    consent_dsgvo_document_version: null,
    erstgespraech_at: '2026-10-08T14:00:00.000Z',
    erstgespraech_standort: 'koeln',
    rejected_at: null,
    rejection_reason: null,
    rejection_note: null,
    ...over,
  }
}

const sendenKnopf = (): HTMLElement =>
  screen.getByRole('button', { name: /Bestätigung senden|Erneut senden/ })

describe('TerminBestaetigungModal', () => {
  beforeEach(() => {
    log = []
    vi.clearAllMocks()
  })

  const ortFeld = (): HTMLElement => screen.getByLabelText(/Ort des Gesprächs/)

  it('sperrt das Senden ohne Ort und zeigt den eingetragenen Ort in der Vorschau', async () => {
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    const text = await screen.findByTestId('termin-mail-text')
    expect(text).toHaveTextContent('Termin: Donnerstag, 8. Oktober 2026, 16:00 Uhr')
    expect(text).toHaveTextContent('Ort: (Ort noch nicht eingetragen)')
    expect(screen.getByText('An: zz@example.org')).toBeInTheDocument()
    await waitFor(() => expect(sendenKnopf()).toBeDisabled())
    expect(sendenKnopf().parentElement).toHaveAttribute('title', 'Bitte den Ort des Gesprächs eintragen.')

    fireEvent.change(ortFeld(), { target: { value: 'ZZ_Musterweg 1, Köln' } })
    expect(text).toHaveTextContent('Ort: ZZ_Musterweg 1, Köln')
    expect(sendenKnopf()).toBeEnabled()

    fireEvent.change(ortFeld(), { target: { value: '   ' } })
    expect(sendenKnopf()).toBeDisabled()
  })

  it('sendet mit dem Ort ueber mail_senden und meldet den Empfaenger', async () => {
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    await screen.findByTestId('termin-mail-text')
    fireEvent.change(ortFeld(), { target: { value: '  ZZ_Coworking Ehrenfeld  ' } })
    await waitFor(() => expect(sendenKnopf()).toBeEnabled())
    fireEvent.click(sendenKnopf())
    expect(await screen.findByText('Gesendet an zz@example.org.')).toBeInTheDocument()
    expect(terminBestaetigungSenden).toHaveBeenCalledWith('ZZ_lead', 'ZZ_Coworking Ehrenfeld')
    expect(sendenKnopf()).toHaveTextContent('Erneut senden')
  })

  it('sperrt ohne Eltern-Mail, auch mit Ort', async () => {
    render(<TerminBestaetigungModal lead={lead({ contact_email: null })} onClose={vi.fn()} />)
    await screen.findByTestId('termin-mail-text')
    fireEvent.change(ortFeld(), { target: { value: 'ZZ_Musterweg 1' } })
    await waitFor(() => expect(sendenKnopf()).toBeDisabled())
    expect(screen.getAllByText(/keine Eltern-Mail/).length).toBeGreaterThan(0)
  })

  it('belegt beim erneuten Senden den letzten Ort vor und weist auf den alten Termin hin', async () => {
    log = [
      {
        id: 'ZZ_v1',
        anlass: 'terminbestaetigung',
        empfaenger: 'zz@example.org',
        ort: 'ZZ_Musterweg 1, Köln',
        termin_at: '2026-10-06T14:00:00.000Z',
        fehler: null,
        erfolgt_at: '2026-10-04T08:00:00.000Z',
      },
    ]
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    const hinweis = await screen.findByText(/Bereits gesendet am/)
    expect(hinweis).toHaveTextContent(/Ort: ZZ_Musterweg 1, Köln/)
    expect(hinweis).toHaveTextContent(/alten Termin/)
    await waitFor(() => expect(ortFeld()).toHaveValue('ZZ_Musterweg 1, Köln'))
    expect(sendenKnopf()).toHaveTextContent('Erneut senden')
    expect(sendenKnopf()).toBeEnabled()
  })
})
