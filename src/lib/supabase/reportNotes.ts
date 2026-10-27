// Eltern-Report — die zwei Coach-Freitexte + Paketwahl (Ausblick).
//
// ⚠️  Die Ablage `lsa_report_notes` ist NOCH NICHT migriert (die Schema-Zone ist
// per guard-paths.sh Opt-in-geschützt, siehe PR-Beschreibung). Bis die
// Migration läuft, meldet Postgres 42P01 („relation does not exist"). Beide
// Funktionen fangen genau das ab und melden es als `unavailable`, damit der
// Report vollständig nutzbar bleibt (er ist ansonsten read-only) und die UI die
// Felder ehrlich als „noch nicht speicherbar" kennzeichnen kann — statt einen
// Speicherfehler als Datenverlust zu präsentieren.

import { supabase } from '@/lib/supabase/client'
import type { ReportNotes, ReportPaket, SupabaseResult } from '@/types'
import { REPORT_PAKETE } from '@/types'

const MISSING_TABLE = '42P01'

export const EMPTY_NOTES: ReportNotes = {
  zielbild: '',
  empfehlung: '',
  paket: null,
}

/**
 * `bestaetigung`: Es gibt die Spalten paket_bestaetigt und ziele_bestaetigt; nur dann zeigt die Ansicht die Schalter
 * „im Gespräch bestätigt“ und saveReportNotes schreibt sie mit (L5 Teil D, Entscheidung 14).
 */
export type NotesResult = SupabaseResult<ReportNotes> & { unavailable: boolean; bestaetigung?: boolean }

function asPaket(value: unknown): ReportPaket | null {
  return REPORT_PAKETE.includes(value as ReportPaket)
    ? (value as ReportPaket)
    : null
}

/**
 * Bericht v2/v3: Bestätigungen des Coachs. Je Spalte eine eigene Abfrage, weil
 * paket_bestaetigt (Migration 20261024135226_bericht_v2) und ziele_bestaetigt
 * (20261024…_bericht_v3_ziele) noch nicht eingespielt sind — fehlt eine, gilt
 * „nicht bestätigt“ und der Bericht zeigt den Vorschlag bzw. keine Ziele.
 */
async function loadBestaetigt(sessionId: string, spalte: 'paket_bestaetigt' | 'ziele_bestaetigt'): Promise<boolean | null> {
  try {
    const { data, error } = await supabase
      .from('lsa_report_notes')
      .select(spalte)
      .eq('session_id', sessionId)
      .maybeSingle()
    if (error) return null
    return (data as Record<string, unknown> | null)?.[spalte] === true
  } catch {
    return null
  }
}

export async function getReportNotes(sessionId: string): Promise<NotesResult> {
  try {
    const { data, error } = await supabase
      .from('lsa_report_notes')
      .select('zielbild, empfehlung, paket')
      .eq('session_id', sessionId)
      .maybeSingle()

    if (error) {
      if (error.code === MISSING_TABLE) {
        return { data: EMPTY_NOTES, error: null, unavailable: true }
      }
      return { data: null, error: error.message, unavailable: false }
    }
    const [paketBestaetigt, zieleBestaetigt] = await Promise.all([
      loadBestaetigt(sessionId, 'paket_bestaetigt'),
      loadBestaetigt(sessionId, 'ziele_bestaetigt'),
    ])
    return {
      data: {
        zielbild: (data?.zielbild as string | null) ?? '',
        empfehlung: (data?.empfehlung as string | null) ?? '',
        paket: asPaket(data?.paket),
        paketBestaetigt: paketBestaetigt === true,
        zieleBestaetigt: zieleBestaetigt === true,
      },
      error: null,
      unavailable: false,
      bestaetigung: paketBestaetigt !== null && zieleBestaetigt !== null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Notizen konnten nicht geladen werden'
    return { data: null, error: message, unavailable: false }
  }
}

/** @param bestaetigung true, wenn die Spalten paket_bestaetigt/ziele_bestaetigt da sind (getReportNotes). */
export async function saveReportNotes(
  sessionId: string,
  notes: ReportNotes,
  bestaetigung = false,
): Promise<NotesResult> {
  try {
    const { error } = await supabase.from('lsa_report_notes').upsert(
      {
        session_id: sessionId,
        zielbild: notes.zielbild.trim() || null,
        empfehlung: notes.empfehlung.trim() || null,
        paket: notes.paket,
        ...(bestaetigung
          ? { paket_bestaetigt: notes.paketBestaetigt === true, ziele_bestaetigt: notes.zieleBestaetigt === true }
          : {}),
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'session_id' },
    )

    if (error) {
      if (error.code === MISSING_TABLE) {
        return { data: notes, error: null, unavailable: true }
      }
      return { data: null, error: error.message, unavailable: false }
    }
    return { data: notes, error: null, unavailable: false }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Notizen konnten nicht gespeichert werden'
    return { data: null, error: message, unavailable: false }
  }
}
