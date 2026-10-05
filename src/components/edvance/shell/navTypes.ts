import type { LucideIcon } from 'lucide-react'

/**
 * Konfiguration der Leiste. Die Hülle (shell/) kennt keine Rolle — welche
 * Einträge es gibt, bringt die Konfiguration mit (admin/adminNav.ts, später
 * die Coach-Sicht).
 */
export type NavEintrag = {
  id: string
  /** Ziel des Links. Fehlt bei Einträgen, die noch „bald“ sind. */
  route?: string
  /**
   * Pfade, auf denen der Eintrag als aktiv gilt. `*` am Ende = Präfix
   * (`/admin/akten*` trifft `/admin/akten/123`). Ohne Angabe: nur `route`.
   */
  aktivBei?: string[]
  /** i18n-Schlüssel (im Namespace der Konfiguration) für Name und Kurzname. */
  nameKey: string
  kurzKey: string
  icon: LucideIcon
  /** Schlüssel in den Zählerwerten, die die Hülle als Prop bekommt. */
  zaehler?: string
  /** Noch ohne Route: ausgegraut, nicht klickbar. */
  bald?: boolean
}

export type NavGruppe = {
  id: string
  /** Ohne Titel steht die Gruppe ganz oben (z. B. „Heute“). */
  titelKey?: string
  eintraege: NavEintrag[]
}

export type NavKonfiguration = {
  /** i18n-Namespace aller Schlüssel dieser Konfiguration. */
  namespace: string
  /** Kleine Marke neben dem Logo, z. B. „Admin“. */
  rolleKey: string
  gruppen: NavGruppe[]
}

export type Zaehlerwerte = Partial<Record<string, number>>

export type LeistenTon = 'navy' | 'hell'

function trifft(muster: string, pfad: string): boolean {
  if (!muster.endsWith('*')) return pfad === muster
  return pfad.startsWith(muster.slice(0, -1))
}

export function istAktiv(eintrag: NavEintrag, pfad: string): boolean {
  const muster = eintrag.aktivBei ?? (eintrag.route ? [eintrag.route] : [])
  return muster.some((m) => trifft(m, pfad))
}
