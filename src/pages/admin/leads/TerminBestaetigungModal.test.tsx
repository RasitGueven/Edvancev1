// Terminbestaetigung: Vorschau vor dem Senden, Sperre ohne Adresse/Mail,
// Versand ueber den (gemockten) Wrapper, Hinweis beim erneuten Senden.
// Kein echter Versand: leadMail ist vollstaendig gemockt.

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import i18n from '@/i18n'
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

const ORT = 'mail.terminOrt_koeln'
const original = i18n.t(ORT, { ns: 'vertraege' })

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
  afterEach(() => {
    i18n.addResource('de', 'vertraege', ORT, original)
  })

  it('zeigt die Vorschau und sperrt das Senden, solange die Adresse fehlt', async () => {
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    expect(await screen.findByTestId('termin-mail-text')).toHaveTextContent(
      'Termin: Donnerstag, 8. Oktober 2026, 16:00 Uhr',
    )
    expect(screen.getByText('An: zz@example.org')).toBeInTheDocument()
    expect(screen.getAllByText(/Adresse des Standorts fehlt/).length).toBeGreaterThan(0)
    await waitFor(() => expect(sendenKnopf()).toBeDisabled())
  })

  it('sendet nach der Vorschau ueber mail_senden und meldet den Empfaenger', async () => {
    i18n.addResource('de', 'vertraege', ORT, 'ZZ_Teststraße 1, 50667 Köln')
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    await waitFor(() => expect(sendenKnopf()).toBeEnabled())
    fireEvent.click(sendenKnopf())
    expect(await screen.findByText('Gesendet an zz@example.org.')).toBeInTheDocument()
    expect(terminBestaetigungSenden).toHaveBeenCalledWith('ZZ_lead')
    expect(sendenKnopf()).toHaveTextContent('Erneut senden')
  })

  it('sperrt ohne Eltern-Mail', async () => {
    i18n.addResource('de', 'vertraege', ORT, 'ZZ_Teststraße 1, 50667 Köln')
    render(<TerminBestaetigungModal lead={lead({ contact_email: null })} onClose={vi.fn()} />)
    await waitFor(() => expect(sendenKnopf()).toBeDisabled())
    expect(screen.getAllByText(/keine Eltern-Mail/).length).toBeGreaterThan(0)
  })

  it('weist beim erneuten Senden auf den letzten Versand und einen alten Termin hin', async () => {
    i18n.addResource('de', 'vertraege', ORT, 'ZZ_Teststraße 1, 50667 Köln')
    log = [
      {
        id: 'ZZ_v1',
        anlass: 'terminbestaetigung',
        empfaenger: 'zz@example.org',
        termin_at: '2026-10-06T14:00:00.000Z',
        fehler: null,
        erfolgt_at: '2026-10-04T08:00:00.000Z',
      },
    ]
    render(<TerminBestaetigungModal lead={lead()} onClose={vi.fn()} />)
    expect(await screen.findByText(/Bereits gesendet am/)).toHaveTextContent(/alten Termin/)
    expect(sendenKnopf()).toHaveTextContent('Erneut senden')
  })
})
