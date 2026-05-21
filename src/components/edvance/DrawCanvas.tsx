// Handschrift-Canvas mit Pointer-Events (Maus, Touch, Stift einheitlich).
// Bei jedem Stroke-Ende wird onChange mit dem aktuellen PNG-Data-URL aufgerufen
// (oder null nach Loeschen). Aufrufer kann den Daten-String z.B. als
// answer_text in der DB speichern.

import { useEffect, useRef, useState, type JSX, type PointerEvent } from 'react'
import { Eraser } from 'lucide-react'

type DrawCanvasProps = {
  onChange?: (dataUrl: string | null) => void
  height?: number
}

const STROKE_COLOR = '#0F172A'
const STROKE_WIDTH = 2.5
const BG_COLOR = '#FFFFFF'

export function DrawCanvas({ onChange, height = 260 }: DrawCanvasProps): JSX.Element {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const drawingRef = useRef<boolean>(false)
  const [hasInk, setHasInk] = useState<boolean>(false)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const parent = canvas.parentElement
    if (!parent) return
    const dpr = window.devicePixelRatio || 1
    const cssWidth = parent.clientWidth || 600
    canvas.width = Math.round(cssWidth * dpr)
    canvas.height = Math.round(height * dpr)
    canvas.style.width = '100%'
    canvas.style.height = `${height}px`
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.scale(dpr, dpr)
    ctx.lineWidth = STROKE_WIDTH
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.strokeStyle = STROKE_COLOR
    // weisser Hintergrund, damit beim Speichern als PNG nicht transparent
    ctx.fillStyle = BG_COLOR
    ctx.fillRect(0, 0, cssWidth, height)
  }, [height])

  function pos(e: PointerEvent<HTMLCanvasElement>): { x: number; y: number } {
    const canvas = canvasRef.current
    if (!canvas) return { x: 0, y: 0 }
    const rect = canvas.getBoundingClientRect()
    return { x: e.clientX - rect.left, y: e.clientY - rect.top }
  }

  function handleDown(e: PointerEvent<HTMLCanvasElement>): void {
    e.preventDefault()
    const ctx = canvasRef.current?.getContext('2d')
    if (!ctx) return
    drawingRef.current = true
    const { x, y } = pos(e)
    ctx.beginPath()
    ctx.moveTo(x, y)
    canvasRef.current?.setPointerCapture(e.pointerId)
  }

  function handleMove(e: PointerEvent<HTMLCanvasElement>): void {
    if (!drawingRef.current) return
    const ctx = canvasRef.current?.getContext('2d')
    if (!ctx) return
    const { x, y } = pos(e)
    ctx.lineTo(x, y)
    ctx.stroke()
    if (!hasInk) setHasInk(true)
  }

  function handleUp(e: PointerEvent<HTMLCanvasElement>): void {
    if (!drawingRef.current) return
    drawingRef.current = false
    canvasRef.current?.releasePointerCapture(e.pointerId)
    if (onChange && canvasRef.current) {
      onChange(canvasRef.current.toDataURL('image/png'))
    }
  }

  function clear(): void {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const dpr = window.devicePixelRatio || 1
    ctx.fillStyle = BG_COLOR
    ctx.fillRect(0, 0, canvas.width / dpr, canvas.height / dpr)
    setHasInk(false)
    onChange?.(null)
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="overflow-hidden rounded-xl border-2 border-border">
        <canvas
          ref={canvasRef}
          onPointerDown={handleDown}
          onPointerMove={handleMove}
          onPointerUp={handleUp}
          onPointerCancel={handleUp}
          className="block touch-none cursor-crosshair bg-white"
        />
      </div>
      <div className="flex items-center justify-between text-xs">
        <p className="text-muted">
          {hasInk ? 'Weiter zeichnen oder loeschen.' : 'Mit Maus, Finger oder Stift zeichnen.'}
        </p>
        <button
          type="button"
          onClick={clear}
          disabled={!hasInk}
          className="inline-flex items-center gap-1 text-muted hover:text-destructive disabled:opacity-40"
        >
          <Eraser className="h-3.5 w-3.5" />
          Loeschen
        </button>
      </div>
    </div>
  )
}
