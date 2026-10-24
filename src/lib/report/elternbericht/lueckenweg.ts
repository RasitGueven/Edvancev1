// Eltern-Bericht v2 — Seite 3: die Lücken und was im Schuljahr darauf aufbaut.
//
// Ein kommendes Schulthema T baut DIREKT auf einem geprüften Bereich g auf,
// wenn es im Voraussetzungsgraphen eine Kante s → g gibt (s setzt g voraus)
// und T das Heimat-Thema von s ist (skill_thema). Nur eine Kante, keine Kette:
// Was über mehrere Schritte zusammenhängt, zeigt der Bericht nicht.
//
// „Kommt noch“ sind die Plan-Einträge nach dem aktuellen Thema (kommtNoch,
// derselbe Plan wie im Lernweg). Themen ohne Bezug zu einem geprüften Bereich
// fallen weg. Unsichere Vorgriffe zählen nicht als Lücke (wie überall).

import { feldPosition } from '@/lib/report/elternbericht/themenfelder'
import type {
  EbBereich,
  EbKommtThema,
  EbLueckenGruppe,
  EbLueckenweg,
  HeimatThema,
  LernPlan,
  LwKante,
  PlanEintrag,
} from '@/types'

export type LueckenwegEingabe = {
  /** Gezählte Bereiche (ohne unsichere Vorgriffe), Labels schon für Eltern. */
  bereiche: readonly EbBereich[]
  kanten: readonly LwKante[]
  heimatThemen: readonly HeimatThema[]
  plan: LernPlan | null
  /** kommtNoch(...) aus lernweg.ts. */
  kommt: readonly PlanEintrag[]
  /** Themenraum der LSA und sein Label; ohne Thema leer bzw. null. */
  raum: ReadonlySet<string>
  thema: string | null
}

const nachKlasseLabel = (a: EbBereich, b: EbBereich): number =>
  a.klasse - b.klasse || a.label.localeCompare(b.label, 'de')

export function baueLueckenweg(e: LueckenwegEingabe): EbLueckenweg {
  const heimat = new Map<string, Set<string>>()
  for (const h of e.heimatThemen) heimat.set(h.skillKey, (heimat.get(h.skillKey) ?? new Set()).add(h.themaKey))

  // Je geprüftem Bereich: die Themen, deren Bereiche direkt auf ihm aufbauen.
  const themenVon = new Map<string, Set<string>>()
  for (const k of e.kanten) {
    for (const t of heimat.get(k.skillKey) ?? []) {
      themenVon.set(k.voraussetzt, (themenVon.get(k.voraussetzt) ?? new Set()).add(t))
    }
  }
  const baut = (b: EbBereich, themaKey: string | null): boolean =>
    themaKey !== null && (themenVon.get(b.skillKey)?.has(themaKey) ?? false)

  const sortiert = [...e.bereiche].sort(nachKlasseLabel)
  const gesehen = new Set<string>()
  const themen: EbKommtThema[] = e.kommt.flatMap((p) => {
    // Ein Thema, das zweimal im Plan steht, nur beim ersten Mal.
    if (p.themaKey === null || gesehen.has(p.themaKey)) return []
    gesehen.add(p.themaKey)
    const drauf = sortiert.filter((b) => baut(b, p.themaKey))
    if (drauf.length === 0) return []
    return [
      {
        titel: p.titel,
        halbjahr: p.halbjahr,
        luecken: drauf.filter((b) => !b.sicher).map((b) => b.label),
        staerken: drauf.filter((b) => b.sicher).map((b) => b.label),
      },
    ]
  })

  const mitBezug = (b: EbBereich): boolean => [...gesehen].some((k) => baut(b, k))

  // Die übrigen Lücken: erst das Thema der LSA, dann je Themenfeld.
  const rest = sortiert.filter((b) => !b.sicher && !mitBezug(b))
  const imThema = rest.filter((b) => e.raum.has(b.skillKey))
  const weitere: EbLueckenGruppe[] = [
    ...(imThema.length > 0 && e.thema ? [{ feld: null, thema: e.thema, labels: imThema.map((b) => b.label) }] : []),
    ...[...new Set(rest.filter((b) => !e.raum.has(b.skillKey) || !e.thema).map((b) => b.feld))]
      .sort((a, b) => feldPosition(a) - feldPosition(b))
      .map((feld) => ({
        feld,
        thema: null,
        labels: rest.filter((b) => b.feld === feld && (!e.raum.has(b.skillKey) || !e.thema)).map((b) => b.label),
      })),
  ]

  const sicher = sortiert.filter((b) => b.sicher)
  return {
    themen,
    weitere,
    staerken: sicher.filter(mitBezug).map((b) => b.label),
    sicherGesamt: sicher.length,
    quelle: e.plan?.quelle ?? 'klp',
    schulname: e.plan?.schulname ?? null,
  }
}

