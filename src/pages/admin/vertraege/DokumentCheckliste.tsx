import { ExternalLink } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import type { VertragDokument } from '@/types'
import { unterlagenUrl } from './vertragUi'

type DokumentChecklisteProps = {
  vertragId: string
  dokumente: VertragDokument[]
  /** Angehakte Dokumente: Schluessel -> Zeitpunkt des Hakens (ISO). */
  haken: Record<string, string>
  onToggle: (dok: VertragDokument, checked: boolean) => void
  disabled: boolean
}

/**
 * Ein eigenes Haekchen je Dokument, nie vorausgewaehlt; das Dokument oeffnet
 * in einem neuen Tab. Optionale Einwilligungen stehen in einem eigenen Bereich.
 */
export function DokumentCheckliste({
  vertragId,
  dokumente,
  haken,
  onToggle,
  disabled,
}: DokumentChecklisteProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const pflicht = dokumente.filter((d) => d.pflicht)
  const optional = dokumente.filter((d) => !d.pflicht)

  const zeile = (dok: VertragDokument): JSX.Element => (
    <li key={dok.schluessel} className="flex min-h-[44px] items-center justify-between gap-4">
      <label className="flex min-w-0 flex-1 items-center gap-2 text-sm text-[var(--color-text-primary)]">
        <input
          type="checkbox"
          checked={haken[dok.schluessel] !== undefined}
          disabled={disabled}
          onChange={(e) => onToggle(dok, e.target.checked)}
          className="h-5 w-5 shrink-0 rounded border-[var(--color-border)]"
        />
        <span className="min-w-0">
          {t('docs.accept', { titel: dok.titel })}
          <span className="block text-xs text-[var(--color-text-muted)]">
            {t('docs.version', { version: dok.version })}
          </span>
        </span>
      </label>
      <a
        href={unterlagenUrl(vertragId, dok.schluessel)}
        target="_blank"
        rel="noreferrer"
        className="inline-flex min-h-[44px] shrink-0 items-center gap-1 text-sm font-medium text-[var(--color-primary)] hover:underline"
      >
        {t('docs.open')}
        <ExternalLink className="h-3.5 w-3.5" />
      </a>
    </li>
  )

  return (
    <div className="flex flex-col gap-4">
      <ul className="flex flex-col gap-2">{pflicht.map(zeile)}</ul>
      {optional.length > 0 && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
            {t('docs.optional')}
          </p>
          <ul className="flex flex-col gap-2">{optional.map(zeile)}</ul>
        </div>
      )}
    </div>
  )
}
