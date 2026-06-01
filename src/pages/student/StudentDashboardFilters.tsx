import type { JSX } from 'react'
import { Search, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
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
        <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-tertiary)]" />
        <input
          type="search"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Suche nach Aufgabe, Video, Artikel …"
          className="h-12 w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] pl-11 pr-11 text-sm shadow-xs focus:border-[var(--color-primary)] focus:outline-none transition-all"
        />
        {search && (
          <button
            type="button"
            onClick={() => onSearchChange('')}
            aria-label="Suche leeren"
            className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1 text-muted hover:bg-background hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {TYPE_FILTERS.map((f) => (
          <Button
            key={f.value}
            variant={typeFilter === f.value ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTypeFilterChange(f.value)}
          >
            {f.label}
          </Button>
        ))}
        {isFiltering && (
          <button
            type="button"
            onClick={onClear}
            className="ml-auto text-xs font-semibold text-muted hover:text-foreground"
          >
            Filter zurücksetzen
          </button>
        )}
      </div>
      {subjects.length > 1 && (
        <div className="mt-1 flex flex-wrap gap-2">
          {subjects.map((s) => (
            <Button
              key={s.id}
              size="sm"
              variant={s.id === selectedSubjectId ? 'default' : 'outline'}
              onClick={() => onSubjectChange(s.id)}
            >
              {s.name}
            </Button>
          ))}
        </div>
      )}
    </div>
  )
}
