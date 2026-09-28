import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listVertraegeAktuell } from '@/lib/supabase/vertraegeMenue'
import { kind, vertragspartner } from '@/lib/vertrag/menue'
import type { VertragAktuell } from '@/types'
import { STATUS_FARBE } from './vertraege/menue/statusFarben'

/**
 * Platzhalter der Vertragsdetailansicht (/admin/vertraege/:id/detail).
 *
 * Die vollstaendige Ansicht — IBAN aufdecken, Zugangscode, Archiv, Historie,
 * Widerruf und Sonderkuendigung — kommt mit P3b-2. Bis dahin steht hier, was
 * die Uebersichtszeile ohnehin schon zeigt, damit der Klick auf eine Zeile
 * nicht ins Leere fuehrt.
 */
export function VertragDetailPage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const { t } = useTranslation('vertraege')
  const [vertrag, setVertrag] = useState<VertragAktuell | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void listVertraegeAktuell().then(({ data, error: err }) => {
      setVertrag((data ?? []).find((v) => v.id === id) ?? null)
      setError(err)
      setLoading(false)
    })
  }, [id])

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-4xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('detail.eyebrow')}
          title={vertrag ? kind(vertrag) || '—' : t('detail.eyebrow')}
          description={t('menue.detailFolgt')}
          backTo="/admin/vertraege"
          backLabel={t('detail.back')}
          actions={
            vertrag ? (
              <EdvanceBadge variant={STATUS_FARBE[vertrag.wirksamer_status]}>
                {t(`menue.wirksam.${vertrag.wirksamer_status}`)}
              </EdvanceBadge>
            ) : undefined
          }
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="card" />
        ) : vertrag ? (
          <EdvanceCard className="flex flex-col gap-2 p-6">
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t('menue.spalte.partner')}: {vertragspartner(vertrag) || '—'}
            </p>
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t('form.child')}: {kind(vertrag) || '—'}
            </p>
            <p className="text-sm text-[var(--color-text-tertiary)]">{t('menue.detailFolgtHint')}</p>
          </EdvanceCard>
        ) : (
          <p className="text-sm text-[var(--color-text-tertiary)]">{t('menue.nichtGefunden')}</p>
        )}
      </main>
    </div>
  )
}
