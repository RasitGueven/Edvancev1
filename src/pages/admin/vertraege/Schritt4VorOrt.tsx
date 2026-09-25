import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { Zustimmung } from '@/lib/supabase/vertraege'
import type { VertragDokument } from '@/types'
import { DokumentCheckliste } from './DokumentCheckliste'
import { UnterschriftPanel } from './UnterschriftPanel'

type Schritt4VorOrtProps = {
  vertragId: string
  /** Alle aktiven Dokumente — die Fassung des Vertrags kommt separat dazu. */
  dokumente: VertragDokument[]
  datenSperre: string | null
  saving: boolean
  onAbschluss: (zustimmungen: Zustimmung[], signaturVertrag: string, signaturSepa: string) => void
}

/** Die vier Punkte zum Bestaetigen (Anforderung D.11). */
const BESTAETIGUNGEN = ['agb', 'datenschutz_vertrag', 'sepa_mandat', 'widerruf']

/**
 * Schritt 4, Weg A. Vier Haekchen, Unterschrift — und erst dann der
 * Abschluss. Der Hinweis benennt, was fehlt; ein Knopf, der nicht geht und
 * nicht sagt warum, ist am Empfang wertlos (Anforderung D.12).
 *
 * Die Fassung des Vertragsdokuments selbst wird NICHT abgehakt, sondern mit der
 * Unterschrift mitgeschickt: Wer unterschreibt, bestaetigt den Text, den er
 * unterschreibt. Die RPC verlangt sie trotzdem, damit im Nachweis alle
 * Pflichtfassungen stehen.
 */
export function Schritt4VorOrt({
  vertragId,
  dokumente,
  datenSperre,
  saving,
  onAbschluss,
}: Schritt4VorOrtProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const [haken, setHaken] = useState<Record<string, string>>({})
  const [signiert, setSigniert] = useState(false)

  const zuBestaetigen = dokumente.filter(
    (d) => BESTAETIGUNGEN.includes(d.schluessel) || !d.pflicht,
  )
  const offenePflicht = zuBestaetigen.filter(
    (d) => d.pflicht && haken[d.schluessel] === undefined,
  )

  const fehlt = [
    datenSperre,
    offenePflicht.length > 0 ? t('ways.blockedChecks') : null,
  ].filter((x): x is string => x !== null)

  const sperre = fehlt.length > 0 ? fehlt.join(' · ') : null

  const abschliessen = (signaturVertrag: string, signaturSepa: string): void => {
    // Alle gehakten Dokumente plus die Fassung des Vertrags selbst.
    const zustimmungen: Zustimmung[] = dokumente
      .filter((d) => haken[d.schluessel] !== undefined || (d.pflicht && d.schluessel === 'vertrag'))
      .map((d) => ({
        schluessel: d.schluessel,
        version: d.version,
        akzeptiert_at: haken[d.schluessel] ?? new Date().toISOString(),
      }))
    onAbschluss(zustimmungen, signaturVertrag, signaturSepa)
  }

  return (
    <div className="flex flex-col gap-4">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('docs.title')}
        </h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('docs.hint')}</p>
        <DokumentCheckliste
          vertragId={vertragId}
          dokumente={zuBestaetigen}
          haken={haken}
          disabled={saving}
          onToggle={(dok, checked) =>
            setHaken((h) => {
              const next = { ...h }
              if (checked) next[dok.schluessel] = new Date().toISOString()
              else delete next[dok.schluessel]
              return next
            })
          }
        />
      </EdvanceCard>

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('ways.sign')}
        </h2>
        {sperre && <p className="text-sm text-[var(--color-text-tertiary)]">{sperre}</p>}
        {signiert ? (
          <UnterschriftPanel
            saving={saving}
            onCancel={() => setSigniert(false)}
            onSign={abschliessen}
          />
        ) : (
          <span title={sperre ?? undefined}>
            <Button disabled={sperre !== null || saving} onClick={() => setSigniert(true)}>
              {t('wizard.toSignature')}
            </Button>
          </span>
        )}
      </EdvanceCard>
    </div>
  )
}
