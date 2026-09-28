import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState } from '@/components/edvance'
import { formatDateOnly } from '@/lib/datetime'
import type { TierPlan, VertragAktuell } from '@/types'
import { formatEuro } from '../VertragForm'
import { STATUS_FARBE } from '../menue/statusFarben'

type Props = {
  /** Alle abgeschlossenen Verträge dieses Kindes, jüngster zuerst. */
  historie: VertragAktuell[]
  aktuellerId: string
  tiers: TierPlan[]
}

/**
 * Die Vertragsgeschichte des Kindes.
 *
 * Der Vorgänger bleibt erhalten (Entscheidung, abweichend vom Clickdummy) —
 * deshalb steht hier eine Kette und keine Löschung. Der gerade geöffnete
 * Vertrag ist markiert, die übrigen sind anklickbar.
 */
export function VertragHistorie({ historie, aktuellerId, tiers }: Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language

  if (historie.length <= 1) {
    return (
      <EmptyState
        icon="📚"
        title={t('detailansicht.historieLeer')}
        description={t('detailansicht.historieLeerHint')}
      />
    )
  }

  return (
    <ol className="flex flex-col gap-2">
      {historie.map((v) => {
        const hier = v.id === aktuellerId
        const inhalt = (
          <div className="flex flex-wrap items-center justify-between gap-2">
            <span className="text-sm text-[var(--color-text-primary)]">
              {v.vertragsbeginn ? formatDateOnly(v.vertragsbeginn, lang) : '—'}
              {' – '}
              {v.vertrag_ende ? formatDateOnly(v.vertrag_ende, lang) : '—'}
              {' · '}
              {tiers.find((x) => x.id === v.tier_id)?.name ?? '—'}
              {v.preis_cents !== null && ` · ${formatEuro(v.preis_cents, lang)}`}
            </span>
            <EdvanceBadge variant={STATUS_FARBE[v.wirksamer_status]}>
              {t(`menue.wirksam.${v.wirksamer_status}`)}
            </EdvanceBadge>
          </div>
        )
        return (
          <li
            key={v.id}
            className={`rounded-[var(--radius-md)] border p-3 ${
              hier
                ? 'border-[var(--color-primary)] bg-[var(--color-bg-app)]'
                : 'border-[var(--color-border)]'
            }`}
          >
            {hier ? (
              <>
                {inhalt}
                <span className="text-xs text-[var(--color-text-tertiary)]">
                  {t('detailansicht.dieserVertrag')}
                </span>
              </>
            ) : (
              <Link to={`/admin/vertraege/${v.id}/detail`} className="block hover:underline">
                {inhalt}
              </Link>
            )}
          </li>
        )
      })}
    </ol>
  )
}
