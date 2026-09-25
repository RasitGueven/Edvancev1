import { ExternalLink } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { VertragEnde } from '@/lib/supabase/vertragEnde'
import type { Vertrag, VertragDokument } from '@/types'
import { DokumentText } from './DokumentText'
import { DOKUMENTE, fillDokument } from './dokumente'
import { dokumentWerte } from './dokumentWerte'
import { openUnterlagen } from './vertragUi'

type Schritt2Props = {
  vertrag: Vertrag
  iban: string | null
  paket: string | null
  glaeubigerId: string | null
  dokumente: VertragDokument[]
  ende: VertragEnde | null
}

/**
 * Das fertige Vertragsdokument, so wie es an die Eltern geht (Anforderung B.6).
 *
 * Bewusst derselbe Text und dieselben Werte wie die Druckansicht — nicht eine
 * zweite, "fuer den Bildschirm aufbereitete" Fassung. Was hier steht, kommt
 * auch aus dem Drucker.
 */
export function Schritt2Dokument({
  vertrag,
  iban,
  paket,
  glaeubigerId,
  dokumente,
  ende,
}: Schritt2Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const vorlage = DOKUMENTE.vertrag
  const aktiv = dokumente.find((d) => d.schluessel === 'vertrag')

  const werte = {
    ...dokumentWerte({ vertrag, iban, paket, glaeubigerId, locale: i18n.language, t }),
    // Die Ferienklausel steht nur im Halbjahresvertrag (Anforderung B.7).
    ferienklausel:
      vertrag.laufzeit_monate === 6
        ? t('doc.ferienklausel', {
            einheiten: vertrag.einheiten ?? '—',
            ende: ende?.ende ?? '—',
            tage: ende?.ferientage ?? 0,
          })
        : t('doc.keineFerienklausel'),
    vertragsende: ende?.ende ?? null,
  }

  const versionPasst = aktiv === undefined || aktiv.version === vorlage.version

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
          {t('wizard.step2Title')}
        </h2>
        <Button size="sm" variant="outline" onClick={() => openUnterlagen(vertrag.id)}>
          <ExternalLink className="h-4 w-4" />
          {t('wizard.openAllDocs')}
        </Button>
      </div>

      {versionPasst ? (
        <DokumentText text={fillDokument(vorlage.text, werte)} />
      ) : (
        <p className="text-sm text-[var(--color-error-exam)]">
          {t('docsView.versionMismatch', {
            titel: aktiv.titel,
            text: vorlage.version,
            db: aktiv.version,
          })}
        </p>
      )}
    </EdvanceCard>
  )
}
