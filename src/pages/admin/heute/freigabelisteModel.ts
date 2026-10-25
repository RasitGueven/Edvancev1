import type { PruefBoardZeile, PruefSollZeile } from '@/types'

/** Anlass von Batus Freigabeliste in pruef_soll (docs/lsa/freigabeliste-batu-1025.md, P4). */
export const ANLASS_BATU = 'batu_lsa'

export type ListenBlock = 'grundlage' | 'ka2' | 'rueckblick' | 'ausblick'

/** Block nach pruef_soll.sort (P4): unter 300 Thema/Grundlagen, 300–399 KA2, 400–899 Rückblick, ab 900 Ausblick. */
export const blockVon = (sort: number): ListenBlock =>
  sort < 300 ? 'grundlage' : sort < 400 ? 'ka2' : sort < 900 ? 'rueckblick' : 'ausblick'

export type BlockStand = {
  block: ListenBlock
  /** Bereiche mit offener Freigabe. */
  bereiche: number
  /** Freigaben, die noch fehlen: je Bereich max(soll − freigegeben, rest). */
  fehlt: number
  /** Aufgaben, die Lena für das Soll noch prüfen muss (pruef_board_soll.rest). */
  lena: number
  /** Bereiche, die nur noch eine Aufgabe ohne MC brauchen (Soll sonst erreicht). */
  ohneMc: string[]
}

export type FreigabeStand = {
  bloecke: BlockStand[]
  fehlt: number
  /** Von Lena mit „passt“ geprüft, wartet auf die Freigabe durch den Admin; in Listenreihenfolge. */
  wartend: string[]
}

/** Was von Batus Freigabeliste noch offen ist, je Block in Listenreihenfolge; erledigte Blöcke fallen weg. */
export function freigabeStand(soll: PruefSollZeile[], board: PruefBoardZeile[]): FreigabeStand {
  const jeKnoten = new Map<string, PruefBoardZeile[]>()
  for (const z of board) {
    if (!z.skill_key || !z.anlaesse.includes(ANLASS_BATU)) continue
    jeKnoten.set(z.skill_key, [...(jeKnoten.get(z.skill_key) ?? []), z])
  }
  const bloecke = new Map<ListenBlock, BlockStand>()
  const wartend: string[] = []
  for (const s of [...soll].sort((a, b) => a.sort - b.sort)) {
    const zeilen = jeKnoten.get(s.skill_key) ?? []
    const frei = zeilen.filter((z) => z.lena_status === 'freigegeben').length
    const fehlt = Math.max(s.soll - frei, s.rest)
    if (fehlt === 0) continue
    wartend.push(...zeilen.filter((z) => z.lena_status === 'passt').map((z) => z.task_id))
    const block = blockVon(s.sort)
    const b = bloecke.get(block) ?? { block, bereiche: 0, fehlt: 0, lena: 0, ohneMc: [] }
    b.bereiche += 1
    b.fehlt += fehlt
    b.lena += s.rest
    if (s.rest > 0 && s.gezaehlt >= s.soll) b.ohneMc.push(s.skill_label)
    bloecke.set(block, b)
  }
  const liste = [...bloecke.values()]
  return { bloecke: liste, fehlt: liste.reduce((n, b) => n + b.fehlt, 0), wartend }
}
