// Die Raender der Pflege-Strecke: kein Einstieg ohne Warteschlange, und der
// Abschluss-Screen mit der Bilanz. Beide leben ausserhalb des Item-Flusses —
// deshalb eigene Datei, die Seite behaelt den Fluss.

import type { JSX, ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { buttonVariants } from '@/components/ui/button'

export type WizardOutcome = 'released' | 'reviewed' | 'skipped'

export function WizardShell({ children }: { children: ReactNode }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('wizard.subtitle')} sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">{children}</main>
    </div>
  )
}

export function NoQueueScreen(): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <WizardShell>
      <EmptyState
        icon="🧭"
        title={t('wizard.noQueueTitle')}
        description={t('wizard.noQueueDescription')}
      />
      <div className="flex flex-wrap justify-center gap-2">
        <Link to="/admin/authoring" className={buttonVariants({ variant: 'outline', size: 'sm' })}>
          {t('wizard.toList')}
        </Link>
        <Link
          to="/admin/content-gesundheit"
          className={buttonVariants({ variant: 'outline', size: 'sm' })}
        >
          {t('wizard.toHealth')}
        </Link>
      </div>
    </WizardShell>
  )
}

export function DoneScreen({
  total,
  outcomes,
}: {
  total: number
  outcomes: Record<string, WizardOutcome>
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const tally = Object.values(outcomes)
  const count = (o: WizardOutcome): number => tally.filter((x) => x === o).length
  return (
    <WizardShell>
      <EmptyState
        icon="🎉"
        title={t('wizard.done.title')}
        description={t('wizard.done.description', { total })}
      />
      <ul className="flex flex-col items-center gap-1 text-sm text-[var(--color-text-secondary)]">
        <li>{t('wizard.done.released', { count: count('released') })}</li>
        <li>{t('wizard.done.reviewed', { count: count('reviewed') })}</li>
        <li>{t('wizard.done.skipped', { count: count('skipped') })}</li>
      </ul>
      <div className="flex justify-center">
        <Link to="/admin/authoring" className={buttonVariants({ size: 'sm' })}>
          {t('wizard.done.backToList')}
        </Link>
      </div>
    </WizardShell>
  )
}
