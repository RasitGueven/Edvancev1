import { ZEITPUNKTE } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { LiveZeitpunkt } from '@/types/coachLive'
import { useLiveTexte } from './useLiveTexte'

/**
 * Nur im Beispielmodus: schmale Leiste zum Umschalten der sechs Zeitpunkte (wie im
 * Dummy). Verschwindet, sobald die Datenquelle echte Daten liefert (C2).
 */
export function BeispielLeiste({ zeitpunkt, onWaehle }: { zeitpunkt: LiveZeitpunkt; onWaehle: (z: LiveZeitpunkt) => void }): JSX.Element {
  const { t } = useLiveTexte()
  return (
    <div
      className="flex flex-none flex-wrap items-center gap-x-4 gap-y-2 border-b border-[var(--color-gold-altgold)]/50 bg-[var(--color-gold-warning-light)] px-5 py-1.5"
      data-testid="beispiel-leiste"
    >
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-gold-warning)]">{t('beispiel.titel')}</span>
      <div
        role="group"
        aria-label={t('beispiel.zeitpunkt')}
        className="inline-flex flex-wrap overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-neutral-unknown)] bg-[var(--color-bg-surface)]"
      >
        {ZEITPUNKTE.map((z) => (
          <button
            key={z}
            type="button"
            aria-pressed={zeitpunkt === z}
            onClick={() => onWaehle(z)}
            className={cn(
              'min-h-[44px] border-l border-[var(--color-neutral-unknown)] px-3 text-sm first:border-l-0',
              zeitpunkt === z
                ? 'bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]'
                : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]',
            )}
          >
            {t(`zeitpunkt.${z}`)}
          </button>
        ))}
      </div>
      <span className="hidden text-xs text-[var(--color-gold-warning)] voll:inline">{t('beispiel.hinweis')}</span>
    </div>
  )
}
