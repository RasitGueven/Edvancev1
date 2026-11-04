// Bericht V4-S (docs/report/v4/Bauauftrag-V4-S.md, Entscheidungen 2–3): die anstehende Arbeit im aktuellen Thema.
//
// Nur bei leads.klassenarbeit_status = 'bevorstehend'. Dann prüft die LSA das aktuelle Thema zuerst, und die
// Befunde gehören auf die Karte der aktuellen Station. Zwei Gruppen:
//   a) im Thema selbst — direkt geprüfte Bereiche, deren Heimat-Thema das aktuelle Thema ist,
//   b) Voraussetzungen — direkt geprüfte Bereiche, die das Thema voraussetzt (dieselbe Kante wie signaleJeThema
//      und baueLueckenweg: s setzt b voraus, Heimat-Thema von s ist das Thema), ohne die aus a.
// Gezählt wird wie überall im Bericht: `bereiche` sind die gezählten (ohne unsichere Vorgriffe). Das Signal folgt
// derselben Regel wie bei den kommenden Stationen, über a und b zusammen.

import { signalVon } from '@/lib/report/elternbericht/fahrplan'
import type { EbAnstehend, EbBereich, EbSignal, HeimatThema } from '@/types'

const nachKlasseLabel = (a: EbBereich, b: EbBereich): number =>
  a.klasse - b.klasse || a.label.localeCompare(b.label, 'de')

const teile = (liste: readonly EbBereich[]): EbAnstehend['imThema'] => {
  const sortiert = [...liste].sort(nachKlasseLabel)
  return { sitzt: sortiert.filter((b) => b.sicher), fehlt: sortiert.filter((b) => !b.sicher) }
}

/**
 * @param bereiche die gezählten Bereiche
 * @param heimatThemen skill_thema
 * @param voraus signaleJeThema(...).get(themaKey): die Bereiche, die das Thema voraussetzt (Gruppe b samt a)
 */
export function baueAnstehend({
  themaKey,
  titel,
  bereiche,
  heimatThemen,
  voraus,
}: {
  themaKey: string
  titel: string
  bereiche: readonly EbBereich[]
  heimatThemen: readonly HeimatThema[]
  voraus: { sitzt: readonly EbBereich[]; fehlt: readonly EbBereich[] } | undefined
}): EbAnstehend {
  const heimat = new Set(heimatThemen.filter((h) => h.themaKey === themaKey).map((h) => h.skillKey))
  const imThema = bereiche.filter((b) => heimat.has(b.skillKey))
  const vorher = [...(voraus?.sitzt ?? []), ...(voraus?.fehlt ?? [])].filter((b) => !heimat.has(b.skillKey))
  return { themaKey, titel, imThema: teile(imThema), voraus: teile(vorher) }
}

/** Signal der anstehenden Arbeit: fehlt, erfuellt oder ohne über a und b zusammen. */
export function signalAnstehend(a: EbAnstehend): EbSignal {
  const alle = new Map([[a.themaKey, {
    sitzt: [...a.imThema.sitzt, ...a.voraus.sitzt],
    fehlt: [...a.imThema.fehlt, ...a.voraus.fehlt],
  }]])
  return signalVon(alle, a.themaKey)
}

/** Alle Labels mit Übungsbedarf aus a und b (für den Lernpfad). */
export const fehltAnstehend = (a: EbAnstehend): Set<string> =>
  new Set([...a.imThema.fehlt, ...a.voraus.fehlt].map((b) => b.label))
