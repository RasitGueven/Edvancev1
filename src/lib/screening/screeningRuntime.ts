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
import { getStudentByProfile } from '@/lib/supabase/students'
import { summarizeLogs, type AdaptiveAnswerLog } from '@/lib/screening/adaptive'
import type { ScreeningItem, SupabaseResult } from '@/types'

export const SCREENING_SUBJECT = 'Mathematik'

// Nur freigegebene Items. Engine degradiert robust bei leerem Ergebnis
// (Aufrufer zeigt dann einen freundlichen Leerzustand).
export async function loadActiveScreeningPool(): Promise<
  SupabaseResult<ScreeningItem[]>
> {
  return listScreeningItems({ active: true })
}

export type McPayload = { type: 'mc'; options: string[]; correct_index?: number }

export function isMcPayload(p: unknown): p is McPayload {
  return (
    typeof p === 'object' &&
    p !== null &&
    Array.isArray((p as { options?: unknown }).options)
  )
}

// Rohwert aus der UI → Antwort-Objekt für gradeScreeningAnswer.
//  - MC / mc_index:   Index → { index }
//  - sonst (numeric / normalized / Fallback): Freitext → { value }
export function buildScreeningAnswer(
  item: ScreeningItem,
  raw: { mcIndex: number | null; text: string },
): unknown {
  if (item.check_type === 'mc_index') {
    return { index: raw.mcIndex }
  }
  return { value: raw.text.trim() }
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
