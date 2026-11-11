import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'

export type LogoFassung = 'logo' | 'wortmarke' | 'zeichen'
export type LogoGrund = 'hell' | 'dunkel' | 'cobalt'

type Props = {
  /** logo = Zeichen und Wortmarke, wortmarke = nur Schrift, zeichen = Schale mit Lichtpunkt. */
  fassung?: LogoFassung
  /** Grund, auf dem das Logo steht: hell (Ivory/Weiß), dunkel (Navy), cobalt. */
  grund?: LogoGrund
  /** Höhe über Tailwind (z. B. h-6); die Breite folgt dem Seitenverhältnis der Datei. */
  className?: string
  /** Neben sichtbarem Markennamen: leeres alt, damit Screenreader nicht doppelt lesen. */
  dekorativ?: boolean
}

/**
 * Logo „Funke“ (Brand Foundation v1.2, Bauauftrag CI-1). Einzige Quelle sind
 * die SVG-Dateien aus docs/marke/logo/, unverändert nach public/marke/ kopiert.
 * Nichts wird nachgezeichnet; Farben stecken in den Dateien je Grund.
 */
export function MarkenLogo({ fassung = 'logo', grund = 'hell', className, dekorativ = false }: Props): JSX.Element {
  const { t } = useTranslation('common')
  return (
    <img
      src={`/marke/edvance-${fassung}-auf-${grund}.svg`}
      alt={dekorativ ? '' : t('marke.name')}
      className={cn('block h-6 w-auto select-none', className)}
      draggable={false}
    />
  )
}
