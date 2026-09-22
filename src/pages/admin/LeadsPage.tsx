import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { LsaTodayCard } from '@/components/edvance/report/LsaTodayCard'
import { useAuthContext } from '@/context/AuthContext'
import { listReportSessionsByLead } from '@/lib/supabase/leadLsa'
import { listLeads, updateLead } from '@/lib/supabase/leads'
import { listActivePlaetzeByLead, type LeadPlatz } from '@/lib/supabase/platz'
import { vertragStarten } from '@/lib/supabase/vertraege'
import type { Lead, RejectionReason } from '@/types'
import { LeadIntakeForm } from './intake/LeadIntakeForm'
import { PlatzPanel } from './intake/PlatzPanel'
import { LeadBoard } from './leads/LeadBoard'
import { LeadFilterBar } from './leads/LeadFilterBar'
import { RejectModal } from './leads/RejectModal'
import { TerminModal, type TerminInput } from './leads/TerminModal'
import {
  BOARD_COLUMNS,
  DONE_COLUMN,
  EMPTY_FILTERS,
  type LeadFilters,
} from './leads/boardModel'

export function LeadsPage(): JSX.Element {
  const { t } = useTranslation('leads')
  const { t: tc } = useTranslation('common')
  const { role } = useAuthContext()
  const navigate = useNavigate()
  const [leads, setLeads] = useState<Lead[]>([])
  const [platzByLead, setPlatzByLead] = useState<Record<string, LeadPlatz>>({})
  const [reportByLead, setReportByLead] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingLead, setEditingLead] = useState<Lead | null>(null)
  const [editingStep, setEditingStep] = useState<0 | 1>(0)
  const [platzLead, setPlatzLead] = useState<Lead | null>(null)
  const [terminLead, setTerminLead] = useState<Lead | null>(null)
  const [rejectLead, setRejectLead] = useState<Lead | null>(null)
  const [saving, setSaving] = useState(false)
  // Lead, fuer den gerade "Vertrag starten" laeuft — sperrt den Doppelklick
  // schon im UI; die RPC ist zusaetzlich idempotent.
  const [busyLeadId, setBusyLeadId] = useState<string | null>(null)
  const [filters, setFilters] = useState<LeadFilters>(EMPTY_FILTERS)
  const [showDone, setShowDone] = useState(false)

  const load = (): void => {
    setLoading(true)
    void Promise.all([listLeads(), listActivePlaetzeByLead()]).then(
      async ([leadsRes, platzRes]) => {
        const all = leadsRes.data ?? []
        const decided = all.filter((l) => l.status === 'lsa_fertig').map((l) => l.id)
        const reportRes = await listReportSessionsByLead(decided)
        setLeads(all)
        setPlatzByLead(platzRes.data ?? {})
        setReportByLead(reportRes.data ?? {})
        setError(leadsRes.error ?? platzRes.error ?? reportRes.error)
        setLoading(false)
      },
    )
  }

  useEffect(load, [])

  // Termin speichern. Aus Spalte 1 wechselt der Lead erst jetzt nach
  // "Termin vereinbart"; spaeter aendert es nur den Termin.
  const saveTermin = async (lead: Lead, termin: TerminInput): Promise<void> => {
    setSaving(true)
    const first = lead.status === 'new'
    const { error: err } = await updateLead(lead.id, {
      erstgespraech_at: termin.at,
      erstgespraech_standort: termin.standort,
      ...(first ? { status: 'contacted', contacted_at: new Date().toISOString() } : {}),
    })
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setTerminLead(null)
    load()
  }

  const reject = async (
    lead: Lead,
    reason: RejectionReason,
    note: string | null,
  ): Promise<void> => {
    setSaving(true)
    const { error: err } = await updateLead(lead.id, {
      status: 'rejected',
      rejection_reason: reason,
      rejection_note: note,
    })
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setRejectLead(null)
    load()
  }

  // Legt den Vertrag an (Lead verschwindet vom Board) und oeffnet das Formular.
  const startContract = async (lead: Lead): Promise<void> => {
    if (busyLeadId) return
    setBusyLeadId(lead.id)
    setError(null)
    const { data: vertragId, error: err } = await vertragStarten(lead.id)
    setBusyLeadId(null)
    if (err || !vertragId) {
      setError(err)
      return
    }
    navigate(`/admin/vertraege/${vertragId}`)
  }

  const openLead = (lead: Lead, step: 0 | 1): void => {
    setShowForm(false)
    setEditingStep(step)
    setEditingLead(lead)
  }

  const closeForm = (): void => {
    setEditingLead(null)
    setShowForm(false)
    setEditingStep(0)
    load()
  }

  const columns = showDone ? [...BOARD_COLUMNS, DONE_COLUMN] : BOARD_COLUMNS

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('page.eyebrow')}
          title={t('page.title')}
          description={t('page.description')}
          actions={
            <button
              type="button"
              onClick={() => {
                setEditingLead(null)
                setEditingStep(0)
                setShowForm((v) => !v)
              }}
              className="admin-cta-gold inline-flex min-h-[44px] items-center gap-1.5 rounded-[var(--radius-full)] px-4 text-sm font-semibold"
            >
              <Plus className="h-4 w-4" /> {showForm ? tc('close') : t('page.newLead')}
            </button>
          }
        />

        {/* Fertig-Signal: „ist das Kind durch?" — direkt neben der Freigabe,
            die im Intake-Formular darunter passiert. */}
        <LsaTodayCard />

        {editingLead ? (
          <LeadIntakeForm
            key={editingLead.id}
            existingLead={editingLead}
            initialStep={editingStep}
            onRefresh={load}
            onClose={closeForm}
          />
        ) : (
          showForm && <LeadIntakeForm onRefresh={load} onClose={closeForm} />
        )}

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : leads.length === 0 ? (
          <EmptyState
            icon="📥"
            title={t('page.emptyTitle')}
            description={t('page.emptyDescription')}
          />
        ) : (
          <>
            <LeadFilterBar
              filters={filters}
              onChange={(next) => setFilters((f) => ({ ...f, ...next }))}
              showDone={showDone}
              onToggleDone={setShowDone}
            />
            <LeadBoard
              columns={columns}
              leads={leads}
              filters={filters}
              platzByLead={platzByLead}
              reportByLead={reportByLead}
              canStartContract={role === 'admin'}
              busyLeadId={busyLeadId}
              onOpen={(lead) => openLead(lead, 0)}
              onOpenErstgespraech={(lead) => openLead(lead, 1)}
              onTermin={setTerminLead}
              onAssignPlatz={setPlatzLead}
              onReject={setRejectLead}
              onStartContract={(lead) => void startContract(lead)}
            />
          </>
        )}
      </main>

      <TerminModal
        lead={terminLead}
        saving={saving}
        onClose={() => setTerminLead(null)}
        onSave={(lead, termin) => void saveTermin(lead, termin)}
      />
      {/* key: jeder Lead startet mit leerer Auswahl. */}
      <RejectModal
        key={rejectLead?.id ?? 'none'}
        name={rejectLead?.full_name ?? null}
        saving={saving}
        onClose={() => setRejectLead(null)}
        onConfirm={(reason, note) => {
          if (rejectLead) void reject(rejectLead, reason, note)
        }}
      />

      {platzLead && (
        <PlatzPanel
          lead={platzLead}
          onClose={() => setPlatzLead(null)}
          onChanged={load}
        />
      )}
    </div>
  )
}
