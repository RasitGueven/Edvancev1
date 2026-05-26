/**
 * Edvance Design-System v2 — UI-Kit
 *
 * SCHRITT 3 — Basis-Komponenten visuell auf v2-Tokens gemappt.
 * Greift nur unter `[data-design="v2"]`. Keine Aenderung an
 * produktiven Komponenten unter `src/components`.
 *
 * KRITISCHE REGELN (siehe Schritt 7):
 *  1. `--color-accent` (#E8A020) NIE als Textfarbe auf Weiss — WCAG fail.
 *  2. Celebration-Farben (`--color-moment-*`) nur in Animations-Modals.
 *  3. Glaseffekte nur auf dunklem Hintergrund (Header/Hero) — nie auf #FFF.
 *  4. Level-Up/Boss max. 1x pro Session.
 *  5. Streak-Rot kurz, danach Repair-Lila anbieten.
 *  6. Mastered-Status nur via Coach-Bestaetigung im Backend.
 *  7. Alle Schatten ueber `--shadow-*` (blau getoent) — kein neutrales Grau.
 *  8. Rundungen aus `--radius-*` — kein hardcodiertes `rounded-full` ausser Kreisen.
 */
import type { JSX, ReactNode } from 'react'
import { cn } from '@/lib/utils'

function Section({ title, hint, children }: { title: string; hint?: string; children: ReactNode }): JSX.Element {
  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-baseline justify-between">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{title}</h3>
        {hint ? <span className="text-[10px] text-[var(--color-text-tertiary)]">{hint}</span> : null}
      </div>
      <div className="bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-lg p-5 shadow-md flex flex-col gap-4">
        {children}
      </div>
    </section>
  )
}

function ButtonRow(): JSX.Element {
  return (
    <Section title="Button" hint="primary · secondary · ghost · disabled">
      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          className="bg-[var(--color-primary)] text-white px-4 py-2 rounded-md shadow-md hover:bg-[var(--color-primary-hover)] hover:-translate-y-0.5 transition-all duration-fast ease-out text-sm font-medium"
        >
          Primary
        </button>
        <button
          type="button"
          className="border border-[var(--color-primary)] text-[var(--color-primary)] px-4 py-2 rounded-md hover:bg-[var(--color-primary-light)] transition-all duration-fast text-sm font-medium"
        >
          Secondary
        </button>
        <button
          type="button"
          className="text-[var(--color-primary)] px-4 py-2 rounded-md hover:bg-[var(--color-primary-light)] transition-all duration-fast text-sm font-medium"
        >
          Ghost
        </button>
        <button
          type="button"
          disabled
          className="bg-[var(--color-primary)] text-white px-4 py-2 rounded-md opacity-40 cursor-not-allowed text-sm font-medium"
        >
          Disabled
        </button>
      </div>
    </Section>
  )
}

function Pill({ className, children }: { className: string; children: ReactNode }): JSX.Element {
  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-sm', className)}>
      {children}
    </span>
  )
}

function BadgeRow(): JSX.Element {
  return (
    <Section title="Badge / Chip" hint="status-sprachfarben">
      <div className="flex flex-wrap gap-2">
        <Pill className="bg-[var(--color-success-light)] text-[var(--color-success)]">success</Pill>
        <Pill className="bg-[var(--color-error-gap-light)] text-[var(--color-error-gap)]">error-gap</Pill>
        <Pill className="bg-[var(--color-error-exam-light)] text-[var(--color-error-exam)]">error-exam</Pill>
        <Pill className="bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]">warning</Pill>
        {/* XP-Pill: dunkler Text auf Gold, NIE Accent als Textfarbe auf Weiss */}
        <Pill className="bg-[var(--color-gold-altgold)] text-[var(--color-accent-on)]">+25 XP</Pill>
        <Pill className="bg-[var(--color-repair-light)] text-[var(--color-repair)]">streak-repair</Pill>
      </div>
    </Section>
  )
}

