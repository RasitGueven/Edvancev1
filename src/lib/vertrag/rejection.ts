import type { RejectionReason } from '@/types'

/** Reihenfolge der Auswahl im Ablehnen-Dialog (Lead und Vertrag). */
export const REJECTION_REASONS: RejectionReason[] = [
  'preis',
  'zeit',
  'anderer_anbieter',
  'kein_bedarf',
  'kein_kontakt',
  'sonstiges',
]

/** Spiegel des DB-Checks: "Sonstiges" nur mit Freitext. */
export function isRejectionComplete(reason: RejectionReason | null, note: string): boolean {
  if (reason === null) return false
  return reason !== 'sonstiges' || note.trim() !== ''
}
