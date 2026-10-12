import { useTranslation } from 'react-i18next'
import { montagVon } from '@/components/edvance/wochenNavigation.model'
import type { SlotsZiel } from '@/types/slotplan'
import { datumKurz, wochentagName } from '../slotsFormat'

export const zielKey = (z: { datum: string; zeit_id: string }): string => `${z.datum}|${z.zeit_id}`

/**
 * Gültige Ziele (nur aus slots_ziele, der Server hat alle Regeln geprüft) als kleines Raster:
 * Wochen untereinander, Mo–Fr nebeneinander, je Ziel ein Chip mit Uhrzeit und freien Plätzen.
 */
export function ZieleRaster({
  ziele,
  gewaehlt,
  onWahl,
}: {
  ziele: SlotsZiel[]
  gewaehlt: string | null
  onWahl: (ziel: SlotsZiel) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const wochen = [...new Set(ziele.map((z) => montagVon(z.datum)))].sort()

  if (ziele.length === 0) {
    return <p className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] px-4 py-4 text-sm text-[var(--color-text-secondary)]">{t('dialog.ziele.keine')}</p>
  }

  return (
    <div className="flex flex-col gap-2" role="group" aria-label={t('dialog.ziele.label')}>
      <div className="grid grid-cols-5 gap-1 text-xs font-semibold text-[var(--color-text-tertiary)]" aria-hidden="true">
        {[1, 2, 3, 4, 5].map((w) => (
          <span key={w} className="px-1">{wochentagName(w, i18n.language)}</span>
        ))}
      </div>
      {wochen.map((mo) => (
        <div key={mo} className="grid grid-cols-5 gap-1">
          {[0, 1, 2, 3, 4].map((i) => {
            const tagZiele = ziele.filter((z) => montagVon(z.datum) === mo && new Date(`${z.datum}T00:00:00Z`).getUTCDay() === i + 1)
            const datum = tagZiele[0]?.datum
            return (
              <div key={i} className="flex min-w-0 flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-1">
                {datum && <span className="px-1 text-xs tabular-nums text-[var(--color-text-tertiary)]">{datumKurz(datum, i18n.language)}</span>}
                {tagZiele.map((z) => {
                  const an = gewaehlt === zielKey(z)
                  return (
                    <button
                      key={zielKey(z)}
                      type="button"
                      aria-pressed={an}
                      aria-label={t('dialog.ziele.chipLabel', { datum: datumKurz(z.datum, i18n.language), beginn: z.beginn, count: z.frei })}
                      onClick={() => onWahl(z)}
                      className={`flex min-h-[44px] flex-col items-start justify-center rounded-[var(--radius-md)] px-2 text-left transition-colors duration-150 ease-out ${
                        an
                          ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                          : 'bg-[var(--color-bg-surface)] text-[var(--color-text-primary)] hover:bg-[var(--color-primary-light)]'
                      }`}
                    >
                      <span className="text-sm font-semibold tabular-nums">{z.beginn}</span>
                      <span className={`text-xs tabular-nums ${an ? '' : 'text-[var(--color-text-tertiary)]'}`}>
                        {t('dialog.ziele.frei', { count: z.frei })}
                      </span>
                    </button>
                  )
                })}
              </div>
            )
          })}
        </div>
      ))}
    </div>
  )
}
