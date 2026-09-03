import { useEffect, useState } from 'react'
import { Plus } from 'lucide-react'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { LsaTodayCard } from '@/components/edvance/report/LsaTodayCard'
import { listLeads, updateLead } from '@/lib/supabase/leads'
import { listActivePlaetzeByLead, type LeadPlatz } from '@/lib/supabase/platz'
import { provisionStudent } from '@/lib/supabase/provision'
import type { Lead, LeadStatus } from '@/types'
import { LeadIntakeForm } from './intake/LeadIntakeForm'
import { PlatzPanel } from './intake/PlatzPanel'
import { LeadBoard } from './leads/LeadBoard'
import { LeadFilterBar } from './leads/LeadFilterBar'
import {
  BOARD_COLUMNS,
  DONE_COLUMN,
  EMPTY_FILTERS,
  type LeadFilters,
} from './leads/boardModel'

export function LeadsPage(): JSX.Element {
  const [leads, setLeads] = useState<Lead[]>([])
  const [platzByLead, setPlatzByLead] = useState<Record<string, LeadPlatz>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingLead, setEditingLead] = useState<Lead | null>(null)
  const [editingStep, setEditingStep] = useState<0 | 1>(0)
  const [platzLead, setPlatzLead] = useState<Lead | null>(null)
  const [convertLead, setConvertLead] = useState<Lead | null>(null)
  const [pw, setPw] = useState('')
  const [converting, setConverting] = useState(false)
  const [filters, setFilters] = useState<LeadFilters>(EMPTY_FILTERS)
  const [showDone, setShowDone] = useState(false)

  const load = (): void => {
    setLoading(true)
    void Promise.all([listLeads(), listActivePlaetzeByLead()]).then(
      ([leadsRes, platzRes]) => {
        setLeads(leadsRes.data ?? [])
        setPlatzByLead(platzRes.data ?? {})
        setError(leadsRes.error ?? platzRes.error)
        setLoading(false)
      },
    )
  }

  useEffect(load, [])

  // Einziger verbliebener manueller Statuswechsel: "Ablehnen" im
  // Overflow-Menue der Karte. 'contacted' setzt seit dem Wizard-Umbau der
  // Speicherpfad von Schritt 2, 'lsa_freigegeben' die RPC, 'lsa_fertig' ein
  // Trigger.
  const changeStatus = async (lead: Lead, next: LeadStatus): Promise<void> => {
    const { error: err } = await updateLead(lead.id, { status: next })
    if (err) {
      setError(err)
      return
    }
    load()
  }

  const convert = async (lead: Lead, password: string): Promise<void> => {
    setConverting(true)
    setError(null)
    const { error: err } = await provisionStudent({
      lead_id: lead.id,
      full_name: lead.full_name,
      parent_email: lead.contact_email,
      class_level: lead.class_level,
      school_type: lead.school_type,
      school_name: lead.school_name,
      subjects: lead.subjects,
      student_password: password,
    })
    setConverting(false)
    if (err) {
      setError(err)
      return
    }
    setConvertLead(null)
    setPw('')
    load()
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
      <EdvanceNavbar subtitle="Leads" sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow="Vertrieb"
          title="Leads"
          description="Interessenten erfassen, qualifizieren und in Schüler konvertieren."
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
              <Plus className="h-4 w-4" /> {showForm ? 'Schließen' : 'Neuer Lead'}
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
            title="Noch keine Leads"
            description="Lege den ersten Lead über den Button oben an."
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
              onOpen={(lead) => openLead(lead, 0)}
              onOpenErstgespraech={(lead) => openLead(lead, 1)}
              onAssignPlatz={setPlatzLead}
              onConvert={(lead) => {
                setPw('')
                setError(null)
                setConvertLead(lead)
              }}
              onReject={(lead) => void changeStatus(lead, 'rejected')}
            />
          </>
        )}
      </main>

      <Modal
        open={convertLead !== null}
        onClose={() => setConvertLead(null)}
        title="In Schüler konvertieren"
        description="Das Passwort dem Schüler persönlich mitteilen — es wird nirgends erneut angezeigt."
        size="md"
      >
        <div className="flex flex-col gap-2">
          <Label htmlFor="convert-pw">Schüler-Passwort (min. 6 Zeichen)</Label>
          <Input
            id="convert-pw"
            type="text"
            autoComplete="off"
            value={pw}
            onChange={(e) => setPw(e.target.value)}
          />
          <div className="mt-2 flex flex-wrap gap-2">
            <Button
              disabled={converting || pw.length < 6}
              onClick={() => convertLead && void convert(convertLead, pw)}
            >
              {converting ? 'Konvertiert …' : 'Bestätigen'}
            </Button>
            <Button
              variant="outline"
              disabled={converting}
              onClick={() => setConvertLead(null)}
            >
              Abbrechen
            </Button>
          </div>
        </div>
      </Modal>

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
