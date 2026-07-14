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

export function ItemRow({ row }: { row: ItemRowData }): JSX.Element {
  const { t } = useTranslation('authoring')
  const { task } = row

  return (
    <EdvanceCard className="flex flex-col gap-3 p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <span className="text-base font-semibold text-[var(--color-text-primary)]">
            {task.title ?? t('fields.none')}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {task.competency_content ?? t('fields.none')}
          </span>
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
          className={buttonVariants({ variant: 'outline', size: 'sm' })}
        >
          {t('list.edit')}
        </Link>
      </div>
    </EdvanceCard>
  )
}
