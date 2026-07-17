// Bild-Zuschnitt im Autoren-Tool.
//
// WARUM ES DAS GIBT: Die EMF-Renders aus der IQB-Quelle haben den Aufgabentext
// ins Bild eingebrannt. Der Text steht schon im Prompt — das Kind saehe ihn
// doppelt. Der Pfleger stellt hier die reine Figur frei.
//
// ZWEI ZUSAGEN, DIE DIESE DATEI EINHAELT:
//   1. Der Canvas, den der Pfleger als Vorschau sieht, IST die Datei, die
//      hochgeladen wird (toBlob auf genau diesem Element). Keine zweite
//      Rechnung, die anders ausgehen koennte als die gezeigte.
//   2. Es wird ausschliesslich geschnitten. drawImage kopiert den Ausschnitt
//      1:1 in einen Canvas derselben Groesse — kein Skalieren, kein Filtern,
//      kein Rotieren. Die Pixel im Ausschnitt sind dieselben Pixel.

import { useCallback, useEffect, useRef, useState, type JSX, type PointerEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  isUsableCrop,
  normalizeRect,
  toNaturalRect,
  type CropPoint,
  type CropRect,
} from '@/lib/authoring/crop'
import { uploadTaskAssetCrop } from '@/lib/supabase/storage'

export function AssetCropper({
  taskId,
  sourceUrl,
  alt,
  onCropped,
  onCancel,
}: {
  taskId: string
  sourceUrl: string
  alt: string
  onCropped: (cropUrl: string) => void
  onCancel: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const imgRef = useRef<HTMLImageElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)

  const [drag, setDrag] = useState<{ from: CropPoint; to: CropPoint } | null>(null)
  const [rect, setRect] = useState<CropRect | null>(null)
  const [natural, setNatural] = useState<CropRect | null>(null)
  const [busy, setBusy] = useState(false)
  const [broken, setBroken] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const pointIn = (e: PointerEvent<HTMLDivElement>): CropPoint => {
    const box = e.currentTarget.getBoundingClientRect()
    return { x: e.clientX - box.left, y: e.clientY - box.top }
  }

  const onPointerDown = (e: PointerEvent<HTMLDivElement>): void => {
    e.currentTarget.setPointerCapture(e.pointerId)
    const p = pointIn(e)
    setDrag({ from: p, to: p })
    setRect(null)
    setNatural(null)
    setError(null)
  }

  const onPointerMove = (e: PointerEvent<HTMLDivElement>): void => {
    if (!drag) return
    setDrag({ from: drag.from, to: pointIn(e) })
  }

  const onPointerUp = (e: PointerEvent<HTMLDivElement>): void => {
    if (!drag) return
    const img = imgRef.current
    const box = e.currentTarget.getBoundingClientRect()
    const display = normalizeRect(drag.from, pointIn(e))
    setDrag(null)
    if (!img) return

    const nat = toNaturalRect(
      display,
      { width: box.width, height: box.height },
      { width: img.naturalWidth, height: img.naturalHeight },
    )
    if (!isUsableCrop(nat)) {
      setRect(null)
      setNatural(null)
      return
    }
    setRect(display)
    setNatural(nat)
  }

  // Vorschau zeichnen. Genau dieser Canvas wird spaeter hochgeladen.
  useEffect(() => {
    const canvas = canvasRef.current
    const img = imgRef.current
    if (!canvas || !img || !natural) return
    canvas.width = natural.width
    canvas.height = natural.height
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(
      img,
      natural.x,
      natural.y,
      natural.width,
      natural.height,
      0,
      0,
      natural.width,
      natural.height,
    )
  }, [natural])

  const confirm = useCallback(async (): Promise<void> => {
    const canvas = canvasRef.current
    if (!canvas || !natural) return
    setBusy(true)
    setError(null)
    try {
      const blob = await new Promise<Blob | null>((resolve) => {
        canvas.toBlob((b) => resolve(b), 'image/png')
      })
      if (!blob) {
        setError(t('fields.cropUnavailable'))
        return
      }
      const res = await uploadTaskAssetCrop(taskId, sourceUrl, blob)
      if (res.error || !res.data) {
        // Der Grund kommt vom Server (z.B. RLS-Verstoss bei fehlender Admin-
        // Rolle). Ihn zu verschlucken hiesse, den Pfleger raten zu lassen.
        setError(t('fields.cropFailed', { detail: res.error ?? '' }))
        return
      }
      onCropped(res.data.url)
    } catch {
      // SecurityError: Canvas vergiftet — Bild ohne CORS-Freigabe.
      setError(t('fields.cropUnavailable'))
    } finally {
      setBusy(false)
    }
  }, [natural, taskId, sourceUrl, onCropped, t])

  const box = drag ? normalizeRect(drag.from, drag.to) : rect

  return (
    <div className="flex flex-col gap-4 rounded-[var(--radius-md)] border border-[var(--color-primary)] p-4">
      <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
        {t('fields.cropHint')}
      </p>

      <div
        className={`relative max-w-full select-none self-start touch-none ${
          busy || broken ? 'pointer-events-none opacity-60' : 'cursor-crosshair'
        }`}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={() => setDrag(null)}
      >
        <img
          ref={imgRef}
          src={sourceUrl}
          alt={alt}
          // Ohne CORS-Freigabe waere der Canvas vergiftet und toBlob wuerfe.
          // Mit crossOrigin scheitert stattdessen schon das Laden — deshalb
          // braucht es onError: sonst saehe der Pfleger nur einen Cropper, der
          // grundlos keine Auswahl annimmt, und keinen Grund dafuer.
          crossOrigin="anonymous"
          draggable={false}
          onError={() => {
            setBroken(true)
            setError(t('fields.cropUnavailable'))
          }}
          className="max-h-[420px] w-auto max-w-full rounded-[var(--radius-md)] border border-[var(--color-border)]"
        />
        {box && box.width > 0 && box.height > 0 && (
          <div
            className="pointer-events-none absolute border-2 border-[var(--color-primary)] bg-[var(--color-primary)]/10"
            style={{ left: box.x, top: box.y, width: box.width, height: box.height }}
          />
        )}
      </div>

      <div className={natural ? 'flex flex-col gap-2' : 'hidden'}>
        <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
          {t('fields.cropPreview')}
        </span>
        <canvas
          ref={canvasRef}
          className="max-h-48 w-auto max-w-full self-start rounded-[var(--radius-md)] border border-[var(--color-border)]"
        />
        {natural && (
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('fields.cropSize', { width: natural.width, height: natural.height })}
          </span>
        )}
      </div>

      {error && (
        <p className="text-xs leading-relaxed text-[var(--color-destructive)]">{error}</p>
      )}

      <div className="flex items-center gap-2">
        <Button
          size="sm"
          disabled={!natural || busy}
          title={natural ? undefined : t('fields.cropNoSelection')}
          onClick={() => void confirm()}
        >
          <Check className="mr-2 h-4 w-4" />
          {busy ? t('fields.cropSaving') : t('fields.cropConfirm')}
        </Button>
        <Button variant="outline" size="sm" disabled={busy} onClick={onCancel}>
          <X className="mr-2 h-4 w-4" />
          {t('fields.cropCancel')}
        </Button>
      </div>
    </div>
  )
}
