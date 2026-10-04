// Anlass 'terminbestaetigung': die Bestaetigung des Erstgespraechs an die
// Eltern eines Leads. Kein Vertrag, keine Anhaenge — Termin, Ort, Dauer, Ablauf,
// Mitbring-Hinweis.
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

/** Ein Wert, der vor dem Echtbetrieb noch eingetragen werden muss. */
const PLATZHALTER = /\[[^\]]*FEHLT[^\]]*\]/

type Antwort = { status: number; payload: Record<string, unknown> }

function einsetzen(vorlage: string, werte: Record<string, string>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => werte[k] ?? '—')
}

export async function terminBestaetigung(
  admin: SupabaseClient,
  caller: SupabaseClient,
  leadId: string,
): Promise<Antwort> {
  const { data: lead, error } = await admin
    .from('leads')
    .select('id, full_name, first_name, contact_email, erstgespraech_at, erstgespraech_standort')
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
    ort: MAIL[`terminOrt_${lead.erstgespraech_standort ?? 'koeln'}`] ?? '[ADRESSE FEHLT]',
    dauer: MAIL.terminDauer,
  }
  const betreff = einsetzen(MAIL.terminBetreff, werte)
  const text = einsetzen(MAIL.terminText, werte)

  // Nicht mit Platzhalter an echte Eltern. Kein Protokoll: es wurde nichts
  // versucht.
  if (PLATZHALTER.test(text)) {
    return { status: 400, payload: { error: 'Die Mail enthaelt noch einen Platzhalter (Adresse des Standorts)' } }
  }

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
    p_termin_at: lead.erstgespraech_at,
    p_fehler: fehler,
  })
  if (protErr) console.error('mail_senden: Protokoll', protErr.message)

  if (fehler) return { status: 502, payload: { error: fehler, protokolliert: protErr === null } }
  return { status: 200, payload: { an, anhaenge: [], protokolliert: protErr === null } }
}
