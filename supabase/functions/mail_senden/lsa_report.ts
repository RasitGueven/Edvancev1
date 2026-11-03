// Anlass 'lsa_report': der Eltern-Bericht der LSA als PDF an die Eltern des
// Leads (Bauauftrag LR-2, Entscheidungen 4–7 und 10).
//
// Das PDF entsteht im Browser aus dem fertigen Bogen und liegt schon im
// privaten Bucket lsa_reports, wenn diese Funktion laeuft. Sie bekommt nur
// Sitzung und Pfad; Lead und Adresse ermittelt sie selbst. Empfaenger ist immer
// leads.contact_email — keine Adresse und keine Lead-ID aus dem Request, damit
// die Funktion nicht als Versandweg an beliebige Adressen taugt (wie termin.ts).
//
// Die Texte kommen aus MAIL (de/vertraege.json → mail.lsaReport*), dieselben,
// aus denen die Oberflaeche die Vorschau baut (src/lib/lsaReportMail.ts).
// Testlauf-Sitzungen duerfen versendet werden, der Betreff traegt dann "[Test] ".
//
// Protokolliert wird jeder Versandversuch mit Pfad und SHA-256 der Datei, auch
// der gescheiterte. Pruefungen vor dem Versand (falscher Pfad, Sitzung nicht
// auswertbar, keine Adresse) enden mit 400 ohne Protokoll, wie bei termin.ts.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { MAIL } from '../_shared/dokumente/texte.ts'
import { mailSenden } from '../_shared/graph_mail.ts'

export const BUCKET_REPORTS = 'lsa_reports'

const DATUM = new Intl.DateTimeFormat('de-DE', {
  day: '2-digit', month: '2-digit', year: 'numeric', timeZone: 'Europe/Berlin',
})
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

type Antwort = { status: number; payload: Record<string, unknown> }

function einsetzen(vorlage: string, werte: Record<string, string>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => werte[k] ?? '—')
}

/** Nur {session}/{yyyyMMdd-HHmmss}.pdf dieser Sitzung — kein fremder Ordner, kein "..". */
export function pfadPasst(sessionId: string, pfad: string): boolean {
  return pfad.startsWith(`${sessionId}/`) && /^[0-9a-f-]{36}\/\d{8}-\d{6}\.pdf$/.test(pfad)
}

async function sha256(puffer: ArrayBuffer): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', puffer))
  return [...digest].map((b) => b.toString(16).padStart(2, '0')).join('')
}

export async function lsaReport(
  admin: SupabaseClient,
  caller: SupabaseClient,
  sessionRoh: unknown,
  pfadRoh: unknown,
): Promise<Antwort> {
  const sessionId = typeof sessionRoh === 'string' ? sessionRoh.trim().toLowerCase() : ''
  const pfad = typeof pfadRoh === 'string' ? pfadRoh.trim() : ''
  if (!UUID.test(sessionId)) return { status: 400, payload: { error: 'lsa_session_id erforderlich' } }
  if (!pfadPasst(sessionId, pfad)) {
    return { status: 400, payload: { error: 'Die Datei gehoert nicht zu dieser Sitzung' } }
  }

  const { data: s, error: sErr } = await admin
    .from('lsa_sessions')
    .select('id, student_id, status, auswertbar, testlauf, completed_at, started_at, created_at')
    .eq('id', sessionId)
    .maybeSingle()
  if (sErr || !s) return { status: 404, payload: { error: 'LSA nicht gefunden' } }
  if (s.status !== 'completed') return { status: 400, payload: { error: 'Die LSA ist nicht abgeschlossen' } }
  if (s.auswertbar === false) return { status: 400, payload: { error: 'Die LSA ist nicht auswertbar' } }

  // Derselbe Weg wie im Report (lsa_lead_kontext): students.lead_id, sonst leads.converted_student_id.
  const { data: leadId } = await admin.rpc('lsa_lead_von_schueler', { p_student_id: s.student_id })
  if (!leadId) return { status: 400, payload: { error: 'Zur LSA gehoert kein Lead' } }
  const { data: lead, error: lErr } = await admin
    .from('leads')
    .select('id, full_name, first_name, contact_email')
    .eq('id', leadId)
    .single()
  if (lErr || !lead) return { status: 400, payload: { error: 'Zur LSA gehoert kein Lead' } }

  const an = (lead.contact_email ?? '').trim()
  if (an === '') return { status: 400, payload: { error: 'Keine Eltern-Mail am Lead hinterlegt' } }

  const { data: datei, error: dErr } = await admin.storage.from(BUCKET_REPORTS).download(pfad)
  if (dErr || !datei) return { status: 400, payload: { error: 'Die Datei liegt nicht im Speicher' } }
  const puffer = await datei.arrayBuffer()
  const bytes = new Uint8Array(puffer)
  const pruefsumme = await sha256(puffer)

  const werte: Record<string, string> = {
    kind: (lead.first_name ?? '').trim() || lead.full_name,
    datum: DATUM.format(new Date(s.completed_at ?? s.started_at ?? s.created_at)),
  }
  const betreff = (s.testlauf ? MAIL.lsaReportTestPraefix : '') + einsetzen(MAIL.lsaReportBetreff, werte)
  const text = einsetzen(MAIL.lsaReportText, werte)
  const name = `${einsetzen(MAIL.lsaReportDatei, werte)}.pdf`

  let fehler: string | null = null
  try {
    await mailSenden({ an, betreff, text, anhaenge: [{ name, contentType: 'application/pdf', bytes }] })
  } catch (err) {
    fehler = err instanceof Error ? err.message : 'Versand fehlgeschlagen'
    console.error('mail_senden lsa_report', sessionId, fehler)
  }

  const { error: protErr } = await caller.rpc('lead_mail_protokollieren', {
    p_lead_id: lead.id,
    p_anlass: 'lsa_report',
    p_empfaenger: an,
    p_fehler: fehler,
    p_lsa_session_id: sessionId,
    p_anhang_pfad: pfad,
    p_anhang_sha256: pruefsumme,
  })
  if (protErr) console.error('mail_senden: Protokoll', protErr.message)

  if (fehler) return { status: 502, payload: { error: fehler, protokolliert: protErr === null } }
  return {
    status: 200,
    payload: { an, anhaenge: [name], bytes: bytes.length, sha256: pruefsumme, protokolliert: protErr === null },
  }
}
