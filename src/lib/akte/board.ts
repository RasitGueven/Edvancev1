// Board "Schueler" (S2): reine Anzeige-Logik — Spalten, Suche, Sortierung,
// Filter. Keine Einheiten-Rechnung: Ampel, Rueckstand und "verbraucht"
// kommen fertig aus board_schueler().

import type { AttendanceStatus, BoardSchueler, WortlisteEintrag } from '@/types'

export type BoardSortierung = 'nachname' | 'rueckstand'
export type ZustandFilter = 'aktiv' | 'ruhend' | 'alle'

/** Nachname = letztes Wort des Namens (die Akte fuehrt einen Namen, kein Feld je Teil). */
export function nachname(name: string | null): string {
  const teile = (name ?? '').trim().split(/\s+/)
  return (teile[teile.length - 1] ?? '').toLocaleLowerCase('de')
}

/** Name oder Schule enthaelt den Suchtext (ohne Gross/Klein). */
export function passtZurSuche(s: BoardSchueler, suche: string): boolean {
  const q = suche.trim().toLocaleLowerCase('de')
  if (!q) return true
  return [s.name, s.schule].some((f) => (f ?? '').toLocaleLowerCase('de').includes(q))
}

export function passtZumZustand(s: BoardSchueler, filter: ZustandFilter): boolean {
  return filter === 'alle' || s.zustand === filter
}

export function sortiere(liste: BoardSchueler[], sortierung: BoardSortierung): BoardSchueler[] {
  const kopie = [...liste]
  const nachNamen = (a: BoardSchueler, b: BoardSchueler): number =>
    nachname(a.name).localeCompare(nachname(b.name), 'de') ||
    (a.name ?? '').localeCompare(b.name ?? '', 'de')
  if (sortierung === 'nachname') return kopie.sort(nachNamen)
  // Groesster Rueckstand zuerst; ohne Einheiten-Stand (startet noch, ruhend) ans Ende.
  return kopie.sort((a, b) => {
    if (a.rueckstand === null && b.rueckstand === null) return nachNamen(a, b)
    if (a.rueckstand === null) return 1
    if (b.rueckstand === null) return -1
    return b.rueckstand - a.rueckstand || nachNamen(a, b)
  })
}

/** Eine Spalte je vorhandener Klassenstufe, aufsteigend; ohne Klasse (null) zuletzt. */
export function klassenSpalten(liste: BoardSchueler[]): (number | null)[] {
  const klassen = [...new Set(liste.map((s) => s.klasse))]
  return klassen.sort((a, b) => (a === null ? 1 : b === null ? -1 : a - b))
}

export type Spalte = {
  klasse: number | null
  gesamt: number
  sichtbar: BoardSchueler[]
}

/**
 * Baut die Spalten: Zustandsfilter bestimmt, wer ueberhaupt zaehlt ("y");
 * globale Suche und Spaltensuche wirken zusammen ("x").
 */
export function baueSpalten(
  liste: BoardSchueler[],
  opts: {
    zustand: ZustandFilter
    sucheGlobal: string
    sucheSpalte: Record<string, string>
    sortierung: BoardSortierung
  },
): { spalten: Spalte[]; trefferGesamt: number } {
  const imFilter = liste.filter((s) => passtZumZustand(s, opts.zustand))
  const spalten = klassenSpalten(imFilter).map((klasse) => {
    const inSpalte = imFilter.filter((s) => s.klasse === klasse)
    const suche = opts.sucheSpalte[String(klasse)] ?? ''
    const sichtbar = inSpalte.filter((s) => passtZurSuche(s, opts.sucheGlobal) && passtZurSuche(s, suche))
    return { klasse, gesamt: inSpalte.length, sichtbar: sortiere(sichtbar, opts.sortierung) }
  })
  return { spalten, trefferGesamt: spalten.reduce((n, sp) => n + sp.sichtbar.length, 0) }
}

export const ANWESENHEIT_REIHENFOLGE: AttendanceStatus[] = [
  'present',
  'cancelled',
  'unexcused',
  'cancelled_by_us',
  'planned',
]

/** Anzahl Sessions je Anwesenheitszustand (fuer die Summe ueber der Liste). */
export function summeJeZustand(zustaende: AttendanceStatus[]): Record<AttendanceStatus, number> {
  const summe = Object.fromEntries(ANWESENHEIT_REIHENFOLGE.map((z) => [z, 0])) as Record<AttendanceStatus, number>
  for (const z of zustaende) summe[z] += 1
  return summe
}

/**
 * Live-Pruefung des Notizfelds gegen die Wortliste "gesundheit" — dieselbe
 * Regel wie akte_wortliste_treffer() in der Datenbank (kleingeschrieben;
 * nur_ganzes_wort ueber Wortgrenzen, sonst Wortteil). Verbindlich bleibt die
 * Pruefung in notiz_anlegen.
 */
export function gesundheitsTreffer(text: string, liste: WortlisteEintrag[]): string | null {
  const t = text.toLocaleLowerCase('de')
  const sortiert = [...liste].sort((a, b) => a.wort.localeCompare(b.wort))
  for (const w of sortiert) {
    if (w.nur_ganzes_wort) {
      const muster = w.wort.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      if (new RegExp(`(^|[^\\p{L}\\p{N}_])${muster}($|[^\\p{L}\\p{N}_])`, 'u').test(t)) return w.wort
    } else if (t.includes(w.wort)) {
      return w.wort
    }
  }
  return null
}
