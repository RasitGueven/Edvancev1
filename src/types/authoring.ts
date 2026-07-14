// Typen fuer das Autoren-Tool (Item-Pflege, /admin/authoring).
//
// Warum ein eigener Task-Typ statt einer Erweiterung von `Task` aus content.ts:
// `Task` ist der Lese-Typ der Schueler-/Coach-Pfade und kennt die P01/P02-Spalten
// (status, afb, competency_*, parts, unit, est_duration_sec) bis heute nicht. Sie
// dort nachzuruesten wuerde jeden Consumer beruehren. Das Autoren-Tool ist der
// einzige Ort, der die volle Zeile braucht — also traegt es seinen eigenen Typ.
//
// Die Loesung steckt bewusst NICHT in AuthoringTask: sie lebt in task_solutions
// und ist nur ueber die SECURITY-DEFINER-RPCs erreichbar (P01 §4). Zwei Typen,
// zwei Zugriffspfade — die Trennung soll im Code sichtbar bleiben.

import type { InputType, TaskAsset } from './content'

export type TaskStatus = 'draft' | 'review' | 'ready'
export type Afb = 'I' | 'II' | 'III'

/** Der Enum aus Migration P02 — CanonicalInputType kennt MULTI_PART nicht. */
export type AuthoringInputType = InputType | 'MULTI_PART'

/** Antworttyp einer Teilaufgabe. Nur auto-bewertbare (lsa_parts_valid). */
export type PartKind = 'short_input' | 'mc'

export type PartOption = { id: string; label: string }

/**
 * Eine Teilaufgabe aus `tasks.parts`. Oeffentliche Struktur — die Loesung liegt
 * in task_solutions.correct_answers unter dem Schluessel `nr` (P02).
 * Kompetenz und AFB sind Diagnostik-Metadaten und gehen NICHT ans Kind.
 */
export type TaskPart = {
  nr: number
  kind: PartKind
  prompt: string
  unit?: string | null
  options?: PartOption[]
  competency_content?: string | null
  competency_process?: string | null
  afb?: Afb | null
}

/** Eine tasks-Zeile, wie das Autoren-Tool sie sieht. */
export type AuthoringTask = {
  id: string
  title: string | null
  question: string | null
  status: TaskStatus
  input_type: AuthoringInputType | null
  afb: Afb | null
  competency_content: string | null
  competency_process: string | null
  cluster_id: string | null
  unit: string | null
  est_duration_sec: number | null
  /** Herkunftsjahrgang des Tests (VERA-8 → 8). NICHT der Stoffanker. */
  class_level: number | null
  parts: TaskPart[]
  assets: TaskAsset[]
  question_payload: unknown | null
  source: string
  source_ref: string | null
  is_active: boolean
  created_at: string

  // --- Erst nach docs/schema/A01-authoring.proposal.sql vorhanden ---
  /** STOFFANKER: welcher Jahrgangsstoff wird geprueft. undefined = Spalte fehlt. */
  curriculum_grade?: number | null
  reviewed_by?: string | null
  reviewed_at?: string | null
}

/** Was der Editor an `tasks` schreibt. Status NICHT dabei — der laeuft ueber das Gate. */
export type AuthoringTaskPatch = {
  title?: string | null
  question?: string | null
  input_type?: AuthoringInputType | null
  afb?: Afb | null
  competency_content?: string | null
  competency_process?: string | null
  unit?: string | null
  est_duration_sec?: number | null
  curriculum_grade?: number | null
  parts?: TaskPart[]
  assets?: TaskAsset[]
  question_payload?: unknown
}

/**
 * task_solutions, gelesen ueber task_solution_get.
 * `correct_answers`: Array bei flachen Items, Objekt {"1": [...]} bei MULTI_PART.
 */
export type SolutionAnswers = string[] | Record<string, string[]>

