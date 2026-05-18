import { useRef, useState, type JSX } from 'react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { MCWidget } from '@/components/edvance/tasks/MCWidget'
import { MatchingWidget, type MatchPairs } from '@/components/edvance/tasks/MatchingWidget'
import { StepsWidget } from '@/components/edvance/tasks/StepsWidget'
import { DrawCanvas } from '@/components/edvance/DrawCanvas'
import { MathToolbar } from '@/components/edvance/MathToolbar'
import { Card, CardContent } from '@/components/ui/card'
import type { InputType } from '@/types'

// ─── Demo-Daten ─────────────────────────────────────────────────────────────

const MC_DEMO = {
  question: 'Ein Würfel wird dreimal geworfen. Was ist die Wahrscheinlichkeit, dass mindestens eine 6 fällt?',
  options: [
    '1 − (5/6)³ ≈ 42 %',
    '3 · (1/6) = 50 %',
    '(1/6)³ ≈ 0,5 %',
    'Nicht berechenbar ohne mehr Daten',
  ],
}

const MATCHING_DEMO = {
  question: 'Ordne den Fachbegriff der passenden Definition zu.',
  pairs: [
    { left: 'Relative Häufigkeit', right: 'Anzahl Treffer ÷ Gesamtanzahl' },
    { left: 'Laplace-Experiment', right: 'Alle Ergebnisse gleich wahrscheinlich' },
    { left: 'Ergebnisraum Ω', right: 'Menge aller möglichen Ergebnisse' },
    { left: 'Gegenereignis', right: 'Alles außer dem betrachteten Ereignis' },
  ],
}

const STEPS_DEMO = {
  question: 'Berechne die Wahrscheinlichkeit, bei einem fairen Würfel eine Zahl > 4 zu würfeln.',
  steps: [
    { prompt: 'Wie viele Zahlen auf einem Würfel sind größer als 4?', placeholder: 'Anzahl …' },
    { prompt: 'Wie viele Ergebnisse hat der Ergebnisraum insgesamt?', placeholder: 'Anzahl …' },
    { prompt: 'Berechne die Wahrscheinlichkeit als Bruch.', placeholder: 'P = …' },
    { prompt: 'Wie viel Prozent ist das?', placeholder: '… %' },
  ],
}

const FREE_DEMO = {
  question: 'Erkläre in eigenen Worten, warum die Summe der Wahrscheinlichkeiten aller Ergebnisse eines Zufallsexperiments immer 1 ergibt.',
}

const DRAW_DEMO = {
  question: 'Zeichne ein Baumdiagramm für zweimaliges Werfen einer Münze (Kopf / Zahl).',
}

const TYPE_META: Record<InputType, { label: string; color: string }> = {
  MC: { label: 'Multiple Choice', color: 'var(--primary)' },
  MATCHING: { label: 'Zuordnung', color: 'var(--info)' },
  STEPS: { label: 'Rechnen (Schritte)', color: 'var(--success)' },
  FREE_INPUT: { label: 'Freitext', color: 'var(--warning)' },
  DRAW: { label: 'Zeichnen', color: 'var(--brand-navy)' },
}

// ─── Sektion ─────────────────────────────────────────────────────────────────

