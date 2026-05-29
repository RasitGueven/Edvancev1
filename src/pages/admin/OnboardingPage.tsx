import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Check, ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EdvanceCard } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { CoachStep } from '@/components/edvance/onboarding/CoachStep'
import { EMPTY_FORM, STEP_LABELS } from '@/components/edvance/onboarding/constants'
import { StepIndicator } from '@/components/edvance/onboarding/StepIndicator'
import { StudentDataStep } from '@/components/edvance/onboarding/StudentDataStep'
import { SubjectsStep } from '@/components/edvance/onboarding/SubjectsStep'
import { SummaryStep } from '@/components/edvance/onboarding/SummaryStep'
import { TierStep } from '@/components/edvance/onboarding/TierStep'
import { canProceed } from '@/components/edvance/onboarding/validation'
import { getCoaches } from '@/lib/supabase/profiles'
import { listTiers } from '@/lib/supabase/subscriptions'
import { provisionStudent } from '@/lib/supabase/provision'
import type { Coach, OnboardingFormData, SchoolKind, TierPlan } from '@/types'

const STEP_DATA = 0
const STEP_SUBJECTS = 1
const STEP_TIER = 2
const STEP_COACH = 3
const STEP_SUMMARY = 4

type StepRendererProps = {
  step: number
  data: OnboardingFormData
  setData: (next: OnboardingFormData) => void
  coaches: Coach[]
  coachesLoading: boolean
  tiers: TierPlan[]
  tiersLoading: boolean
}

function StepRenderer({
  step,
  data,
  setData,
  coaches,
  coachesLoading,
  tiers,
  tiersLoading,
}: StepRendererProps): JSX.Element | null {
  if (step === STEP_DATA) return <StudentDataStep data={data} setData={setData} />
  if (step === STEP_SUBJECTS) return <SubjectsStep data={data} setData={setData} />
  if (step === STEP_TIER)
    return <TierStep data={data} setData={setData} tiers={tiers} loading={tiersLoading} />
  if (step === STEP_COACH)
    return <CoachStep data={data} setData={setData} coaches={coaches} loading={coachesLoading} />
  if (step === STEP_SUMMARY) return <SummaryStep data={data} coaches={coaches} />
  return null
}

type SuccessStateProps = {
  data: OnboardingFormData
  coaches: Coach[]
  onReset: () => void
}

function SuccessState({ data, coaches, onReset }: SuccessStateProps): JSX.Element {
  const coachName = coaches.find((entry) => entry.id === data.coachId)?.full_name
  return (
    <EdvanceCard variant="hero-student">
      <div className="flex flex-col items-center gap-5 py-6 text-center">
        <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[color-mix(in_srgb,var(--color-success)_15%,transparent)]">
          <Check className="h-10 w-10 text-white" />
        </div>
        <div className="flex flex-col gap-2">
          <p className="text-2xl font-bold">Schüler angelegt!</p>
          <p className="text-sm opacity-80">
            {data.firstName} {data.lastName} wurde eingetragen
            {coachName ? ` und ${coachName} zugewiesen` : ''}.
          </p>
        </div>
        <Button
          onClick={onReset}
          className="mt-2 border-0 bg-white/20 text-white hover:bg-white/30"
        >
          Weiteren Schüler anlegen
        </Button>
      </div>
    </EdvanceCard>
  )
}

