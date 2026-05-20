import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  EdvanceBadge,
  EdvanceCard,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { ItemEditorModal } from '@/components/edvance/screening/ItemEditorModal'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import {
  listScreeningItems,
  setScreeningItemActive,
} from '@/lib/supabase/screeningItems'
import type { ScreeningItem, SkillCluster, Subject } from '@/types'

const SELECT_CLASS =
  'h-10 rounded-xl border border-[var(--border)] bg-[var(--card)] px-2 text-sm'

type Filter = 'all' | 'active' | 'inactive'
type V2Filter = 'all' | 'v2' | 'legacy'

function ItemCard({
  item,
  onEdit,
  onChanged,
}: {
  item: ScreeningItem
  onEdit: (i: ScreeningItem) => void
  onChanged: () => void
}): JSX.Element {
  const [busy, setBusy] = useState(false)
  const toggleActive = async (): Promise<void> => {
    setBusy(true)
    await setScreeningItemActive(item.id, !item.active)
    setBusy(false)
    onChanged()
  }
  return (
    <EdvanceCard className="flex flex-col gap-2 p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="text-sm font-semibold text-[var(--text-primary)]">
          {item.skill_label}{' '}
          <span className="text-[var(--text-muted)]">· {item.topic}</span>
        </span>
        <div className="flex flex-wrap items-center gap-2">
          {item.afb && (
            <EdvanceBadge variant="primary">AFB {item.afb}</EdvanceBadge>
          )}
          {item.phase && (
            <EdvanceBadge variant="muted">{item.phase}</EdvanceBadge>
          )}
          <EdvanceBadge variant="muted">L{item.level}</EdvanceBadge>
          <EdvanceBadge variant="muted">{item.input_type}</EdvanceBadge>
          <EdvanceBadge variant={item.active ? 'success' : 'muted'}>
            {item.active ? 'Aktiv' : 'Inaktiv'}
          </EdvanceBadge>
        </div>
      </div>
      <p className="line-clamp-2 text-sm text-[var(--text-secondary)]">
        {item.prompt}
      </p>
      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="outline" onClick={() => onEdit(item)}>
          Bearbeiten
        </Button>
        <Button
          size="sm"
          variant={item.active ? 'outline' : 'default'}
          disabled={busy}
          onClick={toggleActive}
        >
          {item.active ? 'Deaktivieren' : 'Aktivieren'}
        </Button>
      </div>
    </EdvanceCard>
  )
}

export function ScreeningItemsPage(): JSX.Element {
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [subjectId, setSubjectId] = useState('')
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [clusterId, setClusterId] = useState('')
  const [items, setItems] = useState<ScreeningItem[]>([])
  const [filter, setFilter] = useState<Filter>('all')
  const [v2Filter, setV2Filter] = useState<V2Filter>('all')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState<ScreeningItem | null>(null)
  const [modalOpen, setModalOpen] = useState(false)

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
    })
  }, [subjectId])

  useEffect(() => {
    setLoading(true)
    listScreeningItems(clusterId ? { clusterId } : {}).then(
      ({ data, error: err }) => {
        setItems(data ?? [])
        setError(err)
        setLoading(false)
      },
    )
  }, [clusterId])

  const reload = (): void => {
    listScreeningItems(clusterId ? { clusterId } : {}).then(
      ({ data, error: err }) => {
        setItems(data ?? [])
        setError(err)
      },
    )
  }

  const openCreate = (): void => {
    setEditing(null)
    setModalOpen(true)
  }
  const openEdit = (it: ScreeningItem): void => {
    setEditing(it)
    setModalOpen(true)
  }
  const onSaved = (): void => {
    setModalOpen(false)
    reload()
  }

  const shown = items.filter((i) => {
    if (filter === 'active' && !i.active) return false
    if (filter === 'inactive' && i.active) return false
    if (v2Filter === 'v2' && !(i.afb && i.phase)) return false
    if (v2Filter === 'legacy' && i.afb && i.phase) return false
    return true
  })

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Screening-Items" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/admin"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Admin
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Screening-Items
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Items reviewen, freigeben und neu anlegen. v2-Items haben AFB +
            Phase gesetzt.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <select
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
            className={SELECT_CLASS}
            value={clusterId}
            onChange={(e) => setClusterId(e.target.value)}
          >
            <option value="">Alle Cluster</option>
            {clusters.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
          <select
            className={SELECT_CLASS}
            value={filter}
            onChange={(e) => setFilter(e.target.value as Filter)}
          >
            <option value="all">Alle</option>
            <option value="active">Nur aktiv</option>
            <option value="inactive">Nur inaktiv</option>
          </select>
          <select
            className={SELECT_CLASS}
            value={v2Filter}
            onChange={(e) => setV2Filter(e.target.value as V2Filter)}
          >
            <option value="all">v1 + v2</option>
            <option value="v2">Nur v2</option>
            <option value="legacy">Nur Legacy</option>
          </select>
          <Button
            size="sm"
            onClick={openCreate}
            disabled={!clusterId}
            title={clusterId ? '' : 'Erst Cluster wählen, um anzulegen'}
            className="ml-auto"
          >
            <Plus className="mr-1 h-4 w-4" /> Neues Item
          </Button>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
          {shown.length} von {items.length} Items
          {clusterId ? ' (Cluster gefiltert)' : ' (alle Cluster)'}
        </p>

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : items.length === 0 ? (
          <EmptyState
            icon="📭"
            title="Noch keine Items in der Datenbank"
            description={
              clusterId
                ? 'Klicke „Neues Item", um den ersten Entwurf anzulegen.'
                : 'Wähle ein Cluster und lege das erste Item an.'
            }
          />
        ) : shown.length === 0 ? (
          <EmptyState
            icon="🔎"
            title="Keine Items für diesen Filter"
            description={'Setze den Status- oder v2-Filter auf „Alle".'}
          />
        ) : (
          <div className="flex flex-col gap-4">
            {shown.map((it) => (
              <ItemCard
                key={it.id}
                item={it}
                onEdit={openEdit}
                onChanged={reload}
              />
            ))}
          </div>
        )}
      </main>

      <ItemEditorModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onSaved={onSaved}
        item={editing}
        clusterId={clusterId || null}
      />
    </div>
  )
}
