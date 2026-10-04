// Themenkatalog, Schulplaene und lead_themen fuer das Erstgespraech
// (Migration 20261001114732). themen ist fuer alle lesbar, schul_themenplan
// fuer Admin und Coach, lead_themen nur fuer Admins.

import { supabase } from '@/lib/supabase/client'
import type {
  LeadThema,
  LeadThemaQuelle,
  SchulPlanZeile,
  SkillThema,
  Stufe,
  SupabaseResult,
  Thema,
} from '@/types'

const fehler = (err: unknown, fallback: string): string =>
  err instanceof Error ? err.message : fallback

/** Fachname am Lead ("Mathematik") → fach im Katalog ("mathematik"). */
export function fachSchluessel(fachName: string): string {
  return fachName.trim().toLowerCase()
}

export async function listThemen(fach: string): Promise<SupabaseResult<Thema[]>> {
  try {
    const { data, error } = await supabase
      .from('themen')
      .select('thema_key, fach, stufe, label, schlagworte, sort')
      .eq('fach', fach)
      .order('sort', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Thema[], error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load topic catalog') }
  }
}

/**
 * Alle Heimat-Themen der Skills in einem Abruf (skill_thema mit eingebettetem
 * themen). Lesbar fuer admin und coach; ein Skill ohne Zeile hat kein Thema.
 */
export async function listSkillThemen(): Promise<SupabaseResult<SkillThema[]>> {
  try {
    const { data, error } = await supabase
      .from('skill_thema')
      .select('skill_key, thema_key, themen(label, stufe, sort)')
    if (error) return { data: null, error: error.message }
    type Eingebettet = { label: string | null; stufe: Stufe; sort: number | null }
    const rows = (data ?? []) as unknown as {
      skill_key: string
      thema_key: string
      themen: Eingebettet | Eingebettet[] | null
    }[]
    return {
      data: rows.flatMap((r) => {
        const th = Array.isArray(r.themen) ? r.themen[0] : r.themen
        if (!th) return []
        return [{
          skill_key: r.skill_key,
          thema_key: r.thema_key,
          label: th.label ?? r.thema_key,
          stufe: th.stufe,
          sort: th.sort,
        }]
      }),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load skill topics') }
  }
}

export async function listSchulPlan(
  schuleId: string,
  fach: string,
): Promise<SupabaseResult<SchulPlanZeile[]>> {
  try {
    const { data, error } = await supabase
      .from('schul_themenplan')
      .select('klasse, position, thema_key, stand')
      .eq('schule_id', schuleId)
      .eq('fach', fach)
      .order('klasse', { ascending: true })
      .order('position', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SchulPlanZeile[], error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load school plan') }
  }
}

export async function listLeadThemen(
  leadId: string,
  fach: string,
): Promise<SupabaseResult<LeadThema[]>> {
  try {
    const { data, error } = await supabase
      .from('lead_themen')
      .select('thema_key, fach, status, quelle')
      .eq('lead_id', leadId)
      .eq('fach', fach)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as LeadThema[], error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load lead topics') }
  }
}

/**
 * Setzt das aktuelle Thema in einem Schritt (RPC lead_thema_setzen, Migration
 * 20261004001333). Ein altes 'aktuell' desselben Fachs faellt weg; war das
 * neue Thema schon als 'behandelt' erfasst, wird die Zeile umgestellt.
 * themaKey null entfernt das aktuelle Thema.
 */
export async function setAktuellesThema(
  leadId: string,
  fach: string,
  themaKey: string | null,
  quelle: LeadThemaQuelle = 'gespraech',
): Promise<SupabaseResult<null>> {
  try {
    const { error } = await supabase.rpc('lead_thema_setzen', {
      p_lead_id: leadId,
      p_fach: fach,
      p_thema_key: themaKey,
      p_quelle: quelle,
    })
    if (error) return { data: null, error: error.message }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not set current topic') }
  }
}

/** Legt 'behandelt'-Zeilen an; bestehende Zeilen bleiben unberuehrt. */
export async function behandeltAnlegen(
  leadId: string,
  fach: string,
  themaKeys: string[],
  quelle: LeadThemaQuelle,
): Promise<SupabaseResult<null>> {
  if (themaKeys.length === 0) return { data: null, error: null }
  try {
    const angelegt = new Date().toISOString()
    const { error } = await supabase.from('lead_themen').upsert(
      themaKeys.map((thema_key) => ({
        lead_id: leadId,
        fach,
        thema_key,
        status: 'behandelt',
        quelle,
        angelegt,
      })),
      { onConflict: 'lead_id,thema_key', ignoreDuplicates: true },
    )
    if (error) return { data: null, error: error.message }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not save covered topics') }
  }
}

/** Entfernt 'behandelt'-Zeilen (Abwaehlen). 'aktuell' bleibt stehen. */
export async function behandeltEntfernen(
  leadId: string,
  themaKeys: string[],
): Promise<SupabaseResult<null>> {
  if (themaKeys.length === 0) return { data: null, error: null }
  try {
    const { error } = await supabase
      .from('lead_themen')
      .delete()
      .eq('lead_id', leadId)
      .eq('status', 'behandelt')
      .in('thema_key', themaKeys)
    if (error) return { data: null, error: error.message }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not remove covered topics') }
  }
}
