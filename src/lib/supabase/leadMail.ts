// Mails an Eltern eines Leads, vor dem Vertrag. Erster Anlass: die
// Terminbestaetigung zum Erstgespraech.
//
// Verschickt wird wie beim Vertrag in der Edge Function mail_senden (Absender
// hello@). Der Empfaenger ist immer leads.contact_email — die Funktion liest
// ihn selbst, die Oberflaeche schickt keine Adresse mit. Den Ort des Gespraechs
// (Pflicht, Freitext) schickt sie mit; Edvance hat keinen festen Standort. Protokolliert wird
// dort in lead_mail_versand, auch ein gescheiterter Versuch.

import { supabase } from '@/lib/supabase/client'
import type { LeadMailVersand, SupabaseResult } from '@/types'
import { meldung, type VersandErgebnis } from './vertragMail'

export async function terminBestaetigungSenden(
  leadId: string,
  ort: string,
): Promise<SupabaseResult<VersandErgebnis>> {
  try {
    const { data, error } = await supabase.functions.invoke('mail_senden', {
      body: { lead_id: leadId, anlass: 'terminbestaetigung', ort: ort.trim() },
    })
    if (error) return { data: null, error: await meldung(error, 'Sending failed') }
    return { data: data as VersandErgebnis, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Sending failed' }
  }
}

/** Alle Versandversuche eines Leads, neueste zuerst. */
export async function listLeadMailVersand(
  leadId: string,
): Promise<SupabaseResult<LeadMailVersand[]>> {
  try {
    const { data, error } = await supabase
      .from('lead_mail_versand')
      .select('id, anlass, empfaenger, ort, termin_at, fehler, erfolgt_at')
      .eq('lead_id', leadId)
      .order('erfolgt_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as LeadMailVersand[], error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Could not load mail log' }
  }
}
