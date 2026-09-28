import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { Button } from '@/components/ui/button'
import { formatDateOnly } from '@/lib/datetime'
import type { TierPlan, VertragMitLead } from '@/types'
import { kindName } from '../vertragModel'
import { ANTRAG_FARBE } from './statusFarben'

type Props = {
  antraege: VertragMitLead[]
  tiers: TierPlan[]
  zeigeAbgelehnte: boolean
  onZeigeAbgelehnte: (an: boolean) => void
  heute: string
  onFortsetzen: (v: VertragMitLead) => void
  onAblehnen: (v: VertragMitLead) => void
}

/**
 * Offene Antraege: in Vorbereitung und unterschrift_ausstehend. Ein Antrag ist
 * kein Vertrag — deshalb steht er nicht in der Uebersicht, sondern hier.
 *
 * "Fortsetzen" und "Einpflegen" fuehren beide auf dieselbe Seite: die Strecke
 * aus P2 entscheidet am Status selbst, ob sie das Formular oder das Einpflegen
 * zeigt. Zwei Knoepfe, weil am Empfang zwei verschiedene Dinge gemeint sind.
 */
export function ReiterAntraege({
  antraege,
  tiers,
  zeigeAbgelehnte,
  onZeigeAbgelehnte,
  heute,
  onFortsetzen,
  onAblehnen,
}: Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const { t: tl } = useTranslation('leads')
  const lang = i18n.language
  const sichtbar = antraege.filter((v) =>
    zeigeAbgelehnte ? true : v.status !== 'abgelehnt',
  )

  const spalten: Spalte<VertragMitLead>[] = [
    {
      key: 'partner',
      kopf: t('menue.spalte.partner'),
      zelle: (v) => (
        <div className="flex flex-col">
          <span className="font-semibold">
            {[v.eltern_vorname, v.eltern_nachname].filter(Boolean).join(' ') || '—'}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{kindName(v)}</span>
        </div>
      ),
    },
    {
      key: 'paket',
      kopf: t('field.tier_id'),
      zelle: (v) => tiers.find((x) => x.id === v.tier_id)?.name ?? '—',
    },
    {
      key: 'status',
      kopf: t('menue.spalte.status'),
      zelle: (v) => (
        <EdvanceBadge variant={ANTRAG_FARBE[v.status]}>{t(`status.${v.status}`)}</EdvanceBadge>
      ),
    },
    {
      key: 'rueckmeldung',
      kopf: t('menue.spalte.rueckmeldung'),
      zelle: (v) => {
        if (!v.rueckmeldung_bis) return '—'
        const ueberfaellig = v.rueckmeldung_bis < heute && v.status === 'unterschrift_ausstehend'
        return (
          <span
            className={
              ueberfaellig ? 'font-semibold text-[var(--color-error-exam)]' : undefined
            }
          >
            {formatDateOnly(v.rueckmeldung_bis, lang)}
            {ueberfaellig && ` · ${t('menue.ueberfaellig')}`}
          </span>
        )
      },
    },
    {
      key: 'aktionen',
      kopf: t('menue.spalte.aktionen'),
      rechts: true,
      zelle: (v) =>
        v.status === 'abgelehnt' ? (
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {v.abgelehnt_grund ? tl(`reasons.${v.abgelehnt_grund}`) : '—'}
          </span>
        ) : (
          <div className="flex flex-wrap justify-end gap-2">
            <Button size="sm" onClick={() => onFortsetzen(v)}>
              {v.status === 'unterschrift_ausstehend'
                ? t('card.einpflegen')
                : t('menue.fortsetzen')}
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="text-[var(--color-destructive)]"
              onClick={() => onAblehnen(v)}
            >
              {t('einpflegen.notConcluded')}
            </Button>
          </div>
        ),
    },
  ]

  return (
    <div className="flex flex-col gap-4">
      <label className="inline-flex min-h-[44px] w-fit items-center gap-2 text-sm text-[var(--color-text-secondary)]">
        <input
          type="checkbox"
          checked={zeigeAbgelehnte}
          onChange={(e) => onZeigeAbgelehnte(e.target.checked)}
        />
        {t('menue.zeigeAbgelehnte')}
      </label>

      {sichtbar.length === 0 ? (
        <EmptyState icon="📥" title={t('menue.leer.antraege')} description={t('menue.leer.antraegeHint')} />
      ) : (
        <EdvanceTable
          beschriftung={t('menue.reiter.antraege')}
          spalten={spalten}
          zeilen={sichtbar}
          zeileKey={(v) => v.id}
        />
      )}
    </div>
  )
}
