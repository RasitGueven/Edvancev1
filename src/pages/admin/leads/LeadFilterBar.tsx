import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { SELECT_SM } from '@/lib/formStyles'
import { CLASS_LEVELS, SUBJECTS } from '../intake/intakeConstants'
import type { LeadFilters } from './boardModel'

type LeadFilterBarProps = {
  filters: LeadFilters
  onChange: (next: Partial<LeadFilters>) => void
  showDone: boolean
  onToggleDone: (next: boolean) => void
}

// Eine Zeile ueber dem Board. Die Filter wirken auf alle Spalten zugleich;
// die Zahl im Spaltenkopf zeigt darum das gefilterte Ergebnis.
export function LeadFilterBar({
  filters,
  onChange,
  showDone,
  onToggleDone,
}: LeadFilterBarProps): JSX.Element {
  return (
    <div className="flex flex-wrap items-end gap-4">
      <div className="flex min-w-[12rem] flex-1 flex-col gap-2">
        <Label htmlFor="lead-search">Suche</Label>
        <Input
          id="lead-search"
          value={filters.query}
          onChange={(e) => onChange({ query: e.target.value })}
          placeholder="Rufname oder vollständiger Name"
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="lead-filter-subject">Fach</Label>
        <select
          id="lead-filter-subject"
          className={SELECT_SM}
          value={filters.subject ?? ''}
          onChange={(e) => onChange({ subject: e.target.value || null })}
        >
          <option value="">Alle</option>
          {SUBJECTS.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="lead-filter-class">Klasse</Label>
        <select
          id="lead-filter-class"
          className={SELECT_SM}
          value={filters.classLevel ?? ''}
          onChange={(e) =>
            onChange({ classLevel: e.target.value ? Number(e.target.value) : null })
          }
        >
          <option value="">Alle</option>
          {CLASS_LEVELS.map((lvl) => (
            <option key={lvl} value={lvl}>
              {lvl}. Klasse
            </option>
          ))}
        </select>
      </div>
      <label className="flex min-h-[44px] items-center gap-2 text-sm text-[var(--color-text-secondary)]">
        <input
          type="checkbox"
          checked={showDone}
          onChange={(e) => onToggleDone(e.target.checked)}
          className="h-4 w-4 rounded border-[var(--color-border)]"
        />
        Abgeschlossene anzeigen
      </label>
    </div>
  )
}
