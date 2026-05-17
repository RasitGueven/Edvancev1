import type { Coach, OnboardingFormData, SummaryStepProps } from '@/types'

const PLACEHOLDER_DASH = '–'
const SUCCESS_BG = 'color-mix(in srgb, var(--success) 10%, transparent)'
const SUCCESS_BORDER = '1px solid color-mix(in srgb, var(--success) 30%, transparent)'
const ROW_ALT_BG = 'color-mix(in srgb, var(--muted) 5%, transparent)'

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
      <div className="rounded-xl p-4 text-sm" style={{ background: SUCCESS_BG, border: SUCCESS_BORDER }}>
        <p className="font-semibold text-success">Alles bereit zum Anlegen</p>
        <p className="mt-0.5 text-muted">Bitte prüfe die Angaben und bestätige das Onboarding.</p>
      </div>
      <div className="rounded-xl border border-border overflow-hidden">
        {rows.map(([label, value], index) => (
          <div
            key={label}
            className="flex items-center justify-between px-4 py-3 text-sm"
            style={{ background: index % 2 === 0 ? 'var(--card)' : ROW_ALT_BG }}
          >
            <span className="text-muted font-medium w-28 shrink-0">{label}</span>
            <span className="text-foreground font-semibold text-right">{value}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
