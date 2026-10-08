// Typen fuer tools/erklaer-lib.mjs. Das Werkzeug bleibt .mjs, damit es ohne Bauschritt
// laeuft; der Test importiert es und braucht diese Beschreibung.
import type { Q } from './prefill-rechnen.mjs'

export type Block =
  | { art: 'titel' | 'merk' | 'absatz'; text: string }
  | { art: 'schritte'; zeilen: string[] }

export const BILD_PFAD: string
export const BILD_THEME: string
export const ZAHLWORT: RegExp
export function bilderPython(
  bilder: { generator: string; params: unknown }[],
  theme?: string | null,
): { hash: string; svg?: string; ok?: boolean; meldung?: string }[]
export function bloecke(inhalt: string): Block[]
export function markdownFehler(inhalt: string): string[]
export function formeln(text: string): string[]
export function zahlen(text: string): Q[]
export function punkteImText(text: string): { label: string; x: Q; y: Q }[]
export function qAus(v: number | string): Q
export function aufGerade(f: { m: number; b: number }, x: Q, y: Q): boolean
export function lesetext(b: Block): string
