import type { LeistenTon } from './navTypes'

/**
 * Farben der Leiste je Ton (Bauauftrag Admin-Hülle, Entscheidungen 2 und 3).
 * Navy = Midnight-Verlauf mit Creme-Schrift, Gold-Akzent. Hell = weiß mit
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
  logo: string
  logoAkzent: string
}

const CREME = 'var(--color-stage-text)'

export const LEISTEN_TON: Record<LeistenTon, TonKlassen> = {
  navy: {
    flaeche: 'bg-[image:var(--gradient-midnight)]',
    text: 'text-[var(--color-stage-text)]',
    gedimmt: 'text-[color-mix(in_srgb,var(--color-stage-text)_72%,transparent)]',
    gruppe: 'text-[color-mix(in_srgb,var(--color-stage-text)_56%,transparent)]',
    aktiv: 'bg-[color-mix(in_srgb,var(--color-stage-text)_14%,transparent)] text-[var(--color-stage-text)]',
    hover: 'hover:bg-[color-mix(in_srgb,var(--color-stage-text)_8%,transparent)]',
    symbolAktiv: 'text-[var(--color-gold-altgold)]',
    pille: 'bg-[var(--color-gold-altgold)] text-[var(--color-on-cream)]',
    punkt: 'bg-[var(--color-gold-altgold)]',
    linie: 'border-[color-mix(in_srgb,var(--color-stage-text)_14%,transparent)]',
    logo: CREME,
    logoAkzent: 'var(--color-gold-altgold)',
  },
  hell: {
    flaeche: 'border-r border-[var(--color-border)] bg-[var(--color-bg-surface)]',
    text: 'text-[var(--color-primary)]',
    gedimmt: 'text-[var(--color-text-secondary)]',
    gruppe: 'text-[var(--color-text-tertiary)]',
    aktiv: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
    hover: 'hover:bg-[var(--color-bg-app)]',
    symbolAktiv: 'text-[var(--color-primary)]',
    pille: 'bg-[var(--color-primary)] text-[var(--color-stage-text)]',
    punkt: 'bg-[var(--color-primary)]',
    linie: 'border-[var(--color-border)]',
    logo: 'var(--color-primary)',
    logoAkzent: 'var(--color-gold-altgold)',
  },
}
