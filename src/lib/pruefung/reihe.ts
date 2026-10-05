// Die Reihe der Admin-Pruefansicht (Bauauftrag C 13, C 15, C 16): die geordnete Liste von Aufgaben-IDs mit
// Herkunft, ueber die /admin/pruefen/:taskId laeuft. Ersetzt die Warteschlange der Pflege-Strecke.
//
// Sie liegt im sessionStorage und ist nur Komfort: fehlt sie oder enthaelt sie die Aufgabe nicht, oeffnet die
// Pruefansicht die einzelne Aufgabe ohne Position, und "Schliessen" fuehrt zur Expertenliste.
// Die Position ergibt sich aus der Aufgabe in der Adresse, nicht aus einem Zaehler: So kommt der Rueckweg
// aus dem Editor an dieselbe Stelle, und ein Reload verliert nichts.

export type ReiheHerkunft = 'liste' | 'auswahl' | 'board' | 'gesundheit' | 'heute'

export type ReiheErgebnis = {
  freigegeben: string[]
  anLena: string[]
  zurueckgewiesen: string[]
  uebersprungen: string[]
}

export type Reihe = {
  ids: string[]
  herkunft: ReiheHerkunft
  /** Fertiger Text fuer den Kopf, z. B. „Expertenliste · Filter: Rückfrage“. */
  label: string
  /** Wohin „Schließen“ und „Zurück zur ⟨Herkunft⟩“ fuehren (Pfad mit Query). */
  zurueck: string
  ergebnis: ReiheErgebnis
}

export type ReiheArt = keyof ReiheErgebnis

const KEY = 'edvance.adminPruefReihe'
/** Ohne Reihe fuehrt „Schließen“ hierhin (Anforderung, Grenzfaelle). */
export const OHNE_REIHE_ZURUECK = '/admin/authoring/liste'

const leer = (): ReiheErgebnis => ({ freigegeben: [], anLena: [], zurueckgewiesen: [], uebersprungen: [] })

export function neueReihe(ids: string[], herkunft: ReiheHerkunft, label: string, zurueck: string): Reihe {
  return { ids: [...new Set(ids)], herkunft, label, zurueck, ergebnis: leer() }
}

export function speichereReihe(reihe: Reihe): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(reihe))
  } catch {
    // Voller oder gesperrter Storage: die Pruefansicht oeffnet dann die einzelne Aufgabe.
  }
}

const liste = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [])

export function leseReihe(): Reihe | null {
  try {
    const raw = sessionStorage.getItem(KEY)
    if (!raw) return null
    const r = JSON.parse(raw) as Partial<Reihe>
    const ids = liste(r.ids)
    if (ids.length === 0 || typeof r.zurueck !== 'string') return null
    const e = (r.ergebnis ?? {}) as Partial<ReiheErgebnis>
    return {
      ids,
      herkunft: (['liste', 'auswahl', 'board', 'gesundheit', 'heute'] as const).find((h) => h === r.herkunft) ?? 'liste',
      label: typeof r.label === 'string' ? r.label : '',
      zurueck: r.zurueck,
      ergebnis: {
        freigegeben: liste(e.freigegeben),
        anLena: liste(e.anLena),
        zurueckgewiesen: liste(e.zurueckgewiesen),
        uebersprungen: liste(e.uebersprungen),
      },
    }
  } catch {
    return null
  }
}

export function vergissReihe(): void {
  try {
    sessionStorage.removeItem(KEY)
  } catch {
    // s. o.
  }
}

/** Merkt die Reihe und liefert die Adresse ihrer ersten (oder der angegebenen) Aufgabe — fuer alle Einstiege. */
export function reiheStarten(reihe: Reihe, startId?: string): string {
  speichereReihe(reihe)
  return `/admin/pruefen/${startId && reihe.ids.includes(startId) ? startId : reihe.ids[0]}`
}

/** Die Reihe, wenn sie die Aufgabe enthaelt — sonst null (direkter Link ohne Reihe). */
export function reiheFuer(reihe: Reihe | null, taskId: string | undefined): Reihe | null {
  return reihe && taskId && reihe.ids.includes(taskId) ? reihe : null
}

/** Position 1..n der Aufgabe in der Reihe, sonst null. */
export function position(reihe: Reihe | null, taskId: string): { nr: number; anzahl: number } | null {
  const i = reihe ? reihe.ids.indexOf(taskId) : -1
  return reihe && i >= 0 ? { nr: i + 1, anzahl: reihe.ids.length } : null
}

/** Die naechste Aufgabe der Reihe; null am Ende (dann folgt die Abschlussseite). */
export function naechste(reihe: Reihe, taskId: string): string | null {
  const i = reihe.ids.indexOf(taskId)
  return i >= 0 && i < reihe.ids.length - 1 ? reihe.ids[i + 1] : null
}

/** Die vorige Aufgabe der Reihe; null an der ersten Stelle. */
export function vorige(reihe: Reihe, taskId: string): string | null {
  const i = reihe.ids.indexOf(taskId)
  return i > 0 ? reihe.ids[i - 1] : null
}

/** Haelt fest, was mit einer Aufgabe geschah. Die letzte Entscheidung zaehlt (eine Aufgabe, eine Zeile). */
export function vermerke(reihe: Reihe, taskId: string, art: ReiheArt): Reihe {
  const ergebnis = leer()
  for (const k of Object.keys(ergebnis) as ReiheArt[]) {
    ergebnis[k] = reihe.ergebnis[k].filter((id) => id !== taskId)
  }
  ergebnis[art].push(taskId)
  return { ...reihe, ergebnis }
}

/** Die uebersprungenen Aufgaben als neue Reihe, in der Reihenfolge der alten (Abschlussseite). */
export function reiheDerUebersprungenen(reihe: Reihe): Reihe {
  const ids = reihe.ids.filter((id) => reihe.ergebnis.uebersprungen.includes(id))
  return { ...reihe, ids, ergebnis: leer() }
}
