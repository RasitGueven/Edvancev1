// Typen fuer tools/eltern-konten-entfernen.mjs. Das Werkzeug bleibt .mjs, damit es ohne
// Bauschritt laeuft; der Test importiert es und braucht diese Beschreibung.

export type Verknuepfung = { parent: string; istTest: boolean | null }
export type Bestand = { eltern: string[]; links: Verknuepfung[]; blockierend: number; cascade?: number }
export type Zahlen = {
  eltern: number
  elternMitKind: number
  parentStudent: number
  kinderTest: number
  kinderEcht: number
  kinderOhneSchuelerzeile: number
  blockierend: number
  cascade: number
}
export type Plan = { zahlen: Zahlen; abbruch: boolean; gruende: string[] }

export function planen(bestand: Bestand): Plan
export function bericht(plan: Plan, modus: 'dry-run' | 'ausfuehren'): string
export function bestandLesen(): Bestand
export const SQL_BLOCKIEREND: string
export const SQL_CASCADE: string
export type Konten = {
  pruefen: (id: string) => Promise<'parent' | 'fehlt' | 'andere_rolle'>
  verknuepfungenLoeschen: (ids: string[]) => Promise<void>
  kontoLoeschen: (id: string) => Promise<void>
}
export function lauf(opts: {
  modus: 'dry-run' | 'ausfuehren'
  lesen: () => Bestand
  konten: Konten | null
  log?: (zeile: string) => void
}): Promise<{ geloescht: number; abbruch: boolean }>
