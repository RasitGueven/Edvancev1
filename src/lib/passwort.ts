// Passwortregeln fuer Mitarbeiterkonten (Konto K1).
//
// Nur eine Regel: Laenge. Keine Pflicht zu Sonderzeichen oder Ziffern — die
// fuehren zu "Passwort1!" und auf Zetteln. Ein Satz aus mehreren Woertern ist
// laenger, leichter zu merken und schwerer zu erraten (NIST SP 800-63B).
// Muss zu minimum_password_length in Supabase Auth passen (10).

export const PASSWORT_MIN = 10

export type PasswortRegelFehler = 'zu_kurz' | 'ungleich'

export function passwortPruefen(neu: string, wiederholung: string): PasswortRegelFehler | null {
  if (neu.length < PASSWORT_MIN) return 'zu_kurz'
  if (neu !== wiederholung) return 'ungleich'
  return null
}
