import { useEffect, useMemo, useState, type JSX, type ReactNode } from 'react'
import { Brain, ImageIcon, ListChecks } from 'lucide-react'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import {
  INITIAL_FILTER_STATE,
  TaskFilterBar,
  type TaskFilterState,
} from '@/components/edvance/tasks/TaskFilterBar'
import { TaskPreviewCard } from '@/components/edvance/tasks/TaskPreviewCard'
import { getMicroskillsByIds, getTasksBySource } from '@/lib/supabase/tasks'
import type { Microskill, Task } from '@/types'

const SOURCE = 'mathebuch_lambacher_8_nrw'

function filterTasks(tasks: Task[], state: TaskFilterState): Task[] {
  const q = state.search.trim().toLowerCase()
  return tasks.filter((t) => {
    if (q) {
      const haystack = `${t.title ?? ''} ${t.source_ref ?? ''}`.toLowerCase()
      if (!haystack.includes(q)) return false
    }
    if (state.contentTypes.size > 0 && !state.contentTypes.has(t.content_type)) return false
    if (state.cognitiveTypes.size > 0) {
      if (!t.cognitive_type || !state.cognitiveTypes.has(t.cognitive_type)) return false
    }
    if (state.difficulties.size > 0) {
      const d = t.difficulty ?? 0
      if (!state.difficulties.has(d)) return false
    }
    if (state.hasAssets && (!t.assets || t.assets.length === 0)) return false
    return true
  })
}

function StatPanel({
  value,
  label,
  icon,
  color = 'var(--color-primary)',
}: {
  value: number
  label: string
  icon: ReactNode
  color?: string
}): JSX.Element {
  return (
    <EdvanceCard className="flex items-center gap-4">
      <div
        className="flex h-12 w-12 flex-none items-center justify-center rounded-[var(--radius-lg)]"
        style={{
          backgroundColor: `color-mix(in srgb, ${color} 14%, white)`,
          color,
        }}
      >
        {icon}
      </div>
      <div className="min-w-0">
        <p className="text-2xl font-bold leading-none" style={{ color }}>
          {value}
        </p>
        <p className="mt-1 text-xs text-[var(--color-text-tertiary)]">{label}</p>
      </div>
    </EdvanceCard>
  )
}

export function LambacherPreview(): JSX.Element {
  const [tasks, setTasks] = useState<Task[]>([])
  const [microskills, setMicroskills] = useState<Map<string, Microskill>>(new Map())
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const [filter, setFilter] = useState<TaskFilterState>(INITIAL_FILTER_STATE)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setError(null)
    void (async () => {
      const taskResult = await getTasksBySource(SOURCE)
      if (cancelled) return
      if (taskResult.error) {
        setError(taskResult.error)
        setLoading(false)
        return
      }
      const list = taskResult.data ?? []
      setTasks(list)

      const ids = Array.from(
        new Set(list.map((t) => t.microskill_id).filter((id): id is string => !!id)),
      )
      if (ids.length > 0) {
        const msResult = await getMicroskillsByIds(ids)
        if (cancelled) return
        if (msResult.data) {
          const map = new Map<string, Microskill>()
          for (const ms of msResult.data) map.set(ms.id, ms)
          setMicroskills(map)
        }
      }
      setLoading(false)
    })()
    return () => {
      cancelled = true
    }
  }, [])

  const filtered = useMemo(() => filterTasks(tasks, filter), [tasks, filter])

  const stats = useMemo(() => {
    const withAssets = tasks.filter((t) => t.assets && t.assets.length > 0).length
    const withSolution = tasks.filter((t) => !!t.solution).length
    return { total: tasks.length, withAssets, withSolution }
  }, [tasks])

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Lambacher 8 NRW – Vorschau" />
      <main className="mx-auto max-w-4xl space-y-6 px-4 py-8">
        <EdvanceCard variant="hero-student" className="flex flex-col gap-2">
          <p className="text-xs font-semibold uppercase tracking-widest opacity-80">
            Mathebuch-Import
          </p>
          <h1 className="text-2xl font-bold leading-tight">
            Lambacher Schweizer 8 NRW — Aufgaben-Vorschau
          </h1>
          <p className="text-sm opacity-80">
            Quelle: <code className="font-mono">{SOURCE}</code>
          </p>
        </EdvanceCard>

        {!loading && !error && tasks.length > 0 && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <StatPanel
              value={stats.total}
              label="Aufgaben gesamt"
              icon={<ListChecks className="h-6 w-6" />}
            />
            <StatPanel
              value={stats.withAssets}
              label="Mit Abbildung"
              icon={<ImageIcon className="h-6 w-6" />}
              color="var(--color-success)"
            />
            <StatPanel
              value={stats.withSolution}
              label="Mit Lösung"
              icon={<Brain className="h-6 w-6" />}
              color="var(--color-gold-warning)"
            />
          </div>
        )}

        {!loading && !error && tasks.length > 0 && (
          <TaskFilterBar
            state={filter}
            onChange={setFilter}
            onReset={() => setFilter(INITIAL_FILTER_STATE)}
            totalCount={tasks.length}
            filteredCount={filtered.length}
          />
        )}

        {loading && <LoadingPulse lines={3} />}

        {error && (
          <EdvanceCard accent="exam">
            <p className="text-sm font-semibold text-[var(--color-error-exam)]">Fehler beim Laden</p>
            <p className="mt-1 text-sm text-[var(--color-text-secondary)]">{error}</p>
          </EdvanceCard>
        )}

        {!loading && !error && tasks.length === 0 && (
          <EmptyState
            icon="·"
            title="Noch keine Aufgaben importiert"
            description={`Keine Tasks aus Quelle "${SOURCE}" in der DB.`}
          />
        )}

        {!loading && !error && tasks.length > 0 && filtered.length === 0 && (
          <EmptyState
            icon="·"
            title="Keine Treffer"
            description="Mit den aktuellen Filtern findet sich keine Aufgabe. Setze Filter zurück, um alle Aufgaben zu sehen."
          />
        )}

        <div className="flex flex-col gap-4">
          {filtered.map((t) => {
            const ms = t.microskill_id ? microskills.get(t.microskill_id) : null
            return (
              <TaskPreviewCard
                key={t.id}
                task={t}
                microskillName={ms?.name ?? null}
                onTaskUpdated={(updated) =>
                  setTasks((prev) => prev.map((x) => (x.id === updated.id ? updated : x)))
                }
              />
            )
          })}
        </div>
      </main>
    </div>
  )
}
