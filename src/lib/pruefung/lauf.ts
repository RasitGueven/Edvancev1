// Lenas Prueflauf folgt dem Bedarf (P4): erst die Aufgaben, die noch fuer ein Soll fehlen, Thema fuer Thema.
// "Noetig" ist eine offene Aufgabe eines Knotens mit rest > 0 (pruef_board_soll). Reihenfolge wie in der
// Uebersicht: Stufe (aktueller Reiter zuerst, nur LSA), Thema nach sortiereThemen, Knoten nach knotenDesThemas,
// Aufgabe in Board-Reihenfolge. Ohne Sollzahlen gilt der alte Weg naechsteOffene.
// MC-Nachtrag: Fehlt einem Knoten noch "ohne MC", kommen seine Aufgaben ohne MC zuerst; fehlt nur noch das, faellt
// MC dort aus dem Lauf. Ohne Typen (mc fehlt) bleibt die Board-Reihenfolge.

import type { LenaStatus, PruefBoardZeile, PruefSollZeile, Stufe } from '@/types'
import { ersteImThema, naechsteOffene, STUFEN_REIHENFOLGE, themenDerStufe } from './reihenfolge'
import { knotenDesThemas, sortiereThemen } from './soll'

export type LaufGrund = 'gleiches_thema' | 'themenwechsel' | 'stufenwechsel' | 'ohne_soll' | 'fertig'

export type LaufSchritt = { taskId: string | null; grund: LaufGrund }

export type LaufOptionen = {
  /** Reiter, mit dem der Lauf ohne aktuelle Aufgabe beginnt (Uebersicht); sonst der erste mit Bedarf. */
  start?: Stufe | null
  /** false im Session-Bereich: keine Stufen-Reiter, kein Stufenwechsel. */
  stufen?: boolean
  /** "Weitere Aufgaben ohne Soll pruefen": ab da der alte Weg. */
  ohneSoll?: boolean
  /** task_ids mit input_type MC; null/fehlend = Typen unbekannt, dann keine MC-Regel. */
  mc?: ReadonlySet<string> | null
}

type Block = { stufe: Stufe; thema_key: string; zeilen: PruefBoardZeile[] }

/**
 * Die noetigen offenen Aufgaben eines Knotens. Fehlt noch "ohne MC" (gezaehlt_ohne_mc < min_ohne_mc): erst ohne MC,
 * dann MC; ist das Soll sonst erreicht (gezaehlt >= soll), sind die MC-Aufgaben nicht noetig.
 */
export function noetigImKnoten(zeilen: PruefBoardZeile[], s: PruefSollZeile, mc?: ReadonlySet<string> | null): PruefBoardZeile[] {
  const offen = zeilen.filter((z) => z.lena_status === 'offen')
  if (!mc || s.gezaehlt_ohne_mc >= s.min_ohne_mc) return offen
  const ohne = offen.filter((z) => !mc.has(z.task_id))
  return s.gezaehlt >= s.soll ? ohne : [...ohne, ...offen.filter((z) => mc.has(z.task_id))]
}

/** Die noetigen offenen Aufgaben je Thema, in Uebersichts-Reihenfolge; Stufen in STUFEN_REIHENFOLGE. */
function bloecke(board: PruefBoardZeile[], soll: PruefSollZeile[], mc?: ReadonlySet<string> | null): Block[] {
  const noetig = new Map(soll.filter((s) => s.rest > 0).map((s) => [s.skill_key, s]))
  return STUFEN_REIHENFOLGE.flatMap((stufe) =>
    sortiereThemen(themenDerStufe(board, stufe), soll).map((g) => ({
      stufe,
      thema_key: g.thema_key,
      zeilen: knotenDesThemas(g, soll).flatMap((k) => {
        const s = k.skill_key === null ? undefined : noetig.get(k.skill_key)
        return s ? noetigImKnoten(k.zeilen, s, mc) : []
      }),
    })))
}

/** Die naechste Aufgabe eines Themas: erst die nicht uebersprungenen, dann die uebersprungenen in Skip-Reihenfolge. */
function ausBlock(b: Block, aktuell: string | null, uebersprungen: string[]): string | null {
  const kandidaten = b.zeilen.filter((z) => z.task_id !== aktuell)
  const skip = new Set(uebersprungen)
  const frei = kandidaten.find((z) => !skip.has(z.task_id))
  if (frei) return frei.task_id
  const ids = new Set(kandidaten.map((z) => z.task_id))
  return uebersprungen.find((id) => ids.has(id)) ?? null
}

/**
 * Die naechste noetige Aufgabe nach `aktuell`. Bleibt im Thema, solange dort noch etwas noetig ist (auch wenn es
 * im Board weiter vorn liegt), dann das naechste Thema der Stufe (danach von vorn), dann die naechste Stufe.
 * Ohne aktuelle Aufgabe beginnt der Lauf im Reiter `start` und meldet 'gleiches_thema' (kein Zwischenbild).
 */
