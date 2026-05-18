// Edge Function: provision_student
//
// Lead -> Student Conversion. Neues @supabase/server-Muster (withSupabase).
// Aufruf aus dem Admin/Coach-Frontend via supabase.functions.invoke
// (sendet das User-JWT automatisch). Server-zu-Server kann alternativ
// den Secret-Key nutzen.
//
// Sicherheit:
//   - auth: ['user','secret'] – User-JWT ODER Secret-Key erforderlich
//   - User-Modus: Aufrufer-Profil-Rolle muss admin|coach sein
//   - Secret-Modus: vertrauenswuerdig (Server-zu-Server), kein Rollen-Check
//
// Ablauf (privilegiert via ctx.supabaseAdmin):
//   1. Schueler-auth-User anlegen
//   2. optional Eltern-auth-User per Invite
//   3. atomarer DB-Teil via RPC app_provision_student
//   4. bei RPC-Fehler angelegte auth-User wieder entfernen (Cleanup)
//
// Plattform: verify_jwt MUSS aus sein (config.toml) – withSupabase
// uebernimmt die Auth selbst. Deploy: supabase functions deploy provision_student

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { withSupabase } from 'jsr:@supabase/server@^1'

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
  return Response.json(payload, { status })
}

function randomPassword(): string {
  return crypto.randomUUID() + crypto.randomUUID()
}

// Der Auth-Modus heisst je nach @supabase/server-Version authType ODER
// authMode – wir tolerieren beide (siehe Nutzung unten). Der Rest von
// ctx (supabaseAdmin etc.) wird vom withSupabase-Typ geliefert.
type AuthModeCtx = { authType?: string; authMode?: string }

export default {
  fetch: withSupabase(
    { auth: ['user', 'secret'], cors: true },
    async (req: Request, ctx): Promise<Response> => {
      if (req.method !== 'POST') {
        return json(405, { error: 'Method not allowed' })
      }

      let body: Body
      try {
        body = (await req.json()) as Body
      } catch {
        return json(400, { error: 'Ungueltiger Request-Body' })
      }
      if (!body.full_name || body.full_name.trim() === '') {
        return json(400, { error: 'full_name erforderlich' })
      }

      const admin = ctx.supabaseAdmin
      if (!admin) {
        return json(500, { error: 'Service-Client nicht verfuegbar' })
      }

      // Rollen-Check nur im User-Modus (Secret-Key = vertrauenswuerdig).
      // Falscher Property-Name => Modus !== 'secret' => Check laeuft
      // (fail-closed): nie ein offener Bypass, nur Secret-Pfad faellt
      // ggf. zurueck auf den Rollen-Check.
      const aCtx = ctx as AuthModeCtx
      const authMode = aCtx.authType ?? aCtx.authMode
      if (authMode !== 'secret') {
        const callerId = ctx.userClaims?.sub
        if (!callerId) return json(401, { error: 'Nicht authentifiziert' })
        const { data: prof, error: profErr } = await admin
          .from('profiles')
          .select('role')
          .eq('id', callerId)
          .single()
        if (profErr || !prof) {
          return json(403, { error: 'Aufrufer-Profil nicht gefunden' })
        }
        if (prof.role !== 'admin' && prof.role !== 'coach') {
          return json(403, { error: 'Nur Admin/Coach darf konvertieren' })
        }
      }

      const studentEmail =
        body.student_email && body.student_email.trim() !== ''
          ? body.student_email.trim()
          : `student.${crypto.randomUUID()}@edvance.invalid`

      // 1. Schueler-auth-User
      const { data: studentData, error: studentErr } =
        await admin.auth.admin.createUser({
          email: studentEmail,
          password: randomPassword(),
          email_confirm: true,
        })
      if (studentErr || !studentData.user) {
        return json(502, {
          error: `Schueler-Account: ${studentErr?.message ?? 'unbekannt'}`,
        })
      }
      const studentUid = studentData.user.id

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
        parentUid = parentData.user.id
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

      // 4. Cleanup bei DB-Fehler (angelegte auth-User entfernen)
      if (error) {
        await admin.auth.admin.deleteUser(studentUid)
        if (parentUid) await admin.auth.admin.deleteUser(parentUid)
        return json(400, { error: error.message })
      }

      return json(200, { student_id: data })
    },
  ),
}
