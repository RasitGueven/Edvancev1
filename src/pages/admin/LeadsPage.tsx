import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { CLASS_LEVELS, SCHOOL_TYPES, SUBJECTS } from '@/components/edvance/onboarding/constants'
import { createLead, listLeads, updateLead } from '@/lib/supabase/leads'
import { provisionStudent } from '@/lib/supabase/provision'
import type { Lead, LeadGoal, LeadInput, LeadStatus, SchoolKind } from '@/types'

const STATUS_LABEL: Record<LeadStatus, string> = {
  new: 'Neu',
  contacted: 'Kontaktiert',
  onboarding_scheduled: 'Onboarding geplant',
  converted: 'Konvertiert',
  rejected: 'Abgelehnt',
}

const STATUS_VARIANT: Record<LeadStatus, 'primary' | 'warning' | 'success' | 'muted'> = {
  new: 'primary',
  contacted: 'warning',
  onboarding_scheduled: 'warning',
  converted: 'success',
  rejected: 'muted',
}

const GOALS: { value: LeadGoal; label: string }[] = [
  { value: 'IMPROVE_GRADES', label: 'Noten verbessern' },
  { value: 'CLOSE_GAPS', label: 'Lücken schließen' },
  { value: 'EXAM_PREP', label: 'Prüfungsvorbereitung' },
  { value: 'GENERAL', label: 'Allgemein' },
]

const EMPTY_LEAD: LeadInput = {
  full_name: '',
  contact_email: '',
  contact_phone: '',
  class_level: null,
  school_type: null,
  school_name: '',
  subjects: [],
  goal: null,
  source: '',
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

function LeadCreateForm({ onCreated }: { onCreated: () => void }): JSX.Element {
  const [form, setForm] = useState<LeadInput>(EMPTY_LEAD)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const toggleSubject = (subject: string): void => {
    const list = form.subjects ?? []
    setForm({
      ...form,
      subjects: list.includes(subject)
        ? list.filter((s) => s !== subject)
        : [...list, subject],
    })
  }

  const submit = async (): Promise<void> => {
    if (form.full_name.trim() === '') {
      setError('Name ist erforderlich.')
      return
    }
    setSaving(true)
    setError(null)
    const { error: err } = await createLead({
      ...form,
      full_name: form.full_name.trim(),
    })
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setForm(EMPTY_LEAD)
    onCreated()
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        Neuer Lead
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-name">Name *</Label>
          <Input
            id="lead-name"
            value={form.full_name}
            onChange={(e) => setForm({ ...form, full_name: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-email">E-Mail (Eltern)</Label>
          <Input
            id="lead-email"
            type="email"
            value={form.contact_email ?? ''}
            onChange={(e) => setForm({ ...form, contact_email: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-phone">Telefon</Label>
          <Input
            id="lead-phone"
            value={form.contact_phone ?? ''}
            onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-school">Schule</Label>
          <Input
            id="lead-school"
            value={form.school_name ?? ''}
            onChange={(e) => setForm({ ...form, school_name: e.target.value })}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-class">Klasse</Label>
          <select
            id="lead-class"
            className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
            value={form.class_level ?? ''}
            onChange={(e) =>
              setForm({
                ...form,
                class_level: e.target.value ? Number(e.target.value) : null,
              })
            }
          >
            <option value="">–</option>
            {CLASS_LEVELS.map((lvl) => (
              <option key={lvl} value={lvl}>
                {lvl}. Klasse
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-schooltype">Schultyp</Label>
          <select
            id="lead-schooltype"
            className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
            value={form.school_type ?? ''}
            onChange={(e) =>
              setForm({
                ...form,
                school_type: (e.target.value || null) as SchoolKind | null,
              })
            }
          >
            <option value="">–</option>
            {SCHOOL_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-goal">Ziel</Label>
          <select
            id="lead-goal"
            className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
            value={form.goal ?? ''}
            onChange={(e) =>
              setForm({ ...form, goal: (e.target.value || null) as LeadGoal | null })
            }
          >
            <option value="">–</option>
            {GOALS.map((g) => (
              <option key={g.value} value={g.value}>
                {g.label}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lead-source">Quelle</Label>
          <Input
            id="lead-source"
            value={form.source ?? ''}
            onChange={(e) => setForm({ ...form, source: e.target.value })}
          />
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Label>Fächer</Label>
        <div className="flex flex-wrap gap-2">
          {SUBJECTS.map((subject) => {
            const active = (form.subjects ?? []).includes(subject)
            return (
              <button
                key={subject}
                type="button"
                onClick={() => toggleSubject(subject)}
                className="rounded-xl border px-4 py-2 text-sm transition-all"
                style={{
                  borderColor: active ? 'var(--primary)' : 'var(--border)',
                  background: active
                    ? 'color-mix(in srgb, var(--primary) 8%, transparent)'
                    : 'var(--card)',
                }}
              >
                {subject}
              </button>
            )
          })}
        </div>
      </div>
      {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}
      <div>
        <Button onClick={submit} disabled={saving}>
          {saving ? 'Speichert…' : 'Lead anlegen'}
        </Button>
      </div>
    </EdvanceCard>
  )
}

export function LeadsPage(): JSX.Element {
  const [leads, setLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [convertingId, setConvertingId] = useState<string | null>(null)
  const [pwLeadId, setPwLeadId] = useState<string | null>(null)
  const [pw, setPw] = useState('')

  const load = (): void => {
    setLoading(true)
    listLeads().then(({ data, error: err }) => {
      setLeads(data ?? [])
      setError(err)
      setLoading(false)
    })
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
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Leads" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div className="flex items-center justify-between">
          <div>
            <Link
              to="/admin"
              className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
            >
              <ArrowLeft className="h-4 w-4" /> Admin
            </Link>
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">Leads</h1>
          </div>
          <Button onClick={() => setShowForm((v) => !v)}>
            <span className="flex items-center gap-1.5">
              <Plus className="h-4 w-4" /> {showForm ? 'Schließen' : 'Neuer Lead'}
            </span>
          </Button>
        </div>

        {showForm && (
          <LeadCreateForm
            onCreated={() => {
              setShowForm(false)
              load()
            }}
          />
        )}

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

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
                  <span className="text-base font-semibold text-[var(--text-primary)]">
                    {lead.full_name}
                  </span>
                  <EdvanceBadge variant={STATUS_VARIANT[lead.status]}>
                    {STATUS_LABEL[lead.status]}
                  </EdvanceBadge>
                </div>
                <div className="flex flex-wrap gap-x-6 gap-y-1 text-sm text-[var(--text-secondary)]">
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
