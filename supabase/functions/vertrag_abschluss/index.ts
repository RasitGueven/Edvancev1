// Edge Function: vertrag_abschluss
//
// Die Klammer um die RPC vertrag_abschliessen. Sie existiert aus genau einem
// Grund: Ein Auth-Konto kann eine Datenbankfunktion nicht anlegen, und ein
// Vertrag ohne Konto ist kein fertiger Vertrag.
//
// Ablauf:
//   1. Autorisieren (Admin; fail-closed wie in provision_student).
//   2. Den Vertrag lesen — traegt er schon student_id, ist es ein Folgevertrag
//      und es entsteht KEIN zweites Konto.
//   3. Auth-User fuer den Schueler anlegen. Eltern bekommen KEIN Konto (K1b,
//      Entscheidung Rasit 14.10.2026): alle Mails an Eltern gehen an
//      vertraege.eltern_email. Siehe konten.ts.
//   4. RPC vertrag_abschliessen aufrufen. Sie macht den ganzen Rest in EINER
//      Transaktion: Status, Ende, Widerruf, Zugangscode, Schuelerkonto, Abo.
//   5. Wirft die RPC, wird das eben angelegte Schuelerkonto wieder entfernt.
//   6. Das Vertrags-PDF erzeugen. NACH der RPC und ohne Rueckrollrecht: Der
//      Vertrag ist geschlossen, sobald die RPC durch ist. Ein Fehler beim
//      Setzen des PDF macht das nicht rueckgaengig — er wird gemeldet und die
//      Detailansicht zeigt "PDF ausstehend" mit einem Knopf zum Nachholen.
//
// Deploy: supabase functions deploy vertrag_abschluss

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { abschlussParameter, schuelerkontoAnlegen, type AbschlussBody, type Schuelerkonto } from './konten.ts'
import {
  buendelVollstaendig,
  fassungenErzeugen,
  vertragPdfErzeugen,
} from '../_shared/vertrag_pdf_erzeugen.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Body = AbschlussBody

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
  if (!url || !serviceKey) return json(500, { error: 'Service-Config fehlt' })

  let body: Body
  try {
    body = await req.json()
  } catch {
    return json(400, { error: 'Ungueltiger Request-Body' })
  }
  if (!body.vertrag_id) return json(400, { error: 'vertrag_id erforderlich' })
  if (body.weg !== 'vor_ort' && body.weg !== 'papier') {
    return json(400, { error: 'weg muss vor_ort oder papier sein' })
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // ---- 1. Autorisierung: Service-Key ODER eingeloggter Admin ---------------
  const authHeader = req.headers.get('Authorization') ?? ''
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  let callerJwt: string | null = null
  if (bearer !== serviceKey) {
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    if (!bearer || !anonKey) return json(401, { error: 'Nicht authentifiziert' })
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { autoRefreshToken: false, persistSession: false },
    })
    const { data: userData, error: userErr } = await caller.auth.getUser()
    if (userErr || !userData.user) return json(401, { error: 'Nicht authentifiziert' })
    const { data: prof, error: profErr } = await admin
      .from('profiles')
      .select('role')
      .eq('id', userData.user.id)
      .single()
    if (profErr || !prof) return json(403, { error: 'Aufrufer-Profil nicht gefunden' })
    // Der Vertragsabschluss ist Admin-Sache. Die RPC prueft es noch einmal —
    // hier steht es, damit gar nicht erst ein Auth-Konto entsteht.
    if (prof.role !== 'admin') return json(403, { error: 'Nur Admin darf abschliessen' })
    callerJwt = bearer
  }

  // ---- 2. Vertrag lesen ----------------------------------------------------
  const { data: vertrag, error: vErr } = await admin
    .from('vertraege')
    .select('id, status, student_id')
    .eq('id', body.vertrag_id)
    .single()
  if (vErr || !vertrag) return json(404, { error: 'Vertrag nicht gefunden' })

  const braucht_konto = vertrag.student_id === null && vertrag.status !== 'abgeschlossen'

  // ---- 3. Schuelerkonto (Eltern bekommen keins, K1b) ----------------------
  let konto: Schuelerkonto | null = null
  if (braucht_konto) {
    const r = await schuelerkontoAnlegen(admin)
    if ('fehler' in r) return json(502, { error: r.fehler })
    konto = r
  }

  // ---- 4. Der Abschluss ----------------------------------------------------
  // Als Aufrufer geht das JWT des Admins mit: die RPC prueft get_my_role() und
  // schreibt auth.uid() in die Protokollspalten. Mit dem Service-Key allein
  // waere sie ein Systemaufruf ohne Urheber.
  const rpcClient = callerJwt
    ? createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
        global: { headers: { Authorization: `Bearer ${callerJwt}` } },
        auth: { autoRefreshToken: false, persistSession: false },
      })
    : admin

  const { data, error } = await rpcClient.rpc('vertrag_abschliessen', abschlussParameter(body, konto))

  // ---- 5. Aufraeumen -------------------------------------------------------
  if (error) {
    if (konto) await admin.auth.admin.deleteUser(konto.uid)
    return json(400, { error: error.message })
  }

  // ---- 6. Das PDF ----------------------------------------------------------
  // Absichtlich hinter dem Punkt ohne Wiederkehr. Ein Vertrag ohne PDF ist ein
  // fehlendes Dokument; ein zurueckgerollter Abschluss waere ein fehlender
  // Vertrag — mit einem Elternteil, das eben unterschrieben hat.
  let pdf_fehler: string | null = null
  try {
    // Der Aufruf ist idempotent (bereits_abgeschlossen) — dann liegt das PDF
    // schon da und ein zweiter Versuch waere nur ein Upload-Fehler, den
    // niemand lesen muss.
    if (!(await buendelVollstaendig(admin, body.vertrag_id))) {
      await fassungenErzeugen(admin, rpcClient)
      await vertragPdfErzeugen(admin, rpcClient, body.vertrag_id)
    }
  } catch (err) {
    pdf_fehler = err instanceof Error ? err.message : 'PDF konnte nicht erzeugt werden'
    console.error('vertrag_pdf', body.vertrag_id, pdf_fehler)
  }

  return json(200, { ...(data as Record<string, unknown>), pdf_fehler })
})
