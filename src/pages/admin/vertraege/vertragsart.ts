// V5: Was an der Vertragsart haengt — welche Dokumente zum Buendel gehoeren und
// welches davon der Vertrag selbst ist. Die Datenbank prueft dasselbe
// (vertrag_dokumente.vertragsarten); hier steht es fuer die Anzeige.

import type { Vertragsart, VertragDokument } from '@/types'

export function istPilot(v: { vertragsart?: Vertragsart | null }): boolean {
  return v.vertragsart === 'pilot'
}

/** Schluessel des Vertragsdokuments selbst (Unterschrift "vertrag"). */
export function vertragsDokument(art: Vertragsart): 'vertrag' | 'pilotvereinbarung' {
  return art === 'pilot' ? 'pilotvereinbarung' : 'vertrag'
}

/** Die aktiven Dokumente, die zum Buendel dieser Vertragsart gehoeren. */
export function dokumenteFuer(dokumente: VertragDokument[], art: Vertragsart): VertragDokument[] {
  return dokumente.filter((d) => (d.vertragsarten ?? ['regulaer']).includes(art))
}