/** Stufen des Ausdünnens für Seite 3; die letzte ist die knappste. */
export const LUECKENWEG_STUFEN = 6

/** Höchstzahl der Themen-Zeilen je Stufe (Index = Stufe). */
const ZEILEN = [Infinity, 6, 4, 4, 4, 3]

const kuerze = (labels: readonly string[], n: number): { labels: string[]; rest: number } => ({
  labels: labels.slice(0, n),
  rest: Math.max(0, labels.length - n),
})

/**
 * Seite 3 dünnt aus, bis sie passt (Auftrag: „Inhalte ausdünnen“), Schritt für
 * Schritt, jeder Schritt behält die vorigen:
 *   1. höchstens sechs Themen-Zeilen (die frühesten im Plan); Lücken der übrigen
 *      Themen, die in keiner Zeile stehen, kommen in die Gruppe „spätere Themen“;
 *      übrige Lücken je Gruppe höchstens drei Namen, Rest als Zahl,
 *   2. höchstens vier Zeilen, je Zeile höchstens drei Lücken, ohne „Sitzt schon“,
 *   3. übrige Lücken nur noch als Zahl je Gruppe,
 *   4. Stärken nur noch als Zahl,
 *   5. höchstens drei Zeilen.
 * Was wegfällt, steht als Zahl oder in einer Gruppe da, nichts verschwindet still.
 */
export function duenneLueckenweg(lw: EbLueckenweg, stufe: number): EbLueckenweg {
  if (stufe <= 0) return lw
  const zeilen = lw.themen.filter((k) => k.luecken.length > 0)
  const max = ZEILEN[Math.min(stufe, ZEILEN.length - 1)]
  const gezeigt = zeilen.slice(0, max)
  const sichtbar = new Set(gezeigt.flatMap((k) => k.luecken))
  const spaeter = [...new Set(zeilen.slice(max).flatMap((k) => k.luecken))].filter((l) => !sichtbar.has(l))
  const gruppen: EbLueckenGruppe[] = [
    ...(spaeter.length > 0 ? [{ feld: null, thema: null, spaeter: true, labels: spaeter }] : []),
    ...lw.weitere,
  ].map((g) => ({ ...g, ...kuerze(g.labels, stufe >= 3 ? 0 : 3) }))
  const themen = gezeigt.map((k) => {
    if (stufe < 2) return k
    const { labels, rest } = kuerze(k.luecken, 3)
    return { ...k, luecken: labels, rest, zeileOhneStaerken: true }
  })
  // Der Stärken-Satz rechnet mit allen Themen weiter (dort stehen sie nur als Titel).
  const nurStaerken = lw.themen.filter((k) => !gezeigt.includes(k)).map((k) => ({ ...k, luecken: [] }))
  return { ...lw, themen: [...themen, ...nurStaerken], weitere: gruppen, staerken: stufe >= 4 ? [] : lw.staerken }
}
