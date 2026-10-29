// Muster-Ansicht nach Sessions (M1): Gruppierung der Zeilen aus bauform_pruef_plan, Fortschritt je Session und die
// Bedingung fuer „Session n freigeben“. Rein, ohne Texte.
import type { BauformPlanZeile, BauformStatus } from '@/types/bauformPruefung'
import { musterStand, type MusterStand } from './bauformStand'

export type MusterFilter = 'alle' | 'zur_pruefung' | 'rueckfrage' | 'zur_freigabe' | 'freigegeben'
export const MUSTER_FILTER: readonly MusterFilter[] = ['alle', 'zur_pruefung', 'rueckfrage', 'zur_freigabe', 'freigegeben']

export type SessionGruppe = {
  /** Session-Nummer, null fuer die Gruppe am Ende (nicht zugeordnet). */
  nr: number | null
  titel: string | null
  /** Nur Voraussetzungs-Muster in der Gruppe ohne Session. */
  nurVoraussetzungen: boolean
  zeilen: BauformPlanZeile[]
  stand: MusterStand
}

const reihenfolge = (a: BauformPlanZeile, b: BauformPlanZeile): number =>
  Number(b.ist_voraussetzung) - Number(a.ist_voraussetzung) || a.schluessel.localeCompare(b.schluessel)

/** Gruppen nach Session aufsteigend, nicht zugeordnete am Ende; innerhalb Voraussetzungen zuerst. */
export function nachSessions(zeilen: BauformPlanZeile[]): SessionGruppe[] {
  const map = new Map<number | null, BauformPlanZeile[]>()
  for (const z of zeilen) map.set(z.session_nr, [...(map.get(z.session_nr) ?? []), z])
  return [...map.entries()]
    .sort(([a], [b]) => (a ?? Infinity) - (b ?? Infinity))
    .map(([nr, liste]) => {
      const sortiert = [...liste].sort(reihenfolge)
      return {
        nr,
        titel: sortiert.find((z) => z.session_titel)?.session_titel ?? null,
        nurVoraussetzungen: sortiert.every((z) => z.ist_voraussetzung),
        zeilen: sortiert,
        stand: musterStand(sortiert),
      }
    })
}

export function passtZuFilter(status: BauformStatus, filter: MusterFilter): boolean {
  return filter === 'alle' || status === filter
}

/** Schluessel, die „Session n freigeben“ freigibt: alle zur Freigabe, aber nur, wenn keines in Rueckfrage steht. */
export function freigebbar(gruppe: SessionGruppe): string[] {
  if (gruppe.zeilen.some((z) => z.status === 'rueckfrage')) return []
  return gruppe.zeilen.filter((z) => z.status === 'zur_freigabe').map((z) => z.schluessel)
}
