import { Check } from 'lucide-react'
import { MAX_SUBJECTS_PER_STUDENT, SUBJECTS } from '@/components/edvance/onboarding/constants'
import type { StepProps } from '@/types'

const SELECTED_BG = 'color-mix(in srgb, var(--primary) 8%, transparent)'

export function SubjectsStep({ data, setData }: StepProps): JSX.Element {
  const toggleSubject = (subject: string): void => {
    const alreadySelected = data.subjects.includes(subject)
    if (alreadySelected) {
      setData({ ...data, subjects: data.subjects.filter((entry) => entry !== subject) })
      return
    }
    if (data.subjects.length < MAX_SUBJECTS_PER_STUDENT) {
      setData({ ...data, subjects: [...data.subjects, subject] })
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">Maximal {MAX_SUBJECTS_PER_STUDENT} Fächer wählbar (MVP).</p>
      <div className="flex flex-col gap-3">
        {SUBJECTS.map((subject) => {
          const selected = data.subjects.includes(subject)
          const disabled = !selected && data.subjects.length >= MAX_SUBJECTS_PER_STUDENT
          return (
            <button
              key={subject}
              type="button"
              disabled={disabled}
              onClick={() => toggleSubject(subject)}
              className="flex items-center justify-between rounded-xl border px-5 py-4 text-left transition-all"
              style={{
                borderColor: selected ? 'var(--primary)' : 'var(--border)',
                background: selected ? SELECTED_BG : 'var(--card)',
                opacity: disabled ? 0.4 : 1,
                cursor: disabled ? 'not-allowed' : 'pointer',
              }}
            >
              <span className="font-medium text-foreground">{subject}</span>
              {selected && (
                <span className="flex h-6 w-6 items-center justify-center rounded-full bg-[var(--primary)]">
                  <Check className="h-3.5 w-3.5 text-white" />
                </span>
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}
