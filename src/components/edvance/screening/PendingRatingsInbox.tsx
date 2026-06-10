import { useEffect, useState, type JSX } from 'react'
import { Button } from '@/components/ui/button'
import { EdvanceCard, EdvanceBadge, EmptyState } from '@/components/edvance'
import { useAuth } from '@/hooks/useAuth'
import { listScreeningItemsByIds } from '@/lib/supabase/screeningItems'
import {
  createScreeningItemRating,
  listItemRatingsForResults,
} from '@/lib/supabase/screeningItemRatings'
import { getScreeningPhotoSignedUrls } from '@/lib/supabase/screeningUploads'
import type {
  ScreeningAfb,
  ScreeningItem,
  ScreeningItemRating,
  ScreeningItemResult,
} from '@/types'

const AFBS: ScreeningAfb[] = ['I', 'II', 'III']

type Props = {
  results: ScreeningItemResult[]
  clusterNames: Map<string, string>
}

function answerPreview(raw: unknown): string {
  if (raw === null || raw === undefined) return '—'
  if (typeof raw === 'string') return raw
  if (typeof raw === 'object') {
    const obj = raw as Record<string, unknown>
    if (typeof obj.text === 'string') return obj.text
    if (typeof obj.value === 'string' || typeof obj.value === 'number')
      return String(obj.value)
    if (obj.steps && typeof obj.steps === 'object') {
      return Object.entries(obj.steps as Record<string, unknown>)
        .map(([k, v]) => `${k}: ${typeof v === 'object' && v !== null ? JSON.stringify(v) : String(v)}`)
        .join(' · ')
    }
    if (obj.slots && typeof obj.slots === 'object') {
      return Object.entries(obj.slots as Record<string, unknown>)
        .map(([k, v]) => `${k} → ${String(v)}`)
        .join(' · ')
    }
    if (typeof obj.index === 'number') return `Auswahl ${obj.index + 1}`
    // Skizze allein ohne andere Antwort
    if (typeof obj.drawing === 'string') return '(nur Skizze)'
  }
  return JSON.stringify(raw)
}

function answerDrawing(raw: unknown): string | null {
  if (raw && typeof raw === 'object') {
    const d = (raw as Record<string, unknown>).drawing
    if (typeof d === 'string' && d.startsWith('data:image/')) return d
  }
  return null
}

function answerUploadPaths(raw: unknown): string[] {
  if (raw && typeof raw === 'object') {
    const u = (raw as Record<string, unknown>).uploads
    if (Array.isArray(u)) return u.filter((p): p is string => typeof p === 'string')
  }
  return []
}

