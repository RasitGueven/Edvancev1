// Eltern-Bericht R7-9 — was worauf aufbaut (Entscheidung 8).
//
// Aus den Kanten mit direkt geprüfter Basis werden ↳-Einträge (Ziel in
// derselben Insel) und goldene Linien (Ziel woanders, nur von sicheren Basen).
// Die Grenzen schneiden ab; was wegfällt, wird gezählt, nicht gezeigt.

import type { LwKante } from '@/types'

/** Wo ein Ziel steht: in einer Insel, und ob es direkt geprüft ist. */
export type ZielOrt = {
  insel: string
  /** Direkt geprüft (sonst „noch nicht geprüft“). */
  geprueft: boolean
  /** Insel in Kommt noch. */
  kommt: boolean
}

export type Grenzen = {
  /** Höchstens so viele Linien. */
  linien: number
  /** Höchstens so viele nicht geprüfte Einträge je Insel. */
  offenJeInsel: number
  /** … und insgesamt. */
  offenGesamt: number
  /** Höchstens so viele Plan-Themen in Kommt noch (und in der nächsten Klasse). */
  kommt: number
}

/** Entscheidung 8 und 9. Der Druck kürzt bei Platzmangel (Entscheidung 18). */
export const GRENZEN: Grenzen = { linien: 6, offenJeInsel: 2, offenGesamt: 8, kommt: 6 }

/** Die Kürzungsstufen des Drucks, in dieser Reihenfolge (Entscheidung 18). */
export const KUERZUNGEN: readonly Grenzen[] = [
  GRENZEN,
  { ...GRENZEN, offenJeInsel: 1 },
  { ...GRENZEN, offenJeInsel: 1, linien: 4 },
  { ...GRENZEN, offenJeInsel: 1, linien: 4, kommt: 4 },
]

export type Bezug = { basis: string; ziel: string }

export type KantenErgebnis = {
  /** Ziel → Basen derselben Insel, in der Reihenfolge der Insel. */
  unter: Map<string, string[]>
  /** Die Linien nach Vorrang, schon begrenzt. */
  linien: Bezug[]
  /** Nicht geprüfte Ziele, die erscheinen (über ↳ oder Linie). */
  offen: Set<string>
  weggelassen: { linien: number; offen: number }
}

export type KantenEingabe = {
  kanten: readonly LwKante[]
  /** Direkt geprüfte Bereiche: Schlüssel → Insel, sicher; in Anzeige-Reihenfolge. */
  direkt: ReadonlyMap<string, { insel: string; sicher: boolean }>
  /** Ort eines Ziels; null, wenn es nicht gezeigt werden kann (unbekannter Skill). */
  ort: (ziel: string) => ZielOrt | null
  grenzen: Grenzen
}

/**
 * Teilt die Kanten mit direkt geprüfter Basis auf. Reihenfolge der Basen wie
 * in `direkt`; Linien-Vorrang: Ziel in Kommt noch, dann geprüftes Ziel, dann
 * der Rest; bei Gleichstand die Basis mit mehr Zielen. Danach die Grenzen für
 * nicht geprüfte Einträge: zuerst die der Linien (in deren Vorrang), dann die
 * der ↳-Einträge. Fällt ein nicht geprüftes Linienziel weg, fällt die Linie mit.
 */
export function teileKanten({ kanten, direkt, ort, grenzen }: KantenEingabe): KantenErgebnis {
  const rang = new Map([...direkt.keys()].map((k, i) => [k, i]))
  const relevant = kanten
    .filter((k) => k.skillKey !== k.voraussetzt && direkt.has(k.voraussetzt))
    .map((k) => ({ basis: k.voraussetzt, ziel: k.skillKey, ort: ort(k.skillKey) }))
    .filter((k): k is Bezug & { ort: ZielOrt } => k.ort !== null)
    // Doppelte Kanten zählen einmal.
    .filter((k, i, alle) => alle.findIndex((x) => x.basis === k.basis && x.ziel === k.ziel) === i)

  const unter = new Map<string, string[]>()
  const kandidaten: (Bezug & { ort: ZielOrt })[] = []
  for (const k of relevant) {
    const basis = direkt.get(k.basis)!
    if (k.ort.insel === basis.insel) {
      unter.set(k.ziel, [...(unter.get(k.ziel) ?? []), k.basis])
    } else if (basis.sicher) {
      kandidaten.push(k)
    }
  }
  for (const [ziel, basen] of unter) unter.set(ziel, basen.sort((a, b) => rang.get(a)! - rang.get(b)!))

  // Ein geprüftes Ziel, das selbst ↳-Einträge trägt, rückt nicht ein (keine
  // zweite Stufe); es bleibt an seinem Platz und verliert nur das ↳.
  const traeger = new Set([...unter.values()].flat())
  for (const ziel of [...unter.keys()]) {
    if (direkt.has(ziel) && traeger.has(ziel)) unter.delete(ziel)
  }

  const zielZahl = new Map<string, number>()
  for (const k of kandidaten) zielZahl.set(k.basis, (zielZahl.get(k.basis) ?? 0) + 1)
  const stufe = (o: ZielOrt): number => (o.kommt ? 0 : o.geprueft ? 1 : 2)
  kandidaten.sort(
    (a, b) =>
      stufe(a.ort) - stufe(b.ort) ||
      zielZahl.get(b.basis)! - zielZahl.get(a.basis)! ||
      rang.get(a.basis)! - rang.get(b.basis)! ||
      a.ziel.localeCompare(b.ziel),
  )
  const gewaehlt = kandidaten.slice(0, grenzen.linien)
  let wegLinien = kandidaten.length - gewaehlt.length

  // Nicht geprüfte Einträge begrenzen: je Insel und insgesamt.
  const offen = new Set<string>()
  const jeInsel = new Map<string, number>()
  const wegOffen = new Set<string>()
  const nimm = (ziel: string, insel: string): boolean => {
    if (offen.has(ziel)) return true
    const n = jeInsel.get(insel) ?? 0
    if (n >= grenzen.offenJeInsel || offen.size >= grenzen.offenGesamt) return false
    offen.add(ziel)
    jeInsel.set(insel, n + 1)
    return true
  }
  const linien: Bezug[] = []
  for (const k of gewaehlt) {
    if (k.ort.geprueft || nimm(k.ziel, k.ort.insel)) linien.push({ basis: k.basis, ziel: k.ziel })
    else {
      wegLinien += 1
      wegOffen.add(k.ziel)
    }
  }
  for (const [ziel, basen] of [...unter]) {
    if (direkt.has(ziel)) continue
    if (!nimm(ziel, direkt.get(basen[0])!.insel)) {
      unter.delete(ziel)
      wegOffen.add(ziel)
    }
  }
  return { unter, linien, offen, weggelassen: { linien: wegLinien, offen: [...wegOffen].filter((z) => !offen.has(z)).length } }
}
