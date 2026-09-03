// Eltern-Report (R1) — Lesezugriff. Read-only gegenüber den Sitzungsdaten.
//
// Quellen (alle bereits per RLS für coach/admin lesbar, kein neuer Grant):
//   lsa_sessions   — item_ids, Fach, Klasse, Status, Zeitpunkte
//   lsa_responses  — correct + duration_ms je Aufgabe (serverseitig von
//                    lsa_submit gesetzt, siehe src/types/report.ts)
//   tasks          — competency_content als Stoffanker/Thema
//   leads          — Rufname (students.lead_id → leads.first_name)
//
// task_solutions wird NICHT angefasst.

import { supabase } from '@/lib/supabase/client'
import { loadErzaehlung } from '@/lib/supabase/lsaReportErzaehlung'
import { loadSkillbefunde } from '@/lib/supabase/lsaReportSkills'
import type {
  LsaSessionListItem,
  LsaSessionState,
  ParentAssessment,
  ReportData,
  ReportFehlbild,
  SupabaseResult,
} from '@/types'

type SessionRow = {
  id: string
  student_id: string
  subject: string
  grade: number
  status: LsaSessionState
  item_ids: string[] | null
  started_at: string | null
  completed_at: string | null
  created_at: string
}

const SESSION_COLS =
  'id, student_id, subject, grade, status, item_ids, started_at, completed_at, created_at'

// Rufname je student_id — über den provisorischen Schüler (students.lead_id).
// students trägt selbst keinen Namen; der Rufname lebt am Lead.
async function loadNames(
  studentIds: string[],
): Promise<Record<string, string | null>> {
  const names: Record<string, string | null> = {}
  if (studentIds.length === 0) return names

  const { data: students } = await supabase
    .from('students')
    .select('id, lead_id')
    .in('id', studentIds)

  const byLead = new Map<string, string>()
  for (const s of students ?? []) {
    if (s.lead_id) byLead.set(s.lead_id as string, s.id as string)
  }
  if (byLead.size === 0) return names

  const { data: leads } = await supabase
    .from('leads')
    .select('id, first_name, full_name')
    .in('id', [...byLead.keys()])

  for (const l of leads ?? []) {
    const studentId = byLead.get(l.id as string)
    if (!studentId) continue
    names[studentId] =
      (l.first_name as string | null) ?? (l.full_name as string | null) ?? null
  }
  return names
}

// Die heutigen Analyse-Sitzungen — Grundlage des Fertig-Signals.
// „fertig" = status 'completed' (lsa_finish setzt Status + completed_at).
export async function listTodaysLsaSessions(): Promise<
  SupabaseResult<LsaSessionListItem[]>
