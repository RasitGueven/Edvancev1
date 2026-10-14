import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

// Coach-Einladung ueber die Edge Function coach_einladen (Admin-only) und der
// Stand der Konten ueber die RPC mitarbeiter_konto_stand (Admin-only).
// Ersetzt provisionCoach: Der Admin vergibt kein Passwort mehr.

export type EinladungFehler =
  | 'email_vergeben'
  | 'schon_aktiv'
  | 'nicht_gefunden'
  | 'eingabe'
  | 'kein_admin'
  | 'unbekannt'

const BEKANNT: readonly string[] = ['email_vergeben', 'schon_aktiv', 'nicht_gefunden', 'eingabe', 'kein_admin']

export type CoachEinladung = { vorname: string; nachname: string; email: string }

/** Stand eines Mitarbeiterkontos; Zeiten als ISO-Strings (UTC). */
export type KontoStand = {
  id: string
  eingeladen_at: string | null
  bestaetigt_at: string | null
  zuletzt_angemeldet_at: string | null
}

async function aufrufen(body: Record<string, unknown>): Promise<SupabaseResult<{ coach_id: string }>> {
  try {
    const { data, error } = await supabase.functions.invoke('coach_einladen', {
      body: { ...body, redirect_to: `${window.location.origin}/auth/einladung` },
    })
    if (error) {
      let c = 'unbekannt'
      try {
        const antwort = (await (error as unknown as { context: Response }).context.json()) as { code?: string }
        if (antwort?.code && BEKANNT.includes(antwort.code)) c = antwort.code
      } catch {
        /* generischer Fehler */
      }
      return { data: null, error: c }
    }
    const cid = (data as { coach_id?: string } | null)?.coach_id
    if (!cid) return { data: null, error: 'unbekannt' }
    return { data: { coach_id: cid }, error: null }
  } catch (err) {
    console.warn('coach_einladen failed', err)
    return { data: null, error: 'unbekannt' }
  }
}

/** Neuen Coach einladen. error ist ein EinladungFehler-Code. */
export function coachEinladen(e: CoachEinladung): Promise<SupabaseResult<{ coach_id: string }>> {
  return aufrufen({ aktion: 'neu', vorname: e.vorname.trim(), nachname: e.nachname.trim(), email: e.email.trim() })
}

/** Einladung erneut senden (nur fuer Konten, die sie noch nicht angenommen haben). */
export function einladungErneut(coachId: string): Promise<SupabaseResult<{ coach_id: string }>> {
  return aufrufen({ aktion: 'erneut', coach_id: coachId })
}

export async function getKontoStand(): Promise<SupabaseResult<KontoStand[]>> {
  try {
    const { data, error } = await supabase.rpc('mitarbeiter_konto_stand')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as KontoStand[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Kontostand konnte nicht geladen werden'
    return { data: null, error: message }
  }
}
