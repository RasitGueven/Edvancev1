// Eltern-Bericht R7-9 — Linienführung des Lernwegs (Entscheidung 11).
//
// Eingang: gemessene Rechtecke (Inseln, Einträge), die Spalten und die Linien.
// Ausgang: SVG-Pfade. Geführt wird nur in den Lücken: waagrecht in freien
// Gängen zwischen den Inseln, senkrecht in den Gassen zwischen den Spalten,
// Ecken gerundet. Linien derselben Basis teilen sich den Stamm bis zur
// Abzweigung. Dieselbe Funktion dient Druck (pt) und Präsentation (px).

export type Rechteck = { x: number; y: number; b: number; h: number }

export type LinienEingabe = {
  /** Spalten von links nach rechts (x0 < x1), Inseln liegen ganz in ihrer Spalte. */
  spalten: readonly { x0: number; x1: number }[]
  inseln: readonly { id: string; spalte: number; rect: Rechteck }[]
  eintraege: readonly { id: string; insel: string; rect: Rechteck }[]
  linien: readonly { von: string; zu: string }[]
  /** Oberkante des freien Bereichs (unter den Zonen-Überschriften). */
  oben: number
  /** Unterkante des freien Bereichs. */
  unten: number
  /** Eckenradius. */
  radius?: number
  /** Abstand einer Linie zu jeder Insel. */
  abstand?: number
  /** Länge der Spitze. */
  spitze?: number
}

export type Punkt = { x: number; y: number }

export type LinienPfad = {
  von: string
  zu: string
  /** Pfad bis zum Ansatz der Spitze. */
  d: string
  /** Dreieck der Spitze, Spitze genau am Rand der Ziel-Insel. */
  spitzeD: string
  /** Die Eckpunkte vor dem Runden (für Tests und die Fahrt). */
  punkte: Punkt[]
}

const RADIUS = 6
const ABSTAND = 5
const SPITZE = 6

type Lage = { insel: { spalte: number; rect: Rechteck }; mitteY: number }

const frei = (y: number, spalte: number, e: LinienEingabe, m: number): boolean =>
  e.inseln.every((i) => i.spalte !== spalte || y <= i.rect.y - m || y >= i.rect.y + i.rect.h + m)

/** Mitte der Gasse rechts von Spalte s (rechts der letzten: halber Abstand nach außen). */
function gasseRechts(e: LinienEingabe, s: number): number {
  const a = e.spalten[s]
  const b = e.spalten[s + 1]
  return b ? (a.x1 + b.x0) / 2 : a.x1 + (a.x1 - a.x0) * 0.04
}

/** Ein waagrechter Gang über den Spalten von..bis (ohne sie), möglichst nah an y. */
function gang(
  e: LinienEingabe,
  von: number,
  bis: number,
  y: number,
  belegt: readonly { y: number; x0: number; x1: number }[],
  x0: number,
  x1: number,
  m: number,
): number {
  const spalten: number[] = []
  for (let s = Math.min(von, bis) + 1; s < Math.max(von, bis); s++) spalten.push(s)
  const ok = (k: number): boolean =>
    k >= e.oben + m &&
    k <= e.unten - m &&
    spalten.every((s) => frei(k, s, e, m)) &&
    belegt.every((b) => Math.abs(b.y - k) >= m || b.x1 <= x0 || b.x0 >= x1)
  if (ok(y)) return y
  const kandidaten = new Set<number>([e.oben + m, e.unten - m])
  for (const i of e.inseln) {
    if (!spalten.includes(i.spalte)) continue
    kandidaten.add(i.rect.y - m)
    kandidaten.add(i.rect.y + i.rect.h + m)
  }
  for (const b of belegt) {
    kandidaten.add(b.y - m)
    kandidaten.add(b.y + m)
  }
  const sortiert = [...kandidaten].sort((a, b) => Math.abs(a - y) - Math.abs(b - y))
  return sortiert.find(ok) ?? e.unten - m
}

/** Rundet die Ecken eines achsparallelen Linienzugs. */
export function gerundet(punkte: readonly Punkt[], r: number): string {
  if (punkte.length === 0) return ''
  const z = (n: number): string => String(Math.round(n * 100) / 100)
  let d = `M${z(punkte[0].x)} ${z(punkte[0].y)}`
  for (let i = 1; i < punkte.length - 1; i++) {
    const a = punkte[i - 1]
    const p = punkte[i]
    const b = punkte[i + 1]
    const la = Math.hypot(p.x - a.x, p.y - a.y)
    const lb = Math.hypot(b.x - p.x, b.y - p.y)
    const k = Math.min(r, la / 2, lb / 2)
    const vor = { x: p.x - ((p.x - a.x) / (la || 1)) * k, y: p.y - ((p.y - a.y) / (la || 1)) * k }
    const nach = { x: p.x + ((b.x - p.x) / (lb || 1)) * k, y: p.y + ((b.y - p.y) / (lb || 1)) * k }
    d += ` L${z(vor.x)} ${z(vor.y)} Q${z(p.x)} ${z(p.y)} ${z(nach.x)} ${z(nach.y)}`
  }
  const l = punkte[punkte.length - 1]
  return `${d} L${z(l.x)} ${z(l.y)}`
}

/** Entfernt doppelte und gerade durchlaufene Punkte. */
function bereinigt(punkte: Punkt[]): Punkt[] {
  const ohne = punkte.filter((p, i) => i === 0 || Math.hypot(p.x - punkte[i - 1].x, p.y - punkte[i - 1].y) > 0.01)
  return ohne.filter((p, i) => {
    if (i === 0 || i === ohne.length - 1) return true
    const a = ohne[i - 1]
    const b = ohne[i + 1]
    return !((a.x === p.x && p.x === b.x) || (a.y === p.y && p.y === b.y))
  })
}

