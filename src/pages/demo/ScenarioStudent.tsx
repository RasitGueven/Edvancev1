import { useState, type JSX } from 'react'
import { EdvanceBadge, EdvanceCard, MasteryBar, ToastBanner, XPBar } from '@/components/edvance'
import { MCWidget } from '@/components/edvance/tasks/MCWidget'
import { Button } from '@/components/ui/button'

const MC_OPTIONS = [
  'P = 1/6 ≈ 16,7 % — nur die 2 zählt',
  'P = 1/3 ≈ 33,3 % — zwei Zahlen zählen',
  'P = 1/2 = 50 % — drei von sechs Seiten sind gerade',
  'P = 2/3 ≈ 66,7 % — vier Zahlen zählen',
]

type Phase = 'idle' | 'loading' | 'done'

export function ScenarioStudent(): JSX.Element {
  const [selected, setSelected] = useState<number | null>(null)
  const [phase, setPhase] = useState<Phase>('idle')
  const [xp, setXp] = useState(340)
  const [mastery, setMastery] = useState(5)
  const [showToast, setShowToast] = useState(false)

  function handleSubmit() {
    setPhase('loading')
    setTimeout(() => {
      setPhase('done')
      setXp(360)
      setMastery(6)
      setShowToast(true)
    }, 1200)
  }

  function handleReset() {
    setSelected(null)
    setPhase('idle')
    setXp(340)
    setMastery(5)
  }

  const isDone = phase === 'done'

  return (
    <div className="flex flex-col gap-5">
      {showToast && (
        <ToastBanner
          type="xp"
          message="Aufgabe abgeschlossen!"
          xpAmount={20}
          onClose={() => setShowToast(false)}
        />
      )}

      {/* Kopfzeile: XP + Streak */}
      <EdvanceCard className="flex flex-col gap-4">
        <XPBar current={xp} max={500} level={4} levelName="Entdecker" />
        <div className="flex items-center justify-between text-xs text-[var(--color-text-tertiary)]">
          <span>Heutige Session · Kap. 1 Wahrscheinlichkeit</span>
          <EdvanceBadge variant="streak-presence">5 Tage</EdvanceBadge>
        </div>
      </EdvanceCard>

      {/* Aufgabe */}
      <EdvanceCard>
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] mb-1">
          kap1.s10 · Multiple Choice
        </p>
        <h2 className="text-base font-bold text-[var(--color-text-primary)] mb-4 leading-snug">
          Beim einmaligen Würfeln mit einem fairen Würfel — wie groß ist P(gerade Zahl)?
        </h2>

        <MCWidget
          options={MC_OPTIONS}
          selected={selected}
          onChange={(i) => { if (phase === 'idle') setSelected(i) }}
          disabled={phase !== 'idle'}
        />

        <div className="mt-5 flex items-center justify-end gap-3">
          {isDone && (
            <Button variant="ghost" size="sm" onClick={handleReset}>
              Zurücksetzen
            </Button>
          )}
          <Button
            variant="primary"
            loading={phase === 'loading'}
            disabled={selected === null || isDone}
            onClick={handleSubmit}
          >
            {isDone ? '✓ Eingereicht' : 'Antwort einreichen'}
          </Button>
        </div>
      </EdvanceCard>

      {/* Kompetenz-Niveau */}
      <EdvanceCard>
        <div className="flex items-center justify-between mb-3">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Daten &amp; Zufall — Kompetenz-Niveau
          </p>
          {isDone && (
            <EdvanceBadge variant="mastered">+1 Level</EdvanceBadge>
          )}
        </div>
        <MasteryBar level={mastery} showLabel size="lg" />
      </EdvanceCard>
    </div>
  )
}
