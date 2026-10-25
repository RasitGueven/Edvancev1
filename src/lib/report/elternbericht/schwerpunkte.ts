// Eltern-Bericht R7 — die Schwerpunkte für Seite 1 und 4 (Entscheidung 7).
//
// Kandidaten sind Themenfelder mit mindestens einem Bereich mit Übungsbedarf.
// Reihenfolge:
//   1. gemischt zuerst (Sicheres und Übungsbedarf im selben Feld) — dort
//      „beginnen wir bei dem, was schon klappt",
//   2. dann die tiefste Stufe unter den Übungsbedarf-Bereichen (5/6 vor 7/8
//      vor 9/10),
//   3. dann mehr Übungsbedarf vor weniger,
//   4. dann die Reihenfolge der Themenfelder.
// Höchstens vier; die übrigen gehen in `danach`, in derselben Reihenfolge.
//
// Bericht v2 — Startlogik nach dem Stand der Klassenarbeit zum Thema:
//   bevorstehend oder unbekannt → das Thema zuerst (Regel unten),
//   geschrieben → zuerst die Felder, auf denen ein kommendes Schulthema direkt
//   aufbaut (Planrang endlich), dann das Thema, dann der Rest.
// Jeder Schwerpunkt trägt seinen Grund (grundVon), abgeleitet aus denselben Daten.
//
// Mit Thema der LSA (R7-11, Gründer 22.10.2026) ist Schwerpunkt 1 das Thema
// selbst, sofern es dort Übungsbedarf gibt: nur direkt geprüfte Bereiche im
// Themenraum, in der Thema-Reihenfolge (Voraussetzungen zuerst). Danach die Breite — Themenfelder
// mit Übungsbedarf außerhalb des Raums, zuerst die, die für das nächste
// Schulthema gebraucht werden (Planrang), dann nach der Regel oben. Ohne Thema
// gilt die Regel oben unverändert.

