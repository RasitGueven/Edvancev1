// Zuschnitt-Rechnerei fuer den Bild-Crop im Autoren-Tool — reine Funktionen,
// kein DOM, kein Supabase. Damit ist der Teil testbar, an dem man sich beim
// Zuschneiden verrechnet: das Umrechnen vom gezogenen Rechteck (Bildschirm-
// Pixel im skalierten <img>) auf echte Bild-Pixel.
//
// Warum das Original unangetastet bleibt, steht in uploadTaskAssetCrop.

export type CropPoint = { x: number; y: number }
export type CropRect = { x: number; y: number; width: number; height: number }
export type CropSize = { width: number; height: number }

/** Kleinster Ausschnitt, der noch ein Bild ist. Darunter ist es ein Fehlgriff. */
export const MIN_CROP_PX = 8

/**
 * Zwei Drag-Punkte → Rechteck. Der Pfleger darf in jede Richtung ziehen,
 * auch nach oben-links; negative Breiten gibt es hier nicht.
 */
export function normalizeRect(a: CropPoint, b: CropPoint): CropRect {
  return {
    x: Math.min(a.x, b.x),
    y: Math.min(a.y, b.y),
    width: Math.abs(a.x - b.x),
    height: Math.abs(a.y - b.y),
  }
}

/**
 * Rechteck in Anzeige-Pixeln → Rechteck in echten Bild-Pixeln.
 *
 * Das <img> im Editor ist skaliert (max-w), das Bild dahinter ist es nicht.
 * Ohne diese Umrechnung schneidet man an einer anderen Stelle als man zeigt.
 * Geklemmt wird auf die Bildgrenzen: ein Drag, der ueber den Rand hinauszieht,
 * ist eine Geste, kein Fehler — er endet am Rand.
 */
export function toNaturalRect(
  rect: CropRect,
  display: CropSize,
  natural: CropSize,
): CropRect {
  if (display.width <= 0 || display.height <= 0) {
    return { x: 0, y: 0, width: 0, height: 0 }
  }
  const scaleX = natural.width / display.width
  const scaleY = natural.height / display.height

  const left = clamp(Math.round(rect.x * scaleX), 0, natural.width)
  const top = clamp(Math.round(rect.y * scaleY), 0, natural.height)
  const right = clamp(Math.round((rect.x + rect.width) * scaleX), 0, natural.width)
  const bottom = clamp(Math.round((rect.y + rect.height) * scaleY), 0, natural.height)

  return { x: left, y: top, width: right - left, height: bottom - top }
}

/** Zu klein zum Zuschneiden — ein Fehlklick, kein Ausschnitt. */
export function isUsableCrop(rect: CropRect): boolean {
  return rect.width >= MIN_CROP_PX && rect.height >= MIN_CROP_PX
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

// ── Bucket-Pfade ────────────────────────────────────────────────────────────

const PUBLIC_MARKER = '/storage/v1/object/public/'

/**
 * Objektpfad im Bucket aus einer public URL — oder null, wenn die URL nicht auf
 * unseren Bucket zeigt (z.B. von Hand eingetragene Fremd-URL).
 */
export function objectPathFromPublicUrl(url: string, bucket: string): string | null {
  const marker = `${PUBLIC_MARKER}${bucket}/`
  const at = url.indexOf(marker)
  if (at < 0) return null
  const path = url.slice(at + marker.length).split(/[?#]/)[0]
  if (!path) return null
  try {
    return decodeURIComponent(path)
  } catch {
    return path
  }
}

/**
 * Zielpfad des Zuschnitts: neben dem Original, nie darauf.
 *
 * Aus lsa/<slug>/figur.png wird lsa/<slug>/figur-crop-<stamp>.png. Der Stempel
 * ist kein Schmuck: er macht jeden Zuschnitt zu einer neuen Datei. Ohne ihn
 * wuerde der zweite Zuschnitt desselben Bildes auf den ersten fallen — und
 * genau das (upsert) haben wir uns verboten, damit ein Fehlschnitt reversibel
 * bleibt. Liegt das Original nicht in unserem Bucket, landet der Zuschnitt
 * unter tasks/<taskId>/.
 */
export function cropObjectPath(
  sourceUrl: string,
  bucket: string,
  taskId: string,
  stamp: number,
): string {
  const source = objectPathFromPublicUrl(sourceUrl, bucket)
  if (!source) return `tasks/${taskId}/crop-${stamp}.png`

  const slash = source.lastIndexOf('/')
  const dir = slash < 0 ? '' : source.slice(0, slash + 1)
  const file = slash < 0 ? source : source.slice(slash + 1)
  const dot = file.lastIndexOf('.')
  const base = dot <= 0 ? file : file.slice(0, dot)

  return `${dir}${base}-crop-${stamp}.png`
}
