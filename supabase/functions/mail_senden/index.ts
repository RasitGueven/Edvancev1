// Edge Function: mail_senden
//
// Der Versand der Vertragsunterlagen ueber hello@edvanceacademy.de. Drei
// Anlaesse: die Bestaetigung nach dem Abschluss, die Unterlagen zum
// Ausdrucken (Weg B) und ein neu erzeugter Zugangscode.
//
// Jeder Versuch wird protokolliert — auch der gescheiterte. Ein Protokoll,
// das nur die geglueckten Versuche kennt, beantwortet die eine Frage nicht,
// wegen der man hineinschaut: "warum haben die Eltern nichts bekommen?"
//
// Deploy: npx supabase functions deploy mail_senden --project-ref ztcppihxqcphlqaguhma

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { MAIL } from '../_shared/dokumente/texte.ts'
import { mailSenden, type Anhang } from '../_shared/graph_mail.ts'
import { datum } from '../_shared/vertrag_dokument.ts'
import { BUCKET, buendelPfade } from '../_shared/vertrag_pdf_erzeugen.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Anlass = 'bestaetigung' | 'unterlagen' | 'zugangscode'

// Ein Literal, keine Verkettung: supabase-js leitet die Zeilentypen aus dem
// Text dieser Zeichenkette ab und kann ein zusammengesetztes nicht lesen.
const VERSAND_SPALTEN = `
  id, status, eltern_vorname, eltern_nachname, eltern_email, kind_vorname,
  kind_nachname, vertragsbeginn, vertrag_ende, widerruf_bis, rueckmeldung_bis,
  zugangscode
`

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function einsetzen(vorlage: string, werte: Record<string, string>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => werte[k] ?? '—')
}

/** Die Anhaenge aus dem privaten Bucket holen. */
async function anhaengeLaden(admin: SupabaseClient, pfade: string[]): Promise<Anhang[]> {
  const raus: Anhang[] = []
  for (const pfad of pfade) {
    const { data, error } = await admin.storage.from(BUCKET).download(pfad)
    if (error || !data) throw new Error(`Anhang fehlt: ${pfad}`)
    raus.push({
      name: pfad.split('/').pop() ?? 'anhang.pdf',
      contentType: pfad.endsWith('.png') ? 'image/png' : 'application/pdf',
      bytes: new Uint8Array(await data.arrayBuffer()),
    })
  }
  return raus
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json(405, { error: 'Method not allowed' })

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !serviceKey || !anonKey) return json(500, { error: 'Service-Config fehlt' })

  let body: { vertrag_id?: string; anlass?: Anlass; empfaenger?: string }
  try {
    body = await req.json()
  } catch {
    return json(400, { error: 'Ungueltiger Request-Body' })
  }
  const anlass = body.anlass
  if (!body.vertrag_id) return json(400, { error: 'vertrag_id erforderlich' })
  if (anlass !== 'bestaetigung' && anlass !== 'unterlagen' && anlass !== 'zugangscode') {
    return json(400, { error: 'anlass muss bestaetigung, unterlagen oder zugangscode sein' })
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Autorisierung wie in vertrag_abschluss: fail-closed, Admin oder nichts.
  // Ohne JWT bliebe erfolgt_von leer — ein Versandprotokoll ohne Absender ist
  // genau die Luecke, die es schliessen soll.
  const authHeader = req.headers.get('Authorization') ?? ''
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  if (!bearer || bearer === serviceKey) return json(401, { error: 'Nicht authentifiziert' })
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  })
  const { data: userData, error: userErr } = await caller.auth.getUser()
  if (userErr || !userData.user) return json(401, { error: 'Nicht authentifiziert' })
  const { data: prof } = await admin
    .from('profiles')
    .select('role')
    .eq('id', userData.user.id)
    .maybeSingle()
  if (prof?.role !== 'admin') return json(403, { error: 'Nur Admin darf versenden' })

  // ---- Empfaenger und Inhalt ----------------------------------------------
  const { data: v, error: vErr } = await admin
    .from('vertraege')
    .select(VERSAND_SPALTEN)
    .eq('id', body.vertrag_id)
    .single()
  if (vErr || !v) return json(404, { error: 'Vertrag nicht gefunden' })

  const an = (body.empfaenger ?? v.eltern_email ?? '').trim()
  if (an === '') return json(400, { error: 'Keine Empfaengeradresse hinterlegt' })

  const kind = [v.kind_vorname, v.kind_nachname].filter(Boolean).join(' ') || 'Ihr Kind'
  const eltern = [v.eltern_vorname, v.eltern_nachname].filter(Boolean).join(' ')

  let pfade: string[] = []
  try {
    if (anlass !== 'zugangscode') pfade = await buendelPfade(admin, body.vertrag_id, anlass)
  } catch (err) {
    return json(400, { error: err instanceof Error ? err.message : 'Anhaenge fehlen' })
  }
  const namen = pfade.map((p) => p.split('/').pop() ?? p)
  const liste = namen.map((n) => einsetzen(MAIL.anhangZeile, { name: n })).join('\n')

  const werte: Record<string, string> = {
    kind,
    eltern: eltern || 'Sie',
    liste,
    beginn: datum(v.vertragsbeginn) ?? '—',
    ende: datum(v.vertrag_ende) ?? '—',
    widerruf: datum(v.widerruf_bis) ?? '—',
    bis: datum(v.rueckmeldung_bis) ?? '—',
    code: v.zugangscode ?? '—',
  }

  if (anlass === 'zugangscode' && !v.zugangscode) {
    return json(400, { error: 'Dieser Vertrag hat keinen Zugangscode' })
  }

  const betreff = einsetzen(MAIL[`${anlass}Betreff`], werte)
  const text = einsetzen(MAIL[`${anlass}Text`], werte)

  // ---- Versenden und protokollieren ---------------------------------------
  // Das Protokoll wird in BEIDEN Faellen geschrieben. Die Zeile mit gefuelltem
  // "fehler" ist die wertvollere von beiden.
  let fehler: string | null = null
  try {
    const anhaenge = await anhaengeLaden(admin, pfade)
    await mailSenden({ an, betreff, text, anhaenge })
  } catch (err) {
    fehler = err instanceof Error ? err.message : 'Versand fehlgeschlagen'
    console.error('mail_senden', body.vertrag_id, anlass, fehler)
  }

  const { error: protErr } = await caller.rpc('vertrag_versand_protokollieren', {
    p_vertrag_id: body.vertrag_id,
    p_weg: 'email',
    p_anlass: anlass,
    p_empfaenger: an,
    p_anhaenge: namen.length > 0 ? namen : null,
    p_fehler: fehler,
  })
  if (protErr) console.error('mail_senden: Protokoll', protErr.message)

  if (fehler) return json(502, { error: fehler, protokolliert: protErr === null })
  return json(200, { an, anhaenge: namen, protokolliert: protErr === null })
})
