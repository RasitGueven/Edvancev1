import { Link } from 'react-router-dom'
import { RotateCcw } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import type { DurchklickStand } from '@/types'
import { durchklickGrund, prozent } from './durchklickGrund'

/**
 * Hinweisbalken über dem Bogen einer nicht auswertbaren LSA (LSA-R2), nur am
 * Bildschirm. Nennt Grund und Kennzahlen und führt mit „LSA wiederholen“ in
 * den bestehenden Weg: der Lead im Erstgespräch, dort „LSA freigeben“
 * (lead_lsa_freigeben, nur Admin). Coaches sehen den Knopf gesperrt.
 */
export function NichtAuswertbarBalken({
  stand,
  leadId,
  darfFreigeben,
}: {
  stand: DurchklickStand | null
  leadId: string | null
  darfFreigeben: boolean
}): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const sperre = !darfFreigeben ? t('durchklick.balken.nurAdmin') : !leadId ? t('durchklick.balken.ohneLead') : null

  return (
    <div
      role="status"
      className="print-hide flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-gold-warning-light)] p-4 text-[var(--color-gold-warning)] md:flex-row md:items-center md:justify-between"
      data-testid="nicht-auswertbar-balken"
    >
      <div className="flex min-w-0 flex-col gap-2">
        <p className="text-sm font-semibold">{t('durchklick.balken.titel')}</p>
        <p className="text-sm">
          {t('durchklick.balken.text', { grund: durchklickGrund(t, i18n.language, stand) })}
        </p>
        {stand && (
          <p className="text-xs tabular-nums">
            {t('durchklick.balken.kennzahlen', {
              antworten: stand.antworten,
              schnellFalsch: stand.schnell_falsch,
              anteil: prozent(i18n.language, stand.anteil_schnell_falsch),
              folge: stand.folge_schnell_falsch_max,
            })}
          </p>
        )}
      </div>
      {sperre || !leadId ? (
        // Der Tooltip sitzt an der Hülle: ein deaktivierter Knopf meldet kein Hover.
        <span className="inline-flex shrink-0" title={sperre ?? undefined}>
          <Button type="button" disabled>
            <RotateCcw className="mr-2 h-4 w-4" aria-hidden />
            {t('durchklick.balken.wiederholen')}
          </Button>
        </span>
      ) : (
        <Button asChild className="shrink-0">
          <Link to={`/admin/leads?lead=${leadId}`}>
            <RotateCcw className="mr-2 h-4 w-4" aria-hidden />
            {t('durchklick.balken.wiederholen')}
          </Link>
        </Button>
      )}
    </div>
  )
}
