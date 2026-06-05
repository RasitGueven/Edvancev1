import { useState, type JSX, type ReactNode } from 'react'
import { AlertCircle, CheckCircle2, ChevronRight, Lightbulb } from 'lucide-react'
import { MathContent } from '@/lib/render/MathContent'
import type { Task } from '@/types'

type Accent = 'primary' | 'success' | 'warning'

const ACCENT_STYLES: Record<Accent, { bg: string; text: string }> = {
  primary: { bg: 'var(--color-primary-light)', text: 'var(--color-primary)' },
  success: { bg: 'var(--color-success-light)', text: 'var(--color-success)' },
  warning: { bg: 'var(--color-gold-warning-light)', text: 'var(--color-gold-warning)' },
}

function Section({
  icon,
  title,
  accent,
  defaultOpen = false,
  children,
}: {
  icon: ReactNode
  title: string
  accent: Accent
  defaultOpen?: boolean
  children: ReactNode
}): JSX.Element {
  const [open, setOpen] = useState(defaultOpen)
  const a = ACCENT_STYLES[accent]
  return (
    <div className="rounded-[var(--radius-md)] border border-[var(--color-border)] overflow-hidden">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between gap-3 px-4 py-3 transition-colors"
        style={{ backgroundColor: open ? a.bg : 'var(--color-bg-surface)' }}
        aria-expanded={open}
      >
        <span className="inline-flex items-center gap-2">
          <span style={{ color: a.text }}>{icon}</span>
          <span className="text-sm font-semibold" style={{ color: a.text }}>
            {title}
          </span>
        </span>
        <ChevronRight
          className={`h-4 w-4 transition-transform ${open ? 'rotate-90' : 'rotate-0'}`}
          style={{ color: a.text }}
        />
      </button>
      {open && (
        <div className="border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4">{children}</div>
      )}
    </div>
  )
}

export function TaskPedagogyAccordion({ task }: { task: Task }): JSX.Element | null {
  const hasHint = !!task.hint
  const hasSolution = !!task.solution
  const hasErrors = !!task.common_errors || (task.typical_errors?.length ?? 0) > 0
  if (!hasHint && !hasSolution && !hasErrors) return null
  return (
    <div className="flex flex-col gap-2">
      {hasHint && (
        <Section icon={<Lightbulb className="h-4 w-4" />} title="Hinweis" accent="primary">
          <MathContent text={task.hint} />
        </Section>
      )}
      {hasSolution && (
        <Section icon={<CheckCircle2 className="h-4 w-4" />} title="Lösung" accent="success">
          <MathContent text={task.solution} />
        </Section>
      )}
      {hasErrors && (
        <Section
          icon={<AlertCircle className="h-4 w-4" />}
          title="Typische Fehler"
          accent="warning"
        >
          {task.common_errors && (
            <div className="mb-3">
              <MathContent text={task.common_errors} />
            </div>
          )}
          {task.typical_errors && task.typical_errors.length > 0 && (
            <ul className="list-disc space-y-1 pl-5 text-sm text-[var(--color-text-secondary)]">
              {task.typical_errors.map((err, i) => (
                <li key={i}>{err}</li>
              ))}
            </ul>
          )}
        </Section>
      )}
    </div>
  )
}
