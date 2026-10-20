// Eltern-Bericht R7-9 — der Lernweg (Entscheidungen 5–10): Grundlagen →
// Weiterführend → Aktuell → Kommt noch. Einmal gerechnet; Seite 3 und
// Station 03 zeigen dasselbe Ergebnis (bericht.lernweg, PraesentationDaten.lernweg).
//
// Kennungen der Inseln und Einträge sind eigene (i1, e1 …): Der Bogen rendert
// keine Skill-Schlüssel, auch nicht als Attribut (INV-4.3).

import { nachFeldKlasseLabel } from '@/lib/report/elternbericht/bereiche'
import { elternLabel } from '@/lib/report/elternbericht/elternLabel'
import { GRENZEN, teileKanten, type Grenzen, type ZielOrt } from '@/lib/report/elternbericht/lernwegKanten'

export { GRENZEN, KUERZUNGEN, type Grenzen } from '@/lib/report/elternbericht/lernwegKanten'
import { aktuellePosition, stufeVon } from '@/lib/report/elternbericht/plan'
import { THEMENFELDER, feldVon } from '@/lib/report/elternbericht/themenfelder'
import type {
  EbBereich,
  HeimatThema,
  KatalogSkill,
  LernPlan,
  Lernweg,
  LwEintrag,
  LwInsel,
  LwKante,
  LwStand,
  LwZoneKey,
  Stufe,
  ThemenfeldKey,
} from '@/types'

export type LernwegEingabe = {
  /** Direkt geprüfte Bereiche (bereicheAus: Labels schon für Eltern). */
  bereiche: readonly EbBereich[]
  /** Klasse der Sitzung. */
  klasse: number
  kanten: readonly LwKante[]
  katalog: readonly KatalogSkill[]
  heimatThemen: readonly HeimatThema[]
  plan: LernPlan | null
  /** Thema der Sitzung (lsa_sessions.thema_key); null ohne Thema. */
  themaKey: string | null
  /** Label des Themas für „Aktuell“. */
  thema: string | null
  /** Datum der Sitzung (data.analysedAt). */
  datum: string | null
}

const STUFEN: readonly Stufe[] = ['erprobung', 'erste', 'zweite']
const ZONE_DER_STUFE: Record<Stufe, LwZoneKey> = {
  erprobung: 'grundlagen',
  erste: 'weiterfuehrend',
  zweite: 'aktuell',
}

/** Zone eines Bereichs: Stufen vor der des Kindes links, alles ab ihr in Aktuell. */
export function zoneFuer(bereichKlasse: number, kindKlasse: number): LwZoneKey {
  const s = STUFEN.indexOf(stufeVon(bereichKlasse))
  const kind = STUFEN.indexOf(stufeVon(kindKlasse))
  return s >= kind ? 'aktuell' : ZONE_DER_STUFE[STUFEN[s]]
}

/** Die Zonen für ein Kind dieser Klasse, von links nach rechts. */
export function zonenFuer(kindKlasse: number): LwZoneKey[] {
  const kind = STUFEN.indexOf(stufeVon(kindKlasse))
  return [
    ...(kind > 0 ? (['grundlagen'] as const) : []),
    ...(kind > 1 ? (['weiterfuehrend'] as const) : []),
    'aktuell',
    'kommt',
  ]
}

const FELD_RANG = new Map(THEMENFELDER.map((f, i) => [f.key, i]))
const standVon = (b: EbBereich): LwStand => (b.sicher ? 'sicher' : 'uebung')

type InselBau = {
  zone: LwZoneKey
  feld: ThemenfeldKey | null
  titel: string | null
  themaKey: string | null
  direkt: EbBereich[]
  offen: { key: string; label: string; klasse: number | null }[]
}

