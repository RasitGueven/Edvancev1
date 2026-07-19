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
import type {
  LsaSessionListItem,
  LsaSessionState,
  ParentAssessment,
  ReportData,
  ReportTopic,
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

// Themen-Belege: geplante Items je Thema gegen die tatsächlichen Antworten.
// „ausgelassen" = zugelost, aber nicht beantwortet.
function buildTopics(
  itemIds: string[],
  topicByTask: Map<string, string>,
  responses: { task_id: string; correct: boolean | null; duration_ms: number | null }[],
): ReportTopic[] {
  const UNKNOWN = 'Ohne Themenzuordnung'
  const acc = new Map<
    string,
    { planned: number; answered: number; correct: number; durations: number[] }
  >()
  const ensure = (topic: string) => {
    let e = acc.get(topic)
    if (!e) {
      e = { planned: 0, answered: 0, correct: 0, durations: [] }
      acc.set(topic, e)
    }
    return e
  }

  for (const id of itemIds) ensure(topicByTask.get(id) ?? UNKNOWN).planned += 1

  for (const r of responses) {
    const e = ensure(topicByTask.get(r.task_id) ?? UNKNOWN)
    e.answered += 1
    if (r.correct) e.correct += 1
    if (typeof r.duration_ms === 'number' && r.duration_ms > 0) {
      e.durations.push(r.duration_ms)
    }
  }

  return [...acc.entries()]
    .map(([topic, e]) => ({
      topic,
      planned: e.planned,
      answered: e.answered,
      skipped: Math.max(0, e.planned - e.answered),
      correct: e.correct,
      avgDurationMs:
        e.durations.length > 0
          ? Math.round(e.durations.reduce((a, b) => a + b, 0) / e.durations.length)
          : null,
    }))
    .sort((a, b) => a.topic.localeCompare(b.topic, 'de'))
}

// Der vollständige Report-Datensatz einer Session.
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
    const itemIds = row.item_ids ?? []

    const { data: responses, error: rErr } = await supabase
      .from('lsa_responses')
      .select('task_id, correct, duration_ms')
      .eq('session_id', sessionId)
    if (rErr) return { data: null, error: rErr.message }

    // competency_content ist der Stoffanker, nach dem auch lsa_finish
    // aggregiert — gleiche Achse, damit Report und Auswertung nicht driften.
    const topicByTask = new Map<string, string>()
    if (itemIds.length > 0) {
      const { data: tasks, error: tErr } = await supabase
        .from('tasks')
        .select('id, competency_content')
        .in('id', itemIds)
      if (tErr) return { data: null, error: tErr.message }
      for (const t of tasks ?? []) {
        const label = (t.competency_content as string | null)?.trim()
        if (label) topicByTask.set(t.id as string, label)
      }
    }

    const names = await loadNames([row.student_id])

    return {
      data: {
        sessionId: row.id,
        firstName: names[row.student_id] ?? null,
        grade: row.grade,
        subject: row.subject,
        status: row.status,
        analysedAt: row.completed_at ?? row.started_at ?? row.created_at,
        topics: buildTopics(
          itemIds,
          topicByTask,
          (responses ?? []) as {
            task_id: string
            correct: boolean | null
            duration_ms: number | null
          }[],
        ),
        parentAssessment: await loadParentAssessment(row.student_id),
      },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Report konnte nicht geladen werden'
    return { data: null, error: message }
  }
}