function CardRow(): JSX.Element {
  return (
    <Section title="Card" hint="default · subtle">
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-lg shadow-md p-5 hover:-translate-y-0.5 hover:shadow-lg transition-all duration-base ease-bounce">
          <p className="text-base font-semibold">Default Card</p>
          <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mt-1">
            Hover hebt um 0.5px an und wechselt auf `shadow-lg`.
          </p>
        </div>
        <div className="bg-[var(--color-bg-subtle)] rounded-lg p-5">
          <p className="text-base font-semibold">Subtle</p>
          <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mt-1">
            Eingebettete Metrik-Box ohne eigenen Schatten.
          </p>
        </div>
      </div>
    </Section>
  )
}

function InputRow(): JSX.Element {
  return (
    <Section title="Input / Textarea" hint="focus-ring in primary/10">
      <div className="flex flex-col gap-3 max-w-sm">
        <input
          type="text"
          placeholder="Name eingeben"
          className="border border-[var(--color-border)] rounded-md px-3 py-2 text-sm text-[var(--color-text-primary)] bg-[var(--color-bg-surface)] shadow-xs transition-all duration-instant focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]/10 focus:outline-none"
        />
        <textarea
          rows={2}
          placeholder="Beobachtung notieren ..."
          className="border border-[var(--color-border)] rounded-md px-3 py-2 text-sm text-[var(--color-text-primary)] bg-[var(--color-bg-surface)] shadow-xs transition-all duration-instant focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]/10 focus:outline-none"
        />
      </div>
    </Section>
  )
}

function ProgressRow(): JSX.Element {
  return (
    <Section title="Fortschrittsbalken" hint="normal · success · grow (Session-Ende)">
      <div className="flex flex-col gap-3">
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-1">Normal · primary</p>
          <div className="bg-[var(--color-bg-subtle)] rounded-full h-1.5 overflow-hidden">
            <div className="bg-[var(--color-primary)] h-full rounded-full" style={{ width: '60%' }} />
          </div>
        </div>
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-1">Success · gemeistert</p>
          <div className="bg-[var(--color-bg-subtle)] rounded-full h-1.5 overflow-hidden">
            <div className="bg-[var(--color-success)] h-full rounded-full" style={{ width: '90%' }} />
          </div>
        </div>
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-1">Grow · waechst am Session-Ende</p>
          <div className="bg-[var(--color-bg-subtle)] rounded-full h-1.5 overflow-hidden">
            <div
              className="bg-[var(--color-success-grow)] h-full rounded-full animate-bar-grow"
              style={{ ['--bar-target' as string]: '75%' }}
            />
          </div>
        </div>
      </div>
    </Section>
  )
}

function NavRow(): JSX.Element {
  const items = ['Lernpfad', 'Faecher', 'Profil']
  return (
    <Section title="Navigation" hint="hell auf weiss · hell auf navy">
      <div className="flex flex-col gap-3">
        <div className="flex gap-1 bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-md p-1">
          {items.map((item, idx) => (
            <button
              key={item}
              type="button"
              className={cn(
                'flex-1 px-3 py-1.5 text-sm rounded-md transition-colors duration-instant',
                idx === 0
                  ? 'bg-[var(--color-primary-light)] text-[var(--color-primary)] font-medium'
                  : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]',
              )}
            >
              {item}
            </button>
          ))}
        </div>
        <div className="v2-student-header rounded-md p-1 flex gap-1">
          {items.map((item, idx) => (
            <button
              key={item}
              type="button"
              className={cn(
                'flex-1 px-3 py-1.5 text-sm rounded-md transition-colors duration-instant',
                idx === 0
                  ? 'bg-white/15 text-white font-medium'
                  : 'text-white/70 hover:text-white',
              )}
            >
              {item}
            </button>
          ))}
        </div>
      </div>
    </Section>
  )
}

export function V2Kit(): JSX.Element {
  return (
    <div className="flex flex-col gap-6">
      <ButtonRow />
      <BadgeRow />
      <CardRow />
      <InputRow />
      <ProgressRow />
      <NavRow />
    </div>
  )
}
