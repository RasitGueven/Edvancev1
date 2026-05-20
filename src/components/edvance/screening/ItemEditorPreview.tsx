import { EdvanceBadge } from '@/components/edvance'
import type { ScreeningAfb, ScreeningInputType, ScreeningPhase } from '@/types'

export function ItemEditorPreview({
  prompt,
  inputType,
  payload,
  afb,
  phase,
}: {
  prompt: string
  inputType: ScreeningInputType
  payload: unknown
  afb: ScreeningAfb | null
  phase: ScreeningPhase | null
}): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        Live-Vorschau (so sieht das Kind es)
      </span>
      <div className="flex flex-col gap-4 rounded-[var(--radius-xl)] border border-[var(--border)] bg-[var(--card)] p-5">
        <div className="flex flex-wrap gap-2">
          {afb && <EdvanceBadge variant="primary">AFB {afb}</EdvanceBadge>}
          {phase && <EdvanceBadge variant="muted">{phase}</EdvanceBadge>}
          <EdvanceBadge variant="muted">{inputType}</EdvanceBadge>
        </div>
        <p className="whitespace-pre-wrap text-base font-semibold text-[var(--text-primary)]">
          {prompt || <span className="text-[var(--text-muted)]">— Frage —</span>}
        </p>
        <PreviewInput inputType={inputType} payload={payload} />
      </div>
    </div>
  )
}

function PreviewInput({
  inputType,
  payload,
}: {
  inputType: ScreeningInputType
  payload: unknown
}): JSX.Element {
  if (inputType === 'MC') {
    const opts = readArray(payload, 'options')
    if (opts.length === 0) return <Hint>options[] in payload setzen.</Hint>
    return (
      <div className="flex flex-col gap-2">
        {opts.map((o, i) => (
          <div
            key={i}
            className="rounded-xl border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-sm"
          >
            {String(o)}
          </div>
        ))}
      </div>
    )
  }
  if (inputType === 'NUMERIC' || inputType === 'STEPS_FINAL') {
    return (
      <input
        disabled
        placeholder="Antwort eingeben…"
        className="h-12 w-full rounded-xl border border-[var(--border)] bg-[var(--surface)] px-3 text-sm"
      />
    )
  }
  if (inputType === 'OPEN') {
    return (
      <textarea
        disabled
        placeholder="Erklärung tippen…"
        className="min-h-[120px] w-full rounded-xl border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-sm"
      />
    )
  }
  if (inputType === 'MATCHING') {
    const left = readArray(payload, 'left')
    const right = readArray(payload, 'right')
    if (left.length === 0 || right.length === 0)
      return <Hint>left[] und right[] in payload setzen.</Hint>
    return (
      <div className="grid grid-cols-2 gap-2 text-sm">
        <Column items={left} />
        <Column items={right} />
      </div>
    )
  }
  return <Hint>Kein Renderer für diesen input_type.</Hint>
}

function Column({ items }: { items: unknown[] }): JSX.Element {
  return (
    <div className="flex flex-col gap-1">
      {items.map((v, i) => (
        <div
          key={i}
          className="rounded-xl border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
        >
          {String(v)}
        </div>
      ))}
    </div>
  )
}

function Hint({ children }: { children: React.ReactNode }): JSX.Element {
  return <p className="text-xs italic text-[var(--text-muted)]">{children}</p>
}

function readArray(payload: unknown, key: string): unknown[] {
  if (!payload || typeof payload !== 'object') return []
  const v = (payload as Record<string, unknown>)[key]
  return Array.isArray(v) ? v : []
}
