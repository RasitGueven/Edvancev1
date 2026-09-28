import { useState } from 'react'
import { FileText, FileClock, ExternalLink, Loader2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { formatDateOnly } from '@/lib/datetime'
import type { VertragDatei } from '@/lib/supabase/vertragDateien'
import { scanUrl, type ArchivDatei } from '@/lib/supabase/vertragScan'
import type { VertragDokument, VertragZustimmung } from '@/types'

type ArchivListeProps = {
  dateien: ArchivDatei[]
  erzeugte: VertragDatei[]
  zustimmungen: VertragZustimmung[]
  dokumente: VertragDokument[]
  onPdfErzeugen: () => void
  /** Läuft gerade eine Aktion — dann ist der Knopf gesperrt. */
  erzeugt: boolean
  onFehler: (text: string) => void
}

/**
 * Was zu diesem Vertrag archiviert ist.
 *
 * Drei Arten von Einträgen, und alle drei stehen da — auch die fehlenden:
 * hochgeladene und erzeugte Dateien, festgehaltene Fassungen aus
 * vertrag_zustimmungen, und ein fehlendes Vertrags-PDF. Letzteres zu
 * verstecken hieße zu behaupten, das Archiv sei vollständig.
 *
 * Die Dateiliste kommt aus dem Bucket, die Herkunft aus vertrag_dateien. Was
 * ohne Eintrag dort liegt — der Rücklauf-Scan aus P2 — steht trotzdem in der
 * Liste, nur ohne Zeitstempel. Eine Datei zu verschweigen, weil die Tabelle
 * sie nicht kennt, wäre das falsche Ende von beiden.
 */
export function ArchivListe({
  dateien,
  erzeugte,
  zustimmungen,
  dokumente,
  onPdfErzeugen,
  erzeugt,
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

  const herkunft = (pfad: string): string | null => {
    const e = erzeugte.find((x) => x.pfad === pfad)
    if (!e) return null
    return t('detailansicht.erzeugtAm', {
      date: formatDateOnly(e.erzeugtAm.slice(0, 10), i18n.language),
    })
  }

  const hatPdf = erzeugte.some((e) => e.art === 'vertrag')

  return (
    <ul className="flex flex-col gap-2">
      {dateien.map((d) => (
        <li key={d.pfad} className="flex items-center justify-between gap-2">
          <span className="flex min-w-0 flex-col">
            <span className="flex min-w-0 items-center gap-2 text-sm text-[var(--color-text-primary)]">
              <FileText className="h-4 w-4 shrink-0 text-[var(--color-success)]" />
              <span className="truncate">{d.name}</span>
            </span>
            {herkunft(d.pfad) !== null && (
              <span className="pl-6 text-xs text-[var(--color-text-tertiary)]">
                {herkunft(d.pfad)}
              </span>
            )}
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

      {!hatPdf && (
        <li className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-2">
          <span className="flex items-center gap-2 text-sm text-[var(--color-gold-warning)]">
            <FileClock className="h-4 w-4 shrink-0" />
            {t('detailansicht.pdfAusstehend')}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('detailansicht.pdfAusstehendHint')}
          </span>
          <Button size="sm" variant="outline" disabled={erzeugt} onClick={onPdfErzeugen}>
            {erzeugt && <Loader2 className="h-4 w-4 animate-spin" />}
            {t('detailansicht.pdfErzeugen')}
          </Button>
        </li>
      )}

      {/* SEPA-Mandat und die Fassungen der Unterlagen kommen mit P4a-2. */}
      <li className="flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
        {t('detailansicht.weitereFolgen')}
      </li>
    </ul>
  )
}
