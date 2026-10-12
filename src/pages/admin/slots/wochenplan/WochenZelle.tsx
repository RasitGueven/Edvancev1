import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { PlatzPunkte } from '@/components/edvance'
import type { WocheZelle } from '@/types/slotplan'
import { fachKuerzel } from '../slotsFormat'
import { raumBelegung, zellZustand } from '../slots.model'

const FLAECHE = {
  leer: 'border-transparent bg-[var(--color-bg-surface)]',
  normal: 'border-transparent bg-[var(--color-bg-surface)] hover:bg-[var(--color-bg-subtle)]',
  achtung: 'border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)]',
  handeln: 'border-[var(--color-error-coach)] bg-[var(--color-error-coach-light)]',
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
  const mix = zelle.faecher.map((f) => `${fachKuerzel(f.fach) || '–'} ${f.zahl}`).join(' · ')

  return (
    <Link
      to={ziel}
      aria-label={t('woche.zelleLabel', { belegt: zelle.belegt, kapazitaet: zelle.kapazitaet })}
      className={`flex min-h-[44px] h-full flex-col gap-2 rounded-[var(--radius-md)] border-l-[3px] px-2 py-2 transition-colors duration-150 ease-out ${FLAECHE[zustand]} ${vergangen}`}
    >
      <span className="flex items-baseline justify-between gap-2">
        <span className="text-sm tabular-nums">
          <span className="font-semibold text-[var(--color-text-primary)]">{zelle.belegt}</span>
          <span className="text-[var(--color-text-tertiary)]"> / {zelle.kapazitaet}</span>
        </span>
        {mix && <span className="truncate text-xs tabular-nums text-[var(--color-text-tertiary)]">{mix}</span>}
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
