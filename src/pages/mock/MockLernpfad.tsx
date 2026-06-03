import type { JSX } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowLeft } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { LearningPathMap } from '@/components/edvance/LearningPathMap'
import { MOCK_LEARNING_PATH, type LevelStatus } from '@/lib/mocks/lernpfad'

const LEGEND: { status: LevelStatus; color: string; labelKey: string }[] = [
  { status: 'done', color: 'var(--color-mastery-mastered)', labelKey: 'firstSession.lernpfad.legendDone' },
  { status: 'current', color: 'var(--color-primary)', labelKey: 'firstSession.lernpfad.legendCurrent' },
  { status: 'locked', color: 'var(--color-bg-subtle)', labelKey: 'firstSession.lernpfad.legendLocked' },
]

export function MockLernpfad(): JSX.Element {
  const { t } = useTranslation('student')
  const navigate = useNavigate()

  // Klick auf ein freigeschaltetes Level startet die Session.
  const handleSelect = (): void => {
    navigate('/mock/first-session')
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mock · Lernpfad" sticky />

      <section className="relative overflow-hidden student-hero light-source">
        <div className="mx-auto max-w-2xl px-4 py-8 text-white">
          <p className="text-eyebrow opacity-70">
            {t('firstSession.lernpfad.eyebrow')}
          </p>
          <h1 className="text-display text-3xl mt-1.5 leading-none">
            {t('firstSession.lernpfad.title')}
          </h1>
          <p className="mt-2 max-w-md text-sm opacity-80">
            {t('firstSession.lernpfad.subtitle')}
          </p>

          <div className="mt-5 flex flex-wrap items-center gap-4">
            {LEGEND.map((l) => (
              <span key={l.status} className="flex items-center gap-2 text-xs opacity-90">
                <span
                  className="h-3 w-3 rounded-[var(--radius-full)] border border-white/40"
                  style={{ backgroundColor: l.color }}
                  aria-hidden="true"
                />
                {t(l.labelKey)}
              </span>
            ))}
          </div>
        </div>
      </section>

      <main className="mx-auto max-w-2xl px-4 py-10">
        <LearningPathMap
          nodes={MOCK_LEARNING_PATH}
          onSelectNode={handleSelect}
          labels={{
            locked: t('firstSession.lernpfad.locked'),
            current: t('firstSession.lernpfad.current'),
          }}
        />

        <div className="mt-8 flex justify-center">
          <Link
            to="/mock"
            className="inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
          >
            <ArrowLeft className="h-4 w-4" /> Mock-Index
          </Link>
        </div>
      </main>
    </div>
  )
}
