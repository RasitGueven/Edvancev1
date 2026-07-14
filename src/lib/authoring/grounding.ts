// Quellenbeleg (_grounding) aus der Extraktion — Read-Only.
//
// Der Pfleger muss sehen, worauf er sich stuetzt: was stand im Original-Aufgaben-
// blatt, was in der Auswertungsanleitung, was in der didaktischen Kommentierung.
// Ohne den Beleg ist "korrigieren" raten.
//
// Der Index liegt als statische Datei in public/ (gebaut von
// scripts/build-grounding-index.ts) und wird genau einmal geladen — beim ersten
// Item mit VERA-Quelle. Nicht importiert, sondern gefetcht: 600 KB gehoeren nicht
// ins Bundle jeder Admin-Seite.

import type { GroundingRecord } from '@/types'

const INDEX_URL = '/authoring/grounding-vera8.json'

/** Nur diese Quelle hat Belege — bei allem anderen sparen wir uns den Fetch. */
const GROUNDED_SOURCES = new Set(['VERA8_IQB'])

let cache: Record<string, GroundingRecord> | null = null
let inflight: Promise<Record<string, GroundingRecord>> | null = null

async function loadIndex(): Promise<Record<string, GroundingRecord>> {
  if (cache) return cache
  if (inflight) return inflight

  inflight = fetch(INDEX_URL)
    .then((res) => {
      if (!res.ok) throw new Error(`grounding index: HTTP ${res.status}`)
      return res.json() as Promise<Record<string, GroundingRecord>>
    })
    .then((json) => {
      cache = json
      inflight = null
      return json
    })
    .catch((err) => {
      inflight = null
      throw err
    })

  return inflight
}

/**
 * Der Beleg zu einem Item, oder null.
 *
 * null heisst nicht "Fehler", sondern "fuer dieses Item gibt es keinen Beleg" —
 * bei den Fundament-Eigenbauten (Bruchrechnung, Prozent …) ist das der Normalfall.
 * Sie haben keine Quelle, weil sie keine haben sollen.
 */
export async function getGrounding(
  source: string,
  sourceRef: string | null,
): Promise<GroundingRecord | null> {
  if (!sourceRef || !GROUNDED_SOURCES.has(source)) return null
  try {
    const index = await loadIndex()
    return index[sourceRef] ?? null
  } catch {
    // Ein fehlender Index darf den Editor nicht abschiessen — er ist Kontext,
    // kein Pflichtfeld. Das Panel zeigt dann seinen Fehlzustand.
    return null
  }
}

export function hasGroundingSource(source: string, sourceRef: string | null): boolean {
  return Boolean(sourceRef) && GROUNDED_SOURCES.has(source)
}
