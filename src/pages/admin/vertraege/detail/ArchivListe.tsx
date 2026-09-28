import { useState } from 'react'
import { FileText, FileClock, ExternalLink } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { formatDateOnly } from '@/lib/datetime'
import { scanUrl, type ArchivDatei } from '@/lib/supabase/vertragScan'
import type { VertragDokument, VertragZustimmung } from '@/types'

type ArchivListeProps = {
  dateien: ArchivDatei[]
  zustimmungen: VertragZustimmung[]
  dokumente: VertragDokument[]
  onFehler: (text: string) => void
}

/**
 * Was zu diesem Vertrag archiviert ist.
 *
 * Drei Arten von Einträgen, und alle drei stehen da — auch die fehlenden:
 * hochgeladene Dateien (heute der Rücklauf-Scan), festgehaltene Fassungen aus
 * vertrag_zustimmungen, und die PDFs, die es noch nicht gibt. Letztere zu
 * verstecken hieße zu behaupten, das Archiv sei vollständig.
 */
export function ArchivListe({
  dateien,
  zustimmungen,
  dokumente,
  onFehler,
}: ArchivListeProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const [oeffnet, setOeffnet] = useState<string | null>(null)

  const oeffnen = async (pfad: string): Promise<void> => {
    setOeffnet(pfad)
    const { data, error } = await scanUrl(pfad)
    setOeffnet(null)
    if (error || !data) {
      onFehler(error ?? t('detailansicht.archivFehler'))
      return
    }
    window.open(data, '_blank', 'noopener')
  }

  const titel = (schluessel: string): string =>
    dokumente.find((d) => d.schluessel === schluessel)?.titel ?? schluessel

  return (
    <ul className="flex flex-col gap-2">
      {dateien.map((d) => (
        <li key={d.pfad} className="flex items-center justify-between gap-2">
          <span className="flex min-w-0 items-center gap-2 text-sm text-[var(--color-text-primary)]">
            <FileText className="h-4 w-4 shrink-0 text-[var(--color-success)]" />
            <span className="truncate">{d.name}</span>
          </span>
          <button
            type="button"
            disabled={oeffnet === d.pfad}
            onClick={() => void oeffnen(d.pfad)}
            className="inline-flex min-h-[44px] shrink-0 items-center gap-1 text-sm text-[var(--color-text-link)] hover:underline"
          >
            <ExternalLink className="h-4 w-4" />
            {t('detailansicht.oeffnen')}
          </button>
        </li>
      ))}

      {zustimmungen.map((z) => (
        <li
          key={`${z.dokument_schluessel}-${z.dokument_version}`}
          className="flex flex-col text-sm text-[var(--color-text-primary)]"
        >
          <span>{titel(z.dokument_schluessel)}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('detailansicht.fassung', {
              version: z.dokument_version,
              date: formatDateOnly(z.akzeptiert_at.slice(0, 10), i18n.language),
            })}
          </span>
        </li>
      ))}

      {/* Die erzeugten PDFs kommen mit P4. Sichtbar, aber als offen markiert. */}
      <li className="flex items-center gap-2 border-t border-[var(--color-border)] pt-2 text-sm text-[var(--color-text-tertiary)]">
        <FileClock className="h-4 w-4 shrink-0" />
        {t('detailansicht.pdfFolgt')}
      </li>
    </ul>
  )
}
