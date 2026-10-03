// "Schon behandelt" aus dem Schulplan vorbelegen. Rein, ohne Supabase.
import type { LeadThema, SchulPlanZeile, Stufe, Thema } from '@/types'
import { klassenDerStufe } from './suche'

/**
 * Themen, die laut Schulplan vor dem aktuellen Thema dran waren: alles aus
 * den niedrigeren Klassen plus die Vorhaben der eigenen Klasse vor dem
 * aktuellen Thema. Steht das aktuelle Thema nicht im Plan der Klasse (oder
 * fehlt es), nur die niedrigeren Klassen. Ohne Plan oder Klasse: nichts.
 * Das aktuelle Thema selbst ist nie dabei.
 */
export function vorbelegungBehandelt(
  plan: SchulPlanZeile[],
  klasse: number | null,
  aktuellesThema: string | null,
): string[] {
  if (klasse === null || plan.length === 0) return []
  const sortiert = [...plan].sort((a, b) => a.klasse - b.klasse || a.position - b.position)
  // Kommt das Thema in der Klasse mehrfach vor, zaehlt sein erstes Vorhaben.
  // Ohne aktuelles Thema keine Grenze (sonst traefe null die nicht
  // zuordenbaren Vorhaben).
  const grenze =
    aktuellesThema === null
      ? null
      : (sortiert.find((z) => z.klasse === klasse && z.thema_key === aktuellesThema)?.position ??
        null)
  const keys: string[] = []
  for (const z of sortiert) {
    const davor =
      z.klasse < klasse || (z.klasse === klasse && grenze !== null && z.position < grenze)
    if (!davor || z.thema_key === null || z.thema_key === aktuellesThema) continue
    if (!keys.includes(z.thema_key)) keys.push(z.thema_key)
  }
  return keys
}

/** Stand des Plans fuer den Hinweis "aus dem Schulplan (Stand …)". */
export function planStand(plan: SchulPlanZeile[]): string | null {
  return plan.find((z) => z.stand !== null && z.stand.trim() !== '')?.stand ?? null
}

/**
 * Was beim Setzen des aktuellen Themas an "behandelt"-Zeilen zu schreiben ist:
 * fehlende Vorbelegungen anlegen, alte Vorbelegungen aus dem Schulplan, die
 * nicht mehr passen, entfernen. Im Gespraech genannte Zeilen bleiben stehen.
 */
export function abgleichBehandelt(
  vorhanden: LeadThema[],
  vorbelegung: string[],
): { anlegen: string[]; entfernen: string[] } {
  const keys = new Set(vorhanden.map((t) => t.thema_key))
  return {
    anlegen: vorbelegung.filter((k) => !keys.has(k)),
    entfernen: vorhanden
      .filter((t) => t.status === 'behandelt' && t.quelle === 'schulplan')
      .filter((t) => !vorbelegung.includes(t.thema_key))
      .map((t) => t.thema_key),
  }
}

export type ChipGruppe = { klasse: number | null; themen: Thema[] }

/**
 * Themen einer Stufe fuer die Chip-Ansicht. Mit Schulplan je Klasse dieser
 * Schule in Plan-Reihenfolge, Stufen-Themen ausserhalb des Plans am Ende
 * (klasse null). Ohne Plan eine Gruppe in Katalog-Reihenfolge.
 */
export function chipGruppen(
  katalog: Thema[],
  stufe: Stufe,
  plan: SchulPlanZeile[],
): ChipGruppe[] {
  const derStufe = [...katalog]
    .filter((t) => t.stufe === stufe)
    .sort((a, b) => (a.sort ?? 0) - (b.sort ?? 0))
  const [von, bis] = klassenDerStufe(stufe)
  const zeilen = plan
    .filter((z) => z.klasse >= von && z.klasse <= bis && z.thema_key !== null)
    .sort((a, b) => a.klasse - b.klasse || a.position - b.position)
  if (zeilen.length === 0) return derStufe.length > 0 ? [{ klasse: null, themen: derStufe }] : []

  const nachKey = new Map(katalog.map((t) => [t.thema_key, t]))
  const gruppen: ChipGruppe[] = []
  const gesehen = new Set<string>()
  for (const z of zeilen) {
    const thema = nachKey.get(z.thema_key ?? '')
    if (!thema) continue
    let gruppe = gruppen.find((g) => g.klasse === z.klasse)
    if (!gruppe) {
      gruppe = { klasse: z.klasse, themen: [] }
      gruppen.push(gruppe)
    }
    if (!gruppe.themen.includes(thema)) gruppe.themen.push(thema)
    gesehen.add(thema.thema_key)
  }
  const rest = derStufe.filter((t) => !gesehen.has(t.thema_key))
  if (rest.length > 0) gruppen.push({ klasse: null, themen: rest })
  return gruppen
}