export function OnboardingPage(): JSX.Element {
  const [step, setStep] = useState<number>(STEP_DATA)
  const [data, setData] = useState<OnboardingFormData>(EMPTY_FORM)
  const [done, setDone] = useState<boolean>(false)
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [coachesLoading, setCoachesLoading] = useState<boolean>(true)
  const [tiers, setTiers] = useState<TierPlan[]>([])
  const [tiersLoading, setTiersLoading] = useState<boolean>(true)
  const [submitting, setSubmitting] = useState<boolean>(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    getCoaches().then(({ data: list }) => {
      if (!active) return
      setCoaches(list ?? [])
      setCoachesLoading(false)
    })
    listTiers().then(({ data: list }) => {
      if (!active) return
      setTiers(list ?? [])
      setTiersLoading(false)
    })
    return () => {
      active = false
    }
  }, [])

  const isLast = step === STEP_LABELS.length - 1

  const handleNext = async (): Promise<void> => {
    if (!isLast) {
      setStep((current) => current + 1)
      return
    }
    setSubmitting(true)
    setSubmitError(null)
    const tierId = tiers.find((t) => t.name === data.tier)?.id ?? null
    const { error } = await provisionStudent({
      full_name: `${data.firstName} ${data.lastName}`.trim(),
      parent_email: data.email || null,
      class_level: data.classLevel ? Number(data.classLevel) : null,
      school_type: data.schoolType ? (data.schoolType as SchoolKind) : null,
      school_name: data.schoolName || null,
      subjects: data.subjects,
      coach_id: data.coachId || null,
      tier_id: tierId,
      lead_id: null,
    })
    setSubmitting(false)
    if (error) {
      setSubmitError(error)
      return
    }
    setDone(true)
  }

  const handleBack = (): void => setStep((current) => current - 1)

  const handleReset = (): void => {
    setData(EMPTY_FORM)
    setStep(STEP_DATA)
    setDone(false)
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Admin · Schüler-Onboarding" />

      {/* Ambient background blobs */}
      <div aria-hidden="true" className="pointer-events-none absolute -right-24 top-1/4 h-80 w-80 rounded-full opacity-[0.07] blur-3xl bg-[var(--color-accent)]" />
      <div aria-hidden="true" className="pointer-events-none absolute -left-16 bottom-1/3 h-64 w-64 rounded-full opacity-[0.06] blur-3xl bg-[var(--color-primary)]" />

      {/* Hero header band */}
      <div className="student-hero">
        <div className="mx-auto max-w-2xl px-4 py-6 text-white">
          <p className="text-xs font-semibold uppercase tracking-widest opacity-70">
            Admin · Schüler-Onboarding
          </p>
          <h1 className="mt-1 text-2xl font-bold">
            {done ? 'Schüler angelegt ✓' : STEP_LABELS[step]}
          </h1>
          {!done && (
            <p className="mt-1 text-sm opacity-70">
              Schritt {step + 1} von {STEP_LABELS.length}
            </p>
          )}
        </div>
      </div>
      <div
        aria-hidden="true"
        className="h-6 bg-gradient-to-b from-[var(--color-primary)] to-[var(--color-bg-app)] opacity-20"
      />

      <main className="mx-auto max-w-2xl px-4 pb-12 pt-4">
        <Link
          to="/admin"
          className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-[var(--color-primary)] hover:underline"
        >
          <ChevronLeft className="h-4 w-4" /> Zurück zum Dashboard
        </Link>

        {done ? (
          <SuccessState data={data} coaches={coaches} onReset={handleReset} />
        ) : (
          <EdvanceCard className="overflow-hidden p-0">
            {/* Colored card header accent */}
            <div
              className="px-6 py-4 text-white"
              style={{
                background: 'linear-gradient(90deg, var(--color-primary) 0%, var(--color-primary) 100%)',
              }}
            >
              <p className="text-xs font-semibold uppercase tracking-widest opacity-70">
                Schritt {step + 1} · {STEP_LABELS[step]}
              </p>
            </div>

            <div className="px-6 pb-6 pt-5">
              <StepIndicator current={step} />
              <StepRenderer
                step={step}
                data={data}
                setData={setData}
                coaches={coaches}
                coachesLoading={coachesLoading}
                tiers={tiers}
                tiersLoading={tiersLoading}
              />

              {submitError && (
                <p className="mt-4 text-sm text-[var(--color-error-exam)]">{submitError}</p>
              )}

              <div className="mt-8 flex items-center justify-between">
                <Button
                  variant="outline"
                  onClick={handleBack}
                  disabled={step === STEP_DATA || submitting}
                >
                  Zurück
                </Button>
                <Button
                  onClick={handleNext}
                  disabled={!canProceed(step, data) || submitting}
                >
                  {isLast ? (
                    submitting ? 'Legt an …' : 'Jetzt anlegen'
                  ) : (
                    <span className="flex items-center gap-1.5">
                      Weiter <ChevronRight className="h-4 w-4" />
                    </span>
                  )}
                </Button>
              </div>
            </div>
          </EdvanceCard>
        )}
      </main>
    </div>
  )
}
