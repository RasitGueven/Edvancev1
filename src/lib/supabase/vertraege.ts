// Vertragsprozess: duenne Wrapper um vertraege & Co. und die RPCs vertrag_*.
// Autorisierung (nur Admin), Statuswechsel, Idempotenz und das Pflicht-Gate
// vor der Unterschrift liegen in der DB (Migration 20260922120000).

import { supabase } from '@/lib/supabase/client'
import type {
  RejectionReason,
  SupabaseResult,
  Vertrag,
  VertragDokument,
  VertragMitLead,
  VertragPatch,
  VertragUnterschrift,
  VertragVersand,
  VertragZustimmung,
} from '@/types'

function fail<T>(err: unknown, fallback: string): SupabaseResult<T> {
  return { data: null, error: err instanceof Error ? err.message : fallback }
}

// Board: alle Vertraege mit ihrem Lead, neueste zuerst.
export async function listVertraege(): Promise<SupabaseResult<VertragMitLead[]>> {
  try {
    const { data, error } = await supabase
      .from('vertraege')
      .select('*, lead:leads(*)')
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as VertragMitLead[], error: null }
  } catch (err) {
    return fail(err, 'Verträge konnten nicht geladen werden')
  }
}

export async function getVertrag(id: string): Promise<SupabaseResult<VertragMitLead>> {
  try {
    const { data, error } = await supabase
      .from('vertraege')
      .select('*, lead:leads(*)')
      .eq('id', id)
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as VertragMitLead, error: null }
  } catch (err) {
    return fail(err, 'Vertrag konnte nicht geladen werden')
  }
}

// Formulardaten. RLS laesst das nur zu, solange der Vertrag in Vorbereitung ist.
export async function updateVertrag(
  id: string,
  patch: VertragPatch,
): Promise<SupabaseResult<Vertrag>> {
  try {
    const { data, error } = await supabase
      .from('vertraege')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Vertrag, error: null }
  } catch (err) {
    return fail(err, 'Vertrag konnte nicht gespeichert werden')
  }
}

// Volle IBAN — nur fuer das Formular und das SEPA-Mandat, nie fuer Listen.
export async function getIban(vertragId: string): Promise<SupabaseResult<string | null>> {
  try {
    const { data, error } = await supabase
      .from('vertrag_bankdaten')
      .select('iban')
      .eq('vertrag_id', vertragId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data?.iban as string | undefined) ?? null, error: null }
  } catch (err) {
    return fail(err, 'IBAN konnte nicht geladen werden')
  }
}

export async function saveIban(
  vertragId: string,
  iban: string,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase
      .from('vertrag_bankdaten')
      .upsert({ vertrag_id: vertragId, iban, updated_at: new Date().toISOString() })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return fail(err, 'IBAN konnte nicht gespeichert werden')
  }
}

// Aktive Dokumentfassungen in Anzeigereihenfolge.
export async function listVertragDokumente(): Promise<SupabaseResult<VertragDokument[]>> {
  try {
    const { data, error } = await supabase
      .from('vertrag_dokumente')
      .select('schluessel, version, titel, pflicht, sort_order')
      .eq('aktiv', true)
      .order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as VertragDokument[], error: null }
  } catch (err) {
    return fail(err, 'Vertragsdokumente konnten nicht geladen werden')
  }
}

export async function getGlaeubigerId(): Promise<SupabaseResult<string | null>> {
  try {
    const { data, error } = await supabase
      .from('vertrag_einstellungen')
      .select('glaeubiger_id')
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data?.glaeubiger_id as string | null | undefined) ?? null, error: null }
  } catch (err) {
    return fail(err, 'Gläubiger-ID konnte nicht geladen werden')
  }
}

export type VertragNachweise = {
  zustimmungen: VertragZustimmung[]
  unterschriften: VertragUnterschrift[]
  versand: VertragVersand[]
}

// Haekchen, Unterschriften und Versandprotokoll eines Vertrags.
export async function getVertragNachweise(
  vertragId: string,
): Promise<SupabaseResult<VertragNachweise>> {
  try {
    const [z, u, v] = await Promise.all([
      supabase
        .from('vertrag_zustimmungen')
        .select('dokument_schluessel, dokument_version, akzeptiert_at')
        .eq('vertrag_id', vertragId),
      supabase
        .from('vertrag_unterschriften')
        .select('art, signatur, unterschrieben_at')
        .eq('vertrag_id', vertragId),
      supabase
        .from('vertrag_versand')
        .select('id, weg, anlass, empfaenger, erfolgt_at')
        .eq('vertrag_id', vertragId)
        .order('erfolgt_at', { ascending: false }),
    ])
    const error = z.error ?? u.error ?? v.error
    if (error) return { data: null, error: error.message }
    return {
      data: {
        zustimmungen: (z.data ?? []) as VertragZustimmung[],
        unterschriften: (u.data ?? []) as VertragUnterschrift[],
        versand: (v.data ?? []) as VertragVersand[],
      },
      error: null,
    }
  } catch (err) {
    return fail(err, 'Nachweise konnten nicht geladen werden')
  }
}

// ── RPCs ────────────────────────────────────────────────────────────────────

// Idempotent: ein zweiter Aufruf liefert denselben Vertrag.
export async function vertragStarten(leadId: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.rpc('vertrag_starten', { p_lead_id: leadId })
    if (error) return { data: null, error: error.message }
    return { data: data as string, error: null }
  } catch (err) {
    return fail(err, 'Vertrag konnte nicht gestartet werden')
  }
}

export async function vertragVersandProtokollieren(
  vertragId: string,
  weg: VertragVersand['weg'],
  anlass: VertragVersand['anlass'],
  empfaenger: string | null = null,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_versand_protokollieren', {
      p_vertrag_id: vertragId,
      p_weg: weg,
      p_anlass: anlass,
      p_empfaenger: empfaenger,
    })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return fail(err, 'Versand konnte nicht protokolliert werden')
  }
}

export type AbschlussVorOrt = {
  weg: 'vor_ort'
  zustimmungen: { schluessel: string; version: string; akzeptiert_at: string }[]
  signaturVertrag: string
  signaturSepa: string
}

export type AbschlussPapier = { weg: 'papier'; unterschriebenAm: string }

// Idempotent: ein bereits abgeschlossener Vertrag bleibt unveraendert.
export async function vertragAbschliessen(
  vertragId: string,
  abschluss: AbschlussVorOrt | AbschlussPapier,
): Promise<SupabaseResult<true>> {
  try {
    const params =
      abschluss.weg === 'vor_ort'
        ? {
            p_vertrag_id: vertragId,
            p_weg: 'vor_ort',
            p_zustimmungen: abschluss.zustimmungen,
            p_signatur_vertrag: abschluss.signaturVertrag,
            p_signatur_sepa: abschluss.signaturSepa,
          }
        : {
            p_vertrag_id: vertragId,
            p_weg: 'papier',
            p_unterschrieben_am: abschluss.unterschriebenAm,
          }
    const { error } = await supabase.rpc('vertrag_abschliessen', params)
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return fail(err, 'Vertrag konnte nicht abgeschlossen werden')
  }
}

export async function vertragAblehnen(
  vertragId: string,
  grund: RejectionReason,
  notiz: string | null,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_ablehnen', {
      p_vertrag_id: vertragId,
      p_grund: grund,
      p_notiz: notiz,
    })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return fail(err, 'Vertrag konnte nicht abgelehnt werden')
  }
}
