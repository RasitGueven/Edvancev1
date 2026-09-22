import { useTranslation } from 'react-i18next'
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
  /** Eindeutige ids, wenn die Leiste in einer anderen Ansicht (Vertraege) steht. */
  idPrefix?: string
}

// Eine Zeile ueber dem Board. Die Filter wirken auf alle Spalten zugleich;
// die Zahl im Spaltenkopf zeigt darum das gefilterte Ergebnis.
export function LeadFilterBar({
  filters,
  onChange,
  showDone,
  onToggleDone,
  idPrefix = 'lead',
}: LeadFilterBarProps): JSX.Element {
  const { t } = useTranslation('leads')
  return (
    <div className="flex flex-wrap items-end gap-4">
      <div className="flex min-w-[12rem] flex-1 flex-col gap-2">
        <Label htmlFor={`${idPrefix}-search`}>{t('filters.search')}</Label>
        <Input
          id={`${idPrefix}-search`}
          value={filters.query}
          onChange={(e) => onChange({ query: e.target.value })}
          placeholder={t('filters.searchPlaceholder')}
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor={`${idPrefix}-filter-subject`}>{t('filters.subject')}</Label>
        <select
          id={`${idPrefix}-filter-subject`}
          className={SELECT_SM}
          value={filters.subject ?? ''}
          onChange={(e) => onChange({ subject: e.target.value || null })}
        >
          <option value="">{t('filters.all')}</option>
          {SUBJECTS.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor={`${idPrefix}-filter-class`}>{t('filters.classLevel')}</Label>
        <select
          id={`${idPrefix}-filter-class`}
          className={SELECT_SM}
          value={filters.classLevel ?? ''}
          onChange={(e) =>
            onChange({ classLevel: e.target.value ? Number(e.target.value) : null })
          }
        >
          <option value="">{t('filters.all')}</option>
          {CLASS_LEVELS.map((lvl) => (
            <option key={lvl} value={lvl}>
              {t('filters.classOption', { level: lvl })}
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
        {t('filters.archive')}
      </label>
    </div>
  )
}
