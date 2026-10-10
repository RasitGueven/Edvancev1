import { useTranslation } from 'react-i18next'

/** Plätze je Raum: höchstens fünf Kinder (Kleingruppe). */
export const PLAETZE_JE_RAUM = 5

export type PlatzPunkteProps = {
  /** Belegte Plätze je geöffnetem Raum, in Anzeigereihenfolge. Je Raum fünf Punkte. */
  raeume: number[]
  /** Kinder ohne Platz (mehr Kinder als Plätze). Erscheint als "+n" in der Handeln-Farbe. */
  ueberhang?: number
  /** "3/5" hinter den Punkten (wie in "Heute im Betrieb"). */
  mitZahl?: boolean
  className?: string
}

/**
 * Platz-Punkte: je geöffnetem Raum fünf Punkte, belegte gefüllt. Was in keinen Raum passt, steht als
 * "+n" dahinter. Der Screenreader hört "4 von 5 Plätzen belegt" (und "2 ohne Platz").
 * Ohne Fachlogik: wer wie viele Plätze belegt, entscheidet der Aufrufer.
 */
export function PlatzPunkte({ raeume, ueberhang = 0, mitZahl = false, className = '' }: PlatzPunkteProps): JSX.Element {
  const { t } = useTranslation('common')
  const max = raeume.length * PLAETZE_JE_RAUM
  // Mehr als fünf in einem Raum ist ebenfalls Überhang.
  const rest = raeume.reduce((summe, b) => summe + Math.max(b - PLAETZE_JE_RAUM, 0), 0) + Math.max(ueberhang, 0)
  const belegt = raeume.reduce((summe, b) => summe + Math.min(Math.max(b, 0), PLAETZE_JE_RAUM), 0)
  const label = [t('platzPunkte.belegt', { belegt, max }), rest > 0 ? t('platzPunkte.ueberhang', { count: rest }) : null]
    .filter(Boolean)
    .join(', ')

  return (
    <span role="img" className={`inline-flex items-center gap-1 ${className}`} aria-label={label}>
      {raeume.map((b, r) => (
        <span key={r} aria-hidden="true" className={`inline-flex items-center gap-1 ${r > 0 ? 'ml-1' : ''}`}>
          {Array.from({ length: PLAETZE_JE_RAUM }, (_, i) => (
            <span
              key={i}
              className={`h-2 w-2 rounded-full ${
                i < b ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-bg-subtle)] ring-1 ring-[var(--color-border)]'
              }`}
            />
          ))}
        </span>
      ))}
      {rest > 0 && (
        <span aria-hidden="true" className="ml-1 text-xs font-semibold tabular-nums text-[var(--color-error-coach)]">
          +{rest}
        </span>
      )}
      {mitZahl && (
        <span aria-hidden="true" className="ml-1 text-xs tabular-nums text-[var(--color-text-tertiary)]">
          {belegt}/{max}
        </span>
      )}
    </span>
  )
}
