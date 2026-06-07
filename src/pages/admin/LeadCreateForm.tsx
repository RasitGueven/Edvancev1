import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard } from '@/components/edvance'
import { CLASS_LEVELS, SCHOOL_TYPES, SUBJECTS } from '@/components/edvance/onboarding/constants'
import { createLead } from '@/lib/supabase/leads'
import type { LeadGoal, LeadInput, SchoolKind } from '@/types'

const SELECT_CLS =
  'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

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

export function LeadCreateForm({ onCreated }: { onCreated: () => void }): JSX.Element {
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
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
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
            className={SELECT_CLS}
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
            className={SELECT_CLS}
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
            className={SELECT_CLS}
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
                className={`rounded-xl border px-4 py-2 text-sm transition-all ${
                  active
                    ? 'border-[var(--color-primary)] bg-[color-mix(in_srgb,var(--color-primary)_8%,transparent)]'
                    : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
                }`}
              >
                {subject}
              </button>
            )
          })}
        </div>
      </div>
      {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
      <div>
        <Button onClick={submit} disabled={saving}>
          {saving ? 'Speichert…' : 'Lead anlegen'}
        </Button>
      </div>
    </EdvanceCard>
  )
}
