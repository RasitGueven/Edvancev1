// Eine Zeile der Pflege-Liste.
//
// Sie zeigt genau das, was entscheidet, ob man dieses Item als naechstes anfasst:
// Status, Typ, wie viele Teilaufgaben, ob ein Bild oder eine Tabelle dranhaengt,
// ob der Stoffanker steht — und wie viele Punkte offen sind. Kein <table>: eine
// Liste von Objekten ist eine Liste von Karten (CLAUDE §11).

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, CheckCircle2, Image, Table2 } from 'lucide-react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { buttonVariants } from '@/components/ui/button'
import type { AuthoringTask } from '@/types'
import { StatusBadge } from './ui'

// Bewusst `buttonVariants` auf dem Link statt `<Button asChild>`: Button rendert
// immer `{loading && <Spinner/>}{children}` — mit asChild sieht Radix' Slot darin
// zwei Kinder und wirft "React.Children.only". Der Bug steckt im geteilten Button
// (src/components/ui/button.tsx) und gehoert dort gefixt, nicht hier umschifft;
// siehe Retro. Bis dahin ist das hier der Weg, der nicht kracht.

export type ItemRowData = {
  task: AuthoringTask
  flagCount: number
  blockingCount: number
  hasTable: boolean
}

type Props = {
  row: ItemRowData
  /** Expertenliste: Auswahlfeld je Zeile (Sammelaktionen). */
  auswahl?: { an: boolean; onChange: () => void; label: string }
  /** Expertenliste: ein Klick auf die uebrige Zeile oeffnet die Admin-Pruefansicht. */
  onOeffnen?: () => void
}

export function ItemRow({ row, auswahl, onOeffnen }: Props): JSX.Element {
  const { t } = useTranslation('authoring')
  const { task } = row
  const titel = task.title ?? t('fields.none')

  return (
    <EdvanceCard className={`flex flex-col gap-3 p-5 ${onOeffnen ? 'cursor-pointer hover:shadow-elevation-md' : ''} ${auswahl?.an ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]' : ''}`}
      onClick={onOeffnen}>
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex items-start gap-3">
        {auswahl && (
          <label className="-m-2 flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center" onClick={(e) => e.stopPropagation()}>
            <input type="checkbox" className="h-5 w-5 accent-[var(--color-primary)]" checked={auswahl.an}
              aria-label={auswahl.label} onChange={auswahl.onChange} />
          </label>
        )}
        <div className="flex flex-col gap-1">
          {onOeffnen ? (
            <button type="button" className="text-left text-base font-semibold text-[var(--color-text-primary)] hover:underline"
              onClick={(e) => { e.stopPropagation(); onOeffnen() }}>
              {titel}
            </button>
          ) : (
            <span className="text-base font-semibold text-[var(--color-text-primary)]">{titel}</span>
          )}
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {task.competency_content ?? t('fields.none')}
          </span>
        </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge status={task.status} label={t(`status.${task.status}`)} />
          {task.input_type && <EdvanceBadge variant="muted">{task.input_type}</EdvanceBadge>}
          {task.afb && <EdvanceBadge variant="primary">AFB {task.afb}</EdvanceBadge>}
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-3 text-xs text-[var(--color-text-tertiary)]">
        {task.parts.length > 0 && <span>{t('list.parts', { count: task.parts.length })}</span>}
        {task.assets.length > 0 && (
          <span className="inline-flex items-center gap-1">
            <Image className="h-3.5 w-3.5" aria-hidden />
            {t('list.hasAsset')}
          </span>
        )}
        {row.hasTable && (
          <span className="inline-flex items-center gap-1">
            <Table2 className="h-3.5 w-3.5" aria-hidden />
            {t('list.hasTable')}
          </span>
        )}
        <span>
          {task.curriculum_grade != null
            ? t('list.stoffanker', { grade: task.curriculum_grade })
            : t('list.stoffankerMissing')}
        </span>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        {row.flagCount === 0 ? (
          <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--color-success)]">
            <CheckCircle2 className="h-4 w-4" aria-hidden />
            {t('list.noFlags')}
          </span>
        ) : (
          <span
            className={`inline-flex items-center gap-1.5 text-xs font-semibold ${
              row.blockingCount > 0
                ? 'text-[var(--color-destructive)]'
                : 'text-[var(--color-text-tertiary)]'
            }`}
          >
            <AlertTriangle className="h-4 w-4" aria-hidden />
            {row.blockingCount > 0
              ? t('list.blocking', { count: row.blockingCount })
              : t('list.openFlags', { count: row.flagCount })}
          </span>
        )}
        <Link
          to={`/admin/authoring/${task.id}`}
          onClick={(e) => e.stopPropagation()}
          className={buttonVariants({ variant: 'outline', size: 'sm' })}
        >
          {t('list.edit')}
        </Link>
      </div>
    </EdvanceCard>
  )
}