export function PendingRatingsInbox({ results, clusterNames }: Props): JSX.Element {
  const { user } = useAuth()
  const pending = results.filter((r) => r.correct === null)
  const [items, setItems] = useState<Map<string, ScreeningItem>>(new Map())
  const [ratings, setRatings] = useState<Map<string, ScreeningItemRating>>(new Map())
  const [drafts, setDrafts] = useState<
    Record<string, { afb: ScreeningAfb | null; note: string }>
  >({})
  const [savingId, setSavingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [uploadUrls, setUploadUrls] = useState<Record<string, string>>({})

  useEffect(() => {
    if (pending.length === 0) return
    const itemIds = Array.from(new Set(pending.map((p) => p.screening_item_id)))
    const resultIds = pending.map((p) => p.id)
    void Promise.all([
      listScreeningItemsByIds(itemIds),
      listItemRatingsForResults(resultIds),
    ]).then(([itemRes, ratingRes]) => {
      const im = new Map<string, ScreeningItem>()
      for (const it of itemRes.data ?? []) im.set(it.id, it)
      setItems(im)
      setRatings(ratingRes.data ?? new Map())
      if (itemRes.error) setError(itemRes.error)
    })
  }, [pending.length, results])

  // Signed URLs für alle gerade sichtbaren Foto-Uploads vorab ziehen.
  useEffect(() => {
    const allPaths = pending.flatMap((p) => answerUploadPaths(p.answer))
    if (allPaths.length === 0) return
    void getScreeningPhotoSignedUrls(allPaths).then((urls) => setUploadUrls(urls))
  }, [pending.length, results])

  if (pending.length === 0) {
    return (
      <EmptyState
        icon="✅"
        title="Keine offenen Bewertungen"
        description="Alle Antworten dieses Laufs sind bewertet."
      />
    )
  }

  async function saveRating(resultId: string): Promise<void> {
    const draft = drafts[resultId]
    if (!draft || !draft.afb) return
    setSavingId(resultId)
    setError(null)
    const { data, error: err } = await createScreeningItemRating({
      screening_item_result_id: resultId,
      coach_id: user?.id ?? null,
      reached_afb: draft.afb,
      note: draft.note.trim() || null,
    })
    setSavingId(null)
    if (err || !data) {
      setError(err ?? 'Bewertung konnte nicht gespeichert werden')
      return
    }
    setRatings((prev) => {
      const next = new Map(prev)
      next.set(resultId, data)
      return next
    })
  }

  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        Wartet auf Bewertung ({pending.length})
      </h2>
      {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
      {pending.map((p) => {
        const item = items.get(p.screening_item_id)
        const existing = ratings.get(p.id)
        const draft = drafts[p.id] ?? { afb: existing?.reached_afb ?? null, note: existing?.note ?? '' }
        const clusterName = clusterNames.get(p.cluster_id) ?? p.cluster_id
        const drawing = answerDrawing(p.answer)
        const uploadPaths = answerUploadPaths(p.answer)
        return (
          <EdvanceCard key={p.id} className="flex flex-col gap-3 p-5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {clusterName}
              </span>
              {existing ? (
                <EdvanceBadge variant="mastered">
                  Bewertet: AFB {existing.reached_afb}
                </EdvanceBadge>
              ) : (
                <EdvanceBadge variant="warning">offen</EdvanceBadge>
              )}
            </div>
            {item?.prompt && (
              <p className="text-sm leading-relaxed text-[var(--color-text-primary)]">
                {item.prompt}
              </p>
            )}
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-app)] p-3">
              <p className="text-xs font-semibold text-[var(--color-text-tertiary)]">
                Schüler-Antwort
              </p>
              <p className="mt-1 whitespace-pre-wrap text-sm text-[var(--color-text-primary)]">
                {answerPreview(p.answer)}
              </p>
              {drawing && (
                <a
                  href={drawing}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-2 inline-block"
                  title="Skizze in voller Größe öffnen"
                >
                  <img
                    src={drawing}
                    alt="Rechenweg-Skizze"
                    className="max-h-40 rounded border border-[var(--color-border)] bg-white object-contain"
                  />
                </a>
              )}
              {uploadPaths.length > 0 && (
                <div className="mt-2 flex flex-wrap gap-2">
                  {uploadPaths.map((path) => {
                    const url = uploadUrls[path]
                    if (!url) {
                      return (
                        <div
                          key={path}
                          className="h-24 w-24 animate-pulse rounded border border-[var(--color-border)] bg-[var(--muted)]"
                        />
                      )
                    }
                    return (
                      <a
                        key={path}
                        href={url}
                        target="_blank"
                        rel="noreferrer"
                        title="Rechenweg-Foto in voller Größe"
                      >
                        <img
                          src={url}
                          alt="Rechenweg-Foto"
                          className="h-24 w-24 rounded border border-[var(--color-border)] bg-white object-cover"
                        />
                      </a>
                    )
                  })}
                </div>
              )}
            </div>
            <div className="flex flex-wrap gap-2">
              {AFBS.map((afb) => (
                <button
                  key={afb}
                  type="button"
                  onClick={() =>
                    setDrafts((prev) => ({
                      ...prev,
                      [p.id]: { ...draft, afb },
                    }))
                  }
                  className={[
                    'min-h-[44px] flex-1 rounded-xl border-2 px-3 text-sm font-semibold transition-colors',
                    draft.afb === afb
                      ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]'
                      : 'border-[var(--color-border)] bg-card text-[var(--color-text-secondary)] hover:border-[var(--color-primary-light)]',
                  ].join(' ')}
                >
                  AFB {afb}
                </button>
              ))}
            </div>
            <textarea
              value={draft.note}
              onChange={(e) =>
                setDrafts((prev) => ({
                  ...prev,
                  [p.id]: { ...draft, note: e.target.value },
                }))
              }
              placeholder="Notiz (optional)"
              rows={2}
              className="min-h-[60px] w-full rounded-xl border-2 border-[var(--color-border)] bg-card p-3 text-sm leading-relaxed text-foreground focus:border-[var(--color-primary)] focus:outline-none"
            />
            <Button
              size="lg"
              className="rounded-xl"
              disabled={!draft.afb || savingId === p.id}
              onClick={() => void saveRating(p.id)}
            >
              {savingId === p.id ? 'Speichert …' : existing ? 'Korrektur speichern' : 'Bewertung speichern'}
            </Button>
          </EdvanceCard>
        )
      })}
    </div>
  )
}
