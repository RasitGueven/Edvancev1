// Die Liste der Item-Pflege — der Arbeitsvorrat.
//
// Sie laedt alle Items auf einmal und filtert im Client. Das ist Absicht: die Flags
// lassen sich nur aus dem Item selbst rechnen, und ein serverseitiger Statusfilter
// wuerde die Zaehler der ausgeblendeten Items verschweigen. Bei ~185 Zeilen ist das
// eine Handvoll KB.
//
// Was die Liste NICHT laedt: die Loesungen. Das waeren 185 RPC-Aufrufe. Die Zaehler
// hier sind deshalb ausdruecklich nur die STRUKTURELLEN Befunde (Stamm, Typ, AFB,
// Cluster, Stoffanker, Alt-Text, Teilaufgaben) — die Loesungsluecken zeigt der
// Editor. Ein Item mit "Vollstaendig" in der Liste kann im Editor trotzdem eine
// fehlende Loesung haben. Lieber diese Ehrlichkeit als ein Haken, der nichts
// bedeutet.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ListChecks } from 'lucide-react'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import {
  AuthoringFilters,
  EMPTY_FILTERS,
  type FilterState,
} from '@/components/edvance/authoring/AuthoringFilters'
import { ItemRow, type ItemRowData } from '@/components/edvance/authoring/ItemRow'
import { SchemaBanner } from '@/components/edvance/authoring/SchemaBanner'
import { computeFlags, hasTable } from '@/lib/authoring/flags'
import { isGroundedSource } from '@/lib/authoring/grounding'
import {
  listAuthoringTasks,
  listClustersWithSubject,
  probeAuthoringSchema,
  type AuthoringCluster,
} from '@/lib/supabase/taskAuthoring'
import type { AuthoringSchema, AuthoringTask, TaskSolution, TaskStatus } from '@/types'

/**
 * Die Liste kennt die Loesung nicht (siehe Kopf). computeFlags bekommt eine leere
 * Loesung — die Befunde, die daraus entstehen, filtern wir wieder heraus. Sonst
 * haette jedes Item "keine Loesung", nur weil wir nicht nachgesehen haben.
 */
const NO_SOLUTION: TaskSolution = {
  exists: false,
  correct_answers: [],
  solution: null,
  beleg: [],
  hints: [],
  coach_hints: [],
  typical_errors: [],
}

const SOLUTION_CODES = new Set([
  'solutionMissing',
  'solutionTextMissing',
  'typicalErrorsMissing',
  'partSolutionMissing',
])

function buildRow(task: AuthoringTask, schema: AuthoringSchema): ItemRowData {
  const flags = computeFlags(task, NO_SOLUTION, schema.hasStoffanker).filter(
    (f) => !SOLUTION_CODES.has(f.code),
  )
  return {
    task,
    flagCount: flags.length,
    blockingCount: flags.filter((f) => f.blocking).length,
    hasTable: hasTable(task.question),
  }
}

const STATUS_ORDER: Record<TaskStatus, number> = { draft: 0, review: 1, ready: 2 }

