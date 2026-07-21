// Die Pflichtfeld-Pruefung der Item-Pflege.
//
// Ein Flag ist ein Befund am Item. `blocking: true` heisst: dieses Item kann
// nicht auf 'ready' — und damit nicht in den LSA-Pool. Die blockierenden Regeln
// sind bewusst ein SPIEGEL der DB-Regeln (tasks_multipart_check aus P02,
// lsa_has_answers, das Gate in task_status_set), plus die drei, die die DB nicht
// beantworten kann: Alt-Text, Kompetenz je Teilaufgabe, MC-Optionen bei flachen
// Items. Wo die DB haerter ist, gewinnt die DB — sie wirft dann beim Speichern.
// Das Tool soll den Fehler nur VORHER zeigen, nicht ihn allein verhindern.
//
// Reine Funktionen, kein React, kein Supabase — deshalb testbar (flags.test.ts).
// Kein fertiger Text: `code` ist ein i18n-Key unter authoring:flags.*.

import type {
  AuthoringTask,
  ItemFlag,
  PartOption,
  SolutionAnswers,
  TaskPart,
  TaskSolution,
} from '@/types'

/** Markdown-GFM-Tabelle im Stamm: eine Zeile, die mit | beginnt und endet. */
export function hasTable(question: string | null): boolean {
  if (!question) return false
  return question
    .split('\n')
    .some((line) => /^\s*\|.*\|\s*$/.test(line))
}

/** Antworten einer Teilaufgabe aus der Multi-Part-Form {"1": [...]}. */
function answersForPart(answers: SolutionAnswers, nr: number): string[] {
  if (Array.isArray(answers)) return []
  return answers[String(nr)] ?? []
}

function isBlank(s: string | null | undefined): boolean {
  return !s || s.trim() === ''
}

function optionsOf(payload: unknown): PartOption[] {
  if (!payload || typeof payload !== 'object') return []
  const opts = (payload as { options?: unknown }).options
  return Array.isArray(opts) ? (opts as PartOption[]) : []
}

function flag(code: string, blocking: boolean, vars?: ItemFlag['vars']): ItemFlag {
  return { code, blocking, ...(vars ? { vars } : {}) }
}

/**
 * Alle Befunde zu einem Item.
 *
 * `hasStoffankerField` = false bedeutet: die Spalte curriculum_grade existiert in
 * dieser DB noch nicht (A01-Migration nicht eingespielt). Dann ist der fehlende
 * Stoffanker KEIN blockierender Fehler des Pflegers — es ist ein fehlendes Feld.
 * Ein Gate, das eine Eingabe verlangt, die es nicht gibt, ist kaputt.
 */
