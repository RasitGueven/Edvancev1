import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
} from 'react'

export type SignaturePadHandle = {
  clear: () => void
  toDataURL: () => string
}

type SignaturePadProps = {
  /** Meldet, ob bereits etwas gezeichnet wurde — steuert „Unterschreiben". */
  onInkChange: (hasInk: boolean) => void
}

/**
 * Unterschriftenfeld auf einem <canvas>, gezeichnet ueber Pointer-Events —
 * damit funktionieren Maus, Stift und Finger gleichermassen. Bewusst ohne
 * Fremdpaket.
 *
 * Die Zeichenflaeche wird in Geraetepixeln gefuehrt (devicePixelRatio), damit
 * die Linie auf Tablets nicht ausfranst; die CSS-Groesse bleibt davon
 * unberuehrt.
 */
export const SignaturePad = forwardRef<SignaturePadHandle, SignaturePadProps>(
  function SignaturePad({ onInkChange }, ref) {
    const canvasRef = useRef<HTMLCanvasElement | null>(null)
    const drawing = useRef(false)
    const hasInk = useRef(false)

    const context = (): CanvasRenderingContext2D | null =>
      canvasRef.current?.getContext('2d') ?? null

    // Canvas an seine dargestellte Groesse angleichen. Ein Resize leert die
    // Flaeche — deshalb faellt dabei auch die bisherige Zeichnung weg.
    const resize = useCallback((): void => {
      const canvas = canvasRef.current
      if (!canvas) return
      const rect = canvas.getBoundingClientRect()
      if (rect.width === 0 || rect.height === 0) return
      const ratio = window.devicePixelRatio || 1
      canvas.width = Math.round(rect.width * ratio)
      canvas.height = Math.round(rect.height * ratio)
      const ctx = context()
      if (!ctx) return
      ctx.scale(ratio, ratio)
      ctx.lineWidth = 2
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'
      ctx.strokeStyle = getComputedStyle(canvas).color
      hasInk.current = false
      onInkChange(false)
    }, [onInkChange])

    useEffect(() => {
      resize()
      window.addEventListener('resize', resize)
      return () => window.removeEventListener('resize', resize)
    }, [resize])

    useImperativeHandle(ref, () => ({
      clear: () => {
        const canvas = canvasRef.current
        const ctx = context()
        if (!canvas || !ctx) return
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        hasInk.current = false
        onInkChange(false)
      },
      toDataURL: () => canvasRef.current?.toDataURL('image/png') ?? '',
    }))

    const pointAt = (e: React.PointerEvent<HTMLCanvasElement>): [number, number] => {
      const rect = e.currentTarget.getBoundingClientRect()
      return [e.clientX - rect.left, e.clientY - rect.top]
    }

    const start = (e: React.PointerEvent<HTMLCanvasElement>): void => {
      const ctx = context()
      if (!ctx) return
      e.currentTarget.setPointerCapture(e.pointerId)
      drawing.current = true
      const [x, y] = pointAt(e)
      ctx.beginPath()
      ctx.moveTo(x, y)
    }

    const move = (e: React.PointerEvent<HTMLCanvasElement>): void => {
      if (!drawing.current) return
      const ctx = context()
      if (!ctx) return
      const [x, y] = pointAt(e)
      ctx.lineTo(x, y)
      ctx.stroke()
      if (!hasInk.current) {
        hasInk.current = true
        onInkChange(true)
      }
    }

    const end = (e: React.PointerEvent<HTMLCanvasElement>): void => {
      if (!drawing.current) return
      drawing.current = false
      // Ein reiner Klick ohne Bewegung soll trotzdem einen Punkt setzen.
      const ctx = context()
      if (ctx) {
        const [x, y] = pointAt(e)
        ctx.lineTo(x, y)
        ctx.stroke()
      }
      if (!hasInk.current) {
        hasInk.current = true
        onInkChange(true)
      }
    }

    return (
      <div className="relative w-full">
        <canvas
          ref={canvasRef}
          onPointerDown={start}
          onPointerMove={move}
          onPointerUp={end}
          onPointerLeave={end}
          aria-label="Unterschriftenfeld"
          className="h-40 w-full touch-none rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-primary)]"
        />
        {/* Angedeutete Grundlinie — rein dekorativ, liegt unter dem Zeiger. */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-6 bottom-8 border-b border-dashed border-[var(--color-border)]"
        />
      </div>
    )
  },
)