export function naechsteNoetige(
  board: PruefBoardZeile[],
  soll: PruefSollZeile[] | null,
  aktuell: string | null,
  uebersprungen: string[] = [],
  opt: LaufOptionen = {},
): LaufSchritt {
  if (opt.ohneSoll || !soll?.length) {
    return { taskId: naechsteOffene(board, aktuell, uebersprungen), grund: 'ohne_soll' }
  }
  const alle = bloecke(board, soll, opt.mc)
  const mitStufen = opt.stufen ?? true
  const jetzt = board.find((z) => z.task_id === aktuell)
  const stufeStart = jetzt?.stufe ?? opt.start
    ?? STUFEN_REIHENFOLGE.find((s) => alle.some((b) => b.stufe === s && ausBlock(b, null, uebersprungen)))
  // Session: eine einzige Folge ueber alle Stufen. LSA: der aktuelle Reiter zuerst, dann die uebrigen.
  const folge = mitStufen && stufeStart
    ? [...alle.filter((b) => b.stufe === stufeStart), ...alle.filter((b) => b.stufe !== stufeStart)]
    : alle
  const hier = jetzt ? folge.findIndex((b) => b.thema_key === jetzt.thema_key) : -1
  if (hier >= 0) {
    const id = ausBlock(folge[hier], aktuell, uebersprungen)
    if (id) return { taskId: id, grund: 'gleiches_thema' }
  }
  // Nach dem aktuellen Thema weiter, innerhalb der Stufe danach von vorn; erst dann die naechste Stufe.
  const gleicheStufe = (b: Block): boolean => !mitStufen || !jetzt || b.stufe === jetzt.stufe
  const reihe = [
    ...folge.slice(hier + 1).filter(gleicheStufe),
    ...folge.slice(0, Math.max(hier, 0)).filter(gleicheStufe),
    ...folge.filter((b) => !gleicheStufe(b)),
  ]
  for (const b of reihe) {
    const id = ausBlock(b, aktuell, uebersprungen)
    if (!id) continue
    if (!jetzt) return { taskId: id, grund: 'gleiches_thema' }
    return { taskId: id, grund: gleicheStufe(b) ? 'themenwechsel' : 'stufenwechsel' }
  }
  return { taskId: null, grund: 'fertig' }
}

/** "Pruefen" je Thema: die erste noetige offene Aufgabe des Themas, sonst wie ersteImThema. */
export function ersteNoetigeImThema(
  board: PruefBoardZeile[], soll: PruefSollZeile[], themaKey: string, mc?: ReadonlySet<string> | null,
): string | null {
  const b = bloecke(board, soll, mc).find((x) => x.thema_key === themaKey)
  return b?.zeilen[0]?.task_id ?? ersteImThema(board, themaKey)
}

/** "noch n noetig im Thema": Summe der Restbedarfe der Knoten des Themas; null ohne Soll. */
export function restImThema(soll: PruefSollZeile[] | null, themaKey: string): number | null {
  const z = (soll ?? []).filter((s) => s.thema_key === themaKey)
  return z.length ? z.reduce((n, s) => n + s.rest, 0) : null
}

/** Entscheidung 8: Knoten mit Restbedarf, aber ohne offene Aufgabe im Board (hier fehlen Aufgaben). */
export function knotenOhneAufgabe(board: PruefBoardZeile[], soll: PruefSollZeile[]): PruefSollZeile[] {
  const offen = new Set(board.filter((z) => z.lena_status === 'offen').map((z) => z.skill_key))
  return soll.filter((s) => s.rest > 0 && !offen.has(s.skill_key))
}

const zaehlt = (s: LenaStatus): number => (s === 'passt' || s === 'freigegeben' ? 1 : 0)

/**
 * Den Knoten einer Aufgabe nach einer Entscheidung (oder Rueckgaengig) lokal nachrechnen, wie pruef_board_soll:
 * gezaehlt sind passt und freigegeben; MC zaehlt nicht fuer min_ohne_mc.
 */
export function nachrechnen(
  soll: PruefSollZeile[],
  skillKey: string | null,
  vorher: LenaStatus,
  nachher: LenaStatus,
  mc: boolean,
): PruefSollZeile[] {
  const d = zaehlt(nachher) - zaehlt(vorher)
  if (!d || !skillKey) return soll
  return soll.map((s) => {
    if (s.skill_key !== skillKey) return s
    const gezaehlt = s.gezaehlt + d
    const gezaehlt_ohne_mc = s.gezaehlt_ohne_mc + (mc ? 0 : d)
    return {
      ...s, gezaehlt, gezaehlt_ohne_mc,
      rest: Math.max(s.soll - gezaehlt, s.min_ohne_mc - gezaehlt_ohne_mc, 0),
      reicht: gezaehlt >= s.soll && gezaehlt_ohne_mc >= s.min_ohne_mc,
    }
  })
}
