import type { JSX, ReactNode } from 'react'
import {
  BookOpen,
  Brain,
  Hand,
  ListChecks,
  Microscope,
  MoveRight,
  PencilLine,
  Repeat,
} from 'lucide-react'
import { MathContent } from '@/lib/render/MathContent'
import { parseQuestion } from '@/lib/render/taskQuestionParser'
import type { CognitiveType, InputType, Task } from '@/types'

type CognitiveMeta = {
  label: string
  desc: string
  icon: ReactNode
  accentCls: string
  accentBgCls: string
  heroBgCls: string
}

const COGNITIVE_META: Record<CognitiveType, CognitiveMeta> = {
  FACT: {
    label: 'Wissen abrufen',
    desc: 'Setze eine Formel oder Definition direkt ein.',
    icon: <BookOpen className="h-4 w-4" />,
    accentCls: 'text-[var(--color-primary)]',
    accentBgCls: 'bg-[var(--color-primary)]',
    heroBgCls: 'bg-[var(--color-primary-light)]',
  },
  TRANSFER: {
    label: 'Übertragen',
    desc: 'Wende Gelerntes auf eine neue Situation an.',
    icon: <MoveRight className="h-4 w-4" />,
    accentCls: 'text-[var(--color-success)]',
    accentBgCls: 'bg-[var(--color-success)]',
    heroBgCls: 'bg-[var(--color-success-light)]',
  },
  ANALYSIS: {
    label: 'Analyse',
    desc: 'Verknüpfe Daten und schließe logisch auf das Ergebnis.',
    icon: <Microscope className="h-4 w-4" />,
    accentCls: 'text-[var(--color-gold-warning)]',
    accentBgCls: 'bg-[var(--color-gold-warning)]',
    heroBgCls: 'bg-[var(--color-gold-warning-light)]',
  },
}

function CognitiveHero({ type }: { type: CognitiveType }): JSX.Element {
  const m = COGNITIVE_META[type]
  return (
    <div className={`flex items-center gap-3 rounded-[var(--radius-md)] px-4 py-2 ${m.heroBgCls}`}>
      <span
        className={`flex h-7 w-7 flex-none items-center justify-center rounded-[var(--radius-full)] text-white ${m.accentBgCls}`}
      >
        {m.icon}
      </span>
      <div className="min-w-0">
        <p className={`text-xs font-bold uppercase tracking-widest ${m.accentCls}`}>
          {m.label}
        </p>
        <p className="text-xs text-[var(--color-text-secondary)]">{m.desc}</p>
      </div>
    </div>
  )
}

type InputCue = { icon: ReactNode; label: string }

const INPUT_CUES: Partial<Record<InputType, InputCue>> = {
  MC: { icon: <ListChecks className="h-3.5 w-3.5" />, label: 'Antwort auswählen' },
  NUMERIC: { icon: <PencilLine className="h-3.5 w-3.5" />, label: 'Zahl eingeben' },
  SHORT_TEXT: { icon: <PencilLine className="h-3.5 w-3.5" />, label: 'Kurz antworten' },
  TRUE_FALSE: { icon: <ListChecks className="h-3.5 w-3.5" />, label: 'Wahr oder falsch' },
  FREE_TEXT: { icon: <PencilLine className="h-3.5 w-3.5" />, label: 'Antwort eingeben' },
  MATCHING: { icon: <Repeat className="h-3.5 w-3.5" />, label: 'Kärtchen zuordnen' },
  CLOZE: { icon: <Brain className="h-3.5 w-3.5" />, label: 'Lücken füllen' },
  COORDINATE: { icon: <Hand className="h-3.5 w-3.5" />, label: 'Punkt setzen' },
}

function InputCueChip({ type }: { type: InputType }): JSX.Element | null {
  const cue = INPUT_CUES[type]
  if (!cue) return null
  return (
    <span className="inline-flex items-center gap-1.5 rounded-[var(--radius-full)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 py-1 text-xs font-semibold text-[var(--color-text-secondary)]">
      <span className="text-[var(--color-primary)]">{cue.icon}</span>
      {cue.label}
    </span>
  )
}

const SUBTASK_TINTS: { borderCls: string; bgCls: string }[] = [
  { borderCls: 'border-l-[var(--color-primary)]',       bgCls: 'bg-[var(--color-primary)]' },
  { borderCls: 'border-l-[var(--color-success)]',       bgCls: 'bg-[var(--color-success)]' },
  { borderCls: 'border-l-[var(--color-gold-warning)]',  bgCls: 'bg-[var(--color-gold-warning)]' },
  { borderCls: 'border-l-[var(--color-primary)]',       bgCls: 'bg-[var(--color-primary)]' },
]

function SubtaskCard({
  letter,
  index,
  content,
}: {
  letter: string
  index: number
  content: string
}): JSX.Element {
  const tint = SUBTASK_TINTS[index % SUBTASK_TINTS.length]
  return (
    <div
      className={`flex gap-4 rounded-[var(--radius-md)] border-l-4 bg-[var(--color-bg-surface)] p-4 shadow-card ${tint.borderCls}`}
    >
      <div
        className={`flex h-9 w-9 flex-none items-center justify-center rounded-[var(--radius-full)] text-base font-bold uppercase text-white ${tint.bgCls}`}
        aria-hidden="true"
      >
        {letter}
      </div>
      <div className="min-w-0 flex-1">
        <p className="mb-1 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Teilaufgabe {letter.toUpperCase()}
        </p>
        <MathContent text={content} />
      </div>
    </div>
  )
}

export function TaskQuestionBlock({ task }: { task: Task }): JSX.Element | null {
  if (!task.question) return null
  const parts = parseQuestion(task.question)
  const subtasks = parts.filter((p) => p.type === 'subtask')
  const preamble = parts.find((p) => p.type === 'preamble')

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        {task.cognitive_type ? (
          <CognitiveHero type={task.cognitive_type} />
        ) : (
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Aufgabenstellung
          </span>
        )}
        {task.input_type && <InputCueChip type={task.input_type} />}
      </div>

      {preamble && (
        <div className="rounded-[var(--radius-md)] bg-[var(--color-primary-light)] p-6">
          <MathContent text={preamble.content} />
        </div>
      )}

      {subtasks.length > 0 && (
        <div className="flex flex-col gap-3">
          {subtasks.map((s, idx) =>
            s.type === 'subtask' ? (
              <SubtaskCard key={s.key} letter={s.key} index={idx} content={s.content} />
            ) : null,
          )}
        </div>
      )}
    </div>
  )
}
