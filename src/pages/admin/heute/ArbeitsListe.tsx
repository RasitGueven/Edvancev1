import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight, CheckCircle2, type LucideIcon } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { MAX_ZEILEN } from './heuteModel'

/** Eine Zeile einer Arbeitsliste: Titel, Unterzeile, rechts Pille/Knopf. */
export type ListenZeile = {
  key: string
  titel: ReactNode
  unterzeile?: ReactNode
  rechts?: ReactNode
}

type Props = {
  icon: LucideIcon
  titel: string
  unterzeile: string
  anzahl: number
  zeilen: ListenZeile[]
  /** Text der grünen Zeile, wenn nichts offen ist. Standard: „nichts offen“. */
  leerText?: string
  /** Zusätzliche Zeilen nach den Einträgen, z. B. „Keine Zahlungsverzüge“. */
  nachZeilen?: ReactNode
  fussLabel: string
  fussZiel: string
}

/** Grüne Zeile mit Häkchen — die Null ist sichtbar (Entscheidung 7). */
export function OkZeile({ text }: { text: string }): JSX.Element {
  return (
    <li className="flex min-h-[44px] items-center gap-2 border-t border-[var(--color-border)] py-2 text-sm font-medium text-[var(--color-success)]">
      <CheckCircle2 aria-hidden="true" className="h-4 w-4 shrink-0" />
      {text}
    </li>
  )
}

/**
 * Eine Arbeitsliste der Startseite als Zeile der Karte „Zu erledigen“ (CI-1):
 * Symbol, Titel, Unterzeile, Zähler und genau eine Aktion (in den Bereich).
 * Darunter höchstens drei Einträge, „und n weitere“. Eine leere Liste bleibt
 * stehen, blass mit Haken und „nichts offen“ (Entscheidung 7).
 */
export function ArbeitsListe({
  icon: Icon,
  titel,
  unterzeile,
  anzahl,
  zeilen,
  leerText,
  nachZeilen,
  fussLabel,
  fussZiel,
}: Props): JSX.Element {
  const { t } = useTranslation('admin')
  const leer = anzahl === 0
  const sichtbar = zeilen.slice(0, MAX_ZEILEN)
  const weitere = Math.max(0, zeilen.length - sichtbar.length)

  return (
    <div className={`flex flex-col p-4 ${leer ? 'opacity-60' : ''}`}>
      <header className="flex items-center gap-4">
        <span
          className={`inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-md)] ${
            leer
              ? 'bg-[var(--color-success-light)] text-[var(--color-success)]'
              : 'bg-[var(--color-primary-light)] text-[var(--color-primary)]'
          }`}
        >
          {leer ? <CheckCircle2 aria-hidden="true" className="h-5 w-5" /> : <Icon aria-hidden="true" className="h-5 w-5" />}
        </span>
        <div className="flex min-w-0 flex-1 flex-col">
          <h3 className="text-base font-semibold">{titel}</h3>
          <p className="truncate text-xs text-[var(--color-text-tertiary)]">{unterzeile}</p>
        </div>
        <span
          className={`min-w-[2.5rem] rounded-[var(--radius-md)] px-2 py-1 text-center text-base font-bold tabular-nums ${
            leer ? 'text-[var(--color-success)]' : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-primary)]'
          }`}
        >
          {anzahl}
        </span>
        <Link
          to={fussZiel}
          aria-label={fussLabel}
          title={fussLabel}
          className="inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-[var(--radius-feld)] text-[var(--color-text-link)] hover:bg-[var(--color-primary-light)]"
        >
          <ArrowRight aria-hidden="true" className="h-5 w-5" />
        </Link>
      </header>

      <ul className="flex flex-col pl-[3.25rem]">
        {sichtbar.map((z) => (
          <li key={z.key} className="flex min-h-[54px] items-center gap-2 border-t border-[var(--color-border)] py-2 first:mt-2">
            <div className="flex min-w-0 flex-1 flex-col">
              <span className="truncate text-sm font-semibold">{z.titel}</span>
              {z.unterzeile && (
                <span className="truncate text-xs text-[var(--color-text-tertiary)]">{z.unterzeile}</span>
              )}
            </div>
            {z.rechts && <div className="flex shrink-0 items-center gap-2">{z.rechts}</div>}
          </li>
        ))}
        {zeilen.length === 0 && <OkZeile text={leerText ?? t('heute.nichtsOffen')} />}
        {nachZeilen}
      </ul>

      {weitere > 0 && (
        <p className="pl-[3.25rem] pt-2 text-xs text-[var(--color-text-tertiary)]">{t('heute.weitere', { count: weitere })}</p>
      )}
    </div>
  )
}
