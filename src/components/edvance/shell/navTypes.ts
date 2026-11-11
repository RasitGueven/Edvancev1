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
  /**
   * Arbeitsbereich (CI-1): Mit Symbol zeigt die schmale Leiste die Gruppe als
   * einen Eintrag (Symbol + Titel), der auf den ersten Unterpunkt führt und auf
   * allen Unterpunkten aktiv ist. Ohne Symbol stehen die Einträge einzeln da.
   */
  icon?: LucideIcon
  eintraege: NavEintrag[]
}

export type NavKonfiguration = {
  /** i18n-Namespace aller Schlüssel dieser Konfiguration. */
  namespace: string
  /** Kleine Marke neben dem Logo, z. B. „Admin“. */
  rolleKey: string
  gruppen: NavGruppe[]
  /** Einträge im Fuß der Leiste, über dem Konto (z. B. Einstellungen). */
  fuss?: NavEintrag[]
  /** Kleines Horizont-Motiv unten in der Leiste (nur Admin, CI-1). */
  horizont?: boolean
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

/**
 * Ein Arbeitsbereich als ein Eintrag der schmalen Leiste: Ziel ist der erste
 * Unterpunkt mit Route, aktiv auf allen Mustern der Unterpunkte, Zähler als Summe.
 */
export function bereichAlsEintrag(gruppe: NavGruppe & { icon: LucideIcon; titelKey: string }): NavEintrag {
  const mitRoute = gruppe.eintraege.filter((e) => e.route && !e.bald)
  return {
    id: gruppe.id,
    route: mitRoute[0]?.route,
    aktivBei: mitRoute.flatMap((e) => e.aktivBei ?? [e.route as string]),
    nameKey: gruppe.titelKey,
    kurzKey: gruppe.titelKey,
    icon: gruppe.icon,
  }
}

export function bereichZaehler(gruppe: NavGruppe, zaehler: Zaehlerwerte): number {
  return gruppe.eintraege.reduce((summe, e) => summe + (e.zaehler && !e.bald ? (zaehler[e.zaehler] ?? 0) : 0), 0)
}
