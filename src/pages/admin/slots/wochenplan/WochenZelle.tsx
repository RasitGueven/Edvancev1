import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { PlatzPunkte } from '@/components/edvance'
import type { WocheZelle } from '@/types/slotplan'
import { fachKuerzel } from '../slotsFormat'
import { raumBelegung, zellZustand } from '../slots.model'

/** Fläche und 3-px-Streifen links nur bei einem Zustand (Entscheidung 28); der Streifen ist ein Inset-Schatten. */
const FLAECHE = {
  leer: 'bg-[var(--color-bg-surface)]',
  normal: 'bg-[var(--color-bg-surface)] hover:bg-[var(--color-bg-subtle)]',
  achtung: 'bg-[var(--color-gold-warning-light)] shadow-[inset_3px_0_0_var(--color-gold-warning)]',
  handeln: 'bg-[var(--color-error-coach-light)] shadow-[inset_3px_0_0_var(--color-error-coach)]',
} as const

/**
 * Eine Zelle des Wochenplans: "8 / 10" mit Fach-Mix, Platz-Punkte je geöffnetem Raum, eine dritte Zeile nur
 * bei Handlungsbedarf. Fläche und Rand nur mit Bedeutung (Entscheidung 28). Die ganze Zelle ist der Link.
 */
export function WochenZelle({ zelle, ziel }: { zelle: WocheZelle; ziel: string }): JSX.Element {
  const { t } = useTranslation('slots')
  const zustand = zellZustand(zelle)
  const vergangen = zelle.vergangen ? 'opacity-60' : ''

  if (zustand === 'leer') {
    return (
      <Link
        to={ziel}
        title={t('woche.keinRaum')}
        className={`flex min-h-[44px] h-full items-center justify-center rounded-[var(--radius-md)] text-sm text-[var(--color-text-tertiary)] transition-colors duration-150 ease-out hover:bg-[var(--color-bg-subtle)] ${vergangen}`}
      >
        <span aria-hidden="true">–</span>
        <span className="sr-only">{t('woche.keinRaum')}</span>
      </Link>
    )
  }

  const hinweise = [
    zelle.coach_fehlt > 0 ? t('woche.coachFehlt') : null,
    zelle.ohne_raum > 0 ? t('woche.ohneRaum', { count: zelle.ohne_raum }) : null,
  ].filter(Boolean)

  return (
    <Link
      to={ziel}
      aria-label={[t('woche.zelleLabel', { belegt: zelle.belegt, kapazitaet: zelle.kapazitaet }), ...hinweise].join(', ')}
      className={`flex min-h-[44px] h-full flex-col gap-2 rounded-[var(--radius-md)] py-2 pl-3 pr-2 transition-colors duration-150 ease-out ${FLAECHE[zustand]} ${vergangen}`}
    >
      <span className="flex items-baseline justify-between gap-2">
        <span className="text-sm tabular-nums">
          <span className="font-semibold text-[var(--color-text-primary)]">{zelle.belegt}</span>
          <span className="text-[var(--color-text-tertiary)]"> / {zelle.kapazitaet}</span>
        </span>
        {zelle.faecher.length > 0 && (
          <span className="flex min-w-0 flex-wrap justify-end gap-1">
            {zelle.faecher.map((f) => (
              <span key={f.fach ?? '-'} title={f.fach ?? undefined} className="inline-flex h-5 items-center gap-1 rounded-[var(--radius-full)] border border-[var(--color-border)] px-1 text-xs tabular-nums text-[var(--color-text-secondary)]">
                <span className="font-semibold">{fachKuerzel(f.fach) || '–'}</span>
                {f.zahl}
              </span>
            ))}
          </span>
        )}
      </span>
      {zelle.kapazitaet > 0 || zelle.ohne_raum > 0 ? (
        <PlatzPunkte raeume={raumBelegung(zelle)} ueberhang={zelle.ohne_raum} className="flex-wrap" />
      ) : null}
      {hinweise.length > 0 && (
        <span className="text-xs font-semibold text-[var(--color-error-coach)]">{hinweise.join(' · ')}</span>
      )}
    </Link>
  )
}