export function fuehreLinien(e: LinienEingabe): LinienPfad[] {
  const r = e.radius ?? RADIUS
  const m = e.abstand ?? ABSTAND
  const sp = e.spitze ?? SPITZE
  const inseln = new Map(e.inseln.map((i) => [i.id, i]))
  const lage = new Map<string, Lage>()
  for (const ein of e.eintraege) {
    const insel = inseln.get(ein.insel)
    if (insel) lage.set(ein.id, { insel, mitteY: ein.rect.y + ein.rect.h / 2 })
  }

  // Gassen-Spuren: jede Basis bekommt in jeder Gasse ihren eigenen Platz.
  const spuren = new Map<number, string[]>()
  const spur = (gasse: number, basis: string): void => {
    const liste = spuren.get(gasse) ?? []
    if (!liste.includes(basis)) spuren.set(gasse, [...liste, basis])
  }
  type Plan = { von: string; zu: string; a: Lage; z: Lage; rechts: boolean; gS: number; gZ: number }
  const plaene: Plan[] = []
  for (const l of e.linien) {
    const a = lage.get(l.von)
    const z = lage.get(l.zu)
    if (!a || !z) continue
    const sa = a.insel.spalte
    const sz = z.insel.spalte
    const letzte = sa === e.spalten.length - 1
    // Nach rechts, auch innerhalb der Spalte; in der letzten Spalte über die linke Gasse.
    const rechts = sz > sa || (sz === sa && !letzte)
    const gS = rechts ? sa : sa - 1
    const gZ = sz === sa ? gS : rechts ? sz - 1 : sz
    spur(gS, l.von)
    spur(gZ, l.von)
    plaene.push({ von: l.von, zu: l.zu, a, z, rechts, gS, gZ })
  }
  const gasseX = (g: number, basis: string): number => {
    const liste = spuren.get(g) ?? [basis]
    const i = liste.indexOf(basis)
    const breite = g >= 0 && g < e.spalten.length - 1 ? e.spalten[g + 1].x0 - e.spalten[g].x1 : 2 * m
    const schritt = Math.min(4, breite / (liste.length + 1))
    const mitte = g < 0 ? e.spalten[0].x0 - m : gasseRechts(e, g)
    return mitte + (i - (liste.length - 1) / 2) * schritt
  }

  // Ein Gang je Basis und Richtung, über alle Spalten zwischen ihr und dem weitesten Ziel.
  const belegt: { y: number; x0: number; x1: number }[] = []
  const stamm = new Map<string, number>()
  for (const p of plaene) {
    const key = `${p.von}|${p.rechts}`
    if (stamm.has(key)) continue
    const eigene = plaene.filter((q) => q.von === p.von && q.rechts === p.rechts)
    const sa = p.a.insel.spalte
    const weit = p.rechts ? Math.max(...eigene.map((q) => q.z.insel.spalte)) : Math.min(...eigene.map((q) => q.z.insel.spalte))
    const xA = gasseX(p.gS, p.von)
    const xZ = Math.max(...eigene.map((q) => gasseX(q.gZ, p.von)))
    const x0 = Math.min(xA, xZ)
    const x1 = Math.max(xA, xZ)
    const y = Math.abs(weit - sa) >= 2 ? gang(e, sa, weit, p.a.mitteY, belegt, x0, x1, m) : p.a.mitteY
    stamm.set(key, y)
    if (Math.abs(weit - sa) >= 2) belegt.push({ y, x0, x1 })
  }

  return plaene.map((p) => {
    const ar = p.a.insel.rect
    const zr = p.z.insel.rect
    const richtungZiel = p.gZ < p.z.insel.spalte ? 1 : -1
    const start = { x: p.rechts ? ar.x + ar.b : ar.x, y: p.a.mitteY }
    const ende = { x: richtungZiel === 1 ? zr.x : zr.x + zr.b, y: p.z.mitteY }
    const y = stamm.get(`${p.von}|${p.rechts}`)!
    const xS = gasseX(p.gS, p.von)
    const xZ = gasseX(p.gZ, p.von)
    const ansatz = { x: ende.x - richtungZiel * sp, y: ende.y }
    const punkte = bereinigt(
      y === start.y && p.gS !== p.gZ
        ? [start, { x: xZ, y }, { x: xZ, y: ende.y }, ansatz]
        : [start, { x: xS, y: start.y }, { x: xS, y }, { x: xZ, y }, { x: xZ, y: ende.y }, ansatz],
    )
    const h = sp * 0.55
    const spitzeD = `M${ansatz.x} ${ende.y - h} L${ende.x} ${ende.y} L${ansatz.x} ${ende.y + h} Z`
    return { von: p.von, zu: p.zu, d: gerundet(punkte, r), spitzeD, punkte: [...punkte, ende] }
  })
}

/** Schneidet ein achsparalleles Stück das Innere eines Rechtecks? (für Tests und Prüfungen) */
export function schneidet(a: Punkt, b: Punkt, rect: Rechteck, rand = 0.5): boolean {
  const x0 = rect.x + rand
  const x1 = rect.x + rect.b - rand
  const y0 = rect.y + rand
  const y1 = rect.y + rect.h - rand
  if (a.y === b.y) return a.y > y0 && a.y < y1 && Math.max(a.x, b.x) > x0 && Math.min(a.x, b.x) < x1
  return a.x > x0 && a.x < x1 && Math.max(a.y, b.y) > y0 && Math.min(a.y, b.y) < y1
}
