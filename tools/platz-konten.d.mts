// Typen fuer tools/platz-konten.mjs. Das Werkzeug bleibt .mjs, damit es ohne Bauschritt
// laeuft; der Test importiert es und braucht diese Beschreibung.

export const DOMAIN: string
export const ZUGAENGE: string
export function mailFuer(nr: number): string
export function labelFuer(nr: number): string

export type Bestand = { belegt: Set<number>; mails: Set<number> }
export type Schritt = { nr: number; aktion: 'anlegen' | 'ueberspringen' | 'konflikt'; grund: string }
export type Stand = { angelegt: number; uebersprungen: number; konflikt: number }
export type Konto = { nr: number; email: string; label: string; passwort: string }

export function nummernLesen(args: string[]): number[]
export function planen(nummern: number[], bestand: Bestand): Schritt[]
export function passwortErzeugen(): string
export function bestandLesen(): Bestand
export function lauf(opts: {
  plan: Schritt[]
  dryRun: boolean
  anlegen: ((konto: Konto) => Promise<void>) | null
  notieren: (z: { nr: number; email: string; passwort: string }) => void
  log?: (zeile: string) => void
}): Promise<Stand>
