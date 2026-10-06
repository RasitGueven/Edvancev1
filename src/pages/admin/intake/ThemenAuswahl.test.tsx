// Themenauswahl im Erstgespraech: Bestandsleads mit altem Cluster rendern
// weiter, der Hinweis ohne Schulplan erscheint, eine Suche ohne Treffer zeigt
// den Mathe-Heft-Hinweis, eine Auswahl schreibt lead_themen inklusive
// Vorbelegung aus dem Plan. Supabase ist gemockt.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { Lead, LeadThema } from '@/types'
import { TEST_KATALOG } from '@/lib/themen/katalog.fixture'

let leadThemen: LeadThema[] = []

vi.mock('@/lib/supabase/themen', () => ({
  fachSchluessel: (f: string) => f.toLowerCase(),
  listThemen: vi.fn((fach: string) =>
    Promise.resolve({ data: fach === 'mathematik' ? TEST_KATALOG : [], error: null }),
  ),
  listSchulPlan: vi.fn(() =>
    Promise.resolve({
      data: [
        { klasse: 7, position: 1, thema_key: 'rationale_zahlen', stand: '08/2021' },
        { klasse: 8, position: 1, thema_key: 'terme_binomische_formeln', stand: '08/2021' },
        { klasse: 8, position: 2, thema_key: 'zufallsexperimente', stand: '08/2021' },
      ],
      error: null,
    }),
  ),
  listLeadThemen: vi.fn(() => Promise.resolve({ data: leadThemen, error: null })),
  setAktuellesThema: vi.fn((_l: string, fach: string, key: string) => {
    leadThemen = [
      ...leadThemen.filter((x) => x.status !== 'aktuell' && x.thema_key !== key),
      { thema_key: key, fach, status: 'aktuell', quelle: 'gespraech' },
    ]
    return Promise.resolve({ data: null, error: null })
  }),
  behandeltAnlegen: vi.fn((_l: string, fach: string, keys: string[], quelle) => {
    leadThemen = [
      ...leadThemen,
      ...keys.map((k) => ({ thema_key: k, fach, status: 'behandelt' as const, quelle })),
    ]
    return Promise.resolve({ data: null, error: null })
  }),
  behandeltEntfernen: vi.fn(() => Promise.resolve({ data: null, error: null })),
}))
vi.mock('@/lib/supabase/tasks', () => ({
  getClusterById: vi.fn(() =>
    Promise.resolve({ data: { id: 'ZZ_cluster', name: 'ZZ Bruchrechnung (alt)' }, error: null }),
  ),
}))
vi.mock('@/lib/supabase/testmodus', () => ({
  getStudentIstTest: vi.fn(() => Promise.resolve({ data: false, error: null })),
  testkontoSetzen: vi.fn(() => Promise.resolve({ data: true, error: null })),
}))
vi.mock('@/lib/supabase/schulen', () => ({
  listSchulenAuswahl: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))
vi.mock('@/lib/supabase/leads', () => ({
  createLead: vi.fn(),
  updateLead: vi.fn(() => Promise.resolve({ data: null, error: null })),
  setLeadConsent: vi.fn(),
}))
vi.mock('@/lib/supabase/leadLsa', () => ({
  leadAssessmentUpsert: vi.fn(),
  leadLsaFreigeben: vi.fn(() => Promise.resolve({ data: null, error: null })),
}))
vi.mock('@/context/AuthContext', () => ({
  useAuthContext: () => ({ user: { id: 'ZZ_admin', email: 'admin@edvance.de' } }),
}))

import { behandeltAnlegen, setAktuellesThema } from '@/lib/supabase/themen'
import { leadLsaFreigeben } from '@/lib/supabase/leadLsa'
import { LeadIntakeForm } from './LeadIntakeForm'

function bestandsLead(over: Partial<Lead> = {}): Lead {
  return {
    id: 'ZZ_lead',
    created_at: '2026-09-01T10:00:00.000Z',
    full_name: 'ZZ_Test Kind',
    first_name: 'ZZ_Mia',
    contact_email: 'zz@example.org',
    contact_phone: null,
    class_level: 8,
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
    erstgespraech_at: null,
    erstgespraech_standort: null,
    rejected_at: null,
    rejection_reason: null,
    rejection_note: null,
    ...over,
  }
}

const oeffnen = (lead: Lead): void => {
  render(
    <LeadIntakeForm existingLead={lead} initialStep={1} onRefresh={vi.fn()} onClose={vi.fn()} />,
  )
}

describe('ThemenAuswahl im Erstgespraech', () => {
  beforeEach(() => {
    leadThemen = []
    vi.clearAllMocks()
  })

  it('ein Lead mit altem current_topic_cluster_id rendert weiter und zeigt das alte Thema', async () => {
    oeffnen(bestandsLead({ current_topic_cluster_id: 'ZZ_cluster' }))
    expect(
      await screen.findByText('Bisher erfasst (alte Auswahl): ZZ Bruchrechnung (alt)'),
    ).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/Was sagt das Kind/)).toBeInTheDocument()
  })

  it('ohne Schule: Hinweis "Kein Schulplan hinterlegt"', async () => {
    oeffnen(bestandsLead())
    expect(
      await screen.findByText('Kein Schulplan hinterlegt – im Mathe-Heft nachsehen'),
    ).toBeInTheDocument()
  })

  it('kein Treffer: Hinweis aufs Mathe-Heft, kein Freitext-Thema', async () => {
    oeffnen(bestandsLead())
    const feld = await screen.findByPlaceholderText(/Was sagt das Kind/)
    fireEvent.change(feld, { target: { value: 'photosynthese' } })
    expect(
      screen.getByText('Kein passendes Thema – bitte mit dem Mathe-Heft abgleichen'),
    ).toBeInTheDocument()
  })

  it('mit Schulplan: Auswahl setzt das aktuelle Thema und belegt "schon behandelt" vor', async () => {
    oeffnen(bestandsLead({ schule_id: 'ZZ_schule', school_name: 'ZZ Gymnasium' }))
    const feld = await screen.findByPlaceholderText(/Was sagt das Kind/)
    fireEvent.change(feld, { target: { value: 'baumdiagramm' } })
    // Klasse 8 = Erste Stufe: Zufall steht oben, Bedingte W. unter "andere".
    fireEvent.click(screen.getAllByRole('button', { name: 'Zufall und Wahrscheinlichkeit' })[0])
    await waitFor(() =>
      expect(setAktuellesThema).toHaveBeenCalledWith('ZZ_lead', 'mathematik', 'zufallsexperimente'),
    )
    await waitFor(() =>
      expect(behandeltAnlegen).toHaveBeenCalledWith(
        'ZZ_lead',
        'mathematik',
        ['rationale_zahlen', 'terme_binomische_formeln'],
        'schulplan',
      ),
    )
    expect(await screen.findByText('aus dem Schulplan (Stand 08/2021)')).toBeInTheDocument()
    expect(screen.getByText('Aktuell: Zufall und Wahrscheinlichkeit')).toBeInTheDocument()
  })
})

