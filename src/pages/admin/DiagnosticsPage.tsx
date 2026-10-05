import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import {
  getClustersBySubject,
  getSubjects,
  getTasksByCluster,
} from '@/lib/supabase/tasks'
import type { SkillCluster, Subject, Task } from '@/types'
import { NewTaskForm } from './diagnostics/NewTaskForm'
import { TaskRow } from './diagnostics/TaskRow'
import { SELECT_CLASS } from './diagnostics/shared'

export function DiagnosticsPage(): JSX.Element {
  const { t } = useTranslation('admin')
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [subjectId, setSubjectId] = useState('')
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [clusterId, setClusterId] = useState('')
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    getSubjects().then(({ data }) => {
      setSubjects(data ?? [])
      if (data && data.length > 0) setSubjectId(data[0].id)
    })
  }, [])

  useEffect(() => {
    if (!subjectId) return
    getClustersBySubject(subjectId).then(({ data }) => {
      setClusters(data ?? [])
      setClusterId('')
      setTasks([])
    })
  }, [subjectId])

  const loadTasks = (cid: string): void => {
    setClusterId(cid)
    if (!cid) {
      setTasks([])
      return
    }
    setLoading(true)
    getTasksByCluster(cid).then(({ data, error: err }) => {
      setTasks(data ?? [])
      setError(err)
      setLoading(false)
    })
  }

  return (
    <>
      <PageHeader
        rubrik={t('nav.gruppe.inhalte')}
        titel={t('diagnostik.titel')}
        satz={t('diagnostik.satz')}
        zurueckZu="/admin/authoring"
        zurueckLabel={t('nav.itemPflege')}
      />

      {/* Formular und Aufgaben bleiben in Lesebreite und stehen links. */}
      <div className="flex flex-col gap-6 @4xl:max-w-3xl">
        <div className="flex flex-wrap gap-3">
          <select
            aria-label={t('diagnostik.fach')}
            className={SELECT_CLASS}
            value={subjectId}
            onChange={(e) => setSubjectId(e.target.value)}
          >
            {subjects.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
          <select
            aria-label={t('diagnostik.cluster')}
            className={SELECT_CLASS}
            value={clusterId}
            onChange={(e) => loadTasks(e.target.value)}
          >
            <option value="">{t('diagnostik.clusterOption')}</option>
            {clusters.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>

        <NewTaskForm
          clusters={clusters}
          onCreated={() => clusterId && loadTasks(clusterId)}
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : !clusterId ? (
          <EmptyState
            icon="🧪"
            title={t('diagnostik.ohneCluster.titel')}
            description={t('diagnostik.ohneCluster.beschreibung')}
          />
        ) : tasks.length === 0 ? (
          <EmptyState
            icon="📭"
            title={t('diagnostik.leer.titel')}
            description={t('diagnostik.leer.beschreibung')}
          />
        ) : (
          <div className="flex flex-col gap-4">
            {tasks.map((task) => (
              <TaskRow
                key={task.id}
                task={task}
                onSaved={() => clusterId && loadTasks(clusterId)}
              />
            ))}
          </div>
        )}
      </div>
    </>
  )
}
