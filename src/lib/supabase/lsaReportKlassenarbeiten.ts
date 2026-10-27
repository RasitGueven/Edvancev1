// L5 Teil C — Lesepfad für die Mathearbeiten eines Kindes (ka_folge_lead): eigene Angaben aus Erstgespräch,
// Check-in und Admin, dazu die gültige Folge der Schule und Klasse. Nur Admin (wie leads); beim Coach, bei Fehler
// oder ohne die Funktion (Migration 20261027081403 noch nicht eingespielt) eine leere Liste: Dann gilt die Folge als
// unbekannt, und der Bericht zeigt Themen ohne Nummer.

import { supabase } from '@/lib/supabase/client'
import { schuljahrVon } from '@/lib/report/elternbericht/kaFolge'
import type { KlassenarbeitStatus, ReportKlassenarbeit } from '@/types'

type Zeile = {
  nr: number | null
  thema_keys: string[] | null
  datum: string | null
  status: string | null
  note: number | null
  herkunft: string
}

const STATUS: readonly KlassenarbeitStatus[] = ['bevorstehend', 'geschrieben']

/** @param analysedAt Zeitpunkt der Sitzung — bestimmt das Schuljahr. */
export async function loadKlassenarbeiten(leadId: string, analysedAt: string | null): Promise<ReportKlassenarbeit[]> {
  const tag = (analysedAt ?? new Date().toISOString()).slice(0, 10)
  try {
    const { data, error } = await supabase.rpc('ka_folge_lead', { p_lead_id: leadId, p_schuljahr: schuljahrVon(tag) })
    if (error) {
      console.warn('report: ka_folge_lead failed', error.message)
      return []
    }
    return ((data ?? []) as Zeile[]).map((z) => ({
      nr: typeof z.nr === 'number' ? z.nr : null,
      themaKeys: z.thema_keys ?? [],
      datum: z.datum,
      status: STATUS.includes(z.status as KlassenarbeitStatus) ? (z.status as KlassenarbeitStatus) : null,
      note: typeof z.note === 'number' && z.note >= 1 && z.note <= 6 ? z.note : null,
      herkunft: z.herkunft === 'schule' ? 'schule' : 'eigen',
    }))
  } catch (e) {
    console.warn('report: ka_folge_lead failed', e)
    return []
  }
}
