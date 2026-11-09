// FR-2 F3: gezielte Prüfliste für Lena (pruef_ziel_liste). Reine Rechnungen für die Übersicht und den Lauf in der
// Prüfansicht (?liste=gezielt): Reihenfolge der Aufgaben, nächste offene Aufgabe, Stand und Gruppen nach Thema.

import type { LsaWirkungZeile, PruefBoardZeile, PruefZielZeile } from '@/types'

/** Aufgaben der gezielten Liste in Reihenfolge (sort der Skills, darin die Vorschläge der Reihe nach). */
export function zielReihe(liste: PruefZielZeile[]): string[] {
  return liste
    .filter((z) => z.abschnitt === 'gezielt')
    .sort((a, b) => a.sort - b.sort)
    .flatMap((z) => z.task_ids)
}

/**
 * Nächste noch offene Aufgabe der Liste nach `nach` (sonst von vorn), ohne übersprungene. Offen heißt: im Board und
 * noch nicht entschieden. Null, wenn nichts mehr offen ist.
 */
export function naechsteZiel(
  reihe: string[],
  board: PruefBoardZeile[],
  nach: string | null,
  skip: string[] = [],
): string | null {
  const offen = new Set(board.filter((z) => z.lena_status === 'offen').map((z) => z.task_id))
  const ab = nach ? reihe.indexOf(nach) + 1 : 0
  const rund = [...reihe.slice(ab), ...reihe.slice(0, ab)]
  return rund.find((id) => id !== nach && offen.has(id) && !skip.includes(id)) ?? null
}

export type ZielStand = { offen: number; geprueft: number }

/** Wie viele Aufgaben die Liste noch braucht (Summe rest) und wie viele schon „passt“ sind (freigabe_ids). */
export function zielStand(liste: PruefZielZeile[]): ZielStand {
  const g = liste.filter((z) => z.abschnitt === 'gezielt')
  return { offen: g.reduce((n, z) => n + z.rest, 0), geprueft: g.reduce((n, z) => n + z.freigabe_ids.length, 0) }
}

export type ZielGruppe = { thema: string; schulen: number; zeilen: PruefZielZeile[] }

/** Gruppen nach Thema (Lenas Sprache), in der Reihenfolge der Liste; schulen = größter Hebel im Thema. */
export function zielGruppen(liste: PruefZielZeile[], abschnitt: PruefZielZeile['abschnitt'], ohneThema: string): ZielGruppe[] {
  const je = new Map<string, ZielGruppe>()
  for (const z of liste.filter((x) => x.abschnitt === abschnitt).sort((a, b) => a.sort - b.sort)) {
    const thema = z.thema_label ?? ohneThema
    const g = je.get(thema) ?? { thema, schulen: 0, zeilen: [] }
    g.zeilen.push(z)
    g.schulen = Math.max(g.schulen, z.hebel_schulen)
    je.set(thema, g)
  }
  return [...je.values()]
}

/** Schulen, an denen nach der Wirkung mindestens ein Paket grün oder gelb ist (aus lsa_wirkung). */
export function bereiteSchulen(wirkung: LsaWirkungZeile[]): number {
  return new Set(wirkung.filter((w) => w.ampel_nachher !== 'rot').map((w) => w.schule_id)).size
}

/** Schulen, die durch die Wirkung ihre erste LSA im Fenster bekommen (schule_neu). */
export function neueSchulen(wirkung: LsaWirkungZeile[]): number {
  return new Set(wirkung.filter((w) => w.schule_neu).map((w) => w.schule_id)).size
}
