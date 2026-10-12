import { FlaskConical } from 'lucide-react'
import { useLiveTexte } from './useLiveTexte'

/**
 * T3: Im Testlauf kommen Hinweise, Musterloesungen und Fehlbilder auch ungeprueft. Der Kopf der Live-Sicht sagt das in
 * jeder Phase, im Stil des TestlaufBanner (Admin). Steht im Fluss, verschiebt nichts nachtraeglich. Am Tablet nichts.
 */
export function TestlaufUngeprueft(): JSX.Element {
  const { t } = useLiveTexte()
  return (
    <p
      role="status"
      data-testid="testlauf-hinweis"
      className="mx-5 mb-2 flex items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] px-3 py-2 text-sm font-semibold text-[var(--color-text-primary)]"
    >
      <FlaskConical className="h-4 w-4 flex-none text-[var(--color-gold-warning)]" aria-hidden />
      {t('kopf.testlaufHinweis')}
    </p>
  )
}
