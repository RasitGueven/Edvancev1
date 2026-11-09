import { Star } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import type { LsaAbdeckungZeile, LsaAmpel } from '@/types'

import { matrix, paketKey, type MatrixZeile } from './abdeckung'

/** Farben der Ampel nur aus Tokens (Coach-/Admin-Status: grün gut, gelb aufmerksam, rot handeln). */
export const AMPEL_KLASSE: Record<LsaAmpel, string> = {
  gruen: 'border-[var(--color-success)] bg-[var(--color-success-light)] text-[var(--color-text-primary)]',
  gelb: 'border-[var(--color-warning)] bg-[var(--color-warning-light)] text-[var(--color-text-primary)]',
  rot: 'border-[var(--color-error-coach)] bg-[var(--color-error-coach-light)] text-[var(--color-text-primary)]',
}

type Props = {
  zeilen: LsaAbdeckungZeile[]
  gewaehlt: string | null
  busyFokus: string | null
  onZelle: (z: LsaAbdeckungZeile) => void
  onFokus: (schuleId: string, an: boolean) => void
}

/**
 * Ampel-Matrix (F2 Punkt 2): Zeilen Schulen (Fokus oben, markiert), Spalten Pakete in Schuljahr-Reihenfolge, Zelle =
 * Ampel + Thema kurz, „geschätzt“ dezent. Klick öffnet das Paket. Der Stern schaltet den Fokus der Schule.
 */
export function AbdeckungMatrix({ zeilen, gewaehlt, busyFokus, onZelle, onFokus }: Props): JSX.Element {
  const { t } = useTranslation('admin')
  const m = matrix(zeilen)

  const zelle = (z: LsaAbdeckungZeile | null): JSX.Element | null => {
    if (!z) return null
    const aktiv = gewaehlt === paketKey(z)
    return (
      <button
        type="button"
        onClick={() => onZelle(z)}
        aria-pressed={aktiv}
        aria-label={t('lsaAbdeckung.zelleAria', { thema: z.thema_labels.join(', '), ampel: t(`lsaAbdeckung.ampel.${z.ampel}`) })}
        data-testid={`zelle-${paketKey(z)}`}
        className={`flex min-h-[44px] w-full min-w-[7.5rem] flex-col items-start gap-1 rounded-[var(--radius-md)] border px-2 py-1 text-left text-xs ${AMPEL_KLASSE[z.ampel]} ${
          aktiv ? 'ring-2 ring-[var(--color-primary)]' : ''
        }`}
      >
        <span className="line-clamp-2 font-semibold">{z.thema_labels.join(' · ')}</span>
        {z.quelle === 'geschaetzt' && <span className="text-[var(--color-text-tertiary)]">{t('lsaAbdeckung.geschaetzt')}</span>}
      </button>
    )
  }

  const spalten: Spalte<MatrixZeile>[] = [
    {
      key: 'schule',
      kopf: t('lsaAbdeckung.spalte.schule'),
      zelle: (r) => (
        <span className="flex items-center gap-2">
          <button
            type="button"
            disabled={busyFokus === r.schuleId}
            onClick={() => onFokus(r.schuleId, !r.fokus)}
            aria-pressed={r.fokus}
            aria-label={t(r.fokus ? 'lsaAbdeckung.fokusAus' : 'lsaAbdeckung.fokusAn', { schule: r.schule })}
            title={t(r.fokus ? 'lsaAbdeckung.fokusAus' : 'lsaAbdeckung.fokusAn', { schule: r.schule })}
            className="flex min-h-[44px] min-w-[44px] items-center justify-center rounded-[var(--radius-md)] hover:bg-[var(--color-bg-muted)]"
          >
            <Star
              aria-hidden
              className={`h-4 w-4 ${r.fokus ? 'fill-[var(--color-gold-warning)] text-[var(--color-gold-warning)]' : 'text-[var(--color-text-tertiary)]'}`}
            />
          </button>
          <span className="flex flex-col">
            <span className="font-semibold">{r.schule}</span>
            {r.fokus && <span className="text-xs text-[var(--color-text-tertiary)]">{t('lsaAbdeckung.fokus')}</span>}
          </span>
        </span>
      ),
    },
    ...Array.from({ length: m.spalten }, (_, i): Spalte<MatrixZeile> => ({
      key: `p${i}`,
      kopf: t('lsaAbdeckung.spalte.paket', { nr: i + 1 }),
      zelle: (r) => zelle(r.zellen[i] ?? null),
    })),
  ]

  return (
    <EdvanceTable
      beschriftung={t('lsaAbdeckung.matrix')}
      spalten={spalten}
      zeilen={m.zeilen}
      zeileKey={(r) => `${r.schuleId}:${r.klasse}`}
    />
  )
}
