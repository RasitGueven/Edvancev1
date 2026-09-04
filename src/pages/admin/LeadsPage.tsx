import { useEffect, useState } from 'react'
import { Plus } from 'lucide-react'
import { AdminHeader, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { LsaTodayCard } from '@/components/edvance/report/LsaTodayCard'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
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
  const [filters, setFilters] = useState<LeadFilters>(EMPTY_FILTERS)
  const [showDone, setShowDone] = useState(false)
  // Konversion: Lead, fuer den das Passwort erfragt wird, plus Eingabe.
  const [convertLead, setConvertLead] = useState<Lead | null>(null)
  const [pw, setPw] = useState('')
  const [converting, setConverting] = useState(false)

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

  // Manuelle Statuswechsel auf dem Board: "Ablehnen" aus dem Overflow und
  // "Termin vereinbart" als Primaeraktion der ersten Spalte. 'lsa_freigegeben'
  // setzt die RPC aus Schritt 2 des Wizards, 'lsa_fertig' ein Trigger.
  const changeStatus = async (
    lead: Lead,
    next: LeadStatus,
    extra: Partial<Parameters<typeof updateLead>[1]> = {},
  ): Promise<void> => {
    const { error: err } = await updateLead(lead.id, { status: next, ...extra })
    if (err) {
      setError(err)
      return
    }
    load()
  }

  // Konversion in einen echten Schueler — irreversibel, deshalb nur ueber das
  // Overflow-Menue und mit Passwortabfrage davor. Unveraenderter Weg:
  // provisionStudent (Edge Function), danach neu laden.
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

        {/* Passwortabfrage der Konversion — inline statt Modal, mit dem Namen
            des Leads, weil sie vom Overflow-Menue einer Karte kommt. */}
        {convertLead && (
          <EdvanceCard className="flex flex-col gap-2 p-4">
            <Label htmlFor="convert-pw">
              Schüler-Passwort für {convertLead.full_name} (min. 6 Zeichen) – dem Schüler
              persönlich mitteilen
            </Label>
            <div className="flex flex-wrap items-center gap-2">
              <Input
                id="convert-pw"
                type="text"
                autoComplete="off"
                className="max-w-xs"
                value={pw}
                onChange={(e) => setPw(e.target.value)}
              />
              <Button
                size="sm"
                disabled={converting || pw.length < 6}
                onClick={() => void convert(convertLead, pw)}
              >
                {converting ? 'Konvertiert …' : 'Bestätigen'}
              </Button>
              <Button
                size="sm"
                variant="outline"
                disabled={converting}
                onClick={() => {
                  setConvertLead(null)
                  setPw('')
                }}
              >
                Abbrechen
              </Button>
            </div>
          </EdvanceCard>
        )}

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
              onMarkContacted={(lead) =>
                void changeStatus(lead, 'contacted', {
                  contacted_at: new Date().toISOString(),
                })
              }
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
