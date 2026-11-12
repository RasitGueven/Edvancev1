// Fortschritt der Liste „Session-Aufgaben prüfen“ (SP-1 S3): „n von 47 Bauformen geprüft“, daneben die Aufgaben, die
// zur Freigabe stehen, darunter ein Balken.
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import type { PruefFortschritt } from '@/lib/pruefung/bauformPlan'

export function PruefFortschrittKarte({ stand }: { stand: PruefFortschritt }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const anteil = stand.total ? Math.round((stand.geprueft / stand.total) * 100) : 0
  return (
    <EdvanceCard className="flex flex-col gap-4">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <span className="text-base font-semibold text-[var(--color-text-primary)] tabular-nums">
          {t('fortschritt.geprueft', { geprueft: stand.geprueft, total: stand.total })}
        </span>
        <span className="text-sm text-[var(--color-text-secondary)] tabular-nums">
          {stand.aufgabenZurFreigabe > 0
            ? t('fortschritt.zurFreigabe', { count: stand.aufgabenZurFreigabe })
            : t('fortschritt.keineZurFreigabe')}
        </span>
      </div>
      <div role="progressbar" aria-valuemin={0} aria-valuemax={stand.total} aria-valuenow={stand.geprueft}
        aria-label={t('fortschritt.geprueft', { geprueft: stand.geprueft, total: stand.total })}
        className="h-2 overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)]">
        <div className="h-full rounded-[var(--radius-full)] bg-[var(--color-primary)] transition-[width] duration-300 motion-reduce:transition-none"
          style={{ width: `${anteil}%` }} />
      </div>
    </EdvanceCard>
  )
}
