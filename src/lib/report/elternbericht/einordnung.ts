// Eltern-Bericht R7 — die Pyramide nach Lehrplanstufe (Entscheidung 6).
//
// Stufe eines Skills = stufeAusKlasse(klasse_herkunft), Stufe des Kindes =
// stufeAusKlasse(Klasse der Sitzung). NIE fundament_tiefe: die Pyramide sagt,
// wo ein Bereich im Lernstoff liegt, nicht, worauf er aufbaut.

import { THEMENFELDER } from '@/lib/report/elternbericht/themenfelder'
import { stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import type { EbBereich, EbEbene, EbeneKey, Stufe } from '@/types'

/** Von oben nach unten. */
export const EBENEN: readonly EbeneKey[] = ['spaeter', 'aktuell', 'weiterfuehrend', 'grundlagen']

const STUFEN_AUFSTEIGEND: readonly Stufe[] = ['erprobung', 'erste', 'zweite']
const rang = (s: Stufe): number => STUFEN_AUFSTEIGEND.indexOf(s)

/**
 * Ab Klasse 11 hat der Katalog keine eigene Stufe: Das Kind steht über allen
 * Stufen, 7–10 sind weiterführend, 5/6 Grundlagen, nichts ist „aktuell".
 */
function rangDesKindes(kindKlasse: number): number {
  return kindKlasse > 10 ? STUFEN_AUFSTEIGEND.length : rang(stufeAusKlasse(kindKlasse))
}

export function ebeneFuer(skillKlasse: number, kindKlasse: number): EbeneKey {
  const skill = rang(stufeAusKlasse(skillKlasse))
  const kind = rangDesKindes(kindKlasse)
  if (skill > kind) return 'spaeter'
  if (skill === kind) return 'aktuell'
  if (skill === 0) return 'grundlagen'
  return 'weiterfuehrend'
}

/** In der Gruppe erst sicher, dann Übungsbedarf, je nach Label. */
const nachZustandLabel = (a: EbBereich, b: EbBereich): number =>
  Number(b.sicher) - Number(a.sicher) || a.label.localeCompare(b.label, 'de')

export function bauePyramide(bereiche: readonly EbBereich[], kindKlasse: number): EbEbene[] {
  return EBENEN.flatMap((ebene) => {
    const drin = bereiche.filter((b) => ebeneFuer(b.klasse, kindKlasse) === ebene)
    if (drin.length === 0) return []

    const vorhanden = new Set(drin.map((b) => stufeAusKlasse(b.klasse)))
    const gruppen = THEMENFELDER.flatMap(({ key }) => {
      const eintraege = drin.filter((b) => b.feld === key).sort(nachZustandLabel)
      return eintraege.length > 0 ? [{ feld: key, eintraege }] : []
    })
    const sicher = drin.filter((b) => b.sicher).length

    return [
      {
        ebene,
        stufen: STUFEN_AUFSTEIGEND.filter((s) => vorhanden.has(s)),
        sicher,
        uebung: drin.length - sicher,
        gruppen,
      },
    ]
  })
}
