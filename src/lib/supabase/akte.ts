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

/** Sessions des Kindes, neueste zuerst (RLS: Coach sieht nur eigene Sessions). */
export async function listAkteSessions(studentId: string): Promise<SupabaseResult<AkteSession[]>> {
  try {
    const { data, error } = await supabase
      .from('session_students')
      .select('attendance, coaching_sessions!inner(id, scheduled_at, coach_id)')
      .eq('student_id', studentId)
    if (error) return { data: null, error: error.message }
    type Zeile = {
      attendance: AttendanceStatus
      coaching_sessions: { id: string; scheduled_at: string; coach_id: string | null }
    }
    const zeilen = (data ?? []) as unknown as Zeile[]
    const namen = await profilNamen(zeilen.map((z) => z.coaching_sessions.coach_id))
    const sessions = zeilen
      .map((z) => ({
        session_id: z.coaching_sessions.id,
        scheduled_at: z.coaching_sessions.scheduled_at,
        coach_name: namen.get(z.coaching_sessions.coach_id ?? '') ?? null,
        attendance: z.attendance,
      }))
      .sort((a, b) => b.scheduled_at.localeCompare(a.scheduled_at))
    return { data: sessions, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'sessions failed') }
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

/** Stammdaten (nur Admin, RLS students_admin_all): Klasse und Schule. */
export async function stammdatenSpeichern(
  studentId: string,
  werte: { class_level: number | null; schule_id: string | null },
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.from('students').update(werte).eq('id', studentId)
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'stammdaten failed') }
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

// Bucket fuer versendete Report-PDFs. Heute ist pdf_pfad ueberall NULL; das
// Feature Eltern-Reports legt Bucket und Pfade an (Annahme, im PR vermerkt).
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