> {
  try {
    const since = new Date()
    since.setHours(0, 0, 0, 0)

    const { data, error } = await supabase
      .from('lsa_sessions')
      .select(SESSION_COLS)
      .gte('created_at', since.toISOString())
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }

    const rows = (data ?? []) as SessionRow[]
    if (rows.length === 0) return { data: [], error: null }

    const names = await loadNames(rows.map((r) => r.student_id))

    // Bearbeitungsstand je Session: eine Abfrage für alle.
    const { data: responses, error: rErr } = await supabase
      .from('lsa_responses')
      .select('session_id')
      .in(
        'session_id',
        rows.map((r) => r.id),
      )
    if (rErr) return { data: null, error: rErr.message }

    const answered = new Map<string, number>()
    for (const r of responses ?? []) {
      const key = r.session_id as string
      answered.set(key, (answered.get(key) ?? 0) + 1)
    }

    return {
      data: rows.map((r) => ({
        session_id: r.id,
        first_name: names[r.student_id] ?? null,
        grade: r.grade,
        subject: r.subject,
        status: r.status,
        started_at: r.started_at,
        completed_at: r.completed_at,
        answered: answered.get(r.id) ?? 0,
        planned: r.item_ids?.length ?? 0,
      })),
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Analysen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Die Eltern-Einschätzung vom Lead (source='parent'). Fehlt sie, ist der
// Abschnitt im Report auszublenden — deshalb null statt leerem Objekt.
async function loadParentAssessment(
  studentId: string,
): Promise<ParentAssessment | null> {
  const { data: student } = await supabase
    .from('students')
    .select('lead_id')
    .eq('id', studentId)
    .maybeSingle()
  const leadId = student?.lead_id as string | null | undefined
  if (!leadId) return null

  const { data } = await supabase
    .from('lead_assessments')
    .select('note, weak_topics')
    .eq('lead_id', leadId)
    .eq('source', 'parent')
    .maybeSingle()
  if (!data) return null

  const note = (data.note as string | null) ?? null
  const weakTopics = (data.weak_topics as string[] | null) ?? []
  if (!note?.trim() && weakTopics.length === 0) return null
  return { note, weakTopics }
}

/**
 * Die Fehlbilder einer Sitzung, UNGEFILTERT.
 *
 * Die Schwelle greift erst NACH der Bündelung je Familie
 * (src/lib/reportFehlbilder.ts) — vorher zu filtern verliert genau den Fall,
 * für den die Bündelung gebaut wurde: zwei Slugs derselben Familie, je unter
 * der Schwelle, zusammen darüber.
 */
async function loadFehlbilder(sessionId: string): Promise<ReportFehlbild[]> {
  const { data, error } = await supabase.rpc('lsa_fehlbild_auswertung', {
    p_session_id: sessionId,
  })
  if (error || !data) return []

  type Row = {
    fehlbild_slug: string
    familie: string | null
    familie_elterntext: string | null
    anzahl: number
    aufgaben: number
    skills: string[] | null
    skill_uebergreifend: boolean
    einstufung: string
  }

  return (data as Row[]).map((r) => ({
    slug: r.fehlbild_slug,
    familie: r.familie,
    familieElterntext: r.familie_elterntext?.trim() ? r.familie_elterntext : null,
    anzahl: r.anzahl,
    aufgaben: r.aufgaben,
    skills: r.skills ?? [],
    skillUebergreifend: r.skill_uebergreifend,
    einstufung: r.einstufung === 'befund' ? ('befund' as const) : ('beobachtung' as const),
  }))
}

/**
 * Das Thema, an dem die Analyse angesetzt hat.
 *
 * `leads` trägt KEINE Spalte `leitthema` — geprüft am Schema, nicht vermutet.
 * `next_exam_topic` ist das, was belegt ist; der Report formuliert entsprechend
 * vorsichtiger („steht als nächstes Thema an", nicht „fällt schwer").
 *
 * Bei Leads aus dem zweistufigen Wizard stammt der Wert aus einer Themenauswahl
 * im Erstgespräch und steht als `leads.current_topic_cluster_id` auf einem
 * Cluster in `skill_clusters`. Bei älteren Leads gibt es diese Auswahl nicht —
 * dort ist der Freitext aus `next_exam_topic` weiterhin die einzige Quelle, und
 * er bleibt auch der Rückfall, wenn sich ein Cluster nicht auflösen lässt.
 */
export async function loadNaechstesThema(studentId: string): Promise<string | null> {
  const { data: student } = await supabase
    .from('students')
    .select('lead_id')
    .eq('id', studentId)
    .maybeSingle()
  const leadId = (student as { lead_id: string | null } | null)?.lead_id
  if (!leadId) return null

  const { data: lead } = await supabase
    .from('leads')
    .select('next_exam_topic, current_topic_cluster_id')
    .eq('id', leadId)
    .maybeSingle()
  const leadRow = lead as {
    next_exam_topic: string | null
    current_topic_cluster_id: string | null
  } | null
  const freitext = leadRow?.next_exam_topic?.trim() || null
  const clusterId = leadRow?.current_topic_cluster_id
  if (!clusterId) return freitext

  // Zweiter Roundtrip statt eingebettetem Select über den Fremdschlüssel: die
  // Funktion läuft einmal pro Report, und der eigene Treffer ist eindeutig.
  const { data: cluster } = await supabase
    .from('skill_clusters')
    .select('name')
    .eq('id', clusterId)
    .maybeSingle()
  const clusterName = (cluster as { name: string | null } | null)?.name?.trim() || null

  // Kein auflösbarer Cluster (gelöscht, nicht lesbar, leerer Name) heißt nicht
  // „kein Thema" — dann trägt der Freitext weiter.
  return clusterName ?? freitext
}

export async function getReportData(
  sessionId: string,
): Promise<SupabaseResult<ReportData>> {
  try {
    const { data: session, error } = await supabase
      .from('lsa_sessions')
      .select(SESSION_COLS)
      .eq('id', sessionId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    if (!session) return { data: null, error: 'Analyse nicht gefunden' }

    const row = session as SessionRow
    const { data: responses, error: rErr } = await supabase
      .from('lsa_responses')
      .select('task_id, correct, duration_ms')
      .eq('session_id', sessionId)
    if (rErr) return { data: null, error: rErr.message }

    // AUFGABEN, nicht Antwortzeilen: zwei Teilaufgaben desselben Items sind
    // eine Aufgabe. Dieselbe Zaehlweise nutzt lsa_fehlbild_auswertung.
    const aufgaben = new Set((responses ?? []).map((r) => r.task_id as string)).size

    const names = await loadNames([row.student_id])

    const parentAssessment = await loadParentAssessment(row.student_id)
    const fehlbilder = await loadFehlbilder(row.id)

    return {
      data: {
        sessionId: row.id,
        firstName: names[row.student_id] ?? null,
        grade: row.grade,
        subject: row.subject,
        status: row.status,
        analysedAt: row.completed_at ?? row.started_at ?? row.created_at,
        aufgaben,
        naechstesThema: await loadNaechstesThema(row.student_id),
        parentAssessment,
        skillbefunde: await loadSkillbefunde(sessionId),
        fehlbilder,
        erzaehlung: await loadErzaehlung(
          sessionId,
          parentAssessment?.weakTopics ?? [],
          fehlbilder,
        ),
      },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Report konnte nicht geladen werden'
    return { data: null, error: message }
  }
}
