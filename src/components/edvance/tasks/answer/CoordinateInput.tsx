import { useCallback, useEffect, useRef, useState, type JSX } from 'react'
import { Mafs, Coordinates, useMovablePoint, Point, Line, Theme } from 'mafs'
import type { CoordinateAnswerPayload, CoordinateGrid } from '@/types'
import type { TaskAnswerInputProps } from './types'

type Vec2 = [number, number]

function snapClamp(v: number, range: [number, number], step: number): number {
  const snapped = step > 0 ? Math.round(v / step) * step : v
  return Math.min(range[1], Math.max(range[0], snapped))
}

function pointCount(p: CoordinateAnswerPayload): number {
  if (p.task === 'place_point') return 1
  if (p.task === 'draw_segment') return 2
  return Math.max(1, p.expected.points?.length ?? 2)
}

function initialPoints(p: CoordinateAnswerPayload, count: number): Vec2[] {
  const { xRange, yRange, step } = p.grid
  const cx = snapClamp((xRange[0] + xRange[1]) / 2, xRange, step)
  const cy = snapClamp((yRange[0] + yRange[1]) / 2, yRange, step)
  return Array.from(
    { length: count },
    (_, i) => [snapClamp(cx + i * step, xRange, step), cy] as Vec2,
  )
}

// Ein bewegbarer, raster-gerasteter Punkt (Tastatur-bedienbar von Mafs aus).
function SnapPoint({
  initial,
  grid,
  disabled,
  onMove,
}: {
  initial: Vec2
  grid: CoordinateGrid
  disabled: boolean
  onMove: (p: Vec2) => void
}): JSX.Element {
  const [x0, x1] = grid.xRange
  const [y0, y1] = grid.yRange
  const constrain = useCallback(
    (p: Vec2): Vec2 => [
      snapClamp(p[0], [x0, x1], grid.step),
      snapClamp(p[1], [y0, y1], grid.step),
    ],
    [x0, x1, y0, y1, grid.step],
  )
  const mp = useMovablePoint(initial, { constrain, color: Theme.blue })
  const last = useRef<Vec2>(initial)
  useEffect(() => {
    if (mp.x !== last.current[0] || mp.y !== last.current[1]) {
      last.current = [mp.x, mp.y]
      onMove([mp.x, mp.y])
    }
  })
  if (disabled) return <Point x={initial[0]} y={initial[1]} color={Theme.blue} />
  return mp.element
}

function CoordinateField({
  payload,
  onChange,
  disabled,
}: {
  payload: CoordinateAnswerPayload
  onChange: TaskAnswerInputProps['onChange']
  disabled: boolean
}): JSX.Element {
  const count = pointCount(payload)
  const [points, setPoints] = useState<Vec2[]>(() => initialPoints(payload, count))

  // Start-Punkte einmalig als Antwort melden (Punkte existieren ab Start).
  useEffect(() => {
    onChange({ input_type: 'COORDINATE', points })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  function handleMove(i: number, np: Vec2): void {
    const next = points.map((q, j) => (j === i ? np : q))
    setPoints(next)
    onChange({ input_type: 'COORDINATE', points: next })
  }

  const showSegment = payload.task === 'draw_segment' && points.length >= 2

  return (
    <div className="overflow-hidden rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-white shadow-[var(--shadow-card)]">
      <Mafs
        viewBox={{ x: payload.grid.xRange, y: payload.grid.yRange }}
        pan={false}
        zoom={false}
        preserveAspectRatio={false}
        height={300}
      >
        <Coordinates.Cartesian subdivisions={1} />
        {showSegment && (
          <Line.Segment point1={points[0]} point2={points[1]} color={Theme.blue} />
        )}
        {points.map((p, i) => (
          <SnapPoint
            key={i}
            initial={p}
            grid={payload.grid}
            disabled={disabled}
            onMove={(np) => handleMove(i, np)}
          />
        ))}
      </Mafs>
    </div>
  )
}

export function CoordinateInput({
  payload,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  if (payload.input_type !== 'COORDINATE') return null
  return <CoordinateField payload={payload} onChange={onChange} disabled={disabled ?? false} />
}
