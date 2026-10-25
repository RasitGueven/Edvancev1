// Hilfe für die V4-Tests: der Bericht eines Falls so gebaut wie Bogen und
// Präsentation ihn bauen (Lernweg-Quelle, Stand der Klassenarbeit, Note).
// Nur Tests; kein Supabase-Client.

import { baueElternbericht, gezaehlteBereiche, type LernwegQuelle } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbBereich, EbFahrplan, EbLernpfadPunkt, EbLueckenweg, EbThemaSignal, Elternbericht, ReportData } from '@/types'

/** Der Bericht mit den v4-Feldern als Pflichtfelder (baueElternbericht setzt sie immer). */
export type BerichtV4 = Elternbericht & {
  fahrplan: EbFahrplan | null
  signale: EbThemaSignal[]
  lueckenwegV4: EbLueckenweg | null
  lernpfad: EbLernpfadPunkt[]
}

export const quelleVon = (d: ReportData): LernwegQuelle => ({ erzaehlung: d.erzaehlung, datum: d.analysedAt })

export const berichtVon = (d: ReportData): BerichtV4 | null =>
  baueElternbericht({
    kompetenzen: d.erzaehlung.kompetenzen,
    katalog: d.erzaehlung.katalog,
    klasse: d.grade,
    lernweg: quelleVon(d),
    klassenarbeit: d.erstgespraech?.klassenarbeit ?? null,
    note: d.erstgespraech?.letzteNote ?? null,
  }) as BerichtV4 | null

export const bericht = (name: string): BerichtV4 => {
  const b = berichtVon(FAELLE[name].data)
  if (!b) throw new Error(`kein Bericht für ${name}`)
  return b
}

/** Die gezählten Bereiche (ohne unsichere Vorgriffe) eines Falls. */
export const gezaehlt = (name: string): EbBereich[] => {
  const d = FAELLE[name].data
  return gezaehlteBereiche(d.erzaehlung.kompetenzen, quelleVon(d)).bereiche
}
