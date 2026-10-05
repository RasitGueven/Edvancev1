import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import type { TonKlassen } from './leistenTon'
import type { NavEintrag } from './navTypes'

type Props = {
  eintrag: NavEintrag
  namespace: string
  ton: TonKlassen
  schmal: boolean
  aktiv: boolean
  wert: number | undefined
}

/**
 * Ein Eintrag der Leiste. Voll: Symbol, Name, Zähler-Pille rechts.
 * Schmal: Symbol über Kurzname, der Zähler als Punkt oben rechts am Symbol.
 */
export function ShellNavEintrag({ eintrag, namespace, ton, schmal, aktiv, wert }: Props): JSX.Element {
  const { t } = useTranslation(namespace)
  const { t: tc } = useTranslation('common')
  const Icon = eintrag.icon
  const name = t(eintrag.nameKey)
  const zahl = wert && wert > 0 ? wert : null

  const symbol = <Icon aria-hidden="true" className={['h-5 w-5 shrink-0', aktiv ? ton.symbolAktiv : ''].join(' ')} />

  const inhalt = schmal ? (
    <>
      <span className="relative">
        {symbol}
        {zahl !== null && !eintrag.bald && (
          <span aria-hidden="true" className={`absolute -right-1 -top-1 h-2 w-2 rounded-[var(--radius-full)] ${ton.punkt}`} />
        )}
      </span>
      <span className="max-w-full truncate text-[11px] leading-tight">{t(eintrag.kurzKey)}</span>
    </>
  ) : (
    <>
      {symbol}
      <span className="min-w-0 flex-1 truncate">{name}</span>
      {eintrag.bald ? (
        <span className={`text-xs ${ton.gruppe}`}>{tc('shell.bald')}</span>
      ) : (
        zahl !== null && (
          <span className={`rounded-[var(--radius-full)] px-2 py-0.5 text-xs font-bold ${ton.pille}`}>{zahl}</span>
        )
      )}
    </>
  )

  const basis = [
    'flex min-h-[44px] items-center rounded-[var(--radius-md)] text-sm font-medium transition-colors',
    schmal ? 'flex-col justify-center gap-1 px-1 py-2 text-center' : 'gap-3 px-3',
  ].join(' ')
  const label = schmal
    ? [name, zahl !== null && !eintrag.bald ? tc('shell.zaehlerLabel', { count: zahl }) : null].filter(Boolean).join(' · ')
    : undefined

  if (eintrag.bald || !eintrag.route) {
    return (
      <span
        aria-disabled="true"
        title={tc('shell.baldHinweis', { name })}
        className={`${basis} cursor-default opacity-50 ${ton.gedimmt}`}
      >
        {inhalt}
      </span>
    )
  }

  return (
    <Link
      to={eintrag.route}
      aria-current={aktiv ? 'page' : undefined}
      aria-label={label}
      title={schmal ? name : undefined}
      className={`${basis} ${aktiv ? ton.aktiv : `${ton.gedimmt} ${ton.hover}`} focus-visible:outline-2 focus-visible:outline-[var(--color-gold-altgold)]`}
    >
      {inhalt}
    </Link>
  )
}