export function AuthoringItemsPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()

  const [rows, setRows] = useState<ItemRowData[]>([])
  const [clusters, setClusters] = useState<AuthoringCluster[]>([])
  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<FilterState>(EMPTY_FILTERS)

  useEffect(() => {
    void (async () => {
      const [detected, taskRes, clusterRes] = await Promise.all([
        probeAuthoringSchema(),
        listAuthoringTasks(),
        listClustersWithSubject(),
      ])
      setSchema(detected)
      setClusters(clusterRes.data ?? [])
      if (taskRes.error || !taskRes.data) {
        setError(taskRes.error ?? t('list.errorTitle'))
        setLoading(false)
        return
      }
      setRows(taskRes.data.map((task) => buildRow(task, detected)))
      setLoading(false)
    })()
  }, [t])

  const subjectOf = useMemo(() => {
    const map = new Map<string, string>()
    for (const c of clusters) map.set(c.id, c.subject_name)
    return map
  }, [clusters])

  const subjects = useMemo(
    () => [...new Set(clusters.map((c) => c.subject_name))].filter(Boolean).sort(),
    [clusters],
  )

  const competencies = useMemo(
    () =>
      [
        ...new Set(
          rows.map((r) => r.task.competency_content).filter((c): c is string => Boolean(c)),
        ),
      ].sort(),
    [rows],
  )

  const visible = useMemo(() => {
    const needle = filters.search.trim().toLowerCase()

    const filtered = rows.filter((row) => {
      const { task, flagCount, blockingCount } = row
      if (needle && !(task.title ?? '').toLowerCase().includes(needle)) return false
      if (filters.status !== 'all' && task.status !== filters.status) return false
      if (
        filters.subject !== 'all' &&
        subjectOf.get(task.cluster_id ?? '') !== filters.subject
      ) {
        return false
      }
      if (filters.competency !== 'all' && task.competency_content !== filters.competency) {
        return false
      }
      if (filters.afb !== 'all' && task.afb !== filters.afb) return false
      if (filters.source !== 'all') {
        const vera = isGroundedSource(task.source)
        if (filters.source === 'eigene' && vera) return false
        if (filters.source === 'vera' && !vera) return false
      }
      if (filters.flags === 'blocking' && blockingCount === 0) return false
      if (filters.flags === 'any' && flagCount === 0) return false
      if (filters.flags === 'none' && flagCount > 0) return false
      if (filters.asset === 'yes' && task.assets.length === 0) return false
      if (filters.asset === 'no' && task.assets.length > 0) return false
      if (filters.table === 'yes' && !row.hasTable) return false
      if (filters.table === 'no' && row.hasTable) return false
      return true
    })

    return [...filtered].sort((a, b) => {
      switch (filters.sort) {
        case 'title':
          return (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
        case 'status':
          return STATUS_ORDER[a.task.status] - STATUS_ORDER[b.task.status]
        case 'newest':
          return b.task.created_at.localeCompare(a.task.created_at)
        case 'flags':
        default:
          // Blockierendes zuerst — das ist die Arbeit, die wirklich ansteht.
          return (
            b.blockingCount - a.blockingCount ||
            b.flagCount - a.flagCount ||
            (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
          )
      }
    })
  }, [rows, filters, subjectOf])

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.listSubtitle')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          title={t('page.listTitle')}
          backLabel={t('page.back')}
          description={t('list.count', { shown: visible.length, total: rows.length })}
        />

        {schema && <SchemaBanner schema={schema} />}

        <AuthoringFilters
          value={filters}
          subjects={subjects}
          competencies={competencies}
          onChange={setFilters}
        />

        {error && <EmptyState icon="⚠️" title={t('list.errorTitle')} description={error} />}

        {!error && loading && <LoadingPulse type="list" lines={5} />}

        {!error && !loading && visible.length === 0 && (
          <EmptyState
            icon="🔍"
            title={t('list.emptyTitle')}
            description={t('list.emptyDescription')}
          />
        )}

        {!error && !loading && visible.length > 0 && (
          <>
            {/* Der Einstieg in die Pflege-Strecke (A07): der AKTIVE Filter wird
                zur Warteschlange — "diese 47 Items durcharbeiten". */}
            <div className="flex justify-end">
              <Button
                onClick={() =>
                  navigate('/admin/pflege', {
                    state: {
                      ids: visible.map((row) => row.task.id),
                      label: t('wizard.sourceList'),
                    },
                  })
                }
              >
                <ListChecks className="h-4 w-4" aria-hidden="true" />
                {t('wizard.start', { count: visible.length })}
              </Button>
            </div>
            <div className="flex flex-col gap-4">
              {visible.map((row) => (
                <ItemRow key={row.task.id} row={row} />
              ))}
            </div>
          </>
        )}
      </main>
    </div>
  )
}
