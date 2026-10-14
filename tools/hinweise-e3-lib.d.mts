// Typen fuer die Nachrechnung der Hinweis-Entwuerfe (E3). Das Werkzeug bleibt .mjs, damit es ohne Bauschritt
// laeuft; der Test importiert es und braucht diese Beschreibung.

export interface Zahl { roh: string; wert: { toString(): string }; betrag: unknown; index: number }
export interface Stufe { text: string; belege?: unknown[]; fehlbild?: string | string[]; frei?: [string, string][] }
export interface Eintrag { stufen: Stufe[]; var?: string; vars?: Record<string, string[]>; gesucht?: string }

export const MAX_ZEICHEN: number
export const MAX_SAETZE: number
export function zahlen(text: string): Zahl[]
export function antworten(aufgabe: unknown): { werte: unknown[]; texte: string[] }
export function richtigeOptionen(aufgabe: unknown): string[]
export function fehlbilder(aufgabe: unknown): Set<string>
export function istKleinerGroesser(aufgabe: unknown): boolean
export function pruefeAufgabe(aufgabe: unknown, eintrag: Eintrag): { fehler: string[] }
export function alsHints(eintrag: Eintrag): { level: number; text: string; status: 'entwurf' }[]
