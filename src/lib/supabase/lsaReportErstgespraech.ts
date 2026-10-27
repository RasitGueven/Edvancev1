// Eltern-Bericht v2 — Lesepfad für den Anlass aus dem Erstgespräch (leads).
//
// leads liest per RLS nur der Admin (wie lsaReportPlan.ts). Beim Coach, bei
// Fehler oder ohne Lead gibt es null, und die Sätze auf Seite 1 entfallen.
//
// klassenarbeit_status kommt aus einer eigenen Abfrage: Die Spalte bringt erst
// die Migration 20261024…_bericht_v2 (noch nicht eingespielt). Fehlt sie,
// scheitert nur diese Abfrage; dann gilt ein next_exam_date ab dem Tag der
// Sitzung als „bevorstehend“, sonst bleibt der Stand unbekannt.

import { supabase } from '@/lib/supabase/client'
import { loadKlassenarbeiten } from '@/lib/supabase/lsaReportKlassenarbeiten'
import type {
  KlassenarbeitStatus,
  LeadGradeTrend,
  LeadStrugglingSince,
  ReportErstgespraech,
} from '@/types'

const TRENDS: readonly LeadGradeTrend[] = ['besser', 'stabil', 'schlechter']
const SEIT: readonly LeadStrugglingSince[] = ['dieses_halbjahr', 'letztes_schuljahr', 'laenger']
const STATUS: readonly KlassenarbeitStatus[] = ['bevorstehend', 'geschrieben']

const aus = <T extends string>(liste: readonly T[], wert: unknown): T | null =>
  liste.includes(wert as T) ? (wert as T) : null

const text = (wert: unknown): string | null => (typeof wert === 'string' && wert.trim() ? wert.trim() : null)

async function loadKlassenarbeitStatus(leadId: string): Promise<KlassenarbeitStatus | null> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('klassenarbeit_status')
      .eq('id', leadId)
      .maybeSingle()
    if (error) return null
    return aus(STATUS, (data as { klassenarbeit_status: unknown } | null)?.klassenarbeit_status)
  } catch {
    return null
  }
}

/**
 * Bericht v4: Note der zuletzt geschriebenen Arbeit (leads.letzte_klassenarbeit_note,
 * Migration aus V4-E). Eigene Abfrage wie loadKlassenarbeitStatus: fehlt die Spalte
 * oder schlägt die Abfrage fehl, null.
 */
async function loadLetzteNote(leadId: string): Promise<number | null> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('letzte_klassenarbeit_note')
      .eq('id', leadId)
      .maybeSingle()
    if (error) return null
    const note = (data as { letzte_klassenarbeit_note: unknown } | null)?.letzte_klassenarbeit_note
    return typeof note === 'number' && note >= 1 && note <= 6 ? note : null
  } catch {
    return null
  }
}

/**
 * @param analysedAt Zeitpunkt der Sitzung — Bezug für „bevorstehend“ aus dem Datum.
 */
export async function loadErstgespraech(
  leadId: string | null,
  analysedAt: string | null,
): Promise<ReportErstgespraech | null> {
  if (!leadId) return null
  try {
    const [{ data, error }, status, letzteNote, klassenarbeiten] = await Promise.all([
      supabase
        .from('leads')
        .select('last_grade, grade_trend, struggling_since, goal, next_exam_date')
        .eq('id', leadId)
        .maybeSingle(),
      loadKlassenarbeitStatus(leadId),
      loadLetzteNote(leadId),
      loadKlassenarbeiten(leadId, analysedAt),
    ])
    if (error || !data) {
      if (error) console.warn('report: erstgespraech lookup failed', error.message)
      return null
    }
    const lead = data as Record<string, unknown>
    const datum = text(lead.next_exam_date)
    const tag = analysedAt ? analysedAt.slice(0, 10) : null
    const ausDatum: KlassenarbeitStatus | null = datum && tag && datum >= tag ? 'bevorstehend' : null
    return {
      note: text(lead.last_grade),
      trend: aus(TRENDS, lead.grade_trend),
      seit: aus(SEIT, lead.struggling_since),
      ziele: text(lead.goal),
      klassenarbeit: status ?? ausDatum,
      klassenarbeitDatum: datum,
      letzteNote,
      klassenarbeiten,
    }
  } catch (e) {
    console.warn('report: erstgespraech lookup failed', e)
    return null
  }
}
