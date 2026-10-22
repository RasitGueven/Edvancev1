// Eltern-Bericht R7-9/R7-12 — einen fertigen Lernweg kürzen, bis er passt.
//
// Seite 3 geht die Stufen aus KUERZUNGEN nacheinander durch (Entscheidung 18),
// die volle Karte in Station 03 beginnt bei Stufe 4 (R7-12, Entscheidung 9).
// Bis Stufe 3 fallen nicht geprüfte Einträge, Linien und Kommt noch; ab R7-12
// auch geprüfte Einträge je Insel („+ n weitere“) und ganze Zonen (Zählzeilen).

import type { Grenzen } from '@/lib/report/elternbericht/lernwegKanten'
import type { Lernweg, LwInsel, LwLinie, LwStand, LwZaehlzeile, LwZone } from '@/types'

/** Startstelle und nächster Bereich des Thema-Schwerpunkts (Labels; EbSchwerpunkt.start/naechster). */
export type ThemaVorrang = { start: string | null; naechster: string | null } | null

type Zeile = { id: string; label: string; stand: LwStand; basis: string | null; rang: number }

const zeilenVon = (i: LwInsel): Zeile[] => {
  const z: Zeile[] = []
  for (const e of i.eintraege) {
    z.push({ id: e.id, label: e.label, stand: e.stand, basis: null, rang: z.length })
    for (const u of e.unter) z.push({ id: u.id, label: u.label, stand: u.stand, basis: e.id, rang: z.length })
  }
  return z
}

const STAND_RANG: Record<LwStand, number> = { uebung: 2, sicher: 3, vorgriff: 4, offen: 5 }

/**
 * Welche Zeilen einer Insel bleiben (R7-12, Entscheidung 3): Linienenden immer
 * (auch über die Grenze), dann Startstelle und nächster Bereich des Themas
 * (erster Treffer je Label), dann Übungsbedarf vor sicher vor noch nicht
 * behandelt (LSA-V2) vor nicht geprüft,
 * sonst die Reihenfolge der Insel. Ein ↳ bleibt nur mit seiner Basis.
 */
export function waehleZeilen(
  i: LwInsel,
  grenze: number,
  enden: ReadonlySet<string>,
  thema: ThemaVorrang,
): { bleibt: Set<string>; weg: Zeile[] } {
  const zeilen = zeilenVon(i)
  if (zeilen.length <= grenze) return { bleibt: new Set(zeilen.map((z) => z.id)), weg: [] }
  const wichtig = new Set(
    [thema?.start, thema?.naechster]
      .filter((l): l is string => Boolean(l))
      .map((l) => zeilen.find((z) => z.label === l)?.id)
      .filter((id): id is string => id !== undefined),
  )
  const rang = (z: Zeile): number => (enden.has(z.id) ? 0 : wichtig.has(z.id) ? 1 : STAND_RANG[z.stand])
  const sortiert = [...zeilen].sort((a, b) => rang(a) - rang(b) || a.rang - b.rang)

  const bleibt = new Set<string>()
  for (const z of zeilen) {
    if (!enden.has(z.id)) continue
    bleibt.add(z.id)
    if (z.basis) bleibt.add(z.basis)
  }
  // Nach jeder Aufnahme von vorn: Eine eben aufgenommene Basis gibt ihr ↳ frei.
  for (let neu = true; neu; ) {
    neu = false
    for (const z of sortiert) {
      if (bleibt.size >= grenze) break
      if (bleibt.has(z.id) || (z.basis && !bleibt.has(z.basis))) continue
      bleibt.add(z.id)
      neu = true
      break
    }
  }
  return { bleibt, weg: zeilen.filter((z) => !bleibt.has(z.id)) }
}

/** Zählzeilen einer Zone je Themenfeld, nur mit Zahlen > 0 (Entscheidung 5). */
function zaehlzeilen(z: LwZone): LwZaehlzeile[] {
  return z.inseln.flatMap((i) => {
    const s = zeilenVon(i)
    const sicher = s.filter((x) => x.stand === 'sicher').length
    const uebung = s.filter((x) => x.stand === 'uebung').length
    return i.feld && sicher + uebung > 0 ? [{ feld: i.feld, sicher, uebung }] : []
  })
}

