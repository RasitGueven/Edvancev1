import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { CircleDot, ArrowLeft } from 'lucide-react'
import { EdvanceCard, MasteryBar } from '@/components/edvance'
import { SessionShell } from '../components/SessionShell'
import { SessionButton } from '../components/SessionButton'
import {
  MOCK_SESSION_TOPIC,
  MOCK_SESSION_CHECKPOINTS,
  MOCK_SESSION_TASKS,
  MOCK_SESSION_STUDENT,
} from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

/**
 * Screen 3 — Heutiges Ziel / Lernpfad-Karte. Transparenz vor dem Start:
 * Thema, Teilziele, geschätzter Umfang, Mastery-Stand (zeigt Wachstum, nicht
 * Lücke). Hier beginnt die echte Pfad-Progression. Ein CTA: „Erste Aufgabe".
 */
export function GoalScreen({ dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const taskCount = MOCK_SESSION_TASKS.length
  const minutes = taskCount * 6

  return (
    <SessionShell maxWidth="md">
      <div className="flex flex-col gap-6">
        <button
          type="button"
          onClick={() => dispatch({ type: 'BACK_TO_HUB' })}
          className="inline-flex min-h-[44px] items-center gap-1.5 self-start text-sm font-semibold text-warm-56 hover:text-warm"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          {t('session.common.backToHub')}
        </button>

        <div>
          <p className="text-eyebrow text-warm-56">{t('session.goal.eyebrow')}</p>
          <h1 className="text-display mt-1 text-3xl text-warm">
            {t('session.goal.title', { topic: MOCK_SESSION_TOPIC.name })}
          </h1>
          <p className="mt-2 text-sm text-warm-56">
            {t('session.goal.lastSession', { note: MOCK_SESSION_STUDENT.lastSessionNote })}
          </p>
        </div>

        <EdvanceCard variant="glass" className="text-warm">
          <p className="text-xs font-semibold uppercase tracking-widest text-warm-56">
            {t('session.goal.checkpointsLabel')}
          </p>
          <ul className="mt-3 flex flex-col gap-3">
            {MOCK_SESSION_CHECKPOINTS.map((cp) => (
              <li key={cp.id} className="flex items-start gap-3">
                <CircleDot
                  className="mt-0.5 h-5 w-5 shrink-0 text-[var(--color-gold-champagner)]"
                  aria-hidden="true"
                />
                <span className="text-sm leading-relaxed text-warm">{cp.label}</span>
              </li>
            ))}
          </ul>
        </EdvanceCard>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-center justify-between gap-3">
            <span className="text-xs font-semibold uppercase tracking-widest text-warm-56">
              {t('session.goal.masteryLabel')}
            </span>
            <span className="text-xs font-semibold text-warm-72">
              {t('session.goal.estimateValue', { count: taskCount, minutes })}
            </span>
          </div>
          <div className="mt-3">
            <MasteryBar score={MOCK_SESSION_TOPIC.startScore} size="lg" showLabel />
          </div>
        </EdvanceCard>

        <SessionButton block onClick={() => dispatch({ type: 'START_TASKS' })}>
          {t('session.goal.cta')}
        </SessionButton>
      </div>
    </SessionShell>
  )
}