import { nachFeldKlasseLabel } from '@/lib/report/elternbericht/bereiche'
import { THEMENFELDER, feldPosition } from '@/lib/report/elternbericht/themenfelder'
import { stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import type {
  EbBereich,
  EbGrund,
  EbSchwerpunkt,
  KlassenarbeitStatus,
  HeimatThema,
  LwKante,
  PlanEintrag,
  Stufe,
  ThemenfeldKey,
} from '@/types'

export const MAX_SCHWERPUNKTE = 4

const STUFEN_RANG: Readonly<Record<Stufe, number>> = { erprobung: 0, erste: 1, zweite: 2 }

/** Alles, was die Thema-Regel braucht (R7-11). Ohne Thema: null. */
export type ThemaKontext = {
  /** Label des Themas (Suchweg.themaLabel, wie im Thema-Satz von R7-6). */
  thema: string
  /** Themenraum: einstieg ∪ darunter, dieselbe Quelle wie themaAbdeckung. */
  raum: ReadonlySet<string>
  /** Schlüssel aller direkt geprüften Bereiche (für die Thema-Reihenfolge). */
  geprueft: ReadonlySet<string>
  kanten: readonly LwKante[]
  heimatThemen: readonly HeimatThema[]
  /** Die Plan-Einträge nach der aktuellen Position (kommtNoch aus lernweg.ts). */
  kommt: readonly PlanEintrag[]
}

type Kandidat = EbSchwerpunkt & { feld: ThemenfeldKey; tiefste: number; planrang: number }

function kandidat(
  feld: ThemenfeldKey,
  bereiche: readonly EbBereich[],
  planrang: (b: EbBereich) => number,
): Kandidat | null {
  const drin = bereiche.filter((b) => b.feld === feld).sort(nachFeldKlasseLabel)
  const uebung = drin.filter((b) => !b.sicher)
  if (uebung.length === 0) return null
  const sicher = drin.filter((b) => b.sicher)
  return {
    feld,
    thema: null,
    gemischt: sicher.length > 0,
    sicher: sicher.map((b) => b.label),
    uebung: uebung.map((b) => b.label),
    start: null,
    naechster: null,
    tiefste: Math.min(...uebung.map((b) => STUFEN_RANG[stufeAusKlasse(b.klasse)])),
    planrang: Math.min(...uebung.map(planrang)),
  }
}

/** R7, Entscheidung 7: gemischt zuerst, dann tiefste Stufe, mehr Übungsbedarf, Feldfolge. */
const nachRegel = (a: Kandidat, b: Kandidat): number =>
  Number(b.gemischt) - Number(a.gemischt) ||
  a.tiefste - b.tiefste ||
  b.uebung.length - a.uebung.length ||
  feldPosition(a.feld) - feldPosition(b.feld)

/**
 * Die Thema-Reihenfolge (R7-11, Entscheidung 2): entlang skill_kante innerhalb
 * des Themenraums, Voraussetzungen zuerst. Rang eines Bereichs = die meisten
 * direkt geprüften Voraussetzungen auf einem Weg dorthin. Nicht geprüfte
 * Bereiche des Raums leiten den Weg weiter, zählen aber nicht als Stufe — sonst
 * hinge die Startstelle davon ab, wie viele Zwischenschritte der Graph zufällig
 * hat. Jede Kante zwischen zwei geprüften Bereichen hebt den Rang, die
 * Reihenfolge ist also topologisch. Gleichstand nach Klasse, dann Label. Nur
 * die übergebenen Bereiche kommen zurück.
 */
export function themaReihenfolge(
  bereiche: readonly EbBereich[],
  raum: ReadonlySet<string>,
  kanten: readonly LwKante[],
  geprueft: ReadonlySet<string> = new Set(bereiche.map((b) => b.skillKey)),
): EbBereich[] {
  const voraus = new Map<string, string[]>()
  for (const k of kanten) {
    if (!raum.has(k.skillKey) || !raum.has(k.voraussetzt)) continue
    voraus.set(k.skillKey, [...(voraus.get(k.skillKey) ?? []), k.voraussetzt])
  }
  const rang = new Map<string, number>()
  const unterwegs = new Set<string>()
  const rangVon = (key: string): number => {
    const fertig = rang.get(key)
    if (fertig !== undefined) return fertig
    // Ein Kreis im Graphen darf die Rechnung nicht aufhängen: dort endet der Weg.
    if (unterwegs.has(key)) return 0
    unterwegs.add(key)
    const r = Math.max(0, ...(voraus.get(key) ?? []).map((v) => rangVon(v) + Number(geprueft.has(v))))
    unterwegs.delete(key)
    rang.set(key, r)
    return r
  }
  return [...bereiche].sort(
    (a, b) =>
      rangVon(a.skillKey) - rangVon(b.skillKey) ||
      a.klasse - b.klasse ||
      a.label.localeCompare(b.label, 'de'),
  )
}

/**
 * Planrang eines Bereichs (R7-11, Entscheidung 4): die kleinste Position unter
 * den Kommt-noch-Einträgen, deren Thema das Heimat-Thema des Bereichs ist oder
 * eines Bereichs, der direkt auf ihm aufbaut. Infinity ohne Treffer.
 */
export function planrangVon(k: ThemaKontext): (b: EbBereich) => number {
  const heimat = new Map<string, string[]>()
  for (const h of k.heimatThemen) heimat.set(h.skillKey, [...(heimat.get(h.skillKey) ?? []), h.themaKey])
  const nachfolger = new Map<string, string[]>()
  for (const e of k.kanten) nachfolger.set(e.voraussetzt, [...(nachfolger.get(e.voraussetzt) ?? []), e.skillKey])
  return (b) => {
    const themen = new Set(
      [b.skillKey, ...(nachfolger.get(b.skillKey) ?? [])].flatMap((s) => heimat.get(s) ?? []),
    )
    const i = k.kommt.findIndex((p) => p.themaKey !== null && themen.has(p.themaKey))
    return i < 0 ? Infinity : i
  }
}

/**
 * Der Thema-Schwerpunkt: nur direkt geprüfte Bereiche im Raum. null ohne
 * Übungsbedarf im Thema — dann ist das Thema kein Schwerpunkt (R7-11,
 * Nachbesserung 3).
 */
function themaSchwerpunkt(bereiche: readonly EbBereich[], k: ThemaKontext): EbSchwerpunkt | null {
  const drin = themaReihenfolge(
    bereiche.filter((b) => k.raum.has(b.skillKey)),
    k.raum,
    k.kanten,
    k.geprueft,
  )
  const uebung = drin.filter((b) => !b.sicher)
  const sicher = drin.filter((b) => b.sicher)
  const start = uebung[0]
  if (!start) return null
  // Wer baut direkt auf der Startstelle auf? Der erste in der Thema-Reihenfolge.
  const darauf = new Set(k.kanten.filter((e) => e.voraussetzt === start.skillKey).map((e) => e.skillKey))
  return {
    feld: null,
    thema: k.thema,
    gemischt: sicher.length > 0,
    sicher: sicher.map((b) => b.label),
    uebung: uebung.map((b) => b.label),
    start: start.label,
    naechster: uebung.find((b) => darauf.has(b.skillKey))?.label ?? null,
  }
}

const STUFE_VON_RANG: readonly Stufe[] = ['erprobung', 'erste', 'zweite']

/**
 * Der Grund eines Feld-Schwerpunkts: kommendes Thema, sonst Grundlagen, sonst
 * Anzahl. Bauen mehrere Felder auf dasselbe kommende Thema auf und liegen sie in
 * verschiedenen Klassenbändern, nennt der Grund das Band (Regel siehe
 * nachPlanrang): der erste „zuerst, weil Stoff aus Klasse 5/6“, die übrigen
 * „danach, weil Stoff aus Klasse 7/8“.
 */
function feldGrund(k: Kandidat, alle: readonly Kandidat[], kommt: readonly PlanEintrag[]): EbGrund {
  if (Number.isFinite(k.planrang)) {
    const titel = kommt[k.planrang].titel
    const gruppe = alle.filter((x) => x.planrang === k.planrang)
    const baender = new Set(gruppe.map((x) => x.tiefste))
    if (gruppe.length < 2 || baender.size < 2) return { art: 'naechstesThema', titel }
    const stufe = STUFE_VON_RANG[k.tiefste]
    return gruppe[0] === k
      ? { art: 'naechstesThema', titel, stufe, reihe: 'zuerst' }
      : { art: 'naechstesThema', titel, stufe, reihe: 'danach' }
  }
  if (k.tiefste === STUFEN_RANG.erprobung) return { art: 'grundlagen' }
  return { art: 'anzahl', count: k.uebung.length }
}

/**
 * Der Grund des Thema-Schwerpunkts nach dem Stand der Klassenarbeit. Ist sie
 * geschrieben, ist das Thema eine vorhandene Lücke: Baut ein kommendes Thema
 * laut Graph darauf auf, nennt der Grund es („wird beim … wieder gebraucht“).
 */
function themaGrund(klassenarbeit: KlassenarbeitStatus | null, spaeter: string | null): EbGrund {
  if (klassenarbeit === 'bevorstehend') return { art: 'klassenarbeit' }
  if (klassenarbeit !== 'geschrieben') return { art: 'thema' }
  return spaeter ? { art: 'spaeterGebraucht', titel: spaeter } : { art: 'themaGeschrieben' }
}

/**
 * Reihenfolge der Felder (Bericht v3): zuerst nach Planrang (das früheste
 * kommende Schulthema, das direkt auf einer Lücke aufbaut). Bei GLEICHEM
 * kommenden Thema das frühere Klassenband zuerst (tiefste Stufe der Lücken) —
 * was früher im Lehrplan kommt, wird zuerst gefestigt; erst bei gleichem Band die
 * Regel aus R7 (nachRegel). Ohne kommendes Thema gilt nachRegel unverändert.
 */
const nachPlanrang = (a: Kandidat, b: Kandidat): number => {
  if (a.planrang !== b.planrang) return a.planrang < b.planrang ? -1 : 1
  if (Number.isFinite(a.planrang) && a.tiefste !== b.tiefste) return a.tiefste - b.tiefste
  return nachRegel(a, b)
}

export function waehleSchwerpunkte(
  bereiche: readonly EbBereich[],
  kontext: ThemaKontext | null = null,
  klassenarbeit: KlassenarbeitStatus | null = null,
): {
  schwerpunkte: EbSchwerpunkt[]
  danach: ThemenfeldKey[]
} {
  const { schwerpunkte, danach } = schwerpunkteMitGrund(bereiche, kontext, klassenarbeit)
  return { schwerpunkte: schwerpunkte.map(({ grund: _g, ...s }) => s), danach }
}

/**
 * Wie waehleSchwerpunkte, dazu je Schwerpunkt sein Grund (Bericht v2/v3) — als
 * eigene Liste in derselben Reihenfolge, damit EbSchwerpunkt für Präsentation
 * und Druck gleich bleibt.
 */
export function schwerpunkteMitGrund(
  bereiche: readonly EbBereich[],
  kontext: ThemaKontext | null = null,
  klassenarbeit: KlassenarbeitStatus | null = null,
): {
  schwerpunkte: (EbSchwerpunkt & { grund: EbGrund })[]
  danach: ThemenfeldKey[]
} {
  const breite = kontext ? bereiche.filter((b) => !kontext.raum.has(b.skillKey)) : bereiche
  const planrang = kontext ? planrangVon(kontext) : () => Infinity
  const felder = THEMENFELDER.flatMap(({ key }) => kandidat(key, breite, planrang) ?? []).sort(nachPlanrang)
  const kommt = kontext?.kommt ?? []
  const fertig = felder.map((k): EbSchwerpunkt & { grund: EbGrund } => {
    const { tiefste: _t, planrang: _p, ...s } = k
    return { ...s, grund: feldGrund(k, felder, kommt) }
  })

  // Planrang des Themas: über seine Lücken, wie bei den Feldern.
  const roh = kontext ? themaSchwerpunkt(bereiche, kontext) : null
  const themaRang = roh
    ? Math.min(Infinity, ...bereiche.filter((b) => !b.sicher && kontext!.raum.has(b.skillKey)).map(planrang))
    : Infinity
  const spaeter = Number.isFinite(themaRang) ? kommt[themaRang].titel : null
  const thema = roh ? { ...roh, grund: themaGrund(klassenarbeit, spaeter) } : null

  // Klassenarbeit geschrieben: erst die Voraussetzungen kommender Schulthemen —
  // das Thema reiht sich nach seinem Planrang ein (bei Gleichstand nach den
  // Feldern). Es bleibt unter den vier (es fiele sonst aus `danach`, das nur Felder kennt).
  const vorThema =
    thema && klassenarbeit === 'geschrieben'
      ? Math.min(
          felder.filter((f) => Number.isFinite(f.planrang) && f.planrang <= themaRang).length,
          MAX_SCHWERPUNKTE - 1,
        )
      : 0
  const reihe = thema ? [...fertig.slice(0, vorThema), thema, ...fertig.slice(vorThema)] : fertig
  return {
    schwerpunkte: reihe.slice(0, MAX_SCHWERPUNKTE),
    danach: reihe.slice(MAX_SCHWERPUNKTE).flatMap((s) => (s.feld ? [s.feld] : [])),
  }
}

/**
 * Seite 1, Listen mit Thema (R7-11, Entscheidung 7): die Bereiche des Themas
 * zuerst in der Thema-Reihenfolge, dann der Rest in der bisherigen Reihenfolge.
 */
export function themaZuerst(liste: readonly EbBereich[], kontext: ThemaKontext | null): EbBereich[] {
  if (!kontext) return [...liste]
  const drin = liste.filter((b) => kontext.raum.has(b.skillKey))
  return [
    ...themaReihenfolge(drin, kontext.raum, kontext.kanten, kontext.geprueft),
    ...liste.filter((b) => !kontext.raum.has(b.skillKey)),
  ]
}
