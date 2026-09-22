// Die Bilanz eines Durchlaufs: was mit jeder Aufgabe geschah und welche das
// Themengebiet gewechselt haben ("verschoben").
//
// Liegt wie die Warteschlange im sessionStorage: der Weg in den Editor und
// zurueck laedt die Strecke neu — die Bilanz soll das ueberleben.

import { useCallback, useState } from 'react'
import type { WizardOutcome } from './WizardScreens'

const KEY = 'edvance.pflegeBilanz'

export type RunBilanz = {
  outcomes: Record<string, WizardOutcome>
  /** Task-IDs, deren Themengebiet in diesem Durchlauf geaendert wurde. */
  verschoben: string[]
}

function lade(): RunBilanz {
  try {
    const raw = sessionStorage.getItem(KEY)
    if (!raw) return { outcomes: {}, verschoben: [] }
    const p = JSON.parse(raw) as Partial<RunBilanz>
    return {
      outcomes: p.outcomes && typeof p.outcomes === 'object' ? p.outcomes : {},
      verschoben: Array.isArray(p.verschoben) ? p.verschoben : [],
    }
  } catch {
    return { outcomes: {}, verschoben: [] }
  }
}

function speichere(b: RunBilanz): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(b))
  } catch {
    // Voller/gesperrter Storage: die Bilanz gilt dann nur bis zum Reload.
  }
}

/** Beim Start einer NEUEN Warteschlange leeren (persistQueue). */
export function leereBilanz(): void {
  try {
    sessionStorage.removeItem(KEY)
  } catch {
    // s. o.
  }
}

export function useRunBilanz(): RunBilanz & {
  erfasse: (taskId: string, outcome: WizardOutcome, verschoben: boolean) => void
} {
  const [bilanz, setBilanz] = useState<RunBilanz>(lade)
  const erfasse = useCallback((taskId: string, outcome: WizardOutcome, verschoben: boolean) => {
    setBilanz((b) => {
      const next: RunBilanz = {
        outcomes: { ...b.outcomes, [taskId]: outcome },
        verschoben: verschoben && !b.verschoben.includes(taskId) ? [...b.verschoben, taskId] : b.verschoben,
      }
      speichere(next)
      return next
    })
  }, [])
  return { ...bilanz, erfasse }
}
