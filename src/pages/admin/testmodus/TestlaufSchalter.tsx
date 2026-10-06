import { useTranslation } from 'react-i18next'

type TestlaufSchalterProps = {
  /** Nur ein Admin startet einen Testlauf. */
  istAdmin: boolean
  /** Nur mit einem Testkonto (Kind bzw. Lead). */
  istTest: boolean
  wert: boolean
  onChange: (wert: boolean) => void
  disabled?: boolean
}

/**
 * Schalter "Testlauf" beim Start einer LSA (Entscheidung 27). Sichtbar nur fuer
 * Admins bei Testkonten; sonst rendert er nichts. Im Testlauf zieht die Auswahl
 * auch ungepruefte Aufgaben, die die Pruefung des Lena-Boards bestehen; der Lauf
 * zaehlt in keiner Kennzahl, keinem Report und keiner Akte.
 */
export function TestlaufSchalter({ istAdmin, istTest, wert, onChange, disabled }: TestlaufSchalterProps): JSX.Element | null {
  const { t } = useTranslation('admin')
  if (!istAdmin || !istTest) return null
  return (
    <label className="flex min-h-11 cursor-pointer items-start gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3">
      <input
        type="checkbox"
        role="switch"
        aria-checked={wert}
        className="mt-1 h-5 w-5 accent-[var(--color-gold-warning)]"
        checked={wert}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span className="flex flex-col gap-1">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">{t('testmodus.schalter.label')}</span>
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('testmodus.schalter.hilfe')}</span>
      </span>
    </label>
  )
}
