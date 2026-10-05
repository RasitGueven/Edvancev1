import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
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
import { TerminBestaetigungModal } from './leads/TerminBestaetigungModal'
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
  const [params, setParams] = useSearchParams()
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
  const [bestaetigungLead, setBestaetigungLead] = useState<Lead | null>(null)
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

  // „Neuer Lead“ von der Startseite (/admin/leads?neu=1): Formular öffnen und
  // den Parameter entfernen, damit Neuladen es nicht erneut öffnet.
  useEffect(() => {
    if (params.get('neu') !== '1') return
    setEditingLead(null)
    setEditingStep(0)
    setShowForm(true)
    setParams((p) => {
      p.delete('neu')
      return p
    }, { replace: true })
  }, [params, setParams])

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
    <>
      <PageHeader
        rubrik={t('page.eyebrow')}
        titel={t('page.title')}
        satz={t('page.description')}
        aktionen={
          <Button
            type="button"
            onClick={() => {
              setEditingLead(null)
              setEditingStep(0)
              setShowForm((v) => !v)
            }}
          >
            <Plus aria-hidden="true" className="h-4 w-4" /> {showForm ? tc('close') : t('page.newLead')}
          </Button>
        }
      />

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
            onBestaetigung={role === 'admin' ? setBestaetigungLead : undefined}
            onAssignPlatz={setPlatzLead}
            onReject={setRejectLead}
            onStartContract={(lead) => void startContract(lead)}
          />
        </>
      )}

      <TerminModal
        lead={terminLead}
        saving={saving}
        onClose={() => setTerminLead(null)}
        onSave={(lead, termin) => void saveTermin(lead, termin)}
      />
      <TerminBestaetigungModal lead={bestaetigungLead} onClose={() => setBestaetigungLead(null)} />
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
    </>
  )
}
