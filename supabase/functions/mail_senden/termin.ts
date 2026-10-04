// Anlass 'terminbestaetigung': die Bestaetigung des Erstgespraechs an die
// Eltern eines Leads. Kein Vertrag, keine Anhaenge — Termin, Ort, Dauer, Ablauf,
// Mitbring-Hinweis.
//
// Edvance hat keinen festen Standort. Der Ort ist deshalb Pflichtangabe des
// Admins im Versand-Dialog (Freitext: Adresse der Familie, Coworking …) und
// wird mit dem Termin protokolliert.
//
// Die Texte kommen aus MAIL (de/vertraege.json → mail.termin*), dieselben, aus
// denen die Oberflaeche die Vorschau baut. Datum und Uhrzeit werden hier wie
// dort mit denselben Intl-Optionen formatiert (src/lib/terminBestaetigung.ts).
//
// Empfaenger ist immer leads.contact_email — keine freie Adresse aus dem
// Request, damit die Funktion nicht als Versandweg an beliebige Adressen taugt.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { MAIL } from '../_shared/dokumente/texte.ts'
import { mailSenden } from '../_shared/graph_mail.ts'

const ZONE = 'Europe/Berlin'
const DATUM = new Intl.DateTimeFormat('de-DE', {
  weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: ZONE,
})
const UHRZEIT = new Intl.DateTimeFormat('de-DE', {
  hour: '2-digit', minute: '2-digit', timeZone: ZONE,
})

/** Wie lead_mail_versand_ort_check. */
export const ORT_MAX = 300

type Antwort = { status: number; payload: Record<string, unknown> }

function einsetzen(vorlage: string, werte: Record<string, string>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => werte[k] ?? '—')
}

export async function terminBestaetigung(
  admin: SupabaseClient,
  caller: SupabaseClient,
  leadId: string,
  ortRoh: unknown,
): Promise<Antwort> {
  const ort = typeof ortRoh === 'string' ? ortRoh.trim() : ''
  if (ort === '') return { status: 400, payload: { error: 'Ort des Gespraechs fehlt' } }
  if (ort.length > ORT_MAX) {
    return { status: 400, payload: { error: `Ort ist laenger als ${ORT_MAX} Zeichen` } }
  }

  const { data: lead, error } = await admin
    .from('leads')
    .select('id, full_name, first_name, contact_email, erstgespraech_at')
    .eq('id', leadId)
    .single()
  if (error || !lead) return { status: 404, payload: { error: 'Lead nicht gefunden' } }

  const an = (lead.contact_email ?? '').trim()
  if (an === '') return { status: 400, payload: { error: 'Keine Eltern-Mail am Lead hinterlegt' } }
  if (!lead.erstgespraech_at) return { status: 400, payload: { error: 'Kein Termin am Lead' } }

  const termin = new Date(lead.erstgespraech_at)
  const werte: Record<string, string> = {
    kind: (lead.first_name ?? '').trim() || lead.full_name,
    datum: DATUM.format(termin),
    uhrzeit: UHRZEIT.format(termin),
    ort,
    dauer: MAIL.terminDauer,
  }
  const betreff = einsetzen(MAIL.terminBetreff, werte)
  const text = einsetzen(MAIL.terminText, werte)

  let fehler: string | null = null
  try {
    await mailSenden({ an, betreff, text, anhaenge: [] })
  } catch (err) {
    fehler = err instanceof Error ? err.message : 'Versand fehlgeschlagen'
    console.error('mail_senden terminbestaetigung', leadId, fehler)
  }

  const { error: protErr } = await caller.rpc('lead_mail_protokollieren', {
    p_lead_id: leadId,
    p_anlass: 'terminbestaetigung',
    p_empfaenger: an,
    p_ort: ort,
    p_termin_at: lead.erstgespraech_at,
    p_fehler: fehler,
  })
  if (protErr) console.error('mail_senden: Protokoll', protErr.message)

  if (fehler) return { status: 502, payload: { error: fehler, protokolliert: protErr === null } }
  return { status: 200, payload: { an, anhaenge: [], protokolliert: protErr === null } }
}
