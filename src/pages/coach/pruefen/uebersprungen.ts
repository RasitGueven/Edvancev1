// Uebersprungene Aufgaben (Entscheidung 30). Nur Komfort: liegt im sessionStorage und darf fehlen.
const SCHLUESSEL = 'pruefen.uebersprungen'

export function leseUebersprungen(): string[] {
  try {
    const roh = sessionStorage.getItem(SCHLUESSEL)
    const liste: unknown = roh ? JSON.parse(roh) : []
    return Array.isArray(liste) ? liste.filter((x): x is string => typeof x === 'string') : []
  } catch {
    return []
  }
}

function schreibe(liste: string[]): void {
  try {
    sessionStorage.setItem(SCHLUESSEL, JSON.stringify(liste))
  } catch {
    // Ohne Speicher kommen Uebersprungene einfach nicht ans Ende.
  }
}

export function merkeUebersprungen(taskId: string): string[] {
  const liste = [...leseUebersprungen().filter((x) => x !== taskId), taskId]
  schreibe(liste)
  return liste
}

export function vergissUebersprungen(taskId: string): void {
  schreibe(leseUebersprungen().filter((x) => x !== taskId))
}
