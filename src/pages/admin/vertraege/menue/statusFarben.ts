import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import type { VertragStatus, WirksamerStatus, Zahlungsstatus } from '@/types'

/** Gruen = laeuft, gelb = wartet auf jemanden, rot = jemand muss handeln. */
export const STATUS_FARBE: Record<WirksamerStatus, EdvanceBadgeVariant> = {
  aktiv: 'strength',
  im_widerruf: 'warning',
  gekuendigt: 'exam',
  ausgelaufen: 'muted',
  widerrufen: 'muted',
}

export const ANTRAG_FARBE: Record<VertragStatus, EdvanceBadgeVariant> = {
  in_vorbereitung: 'primary',
  unterschrift_ausstehend: 'warning',
  abgeschlossen: 'strength',
  abgelehnt: 'muted',
}

/** In Ordnung ist still, alles andere faellt auf — je spaeter, desto lauter. */
export const ZAHLUNG_FARBE: Record<Zahlungsstatus, EdvanceBadgeVariant> = {
  in_ordnung: 'muted',
  zahlung_offen: 'warning',
  mahnung_1: 'warning',
  mahnung_2: 'exam',
  inkasso: 'coach-emergency',
}
