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
import { useNavigate, useSearchParams } from 'react-router-dom'
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
import { STUFEN, themaVon, zuordnungAus, type Zuordnung } from '@/lib/authoring/board'
import { filtereUndSortiere, groupBySkill, STATUS_ORDER } from '@/lib/authoring/itemFilter'
import { getFehlbilder, getPruefAdminListe } from '@/lib/supabase/pruefung'
import { LenaInfo } from '@/components/edvance/authoring/board/LenaInfo'
import {
  listAuthoringTasks,
  listClustersWithSubject,
  listReviewMeta,
  probeAuthoringSchema,
  type AuthoringCluster,
  type ReviewMeta,
} from '@/lib/supabase/taskAuthoring'
import { freigabeMuster, freigabeZuruecknehmen } from '@/lib/supabase/freigabe'
import { listSkillThemen } from '@/lib/supabase/themen'
import type { AuthoringSchema, AuthoringTask, Fehlbild, PruefAdminZeile, SkillThema, TaskSolution, TaskStatus } from '@/types'

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


export function AuthoringItemsPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()

  const [rows, setRows] = useState<ItemRowData[]>([])
  const [clusters, setClusters] = useState<AuthoringCluster[]>([])
  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  // ?status= als Startwert (Startseite „Heute“: ?status=rueckfrage). Unbekannte
  // Werte zählen nicht, der Filter bleibt dann auf dem Standard.
  const [params] = useSearchParams()
  const [filters, setFilters] = useState<FilterState>(() => {
    const status = params.get('status')
    return status && Object.hasOwn(STATUS_ORDER, status) ? { ...EMPTY_FILTERS, status: status as TaskStatus } : EMPTY_FILTERS
  })
  const [meta, setMeta] = useState<Map<string, ReviewMeta>>(new Map())
  const [zuordnung, setZuordnung] = useState<Zuordnung>(new Map())
  const [lena, setLena] = useState<Map<string, PruefAdminZeile>>(new Map())
  const [fehlbilder, setFehlbilder] = useState<Fehlbild[]>([])
  // Nach einer Sammelfreigabe hochzaehlen -> der Effekt laedt die Liste neu.
  const [reloadKey, setReloadKey] = useState(0)
  // skill_key der Gruppe, die gerade eine Aktion laeuft (Buttons sperren).
  const [gruppeBusy, setGruppeBusy] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      const [detected, taskRes, clusterRes, metaMap, themaRes, lenaRes, fehlbildRes] = await Promise.all([
        probeAuthoringSchema(),
        listAuthoringTasks(),
        listClustersWithSubject(),
        // Faellt der RPC aus (A20 noch nicht eingespielt), bleibt die Liste
        // bedienbar — die Label-Filter finden dann nur nichts.
        listReviewMeta(),
        listSkillThemen(),
        getPruefAdminListe(),
        getFehlbilder(),
      ])
      setLena(new Map((lenaRes.data ?? []).map((z) => [z.task_id, z])))
      setFehlbilder(fehlbildRes.data ?? [])
      setSchema(detected)
      setClusters(clusterRes.data ?? [])
      setZuordnung(zuordnungAus(themaRes.data ?? []))
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

  // Heimat-Themen der geladenen Aufgaben, nach Stufe und themen.sort (W4).
  const themen = useMemo(() => {
    const map = new Map<string, SkillThema>()
    for (const r of rows) {
      const th = themaVon(r.task, zuordnung)
      if (th) map.set(th.thema_key, th)
    }
    return [...map.values()]
      .sort((a, b) => STUFEN.indexOf(a.stufe) - STUFEN.indexOf(b.stufe) || (a.sort ?? 0) - (b.sort ?? 0))
      .map((th) => ({ key: th.thema_key, label: th.label }))
  }, [rows, zuordnung])

  // Nur die tatsaechlich vergebenen Fehlbild-Slugs — die volle Registry waere
  // ein Dropdown voller Labels, die keine Aufgabe traegt.
  const labels = useMemo(
    () => [...new Set([...meta.values()].flatMap((m) => m.labels))].sort(),
    [meta],
  )

  const visible = useMemo(
    () => filtereUndSortiere(rows, filters, { subjectOf, meta, zuordnung, lena }),
    [rows, filters, subjectOf, meta, zuordnung, lena],
  )

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

  // Lenas Ergebnis unter der Zeile (Lena-Board, Entscheidungen 39 und 42).
  const zeile = (row: ItemRowData): JSX.Element => (
    <div key={row.task.id} className="flex flex-col gap-2">
      <ItemRow row={row} />
      <LenaInfo taskId={row.task.id} zeile={lena.get(row.task.id)} onReload={() => setReloadKey((k) => k + 1)}
        fehlbildName={(slug) => fehlbilder.find((f) => f.slug === slug)?.klartext ?? slug} />
    </div>
  )

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
          themen={themen}
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
                    {group.map((row) => zeile(row))}
                  </div>
                )
              })
            ) : (
              <div className="flex flex-col gap-4">
                {visible.map((row) => zeile(row))}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
