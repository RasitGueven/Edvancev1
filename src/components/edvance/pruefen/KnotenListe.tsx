// Aufgeklapptes Thema mit Sollzahlen (P2): je Knoten Soll, gezaehlt und "mind. 1 ohne Multiple Choice",
// darunter seine Aufgaben. Fertige Knoten bleiben sichtbar, nur ausgegraut; Knoten ohne Soll ohne Hervorhebung.
// Offene Punkte neutral, nie rot.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react'
import { EdvanceBadge } from '@/components/edvance'
import { cn } from '@/lib/utils'
import type { KnotenGruppe } from '@/lib/pruefung/soll'
import type { LenaStatus, PruefBoardZeile } from '@/types'

type Props = {
  knoten: KnotenGruppe[]
  /** Nummer der Aufgabe im Thema (wie in der Liste ohne Soll). */
  nummer: (taskId: string) => number
  statusText: (z: PruefBoardZeile) => string
  statusFarbe: Record<LenaStatus, string>
  onAufgabe: (id: string) => void
  /** Kennzeichnung je Aufgabe, z. B. der Pool. */
  zusatz?: (z: PruefBoardZeile) => string | null
}

/** Kennzeichnung an einer Aufgabenzeile, z. B. "Pool Session". */
export function Zusatz({ text }: { text?: string | null }): JSX.Element | null {
  return text ? <EdvanceBadge variant="muted">{text}</EdvanceBadge> : null
}

function KnotenKopf({ k }: { k: KnotenGruppe }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const s = k.soll
  if (!s) return <span className="text-xs text-[var(--color-text-tertiary)]">{k.label}</span>
  const mcErfuellt = s.gezaehlt_ohne_mc >= s.min_ohne_mc
  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
      <span className="text-sm font-semibold text-[var(--color-text-primary)]">{k.label}</span>
      <span className="text-xs text-[var(--color-text-secondary)]">
        {t('soll.knotenZahl', { gezaehlt: s.gezaehlt, soll: s.soll })}
      </span>
      {s.min_ohne_mc > 0 && (
        <span className={cn('text-xs', mcErfuellt ? 'text-[var(--color-success)]' : 'text-[var(--color-text-tertiary)]')}>
          {t(mcErfuellt ? 'soll.ohneMcErfuellt' : 'soll.ohneMcOffen', { count: s.min_ohne_mc })}
        </span>
      )}
      {s.reicht && (
        <span className="inline-flex items-center gap-1 text-xs font-semibold text-[var(--color-success)]">
          <Check className="h-3.5 w-3.5" aria-hidden="true" />{t('soll.knotenReicht')}
        </span>
      )}
    </div>
  )
}

export function KnotenListe({ knoten, nummer, statusText, statusFarbe, onAufgabe, zusatz }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <div className="flex flex-col gap-4 border-t border-[var(--color-border)] pt-4">
      {knoten.map((k) => {
        const offen = !!k.soll && !k.soll.reicht
        return (
          <section key={k.skill_key ?? ''} data-testid={`knoten-${k.skill_key ?? ''}`}
            className={cn('flex flex-col gap-2 pl-3',
              offen ? 'border-l-2 border-[var(--color-primary)]' : 'border-l-2 border-transparent',
              k.soll?.reicht && 'opacity-60')}>
            <KnotenKopf k={k} />
            {k.zeilen.length === 0 ? (
              <span className="text-xs text-[var(--color-text-tertiary)]">{t('soll.knotenLeer')}</span>
            ) : (
              <ul className="flex flex-col">
                {k.zeilen.map((z) => (
                  <li key={z.task_id}>
                    <button type="button" onClick={() => onAufgabe(z.task_id)}
                      className="flex min-h-[44px] w-full items-center gap-3 border-b border-[var(--color-border)] py-2 text-left text-sm hover:bg-[var(--color-bg-subtle)]">
                      <span className="min-w-0 flex-1 font-medium text-[var(--color-text-primary)]">
                        {t('themen.aufgabe', { nr: nummer(z.task_id), titel: z.kurztitel })}
                      </span>
                      <Zusatz text={zusatz?.(z)} />
                      <span className={cn('whitespace-nowrap text-xs', statusFarbe[z.lena_status])}>{statusText(z)}</span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </section>
        )
      })}
    </div>
  )
}
