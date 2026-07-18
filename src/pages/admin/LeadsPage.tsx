import { useEffect, useState } from 'react'
import { MonitorSmartphone, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  AdminHeader,
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listLeads, updateLead } from '@/lib/supabase/leads'
import { listActivePlaetzeByLead, type LeadPlatz } from '@/lib/supabase/platz'
import { provisionStudent } from '@/lib/supabase/provision'
import type { Lead, LeadStatus } from '@/types'
import { LeadIntakeForm } from './intake/LeadIntakeForm'

const STATUS_LABEL: Record<LeadStatus, string> = {
  new: 'Neu',
  contacted: 'Kontaktiert',
  onboarding_scheduled: 'Onboarding geplant',
  converted: 'Konvertiert',
  rejected: 'Abgelehnt',
  lsa_freigegeben: 'LSA freigegeben',
  lsa_fertig: 'LSA fertig',
}

const STATUS_VARIANT: Record<LeadStatus, 'primary' | 'warning' | 'success' | 'muted'> = {
  new: 'primary',
  contacted: 'warning',
  onboarding_scheduled: 'warning',
  converted: 'success',
  rejected: 'muted',
  lsa_freigegeben: 'primary',
  lsa_fertig: 'success',
}

function nextActions(status: LeadStatus): { label: string; next: LeadStatus }[] {
  if (status === 'new')
    return [
      { label: 'Kontaktiert', next: 'contacted' },
      { label: 'Ablehnen', next: 'rejected' },
    ]
  if (status === 'contacted')
    return [
      { label: 'Onboarding geplant', next: 'onboarding_scheduled' },
      { label: 'Ablehnen', next: 'rejected' },
    ]
  if (status === 'onboarding_scheduled')
    return [{ label: 'Ablehnen', next: 'rejected' }]
  return []
}

export function LeadsPage(): JSX.Element {
  const [leads, setLeads] = useState<Lead[]>([])
  const [platzByLead, setPlatzByLead] = useState<Record<string, LeadPlatz>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingLead, setEditingLead] = useState<Lead | null>(null)
  const [convertingId, setConvertingId] = useState<string | null>(null)
  const [pwLeadId, setPwLeadId] = useState<string | null>(null)
  const [pw, setPw] = useState('')

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

  const changeStatus = async (lead: Lead, next: LeadStatus): Promise<void> => {
    const patch: Parameters<typeof updateLead>[1] = { status: next }
    if (next === 'contacted') patch.contacted_at = new Date().toISOString()
    if (next === 'onboarding_scheduled')
      patch.onboarding_scheduled_at = new Date().toISOString()
    const { error: err } = await updateLead(lead.id, patch)
    if (err) {
      setError(err)
      return
    }
    load()
  }

  const convert = async (lead: Lead, password: string): Promise<void> => {
    setConvertingId(lead.id)
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
    setConvertingId(null)
    if (err) {
      setError(err)
      return
    }
    setPwLeadId(null)
    setPw('')
    load()
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle="Leads" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow="Vertrieb"
          title="Leads"
          description="Interessenten erfassen, qualifizieren und in Schüler konvertieren."
          actions={
            <button
              type="button"
              onClick={() => {
                setEditingLead(null)
                setShowForm((v) => !v)
              }}
              className="admin-cta-gold inline-flex min-h-[44px] items-center gap-1.5 rounded-[var(--radius-full)] px-4 text-sm font-semibold"
            >
              <Plus className="h-4 w-4" /> {showForm ? 'Schließen' : 'Neuer Lead'}
            </button>
          }
        />

        {editingLead ? (
          <LeadIntakeForm
            key={editingLead.id}
            existingLead={editingLead}
            onRefresh={load}
            onClose={() => {
              setEditingLead(null)
              load()
            }}
          />
        ) : (
          showForm && (
            <LeadIntakeForm
              onRefresh={load}
              onClose={() => {
                setShowForm(false)
                load()
              }}
            />
          )
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
          <div className="flex flex-col gap-4">
            {leads.map((lead) => (
              <EdvanceCard key={lead.id} className="flex flex-col gap-3 p-6">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowForm(false)
                      setEditingLead(lead)
                    }}
                    className="text-left text-base font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)]"
                  >
                    {lead.first_name ? `${lead.first_name} · ` : ''}
                    {lead.full_name}
                  </button>
                  <div className="flex items-center gap-2">
                    {platzByLead[lead.id] && (
                      <EdvanceBadge variant="success">
                        <MonitorSmartphone className="mr-1 inline h-3.5 w-3.5" />
                        {platzByLead[lead.id].label}
                      </EdvanceBadge>
                    )}
                    <EdvanceBadge variant={STATUS_VARIANT[lead.status]}>
                      {STATUS_LABEL[lead.status]}
                    </EdvanceBadge>
                  </div>
                </div>
                <div className="flex flex-wrap gap-x-6 gap-y-1 text-sm text-[var(--color-text-secondary)]">
                  {lead.contact_email && <span>{lead.contact_email}</span>}
                  {lead.contact_phone && <span>{lead.contact_phone}</span>}
                  {lead.class_level && <span>Kl. {lead.class_level}</span>}
                  {lead.school_type && <span>{lead.school_type}</span>}
                  {lead.subjects.length > 0 && <span>{lead.subjects.join(', ')}</span>}
                </div>
                {nextActions(lead.status).length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {nextActions(lead.status).map((action) => (
                      <Button
                        key={action.next}
                        variant={action.next === 'rejected' ? 'outline' : 'default'}
                        size="sm"
                        onClick={() => changeStatus(lead, action.next)}
                      >
                        {action.label}
                      </Button>
                    ))}
                    {lead.status !== 'converted' &&
                      lead.status !== 'rejected' &&
                      pwLeadId !== lead.id && (
                        <Button
                          size="sm"
                          onClick={() => {
                            setPwLeadId(lead.id)
                            setPw('')
                            setError(null)
                          }}
                        >
                          In Schüler konvertieren
                        </Button>
                      )}
                  </div>
                )}
                {pwLeadId === lead.id && (
                  <div className="flex flex-col gap-2">
                    <Label htmlFor={`pw-${lead.id}`}>
                      Schüler-Passwort (min. 6 Zeichen) – dem Schüler persönlich mitteilen
                    </Label>
                    <div className="flex flex-wrap items-center gap-2">
                      <Input
                        id={`pw-${lead.id}`}
                        type="text"
                        autoComplete="off"
                        className="max-w-xs"
                        value={pw}
                        onChange={(e) => setPw(e.target.value)}
                      />
                      <Button
                        size="sm"
                        disabled={convertingId === lead.id || pw.length < 6}
                        onClick={() => convert(lead, pw)}
                      >
                        {convertingId === lead.id ? 'Konvertiert …' : 'Bestätigen'}
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={convertingId === lead.id}
                        onClick={() => {
                          setPwLeadId(null)
                          setPw('')
                        }}
                      >
                        Abbrechen
                      </Button>
                    </div>
                  </div>
                )}
              </EdvanceCard>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
