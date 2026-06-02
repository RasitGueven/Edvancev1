import { Check } from 'lucide-react'
import { STEP_LABELS } from '@/components/edvance/onboarding/constants'
import type { StepIndicatorProps } from '@/types'

const ACTIVE_BG = 'linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-hover) 100%)'

function stepBackground(done: boolean, active: boolean): string {
  if (done) return 'var(--color-success)'
  if (active) return ACTIVE_BG
  return 'var(--color-border)'
}

function stepLabelColor(done: boolean, active: boolean): string {
  if (active) return 'var(--color-primary)'
  if (done) return 'var(--color-success)'
  return 'var(--muted)'
}

export function StepIndicator({ current }: StepIndicatorProps): JSX.Element {
  return (
    <div className="mb-8">
      <div className="flex items-center justify-center gap-0">
        {STEP_LABELS.map((label, index) => {
          const done = index < current
          const active = index === current
          return (
            <div key={label} className="flex items-center">
              <div className="flex flex-col items-center">
                <div
                  className={`flex items-center justify-center rounded-full text-sm font-semibold transition-all duration-300 ${active ? 'h-10 w-10' : 'h-9 w-9'}`}
                  style={{
                    background: stepBackground(done, active),
                    color: done || active ? 'white' : 'var(--muted)',
                  }}
                >
                  {done ? <Check className="h-4 w-4" /> : index + 1}
                </div>
                <span
                  className="mt-1 block text-[10px] font-medium"
                  style={{ color: stepLabelColor(done, active) }}
                >
                  {label}
                </span>
              </div>
              {index < STEP_LABELS.length - 1 && (
                <div
                  className="mx-1 mb-4 h-1 w-10 transition-all duration-500 sm:w-14"
                  style={{ background: done ? 'var(--color-success)' : 'var(--color-border)' }}
                />
              )}
            </div>
          )
        })}
      </div>

      {/* Overall progress bar */}
      <div className="mt-4 h-1.5 w-full overflow-hidden rounded-full bg-[var(--color-border)]">
        <div
          className="h-full rounded-full bg-[var(--color-primary)] transition-all duration-500"
          style={{ width: `${Math.round(((current + 1) / STEP_LABELS.length) * 100)}%` }}
        />
      </div>
    </div>
  )
}