export type TaskSolution = {
  exists: boolean
  correct_answers: SolutionAnswers
  /** Der didaktische LOESUNGSWEG (Handarbeit). Nicht der Beleg — siehe `beleg`. */
  solution: string | null
  /**
   * Die Quellenbelege der Extraktion (task_solutions.beleg, B01) — WORAUF sich die
   * Loesung stuetzt. READ-ONLY im Tool: der Editor zeigt sie an und schickt sie nie
   * zurueck, damit ein Speichern sie nicht zerstoeren kann. Geschrieben wird der
   * Beleg allein vom Import (scripts/import-vera8-draft.ts).
   */
  beleg: GroundingBeleg[]
  hints: { level?: number; text: string }[]
  coach_hints: string[]
  typical_errors: { error: string; socratic_question?: string }[]
  updated_at?: string
}

/** Was der Editor an task_solution_upsert schickt — ohne `beleg` (read-only). */
export type TaskSolutionPatch = Omit<TaskSolution, 'exists' | 'updated_at' | 'beleg'>

/** Ein Pflege-Befund. `blocking` = verhindert den Uebergang nach 'ready'. */
export type ItemFlag = {
  /** i18n-Key unter authoring:flags.* — nie ein fertiger Satz. */
  code: string
  blocking: boolean
  /** Interpolationswerte fuer t(), z.B. { nr: 2 }. */
  vars?: Record<string, string | number>
}

/** Listenzeile — bewusst schmal, die Liste laedt keine Loesungen. */
export type AuthoringListItem = {
  id: string
  title: string | null
  status: TaskStatus
  input_type: AuthoringInputType | null
  afb: Afb | null
  competency_content: string | null
  curriculum_grade?: number | null
  class_level: number | null
  partCount: number
  hasAsset: boolean
  hasTable: boolean
  flagCount: number
  blockingCount: number
}

/** Welche Felder die DB heute wirklich hat (Feature-Detection statt Annahme). */
export type AuthoringSchema = {
  /** tasks.curriculum_grade / reviewed_by / reviewed_at */
  hasStoffanker: boolean
  /** RPC task_solution_get */
  hasSolutionRead: boolean
  /** RPC task_status_set */
  hasStatusGate: boolean
}

/** Quellenbeleg aus der Extraktion (gebaut von scripts/build-grounding-index.ts). Read-only. */
export type GroundingQuote = { quelle: string; zitat: string; methode?: string }

/** Ein Beleg der Neuextraktion: welches Feld, welches Gate, welches Zitat. */
export type GroundingBeleg = {
  /** Feldpfad aus der Extraktion, z.B. "part1.prompt" oder "assets.lizenz". */
  feld: string
  gate?: string
  quelle?: string
  zitat: string
  hinweis?: string
}

/** Eine Teilaufgabe, die der P02-Vertrag nicht halten konnte (Freitext, leerer
 *  Prompt, MC ohne Optionen). Read-only — sie steht NICHT in tasks.parts und muss
 *  im Editor von Hand angelegt werden. Ohne Loesung: der Index ist oeffentlich. */
export type GroundingRohteil = {
  nr: number
  kind: string
  prompt: string
  unit?: string
  options?: { id: string; label: string }[]
}

/**
 * Der Beleg-Datensatz zu einem Item.
 *
 * ⚠️  Kommt aus public/authoring/grounding-vera8.json — statisch, ohne Auth.
 *     Deshalb enthaelt er KEINEN Loesungsbeleg (seit C08). Worauf sich die Loesung
 *     stuetzt, steht in task_solutions.solution und kommt ueber task_solution_get
 *     — gegated auf Coach/Admin.
 */
export type GroundingRecord = {
  id: string
  titel?: string
  quelle?: string
  lizenz_status?: string
  iqb_urls?: Record<string, string>
  aufgabe_text?: string
  /** Probleme, die der Altlauf gemeldet hat. */
  problems?: string[]
  /** Was die Neuextraktion selbst unsicher fand (_flags). */
  flags?: string[]
  /** Was der Import nicht abbilden konnte (verworfene Tabelle, Teilaufgaben, Assets). */
  import_flags?: string[]
  belege?: GroundingBeleg[]
  teilaufgaben_roh?: GroundingRohteil[]
  /** Eine Tabelle, die F01 abgewiesen hat — roh, zum Nachbauen. */
  tabelle_roh?: { header?: string[]; headers?: string[]; rows?: string[][] }
}
