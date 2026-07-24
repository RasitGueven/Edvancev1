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
  listReviewMeta,
  probeAuthoringSchema,
  type AuthoringCluster,
  type ReviewMeta,
} from '@/lib/supabase/taskAuthoring'
import { freigabeMuster, freigabeZuruecknehmen } from '@/lib/supabase/freigabe'
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

const STATUS_ORDER: Record<TaskStatus, number> = {
  beanstandet: 0,
  draft: 1,
  review: 2,
  ready: 3,
}

/** Erhaelt die (bereits nach Skill sortierten) Zeilen als Gruppen [skill, rows]. */
function groupBySkill(rows: ItemRowData[]): [string, ItemRowData[]][] {
  const groups = new Map<string, ItemRowData[]>()
  for (const row of rows) {
    const key = row.task.skill_key ?? '—'
    const group = groups.get(key)
    if (group) group.push(row)
    else groups.set(key, [row])
  }
  return [...groups.entries()]
}

export function AuthoringItemsPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()

  const [rows, setRows] = useState<ItemRowData[]>([])
  const [clusters, setClusters] = useState<AuthoringCluster[]>([])
  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<FilterState>(EMPTY_FILTERS)
  const [meta, setMeta] = useState<Map<string, ReviewMeta>>(new Map())
  // Nach einer Sammelfreigabe hochzaehlen -> der Effekt laedt die Liste neu.
  const [reloadKey, setReloadKey] = useState(0)
  // skill_key der Gruppe, die gerade eine Aktion laeuft (Buttons sperren).
  const [gruppeBusy, setGruppeBusy] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      const [detected, taskRes, clusterRes, metaMap] = await Promise.all([
        probeAuthoringSchema(),
        listAuthoringTasks(),
        listClustersWithSubject(),
        // Faellt der RPC aus (A20 noch nicht eingespielt), bleibt die Liste
        // bedienbar — die Label-Filter finden dann nur nichts.
        listReviewMeta(),
      ])
      setSchema(detected)
      setClusters(clusterRes.data ?? [])
      setMeta(metaMap)
      if (taskRes.error || !taskRes.data) {
        setError(taskRes.error ?? t('list.errorTitle'))
        setLoading(false)
        return
      }
      setRows(taskRes.data.map((task) => buildRow(task, detected)))
      setLoading(false)
    })()
  }, [t, reloadKey])

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

  const skills = useMemo(
    () =>
      [
        ...new Set(rows.map((r) => r.task.skill_key).filter((s): s is string => Boolean(s))),
      ].sort(),
    [rows],
  )

  // Nur die tatsaechlich vergebenen Fehlbild-Slugs — die volle Registry waere
  // ein Dropdown voller Labels, die keine Aufgabe traegt.
  const labels = useMemo(
    () => [...new Set([...meta.values()].flatMap((m) => m.labels))].sort(),
    [meta],
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
      if (filters.skill !== 'all' && task.skill_key !== filters.skill) return false
      const rowMeta = meta.get(task.id)
      if (filters.fehlbild !== 'all' && !(rowMeta?.labels ?? []).includes(filters.fehlbild)) {
        return false
      }
      if (filters.labelIncomplete === 'yes' && !rowMeta?.hasIncomplete) return false
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
        case 'skill':
          // Nach Skill gruppiert (Aufgaben eines Skills stammen aus demselben
          // Muster — Lena arbeitet sie am Stueck durch). Ohne Skill nach unten.
          return (
            (a.task.skill_key ?? '￿').localeCompare(b.task.skill_key ?? '￿', 'de') ||
            (a.task.title ?? '').localeCompare(b.task.title ?? '', 'de')
          )
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
  }, [rows, filters, subjectOf, meta])

  /**
   * Sammelfreigabe einer Skill-Gruppe. Der Bestaetigungsdialog nennt die Anzahl
   * der DRAFT-Aufgaben (nur die koennen frei werden). Serverseitig hebt das Gate
   * unvollstaendige Items nicht mit — die Rueckgabe ist die echte Anzahl, die im
   * Anschluss gemeldet wird. Danach laedt die Liste neu.
   */
  const gruppeFreigeben = async (skill: string, draftCount: number): Promise<void> => {
    if (gruppeBusy) return
    if (!window.confirm(t('freigabe.confirmFreigeben', { skill, count: draftCount }))) return
    setGruppeBusy(skill)
    const res = await freigabeMuster(skill)
    setGruppeBusy(null)
    if (res.error || res.data === null) {
      window.alert(t('freigabe.fehler', { message: res.error ?? '' }))
      return
    }
    window.alert(t('freigabe.freigegeben', { count: res.data }))
    setReloadKey((k) => k + 1)
  }

  const gruppeZuruecknehmen = async (skill: string, readyCount: number): Promise<void> => {
    if (gruppeBusy) return
    if (!window.confirm(t('freigabe.confirmZuruecknehmen', { skill, count: readyCount }))) return
    setGruppeBusy(skill)
    const res = await freigabeZuruecknehmen(skill)
    setGruppeBusy(null)
    if (res.error || res.data === null) {
      window.alert(t('freigabe.fehler', { message: res.error ?? '' }))
      return
    }
    window.alert(t('freigabe.zurueckgenommen', { count: res.data }))
    setReloadKey((k) => k + 1)
  }

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
          skills={skills}
          labels={labels}
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
            {filters.sort === 'skill' ? (
              // Nach Skill gruppiert: je Skill eine Überschrift mit Anzahl —
              // Aufgaben eines Skills stammen aus demselben Muster.
              groupBySkill(visible).map(([skill, group]) => {
                const draftCount = group.filter((r) => r.task.status === 'draft').length
                const readyCount = group.filter((r) => r.task.status === 'ready').length
                return (
                  <div key={skill} className="flex flex-col gap-4">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                        {skill} · {group.length}
                      </h2>
                      <div className="flex items-center gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          disabled={gruppeBusy !== null || draftCount === 0}
                          onClick={() => void gruppeFreigeben(skill, draftCount)}
                        >
                          {t('freigabe.freigeben', { count: draftCount })}
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          disabled={gruppeBusy !== null || readyCount === 0}
                          onClick={() => void gruppeZuruecknehmen(skill, readyCount)}
                        >
                          {t('freigabe.zuruecknehmen')}
                        </Button>
                      </div>
                    </div>
                    {group.map((row) => (
                      <ItemRow key={row.task.id} row={row} />
                    ))}
                  </div>
                )
              })
            ) : (
              <div className="flex flex-col gap-4">
                {visible.map((row) => (
                  <ItemRow key={row.task.id} row={row} />
                ))}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
