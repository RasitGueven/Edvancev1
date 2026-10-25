// Eltern-Bericht v4 — Ziele in Elternsprache (Bauauftrag V4, Entscheidung 7).
//
// Der Systemvorschlag für Seite 5, gebaut aus Fahrplan und Sorgfalts-Muster.
// Nur Schlüssel und Werte (die Sätze stehen in elternbericht.json, v4.s5.ziele),
// keine Fachbegriffe, keine Note, keine Prognose. Höchstens vier Ziele:
//   1. die erste kommende Station mit Übungsbedarf („gut vorbereitet“),
//   2. die nächsten ein bis zwei solcher Stationen („nicht bei null“),
//   3. das Sorgfalts-Muster,
//   4. übrige Lücken ohne kommende Station („Wird später wichtig“).
// Gezeigt nur bei ziele_bestaetigt; ein Zielbild des Coachs geht vor (Seite 5).

import type { Fehlermuster } from '@/lib/report/elternbericht/fehlermuster'
import type { EbFahrplan } from '@/types'

export type ZielSchluessel = { schluessel: string; werte: Record<string, string> }

export function zieleV4({
  fahrplan,
  muster,
  name,
  spaeterLuecken,
}: {
  fahrplan: EbFahrplan | null
  muster: Fehlermuster | null
  /** Vorname; null → Fassungen „…OhneName“. */
  name: string | null
  /** Zahl der Bereiche in „Wird später wichtig“. */
  spaeterLuecken: number
}): ZielSchluessel[] {
  const mitName = (schluessel: string, werte: Record<string, string> = {}): ZielSchluessel =>
    name ? { schluessel, werte: { ...werte, name } } : { schluessel: `${schluessel}OhneName`, werte }
  const fehlt = (fahrplan?.stationen ?? []).filter((s) => s.nummer > 1 && s.signal === 'fehlt')
  const [erste, ...rest] = fehlt
  const danach = rest.slice(0, 2)

  const ziele: ZielSchluessel[] = []
  if (erste) ziele.push(mitName('v4.s5.ziele.vorbereitet', { thema: erste.titel }))
  if (danach.length === 1) ziele.push(mitName('v4.s5.ziele.spaeterEins', { a: danach[0].titel }))
  if (danach.length === 2) ziele.push(mitName('v4.s5.ziele.spaeterZwei', { a: danach[0].titel, b: danach[1].titel }))
  if (muster?.sorgfalt) ziele.push(mitName('v4.s5.ziele.sorgfalt'))
  if (spaeterLuecken > 0) ziele.push({ schluessel: 'v4.s5.ziele.weitere', werte: {} })
  return ziele.slice(0, 4)
}
