import type { TFunction } from 'i18next'
import type { DurchklickStand } from '@/types'

/**
 * Der Grund „nicht auswertbar“ als Satzteil (LSA-R2), für den Tooltip in der
 * Liste und den Hinweisbalken im Report. Die Schwellen kommen aus dem
 * gespeicherten Stand (lsa_durchklick_stand), nicht aus dem Code. Ohne Stand
 * (vor der Migration abgeschlossen) bleibt der allgemeine Satz.
 */
export function durchklickGrund(
  t: TFunction<'admin'>,
  sprache: string,
  stand: DurchklickStand | null | undefined,
): string {
  if (!stand?.grund || !stand.schwellen) return t('durchklick.grund.unbekannt')
  const sekunden = new Intl.NumberFormat(sprache).format(stand.schwellen.schnell_ms / 1000)
  if (stand.grund === 'folge') {
    return t('durchklick.grund.folge', { folge: stand.folge_schnell_falsch_max, sekunden })
  }
  return t('durchklick.grund.anteil', { anteil: prozent(sprache, stand.anteil_schnell_falsch), sekunden })
}

/** 0,75 → „75 %“ in der Sprache der Oberfläche. */
export function prozent(sprache: string, anteil: number): string {
  return new Intl.NumberFormat(sprache, { style: 'percent', maximumFractionDigits: 0 }).format(anteil)
}
