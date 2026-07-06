import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react'
import { AvatarInitials, EdvanceCard } from '@/components/edvance'
import { MASTERY_STAGE_LABEL } from '@/lib/mastery'
import { displayStage } from '@/lib/mocks/sessionMachine'
import { cn } from '@/lib/utils'
import { SessionShell } from '../components/SessionShell'
import { SessionButton, STAGE_BG, STAGE_TEXT } from '@/components/student'
import { MOCK_SESSION_TOPIC, MOCK_SESSION_STUDENT } from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

/**
 * Screen 7 — Mastery-Moment. Sichtbarer Beweis „heute kann ich das": die
 * Mastery-Bar wächst durch die Stufen. „Gemeistert" erscheint nur, weil das
 * Thema `coachGranted` trägt (Hard Rule §6) — der Mock setzt es nie selbst.
 */
export function MasteryScreen({ dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const topic = MOCK_SESSION_TOPIC
  const stage = displayStage(topic.score, topic.coachGranted)

  const [width, setWidth] = useState(topic.startScore)
  useEffect(() => {
    const id = setTimeout(() => setWidth(topic.score), 250)
    return () => clearTimeout(id)
  }, [topic.score])

  return (
    <SessionShell center maxWidth="md">
      <div className="flex animate-fade-in flex-col gap-6 text-center">
        <div>
          <p className="text-eyebrow text-warm-56">{t('session.mastery.eyebrow')}</p>
          <h1 className="text-display mt-1 text-3xl text-warm">
            {t('session.mastery.title')}
          </h1>
          <p className="mt-2 text-base text-warm-72">
            {t('session.mastery.topic', { topic: topic.name })}
          </p>
        </div>

        <EdvanceCard variant="glass" className="text-warm">
          <div className="flex items-center justify-between">
            <span className="text-sm text-warm-72">{t('session.mastery.grew')}</span>
            <span className={cn('text-sm font-bold', STAGE_TEXT[stage])}>
              {MASTERY_STAGE_LABEL[stage]} · {topic.score}%
            </span>
          </div>
          <div className="mt-3 h-4 w-full overflow-hidden rounded-[var(--radius-full)] bg-white/15">
            <div
              className={cn('mastery-bar-fill h-full rounded-[var(--radius-full)]', STAGE_BG[stage])}
              style={{ width: `${width}%` }}
            />
          </div>
        </EdvanceCard>

        {topic.coachGranted ? (
          <EdvanceCard variant="glass" className="text-warm">
            <div className="flex items-center gap-3 text-left">
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-mastery-mastered)]">
                <Check className="h-5 w-5 text-warm" aria-hidden="true" />
              </span>
              <p className="flex-1 text-sm leading-relaxed text-warm">
                {t('session.mastery.coachConfirmed')}
              </p>
              <span className="flex items-center gap-2">
                <AvatarInitials name={MOCK_SESSION_STUDENT.coachName} size="sm" />
              </span>
            </div>
          </EdvanceCard>
        ) : (
          <p className="text-sm text-warm-72">{t('session.mastery.coachPending')}</p>
        )}

        <SessionButton block onClick={() => dispatch({ type: 'CONTINUE_FROM_MASTERY' })}>
          {t('session.mastery.cta')}
        </SessionButton>
      </div>
    </SessionShell>
  )
}
