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
//   3. Auth-User fuer Schueler anlegen, Elternkonto anlegen oder verknuepfen.
//      OHNE Einladungsmail — die Einladung der Eltern folgt bewusst in P4 ueber
//      hello@ (Microsoft Graph). Bis dahin existiert das Konto, ist aber
//      unbestaetigt und ohne Passwort: niemand kann sich damit anmelden, und
//      niemand bekommt eine Mail, die auf nichts verweist.
//   4. RPC vertrag_abschliessen aufrufen. Sie macht den ganzen Rest in EINER
//      Transaktion: Status, Ende, Widerruf, Zugangscode, Schuelerkonto, Abo.
//   5. Wirft die RPC, werden die eben angelegten Auth-User wieder entfernt —
//      aber nur die eben angelegten. Ein wiederverwendetes Elternkonto bleibt
//      stehen; es gehoert dem Geschwisterkind genauso.
//
// Deploy: supabase functions deploy vertrag_abschluss

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Body = {
  vertrag_id: string
  weg: 'vor_ort' | 'papier'
  zustimmungen?: { schluessel: string; version: string; akzeptiert_at?: string }[]
  signatur_vertrag?: string | null
  signatur_sepa?: string | null
  unterschrieben_am?: string | null
  eingang_datum?: string | null
  scan_pfad?: string | null
  abweichung_vermerk?: string | null
  tier_id?: string | null
  laufzeit_monate?: number | null
  vertragsbeginn?: string | null
  /** Passwort des Schuelerkontos. Nur beim Erstvertrag noetig. */
  student_password?: string | null
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
    .select('id, status, student_id, eltern_email, kind_vorname, kind_nachname')
    .eq('id', body.vertrag_id)
    .single()
  if (vErr || !vertrag) return json(404, { error: 'Vertrag nicht gefunden' })

  const braucht_konto = vertrag.student_id === null && vertrag.status !== 'abgeschlossen'

  const password =
    body.student_password && body.student_password.trim() !== ''
      ? body.student_password
      : null
  if (braucht_konto && password !== null && password.length < 6) {
    return json(400, { error: 'Passwort muss mindestens 6 Zeichen haben' })
  }

  // ---- 3. Auth-Konten ------------------------------------------------------
  let studentUid: string | null = null
  let studentEmail: string | null = null
  let parentUid: string | null = null
  // Nur selbst angelegte Konten werden beim Rollback wieder entfernt.
  let parentNeuAngelegt = false

  if (braucht_konto) {
    // Das Kind hat keine eigene Adresse — dieselbe Konvention wie bisher in
    // provision_student. Angemeldet wird mit dem Passwort, nicht per Mail.
    studentEmail = `student.${crypto.randomUUID()}@edvance.invalid`
    const { data: studentData, error: studentErr } = await admin.auth.admin.createUser({
      email: studentEmail,
      password: password ?? randomPassword(),
      email_confirm: true,
    })
    if (studentErr || !studentData.user) {
      return json(502, { error: `Schueler-Account: ${studentErr?.message ?? 'unbekannt'}` })
    }
    studentUid = studentData.user.id

    const elternMail = (vertrag.eltern_email ?? '').trim()
    if (elternMail !== '') {
      // Hat das Elternteil schon ein Konto — etwa vom Geschwisterkind —, wird
      // es verknuepft statt ein zweites anzulegen. profiles ist dafuer die
      // verlaessliche Quelle: jedes Konto, das dieses System angelegt hat, hat
      // dort eine Zeile.
      //
      // Nur Rolle 'parent': Teilt sich ein Coach oder Admin die Adresse mit
      // einem Elternteil, wuerde die RPC ihn beim Verknuepfen auf 'parent'
      // herabstufen. Dann lieber der Fehler unten als ein verlorener Zugang.
      const { data: vorhanden } = await admin
        .from('profiles')
        .select('id')
        .eq('email', elternMail)
        .eq('role', 'parent')
        .maybeSingle()

      if (vorhanden) {
        parentUid = vorhanden.id as string
      } else {
        // Einladung der Eltern folgt bewusst in P4 ueber hello@ (Microsoft Graph).
        // Deshalb hier kein inviteUserByEmail: kein Passwort, keine Bestaetigung,
        // keine Mail. Das Konto ist angelegt und wartet auf die Einladung.
        const { data: parentData, error: parentErr } = await admin.auth.admin.createUser({
          email: elternMail,
          email_confirm: false,
        })
        if (parentErr || !parentData.user) {
          // Existiert die Adresse in auth.users, aber ohne profiles-Zeile,
          // laesst sich die UID hier nicht aufloesen. Lieber abbrechen und es
          // sagen, als ein zweites Elternkonto zu erzeugen.
          await admin.auth.admin.deleteUser(studentUid)
          return json(502, { error: `Eltern-Account: ${parentErr?.message ?? 'unbekannt'}` })
        }
        parentUid = parentData.user.id
        parentNeuAngelegt = true
      }
    }
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

  const { data, error } = await rpcClient.rpc('vertrag_abschliessen', {
    p_vertrag_id: body.vertrag_id,
    p_weg: body.weg,
    p_zustimmungen: body.zustimmungen ?? [],
    p_signatur_vertrag: body.signatur_vertrag ?? null,
    p_signatur_sepa: body.signatur_sepa ?? null,
    p_unterschrieben_am: body.unterschrieben_am ?? null,
    p_eingang_datum: body.eingang_datum ?? null,
    p_scan_pfad: body.scan_pfad ?? null,
    p_abweichung_vermerk: body.abweichung_vermerk ?? null,
    p_tier_id: body.tier_id ?? null,
    p_laufzeit_monate: body.laufzeit_monate ?? null,
    p_vertragsbeginn: body.vertragsbeginn ?? null,
    p_student_uid: studentUid,
    p_student_email: studentEmail,
    p_parent_uid: parentUid,
    p_parent_email: vertrag.eltern_email ?? null,
  })

  // ---- 5. Aufraeumen -------------------------------------------------------
  if (error) {
    if (studentUid) await admin.auth.admin.deleteUser(studentUid)
    if (parentUid && parentNeuAngelegt) await admin.auth.admin.deleteUser(parentUid)
    return json(400, { error: error.message })
  }

  return json(200, data)
})
