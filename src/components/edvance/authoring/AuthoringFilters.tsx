// Filterleiste der Item-Pflege. Reine Darstellung — die Filterlogik selbst lebt
// in der Liste (AuthoringItemsPage), damit sie mit den Zaehlern in einer Quelle
// bleibt.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { EdvanceCard } from '@/components/edvance'
import { SELECT_SM } from '@/lib/formStyles'
import type { TaskStatus } from '@/types'

export type FlagFilter = 'all' | 'blocking' | 'any' | 'none'
export type TriFilter = 'all' | 'yes' | 'no'
export type SortKey = 'flags' | 'title' | 'status' | 'newest'

/** Herkunft: 'eigene' = alles ausser VERA, 'vera' = nur VERA, 'all' = beides. */
export type SourceFilter = 'all' | 'eigene' | 'vera'

export type FilterState = {
  search: string
  status: TaskStatus | 'all'
  subject: string
  competency: string
  afb: string
  source: SourceFilter
  flags: FlagFilter
  asset: TriFilter
  table: TriFilter
  sort: SortKey
}

export const EMPTY_FILTERS: FilterState = {
  search: '',
  status: 'all',
  subject: 'all',
  competency: 'all',
  afb: 'all',
  // Der einzige Filter, der NICHT auf 'all' steht: die Pflege arbeitet am
  // Eigenbau, der VERA-Bestand liegt daneben und wuerde die Liste zudecken.
  // Ausgeblendet, nicht geloescht — ein Griff ins Dropdown holt ihn zurueck.
  source: 'eigene',
  flags: 'all',
  asset: 'all',
  table: 'all',
  sort: 'flags',
}

export function AuthoringFilters({
  value,
  subjects,
  competencies,
  onChange,
}: {
  value: FilterState
  subjects: string[]
  competencies: string[]
  onChange: (next: FilterState) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const set = <K extends keyof FilterState>(key: K, v: FilterState[K]): void =>
    onChange({ ...value, [key]: v })

  return (
    <EdvanceCard className="flex flex-col gap-4 p-5">
      <Input
        value={value.search}
        placeholder={t('list.search')}
        onChange={(e) => set('search', e.target.value)}
      />

      <div className="flex flex-wrap gap-3">
        <select
          className={SELECT_SM}
          value={value.status}
          aria-label={t('filter.status')}
          onChange={(e) => set('status', e.target.value as TaskStatus | 'all')}
        >
          <option value="all">
            {t('filter.status')}: {t('filter.all')}
          </option>
          <option value="draft">{t('status.draft')}</option>
          <option value="review">{t('status.review')}</option>
          <option value="ready">{t('status.ready')}</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.subject}
          aria-label={t('filter.subject')}
          onChange={(e) => set('subject', e.target.value)}
        >
          <option value="all">
            {t('filter.subject')}: {t('filter.all')}
          </option>
          {subjects.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>

        <select
          className={SELECT_SM}
          value={value.competency}
          aria-label={t('filter.competency')}
          onChange={(e) => set('competency', e.target.value)}
        >
          <option value="all">
            {t('filter.competency')}: {t('filter.all')}
          </option>
          {competencies.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>

        <select
          className={SELECT_SM}
          value={value.afb}
          aria-label={t('filter.afb')}
          onChange={(e) => set('afb', e.target.value)}
        >
          <option value="all">
            {t('filter.afb')}: {t('filter.all')}
          </option>
          <option value="I">AFB I</option>
          <option value="II">AFB II</option>
          <option value="III">AFB III</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.source}
          aria-label={t('filter.source')}
          onChange={(e) => set('source', e.target.value as SourceFilter)}
        >
          <option value="all">
            {t('filter.source')}: {t('filter.all')}
          </option>
          <option value="eigene">{t('filter.sourceOwn')}</option>
          <option value="vera">{t('filter.sourceVera')}</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.flags}
          aria-label={t('filter.flags')}
          onChange={(e) => set('flags', e.target.value as FlagFilter)}
        >
          <option value="all">
            {t('filter.flags')}: {t('filter.all')}
          </option>
          <option value="blocking">{t('filter.flagsBlocking')}</option>
          <option value="any">{t('filter.flagsAny')}</option>
          <option value="none">{t('filter.flagsNone')}</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.asset}
          aria-label={t('filter.asset')}
          onChange={(e) => set('asset', e.target.value as TriFilter)}
        >
          <option value="all">
            {t('filter.asset')}: {t('filter.all')}
          </option>
          <option value="yes">{t('filter.hasAsset')}</option>
          <option value="no">{t('filter.noAsset')}</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.table}
          aria-label={t('filter.table')}
          onChange={(e) => set('table', e.target.value as TriFilter)}
        >
          <option value="all">
            {t('filter.table')}: {t('filter.all')}
          </option>
          <option value="yes">{t('filter.hasTable')}</option>
          <option value="no">{t('filter.noTable')}</option>
        </select>

        <select
          className={SELECT_SM}
          value={value.sort}
          aria-label={t('filter.sort')}
          onChange={(e) => set('sort', e.target.value as SortKey)}
        >
          <option value="flags">{t('sort.flags')}</option>
          <option value="title">{t('sort.title')}</option>
          <option value="status">{t('sort.status')}</option>
          <option value="newest">{t('sort.newest')}</option>
        </select>

        <Button
          variant="outline"
          size="sm"
          onClick={() => onChange({ ...EMPTY_FILTERS, sort: value.sort })}
        >
          {t('filter.reset')}
        </Button>
      </div>
    </EdvanceCard>
  )
}
