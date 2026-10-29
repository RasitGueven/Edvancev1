// Pruefstand der Session-Muster (Bauformen, Reihe 1): wie im Item-Board heisst „geprueft“ Lena hat zugestimmt,
// also zur Freigabe oder schon freigegeben.
import type { BauformStatus } from '@/types/bauformPruefung'

export type MusterStand = { total: number; geprueft: number; freigegeben: number }

export const GEPRUEFT: readonly BauformStatus[] = ['zur_freigabe', 'freigegeben']

export function musterStand(liste: { status: BauformStatus }[]): MusterStand {
  return {
    total: liste.length,
    geprueft: liste.filter((b) => GEPRUEFT.includes(b.status)).length,
    freigegeben: liste.filter((b) => b.status === 'freigegeben').length,
  }
}
