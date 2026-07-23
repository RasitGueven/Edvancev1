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

export type TaskStatus = 'draft' | 'review' | 'ready' | 'beanstandet'
export type Afb = 'I' | 'II' | 'III'

/**
 * Der Enum aus Migration P02 — CanonicalInputType kennt MULTI_PART nicht.
 *
 * TERM ist der Antworttyp fuer Termumformungen ("5x+4"). Er steht bewusst HIER
 * und nicht in CanonicalInputType: Der kanonische Antwort-Vertrag
 * (answerPayload.ts) beschreibt fuer jeden Typ eine Loesungsstruktur, und die
 * fuer TERM ist noch nicht entschieden. Was feststeht, ist die Pflege-Seite —
 * und die braucht den Typ, sobald es TERM-Aufgaben gibt.
 */
export type AuthoringInputType = InputType | 'MULTI_PART' | 'TERM'

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
  /**
   * Braucht DIESE Teilaufgabe eine Abbildung? Didaktik, nicht Technik — getrennt
   * vom Bild-Zustand der Assets (C10). NULL/undefined = noch nicht beurteilt,
   * true/false = beurteilt. Fehlt das Feld in tasks.parts, gilt "nicht
   * beurteilt" (A08). Bleibt beim Kind unsichtbar: lsa_public_parts reicht es
   * nicht durch.
   */
  needs_image?: boolean | null
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
  /** Fundament-Skill (A14). NULL bei Quellen ohne Skill-Zuordnung (VERA). */
  skill_key: string | null
  /** Herkunftsjahrgang des Tests (VERA-8 → 8). NICHT der Stoffanker. */
  class_level: number | null
  parts: TaskPart[]
  assets: TaskAsset[]
  /**
   * Braucht der Stamm eine Abbildung? Didaktik, getrennt vom Bild-Zustand der
   * Assets (C10-EMF-Befund). NULL = noch nicht beurteilt, true/false =
   * beurteilt. Menschliche Fachentscheidung, keine Heuristik (A08).
   */
  needs_image: boolean | null
  /**
   * Der einblendbare Attributionstext (CC BY 4.0 / TASL, A09). NULL = keiner
   * noetig (Item ohne Bild) oder noch nicht gepflegt. Einer je AUFGABE, nicht je
   * Asset: mehrere Bilder eines Items stammen aus derselben Quelle. Sobald
   * `assets` nicht leer ist, blockiert ein leerer Text die Freigabe (flags.ts).
   */
  licence_text: string | null
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
  needs_image?: boolean | null
  licence_text?: string | null
  question_payload?: unknown
}

/**
 * task_solutions, gelesen ueber task_solution_get.
 * `correct_answers`: Array bei flachen Items, Objekt {"1": [...]} bei MULTI_PART.
 */
export type SolutionAnswers = string[] | Record<string, string[]>

/** Wie streng gerundet werden darf. `exact` traegt keinen Wert (A10). */
export type AcceptanceTolerance =
  | { mode: 'exact' }
  | { mode: 'absolute'; value: number }
  /** Nachkommastellen, 0..6. */
  | { mode: 'decimals'; value: number }

/**
 * Schreibweisen, die als dieselbe Antwort gelten — als REGEL, nicht als
 * aufgezaehlte Varianten (die waeren Kombinatorik und laufen auseinander).
 */
export type AcceptanceNotation = {
  /** 1,5 zaehlt wie 1.5 */
  decimal_comma?: boolean
  /** "1,5" zaehlt wie "1,5 m" — verboten, wenn `unit_graded` gilt. */
  unit_optional?: boolean
  ignore_case?: boolean
  ignore_space?: boolean
}

/**
 * EINE Akzeptanzregel: welche Antwortformen als richtig gelten (A10).
 * Loesungsdatum — kommt aus task_solutions, nie aus dem Schueler-Payload.
 */
export type AcceptanceRule = {
  /** Die kanonische Antwort, z.B. "1,5 m". Pflicht. */
  canonical: string
  /** Fachliche Aequivalente in anderer Einheit/Groessenordnung: ["150 cm"]. */
  equivalents?: string[]
  notation?: AcceptanceNotation
  tolerance?: AcceptanceTolerance
  unit?: string
  /**
   * Ist die geforderte Einheit Teil der Kompetenz? true → "150 cm" zaehlt
   * NICHT, wenn nach Metern gefragt war. Schliesst notation.unit_optional aus.
   */
  unit_graded?: boolean
  /**
   * Muss ein Bruch vollstaendig gekuerzt sein (A11)? true → "22/24" ist bei
   * kanonisch "11/12" nur `teilweise`: richtig gerechnet, Form verfehlt.
   * Fehlt/false → wertgleich reicht fuer `voll`.
   *
   * Steht oben und nicht in `notation`, weil alle notation-Flags LOCKERN und
   * dieses hier VERSCHAERFT — es gehoert neben `unit_graded`.
   */
  require_reduced?: boolean
  /**
   * Die bekannten FEHLBILDER dieser Aufgabe (A12) — welcher Wert entsteht,
   * wenn ein Kind einen bestimmten Denkfehler macht.
   *
   * Zwei Formen, beide gueltig: Objekt `{"17/23":"additiv"}` (Wert →
   * Fehlertyp) oder Array `["17/23","3/7"]` (nur die Werte). Wie ein Fehlbild
   * benannt wird, ist noch nicht entschieden; deshalb erzwingt auch der
   * CHECK die innere Form nicht.
   *
   * REIN DEKLARATIV: aendert die Bewertung nicht. Ohne dieses Feld kann der
   * Report nur „falsch" sagen, mit ihm WELCHER Fehler es war.
   */
  known_errors?: Record<string, string> | string[]
}

/** Flach eine Regel, bei MULTI_PART eine Regel je Teilaufgaben-nr. */
export type AcceptanceSet = AcceptanceRule | Record<string, AcceptanceRule>

/** Bewertungsstufe einer Antwortoption bei AFB III (A10). */
export type OptionScore = 'voll' | 'teilweise' | 'nicht'

/**
 * Die Skala einer Aufgabe/Teilaufgabe: Option-ID → Stufe.
 * KONSTRUKTIONSREGEL: genau eine 'voll', genau eine 'teilweise', Rest 'nicht'.
 * Die Stufe haengt an der OPTION, nicht am Urteil — mehrere Optionen duerfen
 * dasselbe Ja/Nein-Urteil tragen, nur eine ist 'teilweise'.
 */
export type OptionScoreScale = Record<string, OptionScore>

/** Flach eine Skala, bei MULTI_PART eine Skala je Teilaufgaben-nr. */
export type OptionScores = OptionScoreScale | Record<string, OptionScoreScale>

export type TaskSolution = {
  exists: boolean
  correct_answers: SolutionAnswers
  /**
   * Das Akzeptanz-Set (task_solutions.acceptance, A10) — WARUM eine Antwort
   * zaehlt. `undefined`, solange die Migration nicht eingespielt ist (die RPC
   * liefert das Feld dann nicht); `null` = nicht gepflegt. Bewertet wird bis auf
   * Weiteres weiterhin gegen `correct_answers`.
   */
  acceptance?: AcceptanceSet | null
  /**
   * Die Bewertungsstufe je Antwortoption (task_solutions.option_scores, A10).
   * Nur bei AFB III belegt — bei I/II bleibt die Bewertung binaer.
   * `undefined` = Migration fehlt noch, `null` = nicht gepflegt.
   */
  option_scores?: OptionScores | null
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
