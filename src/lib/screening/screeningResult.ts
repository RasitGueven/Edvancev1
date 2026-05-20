// Reiner Parser/Guard für screening_tests.result_summary (Form aus
// screeningRuntime.finishScreeningTest: { kind:'adaptive', answered,
// clusters: ClusterSummary[] }). Kein Supabase, kein React — defensiv:
// null / altes / nicht-adaptives / kaputtes Summary → null statt Crash.
// displayLevel-Mapping liegt hier, damit zentral justier-/testbar.

export type ParsedClusterResult = {
  clusterId: string
  answered: number
  correct: number
  pending: number
  estimatedLevel: 0 | 1 | 2 | 3
  reachedAfb: 'I' | 'II' | 'III' | null
  mastery: number // 0..1
  displayLevel: number // 1..10 (für MasteryBar)
}

export type ParsedScreeningResult = {
  answered: number
  clusters: ParsedClusterResult[]
  overallAnswered: number
  overallCorrect: number
  overallPending: number
  overallPct: number // 0..100
}

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}

function num(v: unknown): number | null {
  return typeof v === 'number' && Number.isFinite(v) ? v : null
}

function clamp(v: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, v))
}

function toEstimatedLevel(v: unknown): 0 | 1 | 2 | 3 {
  const n = num(v) ?? 0
  const r = Math.round(clamp(n, 0, 3))
  return (r === 1 || r === 2 || r === 3 ? r : 0) as 0 | 1 | 2 | 3
}

function toAfb(v: unknown): 'I' | 'II' | 'III' | null {
  return v === 'I' || v === 'II' || v === 'III' ? v : null
}

function parseCluster(raw: unknown): ParsedClusterResult | null {
  if (!isObj(raw) || typeof raw.clusterId !== 'string' || raw.clusterId === '') {
    return null
  }
  const answered = num(raw.answered) ?? 0
  const correct = num(raw.correct) ?? 0
  const pending = num(raw.pending) ?? 0
  const estimatedLevel = toEstimatedLevel(raw.estimatedLevel)
  const reachedAfb =
    toAfb(raw.reachedAfb) ??
    (estimatedLevel === 1 ? 'I' : estimatedLevel === 2 ? 'II' : estimatedLevel === 3 ? 'III' : null)
  const mastery = clamp(num(raw.mastery) ?? 0, 0, 1)
  const displayLevel = clamp(
    Math.round(estimatedLevel * 2.5 + mastery * 2.5),
    1,
    10,
  )
  return {
    clusterId: raw.clusterId,
    answered: Math.max(0, Math.round(answered)),
    correct: Math.max(0, Math.round(correct)),
    pending: Math.max(0, Math.round(pending)),
    estimatedLevel,
    reachedAfb,
    mastery,
    displayLevel,
  }
}

export function parseScreeningResult(
  summary: Record<string, unknown> | null,
): ParsedScreeningResult | null {
  if (!summary || summary.kind !== 'adaptive' || !Array.isArray(summary.clusters)) {
    return null
  }
  const clusters: ParsedClusterResult[] = []
  for (const c of summary.clusters) {
    const parsed = parseCluster(c)
    if (parsed) clusters.push(parsed)
  }
  const overallAnswered = clusters.reduce((s, c) => s + c.answered, 0)
  const overallCorrect = clusters.reduce((s, c) => s + c.correct, 0)
  const overallPending = clusters.reduce((s, c) => s + c.pending, 0)
  const decided = overallAnswered - overallPending
  return {
    answered: num(summary.answered) ?? overallAnswered,
    clusters,
    overallAnswered,
    overallCorrect,
    overallPending,
    overallPct: decided === 0 ? 0 : Math.round((overallCorrect / decided) * 100),
  }
}
