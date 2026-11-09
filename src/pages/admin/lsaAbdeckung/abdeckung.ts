// FR-2 F2: reine Rechnungen der Seite LSA-Abdeckung (Matrix, Kennzahlen, Wirkung einer Freigabe). Ohne React,
// damit die Tests sie direkt prüfen.

import type { LsaAbdeckungZeile, LsaAmpel } from '@/types'

export type Kennzahlen = { gruen: number; gelb: number; rot: number; schulenBereit: number; schulen: number }

/** Pakete je Ampel und Schulen mit mindestens einem grünen oder gelben Paket. */
export function kennzahlen(zeilen: LsaAbdeckungZeile[]): Kennzahlen {
  const bereit = new Set<string>()
  const alle = new Set<string>()
  const n: Record<LsaAmpel, number> = { gruen: 0, gelb: 0, rot: 0 }
  for (const z of zeilen) {
    n[z.ampel] += 1
    alle.add(z.schule_id)
    if (z.ampel !== 'rot') bereit.add(z.schule_id)
  }
  return { ...n, schulenBereit: bereit.size, schulen: alle.size }
}

export type MatrixZeile = {
  schuleId: string
  schule: string
  klasse: number
  fokus: boolean
  /** Index = Spalte; null = an dieser Stelle kein Paket. */
  zellen: (LsaAbdeckungZeile | null)[]
}

/**
 * Zeilen = Schulen (Fokus oben, dann Name), Spalten = Pakete in Schuljahr-Reihenfolge. Die Spalte ist die Stelle des
 * Pakets in der Folge der Schule (nach paket_nr); bei mehreren Klassen im Filter je Klasse eine eigene Zeile.
 */
export function matrix(zeilen: LsaAbdeckungZeile[]): { zeilen: MatrixZeile[]; spalten: number } {
  const je = new Map<string, MatrixZeile>()
  for (const z of [...zeilen].sort((a, b) => a.paket_nr - b.paket_nr)) {
    const key = `${z.schule_id}:${z.klasse}`
    const m = je.get(key) ?? { schuleId: z.schule_id, schule: z.schule, klasse: z.klasse, fokus: z.fokus, zellen: [] }
    m.zellen.push(z)
    je.set(key, m)
  }
  const liste = [...je.values()].sort(
    (a, b) => Number(b.fokus) - Number(a.fokus) || a.schule.localeCompare(b.schule, 'de'),
  )
  return { zeilen: liste, spalten: Math.max(0, ...liste.map((m) => m.zellen.length)) }
}

export const paketKey = (z: Pick<LsaAbdeckungZeile, 'schule_id' | 'klasse' | 'paket_nr'>): string =>
  `${z.schule_id}:${z.klasse}:${z.paket_nr}`

export type Wirkung = { pakete: number; schulen: number }

/** Pakete, die von Rot auf Grün oder Gelb gewechselt sind, und an wie vielen Schulen. */
export function wirkung(vorher: LsaAbdeckungZeile[], nachher: LsaAbdeckungZeile[]): Wirkung {
  const alt = new Map(vorher.map((z) => [paketKey(z), z.ampel]))
  const neu = nachher.filter((z) => z.ampel !== 'rot' && alt.get(paketKey(z)) === 'rot')
  return { pakete: neu.length, schulen: new Set(neu.map((z) => z.schule_id)).size }
}

/** Alle IDs eines Felds über die Zeilen, ohne Doppelte, in Reihenfolge. */
export function vereinige(listen: string[][]): string[] {
  return [...new Set(listen.flat())]
}
