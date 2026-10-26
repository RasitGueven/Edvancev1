import { Info } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import type { KaAbweichung, KaStand } from '@/types'

/**
 * LSA-L4 (Entscheidung 13): Der Bericht zeigt den Stand der Klassenarbeit beim LSA-Start. Hat sich das Erstgespräch
 * seitdem geändert, sagt dieser Hinweis das dem Admin. Nur am Bildschirm (print-hide), nie im Elternbericht.
 */
export function KaAbweichungHinweis({ abweichung }: { abweichung: KaAbweichung }): JSX.Element {
  const { t } = useTranslation('admin')
  const stand = (s: KaStand): string =>
    s.status === 'geschrieben'
      ? s.note !== null
        ? t('lsaReports.kaAbweichung.geschriebenNote', { note: s.note })
        : t('lsaReports.kaAbweichung.geschrieben')
      : s.status === 'bevorstehend'
        ? t('lsaReports.kaAbweichung.bevorstehend')
        : t('lsaReports.kaAbweichung.unbekannt')
  return (
    <div
      role="status"
      data-testid="ka-abweichung"
      className="print-hide flex items-start gap-2 rounded-[var(--radius-md)] border border-[var(--color-primary)] bg-[var(--color-bg-subtle)] p-3 text-sm text-[var(--color-text-primary)]"
    >
      <Info className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-primary)]" />
      <span>
        {t('lsaReports.kaAbweichung.text', { sitzung: stand(abweichung.sitzung), lead: stand(abweichung.lead) })}
      </span>
    </div>
  )
}
