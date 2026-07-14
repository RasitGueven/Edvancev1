import type { JSX } from 'react'
import type { Task } from '@/types'

type ContentType = Task['content_type']

export const TYPE_LABEL: Record<ContentType, string> = {
  exercise: 'Aufgabe',
  exercise_group: 'Mini-Test',
  article: 'Artikel',
  video: 'Video',
  course: 'Kurs',
}

// Auf der dunklen Task-Bühne: Glas-Chip + dark-legible Akzent-Textfarbe je Typ
// (Token, kein Hardcode). Navy-Primary wäre auf Dunkel unlesbar → warm/akzent.
const TYPE_BADGE_TEXT: Record<ContentType, string> = {
  exercise: 'text-warm',
  exercise_group: 'text-warm',
  article: 'text-[var(--color-success-skilltree)]',
  video: 'text-[var(--color-accent-streak)]',
  course: 'text-[var(--color-gold-champagner)]',
}

export function TypeBadge({ type }: { type: ContentType }): JSX.Element {
  return (
    <span
      className={`rounded-[var(--radius-sm)] bg-white/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ${TYPE_BADGE_TEXT[type]}`}
    >
      {TYPE_LABEL[type]}
    </span>
  )
}

export function DifficultyBadge({ difficulty }: { difficulty: number }): JSX.Element {
  return (
    <span className="inline-flex items-center gap-1 rounded-[var(--radius-sm)] px-2 py-1 text-xs font-semibold text-warm-72">
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          className={`inline-block h-1.5 w-1.5 rounded-full ${
            i <= difficulty ? 'bg-white/80' : 'bg-white/20'
          }`}
        />
      ))}
    </span>
  )
}

// `tasks.solution` wird hier bewusst NICHT gerendert: die Spalte ist die
// Loesung (Server-Only-Zone, siehe task_solutions) und hat auf einer
// Schueler-Flaeche nichts zu suchen — auch nicht als Video-Beitext.
export function VideoBlock({ task }: { task: Task }): JSX.Element {
  const url = task.question
  if (!url) return <p className="text-sm text-muted">– kein Video-Link –</p>
  return (
    <div className="flex flex-col gap-4">
      <a
        href={url}
        target="_blank"
        rel="noreferrer"
        className="inline-flex items-center gap-2 self-start rounded-lg border-2 border-border bg-card px-4 py-3 text-sm font-semibold text-primary hover:bg-primary/5"
      >
        {task.title ?? 'Video oeffnen'}
      </a>
    </div>
  )
}

export function UnsupportedBlock({ type }: { type: ContentType }): JSX.Element {
  return (
    <div className="rounded-lg border-2 border-dashed border-border p-6 text-center">
      <p className="text-sm font-semibold text-muted">
        Inhaltstyp <code className="rounded bg-border-strong/40 px-1.5 py-0.5">{type}</code>{' '}
        ist noch nicht unterstuetzt.
      </p>
    </div>
  )
}
