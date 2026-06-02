import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import type { FormState } from './state'
import type { ScreeningTeilaufgabe } from '@/types'

type Mode = 'student' | 'coach'

export function LivePreview({ state }: { state: FormState }): JSX.Element {
  const { t } = useTranslation('screening-editor')
  const [mode, setMode] = useState<Mode>('student')
  const [revealed, setRevealed] = useState<Record<string, number>>({})

  const payload = useMemo<unknown>(() => {
    try {
      return state.payloadStr.trim() === '' ? null : JSON.parse(state.payloadStr)
    } catch {
      return null
    }
  }, [state.payloadStr])

  const reveal = (key: string): void =>
    setRevealed((r) => ({ ...r, [key]: (r[key] ?? 0) + 1 }))

  const hasTeil = state.teilaufgaben.length > 0

  return (
    <div className="flex flex-col gap-3">
      <div className="sticky top-0 z-10 -mx-2 flex items-center gap-2 bg-[var(--color-bg-app)] px-2 py-2">
        <h3 className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('sections.preview')}
        </h3>
        <div className="ml-auto inline-flex rounded-lg border border-[var(--color-border)] p-0.5">
          {(['student', 'coach'] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMode(m)}
              className={`rounded-md px-2.5 py-1 text-xs font-semibold ${
                mode === m
                  ? 'bg-[var(--color-primary)] text-white'
                  : 'text-[var(--color-text-secondary)]'
              }`}
            >
              {m === 'student' ? `👤 ${t('preview.student')}` : `🎓 ${t('preview.coach')}`}
            </button>
          ))}
        </div>
      </div>

      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-5 shadow-card">
        <div className="mb-3 flex flex-wrap gap-1.5">
          <EdvanceBadge variant="primary">{state.usage}</EdvanceBadge>
          <EdvanceBadge variant="muted">{state.input_type}</EdvanceBadge>
          {state.afb && <EdvanceBadge>AFB {state.afb}</EdvanceBadge>}
          {hasTeil && (
            <EdvanceBadge variant="warning">
              {state.teilaufgaben.map((tt) => tt.key).join('+')}
            </EdvanceBadge>
          )}
        </div>
        {state.kontext.trim() !== '' && (
          <div className="mb-3 rounded-r-xl border-l-[3px] border-[var(--color-primary)] bg-[var(--color-bg-subtle)] px-3 py-2 text-sm leading-relaxed text-[var(--color-text-secondary)] whitespace-pre-wrap">
            {state.kontext}
          </div>
        )}
        <p className="whitespace-pre-wrap text-base font-medium leading-relaxed text-[var(--color-text-primary)]">
          {state.prompt || (
            <em className="text-[var(--color-text-tertiary)]">{t('preview.promptMissing')}</em>
          )}
        </p>

        {!hasTeil && (
          <PreviewWidget input_type={state.input_type} payload={payload} mode={mode} />
        )}

        <HintBlock
          hint1={state.hint1}
          hint2={state.hint2}
          revealed={revealed['__main__'] ?? 0}
          onReveal={() => reveal('__main__')}
          mode={mode}
          label={(n) => t('hint.show', { n })}
        />

        {mode === 'coach' && (
          <CoachBoxes
            explanation={state.explanation}
            typical={state.typical}
          />
        )}

        {hasTeil &&
          state.teilaufgaben.map((tt, idx) => (
            <SubCard
              key={idx}
              item={tt}
              hintReveal={revealed[`teil-${idx}`] ?? 0}
              onReveal={() => reveal(`teil-${idx}`)}
              mode={mode}
            />
          ))}
      </div>
    </div>
  )
}

function PreviewWidget({
  input_type,
  payload,
  mode,
}: {
  input_type: FormState['input_type']
  payload: unknown
  mode: Mode
}): JSX.Element | null {
  if (input_type === 'MC') {
    const options = readOptions(payload)
    return (
      <div className="mt-4 grid gap-2">
        {options.map((o, i) => (
          <div
            key={i}
            className={`flex items-center gap-3 rounded-xl border-2 px-4 py-3 text-sm font-medium ${
              mode === 'coach' && o.correct
                ? 'border-[var(--color-success)] bg-[var(--color-success)]/10'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
            }`}
          >
            <span
              className={`grid h-6 w-6 place-items-center rounded-full text-xs font-bold ${
                mode === 'coach' && o.correct
                  ? 'bg-[var(--color-success)] text-white'
                  : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]'
              }`}
            >
              {String.fromCharCode(65 + i)}
            </span>
            <span>{o.text || <em className="text-[var(--color-text-tertiary)]">leer</em>}</span>
          </div>
        ))}
      </div>
    )
  }
  if (input_type === 'NUMERIC' || input_type === 'STEPS_FINAL') {
    return (
      <div className="mt-4 flex items-center gap-2">
        <input
          className="max-w-[220px] flex-1 rounded-xl border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-3 text-lg font-semibold outline-none"
          placeholder="Antwort"
        />
      </div>
    )
  }
  if (input_type === 'OPEN') {
    return (
      <textarea
        className="mt-4 min-h-[90px] w-full rounded-xl border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm leading-relaxed outline-none"
        placeholder="Deine Antwort hier …"
      />
    )
  }
  if (input_type === 'DRAW') {
    return (
      <div className="mt-4 grid h-40 place-items-center rounded-xl border-2 border-dashed border-[var(--color-border)] bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]">
        <div className="text-center">
          <div className="text-3xl">✏️</div>
          <small className="text-xs">Zeichenfläche</small>
        </div>
      </div>
    )
  }
  return null
}

