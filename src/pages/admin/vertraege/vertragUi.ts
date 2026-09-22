import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import type { VertragStatus } from '@/types'

// Gruen = erledigt, gelb = wartet auf die Eltern. Bewusst NICHT 'mastered':
// das Label gehoert allein dem Coach-Gate (FernUSG).
export const STATUS_BADGE: Record<VertragStatus, EdvanceBadgeVariant> = {
  in_vorbereitung: 'primary',
  unterschrift_ausstehend: 'warning',
  abgeschlossen: 'strength',
  abgelehnt: 'muted',
}

export function unterlagenUrl(vertragId: string, dokument?: string): string {
  const base = `/admin/vertraege/${vertragId}/unterlagen`
  return dokument ? `${base}?dok=${encodeURIComponent(dokument)}` : base
}

/** Oeffnet die druckbare Unterlagenansicht in einem neuen Tab. */
export function openUnterlagen(vertragId: string, dokument?: string): void {
  window.open(unterlagenUrl(vertragId, dokument), '_blank', 'noopener')
}
