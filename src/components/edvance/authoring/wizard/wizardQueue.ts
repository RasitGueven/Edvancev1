// Die Warteschlange der Pflege-Strecke (/admin/pflege).
//
// Sie entsteht auf der Item-Liste oder der Content-Gesundheit — aus dem AKTIVEN
// Filter ("diese 47 Items durcharbeiten") — und reist per location.state zum
// Wizard. sessionStorage haelt sie zusaetzlich fest: ein Reload mitten in der
// Strecke darf die Warteschlange nicht verlieren, hoechstens den aktuellen
// Schritt (dieselbe Zusage wie beim Speichern pro Schritt).
//
// Kein src/lib-Baustein: das ist UI-Sitzungszustand, kein Datenzugriff.

export type PflegeQueue = {
  /** Task-IDs in der Reihenfolge der Quell-Liste. */
  ids: string[]
  /** Woher die Auswahl kam — nur Anzeige ("Item-Liste", "Content-Gesundheit"). */
  label: string
}

const QUEUE_KEY = 'edvance.pflegeQueue'
const POS_KEY = 'edvance.pflegeQueuePos'

export function persistQueue(queue: PflegeQueue): void {
  try {
    sessionStorage.setItem(QUEUE_KEY, JSON.stringify(queue))
    sessionStorage.setItem(POS_KEY, '0')
  } catch {
    // Voller/gesperrter Storage: die Strecke funktioniert weiter, nur ein
    // Reload verliert dann die Warteschlange.
  }
}

export function persistPosition(pos: number): void {
  try {
    sessionStorage.setItem(POS_KEY, String(pos))
  } catch {
    // s. o.
  }
}

/** Warteschlange + Position aus dem Storage — oder null, wenn keine da ist. */
export function restoreQueue(): { queue: PflegeQueue; pos: number } | null {
  try {
    const raw = sessionStorage.getItem(QUEUE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<PflegeQueue>
    if (!Array.isArray(parsed.ids) || parsed.ids.length === 0) return null
    const queue: PflegeQueue = {
      ids: parsed.ids.filter((id): id is string => typeof id === 'string'),
      label: typeof parsed.label === 'string' ? parsed.label : '',
    }
    if (queue.ids.length === 0) return null
    const pos = Number.parseInt(sessionStorage.getItem(POS_KEY) ?? '0', 10)
    return {
      queue,
      pos: Number.isFinite(pos) ? Math.min(Math.max(pos, 0), queue.ids.length - 1) : 0,
    }
  } catch {
    return null
  }
}

export function clearQueue(): void {
  try {
    sessionStorage.removeItem(QUEUE_KEY)
    sessionStorage.removeItem(POS_KEY)
  } catch {
    // s. o.
  }
}
