import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import {
  listScreeningItems,
  setScreeningItemActive,
  updateScreeningItem,
} from '@/lib/supabase/screeningItems'
import type { ScreeningItem, ScreeningItemInput, SkillCluster, Subject } from '@/types'

const SELECT_CLASS =
  'h-10 rounded-xl border border-[var(--border)] bg-[var(--card)] px-2 text-sm'
const JSON_CLASS =
  'min-h-[88px] w-full rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 font-mono text-xs'

type Filter = 'all' | 'active' | 'inactive'

function ItemEditor({
  item,
  onSaved,
}: {
  item: ScreeningItem
  onSaved: () => void
}): JSX.Element {
  const [prompt, setPrompt] = useState(item.prompt)
  const [explanation, setExplanation] = useState(item.explanation ?? '')
  const [typical, setTypical] = useState(item.typical_errors.join('\n'))
  const [tolerance, setTolerance] = useState(
    item.tolerance == null ? '' : String(item.tolerance),
  )
  const [payloadStr, setPayloadStr] = useState(
    JSON.stringify(item.payload ?? null, null, 2),
  )
  const [canonicalStr, setCanonicalStr] = useState(
    JSON.stringify(item.canonical, null, 2),
  )
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const save = async (): Promise<void> => {
    let payload: unknown
    let canonical: unknown
    try {
      payload = payloadStr.trim() === '' ? null : JSON.parse(payloadStr)
      canonical = JSON.parse(canonicalStr)
    } catch {
      setError('payload/canonical ist kein gültiges JSON.')
      return
    }
    setBusy(true)
    setError(null)
    const patch: Partial<ScreeningItemInput> = {
      prompt: prompt.trim(),
      explanation: explanation.trim() === '' ? null : explanation.trim(),
      typical_errors: typical.split('\n').map((t) => t.trim()).filter(Boolean),
      tolerance: tolerance.trim() === '' ? null : Number(tolerance),
      payload,
      canonical,
    }
    const { error: err } = await updateScreeningItem(item.id, patch)
    setBusy(false)
    if (err) {
      setError(err)
      return
    }
    onSaved()
  }

  return (
    <div className="mt-3 flex flex-col gap-3 border-t border-[var(--border)] pt-3">
      <div className="flex flex-col gap-2">
        <Label htmlFor={`p-${item.id}`}>Frage</Label>
        <textarea
          id={`p-${item.id}`}
          className="min-h-[60px] rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm"
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
        />
      </div>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label>payload (JSON)</Label>
          <textarea
            className={JSON_CLASS}
            value={payloadStr}
            onChange={(e) => setPayloadStr(e.target.value)}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label>canonical (JSON)</Label>
          <textarea
            className={JSON_CLASS}
            value={canonicalStr}
            onChange={(e) => setCanonicalStr(e.target.value)}
          />
        </div>
      </div>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor={`tol-${item.id}`}>Toleranz (numeric)</Label>
          <Input
            id={`tol-${item.id}`}
            value={tolerance}
            onChange={(e) => setTolerance(e.target.value)}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor={`te-${item.id}`}>Typische Fehler (eine pro Zeile)</Label>
          <textarea
            id={`te-${item.id}`}
            className="min-h-[60px] rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm"
            value={typical}
            onChange={(e) => setTypical(e.target.value)}
          />
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor={`ex-${item.id}`}>Erklärung</Label>
        <textarea
          id={`ex-${item.id}`}
          className="min-h-[48px] rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm"
          value={explanation}
          onChange={(e) => setExplanation(e.target.value)}
        />
      </div>
      {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}
      <div>
        <Button size="sm" onClick={save} disabled={busy}>
          {busy ? 'Speichert…' : 'Speichern'}
        </Button>
      </div>
    </div>
  )
}

function ItemCard({
  item,
  onChanged,
}: {
  item: ScreeningItem
  onChanged: () => void
}): JSX.Element {
  const [open, setOpen] = useState(false)
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
        <div className="flex items-center gap-2">
          <EdvanceBadge variant="muted">L{item.level}</EdvanceBadge>
          <EdvanceBadge variant="muted">{item.input_type}</EdvanceBadge>
          <EdvanceBadge variant={item.active ? 'success' : 'muted'}>
            {item.active ? 'Aktiv' : 'Inaktiv'}
          </EdvanceBadge>
        </div>
      </div>
      <p className="text-sm text-[var(--text-secondary)] line-clamp-2">
        {item.prompt}
      </p>
      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="outline" onClick={() => setOpen((v) => !v)}>
          {open ? 'Schließen' : 'Bearbeiten'}
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
      {open && (
        <ItemEditor
          item={item}
          onSaved={() => {
            setOpen(false)
            onChanged()
          }}
        />
      )}
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
      setItems([])
    })
  }, [subjectId])

  const load = (cid: string): void => {
    setClusterId(cid)
    if (!cid) {
      setItems([])
      return
    }
    setLoading(true)
    listScreeningItems({ clusterId: cid }).then(({ data, error: err }) => {
      setItems(data ?? [])
      setError(err)
      setLoading(false)
    })
  }

  const shown = items.filter((i) =>
    filter === 'all' ? true : filter === 'active' ? i.active : !i.active,
  )

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
            Generierte Items reviewen und freigeben (nur aktive erscheinen im Screening).
          </p>
        </div>

        <div className="flex flex-wrap gap-3">
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
            onChange={(e) => load(e.target.value)}
          >
            <option value="">– Cluster wählen –</option>
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
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : !clusterId ? (
          <EmptyState
            icon="🧮"
            title="Cluster wählen"
            description="Wähle ein Cluster, um dessen Screening-Items zu reviewen."
          />
        ) : shown.length === 0 ? (
          <EmptyState
            icon="📭"
            title="Keine Items"
            description="Für diesen Cluster/Filter gibt es noch keine Items."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {shown.map((it) => (
              <ItemCard key={it.id} item={it} onChanged={() => load(clusterId)} />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
