import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { Button } from '@/components/ui/button'
import { formatDateOnly } from '@/lib/datetime'
import { imVerzug, kind, naechsteStufe, vertragspartner } from '@/lib/vertrag/menue'
import type { VertragAktuell } from '@/types'
import { formatEuro } from '../VertragForm'
import { STATUS_FARBE, ZAHLUNG_FARBE } from './statusFarben'

type Props = {
  vertraege: VertragAktuell[]
  busyId: string | null
  onNaechsteStufe: (v: VertragAktuell) => void
  onBezahlt: (v: VertragAktuell) => void
}

/**
 * Alles, was nicht in Ordnung ist — laengster Verzug zuoberst.
 *
 * Der Zahlungsstatus ist unabhaengig vom Vertragsstatus: ein Vertrag kann aktiv
 * und gleichzeitig in der 2. Mahnung sein (Anforderung E.26). Deshalb stehen
 * hier beide Spalten nebeneinander.
 */
export function ReiterVerzug({ vertraege, busyId, onNaechsteStufe, onBezahlt }: Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language
  const zeilen = imVerzug(vertraege)

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
      key: 'betrag',
      kopf: t('menue.spalte.betrag'),
      rechts: true,
      zelle: (v) => (v.preis_cents !== null ? formatEuro(v.preis_cents, lang) : '—'),
    },
    {
      key: 'offen',
      kopf: t('menue.spalte.offen'),
      rechts: true,
      zelle: (v) =>
        v.offener_betrag_cents !== null ? formatEuro(v.offener_betrag_cents, lang) : '—',
    },
    {
      key: 'stufe',
      kopf: t('menue.spalte.stufe'),
      zelle: (v) => (
        <div className="flex flex-col gap-1">
          <EdvanceBadge variant={ZAHLUNG_FARBE[v.zahlungsstatus]}>
            {t(`menue.zahlung.${v.zahlungsstatus}`)}
          </EdvanceBadge>
          {v.zahlungsstatus_seit && (
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {t('menue.seit', { date: formatDateOnly(v.zahlungsstatus_seit, lang) })}
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'vertrag',
      kopf: t('menue.spalte.status'),
      zelle: (v) => (
        <EdvanceBadge variant={STATUS_FARBE[v.wirksamer_status]}>
          {t(`menue.wirksam.${v.wirksamer_status}`)}
        </EdvanceBadge>
      ),
    },
    {
      key: 'aktionen',
      kopf: t('menue.spalte.aktionen'),
      rechts: true,
      zelle: (v) => {
        const weiter = naechsteStufe(v.zahlungsstatus)
        return (
          <div className="flex flex-wrap justify-end gap-2">
            <span title={weiter === null ? t('menue.keineStufeMehr') : undefined}>
              <Button
                size="sm"
                disabled={weiter === null || busyId === v.id}
                onClick={() => onNaechsteStufe(v)}
              >
                {t('menue.naechsteStufe')}
              </Button>
            </span>
            <Button
              size="sm"
              variant="outline"
              disabled={busyId === v.id}
              onClick={() => onBezahlt(v)}
            >
              {t('menue.bezahlt')}
            </Button>
          </div>
        )
      },
    },
  ]

  if (zeilen.length === 0) {
    return (
      <EmptyState icon="✅" title={t('menue.leer.verzug')} description={t('menue.leer.verzugHint')} />
    )
  }

  return (
    <EdvanceTable
      beschriftung={t('menue.reiter.verzug')}
      spalten={spalten}
      zeilen={zeilen}
      zeileKey={(v) => v.id}
    />
  )
}
