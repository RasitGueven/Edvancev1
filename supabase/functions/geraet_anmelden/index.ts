// Edge Function: geraet_anmelden (Reihe 1 · D1)
//
// Die Home-App meldet ein Geraet mit dem Zugangscode an. Kein Login fuer Mitarbeiter, keine anonyme
// Anmeldung: Am Ende ist das Geraet mit dem eigenen Konto des Kindes angemeldet (docs/reihe1/D/ist-analyse.md §3).
// Die Logik steht in anmelden.ts; hier nur supabase-js.
//
// Rumpf: { code, name, plattform: 'ios'|'android'|'web', installation }   (installation: zufaellige ID der App)
// Antwort 200: { ergebnis: 'ok', access_token, refresh_token, expires_at } oder
//              { ergebnis: 'falsch'|'kein_vertrag'|'zu_viele_geraete'|'gesperrt', warte_sek }
//
// Secrets: GERAET_PEPPER (zufaellig, mindestens 32 Zeichen; HMAC fuer Installations-ID und IP) setzt Rasit
// einmal per `supabase secrets set`. SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY und SUPABASE_ANON_KEY injiziert
// die Runtime.
//
// Deploy: npx supabase functions deploy geraet_anmelden --no-verify-jwt --project-ref ztcppihxqcphlqaguhma

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { anmelden, type Dienste, type Einloesung } from './anmelden.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function hmacMit(pepper: string): Promise<(text: string) => Promise<string>> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey('raw', enc.encode(pepper), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'])
  return async (text) => {
    const sig = await crypto.subtle.sign('HMAC', key, enc.encode(text))
    return Array.from(new Uint8Array(sig), (b) => b.toString(16).padStart(2, '0')).join('')
  }
}

/**
 * Client-IP. cf-connecting-ip setzt der Rand des Netzes selbst (vom Client nicht faelschbar), x-forwarded-for
 * nur als Rueckfall. Welche Kopfzeilen in Prod ankommen, prueft die Live-Checkliste (gefaelschter XFF-Kopf).
 */
export function clientIp(h: Headers): string | null {
  return h.get('cf-connecting-ip')?.trim() || h.get('x-forwarded-for')?.split(',')[0]?.trim() || null
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json(405, { ergebnis: 'eingabe' })

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const pepper = Deno.env.get('GERAET_PEPPER')
  if (!url || !serviceKey || !anonKey || !pepper || pepper.length < 32) return json(500, { ergebnis: 'fehler' })

  let body: Record<string, unknown>
  try {
    body = (await req.json()) as Record<string, unknown>
  } catch {
    return json(400, { ergebnis: 'eingabe' })
  }

  const ohneSitzung = { auth: { autoRefreshToken: false, persistSession: false } }
  const admin = createClient(url, serviceKey, ohneSitzung)
  const oeffentlich = createClient(url, anonKey, ohneSitzung)

  const dienste: Dienste = {
    hmac: await hmacMit(pepper),
    einloesen: async (p) => {
      const { data, error } = await admin.rpc('geraet_einloesen', p)
      if (error) throw new Error(`geraet_einloesen: ${error.message}`)
      return (data as Einloesung[])[0]
    },
    magicLinkHash: async (email) => {
      const { data, error } = await admin.auth.admin.generateLink({ type: 'magiclink', email })
      if (error || !data.properties?.hashed_token) throw new Error(`generateLink: ${error?.message ?? 'ohne Token'}`)
      return data.properties.hashed_token
    },
    linkEinloesen: async (tokenHash) => {
      const { data, error } = await oeffentlich.auth.verifyOtp({ type: 'magiclink', token_hash: tokenHash })
      if (error || !data.session) throw new Error(`verifyOtp: ${error?.message ?? 'ohne Session'}`)
      const s = data.session
      return { access_token: s.access_token, refresh_token: s.refresh_token, expires_at: s.expires_at ?? null }
    },
    sessionSetzen: async (geraetId, sessionId) => {
      const { error } = await admin.rpc('geraet_session_setzen', { p_geraet: geraetId, p_session: sessionId })
      if (error) throw new Error(`geraet_session_setzen: ${error.message}`)
    },
    sessionLoeschen: async (sessionId) => {
      const { error } = await admin.rpc('geraet_auth_session_loeschen', { p_session: sessionId })
      if (error) throw new Error(`geraet_auth_session_loeschen: ${error.message}`)
    },
  }

  const ip = clientIp(req.headers)
  try {
    const antwort = await anmelden(body, ip, dienste)
    return json(antwort.status, antwort.body)
  } catch (err) {
    console.error('geraet_anmelden:', err instanceof Error ? err.message : err)
    return json(500, { ergebnis: 'fehler' })
  }
})
