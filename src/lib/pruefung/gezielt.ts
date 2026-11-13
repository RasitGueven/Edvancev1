// FR-2 F3: gezielte Prüfliste für Lena (pruef_ziel_liste). Reine Rechnungen für die Übersicht und den Lauf in der
// Prüfansicht (?liste=gezielt): Reihenfolge der Aufgaben, nächste offene Aufgabe, Stand und Gruppen nach Thema.

import type { LsaWirkungZeile, PruefBoardZeile, PruefZielStandZeile, PruefZielZeile } from '@/types'

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

// ── IU-1 U3: Prüfziel (z. B. MSA) ─────────────────────────────────────────────────────────────────────────────────

export type ZielBereich = {
  bereich: string
  /** Kompetenzen mit Vorschlägen für Lena (Zeilen der Liste), in Listenreihenfolge, mit Stand (texte). */
  offen: { zeile: PruefZielZeile; texte: number }[]
  /** Kompetenzen, die die Regel schon erfüllen (eingeklappt mit Haken). */
  erledigt: PruefZielStandZeile[]
  /** Kompetenzen ohne Erfüllung und ohne Vorschlag (Aufgaben fehlen). */
  ohneVorschlag: PruefZielStandZeile[]
}

/** Gruppen nach Bereich des Prüfziels; Reihenfolge der Bereiche wie im Stand (alphabetisch aus der Datenbank). */
export function zielBereiche(liste: PruefZielZeile[], stand: PruefZielStandZeile[]): ZielBereich[] {
  const zeile = new Map(liste.filter((z) => z.abschnitt === 'gezielt').map((z) => [z.skill_key, z]))
  const je = new Map<string, ZielBereich>()
  for (const s of stand) {
    const g = je.get(s.bereich) ?? { bereich: s.bereich, offen: [], erledigt: [], ohneVorschlag: [] }
    const z = zeile.get(s.skill_key)
    if (s.erfuellt) g.erledigt.push(s)
    else if (z) g.offen.push({ zeile: z, texte: s.texte })
    else g.ohneVorschlag.push(s)
    je.set(s.bereich, g)
  }
  for (const g of je.values()) g.offen.sort((a, b) => a.zeile.sort - b.zeile.sort)
  return [...je.values()]
}

/** Fortschritt zum Prüfziel in Prozent: belegte Texte über alle Kompetenzen (erledigte zählen mit). */
export function zielAnteil(stand: PruefZielStandZeile[], regel = 2): number {
  if (stand.length === 0) return 100
  const ist = stand.reduce((n, s) => n + Math.min(s.texte, regel), 0)
  return Math.round((ist / (stand.length * regel)) * 100)
}

// ── IU-1b: Prüfziel und Kompetenz im Lauf der Prüfansicht ─────────────────────────────────────────────────────────
export const PRUEFZIELE = ['msa_zp10'] as const

export type ZielFilter = { ziel: string | null; skill: string | null }

/** ?ziel= (nur bekannte Prüfziele) und ?skill= aus der Adresse. */
export function leseZielFilter(params: URLSearchParams): ZielFilter {
  const z = params.get('ziel')
  return { ziel: (PRUEFZIELE as readonly string[]).includes(z ?? '') ? z : null, skill: params.get('skill') || null }
}

/** Anhang für die Adresse, z. B. „&ziel=msa_zp10&skill=x“; ohne Filter leer (alles wie bisher). */
export function zielAnhang(f: ZielFilter): string {
  const s = new URLSearchParams()
  if (f.ziel) s.set('ziel', f.ziel)
  if (f.skill) s.set('skill', f.skill)
  const q = s.toString()
  return q ? `&${q}` : ''
}

/** Prüfansicht aus „Gezielt prüfen“, mit Prüfziel und Kompetenz, damit der Lauf in derselben Liste bleibt. */
export function pruefansichtPfad(taskId: string, f: ZielFilter): string {
  return `/coach/pruefen/${taskId}?bereich=lsa&liste=gezielt${zielAnhang(f)}`
}
