import type { Coach, OnboardingFormData, SummaryStepProps } from '@/types'

const PLACEHOLDER_DASH = '–'

function buildRows(data: OnboardingFormData, coaches: Coach[]): Array<[string, string]> {
  const coach = coaches.find((entry) => entry.id === data.coachId)
  return [
    ['Name', `${data.firstName} ${data.lastName}`],
    ['E-Mail', data.email || PLACEHOLDER_DASH],
    ['Klasse', data.classLevel ? `${data.classLevel}. Klasse` : PLACEHOLDER_DASH],
    ['Schultyp', data.schoolType || PLACEHOLDER_DASH],
    ['Schule', data.schoolName || PLACEHOLDER_DASH],
    ['Fächer', data.subjects.length ? data.subjects.join(', ') : PLACEHOLDER_DASH],
    ['Tarif', data.tier || PLACEHOLDER_DASH],
    ['Coach', coach?.full_name ?? PLACEHOLDER_DASH],
  ]
}

export function SummaryStep({ data, coaches }: SummaryStepProps): JSX.Element {
  const rows = buildRows(data, coaches)

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-xl p-4 text-sm bg-[color-mix(in_srgb,var(--color-success)_10%,transparent)] border border-[color-mix(in_srgb,var(--color-success)_30%,transparent)]">
        <p className="font-semibold text-success">Alles bereit zum Anlegen</p>
        <p className="mt-0.5 text-muted">Bitte prüfe die Angaben und bestätige das Onboarding.</p>
      </div>
      <div className="rounded-xl border border-border overflow-hidden">
        {rows.map(([label, value]) => (
          <div
            key={label}
            className="flex items-center justify-between px-4 py-3 text-sm odd:bg-[var(--color-bg-surface)] even:bg-[color-mix(in_srgb,var(--muted)_5%,transparent)]"
          >
            <span className="text-muted font-medium w-28 shrink-0">{label}</span>
            <span className="text-foreground font-semibold text-right">{value}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
