import { useEffect, useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { formatBerlinDateTime } from '@/lib/datetime'
import { listTiers } from '@/lib/supabase/subscriptions'
import {
  getGlaeubigerId,
  getIban,
  getVertrag,
  getVertragNachweise,
  listVertragDokumente,
  type VertragNachweise,
} from '@/lib/supabase/vertraege'
import type { VertragDokument, VertragMitLead } from '@/types'
import { DokumentText } from './vertraege/DokumentText'
import { DOKUMENTE, fillDokument } from './vertraege/dokumente'
import { dokumentWerte } from './vertraege/dokumentWerte'

type Daten = {
  vertrag: VertragMitLead
  iban: string | null
  paket: string | null
  glaeubigerId: string | null
  dokumente: VertragDokument[]
  nachweise: VertragNachweise
}

// Dokumente mit Unterschriftsfeld: Vertrag und SEPA-Mandat.
const UNTERSCHRIFT_ART: Record<string, 'vertrag' | 'sepa_mandat'> = {
  vertrag: 'vertrag',
  sepa_mandat: 'sepa_mandat',
}

/**
 * Druckbare Unterlagen (/admin/vertraege/:id/unterlagen[?dok=schluessel]).
 * Ohne ?dok das ganze Paket, jedes Dokument auf eigener Seite. Vertrag und
 * SEPA-Mandat mit eingesetzten Formulardaten und — falls geleistet — der
 * Unterschrift. Ausgabe ueber den Browser-Druck (auch "Als PDF sichern").
 */
export function VertragUnterlagenPage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const [params] = useSearchParams()
  const nur = params.get('dok')
  const { t, i18n } = useTranslation('vertraege')
  const [daten, setDaten] = useState<Daten | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      const [v, iban, glaeubiger, dokumente, nachweise, tiers] = await Promise.all([
        getVertrag(id),
        getIban(id),
        getGlaeubigerId(),
        listVertragDokumente(),
        getVertragNachweise(id),
        listTiers(),
      ])
      const err = v.error ?? iban.error ?? glaeubiger.error ?? dokumente.error ?? nachweise.error
      if (err || !v.data || !nachweise.data) {
        setError(err)
        return
      }
      setDaten({
        vertrag: v.data,
        iban: iban.data ?? null,
        paket: (tiers.data ?? []).find((x) => x.id === v.data?.tier_id)?.name ?? null,
        glaeubigerId: glaeubiger.data ?? null,
        dokumente: dokumente.data ?? [],
        nachweise: nachweise.data,
      })
    })()
  }, [id])

  if (!daten) {
    return (
      <main className="mx-auto max-w-3xl px-4 py-8">
        {error ? <p className="text-sm text-[var(--color-error-exam)]">{error}</p> : <LoadingPulse type="card" />}
      </main>
    )
  }

  const werte = dokumentWerte({ ...daten, locale: i18n.language, t })
  const sichtbar = daten.dokumente.filter((d) => nur === null || d.schluessel === nur)

  return (
    <div className="min-h-screen bg-[var(--color-bg-surface)] font-[family-name:var(--font-body)]">
      <main className="mx-auto flex max-w-3xl flex-col gap-8 px-4 py-8 print:max-w-none print:p-0">
        <div className="flex items-center justify-between gap-4 print:hidden">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
            {t('docsView.title', { ref: daten.vertrag.mandatsreferenz })}
          </p>
          <Button onClick={() => window.print()}>
            <Printer className="h-4 w-4" />
            {t('docsView.print')}
          </Button>
        </div>

        {sichtbar.map((dok, index) => {
          const quelle = DOKUMENTE[dok.schluessel]
          const art = UNTERSCHRIFT_ART[dok.schluessel]
          const unterschrift = art
            ? daten.nachweise.unterschriften.find((u) => u.art === art)
            : undefined
          const zustimmung = daten.nachweise.zustimmungen.find(
            (z) => z.dokument_schluessel === dok.schluessel,
          )
          return (
            <article
              key={dok.schluessel}
              className={`flex flex-col gap-4 ${index > 0 ? 'print:break-before-page' : ''}`}
            >
              {!quelle || quelle.version !== dok.version ? (
                <p className="text-sm text-[var(--color-error-exam)]">
                  {t('docsView.versionMismatch', {
                    titel: dok.titel,
                    text: quelle?.version ?? '—',
                    db: dok.version,
                  })}
                </p>
              ) : (
                <DokumentText text={fillDokument(quelle.text, werte)} />
              )}
              <p className="text-xs text-[var(--color-text-muted)]">
                {t('docs.version', { version: dok.version })}
                {zustimmung &&
                  ` · ${t('docsView.accepted', {
                    date: formatBerlinDateTime(zustimmung.akzeptiert_at, i18n.language),
                  })}`}
              </p>
              {art && (
                <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
                  {unterschrift ? (
                    <>
                      <img src={unterschrift.signatur} alt={t(`art.${art}`)} className="h-20 w-auto self-start" />
                      <p className="text-xs text-[var(--color-text-muted)]">
                        {t('docsView.signedAt', {
                          date: formatBerlinDateTime(unterschrift.unterschrieben_at, i18n.language),
                        })}
                      </p>
                    </>
                  ) : (
                    <p className="pt-12 text-xs text-[var(--color-text-muted)]">{t('docsView.signLine')}</p>
                  )}
                </div>
              )}
            </article>
          )
        })}
      </main>
    </div>
  )
}
