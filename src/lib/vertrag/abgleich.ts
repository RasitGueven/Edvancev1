// Abgleich beim Einpflegen eines Ruecklaufs: was versendet wurde gegen das,
// was auf dem unterschriebenen Papier steht. Es gilt das Papier — der Vergleich
// entscheidet nur, ob ein Vermerk Pflicht wird (Anforderung F.20).

export type AbgleichFeld = 'tier_id' | 'laufzeit_monate' | 'vertragsbeginn'

export type AbgleichStand = {
  tier_id: string | null
  laufzeit_monate: number | null
  vertragsbeginn: string | null
}

export const ABGLEICH_FELDER: AbgleichFeld[] = ['tier_id', 'laufzeit_monate', 'vertragsbeginn']

/** Welche Felder auf dem Papier anders stehen als im versendeten Stand. */
export function abweichendeFelder(soll: AbgleichStand, ist: AbgleichStand): AbgleichFeld[] {
  return ABGLEICH_FELDER.filter((feld) => {
    const a = soll[feld]
    const b = ist[feld]
    // Ein noch nicht ausgefuelltes Ist-Feld ist keine Abweichung, sondern eine
    // Luecke — die faengt die Pflichtfeldpruefung ab, nicht der Abgleich.
    if (b === null || b === '') return false
    return a !== b
  })
}

/** Ist der Vermerk Pflicht, und liegt er vor? */
export function vermerkFehlt(
  soll: AbgleichStand,
  ist: AbgleichStand,
  vermerk: string,
): boolean {
  return abweichendeFelder(soll, ist).length > 0 && vermerk.trim() === ''
}
