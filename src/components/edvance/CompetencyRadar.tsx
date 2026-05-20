import type { JSX } from 'react'

export type RadarAxis = {
  label: string
  // Aktueller Wert auf der Achse, 0..max. Null = keine Daten → Punkt fällt auf
  // den Mittelpunkt, Achse wird ausgegraut.
  value: number | null
}

type Props = {
  axes: RadarAxis[]
  max?: number
  size?: number
}

const RING_LEVELS = 4

function polar(
  cx: number,
  cy: number,
  r: number,
  angleRad: number,
): [number, number] {
  return [cx + r * Math.sin(angleRad), cy - r * Math.cos(angleRad)]
}

// FIFA/PES-Style Kompetenz-Radar. Achsenanzahl flexibel (3–8 sinnvoll).
// Ringe markieren Stufen, das aktive Polygon füllt die erreichten Werte.
// Reine SVG-Komponente, keine Chart-Lib.
export function CompetencyRadar({
  axes,
  max = 10,
  size = 280,
}: Props): JSX.Element {
  const cx = size / 2
  const cy = size / 2
  const radius = size * 0.38
  const n = Math.max(3, axes.length)
  const step = (Math.PI * 2) / n

  const ringPoints = (factor: number): string =>
    axes
      .map((_, i) => {
        const [x, y] = polar(cx, cy, radius * factor, i * step)
        return `${x},${y}`
      })
      .join(' ')

  const dataPoints = axes
    .map((a, i) => {
      const f = a.value === null ? 0 : Math.max(0, Math.min(1, a.value / max))
      const [x, y] = polar(cx, cy, radius * f, i * step)
      return `${x},${y}`
    })
    .join(' ')

  return (
    <svg
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label="Kompetenz-Radar"
      className="w-full max-w-[320px]"
    >
      {/* konzentrische Ringe */}
      {Array.from({ length: RING_LEVELS }).map((_, i) => (
        <polygon
          key={i}
          points={ringPoints((i + 1) / RING_LEVELS)}
          fill="none"
          stroke="var(--border)"
          strokeWidth={1}
        />
      ))}

      {/* Achsenlinien */}
      {axes.map((_, i) => {
        const [x, y] = polar(cx, cy, radius, i * step)
        return (
          <line
            key={i}
            x1={cx}
            y1={cy}
            x2={x}
            y2={y}
            stroke="var(--border)"
            strokeWidth={1}
          />
        )
      })}

      {/* Datenfläche */}
      <polygon
        points={dataPoints}
        fill="color-mix(in srgb, var(--primary) 22%, transparent)"
        stroke="var(--primary)"
        strokeWidth={2}
        strokeLinejoin="round"
      />

      {/* Datenpunkte */}
      {axes.map((a, i) => {
        const f = a.value === null ? 0 : Math.max(0, Math.min(1, a.value / max))
        const [x, y] = polar(cx, cy, radius * f, i * step)
        return (
          <circle
            key={i}
            cx={x}
            cy={y}
            r={4}
            fill={a.value === null ? 'var(--text-muted)' : 'var(--primary)'}
            stroke="white"
            strokeWidth={1.5}
          />
        )
      })}

      {/* Labels */}
      {axes.map((a, i) => {
        const [lx, ly] = polar(cx, cy, radius + 22, i * step)
        const anchor =
          Math.abs(lx - cx) < 4 ? 'middle' : lx > cx ? 'start' : 'end'
        return (
          <text
            key={i}
            x={lx}
            y={ly}
            textAnchor={anchor}
            dominantBaseline="middle"
            className="fill-[var(--text-secondary)] text-[11px] font-semibold uppercase tracking-wider"
          >
            {a.label}
          </text>
        )
      })}
    </svg>
  )
}