export function computeFlags(
  task: AuthoringTask,
  solution: TaskSolution,
  hasStoffankerField: boolean,
): ItemFlag[] {
  const flags: ItemFlag[] = []
  const isMulti = task.input_type === 'MULTI_PART'

  // ── Stamm ────────────────────────────────────────────────────────────────
  if (isBlank(task.question)) flags.push(flag('stemMissing', true))
  if (isBlank(task.title)) flags.push(flag('titleMissing', false))

  // Extraktions-Artefakt: die Zeile, die im Original das Eingabefeld war
  // ("x = __________"), ist keine Frage. Der Importer entfernt sie, wo er sie
  // kennt — der Rest muss hier auffallen.
  if (task.question && /_{3,}/.test(task.question)) {
    flags.push(flag('stemFieldLabel', false))
  }

  // ── Typ ──────────────────────────────────────────────────────────────────
  if (!task.input_type) flags.push(flag('inputTypeMissing', true))

  // ── Tags ─────────────────────────────────────────────────────────────────
  if (!task.cluster_id) flags.push(flag('clusterMissing', true))

  if (hasStoffankerField) {
    if (task.curriculum_grade == null) flags.push(flag('stoffankerMissing', true))
  } else {
    flags.push(flag('stoffankerNoField', false))
  }

  // AFB und Kompetenz: bei Multi-Part traegt sie die TEILAUFGABE (P02), beim
  // flachen Item das Item. Beides gleichzeitig zu verlangen waere doppelt.
  if (!isMulti) {
    if (!task.afb) flags.push(flag('afbMissing', true))
    if (isBlank(task.competency_content)) flags.push(flag('competencyMissing', true))
  }

  // ── Teilaufgaben ─────────────────────────────────────────────────────────
  if (isMulti) {
    flags.push(...multiPartFlags(task, solution))
  } else if (task.parts.length > 0) {
    // tasks_multipart_check erzwingt parts = '[]' bei flachen Items — das wuerde
    // beim Speichern werfen. Vorher zeigen.
    flags.push(flag('partsOnFlatItem', true))
  }

  // ── Loesung ──────────────────────────────────────────────────────────────
  if (!isMulti) {
    const answers = Array.isArray(solution.correct_answers)
      ? solution.correct_answers
      : []
    if (answers.filter((a) => !isBlank(a)).length === 0) {
      flags.push(flag('solutionMissing', true))
    }
    if (task.input_type === 'MC' && optionsOf(task.question_payload).length < 2) {
      flags.push(flag('mcOptionsMissing', true))
    }
  }
  if (isBlank(solution.solution)) flags.push(flag('solutionTextMissing', false))
  if (solution.typical_errors.length === 0) flags.push(flag('typicalErrorsMissing', false))

  // ── Assets ───────────────────────────────────────────────────────────────
  task.assets.forEach((asset, i) => {
    if (isBlank(asset.alt)) flags.push(flag('assetAltMissing', true, { index: i + 1 }))
  })

  // Hat ein Item MIT QUELLE ein Bild, MUSS ein Lizenz-/Attributionstext dran
  // sein — CC BY 4.0 verlangt die Namensnennung beim Zeigen (A09). Blockierend
  // wie der Alt-Text. Eigenbauten (Bruchrechnung, Prozent …) haben keine externe
  // Quelle und brauchen keine Attribution — sie sind hier ausgenommen. Die
  // Quellenpruefung ist bewusst inline (diese Datei bleibt abhaengigkeitsfrei):
  // gegrounded ist ein Item mit source_ref aus einer belegpflichtigen Quelle.
  const hatQuelle = Boolean(task.source_ref) && task.source === 'VERA8_IQB'
  if (task.assets.length > 0 && hatQuelle && isBlank(task.licence_text)) {
    flags.push(flag('licenceMissing', true))
  }

  // ── Zeitbudget ───────────────────────────────────────────────────────────
  // Bei MULTI_PART ist es DB-Pflicht (CHECK), sonst nur ein guter Wert: lsa_start
  // zieht dann auf estimated_minutes bzw. 180 s zurueck.
  if (task.est_duration_sec == null) {
    flags.push(flag('estDurationMissing', isMulti))
  }

  return flags
}

function multiPartFlags(task: AuthoringTask, solution: TaskSolution): ItemFlag[] {
  const flags: ItemFlag[] = []
  const parts = task.parts

  if (parts.length < 2) {
    // lsa_parts_valid: eine einzelne "Teilaufgabe" ist ein flaches Item.
    flags.push(flag('partsTooFew', true))
    return flags
  }

  const seen = new Set<number>()
  for (const part of parts) {
    if (seen.has(part.nr)) flags.push(flag('partNrDuplicate', true, { nr: part.nr }))
    seen.add(part.nr)
    flags.push(...partFlags(part, solution.correct_answers))
  }
  return flags
}

function partFlags(part: TaskPart, answers: SolutionAnswers): ItemFlag[] {
  const flags: ItemFlag[] = []
  const nr = part.nr

  if (isBlank(part.prompt)) flags.push(flag('partPromptMissing', true, { nr }))
  if (part.kind === 'mc' && (part.options?.length ?? 0) < 2) {
    flags.push(flag('partMcOptionsMissing', true, { nr }))
  }
  if (!part.afb) flags.push(flag('partAfbMissing', true, { nr }))
  if (isBlank(part.competency_content)) {
    flags.push(flag('partCompetencyMissing', true, { nr }))
  }

  // lsa_has_answers: bei MULTI_PART braucht JEDE Teilaufgabe eine Loesung. Eine
  // fehlende, und das Item ist nicht poolfaehig — nicht "teilweise".
  const answer = answersForPart(answers, nr)
  if (answer.filter((a) => !isBlank(a)).length === 0) {
    flags.push(flag('partSolutionMissing', true, { nr }))
  }

  return flags
}

/** Die Flags, die den Uebergang nach 'ready' verhindern. */
export function blockingFlags(flags: ItemFlag[]): ItemFlag[] {
  return flags.filter((f) => f.blocking)
}

export function canRelease(flags: ItemFlag[]): boolean {
  return blockingFlags(flags).length === 0
}
