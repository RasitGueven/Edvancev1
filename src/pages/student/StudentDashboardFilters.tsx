import type { JSX, ReactNode } from 'react'
import { Search, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { Task, Subject } from '@/types'

export type ContentType = Task['content_type']
export type TypeFilter = 'all' | ContentType

export const TYPE_FILTERS: { value: TypeFilter; label: string }[] = [
  { value: 'all',      label: 'Alle' },
  { value: 'exercise', label: 'Aufgaben' },
  { value: 'article',  label: 'Artikel' },
  { value: 'video',    label: 'Videos' },
]

interface StudentDashboardFiltersProps {
  search: string
  onSearchChange: (v: string) => void
  typeFilter: TypeFilter
  onTypeFilterChange: (v: TypeFilter) => void
  isFiltering: boolean
  onClear: () => void
  subjects: Subject[]
  selectedSubjectId: string | null
  onSubjectChange: (id: string) => void
}

/** Filter-Pille auf der dunklen Bühne: aktiv = heller Surface-Chip, sonst Glass. */
function FilterPill({
  active,
  onClick,
  children,
}: {
  active: boolean
  onClick: () => void
  children: ReactNode
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'inline-flex min-h-[44px] items-center rounded-[var(--radius-full)] px-4 text-sm font-semibold transition-[transform,background] duration-200 ease-bounce active:scale-[0.98]',
        active
          ? 'bg-[var(--color-bg-surface)] text-[var(--color-primary)] shadow-md'
          : 'glass-button',
      )}
    >
      {children}
    </button>
  )
}

export function StudentDashboardFilters({
  search,
  onSearchChange,
  typeFilter,
  onTypeFilterChange,
  isFiltering,
  onClear,
  subjects,
  selectedSubjectId,
  onSubjectChange,
}: StudentDashboardFiltersProps): JSX.Element {
  return (
    <div id="lernpfad" className="flex flex-col gap-3">
      <div className="relative">
        <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-warm-56" />
        <input
          type="search"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Suche nach Aufgabe, Video, Artikel …"
          className="h-12 w-full rounded-[var(--radius-xl)] border border-white/20 bg-white/10 pl-11 pr-11 text-sm text-warm transition-colors placeholder:text-warm-42 focus:border-white/50 focus:outline-none"
        />
        {search && (
          <button
            type="button"
            onClick={() => onSearchChange('')}
            aria-label="Suche leeren"
            className="absolute right-2 top-1/2 -translate-y-1/2 rounded-[var(--radius-sm)] p-1 text-warm-56 hover:bg-white/10 hover:text-warm"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {TYPE_FILTERS.map((f) => (
          <FilterPill
            key={f.value}
            active={typeFilter === f.value}
            onClick={() => onTypeFilterChange(f.value)}
          >
            {f.label}
          </FilterPill>
        ))}
        {isFiltering && (
          <button
            type="button"
            onClick={onClear}
            className="ml-auto text-xs font-semibold text-warm-56 hover:text-warm"
          >
            Filter zurücksetzen
          </button>
        )}
      </div>
      {subjects.length > 1 && (
        <div className="mt-1 flex flex-wrap gap-2">
          {subjects.map((s) => (
            <FilterPill
              key={s.id}
              active={s.id === selectedSubjectId}
              onClick={() => onSubjectChange(s.id)}
            >
              {s.name}
            </FilterPill>
          ))}
        </div>
      )}
    </div>
  )
}
