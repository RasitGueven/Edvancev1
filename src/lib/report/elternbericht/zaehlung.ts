// Eltern-Bericht R7 — die Zahlen „x von y Bereichen" (Entscheidung 4).
//
// Katalog = alle Skills mit klasse_herkunft ≤ k, VEREINIGT mit allen direkt
// geprüften Skills. k = min(Klasse der Sitzung, höchste klasse_herkunft im
// Katalog). Die Vereinigung hält „nicht untersucht" ≥ 0: Ein Kind der Klasse 7
// kann einen Bereich aus Klasse 9 gelöst haben, und der zählt dann mit.
//
// Nicht wie im R6-Profil über die sechs Familien: 41 der 130 Skills haben keine
// Familie (Funktionen, Zufall, Potenzen, Wurzeln, Runden) — die LSA prüft sie
// trotzdem.

import { THEMENFELDER, feldVon } from '@/lib/report/elternbericht/themenfelder'
import type { EbBereich, EbProfilZeile, EbZaehlung, KatalogSkill } from '@/types'

export type ZaehlungErgebnis = {
  zaehlung: EbZaehlung
  profil: EbProfilZeile[]
}

/** null ohne Katalog: Eine falsche Zahl auf Papier wäre schlimmer als keine. */
export function zaehle(
  alleBereiche: readonly EbBereich[],
  katalog: readonly KatalogSkill[],
  kindKlasse: number,
): ZaehlungErgebnis | null {
  if (katalog.length === 0) return null
  // Je Schlüssel ein Bereich — sonst wird „nicht untersucht" negativ.
  const bereiche = [...new Map(alleBereiche.map((b) => [b.skillKey, b])).values()]

  const bisKlasse = Math.min(kindKlasse, Math.max(...katalog.map((k) => k.klasse)))

  // Schlüssel → Feld. Untersuchte Bereiche zuerst: ihr Feld kommt aus
  // demselben Schlüssel, die Reihenfolge ändert also nichts am Ergebnis.
  const menge = new Map<string, EbBereich['feld']>()
  for (const b of bereiche) menge.set(b.skillKey, b.feld)
  for (const k of katalog) {
    if (k.klasse <= bisKlasse && !menge.has(k.skillKey)) menge.set(k.skillKey, feldVon(k.skillKey))
  }

  const untersucht = bereiche.length
  const sicher = bereiche.filter((b) => b.sicher).length
  const uebung = untersucht - sicher

  const profil = THEMENFELDER.flatMap(({ key }) => {
    let vorhanden = 0
    for (const feld of menge.values()) if (feld === key) vorhanden += 1
    if (vorhanden === 0) return []
    const drin = bereiche.filter((b) => b.feld === key)
    const s = drin.filter((b) => b.sicher).length
    return [{ feld: key, vorhanden, sicher: s, uebung: drin.length - s }]
  })

  return {
    zaehlung: {
      untersucht,
      sicher,
      uebung,
      katalog: menge.size,
      offen: menge.size - untersucht,
      bisKlasse,
    },
    profil,
  }
}
