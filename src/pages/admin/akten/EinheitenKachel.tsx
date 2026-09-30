import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { datum, zahl1 } from '@/lib/akte/format'
import type { EinheitenStand } from '@/types'
import { AMPEL_BADGE } from './ampel'

const KACHEL_TITEL = 'text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]'

/**
 * Einheiten-Stand (Anforderung D). Alle Werte kommen aus einheiten_stand();
 * hier wird nur dargestellt. Die Balkenbreiten sind die einzigen berechneten
 * Werte (Anteil an den Einheiten) und deshalb dynamische Inline-Styles.
 */
export function EinheitenKachel({ stand }: { stand: EinheitenStand | null }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language

  if (!stand || stand.art === 'keiner') {
    return (
      <EdvanceCard className="flex flex-col gap-2 p-6">
        <h2 className={KACHEL_TITEL}>{t('einheiten.titel')}</h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('einheiten.keiner')}</p>
      </EdvanceCard>
    )
  }

  if (stand.art === 'vorher') {
    return (
      <EdvanceCard className="flex flex-col gap-2 p-6">
        <h2 className={KACHEL_TITEL}>{t('einheiten.titel')}</h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {t('einheiten.startet', {
            beginn: stand.beginn ? datum(stand.beginn, lang) : '—',
            einheiten: stand.einheiten ?? 0,
            stichtag: stand.stichtag ? datum(stand.stichtag, lang) : '—',
          })}
        </p>
      </EdvanceCard>
    )
  }

  const einheiten = stand.einheiten ?? 0
  const verbraucht = stand.verbraucht ?? 0
  const soll = stand.soll ?? 0
  const anteil = (wert: number): string =>
    `${einheiten > 0 ? Math.min(100, Math.max(0, (wert / einheiten) * 100)) : 0}%`
  const rueckstand = stand.rueckstand ?? 0

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className={KACHEL_TITEL}>{t('einheiten.titel')}</h2>
        {stand.ampel && <EdvanceBadge variant={AMPEL_BADGE[stand.ampel]}>{t(`ampel.${stand.ampel}`)}</EdvanceBadge>}
      </div>

      <p className="text-sm text-[var(--color-text-secondary)]">
        {t('einheiten.gesamt', { einheiten, stichtag: stand.stichtag ? datum(stand.stichtag, lang) : '—' })}
      </p>

      <div className="grid grid-cols-3 gap-4">
        <div className="flex flex-col gap-2">
          <span className="text-3xl font-bold text-[var(--color-text-primary)]">{verbraucht}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{t('einheiten.verbraucht')}</span>
        </div>
        <div className="flex flex-col gap-2">
          <span className="text-3xl font-bold text-[var(--color-text-primary)]">{stand.offen ?? 0}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{t('einheiten.offen')}</span>
        </div>
        <div className="flex flex-col gap-2">
          <span className="text-3xl font-bold text-[var(--color-text-primary)]">
            {stand.wochen_rest !== null ? zahl1(stand.wochen_rest, lang) : '—'}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{t('einheiten.wochen')}</span>
        </div>
      </div>

      <div
        role="img"
        aria-label={t('einheiten.balkenLabel', { verbraucht, einheiten, soll: zahl1(soll, lang) })}
        className="relative h-3 w-full rounded-full bg-[var(--color-bg-subtle)]"
      >
        <div className="h-3 rounded-full bg-[var(--color-primary)]" style={{ width: anteil(verbraucht) }} />
        <div
          className="absolute -top-1 h-5 w-0.5 bg-[var(--color-text-primary)]"
          style={{ left: anteil(soll) }}
          aria-hidden="true"
        />
      </div>

      <div className="flex flex-wrap gap-4 text-xs text-[var(--color-text-tertiary)]">
        <span>{t('einheiten.soll', { wert: zahl1(soll, lang) })}</span>
        <span>
          {rueckstand > 0
            ? t('einheiten.rueckstand', { wert: zahl1(rueckstand, lang) })
            : t('einheiten.vorsprung', { wert: zahl1(Math.abs(rueckstand), lang) })}
        </span>
      </div>

      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {t('einheiten.satz', {
          noetig: zahl1(stand.noetig_pro_woche ?? 0, lang),
          gleichmaessig: zahl1(stand.gleichmaessig_pro_woche ?? 0, lang),
        })}
      </p>
    </EdvanceCard>
  )
}
