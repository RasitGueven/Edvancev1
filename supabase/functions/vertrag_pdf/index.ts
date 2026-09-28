// Edge Function: vertrag_pdf
//
// Erzeugt das Vertrags-PDF zu einem abgeschlossenen Vertrag und legt es im
// privaten Bucket "vertraege" ab. Zwei Aufrufer: der Abschluss selbst
// (vertrag_abschluss, direkt ueber den gemeinsamen Baustein) und der Knopf
// "PDF erzeugen" in der Detailansicht, wenn beim Abschluss etwas schiefging.
//
// Warum ueberhaupt serverseitig: Die Oberflaeche ist eine Vite-SPA ohne
// eigenen Server. Ein im Browser erzeugtes PDF haenge davon ab, welcher
// Rechner am Empfang steht — und liesse sich vor dem Hochladen veraendern.
// Ein Archivdokument muss dort entstehen, wo auch die Daten liegen.
//
// Deploy: npx supabase functions deploy vertrag_pdf --project-ref ztcppihxqcphlqaguhma

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  fassungenErzeugen,
  hatVertragPdf,
  vertragPdfErzeugen,
} from '../_shared/vertrag_pdf_erzeugen.ts'

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

  let body: { vertrag_id?: string }
  try {
    body = await req.json()
  } catch {
    return json(400, { error: 'Ungueltiger Request-Body' })
  }
  if (!body.vertrag_id) return json(400, { error: 'vertrag_id erforderlich' })

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Autorisierung wie in vertrag_abschluss: fail-closed, Admin oder nichts.
  // Die RPC vertrag_datei_eintragen prueft es noch einmal — hier steht es,
  // damit gar nicht erst ein PDF entsteht und im Bucket landet.
  const authHeader = req.headers.get('Authorization') ?? ''
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  if (!bearer || bearer === serviceKey) {
    // Ohne JWT bliebe erzeugt_von leer. Ein Archiveintrag ohne Urheber ist
    // genau die Luecke, die diese Tabelle schliessen soll.
    return json(401, { error: 'Nicht authentifiziert' })
  }
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
  if (prof?.role !== 'admin') return json(403, { error: 'Nur Admin darf PDFs erzeugen' })

  if (await hatVertragPdf(admin, body.vertrag_id)) {
    return json(409, { error: 'Fuer diesen Vertrag gibt es das PDF schon' })
  }

  try {
    // Erst die geteilten Unterlagen — sie gehoeren zum Buendel und sind beim
    // ersten Vertrag noch nicht da. Idempotent: liegen sie schon, passiert
    // nichts.
    const fassungen = await fassungenErzeugen(admin, caller)
    const dateien = await vertragPdfErzeugen(admin, caller, body.vertrag_id)
    return json(200, { dateien, fassungen })
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'PDF konnte nicht erzeugt werden'
    return json(400, { error: msg })
  }
})
