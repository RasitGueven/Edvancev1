import { useState, type JSX } from 'react'
import { AvatarInitials, EdvanceBadge, EdvanceCard, MasteryBar, StatCard, ToastBanner } from '@/components/edvance'
import { Button } from '@/components/ui/button'

type StudentStatus = 'ok' | 'needs-help' | 'levelup'

type Student = {
  name: string
  task: string
  mastery: number
  minutes: number
  status: StudentStatus
}

const STUDENTS: Student[] = [
  { name: 'Lena M.',  task: 'kap1.s10.nr3 — Zylinder-Versuch',  mastery: 7, minutes: 2, status: 'ok' },
  { name: 'Tom K.',   task: 'kap1.s11.nr5 — Wetten auf Würfel', mastery: 4, minutes: 8, status: 'needs-help' },
  { name: 'Sara L.',  task: 'kap1.s10.nr1 — Würfelexperiment',  mastery: 9, minutes: 1, status: 'levelup' },
  { name: 'Max B.',   task: 'kap1.s11.nr8 — Münzwurf ×3',       mastery: 5, minutes: 4, status: 'ok' },
]

const STATUS_BADGE: Record<StudentStatus, JSX.Element> = {
  ok:         <EdvanceBadge variant="muted">aktiv</EdvanceBadge>,
  'needs-help': <EdvanceBadge variant="warning">Aufmerksamkeit</EdvanceBadge>,
  levelup:    <EdvanceBadge variant="xp-day">Level-Up ✨</EdvanceBadge>,
}

export function ScenarioCoach(): JSX.Element {
  const [sentTo, setSentTo] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-5">
      {sentTo && (
        <ToastBanner
          type="success"
          message={`Nachricht an ${sentTo} gesendet.`}
          onClose={() => setSentTo(null)}
        />
      )}

      {/* Stat-Leiste */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard value={4}   label="Aktive Schüler"      icon="👥" color="var(--color-primary)" />
        <StatCard value="3,2" label="Ø Aufgaben / Schüler" icon="✅" color="var(--color-success)" />
        <StatCard value={1}   label="Handlungsbedarf"      icon="⚠️" color="var(--color-warning)" />
      </div>

      {/* Schüler-Kacheln */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {STUDENTS.map((s) => (
          <EdvanceCard
            key={s.name}
            accent={s.status === 'needs-help' ? 'left-warning' : s.status === 'levelup' ? 'left-success' : 'none'}
          >
            {/* Header */}
            <div className="flex items-start justify-between gap-3 mb-3">
              <div className="flex items-center gap-3 min-w-0">
                <AvatarInitials name={s.name} size="md" />
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-[var(--color-text-primary)] truncate">{s.name}</p>
                  <p className="text-xs text-[var(--color-text-tertiary)] truncate">{s.task}</p>
                </div>
              </div>
              {STATUS_BADGE[s.status]}
            </div>

            {/* Mastery + Zeit */}
            <MasteryBar level={s.mastery} showLabel size="sm" />
            <p className="mt-2 text-xs text-[var(--color-text-tertiary)]">
              {s.minutes < 5
                ? `Seit ${s.minutes} Min. an dieser Aufgabe`
                : `⚠ ${s.minutes} Min. ohne Fortschritt`}
            </p>

            {/* Intervention */}
            {s.status === 'needs-help' && (
              <div className="mt-3 pt-3 border-t border-[var(--color-border)]">
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={() => setSentTo(s.name)}
                >
                  Eingreifen
                </Button>
              </div>
            )}
          </EdvanceCard>
        ))}
      </div>
    </div>
  )
}
