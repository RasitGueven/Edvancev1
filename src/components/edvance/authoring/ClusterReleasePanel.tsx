// Die zweite Stufe der Freigabe: admin gibt je Themengebiet (Cluster) alles frei,
// was die Pruefer auf "Zur Freigabe" gesetzt haben (freigabe_cluster).
//
// Nur fuer admin sichtbar, nur Cluster mit mindestens einer review-Aufgabe.
// Unvollstaendige Aufgaben faellt das Gate heraus — sie bleiben auf review, die
// Meldung nennt die tatsaechlich freigegebene Zahl.

import { useMemo, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ShieldCheck } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { freigabeCluster } from '@/lib/supabase/freigabe'
import type { AuthoringCluster } from '@/lib/supabase/taskAuthoring'
import type { AuthoringTask } from '@/types'

export function ClusterReleasePanel({
  tasks,
  clusters,
  onDone,
}: {
  tasks: AuthoringTask[]
  clusters: AuthoringCluster[]
  onDone: () => void
}): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const { role } = useAuth()
  const [busy, setBusy] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)

  const offen = useMemo(() => {
    const zaehler = new Map<string, number>()
    for (const task of tasks) {
      if (task.status === 'review' && task.cluster_id) {
        zaehler.set(task.cluster_id, (zaehler.get(task.cluster_id) ?? 0) + 1)
      }
    }
    return clusters
      .filter((c) => zaehler.has(c.id))
      .map((c) => ({ cluster: c, count: zaehler.get(c.id) ?? 0 }))
  }, [tasks, clusters])

  if (role !== 'admin' || (offen.length === 0 && !meldung)) return null

  const freigeben = async (clusterId: string): Promise<void> => {
    setBusy(clusterId)
    setMeldung(null)
    const res = await freigabeCluster(clusterId)
    setBusy(null)
    if (res.error || res.data === null) {
      setMeldung(t('clusterRelease.failed', { error: res.error ?? '' }))
      return
    }
    setMeldung(`${t('clusterRelease.done', { count: res.data })} ${t('clusterRelease.skippedHint')}`)
    onDone()
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('clusterRelease.title')}
      </h2>
      {offen.map(({ cluster, count }) => (
        <div key={cluster.id} className="flex flex-wrap items-center justify-between gap-2">
          <span className="text-base font-semibold">{cluster.name}</span>
          <Button disabled={busy != null} onClick={() => void freigeben(cluster.id)}>
            <ShieldCheck className="h-4 w-4" aria-hidden="true" />
            {t('clusterRelease.button', { count })}
          </Button>
        </div>
      ))}
      {meldung && (
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{meldung}</p>
      )}
    </EdvanceCard>
  )
}
