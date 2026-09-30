import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import type { Ampel } from '@/types'

/** Farbe hat Bedeutung: gruen im Plan, gelb leicht, rot deutlich im Rueckstand. */
export const AMPEL_BADGE: Record<Ampel, EdvanceBadgeVariant> = {
  im_plan: 'strength',
  leicht_im_rueckstand: 'warning',
  deutlich_im_rueckstand: 'gap',
}
