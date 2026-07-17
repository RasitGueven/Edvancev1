// Welche Schritte ein Item in der Pflege-Strecke durchlaeuft.
//
// Fuenf Schritte, aber nicht immer alle: BILDER erscheint nur, wenn das Item
// Assets hat oder der Text auf eine Abbildung verweist — ein leerer Bild-Schritt
// waere ein Klick ohne Frage. Die Liste wird EINMAL beim Laden des Items
// berechnet und bleibt dann stehen: ein Schritt, der unter dem Pfleger
// verschwindet (weil er gerade den toten Pfad entfernt hat), waere Treibsand.
//
// Reine Funktion, kein React — testbar (wizardSteps.test.ts).

import { imageRefFinding } from '@/lib/authoring/health'
import type { AuthoringTask } from '@/types'

export type WizardStepId = 'read' | 'anchor' | 'images' | 'solution' | 'release'

export function stepsForTask(task: AuthoringTask): WizardStepId[] {
  const hasImageWork = task.assets.length > 0 || imageRefFinding(task) != null
  return [
    'read',
    'anchor',
    ...(hasImageWork ? (['images'] as const) : []),
    'solution',
    'release',
  ]
}
