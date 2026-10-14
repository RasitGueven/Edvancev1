// Typen fuer tools/eltern-konten-entfernen.mjs. Das Werkzeug bleibt .mjs, damit es ohne
// Bauschritt laeuft; der Test importiert es und braucht diese Beschreibung.

export type Verknuepfung = { parent: string; istTest: boolean | null }
export type Bestand = { eltern: string[]; links: Verknuepfung[]; blockierend: number }
export type Zahlen = {
  eltern: number
  elternMitKind: number
  parentStudent: number
  kinderTest: number
  kinderEcht: number
  kinderOhneSchuelerzeile: number
  blockierend: number
}
export type Plan = { zahlen: Zahlen; abbruch: boolean; gruende: string[] }

export function planen(bestand: Bestand): Plan
export function bericht(plan: Plan, modus: 'dry-run' | 'ausfuehren'): string
export function bestandLesen(): Bestand
