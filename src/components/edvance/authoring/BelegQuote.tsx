// Ein Quellenbeleg als Zitat — READ-ONLY, an zwei Stellen benutzt:
//   GroundingPanel   → die oeffentlichen Belege (Stamm, Teilaufgaben, Lizenz)
//   PedagogySection  → der LOESUNGSbeleg (task_solutions.beleg, gegated auf
//                      Coach/Admin ueber task_solution_get)
//
// Eine Darstellung, zwei Kanaele: der Pfleger soll einen Beleg als Beleg
// erkennen, egal woher er kommt — und ihn nirgends bearbeiten koennen.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { GroundingBeleg } from '@/types'

export function BelegQuote({ beleg }: { beleg: GroundingBeleg }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <figure className="flex flex-col gap-1 border-l-2 border-[var(--color-border)] pl-3">
      <figcaption className="text-xs font-semibold text-[var(--color-text-secondary)]">
        {beleg.feld}
        {beleg.gate ? ` · ${beleg.gate}` : ''}
      </figcaption>
      <blockquote className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {beleg.zitat}
      </blockquote>
      {beleg.hinweis && (
        <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {beleg.hinweis}
        </span>
      )}
      {beleg.quelle && (
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {t('grounding.quelle', { file: beleg.quelle })}
        </span>
      )}
    </figure>
  )
}