function Section({
  type,
  question,
  children,
  submitted,
  onSubmit,
  onReset,
}: {
  type: InputType
  question: string
  children: JSX.Element
  submitted: boolean
  onSubmit: () => void
  onReset: () => void
}): JSX.Element {
  const { label, color } = TYPE_META[type]
  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center gap-3">
        <span
          className="rounded-md px-2.5 py-1 text-xs font-bold uppercase tracking-wider text-white"
          style={{ background: color }}
        >
          {label}
        </span>
        <code className="rounded bg-[var(--surface-subtle)] px-1.5 py-0.5 text-xs text-[var(--text-muted)]">
          {type}
        </code>
        {submitted && (
          <span className="text-xs font-semibold" style={{ color: 'var(--success)' }}>
            ✓ Eingereicht
          </span>
        )}
      </div>

      <Card>
        <CardContent className="pt-5">
          <p className="mb-4 text-sm font-medium leading-relaxed text-foreground">{question}</p>
          {children}

          <div className="mt-4 flex gap-2">
            {!submitted && (
              <button
                type="button"
                onClick={onSubmit}
                className="rounded-xl px-4 py-2 text-sm font-semibold text-white"
                style={{ background: color }}
              >
                Antwort einreichen
              </button>
            )}
            <button
              type="button"
              onClick={onReset}
              className="rounded-xl border-2 border-[var(--border)] px-4 py-2 text-sm font-semibold text-muted hover:border-[var(--primary-light)]"
            >
              Reset
            </button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

// ─── Page ────────────────────────────────────────────────────────────────────

export function TaskWidgetDemo(): JSX.Element {
  // MC
  const [mcSel, setMcSel] = useState<number | null>(null)
  const [mcDone, setMcDone] = useState(false)

  // Matching — right items shuffled once
  const [pairs, setPairs] = useState<MatchPairs>(new Map())
  const [matchDone, setMatchDone] = useState(false)
  const shuffled = ['Menge aller möglichen Ergebnisse', 'Anzahl Treffer ÷ Gesamtanzahl', 'Alles außer dem betrachteten Ereignis', 'Alle Ergebnisse gleich wahrscheinlich']

  // Steps
  const [stepAns, setStepAns] = useState<string[]>([])
  const [stepsDone, setStepsDone] = useState(false)

  // Free input
  const [freeText, setFreeText] = useState('')
  const [freeDone, setFreeDone] = useState(false)
  const freeRef = useRef<HTMLTextAreaElement>(null)

  // Draw
  const [drawing, setDrawing] = useState<string | null>(null)
  const [drawDone, setDrawDone] = useState(false)

  const insertSymbol = (sym: string): void => {
    const ta = freeRef.current
    if (!ta) { setFreeText(freeText + sym); return }
    const s = ta.selectionStart, en = ta.selectionEnd
    const next = freeText.slice(0, s) + sym + freeText.slice(en)
    setFreeText(next)
    requestAnimationFrame(() => {
      ta.focus()
      const pos = s + sym.length
      ta.setSelectionRange(pos, pos)
    })
  }

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <EdvanceNavbar subtitle="Widget-Demo" />

      <main className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Aufgaben-Widgets</h1>
          <p className="mt-1 text-sm text-[var(--text-muted)]">
            Demo-Seite ohne Login — zeigt alle 5 Eingabe-Typen für Schüler-Aufgaben.
          </p>
        </div>

        <div className="flex flex-col gap-8">
          {/* Multiple Choice */}
          <Section
            type="MC"
            question={MC_DEMO.question}
            submitted={mcDone}
            onSubmit={() => mcSel !== null && setMcDone(true)}
            onReset={() => { setMcSel(null); setMcDone(false) }}
          >
            <MCWidget
              options={MC_DEMO.options}
              selected={mcSel}
              onChange={setMcSel}
              disabled={mcDone}
            />
          </Section>

          {/* Matching / Zuordnung */}
          <Section
            type="MATCHING"
            question={MATCHING_DEMO.question}
            submitted={matchDone}
            onSubmit={() => pairs.size === MATCHING_DEMO.pairs.length && setMatchDone(true)}
            onReset={() => { setPairs(new Map()); setMatchDone(false) }}
          >
            <MatchingWidget
              left={MATCHING_DEMO.pairs.map((p) => p.left)}
              right={shuffled}
              pairs={pairs}
              onChange={setPairs}
              disabled={matchDone}
            />
          </Section>

          {/* Steps / Rechnen */}
          <Section
            type="STEPS"
            question={STEPS_DEMO.question}
            submitted={stepsDone}
            onSubmit={() => {
              const allFilled = STEPS_DEMO.steps.every((_, i) => (stepAns[i] ?? '').trim().length > 0)
              if (allFilled) setStepsDone(true)
            }}
            onReset={() => { setStepAns([]); setStepsDone(false) }}
          >
            <StepsWidget
              steps={STEPS_DEMO.steps}
              answers={stepAns}
              onChange={setStepAns}
              disabled={stepsDone}
            />
          </Section>

          {/* Freitext */}
          <Section
            type="FREE_INPUT"
            question={FREE_DEMO.question}
            submitted={freeDone}
            onSubmit={() => freeText.trim().length > 0 && setFreeDone(true)}
            onReset={() => { setFreeText(''); setFreeDone(false) }}
          >
            <div className="flex flex-col gap-3">
              <textarea
                ref={freeRef}
                value={freeText}
                onChange={(e) => setFreeText(e.target.value)}
                placeholder="Zeige deinen Lösungsweg …"
                rows={5}
                disabled={freeDone}
                className="min-h-[120px] w-full resize-y rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed focus:border-[var(--primary)] focus:outline-none"
              />
              <MathToolbar onInsert={insertSymbol} />
            </div>
          </Section>

          {/* Zeichnen */}
          <Section
            type="DRAW"
            question={DRAW_DEMO.question}
            submitted={drawDone}
            onSubmit={() => drawing !== null && setDrawDone(true)}
            onReset={() => { setDrawing(null); setDrawDone(false) }}
          >
            <DrawCanvas onChange={setDrawing} />
          </Section>
        </div>
      </main>
    </div>
  )
}
