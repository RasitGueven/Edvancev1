import { useTranslation } from 'react-i18next'
import { PLAETZE, raumFarbe, type RaumFarbe } from './wochenplan.model'

/** Fläche, Schrift und Punktfarbe je Belegung (Entscheidung 4); nur Tokens. */
export const FARBE: Record<RaumFarbe, { flaeche: string; punkt: string; leer: string }> = {
  leer: {
    flaeche: 'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]',
    punkt: 'bg-[var(--color-text-tertiary)]',
    leer: 'bg-[var(--color-border)]',
  },
  rot: {
    flaeche: 'bg-[var(--color-error-coach-light)] text-[var(--color-error-coach)]',
    punkt: 'bg-[var(--color-error-coach)]',
    leer: 'bg-[var(--color-border)]',
  },
  gelb: {
    flaeche: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]',
    punkt: 'bg-[var(--color-gold-warning)]',
    leer: 'bg-[var(--color-border)]',
  },
  gruen: {
    flaeche: 'bg-[var(--color-success-light)] text-[var(--color-success)]',
    punkt: 'bg-[var(--color-success)]',
    leer: 'bg-[var(--color-border)]',
  },
  keinCoach: {
    flaeche: 'bg-[var(--color-error-coach)] text-[var(--color-text-inverse)]',
    punkt: 'bg-[var(--color-text-inverse)]',
    leer: 'bg-[var(--color-error-coach-light)] opacity-40',
  },
}

/** Fünf Punkte, belegte in der Farbe des Raums. */
export function Punkte({ belegt, farbe }: { belegt: number; farbe: RaumFarbe }): JSX.Element {
  return (
    <span aria-hidden="true" className="inline-flex shrink-0 gap-1">
      {Array.from({ length: PLAETZE }, (_, i) => (
        <span key={i} className={`h-2 w-2 rounded-full ${i < belegt ? FARBE[farbe].punkt : FARBE[farbe].leer}`} />
      ))}
    </span>
  )
}

type Props = {
  name: string
  belegt: number
  mitCoach: boolean
  /** Tagespanel: Coach-Name in der Zeile. */
  coach?: string | null
  className?: string
}

/** Eine Raum-Zeile: Raumname, fünf Punkte, „n/5“ bzw. „kein Coach“, Fläche nach Belegung. */
export function RaumZeile({ name, belegt, mitCoach, coach, className = '' }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const farbe = raumFarbe(belegt, mitCoach)
  const zahl = t('wochenplan2.raum.belegt', { belegt, max: PLAETZE })
  // Ohne Coach-Spalte trägt die Zahl den Hinweis „kein Coach“ (Raster); mit Coach-Spalte steht er dort.
  const rechts = farbe === 'keinCoach' && coach === undefined ? t('wochenplan2.raum.keinCoach') : zahl
  return (
    <span
      className={`flex min-w-0 items-center gap-2 rounded-[var(--radius-sm)] px-2 py-1 text-xs ${FARBE[farbe].flaeche} ${className}`}
      aria-label={t('wochenplan2.raum.label', { raum: name, stand: farbe === 'keinCoach' ? `${zahl}, ${t('wochenplan2.raum.keinCoach')}` : zahl })}
      role="img"
    >
      <span className="min-w-[1.5rem] font-semibold">{name}</span>
      <Punkte belegt={belegt} farbe={farbe} />
      {coach !== undefined && (
        <span className={`min-w-0 truncate ${farbe === 'keinCoach' ? 'font-semibold' : 'text-[var(--color-text-secondary)]'}`}>
          {coach ?? t('wochenplan2.raum.keinCoach')}
        </span>
      )}
      <span className="ml-auto shrink-0 font-semibold tabular-nums">{rechts}</span>
    </span>
  )
}
