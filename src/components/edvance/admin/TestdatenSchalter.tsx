import { useState } from 'react'
import { useTranslation } from 'react-i18next'

const SCHLUESSEL = 'edvance.testdaten.'

function lese(seite: string): boolean {
  try {
    return window.localStorage.getItem(SCHLUESSEL + seite) === '1'
  } catch {
    return false
  }
}

/**
 * Ob eine Admin-Liste Testdaten zeigt (CI-1 Teil D). Aus per Default; die Wahl
 * merkt sich die Seite pro Browser.
 */
export function useTestdatenSchalter(seite: string): [boolean, (an: boolean) => void] {
  const [an, setAn] = useState(() => lese(seite))
  const setze = (neu: boolean): void => {
    setAn(neu)
    try {
      window.localStorage.setItem(SCHLUESSEL + seite, neu ? '1' : '0')
    } catch {
      // Ohne Speicher gilt die Wahl nur bis zum Neuladen.
    }
  }
  return [an, setze]
}

/** Schalter „Testdaten anzeigen (n)“ oben rechts in Lead-Board, Akten, LSA-Reports, Verträgen. */
export function TestdatenSchalter({ anzahl, an, onChange }: { anzahl: number; an: boolean; onChange: (an: boolean) => void }): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <button
      type="button"
      role="switch"
      aria-checked={an}
      onClick={() => onChange(!an)}
      className="inline-flex min-h-[44px] items-center gap-2 rounded-[var(--radius-feld)] px-2 text-sm font-medium text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]"
    >
      <span
        aria-hidden="true"
        className={`relative inline-flex h-6 w-10 shrink-0 rounded-[var(--radius-full)] transition-colors ${
          an ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-text-tertiary)]'
        }`}
      >
        <span
          className={`absolute top-0.5 h-5 w-5 rounded-[var(--radius-full)] bg-[var(--color-bg-surface)] shadow-xs transition-transform ${
            an ? 'translate-x-[18px]' : 'translate-x-0.5'
          }`}
        />
      </span>
      <span className="tabular-nums">{t('testdaten.anzeigen', { count: anzahl })}</span>
    </button>
  )
}
