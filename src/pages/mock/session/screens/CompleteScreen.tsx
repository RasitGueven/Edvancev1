import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Home } from 'lucide-react'
import { AvatarInitials, EdvanceCard } from '@/components/edvance'
import { correctCount } from '@/lib/mocks/sessionMachine'
import { SessionShell } from '../components/SessionShell'
import { SessionButton } from '@/components/student'
import { WeekStreak, type DayState } from '../components/WeekStreak'
import { MOCK_SESSION_TOPIC, MOCK_SESSION_STUDENT } from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

/** Diese Woche nach der Session: heute ist erledigt (Kreis füllt sich). */
const WEEK_AFTER: DayState[] = [
  'done',
  'today-done',
  'empty',
  'empty',
  'empty',
  'empty',
  'empty',
]

/**
 * Screen 11 — Session-Abschluss. Recap, verdiente XP, Presence-Streak-Update,
 * Coach-Notiz (Mensch sichtbar), Brücke in die Home-Welt. Das Level-Up-Modal
 * (max 1×) liegt als Overlay darüber und wird vom Orchestrator gesteuert.
 */
export function CompleteScreen({ state, dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const student = MOCK_SESSION_STUDENT
  const earnedXp = state.xp - state.config.startXp
  const solved = correctCount(state)

  return (
    <SessionShell maxWidth="md" showExit>
      <div className="flex flex-col gap-6">
        <div className="text-center">
          <p className="text-eyebrow text-warm-56">{t('session.complete.eyebrow')}</p>
          <h1 className="text-display mt-1 text-3xl text-warm">
            {t('session.complete.title', { name: student.displayName })}
          </h1>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <EdvanceCard variant="glass" className="text-warm">
            <p className="text-xs font-semibold uppercase tracking-widest text-warm-56">
              {t('session.complete.recapMastered')}
            </p>
            <p className="mt-2 text-lg font-semibold">{MOCK_SESSION_TOPIC.name}</p>
          </EdvanceCard>
          <EdvanceCard variant="glass" className="text-warm">
            <p className="text-xs font-semibold uppercase tracking-widest text-warm-56">
              {t('session.complete.recapPracticed')}
            </p>
            <p className="mt-2 text-lg font-semibold">
              {solved}/{state.taskCount}
            </p>
          </EdvanceCard>
        </div>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-center justify-between gap-4">
            <span className="text-sm text-warm-72">{t('session.complete.xpLabel')}</span>
            <span className="animate-count-up text-3xl font-bold text-[var(--color-gold-champagner)]">
              +{earnedXp}
              <span className="ml-1 text-base text-warm-72">{t('session.common.xpUnit')}</span>
            </span>
          </div>
        </EdvanceCard>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-center justify-between gap-3">
            <span className="text-sm text-warm-72">{t('session.complete.streakLabel')}</span>
            <span className="text-xs font-semibold text-[var(--color-accent-streak)]">
              {t('session.complete.streakUpdated')}
            </span>
          </div>
          <div className="mt-3">
            <WeekStreak states={WEEK_AFTER} popIndex={1} />
          </div>
        </EdvanceCard>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-start gap-3">
            <AvatarInitials name={student.coachName} size="md" />
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-widest text-warm-56">
                {t('session.complete.coachNoteLabel', { coach: student.coachName })}
              </p>
              <p className="mt-1 text-sm leading-relaxed text-warm">{student.coachNote}</p>
            </div>
          </div>
        </EdvanceCard>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-start gap-3">
            <Home className="mt-0.5 h-5 w-5 shrink-0 text-[var(--color-accent-streak-light)]" aria-hidden="true" />
            <div>
              <p className="text-base font-semibold">{t('session.complete.bridgeTitle')}</p>
              <p className="mt-1 text-sm leading-relaxed text-warm-72">
                {t('session.complete.bridgeBody')}
              </p>
            </div>
          </div>
        </EdvanceCard>

        <SessionButton block onClick={() => dispatch({ type: 'RESTART' })}>
          {t('session.complete.cta')}
        </SessionButton>
      </div>
    </SessionShell>
  )
}
