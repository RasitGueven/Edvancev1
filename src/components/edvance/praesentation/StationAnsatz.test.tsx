// R7-11: Station 01 und 04 nehmen dieselbe Rechnung wie der Bogen —
// Schwerpunkte aus schwerpunkte.ts, Anliegen aus anliegen.ts.
import { screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Station1 } from './Station1'
import { Station4 } from './Station4'
import { zeigeStation } from './testStation'
import { daten, zeige } from './testStation34'

const F = PRAESENTATION_FAELLE

describe('Station 01 — Anliegen wie Seite 1', () => {
  it('abgestuft: Frage und Antwort zum Thema, kein „Im Blick“', () => {
    zeigeStation(Station1, 'abgestuft')
    expect(screen.getByTestId('tp-s1-anliegen')).toHaveTextContent(
      'Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.',
    )
    expect(screen.queryByText(/Im Blick/)).toBeNull()
  })

  it('anliegenGemischt: nur Noten, mit Antwortsatz; kein Wort zur Konzentration', () => {
    const { container } = zeigeStation(Station1, 'anliegenGemischt')
    expect(screen.getByTestId('tp-s1-anliegen')).toHaveTextContent(
      'Sie machen sich Sorgen um Ilkays Noten. Dort setzen wir zuerst an: Geometrie.',
    )
    expect(container).not.toHaveTextContent(/Konzentration/)
  })

  it('ilkay und anliegenNurUeberfach: kein Anliegen-Satz', () => {
    for (const fall of ['ilkay', 'anliegenNurUeberfach']) {
      const { container, unmount } = zeigeStation(Station1, fall)
      expect(screen.queryByTestId('tp-s1-anliegen'), fall).toBeNull()
      expect(container, fall).not.toHaveTextContent(/Konzentration/)
      unmount()
    }
  })
})

describe('Station 04 — Schwerpunkte aus schwerpunkte.ts', () => {
  it('abgestuft: Reelle Zahlen an Platz 1 mit Schild, Förderfokus mit Übungsbedarf im Thema', () => {
    zeige(Station4, F.abgestuft)
    const tabs = screen.getAllByRole('tab')
    expect(tabs[0]).toHaveTextContent('Reelle Zahlen')
    expect(tabs[1]).toHaveTextContent('Terme & Gleichungen')
    expect(screen.getByTestId('tp-s4-chip-thema')).toHaveTextContent('Aktuelles Thema')
    expect(screen.getByRole('tabpanel')).toHaveTextContent('Wurzelgesetze für Produkt und Quotient')
  })

  it.each(Object.keys(F).filter((n) => n !== 'ohneKatalog'))('%s: dieselben Titel und Reihenfolge wie der Bogen', (n) => {
    const f = F[n]
    const e = f.data.erzaehlung
    const b = baueElternbericht({
      kompetenzen: e.kompetenzen,
      katalog: e.katalog,
      klasse: f.data.grade,
      lernweg: { erzaehlung: e, datum: f.data.analysedAt },
    })!
    expect(daten(f).schwerpunkte.map((s) => s.thema ?? s.feld)).toEqual(b.schwerpunkte.map((s) => s.thema ?? s.feld))
  })
})
