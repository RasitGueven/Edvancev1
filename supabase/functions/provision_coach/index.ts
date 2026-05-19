// Edge Function: provision_coach
//
// Legt einen Coach-Account an. Laeuft privilegiert mit service-role.
//
// Autorisierung (fail-closed):
//   - Server-zu-Server: Bearer == SERVICE_ROLE_KEY -> vertrauenswuerdig
//   - sonst: gueltiges User-JWT erforderlich, Aufrufer muss Rolle 'admin'
//     haben (nur Admin darf Personal anlegen)
//
// Schritte:
//   1. auth-User fuer Coach anlegen (Auth-Admin-API, email_confirm)
//   2. profiles-Upsert role='coach' (defensiv gegen handle_new_user-Trigger)
//   3. bei profiles-Fehler den angelegten auth-User wieder entfernen
//
// Deploy: supabase functions deploy provision_coach
// (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY + SUPABASE_ANON_KEY
//  werden vom Runtime injiziert)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Body = {
  full_name: string
  email: string
  password: string
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json(405, { error: 'Method not allowed' })

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!url || !serviceKey) return json(500, { error: 'Service-Config fehlt' })

  let body: Body
  try {
    body = await req.json()
  } catch {
    return json(400, { error: 'Ungueltiger Request-Body' })
  }

  const fullName = (body.full_name ?? '').trim()
  const email = (body.email ?? '').trim().toLowerCase()
  const password = body.password ?? ''
  if (fullName === '') return json(400, { error: 'full_name erforderlich' })
  if (!EMAIL_RE.test(email)) return json(400, { error: 'Ungueltige E-Mail' })
  if (password.length < 6) {
    return json(400, { error: 'Passwort muss mindestens 6 Zeichen haben' })
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Autorisierung: Service-Role-Key ODER eingeloggter Admin. Fail-closed.
  const authHeader = req.headers.get('Authorization') ?? ''
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  if (bearer !== serviceKey) {
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    if (!bearer || !anonKey) {
      return json(401, { error: 'Nicht authentifiziert' })
    }
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { autoRefreshToken: false, persistSession: false },
    })
    const { data: userData, error: userErr } = await caller.auth.getUser()
    if (userErr || !userData.user) {
      return json(401, { error: 'Nicht authentifiziert' })
    }
    const { data: prof, error: profErr } = await admin
      .from('profiles')
      .select('role')
      .eq('id', userData.user.id)
      .single()
    if (profErr || !prof) {
      return json(403, { error: 'Aufrufer-Profil nicht gefunden' })
    }
    if (prof.role !== 'admin') {
      return json(403, { error: 'Nur Admin darf Coaches anlegen' })
    }
  }

  // 1. auth-User
  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  })
  if (createErr || !created.user) {
    return json(502, {
      error: `Coach-Account: ${createErr?.message ?? 'unbekannt'}`,
    })
  }
  const coachUid = created.user.id

  // 2. profiles-Upsert (defensiv gegen handle_new_user-Trigger)
  const { error: profileErr } = await admin
    .from('profiles')
    .upsert(
      { id: coachUid, email, role: 'coach', full_name: fullName },
      { onConflict: 'id' },
    )

  // 3. Cleanup bei profiles-Fehler
  if (profileErr) {
    await admin.auth.admin.deleteUser(coachUid)
    return json(400, { error: profileErr.message })
  }

  return json(200, { coach_id: coachUid })
})
