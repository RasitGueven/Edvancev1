import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
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

type ChipGruppeProps<T> = {
  label: string
  werte: readonly T[]
  aktiv: T | null
  name: (wert: T) => string
  onWahl: (wert: T | null) => void
}

// Fach und Klasse als Chips statt Select (Bauauftrag Admin-Hülle H2, Punkt 5):
// ein Tipp statt zwei, auf dem iPad mit 44 px Trefferfläche (Entscheidung 9).
function ChipGruppe<T extends string | number>({ label, werte, aktiv, name, onWahl }: ChipGruppeProps<T>): JSX.Element {
  const { t } = useTranslation('leads')
  const chip = (gewaehlt: boolean): string =>
    [
      'min-h-[44px] rounded-[var(--radius-full)] px-4 text-sm font-semibold transition-colors',
      gewaehlt
        ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
        : 'border border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]',
    ].join(' ')
  return (
    <div role="group" aria-label={label} className="flex flex-wrap items-center gap-2">
      <span className="text-xs text-[var(--color-text-tertiary)]">{label}</span>
      <button type="button" aria-pressed={aktiv === null} onClick={() => onWahl(null)} className={chip(aktiv === null)}>
        {t('filters.all')}
      </button>
      {werte.map((w) => (
        <button key={w} type="button" aria-pressed={aktiv === w} onClick={() => onWahl(w)} className={chip(aktiv === w)}>
          {name(w)}
        </button>
      ))}
    </div>
  )
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
    <div className="flex flex-wrap items-center gap-4">
      <div className="flex min-w-[12rem] flex-1 flex-col">
        <Label htmlFor={`${idPrefix}-search`} className="sr-only">
          {t('filters.search')}
        </Label>
        <Input
          id={`${idPrefix}-search`}
          value={filters.query}
          onChange={(e) => onChange({ query: e.target.value })}
          placeholder={t('filters.searchPlaceholder')}
          className="min-h-[44px]"
        />
      </div>
      <ChipGruppe
        label={t('filters.subject')}
        werte={SUBJECTS}
        aktiv={filters.subject as (typeof SUBJECTS)[number] | null}
        name={(s) => s}
        onWahl={(s) => onChange({ subject: s })}
      />
      <ChipGruppe
        label={t('filters.classLevel')}
        werte={CLASS_LEVELS}
        aktiv={filters.classLevel}
        name={(lvl) => String(lvl)}
        onWahl={(lvl) => onChange({ classLevel: lvl })}
      />
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
