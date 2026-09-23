// Der Editor-Teil des Rueckwegs in die Pflege-Strecke (s. wizardQueue.ts).
//
// Kam der Editor aus der Strecke (?pflege=<schritt>), fuehrt der Zurueck-Link in
// die Strecke statt ins Board, und nach erfolgreichem Speichern geht es
// automatisch dorthin zurueck — an dieselbe Aufgabe, in denselben Schritt.

import { useNavigate, useSearchParams } from 'react-router-dom'
import { PFLEGE_PARAM, zurueckInStrecke } from './wizardQueue'

export function usePflegeRueckweg(): {
  /** Ziel des Zurueck-Links: Strecke oder Board. */
  zurueck: { to: string; state?: { schritt: string }; labelKey: string }
  /** Nach erfolgreichem Speichern aufrufen. */
  nachSpeichern: () => void
} {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const schritt = params.get(PFLEGE_PARAM)

  if (!schritt) {
    return { zurueck: { to: '/admin/authoring', labelKey: 'page.backToList' }, nachSpeichern: () => undefined }
  }
  const ziel = zurueckInStrecke(schritt)
  return {
    zurueck: { ...ziel, labelKey: 'wizard.backToRun' },
    nachSpeichern: () => navigate(ziel.to, { state: ziel.state }),
  }
}
