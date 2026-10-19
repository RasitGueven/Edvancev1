import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

import { stationsNummer } from './stationProps'

/**
 * Kicker einer Station wie im Dummy: „01 — Lernstand". Die Nummer ist
 * zweistellig, der Strich ein gezeichnetes Element, kein Text.
 */
export function Kicker({ nummer, children }: { nummer: number; children: ReactNode }): JSX.Element {
  const { i18n } = useTranslation()
  return (
    <p className="tp-kicker tp-reveal">
      <span className="tp-kicker-nr">{stationsNummer(nummer, i18n.language)}</span>
      <i aria-hidden="true" />
      {children}
    </p>
  )
}
