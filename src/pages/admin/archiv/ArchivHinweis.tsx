import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'

type Props = { archiviertAm: string | null | undefined; grund: string | null | undefined }

/**
 * MSA-1 M3: Wer eine archivierte Aufgabe direkt über ihre Adresse aufruft, sieht sie mit diesem Hinweis und dem Weg
 * zum Wiederherstellen (Archiv-Seite), statt eines Fehlers. Ohne Archiv-Kennzeichen erscheint nichts.
 */
export function ArchivHinweis({ archiviertAm, grund }: Props): JSX.Element | null {
  const { t, i18n } = useTranslation('authoring')
  if (!archiviertAm) return null
  const am = new Intl.DateTimeFormat(i18n.language, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Europe/Berlin',
  }).format(new Date(archiviertAm))
  return (
    <EdvanceCard variant="subtle" className="p-6">
      <div className="flex flex-wrap items-center gap-4" role="status">
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {t('archiv.hinweis.text', { am, grund: t(`archiv.grund.${grund ?? 'sonstiges'}`) })}
        </p>
        <Link to="/admin/authoring/archiv" className="text-sm text-[var(--color-text-link)] hover:underline">
          {t('archiv.hinweis.link')}
        </Link>
      </div>
    </EdvanceCard>
  )
}
