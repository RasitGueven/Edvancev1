import { FlaskConical } from 'lucide-react'
import { useTranslation } from 'react-i18next'

/**
 * Markiert eine LSA (spaeter auch eine Session) als Testlauf (Entscheidung 27).
 * Steht im Fluss, nicht schwebend — er verschiebt keinen Inhalt nachtraeglich,
 * weil er mit den Daten zusammen erscheint.
 */
export function TestlaufBanner(): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <div
      role="status"
      className="flex items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] p-3 text-sm text-[var(--color-text-primary)]"
    >
      <FlaskConical className="h-4 w-4 text-[var(--color-gold-warning)]" />
      <span className="font-semibold">{t('testmodus.banner.titel')}</span>
      <span className="text-[var(--color-text-secondary)]">{t('testmodus.banner.text')}</span>
    </div>
  )
}
