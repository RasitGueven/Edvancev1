import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { RarityBadge } from '@/components/edvance'
import { SessionShell } from '../components/SessionShell'
import { SessionButton } from '@/components/student'
import { MOCK_BADGES, type MockBadge } from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

function EarnedBadge({ badge }: { badge: MockBadge }): JSX.Element {
  return (
    <div className="flex flex-col items-center gap-2 text-center">
      <RarityBadge rarity={badge.rarity} form={badge.form} size="md">
        {badge.icon}
      </RarityBadge>
      <span className="text-xs font-semibold text-warm">{badge.name}</span>
    </div>
  )
}

function LockedBadge({ badge }: { badge: MockBadge }): JSX.Element {
  const { t } = useTranslation('mock')
  return (
    <div className="flex flex-col items-center gap-2 text-center">
      <div className="opacity-40 grayscale">
        <RarityBadge rarity={badge.rarity} form={badge.form} size="md">
          ?
        </RarityBadge>
      </div>
      <span className="text-xs font-semibold text-warm-56">{t('session.trophies.lockedName')}</span>
      {badge.classHint !== undefined && (
        <span className="text-[10px] uppercase tracking-wider text-warm-42">
          {t('session.trophies.classHint', { grade: badge.classHint })}
        </span>
      )}
    </div>
  )
}

/**
 * Screen 10 — Trophäen / Badges. Verdient, nicht geschenkt (PlayStation-Logik):
 * erreichbar-aber-offen erscheint als Silhouette + „???" + Klassen-Hinweis,
 * Badges anderer Klassen sind komplett verborgen (nicht in den Mock-Daten).
 */
export function TrophiesScreen({ dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const earned = MOCK_BADGES.filter((b) => b.state === 'earned')
  const locked = MOCK_BADGES.filter((b) => b.state === 'achievable-locked')

  return (
    <SessionShell maxWidth="md" showExit>
      <div className="flex flex-col gap-6">
        <div>
          <p className="text-eyebrow text-warm-56">{t('session.trophies.eyebrow')}</p>
          <h1 className="text-display mt-1 text-3xl text-warm">
            {t('session.trophies.title')}
          </h1>
        </div>

        <section className="flex flex-col gap-4">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-warm-56">
            {t('session.trophies.earnedLabel')}
          </h2>
          <div className="grid grid-cols-3 gap-x-4 gap-y-6">
            {earned.map((b) => (
              <EarnedBadge key={b.id} badge={b} />
            ))}
          </div>
        </section>

        {locked.length > 0 && (
          <section className="flex flex-col gap-4">
            <h2 className="text-xs font-semibold uppercase tracking-widest text-warm-56">
              {t('session.trophies.lockedLabel')}
            </h2>
            <div className="grid grid-cols-3 gap-x-4 gap-y-6">
              {locked.map((b) => (
                <LockedBadge key={b.id} badge={b} />
              ))}
            </div>
          </section>
        )}

        <SessionButton block onClick={() => dispatch({ type: 'BACK_TO_HUB' })}>
          {t('session.trophies.cta')}
        </SessionButton>
      </div>
    </SessionShell>
  )
}
