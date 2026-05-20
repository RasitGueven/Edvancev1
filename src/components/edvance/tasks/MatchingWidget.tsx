import { useState, type JSX } from 'react'

export type MatchPairs = Map<number, number> // leftIdx → rightIdx

type Props = {
  left: string[]
  right: string[] // kann vorgemischt übergeben werden
  pairs: MatchPairs
  onChange: (p: MatchPairs) => void
  disabled: boolean
}

const TINTS = [
  { line: 'var(--primary)',      fill: 'color-mix(in srgb, var(--primary) 10%, white)' },
  { line: 'var(--success)',      fill: 'color-mix(in srgb, var(--success) 10%, white)' },
  { line: 'var(--warning)',      fill: 'color-mix(in srgb, var(--warning) 10%, white)' },
  { line: 'var(--level-purple)', fill: 'color-mix(in srgb, var(--level-purple) 10%, white)' },
]

function tintFor(pairIndex: number) {
  return TINTS[pairIndex % TINTS.length]
}

export function MatchingWidget({ left, right, pairs, onChange, disabled }: Props): JSX.Element {
  const [active, setActive] = useState<number | null>(null)

  // reverse map: rightIdx → leftIdx
  const r2l = new Map<number, number>()
  pairs.forEach((r, l) => r2l.set(r, l))

  // stable color order = insertion order of pairs
  function colorIndex(leftIdx: number): number {
    let ci = 0
    for (const [k] of pairs) {
      if (k === leftIdx) return ci
      ci++
    }
    return -1
  }

  function pickLeft(i: number) {
    if (disabled) return
    setActive(active === i ? null : i)
  }

  function pickRight(j: number) {
    if (disabled) return
    if (active === null) {
      if (r2l.has(j)) {
        const next = new Map(pairs)
        next.delete(r2l.get(j)!)
        onChange(next)
      }
      return
    }
    const next = new Map(pairs)
    if (r2l.has(j)) next.delete(r2l.get(j)!) // steal
    if (next.has(active)) next.delete(active) // replace old
    next.set(active, j)
    setActive(null)
    onChange(next)
  }

  function itemStyle(accent: { line: string; fill: string } | null) {
    return accent ? { borderColor: accent.line, background: accent.fill } : undefined
  }

  const baseCls =
    'flex min-h-[44px] w-full cursor-pointer select-none items-center gap-2 rounded-xl border-2 px-3 py-2 text-sm transition-all'

  return (
    <div className="grid grid-cols-2 gap-x-4 gap-y-1.5">
      <p className="text-[10px] font-bold uppercase tracking-wider text-muted">Begriff</p>
      <p className="text-[10px] font-bold uppercase tracking-wider text-muted">
        {active !== null ? '← hier klicken' : 'Zuordnung'}
      </p>

      {left.map((item, i) => {
        const ci = colorIndex(i)
        const accent = ci >= 0 ? tintFor(ci) : null
        const isActive = active === i
        return (
          <button
            key={i}
            type="button"
            onClick={() => pickLeft(i)}
            className={`${baseCls} ${isActive ? 'border-[var(--primary)] bg-[var(--primary-pale)]' : accent ? '' : 'border-[var(--border)] bg-card hover:border-[var(--primary-light)]'}`}
            style={itemStyle(isActive ? null : accent)}
          >
            {accent && (
              <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: accent.line }} />
            )}
            <span className="flex-1">{item}</span>
          </button>
        )
      })}

      {right.map((item, j) => {
        const lIdx = r2l.get(j)
        const ci = lIdx !== undefined ? colorIndex(lIdx) : -1
        const accent = ci >= 0 ? tintFor(ci) : null
        const isTarget = active !== null && !r2l.has(j)
        return (
          <button
            key={j}
            type="button"
            onClick={() => pickRight(j)}
            className={`${baseCls} ${accent ? '' : isTarget ? 'border-dashed border-[var(--primary)] bg-[var(--primary-pale)]' : 'border-[var(--border)] bg-card hover:border-[var(--primary-light)]'}`}
            style={itemStyle(accent)}
          >
            {accent && (
              <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: accent.line }} />
            )}
            <span className="flex-1">{item}</span>
          </button>
        )
      })}
    </div>
  )
}
