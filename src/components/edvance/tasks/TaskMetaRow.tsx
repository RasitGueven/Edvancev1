import type { JSX, ReactNode } from 'react'
import { Brain, Clock, Layers, TestTube2, Type } from 'lucide-react'
import { EdvanceBadge } from '@/components/edvance'
import { cognitiveTypeLabel, inputTypeLabel } from '@/lib/taskLabels'
import type { Task } from '@/types'

function difficultyFillCls(value: number): string {
  if (value <= 1) return 'bg-[var(--color-success)]'
  if (value <= 3) return 'bg-[var(--color-primary)]'
  return 'bg-[var(--color-gold-warning)]'
}

function DifficultyScale({ value }: { value: number | null }): JSX.Element {
  const v = value ?? 0
  const fillCls = difficultyFillCls(v)
  return (
    <span
      className="inline-flex items-center gap-1"
      aria-label={`Schwierigkeit ${v} von 5`}
      title={`Schwierigkeit ${v}/5`}
    >
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          className={`h-2 w-2 rounded-full ${i <= v ? fillCls : 'bg-[var(--color-border)]'}`}
        />
      ))}
    </span>
  )
}

function MetaItem({ icon, children }: { icon: ReactNode; children: ReactNode }): JSX.Element {
  return (
    <span className="inline-flex items-center gap-1.5 text-xs text-[var(--color-text-secondary)]">
      <span className="text-[var(--color-text-tertiary)]">{icon}</span>
      {children}
    </span>
  )
}

export function TaskMetaRow({ task }: { task: Task }): JSX.Element {
  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
      <MetaItem icon={<Layers className="h-3.5 w-3.5" />}>
        Klasse {task.class_level ?? '–'}
      </MetaItem>
      <MetaItem icon={<Clock className="h-3.5 w-3.5" />}>
        {task.estimated_minutes} Min
      </MetaItem>
      <span className="inline-flex items-center gap-1.5 text-xs text-[var(--color-text-secondary)]">
        <span className="text-[var(--color-text-tertiary)]">Schwierigkeit</span>
        <DifficultyScale value={task.difficulty} />
      </span>
      {task.cognitive_type && (
        <EdvanceBadge variant="primary">
          <Brain className="h-3 w-3" />
          {cognitiveTypeLabel(task.cognitive_type)}
        </EdvanceBadge>
      )}
      {task.input_type && (
        <EdvanceBadge variant="muted">
          <Type className="h-3 w-3" />
          {inputTypeLabel(task.input_type)}
        </EdvanceBadge>
      )}
      {task.is_diagnostic && (
        <EdvanceBadge variant="warning">
          <TestTube2 className="h-3 w-3" />
          Diagnostik
        </EdvanceBadge>
      )}
    </div>
  )
}
