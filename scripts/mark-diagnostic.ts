// Heuristik-Script: ordnet existing Tasks ihren Mikroskills zu
// (per Keyword-Match auf title + question), setzt is_diagnostic=true und
// rät einen sinnvollen input_type. Idempotent.
//
// Nutzung:
//   npm run mark:diagnostic
// Manuell:
//   npx tsx --env-file=.env scripts/mark-diagnostic.ts
//
// Voraussetzung:
//   migration 005 ausgefuehrt + seed:taxonomy gelaufen
//
// Pro Mikroskill werden HOECHSTENS DIAGNOSTIC_PER_MICROSKILL Tasks als
// diagnostisch markiert (sonst gilt eh die ganze Sammlung als Diagnose-Pool).

import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const DIAGNOSTIC_PER_MICROSKILL = 3

// Mikroskill-Code → Liste von Keywords (lowercase) die im Task-Titel oder
// -Question vorkommen muessen. Reihenfolge zaehlt: spezifischere Skills
// (z.B. "lineare funktion") werden vor allgemeineren ("funktion") geprueft.
const MICROSKILL_KEYWORDS: Record<string, string[]> = {
  // Geometrie & Messen (spezifische Begriffe zuerst)
  'M8.GM.03': ['pythagoras', 'hypotenuse', 'kathete'],
  'M8.GM.02': ['volumen', 'prisma', 'zylinder', 'oberflaeche', 'oberfläche'],
  'M8.GM.01': ['flaeche', 'fläche', 'rechteck', 'parallelogramm', 'trapez', 'dreieck'],
  // Algebra & Funktionen
  'M8.AF.04': ['textaufgabe in lineare', 'sachaufgabe gleichung'],
  'M8.AF.03': ['lineare funktion', 'steigung', 'y-achsenabschnitt', 'funktionsgraph'],
  'M8.AF.02': ['lineare gleichung', 'gleichung lösen', 'gleichung loesen', 'aequivalenzumformung'],
  'M8.AF.01': ['term', 'distributivgesetz', 'klammer auflöse', 'klammer aufloese', 'vereinfach'],
  // Daten & Zufall
  'M8.DZ.03': ['wahrscheinlichkeit', 'laplace', 'zufall', 'ereignis'],
  'M8.DZ.02': ['mittelwert', 'median', 'spannweite', 'arithmetisches mittel'],
  'M8.DZ.01': ['diagramm', 'saeulendiagramm', 'säulendiagramm', 'kreisdiagramm', 'liniendiagramm'],
  // Sachrechnen & Modellieren
  'M8.SM.03': ['anwendungsaufgabe', 'mehrschrittig', 'sachaufgabe'],
  'M8.SM.02': ['tarif', 'kostenmodell', 'kosten vergleichen'],
  'M8.SM.01': ['dreisatz', 'direkt proportional', 'proportionalitaet', 'proportionalität'],
  // Zahl & Rechnen
  'M8.ZR.03': ['zins', 'jahreszins', 'monatszins', 'tageszins'],
  'M8.ZR.02': ['prozentwert', 'grundwert', 'prozentsatz', 'prozent'],
  'M8.ZR.01': ['bruch', 'bruchrechnung', 'gemischte zahl'],
  'M8.ZR.04': ['vorzeichen', 'negative zahl', 'rationale zahl', 'ganze zahl'],
}

// Input-Type Heuristik: Stichworte → Type
// Kanonischer input_type-Enum (042): STEPS→FREE_TEXT, DRAW→COORDINATE.
const INPUT_TYPE_RULES: { type: 'MC' | 'FREE_TEXT' | 'MATCHING' | 'COORDINATE'; keywords: string[] }[] = [
  { type: 'MATCHING', keywords: ['ordne zu', 'verbinde', 'ordne ... zu', 'matching'] },
  { type: 'COORDINATE', keywords: ['zeichne', 'skizziere', 'trage ein', 'markiere im'] },
  { type: 'MC', keywords: ['kreuze an', 'welche aussage', 'a) ', 'b) ', 'c) '] },
  { type: 'FREE_TEXT', keywords: ['schritt', 'rechenweg', 'zeige', 'begruende', 'begründe'] },
]

type TaskRow = {
  id: string
  title: string | null
  question: string | null
  cluster_id: string | null
  microskill_id: string | null
  is_diagnostic: boolean
  input_type: string | null
  difficulty: number | null
}

type MicroskillRow = {
  id: string
  code: string
  name: string
  cluster_id: string
  cognitive_type: 'FACT' | 'TRANSFER' | 'ANALYSIS' | null
}

type Stats = {
  totalTasks: number
  microskillAssigned: number
  diagnosticSet: number
  inputTypeSet: number
  cognitiveTypeSet: number
  errors: number
  perMicroskill: Record<string, number>
}

function searchText(t: TaskRow): string {
  return `${t.title ?? ''} ${t.question ?? ''}`.toLowerCase()
}

function pickMicroskill(
  task: TaskRow,
  microskills: MicroskillRow[],
): MicroskillRow | null {
  const text = searchText(task)
  // Cluster-constraint: nur Mikroskills die im selben Cluster wie der Task sind
  const clusterMicroskills = task.cluster_id
    ? microskills.filter((m) => m.cluster_id === task.cluster_id)
    : microskills

  for (const code of Object.keys(MICROSKILL_KEYWORDS)) {
    const keywords = MICROSKILL_KEYWORDS[code]
    if (!keywords) continue
    const hit = keywords.some((kw) => text.includes(kw))
    if (!hit) continue
    const ms = clusterMicroskills.find((m) => m.code === code)
    if (ms) return ms
  }
  return null
}

