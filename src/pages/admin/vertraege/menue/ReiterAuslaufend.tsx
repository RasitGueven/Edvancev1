import { useTranslation } from 'react-i18next'
import { EmptyState } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { formatDateOnly } from '@/lib/datetime'
import { SELECT_SM } from '@/lib/formStyles'
import { auslaufende, kind, vertragspartner } from '@/lib/vertrag/menue'
import type { TierPlan, VerlaengerungStatus, VertragAktuell } from '@/types'
import { formatEuro } from '../VertragForm'

/** 'verlaengert' fehlt bewusst: es entsteht nur aus dem Abschluss eines Folgevertrags. */
const WAEHLBAR: VerlaengerungStatus[] = [
  'offen',
  'kontaktiert',
  'gespraech_vereinbart',
  'keine_verlaengerung',
]

type Props = {
  vertraege: VertragAktuell[]
  tiers: TierPlan[]
  busyId: string | null
  onStatus: (v: VertragAktuell, status: VerlaengerungStatus) => void
  onWiedervorlage: (v: VertragAktuell, datum: string) => void
  /**
   * Warum "Neuer Vertrag" noch nicht geht. Ein Folgevertrag entsteht heute nur
   * aus einem Lead (vertrag_starten); aus einem bestehenden Vertrag heraus
   * fehlt der Weg. Gesperrt, aber mit Begruendung — ein Knopf, der nicht geht
   * und nicht sagt warum, ist am Empfang wertlos.
   */
  neuerVertragSperre: string | null
}

/**
 * Vertraege, die in den naechsten acht Wochen enden — naechstes Ende zuerst.
 *
 * Wer auf "keine Verlaengerung" stellt, bekommt den Pflichtgrund-Dialog und die
 * Zeile verschwindet danach aus der Liste (so filtert auslaufende()). Genauso
 * verschwindet sie, sobald ein Folgevertrag zustande kommt und der Abschluss
 * 'verlaengert' setzt.
 */
export function ReiterAuslaufend({
  vertraege,
  tiers,
  busyId,
  onStatus,
  onWiedervorlage,
  neuerVertragSperre,
}: Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language
  const zeilen = auslaufende(vertraege)

  const spalten: Spalte<VertragAktuell>[] = [
    {
      key: 'partner',
      kopf: t('menue.spalte.partner'),
      zelle: (v) => (
        <div className="flex flex-col">
          <span className="font-semibold">{vertragspartner(v) || '—'}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{kind(v) || '—'}</span>
        </div>
      ),
    },
    {
      key: 'ende',
      kopf: t('menue.spalte.endetAm'),
      zelle: (v) => (
        <div className="flex flex-col">
          <span className="font-semibold">
            {v.vertrag_ende ? formatDateOnly(v.vertrag_ende, lang) : '—'}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('menue.inTagen', { count: v.endet_in_tagen ?? 0 })}
          </span>
        </div>
      ),
    },
    {
      key: 'paket',
      kopf: t('field.tier_id'),
      zelle: (v) =>
        `${tiers.find((x) => x.id === v.tier_id)?.name ?? '—'} · ${
          v.preis_cents !== null ? formatEuro(v.preis_cents, lang) : '—'
        }`,
    },
    {
      key: 'verlaengerung',
      kopf: t('menue.spalte.verlaengerung'),
      zelle: (v) => (
        <select
          className={SELECT_SM}
          aria-label={t('menue.spalte.verlaengerung')}
          value={v.verlaengerung_status ?? 'offen'}
          disabled={busyId === v.id}
          onChange={(e) => onStatus(v, e.target.value as VerlaengerungStatus)}
        >
          {WAEHLBAR.map((s) => (
            <option key={s} value={s}>{t(`menue.verlaengerung.${s}`)}</option>
          ))}
        </select>
      ),
    },
    {
      key: 'wiedervorlage',
      kopf: t('menue.spalte.wiedervorlage'),
      zelle: (v) => (
        <Input
          type="date"
          className="max-w-[10rem]"
          aria-label={t('menue.spalte.wiedervorlage')}
          value={v.wiedervorlage_am ?? ''}
          disabled={busyId === v.id}
          onChange={(e) => onWiedervorlage(v, e.target.value)}
        />
      ),
    },
    {
      key: 'aktion',
      kopf: t('menue.spalte.aktionen'),
      rechts: true,
      zelle: (v) => (
        <span title={neuerVertragSperre ?? undefined}>
          <Button size="sm" disabled={neuerVertragSperre !== null || busyId === v.id}>
            {t('menue.neuerVertrag')}
          </Button>
        </span>
      ),
    },
  ]

  if (zeilen.length === 0) {
    return (
      <EmptyState
        icon="🗓️"
        title={t('menue.leer.auslaufend')}
        description={t('menue.leer.auslaufendHint')}
      />
    )
  }

  return (
    <EdvanceTable
      beschriftung={t('menue.reiter.auslaufend')}
      spalten={spalten}
      zeilen={zeilen}
      zeileKey={(v) => v.id}
    />
  )
}
