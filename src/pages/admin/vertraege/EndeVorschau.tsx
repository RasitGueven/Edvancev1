import { useTranslation } from 'react-i18next'
import { formatDateOnly } from '@/lib/datetime'
import type { VertragEnde } from '@/lib/supabase/vertragEnde'

type EndeVorschauProps = {
  ende: VertragEnde | null
  fehler: string | null
  laufzeitMonate: number | null
}

/**
 * Die Rechnung offen zeigen (Anforderung A.4): welche Ferien in der Laufzeit
 * liegen, wie viele Tage das sind, und auf welches Datum sich das Ende dadurch
 * verschiebt.
 *
 * Die Zahlen kommen aus vertrag_ende_berechnen — auch hier in der Vorschau.
 * Waere es eine zweite Rechnung im Frontend, stuende auf dem Bildschirm
 * irgendwann etwas anderes als im Vertrag.
 */
export function EndeVorschau({ ende, fehler, laufzeitMonate }: EndeVorschauProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')

  if (fehler) {
    return (
      <div className="rounded-xl border border-[var(--color-error-exam)] bg-[var(--color-bg-app)] p-4">
        <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>
      </div>
    )
  }

  if (!ende) {
    return (
      <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-app)] p-4">
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('ende.pending')}</p>
      </div>
    )
  }

  const halbjahr = laufzeitMonate === 6

  return (
    <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-app)] p-4">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('ende.title')}
      </p>
      <p className="text-base font-semibold text-[var(--color-text-primary)]">
        {formatDateOnly(ende.ende, i18n.language)}
      </p>
      {halbjahr ? (
        <>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {t('ende.rechnung', {
              nominal: formatDateOnly(ende.nominal, i18n.language),
              tage: ende.ferientage,
              ende: formatDateOnly(ende.ende, i18n.language),
            })}
          </p>
          {ende.ferien.length > 0 && (
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {t('ende.ferien', { namen: ende.ferien.join(' · ') })}
            </p>
          )}
          <p className="text-sm text-[var(--color-text-secondary)]">{t('ende.beitraegeHalbjahr')}</p>
        </>
      ) : (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('ende.jahr')}</p>
      )}
    </div>
  )
}
