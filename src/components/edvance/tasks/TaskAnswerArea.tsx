import { useRef, useState, type FormEvent, type JSX, type KeyboardEvent } from 'react'
import { Lightbulb, PenLine, Type } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DrawCanvas } from '@/components/edvance/DrawCanvas'
import { MathToolbar } from '@/components/edvance/MathToolbar'
import { MCWidget } from './MCWidget'
import { MatchingWidget, type MatchPairs } from './MatchingWidget'
import { StepsWidget } from './StepsWidget'
import { parseMCPayload, parseMatchingPayload, parseStepsPayload } from '@/types/payloads'
import type { Task } from '@/types'

type Props = {
  task: Task
  onSubmit: (answer: string) => Promise<void>
  onHintToggle: () => void
  hintShown: boolean
  disabled: boolean
  onTextChange?: (v: string) => void
  onKeyDown?: (e: KeyboardEvent<HTMLTextAreaElement>) => void
}

type Mode = 'type' | 'draw'

export function TaskAnswerArea({
  task,
  onSubmit,
  onHintToggle,
  hintShown,
  disabled,
  onTextChange,
  onKeyDown,
}: Props): JSX.Element {
  const inputType = task.input_type
  const payload = task.question_payload

  const mc = inputType === 'MC' ? parseMCPayload(payload) : null
  const matching = inputType === 'MATCHING' ? parseMatchingPayload(payload) : null
  const steps = inputType === 'STEPS' ? parseStepsPayload(payload) : null

  // FREE_INPUT / DRAW state
  const [mode, setMode] = useState<Mode>('type')
  const [text, setText] = useState('')
  const [drawing, setDrawing] = useState<string | null>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  // MC state
  const [mcSel, setMcSel] = useState<number | null>(null)

  // MATCHING state — right items shuffled once on first render
  const [matchPairs, setMatchPairs] = useState<MatchPairs>(new Map())
  const shuffledRight = useRef<string[] | null>(null)
  if (matching && shuffledRight.current === null) {
    shuffledRight.current = [...matching.pairs.map((p) => p.right)].sort(() => Math.random() - 0.5)
  }

  // STEPS state
  const [stepAnswers, setStepAnswers] = useState<string[]>([])

  function hasAnswer(): boolean {
    if (inputType === 'MC') return mc !== null && mcSel !== null
    if (inputType === 'MATCHING' && matching)
      return matchPairs.size === matching.pairs.length
    if (inputType === 'STEPS' && steps)
      return steps.steps.every((_, i) => (stepAnswers[i] ?? '').trim().length > 0)
    if (mode === 'draw') return drawing !== null
    return text.trim().length > 0
  }

  function serialize(): string {
    if (inputType === 'MC') return JSON.stringify({ type: 'mc', selected: mcSel })
    if (inputType === 'MATCHING')
      return JSON.stringify({ type: 'matching', pairs: Object.fromEntries(matchPairs) })
    if (inputType === 'STEPS') return JSON.stringify({ type: 'steps', answers: stepAnswers })
    if (mode === 'draw') return drawing ?? ''
    return text
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!hasAnswer()) return
    await onSubmit(serialize())
  }

  function handleText(v: string) {
    setText(v)
    onTextChange?.(v)
  }

  function insertSymbol(sym: string) {
    const ta = textareaRef.current
    if (!ta) { handleText(text + sym); return }
    const s = ta.selectionStart, en = ta.selectionEnd
    const next = text.slice(0, s) + sym + text.slice(en)
    handleText(next)
    requestAnimationFrame(() => {
      ta.focus()
      const pos = s + sym.length
      ta.setSelectionRange(pos, pos)
    })
  }

  // Shuffle fallback message when payload is missing for structured types
  if ((inputType === 'MC' && !mc) || (inputType === 'MATCHING' && !matching) || (inputType === 'STEPS' && !steps)) {
    return (
      <div className="rounded-xl border-2 border-dashed border-[var(--border)] p-4 text-xs text-muted">
        Aufgaben-Payload fehlt für Typ <code className="rounded bg-[var(--surface-subtle)] px-1">{inputType}</code> — bitte im Admin nachpflegen.
      </div>
    )
  }

  return (
    <form onSubmit={(e) => void handleSubmit(e)} className="flex flex-col gap-3">
      {/* Mode-Toggle nur für FREE_INPUT / kein input_type */}
      {(!inputType || inputType === 'FREE_INPUT') && (
        <div className="flex flex-wrap items-center gap-2">
          <Button type="button" variant={mode === 'type' ? 'default' : 'outline'} size="sm"
            onClick={() => setMode('type')}>
            <Type className="mr-1 h-4 w-4" /> Tippen
          </Button>
          <Button type="button" variant={mode === 'draw' ? 'default' : 'outline'} size="sm"
            onClick={() => setMode('draw')}>
            <PenLine className="mr-1 h-4 w-4" /> Zeichnen
          </Button>
          <span className="ml-auto text-xs font-semibold uppercase tracking-wider text-muted">
            Dein Lösungsweg
          </span>
        </div>
      )}

      {/* Widget nach input_type */}
      {mc && <MCWidget options={mc.options} selected={mcSel} onChange={setMcSel} disabled={disabled} />}

      {matching && shuffledRight.current && (
        <MatchingWidget
          left={matching.pairs.map((p) => p.left)}
          right={shuffledRight.current}
          pairs={matchPairs}
          onChange={setMatchPairs}
          disabled={disabled}
        />
      )}

      {steps && (
        <StepsWidget steps={steps.steps} answers={stepAnswers} onChange={setStepAnswers} disabled={disabled} />
      )}

      {(!inputType || inputType === 'FREE_INPUT') && mode === 'type' && (
        <>
          <textarea
            ref={textareaRef}
            value={text}
            onChange={(e) => handleText(e.target.value)}
            onKeyDown={onKeyDown}
            placeholder="Zeige deinen Lösungsweg …"
            rows={5}
            disabled={disabled}
            className="min-h-[120px] w-full resize-y rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed focus:border-[var(--primary)] focus:outline-none"
          />
          <MathToolbar onInsert={insertSymbol} />
        </>
      )}

      {(!inputType || inputType === 'FREE_INPUT') && mode === 'draw' && (
        <DrawCanvas onChange={setDrawing} />
      )}

      {inputType === 'DRAW' && <DrawCanvas onChange={setDrawing} />}

      {/* Hint + Submit */}
      <div className="flex flex-wrap items-center gap-2">
        {task.hint && (
          <button
            type="button"
            onClick={onHintToggle}
            disabled={hintShown}
            className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-muted hover:text-warning disabled:opacity-50"
          >
            <Lightbulb className="h-3.5 w-3.5" />
            {hintShown ? 'Hint angezeigt' : 'Hint anfordern'}
          </button>
        )}
        <Button type="submit" size="lg" disabled={!hasAnswer() || disabled} className="ml-auto">
          Antwort einreichen
        </Button>
      </div>

      {hintShown && task.hint && (
        <div className="rounded-xl px-4 py-3 text-sm bg-[color-mix(in_srgb,var(--warning)_10%,transparent)] border-2 border-[color-mix(in_srgb,var(--warning)_30%,transparent)] text-[var(--warning)]">
          💡 {task.hint}
        </div>
      )}
    </form>
  )
}
