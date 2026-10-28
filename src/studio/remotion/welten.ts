import { istWelt } from '../skript/welten'

/** CSS-Klasse des Skins; unbekannte Welten fallen auf das Skelett zurück. */
export function weltKlasse(welt: string): string {
  return `studio-welt-${istWelt(welt) ? welt : 'skelett'}`
}

/** Einheit bzw. Gegenstand der Welt aus den Bildparametern, sonst der Standard des Skeletts. */
export function weltWort(bild: Record<string, unknown>, schluessel: 'einheit' | 'gegenstand', standard: string): string {
  const w = bild[schluessel]
  return typeof w === 'string' && w.trim() !== '' ? w : standard
}
