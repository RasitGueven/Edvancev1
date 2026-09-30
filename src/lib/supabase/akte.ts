// Schuelerakte (S2) — Lesezugriff und Stammdaten.
//
// Quellen sind ausschliesslich die S1-Schnittstellen: board_schueler() und
// einheiten_stand() (SECURITY DEFINER, Rechte in der DB), die View
// schuelerakten, eltern_reports (RLS: Coach nur aktive Akten). Das Frontend
// rechnet keinen Einheiten-Stand, keinen Zustand und keine Ampel.

import { supabase } from '@/lib/supabase/client'
import type {
  AkteSession,
  AttendanceStatus,
  BoardSchueler,
  EinheitenStand,
  ElternReport,
  ElternReportArt,
  Schuelerakte,
  SupabaseResult,
} from '@/types'

const fehlertext = (err: unknown, fallback: string): string =>
  err instanceof Error ? err.message : fallback

/** Namen zu Profil-IDs (Admins und Coaches sind fuer beide Rollen lesbar). */
export async function profilNamen(ids: (string | null)[]): Promise<Map<string, string | null>> {
  const eindeutig = [...new Set(ids.filter((i): i is string => Boolean(i)))]
  const namen = new Map<string, string | null>()
  if (eindeutig.length === 0) return namen
  const { data } = await supabase.from('profiles').select('id, full_name').in('id', eindeutig)
  for (const p of data ?? []) namen.set(p.id as string, (p.full_name as string | null) ?? null)
  return namen
}

export async function listBoardSchueler(): Promise<SupabaseResult<BoardSchueler[]>> {
  try {
    const { data, error } = await supabase.rpc('board_schueler')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as BoardSchueler[], error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'board_schueler failed') }
  }
}

/** Die Akte; null, wenn sie fuer die Rolle nicht sichtbar ist (Coach: ruhend). */
export async function getSchuelerakte(studentId: string): Promise<SupabaseResult<Schuelerakte | null>> {
  try {
    const { data, error } = await supabase
      .from('schuelerakten')
      .select('*')
      .eq('student_id', studentId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as Schuelerakte | null) ?? null, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'schuelerakten failed') }
  }
}

export async function getEinheitenStand(studentId: string): Promise<SupabaseResult<EinheitenStand | null>> {
  try {
    const { data, error } = await supabase.rpc('einheiten_stand', { p_student_id: studentId })
    if (error) return { data: null, error: error.message }
    const zeile = (Array.isArray(data) ? data[0] : data) as EinheitenStand | undefined
    return { data: zeile ?? null, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'einheiten_stand failed') }
  }
}

/**
 * Alle Sessions des Kindes seit Beginn der Akte, neueste zuerst — ueber die
 * RPC akte_sessions (S2b): Admin immer, Coach bei aktiver Akte auch Sessions
 * anderer Coaches. Direktes Lesen von session_students zeigte Coaches nur
 * ihre eigenen Sessions.
 */
export async function listAkteSessions(studentId: string): Promise<SupabaseResult<AkteSession[]>> {
  try {
    const { data, error } = await supabase.rpc('akte_sessions', { p_student_id: studentId })
    if (error) return { data: null, error: error.message }
    type Zeile = {
      session_id: string
      scheduled_at: string
      coach_name: string | null
      attendance: AttendanceStatus
    }
    return {
      data: ((data ?? []) as Zeile[]).map((z) => ({
        session_id: z.session_id,
        scheduled_at: z.scheduled_at,
        coach_name: z.coach_name,
        attendance: z.attendance,
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'akte_sessions failed') }
  }
}

/** Anzahl aktiver Akten (schuelerakten, zustand = aktiv) — Kachel "Aktive Schueler". */
export async function zaehleAktiveAkten(): Promise<SupabaseResult<number>> {
  try {
    const { count, error } = await supabase
      .from('schuelerakten')
      .select('student_id', { count: 'exact', head: true })
      .eq('zustand', 'aktiv')
    if (error) return { data: null, error: error.message }
    return { data: count ?? 0, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'schuelerakten count failed') }
  }
}

export async function listFaecher(studentId: string): Promise<SupabaseResult<string[]>> {
  try {
    const { data, error } = await supabase
      .from('student_subjects')
      .select('subjects(name)')
      .eq('student_id', studentId)
    if (error) return { data: null, error: error.message }
    type Zeile = { subjects: { name: string } | null }
    const namen = ((data ?? []) as unknown as Zeile[])
      .map((z) => z.subjects?.name)
      .filter((n): n is string => Boolean(n))
      .sort((a, b) => a.localeCompare(b))
    return { data: namen, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'faecher failed') }
  }
}

/**
 * Stammdaten ueber die RPC akte_stammdaten_aendern (S2b, nur Admin, sonst 42501):
 * Name (profiles.full_name), Klasse und Schule in einem Aufruf, protokolliert.
 */
export async function stammdatenSpeichern(
  studentId: string,
  werte: { name: string; klasse: number | null; schule_id: string | null },
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('akte_stammdaten_aendern', {
      p_student_id: studentId,
      p_name: werte.name,
      p_klasse: werte.klasse,
      p_schule_id: werte.schule_id,
    })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'akte_stammdaten_aendern failed') }
  }
}

/** Versendete Reports (eltern_reports), neueste zuerst. */
export async function listElternReports(studentId: string): Promise<SupabaseResult<ElternReport[]>> {
  try {
    const { data, error } = await supabase
      .from('eltern_reports')
      .select('id, nr, art, berichtsmonat, kernaussagen, freigegeben_von, versendet_am, pdf_pfad')
      .eq('student_id', studentId)
      .order('nr', { ascending: false })
    if (error) return { data: null, error: error.message }
    type Zeile = Omit<ElternReport, 'freigegeben_von_name'> & { freigegeben_von: string | null; art: ElternReportArt }
    const zeilen = (data ?? []) as Zeile[]
    const namen = await profilNamen(zeilen.map((z) => z.freigegeben_von))
    return {
      data: zeilen.map(({ freigegeben_von, ...rest }) => ({
        ...rest,
        freigegeben_von_name: freigegeben_von ? (namen.get(freigegeben_von) ?? null) : null,
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'eltern_reports failed') }
  }
}

// Bucket fuer versendete Report-PDFs: eltern-reports (privat, Frankfurt),
// Entscheidung Rasit 30.09.2026. Angelegt wird er vom Feature Eltern-Reports,
// nicht hier. Einzige Stelle, an der der Name steht.
export const REPORT_BUCKET = 'eltern-reports'

export async function reportLink(pdfPfad: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.storage.from(REPORT_BUCKET).createSignedUrl(pdfPfad, 300)
    if (error || !data) return { data: null, error: error?.message ?? 'signed url failed' }
    return { data: data.signedUrl, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'signed url failed') }
  }
}
