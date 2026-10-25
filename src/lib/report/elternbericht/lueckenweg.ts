// Eltern-Bericht v3 — Seite 3 „Einordnung“: erst was sitzt, dann was fehlt.
//
// Ein kommendes Schulthema T baut DIREKT auf einem geprüften Bereich g auf,
// wenn es im Voraussetzungsgraphen eine Kante s → g gibt (s setzt g voraus)
// und T das Heimat-Thema von s ist (skill_thema). Nur eine Kante, keine Kette.
//
// „Kommt noch“ sind die Plan-Einträge nach dem aktuellen Thema (kommtNoch aus
// lernweg.ts). Jeder Bereich steht in genau EINEM Themenblock: dem ersten
// kommenden Thema im Plan, das auf ihm aufbaut. Die übrigen Themen stehen als
// „betrifft auch …“ daneben. So erscheint kein Bereich doppelt und keiner fehlt:
//   - mit kommendem Thema  → im Block dieses Themas (sitzt bzw. fehlt),
//   - sicher, ohne Thema   → „Weitere Stärken“,
//   - Übungsbedarf, ohne   → „Weitere Bereiche mit Übungsbedarf“ (Thema der LSA
//                            zuerst, dann je Themenfeld).
// Unsichere Vorgriffe zählen nicht als Lücke (wie überall im Bericht).

import { feldPosition } from '@/lib/report/elternbericht/themenfelder'
import type {
  EbBereich,
  EbKommtThema,
  EbLueckenGruppe,
  EbLueckenweg,
  EbZuordnung,
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

/** Die übrigen Lücken: erst das Thema der LSA, dann je Themenfeld. */
function gruppiere(rest: readonly EbBereich[], raum: ReadonlySet<string>, thema: string | null): EbLueckenGruppe[] {
  const imThema = thema ? rest.filter((b) => raum.has(b.skillKey)) : []
  const sonst = rest.filter((b) => !imThema.includes(b))
  return [
    ...(imThema.length > 0 ? [{ feld: null, thema, labels: imThema.map((b) => b.label) }] : []),
    ...[...new Set(sonst.map((b) => b.feld))]
      .sort((a, b) => feldPosition(a) - feldPosition(b))
      .map((feld) => ({ feld, thema: null, labels: sonst.filter((b) => b.feld === feld).map((b) => b.label) })),
  ]
}

export function baueLueckenweg(e: LueckenwegEingabe): EbLueckenweg {
  const heimat = new Map<string, Set<string>>()
  for (const h of e.heimatThemen) heimat.set(h.skillKey, (heimat.get(h.skillKey) ?? new Set()).add(h.themaKey))
  const themenVon = new Map<string, Set<string>>()
  for (const k of e.kanten) {
    for (const t of heimat.get(k.skillKey) ?? []) {
      themenVon.set(k.voraussetzt, (themenVon.get(k.voraussetzt) ?? new Set()).add(t))
    }
  }

  // Kommende Themen in Plan-Reihenfolge, jedes Thema einmal.
  const kommt: (PlanEintrag & { themaKey: string })[] = []
  for (const p of e.kommt) {
    if (p.themaKey !== null && !kommt.some((x) => x.themaKey === p.themaKey)) kommt.push({ ...p, themaKey: p.themaKey })
  }
  const themenFuer = (b: EbBereich) => kommt.filter((p) => themenVon.get(b.skillKey)?.has(p.themaKey) ?? false)

  const bloecke = new Map<string, EbKommtThema>(
    kommt.map((p) => [p.themaKey, { titel: p.titel, halbjahr: p.halbjahr, sitzt: [], fehlt: [] }]),
  )
  const ohneSicher: EbBereich[] = []
  const ohneUebung: EbBereich[] = []
  for (const b of [...e.bereiche].sort(nachKlasseLabel)) {
    const [erstes, ...weitere] = themenFuer(b)
    if (!erstes) {
      if (b.sicher) ohneSicher.push(b)
      else ohneUebung.push(b)
      continue
    }
    const z: EbZuordnung = { label: b.label, auch: weitere.map((p) => p.titel) }
    const block = bloecke.get(erstes.themaKey)!
    if (b.sicher) block.sitzt.push(z)
    else block.fehlt.push(z)
  }

  return {
    themen: [...bloecke.values()].filter((k) => k.sitzt.length + k.fehlt.length > 0),
    weitereStaerken: ohneSicher.map((b) => b.label),
    weitere: gruppiere(ohneUebung, e.raum, e.thema),
    quelle: e.plan?.quelle ?? 'klp',
    schulname: e.plan?.schulname ?? null,
  }
}

/** Stufen des Ausdünnens für Seite 3; die letzte ist die knappste. */
export const LUECKENWEG_STUFEN = 5

/** Höchstzahl der Themenblöcke je Stufe (Index = Stufe). */
const BLOECKE = [Infinity, Infinity, 4, 4, 3]

const kuerze = <T,>(liste: readonly T[], n: number): { liste: T[]; rest: number } => ({
  liste: liste.slice(0, n),
  rest: Math.max(0, liste.length - n),
})

/**
 * Seite 3 dünnt aus, bis sie passt, Schritt für Schritt (jede Stufe behält die vorigen):
 *   Stufe 1: je Kasten höchstens drei Bereiche, Rest als Zahl; übrige Lücken je
 *            Gruppe höchstens drei Namen, weitere Stärken höchstens sechs,
 *   Stufe 2: höchstens vier Themenblöcke (die frühesten im Plan); die Bereiche der
 *            übrigen wandern zu „Weitere Stärken“ bzw. in die Gruppe „spätere Themen“,
 *   Stufe 3: übrige Lücken und weitere Stärken nur noch als Zahl,
 *   Stufe 4: höchstens drei Themenblöcke.
 * Was wegfällt, steht als Zahl oder in einer Gruppe da, nichts verschwindet still.
 */
export function duenneLueckenweg(lw: EbLueckenweg, stufe: number): EbLueckenweg {
  if (stufe <= 0) return lw
  const max = BLOECKE[Math.min(stufe, BLOECKE.length - 1)]
  const ab = lw.themen.slice(max)
  const spaeterLuecken = ab.flatMap((k) => k.fehlt.map((z) => z.label))
  const n = stufe >= 3 ? 0 : 3
  const gruppen: EbLueckenGruppe[] = [
    ...(spaeterLuecken.length > 0 ? [{ feld: null, thema: null, spaeter: true, labels: spaeterLuecken }] : []),
    ...lw.weitere,
  ].map((g) => {
    const { liste, rest } = kuerze(g.labels, n)
    return { ...g, labels: liste, rest }
  })
  const st = kuerze([...lw.weitereStaerken, ...ab.flatMap((k) => k.sitzt.map((z) => z.label))], stufe >= 3 ? 0 : 6)
  return {
    ...lw,
    themen: lw.themen.slice(0, max).map((k) => {
      const s = kuerze(k.sitzt, 3)
      const f = kuerze(k.fehlt, 3)
      return { ...k, sitzt: s.liste, fehlt: f.liste, restSitzt: s.rest, restFehlt: f.rest }
    }),
    weitereStaerken: st.liste,
    weitereStaerkenRest: st.rest,
    weitere: gruppen,
  }
}
