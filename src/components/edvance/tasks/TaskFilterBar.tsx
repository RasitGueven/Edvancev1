import type { JSX } from 'react'
import { Search, X } from 'lucide-react'
import { CONTENT_TYPE_LABELS } from '@/lib/taskLabels'
import type { CognitiveType, ContentType } from '@/types'

export interface TaskFilterState {
  search: string
  contentTypes: Set<ContentType>
  cognitiveTypes: Set<CognitiveType>
  difficulties: Set<number>
  hasAssets: boolean
}

export const INITIAL_FILTER_STATE: TaskFilterState = {
  search: '',
  contentTypes: new Set(),
  cognitiveTypes: new Set(),
  difficulties: new Set(),
  hasAssets: false,
}

export function isFilterActive(state: TaskFilterState): boolean {
  return (
    state.search.trim() !== '' ||
    state.contentTypes.size > 0 ||
    state.cognitiveTypes.size > 0 ||
    state.difficulties.size > 0 ||
    state.hasAssets
  )
}

const CONTENT_TYPES: ContentType[] = ['exercise', 'exercise_group', 'article', 'video', 'course']

const COGNITIVE_TYPES: CognitiveType[] = ['FACT', 'TRANSFER', 'ANALYSIS']

function toggleInSet<T>(set: Set<T>, value: T): Set<T> {
  const next = new Set(set)
  if (next.has(value)) next.delete(value)
  else next.add(value)
  return next
}

const CHIP_BASE =
  'rounded-[var(--radius-full)] border px-3 py-1 text-xs font-semibold transition-colors'
const CHIP_ACTIVE =
  CHIP_BASE +
  ' border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-bg-surface)]'
const CHIP_INACTIVE =
  CHIP_BASE +
  ' border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary-light)]'

export function TaskFilterBar({
  state,
  onChange,
  onReset,
  totalCount,
  filteredCount,
}: {
  state: TaskFilterState
  onChange: (next: TaskFilterState) => void
  onReset: () => void
  totalCount: number
  filteredCount: number
}): JSX.Element {
  const active = isFilterActive(state)
  return (
    <div className="sticky top-0 z-10 flex flex-col gap-3 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4 shadow-card">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-tertiary)]" />
        <input
          type="search"
          value={state.search}
          onChange={(e) => onChange({ ...state, search: e.target.value })}
          placeholder="Titel oder Quellen-Referenz suchen…"
          className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] py-2 pl-9 pr-3 text-sm text-[var(--color-text-primary)] outline-none transition-colors focus:border-[var(--color-primary)]"
        />
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Typ
        </span>
        {CONTENT_TYPES.map((ct) => {
          const selected = state.contentTypes.has(ct)
          return (
            <button
              key={ct}
              type="button"
              onClick={() =>
                onChange({ ...state, contentTypes: toggleInSet(state.contentTypes, ct) })
              }
              className={selected ? CHIP_ACTIVE : CHIP_INACTIVE}
            >
              {CONTENT_TYPE_LABELS[ct]}
            </button>
          )
        })}
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Kognitiv
        </span>
        {COGNITIVE_TYPES.map((ct) => {
          const selected = state.cognitiveTypes.has(ct)
          return (
            <button
              key={ct}
              type="button"
              onClick={() =>
                onChange({ ...state, cognitiveTypes: toggleInSet(state.cognitiveTypes, ct) })
              }
              className={selected ? CHIP_ACTIVE : CHIP_INACTIVE}
            >
              {ct}
            </button>
          )
        })}
      </div>

      <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Schwierigkeit
          </span>
          <div className="flex items-center gap-1.5">
            {[1, 2, 3, 4, 5].map((level) => {
              const selected = state.difficulties.has(level)
              return (
                <button
                  key={level}
                  type="button"
                  onClick={() =>
                    onChange({ ...state, difficulties: toggleInSet(state.difficulties, level) })
                  }
                  className={
                    selected
                      ? 'h-7 w-7 rounded-[var(--radius-full)] border border-[var(--color-primary)] bg-[var(--color-primary)] text-xs font-bold text-[var(--color-bg-surface)]'
                      : 'h-7 w-7 rounded-[var(--radius-full)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] text-xs font-semibold text-[var(--color-text-tertiary)] hover:border-[var(--color-primary-light)]'
                  }
                  aria-label={`Schwierigkeit ${level}`}
                  aria-pressed={selected}
                >
                  {level}
                </button>
              )
            })}
          </div>
        </div>

        <label className="flex cursor-pointer items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <input
            type="checkbox"
            checked={state.hasAssets}
            onChange={(e) => onChange({ ...state, hasAssets: e.target.checked })}
            className="h-4 w-4 cursor-pointer accent-[var(--color-primary)]"
          />
          Nur mit Bildern
        </label>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2 border-t border-[var(--color-border)] pt-3">
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {active ? (
            <>
              <strong className="text-[var(--color-text-primary)]">{filteredCount}</strong> von{' '}
              {totalCount} Aufgaben
            </>
          ) : (
            <>
              <strong className="text-[var(--color-text-primary)]">{totalCount}</strong> Aufgaben
            </>
          )}
        </span>
        {active && (
          <button
            type="button"
            onClick={onReset}
            className="inline-flex items-center gap-1 text-xs font-semibold text-[var(--color-primary)] hover:underline"
          >
            <X className="h-3 w-3" />
            Filter zurücksetzen
          </button>
        )}
      </div>
    </div>
  )
}
