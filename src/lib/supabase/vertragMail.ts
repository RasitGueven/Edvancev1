// Der Versand der Vertragsunterlagen ueber hello@edvanceacademy.de.
//
// Die Oberflaeche ruft hier an, nicht bei Microsoft: Tenant, Client-ID und
// Secret liegen in den Supabase-Secrets und haben im Browser nichts zu suchen.
// Verschickt wird in der Edge Function mail_senden.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'
import { vertragPdfErzeugen } from './vertragDateien'
import { vertragVersenden } from './vertraege'

export type Versandanlass = 'bestaetigung' | 'unterlagen' | 'zugangscode'

export type VersandErgebnis = { an: string; anhaenge: string[] }

/** Die Meldung aus dem Antwortrumpf holen — invoke() sagt nur "non-2xx". */
export async function meldung(error: unknown, ersatz: string): Promise<string> {
  const e = error as { message?: string; context?: Response }
  try {
    const antwort = (await e.context?.json()) as { error?: string } | undefined
    if (antwort?.error) return antwort.error
  } catch {
    /* generische Meldung behalten */
  }
  return e.message ?? ersatz
}

export async function mailSenden(
  vertragId: string,
  anlass: Versandanlass,
  empfaenger: string | null = null,
): Promise<SupabaseResult<VersandErgebnis>> {
  try {
    const { data, error } = await supabase.functions.invoke('mail_senden', {
      body: { vertrag_id: vertragId, anlass, empfaenger },
    })
    if (error) return { data: null, error: await meldung(error, 'Versand fehlgeschlagen') }
    return { data: data as VersandErgebnis, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Versand fehlgeschlagen'
    return { data: null, error: msg }
  }
}

/**
 * Weg B in einem Zug: Unterlagen erzeugen, Antrag auf
 * "unterschrift_ausstehend" setzen, Mail verschicken.
 *
 * Die Reihenfolge ist nicht beliebig. Erst das PDF — ohne Anhang waere die
 * Mail sinnlos. Dann der Status, denn ab hier warten wir auf Post. Zuletzt der
 * Versand: geht der schief, steht der Antrag trotzdem richtig da, das
 * Protokoll traegt den Fehler, und die Mail laesst sich wiederholen.
 */
export async function unterlagenPerMail(
  vertragId: string,
  empfaenger: string,
  rueckmeldungBis: string,
): Promise<SupabaseResult<VersandErgebnis>> {
  const pdf = await vertragPdfErzeugen(vertragId, 'unterlagen')
  if (pdf.error) return { data: null, error: pdf.error }

  const versand = await vertragVersenden(vertragId, 'email', empfaenger, rueckmeldungBis)
  if (versand.error) return { data: null, error: versand.error }

  return await mailSenden(vertragId, 'unterlagen', empfaenger)
}
