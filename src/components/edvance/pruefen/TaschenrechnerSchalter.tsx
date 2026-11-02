// Pruefkarte: Hilfsmittel der Aufgabe (tasks.taschenrechner). Wirkt sofort, nicht ueber den Entwurf: Das Feld gehoert
// nicht zur Antwort, und bei freigegebenen Aufgaben gibt es keinen Entwurf.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'

type Props = {
  an: boolean
  gesperrt: boolean
  arbeitet: boolean
  onSetzen: (wert: boolean) => void
}

export function TaschenrechnerSchalter({ an, gesperrt, arbeitet, onSetzen }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <label
      title={gesperrt ? t('taschenrechner.gesperrt') : undefined}
      className="flex min-h-11 items-start gap-4 rounded-[var(--radius-md)] border border-[var(--color-border)] p-4"
    >
      <input
        type="checkbox"
        role="switch"
        aria-checked={an}
        className="mt-1 h-5 w-5 accent-[var(--color-primary)]"
        checked={an}
        disabled={gesperrt || arbeitet}
        onChange={(e) => onSetzen(e.target.checked)}
      />
      <span className="flex flex-col gap-2">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">{t('taschenrechner.titel')}</span>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {t(gesperrt ? 'taschenrechner.gesperrt' : 'taschenrechner.hilfe')}
        </span>
      </span>
    </label>
  )
}
