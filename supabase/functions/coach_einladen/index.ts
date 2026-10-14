// Edge Function: coach_einladen
//
// Laedt einen Coach per Mail ein (ersetzt provision_coach fuer die
// Oberflaeche). Die Logik steht in einladen.ts; hier nur supabase-js.
//
// Die Einladungsmail selbst verschickt nicht diese Function, sondern Supabase
// Auth ueber den Send Email Hook (auth_mail) aus hello@.
//
// Secrets: APP_URL (Ursprung der App; ohne sie gilt redirect_to aus dem
// Rumpf). SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY und SUPABASE_ANON_KEY
// injiziert die Runtime.
//
// Deploy: npx supabase functions deploy coach_einladen --no-verify-jwt --project-ref ztcppihxqcphlqaguhma

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { einladenBearbeiten, type Dienste } from './einladen.ts'

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

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json(405, { error: 'Method not allowed' })

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !serviceKey || !anonKey) return json(500, { error: 'Service-Config fehlt' })

  let body: Record<string, unknown>
  try {
    body = (await req.json()) as Record<string, unknown>
  } catch {
    return json(400, { code: 'eingabe', error: 'Ungueltiger Request-Body' })
  }

  const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } })

  const dienste: Dienste = {
    serviceKey,
    appUrl: Deno.env.get('APP_URL'),
    aufrufer: async (authHeader) => {
      const caller = createClient(url, anonKey, {
        global: { headers: { Authorization: authHeader } },
        auth: { autoRefreshToken: false, persistSession: false },
      })
      const { data, error } = await caller.auth.getUser()
      return error || !data.user ? null : { id: data.user.id }
    },
    rolle: async (uid) => {
      const { data } = await admin.from('profiles').select('role').eq('id', uid).maybeSingle()
      return (data?.role as string | undefined) ?? null
    },
    emailVorhanden: async (email) => {
      const { data, error } = await admin.rpc('konto_email_vorhanden', { p_email: email })
      // Fail-closed: laesst sich nicht pruefen, gilt die Adresse als vergeben.
      if (error) {
        console.error('coach_einladen: email check failed', error.message)
        return true
      }
      return data === true
    },
    einladen: async (email, opts) => {
      const { data, error } = await admin.auth.admin.inviteUserByEmail(email, opts)
      if (error || !data.user) return { fehler: error?.message ?? 'Einladung fehlgeschlagen', code: error?.code }
      return { id: data.user.id }
    },
    profilSchreiben: async (p) => {
      const { error } = await admin.from('profiles').upsert(p, { onConflict: 'id' })
      return error ? error.message : null
    },
    loeschen: async (uid) => {
      const { error } = await admin.auth.admin.deleteUser(uid)
      if (error) console.error('coach_einladen: cleanup failed', uid, error.message)
    },
    konto: async (uid) => {
      const { data, error } = await admin.auth.admin.getUserById(uid)
      if (error || !data.user?.email) return null
      const name = data.user.user_metadata?.full_name
      return {
        id: data.user.id,
        email: data.user.email,
        bestaetigt: Boolean(data.user.email_confirmed_at),
        name: typeof name === 'string' ? name : '',
      }
    },
  }

  const r = await einladenBearbeiten(req.headers.get('Authorization') ?? '', body, dienste)
  return json(r.status, r.payload)
})
