// Edge Function: provision_student
//
// Lead -> Student Conversion. Laeuft mit service-role (nicht im Browser).
// Schritte:
//   1. auth-User fuer Schueler anlegen (Auth-Admin-API)
//   2. optional auth-User fuer Elternteil per Invite anlegen
//   3. atomaren DB-Teil via RPC app_provision_student ausfuehren
//   4. bei RPC-Fehler die angelegten auth-User wieder entfernen (Cleanup)
//
// Deploy: supabase functions deploy provision_student
// (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY werden vom Runtime injiziert)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Body = {
  lead_id?: string | null
  full_name: string
  student_email?: string | null
  parent_email?: string | null
  class_level?: number | null
  school_type?: string | null
  school_name?: string | null
  subjects?: string[]
  coach_id?: string | null
  tier_id?: string | null
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function randomPassword(): string {
  return crypto.randomUUID() + crypto.randomUUID()
}

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
  if (!body.full_name || body.full_name.trim() === '') {
    return json(400, { error: 'full_name erforderlich' })
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const studentEmail =
    body.student_email && body.student_email.trim() !== ''
      ? body.student_email.trim()
      : `student.${crypto.randomUUID()}@edvance.invalid`

  // 1. Schueler-auth-User
  const { data: studentData, error: studentErr } = await admin.auth.admin.createUser({
    email: studentEmail,
    password: randomPassword(),
    email_confirm: true,
  })
  if (studentErr || !studentData.user) {
    return json(502, {
      error: `Schueler-Account: ${studentErr?.message ?? 'unbekannt'}`,
    })
  }
  const { id: studentUid } = studentData.user

  // 2. optional Elternteil per Invite
  let parentUid: string | null = null
  if (body.parent_email && body.parent_email.trim() !== '') {
    const { data: parentData, error: parentErr } =
      await admin.auth.admin.inviteUserByEmail(body.parent_email.trim())
    if (parentErr || !parentData.user) {
      await admin.auth.admin.deleteUser(studentUid)
      return json(502, {
        error: `Eltern-Account: ${parentErr?.message ?? 'unbekannt'}`,
      })
    }
    const { id: parentIdValue } = parentData.user
    parentUid = parentIdValue
  }

  // 3. atomarer DB-Teil
  const { data, error } = await admin.rpc('app_provision_student', {
    p_student_uid: studentUid,
    p_student_email: studentEmail,
    p_parent_uid: parentUid,
    p_parent_email: body.parent_email ?? null,
    p_full_name: body.full_name.trim(),
    p_class_level: body.class_level ?? null,
    p_school_type: body.school_type ?? null,
    p_school_name: body.school_name ?? null,
    p_subjects: body.subjects ?? [],
    p_coach_id: body.coach_id ?? null,
    p_tier_id: body.tier_id ?? null,
    p_lead_id: body.lead_id ?? null,
  })

  // 4. Cleanup bei DB-Fehler (auth-User wieder entfernen)
  if (error) {
    await admin.auth.admin.deleteUser(studentUid)
    if (parentUid) await admin.auth.admin.deleteUser(parentUid)
    return json(400, { error: error.message })
  }

  return json(200, { student_id: data })
})
