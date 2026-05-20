// Coach-Inbox für offene Open-Antworten: zeigt Prompt + Schüler-Antwort,
// erfasst AFB-Rating (I/II/III) + optionale Notiz. Append-only — Korrektur
// = neuer Eintrag (CLAUDE.md §6/§10 + Migration 028).

import { useEffect, useState, type JSX } from 'react'
import { Button } from '@/components/ui/button'
import { EdvanceCard, EdvanceBadge, EmptyState } from '@/components/edvance'
import { useAuth } from '@/hooks/useAuth'
import { listScreeningItemsByIds } from '@/lib/supabase/screeningItems'
import {
  createScreeningItemRating,
  listItemRatingsForResults,
} from '@/lib/supabase/screeningItemRatings'
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
  }
  return JSON.stringify(raw)
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
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        Wartet auf Bewertung ({pending.length})
      </h2>
      {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}
      {pending.map((p) => {
        const item = items.get(p.screening_item_id)
        const existing = ratings.get(p.id)
        const draft = drafts[p.id] ?? { afb: existing?.reached_afb ?? null, note: existing?.note ?? '' }
        const clusterName = clusterNames.get(p.cluster_id) ?? p.cluster_id
        return (
          <EdvanceCard key={p.id} className="flex flex-col gap-3 p-5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                {clusterName}
              </span>
              {existing ? (
                <EdvanceBadge variant="success">
                  Bewertet: AFB {existing.reached_afb}
                </EdvanceBadge>
              ) : (
                <EdvanceBadge variant="warning">offen</EdvanceBadge>
              )}
            </div>
            {item?.prompt && (
              <p className="text-sm leading-relaxed text-[var(--text-primary)]">
                {item.prompt}
              </p>
            )}
            <div className="rounded-xl border border-[var(--border)] bg-[var(--background)] p-3">
              <p className="text-xs font-semibold text-[var(--text-muted)]">
                Schüler-Antwort
              </p>
              <p className="mt-1 whitespace-pre-wrap text-sm text-[var(--text-primary)]">
                {answerPreview(p.answer)}
              </p>
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
                      ? 'border-[var(--primary)] bg-[var(--primary-pale)] text-[var(--primary)]'
                      : 'border-[var(--border)] bg-card text-[var(--text-secondary)] hover:border-[var(--primary-light)]',
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
              className="min-h-[60px] w-full rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed text-foreground focus:border-[var(--primary)] focus:outline-none"
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