function pickInputType(task: TaskRow): 'MC' | 'FREE_TEXT' | 'MATCHING' | 'COORDINATE' {
  const text = searchText(task)
  for (const rule of INPUT_TYPE_RULES) {
    if (rule.keywords.some((kw) => text.includes(kw))) return rule.type
  }
  return 'FREE_TEXT'
}

async function main(): Promise<void> {
  const supabaseUrl = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Fehlende ENV-Vars: SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY')
    process.exit(1)
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  console.log('▶ Lade Mikroskills + Tasks ...')
  const microskills = await loadMicroskills(supabase)
  if (microskills.length === 0) {
    console.error('Keine Mikroskills gefunden – seed:taxonomy laufen lassen.')
    process.exit(1)
  }
  console.log(`  ${microskills.length} Mikroskills`)

  const tasks = await loadTasks(supabase)
  console.log(`  ${tasks.length} aktive Tasks (mit cluster_id, content_type=exercise)`)

  const stats: Stats = {
    totalTasks: tasks.length,
    microskillAssigned: 0,
    diagnosticSet: 0,
    inputTypeSet: 0,
    cognitiveTypeSet: 0,
    errors: 0,
    perMicroskill: {},
  }

  console.log('▶ Mappe Tasks → Mikroskills ...')
  for (const task of tasks) {
    const update: Partial<{
      microskill_id: string
      is_diagnostic: boolean
      input_type: 'MC' | 'FREE_TEXT' | 'MATCHING' | 'COORDINATE'
      cognitive_type: 'FACT' | 'TRANSFER' | 'ANALYSIS'
    }> = {}

    let microskill: MicroskillRow | null = null
    if (task.microskill_id) {
      microskill = microskills.find((m) => m.id === task.microskill_id) ?? null
    } else {
      microskill = pickMicroskill(task, microskills)
      if (microskill) {
        update.microskill_id = microskill.id
        stats.microskillAssigned += 1
      }
    }

    // is_diagnostic: nur wenn Mikroskill bekannt + Pool noch nicht voll
    if (microskill && !task.is_diagnostic) {
      const taken = stats.perMicroskill[microskill.code] ?? 0
      if (taken < DIAGNOSTIC_PER_MICROSKILL) {
        update.is_diagnostic = true
        stats.diagnosticSet += 1
        stats.perMicroskill[microskill.code] = taken + 1
      }
    } else if (microskill && task.is_diagnostic) {
      // bereits diagnostic: zaehle in pool
      stats.perMicroskill[microskill.code] = (stats.perMicroskill[microskill.code] ?? 0) + 1
    }

    if (task.input_type == null) {
      update.input_type = pickInputType(task)
      stats.inputTypeSet += 1
    }

    if (microskill && microskill.cognitive_type != null) {
      // cognitive_type vom Mikroskill uebernehmen wenn Task keinen hat
      update.cognitive_type = microskill.cognitive_type
      stats.cognitiveTypeSet += 1
    }

    if (Object.keys(update).length === 0) continue

    const { error } = await supabase.from('tasks').update(update).eq('id', task.id)
    if (error) {
      console.error(`  ✗ task ${task.id}: ${error.message}`)
      stats.errors += 1
    }
  }

  console.log('')
  console.log('═══════════════════════════════════════════')
  console.log('  MARK-DIAGNOSTIC FERTIG')
  console.log('═══════════════════════════════════════════')
  console.log(`  Tasks gesamt              : ${stats.totalTasks}`)
  console.log(`  → microskill_id zugewiesen: ${stats.microskillAssigned}`)
  console.log(`  → is_diagnostic gesetzt   : ${stats.diagnosticSet}`)
  console.log(`  → input_type gesetzt      : ${stats.inputTypeSet}`)
  console.log(`  → cognitive_type gesetzt  : ${stats.cognitiveTypeSet}`)
  console.log(`  Fehler (geloggt)          : ${stats.errors}`)
  console.log('  ── pro Mikroskill (diagnostic-pool) ──')
  for (const code of Object.keys(MICROSKILL_KEYWORDS)) {
    const n = stats.perMicroskill[code] ?? 0
    const tag = n === 0 ? '✗' : n < DIAGNOSTIC_PER_MICROSKILL ? '·' : '✓'
    console.log(`  ${tag} ${code}: ${n}`)
  }
  console.log('═══════════════════════════════════════════')
}

async function loadMicroskills(supabase: SupabaseClient): Promise<MicroskillRow[]> {
  const { data, error } = await supabase
    .from('microskills')
    .select('id, code, name, cluster_id, cognitive_type')
    .order('code', { ascending: true })
  if (error) throw new Error(`microskills select: ${error.message}`)
  return (data ?? []) as MicroskillRow[]
}

async function loadTasks(supabase: SupabaseClient): Promise<TaskRow[]> {
  const all: TaskRow[] = []
  const pageSize = 1000
  let from = 0
  while (true) {
    const { data, error } = await supabase
      .from('tasks')
      .select('id, title, question, cluster_id, microskill_id, is_diagnostic, input_type, difficulty')
      .eq('is_active', true)
      .eq('content_type', 'exercise')
      .not('cluster_id', 'is', null)
      .range(from, from + pageSize - 1)
    if (error) throw new Error(`tasks select: ${error.message}`)
    const batch = (data ?? []) as TaskRow[]
    all.push(...batch)
    if (batch.length < pageSize) break
    from += pageSize
  }
  return all
}

main().catch((err) => {
  console.error('Fataler Fehler:', err)
  process.exit(1)
})
