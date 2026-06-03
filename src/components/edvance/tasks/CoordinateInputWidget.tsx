import { useEffect, useRef, type JSX } from 'react'
import JXG from 'jsxgraph'

export interface CoordPoint {
  x: number
  y: number
}

interface CoordinateInputWidgetProps {
  /** Gerade = 2 Punkte; Parabel = Scheitelpunkt + 1 weiterer Punkt. */
  shape: 'line' | 'parabola'
  initialPoints: CoordPoint[]
  /** Beschriftung der Punkte (z.B. ['P','Q'] oder ['S','P']). */
  pointLabels: string[]
  onChange: (points: CoordPoint[]) => void
  disabled?: boolean
}

const BOUND = 6 // sichtbarer Bereich −BOUND … +BOUND

/** Liest eine CSS-Variable vom Wurzelelement (kein hardcoded Hex, §11). */
function cssVar(name: string, fallback: string): string {
  if (typeof window === 'undefined') return fallback
  const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim()
  return v || fallback
}

export function CoordinateInputWidget({
  shape,
  initialPoints,
  pointLabels,
  onChange,
  disabled = false,
}: CoordinateInputWidgetProps): JSX.Element {
  const hostRef = useRef<HTMLDivElement | null>(null)
  const boardRef = useRef<JXG.Board | null>(null)
  const pointsRef = useRef<JXG.Point[]>([])
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange

  // Board einmalig aufbauen (Punkte, Kurve, Drag-Listener).
  useEffect(() => {
    const host = hostRef.current
    if (!host) return

    const primary = cssVar('--color-primary', '#4f46e5')
    const curve = cssVar('--color-accent', '#f59e0b')
    const grid = cssVar('--color-border', '#e5e7eb')

    const board = JXG.JSXGraph.initBoard(host, {
      boundingbox: [-BOUND, BOUND, BOUND, -BOUND],
      axis: true,
      showCopyright: false,
      showNavigation: false,
      keepaspectratio: true,
      defaultAxes: {
        x: { ticks: { majorHeight: 8, strokeColor: grid } },
        y: { ticks: { majorHeight: 8, strokeColor: grid } },
      },
    })
    boardRef.current = board

    const points = initialPoints.map((p, i) =>
      board.create('point', [p.x, p.y], {
        name: pointLabels[i] ?? '',
        size: 5,
        snapToGrid: true,
        snapSizeX: 1,
        snapSizeY: 1,
        fillColor: primary,
        strokeColor: primary,
        highlightFillColor: primary,
        label: { offset: [10, 10], fontSize: 16 },
      }),
    )
    pointsRef.current = points

    if (shape === 'line') {
      board.create('line', [points[0], points[1]], {
        strokeColor: curve,
        strokeWidth: 3,
        fixed: true,
        highlightStrokeColor: curve,
      })
    } else {
      // Parabel in Scheitelform: A = Scheitel (h|k), B = weiterer Punkt.
      const [a, b] = points
      board.create(
        'functiongraph',
        [
          (x: number): number => {
            const h = a.X()
            const k = a.Y()
            const dx = b.X() - h
            if (Math.abs(dx) < 1e-6) return NaN
            const coeff = (b.Y() - k) / (dx * dx)
            return coeff * (x - h) * (x - h) + k
          },
          -BOUND,
          BOUND,
        ],
        { strokeColor: curve, strokeWidth: 3, fixed: true, highlightStrokeColor: curve },
      )
    }

    const emit = (): void => {
      onChangeRef.current(
        pointsRef.current.map((pt) => ({ x: pt.X(), y: pt.Y() })),
      )
    }
    points.forEach((pt) => pt.on('drag', emit))
    emit()

    return () => {
      JXG.JSXGraph.freeBoard(board)
      boardRef.current = null
      pointsRef.current = []
    }
    // Aufbau hängt nur an der Aufgabe (shape/Startpunkte), nicht an onChange.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [shape])

  // Nach dem Absenden: Punkte fixieren (kein weiteres Ziehen).
  useEffect(() => {
    pointsRef.current.forEach((pt) =>
      pt.setAttribute({ fixed: disabled, frozen: disabled }),
    )
  }, [disabled])

  return (
    <div
      ref={hostRef}
      className="aspect-square w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)]"
      aria-label="Interaktives Koordinatensystem"
      role="application"
    />
  )
}