/**
 * Kürzt einen fertigen Lernweg (Entscheidung 18, R7-12 Entscheidungen 1–6), in
 * dieser Reihenfolge: nicht geprüfte Einträge je Insel, Kommt noch, Linien,
 * zusammengefasste Zonen, Zeilen je Insel. Behält jeweils die vorderen (Linien
 * sind schon nach Vorrang sortiert). Ein nicht geprüfter Eintrag, der nur
 * wegen einer Linie da war, geht mit ihr.
 */
export function kuerzeLernweg(lw: Lernweg, g: Grenzen, thema: ThemaVorrang = null): Lernweg {
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
  // 3. Kommt noch (vor den Linien, damit Linien in weggefallene Inseln mitgehen). LSA-V2: Eine Insel mit
  // einem geprüften Eintrag (Vorgriff) bleibt, auch hinter der Grenze.
  const kommt = lw.zonen.find((z) => z.key === 'kommt')
  const bleibtKommt = (i: LwInsel, n: number): boolean => n < g.kommt || i.eintraege.some((e) => e.stand !== 'offen')
  for (const i of kommt?.inseln.filter((x, n) => !bleibtKommt(x, n)) ?? []) for (const e of i.eintraege) raus.add(e.id)
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
  let zonen: LwZone[] = lw.zonen.map((z) => ({
    ...z,
    inseln: (z.key === 'kommt' ? z.inseln.filter(bleibtKommt) : z.inseln)
      .map((i) => ({
        ...i,
        eintraege: i.eintraege
          .filter((e) => !(e.stand === 'offen' && raus.has(e.id)))
          .map((e) => ({ ...e, unter: e.unter.filter((u) => !raus.has(u.id)) })),
      }))
      // Eine Insel, die nur aus weggefallenen nicht geprüften Einträgen bestand, fällt weg.
      .filter((i) => i.titel !== null || i.eintraege.length > 0),
  }))
  const offenIn = (zs: LwZone[]): number =>
    zs.flatMap((z) => z.inseln.flatMap((i) => i.eintraege.flatMap((e) => [e, ...e.unter]))).filter((e) => e.stand === 'offen').length
  weg.offen += offenIn(lw.zonen) - offenIn(zonen)
  weg.kommt += (kommt?.inseln.length ?? 0) - (kommt?.inseln.filter(bleibtKommt).length ?? 0)

  // 4. Zonen zusammenfassen: Linien aus der Zone beginnen an ihrer Zählung,
  // Linien in die Zone fallen weg.
  let gezogen: LwLinie[] = behalten
  for (const key of g.zusammenfassen) {
    const z = zonen.find((x) => x.key === key)
    if (!z || z.inseln.length === 0) continue
    const ids = new Set(z.inseln.flatMap((i) => zeilenVon(i).map((x) => x.id)))
    const zusammen = { id: `zs-${key}`, zeilen: zaehlzeilen(z) }
    const vorher = gezogen.length
    gezogen = gezogen
      .filter((l) => !ids.has(l.zu))
      .map((l) => (ids.has(l.von) ? { von: zusammen.id, zu: l.zu } : l))
    weg.linien += vorher - gezogen.length
    gezogen = gezogen.filter((l, n, alle) => alle.findIndex((x) => x.von === l.von && x.zu === l.zu) === n)
    zonen = zonen.map((x) => (x === z ? { key: z.key, inseln: [], zusammen } : x))
    weg.zonen += 1
  }

  // 5. Zeilen je Insel; Linienenden bleiben immer.
  const enden = new Set(gezogen.flatMap((l) => [l.von, l.zu]))
  zonen = zonen.map((z) => ({
    ...z,
    inseln: z.inseln.map((i) => {
      const { bleibt, weg: fort } = waehleZeilen(i, g.eintraegeJeInsel, enden, thema)
      if (fort.length === 0) return i
      weg.eintraege += fort.length
      const zahl = (s: LwStand): number => fort.filter((x) => x.stand === s).length
      return {
        ...i,
        eintraege: i.eintraege
          .filter((e) => bleibt.has(e.id))
          .map((e) => ({ ...e, unter: e.unter.filter((u) => bleibt.has(u.id)) })),
        weitere: {
          uebung: zahl('uebung'),
          sicher: zahl('sicher'),
          offen: zahl('offen'),
          vorgriff: zahl('vorgriff'),
          labels: fort.map((x) => x.label),
        },
      }
    }),
  }))
  return { ...lw, zonen, linien: gezogen, weggelassen: weg }
}
