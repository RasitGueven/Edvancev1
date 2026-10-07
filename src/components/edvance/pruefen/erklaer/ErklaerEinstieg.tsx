// Einstieg „Erklärungen“ auf der Uebersicht „Aufgaben pruefen“ (L6, Punkt 5): Lena prueft dort die
// Kernideen der Erklaersequenzen; ein Admin landet in seiner Freigabe-Liste.

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Lightbulb } from 'lucide-react'
import { buttonVariants } from '@/components/ui/button'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { useAuth } from '@/hooks/useAuth'
import { erklaerBasis } from '@/lib/pruefung/erklaerTexte'

export function ErklaerEinstieg(): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const { role } = useAuth()
  const admin = role === 'admin'
  return (
    <EdvanceCard className="flex flex-wrap items-center gap-4 p-4">
      <Lightbulb className="h-6 w-6 shrink-0 text-[var(--color-primary)]" aria-hidden="true" />
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <span className="text-base font-semibold text-[var(--color-text-primary)]">{t('einstieg.titel')}</span>
        <span className="text-sm text-[var(--color-text-secondary)]">{t('einstieg.text')}</span>
      </div>
      <Link to={erklaerBasis(admin ? 'admin' : 'lena')} className={buttonVariants({ variant: 'outline', size: 'sm' })}>
        {t(admin ? 'einstieg.adminOeffnen' : 'einstieg.oeffnen')}
      </Link>
    </EdvanceCard>
  )
}
