import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import type { Vertragsart } from '@/types'

/**
 * V5 (Entscheidung 8): Kennzeichen "Pilot" ueberall, wo ein Vertrag steht —
 * Vertragsliste, Detail, Schuelerakte, Slots. Regulaere Vertraege zeigen nichts.
 */
export function PilotKennzeichen({ art }: { art: Vertragsart | null | undefined }): JSX.Element | null {
  const { t } = useTranslation('vertraege')
  if (art !== 'pilot') return null
  return (
    <span title={t('pilot.kennzeichenTitel')}>
      <EdvanceBadge variant="primary">{t('pilot.kennzeichen')}</EdvanceBadge>
    </span>
  )
}
