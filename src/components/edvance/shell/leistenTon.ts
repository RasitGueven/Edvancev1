import type { LogoGrund } from '@/components/brand/MarkenLogo'
import type { LeistenTon } from './navTypes'

/**
 * Farben der Leiste je Ton (Bauauftrag Admin-Hülle, Entscheidungen 2 und 3).
 * Navy = Markenleiste (CI-1) mit Ivory-Schrift, Amber-Akzent, aktiv Cobalt. Hell = weiß mit
 * Navy-Schrift. Ausschließlich Tokens.
 */
export type TonKlassen = {
  flaeche: string
  text: string
  gedimmt: string
  gruppe: string
  aktiv: string
  hover: string
  symbolAktiv: string
  pille: string
  punkt: string
  linie: string
  logoGrund: LogoGrund
}

export const LEISTEN_TON: Record<LeistenTon, TonKlassen> = {
  navy: {
    flaeche: 'marke-leiste',
    text: 'text-[var(--color-marke-ivory)]',
    gedimmt: 'text-[color-mix(in_srgb,var(--color-marke-ivory)_76%,transparent)]',
    gruppe: 'text-[color-mix(in_srgb,var(--color-marke-ivory)_60%,transparent)]',
    // CI-1: aktiver Bereich in Cobalt mit etwa 35 % Deckkraft.
    aktiv: 'bg-[color-mix(in_srgb,var(--color-marke-cobalt)_35%,transparent)] text-[var(--color-marke-ivory)]',
    hover: 'hover:bg-[color-mix(in_srgb,var(--color-marke-ivory)_8%,transparent)]',
    symbolAktiv: 'text-[var(--color-marke-amber)]',
    pille: 'bg-[var(--color-marke-amber)] text-[var(--color-marke-navy)] tabular-nums',
    punkt: 'bg-[var(--color-marke-amber)]',
    linie: 'border-[color-mix(in_srgb,var(--color-marke-ivory)_14%,transparent)]',
    logoGrund: 'dunkel',
  },
  hell: {
    flaeche: 'border-r border-[var(--color-border)] bg-[var(--color-bg-surface)]',
    text: 'text-[var(--color-primary)]',
    gedimmt: 'text-[var(--color-text-secondary)]',
    gruppe: 'text-[var(--color-text-tertiary)]',
    aktiv: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
    hover: 'hover:bg-[var(--color-bg-app)]',
    symbolAktiv: 'text-[var(--color-primary)]',
    pille: 'bg-[var(--color-primary)] text-[var(--color-marke-weiss)] tabular-nums',
    punkt: 'bg-[var(--color-primary)]',
    linie: 'border-[var(--color-border)]',
    logoGrund: 'hell',
  },
}
