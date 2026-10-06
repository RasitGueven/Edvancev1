// Kinder-Hinweise in der Pruefansicht (Paket L5): Lena bearbeitet die Texte im Entwurf, der Server
// (pruef_speichern) setzt geaenderte Hinweise auf entwurf; geprueft werden sie mit der Freigabe der Aufgabe.
// Die Bearbeitung haelt nur Texte in Stufenreihenfolge (Index 0 = Stufe 1).

import type { KinderHinweis, PruefAenderung } from '@/types'

/** Mehr Stufen gibt das Kind nicht ab (session_einstellungen.hinweisstufen, hoechstens 3). */
export const MAX_STUFEN = 3
/** Laenge, die pruef_hinweise_anwenden noch annimmt. */
export const MAX_ZEICHEN = 500

/** Texte fuer den Entwurf: leere fallen weg, die uebrigen ruecken ohne Luecke auf (Stufe n erst nach n-1). */
export function hinweiseFuerEntwurf(texte: string[]): { stufe: number; text: string }[] {
  return texte.map((x) => x.trim()).filter(Boolean).map((text, i) => ({ stufe: i + 1, text }))
}

export function hinweiseGleich(a: string[], b: string[]): boolean {
  return JSON.stringify(hinweiseFuerEntwurf(a)) === JSON.stringify(hinweiseFuerEntwurf(b))
}

/** Aenderungen wie pruef_aenderungen (Feld 'hinweis', teil = Stufe, vorher/nachher Text oder null). */
export function hinweisAenderungen(ausgang: string[], jetzt: string[]): PruefAenderung[] {
  const v = hinweiseFuerEntwurf(ausgang)
  const n = hinweiseFuerEntwurf(jetzt)
  const liste: PruefAenderung[] = []
  for (let stufe = 1; stufe <= Math.max(v.length, n.length); stufe++) {
    const vorher = v[stufe - 1]?.text ?? null
    const nachher = n[stufe - 1]?.text ?? null
    if (vorher !== nachher) liste.push({ feld: 'hinweis', teil: stufe, vorher, nachher })
  }
  return liste
}

/**
 * Status, den eine Stufe nach dem Speichern hat: unveraenderter Text behaelt den Status vom Server,
 * alles andere ist entwurf (E1-Trigger „der Status haengt am Text“).
 */
export function hinweisStatus(geladen: KinderHinweis[], stufe: number, text: string): KinderHinweis['status'] {
  const g = geladen.find((h) => h.stufe === stufe)
  return g && g.text === text.trim() ? g.status : 'entwurf'
}

/** Eine Stufe aendern; Index ausserhalb haengt hinten an (hoechstens MAX_STUFEN). */
export function hinweisSetzen(texte: string[], index: number, text: string): string[] {
  if (index < 0 || index >= MAX_STUFEN) return texte
  const neu = [...texte]
  neu[index] = text
  return neu
}

/** Eine Stufe entfernen; die folgenden ruecken nach. */
export function hinweisEntfernen(texte: string[], index: number): string[] {
  return texte.filter((_, i) => i !== index)
}

/** Hat die Aufgabe Hinweise, die das Kind (noch) nicht bekommt? */
export const hinweiseOffen = (liste: KinderHinweis[]): number => liste.filter((h) => h.status !== 'geprueft').length
