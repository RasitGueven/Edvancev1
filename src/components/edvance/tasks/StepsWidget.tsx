import type { ChangeEvent, JSX } from 'react'

type Step = { prompt: string; placeholder?: string }

type Props = {
  steps: Step[]
  answers: string[]
  onChange: (answers: string[]) => void
  disabled: boolean
}

export function StepsWidget({ steps, answers, onChange, disabled }: Props): JSX.Element {
  function update(i: number, val: string) {
    const next = [...answers]
    next[i] = val
    onChange(next)
  }

  return (
    <div className="flex flex-col gap-5">
      {steps.map((step, i) => (
        <div key={i} className="flex gap-3">
          <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white bg-[var(--primary)]">
            {i + 1}
          </span>
          <div className="flex flex-1 flex-col gap-1.5">
            <p className="text-sm font-medium leading-snug text-foreground">{step.prompt}</p>
            <input
              type="text"
              value={answers[i] ?? ''}
              onChange={(e: ChangeEvent<HTMLInputElement>) => update(i, e.target.value)}
              placeholder={step.placeholder ?? 'Lösung …'}
              disabled={disabled}
              className="w-full rounded-xl border-2 border-[var(--border)] bg-card px-3 py-2.5 text-sm focus:border-[var(--primary)] focus:outline-none disabled:opacity-60"
            />
          </div>
        </div>
      ))}
    </div>
  )
}
