// Einstieg „Bauformen“ auf der Uebersicht „Aufgaben pruefen“ (Sessionreihe 1, A5): Lena prueft dort je Bauform.
import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Shapes } from 'lucide-react'
import { buttonVariants } from '@/components/ui/button'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'

export function BauformEinstieg(): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  return (
    <EdvanceCard className="flex flex-wrap items-center gap-4 p-4">
      <Shapes className="h-6 w-6 shrink-0 text-[var(--color-primary)]" aria-hidden="true" />
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <span className="text-base font-semibold text-[var(--color-text-primary)]">{t('liste.titel')}</span>
        <span className="text-sm text-[var(--color-text-secondary)]">{t('liste.satz')}</span>
      </div>
      <Link to="/coach/pruefen/bauformen" className={buttonVariants({ variant: 'outline', size: 'sm' })}>
        {t('liste.oeffnen')}
      </Link>
    </EdvanceCard>
  )
}
