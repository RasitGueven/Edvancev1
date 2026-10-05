// Eine Themenzeile des Arbeitsbildschirms: Name, Balken, "gepruft / gesamt",
// eigener Durchlauf. Aufgeklappt die Aufgaben im aktiven Filter — mit Titel,
// Aufgabentext, Zustand und bei zurueckgewiesenen dem Grund.
//
// admin sieht zusaetzlich "Alle geprueften freigeben" (freigabe_thema), sobald
// Aufgaben des Themas auf "Zur Freigabe" stehen, mit der Zahl der ausgelassenen geaenderten
// Aufgaben und Rueckfragen (Lena-Board, Entscheidung 41). Unter jeder Aufgabe Lenas Ergebnis.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronDown, ChevronRight, Play, ShieldCheck } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { passtZuFilter, type BoardFilter, type Thema } from '@/lib/authoring/board'
import type { LetzteBeanstandung } from '@/lib/supabase/freigabe'
import type { PruefAdminZeile } from '@/types'
import { LenaInfo } from './LenaInfo'
import { StatusBadge } from '../ui'
import { FortschrittsBalken } from './FortschrittsBalken'

export function ThemaZeile({
  thema,
  filter,
  offen,
  isAdmin,
  busy,
  beanstandungen,
  lena,
  fehlbildName,
  onReload,
  onToggle,
  onDurchlauf,
  onAufgabe,
  onFreigeben,
}: {
  thema: Thema
  filter: BoardFilter
  offen: boolean
  isAdmin: boolean
  busy: boolean
  beanstandungen: Map<string, LetzteBeanstandung>
  lena: Map<string, PruefAdminZeile>
  fehlbildName: (slug: string) => string
  onReload: () => void
  onToggle: () => void
  onDurchlauf: () => void
  onAufgabe: (taskId: string) => void
  onFreigeben: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const { stand } = thema
  const fertig = stand.total > 0 && stand.freigegeben === stand.total
  const aufgaben = thema.tasks.filter((task) => passtZuFilter(task, filter))
  const name = thema.name ?? t('board.ohneThema')
  const ausgelassen = {
    geaendert: thema.tasks.filter((x) => x.status === 'review' && lena.get(x.id)?.geaendert).length,
    rueckfragen: thema.tasks.filter((x) => x.status === 'rueckfrage').length,
  }

  return (
    <div className="flex flex-col border-b border-[var(--color-border)] last:border-b-0">
      <div className="flex flex-wrap items-center gap-4 py-4">
        <button
          type="button"
          onClick={onToggle}
          aria-expanded={offen}
          className="flex min-h-[44px] min-w-0 flex-1 items-center gap-2 text-left"
        >
          {offen ? (
            <ChevronDown className="h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]" aria-hidden="true" />
          ) : (
            <ChevronRight className="h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]" aria-hidden="true" />
          )}
          <span
            className={`truncate text-base font-semibold ${fertig ? 'text-[var(--color-text-tertiary)]' : 'text-[var(--color-text-primary)]'}`}
          >
            {name}
          </span>
        </button>
        <FortschrittsBalken stand={stand} className="w-28" />
        <span className="min-w-16 text-right text-sm tabular-nums text-[var(--color-text-secondary)]">
          {fertig ? t('board.fertig') : t('board.zaehler', { geprueft: stand.geprueft, total: stand.total })}
        </span>
        <div className="flex gap-2">
          {isAdmin && thema.id && stand.zurFreigabe > 0 && (
            <span className="flex flex-col items-end gap-1">
              <Button size="sm" disabled={busy} onClick={onFreigeben}>
                <ShieldCheck className="h-4 w-4" aria-hidden="true" />
                {t('clusterRelease.button', { count: stand.zurFreigabe })}
              </Button>
              {(ausgelassen.geaendert > 0 || ausgelassen.rueckfragen > 0) && (
                <span className="text-xs text-[var(--color-text-tertiary)]">{t('lena.ausgelassen', ausgelassen)}</span>
              )}
            </span>
          )}
          <Button
            size="sm"
            variant="outline"
            disabled={aufgaben.length === 0}
            title={aufgaben.length === 0 ? t('board.keineImFilter') : undefined}
            onClick={onDurchlauf}
          >
            <Play className="h-4 w-4" aria-hidden="true" />
            {t('board.durchlauf')}
          </Button>
        </div>
      </div>

      {offen && (
        <div className="flex flex-col gap-2 pb-4 pl-6 animate-fade-in">
          {aufgaben.length === 0 && (
            <p className="text-xs text-[var(--color-text-tertiary)]">{t('board.keineImFilter')}</p>
          )}
          {aufgaben.map((task) => {
            const grund = task.status === 'beanstandet' ? beanstandungen.get(task.id) : undefined
            return (
              <div key={task.id} className="flex flex-col gap-2 rounded-[var(--radius-md)] p-2 transition hover:bg-[var(--color-bg-app)]">
                <button
                  type="button"
                  onClick={() => onAufgabe(task.id)}
                  className="flex min-h-[44px] flex-col gap-2 text-left"
                >
                  <span className="flex flex-wrap items-center gap-2">
                    <span className="text-sm font-semibold text-[var(--color-text-primary)]">
                      {task.title ?? t('board.ohneTitel')}
                    </span>
                    <StatusBadge status={task.status} label={t(`board.zustand.${task.status}`)} />
                  </span>
                  {task.question && (
                    <span className="line-clamp-2 text-xs leading-relaxed text-[var(--color-text-secondary)]">
                      {task.question}
                    </span>
                  )}
                  {grund && (
                    <span className="text-xs leading-relaxed text-[var(--color-destructive)]">
                      {grund.notiz
                        ? t('board.grundMitNotiz', {
                            grund: t(`reject.kategorie.${grund.kategorie}`),
                            notiz: grund.notiz,
                          })
                        : t(`reject.kategorie.${grund.kategorie}`)}
                    </span>
                  )}
                </button>
                {isAdmin && (
                  <LenaInfo taskId={task.id} zeile={lena.get(task.id)} fehlbildName={fehlbildName} onReload={onReload} />
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
