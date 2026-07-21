// Content-Gesundheit — die Mängel-Übersicht des Item-Bestands.
//
// Zweck: der Pfleger sieht auf einen Blick, WO die Arbeit liegt, statt 299 Items
// einzeln zu öffnen. Reines Frontend über lesenden Queries (listAuthoringTasks,
// getGrounding) — keine Migration, kein neues Backend-Feld. Die Diagnose selbst
// steckt in src/lib/authoring/health.ts (rein, getestet); diese Seite lädt, zählt,
// filtert und rendert.
//
// Die eine Aktion: „Bildpfad entfernen" bei totem Pfad. Sie schreibt über den
// Editor-Update-Pfad (updateAuthoringTask) — sie löscht nur den Asset-Eintrag,
// nichts im Bucket, ist idempotent und Admin-only (RLS admin_write_tasks).

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ListChecks } from 'lucide-react'
import { AdminHeader, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { HealthOverview, type HealthFilter } from '@/components/edvance/authoring/HealthOverview'
import { HealthItemRow, type HealthItem } from '@/components/edvance/authoring/HealthItemRow'
import { getGrounding } from '@/lib/authoring/grounding'
import {
  computeDefects,
  countDefects,
  deadAssets,
  graphicLicenseHints,
  imageRefFinding,
  isDeadAssetUrl,
  type HealthDefect,
} from '@/lib/authoring/health'
import {
  listAuthoringTasks,
  probeAuthoringSchema,
  updateAuthoringTask,
} from '@/lib/supabase/taskAuthoring'
import { useAuth } from '@/hooks/useAuth'
import type { AuthoringTask, TaskStatus } from '@/types'

const EMPTY_STATUS_COUNTS: Record<TaskStatus, number> = { draft: 0, review: 0, ready: 0 }

function matches(item: HealthItem, filter: HealthFilter): boolean {
  if (filter === 'all') return item.defects.size > 0
  if (filter.startsWith('status:')) return item.task.status === filter.slice(7)
  return item.defects.has(filter as HealthDefect)
}

function buildItem(task: AuthoringTask, hasStoffanker: boolean): Omit<HealthItem, 'licenseStatus' | 'licenseHints'> {
  return {
    task,
    defects: computeDefects(task, hasStoffanker),
    dead: deadAssets(task),
    imageRef: imageRefFinding(task),
  }
}

export function ContentHealthPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()
  const { role } = useAuth()
  const canWrite = role === 'admin'

  const [items, setItems] = useState<HealthItem[]>([])
  const [hasStoffanker, setHasStoffanker] = useState(false)
  const [filter, setFilter] = useState<HealthFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [removingId, setRemovingId] = useState<string | null>(null)
  const [toast, setToast] = useState<{ key: number; type: 'success' | 'error'; message: string } | null>(null)

  const showToast = (type: 'success' | 'error', message: string) =>
    setToast((prev) => ({ key: (prev?.key ?? 0) + 1, type, message }))

  useEffect(() => {
    void (async () => {
      const [schema, taskRes] = await Promise.all([
        probeAuthoringSchema(),
        listAuthoringTasks(),
      ])
      setHasStoffanker(schema.hasStoffanker)
      if (taskRes.error || !taskRes.data) {
        setError(taskRes.error ?? t('health.loadError'))
        setLoading(false)
        return
      }

      const base = taskRes.data.map((task) => buildItem(task, schema.hasStoffanker))
      // Grounding nur für tote Pfade — der Index ist 600 KB und wird einmal geladen.
      const deadOnes = base.filter((i) => i.dead.length > 0)
      const records = await Promise.all(
        deadOnes.map((i) => getGrounding(i.task.source, i.task.source_ref)),
      )
      const byId = new Map(deadOnes.map((i, idx) => [i.task.id, records[idx]]))

      setItems(
        base.map((i) => {
          const record = byId.get(i.task.id) ?? null
          return {
            ...i,
            licenseStatus: record?.lizenz_status ?? null,
            licenseHints: graphicLicenseHints(record),
          }
        }),
      )
      setLoading(false)
    })()
  }, [t])

  const counts = useMemo(() => countDefects(items), [items])
  const statusCounts = useMemo(() => {
    const acc = { ...EMPTY_STATUS_COUNTS }
    for (const i of items) acc[i.task.status] += 1
    return acc
  }, [items])

  const visible = useMemo(() => {
    const filtered = items.filter((i) => matches(i, filter))
    return [...filtered].sort((a, b) => {
      const ad = a.defects.has('deadPath') ? 0 : 1
      const bd = b.defects.has('deadPath') ? 0 : 1
      if (ad !== bd) return ad - bd
      if (b.defects.size !== a.defects.size) return b.defects.size - a.defects.size
      return (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
    })
  }, [items, filter])

  async function handleRemovePath(taskId: string): Promise<void> {
    const item = items.find((i) => i.task.id === taskId)
    if (!item || removingId) return
    setRemovingId(taskId)
    const nextAssets = item.task.assets.filter((a) => !isDeadAssetUrl(a.url))
    const res = await updateAuthoringTask(taskId, { assets: nextAssets })
    setRemovingId(null)
    if (res.error || !res.data) {
      showToast('error', t('health.toast.removeFailed', { error: res.error ?? '' }))
      return
    }
    const updated = res.data
    setItems((prev) =>
      prev.map((i) =>
        i.task.id === taskId
          ? {
              ...i,
              task: updated,
              defects: computeDefects(updated, hasStoffanker),
              dead: deadAssets(updated),
              imageRef: imageRefFinding(updated),
            }
          : i,
      ),
    )
    showToast('success', t('health.toast.removed'))
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('health.subtitle')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-8 px-4 py-8">
        <AdminHeader
          eyebrow={t('health.eyebrow')}
          title={t('health.title')}
          backLabel={t('health.back')}
          description={t('health.count', { shown: visible.length, total: items.length })}
        />

        {error && <EmptyState icon="⚠️" title={t('health.errorTitle')} description={error} />}

        {!error && loading && <LoadingPulse type="list" lines={5} />}

        {!error && !loading && (
          <>
            <HealthOverview
              counts={counts}
              statusCounts={statusCounts}
              active={filter}
              onSelect={setFilter}
            />

            {visible.length === 0 ? (
              <EmptyState
                icon="✅"
                title={t('health.emptyTitle')}
                description={t('health.emptyDescription')}
              />
            ) : (
              <>
                {/* Der Einstieg in die Pflege-Strecke (A07): die aktive Mangel-
                    Kachel wird zur Warteschlange. */}
                <div className="flex justify-end">
                  <Button
                    onClick={() =>
                      navigate('/admin/pflege', {
                        state: {
                          ids: visible.map((item) => item.task.id),
                          label: t('wizard.sourceHealth'),
                        },
                      })
                    }
                  >
                    <ListChecks className="h-4 w-4" aria-hidden="true" />
                    {t('wizard.start', { count: visible.length })}
                  </Button>
                </div>
                <div className="flex flex-col gap-4">
                  {visible.map((item) => (
                    <HealthItemRow
                      key={item.task.id}
                      item={item}
                      canWrite={canWrite}
                      removing={removingId === item.task.id}
                      onRemovePath={handleRemovePath}
                    />
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </main>

      {toast && (
        <ToastBanner
          key={toast.key}
          type={toast.type}
          message={toast.message}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  )
}
