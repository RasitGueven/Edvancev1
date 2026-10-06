// Kleine Bausteine der Coach-Live-Sicht. Coach-Sprache = flach, kein Glas
// (Design-Invariante); Farben nur aus Tokens.

import type { ReactNode } from 'react'
import { EdvanceBadge } from '@/components/edvance/EdvanceBadge'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { cn } from '@/lib/utils'
import type { ErgebnisMarke } from '@/types/coachLive'

export type PillenTon = 'neutral' | 'ok' | 'warn' | 'bad' | 'navy' | 'solid'

const PILLE: Record<PillenTon, string> = {
  neutral: 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
  ok: 'bg-[var(--color-success-light)] text-[var(--color-success)]',
  warn: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]',
  bad: 'bg-[var(--color-error-gap-light)] text-[var(--color-error-gap)]',
  navy: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
  solid: 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]',
}

/** Status-Pille: EdvanceBadge in der runden, flachen Form des Dummys. */
export function Pille({ ton = 'neutral', icon, children }: { ton?: PillenTon; icon?: ReactNode; children: ReactNode }): JSX.Element {
  return (
    <EdvanceBadge
      icon={icon}
      className={cn('whitespace-nowrap rounded-full border-0 px-2.5 py-0.5 normal-case tracking-normal', PILLE[ton])}
    >
      {children}
    </EdvanceBadge>
  )
}

/** Section-Header (CLAUDE.md §11) mit optionaler Zusatzzeile rechts. */
export function Abschnitt({ titel, zusatz, children }: { titel: string; zusatz?: ReactNode; children: ReactNode }): JSX.Element {
  return (
    <section className="flex min-w-0 flex-col gap-2">
      <div className="flex items-baseline justify-between gap-4">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{titel}</h2>
        {zusatz && <span className="text-xs text-[var(--color-text-tertiary)]">{zusatz}</span>}
      </div>
      {children}
    </section>
  )
}

export type BlockTon = 'normal' | 'kandidat' | 'entscheidung' | 'info'

const BLOCK: Record<BlockTon, string> = {
  normal: '',
  kandidat: 'border-primary/30 ring-4 ring-[var(--color-primary-light)]',
  entscheidung: 'border-[var(--color-gold-warning)]/40 ring-4 ring-[var(--color-gold-warning-light)]',
  info: 'border-primary/20 bg-[var(--color-primary-light)]',
}

/** Block in der Schublade. */
export function Block({
  titel,
  rechts,
  ton = 'normal',
  children,
}: {
  titel?: string
  rechts?: ReactNode
  ton?: BlockTon
  children: ReactNode
}): JSX.Element {
  return (
    <EdvanceCard className={cn('flex flex-col gap-2 p-4 shadow-none hover:shadow-none', BLOCK[ton])}>
      {(titel || rechts) && (
        <div className="flex flex-wrap items-center justify-between gap-2">
          {titel && <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{titel}</h3>}
          {rechts}
        </div>
      )}
      {children}
    </EdvanceCard>
  )
}

/** Tablet-Nummer als kleines Quadrat. */
export function Platz({ nr }: { nr: number | null }): JSX.Element {
  return (
    <span className="inline-flex h-6 w-6 flex-none items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-bg-subtle)] text-xs font-bold tabular-nums text-[var(--color-text-secondary)]">
      {nr ?? '–'}
    </span>
  )
}

const PUNKT: Record<ErgebnisMarke, string> = {
  richtig: 'bg-[var(--color-success-answer)]',
  falsch: 'bg-[var(--color-error-gap)]',
  hinweis: 'bg-[linear-gradient(90deg,var(--color-success-answer)_50%,var(--color-bg-surface)_50%)] ring-[1.5px] ring-inset ring-[var(--color-success-answer)]',
  aktuell: 'ring-[1.5px] ring-inset ring-[var(--color-neutral-unknown)]',
}

/** Ergebnisfolge als Punkte (nur in der Coach-Sicht; das Kind sieht nie richtig/falsch). */
export function Punkte({ folge }: { folge: ErgebnisMarke[] }): JSX.Element | null {
  if (folge.length === 0) return null
  return (
    <span className="inline-flex items-center gap-1" aria-hidden>
      {folge.map((m, i) => (
        <i key={i} className={cn('h-2.5 w-2.5 rounded-full', PUNKT[m])} />
      ))}
    </span>
  )
}

/** Stand der Kernideen als Balken. */
export function Sequenzbalken({ staende }: { staende: ('sicher' | 'laeuft' | 'offen')[] }): JSX.Element {
  return (
    <span className="flex max-w-[120px] flex-1 gap-1" aria-hidden>
      {staende.map((s, i) => (
        <i
          key={i}
          className={cn(
            'h-2 flex-1 rounded-full',
            s === 'sicher' ? 'bg-[var(--color-primary)]' : s === 'laeuft' ? 'bg-primary/25' : 'bg-[var(--color-bg-subtle)]',
          )}
        />
      ))}
    </span>
  )
}

/** Auswahl-Chip (Gruende, Flags). */
export function Chip({
  aktiv,
  onClick,
  children,
}: {
  aktiv: boolean
  onClick: () => void
  children: ReactNode
}): JSX.Element {
  return (
    <button
      type="button"
      aria-pressed={aktiv}
      onClick={onClick}
      className={cn(
        'min-h-[44px] rounded-full border px-4 text-sm transition-colors duration-150',
        aktiv
          ? 'border-[var(--color-primary)] bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]'
          : 'border-[var(--color-neutral-unknown)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]',
      )}
    >
      {children}
    </button>
  )
}

/** Label in Grossbuchstaben (Feldname). */
export function Feldname({ children, htmlFor }: { children: ReactNode; htmlFor?: string }): JSX.Element {
  const cls = 'block text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]'
  return htmlFor ? <label htmlFor={htmlFor} className={cls}>{children}</label> : <span className={cls}>{children}</span>
}
