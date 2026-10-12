export type ReiterTon = 'neutral' | 'handeln'

export type Reiter<K extends string> = {
  key: K
  titel: string
  /** Zähler hinter dem Titel; ohne Zähler steht nur der Titel. */
  anzahl?: number
  /** handeln = der Zähler steht in der Handeln-Farbe (Arbeit, die sofort ansteht). */
  ton?: ReiterTon
}

/**
 * Reiter als Pillen mit Zähler (Verträge, Slots). Der Zähler ist kein Schmuck: er sagt vor dem Klick,
 * ob dahinter Arbeit liegt. Welche Reiter es gibt und wohin sie führen, entscheidet der Aufrufer.
 */
export function Reiterleiste<K extends string>({
  reiter,
  aktiv,
  onWechsel,
  label,
}: {
  reiter: Reiter<K>[]
  aktiv: K
  onWechsel: (key: K) => void
  /** Name der Reiterleiste für Screenreader. */
  label?: string
}): JSX.Element {
  return (
    <div role="tablist" aria-orientation="horizontal" aria-label={label} className="flex flex-wrap gap-2">
      {reiter.map((r) => {
        const an = r.key === aktiv
        const handeln = r.ton === 'handeln' && (r.anzahl ?? 0) > 0
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
            {r.anzahl !== undefined && (
              <span
                className={[
                  'rounded-[var(--radius-full)] px-2 py-0.5 text-xs font-bold',
                  an
                    ? 'bg-[var(--color-text-inverse)] text-[var(--color-primary)]'
                    : handeln
                      ? 'bg-[var(--color-error-coach-light)] text-[var(--color-error-coach)]'
                      : 'bg-[var(--color-bg-app)] text-[var(--color-text-tertiary)]',
                ].join(' ')}
              >
                {r.anzahl}
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}
