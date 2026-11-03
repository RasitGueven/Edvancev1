// Der LSA-Report per Mail an die Eltern (Bauauftrag LR-2).
//
// Ablauf: Das PDF entsteht im Browser (src/lib/report/bogenPdf.ts), wird hier
// in den privaten Bucket lsa_reports hochgeladen ({session_id}/{yyyyMMdd-HHmmss}.pdf,
// UTC, ohne upsert: jede versendete Fassung bleibt liegen) und dann über die
// Edge Function mail_senden verschickt. Die Oberfläche schickt nur Sitzung und
// Pfad; Lead und Adresse ermittelt die Funktion selbst (Entscheidung 5).
// Protokolliert wird dort in lead_mail_versand, auch ein gescheiterter Versuch.
//
// Lesen und Hochladen nur Admin (RLS an leads, lead_mail_versand und Storage).

import type { LsaReportEmpfaenger } from '@/lib/lsaReportMail'
import { supabase } from '@/lib/supabase/client'
import type { LeadMailVersand, SupabaseResult } from '@/types'
import { meldung } from './vertragMail'

export const LSA_REPORTS_BUCKET = 'lsa_reports'

export type LsaReportVersandErgebnis = { an: string; anhaenge: string[]; bytes?: number; sha256?: string }

/** yyyyMMdd-HHmmss in UTC — sekundengenau, sortiert sich von selbst. */
export function reportPfad(sessionId: string, jetzt: Date = new Date()): string {
  const stempel = jetzt.toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15)
  return `${sessionId}/${stempel}.pdf`
}

/** Name und Eltern-Mail des Leads für Vorschau und Sperrgrund. */
export async function ladeLsaReportEmpfaenger(
  leadId: string,
): Promise<SupabaseResult<LsaReportEmpfaenger>> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('full_name, first_name, contact_email')
      .eq('id', leadId)
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as LsaReportEmpfaenger, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Could not load lead' }
  }
}

/** Das PDF ablegen; liefert den Pfad. Kein Überschreiben (upsert: false). */
export async function lsaReportHochladen(
  sessionId: string,
  pdf: Blob,
  jetzt: Date = new Date(),
): Promise<SupabaseResult<string>> {
  const pfad = reportPfad(sessionId, jetzt)
  try {
    const { error } = await supabase.storage
      .from(LSA_REPORTS_BUCKET)
      .upload(pfad, pdf, { contentType: 'application/pdf', upsert: false })
    if (error) return { data: null, error: error.message }
    return { data: pfad, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Upload failed' }
  }
}

export async function lsaReportSenden(
  sessionId: string,
  pfad: string,
): Promise<SupabaseResult<LsaReportVersandErgebnis>> {
  try {
    const { data, error } = await supabase.functions.invoke('mail_senden', {
      body: { anlass: 'lsa_report', lsa_session_id: sessionId, pfad },
    })
    if (error) return { data: null, error: await meldung(error, 'Sending failed') }
    return { data: data as LsaReportVersandErgebnis, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Sending failed' }
  }
}

/** Alle Versandversuche des Reports zu einer Sitzung, neueste zuerst. */
export async function listLsaReportVersand(
  sessionId: string,
): Promise<SupabaseResult<LeadMailVersand[]>> {
  try {
    const { data, error } = await supabase
      .from('lead_mail_versand')
      .select('id, anlass, empfaenger, ort, termin_at, fehler, erfolgt_at, lsa_session_id, anhang_pfad, anhang_sha256')
      .eq('lsa_session_id', sessionId)
      .eq('anlass', 'lsa_report')
      .order('erfolgt_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as LeadMailVersand[], error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Could not load mail log' }
  }
}