describe('LSA-Freigabe ohne aktuelles Thema', () => {
  const mitEinwilligung = (over: Partial<Lead> = {}): Lead =>
    bestandsLead({ consent_dsgvo_at: '2026-10-01T10:00:00.000Z', ...over })
  const HINWEIS =
    'Kein aktuelles Thema gewählt – die Lernstandsanalyse prüft dann ohne Schwerpunkt in der Breite.'

  beforeEach(() => {
    leadThemen = []
    vi.clearAllMocks()
    // jsdom kennt scrollIntoView nicht.
    Element.prototype.scrollIntoView = vi.fn()
  })

  it('mit Thema: direkt freigeben, keine Bestaetigung', async () => {
    leadThemen = [
      { thema_key: 'reelle_zahlen', fach: 'mathematik', status: 'aktuell', quelle: 'gespraech' },
    ]
    oeffnen(mitEinwilligung())
    const knopf = await screen.findByRole('button', { name: 'Für die LSA freigeben' })
    await waitFor(() => expect(knopf).toBeEnabled())
    expect(screen.queryByText(HINWEIS)).not.toBeInTheDocument()
    fireEvent.click(knopf)
    await waitFor(() => expect(leadLsaFreigeben).toHaveBeenCalledWith('ZZ_lead', 8, 'Mathematik', false))
  })

  it('ohne Thema: Hinweis, primaer "Thema wählen", Freigabe erst nach bewusstem Klick', async () => {
    oeffnen(mitEinwilligung())
    expect(await screen.findByText(HINWEIS)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Für die LSA freigeben' })).not.toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Thema wählen' }))
    expect(document.activeElement?.id).toBe('thema-suche')
    expect(leadLsaFreigeben).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Ohne Thema freigeben' }))
    await waitFor(() => expect(leadLsaFreigeben).toHaveBeenCalledWith('ZZ_lead', 8, 'Mathematik', false))
  })

  it('Deutsch (kein Katalog): keine Bestaetigung', async () => {
    oeffnen(mitEinwilligung({ subjects: ['Deutsch'] }))
    expect(await screen.findByText('Noch kein Themenkatalog')).toBeInTheDocument()
    const knopf = screen.getByRole('button', { name: 'Für die LSA freigeben' })
    expect(knopf).toBeEnabled()
    expect(screen.queryByText(HINWEIS)).not.toBeInTheDocument()
  })
})
