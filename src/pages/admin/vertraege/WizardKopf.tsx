import { useTranslation } from 'react-i18next'

export type WizardSchritt = 1 | 2 | 3 | 4

type WizardKopfProps = {
  aktuell: WizardSchritt
  /** Bis zu welchem Schritt gesprungen werden darf. */
  erreichbar: WizardSchritt
  onSpringe: (schritt: WizardSchritt) => void
}

const SCHRITTE: WizardSchritt[] = [1, 2, 3, 4]

/**
 * Die vier Schritte als Leiste. Zurueckspringen ist immer erlaubt — wer in
 * Schritt 4 merkt, dass die Klasse falsch ist, soll nicht abbrechen muessen.
 * Vorwaerts nur so weit, wie die Daten es hergeben.
 */
export function WizardKopf({ aktuell, erreichbar, onSpringe }: WizardKopfProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  return (
    <ol className="flex flex-wrap items-center gap-2">
      {SCHRITTE.map((s) => {
        const offen = s <= erreichbar
        const aktiv = s === aktuell
        return (
          <li key={s}>
            <button
              type="button"
              disabled={!offen}
              onClick={() => onSpringe(s)}
              aria-current={aktiv ? 'step' : undefined}
              className={[
                'min-h-[44px] rounded-full px-4 text-sm font-semibold transition-colors',
                aktiv
                  ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                  : offen
                    ? 'bg-[var(--color-bg-app)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]'
                    : 'bg-[var(--color-bg-app)] text-[var(--color-text-tertiary)]',
              ].join(' ')}
            >
              {t(`wizard.step${s}`)}
            </button>
          </li>
        )
      })}
    </ol>
  )
}
