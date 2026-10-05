// „Vor der Freigabe klären“ (Bauauftrag B 7): die sperrenden Befunde einer Aufgabe und die Hinweise, je mit
// dem Abschnitt im Editor, an dem man sie behebt. Quelle sind die blockierenden Flags aus computeFlags (sie
// spiegeln das Gate freigabe_gate_fehler, flags.ts Kopf), dazu tote Bildpfade (health.ts) und „Bild fehlt“
// aus pruef_ausschluss. Reine Funktionen; die Texte kommen aus authoring:flags.* bzw. pruefenAdmin:befund.*.

import type { AuthoringTask, ItemFlag, TaskSolution } from '@/types'
import { computeFlags } from '@/lib/authoring/flags'
import { deadAssets } from '@/lib/authoring/health'

/** Sprungziele im Editor (Bauauftrag D 17). */
export type EditorAbschnitt = 'aufgabe' | 'antwort' | 'einordnung' | 'bilder' | 'stoffanker'

export const EDITOR_ABSCHNITTE: readonly EditorAbschnitt[] = ['aufgabe', 'antwort', 'einordnung', 'bilder', 'stoffanker']

export type Befund = {
  /** i18n-Schluessel mit Namespace. */
  key: string
  vars?: Record<string, string | number>
  ziel: EditorAbschnitt
}

const ZIEL: Record<string, EditorAbschnitt> = {
  stemMissing: 'aufgabe', titleMissing: 'aufgabe', stemFieldLabel: 'aufgabe', inputTypeMissing: 'aufgabe',
  mcOptionsMissing: 'aufgabe', partsOnFlatItem: 'aufgabe', partsTooFew: 'aufgabe', partNrDuplicate: 'aufgabe',
  partPromptMissing: 'aufgabe', partMcOptionsMissing: 'aufgabe', estDurationMissing: 'aufgabe',
  solutionMissing: 'antwort', solutionTextMissing: 'antwort', typicalErrorsMissing: 'antwort', partSolutionMissing: 'antwort',
  clusterMissing: 'einordnung', afbMissing: 'einordnung', competencyMissing: 'einordnung', partAfbMissing: 'einordnung',
  partCompetencyMissing: 'einordnung',
  stoffankerMissing: 'stoffanker', stoffankerNoField: 'stoffanker',
  assetAltMissing: 'bilder', licenceMissing: 'bilder',
}

const alsBefund = (f: ItemFlag): Befund => ({
  key: `authoring:flags.${f.code}`,
  ...(f.vars ? { vars: f.vars } : {}),
  ziel: ZIEL[f.code] ?? 'aufgabe',
})

export function befundeVorFreigabe(
  task: AuthoringTask,
  loesung: TaskSolution,
  hatStoffankerFeld: boolean,
  ausschluss: string | null,
): { sperrend: Befund[]; hinweise: Befund[] } {
  const flags = computeFlags(task, loesung, hatStoffankerFeld)
  const sperrend = flags.filter((f) => f.blocking).map(alsBefund)
  if (deadAssets(task).length > 0) sperrend.push({ key: 'pruefenAdmin:befund.toterPfad', ziel: 'bilder' })
  if (ausschluss === 'bild_fehlt') sperrend.push({ key: 'pruefenAdmin:befund.bildFehlt', ziel: 'bilder' })
  return { sperrend, hinweise: flags.filter((f) => !f.blocking).map(alsBefund) }
}

/** Adresse des Editors mit Rueckweg in die Pruefansicht und, wenn gegeben, dem Abschnitt. */
export function editorZiel(taskId: string, abschnitt?: EditorAbschnitt | null): string {
  return `/admin/authoring/${taskId}?zurueck=pruefen${abschnitt ? `&abschnitt=${abschnitt}` : ''}`
}