export function baueLernweg(e: LernwegEingabe, grenzen: Grenzen = GRENZEN): Lernweg {
  const inseln = new Map<string, InselBau>()
  const inselFuer = (zone: LwZoneKey, feld: ThemenfeldKey): string => {
    const key = `${zone}|${feld}`
    if (!inseln.has(key)) inseln.set(key, { zone, feld, titel: null, themaKey: null, direkt: [], offen: [] })
    return key
  }

  // Direkt geprüfte Bereiche: je Zone und Themenfeld eine Insel.
  const sortiert = [...e.bereiche].sort((a, b) => Number(b.sicher) - Number(a.sicher) || nachFeldKlasseLabel(a, b))
  for (const b of sortiert) inseln.get(inselFuer(zoneFuer(b.klasse, e.klasse), b.feld))!.direkt.push(b)

  // Kommt noch: die Plan-Einträge nach der aktuellen Position, höchstens grenzen.kommt.
  const plan = e.plan?.eintraege ?? []
  const nachher = plan.slice(aktuellePosition(plan, e.themaKey, e.datum) + 1)
  const kommtKeys = nachher.slice(0, grenzen.kommt).map((p, i) => {
    const key = `kommt|${i}`
    inseln.set(key, { zone: 'kommt', feld: null, titel: p.titel, themaKey: p.themaKey, direkt: [], offen: [] })
    return key
  })

  // Wo jedes Ziel steht.
  const katalog = new Map(e.katalog.map((k) => [k.skillKey, k]))
  const direkt = new Map<string, { insel: string; sicher: boolean }>()
  for (const [key, insel] of inseln) for (const b of insel.direkt) direkt.set(b.skillKey, { insel: key, sicher: b.sicher })
  const heimat = new Map<string, string[]>()
  for (const h of e.heimatThemen) heimat.set(h.skillKey, [...(heimat.get(h.skillKey) ?? []), h.themaKey])
  const offenOrt = new Map<string, { insel: string; label: string; klasse: number }>()
  const ort = (ziel: string): ZielOrt | null => {
    const d = direkt.get(ziel)
    if (d) return { insel: d.insel, geprueft: true, kommt: false }
    const kat = katalog.get(ziel)
    if (!kat) return null
    const themen = heimat.get(ziel) ?? []
    const imPlan = kommtKeys.find((k) => themen.includes(inseln.get(k)!.themaKey ?? ''))
    const insel = imPlan ?? `${zoneFuer(kat.klasse, e.klasse)}|${feldVon(ziel)}`
    offenOrt.set(ziel, { insel, label: elternLabel(kat.label), klasse: kat.klasse })
    return { insel, geprueft: false, kommt: Boolean(imPlan) }
  }
  const teil = teileKanten({ kanten: e.kanten, direkt, ort, grenzen })

  // Nicht geprüfte Ziele mit Linie stehen als eigener Eintrag in ihrer Insel.
  const unterZiele = new Set(teil.unter.keys())
  for (const ziel of teil.offen) {
    if (unterZiele.has(ziel)) continue
    const o = offenOrt.get(ziel)!
    const [zone, feld] = o.insel.split('|') as [LwZoneKey, string]
    const key = zone === 'kommt' ? o.insel : inselFuer(zone, feld as ThemenfeldKey)
    inseln.get(key)!.offen.push({ key: ziel, label: o.label, klasse: o.klasse })
  }

  // Kennungen und Einträge.
  let nr = 0
  const id = new Map<string, string>()
  const eintragId = (key: string): string => {
    if (!id.has(key)) id.set(key, `e${++nr}`)
    return id.get(key)!
  }
  const ziehtEin = new Set([...teil.unter.keys()].filter((z) => direkt.has(z)))
  const bereichVon = new Map(e.bereiche.map((b) => [b.skillKey, b]))
  const unterVon = (basis: string) =>
    [...teil.unter]
      .filter(([, basen]) => basen[basen.length - 1] === basis)
      .map(([ziel, basen]) => {
        const b = bereichVon.get(ziel)
        return {
          id: eintragId(ziel),
          label: b ? b.label : offenOrt.get(ziel)!.label,
          stand: b ? standVon(b) : ('offen' as const),
          basen: basen.map(eintragId),
        }
      })

  const zonen = zonenFuer(e.klasse).map((zone) => {
    const keys = [...inseln.keys()].filter((k) => inseln.get(k)!.zone === zone)
    if (zone !== 'kommt') keys.sort((a, b) => FELD_RANG.get(inseln.get(a)!.feld!)! - FELD_RANG.get(inseln.get(b)!.feld!)!)
    const fertig: LwInsel[] = keys.map((key) => {
      const i = inseln.get(key)!
      const eintraege: LwEintrag[] = [
        ...i.direkt
          .filter((b) => !ziehtEin.has(b.skillKey))
          .map((b) => ({
            id: eintragId(b.skillKey),
            label: b.label,
            stand: standVon(b),
            klasse: b.klasse,
            spaeter: b.klasse > e.klasse,
            unter: unterVon(b.skillKey),
          })),
        ...i.offen.map((o) => ({
          id: eintragId(o.key),
          label: o.label,
          stand: 'offen' as const,
          klasse: o.klasse,
          spaeter: false,
          unter: [],
        })),
      ]
      const uebung = i.direkt.filter((b) => !b.sicher).length
      return {
        id: '',
        zone,
        feld: i.feld,
        titel: i.titel,
        eintraege,
        broeckelt: uebung >= 2 && uebung > i.direkt.length - uebung,
      }
    })
    return { key: zone, inseln: fertig }
  })

  // Führende leere Zonen fallen weg; Lücken zwischen Zonen mit Inhalt bleiben.
  const erste = zonen.findIndex((z) => z.inseln.length > 0 || z.key === 'aktuell')
  const sichtbar = zonen.slice(Math.max(0, erste))

  let inr = 0
  for (const z of sichtbar) for (const i of z.inseln) i.id = `i${++inr}`
  const naechste = e.plan?.naechsteKlasse
  const naechsteKlasse = naechste
    ? {
        klasse: naechste.klasse,
        inseln: naechste.eintraege.slice(0, grenzen.kommt).map((p) => ({
          id: `i${++inr}`,
          zone: 'kommt' as const,
          feld: null,
          titel: p.titel,
          eintraege: [],
          broeckelt: false,
        })),
      }
    : null

  return {
    klasse: e.klasse,
    zonen: sichtbar,
    linien: teil.linien.map((l) => ({ von: eintragId(l.basis), zu: eintragId(l.ziel) })),
    naechsteKlasse,
    quelle: e.plan?.quelle ?? 'klp',
    schulname: e.plan?.schulname ?? null,
    thema: e.thema,
    datum: e.datum,
    weggelassen: { ...teil.weggelassen, kommt: Math.max(0, nachher.length - grenzen.kommt) },
  }
}

