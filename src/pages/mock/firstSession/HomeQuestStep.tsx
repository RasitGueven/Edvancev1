import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { EdvanceCard, EdvanceBadge, StreakPill } from '@/components/edvance'
import { cn } from '@/lib/utils'
import { MOCK_HOME_QUEST } from '@/lib/mocks/firstSession'

export function HomeQuestStep(): JSX.Element {
  const { t } = useTranslation('student')
  const navigate = useNavigate()
  const [accepted, setAccepted] = useState<boolean>(false)

  const handleAccept = (): void => {
    setAccepted(true)
    setTimeout(() => navigate('/mock'), 1200)
  }

  if (accepted) {
    return (
      <div className="flex flex-col items-center gap-3 py-12 text-center animate-fly-in">
        <span className="text-5xl leading-none">🎯</span>
        <h2 className="text-2xl font-bold text-[var(--color-text-primary)]">
          {t('firstSession.homeQuest.doneTitle')}
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {t('firstSession.homeQuest.doneSubtitle')}
        </p>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6 animate-fly-in">
      <div className="flex flex-col gap-2">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('firstSession.homeQuest.eyebrow')}
        </p>
        <h2 className="text-2xl font-bold text-[var(--color-text-primary)]">
          {t('firstSession.homeQuest.title')}
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {t('firstSession.homeQuest.explanation')}
        </p>
      </div>

      <div className="flex flex-col gap-3">
        {MOCK_HOME_QUEST.map((q) => (
          <EdvanceCard key={q.id} accent="skilltree">
            <div className="flex flex-col gap-2">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {q.clusterName}
              </p>
              <p className="text-base font-semibold text-[var(--color-text-primary)]">
                {q.title}
              </p>
              <div className="flex flex-wrap items-center gap-2">
                <EdvanceBadge variant="primary">
                  {t('firstSession.homeQuest.durationMin', { min: q.durationMin })}
                </EdvanceBadge>
                <EdvanceBadge variant="muted">AFB {q.difficulty}</EdvanceBadge>
              </div>
            </div>
          </EdvanceCard>
        ))}
      </div>

      <div className="flex justify-center">
        <StreakPill variant="home" count={1} />
      </div>

      <button
        type="button"
        onClick={handleAccept}
        className={cn(
          'min-h-[44px] w-full rounded-[var(--radius-lg)] px-6 py-3',
          'text-sm font-semibold text-white shadow-md transition-all duration-base',
          'bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)]',
        )}
      >
        {t('firstSession.homeQuest.accept')}
      </button>
    </div>
  )
}
