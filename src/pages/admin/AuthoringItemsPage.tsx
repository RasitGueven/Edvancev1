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

import { useCallback, useEffect, useMemo, useRef, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Play } from 'lucide-react'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
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
import { EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { alleUmschalten, kopfZustand, umschalten } from '@/lib/authoring/auswahl'
import { neueReihe, reiheStarten } from '@/lib/pruefung/reihe'
import { SammelDialog } from './expertenliste/SammelDialog'
import { Sammelleiste } from './expertenliste/Sammelleiste'
import { LISTE_ZURUECK, useListenZustand } from './expertenliste/useListenZustand'
import { useSammelaktionen } from './expertenliste/useSammelaktionen'
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
  const { t: ta } = useTranslation('pruefenAdmin')
  const navigate = useNavigate()
  const anker = useRef<HTMLDivElement>(null)

  const [rows, setRows] = useState<ItemRowData[]>([])
  const [clusters, setClusters] = useState<AuthoringCluster[]>([])
  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  // ?status= als Startwert (Startseite „Heute“: ?status=rueckfrage). Unbekannte
  // Werte zählen nicht, der Filter bleibt dann auf dem Standard.
  const [params] = useSearchParams()
  const [start] = useState<FilterState>(() => {
    const status = params.get('status')
    return status && Object.hasOwn(STATUS_ORDER, status) ? { ...EMPTY_FILTERS, status: status as TaskStatus } : EMPTY_FILTERS
  })
  // Filter, Auswahl und Scrollposition; „Schließen“ in der Prüfansicht stellt sie wieder her.
  const liste = useListenZustand(start, params.get('wiederherstellen') === '1', anker, !loading)
  const { filters, setFilters, auswahl, setAuswahl } = liste
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
  const imFilter = useMemo(() => visible.map((r) => r.task.id), [visible])
  const auswahlIds = useMemo(() => imFilter.filter((id) => auswahl.has(id)), [imFilter, auswahl])
  const kopf = kopfZustand(imFilter, auswahl)
  const zeileVon = useMemo(() => new Map(rows.map((r) => [r.task.id, r.task])), [rows])
  const skillVon = useCallback((id: string) => zeileVon.get(id)?.skill_key ?? null, [zeileVon])
  const sammel = useSammelaktionen({
    auswahlIds, skillVon, themen: [...zuordnung.values()], setFiltersRoh: liste.setFiltersRoh, setAuswahl,
    neuLaden: () => setReloadKey((k) => k + 1),
  })

  // Reihe fuer die Admin-Pruefansicht: der Filter (Durchlauf, Klick auf eine Zeile) oder die Auswahl.
  const filterText = [
    filters.status !== 'all' ? t(`status.${filters.status}`) : null,
    filters.thema !== 'all' ? themen.find((th) => th.key === filters.thema)?.label ?? null : null,
    filters.lena === 'nicht' ? t('lena.filterNichtBeiLena') : null,
    filters.search.trim() ? `„${filters.search.trim()}“` : null,
  ].filter(Boolean).join(' · ')
  const pruefen = (ids: string[], auswahlReihe: boolean, startId?: string): void => {
    if (ids.length === 0) return
    liste.merke()
    const label = auswahlReihe ? ta('reihe.auswahl')
      : ta('reihe.liste', { filter: filterText ? ta('reihe.filter', { filter: filterText }) : ta('reihe.alleAufgaben') })
    navigate(reiheStarten(neueReihe(ids, auswahlReihe ? 'auswahl' : 'liste', label, LISTE_ZURUECK), startId))
  }

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
      <ItemRow row={row} onOeffnen={() => pruefen(imFilter, false, row.task.id)}
        auswahl={{ an: auswahl.has(row.task.id), label: ta('liste.auswaehlen', { titel: row.task.title ?? '' }),
          onChange: () => setAuswahl(umschalten(auswahl, row.task.id)) }} />
      <LenaInfo taskId={row.task.id} zeile={lena.get(row.task.id)} onReload={() => setReloadKey((k) => k + 1)}
        fehlbildName={(slug) => fehlbilder.find((f) => f.slug === slug)?.klartext ?? slug} />
    </div>
  )

  return (
    <>
      <PageHeader
        rubrik={t('page.listTitle')}
        titel={t('board.expertenliste')}
        satz={t('list.count', { shown: visible.length, total: rows.length })}
        zurueckZu="/admin/authoring"
        zurueckLabel={t('page.backToList')}
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
          {/* Kopf der Liste: „Alle im Filter (n)“ (halb markiert bei Teilauswahl) und der Durchlauf. */}
          <div className="flex flex-wrap items-center justify-between gap-3">
            <label className="flex min-h-[44px] cursor-pointer items-center gap-3 text-sm font-semibold text-[var(--color-text-primary)]">
              <input type="checkbox" className="h-5 w-5 accent-[var(--color-primary)]" checked={kopf === 'alle'}
                ref={(el) => { if (el) el.indeterminate = kopf === 'teil' }}
                onChange={() => setAuswahl(alleUmschalten(imFilter, auswahl))} />
              {ta('liste.alleImFilter', { count: imFilter.length })}
            </label>
            <Button onClick={() => pruefen(imFilter, false)}>
              <Play className="h-4 w-4" aria-hidden="true" />
              {ta('liste.durchlauf', { count: visible.length })}
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
                    <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
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
      <div ref={anker} />
      {auswahlIds.length > 0 && (
        <Sammelleiste anzahl={auswahlIds.length} onAufheben={() => setAuswahl(new Set())}
          onPruefen={() => pruefen(auswahlIds, true)} onAktion={sammel.setDialog} />
      )}
      {sammel.dialog && (
        <SammelDialog aktion={sammel.dialog} ids={auswahlIds} lena={lena} fertigkeiten={sammel.fertigkeiten}
          zeile={(id) => {
            const task = zeileVon.get(id)
            return { titel: task?.title ?? id, thema: (task && themaVon(task, zuordnung)?.label) ?? t('board.ohneThema') }
          }}
          onClose={() => sammel.setDialog(null)} onFertig={sammel.fertig} />
      )}
      {(sammel.meldung || liste.hinweis) && (
        <EntscheidungsMeldung text={sammel.meldung?.text ?? ta('liste.auswahlAufgehoben')}
          onRueckgaengig={sammel.meldung?.aktion?.los} aktionLabel={sammel.meldung?.aktion?.label}
          onZu={() => { sammel.setMeldung(null); liste.setHinweis(null) }} />
      )}
    </>
  )
}
