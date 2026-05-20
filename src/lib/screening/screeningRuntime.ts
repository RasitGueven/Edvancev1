// Glue zwischen DB-Item-Bank und reinem adaptiven Controller.
// Lädt den freigegebenen (active) Pool und formt UI-Rohwerte in die
// Antwort-Objekte, die der Auto-Grader erwartet. Kein Zustand hier —
// der Controller (adaptive.ts) hält die Sitzung.

import {
  listScreeningItems,
  recordScreeningItemResult,
  getResultsForTest,
} from '@/lib/supabase/screeningItems'
import {
  createScreeningTest,
  getActiveScreeningTest,
  completeScreeningTest,
} from '@/lib/supabase/screening'
import { getStudentByProfile, getStudent } from '@/lib/supabase/students'
import { listFocusAreasForStudent } from '@/lib/supabase/studentFocusAreas'
import {
  summarizeLogs,
  type AdaptiveAnswerLog,
  type AdaptiveConfig,
} from '@/lib/screening/adaptive'
import type { ScreeningItem, SupabaseResult } from '@/types'

export const SCREENING_SUBJECT = 'Mathematik'

// Nur freigegebene Items. Engine degradiert robust bei leerem Ergebnis
// (Aufrufer zeigt dann einen freundlichen Leerzustand). Optional auf die
// Klassenstufe einschränken — VERA-Items kommen alle mit class_level=8,
// Edvance-Items aktuell auch klassen-spezifisch geseedet.
export async function loadActiveScreeningPool(opts?: {
  classLevel?: number
}): Promise<SupabaseResult<ScreeningItem[]>> {
  return listScreeningItems({ active: true, classLevel: opts?.classLevel })
}

// Adaptive-Config aus Schüler-Stammdaten (Klassenstufe) und Coach-Schwer-
// punkten (student_focus_areas) ableiten. Ergebnis ist direkt in
// `createAdaptiveSession` einsetzbar.
export async function buildAdaptiveConfigForStudent(
  studentId: string,
): Promise<{ classLevel: number | null; config: AdaptiveConfig }> {
  const [{ data: student }, { data: foci }] = await Promise.all([
    getStudent(studentId),
    listFocusAreasForStudent(studentId, { active: true }),
  ])
  const weightedClusterIds = (foci ?? []).map((f) => f.cluster_id)
  return {
    classLevel: student?.class_level ?? null,
    config: { weightedClusterIds },
  }
}

export type McPayload = { type: 'mc'; options: string[]; correct_index?: number }

export function isMcPayload(p: unknown): p is McPayload {
  return (
    typeof p === 'object' &&
    p !== null &&
    Array.isArray((p as { options?: unknown }).options)
  )
}

export type RawAnswer =
  | { kind: 'mc'; index: number | null }
  | { kind: 'numeric'; value: string }
  | { kind: 'open'; text: string }
  | { kind: 'multistep'; steps: Record<string, string> }

// Rohwert aus der UI → Antwort-Objekt für gradeScreeningAnswer / DB.
// Shape pro input_type:
//   MC           → { index }
//   NUMERIC      → { value }
//   OPEN/manual  → { text }
//   MULTI-STEP   → { steps: { '1a': '…', '1b': '…' } }
export function buildScreeningAnswer(item: ScreeningItem, raw: RawAnswer): unknown {
  if (raw.kind === 'mc') return { index: raw.index }
  if (raw.kind === 'numeric') return { value: raw.value.trim() }
  if (raw.kind === 'multistep') {
    const steps: Record<string, string> = {}
    for (const [k, v] of Object.entries(raw.steps)) steps[k] = v.trim()
    return { steps }
  }
  // open: für check_type 'numeric'/'normalized' nimmt der Grader value, für
  // 'manual' bevorzugt er text — wir liefern beides, damit beides passt.
  const t = raw.text.trim()
  if (item.check_type === 'numeric' || item.check_type === 'normalized') {
    return { value: t }
  }
  return { text: t }
}

// Schüler-Row zum eingeloggten Profil (kann fehlen → Coach/Admin testen
// ohne Persistenz, Lauf bleibt trotzdem nutzbar).
export async function resolveScreeningStudentId(
  profileId: string,
): Promise<string | null> {
  const { data } = await getStudentByProfile(profileId)
  return data?.id ?? null
}

// Laufenden Test fortsetzen oder neuen anlegen. Adaptive Läufe haben
// keinen vorab generierten Test → minimaler generated_test-Marker; die
// echte Auswertung lebt in result_summary + screening_item_results.
export async function startOrResumeScreeningTest(
  studentId: string,
): Promise<SupabaseResult<string>> {
  const active = await getActiveScreeningTest(studentId, SCREENING_SUBJECT)
  if (active.error) return { data: null, error: active.error }
  if (active.data) return { data: active.data.id, error: null }

  const created = await createScreeningTest({
    student_id: studentId,
    subject: SCREENING_SUBJECT,
    estimated_total_minutes: 20,
    generated_test: {
      student_id: studentId,
      subject: SCREENING_SUBJECT,
      grade: 8,
      generated_at: new Date().toISOString(),
      estimated_total_minutes: 20,
      coverage: [],
      tasks: [],
    },
  })
  if (created.error || !created.data) {
    return { data: null, error: created.error ?? 'Test konnte nicht starten' }
  }
  return { data: created.data.id, error: null }
}

// Einzelne (auto-bewertete) Antwort append-only persistieren.
export async function persistScreeningAnswer(
  screeningTestId: string,
  log: AdaptiveAnswerLog,
  answer: unknown,
): Promise<void> {
  await recordScreeningItemResult({
    screening_test_id: screeningTestId,
    screening_item_id: log.itemId,
    cluster_id: log.clusterId,
    level: log.level,
    correct: log.correct,
    answer,
    duration_ms: log.durationMs,
  })
}

// Abschluss: result_summary aus ALLEN persistierten Ergebnissen des Tests
// aggregieren (Server-Wahrheit, resume-fest) und Test schließen.
export async function finishScreeningTest(
  screeningTestId: string,
): Promise<void> {
  const { data } = await getResultsForTest(screeningTestId)
  const logs: AdaptiveAnswerLog[] = (data ?? []).map((r) => ({
    itemId: r.screening_item_id,
    clusterId: r.cluster_id,
    level: r.level,
    correct: r.correct,
    durationMs: r.duration_ms ?? 0,
  }))
  const clusters = summarizeLogs(logs)
  await completeScreeningTest(screeningTestId, {
    kind: 'adaptive',
    answered: logs.length,
    clusters,
  })
}
