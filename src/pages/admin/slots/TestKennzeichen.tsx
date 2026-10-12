import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'

/**
 * Kennzeichen „Test“ für Testkonten (SL2b, Entscheidung 2). Neutral (muted): ein Testkonto ist kein Zustand,
 * der Handeln verlangt. Der Satz dazu steht beim Darüberfahren.
 */
export function TestKennzeichen(): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span title={t('test.titel')} className="inline-flex">
      <EdvanceBadge variant="muted">{t('test.kennzeichen')}</EdvanceBadge>
    </span>
  )
}
