import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listTiers } from '@/lib/supabase/subscriptions'
import { listVertraege, vertragAblehnen } from '@/lib/supabase/vertraege'
import type { RejectionReason, VertragMitLead } from '@/types'
import { BoardColumns } from './leads/BoardColumns'
import { LeadFilterBar } from './leads/LeadFilterBar'
import { RejectModal } from './leads/RejectModal'
import { EMPTY_FILTERS, type LeadFilters } from './leads/boardModel'
import { VertragCard } from './vertraege/VertragCard'
import { VERTRAG_ARCHIV, VERTRAG_COLUMNS, kindName, vertraegeForColumn } from './vertraege/vertragModel'

/** Vertraege als Kanban: In Vorbereitung · Unterschrift ausstehend · Abgeschlossen (/admin/vertraege). */
export function VertraegePage(): JSX.Element {
  const { t } = useTranslation('vertraege')
  const [vertraege, setVertraege] = useState<VertragMitLead[]>([])
  const [paketById, setPaketById] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<LeadFilters>(EMPTY_FILTERS)
  const [showArchiv, setShowArchiv] = useState(false)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [rejectVertrag, setRejectVertrag] = useState<VertragMitLead | null>(null)

  const load = (): void => {
    void Promise.all([listVertraege(), listTiers()]).then(([v, tiers]) => {
      setVertraege(v.data ?? [])
      setPaketById(Object.fromEntries((tiers.data ?? []).map((x) => [x.id, x.name])))
      setError(v.error ?? tiers.error)
      setLoading(false)
    })
  }

  useEffect(load, [])

  const run = async (
    vertrag: VertragMitLead,
    action: () => Promise<{ error: string | null }>,
  ): Promise<boolean> => {
    if (busyId) return false
    setBusyId(vertrag.id)
    setError(null)
    const { error: err } = await action()
    setBusyId(null)
    if (err) setError(err)
    load()
    return err === null
  }

  const reject = async (reason: RejectionReason, note: string | null): Promise<void> => {
    if (!rejectVertrag) return
    const target = rejectVertrag
    if (await run(target, () => vertragAblehnen(target.id, reason, note))) setRejectVertrag(null)
  }

  const columns = showArchiv ? [...VERTRAG_COLUMNS, VERTRAG_ARCHIV] : VERTRAG_COLUMNS

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8">
        <AdminHeader eyebrow={t('page.eyebrow')} title={t('page.title')} description={t('page.description')} />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : vertraege.length === 0 ? (
          <EmptyState icon="📝" title={t('page.emptyTitle')} description={t('page.emptyDescription')} />
        ) : (
          <>
            <LeadFilterBar
              idPrefix="vertrag"
              filters={filters}
              onChange={(next) => setFilters((f) => ({ ...f, ...next }))}
              showDone={showArchiv}
              onToggleDone={setShowArchiv}
            />
            <BoardColumns
              maxFitting={3}
              columns={columns.map((column) => ({
                key: column.key,
                title: t(`columns.${column.key}.title`),
                emptyHint: t(`columns.${column.key}.empty`),
                items: vertraegeForColumn(vertraege, column, filters),
              }))}
              itemKey={(v) => v.id}
              renderItem={(v) => (
                <VertragCard
                  vertrag={v}
                  paket={v.tier_id ? (paketById[v.tier_id] ?? null) : null}
                  busy={busyId === v.id}
                  onReject={setRejectVertrag}
                />
              )}
            />
          </>
        )}
      </main>

      <RejectModal
        key={rejectVertrag?.id ?? 'none'}
        name={rejectVertrag ? kindName(rejectVertrag) : null}
        saving={busyId !== null}
        onClose={() => setRejectVertrag(null)}
        onConfirm={(reason, note) => void reject(reason, note)}
      />
    </div>
  )
}