/**
 * Kürzt einen fertigen Lernweg für den Druck (Entscheidung 18), in dieser
 * Reihenfolge: nicht geprüfte Einträge je Insel, Linien, Plan-Themen in Kommt
 * noch. Behält jeweils die vorderen (Linien sind schon nach Vorrang sortiert).
 * Ein nicht geprüfter Eintrag, der nur wegen einer Linie da war, geht mit ihr.
 */
export function kuerzeLernweg(lw: Lernweg, g: Grenzen): Lernweg {
  const linien = [...lw.linien]
  const weg = { ...lw.weggelassen }
  const raus = new Set<string>()

  // 1. nicht geprüfte Einträge je Insel
  for (const z of lw.zonen) {
    for (const i of z.inseln) {
      let n = 0
      for (const e of i.eintraege) {
        for (const u of e.unter) if (u.stand === 'offen' && ++n > g.offenJeInsel) raus.add(u.id)
        if (e.stand === 'offen' && ++n > g.offenJeInsel) raus.add(e.id)
      }
    }
  }
  // 3. Kommt noch (vor den Linien, damit Linien in weggefallene Inseln mitgehen)
  const kommt = lw.zonen.find((z) => z.key === 'kommt')
  for (const i of kommt?.inseln.slice(g.kommt) ?? []) for (const e of i.eintraege) raus.add(e.id)
  // 2. Linien
  const behalten = linien.filter((l) => !raus.has(l.zu)).slice(0, g.linien)
  const mitLinie = new Set(behalten.map((l) => l.zu))
  // Nur eigenständige nicht geprüfte Einträge hängen an ihrer Linie; ↳-Einträge
  // und geprüfte Ziele bleiben.
  const nurWegenLinie = new Set(
    lw.zonen.flatMap((z) => z.inseln.flatMap((i) => i.eintraege.filter((e) => e.stand === 'offen').map((e) => e.id))),
  )
  for (const l of linien) if (!mitLinie.has(l.zu) && nurWegenLinie.has(l.zu)) raus.add(l.zu)

  weg.linien += linien.length - behalten.length
  const zonen = lw.zonen.map((z) => ({
    ...z,
    inseln: (z.key === 'kommt' ? z.inseln.slice(0, g.kommt) : z.inseln)
      .map((i) => ({
        ...i,
        eintraege: i.eintraege
          .filter((e) => !(e.stand === 'offen' && raus.has(e.id)))
          .map((e) => ({ ...e, unter: e.unter.filter((u) => !raus.has(u.id)) })),
      }))
      // Eine Insel, die nur aus weggefallenen nicht geprüften Einträgen bestand, fällt weg.
      .filter((i) => i.titel !== null || i.eintraege.length > 0),
  }))
  const offenVorher = lw.zonen.flatMap((z) => z.inseln.flatMap((i) => i.eintraege.flatMap((e) => [e, ...e.unter]))).filter((e) => e.stand === 'offen').length
  const offenNachher = zonen.flatMap((z) => z.inseln.flatMap((i) => i.eintraege.flatMap((e) => [e, ...e.unter]))).filter((e) => e.stand === 'offen').length
  weg.offen += offenVorher - offenNachher
  weg.kommt += Math.max(0, (kommt?.inseln.length ?? 0) - g.kommt)
  return { ...lw, zonen, linien: behalten, weggelassen: weg }
}
