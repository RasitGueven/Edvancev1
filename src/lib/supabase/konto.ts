import { supabase } from '@/lib/supabase/client'

// Konto K1: Einladung annehmen, Passwort setzen, vergessen und aendern.
// Die Fehler sind Codes, die Oberflaeche uebersetzt sie (Namespace konto).

// email_change fehlt bewusst: auth_mail lehnt Adressaenderungen ab (K1, Entscheidung Rasit).
export type LinkTyp = 'invite' | 'recovery' | 'signup' | 'magiclink'

export type KontoFehler = 'link_ungueltig' | 'altes_falsch' | 'zu_kurz' | 'gleich' | 'unbekannt'

function code(err: unknown): string | undefined {
  return typeof err === 'object' && err !== null && 'code' in err ? String((err as { code: unknown }).code) : undefined
}

/**
 * Den Token aus dem Mail-Link einloesen. Nur nach einem Klick aufrufen, nie
 * beim Laden der Seite: Mail-Scanner oeffnen Links vorab und wuerden den
 * einmal gueltigen Token sonst verbrauchen.
 */
export async function tokenEinloesen(tokenHash: string, type: LinkTyp): Promise<{ error: KontoFehler | null }> {
  try {
    const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
    if (error) {
      console.warn('tokenEinloesen failed', error.code ?? error.message)
      return { error: 'link_ungueltig' }
    }
    return { error: null }
  } catch (err) {
    console.warn('tokenEinloesen failed', err)
    return { error: 'unbekannt' }
  }
}

function passwortFehler(err: unknown): KontoFehler {
  const c = code(err)
  if (c === 'weak_password') return 'zu_kurz'
  if (c === 'same_password') return 'gleich'
  return 'unbekannt'
}

/** Neues Passwort fuer die angemeldete Sitzung (nach Einladung oder Link). */
export async function passwortSetzen(neu: string): Promise<{ error: KontoFehler | null }> {
  try {
    const { error } = await supabase.auth.updateUser({ password: neu })
    if (error) return { error: passwortFehler(error) }
    return { error: null }
  } catch (err) {
    console.warn('passwortSetzen failed', err)
    return { error: 'unbekannt' }
  }
}

/**
 * Link zum Zuruecksetzen anfordern. Gibt bewusst nichts zurueck: Die
 * Oberflaeche antwortet immer gleich, ob es die Adresse gibt oder nicht.
 */
export async function passwortVergessen(email: string, redirectTo: string): Promise<void> {
  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo })
    if (error) console.warn('passwortVergessen failed', error.code ?? error.status)
  } catch (err) {
    console.warn('passwortVergessen failed', err)
  }
}

/**
 * Passwort aendern: erst das alte pruefen (erneute Anmeldung), dann das neue
 * setzen, dann alle anderen Sitzungen des Kontos abmelden.
 */
export async function passwortAendern(
  email: string,
  alt: string,
  neu: string,
): Promise<{ error: KontoFehler | null }> {
  try {
    const { error: anmeldeFehler } = await supabase.auth.signInWithPassword({ email, password: alt })
    if (anmeldeFehler) {
      return { error: code(anmeldeFehler) === 'invalid_credentials' ? 'altes_falsch' : 'unbekannt' }
    }
    const { error } = await supabase.auth.updateUser({ password: neu })
    if (error) return { error: passwortFehler(error) }
    const { error: abmeldeFehler } = await supabase.auth.signOut({ scope: 'others' })
    if (abmeldeFehler) console.warn('passwortAendern: signOut others failed', abmeldeFehler.message)
    return { error: null }
  } catch (err) {
    console.warn('passwortAendern failed', err)
    return { error: 'unbekannt' }
  }
}