function readOptions(payload: unknown): { text: string; correct: boolean }[] {
  if (!payload || typeof payload !== 'object') return []
  const p = payload as { options?: unknown }
  if (!Array.isArray(p.options)) return []
  return p.options.map((o) => ({
    text: typeof o?.text === 'string' ? o.text : '',
    correct: o?.correct === true,
  }))
}

function HintBlock({
  hint1,
  hint2,
  revealed,
  onReveal,
  mode,
  label,
}: {
  hint1: string
  hint2: string
  revealed: number
  onReveal: () => void
  mode: Mode
  label: (n: number) => string
}): JSX.Element | null {
  const h1 = hint1.trim()
  const h2 = hint2.trim()
  if (!h1 && !h2) return null
  if (mode === 'coach') {
    return (
      <div className="mt-3 flex flex-col gap-1.5">
        {h1 && <HintShown n={1} text={h1} />}
        {h2 && <HintShown n={2} text={h2} />}
      </div>
    )
  }
  const total = (h1 ? 1 : 0) + (h2 ? 1 : 0)
  const next = revealed < total ? revealed + 1 : null
  return (
    <div className="mt-3 flex flex-col gap-1.5">
      {revealed >= 1 && h1 && <HintShown n={1} text={h1} />}
      {revealed >= 2 && h2 && <HintShown n={2} text={h2} />}
      {next && (
        <button
          type="button"
          onClick={onReveal}
          className="self-start rounded-full border border-[var(--color-gold-warning)]/40 bg-[var(--color-gold-warning)]/10 px-3 py-1.5 text-xs font-semibold text-[var(--color-gold-warning)] transition hover:bg-[var(--color-gold-warning)]/20"
        >
          💡 {label(next)}
        </button>
      )}
    </div>
  )
}

function HintShown({ n, text }: { n: number; text: string }): JSX.Element {
  return (
    <div className="flex items-start gap-2 rounded-xl border border-[var(--color-gold-warning)]/30 bg-[var(--color-gold-warning)]/10 px-3 py-2 text-sm text-[var(--color-gold-warning)]">
      <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-[var(--color-gold-warning)] text-xs font-bold text-white">
        {n}
      </span>
      <span>{text}</span>
    </div>
  )
}

function CoachBoxes({
  explanation,
  typical,
}: {
  explanation: string
  typical: string
}): JSX.Element | null {
  const { t } = useTranslation('screening-editor')
  if (!explanation.trim() && !typical.trim()) return null
  return (
    <div className="mt-3 flex flex-col gap-1.5">
      {explanation.trim() && (
        <div className="rounded-xl bg-[var(--color-success)]/10 px-3 py-2 text-xs leading-relaxed text-[var(--color-success)]">
          <strong className="block text-[10px] uppercase tracking-wider">
            {t('preview.coachSolution')}
          </strong>
          {explanation}
        </div>
      )}
      {typical.trim() && (
        <div className="rounded-xl bg-[var(--color-error-exam)]/10 px-3 py-2 text-xs leading-relaxed text-[var(--color-error-exam)]">
          <strong className="block text-[10px] uppercase tracking-wider">
            {t('preview.coachErrors')}
          </strong>
          {typical}
        </div>
      )}
    </div>
  )
}

function SubCard({
  item,
  hintReveal,
  onReveal,
  mode,
}: {
  item: ScreeningTeilaufgabe
  hintReveal: number
  onReveal: () => void
  mode: Mode
}): JSX.Element {
  const { t } = useTranslation('screening-editor')
  return (
    <div className="mt-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4 shadow-card">
      <div className="mb-2 flex items-start gap-3">
        <div className="grid h-7 w-7 place-items-center rounded-lg bg-[var(--color-repair-light)] font-bold text-[var(--color-repair)]">
          {item.key}
        </div>
        <p className="flex-1 pt-0.5 text-sm font-medium leading-relaxed text-[var(--color-text-primary)]">
          {item.prompt || <em className="text-[var(--color-text-tertiary)]">{t('preview.promptMissing')}</em>}
        </p>
      </div>
      {item.input_type === 'NUMERIC' ? (
        <input
          className="w-full max-w-[220px] rounded-xl border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2 text-base outline-none"
          placeholder="Antwort"
        />
      ) : (
        <textarea
          className="min-h-[60px] w-full rounded-xl border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm outline-none"
          placeholder="Antwort"
        />
      )}
      <HintBlock
        hint1=""
        hint2=""
        revealed={hintReveal}
        onReveal={onReveal}
        mode={mode}
        label={(n) => t('hint.show', { n })}
      />
      {mode === 'coach' && (item.accepted ?? []).filter(Boolean).length > 0 && (
        <div className="mt-2 rounded-xl bg-[var(--color-success)]/10 px-3 py-2 text-xs leading-relaxed text-[var(--color-success)]">
          <strong className="block text-[10px] uppercase tracking-wider">
            {t('preview.coachNote')}
          </strong>
          {item.accepted!.filter(Boolean).map((a, i) => (
            <div key={i}>• {a}</div>
          ))}
        </div>
      )}
    </div>
  )
}
