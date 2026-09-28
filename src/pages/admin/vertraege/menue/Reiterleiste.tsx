export type ReiterKey = 'antraege' | 'uebersicht' | 'auslaufend' | 'verzug'

type Reiter = { key: ReiterKey; titel: string; anzahl: number }

/**
 * Die vier Reiter mit ihrem Zaehler. Der Zaehler ist kein Schmuck: er sagt vor
 * dem Klick, ob dahinter Arbeit liegt — bei "Zahlungsverzuege" ist die Null die
 * wichtigste Zahl des Tages.
 */
export function Reiterleiste({
  reiter,
  aktiv,
  onWechsel,
}: {
  reiter: Reiter[]
  aktiv: ReiterKey
  onWechsel: (key: ReiterKey) => void
}): JSX.Element {
  return (
    <div role="tablist" aria-orientation="horizontal" className="flex flex-wrap gap-2">
      {reiter.map((r) => {
        const an = r.key === aktiv
        return (
          <button
            key={r.key}
            type="button"
            role="tab"
            aria-selected={an}
            onClick={() => onWechsel(r.key)}
            className={[
              'inline-flex min-h-[44px] items-center gap-2 rounded-[var(--radius-full)] px-4 text-sm font-semibold transition-colors',
              an
                ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]',
            ].join(' ')}
          >
            {r.titel}
            <span
              className={[
                'rounded-[var(--radius-full)] px-2 py-0.5 text-xs font-bold',
                an
                  ? 'bg-[var(--color-text-inverse)] text-[var(--color-primary)]'
                  : 'bg-[var(--color-bg-app)] text-[var(--color-text-tertiary)]',
              ].join(' ')}
            >
              {r.anzahl}
            </span>
          </button>
        )
      })}
    </div>
  )
}
