import { type JSX } from 'react'
import { EdvanceBadge, EdvanceCard, MasteryBar, ProgressStep, StatCard } from '@/components/edvance'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'

const SESSION_STEPS = ['Check-in', 'Diagnose', 'Lernen', 'Praxis', 'Auswertung']

const ACHIEVEMENTS = [
  { label: '🔥 Streak gehalten',   variant: 'success'     },
  { label: '⚡ 7 Aufgaben',        variant: 'info'        },
  { label: '🎯 85 XP heute',       variant: 'accent'      },
  { label: '📈 Mastery +2',        variant: 'celebration' },
] as const

export function ScenarioSessionEnd(): JSX.Element {
  return (
    <div className="flex flex-col gap-6">

      {/* Session-Phasen */}
      <EdvanceCard>
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] mb-5">
          Session abgeschlossen · Di 13. Mai · 45 Min
        </p>
        <ProgressStep steps={SESSION_STEPS} current={5} />
      </EdvanceCard>

      {/* Kennzahlen */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard
          value="+85"
          label="XP heute verdient"
          icon="⚡"
          trend="+15 vs. letzte Session"
          color="var(--color-accent)"
        />
        <StatCard
          value={7}
          label="Aufgaben gelöst"
          icon="✅"
          trend="+2 vs. letzte Session"
          color="var(--color-success)"
        />
        <StatCard
          value="5 🔥"
          label="Tage Streak"
          icon="🔥"
          color="var(--color-accent-streak)"
        />
      </div>

      {/* Mastery Before / After */}
      <EdvanceCard>
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] mb-4">
          Daten &amp; Zufall — Fortschritt heute
        </p>
        <div className="grid grid-cols-2 gap-6">
          <div className="flex flex-col gap-2">
            <span className="text-xs text-[var(--color-text-tertiary)]">Beginn der Session</span>
            <MasteryBar level={4} showLabel size="md" />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-xs text-[var(--color-success)] font-semibold">Jetzt</span>
            <MasteryBar level={6} showLabel size="md" />
          </div>
        </div>
      </EdvanceCard>

      {/* Achievements */}
      <EdvanceCard>
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] mb-3">
          Heute verdient
        </p>
        <div className="flex flex-wrap gap-2">
          {ACHIEVEMENTS.map(({ label, variant }) => (
            <Badge key={label} variant={variant}>{label}</Badge>
          ))}
        </div>
      </EdvanceCard>

      {/* Coach-Kommentar */}
      <EdvanceCard accent="primary">
        <div className="flex items-start gap-3">
          <EdvanceBadge variant="primary">Coach</EdvanceBadge>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            „Lena, du hast heute einen deutlichen Sprung bei Wahrscheinlichkeiten gemacht —
            besonders die Aufgaben mit Baumdiagrammen saßen am Ende richtig sicher. Weiter so!"
          </p>
        </div>
        <p className="mt-2 text-xs text-[var(--color-text-tertiary)]">
          — Sarah B., Coach · Di 13. Mai
        </p>
      </EdvanceCard>

      <div className="flex justify-end">
        <Button variant="primary">Zur nächsten Session →</Button>
      </div>
    </div>
  )
}
