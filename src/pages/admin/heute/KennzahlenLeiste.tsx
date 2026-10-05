import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'

export type Kennzahl = {
  key: string
  label: string
  wert: string
  unterzeile: string
  ziel: string
}

/**
 * Die Kennzahlen als schmale Leiste: eine Karte, fünf Felder, ab
 * --container-heute-kpi Inhaltsbreite nebeneinander, darunter zwei Spalten.
 * Jedes Feld führt in seinen Bereich.
 */
export function KennzahlenLeiste({ zahlen }: { zahlen: Kennzahl[] }): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <EdvanceCard className="overflow-hidden p-0">
      <nav
        aria-label={t('heute.kpi.label')}
        className="grid grid-cols-2 gap-px bg-[var(--color-border)] @heute-kpi:grid-cols-5"
      >
        {zahlen.map((z, i) => (
          <Link
            key={z.key}
            to={z.ziel}
            className={`flex min-h-[44px] min-w-0 flex-col bg-[var(--color-bg-surface)] px-4 py-4 hover:bg-[var(--color-bg-subtle)] ${
              i === zahlen.length - 1 && zahlen.length % 2 === 1 ? 'col-span-2 @heute-kpi:col-span-1' : ''
            }`}
          >
            <span className="truncate text-xs font-semibold text-[var(--color-text-tertiary)]">{z.label}</span>
            <span className="truncate font-serif text-2xl font-semibold tabular-nums text-[var(--color-text-primary)]">
              {z.wert}
            </span>
            <span className="truncate text-xs text-[var(--color-text-secondary)]">{z.unterzeile}</span>
          </Link>
        ))}
      </nav>
    </EdvanceCard>
  )
}
