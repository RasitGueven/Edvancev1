// Edge Function: auth_mail — Supabase "Send Email Hook".
//
// Supabase Auth schickt keine Mail mehr selbst, sondern ruft diese Function
// mit einer Standard-Webhooks-Signatur. Sie baut die Mail (Texte in texte.ts,
// Links auf die eigenen Seiten der App) und verschickt sie ueber Microsoft
// Graph aus hello@ (_shared/graph_mail.ts). Jeder Versuch steht in
// auth_mail_versand — ohne Token und ohne Link.
//
// Secrets:
//   SEND_EMAIL_HOOK_SECRET  "v1,whsec_…" aus Authentication → Hooks
//   APP_URL                 Ursprung der App, z. B. https://studio.edvanceacademy.de
//   MS_TENANT_ID, MS_CLIENT_ID, MS_CLIENT_SECRET (wie mail_senden)
// Nur lokal:
//   AUTH_MAIL_TESTVERSAND_URL  Mailpit-Send-API statt Graph. Greift nur, wenn
//                              SUPABASE_URL lokal ist (kong, localhost, 127.0.0.1).
//
// Kein JWT: Auth ruft ohne Nutzer-Token (verify_jwt = false in config.toml).
// Deploy: npx supabase functions deploy auth_mail --no-verify-jwt --project-ref ztcppihxqcphlqaguhma

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { ABSENDER, mailSenden } from '../_shared/graph_mail.ts'
import { schluesselAusSecret } from '../_shared/standard_webhooks.ts'
import { hookBearbeiten, type Mail, type ProtokollZeile } from './hook.ts'

const LOKAL = /^https?:\/\/(kong|localhost|127\.0\.0\.1|host\.docker\.internal)(:\d+)?(\/|$)/

/** Lokaler Test-Absender: Mailpit nimmt Mails per HTTP an (POST /api/v1/send). */
async function mailpitSenden(url: string, mail: Mail): Promise<void> {
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      From: { Email: ABSENDER, Name: 'Edvance' },
      To: [{ Email: mail.an }],
      Subject: mail.betreff,
      Text: mail.text,
    }),
  })
  if (!r.ok) throw new Error(`Mailpit ${r.status}`)
}

function versender(): (mail: Mail) => Promise<void> {
  const test = Deno.env.get('AUTH_MAIL_TESTVERSAND_URL')
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  if (test && LOKAL.test(supabaseUrl)) return (mail) => mailpitSenden(test, mail)
  return (mail) => mailSenden({ an: mail.an, betreff: mail.betreff, text: mail.text, speichern: false })
}

Deno.serve(async (req: Request) => {
  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!url || !serviceKey) {
    return new Response(JSON.stringify({ error: { http_code: 500, message: 'Service-Config fehlt' } }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
  const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } })

  const protokollieren = async (z: ProtokollZeile): Promise<void> => {
    const { error } = await admin.rpc('auth_mail_protokollieren', {
      p_art: z.art,
      p_empfaenger: z.empfaenger,
      p_user_id: z.user_id,
      p_fehler: z.fehler,
    })
    if (error) console.error('auth_mail: log failed', error.message)
  }

  return await hookBearbeiten(req, {
    schluessel: schluesselAusSecret(Deno.env.get('SEND_EMAIL_HOOK_SECRET')),
    appUrl: Deno.env.get('APP_URL'),
    senden: versender(),
    protokollieren,
  })
})
