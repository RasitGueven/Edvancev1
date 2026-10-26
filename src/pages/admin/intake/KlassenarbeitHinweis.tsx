import { Info } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import type { IntakeFormState } from './formState'

/** Anker der Felder „Klassenarbeit“ im Erstgespräch (KlassenarbeitFelder). */
export const KLASSENARBEIT_ANKER = 'erstgespraech-klassenarbeit'

/**
 * LSA-L4 (Entscheidung 15): Vor der LSA-Freigabe ein Hinweis, wenn der Stand der letzten Klassenarbeit im
 * Erstgespräch fehlt (nichts gewählt oder „weiß nicht“). Dann startet die Analyse mit dem aktuellen Thema
 * (thema_zuerst). Kein Blocker; der Link führt zu den Feldern.
 */
export function KlassenarbeitHinweis({ form }: { form: IntakeFormState }): JSX.Element | null {
  const { t } = useTranslation('admin')
  if (form.klassenarbeit === 'bevorstehend' || form.klassenarbeit === 'geschrieben') return null
  return (
    <div
      role="status"
      data-testid="intake-ka-hinweis"
      className="flex flex-wrap items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] p-3 text-sm text-[var(--color-text-primary)]"
    >
      <Info className="h-4 w-4 shrink-0 text-[var(--color-gold-warning)]" />
      <span>{t('intake.erstgespraech.klassenarbeit.fehltHinweis')}</span>
      <a
        href={`#${KLASSENARBEIT_ANKER}`}
        className="inline-flex min-h-[44px] items-center font-semibold text-[var(--color-primary)] underline"
        onClick={(e) => {
          e.preventDefault()
          document.getElementById(KLASSENARBEIT_ANKER)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }}
      >
        {t('intake.erstgespraech.klassenarbeit.fehltLink')}
      </a>
    </div>
  )
}
