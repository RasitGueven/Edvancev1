// PS-1, Entscheidung 3: Druckbogen und Präsentation bleiben deckungsgleich. Die
// Präsentation lässt weg, sie behauptet nichts anderes — für alle Fixtures
// stimmen die Zahlen in Station 02 und der erste Schwerpunkt in Station 04 mit
// dem Bericht R7 überein.
import { screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'

import { schwerpunktTitel } from '@/components/edvance/elternbericht/liste'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import type { Elternbericht } from '@/types'

import { Station2 } from './Station2'
import { Station4 } from './Station4'
import { zeigeStation } from './testStation'

const FAELLE = Object.keys(PRAESENTATION_FAELLE).filter((f) => f !== 'ohneKatalog')

function bericht(fall: string): Elternbericht {
  const { data } = PRAESENTATION_FAELLE[fall]
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
  })
  if (!b) throw new Error(fall)
  return b
}

describe('Deckungsgleich mit dem Druckbogen (PS-1, Entscheidung 3)', () => {
  it.each(FAELLE)('%s: sicher und Übungsbedarf wie R7', (fall) => {
    const b = bericht(fall)
    zeigeStation(Station2, fall)
    expect(screen.getByTestId('tp-s2-zahl-sicher').querySelector('strong')).toHaveTextContent(
      new RegExp(`^${b.zaehlung.sicher}$`),
    )
    // Kombiniert (UEBERSPRUNGEN_ANZEIGE): Übungsbedarf mit übersprungen, wie R7.
    expect(screen.getByTestId('tp-s2-zahl-uebung').querySelector('strong')).toHaveTextContent(
      new RegExp(`^${b.zaehlung.uebung}$`),
    )
  })

  it.each(FAELLE)('%s: der erste Punkt ist Schwerpunkt 1 aus R7', (fall) => {
    const b = bericht(fall)
    zeigeStation(Station4, fall)
    const punkte = screen.queryAllByRole('tab')
    if (b.schwerpunkte.length === 0) {
      expect(punkte).toHaveLength(0)
      return
    }
    const tb = i18n.getFixedT('de', 'elternbericht')
    expect(punkte[0].querySelector('.tp-s4-label b')).toHaveTextContent(schwerpunktTitel(tb, b.schwerpunkte[0]))
  })
})
