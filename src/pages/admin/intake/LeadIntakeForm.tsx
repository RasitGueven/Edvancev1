import { useState } from 'react'
import { X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EdvanceCard } from '@/components/edvance'
import { useAuthContext } from '@/context/AuthContext'
import { createLead, setLeadConsent, updateLead } from '@/lib/supabase/leads'
import { leadAssessmentUpsert, leadLsaFreigeben } from '@/lib/supabase/leadLsa'
import type { Lead } from '@/types'
import { SectionLead } from './SectionLead'
import { SectionErstgespraech } from './SectionErstgespraech'
import { CONSENT_DOCUMENT_VERSION } from './consentDocument'
import type { ConsentState } from './ConsentBlock'
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

const STEPS = ['Stammdaten', 'Erstgespräch'] as const

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
  const [consent, setConsent] = useState<ConsentState>({
    at: existingLead?.consent_dsgvo_at ?? null,
    by: existingLead?.consent_dsgvo_by ?? null,
    signature: existingLead?.consent_dsgvo_signature ?? null,
  })
  const [selectedSubject, setSelectedSubject] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [consentSaving, setConsentSaving] = useState(false)
  const [freigebenLoading, setFreigebenLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const patch = (next: Partial<IntakeFormState>): void => setForm((f) => ({ ...f, ...next }))

  // Bei genau einem Fach ist die Wahl eindeutig, sonst entscheidet der Block
  // am Ende von Schritt 2.
  const subject = form.subjects.length === 1 ? form.subjects[0] : selectedSubject

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
      onRefresh()
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

  // Ein Speicherpfad, zwei Ausgaenge: entweder weiter zu Schritt 2 oder das
  // Panel schliessen — der Lead steht dann in der Liste und ist von dort
  // wieder aufklappbar. Leads entstehen meist vor dem Erstgespraech.
  const submitStep1 = async (andThen: 'continue' | 'close'): Promise<void> => {
    const id = await persistLead()
    if (!id) return
    if (andThen === 'continue') setStep(1)
    else onClose()
  }

  const sign = async (signature: string): Promise<void> => {
    if (!leadId || !user) return
    setConsentSaving(true)
    setError(null)
    const { data, error: err } = await setLeadConsent(
      leadId,
      user.id,
      signature,
      CONSENT_DOCUMENT_VERSION,
    )
    setConsentSaving(false)
    if (err) {
      setError(err)
      return
    }
    setConsent({
      at: data?.consent_dsgvo_at ?? new Date().toISOString(),
      by: data?.consent_dsgvo_by ?? user.id,
      signature: data?.consent_dsgvo_signature ?? signature,
    })
    onRefresh()
  }

  // Abschlussaktion: Schritt 2 sichern, Eltern-Einschaetzung ablegen, dann die
  // LSA freigeben. Den Status setzt die RPC, nicht der Client.
  const freigeben = async (): Promise<void> => {
    if (form.class_level === null || subject === null) return
    const id = await persistLead()
    if (!id) return
    // Eltern-Einschaetzung — Gespraechskontext, nie Auswertungs-Input (A3).
    if (form.parent_weak_topics.length > 0 || form.parent_note.trim() !== '') {
      const { error: aErr } = await leadAssessmentUpsert(
        id,
        'parent',
        form.parent_note.trim() || null,
        form.parent_weak_topics,
      )
      if (aErr) {
        setError(aErr)
        return
      }
    }
    setFreigebenLoading(true)
    const { error: err } = await leadLsaFreigeben(id, form.class_level, subject)
    setFreigebenLoading(false)
    if (err) {
      setError(err ?? 'LSA-Freigabe fehlgeschlagen.')
      return
    }
    onRefresh()
    onClose()
  }

  const canLeaveStep1 =
    form.first_name.trim() !== '' &&
    form.full_name.trim() !== '' &&
    (form.contact_email.trim() !== '' || form.contact_phone.trim() !== '')

  const canFreigeben =
    form.class_level !== null &&
    subject !== null &&
    form.current_topic_cluster_id !== null &&
    consent.at !== null

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
      {step === 1 && (
        <SectionErstgespraech
          form={form}
          patch={patch}
          subject={subject}
          onSelectSubject={setSelectedSubject}
          consent={consent}
          consentSaving={consentSaving}
          onSign={sign}
          consentByLabel={consent.by === user?.id ? (user?.email ?? null) : null}
          consentDisabled={leadId === null}
        />
      )}

      {/* Navigation — Abbrechen laeuft ueber das × oben rechts. */}
      <div className="flex flex-wrap items-center justify-end gap-2">
        {step === 0 && (
          <>
            <Button
              variant="outline"
              onClick={() => void submitStep1('continue')}
              disabled={busy || !canLeaveStep1}
            >
              Weiter zum Erstgespräch
            </Button>
            <Button
              onClick={() => void submitStep1('close')}
              disabled={busy || !canLeaveStep1}
            >
              {busy ? 'Speichert …' : 'Speichern'}
            </Button>
          </>
        )}
        {step === 1 && (
          <Button onClick={freigeben} disabled={busy || freigebenLoading || !canFreigeben}>
            {freigebenLoading ? 'Gibt frei …' : 'Für die LSA freigeben'}
          </Button>
        )}
      </div>
    </EdvanceCard>
  )
}
