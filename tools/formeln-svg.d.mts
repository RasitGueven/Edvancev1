// Typen fuer tools/formeln-svg.mjs. Das Werkzeug bleibt .mjs, damit es ohne Bauschritt
// laeuft; der Test importiert es und braucht diese Beschreibung.

export const BUCKET: string
export const PFAD: string

export type Formel = { tex: string; svg: string; hash: string; pfad: string }
export type Schritt = { id: string; inhalt: string; formeln?: string[] }
export type Stand = { geladen: number; uebersprungen: number; fehler: number }

export function formelnFinden(inhalt: string | null | undefined): string[]
export function texZuSvg(tex: string): string
export function pruefeSvg(svg: string): string | null
export function svgHash(svg: string): string
export function schrittFormeln(inhalt: string): Formel[]
export function lauf(opts: {
  schritte: Schritt[]
  dryRun: boolean
  hochladen: (pfad: string, svg: string) => Promise<void> | void
  eintragen: (id: string, inhalt: string, hashes: string[]) => Promise<void> | void
  log?: (zeile: string) => void
}): Promise<Stand>
export function main(argv?: string[]): Promise<number>
