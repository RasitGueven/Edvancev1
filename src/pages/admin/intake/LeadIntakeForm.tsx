import { useEffect, useState } from 'react'
import { X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EdvanceCard } from '@/components/edvance'
import { useAuthContext } from '@/context/AuthContext'
import { createLead, setLeadConsent, updateLead } from '@/lib/supabase/leads'
import {
  getOpenSessionForLead,
  leadAssessmentUpsert,
  leadLsaFreigeben,
} from '@/lib/supabase/leadLsa'
import {
  assignPlatz,
  listPlaetze,
  releasePlatz,
  type PlatzBelegt,
  type PlatzDevice,
} from '@/lib/supabase/platz'
import type { Lead } from '@/types'
import { SectionLead } from './SectionLead'
import { SectionErstgespraech } from './SectionErstgespraech'
import { SectionFreigabePlatz, type FreigabeSession } from './SectionFreigabePlatz'
import {
  EMPTY_INTAKE,
  intakeFromLead,
  intakeToLeadInput,
  type IntakeFormState,
} from './formState'

type LeadIntakeFormProps = {
  existingLead?: Lead
  onRefresh: () => void
  onClose: () => void
}

const STEPS = ['Stammdaten', 'Erstgespräch', 'Freigabe & Platz'] as const

export function LeadIntakeForm({
  existingLead,
  onRefresh,
  onClose,
}: LeadIntakeFormProps): JSX.Element {
  const { user } = useAuthContext()
  const [form, setForm] = useState<IntakeFormState>(
    existingLead ? intakeFromLead(existingLead) : EMPTY_INTAKE,
  )
  const [step, setStep] = useState(0)
  const [leadId, setLeadId] = useState<string | null>(existingLead?.id ?? null)
  const [consentAt, setConsentAt] = useState<string | null>(
    existingLead?.consent_dsgvo_at ?? null,
  )
  const [selectedSubject, setSelectedSubject] = useState<string | null>(null)
  const [session, setSession] = useState<FreigabeSession | null>(null)
  const [plaetze, setPlaetze] = useState<PlatzDevice[] | null>(null)
  const [belegtePlaetze, setBelegtePlaetze] = useState<PlatzBelegt[]>([])
  const [platzLoading, setPlatzLoading] = useState(false)
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [releasingId, setReleasingId] = useState<string | null>(null)
  const [confirmReleaseId, setConfirmReleaseId] = useState<string | null>(null)
  const [assignedPlatz, setAssignedPlatz] = useState<{
    label: string
    expires_at: string
    assignment_id: string
  } | null>(null)
  const [busy, setBusy] = useState(false)
  const [confirmingConsent, setConfirmingConsent] = useState(false)
  const [freigebenLoading, setFreigebenLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const patch = (next: Partial<IntakeFormState>): void => setForm((f) => ({ ...f, ...next }))

  const subjectForFreigabe =
    form.subjects.length === 1 ? form.subjects[0] : selectedSubject

  const loadPlaetze = async (): Promise<void> => {
    setPlatzLoading(true)
    const { data, error: err } = await listPlaetze()
    setPlatzLoading(false)
    if (err || !data) {
      setError(err ?? 'Plätze konnten nicht geladen werden.')
      return
    }
    setPlaetze(data.frei)
    setBelegtePlaetze(data.belegt)
  }

  // Beendet die aktive Zuweisung eines Platzes (platz_release). Danach neu
  // laden — der Platz erscheint wieder unter „Freien Platz wählen".
  const release = async (platz: PlatzBelegt): Promise<void> => {
    setReleasingId(platz.assignment_id)
    setError(null)
    const { error: err } = await releasePlatz(platz.assignment_id)
    setReleasingId(null)
    setConfirmReleaseId(null)
    if (err) {
      setError(err)
      return
    }
    // War es der gerade zugewiesene Platz, fällt die Erfolgs-Ansicht weg.
    if (assignedPlatz?.assignment_id === platz.assignment_id) setAssignedPlatz(null)
    await loadPlaetze()
    onRefresh()
  }

  // Bereits freigegebenen Lead weiterpflegen: offene Session laden, damit die
  // Platz-Zuweisung ohne erneute Freigabe möglich ist.
  useEffect(() => {
    if (!existingLead) return
    if (existingLead.status !== 'lsa_freigegeben') return
    void getOpenSessionForLead(existingLead.id).then(({ data }) => {
      if (data) {
        setSession({ session_id: data.session_id, total_items: data.total_items })
        void loadPlaetze()
      }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [existingLead])

  const persistLead = async (): Promise<string | null> => {
    if (form.full_name.trim() === '') {
      setError('Vollständiger Name ist erforderlich.')
      return null
    }
    setBusy(true)
    setError(null)
    const payload = intakeToLeadInput(form)
    if (leadId) {
      const { error: err } = await updateLead(leadId, payload)
      setBusy(false)
      if (err) {
        setError(err)
        return null
      }
      return leadId
    }
    const { data, error: err } = await createLead(payload)
    setBusy(false)
    if (err || !data) {
      setError(err ?? 'Lead konnte nicht angelegt werden.')
      return null
    }
    setLeadId(data.id)
    onRefresh()
    return data.id
  }

  const nextFromStep1 = async (): Promise<void> => {
    const id = await persistLead()
    if (id) setStep(1)
  }

  const nextFromStep2 = async (): Promise<void> => {
    const id = await persistLead()
    if (!id) return
    // Eltern-Einschätzung — Gesprächskontext, nie Auswertungs-Input (A3).
    if (form.parent_weak_topics.length > 0 || form.parent_note.trim() !== '') {
      const { error: err } = await leadAssessmentUpsert(
        id,
        'parent',
        form.parent_note.trim() || null,
        form.parent_weak_topics,
      )
      if (err) {
        setError(err)
        return
      }
    }
    setStep(2)
  }

  const confirmConsent = async (): Promise<void> => {
    if (!leadId || !user) return
    setConfirmingConsent(true)
    setError(null)
    const { data, error: err } = await setLeadConsent(leadId, user.id)
    setConfirmingConsent(false)
    if (err) {
      setError(err)
      return
    }
    setConsentAt(data?.consent_dsgvo_at ?? new Date().toISOString())
    onRefresh()
  }

  const freigeben = async (): Promise<void> => {
    if (!leadId || form.class_level === null || !subjectForFreigabe) return
    setFreigebenLoading(true)
    setError(null)
    const { data, error: err } = await leadLsaFreigeben(
      leadId,
      form.class_level,
      subjectForFreigabe,
    )
    setFreigebenLoading(false)
    if (err || !data) {
      setError(err ?? 'LSA-Freigabe fehlgeschlagen.')
      return
    }
    setSession({ session_id: data.session_id, total_items: data.total_items })
    onRefresh()
    void loadPlaetze()
  }

  const assign = async (platzProfileId: string): Promise<void> => {
    if (!session) return
    setAssigningId(platzProfileId)
    setError(null)
    const { data, error: err } = await assignPlatz(platzProfileId, session.session_id)
    setAssigningId(null)
    if (err || !data) {
      setError(err ?? 'Platz-Zuweisung fehlgeschlagen.')
      return
    }
    const label = (plaetze ?? []).find((p) => p.profile_id === platzProfileId)?.label ?? 'Platz'
    setAssignedPlatz({
      label,
      expires_at: data.expires_at,
      assignment_id: data.assignment_id,
    })
    await loadPlaetze()
    onRefresh()
  }

  const canLeaveStep1 = form.full_name.trim() !== ''

  return (
    <EdvanceCard className="flex flex-col gap-6 p-6">
      <div className="flex items-start justify-between gap-4">
        <div className="flex flex-col gap-1">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {existingLead ? 'Lead weiterpflegen' : 'Neuer Lead — Erstgespräch'}
          </p>
          <h2 className="text-2xl font-bold text-[var(--color-text-primary)]">
            {form.first_name.trim() || form.full_name.trim() || 'Empfang'}
          </h2>
        </div>
        <button
          type="button"
          onClick={onClose}
          aria-label="Schließen"
          className="rounded-full p-2 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-surface)]"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      {/* Stepper */}
      <div className="flex gap-2">
        {STEPS.map((label, index) => {
          const reachable = index === 0 || leadId !== null
          const active = index === step
          return (
            <button
              key={label}
              type="button"
              disabled={!reachable}
              onClick={() => setStep(index)}
              className={`flex-1 rounded-xl border px-3 py-2 text-sm font-medium transition-colors ${
                active
                  ? 'border-[var(--color-primary)] bg-[color-mix(in_srgb,var(--color-primary)_10%,transparent)] text-[var(--color-text-primary)]'
                  : reachable
                    ? 'border-[var(--color-border)] text-[var(--color-text-secondary)]'
                    : 'border-[var(--color-border)] text-[var(--color-text-tertiary)] opacity-50'
              }`}
            >
              {index + 1}. {label}
            </button>
          )
        })}
      </div>

      {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

      {step === 0 && <SectionLead form={form} patch={patch} />}
      {step === 1 && <SectionErstgespraech form={form} patch={patch} />}
      {step === 2 && (
        <SectionFreigabePlatz
          form={form}
          consentGiven={consentAt !== null}
          confirmingConsent={confirmingConsent}
          onConfirmConsent={confirmConsent}
          selectedSubject={subjectForFreigabe}
          onSelectSubject={setSelectedSubject}
          onFreigeben={freigeben}
          freigebenLoading={freigebenLoading}
          session={session}
          plaetze={plaetze}
          belegtePlaetze={belegtePlaetze}
          platzLoading={platzLoading}
          assigningId={assigningId}
          releasingId={releasingId}
          confirmReleaseId={confirmReleaseId}
          assignedPlatz={assignedPlatz}
          onAssignPlatz={assign}
          onConfirmRelease={setConfirmReleaseId}
          onReleasePlatz={release}
        />
      )}

      {/* Navigation */}
      <div className="flex items-center justify-between gap-2">
        <Button variant="outline" onClick={onClose}>
          {assignedPlatz ? 'Fertig' : 'Schließen'}
        </Button>
        {step === 0 && (
          <Button onClick={nextFromStep1} disabled={busy || !canLeaveStep1}>
            {busy ? 'Speichert …' : leadId ? 'Speichern & weiter' : 'Lead anlegen & weiter'}
          </Button>
        )}
        {step === 1 && (
          <Button onClick={nextFromStep2} disabled={busy}>
            {busy ? 'Speichert …' : 'Speichern & weiter'}
          </Button>
        )}
      </div>
    </EdvanceCard>
  )
}
