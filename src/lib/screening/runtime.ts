// Baut die echte Screening-/Diagnose-Aufgabenliste: ruft den realen
// Generator (liest tasks mit is_diagnostic=true) und reichert jeden
// Treffer mit dem echten Aufgaben-Content an. Ersetzt mockDiagnosisTasks.

import { generateDiagnosticTest } from '@/lib/diagnostic/generator'
import { getTaskById } from '@/lib/supabase/tasks'
import type { DiagnosticTest, OnboardingData, RunTask } from '@/types'

export type BuildRunArgs = {
  grade: number
  subject: OnboardingData['subject']
}

// DiagnosticTask -> RunTask (echter Content via getTaskById).
async function enrich(dt: DiagnosticTest['tasks'][number]): Promise<RunTask> {
  const { data: task } = await getTaskById(dt.task_id)
  return {
    id: dt.task_id,
    skill_id: dt.topic_id,
    skill_cluster: dt.topic_label,
    question: task?.question ?? '(Aufgabentext fehlt)',
    solution: task?.solution ?? '',
    common_errors: task?.common_errors ?? dt.typical_errors.join('\n'),
    coach_hint: dt.coach_hint,
    estimated_minutes: dt.estimated_minutes,
  }
}

export async function buildRunTasks(
  args: BuildRunArgs,
): Promise<{ tasks: RunTask[]; test: DiagnosticTest | null; warnings: string[] }> {
  const onboarding: OnboardingData = {
    student_id: 'screening-temp',
    grade: args.grade,
    school_type: 'GYMNASIUM',
    subject: args.subject,
    goal: 'GENERAL',
  }
  try {
    const { test, warnings } = await generateDiagnosticTest(onboarding)
    const tasks: RunTask[] = []
    for (const dt of test.tasks) tasks.push(await enrich(dt))
    return { tasks, test, warnings }
  } catch (err) {
    const msg =
      err instanceof Error ? err.message : 'Diagnosetest konnte nicht erzeugt werden'
    return { tasks: [], test: null, warnings: [msg] }
  }
}

// Resume: aus dem persistierten generated_test (jsonb) die RunTasks
// identisch rekonstruieren – KEIN erneuter (nicht-deterministischer) Generator-Lauf.
export async function rebuildRunTasks(
  test: DiagnosticTest,
): Promise<RunTask[]> {
  const tasks: RunTask[] = []
  for (const dt of test.tasks) tasks.push(await enrich(dt))
  return tasks
}
